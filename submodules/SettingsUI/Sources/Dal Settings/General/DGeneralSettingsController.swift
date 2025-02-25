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

private final class DGeneralSettingsArguments {
    let context: AccountContext
    let updateProxyEnableState: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let openPremiumSettings: () -> Void
    
    init(
        context: AccountContext,
        updateProxyEnableState: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        openPremiumSettings: @escaping () -> Void
    ) {
        self.context = context
        self.updateProxyEnableState = updateProxyEnableState
        self.updateHidePhone = updateHidePhone
        self.openPremiumSettings = openPremiumSettings
    }
}

private enum DGeneralSettingsSection: Int32, CaseIterable {
    case connection
    case profile
    case premium
}

private enum DGeneralSettingsEntryTag: ItemListItemTag {
    case proxy
    case hidePhoneNumber
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
    
    case profileHeader(PresentationTheme, title: String)
    case hidePhoneNumber(PresentationTheme, title: String, value: Bool)
    case profileFooter(PresentationTheme, title: String)
    
    case premiumSettings(PresentationTheme, title: String)
    case premiumSettingsFooter(PresentationTheme, title: String)
    
    var section: ItemListSectionId {
        switch self {
        case .connectionHeader, .proxy, .connectionFooter:
            return DGeneralSettingsSection.connection.rawValue
            
        case .profileHeader, .hidePhoneNumber, .profileFooter:
            return DGeneralSettingsSection.profile.rawValue
            
        case .premiumSettings, .premiumSettingsFooter:
            return DGeneralSettingsSection.premium.rawValue
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
        case .profileHeader:
            return 3
        case .hidePhoneNumber:
            return 4
        case .profileFooter:
            return 5
        case .premiumSettings:
            return 6
        case .premiumSettingsFooter:
            return 7
        }
    }
    
    var tag: ItemListItemTag? {
        switch self {
        case .proxy:
            return DGeneralSettingsEntryTag.proxy
        case .hidePhoneNumber:
            return DGeneralSettingsEntryTag.hidePhoneNumber
        case .premiumSettings:
            return DGeneralSettingsEntryTag.premiumSettings
            
        case .connectionHeader, .connectionFooter, .profileHeader, .profileFooter, .premiumSettingsFooter:
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
        }
    }
}

private func dGeneralSettingsEntries(
    presentationData: PresentationData,
    isProxyEnabled: Bool,
    hidePhoneEnabled: Bool
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

func dGeneralSettingsController(
    context: AccountContext
) -> ViewController {
    let baseAppBundleId = Bundle.main.bundleIdentifier!
    let buildConfig = BuildConfig(baseAppBundleId: baseAppBundleId)
    
    var openPremiumSettings: (() -> Void)?
    
    let arguments = DGeneralSettingsArguments(
        context: context,
        updateProxyEnableState: { value in
            let _ = (updateProxySettingsInteractively(accountManager: context.sharedContext.accountManager) { proxySettings in
                var proxySettings = proxySettings
                if value == true {
                    proxySettings.enabled = false
                }
                return proxySettings
            } |> mapToSignal { _ in
                updateDahlProxyInteractively(
                    accountManager: context.sharedContext.accountManager) { settings in
                        var settings = settings
                        let parsedSecret = MTProxySecret.parse(buildConfig.dProxySecret)
                        settings.server = value ? ProxyServerSettings(
                            host: buildConfig.dProxyServer,
                            port: buildConfig.dProxyPort,
                            connection: .mtp(secret: parsedSecret!.serialize())
                        ) : nil
                        return settings
                    }
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
        }
    )
    
    let sharedData = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.dalSettings])
    
    let isProxyEnabled = Promise<Bool>()
    isProxyEnabled.set(
        context.sharedContext.accountManager.sharedData(keys: [SharedDataKeys.dahlProxySettings, SharedDataKeys.proxySettings])
    |> map { sharedData -> Bool in
        if sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self)?.effectiveActiveServer != nil {
            return false
        }
        
        return sharedData.entries[SharedDataKeys.dahlProxySettings]?.get(DahlProxySettings.self)?.server != nil
    })
    
    let signal = combineLatest(
        sharedData,
        context.sharedContext.presentationData,
        isProxyEnabled.get()
    ) |> map { sharedData, presentationData, isProxyEnabledValue -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let dahlSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.dalSettings]?.get(DalSettings.self) ?? .defaultSettings
        
        let entries = dGeneralSettingsEntries(
            presentationData: presentationData,
            isProxyEnabled: isProxyEnabledValue,
            hidePhoneEnabled: dahlSettings.hidePhone
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
    
    return controller
}
