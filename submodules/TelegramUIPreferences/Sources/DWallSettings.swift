import Foundation
import TelegramCore

public struct DWallSettings: Codable, Equatable {
    
    public var showArchivedChannels: Bool
    public var excludedChannels: [EnginePeer.Id]
    
    public init(
        showArchivedChannels: Bool,
        excludedChannels: [EnginePeer.Id]
    ) {
        self.showArchivedChannels = showArchivedChannels
        self.excludedChannels = excludedChannels
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.showArchivedChannels = try container.decodeIfPresent(Bool.self, forKey: .showArchivedChannels) ?? false
        self.excludedChannels = try container.decodeIfPresent([EnginePeer.Id].self, forKey: .excludedChannels) ?? []
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showArchivedChannels, forKey: .showArchivedChannels)
        try container.encode(excludedChannels, forKey: .excludedChannels)
    }
    
    enum CodingKeys: CodingKey {
        case showArchivedChannels
        case excludedChannels
    }
}

extension DWallSettings {
    
    public static var `default`: DWallSettings {
        DWallSettings(
            showArchivedChannels: true,
            excludedChannels: []
        )
    }
}
