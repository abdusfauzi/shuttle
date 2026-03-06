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
    private var aboutWindowController: AboutWindowController?

    private let configService = ConfigService()
    private let sshConfigParser = SSHConfigParser()
    private let menuBuilder = MenuBuilder()
    private let terminalRouter = TerminalRouter()
    private let onboardingPreflight = OnboardingPreflight()
    private let fileManager = FileManager.default

    private enum ConfigImportError: LocalizedError {
        case sourceNotReadable
        case sourceValidationFailed
        case backupFailed(Error)
        case replaceFailed(Error)
        case restoreFailed(Error)

        var errorDescription: String? {
            switch self {
            case .sourceNotReadable:
                return NSLocalizedString("Config source is not readable.", comment: "")
            case .sourceValidationFailed:
                return NSLocalizedString("Config source is invalid JSON.", comment: "")
            case .backupFailed:
                return NSLocalizedString("Unable to back up existing config.", comment: "")
            case .replaceFailed:
                return NSLocalizedString("Unable to replace existing config.", comment: "")
            case .restoreFailed:
                return NSLocalizedString("Unable to restore existing config after failed replacement.", comment: "")
            }
        }
    }

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
            do {
                try replaceConfig(with: selectedFileURL.path)
                loadMenu()
            } catch {
                showNonFatalError(
                    title: NSLocalizedString("Import failed", comment: ""),
                    info: error.localizedDescription
                )
            }
        }
    }

    @IBAction func showExportPanel(_ sender: Any?) {
        let savePanelObj = NSSavePanel()
        let result = savePanelObj.runModal()
        if result == .OK, let saveURL = savePanelObj.url {
            do {
                try FileManager.default.copyItem(atPath: shuttleConfigFile, toPath: saveURL.path)
            } catch {
                showNonFatalError(
                    title: NSLocalizedString("Export failed", comment: ""),
                    info: error.localizedDescription
                )
            }
        }
    }

    @IBAction func configure(_ sender: Any?) {
        if editorPref.range(of: "default") != nil {
            NSWorkspace.shared.open(URL(fileURLWithPath: shuttleConfigFile))
        } else {
            guard SecurityPolicies.isSafeCommand(editorPref) else {
                showNonFatalError(
                    title: NSLocalizedString("Invalid editor command", comment: ""),
                    info: NSLocalizedString("The configured editor command contains invalid characters or exceeds command limits.", comment: "")
                )
                return
            }

            let editorCommand = "\(editorPref) \(SecurityPolicies.shellSingleQuote(shuttleConfigFile))"
            let editorPayload = MenuCommandPayload(
                command: editorCommand,
                theme: (nil as String?),
                title: "Editing shuttle JSON",
                window: (nil as String?),
                fallbackTitle: "editJSONconfig"
            )
            let editorRepObj = editorPayload.serialized()
            let editorMenu = NSMenuItem(title: "editJSONconfig", action: #selector(openHost(_:)), keyEquivalent: "")
            editorMenu.representedObject = editorRepObj
            openHost(editorMenu)
        }
    }

    @IBAction func showAbout(_ sender: Any?) {
        aboutWindowController = AboutWindowController(windowNibName: "AboutWindowController")
        aboutWindowController?.showWindow(self)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
        aboutWindowController?.window?.level = .floating
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

            guard SecurityPolicies.isAllowedURL(url, allowSystemSchemes: true) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func replaceConfig(with sourcePath: String) throws {
        let expandedSource = (sourcePath as NSString).expandingTildeInPath
        guard fileManager.isReadableFile(atPath: expandedSource) else {
            throw ConfigImportError.sourceNotReadable
        }

        guard configService.loadConfigSnapshot(from: expandedSource) != nil else {
            throw ConfigImportError.sourceValidationFailed
        }

        guard let destinationPath = validatedWritableConfigPath(shuttleConfigFile) else {
            throw ConfigImportError.replaceFailed(NSError(domain: "Shuttle", code: 1))
        }

        let stagingPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("shuttle-import-\(UUID().uuidString).json")
        let backupPath = "\(destinationPath).backup.\(UUID().uuidString)"

        do {
            try fileManager.copyItem(atPath: expandedSource, toPath: stagingPath)
        } catch {
            throw ConfigImportError.replaceFailed(error)
        }

        defer {
            if fileManager.fileExists(atPath: stagingPath) {
                try? fileManager.removeItem(atPath: stagingPath)
            }
            if fileManager.fileExists(atPath: backupPath) {
                try? fileManager.removeItem(atPath: backupPath)
            }
        }

        if fileManager.fileExists(atPath: destinationPath) {
            do {
                try fileManager.copyItem(atPath: destinationPath, toPath: backupPath)
            } catch {
                throw ConfigImportError.backupFailed(error)
            }
        }

        do {
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.removeItem(atPath: destinationPath)
            }
            try fileManager.moveItem(atPath: stagingPath, toPath: destinationPath)
        } catch {
            if fileManager.fileExists(atPath: backupPath) {
                do {
                    try fileManager.removeItem(atPath: destinationPath)
                } catch {}

                do {
                    try fileManager.copyItem(atPath: backupPath, toPath: destinationPath)
                    throw ConfigImportError.replaceFailed(error)
                } catch {
                    throw ConfigImportError.restoreFailed(error)
                }
            }
            throw ConfigImportError.replaceFailed(error)
        }
    }

    private func validatedWritableConfigPath(_ path: String) -> String? {
        let expanded = (path as NSString).expandingTildeInPath
        let standardized = (expanded as NSString).standardizingPath

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: standardized, isDirectory: &isDirectory), isDirectory.boolValue {
            return nil
        }

        if fileManager.fileExists(atPath: standardized), !fileManager.isWritableFile(atPath: standardized) {
            return nil
        }

        return standardized
    }

    private func showNonFatalError(title: String, info: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        _ = alert.runModal()
    }
}
