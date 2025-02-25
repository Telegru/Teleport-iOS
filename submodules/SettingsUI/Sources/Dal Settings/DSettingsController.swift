import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext
import AppBundle
import AlertUI
import PresentationDataUtils

import TPUI
import TPStrings

public enum DSettingsControllerMode {
    case tab
    case navigation
}

private final class DSettingsArguments {
    let context: AccountContext
    let openGeneralSettings: () -> Void
    let openAppearanceSettings: () -> Void
    let openChatSettings: () -> Void
    let openHelp: () -> Void
    
    init(
        context: AccountContext,
        openGeneralSettings: @escaping () -> Void,
        openAppearanceSettings: @escaping () -> Void,
        openChatSettings: @escaping () -> Void,
        openHelp: @escaping () -> Void
    ) {
        self.context = context
        self.openGeneralSettings = openGeneralSettings
        self.openAppearanceSettings = openAppearanceSettings
        self.openChatSettings = openChatSettings
        self.openHelp = openHelp
    }
}

private enum DSettingsSection: Int32, CaseIterable {
    case header
    case categories
    case support
}

private enum DSettingsEntryTag: ItemListItemTag {
    case general
    case appearance
    case chats
    case support
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DSettingsEntry: ItemListNodeEntry {
    case settingsHeader(theme: PresentationTheme, title: String, subtitle: String)
    
    case categoriesHeader(PresentationTheme, String)
    case general(PresentationTheme, String)
    case appearance(PresentationTheme, String)
    case chats(PresentationTheme, String)
    case support(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .settingsHeader:
            return DSettingsSection.header.rawValue
            
        case .categoriesHeader, .general, .appearance, .chats:
            return DSettingsSection.categories.rawValue
            
        case .support:
            return DSettingsSection.support.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .settingsHeader:
            return 0
        case .categoriesHeader:
            return 1
        case .general:
            return 2
        case .appearance:
            return 3
        case .chats:
            return 4
        case .support:
            return 5
        }
    }
    
    var tag: ItemListItemTag? {
        switch self {
        case .general:
            return DSettingsEntryTag.general
        case .appearance:
            return DSettingsEntryTag.appearance
        case .chats:
            return DSettingsEntryTag.chats
        case .support:
            return DSettingsEntryTag.support
            
        case .settingsHeader, .categoriesHeader:
            return nil
        }
    }
    
    static func ==(lhs: DSettingsEntry, rhs: DSettingsEntry) -> Bool {
        switch lhs {
        case let .settingsHeader(lhsTheme, lhsTitle, lhsSubtitle):
            if case let .settingsHeader(rhsTheme, rhsTitle, rhsSubtitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle,
               lhsSubtitle == rhsSubtitle {
                return true
            } else {
                return false
            }
            
        case let .categoriesHeader(lhsTheme, lhsText):
            if case let .categoriesHeader(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .general(lhsTheme, lhsText):
            if case let .general(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .appearance(lhsTheme, lhsText):
            if case let .appearance(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .chats(lhsTheme, lhsText):
            if case let .chats(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            } else {
                return false
            }
            
        case let .support(lhsTheme, lhsText):
            if case let .support(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: DSettingsEntry, rhs: DSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DSettingsArguments
        
        switch self {
        case .settingsHeader:
            fatalError("No Implemented")
            
        case let .categoriesHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: section
            )
        
        case let .general(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(bundleImageName: "DahlSettings/General"),
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openGeneralSettings()
                }
            )
            
        case let .appearance(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(bundleImageName: "DahlSettings/Appearance"),
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openAppearanceSettings()
                }
            )
            
        case let .chats(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(bundleImageName: "DahlSettings/Chats"),
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openChatSettings()
                }
            )
            
        case let .support(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(bundleImageName: "DahlSettings/Support"),
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openHelp()
                }
            )
        }
    }
}

private func dSettingsEntires(
    presentationData: PresentationData
) -> [DSettingsEntry] {
    var entries = [DSettingsEntry]()
    let lang = presentationData.strings.baseLanguageCode
    
//    entries.append(
//        .settingsHeader(
//            theme: presentationData.theme,
//            title: ,
//            subtitle:
//        )
//    )
    
    entries.append(
        .categoriesHeader(
            presentationData.theme,
            "DahlSettings.Categories.Header".tp_loc(lang: lang).uppercased()
        )
    )
    
    entries.append(
        .general(
            presentationData.theme,
            "DahlSettings.General.Title".tp_loc(lang: lang)
        )
    )
    entries.append(
        .appearance(
            presentationData.theme,
            "DahlSettings.Appearance.Title".tp_loc(lang: lang)
        )
    )
    entries.append(
        .chats(
            presentationData.theme,
            "DahlSettings.Chats.Title".tp_loc(lang: lang)
        )
    )
    
    entries.append(
        .support(
            presentationData.theme,
            "DahlSettings.Support.Title".tp_loc(lang: lang)
        )
    )
    
    return entries
}

public func dSettingsController(
    context: AccountContext,
    mode: DSettingsControllerMode = .navigation
) -> ViewController {
    let lang = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode
    
    var openGeneralSettings: (() -> Void)?
    var openAppearanceSettings: (() -> Void)?
    var openChatSettings: (() -> Void)?
    
    var openHelp: (() -> Void)?
    var openHelpDisposable: Disposable?
    
    let arguments = DSettingsArguments(
        context: context,
        openGeneralSettings: {
            openGeneralSettings?()
        },
        openAppearanceSettings: {
            openAppearanceSettings?()
        },
        openChatSettings: {
            openChatSettings?()
        },
        openHelp: {
            openHelp?()
        }
    )
    
    let tabBarItemSignal = context.sharedContext.presentationData
    |> map { presentationData -> ItemListControllerTabBarItem in
        let tabIcon = UIImage(bundleImageName: "Chat List/Tabs/IconDahl")
        return ItemListControllerTabBarItem(
            title: "Dahl.TabTitle".tp_loc(lang: presentationData.strings.baseLanguageCode),
            image: tabIcon,
            selectedImage: tabIcon
        )
    }
    
    let signal = (
        combineLatest(
            context.sharedContext.presentationData,
            tabBarItemSignal
        )
        |> map { presentationData, tabBarItem in
            let entries = dSettingsEntires(presentationData: presentationData)
            
            let isTabMode = if case .tab = mode {
                true
            } else {
                false
            }
            
            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .navigationItemTitle(""),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
                tabBarItem: isTabMode ? tabBarItem : nil
            )
            
            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: entries,
                style: .blocks
            )
            
            return (controllerState, (listState, arguments))
        }
    )
    
    let controller: ItemListController
    
    switch mode {
    case .navigation:
        controller = ItemListController(context: context, state: signal)
    case .tab:
        controller = ItemListController(context: context, state: signal, tabBarItem: tabBarItemSignal)
    }
    
    openGeneralSettings = { [weak controller] in
        let generalController = dGeneralSettingsController(context: context)
        controller?.push(generalController)
    }
    
    openAppearanceSettings = { [weak controller] in
        let appearanceController = dAppearanceSettingsController(context: context)
        controller?.push(appearanceController)
    }
    
    openChatSettings = { [weak controller] in
        let chatsController = dChatsSettingsController(context: context)
        controller?.push(chatsController)
    }
    
    openHelp = { [weak controller] in
        guard let controller else { return }
        openHelpDisposable?.dispose()
        
        let text = "DahlSettings.Support.Alert.Title".tp_loc(lang: lang)
        let actions: [TextAlertAction] = [
            TextAlertAction(
                type: .defaultAction,
                title: "DahlSettings.Support.Alert.Ok".tp_loc(lang: lang)) {
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
                },
            TextAlertAction(
                type: .genericAction,
                title: "DahlSettings.Support.Alert.Cancel".tp_loc(lang: lang),
                action: {}
            )
        ]
        
        let alert = textAlertController(
            context: arguments.context,
            title: nil,
            text: text,
            actions: actions,
            actionLayout: .horizontal
        )
        controller.present(alert, in: .window(.root))
    }
    
    controller.didDisappear = { _ in
        openHelpDisposable?.dispose()
    }
    
    return controller
}
