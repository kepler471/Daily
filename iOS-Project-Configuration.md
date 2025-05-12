# iOS Project Configuration Guide

This guide outlines the steps to configure the Xcode project for iOS support alongside macOS.

## Project Settings Updates

1. Open `Daily.xcodeproj` in Xcode
2. Select the project in the Navigator panel (top-level item)
3. Select the "Daily" target

### General Tab

1. In the "Deployment Info" section:
   - Check "iOS" as a supported platform
   - Set iOS Deployment Target to iOS 16.0 or later (for best SwiftData support)
   - Check "iPhone" and "iPad" for supported devices

2. In the "App Icons and Launch Screens" section:
   - Configure an iOS app icon set
   - Create a simple launch screen storyboard or use the new iOS 15+ launch screen configuration

### Signing & Capabilities Tab

1. Configure the same team and bundle identifier scheme for iOS as used for macOS
2. Add the following capabilities for iOS:
   - Background Modes:
     - Background fetch
     - Remote notifications
   - Push Notifications (if needed)

### Build Settings Tab

1. Set "Targeted Device Family" to include "iPhone" and "iPad" (1,2)
2. Under "Swift Compiler - General", make sure "Cross-module Optimization" is enabled for release builds
3. Under "Packaging", ensure the Info.plist is set correctly for iOS (might need conditionals)

### Info.plist Configuration

Instead of creating a separate Info.plist, we can use build settings to conditionally include required keys:

1. In the Info.plist, add the following keys with conditional compilation:

```xml
<!-- Common settings -->
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<!-- iOS-specific settings -->
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default</string>
                <key>UISceneDelegateClassName</key>
                <string>Daily.iOSSceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
    <string>remote-notification</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.kepler471.Daily.todoReset</string>
</array>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>
<key>NSUserNotificationsUsageDescription</key>
<string>We'll notify you about your todos and upcoming tasks.</string>
```

## Build Phases

1. In "Build Phases" tab, configure:
   - Add any iOS-specific frameworks (such as UIKit)
   - Ensure SwiftData is available for both platforms

## Project Structure

1. Create logical target membership for your files:
   - Common files: Both macOS and iOS
   - Platform-specific files: Only the respective platform

2. Use the "Target Membership" checkbox in the File Inspector for each file

## Asset Catalog

1. Configure the asset catalog for both platforms:
   - Create universal color sets
   - Add platform-specific images as needed
   - Configure different app icons for iOS and macOS

## Build Schemes

1. Create separate build schemes for iOS and macOS
2. Configure each scheme to build for the appropriate platform

## Notes on Cross-Platform Development

1. Use `#if os(iOS)` / `#if os(macOS)` conditional compilation directives for platform-specific code
2. Use the PlatformTypes.swift abstractions we created to handle platform differences
3. Be cautious with platform-specific APIs; always provide alternatives for both platforms
4. Test on both platforms frequently during development

## SwiftData Considerations

- Ensure the data model is compatible across platforms
- SwiftData should work identically on iOS and macOS
- Be mindful of any platform-specific model extensions

## Next Steps

After configuring the project, be sure to:
1. Test building for both platforms
2. Run on iOS simulator to verify basic functionality
3. Test notification handling on both platforms
4. Verify SwiftData persistence works properly on iOS