import Cocoa
import CoreServices

final class LaunchAtLoginController: NSObject {
    @objc dynamic var launchAtLogin: Bool {
        get {
            willLaunchAtLogin(appURL)
        }
        set {
            willChangeValue(forKey: startAtLoginKey)
            setLaunchAtLogin(newValue, for: appURL)
            didChangeValue(forKey: startAtLoginKey)
        }
    }

    private let startAtLoginKey = "launchAtLogin"
    private let loginItems: LSSharedFileList?
    private lazy var appURL: URL = URL(fileURLWithPath: Bundle.main.bundlePath)

    override init() {
        loginItems = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeUnretainedValue(),
            nil
        )?.takeRetainedValue()
        super.init()

        if let loginItems {
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            LSSharedFileListAddObserver(
                loginItems,
                CFRunLoopGetMain(),
                CFRunLoopMode.defaultMode.rawValue as CFString,
                sharedFileListDidChange,
                context
            )
        }
    }

    deinit {
        if let loginItems {
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            LSSharedFileListRemoveObserver(
                loginItems,
                CFRunLoopGetMain(),
                CFRunLoopMode.defaultMode.rawValue as CFString,
                sharedFileListDidChange,
                context
            )
        }
    }

    func willLaunchAtLogin(_ itemURL: URL) -> Bool {
        findItem(with: itemURL, in: loginItems) != nil
    }

    func setLaunchAtLogin(_ enabled: Bool, for itemURL: URL) {
        guard let loginItems else {
            return
        }

        let appItem = findItem(with: itemURL, in: loginItems)
        if enabled, appItem == nil {
            LSSharedFileListInsertItemURL(
                loginItems,
                kLSSharedFileListItemBeforeFirst.takeUnretainedValue(),
                nil,
                nil,
                itemURL as CFURL,
                nil,
                nil
            )
        } else if !enabled, let appItem {
            LSSharedFileListItemRemove(loginItems, appItem)
        }
    }

    private func findItem(with wantedURL: URL, in fileList: LSSharedFileList?) -> LSSharedFileListItem? {
        guard let fileList else {
            return nil
        }

        guard let snapshot = LSSharedFileListCopySnapshot(fileList, nil)?.takeRetainedValue() as? [LSSharedFileListItem] else {
            return nil
        }

        for item in snapshot {
            let resolutionFlags = UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)
            guard let currentItemURL = LSSharedFileListItemCopyResolvedURL(item, resolutionFlags, nil)?.takeRetainedValue() as URL? else {
                continue
            }

            if currentItemURL == wantedURL {
                return item
            }
        }

        return nil
    }
}

private func sharedFileListDidChange(_ inList: LSSharedFileList, _ context: UnsafeMutableRawPointer) {
    let controller = Unmanaged<LaunchAtLoginController>.fromOpaque(context).takeUnretainedValue()
    controller.willChangeValue(forKey: "launchAtLogin")
    controller.didChangeValue(forKey: "launchAtLogin")
}
