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
import AsyncDisplayKit
import ContextUI

import TPUI
import TPStrings

private final class DWallSettingsArguments {
    let context: AccountContext
    let updateShowArchivedChannels: (Bool) -> Void
    let updateMarkAsRead: (Bool) -> Void
    let addExcludedChannel: () -> Void
    let removeExcludedChannel: (EnginePeer.Id) -> Void
    let removeAllExcludedChannels: () -> Void
    let setPeerIdWithRevealedOptions: (EnginePeer.Id?, EnginePeer.Id?) -> Void
    let peerContextAction: (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void
    
    init(
        context: AccountContext,
        updateShowArchivedChannels: @escaping (Bool) -> Void,
        updateMarkAsRead: @escaping (Bool) -> Void,
        addExcludedChannel: @escaping () -> Void,
        removeExcludedChannel: @escaping (EnginePeer.Id) -> Void,
        removeAllExcludedChannels: @escaping () -> Void,
        setPeerIdWithRevealedOptions: @escaping (EnginePeer.Id?, EnginePeer.Id?) -> Void,
        peerContextAction: @escaping (EnginePeer, ASDisplayNode, ContextGesture?, CGPoint?) -> Void
    ) {
        self.context = context
        self.updateShowArchivedChannels = updateShowArchivedChannels
        self.updateMarkAsRead = updateMarkAsRead
        self.addExcludedChannel = addExcludedChannel
        self.removeExcludedChannel = removeExcludedChannel
        self.removeAllExcludedChannels = removeAllExcludedChannels
        self.setPeerIdWithRevealedOptions = setPeerIdWithRevealedOptions
        self.peerContextAction = peerContextAction
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
    case markAsRead
    
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
    case markAsRead(PresentationTheme, title: String, value: Bool)
    case displayFooter(PresentationTheme, title: String)
    
    case excludedHeader(PresentationTheme, title: String)
    case addExcludedChannel(PresentationTheme, title: String)
    case excludedChannel(Int32, PresentationTheme, EnginePeer, Bool)
    case removeAllExcludedChannels(PresentationTheme, title: String)
    case excludedFooter(PresentationTheme, title: String)
    
    var section: ItemListSectionId {
        switch self {
        case .displayHeader, .showArchivedChannels, .markAsRead, .displayFooter:
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
        case .markAsRead:
            return 3
        case .excludedHeader:
            return 4
        case .addExcludedChannel:
            return 5
        case let .excludedChannel(index, _, _, _):
            return 100 + index
        case .removeAllExcludedChannels:
            return 500
        case .excludedFooter:
            return 600
        }
    }
    
    var tag: ItemListItemTag? {
        switch self {
        case .showArchivedChannels:
            return DWallSettingsEntryTag.showArchivedChannels
        case .markAsRead:
            return DWallSettingsEntryTag.markAsRead
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
            
        case let .markAsRead(lhsTheme, lhsTitle, lhsValue):
            if case let .markAsRead(rhsTheme, rhsTitle, rhsValue) = rhs,
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
        if lhs.section != rhs.section {
            return lhs.section < rhs.section
        }
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
            
        case let .markAsRead(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateMarkAsRead(updatedValue)
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
                color: .primary,
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
                revealOptions: ItemListPeerItemRevealOptions(options: [ItemListPeerItemRevealOption(type: .destructive, title: presentationData.strings.Common_Delete, action: {
                    arguments.removeExcludedChannel(peer.id)
                })]),
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
                },
                contextAction: { sourceNode, gesture in
                    arguments.peerContextAction(peer, sourceNode, gesture, nil)
                }
            )
            
        case let .removeAllExcludedChannels(_, title):
            return ItemListPeerActionItem(
                presentationData: presentationData,
                icon: PresentationResourcesItemList.deleteIconImage(presentationData.theme),
                title: title,
                sectionId: self.section,
                height: .generic,
                color: .destructive,
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
    excludedPeers: [EnginePeer],
    excludedPeersGroups: [EnginePeer.Id: EngineChatList.Group]
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
        .markAsRead(
            presentationData.theme,
            title: "DahlSettings.Wall.Display.MarkAsRead".tp_loc(lang: lang),
            value: wallSettings.markAsRead
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
    
    let filteredPeers: [EnginePeer]
    if wallSettings.showArchivedChannels {
        filteredPeers = excludedPeers
    } else {
        filteredPeers = excludedPeers.filter { peer in
            if let group = excludedPeersGroups[peer.id], group == .archive {
                return false
            }
            return true
        }
    }
    
    var index: Int32 = 0
    for peer in filteredPeers {
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
    
    if !filteredPeers.isEmpty {
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
    
    return entries.sorted()
}

private final class ContextControllerContentSourceImpl: ContextControllerContentSource {
    let controller: ViewController
    weak var sourceNode: ASDisplayNode?
    
    let navigationController: NavigationController? = nil
    
    let passthroughTouches: Bool = true
    
    init(controller: ViewController, sourceNode: ASDisplayNode?) {
        self.controller = controller
        self.sourceNode = sourceNode
    }
    
    func transitionInfo() -> ContextControllerTakeControllerInfo? {
        let sourceNode = self.sourceNode
        return ContextControllerTakeControllerInfo(contentAreaInScreenSpace: CGRect(origin: CGPoint(), size: CGSize(width: 10.0, height: 10.0)), sourceNode: { [weak sourceNode] in
            if let sourceNode = sourceNode {
                return (sourceNode.view, sourceNode.bounds)
            } else {
                return nil
            }
        })
    }
    
    func animatedIn() {
    }
}

public func dWallSettingsController(
    context: AccountContext
) -> ViewController {
    let statePromise = ValuePromise(DWallSettingsState(revealedPeerId: nil), ignoreRepeated: true)
    let stateValue = Atomic(value: DWallSettingsState(revealedPeerId: nil))
    let updateState: ((DWallSettingsState) -> DWallSettingsState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var presentInGlobalOverlayImpl: ((ViewController) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let lang = presentationData.strings.baseLanguageCode

    let arguments = DWallSettingsArguments(
        context: context,
        updateShowArchivedChannels: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var updatedSettings = settings
                    var updatedWallSettings = settings.wallSettings
                    updatedWallSettings.showArchivedChannels = value
                    updatedSettings.wallSettings = updatedWallSettings
                    return updatedSettings
                }
            ).start()
        },
        updateMarkAsRead: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var updatedSettings = settings
                    var updatedWallSettings = settings.wallSettings
                    updatedWallSettings.markAsRead = value
                    updatedSettings.wallSettings = updatedWallSettings
                    return updatedSettings
                }
            ).start()
        },
        addExcludedChannel: {
            let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
                     |> take(1)
                     |> deliverOnMainQueue).start(next: { sharedData in
                let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
                let showArchivedChannels = dahlSettings.wallSettings.showArchivedChannels
                
                let allExcludedChannels = dahlSettings.wallSettings.excludedChannels
                
                let _ = (context.engine.data.get(
                    EngineDataMap(allExcludedChannels.map(TelegramEngine.EngineData.Item.Messages.ChatListGroup.init))
                )
                         |> deliverOnMainQueue).start(next: { groupsMap in
                    let groups = groupsMap.compactMapValues { $0 }
                    
                    let selectedChats: Set<EnginePeer.Id>
                    if showArchivedChannels {
                        selectedChats = Set(allExcludedChannels)
                    } else {
                        selectedChats = Set(allExcludedChannels.filter { peerId in
                            if let group = groups[peerId], group == .archive {
                                return false
                            }
                            return true
                        })
                    }
                    
                    let chatListFilter = ChatListFilter.filter(id: 1, title: ChatFolderTitle(text: "", entities: [], enableAnimations: true), emoticon: nil, data: ChatListFilterData(
                        isShared: false,
                        hasSharedLinks: false,
                        categories: [.channels],
                        excludeMuted: false,
                        excludeRead: false,
                        excludeArchived: !showArchivedChannels,
                        includePeers: ChatListFilterIncludePeers(),
                        excludePeers: [],
                        color: nil
                    ))
                    
                    let controller = context.sharedContext.makeContactMultiselectionController(ContactMultiselectionControllerParams(
                        context: context,
                        mode: .chatSelection(ContactMultiselectionControllerMode.ChatSelection(title: "DahlSettings.Wall.Excluded.Title".tp_loc(lang: lang), searchPlaceholder: "DahlSettings.Wall.Excluded.Search".tp_loc(lang: lang), selectedChats: selectedChats, additionalCategories: nil, chatListFilters: [chatListFilter], disableArchived: !showArchivedChannels, onlyChannels: true)),
                        filters: [],
                        alwaysEnabled: true
                    ))
                    
                    presentControllerImpl?(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                    
                    let _ = (controller.result
                             |> take(1)
                             |> deliverOnMainQueue).start(next: { [weak controller] result in
                        controller?.dismiss()
                        
                        if case let .result(peerIds, _) = result {
                            let updatedVisiblePeerIds = peerIds.compactMap { peerId -> EnginePeer.Id? in
                                if case let .peer(id) = peerId {
                                    return id
                                } else {
                                    return nil
                                }
                            }
                            
                            let _ = updateDalSettingsInteractively(
                                accountManager: context.sharedContext.accountManager,
                                { settings in
                                    var updatedSettings = settings
                                    var updatedWallSettings = settings.wallSettings
                                    
                                    if !showArchivedChannels {
                                        var finalExcludedChannels = updatedVisiblePeerIds
                                        
                                        for peerId in allExcludedChannels {
                                            if let group = groups[peerId], group == .archive {
                                                finalExcludedChannels.append(peerId)
                                            }
                                        }
                                        updatedWallSettings.excludedChannels = finalExcludedChannels
                                    } else {
                                        updatedWallSettings.excludedChannels = updatedVisiblePeerIds
                                    }
                                    
                                    updatedSettings.wallSettings = updatedWallSettings
                                    return updatedSettings
                                }
                            ).start()
                        }
                    })
                })
            })
        },
        removeExcludedChannel: { peerId in
            let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
            |> take(1)
            |> deliverOnMainQueue).start(next: { sharedData in
                let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
                var excludedChannels = dahlSettings.wallSettings.excludedChannels
                
                if let index = excludedChannels.firstIndex(of: peerId) {
                    excludedChannels.remove(at: index)
                    
                    let _ = updateDalSettingsInteractively(
                        accountManager: context.sharedContext.accountManager,
                        { settings in
                            var updatedSettings = settings
                            var updatedWallSettings = settings.wallSettings
                            updatedWallSettings.excludedChannels = excludedChannels
                            updatedSettings.wallSettings = updatedWallSettings
                            return updatedSettings
                        }
                    ).start()
                }
            })
        },
        removeAllExcludedChannels: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let lang = presentationData.strings.baseLanguageCode
            
            let actionSheet = ActionSheetController(presentationData: presentationData)
            
            actionSheet.setItemGroups([
                ActionSheetItemGroup(items: [
                    ActionSheetTextItem(title: "DahlSettings.Wall.Excluded.RemoveAllConfirmation".tp_loc(lang: lang)),
                    ActionSheetButtonItem(title: presentationData.strings.Common_Delete, color: .destructive, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        
                        let _ = updateDalSettingsInteractively(
                            accountManager: context.sharedContext.accountManager,
                            { settings in
                                var updatedSettings = settings
                                var updatedWallSettings = settings.wallSettings
                                updatedWallSettings.excludedChannels = []
                                updatedSettings.wallSettings = updatedWallSettings
                                return updatedSettings
                            }
                        ).start()
                    })
                ]),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    })
                ])
            ])
            
            presentControllerImpl?(actionSheet, nil)
        },
        setPeerIdWithRevealedOptions: { peerId, fromPeerId in
            updateState { state in
                var state = state
                if peerId == fromPeerId {
                    state.revealedPeerId = nil
                } else {
                    state.revealedPeerId = peerId
                }
                return state
            }
        },
        peerContextAction: { peer, sourceNode, gesture, _ in
            let chatController = context.sharedContext.makeChatController(context: context, chatLocation: .peer(id: peer.id), subject: nil, botStart: nil, mode: .standard(.previewing), params: nil)
            chatController.canReadHistory.set(false)
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            
            var items: [ContextMenuItem] = []
            items.append(.action(ContextMenuActionItem(text: "DahlSettings.Wall.Excluded.RemoveFromList".tp_loc(lang: presentationData.strings.baseLanguageCode), textColor: .destructive, icon: { theme in
                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Delete"), color: theme.contextMenu.destructiveColor)
            }, action: { _, f in
                f(.dismissWithoutContent)
                
                let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
                |> take(1)
                |> deliverOnMainQueue).start(next: { sharedData in
                    let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
                    var excludedChannels = dahlSettings.wallSettings.excludedChannels
                    
                    if let index = excludedChannels.firstIndex(of: peer.id) {
                        excludedChannels.remove(at: index)
                        
                        let _ = updateDalSettingsInteractively(
                            accountManager: context.sharedContext.accountManager,
                            { settings in
                                var updatedSettings = settings
                                var updatedWallSettings = settings.wallSettings
                                updatedWallSettings.excludedChannels = excludedChannels
                                updatedSettings.wallSettings = updatedWallSettings
                                return updatedSettings
                            }
                        ).start()
                    }
                })
            })))
            
            let contextController = ContextController(presentationData: presentationData, source: .controller(ContextControllerContentSourceImpl(controller: chatController, sourceNode: sourceNode)), items: .single(ContextController.Items(content: .list(items))), gesture: gesture)
            presentInGlobalOverlayImpl?(contextController)
        }
    )
    
    let sharedDataSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    
    let signal = combineLatest(
        sharedDataSignal,
        statePromise.get(),
        context.sharedContext.presentationData
    )
    |> mapToSignal { sharedData, state, presentationData -> Signal<(PresentationData, DWallSettingsState, DalSettings, [EnginePeer], [EnginePeer.Id: EngineChatList.Group]), NoError> in
        let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
        
        return context.engine.data.get(
            EngineDataList(dahlSettings.wallSettings.excludedChannels.map(TelegramEngine.EngineData.Item.Peer.Peer.init)),
            EngineDataMap(dahlSettings.wallSettings.excludedChannels.map(TelegramEngine.EngineData.Item.Messages.ChatListGroup.init))
        )
        |> map { peerList, groupsMap -> (PresentationData, DWallSettingsState, DalSettings, [EnginePeer], [EnginePeer.Id: EngineChatList.Group]) in
            let peers = peerList.compactMap { $0 }
            let groups = groupsMap.compactMapValues { $0 }
            return (presentationData, state, dahlSettings, peers, groups)
        }
    }
    |> map { presentationData, state, dahlSettings, excludedPeers, groups -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = dWallSettingsEntries(
            presentationData: presentationData,
            state: state,
            wallSettings: dahlSettings.wallSettings,
            excludedPeers: excludedPeers,
            excludedPeersGroups: groups
        )
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .navigationItemTitle(
                "DahlSettings.Wall.Title".tp_loc(
                    lang: presentationData.strings.baseLanguageCode
                )
            ),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    presentControllerImpl = { [weak controller] c, p in
        if let controller = controller {
            controller.present(c, in: .window(.root), with: p)
        }
    }
    
    presentInGlobalOverlayImpl = { [weak controller] c in
        if let controller = controller {
            controller.presentInGlobalOverlay(c)
        }
    }
    
    return controller
}
