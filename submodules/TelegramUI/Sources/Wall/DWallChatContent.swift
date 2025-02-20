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
        
        private var nextHistoryLocationId: Int32 = 1
        private func takeNextHistoryLocationId() -> Int32 {
            let id = self.nextHistoryLocationId
            self.nextHistoryLocationId += 5
            return id
        }
        
        private var ignoredPeerIds: Atomic<Set<PeerId>> = Atomic(value: [])
        private var initialAnchorsDisposable: Disposable?
        private var readViewDisposable: Disposable?
        
        var sourceHistoryViews: Atomic<[PeerId: MessageHistoryView]> = Atomic(value: [:])
        private var count = 44
        
        // Новое свойство для хранения предыдущего списка анкеров
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
            
            loadingDisposable = (isLoadingPromise.get()
                |> distinctUntilChanged)
                .startStrict(next: { [weak self] isLoading in
                    guard let self = self else { return }
                    if isLoading {
                        let historyView = MessageHistoryView(
                            tag: nil,
                            namespaces: .all,
                            entries: [],
                            holeEarlier: false,
                            holeLater: false,
                            isLoading: true
                        )
                        self.mergedHistoryView = historyView
                        self.historyViewStream.putNext((historyView, .Initial))
                    }
                })
            
            // Непрерывное отслеживание анкеров
            self.initialAnchorsDisposable = (context.account.viewTracker.tailChatListView(
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
            |> mapToSignal { peerIds -> Signal<[PeerId: MessageIndex], NoError> in
                return context.account.postbox.oldestUnreadMessagesForPeerIds(
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
                var updateNeeded = false
                if let previous = self.previousAnchors {
                    // Определяем набор ключей предыдущих анкеров
                    let previousKeys = Set(previous.keys)
                    // Если в новом наборе есть пир, которого раньше не было, значит для него раньше было nil
                    let newKeys = Set(anchors.keys)
                    if !newKeys.isSubset(of: previousKeys) {
                        updateNeeded = true
                    }
                    // Для пиров, которые уже присутствуют, изменения их значений игнорируем, даже если они изменились,
                    // поскольку в процессе скролла сообщения помечаются прочитанными и анкеры могут обновляться.
                } else {
                    updateNeeded = true
                }
                
                if updateNeeded {
                    // При появлении нового пира инициируем полную перезагрузку
                    self.updateHistoryViewRequest(anchors: anchors, reload: true, showLoading: true)
                }
                self.previousAnchors = anchors
            })
            
            self.isLoadingPromise.set(false)
            // Первоначальный вызов загрузки производится через обновление анкеров из потока выше
        }
        
        deinit {
            self.historyViewDisposable?.dispose()
            self.loadingDisposable?.dispose()
            self.initialAnchorsDisposable?.dispose()
            self.readViewDisposable?.dispose()
        }
        
        func reloadData() {
            // Если требуется полная перезагрузка, можно использовать текущее состояние анкеров
            if let anchors = self.previousAnchors {
                updateHistoryViewRequest(anchors: anchors, reload: true, showLoading: true)
            }
        }
        
        func loadMore() {
            if let anchors = self.previousAnchors {
                updateHistoryViewRequest(anchors: anchors, reload: false, showLoading: false)
            }
        }
        
        func loadAll() {
            count = 8800
            if let anchors = self.previousAnchors {
                updateHistoryViewRequest(anchors: anchors, reload: false, showLoading: true)
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
        
        // Изменённый метод, принимающий актуальные анкеры в качестве параметра
        private func updateHistoryViewRequest(anchors: [PeerId: MessageIndex], reload: Bool, showLoading: Bool = false) {
            self.historyViewDisposable?.dispose()
            if reload {
                // При полном обновлении сбрасываем счётчик
                self.count = 44
            }
            if showLoading {
                self.isLoadingPromise.set(true)
            }
            
            let context = self.context
            
            self.historyViewDisposable = (context.account.postbox.aggregatedGlobalMessagesHistoryViewForPeerIds(
                peerIds: Array(anchors.keys),
                from: anchors,
                count: self.count,
                clipHoles: false,
                namespaces: Namespaces.Message.Cloud
            )
            |> deliverOnMainQueue)
            .start(next: { [weak self] view in
                guard let self = self else { return }
                
                let updateType: ViewUpdateType = (self.mergedHistoryView?.entries.isEmpty == true) ? .UpdateVisible : .FillHole
                
                self.isLoadingPromise.set(false)
                self.mergedHistoryView = view
                self.historyViewStream.putNext((view, updateType))
                self.count += 44
            })
        }
    }
}
