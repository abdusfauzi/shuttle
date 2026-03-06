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
    private var settingsWindowController: SettingsWindowController?
    private var staticMenuItemCount = 4

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
        shuttleConfigFile = configService.resolveConfigLocation().path

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
        configureStaticMenuItems()
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
        menuBuilder.clearDynamicItems(in: menu, preservingLast: staticMenuItemCount)

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

        RuntimeDiagnostics.measure("menu.build", details: "hosts=\(shuttleHosts.count)") {
            menuBuilder.buildMenu(
                shuttleHosts,
                addToMenu: menu,
                target: self,
                action: #selector(openHost(_:))
            )
        }
    }

    @IBAction func openHost(_ sender: NSMenuItem) {
        let activeConfigPath = syncActiveConfigLocation().path
        let status = evaluatePreflight(configPath: activeConfigPath)
        if !status.isReady {
            showSettings(nil)
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
        shuttleConfigFile = syncActiveConfigLocation().path
        let openPanelObj = NSOpenPanel()
        let result = openPanelObj.runModal()
        if result == .OK, let selectedFileURL = openPanelObj.url {
            do {
                try replaceConfig(at: shuttleConfigFile, with: selectedFileURL.path)
                loadMenu()
                refreshSettingsWindow()
            } catch {
                showNonFatalError(
                    title: NSLocalizedString("Import failed", comment: ""),
                    info: error.localizedDescription
                )
            }
        }
    }

    @IBAction func showExportPanel(_ sender: Any?) {
        shuttleConfigFile = syncActiveConfigLocation().path
        let savePanelObj = NSSavePanel()
        let result = savePanelObj.runModal()
        if result == .OK, let saveURL = savePanelObj.url {
            do {
                try FileManager.default.copyItem(atPath: shuttleConfigFile, toPath: saveURL.path)
                refreshSettingsWindow()
            } catch {
                showNonFatalError(
                    title: NSLocalizedString("Export failed", comment: ""),
                    info: error.localizedDescription
                )
            }
        }
    }

    @IBAction func configure(_ sender: Any?) {
        shuttleConfigFile = syncActiveConfigLocation().path
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

        refreshSettingsWindow()
    }

    @IBAction func showSettings(_ sender: Any?) {
        let controller = activeSettingsWindowController()
        refreshSettingsWindow()
        controller.showWindow(self)
    }

    @IBAction func showAbout(_ sender: Any?) {
        showSettings(sender)
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
        let status = evaluatePreflight(configPath: syncActiveConfigLocation().path)
        guard !status.isReady else {
            return
        }

        showSettings(nil)
    }

    private func openAccessibilitySettings() {
        openSystemSettings(urlStrings: [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ])
    }

    private func openAutomationSettings() {
        openSystemSettings(urlStrings: [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ])
    }

    private func openSystemSettings(urlStrings: [String]) {
        for urlString in urlStrings {
            guard let url = URL(string: urlString),
                  SecurityPolicies.isAllowedURL(url, allowSystemSchemes: true) else {
                continue
            }

            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func replaceConfig(with sourcePath: String) throws {
        try replaceConfig(at: shuttleConfigFile, with: sourcePath)
    }

    private func replaceConfig(at destinationPath: String, with sourcePath: String) throws {
        let expandedSource = (sourcePath as NSString).expandingTildeInPath
        guard fileManager.isReadableFile(atPath: expandedSource) else {
            throw ConfigImportError.sourceNotReadable
        }

        guard configService.loadConfigSnapshot(from: expandedSource) != nil else {
            throw ConfigImportError.sourceValidationFailed
        }

        guard let destinationPath = validatedWritableConfigPath(destinationPath) else {
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

    private func configureStaticMenuItems() {
        if let settingsItem = menu.item(withTitle: "Settings") {
            settingsItem.submenu = nil
            settingsItem.action = #selector(showSettings(_:))
            settingsItem.target = self
            settingsItem.keyEquivalent = ""
        }

        if let aboutItem = menu.item(withTitle: "About") {
            menu.removeItem(aboutItem)
        }

        staticMenuItemCount = menu.items.count
    }

    private func activeSettingsWindowController() -> SettingsWindowController {
        if let settingsWindowController {
            return settingsWindowController
        }

        let controller = SettingsWindowController(windowNibName: "SettingsWindowController")
        controller.settingsDelegate = self
        settingsWindowController = controller
        return controller
    }

    private func syncActiveConfigLocation() -> ConfigLocationResolution {
        let location = configService.resolveConfigLocation()
        if location.path != shuttleConfigFile {
            shuttleConfigFile = location.path
            configModified = nil
        }
        return location
    }

    private func currentSettingsState() -> SettingsWindowState {
        let location = syncActiveConfigLocation()
        let snapshot = configService.loadConfigSnapshot(from: location.path)
        let status = evaluatePreflight(
            configPath: location.path,
            snapshotTerminalPref: snapshot?.terminalPref,
            snapshotOpenInPref: snapshot?.openInPref
        )
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        let bundleVersion = (infoDictionary["CFBundleShortVersionString"] as? String)
            ?? (infoDictionary["CFBundleVersion"] as? String)
            ?? "Unknown"

        return SettingsWindowState(
            configPath: location.path,
            configSource: location.source.displayName,
            configReadable: status.configReadable,
            accessibilityGranted: status.accessibilityGranted,
            automationGranted: status.automationGranted,
            requiresAccessibility: status.requiresAccessibility,
            requiresAutomation: status.requiresAutomation,
            showSSHConfigHosts: snapshot?.showSSHConfigHosts ?? false,
            configFileStatus: status.configReadable
                ? NSLocalizedString("Readable", comment: "")
                : NSLocalizedString("Not readable", comment: ""),
            version: bundleVersion,
            maintainer: String(
                format: "%@%@",
                NSLocalizedString("Maintained by ", comment: ""),
                NSLocalizedString("Abdus Fauzi", comment: "")
            ),
            copyright: (infoDictionary["NSHumanReadableCopyright"] as? String) ?? "",
            originalHomepage: infoDictionary["Product Homepage"] as? String,
            forkHomepage: infoDictionary["Fork Homepage"] as? String
        )
    }

    private func evaluatePreflight(
        configPath: String,
        snapshotTerminalPref: String? = nil,
        snapshotOpenInPref: String? = nil
    ) -> PreflightStatus {
        let resolvedSnapshot = (snapshotTerminalPref == nil || snapshotOpenInPref == nil)
            ? configService.loadConfigSnapshot(from: configPath)
            : nil
        let resolvedTerminalPref = snapshotTerminalPref
            ?? resolvedSnapshot?.terminalPref
            ?? terminalPref
        let resolvedOpenInPref = snapshotOpenInPref
            ?? resolvedSnapshot?.openInPref
            ?? openInPref

        return onboardingPreflight.evaluate(
            configPath: configPath,
            terminalPref: resolvedTerminalPref,
            openInPref: resolvedOpenInPref
        )
    }

    private func refreshSettingsWindow() {
        settingsWindowController?.update(with: currentSettingsState())
    }

    private func applyConfigLocation(_ location: ConfigLocationResolution, reloadMenu: Bool) {
        shuttleConfigFile = location.path
        configModified = nil
        if reloadMenu {
            loadMenu()
            configModified = configService.modificationDate(file: shuttleConfigFile)
        }
        refreshSettingsWindow()
    }

    private func chooseConfigFile() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["json"]
        openPanel.prompt = NSLocalizedString("Choose Config File", comment: "")
        openPanel.directoryURL = URL(fileURLWithPath: (shuttleConfigFile as NSString).deletingLastPathComponent)

        guard openPanel.runModal() == .OK, let selectedFileURL = openPanel.url else {
            return
        }

        guard configService.loadConfigSnapshot(from: selectedFileURL.path) != nil else {
            showNonFatalError(
                title: NSLocalizedString("Import failed", comment: ""),
                info: NSLocalizedString("Config source is invalid JSON.", comment: "")
            )
            return
        }

        do {
            let location = try configService.saveSelectedConfigFile(at: selectedFileURL)
            applyConfigLocation(location, reloadMenu: true)
        } catch {
            showNonFatalError(
                title: NSLocalizedString("Config selection failed", comment: ""),
                info: error.localizedDescription
            )
        }
    }

    private func copyLocalDefaultConfigToDestination() {
        let localDefaultPath = configService.localDefaultConfigFile()
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = URL(fileURLWithPath: localDefaultPath).lastPathComponent
        savePanel.prompt = NSLocalizedString("Copy Config", comment: "")

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else {
            return
        }

        do {
            try replaceConfig(at: destinationURL.path, with: localDefaultPath)
            refreshSettingsWindow()
        } catch {
            showNonFatalError(
                title: NSLocalizedString("Export failed", comment: ""),
                info: error.localizedDescription
            )
        }
    }

    private func copyActiveConfigToLocalDefault() {
        let localDefaultPath = configService.localDefaultConfigFile()

        do {
            try replaceConfig(at: localDefaultPath, with: shuttleConfigFile)
            refreshSettingsWindow()
        } catch {
            showNonFatalError(
                title: NSLocalizedString("Import failed", comment: ""),
                info: error.localizedDescription
            )
        }
    }

    private func relaunchApplication() {
        let relaunchTask = Process()
        relaunchTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        relaunchTask.arguments = ["-n", Bundle.main.bundlePath]

        do {
            try relaunchTask.run()
            NSApp.terminate(nil)
        } catch {
            showNonFatalError(
                title: NSLocalizedString("Relaunch failed", comment: ""),
                info: error.localizedDescription
            )
        }
    }
}

extension AppDelegate: SettingsWindowControllerDelegate {
    func settingsWindowControllerDidRequestChooseConfigFile(_ controller: SettingsWindowController) {
        chooseConfigFile()
    }

    func settingsWindowControllerDidRequestRevealConfigFile(_ controller: SettingsWindowController) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: shuttleConfigFile)])
    }

    func settingsWindowControllerDidRequestUseLocalDefault(_ controller: SettingsWindowController) {
        let location = configService.clearSelectedConfigFile()
        applyConfigLocation(location, reloadMenu: true)
    }

    func settingsWindowControllerDidRequestRefresh(_ controller: SettingsWindowController) {
        refreshSettingsWindow()
    }

    func settingsWindowControllerDidRequestRelaunch(_ controller: SettingsWindowController) {
        relaunchApplication()
    }

    func settingsWindowControllerDidRequestOpenAccessibility(_ controller: SettingsWindowController) {
        openAccessibilitySettings()
    }

    func settingsWindowControllerDidRequestOpenAutomation(_ controller: SettingsWindowController) {
        openAutomationSettings()
    }

    func settingsWindowControllerDidChangeShowSSHConfigHosts(_ controller: SettingsWindowController, enabled: Bool) {
        do {
            try configService.updateShowSSHConfigHosts(enabled, in: shuttleConfigFile)
            configModified = nil
            loadMenu()
            refreshSettingsWindow()
        } catch {
            showNonFatalError(
                title: NSLocalizedString("Config update failed", comment: ""),
                info: error.localizedDescription
            )
        }
    }

    func settingsWindowControllerDidRequestEditConfig(_ controller: SettingsWindowController) {
        configure(nil)
    }

    func settingsWindowControllerDidRequestImportConfig(_ controller: SettingsWindowController) {
        showImportPanel(nil)
        refreshSettingsWindow()
    }

    func settingsWindowControllerDidRequestExportConfig(_ controller: SettingsWindowController) {
        showExportPanel(nil)
    }

    func settingsWindowControllerDidRequestCopyLocalDefaultToDestination(_ controller: SettingsWindowController) {
        copyLocalDefaultConfigToDestination()
    }

    func settingsWindowControllerDidRequestCopyActiveToLocalDefault(_ controller: SettingsWindowController) {
        copyActiveConfigToLocalDefault()
    }
}
