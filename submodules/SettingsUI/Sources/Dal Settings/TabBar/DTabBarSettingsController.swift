import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramUIPreferences
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class DTabBarSettingsControllerArguments {
    let context: AccountContext
    
    let addTab: (DAppTab) -> Void
    let removeTab: (DAppTab) -> Void
    let updateShowTitle: (Bool) -> Void
    
    init(
        context: AccountContext,
        addTab: @escaping (DAppTab) -> Void,
        removeTab: @escaping (DAppTab) -> Void,
        updateShowTitle: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.addTab = addTab
        self.removeTab = removeTab
        self.updateShowTitle = updateShowTitle
    }
}

private enum DTabBarSettingsSection: Int32 {
    case activeTabs
    case availableTabs
    case tabTitleVisibility
}

private enum DTabBarSettingsEntryId: Hashable {
    case index(Int32)
    case tab(DAppTab)
}

private enum DTabBarSettingsEntry: ItemListNodeEntry {
    case activeTabHeader(String, activeCount: Int, maxCount: Int)
    case activeTabFooter(String)
    case activeTab(index: Int32, tab: DAppTab)
    case availableTabHeader(String)
    case availableTab(DAppTab)
    
    case tabTitleVisibility(title: String, value: Bool)
    case tabTitleVisibilityFooter(text: String)
    
    var section: ItemListSectionId {
        switch self {
        case .activeTab, .activeTabHeader, .activeTabFooter:
            return DTabBarSettingsSection.activeTabs.rawValue
        case .availableTab, .availableTabHeader:
            return DTabBarSettingsSection.availableTabs.rawValue
        case .tabTitleVisibility, .tabTitleVisibilityFooter:
            return DTabBarSettingsSection.tabTitleVisibility.rawValue
        }
    }
    
    var stableId: DTabBarSettingsEntryId {
        switch self {
        case .activeTabHeader:
            return .index(0)
        case let .activeTab(_, tab):
            return .tab(tab)
        case .activeTabFooter:
            return .index(1)
        case .availableTabHeader:
            return .index(2)
        case let .availableTab(tab):
            return .index(Int32(tab.rawValue + 10000))
            
        case .tabTitleVisibility:
            return .index(3)
        case .tabTitleVisibilityFooter:
            return .index(4)
        }
    }
    
    static func ==(lhs: DTabBarSettingsEntry, rhs: DTabBarSettingsEntry) -> Bool {
        switch lhs {
        case let .activeTabHeader(lhsText, lhsActiveCount, lhsMaxCount):
            if case let .activeTabHeader(rhsText, rhsActiveCount, rhsMaxCount) = rhs {
                return lhsText == rhsText && lhsActiveCount == rhsActiveCount && lhsMaxCount == rhsMaxCount
            }
            return false
        case let .activeTab(lhsIndex, lhsTab):
            if case .activeTab(let rhsIndex, let rhsTab) = rhs,
               lhsIndex == rhsIndex, lhsTab == rhsTab {
                return true
            }
            return false
        case let .activeTabFooter(lhsText):
            if case let .activeTabFooter(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        case let .availableTabHeader(lhsText):
            if case let .availableTabHeader(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        case let .availableTab(lhsTab):
            if case .availableTab(let rhsTab) = rhs,
               lhsTab == rhsTab {
                return true
            }
            return false
            
        case let .tabTitleVisibility(lhsTitle, lhsValue):
            if case let .tabTitleVisibility(rhsTitle, rhsValue) = rhs,
               lhsTitle == rhsTitle, lhsValue == rhsValue {
                return true
            }
            return false
            
        case let .tabTitleVisibilityFooter(lhsText):
            if case let .tabTitleVisibilityFooter(rhsText) = rhs,
               lhsText == rhsText {
                return true
            }
            return false
        }
    }
    
    static func <(lhs: DTabBarSettingsEntry, rhs: DTabBarSettingsEntry) -> Bool {
        switch lhs {
        case .activeTabHeader:
            return true
            
        case let .activeTab(lhsIndex, _):
            switch rhs {
            case .activeTabHeader:
                return false
            case let .activeTab(rhsIndex, _):
                return lhsIndex < rhsIndex
            default:
                return true
            }
        case .activeTabFooter:
            switch rhs {
            case .activeTabHeader, .activeTab, .activeTabFooter:
                return false
            default:
                return true
            }
            
        case .availableTabHeader:
            switch rhs {
            case .activeTab, .activeTabFooter, .activeTabHeader, .availableTabHeader:
                return false
            default:
                return true
            }
        case .availableTab:
            switch rhs {
            case .activeTab, .activeTabFooter, .activeTabHeader, .availableTabHeader:
                return false
            default:
                return true
            }
            
        case .tabTitleVisibility:
            switch rhs {
            case .activeTab, .activeTabFooter, .activeTabHeader, .availableTabHeader, .availableTab:
                return false
            default:
                return true
            }
        case .tabTitleVisibilityFooter:
            switch rhs {
            case .activeTab, .activeTabFooter, .activeTabHeader, .availableTabHeader, .availableTab, .tabTitleVisibility:
                return false
            case .tabTitleVisibilityFooter:
                return true
            }
        }
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! DTabBarSettingsControllerArguments
        switch self {
        case let .activeTabHeader(text, activeCount, maxCount):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                accessoryText: .init(
                    value: "DahlSettings.TabBarSettings.ActiveTabs.Header.Counter".tp_loc(lang: presentationData.strings.baseLanguageCode, with: activeCount, maxCount),
                    color: .generic
                ),
                sectionId: self.section
            )
        case let .activeTab(_, tab):
            return DTabBarSettingsTabListItem(
                context: arguments.context,
                presentationData: presentationData,
                tab: tab,
                title: tab.title(forStrings: presentationData.strings),
                editing: DTabBarSettingsTabListItemEditing(
                    editable: true,
                    editing: true,
                    revealed: false
                ),
                canBeReordered: true,
                canBeDeleted: !tab.isAlwaysShow,
                isDisabled: false,
                sectionId: self.section) { lhs, rhs in
                    
                } remove: {
                    arguments.removeTab(tab)
                }
        case let .activeTabFooter(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )

        case let .availableTabHeader(text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case let .availableTab(tab):
            return DTabBarSettingsListAvailableItem(
                presentationData: presentationData,
                title: tab.title(forStrings: presentationData.strings),
                sectionId: self.section,
                style: .blocks) {
                    arguments.addTab(tab)
                }
            
        case let .tabTitleVisibility(title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateShowTitle(value)
                }
            )
            
        case let .tabTitleVisibilityFooter(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        }
    }
}

private let maxAllowedNumberOfTabs: Int = 5

private func dTabBarSettingsControllerEntries(
    context: AccountContext,
    presentationData: PresentationData,
    activeTabs: [DAppTab],
    showTabTitle: Bool
) -> [DTabBarSettingsEntry] {
    var entries: [DTabBarSettingsEntry] = []
    let languageCode = presentationData.strings.baseLanguageCode
    
    entries.append(
        .activeTabHeader(
            "DahlSettings.TabBarSettings.ActiveTabs.Header".tp_loc(lang: languageCode).uppercased(),
            activeCount: activeTabs.count,
            maxCount: maxAllowedNumberOfTabs
        )
    )
    
    activeTabs.enumerated().forEach {
        entries.append(.activeTab(index: Int32($0.offset), tab: $0.element))
    }
    
    entries.append(
        .activeTabFooter("DahlSettings.TabBarSettings.ActiveTabs.Footer".tp_loc(lang: languageCode))
    )
    
    if activeTabs.count < maxAllowedNumberOfTabs {
        entries.append(
            .availableTabHeader("DahlSettings.TabBarSettings.AvailableTabs.Header".tp_loc(lang: languageCode).uppercased())
        )
        
        DAppTab.allCases
            .filter { !activeTabs.contains($0) }
            .forEach {
                entries.append(.availableTab($0))
            }
    }
    
    entries.append(
        .tabTitleVisibility(
            title: "DahlSettings.TabBarSettings.TabTitleVisibility".tp_loc(lang: languageCode),
            value: showTabTitle
        )
    )
    
    entries.append(
        .tabTitleVisibilityFooter(text: "DahlSettings.TabBarSettings.TabTitleVisibility.Footer".tp_loc(lang: languageCode))
    )
    
    return entries
}

public func dTabBarSettingsController(
    context: AccountContext
) -> ViewController {
    let activeTabsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    |> map {
        ($0.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings).tabBarSettings.activeTabs
    }
    |> take(1)
    |> mapToSignal { tabs -> Signal<[DAppTab], NoError> in
        return .single(tabs)
    }
    
    let dahlSettingsSignal = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    |> map {
        ($0.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings)
    }
    
    let activeTabs = Promise<[DAppTab]>()
    activeTabs.set(activeTabsSignal)
    
    let arguments = DTabBarSettingsControllerArguments(
        context: context,
        addTab: { tab in
            let _ = (activeTabs.get() |> take(1) |> filter { !$0.contains(tab) } |> deliverOnMainQueue )
                .start(next: { tabs in
                    let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) {
                        var settings = $0
                        var _tabs = tabs
                        _tabs.append(tab)
                        settings.tabBarSettings.activeTabs = _tabs
                        activeTabs.set(.single(_tabs))
                        return settings
                    }.start()
                })
        },
        removeTab: { tab in
            let _ = (activeTabs.get() |> take(1) |> deliverOnMainQueue)
                .start(next: { tabs in
                    let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) {
                        var settings = $0
                        var _tabs = tabs
                        _tabs.removeAll(where: { $0.rawValue == tab.rawValue })
                        settings.tabBarSettings.activeTabs = _tabs
                        activeTabs.set(.single(_tabs))
                        return settings
                    }.start()
                })
        },
        updateShowTitle: { value in
            let _ = updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) {
                var settings = $0
                settings.tabBarSettings.showTabTitles = value
                return settings
            }.start()
        }
    )
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        activeTabs.get(),
        dahlSettingsSignal
    )
    |> map { presentationData, activeTabsValue, dahlSettings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let title = "DahlSettings.TabBarSettings.Title".tp_loc(lang: presentationData.strings.baseLanguageCode)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let entries = dTabBarSettingsControllerEntries(
            context: context,
            presentationData: presentationData,
            activeTabs: activeTabsValue,
            showTabTitle: dahlSettings.tabBarSettings.showTabTitles
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
    
    controller.setReorderEntry { (fromIndex: Int, toIndex: Int, entries: [DTabBarSettingsEntry]) -> Signal<Bool, NoError> in
        let fromEntry = entries[fromIndex]
        guard case let .activeTab(_, fromTab) = fromEntry else {
            return .single(false)
        }
        var referenceTab: DAppTab?
        var beforeAll = false
        var afterAll = false
        if toIndex < entries.count {
            switch entries[toIndex] {
            case let .activeTab(_, tab):
                referenceTab = tab
            default:
                if entries[toIndex] < fromEntry {
                    beforeAll = true
                } else {
                    afterAll = true
                }
            }
        } else {
            afterAll = true
        }
        
        return activeTabs.get() |> take(1) |> mapToSignal { activeTabsValue -> Signal<Bool, NoError> in
            var tabs = activeTabsValue
            let initialOrder = tabs.map { $0.rawValue }
            
            if let index = tabs.firstIndex(where: { $0 == fromTab }) {
                tabs.remove(at: index)
            }
            
            if let referenceTab {
                var inserted = false
                for i in 0..<tabs.count {
                    if tabs[i] == referenceTab {
                        if fromIndex < toIndex {
                            tabs.insert(fromTab, at: i + 1)
                        } else {
                            tabs.insert(fromTab, at: i)
                        }
                        inserted = true
                        break
                    }
                }
                if !inserted {
                    tabs.append(fromTab)
                }
            } else if beforeAll {
                tabs.insert(fromTab, at: 0)
            } else if afterAll {
                tabs.append(fromTab)
            }
            
            let updatedOrder = tabs.map(\.rawValue)
            if initialOrder != updatedOrder {
                activeTabs.set(.single(tabs))
                return .single(true)
            } else {
                return .single(false)
            }
        }
    }
    
    controller.willDisappear = { _ in
        let _ = (combineLatest(
            activeTabs.get() |> take(1),
            context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
            |> take(1)
            |> map {
                ($0.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings).tabBarSettings.activeTabs
            }
        )
        |> filter { $0 != $1 }
        |> mapToSignal { activeTabsValue, _ -> Signal<Void, NoError> in
            return updateDalSettingsInteractively(accountManager: context.sharedContext.accountManager) {
                var settings = $0
                settings.tabBarSettings.activeTabs = activeTabsValue
                return settings
            }
        })
        .start()
    }
    
    return controller
}
