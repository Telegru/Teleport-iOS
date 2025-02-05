import Display
import UIKit
import AsyncDisplayKit
import ComponentFlow
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import UIKitRuntimeUtils

final class DWallControllerNode: ASDisplayNode {
    
    private let context: AccountContext
    private weak var controller: DWallController?
    private var presentationData: PresentationData
    
    let chatController: ChatController
    let wallContent: DWallChatContent
    
    private let navigationBar: NavigationBar?
    
    private let containerNode: ASDisplayNode
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    private var hasValidLayout = false
    
    init(
        context: AccountContext,
        controller: DWallController,
        navigationBar: NavigationBar?,
        navigationController: NavigationController?
    ) {
        self.context = context
        self.controller = controller
        self.navigationBar = navigationBar
        self.presentationData = controller.presentationData
        
        self.containerNode = ASDisplayNode()
        
        let navigationController = controller.navigationController as? NavigationController
        self.wallContent = DWallChatContent(context: context)
        self.chatController = context.sharedContext.makeChatController(context: context, chatLocation: .customChatContents, subject: .customChatContents(contents: wallContent), botStart: nil, mode: .standard(.default), params: nil)
        self.chatController.alwaysShowSearchResultsAsList = false
        self.chatController.showListEmptyResults = true
        self.chatController.customNavigationController = navigationController
        
        super.init()
        
        self.setViewBlock({
            UITracingLayerView()
        })
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
        
        self.addSubnode(self.containerNode)
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
    }
    
    func scrollToTop() {
        chatController.scrollToTop?()
    }
    
    private func animateContentOut() {
        let controller = self.chatController
        controller.contentContainerNode.layer.animateSublayerScale(from: 1.0, to: 0.95, duration: 0.3, removeOnCompletion: false)
        
        if let blurFilter = makeBlurFilter() {
            blurFilter.setValue(30.0 as NSNumber, forKey: "inputRadius")
            controller.contentContainerNode.layer.filters = [blurFilter]
            controller.contentContainerNode.layer.animate(from: 0.0 as NSNumber, to: 30.0 as NSNumber, keyPath: "filters.gaussianBlur.inputRadius", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.3, removeOnCompletion: false)
        }
    }
    
    private func animateContentIn() {
        let controller = self.chatController
        controller.contentContainerNode.layer.animateSublayerScale(from: 0.95, to: 1.0, duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring)
        
        if let blurFilter = makeBlurFilter() {
            blurFilter.setValue(0.0 as NSNumber, forKey: "inputRadius")
            controller.contentContainerNode.layer.filters = [blurFilter]
            controller.contentContainerNode.layer.animate(from: 30.0 as NSNumber, to: 0.0 as NSNumber, keyPath: "filters.gaussianBlur.inputRadius", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.2, removeOnCompletion: false, completion: { [weak controller] completed in
                guard let controller, completed else {
                    return
                }
                controller.contentContainerNode.layer.filters = []
            })
        }
    }
    
    func requestUpdate(transition: ContainedViewLayoutTransition) {
        if let (layout, navigationHeight) = self.containerLayout {
            let _ = self.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, transition: transition)
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) -> CGFloat {
        let isFirstTime = self.containerLayout == nil
        self.containerLayout = (layout, navigationBarHeight)
        
        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight
        
        let toolbarHeight: CGFloat = 40.0
        insets.top += toolbarHeight - 4.0
        
        if isFirstTime {
            self.insertSubnode(self.containerNode, at: 0)
        }
        
        chatController.externalSearchResultsCount = nil
        
        let topInset: CGFloat = insets.top - 79.0
        transition.updateFrame(node: chatController.displayNode, frame: CGRect(origin: .zero, size: layout.size))

        chatController.containerLayoutUpdated(ContainerViewLayout(size: layout.size, metrics: layout.metrics, deviceMetrics: layout.deviceMetrics, intrinsicInsets: UIEdgeInsets(top: topInset, left: layout.safeInsets.left, bottom: layout.intrinsicInsets.bottom, right: layout.safeInsets.right), safeInsets: layout.safeInsets, additionalInsets: layout.additionalInsets, statusBarHeight: nil, inputHeight: layout.inputHeight, inputHeightIsInteractivellyChanging: false, inVoiceOver: false), transition: transition)
        
        if chatController.displayNode.supernode == nil {
            chatController.viewWillAppear(false)
            self.containerNode.addSubnode(chatController.displayNode)
            chatController.viewDidAppear(false)
        }
        
        if !self.hasValidLayout {
            self.hasValidLayout = true
        }
        
        return toolbarHeight
    }
}
