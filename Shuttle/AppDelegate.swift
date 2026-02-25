import Cocoa
import Carbon

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

    private var shuttleJSONPathPref = ""
    private var terminalPref = "terminal"
    private var editorPref = "default"
    private var iTermVersionPref: String?
    private var openInPref = "tab"
    private var themePref: String?

    private var menuName = ""
    private var addSeparator = false

    private var shuttleHosts = NSMutableArray()
    private var ignoreHosts = NSMutableArray()
    private var ignoreKeywords = NSMutableArray()

    private var launchAtLoginController: LaunchAtLoginController!

    override func awakeFromNib() {
        shuttleJSONPathPref = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.path")

        if FileManager.default.fileExists(atPath: shuttleJSONPathPref) {
            let jsonConfigPath = (try? String(contentsOfFile: shuttleJSONPathPref, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            shuttleConfigFile = jsonConfigPath ?? ""
        } else {
            shuttleConfigFile = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.json")
            if !FileManager.default.fileExists(atPath: shuttleConfigFile),
               let cgFileInResource = Bundle.main.path(forResource: "shuttle.default", ofType: "json") {
                try? FileManager.default.copyItem(atPath: cgFileInResource, toPath: shuttleConfigFile)
            }
        }

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
    }

    private func needUpdate(for file: String, with old: Date?) -> Bool {
        let expanded = (file as NSString).expandingTildeInPath
        if !FileManager.default.fileExists(atPath: expanded) {
            return false
        }

        guard let old else {
            return true
        }

        guard let date = getMTime(for: file) else {
            return false
        }

        return date.compare(old) == .orderedDescending
    }

    private func getMTime(for file: String) -> Date? {
        let expanded = (file as NSString).expandingTildeInPath
        let attributes = try? FileManager.default.attributesOfItem(atPath: expanded)
        return attributes?[.modificationDate] as? Date
    }

    func menuWillOpen(_ menu: NSMenu) {
        if needUpdate(for: shuttleConfigFile, with: configModified)
            || needUpdate(for: "/etc/ssh/ssh_config", with: sshConfigSystem)
            || needUpdate(for: "~/.ssh/config", with: sshConfigUser) {
            configModified = getMTime(for: shuttleConfigFile)
            sshConfigSystem = getMTime(for: "/etc/ssh_config")
            sshConfigUser = getMTime(for: "~/.ssh/config")
            loadMenu()
        }
    }

    private func parseSSHConfigFile() -> [String: NSMutableDictionary]? {
        var configFile: String?

        if FileManager.default.fileExists(atPath: "/etc/ssh_config") {
            configFile = "/etc/ssh_config"
        }

        let userConfig = ("~/.ssh/config" as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: userConfig) {
            configFile = userConfig
        }

        guard let configFile else {
            return nil
        }

        return parseSSHConfig(configFile)
    }

    private func parseSSHConfig(_ filepath: String) -> [String: NSMutableDictionary] {
        let fh = (try? String(contentsOfFile: filepath, encoding: .utf8)) ?? ""
        let pattern = "^(#?)[ \\t]*([^ \\t=]+)[ \\t=]+(.*)$"
        let rx = try? NSRegularExpression(pattern: pattern, options: [])

        var servers: [String: NSMutableDictionary] = [:]
        var key: String?

        for line in fh.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let rx,
                  let matches = rx.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: (trimmed as NSString).length)),
                  matches.numberOfRanges == 4 else {
                continue
            }

            func extract(_ index: Int) -> String {
                let range = matches.range(at: index)
                guard range.location != NSNotFound else { return "" }
                return (trimmed as NSString).substring(with: range)
            }

            let isComment = extract(1) == "#"
            let first = extract(2)
            let second = extract(3)

            if isComment, let key, first.hasPrefix("shuttle.") {
                servers[key]?[String(first.dropFirst(8))] = second
            }

            if isComment {
                continue
            }

            if first == "Include" {
                let includePath: String
                if (second as NSString).isAbsolutePath {
                    includePath = (second as NSString).expandingTildeInPath
                } else {
                    includePath = ((filepath as NSString).deletingLastPathComponent as NSString).appendingPathComponent(second)
                }
                for (k, v) in parseSSHConfig(includePath) {
                    servers[k] = v
                }
            }

            if first == "Host" {
                let hostAliases = second
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                key = hostAliases.first
                if let key {
                    servers[key] = NSMutableDictionary()
                }
            }
        }

        return servers
    }

    private func loadMenu() {
        let n = menu.items.count
        if n > 4 {
            for _ in 0..<(n - 4) {
                menu.removeItem(at: 0)
            }
        }

        guard let data = FileManager.default.contents(atPath: shuttleConfigFile),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            let menuItem = menu.insertItem(withTitle: NSLocalizedString("Error parsing config", comment: ""), action: nil, keyEquivalent: "", at: 0)
            menuItem.isEnabled = false
            return
        }

        terminalPref = normalizedTerminalPreference(json["terminal"])
        editorPref = (json["editor"] as? String)?.lowercased() ?? "default"
        iTermVersionPref = (json["iTerm_version"] as? String)?.lowercased()
        openInPref = (json["open_in"] as? String)?.lowercased() ?? "tab"
        themePref = json["default_theme"] as? String
        launchAtLoginController.launchAtLogin = (json["launch_at_login"] as? Bool) ?? false

        shuttleHosts = NSMutableArray(array: (json["hosts"] as? [Any]) ?? [])
        ignoreHosts = NSMutableArray(array: (json["ssh_config_ignore_hosts"] as? [Any]) ?? [])
        ignoreKeywords = NSMutableArray(array: (json["ssh_config_ignore_keywords"] as? [Any]) ?? [])

        var showSshConfigHosts = true
        if json.keys.contains("show_ssh_config_hosts"), (json["show_ssh_config_hosts"] as? Bool) == false {
            showSshConfigHosts = false
        }

        if showSshConfigHosts {
            let servers = parseSSHConfigFile() ?? [:]
            for (key, cfgValue) in servers {
                var skipCurrent = false
                let cfg = cfgValue

                let name = (cfg["name"] as? String) ?? key

                if name.contains("*") {
                    skipCurrent = true
                }

                if name.hasPrefix(".") {
                    skipCurrent = true
                }

                for case let ignore as String in ignoreHosts {
                    if name == ignore {
                        skipCurrent = true
                    }
                }

                for case let ignore as String in ignoreKeywords {
                    if name.range(of: ignore) != nil {
                        skipCurrent = true
                    }
                }

                if skipCurrent {
                    continue
                }

                var path = name.components(separatedBy: "/")
                guard let leaf = path.last else {
                    continue
                }
                path.removeLast()

                var itemList: NSMutableArray? = shuttleHosts

                for part in path {
                    var createList = true
                    guard let currentItemList = itemList else {
                        break
                    }

                    for case let item as NSDictionary in currentItemList {
                        if item["cmd"] != nil || item["name"] != nil {
                            continue
                        }

                        if let child = item[part] {
                            if let childArray = child as? NSMutableArray {
                                itemList = childArray
                                createList = false
                            } else if let childArray = child as? NSArray {
                                let mutableArray = NSMutableArray(array: childArray)
                                itemList = mutableArray
                                createList = false
                            } else {
                                itemList = nil
                            }
                            break
                        }
                    }

                    if itemList == nil {
                        break
                    }

                    if createList {
                        let newList = NSMutableArray()
                        itemList?.add([part: newList])
                        itemList = newList
                    }
                }

                if let itemList {
                    let cmd = "ssh \(key)"
                    itemList.add(["name": leaf, "cmd": cmd])
                }
            }
        }

        buildMenu(shuttleHosts as? [Any] ?? [], addToMenu: menu)
    }

    private func buildMenu(_ data: [Any], addToMenu m: NSMenu) {
        var menus: [String: Any] = [:]
        var leafs: [String: [String: Any]] = [:]

        for itemAny in data {
            guard let item = itemAny as? [String: Any] else {
                continue
            }

            if item["cmd"] != nil, let name = item["name"] as? String {
                leafs[name] = item
            } else {
                for (key, value) in item {
                    menus[key] = value
                }
            }
        }

        let menuKeys = menus.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        let leafKeys = leafs.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        var pos = 0

        for key in menuKeys {
            let subMenu = NSMenu()
            let menuItem = NSMenuItem()
            separatorSortRemoval(key)
            menuItem.title = menuName
            menuItem.submenu = subMenu
            m.insertItem(menuItem, at: pos)
            pos += 1
            if addSeparator {
                m.insertItem(NSMenuItem.separator(), at: pos)
                pos += 1
            }
            buildMenu(menus[key] as? [Any] ?? [], addToMenu: subMenu)
        }

        for key in leafKeys {
            guard let cfg = leafs[key] else {
                continue
            }

            let menuItem = NSMenuItem()
            let menuCmd = cfg["cmd"] as? String ?? ""
            let termTheme = cfg["theme"] as? String
            let termTitle = cfg["title"] as? String
            let termWindow = cfg["inTerminal"] as? String

            separatorSortRemoval(cfg["name"] as? String ?? "")

            let menuRepObj = "\(menuCmd)¬_¬\(jsonStringValue(termTheme))¬_¬\(jsonStringValue(termTitle))¬_¬\(jsonStringValue(termWindow))¬_¬\(menuName)"

            menuItem.title = menuName
            menuItem.representedObject = menuRepObj
            menuItem.action = #selector(openHost(_:))
            m.insertItem(menuItem, at: pos)
            pos += 1
            if addSeparator {
                m.insertItem(NSMenuItem.separator(), at: pos)
                pos += 1
            }
        }
    }

    private func separatorSortRemoval(_ currentName: String) {
        addSeparator = false

        let regexSort = try? NSRegularExpression(pattern: "([\\[][a-z]{3}[\\]])", options: [])
        let regexSeparator = try? NSRegularExpression(pattern: "([\\[][-]{3}[\\]])", options: [])

        let range = NSRange(location: 0, length: (currentName as NSString).length)
        let sortMatches = regexSort?.numberOfMatches(in: currentName, options: [], range: range) ?? 0
        let separatorMatches = regexSeparator?.numberOfMatches(in: currentName, options: [], range: range) ?? 0

        if sortMatches == 1 || separatorMatches == 1 {
            if sortMatches == 1 && separatorMatches == 1 {
                let sorted = regexSort?.stringByReplacingMatches(in: currentName, options: [], range: range, withTemplate: "") ?? currentName
                let finalRange = NSRange(location: 0, length: (sorted as NSString).length)
                menuName = regexSeparator?.stringByReplacingMatches(in: sorted, options: [], range: finalRange, withTemplate: "") ?? sorted
                addSeparator = true
            } else {
                if sortMatches == 1 {
                    menuName = regexSort?.stringByReplacingMatches(in: currentName, options: [], range: range, withTemplate: "") ?? currentName
                    addSeparator = false
                }
                if separatorMatches == 1 {
                    menuName = regexSeparator?.stringByReplacingMatches(in: currentName, options: [], range: range, withTemplate: "") ?? currentName
                    addSeparator = true
                }
            }
        } else {
            menuName = currentName
            addSeparator = false
        }
    }

    @IBAction func openHost(_ sender: NSMenuItem) {
        guard let representedObject = sender.representedObject as? String else {
            return
        }

        let objectsFromJSON = representedObject.components(separatedBy: "¬_¬")
        guard objectsFromJSON.count >= 5 else {
            return
        }

        let escapedObject = objectsFromJSON[0]

        let terminalTheme: String
        if objectsFromJSON[1] == "(null)" {
            if themePref == nil {
                if terminalPref == "iterm" || terminalPref == "warp" || terminalPref == "ghostty" {
                    terminalTheme = "Default"
                } else {
                    terminalTheme = "basic"
                }
            } else {
                terminalTheme = themePref ?? "basic"
            }
        } else {
            terminalTheme = objectsFromJSON[1]
        }

        let terminalTitle: String
        if objectsFromJSON[2] == "(null)" {
            terminalTitle = objectsFromJSON[4]
        } else {
            terminalTitle = objectsFromJSON[2]
        }

        let terminalWindow: String
        if objectsFromJSON[3] == "(null)" {
            if openInPref != "tab" && openInPref != "new" {
                openInPref = "tab"
            }
            terminalWindow = openInPref
        } else {
            terminalWindow = objectsFromJSON[3]
            if terminalWindow != "new" && terminalWindow != "current" && terminalWindow != "tab" && terminalWindow != "virtual" {
                let errorMessage = "'\(terminalWindow)' " + NSLocalizedString("is not a valid value for inTerminal. Please fix this in the JSON file", comment: "")
                let errorInfo = NSLocalizedString("bad \"inTerminal\":\"VALUE\" in the JSON settings", comment: "")
                throwError(errorMessage: errorMessage, additionalInfo: errorInfo, continueOnErrorOption: false)
            }
        }

        let iTermStableNewWindow = Bundle.main.path(forResource: "iTerm2-stable-new-window", ofType: "scpt")
        let iTermStableCurrentWindow = Bundle.main.path(forResource: "iTerm2-stable-current-window", ofType: "scpt")
        let iTermStableNewTabDefault = Bundle.main.path(forResource: "iTerm2-stable-new-tab-default", ofType: "scpt")

        let iTerm2NightlyNewWindow = Bundle.main.path(forResource: "iTerm2-nightly-new-window", ofType: "scpt")
        let iTerm2NightlyCurrentWindow = Bundle.main.path(forResource: "iTerm2-nightly-current-window", ofType: "scpt")
        let iTerm2NightlyNewTabDefault = Bundle.main.path(forResource: "iTerm2-nightly-new-tab-default", ofType: "scpt")

        let terminalNewWindow = Bundle.main.path(forResource: "terminal-new-window", ofType: "scpt")
        let terminalCurrentWindow = Bundle.main.path(forResource: "terminal-current-window", ofType: "scpt")
        let terminalNewTabDefault = Bundle.main.path(forResource: "terminal-new-tab-default", ofType: "scpt")
        let terminalVirtualWithScreen = Bundle.main.path(forResource: "virtual-with-screen", ofType: "scpt")

        let handlerName = "scriptRun"

        let passParameters: [String]
        let url: URL?
        if terminalWindow != "virtual" {
            passParameters = [escapedObject, terminalTheme, terminalTitle]
            url = URL(string: escapedObject)
        } else {
            passParameters = [escapedObject, terminalTitle]
            url = nil
        }

        if let url {
            NSWorkspace.shared.open(url)
        } else if terminalPref == "iterm" {
            if iTermVersionPref != "stable" && iTermVersionPref != "nightly" {
                if iTermVersionPref == nil {
                    let errorMessage = NSLocalizedString("\"iTerm_version\": \"VALUE\", is missing.\n\n\"VALUE\" can be:\n\"stable\" targeting new versions.\n\"nightly\" targeting nightly builds.\n\nPlease fix your shuttle JSON settings.\nSee readme.md on shuttle's github for help.", comment: "")
                    let errorInfo = NSLocalizedString("Press Continue to try iTerm stable applescripts.\n              -->(not recommended)<--\nThis could fail if you have another version of iTerm installed.\n\nPlease fix the JSON settings.\nPress Quit to exit shuttle.", comment: "")
                    throwError(errorMessage: errorMessage, additionalInfo: errorInfo, continueOnErrorOption: true)
                    iTermVersionPref = "stable"
                } else {
                    let errorMessage = "'\(iTermVersionPref ?? "")' " + NSLocalizedString("is not a valid value for iTerm_version. Please fix this in the JSON file", comment: "")
                    let errorInfo = NSLocalizedString("bad \"iTerm_version\": \"VALUE\" in the JSON settings", comment: "")
                    throwError(errorMessage: errorMessage, additionalInfo: errorInfo, continueOnErrorOption: false)
                }
            }

            if iTermVersionPref == "stable" {
                if terminalWindow == "new" {
                    runScript(scriptPath: iTermStableNewWindow, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "current" {
                    runScript(scriptPath: iTermStableCurrentWindow, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "tab" {
                    runScript(scriptPath: iTermStableNewTabDefault, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "virtual" {
                    runScript(scriptPath: terminalVirtualWithScreen, handler: handlerName, parameters: passParameters)
                }
            }

            if iTermVersionPref == "nightly" {
                if terminalWindow == "new" {
                    runScript(scriptPath: iTerm2NightlyNewWindow, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "current" {
                    runScript(scriptPath: iTerm2NightlyCurrentWindow, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "tab" {
                    runScript(scriptPath: iTerm2NightlyNewTabDefault, handler: handlerName, parameters: passParameters)
                }
                if terminalWindow == "virtual" {
                    runScript(scriptPath: terminalVirtualWithScreen, handler: handlerName, parameters: passParameters)
                }
            }
        } else if terminalPref == "warp" {
            if terminalWindow == "virtual" {
                runScript(scriptPath: terminalVirtualWithScreen, handler: handlerName, parameters: passParameters)
            } else {
                runCommandInUIControlledTerminal(terminalName: "Warp", command: escapedObject, terminalWindow: terminalWindow)
            }
        } else if terminalPref == "ghostty" {
            if terminalWindow == "virtual" {
                runScript(scriptPath: terminalVirtualWithScreen, handler: handlerName, parameters: passParameters)
            } else {
                runCommandInGhostty(command: escapedObject)
            }
        } else {
            if terminalWindow == "new" {
                runScript(scriptPath: terminalNewWindow, handler: handlerName, parameters: passParameters)
            }
            if terminalWindow == "current" {
                runScript(scriptPath: terminalCurrentWindow, handler: handlerName, parameters: passParameters)
            }
            if terminalWindow == "tab" {
                runScript(scriptPath: terminalNewTabDefault, handler: handlerName, parameters: passParameters)
            }
            if terminalWindow == "virtual" {
                runScript(scriptPath: terminalVirtualWithScreen, handler: handlerName, parameters: passParameters)
            }
        }
    }

    private func runScript(scriptPath: String?, handler handlerName: String, parameters parametersInArray: [String]) {
        guard let scriptPath else {
            return
        }

        let pathURL = URL(fileURLWithPath: scriptPath)
        var appleScriptCreationError: NSDictionary?
        guard let appleScript = NSAppleScript(contentsOf: pathURL, error: &appleScriptCreationError) else {
            return
        }

        if !handlerName.isEmpty {
            var pid = ProcessInfo.processInfo.processIdentifier
            guard let thisApplication = NSAppleEventDescriptor(
                descriptorType: typeKernelProcessID,
                bytes: &pid,
                length: MemoryLayout.size(ofValue: pid)
            ) else {
                return
            }

            let kASAppleScriptSuite = fourCharCode(from: "ascr")
            let kASSubroutineEvent = fourCharCode(from: "psbr")
            let keyASSubroutineName = fourCharCode(from: "snam")

            let containerEvent = NSAppleEventDescriptor.appleEvent(
                withEventClass: AEEventClass(kASAppleScriptSuite),
                eventID: AEEventID(kASSubroutineEvent),
                targetDescriptor: thisApplication,
                returnID: AEReturnID(kAutoGenerateReturnID),
                transactionID: AETransactionID(kAnyTransactionID)
            )

            containerEvent.setParam(NSAppleEventDescriptor(string: handlerName), forKeyword: AEKeyword(keyASSubroutineName))

            if !parametersInArray.isEmpty {
                let arguments = NSAppleEventDescriptor(listDescriptor: ())
                for object in parametersInArray {
                    arguments.insert(NSAppleEventDescriptor(string: object), at: arguments.numberOfItems + 1)
                }
                containerEvent.setParam(arguments, forKeyword: keyDirectObject)
            }

            _ = appleScript.executeAppleEvent(containerEvent, error: nil)
        }
    }

    @IBAction func showImportPanel(_ sender: Any?) {
        let openPanelObj = NSOpenPanel()
        let result = openPanelObj.runModal()
        if result == .OK, let selectedFileUrl = openPanelObj.url {
            let backupPath = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.json.backup")
            try? FileManager.default.moveItem(atPath: shuttleConfigFile, toPath: backupPath)
            try? FileManager.default.copyItem(atPath: selectedFileUrl.path, toPath: shuttleConfigFile)
            try? FileManager.default.removeItem(atPath: backupPath)
        }
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

    private func normalizedTerminalPreference(_ terminalValue: Any?) -> String {
        guard let terminalValue = terminalValue as? String else {
            return "terminal"
        }

        let normalizedTerminal = terminalValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedTerminal.contains("iterm") {
            return "iterm"
        }
        if normalizedTerminal.contains("warp") {
            return "warp"
        }
        if normalizedTerminal.contains("ghostty") {
            return "ghostty"
        }
        if normalizedTerminal.contains("terminal") {
            return "terminal"
        }

        return "terminal"
    }

    private func appleScriptEscapedString(_ value: String?) -> String {
        guard let value else {
            return ""
        }

        var escapedValue = value.replacingOccurrences(of: "\\", with: "\\\\")
        escapedValue = escapedValue.replacingOccurrences(of: "\"", with: "\\\"")
        escapedValue = escapedValue.replacingOccurrences(of: "\n", with: "\\n")

        return escapedValue
    }

    private func runCommandInUIControlledTerminal(terminalName: String, command: String, terminalWindow: String) {
        let escapedCommand = appleScriptEscapedString(command)
        let escapedTerminalName = appleScriptEscapedString(terminalName)
        let escapedTerminalWindow = appleScriptEscapedString(terminalWindow)

        let scriptSource = """
        set wasRunning to application "\(escapedTerminalName)" is running
        tell application "\(escapedTerminalName)" to activate
        delay 0.2
        tell application "System Events"
            tell process "\(escapedTerminalName)"
                if "\(escapedTerminalWindow)" is "new" then
                    keystroke "n" using {command down}
                    delay 0.1
                else if "\(escapedTerminalWindow)" is "tab" then
                    if wasRunning then
                        keystroke "t" using {command down}
                        delay 0.1
                    end if
                end if
                keystroke "\(escapedCommand)"
                key code 36
            end tell
        end tell
        """

        var scriptError: NSDictionary?
        let appleScript = NSAppleScript(source: scriptSource)
        _ = appleScript?.executeAndReturnError(&scriptError)

        if scriptError != nil {
            let errorMessage = "Unable to run command in \(terminalName)."
            let errorInfo = (scriptError?[NSAppleScript.errorMessage] as? String)
                ?? NSLocalizedString("Please verify macOS automation/accessibility permissions for the selected terminal.", comment: "")
            throwError(errorMessage: errorMessage, additionalInfo: errorInfo, continueOnErrorOption: false)
        }
    }

    private func runCommandInGhostty(command: String) {
        do {
            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = ["-na", "Ghostty.app", "--args", "-e", command]
            try openTask.run()
        } catch {
            throwError(
                errorMessage: "Unable to launch Ghostty.",
                additionalInfo: error.localizedDescription,
                continueOnErrorOption: false
            )
        }
    }

    private func jsonStringValue(_ value: String?) -> String {
        value ?? "(null)"
    }

    private func fourCharCode(from string: String) -> OSType {
        var result: UInt32 = 0
        for scalar in string.unicodeScalars {
            result = (result << 8) + scalar.value
        }
        return result
    }
}
