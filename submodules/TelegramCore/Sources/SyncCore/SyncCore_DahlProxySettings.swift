import Foundation
import Postbox
import SwiftSignalKit

public struct DahlProxySettings: Codable, Equatable {
    
    public var server: ProxyServerSettings?
    
    public static var defaultSettings: DahlProxySettings {
        return DahlProxySettings(server: nil)
    }
    
    public init(server: ProxyServerSettings?) {
        self.server = server
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.server = try container.decodeIfPresent(ProxyServerSettings.self, forKey: "server")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encodeIfPresent(self.server, forKey: "server")
    }
}

public func updateDahlProxyInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (DahlProxySettings) -> DahlProxySettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(SharedDataKeys.dahlProxySettings, { current in
            let previous = current?.get(DahlProxySettings.self) ?? DahlProxySettings.defaultSettings
            return PreferencesEntry(f(previous))
        })
    }
    |> mapToSignal { _ in
        return .complete()
    }
}
