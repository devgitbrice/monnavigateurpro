import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
import AudioToolbox
#endif

// MARK: - Sounds

struct SoundPlayer {
    static func playTink() {
        #if os(macOS)
        NSSound(named: .init("Tink"))?.play()
        #else
        AudioServicesPlaySystemSound(1057)
        #endif
    }

    static func playPurr() {
        #if os(macOS)
        NSSound(named: .init("Purr"))?.play()
        #else
        AudioServicesPlaySystemSound(1519) // taptic + subtle sound
        #endif
    }

    static func playGlass() {
        #if os(macOS)
        NSSound(named: .init("Glass"))?.play()
        #else
        AudioServicesPlaySystemSound(1054)
        #endif
    }
}

// MARK: - Pasteboard

struct ClipboardHelper {
    static func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}

// MARK: - Platform Colors

extension Color {
    static var platformTextBackground: Color {
        #if os(macOS)
        Color(.textBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var platformWindowBackground: Color {
        #if os(macOS)
        Color(.windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var platformControlBackground: Color {
        #if os(macOS)
        Color(.controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    static var platformSeparator: Color {
        #if os(macOS)
        Color(.separatorColor)
        #else
        Color(.separator)
        #endif
    }
}

// MARK: - Platform Image

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif
