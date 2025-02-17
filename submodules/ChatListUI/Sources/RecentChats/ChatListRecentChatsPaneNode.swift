import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import PresentationDataUtils
import AccountContext
import MergeLists
import ItemListUI
import ContextUI
import ContactListUI
import ContactsPeerItem
import PhotoResources
import TelegramUIPreferences
import UniversalMediaPlayer
import TelegramBaseController
import OverlayStatusController
import ListMessageItem
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import ChatListSearchItemHeader
import PhoneNumberFormat
import InstantPageUI
import GalleryData
import AppBundle
import ShimmerEffect
import ChatListSearchRecentPeersNode
import UndoUI
import Postbox
import FetchManagerImpl
import AnimationCache
import MultiAnimationRenderer
import AvatarNode
import TPStrings

public let recentChatsPanelHeight: CGFloat = 56.0

final class ChatListRecentChatsPaneNode: ASDisplayNode {
    private let context: AccountContext
    private let animationCache: AnimationCache
    private let animationRenderer: MultiAnimationRenderer
    private var presentationData: PresentationData
    
    private let separatorNode: ASDisplayNode
    private var chatsNode: ChatListRecentChatsNode?
   
    var peerAction: ((EnginePeer) -> Void)?
    var peerContextAction: ((EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void)?

    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.animationCache = context.animationCache
        self.animationRenderer = context.animationRenderer
        self.presentationData = presentationData

        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        self.separatorNode.displaysAsynchronously = false
        self.separatorNode.backgroundColor = presentationData.theme.list.itemPlainSeparatorColor
        
        super.init()
        
        self.addSubnode(self.separatorNode)
    }
    
    func updatePresentationData(_ data: PresentationData){
        self.presentationData = data
        self.separatorNode.backgroundColor = data.theme.list.itemPlainSeparatorColor
        self.chatsNode?.updateThemeAndStrings(theme: data.theme, strings: data.strings)
    }
    
    func updtateLayout(size: CGSize, transition: ContainedViewLayoutTransition){
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: UIScreenPixel)))
        
        let chatsNode: ChatListRecentChatsNode
        if let node = self.chatsNode{
            chatsNode = node
        }else{
            chatsNode = ChatListRecentChatsNode(
                context: self.context,
                presentationData: self.presentationData,
                strings: self.presentationData.strings,
                action: {[weak self] peer in
                    self?.peerAction?(peer)
                },
                peerContextAction: {[weak self] peer, node, gesture, location in
                    self?.peerContextAction?(peer, node, gesture, location)
                })
            self.chatsNode = chatsNode
            self.addSubnode(chatsNode)
        }
        transition.updateFrame(node: chatsNode, frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: 56.0 - UIScreenPixel)))
        chatsNode.updateLayout(size: size, transition: transition)
    }
}

