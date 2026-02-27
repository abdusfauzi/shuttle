import Cocoa

@objc(AboutWindowController)
class AboutWindowController: NSWindowController {
    @IBOutlet weak var appName: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet weak var appMaintainer: NSTextField!
    @IBOutlet weak var appCopyright: NSTextField!

    private var plistDict: [String: Any] = [:]

    override func windowDidLoad() {
        super.windowDidLoad()

        // Keep About window position stable across multiple opens.
        self.shouldCascadeWindows = false

        plistDict = Bundle.main.infoDictionary ?? [:]

        let applicationName = (plistDict["CFBundleName"] as? String) ?? "Shuttle"
        let applicationVersion = (plistDict["CFBundleVersion"] as? String) ?? ""
        let applicationCopyright = (plistDict["NSHumanReadableCopyright"] as? String) ?? ""

        let aboutTitle = String(format: "%@%@", NSLocalizedString("About ", comment: ""), applicationName)
        window?.title = aboutTitle

        let programName = String(
            format: "%@%@",
            applicationName,
            NSLocalizedString(" - A simple SSH shortcut menu.", comment: "")
        )
        appName.stringValue = programName

        let migrationNote = NSLocalizedString(" (Swift core refactor; SwiftUI migration groundwork)", comment: "")
        let programVersion = String(
            format: "%@%@%@",
            NSLocalizedString("Version: ", comment: ""),
            applicationVersion,
            migrationNote
        )
        appVersion.cell?.wraps = true
        appVersion.cell?.usesSingleLineMode = false
        appVersion.stringValue = programVersion

        let maintainerName = NSLocalizedString("Abdus Fauzi", comment: "")
        let maintainerLine = String(
            format: "%@%@",
            NSLocalizedString("Maintained by ", comment: ""),
            maintainerName
        )
        appMaintainer.stringValue = maintainerLine

        appCopyright.font = NSFont.systemFont(ofSize: 10)
        appCopyright.stringValue = applicationCopyright
    }

    @IBAction func btnOriginalAuthor(_ sender: Any) {
        guard let applicationHomepage = plistDict["Product Homepage"] as? String,
              let homeURL = URL(string: applicationHomepage) else {
            return
        }

        NSWorkspace.shared.open(homeURL)
    }

    @IBAction func btnForkRepository(_ sender: Any) {
        guard let forkHomepage = plistDict["Fork Homepage"] as? String,
              let homeURL = URL(string: forkHomepage) else {
            return
        }

        NSWorkspace.shared.open(homeURL)
    }
}
