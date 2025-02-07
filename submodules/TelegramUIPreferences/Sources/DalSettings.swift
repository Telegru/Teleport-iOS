import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore


public enum CameraType: String, Codable, Equatable {
    case front = "front"
    case back = "back"
    case undefined = "undefined"
}

public struct DalSettings: Codable, Equatable {
    
    public var tabBarSettings: TabBarSettings
    public var menuItemsSettings: MenuItemsSettings
    
    // Раздел Stories
    public var hidePublishStoriesButton: Bool
    public var hideStories: Bool
    public var hideViewedStories: Bool
    
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

    public static var defaultSettings: DalSettings {
        return DalSettings(
            tabBarSettings: .default,
            menuItemsSettings: .default,
            hidePublishStoriesButton: false,
            hideStories: false,
            hideViewedStories: false,
            hidePhone: false,
            disableReadHistory: false,
            offlineMode: false,
            sendAudioConfirmation: false,
            callConfirmation: false,
            videoMessageCamera: CameraType.front,
            chatsFoldersAtBottom: true,
            hideAllChatsFolder: false,
            infiniteScrolling: false
        )
    }
    
    public init(
        tabBarSettings: TabBarSettings,
        menuItemsSettings: MenuItemsSettings,
        hidePublishStoriesButton: Bool,
        hideStories: Bool,
        hideViewedStories: Bool,
        hidePhone: Bool,
        disableReadHistory: Bool,
        offlineMode: Bool,
        sendAudioConfirmation: Bool,
        callConfirmation: Bool,
        videoMessageCamera: CameraType,
        chatsFoldersAtBottom: Bool,
        hideAllChatsFolder: Bool,
        infiniteScrolling: Bool
    ) {
        self.tabBarSettings = tabBarSettings
        self.menuItemsSettings = menuItemsSettings
        self.hidePublishStoriesButton = hidePublishStoriesButton
        self.hideStories = hideStories
        self.hideViewedStories = hideViewedStories
        self.hidePhone = hidePhone
        self.disableReadHistory = disableReadHistory
        self.offlineMode = offlineMode
        self.videoMessageCamera = videoMessageCamera
        self.callConfirmation = callConfirmation
        self.sendAudioConfirmation = sendAudioConfirmation
        self.chatsFoldersAtBottom = chatsFoldersAtBottom
        self.hideAllChatsFolder = hideAllChatsFolder
        self.infiniteScrolling = infiniteScrolling
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.tabBarSettings = (try container.decodeIfPresent(TabBarSettings.self, forKey: "tabBarSettings") ?? .default)
        self.menuItemsSettings = (try container.decodeIfPresent(MenuItemsSettings.self, forKey: "menuItemsSettings") ?? .default)
        // Раздел Stories
        self.hidePublishStoriesButton = (try container.decodeIfPresent(Int32.self, forKey: "hidePublishStoriesButton") ?? 0) != 0
        self.hideStories = (try container.decodeIfPresent(Int32.self, forKey: "hideStories") ?? 0) != 0
        self.hideViewedStories = (try container.decodeIfPresent(Int32.self, forKey: "hideViewedStories") ?? 0) != 0
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
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.tabBarSettings, forKey: "tabBarSettings")
        try container.encode(self.menuItemsSettings, forKey: "menuItemsSettings")
        // Раздел Stories
        try container.encode((self.hidePublishStoriesButton ? 1 : 0) as Int32, forKey: "hidePublishStoriesButton")
        try container.encode((self.hideStories ? 1 : 0) as Int32, forKey: "hideStories")
        try container.encode((self.hideViewedStories ? 1 : 0) as Int32, forKey: "hideViewedStories")
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
