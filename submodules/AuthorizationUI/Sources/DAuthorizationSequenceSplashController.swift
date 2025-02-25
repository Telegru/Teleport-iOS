//
//  DAuthorizationSequenceSplashController.swift
//  AuthorizationUI
//
//  Created by Lenar Gilyazov on 19.12.2024.
//

import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import LegacyComponents
import SolidRoundedButtonNode
import RMIntro
import DAuth
import TPOnboarding

public final class DAuthorizationSequenceSplashController: ViewController {
    
    private var controllerNode: AuthorizationSequenceSplashControllerNode {
        return self.displayNode as! AuthorizationSequenceSplashControllerNode
    }
    
    private let accountManager: AccountManager<TelegramAccountManagerTypes>
    private let account: UnauthorizedAccount
    private let theme: PresentationTheme
    
    private let controller: DIntroViewController
    
    private var validLayout: ContainerViewLayout?
    
    var nextPressed: ((PresentationStrings?) -> Void)?
    
    private let suggestedLocalization = Promise<SuggestedLocalizationInfo?>()
    private let activateLocalizationDisposable = MetaDisposable()
    
    private let startButton: SolidRoundedButtonNode
    
    init(
        accountManager: AccountManager<TelegramAccountManagerTypes>,
        account: UnauthorizedAccount,
        theme: PresentationTheme
    ) {
        self.accountManager = accountManager
        self.account = account
        self.theme = theme
        
        self.suggestedLocalization.set(
            .single(nil)
            |> then(TelegramEngineUnauthorized(account: self.account)
                .localization
                .currentlySuggestedLocalization(extractKeys: ["Login.ContinueWithLocalization"]))
        )
        let suggestedLocalization = self.suggestedLocalization
        
        let localizationSignal = SSignal(generator: { subscriber in
            if Locale.current.languageCode == "ru" {
                subscriber.putNext("en")
                subscriber.putCompletion()
                return SBlockDisposable()
            }
            
            let disposable = suggestedLocalization.get().start(next: { localization in
                guard let localization else {
                    return
                }
                
                if let available = localization.availableLocalizations.first(where: { $0.languageCode == "ru" }) {
                    subscriber.putNext(available.languageCode)
                }
            }, completed: {
                subscriber.putCompletion()
            })
            
            return SBlockDisposable(block: {
                disposable.dispose()
            })
        })
        
        self.controller = DIntroViewController(suggestedLocalizationSignal: localizationSignal)
        self.startButton = SolidRoundedButtonNode(
            title: "Intro.StartMessaging".tp_loc(),
            theme: SolidRoundedButtonTheme(backgroundColor: UIColor(hexString: "#7B86C3")!, foregroundColor: .white),
            height: 50.0,
            cornerRadius: 13.0,
            gloss: true
        )
        
        super.init(navigationBarPresentationData: nil)
        
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        
        self.statusBar.statusBarStyle = .White
        
        self.controller.startMessagingInAlternativeLanguage = { [weak self] code in
            self?.activateLocalization(code)
        }
        
        self.startButton.pressed = { [weak self] in
            self?.activateLocalization(Locale.current.languageCode == "ru" ? "ru" : "en")
        }
        
        self.controller.createStartButton = { [weak self] width in
            guard let self else { return UIView() }
            _ = startButton.updateLayout(width: width, transition: .immediate)
            return startButton.view
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        activateLocalizationDisposable.dispose()
    }
    
    public override func loadDisplayNode() {
        displayNode = AuthorizationSequenceSplashControllerNode(theme: theme)
        displayNodeDidLoad()
    }
    
    var buttonFrame: CGRect {
        startButton.frame
    }
    
    var buttonTitle: String {
        startButton.title ?? ""
    }
    
    private func addControllerIfNeeded() {
        if !controller.isViewLoaded || controller.view.superview == nil {
            displayNode.view.addSubview(controller.view)
            if let layout = validLayout {
                controller.view.frame = CGRect(origin: CGPoint(), size: layout.size)
            }
            controller.viewDidAppear(false)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addControllerIfNeeded()
        controller.viewWillAppear(false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        controller.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        controller.viewWillDisappear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        controller.viewDidDisappear(animated)
    }
    
    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.validLayout = layout
        let controllerFrame = CGRect(origin: CGPoint(), size: layout.size)
        self.controller.view.frame = controllerFrame
        self.controller.defaultFrame = controllerFrame
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: 0.0, transition: transition)
        
        self.addControllerIfNeeded()
        if case .immediate = transition {
            self.controller.view.frame = controllerFrame
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.controller.view.frame = controllerFrame
            })
        }
    }
    
    private func activateLocalization(_ code: String) {
        guard code != "en" else {
            pressNext(strings: nil)
            return
        }
        
        startButton.alpha = 0.6
        controller.isEnabled = false
        startButton.isEnabled = false
        let accountManager = accountManager
        
        activateLocalizationDisposable.set(
            TelegramEngineUnauthorized(account: account)
                .localization
                .downloadAndApplyLocalization(accountManager: accountManager, languageCode: code)
                .start(completed: { [weak self] in
                    let _ = (accountManager.transaction { transaction -> PresentationStrings? in
                        let localizationSettings: LocalizationSettings?
                        if let current = transaction.getSharedData(SharedDataKeys.localizationSettings)?.get(LocalizationSettings.self) {
                            localizationSettings = current
                        } else {
                            localizationSettings = nil
                        }
                        let stringsValue: PresentationStrings
                        if let localizationSettings = localizationSettings, !AppReviewLogin.shared.isAuthorized {
                            stringsValue = PresentationStrings(primaryComponent: PresentationStrings.Component(languageCode: localizationSettings.primaryComponent.languageCode, localizedName: localizationSettings.primaryComponent.localizedName, pluralizationRulesCode: localizationSettings.primaryComponent.customPluralizationCode, dict: dictFromLocalization(localizationSettings.primaryComponent.localization)), secondaryComponent: localizationSettings.secondaryComponent.flatMap({ PresentationStrings.Component(languageCode: $0.languageCode, localizedName: $0.localizedName, pluralizationRulesCode: $0.customPluralizationCode, dict: dictFromLocalization($0.localization)) }), groupingSeparator: "")
                        } else {
                            stringsValue = defaultPresentationStrings
                        }
                        return stringsValue
                    }
                             |> deliverOnMainQueue
                    ).start(next: { strings in
                        self?.controller.isEnabled = true
                        self?.startButton.isEnabled = true
                        self?.startButton.alpha = 1.0
                        self?.pressNext(strings: strings)
                    })
                })
        )
    }
    
    private func pressNext(strings: PresentationStrings?) {
        if let navigationController = self.navigationController, navigationController.viewControllers.last === self {
            self.nextPressed?(strings)
        }
    }
}

