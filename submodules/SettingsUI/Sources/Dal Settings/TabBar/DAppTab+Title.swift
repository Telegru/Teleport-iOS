//
//  DAppTab+Title.swift
//  SettingsUI
//
//  Created by Lenar Gilyazov on 16.01.2025.
//

import Foundation
import TPStrings
import TelegramUIPreferences
import TelegramPresentationData

public extension DAppTab {
    
    func title(forStrings strings: PresentationStrings) -> String {
        switch self {
        case .contacts:
            return strings.Contacts_TabTitle
        case .chats:
            return strings.DialogList_TabTitle
        case .calls:
            return strings.Calls_TabTitle
        case .settings:
            return strings.Settings_Title
        case .dahlSettings:
            return "DahlSettings.TabTitle".tp_loc(lang: strings.baseLanguageCode)
        case .wallet:
            return "Wallet.TabTitle".tp_loc(lang: strings.baseLanguageCode)
//        case .channels:
//            return strings.ChatListFolder_NameChannels
        }
    }
}
