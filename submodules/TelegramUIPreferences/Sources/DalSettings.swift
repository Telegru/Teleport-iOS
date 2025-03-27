import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore


public enum CameraType: String, Codable, Equatable {
    case front = "front"
    case back = "back"
    case undefined = "undefined"
}

public enum DChatListViewStyle: Int32, CaseIterable, Codable, Equatable {
    case singleLine = 0
    case doubleLine = 1
    case tripleLine = 2
}

public struct DalSettings: Codable, Equatable {
    
    public var tabBarSettings: DTabBarSettings
    public var menuItemsSettings: MenuItemsSettings
    public var chatsListViewType: DChatListViewStyle
    public var premiumSettings: DPremiumSettings
    public var appearanceSettings: DAppearanceSettings
    
    // Раздел Stories
    public var hidePublishStoriesButton: Bool
    public var hideStories: Bool
    public var hideViewedStories: Bool
    public var isStoriesPostingGestureEnabled: Bool
    
    // Раздел Конфиденциальность
    public var hidePhone: Bool
    public var disableReadHistory: Bool
    public var offlineMode: Bool
    
    // Подтверждение
    public var sendAudioConfirmation: Bool
    public var callConfirmation: Bool
    public var videoMessageCamera: CameraType
    
    // Папки с чатами
    public var chatsFoldersAtBottom: Bool
    public var hideAllChatsFolder: Bool
    public var infiniteScrolling: Bool
    public var showChatFolders: Bool
    
    //Недавние чаты
    public var showRecentChats: Bool?

    public static var defaultSettings: DalSettings {
        return DalSettings(
            tabBarSettings: .default,
            menuItemsSettings: .default,
            premiumSettings: .default,
            appearanceSettings: .default,
            hidePublishStoriesButton: false,
            hideStories: false,
            hideViewedStories: false,
            isStoriesPostingGestureEnabled: true,
            hidePhone: false,
            disableReadHistory: false,
            offlineMode: false,
            sendAudioConfirmation: false,
            callConfirmation: false,
            videoMessageCamera: CameraType.front,
            chatsFoldersAtBottom: false,
            hideAllChatsFolder: false,
            infiniteScrolling: false,
            showChatFolders: true,
            showRecentChats: nil,
            chatsListViewType: .tripleLine
        )
    }
    
    public init(
        tabBarSettings: DTabBarSettings,
        menuItemsSettings: MenuItemsSettings,
        premiumSettings: DPremiumSettings,
        appearanceSettings: DAppearanceSettings,
        hidePublishStoriesButton: Bool,
        hideStories: Bool,
        hideViewedStories: Bool,
        isStoriesPostingGestureEnabled: Bool,
        hidePhone: Bool,
        disableReadHistory: Bool,
        offlineMode: Bool,
        sendAudioConfirmation: Bool,
        callConfirmation: Bool,
        videoMessageCamera: CameraType,
        chatsFoldersAtBottom: Bool,
        hideAllChatsFolder: Bool,
        infiniteScrolling: Bool,
        showChatFolders: Bool,
        showRecentChats: Bool?,
        chatsListViewType: DChatListViewStyle
    ) {
        self.tabBarSettings = tabBarSettings
        self.menuItemsSettings = menuItemsSettings
        self.premiumSettings = premiumSettings
        self.appearanceSettings = appearanceSettings
        self.hidePublishStoriesButton = hidePublishStoriesButton
        self.hideStories = hideStories
        self.hideViewedStories = hideViewedStories
        self.isStoriesPostingGestureEnabled = isStoriesPostingGestureEnabled
        self.hidePhone = hidePhone
        self.disableReadHistory = disableReadHistory
        self.offlineMode = offlineMode
        self.videoMessageCamera = videoMessageCamera
        self.callConfirmation = callConfirmation
        self.sendAudioConfirmation = sendAudioConfirmation
        self.chatsFoldersAtBottom = chatsFoldersAtBottom
        self.hideAllChatsFolder = hideAllChatsFolder
        self.infiniteScrolling = infiniteScrolling
        self.showChatFolders = showChatFolders
        self.showRecentChats = showRecentChats
        self.chatsListViewType = chatsListViewType
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.tabBarSettings = (try container.decodeIfPresent(DTabBarSettings.self, forKey: "tabBarSettings") ?? .default)
        self.menuItemsSettings = (try container.decodeIfPresent(MenuItemsSettings.self, forKey: "menuItemsSettings") ?? .default)
        self.premiumSettings = (try container.decodeIfPresent(DPremiumSettings.self, forKey: "premiumSettings") ?? .default)
        self.appearanceSettings = (try container.decodeIfPresent(DAppearanceSettings.self, forKey: "appearanceSettings") ?? .default)
        // Раздел Stories
        self.hidePublishStoriesButton = (try container.decodeIfPresent(Int32.self, forKey: "hidePublishStoriesButton") ?? 0) != 0
        self.hideStories = (try container.decodeIfPresent(Int32.self, forKey: "hideStories") ?? 0) != 0
        self.hideViewedStories = (try container.decodeIfPresent(Int32.self, forKey: "hideViewedStories") ?? 0) != 0
        self.isStoriesPostingGestureEnabled = (try container.decodeIfPresent(Int32.self, forKey: "isStoriesPostingGestureEnabled") ?? 1) != 0
        // Раздел Конфиденциальность
        self.hidePhone = (try container.decodeIfPresent(Int32.self, forKey: "hidePhone") ?? 0) != 0
        self.disableReadHistory = (try container.decodeIfPresent(Int32.self, forKey: "disableReadHistory") ?? 0) != 0
        self.offlineMode = (try container.decodeIfPresent(Int32.self, forKey: "offlineMode") ?? 0) != 0
        if let cameraString = try container.decodeIfPresent(String.self, forKey: "videoMessageCamera"),
           let cameraType = CameraType(rawValue: cameraString) {
            self.videoMessageCamera = cameraType
        } else {
            self.videoMessageCamera = .front
        }
        self.sendAudioConfirmation = (try container.decodeIfPresent(Int32.self, forKey: "sendAudioConfirmation") ?? 0) != 0
        self.callConfirmation = (try container.decodeIfPresent(Int32.self, forKey: "callConfirmation") ?? 0) != 0
        self.chatsFoldersAtBottom = (try container.decodeIfPresent(Int32.self, forKey: "chatsFoldersAtBottom") ?? 1) != 0
        self.hideAllChatsFolder = (try container.decodeIfPresent(Int32.self, forKey: "hideAllChatsFolder") ?? 0) != 0
        self.infiniteScrolling = (try container.decodeIfPresent(Int32.self, forKey: "infiniteScrolling") ?? 0) != 0
        self.showChatFolders = (try container.decodeIfPresent(Bool.self, forKey: "showChatFolders") ?? true)
        if let showRecentChats = (try container.decodeIfPresent(Int32.self, forKey: "showRecentChats")) {
            self.showRecentChats = showRecentChats != 0
        }
        
        if let listViewString = try container.decodeIfPresent(Int32.self, forKey: "chatsListViewType"),
           let listView = DChatListViewStyle(rawValue: listViewString) {
            self.chatsListViewType = listView
        } else {
            self.chatsListViewType = .singleLine
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.tabBarSettings, forKey: "tabBarSettings")
        try container.encode(self.menuItemsSettings, forKey: "menuItemsSettings")
        try container.encode(self.premiumSettings, forKey: "premiumSettings")
        try container.encode(self.appearanceSettings, forKey: "appearanceSettings")
        // Раздел Stories
        try container.encode((self.hidePublishStoriesButton ? 1 : 0) as Int32, forKey: "hidePublishStoriesButton")
        try container.encode((self.hideStories ? 1 : 0) as Int32, forKey: "hideStories")
        try container.encode((self.hideViewedStories ? 1 : 0) as Int32, forKey: "hideViewedStories")
        try container.encode((self.isStoriesPostingGestureEnabled ? 1 : 0) as Int32, forKey: "isStoriesPostingGestureEnabled")
        // Раздел Конфиденциальность
        try container.encode((self.hidePhone ? 1 : 0) as Int32, forKey: "hidePhone")
        try container.encode((self.disableReadHistory ? 1 : 0) as Int32, forKey: "disableReadHistory")
        try container.encode((self.offlineMode ? 1 : 0) as Int32, forKey: "offlineMode")
        try container.encode(self.videoMessageCamera.rawValue, forKey: "videoMessageCamera")
        try container.encode((self.sendAudioConfirmation ? 1 : 0) as Int32, forKey: "sendAudioConfirmation")
        try container.encode((self.callConfirmation ? 1 : 0) as Int32, forKey: "callConfirmation")
        try container.encode((self.chatsFoldersAtBottom ? 1 : 0) as Int32, forKey: "chatsFoldersAtBottom")
        try container.encode((self.hideAllChatsFolder ? 1 : 0) as Int32, forKey: "hideAllChatsFolder")
        try container.encode((self.infiniteScrolling ? 1 : 0) as Int32, forKey: "infiniteScrolling")
        try container.encode(self.showChatFolders, forKey: "showChatFolders")
        if let showRecentChats = self.showRecentChats {
            try container.encode((showRecentChats ? 1 : 0) as Int32, forKey: "showRecentChats")
        }
        try container.encode(self.chatsListViewType.rawValue, forKey: "chatsListViewType")
    }
    
    public func withUpdatedShowCallTab() -> DalSettings {
        var dalSettings = self
        var activeTabs = tabBarSettings.activeTabs
        if activeTabs.contains(.calls) {
            return self
        }
        if activeTabs.count == 5 {
            let index = activeTabs.firstIndex { !$0.isAlwaysShow } ?? 0
            activeTabs.remove(at: index)
        }
        activeTabs.append(.calls)
        dalSettings.tabBarSettings.activeTabs = activeTabs
        return dalSettings
    }
}

public func updateDalSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (DalSettings) -> DalSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.dalSettings, { entry in
            let currentSettings: DalSettings
            if let entry = entry?.get(DalSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = DalSettings.defaultSettings
            }
            return PreferencesEntry(f(currentSettings))
        })
    }
    |> mapToSignal { _ in
        return .complete()
    }
}
