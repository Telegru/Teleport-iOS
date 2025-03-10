import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext
import AppBundle
import PresentationDataUtils
import ItemListPeerItem
import ItemListPeerActionItem

import TPUI
import TPStrings

private final class DWallSettingsArguments {
    let context: AccountContext
    let updateShowArchivedChannels: (Bool) -> Void
    let addExcludedChannel: () -> Void
    let removeExcludedChannel: (EnginePeer.Id) -> Void
    let removeAllExcludedChannels: () -> Void
    let setPeerIdWithRevealedOptions: (EnginePeer.Id?, EnginePeer.Id?) -> Void
    
    init(
        context: AccountContext,
        updateShowArchivedChannels: @escaping (Bool) -> Void,
        addExcludedChannel: @escaping () -> Void,
        removeExcludedChannel: @escaping (EnginePeer.Id) -> Void,
        removeAllExcludedChannels: @escaping () -> Void,
        setPeerIdWithRevealedOptions: @escaping (EnginePeer.Id?, EnginePeer.Id?) -> Void
    ) {
        self.context = context
        self.updateShowArchivedChannels = updateShowArchivedChannels
        self.addExcludedChannel = addExcludedChannel
        self.removeExcludedChannel = removeExcludedChannel
        self.removeAllExcludedChannels = removeAllExcludedChannels
        self.setPeerIdWithRevealedOptions = setPeerIdWithRevealedOptions
    }
}

private struct DWallSettingsState: Equatable {
    var revealedPeerId: EnginePeer.Id?
}

private enum DWallSettingsSection: Int32, CaseIterable {
    case display
    case excluded
}

private enum DWallSettingsEntryTag: ItemListItemTag {
    case showArchivedChannels
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DWallSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DWallSettingsEntry: ItemListNodeEntry {
    case displayHeader(PresentationTheme, title: String)
    case showArchivedChannels(PresentationTheme, title: String, value: Bool)
    case displayFooter(PresentationTheme, title: String)
    
    case excludedHeader(PresentationTheme, title: String)
    case addExcludedChannel(PresentationTheme, title: String)
    case excludedChannel(Int32, PresentationTheme, EnginePeer, Bool)
    case removeAllExcludedChannels(PresentationTheme, title: String)
    case excludedFooter(PresentationTheme, title: String)
    
    var section: ItemListSectionId {
        switch self {
        case .displayHeader, .showArchivedChannels, .displayFooter:
            return DWallSettingsSection.display.rawValue
        case .excludedHeader, .addExcludedChannel, .excludedChannel, .removeAllExcludedChannels, .excludedFooter:
            return DWallSettingsSection.excluded.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .displayHeader:
            return 0
        case .showArchivedChannels:
            return 1
        case .displayFooter:
            return 2
        case .excludedHeader:
            return 3
        case .addExcludedChannel:
            return 4
        case let .excludedChannel(index, _, _, _):
            return 100 + index
        case .removeAllExcludedChannels:
            return 5
        case .excludedFooter:
            return 6
        }
    }
    
    var tag: ItemListItemTag? {
        switch self {
        case .showArchivedChannels:
            return DWallSettingsEntryTag.showArchivedChannels
        default:
            return nil
        }
    }
    
    static func ==(lhs: DWallSettingsEntry, rhs: DWallSettingsEntry) -> Bool {
        switch lhs {
        case let .displayHeader(lhsTheme, lhsTitle):
            if case let .displayHeader(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .showArchivedChannels(lhsTheme, lhsTitle, lhsValue):
            if case let .showArchivedChannels(rhsTheme, rhsTitle, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .displayFooter(lhsTheme, lhsTitle):
            if case let .displayFooter(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .excludedHeader(lhsTheme, lhsTitle):
            if case let .excludedHeader(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .addExcludedChannel(lhsTheme, lhsTitle):
            if case let .addExcludedChannel(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .excludedChannel(lhsIndex, lhsTheme, lhsPeer, lhsRevealed):
            if case let .excludedChannel(rhsIndex, rhsTheme, rhsPeer, rhsRevealed) = rhs,
                lhsIndex == rhsIndex,
                lhsTheme === rhsTheme,
                lhsPeer == rhsPeer,
                lhsRevealed == rhsRevealed {
                return true
            } else {
                return false
            }
            
        case let .removeAllExcludedChannels(lhsTheme, lhsTitle):
            if case let .removeAllExcludedChannels(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .excludedFooter(lhsTheme, lhsTitle):
            if case let .excludedFooter(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: DWallSettingsEntry, rhs: DWallSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(
        presentationData: ItemListPresentationData,
        arguments: Any
    ) -> ListViewItem {
        let arguments = arguments as! DWallSettingsArguments
        
        switch self {
        case let .displayHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .showArchivedChannels(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateShowArchivedChannels(updatedValue)
                },
                tag: self.tag
            )
            
        case let .displayFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )
            
        case let .excludedHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .addExcludedChannel(_, title):
            return ItemListPeerActionItem(
                presentationData: presentationData,
                icon: PresentationResourcesItemList.plusIconImage(presentationData.theme, color: presentationData.theme.list.itemPrimaryTextColor),
                title: title,
                sectionId: self.section,
                height: .generic,
                editing: false,
                action: {
                    arguments.addExcludedChannel()
                }
            )
            
        case let .excludedChannel(_, _, peer, isRevealed):
            return ItemListPeerItem(
                presentationData: presentationData,
                dateTimeFormat: PresentationDateTimeFormat(),
                nameDisplayOrder: .firstLast,
                context: arguments.context,
                peer: peer,
                height: .generic,
                aliasHandling: .threatSelfAsSaved,
                presence: nil,
                text: .none,
                label: .none,
                editing: ItemListPeerItemEditing(editable: true, editing: false, revealed: isRevealed),
                switchValue: nil,
                enabled: true,
                selectable: false,
                sectionId: self.section,
                action: nil,
                setPeerIdWithRevealedOptions: { peerId, fromPeerId in
                    arguments.setPeerIdWithRevealedOptions(peerId, fromPeerId)
                },
                removePeer: { peerId in
                    arguments.removeExcludedChannel(peerId)
                }
            )
            
        case let .removeAllExcludedChannels(_, title):
            return ItemListPeerActionItem(
                presentationData: presentationData,
                icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme),
                title: title,
                sectionId: self.section,
                height: .generic,
                editing: false,
                action: {
                    arguments.removeAllExcludedChannels()
                }
            )
            
        case let .excludedFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )
        }
    }
}

private func dWallSettingsEntries(
    presentationData: PresentationData,
    state: DWallSettingsState,
    wallSettings: DWallSettings,
    excludedPeers: [EnginePeer]
) -> [DWallSettingsEntry] {
    var entries: [DWallSettingsEntry] = []
    let lang = presentationData.strings.baseLanguageCode
    
    entries.append(
        .displayHeader(
            presentationData.theme,
            title: "DahlSettings.Wall.Display.Header".tp_loc(lang: lang).uppercased()
        )
    )
    
    entries.append(
        .showArchivedChannels(
            presentationData.theme,
            title: "DahlSettings.Wall.Display.ArchivedChannels".tp_loc(lang: lang),
            value: wallSettings.showArchivedChannels
        )
    )
    
    entries.append(
        .displayFooter(
            presentationData.theme,
            title: "DahlSettings.Wall.Display.Footer".tp_loc(lang: lang)
        )
    )
    
    entries.append(
        .excludedHeader(
            presentationData.theme,
            title: "DahlSettings.Wall.Excluded.Header".tp_loc(lang: lang).uppercased()
        )
    )
    
    entries.append(
        .addExcludedChannel(
            presentationData.theme,
            title: "DahlSettings.Wall.Excluded.AddExclusion".tp_loc(lang: lang)
        )
    )
    
    var index: Int32 = 0
    for peer in excludedPeers {
        entries.append(
            .excludedChannel(
                index,
                presentationData.theme,
                peer,
                state.revealedPeerId == peer.id
            )
        )
        index += 1
    }
    
    if !excludedPeers.isEmpty {
        entries.append(
            .removeAllExcludedChannels(
                presentationData.theme,
                title: "DahlSettings.Wall.Excluded.RemoveAll".tp_loc(lang: lang)
            )
        )
    }
    
    entries.append(
        .excludedFooter(
            presentationData.theme,
            title: "DahlSettings.Wall.Excluded.Footer".tp_loc(lang: lang)
        )
    )
    
    return entries
}

