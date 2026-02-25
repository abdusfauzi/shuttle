import Cocoa

@objc(AboutWindowController)
class AboutWindowController: NSWindowController {
    @IBOutlet weak var appName: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
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

        let programVersion = String(format: "%@%@", NSLocalizedString("Version: ", comment: ""), applicationVersion)
        appVersion.stringValue = programVersion

        appCopyright.font = NSFont.systemFont(ofSize: 10)
        appCopyright.stringValue = applicationCopyright
    }

    @IBAction func btnHomepage(_ sender: Any) {
        guard let applicationHomepage = plistDict["Product Homepage"] as? String,
              let homeURL = URL(string: applicationHomepage) else {
            return
        }

        NSWorkspace.shared.open(homeURL)
        close()
    }
}
