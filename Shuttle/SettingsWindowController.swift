import Cocoa

protocol SettingsWindowControllerDelegate: AnyObject {
    func settingsWindowControllerDidRequestChooseConfigFile(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestRevealConfigFile(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestUseLocalDefault(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestRefresh(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestOpenAccessibility(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestOpenAutomation(_ controller: SettingsWindowController)
    func settingsWindowControllerDidChangeShowSSHConfigHosts(_ controller: SettingsWindowController, enabled: Bool)
    func settingsWindowControllerDidRequestEditConfig(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestImportConfig(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestExportConfig(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestCopyLocalDefaultToDestination(_ controller: SettingsWindowController)
    func settingsWindowControllerDidRequestCopyActiveToLocalDefault(_ controller: SettingsWindowController)
}

struct SettingsWindowState {
    let configPath: String
    let configSource: String
    let configReadable: Bool
    let accessibilityGranted: Bool
    let automationGranted: Bool
    let requiresAccessibility: Bool
    let requiresAutomation: Bool
    let showSSHConfigHosts: Bool
    let configFileStatus: String
    let version: String
    let maintainer: String
    let copyright: String
    let originalHomepage: String?
    let forkHomepage: String?
}

@objc(SettingsWindowController)
final class SettingsWindowController: NSWindowController {
    weak var settingsDelegate: SettingsWindowControllerDelegate?

    private let tabView = NSTabView()
    private let summaryLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 13))
    private let accessibilityStatusLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let accessibilityDetailLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 11))
    private let automationStatusLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let automationDetailLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 11))
    private let lastCheckedLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 11))
    private let configStatusLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let configPathLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.userFixedPitchFont(ofSize: 11) ?? NSFont.systemFont(ofSize: 11))
    private let configSourceLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let versionLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let maintainerLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 12))
    private let copyrightLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 11))
    private lazy var showSSHConfigHostsButton: NSButton = {
        let button = NSButton(checkboxWithTitle: NSLocalizedString("Show SSH config hosts", comment: ""), target: self, action: #selector(toggleShowSSHConfigHosts(_:)))
        button.controlSize = .small
        return button
    }()

    private var currentState: SettingsWindowState?
    private lazy var refreshTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    override func windowDidLoad() {
        super.windowDidLoad()
        shouldCascadeWindows = false
        configureWindow()
        buildInterface()
    }

    override func showWindow(_ sender: Any?) {
        _ = window
        super.showWindow(sender)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func update(with state: SettingsWindowState) {
        _ = window
        currentState = state
        refreshInterface(with: state)
    }

    private func configureWindow() {
        window?.title = NSLocalizedString("Shuttle Settings", comment: "")
        window?.setContentSize(NSSize(width: 720, height: 560))
        window?.minSize = NSSize(width: 660, height: 520)
    }

    private func buildInterface() {
        guard let contentView = window?.contentView else {
            return
        }

        tabView.tabViewType = .topTabsBezelBorder
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(makePermissionsTab())
        tabView.addTabViewItem(makeConfigTab())
        tabView.addTabViewItem(makeAboutTab())

        contentView.addSubview(tabView)

        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func makePermissionsSection() -> NSView {
        let accessibilityRow = makeActionRow(
            title: NSLocalizedString("Accessibility", comment: ""),
            statusLabel: accessibilityStatusLabel,
            detailLabel: accessibilityDetailLabel,
            buttons: [
                makeButton(title: NSLocalizedString("Open Accessibility", comment: ""), action: #selector(openAccessibility(_:)))
            ]
        )

        let automationRow = makeActionRow(
            title: NSLocalizedString("Automation", comment: ""),
            statusLabel: automationStatusLabel,
            detailLabel: automationDetailLabel,
            buttons: [
                makeButton(title: NSLocalizedString("Open Automation", comment: ""), action: #selector(openAutomation(_:)))
            ]
        )

        let refreshRow = NSStackView(views: [
            summaryLabel,
            makeButton(title: NSLocalizedString("Refresh Status", comment: ""), action: #selector(refreshStatus(_:)))
        ])
        refreshRow.orientation = .horizontal
        refreshRow.alignment = .centerY
        refreshRow.spacing = 12

        let body = NSStackView(views: [accessibilityRow, automationRow, refreshRow, lastCheckedLabel])
        body.orientation = .vertical
        body.alignment = .leading
        body.spacing = 12

        return makeTabContent(
            title: NSLocalizedString("Permissions", comment: ""),
            subtitle: NSLocalizedString("Grant the permissions Shuttle needs to open hosts reliably.", comment: ""),
            body: body
        )
    }

    private func makeConfigSection() -> NSView {
        let sourceRow = makeInfoRow(title: NSLocalizedString("Source", comment: ""), valueLabel: configSourceLabel)
        let pathRow = makeInfoRow(title: NSLocalizedString("Path", comment: ""), valueLabel: configPathLabel)
        let fileStatusRow = makeInfoRow(title: NSLocalizedString("File", comment: ""), valueLabel: configStatusLabel)

        let buttonRow = NSStackView(views: [
            makeButton(title: NSLocalizedString("Choose Config File", comment: ""), action: #selector(chooseConfigFile(_:))),
            makeButton(title: NSLocalizedString("Reveal in Finder", comment: ""), action: #selector(revealConfigFile(_:))),
            makeButton(title: NSLocalizedString("Use Local Default", comment: ""), action: #selector(useLocalDefault(_:)))
        ])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        let managementRow = NSStackView(views: [
            makeButton(title: NSLocalizedString("Edit Config", comment: ""), action: #selector(editConfig(_:))),
            makeButton(title: NSLocalizedString("Import", comment: ""), action: #selector(importConfig(_:))),
            makeButton(title: NSLocalizedString("Export", comment: ""), action: #selector(exportConfig(_:)))
        ])
        managementRow.orientation = .horizontal
        managementRow.alignment = .centerY
        managementRow.spacing = 8

        let copyRow = NSStackView(views: [
            makeButton(title: NSLocalizedString("Copy Local Default To...", comment: ""), action: #selector(copyLocalDefaultToDestination(_:))),
            makeButton(title: NSLocalizedString("Copy Active To Local Default", comment: ""), action: #selector(copyActiveToLocalDefault(_:)))
        ])
        copyRow.orientation = .horizontal
        copyRow.alignment = .centerY
        copyRow.spacing = 8

        let body = NSStackView(views: [sourceRow, pathRow, fileStatusRow, showSSHConfigHostsButton, buttonRow, managementRow, copyRow])
        body.orientation = .vertical
        body.alignment = .leading
        body.spacing = 12

        return makeTabContent(
            title: NSLocalizedString("Config", comment: ""),
            subtitle: NSLocalizedString("Choose where Shuttle reads its config and manage local or iCloud copies.", comment: ""),
            body: body
        )
    }

    private func makeAboutSection() -> NSView {
        let homepageButton = makeButton(title: NSLocalizedString("Original Author", comment: ""), action: #selector(openOriginalHomepage(_:)))
        let forkButton = makeButton(title: NSLocalizedString("Project Fork", comment: ""), action: #selector(openForkHomepage(_:)))
        let buttonRow = NSStackView(views: [homepageButton, forkButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8

        let body = NSStackView(views: [versionLabel, maintainerLabel, copyrightLabel, buttonRow])
        body.orientation = .vertical
        body.alignment = .leading
        body.spacing = 10

        return makeTabContent(
            title: NSLocalizedString("About Shuttle", comment: ""),
            subtitle: NSLocalizedString("Version, ownership, and project links for the current build.", comment: ""),
            body: body
        )
    }

    private func makePermissionsTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "permissions")
        item.label = NSLocalizedString("Permissions", comment: "")
        item.view = makePermissionsSection()
        return item
    }

    private func makeConfigTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "config")
        item.label = NSLocalizedString("Config", comment: "")
        item.view = makeConfigSection()
        return item
    }

    private func makeAboutTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "about")
        item.label = NSLocalizedString("About", comment: "")
        item.view = makeAboutSection()
        return item
    }

    private func makeTabContent(title: String, subtitle: String, body: NSView) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = SettingsWindowController.makeHeadlineLabel(title)
        let subtitleLabel = SettingsWindowController.makeWrappingLabel(font: NSFont.systemFont(ofSize: 13))
        subtitleLabel.stringValue = subtitle

        let stack = NSStackView(views: [titleLabel, subtitleLabel, body])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24)
        ])

        return container
    }

    private func makeActionRow(title: String, statusLabel: NSTextField, detailLabel: NSTextField, buttons: [NSButton]) -> NSView {
        let titleLabel = SettingsWindowController.makeSectionLabel(title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let buttonsStack = NSStackView(views: buttons)
        buttonsStack.orientation = .horizontal
        buttonsStack.alignment = .centerY
        buttonsStack.spacing = 8

        let topRow = NSStackView(views: [titleLabel, statusLabel, buttonsStack])
        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 12

        let row = NSStackView(views: [topRow, detailLabel])
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 4
        return row
    }

    private func makeInfoRow(title: String, valueLabel: NSTextField) -> NSView {
        let titleLabel = SettingsWindowController.makeSectionLabel(title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = NSStackView(views: [titleLabel, valueLabel])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 12
        return row
    }

    private func refreshInterface(with state: SettingsWindowState) {
        accessibilityStatusLabel.stringValue = permissionStatusText(
            granted: state.accessibilityGranted,
            required: state.requiresAccessibility,
            fallback: NSLocalizedString("Not required", comment: "")
        )
        automationStatusLabel.stringValue = permissionStatusText(
            granted: state.automationGranted,
            required: state.requiresAutomation,
            fallback: NSLocalizedString("On-demand", comment: "")
        )
        accessibilityDetailLabel.stringValue = accessibilityDetailText(for: state)
        automationDetailLabel.stringValue = automationDetailText(for: state)
        configStatusLabel.stringValue = state.configFileStatus
        configPathLabel.stringValue = state.configPath
        configSourceLabel.stringValue = state.configSource
        versionLabel.stringValue = String(format: NSLocalizedString("Version: %@", comment: ""), state.version)
        maintainerLabel.stringValue = state.maintainer
        copyrightLabel.stringValue = state.copyright
        showSSHConfigHostsButton.state = state.showSSHConfigHosts ? .on : .off
        showSSHConfigHostsButton.isEnabled = state.configReadable
        summaryLabel.stringValue = summaryText(for: state)
        lastCheckedLabel.stringValue = String(
            format: NSLocalizedString("Last checked: %@", comment: ""),
            refreshTimestampFormatter.string(from: Date())
        )
    }

    private func summaryText(for state: SettingsWindowState) -> String {
        var missing: [String] = []
        if state.requiresAccessibility && !state.accessibilityGranted {
            missing.append(NSLocalizedString("Accessibility permission is required.", comment: ""))
        }
        if state.requiresAutomation && !state.automationGranted {
            missing.append(NSLocalizedString("Automation permission is required (System Events).", comment: ""))
        }
        if !state.configReadable {
            missing.append(NSLocalizedString("Config file is not readable.", comment: ""))
        }

        guard !missing.isEmpty else {
            return NSLocalizedString("Setup is complete. Shuttle is ready to open hosts.", comment: "")
        }

        return missing.joined(separator: " ")
    }

    private func permissionStatusText(granted: Bool, required: Bool, fallback: String) -> String {
        if granted {
            return NSLocalizedString("Granted", comment: "")
        }
        if required {
            return NSLocalizedString("Required", comment: "")
        }
        return fallback
    }

    private func accessibilityDetailText(for state: SettingsWindowState) -> String {
        if state.requiresAccessibility {
            if state.accessibilityGranted {
                return NSLocalizedString("Granted. Required for the selected terminal/backend.", comment: "")
            }
            return NSLocalizedString("Missing. Required for the selected terminal/backend.", comment: "")
        }

        if state.accessibilityGranted {
            return NSLocalizedString("Granted, but not required for the selected terminal.", comment: "")
        }

        return NSLocalizedString("Not currently required for the selected terminal.", comment: "")
    }

    private func automationDetailText(for state: SettingsWindowState) -> String {
        if state.requiresAutomation {
            if state.automationGranted {
                return NSLocalizedString("Granted. System Events automation is required for the selected terminal/backend.", comment: "")
            }
            return NSLocalizedString("Missing. System Events automation is required for the selected terminal/backend.", comment: "")
        }

        if state.automationGranted {
            return NSLocalizedString("Granted and available for UI scripting fallbacks.", comment: "")
        }

        return NSLocalizedString("Not currently required for the selected terminal. Shuttle will request it only when a backend needs System Events.", comment: "")
    }

    private static func makeHeadlineLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 24)
        return label
    }

    private static func makeSectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 14)
        return label
    }

    private static func makeWrappingLabel(font: NSFont) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = font
        label.lineBreakMode = .byWordWrapping
        label.cell?.wraps = true
        label.cell?.usesSingleLineMode = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        return button
    }

    @objc private func refreshStatus(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestRefresh(self)
    }

    @objc private func chooseConfigFile(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestChooseConfigFile(self)
    }

    @objc private func revealConfigFile(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestRevealConfigFile(self)
    }

    @objc private func useLocalDefault(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestUseLocalDefault(self)
    }

    @objc private func openAccessibility(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestOpenAccessibility(self)
    }

    @objc private func openAutomation(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestOpenAutomation(self)
    }

    @objc private func editConfig(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestEditConfig(self)
    }

    @objc private func importConfig(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestImportConfig(self)
    }

    @objc private func exportConfig(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestExportConfig(self)
    }

    @objc private func copyLocalDefaultToDestination(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestCopyLocalDefaultToDestination(self)
    }

    @objc private func copyActiveToLocalDefault(_ sender: Any?) {
        settingsDelegate?.settingsWindowControllerDidRequestCopyActiveToLocalDefault(self)
    }

    @objc private func toggleShowSSHConfigHosts(_ sender: NSButton) {
        settingsDelegate?.settingsWindowControllerDidChangeShowSSHConfigHosts(self, enabled: sender.state == .on)
    }

    @objc private func openOriginalHomepage(_ sender: Any?) {
        guard let urlString = currentState?.originalHomepage,
              let url = URL(string: urlString) else {
            return
        }
        openURL(url)
    }

    @objc private func openForkHomepage(_ sender: Any?) {
        guard let urlString = currentState?.forkHomepage,
              let url = URL(string: urlString) else {
            return
        }
        openURL(url)
    }

    private func openURL(_ url: URL) {
        guard SecurityPolicies.isAllowedURL(url) else {
            NSLog("Blocked unexpected URL scheme: %@", url.absoluteString)
            return
        }

        if NSWorkspace.shared.open(url) {
            return
        }

        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-g", url.absoluteString]
            try task.run()
        } catch {
            NSLog("Failed to open URL %@: %@", url.absoluteString, error.localizedDescription)
        }
    }
}
