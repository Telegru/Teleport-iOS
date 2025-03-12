import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import ChatListUI
import TelegramUIPreferences

final class DWallChatContent: ChatCustomContentsProtocol {
    
    let kind: ChatCustomContentsKind
    
    var isLoadingSignal: Signal<Bool, NoError> {
        impl.syncWith { impl in
            impl.isLoadingPromise.get()
        }
    }
    
    var filterSignal: Signal<ChatListFilterPredicate, NoError> {
        return impl.syncWith { impl in
            impl.filterPredicatePromise.get()
        }
    }
    
    var historyView: Signal<(MessageHistoryView, ViewUpdateType), NoError> {
        return self.impl.signalWith({ impl, subscriber in
            if let mergedHistoryView = impl.mergedHistoryView {
                subscriber.putNext((mergedHistoryView, .Initial))
            }
            return impl.historyViewStream.signal().start(next: subscriber.putNext)
        })
    }
    
    var messageLimit: Int? { nil }
    
    var disableFloatingDateHeaders: Bool = false
    
    var hashtagSearchResultsUpdate: ((SearchMessagesResult, SearchMessagesState)) -> Void = { _ in }
    
    private let queue: Queue
    private let impl: QueueLocalObject<Impl>
    
    init(context: AccountContext) {
        let queue = Queue()
        self.queue = queue
        
        let tailChatsCount = 1000
        
        kind = .wall(tailChatsCount: tailChatsCount)
        
        self.impl = QueueLocalObject(queue: queue, generate: {
            return Impl(queue: queue, context: context, tailChatsCount: tailChatsCount)
        })
    }
    
    func reloadData() {
        self.impl.with { impl in
            impl.reloadData()
        }
    }
    
    func loadMore() {
        self.impl.with { impl in
            impl.loadMore()
        }
    }
    
    func loadAll() {
        self.impl.with { impl in
            impl.loadAll()
        }
    }
    
    func loadMoreAt(messageIndex: MessageIndex) {
        self.impl.with { impl in
            impl.loadMoreAt(messageIndex: messageIndex)
        }
    }
    
    func applyMaxReadIndex(for location: ChatLocation, contextHolder: Atomic<ChatLocationContextHolder?>, messageIndex: MessageIndex) {
        self.impl.with { impl in
            impl.markAllMessagesRead(olderThan: messageIndex)
        }
    }
    
    func enqueueMessages(messages: [EnqueueMessage]) {}
    func deleteMessages(ids: [EngineMessage.Id]) {}
    func businessLinkUpdate(message: String, entities: [TelegramCore.MessageTextEntity], title: String?) {}
    func editMessage(id: EngineMessage.Id, text: String, media: RequestEditMessageMedia, entities: TextEntitiesMessageAttribute?, webpagePreviewAttribute: WebpagePreviewMessageAttribute?, disableUrlPreview: Bool) {}
    func quickReplyUpdateShortcut(value: String) {}
    func hashtagSearchUpdate(query: String) {}
}

// MARK: - DWallChatContent.Impl

extension DWallChatContent {
    
    private final class Impl {
        
        let queue: Queue
        let context: AccountContext
        let historyViewStream = ValuePipe<(MessageHistoryView, ViewUpdateType)>()
        let isLoadingPromise = ValuePromise<Bool>(true)
        let tailChatsCount: Int
        
        var filterPredicate: ChatListFilterPredicate {
            didSet {
                filterPredicatePromise.set(filterPredicate)
            }
        }
        
        let filterPredicatePromise: ValuePromise<ChatListFilterPredicate>

        var excludedPeerIds: Set<PeerId> = Set()
        var showArchivedChannels: Bool = true
        private var settingsDisposable: Disposable?
        
        var mergedHistoryView: MessageHistoryView?
        private var historyViewDisposable: Disposable?
        private var loadingDisposable: Disposable?
        private var loadMaxCountDisposable: Disposable?
        private var autoMarkReadDisposable: Disposable?
        
        private var nextHistoryLocationId: Int32 = 1
        private func takeNextHistoryLocationId() -> Int32 {
            let id = self.nextHistoryLocationId
            self.nextHistoryLocationId += 5
            return id
        }
        
        private var ignoredPeerIds: Atomic<Set<PeerId>> = Atomic(value: [])
        private var anchorsDisposable: Disposable?
        private var readViewDisposable: Disposable?
        
        var sourceHistoryViews: Atomic<[PeerId: MessageHistoryView]> = Atomic(value: [:])
        private var pageAnchor: MessageIndex?
        private var filterBefore: [PeerId: MessageIndex]?
        private var currentAnchors: [PeerId: MessageIndex]?
        private let messagesPerPage = 44
        
        init(
            queue: Queue,
            context: AccountContext,
            tailChatsCount: Int
        ) {
            self.queue = queue
            self.context = context
            self.tailChatsCount = tailChatsCount
            
            let filterData = ChatListFilterData(
                isShared: false,
                hasSharedLinks: false,
                categories: .channels,
                excludeMuted: false,
                excludeRead: true,
                excludeArchived: false,
                includePeers: ChatListFilterIncludePeers(),
                excludePeers: [],
                color: nil
            )
            
            let filterPredicate = chatListFilterPredicate(
                filter: filterData,
                accountPeerId: context.account.peerId
            )
            self.filterPredicate = filterPredicate
            self.filterPredicatePromise = ValuePromise<ChatListFilterPredicate>(filterPredicate)
            
            self.settingsDisposable = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
                |> deliverOn(self.queue)).start(next: { [weak self] sharedData in
                    guard let self = self else { return }
                    
                    let dalSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
                    let wallSettings = dalSettings.wallSettings
                    
                    let showArchivedChannelsChanged = self.showArchivedChannels != wallSettings.showArchivedChannels
                    let excludedPeerIdsChanged = Set(wallSettings.excludedChannels) != self.excludedPeerIds
                    
                    if showArchivedChannelsChanged || excludedPeerIdsChanged {
                        self.showArchivedChannels = wallSettings.showArchivedChannels
                        self.excludedPeerIds = Set(wallSettings.excludedChannels)
                        
                        self.updateFilterPredicate()
                        
                        self.reloadData()
                    }
                })
            
            self.updateFilterPredicate()
            
            self.loadInitialData()
            self.loadingDisposable = (self.historyViewStream.signal()
                                      |> map { $0.0.isLoading })
            .start(next: { [weak self] isLoading in
                self?.isLoadingPromise.set(isLoading)
            })
        }
        
        deinit {
            self.historyViewDisposable?.dispose()
            self.loadingDisposable?.dispose()
            self.anchorsDisposable?.dispose()
            self.readViewDisposable?.dispose()
            self.loadMaxCountDisposable?.dispose()
            self.autoMarkReadDisposable?.dispose()
            self.settingsDisposable?.dispose()
        }
        
        private func updateFilterPredicate() {
            let filterData = ChatListFilterData(
                isShared: false,
                hasSharedLinks: false,
                categories: .channels,
                excludeMuted: false,
                excludeRead: true,
                excludeArchived: !self.showArchivedChannels,
                includePeers: ChatListFilterIncludePeers(),
                excludePeers: Array(self.excludedPeerIds),
                color: nil
            )
            
            self.filterPredicate = chatListFilterPredicate(
                filter: filterData,
                accountPeerId: self.context.account.peerId
            )
        }
        
        func loadInitialData() {
            self.currentAnchors = nil
            self.filterBefore = nil
            self.pageAnchor = nil
            self.mergedHistoryView = nil
            self.historyViewDisposable?.dispose()
            self.anchorsDisposable?.dispose()
            self.anchorsDisposable = (context.account.viewTracker.tailChatListView(
                groupId: .root,
                filterPredicate: filterPredicate,
                count: tailChatsCount
            )
                                      |> map { view, _ -> [PeerId] in
                return view.entries.compactMap { entry -> PeerId? in
                    switch entry {
                    case let .MessageEntry(entryData):
                        return (entryData.renderedPeer.peer as? TelegramChannel)?.id
                    default:
                        return nil
                    }
                }
            }
                                      |> mapToSignal { [weak self] peerIds -> Signal<[PeerId: MessageIndex], NoError> in
                guard let self = self else {
                    return .complete()
                }
                return self.context.account.postbox.maxReadIndexForPeerIds(
                    peerIds: peerIds,
                    clipHoles: false,
                    namespaces: .all
                )
            })
            .start(next: { [weak self] anchors in
                guard let self = self else { return }
                
                guard !anchors.isEmpty else {
                    let historyView = MessageHistoryView(
                        tag: nil,
                        namespaces: .all,
                        entries: [],
                        holeEarlier: false,
                        holeLater: false,
                        isLoading: false
                    )
                    self.mergedHistoryView = historyView
                    self.historyViewStream.putNext((historyView, .UpdateVisible))
                    return
                }
                
                var newPeerAdded = false
                for (peerId, _) in anchors {
                    if currentAnchors?[peerId] == nil {
                        newPeerAdded = true
                    }
                }
                
                if newPeerAdded  {
                    self.filterBefore = anchors
                    self.currentAnchors = anchors
                    
                    self.showLoading()
                    self.updateHistoryViewRequest()
                }
                
            })
        }
        
        func reloadData() {
            showLoading()
            loadInitialData()
        }
        
        func loadMore() {
            if let view = self.mergedHistoryView {
                updateAnchorsForPagination(from: view)
            }
            updateHistoryViewRequest()
        }
        
        func loadAll() {
            self.currentAnchors = nil
            self.pageAnchor = nil
            
            let messagesPerPage = self.messagesPerPage
            let filterBefore = self.filterBefore!
            let context = self.context
            
            loadMaxCountDisposable?.dispose()
            
            //FIXME: Тут вероятно перестанет работать подгрузка обновлений, по лайкам
            historyViewDisposable?.dispose()
            //FIXME: Тут вероятно перестанет работать подгрузка обновлений, по подпискам
            anchorsDisposable?.dispose()
            
            loadMaxCountDisposable = (context.account.viewTracker.tailChatListView(
                groupId: .root,
                filterPredicate: filterPredicate,
                count: tailChatsCount
            ) |> map { view, _ -> [PeerId] in
                return view.entries.compactMap { entry -> PeerId? in
                    switch entry {
                    case let .MessageEntry(entryData):
                        return (entryData.renderedPeer.peer as? TelegramChannel)?.id
                    default:
                        return nil
                    }
                }
            } |> mapToSignal { peers in
                (context.account.postbox.getTopMessageAnchorsForPeerIds(
                    peerIds: peers,
                    namespace: Namespaces.Message.Cloud)
                                          |> take(1)
                                          |> mapToSignal { topAnchors in
                    return context.account.postbox.aroundAggregatedMessageHistoryViewForPeerIds(
                        peerIds: Array(topAnchors.keys),
                        anchors: topAnchors,
                        filterBofore: filterBefore,
                        count: messagesPerPage * 4,
                        clipHoles: false,
                        takeTail: true
                    )
                } )
            } |> take(1))
            .startStrict(next: { [weak self] view in
                guard let self = self else { return }
                
                self.mergedHistoryView = view.0
                self.historyViewStream.putNext((view.0, self.mergedHistoryView?.entries.isEmpty == true ? view.1 : .Generic))
                self.checkAndMarkAsReadIfNeeded(view: view.0)
            })
        }
        
        func markAllMessagesRead(olderThan threshold: MessageIndex) {
            guard let mergedView = self.mergedHistoryView else {
                return
            }
            
            var maxReadIndices: [PeerId: MessageIndex] = [:]
            
            for entry in mergedView.entries {
                let message = entry.message
                if message.timestamp <= threshold.timestamp {
                    let peerId = message.id.peerId
                    if let existing = maxReadIndices[peerId] {
                        if existing < message.index {
                            maxReadIndices[peerId] = message.index
                        }
                    } else {
                        maxReadIndices[peerId] = message.index
                    }
                }
            }
            
            for (peerId, messageIndex) in maxReadIndices {
                let location = ChatLocation.peer(id: peerId)
                let contextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
                self.context.applyMaxReadIndex(for: location, contextHolder: contextHolder, messageIndex: messageIndex)
            }
        }
        
        private func checkAndMarkAsReadIfNeeded(view: MessageHistoryView) {
            if view.entries.count == 1, let entry = view.entries.first {
                let location = ChatLocation.peer(id: entry.message.id.peerId)
                let contextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
                
                self.context.applyMaxReadIndex(
                    for: location,
                    contextHolder: contextHolder,
                    messageIndex: entry.message.index
                )
            }
        }
        
        private func showLoading() {
            guard self.mergedHistoryView?.isLoading != true else {
                return
            }
            
            let historyView = MessageHistoryView(
                tag: nil,
                namespaces: .all,
                entries: [],
                holeEarlier: false,
                holeLater: false,
                isLoading: true
            )
            self.mergedHistoryView = historyView
            self.historyViewStream.putNext((historyView, .UpdateVisible))
        }
        
        private func cancelLoadingIfNeeded() {
            if let merged = self.mergedHistoryView, merged.isLoading {
                let updatedHistoryView = MessageHistoryView(
                    tag: merged.tag,
                    namespaces: merged.namespaces,
                    entries: merged.entries,
                    holeEarlier: merged.holeEarlier,
                    holeLater: merged.holeLater,
                    isLoading: false
                )
                self.mergedHistoryView = updatedHistoryView
                self.historyViewStream.putNext((updatedHistoryView, .UpdateVisible))
            }
        }
        
        private func updateHistoryViewRequest() {
            guard let currentAnchors = self.currentAnchors, let filterBefore = self.filterBefore else {
                return
            }
            
            self.historyViewDisposable?.dispose()
            let context = self.context
            
            self.historyViewDisposable = (context.account.postbox.aroundAggregatedMessageHistoryViewForPeerIds(
                peerIds: Array(currentAnchors.keys),
                anchors: currentAnchors,
                anchor: self.pageAnchor,
                filterBofore: filterBefore,
                count: self.messagesPerPage,
                clipHoles: false
            ))
            .start(next: { [weak self] view in
                guard let self = self else { return }
                self.mergedHistoryView = view.0
                self.historyViewStream.putNext((view.0, self.mergedHistoryView?.entries.isEmpty == true ? view.1 : .Generic))
                self.checkAndMarkAsReadIfNeeded(view: view.0)
            })
        }
        
        private func updateAnchorsForPagination(from view: MessageHistoryView) {
            var messagesByPeer: [PeerId: [MessageHistoryEntry]] = [:]
            
            for entry in view.entries {
                let peerId = entry.message.id.peerId
                if messagesByPeer[peerId] == nil {
                    messagesByPeer[peerId] = []
                }
                messagesByPeer[peerId]?.append(entry)
            }
            for (peerId, entries) in messagesByPeer {
                if entries.count > 22 {
                    let middleIndex = entries.count / 2
                    let anchor = entries[middleIndex].index
                    self.currentAnchors?[peerId] = anchor
                }
            }
            if view.entries.count > 22 {
                self.pageAnchor = view.entries[view.entries.count / 2].message.index
            }
        }
        
        
        func loadMoreAt(messageIndex: MessageIndex) {
            guard let currentView = self.mergedHistoryView, !currentView.entries.isEmpty else {
                return
            }
            
            let totalEntries = currentView.entries.count
            let position = findPositionForMessageIndex(messageIndex: messageIndex, in: currentView)
            
            if position > totalEntries * 2 / 3 {
                updateAnchorsForPagination(from: currentView)
                updateHistoryViewRequest()
            }
            
            // TODO: настроить скрол вверх

//            else if position < totalEntries / 3 && !isAtBeginning(currentView) {
//
//                updateAnchorsForPreviousPage(from: currentView)
//                updateHistoryViewRequest()
//            }
        }
                
        private func findPositionForMessageIndex(messageIndex: MessageIndex, in view: MessageHistoryView) -> Int {
            for (index, entry) in view.entries.enumerated() {
                if messageIndex <= entry.message.index {
                    return index
                }
            }
            return view.entries.count - 1
        }
        
        private func isAtBeginning(_ view: MessageHistoryView) -> Bool {
            return !view.holeEarlier
        }
        
        private func updateAnchorsForPreviousPage(from view: MessageHistoryView) {
            var firstMessagesByPeer: [PeerId: MessageHistoryEntry] = [:]
            
            for entry in view.entries.reversed() {
                let peerId = entry.message.id.peerId
                if let existing = firstMessagesByPeer[peerId] {
                    if entry.index < existing.index {
                        firstMessagesByPeer[peerId] = entry
                    }
                } else {
                    firstMessagesByPeer[peerId] = entry
                }
            }
            
            for (peerId, entry) in firstMessagesByPeer {
                if let _ = self.currentAnchors?[peerId] {
                    self.currentAnchors?[peerId] = entry.index
                }
            }
        }
    }
}
