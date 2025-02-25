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

private final class DChatsSettingsControllerArguments {
    let context: AccountContext
    let updateChatsListViewType: (ListViewType) -> Void
    let pushController: (ViewController) -> Void

    init(
        context: AccountContext,
        updateChatsListViewType: @escaping (ListViewType) -> Void,
        pushController: @escaping (ViewController) -> Void
    ) {
        self.context = context
        self.updateChatsListViewType = updateChatsListViewType
        self.pushController = pushController
    }
}

private enum DChatsSettingsSection: Int32 {
    case listViewType
    case recentChats
}

private enum DChatsSettingsEntry: ItemListNodeEntry {
    case listViewTypeHeader(String)
    case listViewTypeOption(String, ListViewType, Bool)
    case recentChats(PresentationTheme, String, Bool)
    
    var section: ItemListSectionId {
        switch self {
        case .listViewTypeHeader, .listViewTypeOption:
            return DChatsSettingsSection.listViewType.rawValue
        case .recentChats:
            return DChatsSettingsSection.recentChats.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .listViewTypeHeader:
            return 0
        case let .listViewTypeOption(_, type, _):
            return Int32(type.rawValue + 100)
        case .recentChats:
            return 1000
        }
    }

    static func ==(lhs: DChatsSettingsEntry, rhs: DChatsSettingsEntry) -> Bool {
        switch lhs {
        case let .listViewTypeHeader(lhsText):
            if case let .listViewTypeHeader(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        case let .listViewTypeOption(lhsText, lhsType, lhsSelected):
            if case let .listViewTypeOption(rhsText, rhsType, rhsSelected) = rhs {
                return lhsText == rhsText && lhsType == rhsType && lhsSelected == rhsSelected
            }
            return false
        case let .recentChats(lhsTheme, lhsText, lhsValue):
            if case let .recentChats(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            }
            return false
        }
    }

    static func <(lhs: DChatsSettingsEntry, rhs: DChatsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DChatsSettingsControllerArguments
        switch self {
        case let .listViewTypeHeader(text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
            
        case let .listViewTypeOption(text, type, selected):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: text,
                style: .right,
                textColor: .primary,
                checked: selected,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.updateChatsListViewType(type)
                }
            )
        
        case let .recentChats(_, text, _):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    let recentChatsController = dRecentChatsSettingsController(context: arguments.context)
                    arguments.pushController(recentChatsController)
                }
            )
        }
    }
}

// MARK: - Controller

public func dChatsSettingsController(
    context: AccountContext,
    tabBarItem: ItemListControllerTabBarItem? = nil
) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = DChatsSettingsControllerArguments(
        context: context,
        updateChatsListViewType: { selectedType in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.chatsListViewType = selectedType
                return updatedSettings
            }
            .start()
        },
        pushController: { controller in
            pushControllerImpl?(controller)
        }
    )
    
    let chatsListViewType = (
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
        |> map { sharedData -> ListViewType in
            let dalSettings: DalSettings
            if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) {
                dalSettings = entry
            } else {
                dalSettings = DalSettings.defaultSettings
            }
            return dalSettings.chatsListViewType
        }
        |> distinctUntilChanged
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
    
    let signal = combineLatest(context.sharedContext.presentationData, chatsListViewType, showRecentChats)
    |> map { presentationData, chatsListViewType, showRecentChats -> (ItemListControllerState, (ItemListNodeState, Any)) in
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.ChatsList".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )

        var entries: [DChatsSettingsEntry] = []
        entries.append(.listViewTypeHeader("DahlSettings.ChatsList.ListView".tp_loc(lang: presentationData.strings.baseLanguageCode).uppercased()))

        let options: [(String, ListViewType)] = [
            ("DahlSettings.ChatsList.SingleLine".tp_loc(lang: presentationData.strings.baseLanguageCode), .singleLine),
            ("DahlSettings.ChatsList.DoubleLine".tp_loc(lang: presentationData.strings.baseLanguageCode), .doubleLine),
            ("DahlSettings.ChatsList.TripleLine".tp_loc(lang: presentationData.strings.baseLanguageCode), .tripleLine)
        ]

        for (title, type) in options {
            entries.append(.listViewTypeOption(title, type, type == chatsListViewType))
        }
        
        entries.append(.recentChats(
            presentationData.theme,
            "DahlSettings.RecentChatsHeader".tp_loc(lang: presentationData.strings.baseLanguageCode),
            showRecentChats
        ))
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller: ItemListController
    
    if let tabBarItem {
        controller = ItemListController(context: context, state: signal, tabBarItem: .single(tabBarItem))
    } else {
        controller = ItemListController(context: context, state: signal)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
