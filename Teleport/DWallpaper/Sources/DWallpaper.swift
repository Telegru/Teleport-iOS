import TelegramCore
import Foundation
import AppBundle
import Postbox
import SwiftSignalKit

private class DWallpaperClass { }

public func telegramWallpapersWithDWallpapers(postbox: Postbox, network: Network, forceUpdate: Bool = false) -> Signal<[TelegramWallpaper], NoError> {
    return telegramWallpapers(postbox: postbox, network: network, forceUpdate: forceUpdate)
    |> map { remoteWallpapers in
        let dWallpapers = DWallpaper.allCases.compactMap { $0.makeWallpaper() }
        return dWallpapers + remoteWallpapers
    }
}

public enum DWallpaper: CaseIterable {
    case kazan, russia, saintPetersburg, moscow

    // MARK: - Resource Bundle
    

    private static var resourceBundle: Bundle? {
        let frameworkBundle = Bundle(for: DWallpaperClass.self)
        guard let bundleURL = frameworkBundle.url(forResource: "DWallpaperResourcesBundle", withExtension: "bundle") else {
            return nil
        }
        return Bundle(url: bundleURL)
    }
    
    // MARK: - Вспомогательный метод для получения размера файла

    private func fileSizeForResource(atPath path: String) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - Основной метод создания обоев

    public func makeWallpaper(darkMode: Bool = false) -> TelegramWallpaper? {
        let (resourceName, resourceType) = resourceData
        let (previewName, previewType) = previewData

        guard
            let bundle = DWallpaper.resourceBundle,
            let path = bundle.path(forResource: resourceName, ofType: resourceType),
            let previewPath = bundle.path(forResource: previewName, ofType: previewType),
            let fileSize = fileSizeForResource(atPath: path),
            let previewFileSize = fileSizeForResource(atPath: previewPath)
        else {
            return nil
        }
        
        let (fileId, previewFileId, accessHash, slug) = fileData
        
        return TelegramWallpaper.file(
            TelegramWallpaper.File(
                id: fileId,
                accessHash: accessHash,
                isCreator: false,
                isDefault: true,
                isPattern: true,
                isDark: darkMode,
                slug: slug,
                file: TelegramMediaFile(
                    fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: fileId),
                    partialReference: nil,
                    resource: LocalFileMediaResource(fileId: fileId, size: fileSize),
                    previewRepresentations: [
                        TelegramMediaImageRepresentation(
                            dimensions: PixelDimensions(width: 155, height: 320),
                            resource: LocalFileMediaResource(fileId: previewFileId, size: previewFileSize),
                            progressiveSizes: [],
                            immediateThumbnailData: nil,
                            hasVideo: false,
                            isPersonal: false
                        )
                    ],
                    videoThumbnails: [],
                    immediateThumbnailData: nil,
                    mimeType: "image/svg",
                    size: fileSize,
                    attributes: [
                        .ImageSize(size: PixelDimensions(width: 720, height: 1480)),
                        .FileName(fileName: "\(resourceName).\(resourceType)")
                    ],
                    alternativeRepresentations: []
                ),
                settings: WallpaperSettings(colors: darkMode ? darkColors : colors, intensity: darkMode ? -40 : 50)
            )
        )
    }
    
    // MARK: - Получение данных файла в виде Data

    public func fileDataForDWallpaper() -> Data? {
        let (resourceName, resourceType) = resourceData
        guard
            let bundle = DWallpaper.resourceBundle,
            let path = bundle.path(forResource: resourceName, ofType: resourceType)
        else {
            return nil
        }
        
        let fileURL = URL(fileURLWithPath: path)
        return try? Data(contentsOf: fileURL)
    }
    
    public func fileDataForPreview() -> Data? {
        let (resourceName, resourceType) = previewData
        guard
            let bundle = DWallpaper.resourceBundle,
            let path = bundle.path(forResource: resourceName, ofType: resourceType)
        else {
            return nil
        }
        
        let fileURL = URL(fileURLWithPath: path)
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Локальные ресурсы

    public func makeLocalFileMediaResource() -> LocalFileMediaResource? {
        let (resourceName, resourceType) = resourceData
        guard
            let bundle = DWallpaper.resourceBundle,
            let path = bundle.path(forResource: resourceName, ofType: resourceType),
            let fileSize = fileSizeForResource(atPath: path)
        else {
            return nil
        }
        
        let (fileId, _, _, _) = fileData
        return LocalFileMediaResource(fileId: fileId, size: fileSize)
    }
    
    public func makePreviewLocalFileMediaResource() -> LocalFileMediaResource? {
        let (resourceName, resourceType) = previewData
        guard
            let bundle = DWallpaper.resourceBundle,
            let path = bundle.path(forResource: resourceName, ofType: resourceType),
            let fileSize = fileSizeForResource(atPath: path)
        else {
            return nil
        }
        
        let (_, preivewFileId, _, _) = fileData
        return LocalFileMediaResource(fileId: preivewFileId, size: fileSize)
    }
    
    // MARK: - Данные о ресурсах
    
    public var slug: String {
        let (_, _, _, slug) = fileData
        return slug
    }

    private var resourceData: (String, String) {
        switch self {
        case .kazan:            return ("WallpaperKazan", "svg")
        case .russia:           return ("WallpaperRussia", "svg")
        case .saintPetersburg:  return ("WallpaperSP", "svg")
        case .moscow:           return ("WallpaperMoscow", "svg")
        }
    }
    
    private var previewData: (String, String) {
        switch self {
        case .kazan:            return ("WallpaperPreviewKazan", "png")
        case .russia:           return ("WallpaperPreviewRussia", "png")
        case .saintPetersburg:  return ("WallpaperPreviewSP", "png")
        case .moscow:           return ("WallpaperPreviewMoscow", "png")
        }
    }
    
    private var fileData: (Int64, Int64, Int64, String) {
        switch self {
        case .kazan:            return (231222124451, 231222124452, 1234, "slugKazan")
        case .russia:           return (241222124562, 241222124563, 5678, "slugRussia")
        case .saintPetersburg:  return (251222124673, 251222124674, 9876, "slugSaintPetersburg")
        case .moscow:           return (223442223441, 223442223442, 3451, "slugMoscow")
        }
    }
    
    private var colors: [UInt32] {
        switch self {
        case .kazan:            return [8372873, 14996851, 11523703, 15777914]
        case .russia:           return [15377262, 15787142, 15900351, 15253614]
        case .saintPetersburg:  return [14346955, 15518719, 15518719, 12182271]
        case .moscow:           return [8372873, 15518719, 15900351, 15777914]
        }
    }
    
    private var darkColors: [UInt32] {
        switch self {
        case .kazan:            return [8364929, 16774597, 3370837, 16507773]
        case .russia:           return [9100274, 8949228, 14917610, 6790381]
        case .saintPetersburg:  return [16696470, 9842623, 5200853, 16696470]
        case .moscow:           return [8364929, 8949228, 14917610, 16696470]
        }
    }
}
