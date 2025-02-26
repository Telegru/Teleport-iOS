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

private final class DChatsSettingsArguments {
    let context: AccountContext
    let updateCallConfirmation: (Bool) -> Void
    let updateAudioMessageConfirmation: (Bool) -> Void
    let openVideoMessageSettings: () -> Void
    
    let updateRecentChatsEnabled: (Bool) -> Void
    
    let updateBottomFolders: (Bool) -> Void
    let updateFolderInfiniteScrolling: (Bool) -> Void
    let updateHideAllChats: (Bool) -> Void

    init(
        context: AccountContext,
        updateCallConfirmation: @escaping (Bool) -> Void,
        updateAudioMessageConfirmation: @escaping (Bool) -> Void,
        openVideoMessageSettings: @escaping () -> Void,
        updateRecentChatsEnabled: @escaping (Bool) -> Void,
        updateBottomFolders: @escaping (Bool) -> Void,
        updateFolderInfiniteScrolling: @escaping (Bool) -> Void,
        updateHideAllChats: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.updateCallConfirmation = updateCallConfirmation
        self.updateAudioMessageConfirmation = updateAudioMessageConfirmation
        self.openVideoMessageSettings = openVideoMessageSettings
        self.updateRecentChatsEnabled = updateRecentChatsEnabled
        self.updateBottomFolders = updateBottomFolders
        self.updateFolderInfiniteScrolling = updateFolderInfiniteScrolling
        self.updateHideAllChats = updateHideAllChats
    }
}

private enum DChatsSettingsSection: Int32 {
    case confirmation
    case recentChats
    case folders
}

private enum DChatsSettingsEntry: ItemListNodeEntry {
    case confirmationHeader(title: String)
    case confirmCall(title: String, value: Bool)
    case confirmAudioMessage(title: String, value: Bool)
    case audioMessageCamera(title: String, detail: String)
    
    case recentChatsHeader(title: String)
    case recentChats(title: String, value: Bool)
    case recentChatsFooter(title: String)
    
    case foldersHeader(title: String)
    case bottomFolder(title: String, value: Bool)
    case folderInfiniteScroll(title: String, value: Bool)
    case hideAllChats(title: String, value: Bool)
    
    var section: ItemListSectionId {
        switch self {
        case .confirmationHeader, .confirmCall, .confirmAudioMessage, .audioMessageCamera:
            return DChatsSettingsSection.confirmation.rawValue
            
        case .recentChatsHeader, .recentChats, .recentChatsFooter:
            return DChatsSettingsSection.recentChats.rawValue
            
        case .foldersHeader, .bottomFolder, .folderInfiniteScroll, .hideAllChats:
            return DChatsSettingsSection.folders.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .confirmationHeader: return 0
        case .confirmCall: return 1
        case .confirmAudioMessage: return 2
        case .audioMessageCamera: return 3
        case .recentChatsHeader: return 4
        case .recentChats: return 5
        case .recentChatsFooter: return 6
        case .foldersHeader: return 7
        case .bottomFolder: return 8
        case .folderInfiniteScroll: return 9
        case .hideAllChats: return 10
        }
    }

    static func ==(lhs: DChatsSettingsEntry, rhs: DChatsSettingsEntry) -> Bool {
        switch lhs {
        case let .confirmationHeader(lhsTitle):
            if case let .confirmationHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .confirmCall(lhsTitle, lhsValue):
            if case let .confirmCall(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
            
        case let .confirmAudioMessage(lhsTitle, lhsValue):
            if case let .confirmAudioMessage(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
            
        case let .audioMessageCamera(lhsTitle, lhsDetail):
            if case let .audioMessageCamera(rhsTitle, rhsDetail) = rhs {
                return lhsTitle == rhsTitle && lhsDetail == rhsDetail
            }
            return false
            
        case let .recentChatsHeader(lhsTitle):
            if case let .recentChatsHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .recentChats(lhsTitle, lhsValue):
            if case let .recentChats(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
            
        case let .recentChatsFooter(lhsTitle):
            if case let .recentChatsFooter(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .foldersHeader(lhsTitle):
            if case let .foldersHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .bottomFolder(lhsTitle, lhsValue):
            if case let .bottomFolder(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
            
        case let .folderInfiniteScroll(lhsTitle, lhsValue):
            if case let .folderInfiniteScroll(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
            
        case let .hideAllChats(lhsTitle, lhsValue):
            if case let .hideAllChats(rhsTitle, rhsValue) = rhs {
                return lhsTitle == rhsTitle && lhsValue == rhsValue
            }
            return false
        }
    }

    static func <(lhs: DChatsSettingsEntry, rhs: DChatsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DChatsSettingsArguments
        
        switch self {
        case let .confirmationHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
        
        case let .confirmCall(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateCallConfirmation(updatedValue)
                }
        
        case let .confirmAudioMessage(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateAudioMessageConfirmation(updatedValue)
                }
            
        case let .audioMessageCamera(title, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: detail,
                sectionId: section,
                style: .blocks) {
                    arguments.openVideoMessageSettings()
                }
            
        case let .recentChatsHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .recentChats(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateRecentChatsEnabled(updatedValue)
                }
            
        case let .foldersHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .bottomFolder(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateBottomFolders(updatedValue)
                }
            
        case let .folderInfiniteScroll(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateFolderInfiniteScrolling(updatedValue)
                }
            
        case let .hideAllChats(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: section,
                style: .blocks) { updatedValue in
                    arguments.updateHideAllChats(updatedValue)
                }
            
        case let .recentChatsFooter(title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: section
            )
        }
    }
}

// MARK: - Controller

public func dChatsSettingsController(
    context: AccountContext
) -> ViewController {
    var openVideoMessageSettings: (() -> Void)?
    
    let arguments = DChatsSettingsArguments(
        context: context,
        updateCallConfirmation: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.callConfirmation = updatedValue
                    return settings
                }
            ).start()
        },
        updateAudioMessageConfirmation: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.sendAudioConfirmation = updatedValue
                    return settings
                }
            ).start()
        },
        openVideoMessageSettings: {
            openVideoMessageSettings?()
        },
        updateRecentChatsEnabled: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.showRecentChats = updatedValue
                    return settings
                }
            ).start()
        },
        updateBottomFolders: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.chatsFoldersAtBottom = updatedValue
                    return settings
                }
            ).start()
        },
        updateFolderInfiniteScrolling: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.infiniteScrolling = updatedValue
                    return settings
                }
            ).start()
        },
        updateHideAllChats: { updatedValue in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hideAllChatsFolder = updatedValue
                    return settings
                }
            ).start()
        }
    )
    
    let dahlSettingsSignal = (
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
        |> map { sharedData -> DalSettings in
            return sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? DalSettings.defaultSettings
        }
        |> distinctUntilChanged
    )
    
    let signal = combineLatest(
        context.sharedContext.presentationData,
        dahlSettingsSignal
    )
    |> map { presentationData, dahlSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("DahlSettings.Chats.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let lang = presentationData.strings.baseLanguageCode

        var entries: [DChatsSettingsEntry] = []
        
        entries.append(
            .confirmationHeader(
                title: "DahlSettings.Chats.Confirmation.Header".tp_loc(lang: lang).uppercased()
            )
        )
        entries.append(
            .confirmCall(
                title: "DahlSettings.Chats.Confirmation.Call".tp_loc(lang: lang),
                value: dahlSettings.callConfirmation
            )
        )
        entries.append(
            .confirmAudioMessage(
                title: "DahlSettings.Chats.Confirmation.AudioMessage".tp_loc(lang: lang),
                value: dahlSettings.sendAudioConfirmation
            )
        )
        
        let audioMessageCameraDetail = {
            switch dahlSettings.videoMessageCamera {
            case .back: return "DahlSettings.BackCamera".tp_loc(lang: lang)
            case .front: return "DahlSettings.FrontCamera".tp_loc(lang: lang)
            case .undefined: return "DahlSettings.AskBeforeRecording".tp_loc(lang: lang)
            }
        }()
        entries.append(
            .audioMessageCamera(
                title: "DahlSettings.Chats.Confirmation.VideoMessage".tp_loc(lang: lang),
                detail: audioMessageCameraDetail
            )
        )
        
        entries.append(
            .recentChatsHeader(
                title: "DahlSettings.Chats.RecentChats.Header".tp_loc(lang: lang).uppercased()
            )
        )
        
        entries.append(
            .recentChats(
                title: "DahlSettings.Chats.RecentChats".tp_loc(lang: lang),
                value: dahlSettings.showRecentChats ?? false
            )
        )
        
        entries.append(
            .recentChatsFooter(
                title: "DahlSettings.Chats.RecentChats.Footer".tp_loc(lang: lang)
            )
        )
        
        entries.append(
            .foldersHeader(
                title: "DahlSettings.Chats.Folders.Header".tp_loc(lang: lang).uppercased()
            )
        )
        
        entries.append(
            .bottomFolder(
                title: "DahlSettings.Chats.Folders.BottomFolders".tp_loc(lang: lang),
                value: dahlSettings.chatsFoldersAtBottom
            )
        )
        
        entries.append(
            .folderInfiniteScroll(
                title: "DahlSettings.Chats.Folders.InfiniteScroll".tp_loc(lang: lang),
                value: dahlSettings.infiniteScrolling
            )
        )
        
        entries.append(
            .hideAllChats(
                title: "DahlSettings.Chats.Folders.HideAllChats".tp_loc(lang: lang),
                value: dahlSettings.hideAllChatsFolder
            )
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    openVideoMessageSettings = { [weak controller] in
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
        controller?.push(cameraSettingsController)
    }
    
    return controller
}
