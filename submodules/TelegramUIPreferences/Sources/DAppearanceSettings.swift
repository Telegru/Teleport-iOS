import Foundation

public struct DAppearanceSettings: Codable, Equatable {
    
    public var squareStyle: Bool
    public var vkIcons: Bool
    public var alternativeAvatarFont: Bool
    
    public init(
        squareStyle: Bool,
        vkIcons: Bool,
        alternativeAvatarFont: Bool
    ) {
        self.squareStyle = squareStyle
        self.vkIcons = vkIcons
        self.alternativeAvatarFont = alternativeAvatarFont
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.squareStyle = try container.decode(Bool.self, forKey: .squareStyle)
        self.vkIcons = try container.decode(Bool.self, forKey: .vkIcons)
        self.alternativeAvatarFont = try container.decode(Bool.self, forKey: .alternativeAvatarFont)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(squareStyle, forKey: .squareStyle)
        try container.encode(vkIcons, forKey: .vkIcons)
        try container.encode(alternativeAvatarFont, forKey: .alternativeAvatarFont)
    }
    
    enum CodingKeys: CodingKey {
        case squareStyle
        case vkIcons
        case alternativeAvatarFont
    }
}

extension DAppearanceSettings {
    
    public static var `default`: DAppearanceSettings {
        DAppearanceSettings(
            squareStyle: false,
            vkIcons: false,
            alternativeAvatarFont: false
        )
    }
}
