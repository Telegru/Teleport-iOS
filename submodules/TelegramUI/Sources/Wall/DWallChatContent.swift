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
    
    var messageLimit: Int? {
        nil
    }
    
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
    
    func enqueueMessages(messages: [EnqueueMessage]) {}

    func deleteMessages(ids: [EngineMessage.Id]) {}
    
    func businessLinkUpdate(
        message: String,
        entities: [TelegramCore.MessageTextEntity],
        title: String?
    ) {}
    
    func editMessage(
        id: EngineMessage.Id,
        text: String,
        media: RequestEditMessageMedia,
        entities: TextEntitiesMessageAttribute?,
        webpagePreviewAttribute: WebpagePreviewMessageAttribute?,
        disableUrlPreview: Bool
    ) {}
    
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
        
        private(set) var mergedHistoryView: MessageHistoryView?
        private var historyViewDisposable: Disposable?
        private var loadingDisposable: Disposable?
        
        private var nextHistoryLocationId: Int32 = 1
        private func takeNextHistoryLocationId() -> Int32 {
            let id = self.nextHistoryLocationId
            self.nextHistoryLocationId += 5
            return id
        }
        
        private var ignoredPeerIds: Atomic<Set<PeerId>> = Atomic(value: [])
        private var sourceHistoryViews: Atomic<[PeerId: MessageHistoryView]> = Atomic(value: [:])
        
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
            self.updateHistoryViewRequest(reload: false)
            
            loadingDisposable = (isLoadingPromise.get()
                |> distinctUntilChanged)
                .startStrict(next: { [weak self] isLoading in
                    guard let self else { return }
                    if isLoading {
                        let historyView = MessageHistoryView(
                            tag: nil,
                            namespaces: .all,
                            entries: [],
                            holeEarlier: false,
                            holeLater: false,
                            isLoading: true
                        )
                        mergedHistoryView = historyView
                        historyViewStream.putNext((historyView, .Initial))
                    }
                })
        }
        
        deinit {
            self.historyViewDisposable?.dispose()
            self.loadingDisposable?.dispose()
        }
        
        func reloadData() {
            updateHistoryViewRequest(reload: true)
        }
        
        func loadMore() {
            // TODO: Load more next
        }
        
        private func updateHistoryViewRequest(reload: Bool) {
            guard self.historyViewDisposable == nil || reload else {
                return
            }
            
            self.historyViewDisposable?.dispose()
            
            self.isLoadingPromise.set(true)
            
            let context = self.context
            
            self.historyViewDisposable = (
                context.account.viewTracker.tailChatListView(
                    groupId: .root,
                    filterPredicate: filterPredicate,
                    count: tailChatsCount
                )
                |> take(1)
                |> mapToSignal { view, _ -> Signal<[PeerId], NoError> in
                    let peerIds = view.entries.compactMap { entry -> PeerId? in
                        switch entry {
                        case let .MessageEntry(entryData):
                            return (entryData.renderedPeer.peer as? TelegramChannel)?.id
                        default:
                            return nil
                        }
                    }
                    return .single(peerIds)
                }
                |> mapToSignal { peerIds -> Signal<[(PeerId, MessageHistoryView)], NoError> in
                    return combineLatest(
                        peerIds.map { peerId -> Signal<(PeerId, MessageHistoryView), NoError> in
                            var additionalData: [AdditionalMessageHistoryViewData] = []
                            additionalData.append(.cachedPeerData(peerId))
                            additionalData.append(.cachedPeerDataMessages(peerId))
                            additionalData.append(.peerNotificationSettings(peerId))
                            if [Namespaces.Peer.CloudChannel, Namespaces.Peer.CloudGroup].contains(peerId.namespace) {
                                additionalData.append(.peer(peerId))
                            }
                            if peerId.namespace == Namespaces.Peer.CloudUser || peerId.namespace == Namespaces.Peer.SecretChat {
                                additionalData.append(.peerIsContact(peerId))
                            }
                            
                            return context.account.postbox.aroundMessageHistoryViewForLocation(
                                .peer(peerId: peerId, threadId: nil),
                                anchor: .unread,
                                ignoreMessagesInTimestampRange: nil,
                                ignoreMessageIds: Set(),
                                count: 11,
                                fixedCombinedReadStates: nil,
                                topTaggedMessageIdNamespaces: Set(),
                                tag: nil,
                                appendMessagesFromTheSameGroup: false,
                                namespaces: .not(Namespaces.Message.allNonRegular),
                                orderStatistics: [],
                                additionalData: additionalData
                            )
                            |> map { update -> (PeerId, MessageHistoryView) in
                                return (peerId, update.0)
                            }
                        }
                    )
                }
                |> deliverOnMainQueue
                |> mapToSignal { [weak self] viewsAndIds -> Signal<[MessageHistoryEntry], NoError> in
                    guard let strongSelf = self else { return .complete() }
                    
                    for (peerId, view) in viewsAndIds {
                        if view.entries.contains(where: { $0.isRead }) {
                            _ = strongSelf.ignoredPeerIds.modify {
                                var updated = $0
                                updated.insert(peerId)
                                return updated
                            }
                        }
                        
                        _ = strongSelf.sourceHistoryViews.modify {
                            var dict = $0
                            dict[peerId] = view
                            return dict
                        }
                    }
                    
                    let historyViews = strongSelf.sourceHistoryViews.with { $0 }
                    guard !historyViews.isEmpty else { return .single([]) }
                    
                    return context.account.postbox.transaction { transaction -> [MessageHistoryEntry] in
                        var result = [MessageHistoryEntry]()
                        
                        for (peerId, historyView) in historyViews {
                            if let combinedState = transaction.getCombinedPeerReadState(peerId) {
                                let unreadEntries = historyView.entries.filter { entry in
                                    return !combinedState.isIncomingMessageIndexRead(entry.message.index)
                                }
                                result.append(contentsOf: unreadEntries)
                            } else {
                                result.append(contentsOf: historyView.entries)
                            }
                        }
                        
                        result.sort(by: { $0.message.index > $1.message.index })
                        
                        return result
                    }
                }
                |> deliverOnMainQueue
            )
            .start(next: { [weak self] allEntries in
                guard let self = self else { return }
                
                let historyViews = self.sourceHistoryViews.with { $0 }
                guard let templateHistoryView = historyViews.first?.value else { return }
                
                let mergedHistoryView = MessageHistoryView(
                    tag: templateHistoryView.tag,
                    namespaces: templateHistoryView.namespaces,
                    entries: allEntries,
                    holeEarlier: false,
                    holeLater: templateHistoryView.holeLater,
                    isLoading: false
                )
                
                self.mergedHistoryView = mergedHistoryView
                self.historyViewStream.putNext((mergedHistoryView, .FillHole))
                
                self.isLoadingPromise.set(false)
            })
        }
    }
}
