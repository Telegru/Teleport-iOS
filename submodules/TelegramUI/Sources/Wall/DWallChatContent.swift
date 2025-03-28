import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import ChatListUI
import TelegramUIPreferences
import TelegramPresentationData

enum DWallLoadingAction: Equatable {
    case loadingStarted(isLoadAll: Bool)
    case loadingEnded(isLoadAll: Bool)
}

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
    
    var loadingActionSignal: Signal<DWallLoadingAction, NoError> {
        return impl.syncWith { impl in
            impl.loadingActionPromise.get()
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
        
        let tailChatsCount = 100
        
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
    
    func loadMoreAt(messageIndex: MessageIndex, direction: ChatHistoryListLoadDirection){
        self.impl.with { impl in
            impl.loadMoreAt(messageIndex: messageIndex, direction: direction)
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
        let loadingActionPromise = ValuePromise<DWallLoadingAction>(DWallLoadingAction.loadingStarted(isLoadAll: false), ignoreRepeated: false)

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
        private var loadingActionDisposable: Disposable?

        var sourceHistoryViews: Atomic<[PeerId: MessageHistoryView]> = Atomic(value: [:])
        private var pageAnchor: MessageIndex?
        private var currentMessageIndex: MessageIndex?
        private var filterBefore: [PeerId: MessageIndex]?
        private var currentAnchors: [PeerId: MessageIndex]?
        private let messagesPerPage = 50
        private var isLoadingHistoryViewInProgress = false
        private var pendingInitialLoad = true
        private let peersLoadingMonitor: PeersLoadingMonitor
        private var statusDisposable: Disposable? = nil
        
        init(
            queue: Queue,
            context: AccountContext,
            tailChatsCount: Int
        ) {
            self.queue = queue
            self.context = context
            self.tailChatsCount = tailChatsCount
            self.peersLoadingMonitor = PeersLoadingMonitor(postbox: context.account.postbox)

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
                        
                        if !self.pendingInitialLoad {
                            self.reloadData()
                        }
                    }
                })
            
            self.updateFilterPredicate()
            self.showLoading()
            
            self.loadingDisposable = (
                self.historyViewStream.signal()
                |> map { $0.0.isLoading }
            )
            .start(next: { [weak self] isLoading in
                self?.isLoadingPromise.set(isLoading)
            })
            
            statusDisposable = peersLoadingMonitor.loadedSignal.start(next: { [weak self] loaded in
                if loaded {
                    self?.pendingInitialLoad = false
                    self?.loadInitialData()
                }
            })
            peersLoadingMonitor.start()
        }
        
        deinit {
            self.historyViewDisposable?.dispose()
            self.loadingDisposable?.dispose()
            self.anchorsDisposable?.dispose()
            self.readViewDisposable?.dispose()
            self.loadMaxCountDisposable?.dispose()
            self.autoMarkReadDisposable?.dispose()
            self.settingsDisposable?.dispose()
            self.loadingActionDisposable?.dispose()
            self.statusDisposable?.dispose()
            self.peersLoadingMonitor.stop()
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
            
            
            self.anchorsDisposable = (
                combineLatest(
                    self.context.account.postbox.getChatListPeers(
                        groupId: .root,
                        filterPredicate: self.filterPredicate
                    ),
                    self.context.account.postbox.getChatListPeers(
                        groupId: Namespaces.PeerGroup.archive,
                        filterPredicate: self.filterPredicate
                    )
                )
                |> mapToSignal { [weak self] rootPeers, archivePeers -> Signal<[PeerId: MessageIndex], NoError> in
                    guard let self = self else {
                        return .complete()
                    }
                    let peerIds = rootPeers + archivePeers
                    return self.context.account.postbox.maxReadIndexForPeerIds(
                        peerIds: peerIds,
                        clipHoles: true,
                        namespaces: .all
                    )
                    |> take(1)
                    |> deliverOn(self.queue)
                }
            )
                .startStrict(next: { [weak self] anchors in
                    guard let self = self else { return }
                    
                    if anchors.isEmpty && self.currentAnchors == nil {
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
                        if self.currentAnchors?[peerId] == nil {
                            newPeerAdded = true
                        }
                    }
                    
                    if newPeerAdded || self.mergedHistoryView?.entries.isEmpty == true {
                        self.filterBefore = anchors
                        self.currentAnchors = anchors
                        
                        if self.mergedHistoryView == nil || self.mergedHistoryView?.entries.isEmpty == true {
                            self.showLoading()
                        }
                        self.updateHistoryViewRequest()
                    }
            })
        }
        
        func reloadData() {
            guard !self.pendingInitialLoad else {
                self.showLoading()
                return
            }
            
            currentMessageIndex = nil
            currentAnchors = nil
            pageAnchor = nil
            historyViewDisposable?.dispose()
            loadInitialData()
            showLoading()
            loadingActionPromise.set(.loadingStarted(isLoadAll: false))
            self.loadingActionDisposable?.dispose()
            self.loadingActionDisposable = (
                (self.historyViewStream.signal())
                |> take(1)
            )
            .start(next: { [weak self] view in
                self?.loadingActionPromise.set(.loadingEnded(isLoadAll: false))
            })
        }
        
        func loadMore() {
        }
        
        func loadAll() {
            
            self.currentAnchors = nil
            self.pageAnchor = nil
            
            let messagesPerPage = self.messagesPerPage
            guard let filterBefore = self.filterBefore else {
                assertionFailure()
                return
            }
            
            let context = self.context
            loadingActionPromise.set(.loadingStarted(isLoadAll: true))

            loadMaxCountDisposable?.dispose()
            
            historyViewDisposable?.dispose()
            
            let getPeerIds = { (groupId: PeerGroupId) -> Signal<[PeerId], NoError> in
                return self.context.account.postbox.getChatListPeers(
                    groupId: groupId,
                    filterPredicate: self.filterPredicate
                )
            }

            loadMaxCountDisposable = (combineLatest(
                getPeerIds(.root),
                getPeerIds(Namespaces.PeerGroup.archive)
            ) |> mapToSignal { rootPeers, archivePeers in
                (context.account.postbox.getTopMessageAnchorsForPeerIds(
                    peerIds: rootPeers + archivePeers,
                    namespace: Namespaces.Message.Cloud)
                                          |> take(1)
                                          |> mapToSignal { topAnchors in
                    return context.account.postbox.aroundAggregatedMessageHistoryViewForPeerIds(
                        peerIds: Array(topAnchors.keys),
                        anchorIndices: topAnchors,
                        filterOlderThanIndices: filterBefore,
                        selectionOptions: MessageHistorySelectionOptions(boundAnchor: self.pageAnchor, direction: .newerMessages, range: .fromEnd),
                        messageCount: messagesPerPage,
                        clipHoles: true
                    ) |> map {
                        ($0, topAnchors)
                    }
                })
            } |> deliverOn(queue)
              |> take(1)
            )
            .startStrict(next: { [weak self] (view, topAnchors) in
                guard let self = self else { return }
                var updatedAnchors: [PeerId: MessageIndex] = [:]
                
                var oldestMessageByPeer: [PeerId: MessageIndex] = [:]
                for entry in view.0.entries {
                    let peerId = entry.message.id.peerId
                    if let existing = oldestMessageByPeer[peerId] {
                        if entry.index < existing {
                            oldestMessageByPeer[peerId] = entry.index
                        }
                    } else {
                        oldestMessageByPeer[peerId] = entry.index
                    }
                }
                
                for (peerId, messageIndex) in oldestMessageByPeer {
                    updatedAnchors[peerId] = messageIndex
                }
                
                let sortedEntries = view.0.entries.sorted(by: { $0.index < $1.index })
                
                if let oldestMessage = sortedEntries.first {
                    self.pageAnchor = oldestMessage.index
                }
                
                self.currentAnchors = updatedAnchors
                self.updateHistoryViewRequest()
                
                self.loadingActionDisposable?.dispose()
                self.loadingActionDisposable = (
                    (self.historyViewStream.signal())
                    |> take(1)
                )
                .start(next: { [weak self] view in
                    self?.loadingActionPromise.set(.loadingEnded(isLoadAll: true))
                })
                
                
                let markAsRead = self.context.currentDahlSettings.with { $0 }.wallSettings.markAsRead

                if markAsRead {
                    for (peerId, index) in topAnchors {
                        let location = ChatLocation.peer(id: peerId)
                        let contextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
                        self.context.applyMaxReadIndex(
                            for: location,
                            contextHolder: contextHolder,
                            messageIndex: index
                        )
                    }
                }
            })
        }
        
        func markAllMessagesRead(olderThan threshold: MessageIndex) {
            let markAsRead = self.context.currentDahlSettings.with { $0 }.wallSettings.markAsRead
            guard markAsRead else {
                return
            }
            
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
            let markAsRead = self.context.currentDahlSettings.with { $0 }.wallSettings.markAsRead
            guard markAsRead else {
                return
            }
            
            if view.entries.count == 1, let entry = view.entries.first {
                let location = ChatLocation.peer(id: entry.message.id.peerId)
                let contextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
                
                self.context.applyMaxReadIndex(
                    for: location,
                    contextHolder: contextHolder,
                    messageIndex: entry.message.index
                )
            } else if view.entries.count > 1 {
                var currentGroupKey: Int64? = nil
                var isMultipleGroups = false
                
                for entryIndex in (0..<view.entries.count).reversed() {
                    let entry = view.entries[entryIndex]
                    let groupKey = entry.message.groupingKey
                    
                    if groupKey == nil {
                        isMultipleGroups = true
                        break
                    }
                    
                    if currentGroupKey == nil {
                        currentGroupKey = groupKey
                    }
                    else if currentGroupKey != groupKey {
                        isMultipleGroups = true
                        break
                    }
                }
                
                if !isMultipleGroups && currentGroupKey != nil {
                    if let latestEntry = view.entries.first {
                        let location = ChatLocation.peer(id: latestEntry.message.id.peerId)
                        let contextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
                        
                        self.context.applyMaxReadIndex(
                            for: location,
                            contextHolder: contextHolder,
                            messageIndex: latestEntry.message.index
                        )
                    }
                }
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
        
        private func updateHistoryViewRequest(takeLatestEntries: Bool = false) {
            guard let currentAnchors = self.currentAnchors, let filterBefore = self.filterBefore else {
                return
            }
            
            self.historyViewDisposable?.dispose()
            
            #if DEBUG
            let previousEntryCount = self.mergedHistoryView?.entries.count ?? 0
            
            if let mergedHistoryView, !mergedHistoryView.entries.isEmpty {
                if let pageAnchor = self.pageAnchor, let currentMessageIndex = self.currentMessageIndex {
                    let pageAnchorPositions = mergedHistoryView.entries.enumerated()
                        .filter { $0.element.index >= pageAnchor }
                        .prefix(1)
                        .map { $0.offset }
                    
                    let currentMessageIndexPositions = mergedHistoryView.entries.enumerated()
                        .filter { $0.element.index >= currentMessageIndex }
                        .prefix(1)
                        .map { $0.offset }
                    
                    print("📌📌📌 PAGE ANCHOR BEFORE REQUEST: \(pageAnchor)")
                    print("📌📌📌 Position in list before request: \(pageAnchorPositions.first.map { "[\($0)]" } ?? "not found")/\(mergedHistoryView.entries.count) \(currentMessageIndexPositions.first.map { "[\($0)]" } ?? "not found") ")
                }
            }
            #endif

            isLoadingHistoryViewInProgress = true
            self.historyViewDisposable = (
                (
                    context.account.postbox.aroundAggregatedMessageHistoryViewForPeerIds(
                        peerIds: Array(currentAnchors.keys),
                        anchorIndices: currentAnchors,
                        filterOlderThanIndices: filterBefore,
                        selectionOptions: MessageHistorySelectionOptions(boundAnchor: self.pageAnchor, direction: takeLatestEntries ? .olderMessages : .newerMessages, range: takeLatestEntries ? .fromEnd : .fromBeginning),
                        messageCount: self.messagesPerPage,
                        clipHoles: true
                    )
                    |> distinctUntilChanged(isEqual: areHistoryViewsEqual)
                    |> deliverOn(self.queue)
                )
            )
            .start(next: { [weak self] result in
                guard let self = self else { return }
                self.isLoadingHistoryViewInProgress = false
                let (view, _, _) = result
                
                var updateType: ViewUpdateType = .Generic
                
                if self.mergedHistoryView == nil || self.mergedHistoryView?.entries.isEmpty == true  {
                    updateType = .Initial
                } else if let oldView = self.mergedHistoryView {
                    let oldMessageIds = Set(oldView.entries.map { $0.message.id })
                    let newMessageIds = Set(view.entries.map { $0.message.id })
                    
                    let added = !newMessageIds.subtracting(oldMessageIds).isEmpty
                    let removed = !oldMessageIds.subtracting(newMessageIds).isEmpty
                    
                    var positionsChanged = false
                    if !added && !removed && oldMessageIds.count == newMessageIds.count {
                        for (index, entry) in oldView.entries.enumerated() {
                            if index < view.entries.count && entry.message.id != view.entries[index].message.id {
                                positionsChanged = true
                                break
                            }
                        }
                    }
                    
                    if added || removed || positionsChanged {
                        updateType = .FillHole
                    }
                } else {
                    updateType = .FillHole
                }
                
                #if DEBUG
                print("📌📌📌 HISTORY VIEW LOADED: \(view.entries.count) entries =====")
                
                let newCount = view.entries.count
                let diff = newCount - previousEntryCount
                
                if let oldView = self.mergedHistoryView {
                    let oldMessageIds = Set(oldView.entries.map { $0.message.id })
                    let newMessageIds = Set(view.entries.map { $0.message.id })
                    
                    let addedIds = newMessageIds.subtracting(oldMessageIds)
                    let removedIds = oldMessageIds.subtracting(newMessageIds)
                    
                    print("📌📌📌 ENTRIES CHANGES: total diff \(diff > 0 ? "+" : "")\(diff), added \(addedIds.count), removed \(removedIds.count)")
                    print("📌📌📌 UPDATE TYPE: \(updateType)")
                } else {
                    print("📌📌📌 ENTRIES CHANGES: initial load of \(newCount) entries")
                    print("📌📌📌 UPDATE TYPE: \(updateType) (initial load)")
                }

                if !view.entries.isEmpty {
                    if let pageAnchor = self.pageAnchor, let currentMessageIndex = self.currentMessageIndex {
                        let pageAnchorPositions = view.entries.enumerated()
                            .filter { $0.element.index >= pageAnchor }
                            .prefix(1)
                            .map { $0.offset }
                        
                        let currentMessageIndexPositions = view.entries.enumerated()
                            .filter { $0.element.index >= currentMessageIndex }
                            .prefix(1)
                            .map { $0.offset }
                        
                        print("📌📌📌 PAGE ANCHOR: \(pageAnchor)")
                        print("📌📌📌 Position in list: \(pageAnchorPositions.first.map { "[\($0)]" } ?? "not found")/\(view.entries.count) \(currentMessageIndexPositions.first.map { "[\($0)]" } ?? "not found") ")
                    }
                }
                #endif

                print("📌📌📌 Last item in view: \(view.entries.last?.message.text ?? "not found") ")

                self.historyViewStream.putNext((view, updateType: updateType))
                self.mergedHistoryView = view
                self.checkAndMarkAsReadIfNeeded(view: view)
            })
        }
        
        private func updateAnchorsForPagination(from view: MessageHistoryView, direction: ChatHistoryListLoadDirection) {
            guard let currentAnchors, view.entries.count >= messagesPerPage else {
                return
            }
            
            let centerIndex: Int
            
            switch direction {
            case .down:
                centerIndex = min(20, view.entries.count - messagesPerPage + 20)
            case .up:
                centerIndex = max(view.entries.count - 20, messagesPerPage - 20)
            }
            
            if centerIndex < view.entries.count {
                self.currentAnchors = getConsistentAnchorsForAllPeers(
                    currentEntries: view.entries,
                    peerIds: Array(currentAnchors.keys),
                    centerEntry: view.entries[centerIndex]
                )
                self.pageAnchor = view.entries[centerIndex].index
            }
        }
        
        private func getConsistentAnchorsForAllPeers(
            currentEntries: [MessageHistoryEntry],
            peerIds: [PeerId],
            centerEntry: MessageHistoryEntry?
        ) -> [PeerId: MessageIndex] {
            let centerTimestamp = centerEntry?.message.timestamp ?? Int32(Date().timeIntervalSince1970)
            
            var anchors: [PeerId: MessageIndex] = [:]
            
            for peerId in peerIds {
                let peerEntries = currentEntries.filter { $0.message.id.peerId == peerId }
                
                if let closestEntry = peerEntries.min(by: { entry1, entry2 in
                    abs(entry1.message.timestamp - centerTimestamp) < abs(entry2.message.timestamp - centerTimestamp)
                }) {
                    anchors[peerId] = closestEntry.index
                } else if let centerEntry = centerEntry {
                    anchors[peerId] = MessageIndex(
                        id: MessageId(peerId: peerId, namespace: centerEntry.index.id.namespace, id: 0),
                        timestamp: centerTimestamp
                    )
                }
            }
            
            return anchors
        }
        
        
        func loadMoreAt(messageIndex: MessageIndex, direction: ChatHistoryListLoadDirection){
            guard let currentView = self.mergedHistoryView, !currentView.entries.isEmpty, currentMessageIndex != messageIndex, !isLoadingHistoryViewInProgress else {
                return
            }

            let index = currentView.entries.firstIndex { $0.index == messageIndex } ?? 0
            debugPrint("📌📌📌 Load More At: \(index) \(currentView.entries[index].message.text)")

            if direction == .down && index > messagesPerPage / 2 {
                currentMessageIndex = messageIndex
                updateAnchorsForPagination(from: currentView, direction: direction)
                updateHistoryViewRequest(takeLatestEntries: false)
            } else if direction == .up && index < messagesPerPage / 2 {
                currentMessageIndex = messageIndex
                updateAnchorsForPagination(from: currentView, direction: direction)
                updateHistoryViewRequest(takeLatestEntries: true)
            }
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


private func areHistoryViewsEqual(_ lhs: (MessageHistoryView, ViewUpdateType, InitialMessageHistoryData?),
                                  _ rhs: (MessageHistoryView, ViewUpdateType, InitialMessageHistoryData?)) -> Bool {
    if lhs.1 != rhs.1 {
        return false
    }
    
    if lhs.0.entries.count != rhs.0.entries.count {
        return false
    }
    
    for i in 0..<lhs.0.entries.count {
        let lhsEntry = lhs.0.entries[i]
        let rhsEntry = rhs.0.entries[i]
        
        if lhsEntry.index != rhsEntry.index {
            return false
        }
        
        if lhsEntry.location != rhsEntry.location {
            return false
        }
        
        if lhsEntry.monthLocation != rhsEntry.monthLocation {
            return false
        }
        
        if lhsEntry.attributes != rhsEntry.attributes {
            return false
        }
        
        let lhsMsg = lhsEntry.message
        let rhsMsg = rhsEntry.message
        
        if lhsMsg.stableId != rhsMsg.stableId  {
            return false
        }
        
        if lhsMsg.id != rhsMsg.id ||
            lhsMsg.timestamp != rhsMsg.timestamp ||
            lhsMsg.flags != rhsMsg.flags {
            return false
        }
        
        if lhsMsg.text != rhsMsg.text {
            return false
        }
        
        if lhsMsg.tags != rhsMsg.tags ||
            lhsMsg.globalTags != rhsMsg.globalTags ||
            lhsMsg.localTags != rhsMsg.localTags {
            return false
        }
        
        if lhsMsg.customTags.count != rhsMsg.customTags.count {
            return false
        }
        
        for j in 0..<lhsMsg.customTags.count {
            if lhsMsg.customTags[j] != rhsMsg.customTags[j] {
                return false
            }
        }
        
        if lhsMsg.attributes.count != rhsMsg.attributes.count {
            return false
        }
        
        if lhsMsg.media.count != rhsMsg.media.count {
            return false
        }
        
        if let lhsThreadInfo = lhsMsg.associatedThreadInfo,
           let rhsThreadInfo = rhsMsg.associatedThreadInfo {
            if lhsThreadInfo.title != rhsThreadInfo.title ||
                lhsThreadInfo.icon != rhsThreadInfo.icon ||
                lhsThreadInfo.iconColor != rhsThreadInfo.iconColor ||
                lhsThreadInfo.isClosed != rhsThreadInfo.isClosed {
                return false
            }
        } else if (lhsMsg.associatedThreadInfo == nil) != (rhsMsg.associatedThreadInfo == nil) {
            return false
        }
    }
    
    return true
}
