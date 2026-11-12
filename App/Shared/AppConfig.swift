import CloudKit
import Foundation
import os

/// Identifiers registered for the app in the Apple Developer account (decision 0017).
enum AppConfig {
    /// The CloudKit container that holds every list, wish and overlay.
    static let containerID = "iCloud.com.cambrium.wishfully"
    /// The App Group shared by the app and the Share extension.
    static let appGroupID = "group.com.cambrium.wishfully"

    static var container: CKContainer {
        CKContainer(identifier: containerID)
    }

    /// The App Group folder, or the app's caches folder when the group is unavailable
    /// (simulator builds without signing).
    static var sharedFolder: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

/// Logger categories (decision 0016, G1). List content is interpolated as private values.
enum Log {
    private static let subsystem = "com.cambrium.wishfully"
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let share = Logger(subsystem: subsystem, category: "share")
    static let extraction = Logger(subsystem: subsystem, category: "extraction")
}
