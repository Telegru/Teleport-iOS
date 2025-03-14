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
import ListSectionComponent
import ListItemComponentAdaptor
import ListActionItemComponent
import SettingsUI

public enum DSettingsControllerMode {
    case tab
    case navigation
}

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
        
        private var openHelpDisposable: Disposable?
        
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
            
            self.backButton.action = { [weak self] _, _ in
                if let self, let controller = environment?.controller() {
                    controller.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            openHelpDisposable?.dispose()
        }
        
        func scrollToTop() {
            self.scrollView.setContentOffset(CGPoint(), animated: true)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.updateScrolling(transition: .immediate)
        }
        
        var scrolledUp = true
        private func updateScrolling(transition: ComponentTransition) {
            let navigationAlphaDistance: CGFloat = 120.0
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
        
        private func openGeneralSettings() {
            guard
                let controller = environment?.controller(),
                let context = component?.context
            else {
                return
            }
            let generalController = dGeneralSettingsController(context: context)
            controller.push(generalController)
        }
        
        private func openAppearanceSettings() {
            guard
                let controller = environment?.controller(),
                let context = component?.context
            else {
                return
            }
            let appearanceController = dAppearanceSettingsController(context: context)
            controller.push(appearanceController)
        }
        
        private func openChatsSettings() {
            guard
                let controller = environment?.controller(),
                let context = component?.context
            else {
                return
            }
            let chatsController = dChatsSettingsController(context: context)
            controller.push(chatsController)
        }
        
        private func openSupport() {
            guard
                let controller = environment?.controller(),
                let context = component?.context
            else {
                return
            }
            openHelpDisposable?.dispose()
            
            let lang = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
            
            let text = "DahlSettings.Support.Alert.Title".tp_loc(lang: lang)
            let actions: [TextAlertAction] = [
                TextAlertAction(
                    type: .genericAction,
                    title: "DahlSettings.Support.Alert.Cancel".tp_loc(lang: lang),
                    action: {}
                ),
                TextAlertAction(
                    type: .defaultAction,
                    title: "DahlSettings.Support.Alert.Ok".tp_loc(lang: lang)) { [weak self] in
                        guard let self else { return }
                        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                        let statusController = OverlayStatusController(theme: presentationData.theme, type: .loading(cancelled: nil))
                        controller.present(statusController, in: .window(.root))
                        
                        let navigationController = controller.navigationController as? NavigationController
                        openHelpDisposable = (
                            context.engine.peers.resolvePeerByName(
                                name: "@dahl_help",
                                referrer: nil
                            )
                            |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
                                guard case let .result(result) = result else {
                                    return .complete()
                                }
                                return .single(result)
                            }
                            |> deliverOnMainQueue
                        ).startStrict(next: { [weak statusController] peer in
                            statusController?.dismiss()
                            if let peer = peer, let navigationController = navigationController {
                                context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: context, chatLocation: .peer(peer)))
                            }
                        })
                    }
            ]
            
            let alert = textAlertController(
                context: context,
                title: nil,
                text: text,
                actions: actions,
                actionLayout: .horizontal
            )
            controller.present(alert, in: .window(.root))
        }
        
        func update(component: DSettingsScreenComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
            self.isUpdating = true
            defer { self.isUpdating = false }
            
            let environment = environment[EnvironmentType.self].value
            let themeUpdated = self.environment?.theme !== environment.theme
            self.environment = environment
            
            let lang = component.context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
             
            self.component = component
            self.state = state
            
            if themeUpdated {
                self.backgroundColor = environment.theme.list.blocksBackgroundColor
            }
            
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
            self.backButton.frame = CGRect(
                origin: CGPoint(
                    x: environment.safeInsets.left + 16.0,
                    y: environment.navigationHeight - 44.0
                ),
                size: backSize
            )
            if self.backButton.view.superview == nil {
                if let controller = self.environment?.controller(),
                   let navigationController = controller.navigationController,
                   let navigationBar = controller.navigationBar,
                   navigationController.viewControllers.first != controller && navigationController.viewControllers.first != controller.parent {
                    navigationBar.view.addSubview(self.backButton.view)
                }
            }
            
            let bottomInset: CGFloat = 8.0
            let sideInset: CGFloat = 16.0 + environment.safeInsets.left
            let sectionSpacing: CGFloat = 32.0
            
            var contentHeight: CGFloat = 0.0
            
            let presentationData = component.context.sharedContext.currentPresentationData.with { $0 }
            
            let headerSectionSize = self.headerSection.update(
                transition: transition,
                component: AnyComponent(
                    ListSectionComponent(
                        theme: environment.theme,
                        background: .none(clipped: false),
                        header: nil,
                        footer: nil,
                        items: [
                            AnyComponentWithIdentity(
                                id: 0,
                                component: AnyComponent(
                                    ListItemComponentAdaptor(
                                        itemGenerator: DSettingsHeaderItem(
                                            context: component.context,
                                            theme: environment.theme,
                                            strings: environment.strings,
                                            topInset: environment.statusBarHeight,
                                            sectionId: 0,
                                            showBackground: false
                                        ),
                                        params: ListViewItemLayoutParams(width: availableSize.width, leftInset: 0.0, rightInset: 0.0, availableHeight: 10000.0, isStandalone: true))
                                    )
                            )
                        ])
                ),
                environment: {},
                containerSize: CGSize(width: availableSize.width, height: 1000.0)
            )
            
            let headerSectionFrame = CGRect(origin: CGPoint(x: 0.0, y: contentHeight), size: headerSectionSize)
            if let headerSectionView = self.headerSection.view {
                if headerSectionView.superview == nil {
                    self.scrollView.addSubview(headerSectionView)
                }
                transition.setFrame(view: headerSectionView, frame: headerSectionFrame)
            }
            
            contentHeight += headerSectionSize.height
            contentHeight += sectionSpacing
            
            let categoriesSectionSize = self.categoriesSection.update(
                transition: transition,
                component: AnyComponent(
                    ListSectionComponent(
                        theme: environment.theme,
                        header: AnyComponent(
                            Text(
                                text: "DahlSettings.Categories.Header".tp_loc(lang: lang).uppercased(),
                                font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                                color: environment.theme.list.freeTextColor
                            )
                        ),
                        footer: nil,
                        items: [
                            AnyComponentWithIdentity(
                                id: 0,
                                component: AnyComponent(
                                    ListActionItemComponent(
                                        theme: environment.theme,
                                        title: AnyComponent(MultilineTextComponent(
                                            text: .plain(NSAttributedString(
                                                string: "DahlSettings.General.Title".tp_loc(lang: lang),
                                                font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                                textColor: environment.theme.list.itemPrimaryTextColor
                                            )),
                                            maximumNumberOfLines: 0
                                        )),
                                        leftIcon: .custom(AnyComponentWithIdentity(id: 0, component: AnyComponent(BundleIconComponent(
                                            name: "DahlSettings/General",
                                            tintColor: nil
                                        ))), false),
                                        action: { [weak self] view in
                                            guard let self else {
                                                return
                                            }
                                            
                                            self.openGeneralSettings()
                                        }
                                    )
                                )
                            ),
                            
                            AnyComponentWithIdentity(
                                id: 1,
                                component: AnyComponent(
                                    ListActionItemComponent(
                                        theme: environment.theme,
                                        title: AnyComponent(MultilineTextComponent(
                                            text: .plain(NSAttributedString(
                                                string: "DahlSettings.Appearance.Title".tp_loc(lang: lang),
                                                font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                                textColor: environment.theme.list.itemPrimaryTextColor
                                            )),
                                            maximumNumberOfLines: 0
                                        )),
                                        leftIcon: .custom(AnyComponentWithIdentity(id: 0, component: AnyComponent(BundleIconComponent(
                                            name: "DahlSettings/Appearance",
                                            tintColor: nil
                                        ))), false),
                                        action: { [weak self] view in
                                            guard let self else {
                                                return
                                            }
                                            
                                            self.openAppearanceSettings()
                                        }
                                    )
                                )
                            ),
                            
                            AnyComponentWithIdentity(
                                id: 2,
                                component: AnyComponent(
                                    ListActionItemComponent(
                                        theme: environment.theme,
                                        title: AnyComponent(MultilineTextComponent(
                                            text: .plain(NSAttributedString(
                                                string: "DahlSettings.Chats.Title".tp_loc(lang: lang),
                                                font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                                textColor: environment.theme.list.itemPrimaryTextColor
                                            )),
                                            maximumNumberOfLines: 0
                                        )),
                                        leftIcon: .custom(AnyComponentWithIdentity(id: 0, component: AnyComponent(BundleIconComponent(
                                            name: "DahlSettings/Chats",
                                            tintColor: nil
                                        ))), false),
                                        action: { [weak self] view in
                                            guard let self else {
                                                return
                                            }
                                            
                                            self.openChatsSettings()
                                        }
                                    )
                                )
                            )
                        ]
                    )
                ),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 10000.0)
            )
            let categoriesSectionFrame = CGRect(
                origin: CGPoint(
                    x: sideInset,
                    y: contentHeight
                ),
                size: categoriesSectionSize
            )
            if let categoriesSectionView = self.categoriesSection.view {
                if categoriesSectionView.superview == nil {
                    self.scrollView.addSubview(categoriesSectionView)
                }
                transition.setFrame(view: categoriesSectionView, frame: categoriesSectionFrame)
            }
            
            contentHeight += categoriesSectionSize.height
            contentHeight += sectionSpacing - 8.0
            
            let supportSectionSize = self.supportSection.update(
                transition: transition,
                component: AnyComponent(
                    ListSectionComponent(
                        theme: environment.theme,
                        header: nil,
                        footer: nil,
                        items: [
                            AnyComponentWithIdentity(
                                id: 0,
                                component: AnyComponent(
                                    ListActionItemComponent(
                                        theme: environment.theme,
                                        title: AnyComponent(MultilineTextComponent(
                                            text: .plain(NSAttributedString(
                                                string: "DahlSettings.Support.Title".tp_loc(lang: lang),
                                                font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                                textColor: environment.theme.list.itemPrimaryTextColor
                                            )),
                                            maximumNumberOfLines: 0
                                        )),
                                        leftIcon: .custom(AnyComponentWithIdentity(id: 0, component: AnyComponent(BundleIconComponent(
                                            name: "DahlSettings/Support",
                                            tintColor: nil
                                        ))), false),
                                        action: { [weak self] view in
                                            guard let self else {
                                                return
                                            }
                                            
                                            self.openSupport()
                                        }
                                    )
                                )
                            )
                        ]
                    )
                ),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 1000.0)
            )
            let supportSectionFrame = CGRect(
                origin: CGPoint(
                    x: sideInset,
                    y: contentHeight
                ),
                size: supportSectionSize
            )
            if let supportSectionView = self.supportSection.view {
                if supportSectionView.superview == nil {
                    self.scrollView.addSubview(supportSectionView)
                }
                transition.setFrame(view: supportSectionView, frame: supportSectionFrame)
            }
            
            contentHeight += bottomInset
            contentHeight += environment.safeInsets.bottom
            
            let previousBounds = self.scrollView.bounds
            
            let contentSize = CGSize(width: availableSize.width, height: contentHeight)
            if self.scrollView.frame != CGRect(origin: CGPoint(), size: availableSize) {
                self.scrollView.frame = CGRect(origin: CGPoint(), size: availableSize)
            }
            if self.scrollView.contentSize != contentSize {
                self.scrollView.contentSize = contentSize
            }
            let scrollInsets = UIEdgeInsets(top: environment.navigationHeight, left: 0.0, bottom: availableSize.height, right: 0.0)
            if self.scrollView.scrollIndicatorInsets != scrollInsets {
                self.scrollView.scrollIndicatorInsets = scrollInsets
            }
            
            if !previousBounds.isEmpty, !transition.animation.isImmediate {
                let bounds = self.scrollView.bounds
                if bounds.maxY != previousBounds.maxY {
                    let offsetY = previousBounds.maxY - bounds.maxY
                    transition.animateBoundsOrigin(view: self.scrollView, from: CGPoint(x: 0.0, y: offsetY), to: CGPoint(), additive: true)
                }
            }
            
            
            self.updateScrolling(transition: transition)
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View()
    }
    
    func update(
        view: View,
        availableSize: CGSize,
        state: EmptyComponentState,
        environment: Environment<EnvironmentType>,
        transition: ComponentTransition
    ) -> CGSize {
        return view.update(
            component: self,
            availableSize: availableSize,
            state: state,
            environment: environment,
            transition: transition
        )
    }
}

public final class DSettingsScreen: ViewControllerComponentContainer {
    
    private let context: AccountContext
    
    private var presentationDataDisposable: Disposable?
    
    public init(
        context: AccountContext,
        mode: DSettingsControllerMode = .navigation ,
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
        
        switch mode {
        case .tab:
            let tabIcon = UIImage(bundleImageName: "Chat List/Tabs/IconDahl")
            self.tabBarItem.image = tabIcon
            self.tabBarItem.selectedImage = tabIcon
        default:
            break
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIView())
        
        presentationDataDisposable = (
            context.sharedContext.presentationData
            |> distinctUntilChanged
            |> deliverOnMainQueue
        ).startStrict(next: { [weak self] presentationData in
            guard let self else { return }
            self.tabBarItem.title = "Dahl.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode)
        })
        
        self.scrollToTop = { [weak self] in
            guard let self, let componentView = self.node.hostView.componentView as? DSettingsScreenComponent.View else {
                return
            }
            componentView.scrollToTop()
        }
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        presentationDataDisposable?.dispose()
    }
}
