// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

#if os(macOS)
  import AppKit.NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import UIKit.UIFont
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Fonts

// swiftlint:disable identifier_name line_length type_body_length
public enum LumenFontFamily: Sendable {
  public enum AbrilFatface: Sendable {
    public static let regular = LumenFontConvertible(name: "AbrilFatface-Regular", family: "Abril Fatface", path: "AbrilFatface-Regular.ttf")
    public static let all: [LumenFontConvertible] = [regular]
  }
  public enum Caveat: Sendable {
    public static let regular = LumenFontConvertible(name: "Caveat-Regular", family: "Caveat", path: "Caveat.ttf")
    public static let bold = LumenFontConvertible(name: "CaveatRoman-Bold", family: "Caveat", path: "Caveat.ttf")
    public static let all: [LumenFontConvertible] = [regular, bold]
  }
  public enum CormorantGaramond: Sendable {
    public static let bold = LumenFontConvertible(name: "CormorantGaramond-Bold", family: "Cormorant Garamond", path: "CormorantGaramond-Bold.ttf")
    public static let all: [LumenFontConvertible] = [bold]
  }
  public enum CormorantGaramondSemiBold: Sendable {
    public static let regular = LumenFontConvertible(name: "CormorantGaramond-SemiBold", family: "Cormorant Garamond SemiBold", path: "CormorantGaramond-SemiBold.ttf")
    public static let all: [LumenFontConvertible] = [regular]
  }
  public enum DancingScript: Sendable {
    public static let bold = LumenFontConvertible(name: "DancingScript-Bold", family: "Dancing Script", path: "DancingScript.ttf")
    public static let medium = LumenFontConvertible(name: "DancingScript-Medium", family: "Dancing Script", path: "DancingScript.ttf")
    public static let regular = LumenFontConvertible(name: "DancingScript-Regular", family: "Dancing Script", path: "DancingScript.ttf")
    public static let semiBold = LumenFontConvertible(name: "DancingScript-SemiBold", family: "Dancing Script", path: "DancingScript.ttf")
    public static let all: [LumenFontConvertible] = [bold, medium, regular, semiBold]
  }
  public enum JosefinSans: Sendable {
    public static let thin = LumenFontConvertible(name: "JosefinSans-Thin", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let bold = LumenFontConvertible(name: "JosefinSansRoman-Bold", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let extraLight = LumenFontConvertible(name: "JosefinSansRoman-ExtraLight", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let light = LumenFontConvertible(name: "JosefinSansRoman-Light", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let medium = LumenFontConvertible(name: "JosefinSansRoman-Medium", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let regular = LumenFontConvertible(name: "JosefinSansRoman-Regular", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let semiBold = LumenFontConvertible(name: "JosefinSansRoman-SemiBold", family: "Josefin Sans", path: "JosefinSans.ttf")
    public static let all: [LumenFontConvertible] = [thin, bold, extraLight, light, medium, regular, semiBold]
  }
  public enum PlayfairDisplay: Sendable {
    public static let regular = LumenFontConvertible(name: "PlayfairDisplay-Regular", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let black = LumenFontConvertible(name: "PlayfairDisplayRoman-Black", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let bold = LumenFontConvertible(name: "PlayfairDisplayRoman-Bold", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let extraBold = LumenFontConvertible(name: "PlayfairDisplayRoman-ExtraBold", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let medium = LumenFontConvertible(name: "PlayfairDisplayRoman-Medium", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let semiBold = LumenFontConvertible(name: "PlayfairDisplayRoman-SemiBold", family: "Playfair Display", path: "PlayfairDisplay.ttf")
    public static let all: [LumenFontConvertible] = [regular, black, bold, extraBold, medium, semiBold]
  }
  public enum Righteous: Sendable {
    public static let regular = LumenFontConvertible(name: "Righteous-Regular", family: "Righteous", path: "Righteous-Regular.ttf")
    public static let all: [LumenFontConvertible] = [regular]
  }
  public enum ZillaSlab: Sendable {
    public static let bold = LumenFontConvertible(name: "ZillaSlab-Bold", family: "Zilla Slab", path: "ZillaSlab-Bold.ttf")
    public static let semiBold = LumenFontConvertible(name: "ZillaSlab-SemiBold", family: "Zilla Slab", path: "ZillaSlab-SemiBold.ttf")
    public static let all: [LumenFontConvertible] = [bold, semiBold]
  }
  public static let allCustomFonts: [LumenFontConvertible] = [AbrilFatface.all, Caveat.all, CormorantGaramond.all, CormorantGaramondSemiBold.all, DancingScript.all, JosefinSans.all, PlayfairDisplay.all, Righteous.all, ZillaSlab.all].flatMap { $0 }
  public static func registerAllCustomFonts() {
    allCustomFonts.forEach { $0.register() }
  }
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

public struct LumenFontConvertible: Sendable {
  public let name: String
  public let family: String
  public let path: String

  #if os(macOS)
  public typealias Font = NSFont
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Font = UIFont
  #endif

  public func font(size: CGFloat) -> Font {
    guard let font = Font(font: self, size: size) else {
      fatalError("Unable to initialize font '\(name)' (\(family))")
    }
    return font
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public func swiftUIFont(size: CGFloat) -> SwiftUI.Font {
    guard let font = Font(font: self, size: size) else {
      fatalError("Unable to initialize font '\(name)' (\(family))")
    }
    #if os(macOS)
    return SwiftUI.Font.custom(font.fontName, size: font.pointSize)
    #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    return SwiftUI.Font(font)
    #endif
  }
  #endif

  public func register() {
    // swiftlint:disable:next conditional_returns_on_newline
    guard let url = url else { return }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }

  fileprivate var url: URL? {
    // swiftlint:disable:next implicit_return
    return Bundle.module.url(forResource: path, withExtension: nil)
  }
}

public extension LumenFontConvertible.Font {
  convenience init?(font: LumenFontConvertible, size: CGFloat) {
    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    if !UIFont.fontNames(forFamilyName: font.family).contains(font.name) {
      font.register()
    }
    #elseif os(macOS)
    if let url = font.url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
      font.register()
    }
    #endif

    self.init(name: font.name, size: size)
  }
}
// swiftformat:enable all
// swiftlint:enable all
