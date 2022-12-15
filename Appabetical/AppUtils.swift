//
//  AppUtils.swift
//  Appabetical
//
//  Created by Rory Madden on 12/12/22.
//

import Foundation
import AssetCatalogWrapper

class AppUtils {
    static let shared = AppUtils()
    private init() {
        fm = FileManager.default
        idToName = [:]
        idToBundle = [:]
        idToIcon = [:]
        idToColor = [:]
        
        let apps = LSApplicationWorkspace.default().allApplications() ?? []
        for app in apps {
            // Get name
            let name = app.localizedName()
            idToName[app.applicationIdentifier] = name
            
            // Get bundle
            let bundleUrl = app.bundleURL
            idToBundle[app.applicationIdentifier] = bundleUrl
        }
    }

    private let fm: FileManager
    private var idToName: [String:String]
    private var idToBundle: [String:URL]
    private var idToIcon: [String:UIImage]
    private var idToColor: [String:UIColor]
    
    private func _getIcon(bundleUrl: URL) -> UIImage {
        let infoPlistUrl = bundleUrl.appendingPathComponent("Info.plist")
        if !fm.fileExists(atPath: infoPlistUrl.path) {
            return UIImage()
        }
        guard let infoPlist = NSDictionary(contentsOf: infoPlistUrl) as? [String:AnyObject] else { return UIImage () }
        if infoPlist.keys.contains("CFBundleIcons") {
            guard let CFBundleIcons = infoPlist["CFBundleIcons"] as? [String:AnyObject] else { return UIImage () }
            if CFBundleIcons.keys.contains("CFBundlePrimaryIcon") {
                guard let CFBundlePrimaryIcon = CFBundleIcons["CFBundlePrimaryIcon"] as? [String:AnyObject] else { return UIImage () }
                if CFBundlePrimaryIcon.keys.contains("CFBundleIconName") {
                    // Check assets file, hope there's a better way than this
                    guard let CFBundleIconName = CFBundlePrimaryIcon["CFBundleIconName"] as? String else { return UIImage () }
                    let assetsUrl = bundleUrl.appendingPathComponent("Assets.car")
                    do {
                        let (_, renditionsRoot) = try AssetCatalogWrapper.shared.renditions(forCarArchive: assetsUrl)
                        for rendition in renditionsRoot {
                            let renditions = rendition.renditions
                            for rend in renditions {
                                if rend.namedLookup.name == CFBundleIconName {
                                    guard let cgImage = rend.image else { return UIImage () }
                                    return UIImage(cgImage: cgImage)
                                }
                            }
                        }
                    } catch {
                        // fall thru
                    }
                }
                if CFBundlePrimaryIcon.keys.contains("CFBundleIconFiles") {
                    // Check bundle file
                    guard let CFBundleIconFiles = CFBundlePrimaryIcon["CFBundleIconFiles"] as? [String] else { return UIImage () }
                    if !CFBundleIconFiles.isEmpty {
                        let iconName = CFBundleIconFiles[0]
                        let appIcon = _iconFromFile(iconName: iconName, bundleUrl: bundleUrl)
                        return appIcon
                    }
                }
            }
        }
        if infoPlist.keys.contains("CFBundleIconFiles") {
            // Check bundle file
            guard let CFBundleIconFiles = infoPlist["CFBundleIconFiles"] as? [String] else { return UIImage () }
            if !CFBundleIconFiles.isEmpty {
                let iconName = CFBundleIconFiles[0]
                let appIcon = _iconFromFile(iconName: iconName, bundleUrl: bundleUrl)
                return appIcon
            }
        }
        // Nothing found
        return UIImage()
    }
    
    // Get an app's icon from its bundle file
    private func _iconFromFile(iconName: String, bundleUrl: URL) -> UIImage {
        var iconFile = ""
        var iconFound = true
        if fm.fileExists(atPath: bundleUrl.appendingPathComponent(iconName + ".png").path) {
            iconFile = iconName + ".png"
        } else if fm.fileExists(atPath: bundleUrl.appendingPathComponent(iconName + "@2x.png").path) {
            iconFile = iconName + "@2x.png"
        } else if fm.fileExists(atPath: bundleUrl.appendingPathComponent(iconName + "-large.png").path) {
            iconFile = iconName + "-large.png"
        } else if fm.fileExists(atPath: bundleUrl.appendingPathComponent(iconName + "@23.png").path) {
            iconFile = iconName + "@23.png"
        } else if fm.fileExists(atPath: bundleUrl.appendingPathComponent(iconName + "@3x.png").path) {
            iconFile = iconName + "@3x.png"
        } else {
            iconFound = false
        }

        if iconFound {
            let iconUrl = (bundleUrl.appendingPathComponent(iconFile))
            do {
                let iconData = try Data(contentsOf: iconUrl)
                guard let icon = UIImage(data: iconData) else { return UIImage () }
                return icon
            } catch {
                return UIImage()
            }
        }
        return UIImage()
    }
    
//    func getIcon(id: String) -> UIImage {
//        if let icon = idToIcon[id] {
//            return icon
//        } else {
//            guard let bundleUrl = idToBundle[id] else { return UIImage() }
//            let icon = _getIcon(bundleUrl: bundleUrl)
//            idToIcon[id] = icon
//            return icon
//        }
//    }
    
    func getColor(id: String) -> UIColor {
        if let color = idToColor[id] {
            return color
        } else {
            guard let bundleUrl = idToBundle[id] else { return UIColor.black }
            var icon = idToIcon[id]
            if icon == nil {
                icon = _getIcon(bundleUrl: bundleUrl)
                idToIcon[id] = icon
            }
            guard let color = icon?.mergedColor() else { return UIColor.black }
            idToColor[id] = color
            return color
        }
    }
    
    func getName(id: String) -> String {
        guard let name = idToName[id] else { return "" }
        return name
    }
}
