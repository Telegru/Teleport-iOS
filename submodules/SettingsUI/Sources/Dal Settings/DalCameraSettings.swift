import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ItemListUI
import AccountContext
import PresentationDataUtils
import TelegramUIPreferences



import TPStrings

private final class DalCameraSettingsArguments {
    let updateSelectedCamera: (String) -> Void

    init(updateSelectedCamera: @escaping (String) -> Void) {
        self.updateSelectedCamera = updateSelectedCamera
    }
}

private enum DalCameraSettingsSection: Int32 {
    case main
}

private enum DalCameraSettingsEntry: ItemListNodeEntry {
    case frontCamera(PresentationTheme, String, Bool)
    case backCamera(PresentationTheme, String, Bool)
    case askBeforeRecord(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        return DalCameraSettingsSection.main.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .frontCamera:
            return 0
        case .backCamera:
            return 1
        case .askBeforeRecord:
            return 2
        }
    }

    static func ==(lhs: DalCameraSettingsEntry, rhs: DalCameraSettingsEntry) -> Bool {
        switch lhs {
        case let .frontCamera(lhsTheme, lhsText, lhsValue):
            if case let .frontCamera(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .backCamera(lhsTheme, lhsText, lhsValue):
            if case let .backCamera(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .askBeforeRecord(lhsTheme, lhsText, lhsValue):
            if case let .askBeforeRecord(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        }
    }

    static func <(lhs: DalCameraSettingsEntry, rhs: DalCameraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DalCameraSettingsArguments
        switch self {
        case let .frontCamera(_, text, value):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: text,
                style: .left,
                checked: value,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.updateSelectedCamera(CameraType.front.rawValue)
                }
            )
        case let .backCamera(_, text, value):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: text,
                style: .left,
                checked: value,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.updateSelectedCamera(CameraType.back.rawValue)
                }
            )
        case let .askBeforeRecord(_, text, value):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                title: text,
                style: .left,
                checked: value,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.updateSelectedCamera(CameraType.undefined.rawValue)
                }
            )
        }
    }
}

private func dalCameraSettingsEntries(selectedCamera: String, presentationData: PresentationData) -> [DalCameraSettingsEntry] {
    return [
        .frontCamera(presentationData.theme, "DahlSettings.FrontCamera".tp_loc(lang: presentationData.strings.baseLanguageCode), selectedCamera == CameraType.front.rawValue),
        .backCamera(presentationData.theme, "DahlSettings.BackCamera".tp_loc(lang: presentationData.strings.baseLanguageCode), selectedCamera == CameraType.back.rawValue),
        .askBeforeRecord(presentationData.theme, "DahlSettings.AskBeforeRecording".tp_loc(lang: presentationData.strings.baseLanguageCode), selectedCamera == CameraType.undefined.rawValue)
    ]
}

public func dalCameraSettingsController(context: AccountContext, updateCamera: @escaping (String) -> Void) -> ViewController {
    let arguments = DalCameraSettingsArguments(updateSelectedCamera: { newCamera in
        updateCamera(newCamera)
    })

    let selectedCamera = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    |> map { sharedData -> CameraType in
        let dalSettings: DalSettings
        if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) {
            dalSettings = entry
        } else {
            dalSettings = DalSettings.defaultSettings
        }
        return dalSettings.videoMessageCamera
    }
    |> distinctUntilChanged)

    
    let signal = combineLatest(context.sharedContext.presentationData, selectedCamera)
    |> map { presentationData, selectedCamera -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = dalCameraSettingsEntries(selectedCamera: selectedCamera.rawValue, presentationData: presentationData)
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.VideoMessage".tp_loc(lang: presentationData.strings.baseLanguageCode)),
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
