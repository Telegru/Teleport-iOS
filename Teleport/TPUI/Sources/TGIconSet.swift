import UIKit

public struct TGIconSet: IconSet {
    
    public init() {}
    
    public func icon(_ type: IconType) -> UIImage? {
        switch type {
        case .addStory:
            return UIImage(bundleImageName: "Chat List/AddStoryIcon")
        case .storyCompose:
            return UIImage(bundleImageName: "Chat List/ComposeIcon")
        case .peerPinnedIcon:
            return UIImage(bundleImageName: "Chat List/PeerPinnedIcon")
        case .profile:
            return UIImage(bundleImageName: "Settings/Menu/Profile")
        case .savedMessages:
            return UIImage(bundleImageName: "Settings/Menu/SavedMessages")
        case .chatListFilters:
            return UIImage(bundleImageName: "Settings/Menu/ChatListFilters")
        case .sessions:
            return UIImage(bundleImageName: "Settings/Menu/Sessions")
        case .notifications:
            return UIImage(bundleImageName: "Settings/Menu/Notifications")
        case .security:
            return UIImage(bundleImageName: "Settings/Menu/Security")
        case .dataAndStorage:
            return UIImage(bundleImageName: "Settings/Menu/DataAndStorage")
        case .appearance:
            return UIImage(bundleImageName: "Settings/Menu/Appearance")
        case .powerSaving:
            return UIImage(bundleImageName: "Settings/Menu/PowerSaving")
        case .language:
            return UIImage(bundleImageName: "Settings/Menu/Language")
        case .dahl:
            return UIImage(bundleImageName: "Settings/Dahl")
        case .qrIcon:
            return UIImage(bundleImageName: "Settings/QrIcon")
        case .setAvatar:
            return UIImage(bundleImageName: "Settings/SetAvatar")
        case .recentCalls:
            return UIImage(bundleImageName: "Settings/Menu/RecentCalls")
        case .backArrow:
            return UIImage(bundleImageName: "Navigation/BackArrow")
        case .attachMenuFile:
            return UIImage(bundleImageName: "Chat/Attach Menu/File")
        case .attachMenuGallery:
            return UIImage(bundleImageName: "Chat/Attach Menu/Gallery")
        case .attachMenuReply:
            return UIImage(bundleImageName: "Chat/Attach Menu/Reply")
        case .attachMenuLocation:
            return UIImage(bundleImageName: "Chat/Attach Menu/Location")
        case .attachMenuGift:
            return UIImage(bundleImageName: "Chat/Attach Menu/Gift")
        case .attachMenuContacts:
            return UIImage(bundleImageName: "Chat/Attach Menu/Contact")
        case .addMemberIcon:
            return UIImage(bundleImageName: "Contact List/AddMemberIcon")
        case .peerButtonCall:
            return UIImage(bundleImageName: "Peer Info/ButtonCall")
        case .peerVideoCall:
            return UIImage(bundleImageName: "Peer Info/ButtonVideo")
        case .peerMute:
            return nil
        case .peerUnmute:
            return nil
        case .peerSearch:
            return UIImage(bundleImageName: "Peer Info/ButtonSearch")
        case .peerMore:
            return nil
        case .peerLeave:
            return nil
        case .peerAddMember:
            return UIImage(bundleImageName: "Peer Info/ButtonAddMember")
        case .avatarSaved:
            return UIImage(bundleImageName: "Avatar/SavedMessagesIcon")
        case .avatarArchive:
            return UIImage(bundleImageName: "Avatar/ArchiveAvatarIcon")
        case .contextMenuClear:
            return UIImage(bundleImageName: "Context Menu/Clear")
        case .contextMenuDelete:
            return UIImage(bundleImageName: "Context Menu/Delete")
        case .contextMenuEye:
            return UIImage(bundleImageName: "Context Menu/Eye")
        case .callsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/IconCalls")
        case .contactsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/IconContacts")
        case .chatsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/IconChats")
        case .settingsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/IconSettings")
        case .wallTab:
            return UIImage(bundleImageName: "Wall/WallTabTG")
        case .chatAdd:
            return UIImage(bundleImageName: "Chat List/AddIcon")
        case .chatDelete:
            return UIImage(bundleImageName: "Chat/Input/Accessory Panels/MessageSelectionTrash")
        case .wallGear:
            return UIImage(bundleImageName: "Wall/WallGear")
        }
    }
    
}
