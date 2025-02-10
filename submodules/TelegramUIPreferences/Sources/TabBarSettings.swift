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
    
    #if DEBUG
    case wall
    #endif
    
    public var isAlwaysShow: Bool {
        switch self {
        case .chats, .settings:
            return true
        default:
            return false
        }
    }
}

public struct TabBarSettings: Codable, Hashable {
    
    public var activeTabs: [DAppTab]
    
    public init(currentTabs: [DAppTab]) {
        self.activeTabs = currentTabs
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.activeTabs = try container
            .decodeIfPresent([Int32].self, forKey: "currentTabs")?
            .compactMap { DAppTab(rawValue: Int($0)) } ?? []
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(self.activeTabs.map { Int32($0.rawValue) }, forKey: "currentTabs")
    }
}

extension TabBarSettings {
    
    public static var `default`: TabBarSettings {
        TabBarSettings(currentTabs: [
            .contacts,
            .calls,
//            .apps,
//            .wallet,
            .chats,
            .dahlSettings,
            .settings
        ])
    }
}
