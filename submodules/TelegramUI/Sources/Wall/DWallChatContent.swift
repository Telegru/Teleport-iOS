import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import ChatListUI

final class DWallChatContent: ChatCustomContentsProtocol {
    
    let kind: ChatCustomContentsKind
    
    var isLoadingSignal: Signal<Bool, NoError> {
        impl.syncWith { impl in
            impl.isLoadingPromise.get()
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
        
        let tailChatsCount = 100
        let filterPredicate = chatListFilterPredicate(filter: filterData, accountPeerId: context.account.peerId)
        
        kind = .wall(tailChatsCount: tailChatsCount, filter: filterPredicate)
        
        self.impl = QueueLocalObject(queue: queue, generate: {
            return Impl(queue: queue, context: context, filterPredicate: filterPredicate, tailChatsCount: tailChatsCount)
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
        let filterPredicate: ChatListFilterPredicate
        let tailChatsCount: Int
        
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
        private var count: Int = 44
        
        private var previousAnchors: [PeerId: MessageIndex]?

        init(
            queue: Queue,
            context: AccountContext,
            filterPredicate: ChatListFilterPredicate,
            tailChatsCount: Int
        ) {
            self.queue = queue
            self.context = context
            self.tailChatsCount = tailChatsCount
            self.filterPredicate = filterPredicate
            self.loadAnchors()
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
        }
        
        func loadAnchors()  {
            self.previousAnchors = nil
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
                return self.context.account.postbox.oldestUnreadMessagesForPeerIds(
                    peerIds: peerIds,
                    clipHoles: false,
                    namespaces: .all
                )
                |> map { unreadDict -> [PeerId: MessageIndex] in
                    var anchors: [PeerId: MessageIndex] = [:]
                    for peerId in peerIds {
                        if let message = unreadDict[peerId] {
                            anchors[peerId] = MessageIndex(id: message.id, timestamp: message.timestamp)
                        }
                    }
                    return anchors
                }
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
                
                var mergedAnchors: [PeerId: MessageIndex] = self.previousAnchors ?? [:]
                var newPeerAdded = false

                for (peerId, newAnchor) in anchors {
                    if mergedAnchors[peerId] == nil {
                        mergedAnchors[peerId] = newAnchor
                        newPeerAdded = true
                    }
                }

                if newPeerAdded || self.previousAnchors == nil {
                    self.showLoading()
                    self.updateHistoryViewRequest(anchors: mergedAnchors, reload: true)
                    self.previousAnchors = mergedAnchors
                }
            })
        }
        
        func reloadData() {
            showLoading()
            loadAnchors()
        }
        
        func loadMore() {
            if let anchors = self.previousAnchors {
                updateHistoryViewRequest(anchors: anchors, reload: false)
            }
        }
        
        func loadAll() {
            if let anchors = self.previousAnchors {
                loadMaxCountDisposable?.dispose()
                historyViewDisposable?.dispose()
                showLoading()
                loadMaxCountDisposable = (context.account.postbox
                    .maximumUnreadMessagesCountAmongPeers(peerIds: Array(anchors.keys))
                    |> take(1))
                    .startStrict(next: { [weak self] count in
                        guard let self = self else { return }
                        self.count = Int(count) * anchors.keys.count
                        self.updateHistoryViewRequest(anchors: anchors, reload: false)
                    })
            }
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
        
        private func updateHistoryViewRequest(anchors: [PeerId: MessageIndex], reload: Bool) {
            self.historyViewDisposable?.dispose()
            if reload {
                self.count = 44
            }

            let context = self.context
            
            self.historyViewDisposable = (context.account.postbox.aroundAggregatedMessageHistoryViewForPeerIds(
                peerIds: Array(anchors.keys),
                from: anchors,
                count: self.count,
                clipHoles: false
            ))
            .start(next: { [weak self] view in
                guard let self = self else { return }
                self.mergedHistoryView = view.0
                self.historyViewStream.putNext((view.0, view.1))
                self.count = (mergedHistoryView?.entries.count ?? 44) + 44
                
                self.checkAndMarkAsReadIfNeeded(view: view.0)
                if self.count > 1320 {
                    self.count = 88
                    self.loadAnchors()
                }
            })
        }
    }
}
