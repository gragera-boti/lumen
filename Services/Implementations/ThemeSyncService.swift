import Foundation
import SwiftData

@MainActor
struct ThemeSyncService {
    /// Synchronizes the imageData from AppThemes natively tracked by CloudKit down to the
    /// extremely-performant local file system directories, enabling existing ViewModels and grids
    /// to instantly extract images efficiently on multi-core loads.
    static func syncToDisk(themes: [AppTheme]) {
        // Execute synchronously. Since `Data` properties flagged with @Attribute(.externalStorage)
        // are loaded lazily by SwiftData, iterating and only tapping `imageData` when the specific
        // file URL literally errors out entirely eliminates vast memory/IO constraints.
        let fm = FileManager.default
        let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")
        
        guard let photosDir = groupURL?.appendingPathComponent("themes").appendingPathComponent("photos"),
              let aiDir = groupURL?.appendingPathComponent("themes").appendingPathComponent("generated") else { return }
        
        try? fm.createDirectory(at: photosDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: aiDir, withIntermediateDirectories: true)
        
        for theme in themes {
            let isCustom = (theme.type == .customPhoto)
            let isGen = (theme.type == .generatedImage)
            guard isCustom || isGen else { continue }
            
            let dir = isCustom ? photosDir : aiDir
            let ext = isGen ? "png" : "jpg"
            let imagePath = dir.appendingPathComponent("\(theme.id).\(ext)")
            let thumbPath = dir.appendingPathComponent("\(theme.id)_thumb.jpg") // AI thumbs are JPG too 
            
            if !fm.fileExists(atPath: imagePath.path) {
                if let data = theme.imageData {
                    try? data.write(to: imagePath)
                }
            }
            if !fm.fileExists(atPath: thumbPath.path) {
                if let data = theme.thumbnailData {
                    try? data.write(to: thumbPath)
                }
            }
        }
    }
}
