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

private final class DalSettingsArguments {
    let context: AccountContext
    let presentController: (ViewController, ViewControllerPresentationArguments?) -> Void
    let pushController: (ViewController) -> Void

    let updateHidePublishStoriesButton: (Bool) -> Void
    let updateHideStories: (Bool) -> Void
    let updateHideViewedStories: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let updateHideReadTime: (Bool) -> Void

    init(
        context: AccountContext,
        presentController: @escaping (ViewController, ViewControllerPresentationArguments?) -> Void,
        pushController: @escaping (ViewController) -> Void,
        updateHidePublishStoriesButton: @escaping (Bool) -> Void,
        updateHideStories: @escaping (Bool) -> Void,
        updateHideViewedStories: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        updateHideReadTime: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.presentController = presentController
        self.pushController = pushController
        self.updateHidePublishStoriesButton = updateHidePublishStoriesButton
        self.updateHideStories = updateHideStories
        self.updateHideViewedStories = updateHideViewedStories
        self.updateHidePhone = updateHidePhone
        self.updateHideReadTime = updateHideReadTime
    }
}

private enum DalSettingsSection: Int32 {
    case stories
    case confidentiality
}

public enum DalSettingsEntryTag: ItemListItemTag {
    case hidePublishStoriesButton
    case hideStories
    case hideViewedStories
    case hidePhone
    case hideReadTime

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
    
    // Раздел Stories
    case hidePublishStoriesButton(PresentationTheme, String, Bool)
    case hideStories(PresentationTheme, String, Bool)
    case hideViewedStories(PresentationTheme, String, Bool)
    
    // Раздел Конфиденциальность
    case hidePhone(PresentationTheme, String, Bool)
    case hideReadTime(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        switch self {
            // Истории находятся в секции stories
        case .storiesHeader, .hidePublishStoriesButton, .hideStories, .hideViewedStories:
            return DalSettingsSection.stories.rawValue
            
            // Приватность находится в секции confidentiality
        case .privacyHeader, .hidePhone, .hideReadTime:
            return DalSettingsSection.confidentiality.rawValue
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
        case .hideReadTime:
            return 6
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
        case .hideReadTime:
            return DalSettingsEntryTag.hideReadTime
        case .storiesHeader, .privacyHeader:
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
        case let .hideReadTime(lhsTheme, lhsText, lhsValue):
            if case let .hideReadTime(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case .storiesHeader(_, _), .privacyHeader(_, _):
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
        case let .hideReadTime(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideReadTime(updatedValue)
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
        }
    }
}

private func dalSettingsEntries(
    hidePublishStoriesButton: Bool,
    hideStories: Bool,
    hideViewedStories: Bool,
    hidePhone: Bool,
    hideReadTime: Bool,
    presentationData: PresentationData
) -> [DalSettingsEntry] {
    var entries: [DalSettingsEntry] = []
    
    // Добавляем заголовок для секции "Истории"
    entries.append(.storiesHeader(presentationData.theme, presentationData.strings.DalSettings_StoriesHeader.uppercased()))
    entries.append(.hidePublishStoriesButton(
        presentationData.theme,
        presentationData.strings.DalSettings_HidePublishStoriesButton,
        hidePublishStoriesButton
    ))
    entries.append(.hideStories(
        presentationData.theme,
        presentationData.strings.DalSettings_HideStories,
        hideStories
    ))
    entries.append(.hideViewedStories(
        presentationData.theme,
        presentationData.strings.DalSettings_HideViewedStories,
        hideViewedStories
    ))
    
    entries.append(.privacyHeader(presentationData.theme, presentationData.strings.DalSettings_PrivacyHeader.uppercased()))
    entries.append(.hidePhone(
        presentationData.theme,
        presentationData.strings.DalSettings_HidePhone,
        hidePhone
    ))
    entries.append(.hideReadTime(
        presentationData.theme,
        presentationData.strings.DalSettings_HideActivity,
        hideReadTime
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
        updateHideReadTime: { value in
            let currentPrivacy = Promise<AccountPrivacySettings>()
            currentPrivacy.set(context.engine.privacy.requestAccountPrivacySettings())
                        
            let _ = (currentPrivacy.get()
            |> take(1)
            |> mapToSignal { current in
                var settings = current.globalSettings
                settings.hideReadTime = value
                return context.engine.privacy.updateGlobalPrivacySettings(settings: settings)
            }
            |> deliverOnMainQueue).startStandalone(completed: {
                let _ = updateDalSettingsInteractively(
                    accountManager: context.sharedContext.accountManager,
                    { settings in
                        var settings = settings
                        settings.hideReadTime = value
                        return settings
                    }
                ).start()
            })
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
            hideReadTime: dalSettings.hideReadTime,
            presentationData: presentationData
        )
        
        
        // Разделение записей по секциям
        let groupedEntries = Dictionary(grouping: entries, by: { $0.section })
        
        var allEntries: [DalSettingsEntry] = []
        
        for section in [DalSettingsSection.stories.rawValue, DalSettingsSection.confidentiality.rawValue] {
            if let entries = groupedEntries[section] {
                allEntries.append(contentsOf: entries.sorted())
            }
        }
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(presentationData.strings.Settings_DalSettings),
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
