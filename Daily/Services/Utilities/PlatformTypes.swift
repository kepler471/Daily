//
//  PlatformTypes.swift
//  Daily
//
//  Created by Stelios Georgiou on 05/12/2025.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Platform Conditional Types

/// Define platform-specific type aliases and extensions to maintain cross-platform compatibility
public enum Platform {
    /// Current platform identification
    #if os(iOS)
    public static let isIOS = true
    public static let isMacOS = false
    #elseif os(macOS)
    public static let isIOS = false
    public static let isMacOS = true
    #endif
    
    /// Platform-specific application UIApplication/NSApplication
    #if os(iOS)
    public typealias ApplicationClass = UIApplication
    #elseif os(macOS)
    public typealias ApplicationClass = NSApplication
    #endif
    
    /// Platform-specific window UIWindow/NSWindow
    #if os(iOS)
    public typealias WindowClass = UIWindow
    #elseif os(macOS)
    public typealias WindowClass = NSWindow
    #endif
    
    /// Platform-specific view UIView/NSView
    #if os(iOS)
    public typealias ViewClass = UIView
    #elseif os(macOS)
    public typealias ViewClass = NSView
    #endif
    
    /// Platform-specific color UIColor/NSColor
    #if os(iOS)
    public typealias ColorClass = UIColor
    #elseif os(macOS)
    public typealias ColorClass = NSColor
    #endif
    
    /// Platform-specific image UIImage/NSImage
    #if os(iOS)
    public typealias ImageClass = UIImage
    #elseif os(macOS)
    public typealias ImageClass = NSImage
    #endif
    
    /// Platform-specific screen UIScreen/NSScreen
    #if os(iOS)
    public typealias ScreenClass = UIScreen
    #elseif os(macOS)
    public typealias ScreenClass = NSScreen
    #endif
    
    /// Platform-specific font UIFont/NSFont
    #if os(iOS)
    public typealias FontClass = UIFont
    #elseif os(macOS)
    public typealias FontClass = NSFont
    #endif
    
    /// Platform-specific notification center
    public typealias NotificationCenterClass = NotificationCenter
}

// MARK: - Platform-Specific Extensions

#if os(iOS)
/// UIApplication extension for badge count
extension UIApplication {
    /// Set the application badge count (iOS)
    @available(iOS 13.0, *)
    public func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            if count > 0 {
                self.applicationIconBadgeNumber = count
            } else {
                self.applicationIconBadgeNumber = 0
            }
        }
    }
    
    /// Clear the application badge count (iOS)
    @available(iOS 13.0, *)
    public func clearBadgeCount() {
        DispatchQueue.main.async {
            self.applicationIconBadgeNumber = 0
        }
    }
}
#elseif os(macOS)
/// NSApplication extension for badge count
extension NSApplication {
    /// Set the application badge count (macOS)
    public func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            if count > 0 {
                self.dockTile.badgeLabel = "\(count)"
            } else {
                self.dockTile.badgeLabel = nil
            }
            self.dockTile.display()
        }
    }
    
    /// Clear the application badge count (macOS)
    public func clearBadgeCount() {
        DispatchQueue.main.async {
            self.dockTile.badgeLabel = nil
            self.dockTile.display()
        }
    }
}
#endif

// MARK: - Environment Values

/// Environment key to determine the current platform
private struct PlatformEnvironmentKey: EnvironmentKey {
    #if os(iOS)
    static let defaultValue = Platform.isIOS
    #elseif os(macOS)
    static let defaultValue = Platform.isMacOS
    #endif
}

/// Environment extension for platform checking
extension EnvironmentValues {
    /// Whether the current platform is iOS
    var isIOS: Bool {
        get { self[PlatformEnvironmentKey.self] }
        set { self[PlatformEnvironmentKey.self] = newValue }
    }
    
    /// Whether the current platform is macOS
    var isMacOS: Bool {
        get { return !isIOS }
    }
}

// MARK: - View Modifiers

/// Simple helper functions for platform-specific view modifications
/// These avoid the need for a full ViewModifier implementation

/// View extension for platform-specific modifications
extension View {
    /// Apply view modifier only on iOS
    @ViewBuilder
    func iOSOnly<Content: View>(@ViewBuilder modifier: @escaping (Self) -> Content) -> some View {
        #if os(iOS)
        modifier(self)
        #else
        self
        #endif
    }
    
    /// Apply view modifier only on macOS
    @ViewBuilder
    func macOSOnly<Content: View>(@ViewBuilder modifier: @escaping (Self) -> Content) -> some View {
        #if os(macOS)
        modifier(self)
        #else
        self
        #endif
    }
    
    /// Apply a different view modifier based on platform
    @ViewBuilder
    func platformSpecific<iOSContent: View, macOSContent: View>(
        @ViewBuilder iOS: @escaping (Self) -> iOSContent,
        @ViewBuilder macOS: @escaping (Self) -> macOSContent
    ) -> some View {
        #if os(iOS)
        iOS(self)
        #elseif os(macOS)
        macOS(self)
        #endif
    }
}