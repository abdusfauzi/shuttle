import Cocoa

@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet var arrayController: NSArrayController!

    private var regularIcon: NSImage?
    private var altIcon: NSImage?

    private var statusItem: NSStatusItem?
    private var shuttleConfigFile = ""

    private var configModified: Date?
    private var sshConfigUser: Date?
    private var sshConfigSystem: Date?

    private var terminalPref = "terminal"
    private var editorPref = "default"
    private var iTermVersionPref: String?
    private var openInPref = "tab"
    private var themePref: String?

    private var shuttleHosts: [Any] = []
    private var ignoreHosts: [String] = []
    private var ignoreKeywords: [String] = []

    private var launchAtLoginController: LaunchAtLoginController!

    private let configService = ConfigService()
    private let sshConfigParser = SSHConfigParser()
    private let menuBuilder = MenuBuilder()
    private let terminalRouter = TerminalRouter()
    private let onboardingPreflight = OnboardingPreflight()

    override func awakeFromNib() {
        shuttleConfigFile = configService.resolveShuttleConfigFile()

        regularIcon = NSImage(named: "StatusIcon")
        altIcon = NSImage(named: "StatusIconAlt")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.menu = menu
        statusItem?.image = regularIcon

        let oldAppKitVersion = floor(NSAppKitVersion.current.rawValue) <= 1265
        if !oldAppKitVersion {
            regularIcon?.isTemplate = true
        } else {
            statusItem?.highlightMode = true
            statusItem?.alternateImage = altIcon
        }

        launchAtLoginController = LaunchAtLoginController()
        menu.delegate = self

        DispatchQueue.main.async { [weak self] in
            self?.showPreflightOnboardingIfNeeded()
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        if configService.needsUpdate(file: shuttleConfigFile, old: configModified)
            || configService.needsUpdate(file: "/etc/ssh_config", old: sshConfigSystem)
            || configService.needsUpdate(file: "~/.ssh/config", old: sshConfigUser) {
            configModified = configService.modificationDate(file: shuttleConfigFile)
            sshConfigSystem = configService.modificationDate(file: "/etc/ssh_config")
            sshConfigUser = configService.modificationDate(file: "~/.ssh/config")
            loadMenu()
        }
    }

    private func loadMenu() {
        menuBuilder.clearDynamicItems(in: menu)

        guard let snapshot = configService.loadConfigSnapshot(from: shuttleConfigFile) else {
            let menuItem = menu.insertItem(
                withTitle: NSLocalizedString("Error parsing config", comment: ""),
                action: nil,
                keyEquivalent: "",
                at: 0
            )
            menuItem.isEnabled = false
            return
        }

        terminalPref = snapshot.terminalPref
        editorPref = snapshot.editorPref
        iTermVersionPref = snapshot.iTermVersionPref
        openInPref = snapshot.openInPref
        themePref = snapshot.themePref
        launchAtLoginController.launchAtLogin = snapshot.launchAtLogin

        shuttleHosts = snapshot.hosts
        ignoreHosts = snapshot.ignoreHosts
        ignoreKeywords = snapshot.ignoreKeywords

        if snapshot.showSSHConfigHosts {
            let servers = sshConfigParser.parsePreferredConfig()
            configService.mergeSSHHosts(
                into: &shuttleHosts,
                servers: servers,
                ignoreHosts: ignoreHosts,
                ignoreKeywords: ignoreKeywords
            )
        }

        terminalRouter.updatePreferences(
            terminalPref: terminalPref,
            iTermVersionPref: iTermVersionPref,
            openInPref: openInPref,
            themePref: themePref
        )

        menuBuilder.buildMenu(
            shuttleHosts,
            addToMenu: menu,
            target: self,
            action: #selector(openHost(_:))
        )
    }

    @IBAction func openHost(_ sender: NSMenuItem) {
        let status = onboardingPreflight.evaluate(configPath: shuttleConfigFile)
        if !status.isReady {
            showPreflightOnboardingIfNeeded()
            return
        }

        guard let representedObject = sender.representedObject as? String else {
            return
        }

        terminalRouter.openHost(representedObject) { [weak self] errorMessage, errorInfo, continueOption in
            self?.throwError(errorMessage: errorMessage, additionalInfo: errorInfo, continueOnErrorOption: continueOption)
        }

        iTermVersionPref = terminalRouter.currentITermVersionPref
    }

    @IBAction func showImportPanel(_ sender: Any?) {
        let openPanelObj = NSOpenPanel()
        let result = openPanelObj.runModal()
        if result == .OK, let selectedFileURL = openPanelObj.url {
            let backupPath = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.json.backup")
            try? FileManager.default.moveItem(atPath: shuttleConfigFile, toPath: backupPath)
            try? FileManager.default.copyItem(atPath: selectedFileURL.path, toPath: shuttleConfigFile)
            try? FileManager.default.removeItem(atPath: backupPath)
        }
    }

    @IBAction func showExportPanel(_ sender: Any?) {
        let savePanelObj = NSSavePanel()
        let result = savePanelObj.runModal()
        if result == .OK, let saveURL = savePanelObj.url {
            try? FileManager.default.copyItem(atPath: shuttleConfigFile, toPath: saveURL.path)
        }
    }

    @IBAction func configure(_ sender: Any?) {
        if editorPref.range(of: "default") != nil {
            NSWorkspace.shared.openFile(shuttleConfigFile)
        } else {
            let editorCommand = "\(editorPref) \(shuttleConfigFile)"
            let editorRepObj = "\(editorCommand)¬_¬(null)¬_¬Editing shuttle JSON¬_¬(null)¬_¬(null)"
            let editorMenu = NSMenuItem(title: "editJSONconfig", action: #selector(openHost(_:)), keyEquivalent: "")
            editorMenu.representedObject = editorRepObj
            openHost(editorMenu)
        }
    }

    @IBAction func showAbout(_ sender: Any?) {
        let aboutWindow = AboutWindowController(windowNibName: "AboutWindowController")
        aboutWindow.window?.makeKeyAndOrderFront(nil)
        aboutWindow.window?.level = .floating
        aboutWindow.showWindow(self)
    }

    @IBAction func quit(_ sender: Any?) {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        NSApp.terminate(NSApp)
    }

    private func throwError(errorMessage: String, additionalInfo errorInfo: String, continueOnErrorOption continueOption: Bool) {
        let alert = NSAlert()
        alert.informativeText = errorInfo
        alert.messageText = errorMessage
        alert.alertStyle = .warning

        if continueOption {
            alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))
        } else {
            alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
        }

        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(NSApp)
        }
    }

    private func showPreflightOnboardingIfNeeded() {
        let status = onboardingPreflight.evaluate(configPath: shuttleConfigFile)
        guard !status.isReady else {
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Shuttle setup required", comment: "")
        alert.informativeText = preflightMessage(status)
        alert.addButton(withTitle: NSLocalizedString("Open Privacy Settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Open Config", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openPrivacySettings()
        case .alertSecondButtonReturn:
            configure(nil)
        default:
            break
        }
    }

    private func preflightMessage(_ status: PreflightStatus) -> String {
        var lines: [String] = []

        if !status.accessibilityGranted {
            lines.append(NSLocalizedString("Accessibility permission is required.", comment: ""))
        }
        if !status.automationGranted {
            lines.append(NSLocalizedString("Automation permission is required (System Events).", comment: ""))
        }
        if !status.configReadable {
            lines.append(NSLocalizedString("Config file is not readable.", comment: ""))
        }

        lines.append(NSLocalizedString("Grant permissions and try again.", comment: ""))
        return lines.joined(separator: "\n")
    }

    private func openPrivacySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ]

        for urlString in urls {
            guard let url = URL(string: urlString) else {
                continue
            }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
