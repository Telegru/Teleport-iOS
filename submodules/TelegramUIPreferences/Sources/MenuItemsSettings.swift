import Foundation

public struct MenuItemsSettings: Codable, Equatable {
    
    public var myProfile: Bool
    public var wallet: Bool
    public var savedMessages: Bool
    public var recentCalls: Bool
    public var devices: Bool
    public var chatFolders: Bool
    public var premium: Bool
    public var myStars: Bool
    public var business: Bool
    public var sendGift: Bool
    public var support: Bool
    public var faq: Bool
    public var tips: Bool
    
   public init(myProfile: Bool, wallet: Bool, savedMessages: Bool, recentCalls: Bool, devices: Bool, chatFolders: Bool, premium: Bool, myStars: Bool, business: Bool, sendGift: Bool, support: Bool, faq: Bool, tips: Bool) {
        self.myProfile = myProfile
        self.wallet = wallet
        self.savedMessages = savedMessages
        self.recentCalls = recentCalls
        self.devices = devices
        self.chatFolders = chatFolders
        self.premium = premium
        self.myStars = myStars
        self.business = business
        self.sendGift = sendGift
        self.support = support
        self.faq = faq
        self.tips = tips
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.myProfile = try container.decodeIfPresent(Bool.self, forKey: .myProfile) ?? true
        self.wallet = try container.decodeIfPresent(Bool.self, forKey: .wallet) ?? true
        self.savedMessages = try container.decodeIfPresent(Bool.self, forKey: .savedMessages) ?? false
        self.recentCalls = try container.decodeIfPresent(Bool.self, forKey: .recentCalls) ?? true
        self.devices = try container.decodeIfPresent(Bool.self, forKey: .devices) ?? false
        self.chatFolders = try container.decodeIfPresent(Bool.self, forKey: .chatFolders) ?? false
        self.premium = try container.decodeIfPresent(Bool.self, forKey: .premium) ?? false
        self.myStars = try container.decodeIfPresent(Bool.self, forKey: .myStars) ?? false
        self.business = try container.decodeIfPresent(Bool.self, forKey: .business) ?? false
        self.sendGift = try container.decodeIfPresent(Bool.self, forKey: .sendGift) ?? false
        self.support = try container.decodeIfPresent(Bool.self, forKey: .support) ?? false
        self.faq = try container.decodeIfPresent(Bool.self, forKey: .faq) ?? false
        self.tips = try container.decodeIfPresent(Bool.self, forKey: .tips) ?? false
    }
    
    enum CodingKeys: CodingKey {
        case myProfile
        case wallet
        case savedMessages
        case recentCalls
        case devices
        case chatFolders
        case premium
        case myStars
        case business
        case sendGift
        case support
        case faq
        case tips
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.myProfile, forKey: .myProfile)
        try container.encode(self.wallet, forKey: .wallet)
        try container.encode(self.savedMessages, forKey: .savedMessages)
        try container.encode(self.recentCalls, forKey: .recentCalls)
        try container.encode(self.devices, forKey: .devices)
        try container.encode(self.chatFolders, forKey: .chatFolders)
        try container.encode(self.premium, forKey: .premium)
        try container.encode(self.myStars, forKey: .myStars)
        try container.encode(self.business, forKey: .business)
        try container.encode(self.sendGift, forKey: .sendGift)
        try container.encode(self.support, forKey: .support)
        try container.encode(self.faq, forKey: .faq)
        try container.encode(self.tips, forKey: .tips)
    }
    
}

extension MenuItemsSettings{
    
    public static var `default`: MenuItemsSettings {
        return MenuItemsSettings(
            myProfile: true,
            wallet: true,
            savedMessages: false,
            recentCalls: true,
            devices: false,
            chatFolders: false,
            premium: false,
            myStars: false,
            business: false,
            sendGift: false,
            support: false,
            faq: false,
            tips: false
        )
    }
}
