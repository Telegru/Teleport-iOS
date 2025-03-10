import UIKit

public struct DahlIconSet: IconSet {
    
    public init() {}
    
    public func icon(_ type: IconType) -> UIImage? {
        switch type {
        case .addStory:
            return UIImage(bundleImageName: "TPChat List/AddStoryIcon")!
        case .storyCompose:
            return UIImage(bundleImageName: "TPChat List/ComposeIcon")!
        case .peerPinnedIcon:
            return UIImage(bundleImageName: "TPChat List/PeerPinnedIcon")!
        case .profile:
            return UIImage(bundleImageName: "Settings/Profile")!
        case .savedMessages:
            return UIImage(bundleImageName: "Settings/SavedMessages")!
        case .chatListFilters:
            return UIImage(bundleImageName: "Settings/ChatListFilters")!
        case .sessions:
            return UIImage(bundleImageName: "Settings/Sessions")!
        case .notifications:
            return UIImage(bundleImageName: "Settings/Notifications")!
        case .security:
            return UIImage(bundleImageName: "Settings/Security")!
        case .dataAndStorage:
            return UIImage(bundleImageName: "Settings/DataAndStorage")!
        case .appearance:
            return UIImage(bundleImageName: "Settings/Appearance")!
        case .powerSaving:
            return UIImage(bundleImageName: "Settings/PowerSaving")!
        case .language:
            return UIImage(bundleImageName: "Settings/Language")!
        case .dahl:
            return UIImage(bundleImageName: "Settings/Dahl")!
        case .qrIcon:
            return UIImage(bundleImageName: "Settings/QRIcon")!
        case .setAvatar:
            return UIImage(bundleImageName: "Settings/SetAvatar")!
        case .recentCalls:
            return UIImage(bundleImageName: "Settings/RecentCalls")!
        case .backArrow:
            return UIImage(bundleImageName: "Navigation/BackArrow")!
        case .attachMenuFile:
            return UIImage(bundleImageName: "Attach/AttachMenuFile")!
        case .attachMenuGallery:
            return UIImage(bundleImageName: "Attach/AttachMenuGallery")!
        case .attachMenuReply:
            return UIImage(bundleImageName: "Attach/AttachMenuReply")!
        case .attachMenuLocation:
            return UIImage(bundleImageName: "Attach/AttachMenuLocation")!
        case .attachMenuGift:
            return UIImage(bundleImageName: "Attach/AttachMenuGift")!
        case .attachMenuContacts:
            return UIImage(bundleImageName: "Attach/AttachMenuContacts")!
        case .addMemberIcon:
            return UIImage(bundleImageName: "Peer/addMember")!
        case .peerButtonCall:
            return UIImage(bundleImageName: "Peer/ButtonCall")!
        case .peerVideoCall:
            return UIImage(bundleImageName: "Peer/VideoCall")!
        case .peerMute:
            return UIImage(bundleImageName: "Peer/Mute")!
        case .peerUnmute:
            return UIImage(bundleImageName: "Peer/Unmute")!
        case .peerSearch:
            return UIImage(bundleImageName: "Peer/Search")!
        case .peerMore:
            return UIImage(bundleImageName: "Peer/More")!
        case .peerLeave:
            return UIImage(bundleImageName: "Peer/Leave")!
        case .peerAddMember:
            return UIImage(bundleImageName: "Peer/ButtonAddMember")!
        case .avatarSaved:
            return UIImage(bundleImageName: "Avatar/Saved")!
        case .avatarArchive:
            return UIImage(bundleImageName: "Avatar/Archive")!
        case .contextMenuClear:
            return UIImage(bundleImageName: "Context Menu/Clear")!
        case .contextMenuDelete:
            return UIImage(bundleImageName: "Context Menu/Delete")!
        case .contextMenuEye:
            return UIImage(bundleImageName: "Context Menu/Eye")!
        case .callsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/DIconCalls")
        case .contactsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/DIconContacts")
        case .chatsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/DIconChats")
        case .settingsTab:
            return UIImage(bundleImageName: "Chat List/Tabs/DIconSettings")
        case .chatAdd:
            return UIImage(bundleImageName: "TPChat List/Add")!
        case .chatDelete:
            return UIImage(bundleImageName: "TPChat List/Delete")!
        }
    }
}
