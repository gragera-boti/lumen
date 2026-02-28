// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist



#if os(macOS)
#if hasFeature(InternalImportsByDefault)
public import AppKit
#else
import AppKit
#endif
#else
#if hasFeature(InternalImportsByDefault)
public import UIKit
#else
import UIKit
#endif
#endif

#if canImport(SwiftUI)
#if hasFeature(InternalImportsByDefault)
public import SwiftUI
#else
import SwiftUI
#endif
#endif

// MARK: - Asset Catalogs

public enum LumenAsset: Sendable {
  public static let accentColor = LumenColors(name: "AccentColor")
  public static let aiBgAuroraBorealis = LumenImages(name: "ai_bg_aurora_borealis")
  public static let aiBgAutumnLeaves = LumenImages(name: "ai_bg_autumn_leaves")
  public static let aiBgCloudWhisper = LumenImages(name: "ai_bg_cloud_whisper")
  public static let aiBgCopperSunset = LumenImages(name: "ai_bg_copper_sunset")
  public static let aiBgCosmicDust = LumenImages(name: "ai_bg_cosmic_dust")
  public static let aiBgCrystalCave = LumenImages(name: "ai_bg_crystal_cave")
  public static let aiBgDesertMirage = LumenImages(name: "ai_bg_desert_mirage")
  public static let aiBgEtherealGlow = LumenImages(name: "ai_bg_ethereal_glow")
  public static let aiBgGoldenHour = LumenImages(name: "ai_bg_golden_hour")
  public static let aiBgMorningVeil = LumenImages(name: "ai_bg_morning_veil")
  public static let aiBgMysticForest = LumenImages(name: "ai_bg_mystic_forest")
  public static let aiBgNebulaHeart = LumenImages(name: "ai_bg_nebula_heart")
  public static let aiBgNeonDusk = LumenImages(name: "ai_bg_neon_dusk")
  public static let aiBgOceanCurrent = LumenImages(name: "ai_bg_ocean_current")
  public static let aiBgPastelSkies = LumenImages(name: "ai_bg_pastel_skies")
  public static let aiBgPrismLight = LumenImages(name: "ai_bg_prism_light")
  public static let aiBgSnowyPeaks = LumenImages(name: "ai_bg_snowy_peaks")
  public static let aiBgStarryNight = LumenImages(name: "ai_bg_starry_night")
  public static let aiBgUnderwaterGarden = LumenImages(name: "ai_bg_underwater_garden")
  public static let aiBgZenGarden = LumenImages(name: "ai_bg_zen_garden")
}

// MARK: - Implementation Details

public final class LumenColors: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  public var color: Color {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIColor: SwiftUI.Color {
      return SwiftUI.Color(asset: self)
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension LumenColors.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  convenience init?(asset: LumenColors) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
  init(asset: LumenColors) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct LumenImages: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
  init(asset: LumenImages) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }

  init(asset: LumenImages, label: Text) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: LumenImages) {
    let bundle = Bundle.module
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftformat:enable all
// swiftlint:enable all
