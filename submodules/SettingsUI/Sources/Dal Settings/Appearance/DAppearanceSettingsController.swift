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
import PresentationDataUtils
import UndoUI

import TPUI
import TPStrings

private final class DAppearanceSettingsArguments {
    let context: AccountContext
    
    let updateShowCustomWallpaperInChannels: (Bool) -> Void
    let updateChannelBottomPanel: (Bool) -> Void
    let updateChatsListViewType: (ListViewType) -> Void
    let openSettingsItemsConfiguration: () -> Void
    let openTabBarSettings: () -> Void
    let updateViewRounding: (Bool) -> Void
    let updateVKIcons: (Bool) -> Void
    let updateAlternativeFontInAvatars: (Bool) -> Void
    
    init(
        context: AccountContext,
        updateShowCustomWallpaperInChannels: @escaping (Bool) -> Void,
        updateChannelBottomPanel: @escaping (Bool) -> Void,
        updateChatsListViewType: @escaping (ListViewType) -> Void,
        openSettingsItemsConfiguration: @escaping () -> Void,
        openTabBarSettings: @escaping () -> Void,
        updateViewRounding: @escaping (Bool) -> Void,
        updateVKIcons: @escaping (Bool) -> Void,
        updateAlternativeFontInAvatars: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.updateShowCustomWallpaperInChannels = updateShowCustomWallpaperInChannels
        self.updateChannelBottomPanel = updateChannelBottomPanel
        self.updateChatsListViewType = updateChatsListViewType
        self.openSettingsItemsConfiguration = openSettingsItemsConfiguration
        self.openTabBarSettings = openTabBarSettings
        self.updateViewRounding = updateViewRounding
        self.updateVKIcons = updateVKIcons
        self.updateAlternativeFontInAvatars = updateAlternativeFontInAvatars
    }
}

private enum DAppearanceSettingsSection: Int32 {
    case chatsAppearance
    case listViewType
    case menuItems
    case tabBar
    case viewRounding
    case avatarFont
    case icons
}

private enum DAppearanceSettingsEntry: ItemListNodeEntry {
    case chatsAppearanceHeader(title: String)
    case showCustomWallpaperInChannels(title: String, isActive: Bool)
    case showChannelBottomPanel(title: String, isActive: Bool)
    
    case listViewTypeHeader(title: String)
    case listViewTypeOption(title: String, type: ListViewType, isSelected: Bool)
    case menuItemsHeader(title: String)
    case menuItems(title: String, detail: String)
    case tabBar(title: String, detail: String)
    
    case viewRoundingHeader(title: String)
    case viewRounding(title: String, isActive: Bool)
    
    case avatarFontHeader(title: String)
    case avatarFont(title: String, isActive: Bool)
    case avatarFontFooter(text: NSAttributedString)
    
    case iconsHeader(title: String)
    case vkIcons(title: String, isActive: Bool)
    case iconsPreview(PresentationTheme)
    
    var section: ItemListSectionId {
        switch self {
        case .chatsAppearanceHeader, .showCustomWallpaperInChannels, .showChannelBottomPanel:
            return DAppearanceSettingsSection.chatsAppearance.rawValue
            
        case .listViewTypeHeader, .listViewTypeOption:
            return DAppearanceSettingsSection.listViewType.rawValue
            
        case .menuItemsHeader, .menuItems:
            return DAppearanceSettingsSection.menuItems.rawValue
            
        case .tabBar:
            return DAppearanceSettingsSection.tabBar.rawValue
            
        case .viewRoundingHeader, .viewRounding:
            return DAppearanceSettingsSection.viewRounding.rawValue
            
        case .avatarFontHeader, .avatarFont, .avatarFontFooter:
            return DAppearanceSettingsSection.avatarFont.rawValue
            
        case .iconsHeader, .vkIcons, .iconsPreview:
            return DAppearanceSettingsSection.icons.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .chatsAppearanceHeader:
            return 0
        case .showCustomWallpaperInChannels:
            return 1
        case .showChannelBottomPanel:
            return 2
        case .listViewTypeHeader:
            return 3
        case let .listViewTypeOption(_, type, _):
            return Int32(type.rawValue + 100)
        case .menuItemsHeader:
            return 1000
        case .menuItems:
            return 1001
        case .tabBar:
            return 1002
        case .viewRoundingHeader:
            return 1003
        case .viewRounding:
            return 1004
        case .avatarFontHeader:
            return 1005
        case .avatarFont:
            return 1006
        case .avatarFontFooter:
            return 1007
        case .iconsHeader:
            return 1008
        case .vkIcons:
            return 1009
        case .iconsPreview:
            return 1010
        }
    }
    
    static func == (lhs: DAppearanceSettingsEntry, rhs: DAppearanceSettingsEntry) -> Bool {
        switch lhs {
        case let .chatsAppearanceHeader(lhsTitle):
            if case let .chatsAppearanceHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .showCustomWallpaperInChannels(lhsTitle, lhsIsActive):
            if case let .showCustomWallpaperInChannels(rhsTitle, rhsIsActive) = rhs {
                return lhsTitle == rhsTitle && lhsIsActive == rhsIsActive
            }
            return false
            
        case let .showChannelBottomPanel(lhsTitle, lhsIsActive):
            if case let .showChannelBottomPanel(rhsTitle, rhsIsActive) = rhs {
                return lhsTitle == rhsTitle && lhsIsActive == rhsIsActive
            }
            return false
            
        case let .listViewTypeHeader(lhsTitle):
            if case let .listViewTypeHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .listViewTypeOption(lhsText, lhsType, lhsSelected):
            if case let .listViewTypeOption(rhsText, rhsType, rhsSelected) = rhs {
                return lhsText == rhsText && lhsType == rhsType && lhsSelected == rhsSelected
            }
            return false
            
        case let .menuItemsHeader(lhsTitle):
            if case let .menuItemsHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .menuItems(lhsTitle, lhsDetail):
            if case let .menuItems(rhsTitle, rhsDetail) = rhs {
                return lhsTitle == rhsTitle && lhsDetail == rhsDetail
            }
            return false
            
        case let .tabBar(lhsTitle, lhsDetail):
            if case let .tabBar(rhsTitle, rhsDetail) = rhs {
                return lhsTitle == rhsTitle && lhsDetail == rhsDetail
            }
            return false
            
        case let .viewRoundingHeader(lhsTitle):
            if case let .viewRoundingHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
        
        case let .viewRounding(lhsTitle, lhsIsActive):
            if case let .viewRounding(rhsTitle, rhsIsActive) = rhs {
                return lhsTitle == rhsTitle && lhsIsActive == rhsIsActive
            }
            return false
            
        case let .avatarFontHeader(lhsTitle):
            if case let .avatarFontHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .avatarFont(lhsTitle, lhsIsActive):
            if case let .avatarFont(rhsTitle, rhsIsActive) = rhs {
                return lhsTitle == rhsTitle && lhsIsActive == rhsIsActive
            }
            return false

        case let .avatarFontFooter(lhsTitle):
            if case let .avatarFontFooter(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .iconsHeader(lhsTitle):
            if case let .iconsHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .vkIcons(lhsTitle, lhsIsActive):
            if case let .vkIcons(rhsTitle, rhsIsActive) = rhs {
                return lhsTitle == rhsTitle && lhsIsActive == rhsIsActive
            }
            return false

        case let .iconsPreview(lhsTheme):
            if case let .iconsPreview(rhsTheme) = rhs {
                return lhsTheme === rhsTheme
            }
            return false
        }
    }
    
    static func <(lhs: DAppearanceSettingsEntry, rhs: DAppearanceSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DAppearanceSettingsArguments
        switch self {
        case let .chatsAppearanceHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .showCustomWallpaperInChannels(title, isActive):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: isActive,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateShowCustomWallpaperInChannels(value)
                }
            )
            
        case let .showChannelBottomPanel(title, isActive):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: isActive,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateChannelBottomPanel(value)
                }
            )
            
        case let .listViewTypeHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .listViewTypeOption(title, type, isSelected):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: title,
                style: .right,
                textColor: .primary,
                checked: isSelected,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.updateChatsListViewType(type)
                }
            )
            
        case let .menuItemsHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .menuItems(title, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openSettingsItemsConfiguration()
                }
            )
            
        case let .tabBar(title, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openTabBarSettings()
                }
            )
            
        case let .viewRoundingHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .viewRounding(title, isActive):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: isActive,
                sectionId: section,
                style: .blocks) { value in
                    arguments.updateViewRounding(value)
                }
            
        case let .avatarFontHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .avatarFont(title, isActive):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: isActive,
                sectionId: section,
                style: .blocks) { value in
                    arguments.updateAlternativeFontInAvatars(value)
                }
            
        case let .avatarFontFooter(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .custom(context: arguments.context, string: text),
                sectionId: self.section,
                style: .blocks,
                additionalInsets: UIEdgeInsets(top: -12.0, left: 0.0, bottom: 0.0, right: 0.0)
            )
            
        case let .iconsHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .vkIcons(title, isActive):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: isActive,
                sectionId: section,
                style: .blocks) { value in
                    arguments.updateVKIcons(value)
                }

        case .iconsPreview:
            return DIconSetPreviewItem(
                presentationData: presentationData,
                sectionId: section
            )
        }
    }
}

public func dAppearanceSettingsController(
    context: AccountContext
) -> ViewController {
    var openSettingsItemsConfiguration: (() -> Void)?
    var openTabBarSettings: (() -> Void)?
    var showRestartToast: (() -> Void)?
    
    let arguments = DAppearanceSettingsArguments(
        context: context,
        updateShowCustomWallpaperInChannels: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.appearanceSettings.showCustomWallpaperInChannels = value
                return updatedSettings
            }
            .start()
        },
        updateChannelBottomPanel: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.appearanceSettings.showChannelBottomPanel = value
                return updatedSettings
            }
            .start()
        },
        updateChatsListViewType: { selectedType in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.chatsListViewType = selectedType
                return updatedSettings
            }
            .start()
        },
        openSettingsItemsConfiguration: {
            openSettingsItemsConfiguration?()
        },
        openTabBarSettings: {
            openTabBarSettings?()
        },
        updateViewRounding: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.appearanceSettings.squareStyle = value
                return updatedSettings
            }
            .start()
        },
        updateVKIcons: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.appearanceSettings.vkIcons = value
                return updatedSettings
            }
            .start()
        },
        updateAlternativeFontInAvatars: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.appearanceSettings.alternativeAvatarFont = value
                return updatedSettings
            }
            .start()
            
            if DFontManager.shared.isAlternativeFontEnabled != value {
                showRestartToast?()
            }
        }
    )
    
    let dahlSettingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    |> map { sharedData -> DalSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
    } |> distinctUntilChanged
    
    let signal = combineLatest(
        context.sharedContext.presentationData,
        dahlSettingsSignal
    ) |> map { presentationData, dahlSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        
        let lang = presentationData.strings.baseLanguageCode
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.Appearance.Title".tp_loc(lang: lang)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        
        var entries: [DAppearanceSettingsEntry] = []
        
        entries.append(.chatsAppearanceHeader(title: "DahlSettings.Appearance.Chats.Header".tp_loc(lang: lang).uppercased()))
        entries.append(
            .showCustomWallpaperInChannels(
                title: "DahlSettings.Appearance.Chats.CustomChannelWallpapers".tp_loc(lang: lang),
                isActive: dahlSettings.appearanceSettings.showCustomWallpaperInChannels
            )
        )
        entries.append(
            .showChannelBottomPanel(
                title: "DahlSettings.Appearance.Chats.ChannelBottomPanel".tp_loc(lang: lang),
                isActive: dahlSettings.appearanceSettings.showChannelBottomPanel
            )
        )
        
        entries.append(
            .listViewTypeHeader(title: "DahlSettings.Appearance.ChatsList.Header".tp_loc(lang: lang).uppercased())
        )
        
        let options: [(String, ListViewType)] = [
            ("DahlSettings.ChatsList.SingleLine".tp_loc(lang: lang), .singleLine),
            ("DahlSettings.ChatsList.DoubleLine".tp_loc(lang: lang), .doubleLine),
            ("DahlSettings.ChatsList.TripleLine".tp_loc(lang: lang), .tripleLine)
        ]
        
        
        for (title, type) in options {
            entries.append(
                .listViewTypeOption(
                    title: title,
                    type: type,
                    isSelected: type == dahlSettings.chatsListViewType
                )
            )
        }
        
        entries.append(
            .menuItemsHeader(title: "DahlSettings.Appearance.MenuItems.Header".tp_loc(lang: lang).uppercased())
        )
        
        entries.append(
            .menuItems(
                title: "DahlSettings.Appearance.MenuItems".tp_loc(lang: lang),
                detail: "\(dahlSettings.menuItemsSettings.activeItemsCount)"
            )
        )
        
        entries.append(
            .tabBar(
                title: "DahlSettings.TabBarSettings.Title".tp_loc(lang: lang),
                detail: "\(dahlSettings.tabBarSettings.activeTabs.count)"
            )
        )
        
        entries.append(
            .viewRoundingHeader(
                title: "DahlSettings.Appearance.ViewRounding.Header".tp_loc(lang: lang).uppercased()
            )
        )
        
        entries.append(
            .viewRounding(
                title: "DahlSettings.Appearance.ViewRounding".tp_loc(lang: lang),
                isActive: dahlSettings.appearanceSettings.squareStyle
            )
        )
        
        entries.append(
            .avatarFontHeader(
                title: "DahlSettings.Appearance.AvatarFont.Header".tp_loc(lang: lang).uppercased()
            )
        )
        
        entries.append(
            .avatarFont(
                title: "DahlSettings.Appearance.AvatarFont".tp_loc(lang: lang),
                isActive: dahlSettings.appearanceSettings.alternativeAvatarFont
            )
        )
        
        let tableFont = Font.regular(13.0)
        let presentationData = arguments.context.sharedContext.currentPresentationData.with { $0 }
        let footerTextColor = presentationData.theme.list.sectionHeaderTextColor
        let footerHighlightColor = presentationData.theme.list.itemPrimaryTextColor
        let avatarFontString = NSMutableAttributedString(string: "DahlSettings.Appearance.AvatarFont.Footer".tp_loc(lang: lang), font: tableFont, paragraphAlignment: .left)
        var highlightStartPosition: Int = 0
        if let highlightIndex = avatarFontString.string.firstIndex(of: ":") {
            highlightStartPosition = avatarFontString.string.distance(from: avatarFontString.string.startIndex, to: highlightIndex) + 1
        }
        avatarFontString.addAttribute(.foregroundColor, value: footerTextColor, range: NSRange(location: 0, length: highlightStartPosition))
        avatarFontString.addAttribute(.foregroundColor, value: footerHighlightColor, range: NSRange(location: highlightStartPosition, length: avatarFontString.length - highlightStartPosition - 1))
        
        entries.append(
            .avatarFontFooter(text: avatarFontString)
        )
        
        entries.append(
            .iconsHeader(
                title: "DahlSettings.Appearance.Icons.Header".tp_loc(lang: lang).uppercased()
            )
        )
        
        entries.append(
            .vkIcons(
                title: "DahlSettings.Appearance.Icons.VKUI".tp_loc(lang: lang),
                isActive: dahlSettings.appearanceSettings.vkIcons
            )
        )
        
//        entries.append(.iconsPreview(presentationData.theme))
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    openTabBarSettings = { [weak controller] in
        let tabBarSettings = dTabBarSettingsController(context: context)
        controller?.push(tabBarSettings)
    }
    
    openSettingsItemsConfiguration = { [weak controller] in
        let menuItemSettings = dMenuItemsSettingsController(context: context)
        controller?.push(menuItemSettings)
    }
    
    showRestartToast = { [weak controller] in
        guard let controller else { return }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let lang = presentationData.strings.baseLanguageCode
        let presenting = UndoOverlayController(
            presentationData: presentationData,
            content: .info(
                title: nil,
                text: "DahlSettings.Common.RestartRequired".tp_loc(lang: lang),
                timeout: nil,
                customUndoText: "DahlSettings.Common.RestartNow".tp_loc(lang: lang)
            ),
            elevatedLayout: false,
            action: { action in if action == .undo { exit(0) }; return true }
        )
        controller.present(presenting, in: .window(.root))
    }
    
    return controller
}

private extension MenuItemsSettings {
    
    var activeItemsCount: Int {
        var count = 0
        if myProfile { count += 1 }
        if wallet { count += 1 }
        if savedMessages { count += 1 }
        if recentCalls { count += 1 }
        if devices { count += 1 }
        if chatFolders { count += 1 }
        if myStars { count += 1 }
        if business { count += 1 }
        if sendGift { count += 1 }
        if support { count += 1 }
        if faq { count += 1 }
        if tips { count += 1 }
        return count
    }
}
