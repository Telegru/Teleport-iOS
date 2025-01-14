import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI
import TelegramNotices
import NotificationSoundSelectionUI
import TelegramStringFormatting


import TPStrings

private final class DalSettingsArguments {
    let context: AccountContext
    let presentController: (ViewController, ViewControllerPresentationArguments?) -> Void
    let pushController: (ViewController) -> Void

    let updateHidePublishStoriesButton: (Bool) -> Void
    let updateHideStories: (Bool) -> Void
    let updateHideViewedStories: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let updateDisableReadHistory: (Bool) -> Void
    let updateOfflineMode: (Bool) -> Void
    let openCameraSettings: (String) -> Void

    init(
        context: AccountContext,
        presentController: @escaping (ViewController, ViewControllerPresentationArguments?) -> Void,
        pushController: @escaping (ViewController) -> Void,
        updateHidePublishStoriesButton: @escaping (Bool) -> Void,
        updateHideStories: @escaping (Bool) -> Void,
        updateHideViewedStories: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        updateDisableReadHistory: @escaping (Bool) -> Void,
        updateOfflineMode: @escaping (Bool) -> Void,
        openCameraSettings: @escaping (String) -> Void
    ) {
        self.context = context
        self.presentController = presentController
        self.pushController = pushController
        self.updateHidePublishStoriesButton = updateHidePublishStoriesButton
        self.updateHideStories = updateHideStories
        self.updateHideViewedStories = updateHideViewedStories
        self.updateHidePhone = updateHidePhone
        self.updateDisableReadHistory = updateDisableReadHistory
        self.updateOfflineMode = updateOfflineMode
        self.openCameraSettings = openCameraSettings
    }
}

private enum DalSettingsSection: Int32 {
    case stories
    case confidentiality
    case camera
}

public enum DalSettingsEntryTag: ItemListItemTag {
    case hidePublishStoriesButton
    case hideStories
    case hideViewedStories
    case hidePhone
    case disableReadHistory
    case offlineMode
    case cameraChoice

    public func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DalSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DalSettingsEntry: ItemListNodeEntry {
    case storiesHeader(PresentationTheme, String)
    case privacyHeader(PresentationTheme, String)
    case cameraHeader(PresentationTheme, String)

    // Раздел Stories
    case hidePublishStoriesButton(PresentationTheme, String, Bool)
    case hideStories(PresentationTheme, String, Bool)
    case hideViewedStories(PresentationTheme, String, Bool)
    
    // Раздел Конфиденциальность
    case hidePhone(PresentationTheme, String, Bool)
    case disableReadHistory(PresentationTheme, String, Bool)
    case offlineMode(PresentationTheme, String, Bool)
    case cameraChoice(PresentationTheme, String, String)

    var section: ItemListSectionId {
        switch self {
            // Истории находятся в секции stories
        case .storiesHeader, .hidePublishStoriesButton, .hideStories, .hideViewedStories:
            return DalSettingsSection.stories.rawValue
            
        case .privacyHeader, .hidePhone, .disableReadHistory, .offlineMode:
            return DalSettingsSection.confidentiality.rawValue
        case .cameraHeader, .cameraChoice:
            return DalSettingsSection.camera.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .storiesHeader:
            return 0
        case .hidePublishStoriesButton:
            return 1
        case .hideStories:
            return 2
        case .hideViewedStories:
            return 3
        case .privacyHeader:
            return 4
        case .hidePhone:
            return 5
        case .disableReadHistory:
            return 6
        case .offlineMode:
            return 7
        case .cameraHeader:
            return 8
        case .cameraChoice:
            return 9
        }
    }

    var tag: ItemListItemTag? {
        switch self {
        case .hidePublishStoriesButton:
            return DalSettingsEntryTag.hidePublishStoriesButton
        case .hideStories:
            return DalSettingsEntryTag.hideStories
        case .hideViewedStories:
            return DalSettingsEntryTag.hideViewedStories
        case .hidePhone:
            return DalSettingsEntryTag.hidePhone
        case .offlineMode:
            return DalSettingsEntryTag.offlineMode
        case .disableReadHistory:
            return DalSettingsEntryTag.disableReadHistory
        case .cameraChoice:
            return DalSettingsEntryTag.cameraChoice
        case .storiesHeader, .privacyHeader, .cameraHeader:
            return nil
        }
    }

    static func ==(lhs: DalSettingsEntry, rhs: DalSettingsEntry) -> Bool {
        switch lhs {
        case let .hidePublishStoriesButton(lhsTheme, lhsText, lhsValue):
            if case let .hidePublishStoriesButton(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .hideStories(lhsTheme, lhsText, lhsValue):
            if case let .hideStories(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .hideViewedStories(lhsTheme, lhsText, lhsValue):
            if case let .hideViewedStories(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .hidePhone(lhsTheme, lhsText, lhsValue):
            if case let .hidePhone(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .disableReadHistory(lhsTheme, lhsText, lhsValue):
            if case let .disableReadHistory(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .offlineMode(lhsTheme, lhsText, lhsValue):
            if case let .offlineMode(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .cameraChoice(lhsTheme, lhsText, lhsValue):
            if case let .cameraChoice(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case .storiesHeader(_, _), .privacyHeader(_, _), .cameraHeader(_,_):
            if lhs.stableId != rhs.stableId {
                return false
            }
        }
        return true
    }

    static func <(lhs: DalSettingsEntry, rhs: DalSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DalSettingsArguments
        switch self {
            // Раздел Stories
        case let .hidePublishStoriesButton(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHidePublishStoriesButton(updatedValue)
                },
                tag: self.tag
            )
        case let .hideStories(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideStories(updatedValue)
                },
                tag: self.tag
            )
        case let .hideViewedStories(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideViewedStories(updatedValue)
                },
                tag: self.tag
            )
            // Раздел Конфиденциальность
        case let .hidePhone(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHidePhone(updatedValue)
                },
                tag: self.tag
            )
        case let .disableReadHistory(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateDisableReadHistory(updatedValue)
                },
                tag: self.tag
            )
        case let .offlineMode(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateOfflineMode(updatedValue)
                },
                tag: self.tag
            )
        case let .cameraChoice(_, text, selectedCamera):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: selectedCamera == "front" ?  "DahlSettings.FrontCamera".tp_loc(lang: presentationData.strings.baseLanguageCode) : "DahlSettings.BackCamera".tp_loc(lang: presentationData.strings.baseLanguageCode),
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openCameraSettings(selectedCamera)
                },
                tag: self.tag
            )
        case let .storiesHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case let .privacyHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case let .cameraHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        }
    }
}

private func dalSettingsEntries(
    hidePublishStoriesButton: Bool,
    hideStories: Bool,
    hideViewedStories: Bool,
    hidePhone: Bool,
    disableReadHistory: Bool,
    offlintMode: Bool,
    videoMessageCamera: CameraType,
    presentationData: PresentationData
) -> [DalSettingsEntry] {
    var entries: [DalSettingsEntry] = []
    let lang = presentationData.strings.baseLanguageCode
    
    entries.append(.storiesHeader(presentationData.theme, "DahlSettings.StoriesHeader".tp_loc(lang: lang).uppercased()))
    entries.append(.hidePublishStoriesButton(
        presentationData.theme,
        "DahlSettings.HidePublishStoriesButton".tp_loc(lang: lang),
        hidePublishStoriesButton
    ))
    entries.append(.hideStories(
        presentationData.theme,
        "DahlSettings.HideStories".tp_loc(lang: lang),
        hideStories
    ))
    entries.append(.hideViewedStories(
        presentationData.theme,
        "DahlSettings.HideViewedStories".tp_loc(lang: lang),
        hideViewedStories
    ))
    
    entries.append(.privacyHeader(presentationData.theme, "DahlSettings.PrivacyHeader".tp_loc(lang: lang).uppercased()))
    entries.append(.hidePhone(
        presentationData.theme,
        "DahlSettings.HidePhone".tp_loc(lang: lang),
        hidePhone
    ))
    entries.append(.disableReadHistory(
        presentationData.theme,
        "DahlSettings.HideActivity".tp_loc(lang: lang),
        disableReadHistory
    ))
    entries.append(.offlineMode(
        presentationData.theme,
        "DahlSettings.OfflineMode".tp_loc(lang: lang),
        offlintMode
    ))
    
    entries.append(.cameraHeader(presentationData.theme, "DahlSettings.Camera".tp_loc(lang: lang).uppercased()))
    entries.append(.cameraChoice(
        presentationData.theme,
        "DahlSettings.VideoMessage".tp_loc(lang: lang),
        videoMessageCamera.rawValue
    ))
    
    return entries
}

public func dalsettingsController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    
    let arguments = DalSettingsArguments(
        context: context,
        presentController: { controller, arguments in
            presentControllerImpl?(controller, arguments)
        },
        pushController: { controller in
            pushControllerImpl?(controller)
        },
        updateHidePublishStoriesButton: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hidePublishStoriesButton = value
                    return settings
                }
            ).start()
        },
        updateHideStories: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideStories = value
                    return settings
                }
            ).start()
        },
        updateHideViewedStories: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideViewedStories = value
                    return settings
                }
            ).start()
        },
        updateHidePhone: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hidePhone = value
                    return settings
                }
            ).start()
        },
        updateDisableReadHistory: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.disableReadHistory = value
                    return settings
                }
            ).start()
        },
        updateOfflineMode: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.offlineMode = value
                    return settings
                }
            ).start()
        }, openCameraSettings: { _ in
            let cameraSettingsController = dalCameraSettingsController(
                context: context,
                updateCamera: { newCamera in
                    let _ = updateDalSettingsInteractively(
                        accountManager: context.sharedContext.accountManager,
                        { settings in
                            var settings = settings
                            settings.videoMessageCamera = newCamera == CameraType.back.rawValue ? .back : .front
                            return settings
                        }
                    ).start()
                }
            )
            pushControllerImpl?(cameraSettingsController)
        }
    )
    
    let sharedData = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])

    let signal = combineLatest(
        sharedData,
        context.sharedContext.presentationData,
        context.account.postbox.preferencesView(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    )
    |> map { sharedData, presentationData, preferences -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let dalSettings: DalSettings
        if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) {
            dalSettings = entry
        } else {
            dalSettings = DalSettings.defaultSettings
        }
        
        let entries = dalSettingsEntries(
            hidePublishStoriesButton: dalSettings.hidePublishStoriesButton,
            hideStories: dalSettings.hideStories,
            hideViewedStories: dalSettings.hideViewedStories,
            hidePhone: dalSettings.hidePhone,
            disableReadHistory: dalSettings.disableReadHistory,
            offlintMode: dalSettings.offlineMode,
            videoMessageCamera: dalSettings.videoMessageCamera,
            presentationData: presentationData
        )
        
        
        // Разделение записей по секциям
        let groupedEntries = Dictionary(grouping: entries, by: { $0.section })
        
        var allEntries: [DalSettingsEntry] = []
        
        for section in [DalSettingsSection.stories.rawValue, DalSettingsSection.confidentiality.rawValue, DalSettingsSection.camera.rawValue] {
            if let entries = groupedEntries[section] {
                allEntries.append(contentsOf: entries.sorted())
            }
        }
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: allEntries,
            style: .blocks,
            ensureVisibleItemTag: nil,
            initialScrollToItem: nil
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    
    return controller
}
