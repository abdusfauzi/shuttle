import Cocoa
import Carbon

struct ShuttleConfigSnapshot {
    let terminalPref: String
    let editorPref: String
    let iTermVersionPref: String?
    let openInPref: String
    let themePref: String?
    let launchAtLogin: Bool
    let showSSHConfigHosts: Bool
    let hosts: [Any]
    let ignoreHosts: [String]
    let ignoreKeywords: [String]
}

final class ConfigService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolveShuttleConfigFile() -> String {
        let shuttleJSONPathPref = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.path")

        if fileManager.fileExists(atPath: shuttleJSONPathPref) {
            let jsonConfigPath = (try? String(contentsOfFile: shuttleJSONPathPref, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return jsonConfigPath ?? ""
        }

        let shuttleConfigFile = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.json")
        if !fileManager.fileExists(atPath: shuttleConfigFile),
           let configFileInResource = Bundle.main.path(forResource: "shuttle.default", ofType: "json") {
            try? fileManager.copyItem(atPath: configFileInResource, toPath: shuttleConfigFile)
        }

        return shuttleConfigFile
    }

    func needsUpdate(file: String, old: Date?) -> Bool {
        let expanded = (file as NSString).expandingTildeInPath
        if !fileManager.fileExists(atPath: expanded) {
            return false
        }

        guard let old else {
            return true
        }

        guard let date = modificationDate(file: file) else {
            return false
        }

        return date.compare(old) == .orderedDescending
    }

    func modificationDate(file: String) -> Date? {
        let expanded = (file as NSString).expandingTildeInPath
        let attributes = try? fileManager.attributesOfItem(atPath: expanded)
        return attributes?[.modificationDate] as? Date
    }

    func loadConfigSnapshot(from shuttleConfigFile: String) -> ShuttleConfigSnapshot? {
        guard let data = fileManager.contents(atPath: shuttleConfigFile),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            return nil
        }

        let terminalPref = normalizedTerminalPreference(json["terminal"])
        let editorPref = (json["editor"] as? String)?.lowercased() ?? "default"
        let iTermVersionPref = (json["iTerm_version"] as? String)?.lowercased()
        let openInPref = (json["open_in"] as? String)?.lowercased() ?? "tab"
        let themePref = json["default_theme"] as? String
        let launchAtLogin = (json["launch_at_login"] as? Bool) ?? false

        let hosts = (json["hosts"] as? [Any]) ?? []
        let ignoreHosts = ((json["ssh_config_ignore_hosts"] as? [Any]) ?? []).compactMap { $0 as? String }
        let ignoreKeywords = ((json["ssh_config_ignore_keywords"] as? [Any]) ?? []).compactMap { $0 as? String }
        let showSSHConfigHosts = (json["show_ssh_config_hosts"] as? Bool) ?? true

        return ShuttleConfigSnapshot(
            terminalPref: terminalPref,
            editorPref: editorPref,
            iTermVersionPref: iTermVersionPref,
            openInPref: openInPref,
            themePref: themePref,
            launchAtLogin: launchAtLogin,
            showSSHConfigHosts: showSSHConfigHosts,
            hosts: hosts,
            ignoreHosts: ignoreHosts,
            ignoreKeywords: ignoreKeywords
        )
    }

    func mergeSSHHosts(
        into hosts: inout [Any],
        servers: [String: [String: String]],
        ignoreHosts: [String],
        ignoreKeywords: [String]
    ) {
        let shuttleHosts = NSMutableArray(array: hosts)

        for (key, cfg) in servers {
            let name = cfg["name"] ?? key
            if shouldSkipHost(name: name, ignoreHosts: ignoreHosts, ignoreKeywords: ignoreKeywords) {
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
                itemList.add(["name": leaf, "cmd": "ssh \(key)"])
            }
        }

        hosts = shuttleHosts as? [Any] ?? []
    }

    private func shouldSkipHost(name: String, ignoreHosts: [String], ignoreKeywords: [String]) -> Bool {
        if name.contains("*") { return true }
        if name.hasPrefix(".") { return true }
        if ignoreHosts.contains(name) { return true }

        for keyword in ignoreKeywords where name.range(of: keyword) != nil {
            return true
        }

        return false
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
}

final class SSHConfigParser {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func parsePreferredConfig() -> [String: [String: String]] {
        var configFile: String?

        if fileManager.fileExists(atPath: "/etc/ssh_config") {
            configFile = "/etc/ssh_config"
        }

        let userConfig = ("~/.ssh/config" as NSString).expandingTildeInPath
        if fileManager.fileExists(atPath: userConfig) {
            configFile = userConfig
        }

        guard let configFile else {
            return [:]
        }

        return parse(filepath: configFile)
    }

    private func parse(filepath: String) -> [String: [String: String]] {
        let fileContents = (try? String(contentsOfFile: filepath, encoding: .utf8)) ?? ""
        let pattern = "^(#?)[ \\t]*([^ \\t=]+)[ \\t=]+(.*)$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        var servers: [String: [String: String]] = [:]
        var key: String?

        for line in fileContents.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let regex,
                  let matches = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: (trimmed as NSString).length)),
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
                var hostConfig = servers[key] ?? [:]
                hostConfig[String(first.dropFirst(8))] = second
                servers[key] = hostConfig
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

                for (includeKey, includeValue) in parse(filepath: includePath) {
                    servers[includeKey] = includeValue
                }
            }

            if first == "Host" {
                let hostAliases = second
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                key = hostAliases.first
                if let key {
                    servers[key] = [:]
                }
            }
        }

        return servers
    }
}

final class MenuBuilder {
    private var menuName = ""
    private var addSeparator = false

    func clearDynamicItems(in menu: NSMenu, preservingLast staticCount: Int = 4) {
        let count = menu.items.count
        if count > staticCount {
            for _ in 0..<(count - staticCount) {
                menu.removeItem(at: 0)
            }
        }
    }

    func buildMenu(_ data: [Any], addToMenu menu: NSMenu, target: AnyObject, action: Selector) {
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

        var position = 0

        for key in menuKeys {
            let subMenu = NSMenu()
            let menuItem = NSMenuItem()
            separatorSortRemoval(key)
            menuItem.title = menuName
            menuItem.submenu = subMenu
            menu.insertItem(menuItem, at: position)
            position += 1

            if addSeparator {
                menu.insertItem(NSMenuItem.separator(), at: position)
                position += 1
            }

            buildMenu(menus[key] as? [Any] ?? [], addToMenu: subMenu, target: target, action: action)
        }

        for key in leafKeys {
            guard let config = leafs[key] else {
                continue
            }

            let menuItem = NSMenuItem()
            let menuCommand = config["cmd"] as? String ?? ""
            let termTheme = config["theme"] as? String
            let termTitle = config["title"] as? String
            let termWindow = config["inTerminal"] as? String

            separatorSortRemoval(config["name"] as? String ?? "")

            let menuRepObj = "\(menuCommand)¬_¬\(jsonStringValue(termTheme))¬_¬\(jsonStringValue(termTitle))¬_¬\(jsonStringValue(termWindow))¬_¬\(menuName)"

            menuItem.title = menuName
            menuItem.representedObject = menuRepObj
            menuItem.target = target
            menuItem.action = action

            menu.insertItem(menuItem, at: position)
            position += 1

            if addSeparator {
                menu.insertItem(NSMenuItem.separator(), at: position)
                position += 1
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

    private func jsonStringValue(_ value: String?) -> String {
        value ?? "(null)"
    }
}

final class TerminalRouter {
    typealias ErrorHandler = (String, String, Bool) -> Void

    private enum TerminalPreference: String {
        case terminal
        case iterm
        case warp
        case ghostty
    }

    private enum OpenMode: String {
        case new
        case current
        case tab
        case virtual
    }

    private struct MenuCommand {
        let command: String
        let commandTheme: String
        let commandTitle: String
        let commandWindow: String
        let menuFallbackTitle: String

        init?(representedObject: String) {
            let parts = representedObject.components(separatedBy: "¬_¬")
            guard parts.count >= 5 else {
                return nil
            }

            command = parts[0]
            commandTheme = parts[1]
            commandTitle = parts[2]
            commandWindow = parts[3]
            menuFallbackTitle = parts[4]
        }
    }

    private struct TerminalLaunchRequest {
        let command: String
        let theme: String
        let title: String
        let mode: OpenMode

        var scriptParameters: [String] {
            if mode == .virtual {
                return [command, title]
            }
            return [command, theme, title]
        }

        var launchURL: URL? {
            if mode == .virtual {
                return nil
            }
            return URL(string: command)
        }
    }

    private struct ScriptCatalog {
        let iTermStableNewWindow: String?
        let iTermStableCurrentWindow: String?
        let iTermStableNewTabDefault: String?

        let iTermNightlyNewWindow: String?
        let iTermNightlyCurrentWindow: String?
        let iTermNightlyNewTabDefault: String?

        let terminalNewWindow: String?
        let terminalCurrentWindow: String?
        let terminalNewTabDefault: String?
        let terminalVirtualWithScreen: String?

        init(bundle: Bundle = .main) {
            iTermStableNewWindow = bundle.path(forResource: "iTerm2-stable-new-window", ofType: "scpt")
            iTermStableCurrentWindow = bundle.path(forResource: "iTerm2-stable-current-window", ofType: "scpt")
            iTermStableNewTabDefault = bundle.path(forResource: "iTerm2-stable-new-tab-default", ofType: "scpt")

            iTermNightlyNewWindow = bundle.path(forResource: "iTerm2-nightly-new-window", ofType: "scpt")
            iTermNightlyCurrentWindow = bundle.path(forResource: "iTerm2-nightly-current-window", ofType: "scpt")
            iTermNightlyNewTabDefault = bundle.path(forResource: "iTerm2-nightly-new-tab-default", ofType: "scpt")

            terminalNewWindow = bundle.path(forResource: "terminal-new-window", ofType: "scpt")
            terminalCurrentWindow = bundle.path(forResource: "terminal-current-window", ofType: "scpt")
            terminalNewTabDefault = bundle.path(forResource: "terminal-new-tab-default", ofType: "scpt")
            terminalVirtualWithScreen = bundle.path(forResource: "virtual-with-screen", ofType: "scpt")
        }

        func terminalScript(for mode: OpenMode) -> String? {
            switch mode {
            case .new:
                return terminalNewWindow
            case .current:
                return terminalCurrentWindow
            case .tab:
                return terminalNewTabDefault
            case .virtual:
                return terminalVirtualWithScreen
            }
        }

        func iTermScript(version: String, mode: OpenMode) -> String? {
            if mode == .virtual {
                return terminalVirtualWithScreen
            }

            if version == "nightly" {
                switch mode {
                case .new:
                    return iTermNightlyNewWindow
                case .current:
                    return iTermNightlyCurrentWindow
                case .tab:
                    return iTermNightlyNewTabDefault
                case .virtual:
                    return terminalVirtualWithScreen
                }
            }

            switch mode {
            case .new:
                return iTermStableNewWindow
            case .current:
                return iTermStableCurrentWindow
            case .tab:
                return iTermStableNewTabDefault
            case .virtual:
                return terminalVirtualWithScreen
            }
        }
    }

    private struct ExecutionServices {
        let scripts: ScriptCatalog
        let handlerName: String
        let runScript: (_ scriptPath: String?, _ handlerName: String, _ parameters: [String]) -> Void
        let runUIControlledTerminal: (_ terminalName: String, _ command: String, _ terminalWindow: String, _ errorHandler: ErrorHandler) -> Void
        let runGhostty: (_ command: String, _ errorHandler: ErrorHandler) -> Void
    }

    private struct DispatchResult {
        let updatedITermVersionPref: String?
    }

    private protocol TerminalBackend {
        func dispatch(request: TerminalLaunchRequest, services: ExecutionServices, errorHandler: ErrorHandler) -> DispatchResult?
    }

    private struct TerminalAppBackend: TerminalBackend {
        func dispatch(request: TerminalLaunchRequest, services: ExecutionServices, errorHandler: ErrorHandler) -> DispatchResult? {
            let scriptPath = services.scripts.terminalScript(for: request.mode)
            services.runScript(scriptPath, services.handlerName, request.scriptParameters)
            return nil
        }
    }

    private struct WarpBackend: TerminalBackend {
        func dispatch(request: TerminalLaunchRequest, services: ExecutionServices, errorHandler: ErrorHandler) -> DispatchResult? {
            if request.mode == .virtual {
                services.runScript(services.scripts.terminalVirtualWithScreen, services.handlerName, request.scriptParameters)
            } else {
                services.runUIControlledTerminal("Warp", request.command, request.mode.rawValue, errorHandler)
            }
            return nil
        }
    }

    private struct GhosttyBackend: TerminalBackend {
        func dispatch(request: TerminalLaunchRequest, services: ExecutionServices, errorHandler: ErrorHandler) -> DispatchResult? {
            if request.mode == .virtual {
                services.runScript(services.scripts.terminalVirtualWithScreen, services.handlerName, request.scriptParameters)
            } else {
                services.runGhostty(request.command, errorHandler)
            }
            return nil
        }
    }

    private struct ITermBackend: TerminalBackend {
        let preferredVersion: String?

        func dispatch(request: TerminalLaunchRequest, services: ExecutionServices, errorHandler: ErrorHandler) -> DispatchResult? {
            var resolvedVersion = preferredVersion

            if resolvedVersion != "stable" && resolvedVersion != "nightly" {
                if resolvedVersion == nil {
                    let errorMessage = NSLocalizedString("\"iTerm_version\": \"VALUE\", is missing.\n\n\"VALUE\" can be:\n\"stable\" targeting new versions.\n\"nightly\" targeting nightly builds.\n\nPlease fix your shuttle JSON settings.\nSee readme.md on shuttle's github for help.", comment: "")
                    let errorInfo = NSLocalizedString("Press Continue to try iTerm stable applescripts.\n              -->(not recommended)<--\nThis could fail if you have another version of iTerm installed.\n\nPlease fix the JSON settings.\nPress Quit to exit shuttle.", comment: "")
                    errorHandler(errorMessage, errorInfo, true)
                    resolvedVersion = "stable"
                } else {
                    let errorMessage = "'\(resolvedVersion ?? "")' " + NSLocalizedString("is not a valid value for iTerm_version. Please fix this in the JSON file", comment: "")
                    let errorInfo = NSLocalizedString("bad \"iTerm_version\": \"VALUE\" in the JSON settings", comment: "")
                    errorHandler(errorMessage, errorInfo, false)
                    return nil
                }
            }

            guard let resolvedVersion else {
                return nil
            }

            let scriptPath = services.scripts.iTermScript(version: resolvedVersion, mode: request.mode)
            services.runScript(scriptPath, services.handlerName, request.scriptParameters)

            return DispatchResult(updatedITermVersionPref: resolvedVersion)
        }
    }

    private var terminalPref = "terminal"
    private(set) var currentITermVersionPref: String?
    private var openInPref = "tab"
    private var themePref: String?

    func updatePreferences(terminalPref: String, iTermVersionPref: String?, openInPref: String, themePref: String?) {
        self.terminalPref = terminalPref
        currentITermVersionPref = iTermVersionPref
        self.openInPref = openInPref
        self.themePref = themePref
    }

    func openHost(_ representedObject: String, errorHandler: @escaping ErrorHandler) {
        guard let menuCommand = MenuCommand(representedObject: representedObject) else {
            return
        }

        guard let openMode = resolvedOpenMode(commandWindow: menuCommand.commandWindow, errorHandler: errorHandler) else {
            return
        }

        let launchRequest = TerminalLaunchRequest(
            command: menuCommand.command,
            theme: resolvedTheme(commandTheme: menuCommand.commandTheme),
            title: resolvedTitle(commandTitle: menuCommand.commandTitle, menuFallbackTitle: menuCommand.menuFallbackTitle),
            mode: openMode
        )

        if let url = launchRequest.launchURL {
            NSWorkspace.shared.open(url)
            return
        }

        let services = makeExecutionServices()
        let backend = makeBackend(terminalPreference: terminalPreference(), iTermVersionPref: currentITermVersionPref)
        let result = backend.dispatch(request: launchRequest, services: services, errorHandler: errorHandler)
        if let updatedVersion = result?.updatedITermVersionPref {
            currentITermVersionPref = updatedVersion
        }
    }

    private func terminalPreference() -> TerminalPreference {
        TerminalPreference(rawValue: terminalPref) ?? .terminal
    }

    private func resolvedTheme(commandTheme: String) -> String {
        if commandTheme != "(null)" {
            return commandTheme
        }

        if let themePref {
            return themePref
        }

        switch terminalPreference() {
        case .iterm, .warp, .ghostty:
            return "Default"
        case .terminal:
            return "basic"
        }
    }

    private func resolvedTitle(commandTitle: String, menuFallbackTitle: String) -> String {
        if commandTitle == "(null)" {
            return menuFallbackTitle
        }
        return commandTitle
    }

    private func resolvedOpenMode(commandWindow: String, errorHandler: ErrorHandler) -> OpenMode? {
        if commandWindow == "(null)" {
            let normalizedOpenIn = (openInPref == "new" || openInPref == "tab") ? openInPref : "tab"
            return OpenMode(rawValue: normalizedOpenIn) ?? .tab
        }

        if let openMode = OpenMode(rawValue: commandWindow) {
            return openMode
        }

        let errorMessage = "'\(commandWindow)' " + NSLocalizedString("is not a valid value for inTerminal. Please fix this in the JSON file", comment: "")
        let errorInfo = NSLocalizedString("bad \"inTerminal\":\"VALUE\" in the JSON settings", comment: "")
        errorHandler(errorMessage, errorInfo, false)
        return nil
    }

    private func makeBackend(terminalPreference: TerminalPreference, iTermVersionPref: String?) -> TerminalBackend {
        switch terminalPreference {
        case .iterm:
            return ITermBackend(preferredVersion: iTermVersionPref)
        case .warp:
            return WarpBackend()
        case .ghostty:
            return GhosttyBackend()
        case .terminal:
            return TerminalAppBackend()
        }
    }

    private func makeExecutionServices() -> ExecutionServices {
        let scripts = ScriptCatalog()
        return ExecutionServices(
            scripts: scripts,
            handlerName: "scriptRun",
            runScript: { [weak self] scriptPath, handlerName, parameters in
                self?.runScript(scriptPath: scriptPath, handler: handlerName, parameters: parameters)
            },
            runUIControlledTerminal: { [weak self] terminalName, command, terminalWindow, errorHandler in
                self?.runCommandInUIControlledTerminal(
                    terminalName: terminalName,
                    command: command,
                    terminalWindow: terminalWindow,
                    errorHandler: errorHandler
                )
            },
            runGhostty: { [weak self] command, errorHandler in
                self?.runCommandInGhostty(command: command, errorHandler: errorHandler)
            }
        )
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

    private func runCommandInUIControlledTerminal(
        terminalName: String,
        command: String,
        terminalWindow: String,
        errorHandler: (String, String, Bool) -> Void
    ) {
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
            errorHandler(errorMessage, errorInfo, false)
        }
    }

    private func runCommandInGhostty(command: String, errorHandler: (String, String, Bool) -> Void) {
        do {
            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = ["-na", "Ghostty.app", "--args", "-e", command]
            try openTask.run()
        } catch {
            errorHandler("Unable to launch Ghostty.", error.localizedDescription, false)
        }
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

    private func fourCharCode(from string: String) -> OSType {
        var result: UInt32 = 0
        for scalar in string.unicodeScalars {
            result = (result << 8) + scalar.value
        }
        return result
    }
}
