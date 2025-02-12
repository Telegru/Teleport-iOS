import Foundation
import TelegramCore

public enum DAppTab: Int, Codable, CaseIterable {
    case chats
    case settings
    case contacts
    case calls
    case dahlSettings
//    case wallet
//    case apps
//    case channels
    case wall
    
    public var isAlwaysShow: Bool {
        switch self {
        case .chats, .settings:
            return true
        default:
            return false
        }
    }
}

public struct DTabBarSettings: Codable, Hashable {
    
    public var activeTabs: [DAppTab]
    public var showTabTitles: Bool
    
    public init(
        currentTabs: [DAppTab],
        showTabTitles: Bool
    ) {
        self.activeTabs = currentTabs
        self.showTabTitles = showTabTitles
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.activeTabs = try container
            .decodeIfPresent([Int32].self, forKey: "currentTabs")?
            .compactMap { DAppTab(rawValue: Int($0)) } ?? []
        self.showTabTitles = try container.decodeIfPresent(Bool.self, forKey: "showTabTitles") ?? true
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.activeTabs.map { Int32($0.rawValue) }, forKey: "currentTabs")
        try container.encode(self.showTabTitles, forKey: "showTabTitles")
    }
}

extension DTabBarSettings {
    
    public static var `default`: DTabBarSettings {
        DTabBarSettings(
            currentTabs: [
                .contacts,
                .chats,
                .settings
            ],
            showTabTitles: true
        )

}
