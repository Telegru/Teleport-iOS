import Foundation

public struct DAppearanceSettings: Codable, Equatable {
    
    public var squareStyle: Bool
    
    public init(squareStyle: Bool) {
        self.squareStyle = squareStyle
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.squareStyle = try container.decode(Bool.self, forKey: .squareStyle)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(squareStyle, forKey: .squareStyle)
    }
    
    enum CodingKeys: CodingKey {
        case squareStyle
    }
}

extension DAppearanceSettings {
    
    public static var `default`: DAppearanceSettings {
        DAppearanceSettings(
            squareStyle: false
        )
    }
}
