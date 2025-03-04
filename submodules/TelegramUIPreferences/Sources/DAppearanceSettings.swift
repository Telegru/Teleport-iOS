import Foundation

public struct DAppearanceSettings: Codable, Equatable {
    
    public var squareStyle: Bool
    public var vkIcons: Bool
    
    public init(
        squareStyle: Bool,
        vkIcons: Bool
    ) {
        self.squareStyle = squareStyle
        self.vkIcons = vkIcons
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.squareStyle = try container.decode(Bool.self, forKey: .squareStyle)
        self.vkIcons = try container.decode(Bool.self, forKey: .vkIcons)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(squareStyle, forKey: .squareStyle)
        try container.encode(vkIcons, forKey: .vkIcons)
    }
    
    enum CodingKeys: CodingKey {
        case squareStyle
        case vkIcons
    }
}

extension DAppearanceSettings {
    
    public static var `default`: DAppearanceSettings {
        DAppearanceSettings(
            squareStyle: false,
            vkIcons: false
        )
    }
}
