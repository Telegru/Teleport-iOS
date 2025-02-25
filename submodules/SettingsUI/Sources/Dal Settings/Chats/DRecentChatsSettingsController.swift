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

private final class DRecentChatsSettingsControllerArguments {
    let context: AccountContext
    let updateShowRecentChats: (Bool) -> Void

    init(context: AccountContext, updateShowRecentChats: @escaping (Bool) -> Void) {
        self.context = context
        self.updateShowRecentChats = updateShowRecentChats
    }
}

private enum DRecentChatsSettingsSection: Int32 {
    case toggle
}

private enum DRecentChatsSettingsEntry: ItemListNodeEntry {
    case toggleRecentChats(PresentationTheme, String, Bool)
    case info(PresentationTheme, String)
    
    var section: ItemListSectionId {
        return 0
    }
    
    var stableId: Int32 {
        switch self {
        case .toggleRecentChats:
            return 0
        case .info:
            return 1
        }
    }
    
    static func ==(lhs: DRecentChatsSettingsEntry, rhs: DRecentChatsSettingsEntry) -> Bool {
        switch lhs {
        case let .toggleRecentChats(lhsTheme, lhsText, lhsValue):
            if case let .toggleRecentChats(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            }
            return false
        case let .info(lhsTheme, lhsText):
            if case let .info(rhsTheme, rhsText) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText {
                return true
            }
            return false
        }
    }
    
    static func <(lhs: DRecentChatsSettingsEntry, rhs: DRecentChatsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DRecentChatsSettingsControllerArguments
        switch self {
        case let .toggleRecentChats(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowRecentChats(updatedValue)
                },
                tag: nil
            )
        case let .info(_, text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section,
                style: .blocks
            )
        }
    }
}


public func dRecentChatsSettingsController(context: AccountContext) -> ViewController {
    let arguments = DRecentChatsSettingsControllerArguments(
        context: context,
        updateShowRecentChats: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.showRecentChats = value
                return updatedSettings
            }
            .start()
        }
    )
    
    let showRecentChats = (
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
        |> map { sharedData -> Bool in
            let dalSettings: DalSettings
            if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) {
                dalSettings = entry
            } else {
                dalSettings = DalSettings.defaultSettings
            }
            return dalSettings.showRecentChats ?? false
        }
        |> distinctUntilChanged
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, showRecentChats)
    |> map { presentationData, showRecentChats -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.RecentChatsHeader".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let entries: [DRecentChatsSettingsEntry] = [
            .toggleRecentChats(
                presentationData.theme,
                "DahlSettings.EnablePanel".tp_loc(lang: presentationData.strings.baseLanguageCode),
                showRecentChats
            ),
            .info(
                presentationData.theme,
                "DahlSettings.RecentChatsInfo".tp_loc(lang: presentationData.strings.baseLanguageCode)
            )
        ]
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
