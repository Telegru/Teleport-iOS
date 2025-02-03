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
    
    private let emptyRecentTextNode: ImmediateTextNode
    private let separatorNode: ASDisplayNode
    private let chatsNode: ChatListRecentChatsNode
    
   
//    let peerSelected: (EnginePeer) -> Void
//    let peerContextAction: (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void
// 
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.animationCache = context.animationCache
        self.animationRenderer = context.animationRenderer
        self.presentationData = presentationData
        
        let emptyRecentTextNode = ImmediateTextNode()
        emptyRecentTextNode.displaysAsynchronously = false
        emptyRecentTextNode.maximumNumberOfLines = 0
        emptyRecentTextNode.textAlignment = .center
        emptyRecentTextNode.verticalAlignment = .middle
        emptyRecentTextNode.isHidden = false
        emptyRecentTextNode.attributedText = NSAttributedString(string: "Chat.EmptyRecent".tp_loc(lang: presentationData.strings.baseLanguageCode), font: Font.semibold(13.0), textColor: presentationData.theme.list.itemSecondaryTextColor)
        
        self.emptyRecentTextNode = emptyRecentTextNode

        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        self.separatorNode.displaysAsynchronously = false
        self.separatorNode.backgroundColor = presentationData.theme.list.itemPlainSeparatorColor
        
        self.chatsNode = ChatListRecentChatsNode(
            context: context,
            theme: presentationData.theme,
            strings: presentationData.strings,
            peerSelected: { peer in
                
            },
            peerContextAction: { peer, node, gesture, location in
                
            })
        
        super.init()
        
        self.addSubnode(emptyRecentTextNode)
        self.addSubnode(self.chatsNode)
        self.addSubnode(separatorNode)
       
    }
    
    func updatePresentationData(_ data: PresentationData){
        self.presentationData = data
        self.emptyRecentTextNode.attributedText = NSAttributedString(string: "Chat.EmptyRecent".tp_loc(lang: data.strings.baseLanguageCode), font: Font.regular(15.0), textColor: data.theme.list.itemSecondaryTextColor)
        
        self.separatorNode.backgroundColor = data.theme.list.itemPlainSeparatorColor
        self.chatsNode.updateThemeAndStrings(theme: data.theme, strings: data.strings)
    }
    
    func updtateLayout(size: CGSize, transition: ContainedViewLayoutTransition){
        _ = emptyRecentTextNode.updateLayout(CGSize(width: size.width, height: 56.0))
        transition.updateFrame(node: self.emptyRecentTextNode, frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: 56.0)))
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: UIScreenPixel)))
        transition.updateFrame(node: self.chatsNode, frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: 56.0)))
        self.chatsNode.updateLayout(size: size, leftInset: .zero, rightInset: .zero)
    }
}

