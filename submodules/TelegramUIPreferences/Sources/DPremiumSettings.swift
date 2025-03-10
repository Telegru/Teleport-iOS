import Foundation

public struct DPremiumSettings: Codable, Equatable {
    
    public var showStatusIcon: Bool
    public var showAnimatedAvatar: Bool
    public var showAnimatedReactions: Bool
    public var showPremiumStickerAnimation: Bool
    
    public init(
        showStatusIcon: Bool,
        showAnimatedAvatar: Bool,
        showAnimatedReactions: Bool,
        showPremiumStickerAnimation: Bool
    ) {
        self.showStatusIcon = showStatusIcon
        self.showAnimatedAvatar = showAnimatedAvatar
        self.showAnimatedReactions = showAnimatedReactions
        self.showPremiumStickerAnimation = showPremiumStickerAnimation
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.showStatusIcon = try container.decodeIfPresent(Bool.self, forKey: .showStatusIcon) ?? true
        self.showAnimatedAvatar = try container.decodeIfPresent(Bool.self, forKey: .showAnimatedAvatar) ?? true
        self.showAnimatedReactions = try container.decodeIfPresent(Bool.self, forKey: .showAnimatedReactions) ?? true
        self.showPremiumStickerAnimation = try container.decodeIfPresent(Bool.self, forKey: .showPremiumStickerAnimation) ?? true
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showStatusIcon, forKey: .showStatusIcon)
        try container.encode(showAnimatedAvatar, forKey: .showAnimatedAvatar)
        try container.encode(showAnimatedReactions, forKey: .showAnimatedReactions)
        try container.encode(showPremiumStickerAnimation, forKey: .showPremiumStickerAnimation)
    }
    
    enum CodingKeys: CodingKey {
        case showStatusIcon
        case showAnimatedAvatar
        case showAnimatedReactions
        case showPremiumStickerAnimation
    }
}

extension DPremiumSettings {
    
    public static var `default`: DPremiumSettings {
        DPremiumSettings(
            showStatusIcon: true,
            showAnimatedAvatar: true,
            showAnimatedReactions: true,
            showPremiumStickerAnimation: true
        )
    }
}
