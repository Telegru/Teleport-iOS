import Foundation
import UIKit
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import ChatListUI

final class DWallChatContent: ChatCustomContentsProtocol {
    
    var kind: ChatCustomContentsKind
    
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
        self.kind = .wall
        
        let queue = Queue()
        self.queue = queue
        self.impl = QueueLocalObject(queue: queue, generate: {
            return Impl(queue: queue, context: context)
        })
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
        
        private(set) var mergedHistoryView: MessageHistoryView?
        private var sourceHistoryView: MessageHistoryView?
        private var historyViewDisposable: Disposable?
        private var channelsDisposable: Disposable?
        
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
        
        func loadMore() {}
        
        private func updateHistoryViewRequest(reload: Bool) {
            guard self.historyViewDisposable == nil || reload else {
                return
            }
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
            
            channelsDisposable = (self.context.account.viewTracker.tailChatListView(
                groupId: .root,
                filterPredicate: filterPredicate,
                count: 100
            )
            |> deliverOnMainQueue
            |> take(1)
            |> mapToSignal { view, _ -> Signal<[TelegramChannel], NoError> in
                return .single(view.entries.compactMap { entry -> TelegramChannel? in
                    switch entry {
                    case let .MessageEntry(entryData):
                        return entryData.renderedPeer.peer as? TelegramChannel
                    default:
                        return nil
                    }
                })
            }
//                                  |> mapToSignal { [weak self] channels -> Signal<[IntermediateMessage], NoError> in
//                guard let self else { return .single([])}
//                
//                return (combineLatest(channels.compactMap {
//                    guard let associatedMessageId = self.context.account.postbox.cachedPeerDataTable.get($0.peerId)?.associatedHistoryMessageId else {
//                        return nil
//                    }
//                    
//                    // TODO: Get indexes
//                    return self.context.account.postbox.messageHistoryTable.fetch(
//                        peerId: associatedMessageId.peerId,
//                        namespace: associatedMessageId.namespace,
//                        tag: nil,
//                        customTag: nil,
//                        threadId: nil,
//                        from: .absoluteUpperBound().withPeerId(associatedMessageId.peerId).withNamespace(associatedMessageId.namespace),
//                        includeFrom: true,
//                        to: .absoluteLowerBound().withPeerId(associatedMessageId.peerId).withNamespace(associatedMessageId.namespace),
//                        ignoreMessagesInTimestampRange: nil,
//                        ignoreMessageIds: [],
//                        limit: 10
//                    )
//                })
//                |> map { messages in
//                    messages.flatMap { $0 }
//                })
//            }
            )
            .start(next: { channels in
                for channel in channels {
                    print("🚀", channel.title)
                }
            })
            
//            self.context.engine.messages.
//             TODO: Get messages
        }
        
        private func updateHistoryView(updateType: ViewUpdateType) {
            var entries = sourceHistoryView?.entries ?? []
            entries.sort(by: {
                $0.message.index < $1.message.index
            })
            
            let mergedHistoryView = MessageHistoryView(tag: nil, namespaces: .just(Set([Namespaces.Message.Cloud])), entries: entries, holeEarlier: self.sourceHistoryView?.holeEarlier ?? false, holeLater: false, isLoading: false)
            self.mergedHistoryView = mergedHistoryView
            
            self.historyViewStream.putNext((mergedHistoryView, updateType))
        }
    }
}
