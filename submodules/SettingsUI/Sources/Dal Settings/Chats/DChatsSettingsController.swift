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

    init(
        context: AccountContext,
        updateChatsListViewType: @escaping (ListViewType) -> Void
    ) {
        self.context = context
        self.updateChatsListViewType = updateChatsListViewType
    }
}

private enum DChatsSettingsSection: Int32 {
    case listViewType
}

private enum DChatsSettingsEntry: ItemListNodeEntry {
    case listViewTypeHeader(String)
    case listViewTypeOption(String, ListViewType, Bool)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .listViewTypeHeader:
            return 0
        case let .listViewTypeOption(_, type, _):
            return Int32(type.rawValue + 100)
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
        }
    }
}

// MARK: - Controller

public func dChatsSettingsController(context: AccountContext) -> ViewController {
    let arguments = DChatsSettingsControllerArguments(
        context: context,
        updateChatsListViewType: { selectedType in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var updatedSettings = settings
                updatedSettings.chatsListViewType = selectedType
                return updatedSettings
            }
            .start()
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
    |> distinctUntilChanged)

    
    let signal = combineLatest(context.sharedContext.presentationData, chatsListViewType)
    |> map { presentationData, chatsListViewType -> (ItemListControllerState, (ItemListNodeState, Any)) in
        
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

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    return controller
}
