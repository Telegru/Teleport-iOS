import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import Postbox
import SwiftSignalKit
import TelegramPresentationData
import AvatarNode
import PeerOnlineMarkerNode
import LegacyComponents
import ContextUI
import LocalizedPeerData
import AccountContext
import CheckNode
import ComponentFlow
import EmojiStatusComponent
import AnimationCache
import MultiAnimationRenderer
import TelegramUIPreferences

private let avatarFont = avatarPlaceholderFont(size: 24.0)

fileprivate final class RecentChatAvatarNode: ASDisplayNode {
    private let contextContainer: ContextControllerSourceNode
    private let avatarNodeContainer: ASDisplayNode
    private let avatarNode: AvatarNode
    private let action: (EnginePeer) -> Void

    public var contextAction: ((ASDisplayNode, ContextGesture?, CGPoint?) -> Void)? {
        didSet {
            self.contextContainer.isGestureEnabled = self.contextAction != nil
        }
    }
    
    private var currentSelected = false
    
    private var peer: EngineRenderedPeer?
    
    public init(
        action: @escaping (EnginePeer) -> Void
    ) {
        self.contextContainer = ContextControllerSourceNode()
        self.contextContainer.isGestureEnabled = false
        
        self.avatarNodeContainer = ASDisplayNode()
        
        self.avatarNode = AvatarNode(font: avatarFont)
        self.avatarNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: 32.0, height: 32.0))
        
        self.action = action
        
        super.init()
        
        self.addSubnode(self.contextContainer)
        self.avatarNodeContainer.addSubnode(self.avatarNode)
        self.contextContainer.addSubnode(self.avatarNodeContainer)
       
        self.contextContainer.activated = { [weak self] gesture, _ in
            guard let strongSelf = self, let contextAction = strongSelf.contextAction else {
                gesture.cancel()
                return
            }
            contextAction(strongSelf.contextContainer, gesture, nil)
        }
    }
    
    public func setup(context: AccountContext, theme: PresentationTheme, peer: EngineRenderedPeer, synchronousLoad: Bool) {
        self.peer = peer
        guard let mainPeer = peer.chatMainPeer else {
            return
        }
        
        var overrideImage: AvatarNodeImageOverride?
        if peer.peerId == context.account.peerId {
            overrideImage = .savedMessagesIcon
        } else if peer.peerId.isReplies {
            overrideImage = .repliesIcon
        } else if mainPeer.isDeleted {
            overrideImage = .deletedIcon
        }
        
        self.avatarNode.setPeer(
            accountPeerId: context.account.peerId,
            postbox: context.account.postbox,
            network: context.account.network,
            contentSettings: context.currentContentSettings.with { $0 },
            theme: theme,
            peer: mainPeer,
            overrideImage: overrideImage,
            emptyColor: .white,
            clipStyle:  .rect,
            synchronousLoad: synchronousLoad)
        
        self.setNeedsLayout()
    }
    
    public func updateSelection(selected: Bool, animated: Bool) {
        if selected != self.currentSelected {
            self.currentSelected = selected
            
            if selected {
                self.avatarNode.transform = CATransform3DMakeScale(0.866666, 0.866666, 1.0)
                if animated {
                    self.avatarNode.layer.animateScale(from: 1.0, to: 0.866666, duration: 0.2, timingFunction: kCAMediaTimingFunctionSpring)
                }
            } else {
                self.avatarNode.transform = CATransform3DIdentity
                if animated {
                    self.avatarNode.layer.animateScale(from: 0.866666, to: 1.0, duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring)
                }
            }
            self.setNeedsLayout()
        }
    }
    
    override public func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.action(self.peer!.peer!)
        }
    }
    
    override public func layout() {
        super.layout()
        
        let bounds = self.bounds
        
        self.contextContainer.frame = bounds
        
        self.avatarNodeContainer.frame = CGRect(
            origin: CGPoint(x: floor((bounds.size.width - 32.0) / 2.0), y: 12.0),
            size: CGSize(width: 32.0, height: 32.0))
    }
}

private let badgeFont = Font.regular(12.0)

public final class RecentChatItem: ListViewItem {
    let theme: PresentationTheme
    let context: AccountContext
    
    public let peer: EnginePeer
    let action: (EnginePeer) -> Void
    let contextAction: ((EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void)?
    let isPeerSelected: (EnginePeer.Id) -> Bool
    let customWidth: CGFloat?
    let presence: EnginePeer.Presence?
    let unreadBadge: (Int32, Bool)?
    
    public init(
        theme: PresentationTheme,
        context: AccountContext,
        peer: EnginePeer,
        presence: EnginePeer.Presence?,
        unreadBadge: (Int32, Bool)?,
        action: @escaping (EnginePeer) -> Void,
        contextAction: ((EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void)?,
        isPeerSelected: @escaping (EnginePeer.Id) -> Bool,
        customWidth: CGFloat?
    ) {
        self.theme = theme
        self.context = context
        self.peer = peer
        self.action = action
        self.contextAction = contextAction
        self.isPeerSelected = isPeerSelected
        self.customWidth = customWidth
        self.presence = presence
        self.unreadBadge = unreadBadge
    }
    
    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = RecentChatItemNode(action: self.action)
            let (nodeLayout, apply) = node.asyncLayout()(self, params)
            node.insets = nodeLayout.insets
            node.contentSize = nodeLayout.contentSize
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in
                        apply(false, synchronousLoads)
                    })
                })
            }
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            assert(node() is RecentChatItemNode)
            if let nodeValue = node() as? RecentChatItemNode {
                let layout = nodeValue.asyncLayout()
                async {
                    let (nodeLayout, apply) = layout(self, params)
                    Queue.mainQueue().async {
                        completion(nodeLayout, { _ in
                            apply(animation.isAnimated, false)
                        })
                    }
                }
            }
        }
    }
}

public final class RecentChatItemNode: ListViewItemNode {
    fileprivate var peerNode: RecentChatAvatarNode
    let badgeBackBackgroundNode: ASImageNode
    let badgeBackgroundNode: ASImageNode
    let badgeTextNode: TextNode
    
    private let action: (EnginePeer) -> Void
    
    public private(set) var item: RecentChatItem?
    
    public init(action: @escaping (EnginePeer) -> Void) {
        self.action = action
        
        self.peerNode = RecentChatAvatarNode(action: action)
        
        self.badgeBackBackgroundNode = ASImageNode()
        self.badgeBackBackgroundNode.isLayerBacked = true
        self.badgeBackBackgroundNode.displaysAsynchronously = false
        self.badgeBackBackgroundNode.displayWithoutProcessing = true
        
        self.badgeBackgroundNode = ASImageNode()
        self.badgeBackgroundNode.isLayerBacked = true
        self.badgeBackgroundNode.displaysAsynchronously = false
        self.badgeBackgroundNode.displayWithoutProcessing = true
        
        self.badgeTextNode = TextNode()
        self.badgeTextNode.isUserInteractionEnabled = false
        self.badgeTextNode.displaysAsynchronously = true
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.peerNode)
        self.addSubnode(self.badgeBackBackgroundNode)
        self.addSubnode(self.badgeBackgroundNode)
        self.addSubnode(self.badgeTextNode)
    }
    
    override public func didLoad() {
        super.didLoad()
        
        self.layer.sublayerTransform = CATransform3DMakeRotation(CGFloat.pi / 2.0, 0.0, 0.0, 1.0)
    }
    
    public func asyncLayout() -> (RecentChatItem, ListViewItemLayoutParams) -> (ListViewItemNodeLayout, (Bool, Bool) -> Void) {
        let badgeTextLayout = TextNode.asyncLayout(self.badgeTextNode)
        
        func generateBadgeBackgroud(diameter: CGFloat, color: UIColor) -> UIImage?{
            return generateImage(CGSize(width: diameter, height: diameter), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(color.cgColor)
                let rect = CGRect(origin: .zero, size: size)
                let cornerRadius: CGFloat = diameter * 0.2
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                context.addPath(path.cgPath)
                context.fillPath()
            })?.stretchableImage(withLeftCapWidth: Int(diameter / 2.0), topCapHeight: Int(diameter / 2.0))
        }

        return { [weak self] item, params in
            let itemLayout = ListViewItemNodeLayout(contentSize: CGSize(width: 56.0, height: 56.0), insets: UIEdgeInsets())
            
            let background = generateBadgeBackgroud(diameter: 18.0, color: item.theme.rootController.navigationBar.opaqueBackgroundColor.withAlphaComponent(1.0))
            
            let currentBadgeBackgroundImage: UIImage?
            let badgeAttributedString: NSAttributedString
            if let unreadBadge = item.unreadBadge {
                let badgeTextColor: UIColor
                let (unreadCount, isMuted) = unreadBadge
                if isMuted {
                    currentBadgeBackgroundImage = PresentationResourcesChatList.badgeBackgroundInactive(item.theme, diameter: 18.0)
                    badgeTextColor = item.theme.chatList.unreadBadgeInactiveTextColor
                } else {
                    currentBadgeBackgroundImage = PresentationResourcesChatList.badgeBackgroundActive(item.theme, diameter: 18.0)
                    badgeTextColor = item.theme.chatList.unreadBadgeActiveTextColor
                }
                badgeAttributedString = NSAttributedString(string: unreadCount > 0 ? "\(unreadCount)" : " ", font: badgeFont, textColor: badgeTextColor)
                
               
            } else {
                currentBadgeBackgroundImage = nil
                badgeAttributedString = NSAttributedString()
            }
            
            let (badgeLayout, badgeApply) = badgeTextLayout(TextNodeLayoutArguments(attributedString: badgeAttributedString, backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: 50.0, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            var badgeSize: CGFloat = 0.0
            if let currentBadgeBackgroundImage = currentBadgeBackgroundImage {
                badgeSize += max(currentBadgeBackgroundImage.size.width, badgeLayout.size.width + 10.0) + 5.0
            }
            
            return (itemLayout, { animated, synchronousLoads in
                if let strongSelf = self {
                    strongSelf.item = item
                   
                    strongSelf.peerNode.setup(context: item.context, theme: item.theme, peer: EngineRenderedPeer(peer: item.peer), synchronousLoad: synchronousLoads)
                    strongSelf.peerNode.frame = CGRect(origin: CGPoint(), size: itemLayout.size)
                    strongSelf.peerNode.updateSelection(selected: item.isPeerSelected(item.peer.id), animated: false)
                    
                    if let contextAction = item.contextAction {
                        strongSelf.peerNode.contextAction = { [weak item] node, gesture, location in
                            if let item = item {
                                contextAction(item.peer, node, gesture, location)
                            }
                        }
                    } else {
                        strongSelf.peerNode.contextAction = nil
                    }
                    
                    let badgeBackgroundWidth: CGFloat
                    if let currentBadgeBackgroundImage = currentBadgeBackgroundImage {
                        strongSelf.badgeBackgroundNode.image = currentBadgeBackgroundImage
                        strongSelf.badgeBackBackgroundNode.image = background
                        strongSelf.badgeBackgroundNode.isHidden = false
                        strongSelf.badgeBackBackgroundNode.isHidden = false
                        
                        badgeBackgroundWidth = max(badgeLayout.size.width + 10.0, currentBadgeBackgroundImage.size.width)
                      
                        let badgeBackgroundFrame = CGRect(
                            x: itemLayout.size.width - floorToScreenPixels(badgeBackgroundWidth * 1.2),
                            y: 56.0 - currentBadgeBackgroundImage.size.height - 6.0,
                            width: badgeBackgroundWidth,
                            height: currentBadgeBackgroundImage.size.height
                        )
                       
                        let badgeTextFrame = CGRect(origin: CGPoint(x: badgeBackgroundFrame.midX - badgeLayout.size.width / 2.0, y: badgeBackgroundFrame.minY + 2.0), size: badgeLayout.size)
                        
                        strongSelf.badgeTextNode.frame = badgeTextFrame
                        strongSelf.badgeBackgroundNode.frame = badgeBackgroundFrame
                        strongSelf.badgeBackBackgroundNode.frame = badgeBackgroundFrame
                    } else {
                        badgeBackgroundWidth = 0.0
                        strongSelf.badgeBackgroundNode.image = nil
                        strongSelf.badgeBackgroundNode.isHidden = true
                        strongSelf.badgeBackBackgroundNode.isHidden = true
                    }
                    
                    let _ = badgeApply()
                }
            })
        }
    }
    
    public func updateSelection(animated: Bool) {
        if let item = self.item {
            self.peerNode.updateSelection(selected: item.isPeerSelected(item.peer.id), animated: animated)
        }
    }
    
    override public func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        super.animateInsertion(currentTimestamp, duration: duration, options: options)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        super.animateRemoved(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
    
    override public func animateAdded(_ currentTimestamp: Double, duration: Double) {
        super.animateAdded(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
}

