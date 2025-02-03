import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import Postbox
import TelegramPresentationData
import MergeLists
import HorizontalPeerItem
import ListSectionHeaderNode
import ContextUI
import AccountContext
import TelegramUIPreferences
import AnimationCache
import MultiAnimationRenderer

private struct ChatListRecentChatsEntry: Comparable, Identifiable {
    let index: Int
    let peer: EnginePeer
    let presence: EnginePeer.Presence?
    let unreadBadge: (Int32, Bool)?
    let theme: PresentationTheme
    let strings: PresentationStrings
    var stableId: EnginePeer.Id {
        return self.peer.id
    }
    
    static func ==(lhs: ChatListRecentChatsEntry, rhs: ChatListRecentChatsEntry) -> Bool {
        if lhs.index != rhs.index {
            return false
        }
        if lhs.peer != rhs.peer {
            return false
        }
        if lhs.presence != rhs.presence {
            return false
        }
        if lhs.unreadBadge?.0 != rhs.unreadBadge?.0 {
            return false
        }
        if lhs.unreadBadge?.1 != rhs.unreadBadge?.1 {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        return true
    }
    
    static func <(lhs: ChatListRecentChatsEntry, rhs: ChatListRecentChatsEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(
        context: AccountContext,
        peerSelected: @escaping (EnginePeer) -> Void,
        peerContextAction: @escaping (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void,
        isPeerSelected: @escaping (EnginePeer.Id) -> Bool
    ) -> ListViewItem {
        return RecentChatItem(
            theme: self.theme,
            context: context,
            peer: self.peer,
            presence: self.presence,
            unreadBadge: self.unreadBadge,
            action: peerSelected,
            contextAction: { peer, node, gesture, location in
                peerContextAction(peer, node, gesture, location)
            },
            isPeerSelected: isPeerSelected,
            customWidth: 56.0
        )
    }
}

private struct ChatListRecentChatsNodeTransition {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
    let firstTime: Bool
    let animated: Bool
}

private func preparedRecentChatsTransition(
    context: AccountContext,
    peerSelected: @escaping (EnginePeer) -> Void,
    peerContextAction: @escaping (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void,
    from fromEntries: [ChatListRecentChatsEntry],
    to toEntries: [ChatListRecentChatsEntry],
    firstTime: Bool,
    animated: Bool
) -> ChatListRecentChatsNodeTransition {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map { ListViewInsertItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(
        context: context,
        peerSelected: peerSelected,
        peerContextAction: peerContextAction,
        isPeerSelected: { _ in false }
    ), directionHint: .Down) }
    let updates = updateIndices.map { ListViewUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(
        context: context,
        peerSelected: peerSelected,
        peerContextAction: peerContextAction,
        isPeerSelected: { _ in false }
    ), directionHint: nil) }
    
    return ChatListRecentChatsNodeTransition(deletions: deletions, insertions: insertions, updates: updates, firstTime: firstTime, animated: animated)
}

public final class ChatListRecentChatsNode: ASDisplayNode {
    private var theme: PresentationTheme
    private var strings: PresentationStrings
    private let themeAndStringsPromise: Promise<(PresentationTheme, PresentationStrings)>
    private let listView: ListView
  
    private let peerSelected: (EnginePeer) -> Void
    private let peerContextAction: (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void
   
    private let disposable = MetaDisposable()
  
    private var items: [ListViewItem] = []
    private var queuedTransitions: [ChatListRecentChatsNodeTransition] = []
    
    private let ready = Promise<Bool>()
    private var didSetReady: Bool = false
    public var isReady: Signal<Bool, NoError> {
        return self.ready.get()
    }
    
    public init(
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        peerSelected: @escaping (EnginePeer) -> Void, peerContextAction: @escaping (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void
    ) {
        self.theme = theme
        self.strings = strings
        self.themeAndStringsPromise = Promise((self.theme, self.strings))
        self.peerSelected = peerSelected
        self.peerContextAction = peerContextAction
        
        self.listView = ListView()
        self.listView.preloadPages = false
        self.listView.transform = CATransform3DMakeRotation(-CGFloat.pi / 2.0, 0.0, 0.0, 1.0)
        self.listView.accessibilityPageScrolledString = { row, count in
            return strings.VoiceOver_ScrollStatus(row, count).string
        }
        
        super.init()
        
        self.addSubnode(self.listView)
        
        let peersDisposable = DisposableSet()
        
        let accountPeerId = context.account.peerId
        let postbox = context.account.postbox
        
        let recent: Signal<([EnginePeer], [EnginePeer.Id: (Int32, Bool)], [EnginePeer.Id : EnginePeer.Presence]), NoError> = _internal_recentPeers(accountPeerId: accountPeerId, postbox: postbox)
        |> filter { value -> Bool in
            switch value {
                case .disabled:
                    return false
                default:
                    return true
            }
        }
        |> mapToSignal { recent in
            switch recent {
            case .disabled:
                return .single(([], [:], [:]))
            case let .peers(peers):
                return combineLatest(queue: .mainQueue(),
                    peers.filter {
                        !$0.isDeleted
                    }.map {
                        postbox.peerView(id: $0.id)
                    }
                )
                |> mapToSignal { peerViews -> Signal<([EnginePeer], [EnginePeer.Id: (Int32, Bool)], [EnginePeer.Id: EnginePeer.Presence]), NoError> in
                    return postbox.combinedView(keys: peerViews.map { item -> PostboxViewKey in
                        let key = PostboxViewKey.unreadCounts(items: [UnreadMessageCountsItem.peer(id: item.peerId, handleThreads: true)])
                        return key
                    })
                    |> map { views -> [EnginePeer.Id: Int] in
                        var result: [EnginePeer.Id: Int] = [:]
                        for item in peerViews {
                            let key = PostboxViewKey.unreadCounts(items: [UnreadMessageCountsItem.peer(id: item.peerId, handleThreads: true)])
                            
                            if let view = views.views[key] as? UnreadMessageCountsView {
                                result[item.peerId] = Int(view.count(for: .peer(id: item.peerId, handleThreads: true)) ?? 0)
                            } else {
                                result[item.peerId] = 0
                            }
                        }
                        return result
                    }
                    |> map { unreadCounts in
                        var peers: [EnginePeer] = []
                        var unread: [EnginePeer.Id: (Int32, Bool)] = [:]
                        var presences: [EnginePeer.Id: EnginePeer.Presence] = [:]
                        for peerView in peerViews {
                            if let peer = peerViewMainPeer(peerView) {
                                var isMuted: Bool = false
                                if let notificationSettings = peerView.notificationSettings as? TelegramPeerNotificationSettings {
                                    switch notificationSettings.muteState {
                                    case .muted:
                                        isMuted = true
                                    default:
                                        break
                                    }
                                }
                                
                                let unreadCount = unreadCounts[peerView.peerId]
                                if let unreadCount, unreadCount > 0 {
                                    unread[peerView.peerId] = (Int32(unreadCount), isMuted)
                                }
                                
                                if let presence = peerView.peerPresences[peer.id] {
                                    presences[peer.id] = EnginePeer.Presence(presence)
                                }
                                
                                peers.append(EnginePeer(peer))
                            }
                        }
                        return (peers, unread, presences)
                    }
                }
            }
        }
        
        let previous: Atomic<[ChatListRecentChatsEntry]> = Atomic(value: [])
        let firstTime:Atomic<Bool> = Atomic(value: true)
        peersDisposable.add((combineLatest(queue: .mainQueue(), recent,  self.themeAndStringsPromise.get()) |> deliverOnMainQueue).startStrict(next: { [weak self] peers, themeAndStrings in
            if let strongSelf = self {
                var entries: [ChatListRecentChatsEntry] = []
                for peer in peers.0 {
                    entries.append(
                        ChatListRecentChatsEntry(
                            index: entries.count,
                            peer: peer,
                            presence: peers.2[peer.id],
                            unreadBadge: peers.1[peer.id],
                            theme: themeAndStrings.0,
                            strings: themeAndStrings.1)
                    )
                }
                
                let animated = !firstTime.swap(false)
                
                let transition = preparedRecentChatsTransition(
                    context: context,
                    peerSelected: peerSelected,
                    peerContextAction: peerContextAction,
                    from: previous.swap(entries),
                    to: entries,
                    firstTime: !animated,
                    animated: animated
                )

                strongSelf.enqueueTransition(transition)
            }
        }))
       
        self.disposable.set(peersDisposable)
    }
    
    private func enqueueTransition(_ transition: ChatListRecentChatsNodeTransition) {
        self.queuedTransitions.append(transition)
        self.dequeueTransitions()
    }
    
    private func dequeueTransitions() {
        while !self.queuedTransitions.isEmpty {
            let transition = self.queuedTransitions.removeFirst()
            
            var options = ListViewDeleteAndInsertOptions()
            if transition.firstTime {
                options.insert(.PreferSynchronousResourceLoading)
                options.insert(.PreferSynchronousDrawing)
                options.insert(.Synchronous)
                options.insert(.LowLatency)
            } else if transition.animated {
                options.insert(.AnimateInsertion)
            }
            self.listView.transaction(deleteIndices: transition.deletions, insertIndicesAndItems: transition.insertions, updateIndicesAndItems: transition.updates, options: options, updateOpaqueState: nil, completion: { [weak self] _ in
                guard let self else {
                    return
                }
                if !self.didSetReady {
                    self.ready.set(.single(true))
                    self.didSetReady = true
                }
                if !self.listView.preloadPages {
                    Queue.mainQueue().after(0.5) {
                        self.listView.preloadPages = true
                    }
                }
            })
        }
    }
    
    deinit {
        self.disposable.dispose()
    }
    
    public func updateThemeAndStrings(theme: PresentationTheme, strings: PresentationStrings) {
        if self.theme !== theme || self.strings !== strings {
            self.theme = theme
            self.strings = strings
            self.themeAndStringsPromise.set(.single((self.theme, self.strings)))
        }
    }
    
    override public func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: 86.0)
    }
    
    public func updateLayout(size: CGSize, leftInset: CGFloat, rightInset: CGFloat) {
        var insets = UIEdgeInsets()
        insets.top += leftInset
        insets.bottom += rightInset
        
        self.listView.bounds = CGRect(x: 0.0, y: 0.0, width: 56.0, height: size.width)
        self.listView.position = CGPoint(x: size.width / 2.0, y: 56.0 / 2.0)
        self.listView.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous], scrollToItem: nil, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: CGSize(width: 56.0, height: size.width), insets: insets, duration: 0.0, curve: .Default(duration: nil)), stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
    }
    
    public func viewAndPeerAtPoint(_ point: CGPoint) -> (UIView, EnginePeer.Id)? {
        let adjustedPoint = self.view.convert(point, to: self.listView.view)
        var selectedItemNode: ASDisplayNode?
        self.listView.forEachItemNode { itemNode in
            if itemNode.frame.contains(adjustedPoint) {
                selectedItemNode = itemNode
            }
        }
        if let selectedItemNode = selectedItemNode as? HorizontalPeerItemNode, let peer = selectedItemNode.item?.peer {
            return (selectedItemNode.view, peer.id)
        }
        return nil
    }
}
