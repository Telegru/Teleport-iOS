import Foundation
import TelegramCore

public struct DWallSettings: Codable, Equatable {
    
    public var markAsRead: Bool
    public var showArchivedChannels: Bool
    public var excludedChannels: [EnginePeer.Id]
    
    public init(
        markAsRead: Bool,
        showArchivedChannels: Bool,
        excludedChannels: [EnginePeer.Id]
    ) {
        self.markAsRead = markAsRead
        self.showArchivedChannels = showArchivedChannels
        self.excludedChannels = excludedChannels
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.markAsRead = try container.decodeIfPresent(Bool.self, forKey: .markAsRead) ?? false
        self.showArchivedChannels = try container.decodeIfPresent(Bool.self, forKey: .showArchivedChannels) ?? false
        self.excludedChannels = try container.decodeIfPresent([EnginePeer.Id].self, forKey: .excludedChannels) ?? []
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(markAsRead, forKey: .markAsRead)
        try container.encode(showArchivedChannels, forKey: .showArchivedChannels)
        try container.encode(excludedChannels, forKey: .excludedChannels)
    }
    
    enum CodingKeys: CodingKey {
        case markAsRead
        case showArchivedChannels
        case excludedChannels
    }
}

extension DWallSettings {
    
    public static var `default`: DWallSettings {
        DWallSettings(
            markAsRead: false,
            showArchivedChannels: true,
            excludedChannels: []
        )
    }
}
