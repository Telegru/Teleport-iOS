import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TPStrings

public final class NewsFeedViewController: ViewController {
    
    // Dependencies
    private let context: AccountContext
    private var presentationData: PresentationData
    
    // Private properties
    private let disposableSet = DisposableSet()
    private var controllerNode: NewsFeedViewControllerNode {
        displayNode as! NewsFeedViewControllerNode
    }
    
    // MARK: - Initializations
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
        
        title = presentationData.strings.RootTabs_News
        tabBarItem.title = presentationData.strings.RootTabs_News
        let icon = UIImage(bundleImageName: "Chat List/Tabs/IconNews")
        tabBarItem.image = icon
        tabBarItem.selectedImage = icon
        updateNavigationItems()
        
        disposableSet.add(
            (context.sharedContext.presentationData |> deliverOnMainQueue)
                .startStrict(next: { [weak self] presentationData in
                    guard let self else { return }
                    let previousTheme = self.presentationData.theme
                    let previousStrings = self.presentationData.strings
                    
                    self.presentationData = presentationData
                    
                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        updateThemeAndStrings()
                    }
                })
        )
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Node layout
    
    public override func loadDisplayNode() {
        displayNode = NewsFeedViewControllerNode()
    }
    
    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        controllerNode.containerLayoutUpdated(
            layout,
            navigationBarHeight: navigationLayout(layout: layout).navigationFrame.maxY,
            transition: transition
        )
    }
    
    // MARK: - Private methods
    
    private func updateThemeAndStrings() {
        statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
        navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: presentationData))
        
        title = presentationData.strings.RootTabs_News
        tabBarItem.title = presentationData.strings.RootTabs_News
        
        updateNavigationItems()
    }
    
    private func updateNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: PresentationResourcesRootController.navigationHomeIcon(presentationData.theme),
            style: .plain,
            target: self,
            action: #selector(homePressed)
        )
    }
    
    // MARK: - Action senders
    
    @objc
    private func homePressed() {
        controllerNode.loadHomePage()
    }
}

private extension PresentationStrings {
    var RootTabs_News: String {
        "RootTabs.News".tp_loc(lang: baseLanguageCode)
    }
}
