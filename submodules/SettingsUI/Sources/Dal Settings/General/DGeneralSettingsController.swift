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
import MtProtoKit
import BuildConfig

import TPUI
import TPStrings

private struct DisplayProxyServerStatus: Equatable {
    let activity: Bool
    let text: String
    let textActive: Bool
}

private final class DGeneralSettingsArguments {
    let context: AccountContext
    let updateProxyEnableState: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let openPremiumSettings: () -> Void
    let openSettingsItemsConfiguration: () -> Void
    let openTabBarSettings: () -> Void
    let openWallSettings: () -> Void
    
    init(
        context: AccountContext,
        updateProxyEnableState: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        openPremiumSettings: @escaping () -> Void,
        openSettingsItemsConfiguration: @escaping () -> Void,
        openTabBarSettings: @escaping () -> Void,
        openWallSettings: @escaping () -> Void
    ) {
        self.context = context
        self.updateProxyEnableState = updateProxyEnableState
        self.updateHidePhone = updateHidePhone
        self.openPremiumSettings = openPremiumSettings
        self.openSettingsItemsConfiguration = openSettingsItemsConfiguration
        self.openTabBarSettings = openTabBarSettings
        self.openWallSettings = openWallSettings
    }
}

private enum DGeneralSettingsSection: Int32, CaseIterable {
    case connection
    case savedProxies
    case profile
    case wall
    case premium
    case menuItems
    case tabBar
}

private enum DGeneralSettingsEntryTag: ItemListItemTag {
    case proxy
    case hidePhoneNumber
    case wallSettings
    case premiumSettings
    
    func isEqual(to other: ItemListItemTag) -> Bool {
        if let other = other as? DGeneralSettingsEntryTag, self == other {
            return true
        } else {
            return false
        }
    }
}

private enum DGeneralSettingsEntry: ItemListNodeEntry {
    case connectionHeader(PresentationTheme, title: String)
    case proxy(PresentationTheme, title: String, value: Bool)
    case connectionFooter(PresentationTheme, title: String)
    
    case serversHeader(PresentationTheme, String)
    case server(PresentationTheme, PresentationStrings, String?, ProxyServerSettings, Bool, DisplayProxyServerStatus, Bool)
    
    case profileHeader(PresentationTheme, title: String)
    case hidePhoneNumber(PresentationTheme, title: String, value: Bool)
    case profileFooter(PresentationTheme, title: String)
    
    case wallSettings(PresentationTheme, title: String)
    
    case premiumSettings(PresentationTheme, title: String)
    case premiumSettingsFooter(PresentationTheme, title: String)
    
    case menuItemsHeader(title: String)
    case menuItems(title: String, detail: String)
    case tabBar(title: String, detail: String)
    
    var section: ItemListSectionId {
        switch self {
        case .connectionHeader, .proxy, .connectionFooter:
            return DGeneralSettingsSection.connection.rawValue
            
        case .serversHeader, .server:
            return DGeneralSettingsSection.savedProxies.rawValue
            
        case .profileHeader, .hidePhoneNumber, .profileFooter:
            return DGeneralSettingsSection.profile.rawValue
            
        case .wallSettings:
            return DGeneralSettingsSection.wall.rawValue
            
        case .premiumSettings, .premiumSettingsFooter:
            return DGeneralSettingsSection.premium.rawValue
            
        case .menuItemsHeader, .menuItems:
            return DGeneralSettingsSection.menuItems.rawValue
            
        case .tabBar:
            return DGeneralSettingsSection.tabBar.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .connectionHeader:
            return 0
        case .proxy:
            return 1
        case .connectionFooter:
            return 2
        case .serversHeader:
            return 3
        case .server:
            return 4
        case .menuItemsHeader:
            return 5
        case .menuItems:
            return 6
        case .tabBar:
            return 7
        case .profileHeader:
            return 8
        case .hidePhoneNumber:
            return 9
        case .profileFooter:
            return 10
        case .wallSettings:
            return 11
        case .premiumSettings:
            return 12
        case .premiumSettingsFooter:
            return 13
        }
    }
    
    var tag: ItemListItemTag? {
        switch self {
        case .proxy:
            return DGeneralSettingsEntryTag.proxy
        case .hidePhoneNumber:
            return DGeneralSettingsEntryTag.hidePhoneNumber
        case .wallSettings:
            return DGeneralSettingsEntryTag.wallSettings
        case .premiumSettings:
            return DGeneralSettingsEntryTag.premiumSettings
        case .server, .serversHeader, .connectionHeader, .connectionFooter, .profileHeader, .profileFooter, .premiumSettingsFooter, .menuItemsHeader, .menuItems, .tabBar:
            return nil
        }
    }
    
    static func ==(lhs: DGeneralSettingsEntry, rhs: DGeneralSettingsEntry) -> Bool {
        switch lhs {
        case let .connectionHeader(lhsTheme, lhsTitle):
            if case let .connectionHeader(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
        
        case let .proxy(lhsTheme, lhsTitle, lhsValue):
            if case let .proxy(rhsTheme, rhsTitle, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .connectionFooter(lhsTheme, lhsTitle):
            if case let .connectionFooter(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .serversHeader(lhsTheme, lhsTitle):
            if case let .serversHeader(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .server(lhsTheme, lhsStrings, lhsTitle, lhsSettings, lhsActive, lhsStatus, lhsEnabled):
            if case let .server(rhsTheme, rhsStrings, rhsTitle, rhsSettings, rhsActive, rhsStatus, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsStrings == rhsStrings, lhsSettings == rhsSettings, lhsTitle == rhsTitle, lhsActive == rhsActive, lhsStatus == rhsStatus, lhsEnabled == rhsEnabled {
                return true
            } else {
                return false
            }
            
        case let .profileHeader(lhsTheme, lhsTitle):
            if case let .profileHeader(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .hidePhoneNumber(lhsTheme, lhsTitle, lhsValue):
            if case let .hidePhoneNumber(rhsTheme, rhsTitle, rhsValue) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle,
               lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            
        case let .profileFooter(lhsTheme, lhsTitle):
            if case let .profileFooter(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .wallSettings(lhsTheme, lhsTitle):
            if case let .wallSettings(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .premiumSettings(lhsTheme, lhsTitle):
            if case let .premiumSettings(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .premiumSettingsFooter(lhsTheme, lhsTitle):
            if case let .premiumSettingsFooter(rhsTheme, rhsTitle) = rhs,
               lhsTheme === rhsTheme,
               lhsTitle == rhsTitle {
                return true
            } else {
                return false
            }
            
        case let .menuItemsHeader(lhsTitle):
            if case let .menuItemsHeader(rhsTitle) = rhs {
                return lhsTitle == rhsTitle
            }
            return false
            
        case let .menuItems(lhsTitle, lhsDetail):
            if case let .menuItems(rhsTitle, rhsDetail) = rhs {
                return lhsTitle == rhsTitle && lhsDetail == rhsDetail
            }
            return false
            
        case let .tabBar(lhsTitle, lhsDetail):
            if case let .tabBar(rhsTitle, rhsDetail) = rhs {
                return lhsTitle == rhsTitle && lhsDetail == rhsDetail
            }
            return false
        }
    }
    
    static func <(lhs: DGeneralSettingsEntry, rhs: DGeneralSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(
        presentationData: ItemListPresentationData,
        arguments: Any
    ) -> ListViewItem {
        let arguments = arguments as! DGeneralSettingsArguments
        
        switch self {
        case let .connectionHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .proxy(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateProxyEnableState(updatedValue)
                },
                tag: self.tag
            )
            
        case let .connectionFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )
            
        case let .serversHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .server(theme, strings, title, settings, active, status, enabled):
            return ProxySettingsServerItem(
                theme: theme,
                strings: strings,
                title: title,
                server: settings,
                activity: status.activity,
                active: active,
                color: enabled ? .accent : .secondary,
                label: status.text,
                labelAccent: status.textActive,
                editing: ProxySettingsServerItemEditing(editable: false, editing: false, revealed: false, infoAvailable: false),
                sectionId: self.section,
                action: {},
                infoAction: {},
                setServerWithRevealedOptions: { _, _ in },
                removeServer: { _ in }
            )
            
        case let .profileHeader(_, title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: section
            )
            
        case let .hidePhoneNumber(_, title, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { updatedValue in
                    arguments.updateHidePhone(updatedValue)
                },
                tag: self.tag
            )
            
        case let .profileFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )
            
        case let .wallSettings(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openWallSettings()
                }
            )
            
        case let .premiumSettings(_, title):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: "",
                sectionId: section,
                style: .blocks,
                action: {
                    arguments.openPremiumSettings()
                }
            )
            
        case let .premiumSettingsFooter(_, title):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(title),
                sectionId: self.section
            )
            
        case let .menuItemsHeader(title):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: title,
                sectionId: self.section
            )
            
        case let .menuItems(title, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openSettingsItemsConfiguration()
                }
            )
            
        case let .tabBar(title, detail):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: detail,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openTabBarSettings()
                }
            )
        }
    }
}

private func dGeneralSettingsEntries(
    presentationData: PresentationData,
    isProxyEnabled: Bool,
    proxySettings: ProxyServerSettings?,
    proxyStatus: ProxyServerStatus?,
    connectionStatus: ConnectionStatus?,
    hidePhoneEnabled: Bool,
    activeItemsCount: Int,
    activeTabsCount: Int
) -> [DGeneralSettingsEntry] {
    var entries = [DGeneralSettingsEntry]()
    let lang = presentationData.strings.baseLanguageCode
    
    entries.append(
        .connectionHeader(
            presentationData.theme,
            title: "DahlSettings.General.Network.Header".tp_loc(lang: lang).uppercased()
        )
    )
    
    entries.append(
        .proxy(
            presentationData.theme,
            title: "DahlSettings.General.Network.Proxy".tp_loc(lang: lang),
            value: isProxyEnabled
        )
    )
    
    entries.append(
        .connectionFooter(
            presentationData.theme,
            title: "DahlSettings.General.Network.Footer".tp_loc(lang: lang)
        )
    )
    
    if let proxyStatus, let proxySettings, let connectionStatus {
        entries.append(
            .serversHeader(
                presentationData.theme,
                presentationData.strings.SocksProxySetup_SavedProxies
            )
        )
        let strings = presentationData.strings
        let displayStatus: DisplayProxyServerStatus
        if isProxyEnabled {
            switch connectionStatus {
            case .waitingForNetwork:
                displayStatus = DisplayProxyServerStatus(activity: true, text: strings.State_WaitingForNetwork.lowercased(), textActive: false)
            case .connecting, .updating:
                displayStatus = DisplayProxyServerStatus(activity: true, text: strings.SocksProxySetup_ProxyStatusConnecting, textActive: false)
            case .online:
                var text = strings.SocksProxySetup_ProxyStatusConnected
                if case let .available(rtt) = proxyStatus {
                    let pingTime: Int = Int(rtt * 1000.0)
                    text = text + ", \(strings.SocksProxySetup_ProxyStatusPing("\(pingTime)").string)"
                }
                displayStatus = DisplayProxyServerStatus(activity: false, text: text, textActive: true)
            }
        } else {
            var text: String
            switch proxySettings.connection {
            case .socks5:
                text = strings.ChatSettings_ConnectionType_UseSocks5
            case .mtp:
                text = strings.SocksProxySetup_ProxyTelegram
            }
            switch proxyStatus {
            case .notAvailable:
                text = text + ", " + strings.SocksProxySetup_ProxyStatusUnavailable
                displayStatus = DisplayProxyServerStatus(activity: false, text: text, textActive: false)
            case .checking:
                text = text + ", " + strings.SocksProxySetup_ProxyStatusChecking
                displayStatus = DisplayProxyServerStatus(activity: false, text: text, textActive: false)
            case let .available(rtt):
                let pingTime: Int = Int(rtt * 1000.0)
                text = text + ", \(strings.SocksProxySetup_ProxyStatusPing("\(pingTime)").string)"
                displayStatus = DisplayProxyServerStatus(activity: false, text: text, textActive: false)
            }
        }
        let title = "DahlSettings.Proxy".tp_loc(lang: strings.baseLanguageCode)
        entries.append(.server(presentationData.theme, strings, title, proxySettings, true, displayStatus, isProxyEnabled))
    }
    
    entries.append(
        .menuItemsHeader(title: "DahlSettings.Appearance.MenuItems.Header".tp_loc(lang: lang).uppercased())
    )
    
    entries.append(
        .menuItems(
            title: "DahlSettings.Appearance.MenuItems".tp_loc(lang: lang),
            detail: "\(activeItemsCount)"
        )
    )
    
    entries.append(
        .tabBar(
            title: "DahlSettings.TabBarSettings.Title".tp_loc(lang: lang),
            detail: "\(activeTabsCount)"
        )
    )
    
    entries.append(
        .profileHeader(
            presentationData.theme,
            title: "DahlSettings.General.Profile.Header".tp_loc(lang: lang).uppercased()
        )
    )
    
    entries.append(
        .hidePhoneNumber(
            presentationData.theme,
            title: "DahlSettings.General.Profile.HidePhone".tp_loc(lang: lang),
            value: hidePhoneEnabled
        )
    )
    
    entries.append(
        .profileFooter(
            presentationData
                .theme,
            title: "DahlSettings.General.Profile.Footer".tp_loc(lang: lang)
        )
    )
    
    entries.append(
        .wallSettings(
            presentationData.theme,
            title: "DahlSettings.General.Wall".tp_loc(lang: lang)
        )
    )
    
    entries.append(
        .premiumSettings(
            presentationData.theme,
            title: "DahlSettings.General.Premium".tp_loc(lang: lang)
        )
    )
    
    entries.append(
        .premiumSettingsFooter(
            presentationData.theme,
            title: "DahlSettings.General.Premium.Footer".tp_loc(lang: lang)
        )
    )
    
    return entries
}

public func dGeneralSettingsController(
    context: AccountContext
) -> ViewController {
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let buildConfig = BuildConfig(baseAppBundleId: baseAppBundleId)
    
    var openPremiumSettings: (() -> Void)?
    var openWallSettings: (() -> Void)?
    
    var openSettingsItemsConfiguration: (() -> Void)?
    var openTabBarSettings: (() -> Void)?
    
    let proxyServer: ProxyServerSettings? = {
        guard let parsedSecret = MTProxySecret.parse(buildConfig.dProxySecret) else {
            return nil
        }
        return ProxyServerSettings(
            host: buildConfig.dProxyServer,
            port: buildConfig.dProxyPort,
            connection: .mtp(secret: parsedSecret.serialize())
        )
    }()
    
    let arguments = DGeneralSettingsArguments(
        context: context,
        updateProxyEnableState: { value in
            let _ = (updateProxySettingsInteractively(accountManager: context.sharedContext.accountManager) { proxySettings in
                var proxySettings = proxySettings
                if let proxyServer {
                    if !proxySettings.servers.contains(where: { $0.host == proxyServer.host }) {
                        proxySettings.servers.insert(proxyServer, at: 0)
                    }
                    proxySettings.activeServer = proxyServer
                    proxySettings.enabled = value
                }
                return proxySettings
            }).start()
        },
        updateHidePhone: { value in
            let _ = updateDalSettingsInteractively(
                accountManager: context.sharedContext.accountManager,
                { settings in
                    var settings = settings
                    settings.hidePhone = value
                    return settings
                }
            ).start()
        },
        openPremiumSettings: {
            openPremiumSettings?()
        },
        openSettingsItemsConfiguration: {
            openSettingsItemsConfiguration?()
        },
        openTabBarSettings: {
            openTabBarSettings?()
        },
        openWallSettings: {
            openWallSettings?()
        }
    )
    
    let statusesContext = ProxyServersStatuses(network: context.account.network, servers: .single(proxyServer != nil ? [proxyServer!] : []))
    let sharedData = context.sharedContext.accountManager.sharedData(keys: [
        ApplicationSpecificSharedDataKeys.dalSettings,
        SharedDataKeys.proxySettings
    ])
    
    let isProxyEnabled = Promise<Bool>()
    isProxyEnabled.set(
        context.sharedContext.accountManager.sharedData(keys: [SharedDataKeys.proxySettings])
        |> map { sharedData -> Bool in
            let proxySettings = sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self) ?? .defaultSettings
            return proxySettings.activeServer?.host == buildConfig.dProxyServer && proxySettings.enabled
        }
    )
    
    let signal = combineLatest(
        sharedData,
        context.sharedContext.presentationData,
        isProxyEnabled.get(),
        statusesContext.statuses(),
        context.account.network.connectionStatus
    ) |> map { sharedData, presentationData, isProxyEnabledValue, statuses, connectionStatus -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
        let proxySettings = sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self) ?? .defaultSettings
        let entries = dGeneralSettingsEntries(
            presentationData: presentationData,
            isProxyEnabled: isProxyEnabledValue,
            proxySettings: proxySettings.servers.contains(where: { $0.host == proxyServer?.host }) ? proxyServer : nil,
            proxyStatus: statuses.first?.value,
            connectionStatus: connectionStatus,
            hidePhoneEnabled: dahlSettings.hidePhone,
            activeItemsCount: dahlSettings.menuItemsSettings.activeItemsCount,
            activeTabsCount: dahlSettings.tabBarSettings.activeTabs.count
        )
        
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .navigationItemTitle(
                "DahlSettings.General.Title".tp_loc(
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
            style: .blocks
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    
    openPremiumSettings = { [weak controller] in
        let premiumSettings = dPremiumSettingsController(context: context)
        controller?.push(premiumSettings)
    }
    
    openTabBarSettings = { [weak controller] in
        let tabBarSettings = dTabBarSettingsController(context: context)
        controller?.push(tabBarSettings)
    }
    
    openSettingsItemsConfiguration = { [weak controller] in
        let menuItemSettings = dMenuItemsSettingsController(context: context)
        controller?.push(menuItemSettings)
    }
    
    openWallSettings = { [weak controller] in
        let wallSettings = dWallSettingsController(context: context)
        controller?.push(wallSettings)
    }
    
    return controller
}

private extension MenuItemsSettings {
    
    var activeItemsCount: Int {
        var count = 0
        if myProfile { count += 1 }
        if wallet { count += 1 }
        if savedMessages { count += 1 }
        if recentCalls { count += 1 }
        if devices { count += 1 }
        if chatFolders { count += 1 }
        if myStars { count += 1 }
        if business { count += 1 }
        if sendGift { count += 1 }
        if support { count += 1 }
        if faq { count += 1 }
        if tips { count += 1 }
        return count
    }
}
