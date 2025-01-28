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

import MtProtoKit
import TPStrings
import BuildConfig

private final class DalSettingsArguments {
    let context: AccountContext
    let presentController: (ViewController, ViewControllerPresentationArguments?) -> Void
    let pushController: (ViewController) -> Void

    let updateProxy: (Bool) -> Void
    let updateHidePublishStoriesButton: (Bool) -> Void
    let updateHideStories: (Bool) -> Void
    let updateHideViewedStories: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let updateDisableReadHistory: (Bool) -> Void
    let updateOfflineMode: (Bool) -> Void
    let openCameraSettings: (String) -> Void
    let updateCallConfirmation: (Bool) -> Void
    let updateSendAudioConfirmation: (Bool) -> Void
    let updateChatsFoldersAtBottom: (Bool) -> Void
    let updateHideAllChatsFolder: (Bool) -> Void
    let updateInfiniteScrolling: (Bool) -> Void

    init(
        context: AccountContext,
        presentController: @escaping (ViewController, ViewControllerPresentationArguments?) -> Void,
        pushController: @escaping (ViewController) -> Void,
        updateProxy: @escaping (Bool) -> Void,
        updateHidePublishStoriesButton: @escaping (Bool) -> Void,
        updateHideStories: @escaping (Bool) -> Void,
        updateHideViewedStories: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        updateDisableReadHistory: @escaping (Bool) -> Void,
        updateOfflineMode: @escaping (Bool) -> Void,
        openCameraSettings: @escaping (String) -> Void,
        updateCallConfirmation: @escaping (Bool) -> Void,
        updateSendAudioConfirmation: @escaping (Bool) -> Void,
        updateChatsFoldersAtBottom: @escaping (Bool) -> Void,
        updateHideAllChatsFolder: @escaping (Bool) -> Void,
        updateInfiniteScrolling: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.presentController = presentController
        self.pushController = pushController
        self.updateProxy = updateProxy
        self.updateHidePublishStoriesButton = updateHidePublishStoriesButton
        self.updateHideStories = updateHideStories
        self.updateHideViewedStories = updateHideViewedStories
        self.updateHidePhone = updateHidePhone
        self.updateDisableReadHistory = updateDisableReadHistory
        self.updateOfflineMode = updateOfflineMode
        self.openCameraSettings = openCameraSettings
        self.updateCallConfirmation = updateCallConfirmation
        self.updateSendAudioConfirmation = updateSendAudioConfirmation
        self.updateChatsFoldersAtBottom = updateChatsFoldersAtBottom
        self.updateHideAllChatsFolder = updateHideAllChatsFolder
        self.updateInfiniteScrolling = updateInfiniteScrolling
    }
}

private enum DalSettingsSection: Int32, CaseIterable {
    case proxy
    case tabBar
    case stories
    case confidentiality
    case confirmation
    case chatsFolders
}

public enum DalSettingsEntryTag: ItemListItemTag {
    case hidePublishStoriesButton
    case hideStories
    case hideViewedStories
    case hidePhone
    case disableReadHistory
    case offlineMode
    case cameraChoice
    case callConfirmation
    case sendAudioConfirmation
    case proxy
    case chatsFoldersAtBottom
    case hideAllChatsFolder
    case infiniteScrolling

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
    case confirmationHeader(PresentationTheme, String)
    case chatsFoldersHeader(PresentationTheme, String)
    
    case proxy(PresentationTheme, String, Bool)

	// Раздел нижнего меню
    case tabBar

    // Раздел Stories
    case hidePublishStoriesButton(PresentationTheme, String, Bool)
    case hideStories(PresentationTheme, String, Bool)
    case hideViewedStories(PresentationTheme, String, Bool)
    
    // Раздел Конфиденциальность
    case hidePhone(PresentationTheme, String, Bool)
    case disableReadHistory(PresentationTheme, String, Bool)
    case offlineMode(PresentationTheme, String, Bool)
    
    // Подтверждение
    case callConfirmation(PresentationTheme, String, Bool)
    case sendAudioConfirmation(PresentationTheme, String, Bool)
    case cameraChoice(PresentationTheme, String, String)
    
    // Папки с чатами
    case chatsFoldersAtBottom(PresentationTheme, String, Bool)
    case hideAllChatsFolder(PresentationTheme, String, Bool)
    case infiniteScrolling(PresentationTheme, String, Bool)

    var section: ItemListSectionId {
        switch self {
        case .proxy:
            return DalSettingsSection.proxy.rawValue
        
        case .tabBar:
            return DalSettingsSection.tabBar.rawValue
            
        case .storiesHeader, .hidePublishStoriesButton, .hideStories, .hideViewedStories:
            return DalSettingsSection.stories.rawValue
            
        case .privacyHeader, .hidePhone, .disableReadHistory, .offlineMode:
            return DalSettingsSection.confidentiality.rawValue
        case .confirmationHeader, .callConfirmation, .sendAudioConfirmation, .cameraChoice:
            return DalSettingsSection.confirmation.rawValue
        case .chatsFoldersHeader, .chatsFoldersAtBottom, .hideAllChatsFolder, .infiniteScrolling:
            return DalSettingsSection.chatsFolders.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .proxy:
            return -2
        case .tabBar:
            return -1
            
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
        case .confirmationHeader:
            return 8
        case .callConfirmation:
            return 9
        case .sendAudioConfirmation:
            return 10
        case .cameraChoice:
            return 11
        case .chatsFoldersHeader:
            return 12
        case .chatsFoldersAtBottom:
            return 13
        case .hideAllChatsFolder:
            return 14
        case .infiniteScrolling:
            return 15
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
        case .callConfirmation:
            return DalSettingsEntryTag.callConfirmation
        case .sendAudioConfirmation:
            return DalSettingsEntryTag.sendAudioConfirmation
        case .proxy:
            return DalSettingsEntryTag.proxy
        case .chatsFoldersAtBottom:
            return DalSettingsEntryTag.chatsFoldersAtBottom
        case .hideAllChatsFolder:
            return DalSettingsEntryTag.hideAllChatsFolder
        case .infiniteScrolling:
            return DalSettingsEntryTag.infiniteScrolling
        case .storiesHeader, .privacyHeader, .confirmationHeader, .chatsFoldersHeader, .tabBar:
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
        case let .sendAudioConfirmation(lhsTheme, lhsText, lhsValue):
            if case let .sendAudioConfirmation(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .callConfirmation(lhsTheme, lhsText, lhsValue):
            if case let .callConfirmation(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .proxy(lhsTheme, lhsText, lhsValue):
            if case let .proxy(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
		case let .chatsFoldersAtBottom(lhsTheme, lhsText, lhsValue):
            if case let .chatsFoldersAtBottom(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .hideAllChatsFolder(lhsTheme, lhsText, lhsValue):
            if case let .hideAllChatsFolder(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .infiniteScrolling(lhsTheme, lhsText, lhsValue):
            if case let .infiniteScrolling(rhsTheme, rhsText, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsText == rhsText,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case .storiesHeader(_, _), .privacyHeader(_, _), .confirmationHeader(_,_), .chatsFoldersHeader(_, _), .tabBar:
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
                label: selectedCamera == CameraType.front.rawValue ?  "DahlSettings.FrontCamera".tp_loc(lang: presentationData.strings.baseLanguageCode) : selectedCamera == CameraType.back.rawValue ? "DahlSettings.BackCamera".tp_loc(lang: presentationData.strings.baseLanguageCode) : "DahlSettings.AskBeforeRecording".tp_loc(lang: presentationData.strings.baseLanguageCode),
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openCameraSettings(selectedCamera)
                },
                tag: self.tag
            )
        case let .callConfirmation(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateCallConfirmation(updatedValue)
                },
                tag: self.tag
            )
        case let .sendAudioConfirmation(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateSendAudioConfirmation(updatedValue)
                },
                tag: self.tag
            )
        case let .chatsFoldersAtBottom(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateChatsFoldersAtBottom(updatedValue)
                },
                tag: self.tag
            )
        case let .hideAllChatsFolder(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHideAllChatsFolder(updatedValue)
                },
                tag: self.tag
            )
        case let .infiniteScrolling(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateInfiniteScrolling(updatedValue)
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
        case let .confirmationHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case let .chatsFoldersHeader(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case .tabBar:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "DahlSettings.TabBarSettings".tp_loc(lang: presentationData.strings.baseLanguageCode),
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    let tabBarSettingsController = dTabBarSettingsController(context: arguments.context)
                    arguments.pushController(tabBarSettingsController)
                }
            )
            
        case let .proxy(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateProxy(updatedValue)
                },
                tag: self.tag
            )
        }
    }
}

private func dalSettingsEntries(
    isProxyEnabled: Bool,
    hidePublishStoriesButton: Bool,
    hideStories: Bool,
    hideViewedStories: Bool,
    hidePhone: Bool,
    disableReadHistory: Bool,
    offlintMode: Bool,
    callConfirmation: Bool,
    sendAudioConfirmation: Bool,
    videoMessageCamera: CameraType,
    chatsFoldersAtBottom: Bool,
    hideAllChatsFolder: Bool,
    infiniteScrolling: Bool,
    presentationData: PresentationData
) -> [DalSettingsEntry] {
    var entries: [DalSettingsEntry] = []
    let lang = presentationData.strings.baseLanguageCode
    
    entries.append(
        .proxy(
            presentationData.theme,
            "DahlSettings.Proxy".tp_loc(lang: lang),
            isProxyEnabled
        )
    )
    
    // Tab bar
    entries.append(.tabBar)
    
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
    
    entries.append(.confirmationHeader(presentationData.theme, "DahlSettings.ActionConfirmationHeader".tp_loc(lang: lang).uppercased()))
    entries.append(.callConfirmation(
        presentationData.theme,
        "DahlSettings.ConfirmCallToggle".tp_loc(lang: lang),
        callConfirmation
    ))
    entries.append(.sendAudioConfirmation(
        presentationData.theme,
        "DahlSettings.ConfirmAudioMessageToggle".tp_loc(lang: lang),
        sendAudioConfirmation
    ))
    entries.append(.cameraChoice(
        presentationData.theme,
        "DahlSettings.VideoMessage".tp_loc(lang: lang),
        videoMessageCamera.rawValue
    ))
    entries.append(.chatsFoldersHeader(presentationData.theme, "DahlSettings.ChatsFoldersHeader".tp_loc(lang: lang).uppercased()))
    entries.append(.chatsFoldersAtBottom(
        presentationData.theme,
        "DahlSettings.ChatsFoldersAtBottom".tp_loc(lang: lang),
        chatsFoldersAtBottom
    ))
    entries.append(.hideAllChatsFolder(
        presentationData.theme,
        "DahlSettings.HideAllChatsFolder".tp_loc(lang: lang),
        hideAllChatsFolder
    ))
    entries.append(.infiniteScrolling(
        presentationData.theme,
        "DahlSettings.InfiniteScrolling".tp_loc(lang: lang),
        infiniteScrolling
    ))
    return entries
}

public func dalsettingsController(
    context: AccountContext,
    tabBarItem: ItemListControllerTabBarItem? = nil
) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let buildConfig = BuildConfig(baseAppBundleId: baseAppBundleId)
    
    let arguments = DalSettingsArguments(
        context: context,
        presentController: { controller, arguments in
            presentControllerImpl?(controller, arguments)
        },
        pushController: { controller in
            pushControllerImpl?(controller)
        },
        updateProxy: { value in
            let _ = (updateProxySettingsInteractively(accountManager: context.sharedContext.accountManager) { proxySettings in
                var proxySettings = proxySettings
                if value == true {
                    proxySettings.enabled = false
                }
                return proxySettings
            } |> mapToSignal { _ in
                updateDahlProxyInteractively(
                    accountManager: context.sharedContext.accountManager) { settings in
                        var settings = settings
                        let parsedSecret = MTProxySecret.parse(buildConfig.dProxySecret)
                        settings.server = value ? ProxyServerSettings(
                            host: buildConfig.dProxyServer,
                            port: buildConfig.dProxyPort,
                            connection: .mtp(secret: parsedSecret!.serialize())
                        ) : nil
                        return settings
                    }
            }).start()
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
                            settings.videoMessageCamera = CameraType(rawValue: newCamera) ?? .undefined
                            return settings
                        }
                    ).start()
                }
            )
            pushControllerImpl?(cameraSettingsController)
        }, updateCallConfirmation: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.callConfirmation = value
                    return settings
                }
            ).start()
        }, updateSendAudioConfirmation: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.sendAudioConfirmation = value
                    return settings
                }
            ).start()
        }, updateChatsFoldersAtBottom: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.chatsFoldersAtBottom = value
                    return settings
                }
            ).start()
        }, updateHideAllChatsFolder: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideAllChatsFolder = value
                    return settings
                }
            ).start()
        }, updateInfiniteScrolling: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.infiniteScrolling = value
                    return settings
                }
            ).start()
        }
    )
    
    let sharedData = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    
    let isProxyEnabled = Promise<Bool>()
    isProxyEnabled.set(
        context.sharedContext.accountManager.sharedData(keys: [SharedDataKeys.dahlProxySettings, SharedDataKeys.proxySettings])
    |> map { sharedData -> Bool in
        if sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self)?.effectiveActiveServer != nil {
            return false
        }
        
        return sharedData.entries[SharedDataKeys.dahlProxySettings]?.get(DahlProxySettings.self)?.server != nil
    })

    let signal = combineLatest(
        sharedData,
        context.sharedContext.presentationData,
        context.account.postbox.preferencesView(keys: [ApplicationSpecificSharedDataKeys.dalSettings]),
        isProxyEnabled.get()
    )
    |> map { sharedData, presentationData, preferences, isProxyEnabledValue -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let dalSettings: DalSettings
        if let entry = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) {
            dalSettings = entry
        } else {
            dalSettings = DalSettings.defaultSettings
        }
        
        let entries = dalSettingsEntries(
            isProxyEnabled: isProxyEnabledValue,
            hidePublishStoriesButton: dalSettings.hidePublishStoriesButton,
            hideStories: dalSettings.hideStories,
            hideViewedStories: dalSettings.hideViewedStories,
            hidePhone: dalSettings.hidePhone,
            disableReadHistory: dalSettings.disableReadHistory,
            offlintMode: dalSettings.offlineMode,
            callConfirmation: dalSettings.callConfirmation,
            sendAudioConfirmation: dalSettings.sendAudioConfirmation,
            videoMessageCamera: dalSettings.videoMessageCamera,
            chatsFoldersAtBottom: dalSettings.chatsFoldersAtBottom,
            hideAllChatsFolder: dalSettings.hideAllChatsFolder,
            infiniteScrolling: dalSettings.infiniteScrolling,
            presentationData: presentationData
        )
        
        
        // Разделение записей по секциям
        let groupedEntries = Dictionary(grouping: entries, by: { $0.section })
        
        var allEntries: [DalSettingsEntry] = []
        
        for section in DalSettingsSection.allCases.map(\.rawValue) {
            if let entries = groupedEntries[section] {
                allEntries.append(contentsOf: entries.sorted())
            }
        }
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .navigationItemTitle("DahlSettings.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            tabBarItem: tabBarItem
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
    
    let controller: ItemListController
    
    if let tabBarItem {
        controller = ItemListController(context: context, state: signal, tabBarItem: .single(tabBarItem))
    } else {
        controller = ItemListController(context: context, state: signal)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    
    return controller
}
