import Foundation
import UIKit
import Display
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import TelegramBaseController
import AccountContext
import ChatListUI
import Postbox
import ListMessageItem
import AnimationCache
import MultiAnimationRenderer

public final class DWallController: TelegramBaseController {
    
    private let queue = Queue()
    
    private let context: AccountContext
    
    private var transitionDisposable: Disposable?
    
    private(set) var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private var unreadCountDisposable: Disposable?
    
    private let animationCache: AnimationCache
    private let animationRenderer: MultiAnimationRenderer
    
    private var controllerNode: DWallControllerNode {
        return self.displayNode as! DWallControllerNode
    }
    
    public init(context: AccountContext) {
        self.context = context
        
        self.animationCache = context.animationCache
        self.animationRenderer = context.animationRenderer
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(context: context, navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), mediaAccessoryPanelVisibility: .none, locationBroadcastPanelSource: .none, groupCallPanelSource: .none)
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        navigationItem.title = "Wall.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)
        tabBarItem.title = "Wall.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode)
        let icon = UIImage(bundleImageName: "Chat List/Tabs/IconWall")
        tabBarItem.image = icon
        tabBarItem.selectedImage = icon
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: self.presentationData.strings.Common_Back,
            style: .plain,
            target: nil,
            action: nil
        )
        
        self.presentationDataDisposable = (self.context.sharedContext.presentationData
                                           |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            guard let self else { return }
            
            let previousTheme = self.presentationData.theme
            let previousStrings = self.presentationData.strings
            
            self.presentationData = presentationData
            
            if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                updateThemeAndStrings()
            }
        }).strict()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: self.presentationData.strings.Common_Back,
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Wall.Reload".tp_loc(lang: presentationData.strings.baseLanguageCode),
            style: .plain,
            target: self,
            action: #selector(self.reloadPressed)
        )
        
        self.scrollToTop = { [weak self] in
            self?.controllerNode.scrollToTop()
        }
        
        setupUnreadCounterObserving()
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        presentationDataDisposable?.dispose()
        unreadCountDisposable?.dispose()
    }
    
    public override func loadDisplayNode() {
        self.displayNode = DWallControllerNode(context: self.context, controller: self)
        
        controllerNode.chatController.parentController = self
        self.displayNodeDidLoad()
    }
    
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        controllerNode.chatController.customNavigationController = self.navigationController as? NavigationController
    }
    
    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let _ = self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.cleanNavigationHeight, transition: transition)
    }
    
    private func updateThemeAndStrings() {
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        self.controllerNode.updatePresentationData(self.presentationData)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Wall.Reload".tp_loc(lang: presentationData.strings.baseLanguageCode),
            style: .plain,
            target: self,
            action: #selector(self.reloadPressed)
        )
    }
    
    private func setupUnreadCounterObserving(single: Bool = false) {
        let context = self.context

        if case let .wall(count, filter) = controllerNode.wallContent.kind {
            unreadCountDisposable?.dispose()
            unreadCountDisposable = nil
            
            let unreadCountSignal = self.context.totalUnreadCount(filterPredicate: filter, tailChatListViewCount: count)
            
            unreadCountDisposable = (combineLatest(unreadCountSignal, context.sharedContext.presentationData) |> deliverOnMainQueue)
                .startStrict(next: { [weak self] unreadCount, presentationData in
                guard let self else { return }
                if unreadCount == 0 {
                    tabBarItem.badgeValue = ""
                } else {
                    tabBarItem.badgeValue = compactNumericCountString(Int(unreadCount), decimalSeparator: presentationData.dateTimeFormat.decimalSeparator)
                }
            })
            
        }
    }
    
    @objc private func reloadPressed() {
        controllerNode.wallContent.reloadData()
    }
}
