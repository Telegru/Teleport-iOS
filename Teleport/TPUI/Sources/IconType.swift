import UIKit

public enum IconType: String, CaseIterable {
    case callsTab
    case chatsTab
    case contactsTab
    case settingsTab
    case wallTab
    case addStory
    case storyCompose
    case peerPinnedIcon
    case profile
    case savedMessages
    case chatListFilters
    case sessions
    case notifications
    case security
    case dataAndStorage
    case appearance
    case powerSaving
    case language
    case dahl
    case qrIcon
    case setAvatar
    case recentCalls
    case backArrow
    case attachMenuFile
    case attachMenuGallery
    case attachMenuReply
    case attachMenuLocation
    case attachMenuGift
    case attachMenuContacts
    case addMemberIcon
    case peerAddMember
    case peerButtonCall
    case peerVideoCall
    case peerMute
    case peerUnmute
    case peerSearch
    case peerMore
    case peerLeave
    case avatarSaved
    case avatarArchive
    case contextMenuClear
    case contextMenuDelete
    case contextMenuEye
    case chatAdd
    case chatDelete
    case wallGear
}

public enum IconRef: Equatable {
    case iconType(iconType: IconType)
    case name(name: String)
    
    public static func == (lhs: IconRef, rhs: IconRef) -> Bool {
         switch (lhs, rhs) {
         case (.iconType(let lhsType), .iconType(let rhsType)):
             return lhsType == rhsType
         case (.name(let lhsName), .name(let rhsName)):
             return lhsName == rhsName
         default:
             return false
         }
     }
}

public extension IconRef {
    var image: UIImage? {
        switch self {
        case .iconType(let iconType):
            return TPIconManager.shared.icon(iconType)
        case .name(let name):
            return UIImage(named: name)
        }
    }
}
