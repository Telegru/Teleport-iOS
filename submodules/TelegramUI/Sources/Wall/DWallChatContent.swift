import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import ChatListUI

final class DWallChatContent: ChatCustomContentsProtocol {
    
    let kind: ChatCustomContentsKind = .wall
    
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
        self.impl = QueueLocalObject(queue: queue, generate: {
            return Impl(queue: queue, context: context)
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
        
        private(set) var mergedHistoryView: MessageHistoryView?
        private var historyViewDisposable: Disposable?
        
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
            context: AccountContext
        ) {
            self.queue = queue
            self.context = context
            
            self.updateHistoryViewRequest(reload: false)
        }
        
        deinit {
            self.historyViewDisposable?.dispose()
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
            
            let context = self.context
            self.historyViewDisposable?.dispose()
            
            let accountPeerId = context.account.peerId
            
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
            let filterPredicate = chatListFilterPredicate(filter: filterData, accountPeerId: accountPeerId)
            
            isLoadingPromise.set(true)
            
            historyViewDisposable = (self.context.account.viewTracker.tailChatListView(
                groupId: .root,
                filterPredicate: filterPredicate,
                count: 100
            )
            |> take(1)
            |> mapToSignal { view, _ -> Signal<[PeerId], NoError> in
                return .single(view.entries.compactMap { entry -> PeerId? in
                    switch entry {
                    case let .MessageEntry(entryData):
                        return (entryData.renderedPeer.peer as? TelegramChannel)?.id
                    default:
                        return nil
                    }
                })
            } |> mapToSignal { peerIds -> Signal<[(PeerId, MessageHistoryView)], NoError> in
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
                        
//                        chatHistoryViewForLocation(
//                            .init(content: .Initial(count: 11), id: self.takeNextHistoryLocationId()),
//                            ignoreMessagesInTimestampRange: nil,
//                            ignoreMessageIds: [],
//                            context: context,
//                            chatLocation: .peer(id: peerId),
//                            chatLocationContextHolder: Atomic<ChatLocationContextHolder?>(value: nil),
//                            scheduled: false,
//                            fixedCombinedReadStates: nil, tag: nil,
//                            appendMessagesFromTheSameGroup: false,
//                            additionalData: additionalData
//                        )
                        
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
                        ) |> mapToSignal { update -> Signal<(PeerId, MessageHistoryView), NoError> in
                            return .single((peerId, update.0))
                        }
                    }
                )
//            } |> filter {
//                return $0.contains {
//                    let (_, updates) = $0
//                    switch updates {
//                    case .Loading:
//                        return true
//                    default:
//                        return false
//                    }
//                }
            }
            |> deliverOnMainQueue)
            .start(next: { [weak self] viewsAndIds in
                guard let self else { return }
                self.isLoadingPromise.set(false)
                for (peerId, view) in viewsAndIds {
//                    switch update {
//                    case let .HistoryView(view, _, _, _, _, _, _):
                        if view.entries.contains(where: { $0.isRead }) {
                            _ = self.ignoredPeerIds.modify {
                                var _s = $0
                                _s.insert(peerId)
                                return _s
                            }
                        }
                        _ = self.sourceHistoryViews.modify {
                            var _d = $0
                            _d[peerId] = view
                            return _d
                        }
//                    default:
//                        break
//                    }
                }
                updateHistoryView(updateType: .Initial)
            })
        }
        
        private func updateHistoryView(updateType: ViewUpdateType) {
            let historyViews = sourceHistoryViews.with { $0 }.values
            guard !historyViews.isEmpty else { return }
            
//            var entries = mergedHistoryView?.entries ?? []
            var entries = [MessageHistoryEntry]()
            
            let newEntries = historyViews.reduce([MessageHistoryEntry]()) { result, element in
                result + element.entries.filter { !$0.isRead }
            }
            .sorted(by: {
                $0.message.index > $1.message.index
            })
            
            entries.append(contentsOf: newEntries)
            
            guard let templateHistoryView = historyViews.first else {
                return
            }
            
            let mergedHistoryView = MessageHistoryView(
                tag: templateHistoryView.tag,
                namespaces: templateHistoryView.namespaces,
                entries: entries,
                holeEarlier: false,
                holeLater: templateHistoryView.holeLater,
                isLoading: false
            )
            self.mergedHistoryView = mergedHistoryView
            
            self.historyViewStream.putNext((mergedHistoryView, updateType))
        }
    }
}
