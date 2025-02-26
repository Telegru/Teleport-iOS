import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramUIPreferences
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class DMenuItemsSettingsArguments {
    
    let updateMyProfile: (Bool) -> Void
    let updateWallet: (Bool) -> Void
    let updateSavedMessages: (Bool) -> Void
    let updateRecentCalls: (Bool) -> Void
    let updateDevices: (Bool) -> Void
    let updateChatFolders: (Bool) -> Void
    let updatePremium: (Bool) -> Void
    let updateMyStars: (Bool) -> Void
    let updateBusiness: (Bool) -> Void
    let updateSendGift: (Bool) -> Void
    let updateSupport: (Bool) -> Void
    let updateFaq: (Bool) -> Void
    let updateTips: (Bool) -> Void
    
    init(
        updateMyProfile: @escaping (Bool) -> Void,
        updateWallet: @escaping (Bool) -> Void,
        updateSavedMessages: @escaping (Bool) -> Void,
        updateRecentCalls: @escaping (Bool) -> Void,
        updateDevices: @escaping (Bool) -> Void,
        updateChatFolders: @escaping (Bool) -> Void,
        updatePremium: @escaping (Bool) -> Void,
        updateMyStars: @escaping (Bool) -> Void,
        updateBusiness: @escaping (Bool) -> Void,
        updateSendGift: @escaping (Bool) -> Void,
        updateSupport: @escaping (Bool) -> Void,
        updateFaq: @escaping (Bool) -> Void,
        updateTips: @escaping (Bool) -> Void
    ) {
        self.updateMyProfile = updateMyProfile
        self.updateWallet = updateWallet
        self.updateSavedMessages = updateSavedMessages
        self.updateRecentCalls = updateRecentCalls
        self.updateDevices = updateDevices
        self.updateChatFolders = updateChatFolders
        self.updatePremium = updatePremium
        self.updateMyStars = updateMyStars
        self.updateBusiness = updateBusiness
        self.updateSendGift = updateSendGift
        self.updateSupport = updateSupport
        self.updateFaq = updateFaq
        self.updateTips = updateTips
    }
}

private enum DMenuItemsSettingsSection: Int32 {
    case main
}

private enum DMenuItemsSettingsEntrytag: ItemListItemTag{
    
    case myProfile
    case wallet
    case savedMessages
    case recentCalls
    case devices
    case chatFolders
    case premium
    case myStars
    case business
    case sendGift
    case support
    case faq
    case tips
    
    public func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DMenuItemsSettingsEntrytag, self == other {
            return true
        }
        return false
    }
}

private enum DMenuItemsSettingsEntry: ItemListNodeEntry {
  
    case myProfile(PresentationTheme, String, Bool)
    case wallet(PresentationTheme, String, Bool)
    case savedMessages(PresentationTheme, String, Bool)
    case recentCalls(PresentationTheme, String, Bool)
    case devices(PresentationTheme, String, Bool)
    case chatFolders(PresentationTheme, String, Bool)
    case premium(PresentationTheme, String, Bool)
    case myStars(PresentationTheme, String, Bool)
    case business(PresentationTheme, String, Bool)
    case sendGift(PresentationTheme, String, Bool)
    case support(PresentationTheme, String, Bool)
    case faq(PresentationTheme, String, Bool)
    case tips(PresentationTheme, String, Bool)
    
    var section: ItemListSectionId {
        return DMenuItemsSettingsSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case .myProfile:
            return 0
        case .wallet:
            return 1
        case .savedMessages:
            return 2
        case .recentCalls:
            return 3
        case .devices:
            return 4
        case .chatFolders:
            return 5
        case .premium:
            return 6
        case .myStars:
            return 7
        case .business:
            return 8
        case .sendGift:
            return 9
        case .support:
            return 10
        case .faq:
            return 11
        case .tips:
            return 12
        }
    }
    
    var tag: ItemListItemTag? {
        switch self{
        case .myProfile:
            return DMenuItemsSettingsEntrytag.myProfile
        case .wallet:
            return DMenuItemsSettingsEntrytag.wallet
        case .savedMessages:
            return DMenuItemsSettingsEntrytag.savedMessages
        case .recentCalls:
            return DMenuItemsSettingsEntrytag.recentCalls
        case .devices:
            return DMenuItemsSettingsEntrytag.devices
        case .chatFolders:
            return DMenuItemsSettingsEntrytag.chatFolders
        case .premium:
            return DMenuItemsSettingsEntrytag.premium
        case .myStars:
            return DMenuItemsSettingsEntrytag.myStars
        case .business:
            return DMenuItemsSettingsEntrytag.business
        case .sendGift:
            return DMenuItemsSettingsEntrytag.sendGift
        case .support:
            return DMenuItemsSettingsEntrytag.support
        case .faq:
            return DMenuItemsSettingsEntrytag.faq
        case .tips:
            return DMenuItemsSettingsEntrytag.tips
        }
    }
    
    static func ==(lhs: DMenuItemsSettingsEntry, rhs: DMenuItemsSettingsEntry) -> Bool {
        switch lhs {
        case let .myProfile(lhsTheme, lhsText, lhsValue):
            if case let .myProfile(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .wallet(lhsTheme, lhsText, lhsValue):
            if case let .wallet(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .savedMessages(lhsTheme, lhsText, lhsValue):
            if case let .savedMessages(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .recentCalls(lhsTheme, lhsText, lhsValue):
            if case let .recentCalls(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .devices(lhsTheme, lhsText, lhsValue):
            if case let .devices(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .chatFolders(lhsTheme, lhsText, lhsValue):
            if case let .chatFolders(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .premium(lhsTheme, lhsText, lhsValue):
            if case let .premium(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .myStars(lhsTheme, lhsText, lhsValue):
            if case let .myStars(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .business(lhsTheme, lhsText, lhsValue):
            if case let .business(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .sendGift(lhsTheme, lhsText, lhsValue):
            if case let .sendGift(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .support(lhsTheme, lhsText, lhsValue):
            if case let .support(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .faq(lhsTheme, lhsText, lhsValue):
            if case let .faq(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .tips(lhsTheme, lhsText, lhsValue):
            if case let .tips(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: DMenuItemsSettingsEntry, rhs: DMenuItemsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DMenuItemsSettingsArguments
       
        switch self {
        case let .myProfile(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateMyProfile(updatedValue)
                },
                tag: self.tag
            )
        case let .wallet(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateWallet(updatedValue)
                },
                tag: self.tag
            )
        case let .savedMessages(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateSavedMessages(updatedValue)
                },
                tag: self.tag
            )
        case let .recentCalls(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateRecentCalls(updatedValue)
                },
                tag: self.tag
            )
        case let .devices(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateDevices(updatedValue)
                },
                tag: self.tag
            )
        case let .chatFolders(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateChatFolders(updatedValue)
                },
                tag: self.tag
            )
        case let .premium(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updatePremium(updatedValue)
                },
                tag: self.tag
            )
        case let .myStars(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateMyStars(updatedValue)
                },
                tag: self.tag
            )
        case let .business(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateBusiness(updatedValue)
                },
                tag: self.tag
            )
        case let .sendGift(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateSendGift(updatedValue)
                },
                tag: self.tag
            )
        case let .support(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateSupport(updatedValue)
                },
                tag: self.tag
            )
        case let .faq(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateFaq(updatedValue)
                },
                tag: self.tag
            )
        case let .tips(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateTips(updatedValue)
                },
                tag: self.tag
            )
        }
    }
}

private func menuItemsSettingsEntries(from settings: MenuItemsSettings, presentationData data: PresentationData) -> [DMenuItemsSettingsEntry] {
    [
        .myProfile(data.theme, data.strings.Settings_MyProfile, settings.myProfile),
        .wallet(data.theme, "Wallet.TabTitle".tp_loc(lang: data.strings.baseLanguageCode), settings.wallet),
        .savedMessages(data.theme, data.strings.Settings_SavedMessages, settings.savedMessages),
        .recentCalls(data.theme, data.strings.CallSettings_RecentCalls, settings.recentCalls),
        .devices(data.theme, data.strings.Settings_Devices, settings.devices),
        .chatFolders(data.theme, data.strings.Settings_ChatFolders, settings.chatFolders),
        .myStars(data.theme, data.strings.Settings_Stars, settings.myStars),
        .business(data.theme, data.strings.Settings_Business, settings.business),
        .sendGift(data.theme, data.strings.Settings_SendGift, settings.sendGift),
        .support(data.theme, data.strings.Settings_Support, settings.support),
        .faq(data.theme, data.strings.Settings_FAQ, settings.faq),
        .tips(data.theme, data.strings.Settings_Tips, settings.tips),
    ]
}

public func dMenuItemsSettingsController(context: AccountContext) -> ViewController {
    
    let arguments = DMenuItemsSettingsArguments { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.myProfile = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateWallet: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.wallet = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateSavedMessages: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.savedMessages = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateRecentCalls: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.recentCalls = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateDevices: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.devices = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateChatFolders: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.chatFolders = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updatePremium: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.premium = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateMyStars: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.myStars = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateBusiness: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.business = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateSendGift: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.sendGift = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateSupport: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.support = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateFaq: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.faq = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    } updateTips: { value in
        let _ = updateDalSettingsInteractively(
            accountManager: context.sharedContext.accountManager,
            { settings in
                var settings = settings
                var itemsSettings = settings.menuItemsSettings
                itemsSettings.tips = value
                settings.menuItemsSettings = itemsSettings
                return settings
            }
        ).start()
    }

    
    let menuItemsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    |> map {
        $0.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self)?.menuItemsSettings ?? MenuItemsSettings.default
    }
    |> take(1)
    |> mapToSignal { settings -> Signal<MenuItemsSettings, NoError> in
        return .single(settings)
    }
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        menuItemsSignal
    )
    |> map{ presentationData, settings in
        let entries = menuItemsSettingsEntries(from: settings, presentationData: presentationData)
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.MenuItems".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    return controller
}
