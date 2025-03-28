import Display
import UIKit
import AsyncDisplayKit
import ComponentFlow
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import UIKitRuntimeUtils
import ChatListUI

final class DWallControllerNode: ASDisplayNode {
        
    let chatController: ChatController
    let wallContent: DWallChatContent
    
    private let context: AccountContext
    private weak var controller: DWallController?
    private var presentationData: PresentationData
    
    private let containerNode: ASDisplayNode
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    private var hasValidLayout = false
    
    private var shimmerDisposable: Disposable?
    
    init(
        context: AccountContext,
        controller: DWallController
    ) {
        self.context = context
        self.controller = controller
        self.presentationData = controller.presentationData
        
        self.containerNode = ASDisplayNode()
        self.containerNode.clipsToBounds = true
        
        let navigationController = controller.navigationController as? NavigationController
        wallContent = DWallChatContent(context: context)
        chatController = context.sharedContext.makeChatController(context: context, chatLocation: .customChatContents, subject: .customChatContents(contents: wallContent), botStart: nil, mode: .standard(.default), params: nil)
        
        chatController.alwaysShowSearchResultsAsList = false
        chatController.showListEmptyResults = true
        chatController.customNavigationController = navigationController
        
        super.init()
        
        setViewBlock({
            UITracingLayerView()
        })
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        backgroundColor = presentationData.theme.chatList.backgroundColor
        
        addSubnode(containerNode)
        
        chatController.isSelectingMessagesUpdated = { [weak self] isSelecting in
            guard let self else { return }
            let button: UIBarButtonItem? = isSelecting ? UIBarButtonItem(title: presentationData.strings.Common_Cancel, style: .done, target: self, action: #selector(self.cancelPressed)) : nil
            chatController.navigationItem.setRightBarButton(button, animated: true)
        }
        
        controller.addChild(chatController)
    }
    
    deinit {
        shimmerDisposable?.dispose()
    }
    
    @objc private func cancelPressed() {
        self.chatController.cancelSelectingMessages()
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        
        self.backgroundColor = presentationData.theme.chatList.backgroundColor
    }
    
    func scrollToTop() {
        chatController.scrollToTop?()
    }
    
    private func animateContentOut() {
        chatController.contentContainerNode.layer.animateSublayerScale(from: 1.0, to: 0.95, duration: 0.3, removeOnCompletion: false)
        
        if let blurFilter = makeBlurFilter() {
            blurFilter.setValue(30.0 as NSNumber, forKey: "inputRadius")
            chatController.contentContainerNode.layer.filters = [blurFilter]
            chatController.contentContainerNode.layer.animate(from: 0.0 as NSNumber, to: 30.0 as NSNumber, keyPath: "filters.gaussianBlur.inputRadius", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.3, removeOnCompletion: false)
        }
    }
    
    private func animateContentIn() {
        chatController.contentContainerNode.layer.animateSublayerScale(from: 0.95, to: 1.0, duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring)
        
        if let blurFilter = makeBlurFilter() {
            blurFilter.setValue(0.0 as NSNumber, forKey: "inputRadius")
            chatController.contentContainerNode.layer.filters = [blurFilter]
            chatController.contentContainerNode.layer.animate(from: 30.0 as NSNumber, to: 0.0 as NSNumber, keyPath: "filters.gaussianBlur.inputRadius", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.2, removeOnCompletion: false, completion: { [weak self] completed in
                guard let self, completed else {
                    return
                }
                chatController.contentContainerNode.layer.filters = []
            })
        }
    }
    
    func requestUpdate(transition: ContainedViewLayoutTransition) {
        if let (layout, navigationHeight) = containerLayout {
            containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, transition: transition)
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let isFirstTime = containerLayout == nil
        containerLayout = (layout, navigationBarHeight)
        
        var insets = layout.insets(options: [.input])
        insets.top += navigationBarHeight
        
        if isFirstTime {
            self.insertSubnode(self.containerNode, at: 0)
        }
        
        chatController.externalSearchResultsCount = nil
        
        let topInset: CGFloat = insets.top - 46.0
        
        transition.updateFrame(node: chatController.displayNode, frame: CGRect(origin: .zero, size: layout.size))

        chatController.containerLayoutUpdated(ContainerViewLayout(
            size: layout.size,
            metrics: layout.metrics,
            deviceMetrics: layout.deviceMetrics,
            intrinsicInsets: UIEdgeInsets(
                top: topInset,
                left: layout.safeInsets.left,
                bottom: layout.intrinsicInsets.bottom,
                right: layout.safeInsets.right
            ),
            safeInsets: layout.safeInsets,
            additionalInsets: layout.additionalInsets,
            statusBarHeight: nil,
            inputHeight: layout.inputHeight,
            inputHeightIsInteractivellyChanging: false,
            inVoiceOver: false
        ), transition: transition)
        
        if chatController.displayNode.supernode == nil {
            chatController.viewWillAppear(false)
            self.containerNode.addSubnode(chatController.displayNode)
            chatController.viewDidAppear(false)
        }
            
        transition.updateFrame(node: self.containerNode, frame: CGRect(origin: .zero, size: layout.size))
        
        if !self.hasValidLayout {
            self.hasValidLayout = true
        }
    }
}
