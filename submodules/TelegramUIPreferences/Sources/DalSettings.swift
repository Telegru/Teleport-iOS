import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore


public struct DalSettings: Codable, Equatable {
    // Раздел Stories
    public var hidePublishStoriesButton: Bool
    public var hideStories: Bool
    public var hideViewedStories: Bool
    
    // Раздел Конфиденциальность
    public var hidePhone: Bool
    public var disableReadHistory: Bool
    public var offlineMode: Bool

    public static var defaultSettings: DalSettings {
        return DalSettings(
            hidePublishStoriesButton: false,
            hideStories: false,
            hideViewedStories: false,
            hidePhone: false,
            disableReadHistory: false,
            offlineMode: false
        )
    }
    
    public init(
        hidePublishStoriesButton: Bool,
        hideStories: Bool,
        hideViewedStories: Bool,
        hidePhone: Bool,
        disableReadHistory: Bool,
        offlineMode: Bool
    ) {
        self.hidePublishStoriesButton = hidePublishStoriesButton
        self.hideStories = hideStories
        self.hideViewedStories = hideViewedStories
        self.hidePhone = hidePhone
        self.disableReadHistory = disableReadHistory
        self.offlineMode = offlineMode
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        // Раздел Stories
        self.hidePublishStoriesButton = (try container.decodeIfPresent(Int32.self, forKey: "hidePublishStoriesButton") ?? 0) != 0
        self.hideStories = (try container.decodeIfPresent(Int32.self, forKey: "hideStories") ?? 0) != 0
        self.hideViewedStories = (try container.decodeIfPresent(Int32.self, forKey: "hideViewedStories") ?? 0) != 0
        // Раздел Конфиденциальность
        self.hidePhone = (try container.decodeIfPresent(Int32.self, forKey: "hidePhone") ?? 0) != 0
        self.disableReadHistory = (try container.decodeIfPresent(Int32.self, forKey: "disableReadHistory") ?? 0) != 0
        self.offlineMode = (try container.decodeIfPresent(Int32.self, forKey: "offlineMode") ?? 0) != 0
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        // Раздел Stories
        try container.encode((self.hidePublishStoriesButton ? 1 : 0) as Int32, forKey: "hidePublishStoriesButton")
        try container.encode((self.hideStories ? 1 : 0) as Int32, forKey: "hideStories")
        try container.encode((self.hideViewedStories ? 1 : 0) as Int32, forKey: "hideViewedStories")
        // Раздел Конфиденциальность
        try container.encode((self.hidePhone ? 1 : 0) as Int32, forKey: "hidePhone")
        try container.encode((self.disableReadHistory ? 1 : 0) as Int32, forKey: "disableReadHistory")
        try container.encode((self.offlineMode ? 1 : 0) as Int32, forKey: "offlineMode")
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
