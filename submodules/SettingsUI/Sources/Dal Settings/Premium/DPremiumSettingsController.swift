import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

import TPStrings

private final class DPremiumSettingsArguments {
    let context: AccountContext
    
    let updateShowStatusIcon: (Bool) -> Void
    let updateShowAnimatedAvatar: (Bool) -> Void
    let updateShowAnimatedReactions: (Bool) -> Void
    let updateShowPremiumStickerAnimation: (Bool) -> Void
    let updateShowCustomWallpaperInChannels: (Bool) -> Void
    
    init(
        context: AccountContext,
        updateShowStatusIcon: @escaping (Bool) -> Void,
        updateShowAnimatedAvatar: @escaping (Bool) -> Void,
        updateShowAnimatedReactions: @escaping (Bool) -> Void,
        updateShowPremiumStickerAnimation: @escaping (Bool) -> Void,
        updateShowCustomWallpaperInChannels: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.updateShowStatusIcon = updateShowStatusIcon
        self.updateShowAnimatedAvatar = updateShowAnimatedAvatar
        self.updateShowAnimatedReactions = updateShowAnimatedReactions
        self.updateShowPremiumStickerAnimation = updateShowPremiumStickerAnimation
        self.updateShowCustomWallpaperInChannels = updateShowCustomWallpaperInChannels
    }
}

private enum DPremiumSettingsSection: Int32, CaseIterable {
    case main
}

private enum DPremiumSettingsEntryTag: ItemListItemTag {
    
    case showStatusIcon
    case showAnimatedAvatar
    case showAnimatedReactions
    case showPremiumStickerAnimation
    case showCustomWallpaperInChannels
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DPremiumSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DPremiumSettingsEntry: ItemListNodeEntry {
    case showStatusIcon(Bool)
    case showAnimatedAvatar(Bool)
    case showAnimatedReactions(Bool)
    case showPremiumStickerAnimation(Bool)
    case showCustomWallpaperInChannels(Bool)
    
    var section: ItemListSectionId {
        DPremiumSettingsSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case .showStatusIcon: return 0
        case .showAnimatedAvatar: return 1
        case .showAnimatedReactions: return 2
        case .showPremiumStickerAnimation: return 3
        case .showCustomWallpaperInChannels: return 4
        }
    }
    
    var tag: ItemListItemTag {
        switch self {
        case .showStatusIcon:
            return DPremiumSettingsEntryTag.showStatusIcon
        case .showAnimatedAvatar:
            return DPremiumSettingsEntryTag.showAnimatedAvatar
        case .showAnimatedReactions:
            return DPremiumSettingsEntryTag.showAnimatedReactions
        case .showPremiumStickerAnimation:
            return DPremiumSettingsEntryTag.showPremiumStickerAnimation
        case .showCustomWallpaperInChannels:
            return DPremiumSettingsEntryTag.showCustomWallpaperInChannels
        }
    }
    
    static func ==(
        lhs: DPremiumSettingsEntry,
        rhs: DPremiumSettingsEntry
    ) -> Bool {
        switch lhs {
        case let .showStatusIcon(lhsValue):
            guard case let .showStatusIcon(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue
        
        case let .showAnimatedAvatar(lhsValue):
            guard case let .showAnimatedAvatar(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue
            
        case let .showAnimatedReactions(lhsValue):
            guard case let .showAnimatedReactions(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue
            
        case let .showPremiumStickerAnimation(lhsValue):
            guard case let .showPremiumStickerAnimation(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue
            
        case let .showCustomWallpaperInChannels(lhsValue):
            guard case let .showCustomWallpaperInChannels(rhsValue) = rhs else { return false }
            return lhsValue == rhsValue
        }
    }
    
    static func <(
        lhs: DPremiumSettingsEntry,
        rhs: DPremiumSettingsEntry
    ) -> Bool {
        lhs.stableId < rhs.stableId
    }
    
    func item(
        presentationData: ItemListPresentationData,
        arguments: Any
    ) -> ListViewItem {
        let arguments = arguments as! DPremiumSettingsArguments
        let lang = presentationData.strings.baseLanguageCode
        
        switch self {
        case let .showStatusIcon(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.Status".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowStatusIcon(updatedValue)
                },
                tag: tag
            )
            
        case let .showAnimatedAvatar(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedAvatars".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowAnimatedAvatar(updatedValue)
                },
                tag: tag
            )
            
        case let .showAnimatedReactions(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedReactions".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowAnimatedReactions(updatedValue)
                },
                tag: tag
            )
            
        case let .showPremiumStickerAnimation(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.AnimatedPremiumStickers".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowPremiumStickerAnimation(updatedValue)
                },
                tag: tag
            )
            
        case let .showCustomWallpaperInChannels(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: "DahlSettings.PremiumSettings.CustomChannelWallpapers".tp_loc(lang: lang),
                value: value,
                sectionId: section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowCustomWallpaperInChannels(updatedValue)
                },
                tag: tag
            )
        }
    }
}

private func dPremiumSettingsEntries(
    showStatusIcon: Bool,
    showAnimatedAvatar: Bool,
    showAnimatedReactions: Bool,
    showPremiumStickerAnimation: Bool,
    showCustomWallpaperInChannels: Bool
) -> [DPremiumSettingsEntry] {
    var entries = [DPremiumSettingsEntry]()
    
    entries.append(.showStatusIcon(showStatusIcon))
    entries.append(.showAnimatedAvatar(showAnimatedAvatar))
    entries.append(.showAnimatedReactions(showAnimatedReactions))
    entries.append(.showPremiumStickerAnimation(showPremiumStickerAnimation))
    entries.append(.showCustomWallpaperInChannels(showCustomWallpaperInChannels))
    
    return entries
}

public func dPremiumSettingsController(
    context: AccountContext
) -> ViewController {
    let arguments = DPremiumSettingsArguments(
        context: context) { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showStatusIcon = value
                    return settings
                }
            ).start()
        } updateShowAnimatedAvatar: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showAnimatedAvatar = value
                    return settings
                }
            ).start()
        } updateShowAnimatedReactions: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showAnimatedReactions = value
                    return settings
                }
            ).start()
        } updateShowPremiumStickerAnimation: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showPremiumStickerAnimation = value
                    return settings
                }
            ).start()
        } updateShowCustomWallpaperInChannels: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.premiumSettings.showCustomWallpaperInChannels = value
                    return settings
                }
            ).start()
        }

    let sharedData = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    
    let signal = combineLatest(
        sharedData,
        context.sharedContext.presentationData,
        context.account.postbox.preferencesView(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    )
    |> map { sharedData, presentationData, preferences -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
        
        let entries = dPremiumSettingsEntries(
            showStatusIcon: settings.premiumSettings.showStatusIcon,
            showAnimatedAvatar: settings.premiumSettings.showAnimatedAvatar,
            showAnimatedReactions: settings.premiumSettings.showAnimatedReactions,
            showPremiumStickerAnimation: settings.premiumSettings.showPremiumStickerAnimation,
            showCustomWallpaperInChannels: settings.premiumSettings.showCustomWallpaperInChannels
        )
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .navigationItemTitle("DahlSettings.PremiumSettings.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
