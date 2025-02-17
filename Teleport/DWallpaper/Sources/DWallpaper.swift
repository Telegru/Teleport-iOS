import TelegramCore
import Foundation
import AppBundle
import Postbox

public enum DWallpaper: CaseIterable {
    case kazan
    case russia
    case saintPetersburg
    case moscow

    public func makeWallpaper(darkMode: Bool = false) -> TelegramWallpaper? {
        let (resourceName, resourceType) = resourceData
        let (previewName, previewType) = previewData

        guard let path = Bundle.main.path(forResource: resourceName, ofType: resourceType) else {
            return nil
        }
        
        guard let previewPath = Bundle.main.path(forResource: previewName, ofType: previewType) else {
            return nil
        }
        
        let fileSize: Int64
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            fileSize = (attributes[.size] as? Int64) ?? 0
        } catch {
            return nil
        }
        
        let (fileId, accessHash, randomId, slug) = fileData
        
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
                            resource: LocalFileReferenceMediaResource(
                                localFilePath: previewPath,
                                randomId: randomId,
                                isUniquelyReferencedTemporaryFile: true,
                                size: fileSize
                            ),
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
                        .ImageSize(size: PixelDimensions(width: 837, height: 1850)),
                        .FileName(fileName: "\(resourceName).\(resourceType)")
                    ],
                    alternativeRepresentations: []
                ),
                settings: WallpaperSettings(colors: darkMode ? darkColors : colors, intensity: darkMode ? -40 : 50)
            )
        )
    }
    
    public func fileDataForDWallpaper() -> Data? {
        let (resourceName, resourceType) = self.resourceData
        
        guard let path = Bundle.main.path(forResource: resourceName, ofType: resourceType) else {
            return nil
        }
        
        do {
            let fileURL = URL(fileURLWithPath: path)
            return try Data(contentsOf: fileURL)
        } catch {
            return nil
        }
    }
    
    public func makeLocalFileMediaResource() -> LocalFileMediaResource? {
        let (resourceName, resourceType) = resourceData
        guard let path = Bundle.main.path(forResource: resourceName, ofType: resourceType) else {
            return nil
        }
        
        var fileSize: Int64 = 0
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            fileSize = (attributes[.size] as? Int64) ?? 0
        } catch {
            return nil
        }
        
        let (fileId, _, _, _) = fileData
        
        return LocalFileMediaResource(fileId: fileId, size: fileSize)
    }
    
    // MARK: - Данные о ресурсах
    
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
        case .kazan:           return ("WallpaperKazan", "png")
        case .russia:          return ("WallpaperRussia", "png")
        case .saintPetersburg: return ("WallpaperSP", "png")
        case .moscow:          return ("WallpaperMoscow", "png")
        }
    }
    
    private var fileData: (Int64, Int64, Int64, String) {
        switch self {
        case .kazan:
            return (231222124451, 123444, 1234, "slugKazan")
        case .russia:
            return (241222124562, 223555, 5678, "slugRussia")
        case .saintPetersburg:
            return (251222124673, 323666, 9876, "slugSaintPetersburg")
        case .moscow:
            return (223442223441, 533112, 3451, "slugMoscow")
        }
    }
    
    private var colors: [UInt32] {
        switch self {
        case .kazan:
            return [8372873, 14996851, 11523703, 15777914]
        case .russia:
            return [15377262, 15787142, 15900351, 15253614]
        case .saintPetersburg:
            return [14346955, 15518719, 15518719, 12182271]
        case .moscow:
            return [8372873, 15518719, 15900351, 15777914]
        }
    }
    
    private var darkColors: [UInt32] {
        switch self {
        case .kazan:
            return [8364929, 16774597, 3370837, 16507773]
        case .russia:
            return [9100274, 8949228, 14917610, 6790381]
        case .saintPetersburg:
            return [16696470, 9842623, 5200853, 16696470]
        case .moscow:
            return [8364929, 8949228, 14917610, 16696470]
        }
    }
}
