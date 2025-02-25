import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext
import ComponentFlow
import BundleIconComponent
import AnimatedTextComponent
import ViewControllerComponent
import ButtonComponent
import MultilineTextComponent

final class DSettingsScreenComponent: Component {
    
    typealias EnvironmentType = ViewControllerComponentContainer.Environment
    
    let context: AccountContext
    
    init(
        context: AccountContext
    ) {
        self.context = context
    }
    
    static func ==(
        lhs: DSettingsScreenComponent,
        rhs: DSettingsScreenComponent
    ) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }

        return true
    }
    
    private final class ContentsData {}
    
    private final class ScrollView: UIScrollView {
        override func touchesShouldCancel(in view: UIView) -> Bool {
            return true
        }
    }
    
    final class View: UIView, UIScrollViewDelegate {
        private let topOverscrollLayer = SimpleLayer()
        private let scrollView: ScrollView
        
        
        private let backButton = DSettingsNavigationButton()
        private let navigationTitle = ComponentView<Empty>()
        
        private let headerSection = ComponentView<Empty>()
        private let categoriesSection = ComponentView<Empty>()
        private let supportSection = ComponentView<Empty>()
        
        private var isUpdating: Bool = false
        
        private var component: DSettingsScreenComponent?
        private(set) weak var state: EmptyComponentState?
        private var environment: EnvironmentType?
        
        let isReady = ValuePromise<Bool>(false, ignoreRepeated: true)
//        private var contentsData: ContentsData?
//        private var contentsDataDisposable: Disposable?
        
        override init(frame: CGRect) {
            self.scrollView = ScrollView()
            self.scrollView.showsVerticalScrollIndicator = true
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.scrollsToTop = false
            self.scrollView.delaysContentTouches = false
            self.scrollView.canCancelContentTouches = true
            self.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                self.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
            self.scrollView.alwaysBounceVertical = true
            
            super.init(frame: frame)
            
            self.scrollView.delegate = self
            self.addSubview(self.scrollView)
            
            self.scrollView.layer.addSublayer(self.topOverscrollLayer)
            
            self.backButton.action = { [weak self] _, _ in
                if let self, let controller = environment?.controller() {
                    controller.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func scrollToTop() {
            self.scrollView.setContentOffset(CGPoint(), animated: true)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.updateScrolling(transition: .immediate)
        }
        
        var scrolledUp = true
        private func updateScrolling(transition: ComponentTransition) {
            let navigationAlphaDistance: CGFloat = 16.0
            let navigationAlpha: CGFloat = max(0.0, min(1.0, self.scrollView.contentOffset.y / navigationAlphaDistance))
            if let controller = self.environment?.controller(), let navigationBar = controller.navigationBar {
                transition.setAlpha(layer: navigationBar.backgroundNode.layer, alpha: navigationAlpha)
                transition.setAlpha(layer: navigationBar.stripeNode.layer, alpha: navigationAlpha)
            }
            
            var scrolledUp = false
            if navigationAlpha < 0.5 {
                scrolledUp = true
            } else if navigationAlpha > 0.5 {
                scrolledUp = false
            }
            
            if self.scrolledUp != scrolledUp {
                self.scrolledUp = scrolledUp
                if !self.isUpdating {
                    self.state?.updated()
                }
            }
            
            if let navigationTitleView = self.navigationTitle.view {
                transition.setAlpha(view: navigationTitleView, alpha: navigationAlpha)
            }
        }
        
        private func openSupport() {
//            guard let component else {
//                return
//            }
            // Show alert and open support
            // TODO: Open support
        }
        
        func update(component: DSettingsScreenComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
            self.isUpdating = true
            defer { self.isUpdating = false }
            
            let environment = environment[EnvironmentType.self].value
            let themeUpdated = self.environment?.theme !== environment.theme
            self.environment = environment
            
            self.component = component
            self.state = state
            
            if themeUpdated {
                self.backgroundColor = environment.theme.list.blocksBackgroundColor
            }
            
            // TODO: Get app icon
            // TODO: Get app version
            // TODO: Get app icon
            
            self.topOverscrollLayer.backgroundColor = UIColor.clear.cgColor
            
            let backSize = self.backButton.update(presentationData: component.context.sharedContext.currentPresentationData.with { $0 }, height: 44.0)
            
            if let controller = self.environment?.controller() as? DSettingsScreen {
                controller.statusBar.updateStatusBarStyle(.Ignore, animated: true)
            }
            
            self.backButton.updateContentsColor(
                backgroundColor: .clear,
                contentsColor: environment.theme.rootController.navigationBar.accentTextColor,
                canBeExpanded: true,
                transition: .animated(duration: 0.2, curve: .easeInOut)
            )
            self.backButton.frame = CGRect(origin: CGPoint(x: environment.safeInsets.left + 16.0, y: environment.navigationHeight - 44.0), size: backSize)
            if self.backButton.view.superview == nil {
                if let controller = self.environment?.controller(), let navigationBar = controller.navigationBar {
                    navigationBar.view.addSubview(self.backButton.view)
                }
            }
            
            let navigationTitleSize = self.navigationTitle.update(
                transition: transition,
                component: AnyComponent(MultilineTextComponent(
                    text: .plain(NSAttributedString(string: environment.strings.Channel_Appearance_Title, font: Font.semibold(17.0), textColor: environment.theme.rootController.navigationBar.primaryTextColor)),
                    horizontalAlignment: .center
                )),
                environment: {},
                containerSize: availableSize
            )
            let navigationTitleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - navigationTitleSize.width) / 2.0), y: environment.statusBarHeight + floor((environment.navigationHeight - environment.statusBarHeight - navigationTitleSize.height) / 2.0)), size: navigationTitleSize)
            if let navigationTitleView = self.navigationTitle.view {
                if navigationTitleView.superview == nil {
                    if let controller = self.environment?.controller(), let navigationBar = controller.navigationBar {
                        navigationBar.view.addSubview(navigationTitleView)
                    }
                }
                transition.setFrame(view: navigationTitleView, frame: navigationTitleFrame)
            }
            
            let bottomContentInset: CGFloat = 24.0
            let bottomInset: CGFloat = 8.0
            let sideInset: CGFloat = 16.0 + environment.safeInsets.left
            let sectionSpacing: CGFloat = 32.0
            
            let listItemParams = ListViewItemLayoutParams(width: availableSize.width - sideInset * 2.0, leftInset: 0.0, rightInset: 0.0, availableHeight: 10000.0, isStandalone: true)
            
            var contentHeight: CGFloat = 0.0
            
            let presentationData = component.context.sharedContext.currentPresentationData.with { $0 }
            
            let previewSectionSize = self.previewSection.update
        }
    }
}

final class DSettingsScreen: ViewControllerComponentContainer {
    
    private let context: AccountContext
    private var didSetReady: Bool = false
    
    init(
        context: AccountContext,
        updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?
    ) {
        self.context = context
        
        super.init(
            context: context,
            component: DSettingsScreenComponent(context: context),
            navigationBarAppearance: .default,
            theme: .default,
            updatedPresentationData: updatedPresentationData
        )
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView())
        
        self.ready.set(.never())
        
        self.scrollToTop = { [weak self] in
            guard let self, let componentView = self.node.hostView.componentView as? DSettingsScreenComponent.View else {
                return
            }
            componentView.scrollToTop()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        if let componentView = self.node.hostView.componentView as? DSettingsScreenComponent.View {
            if !self.didSetReady {
                self.didSetReady = true
                self.ready.set(componentView.isReady.get())
            }
        }
    }
}
