import Cocoa
import Carbon

enum SecurityPolicies {
    static let allowedBrowserSchemes: Set<String> = ["http", "https", "mailto"]
    static let allowedSystemSchemes: Set<String> = ["x-apple.systempreferences"]
    static let allowedOpenModes: Set<String> = ["new", "current", "tab", "virtual"]
    static let maxCommandLength = 8192
    static let maxHostAliasLength = 256

    static func sanitizeOpenMode(_ candidate: String?) -> String {
        let normalized = (candidate ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return allowedOpenModes.contains(normalized) ? normalized : "tab"
    }

    static func isSafeCommand(_ command: String) -> Bool {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.utf8.count <= maxCommandLength else {
            return false
        }
        return trimmed.unicodeScalars.allSatisfy { scalar in
            scalar.value > 0 && scalar.value != 0x7f && !CharacterSet.controlCharacters.contains(scalar)
        }
    }

    static func shellSingleQuote(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }

    static func isSafeHostAlias(_ alias: String) -> Bool {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.utf8.count <= maxHostAliasLength else {
            return false
        }
        return trimmed.unicodeScalars.allSatisfy { scalar in
            scalar.value > 0 && scalar.value != 0x7f && !CharacterSet.controlCharacters.contains(scalar)
        }
    }

    static func isAllowedURL(_ url: URL?, allowSystemSchemes: Bool = false) -> Bool {
        guard let url else {
            return false
        }

        guard let scheme = url.scheme?.lowercased(),
              !scheme.isEmpty else {
            return false
        }

        if allowedBrowserSchemes.contains(scheme) {
            return true
        }

        return allowSystemSchemes && allowedSystemSchemes.contains(scheme)
    }
}

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
    private let maxConfigPathLength = 1024
    private let maxConfigFileBytes = 5 * 1024 * 1024

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolveShuttleConfigFile() -> String {
        let shuttleJSONPathPref = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.path")

        if fileManager.fileExists(atPath: shuttleJSONPathPref) {
            let jsonConfigPath = (try? String(contentsOfFile: shuttleJSONPathPref, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let path = validatedConfigPath(jsonConfigPath) {
                return path
            }
        }

        let shuttleConfigFile = (NSHomeDirectory() as NSString).appendingPathComponent(".shuttle.json")
        if !fileManager.fileExists(atPath: shuttleConfigFile),
           let configFileInResource = Bundle.main.path(forResource: "shuttle.default", ofType: "json") {
            try? fileManager.copyItem(atPath: configFileInResource, toPath: shuttleConfigFile)
        }

        return shuttleConfigFile
    }

    private func validatedConfigPath(_ candidate: String?) -> String? {
        guard let candidate, !candidate.isEmpty else {
            return nil
        }

        guard candidate.count <= maxConfigPathLength else {
            NSLog("Ignoring .shuttle.path: candidate exceeds max length.")
            return nil
        }

        let expanded = (candidate as NSString).expandingTildeInPath
        let standardized = (expanded as NSString).standardizingPath

        guard !standardized.isEmpty && standardized != "/" else {
            NSLog("Ignoring .shuttle.path: unsafe path value.")
            return nil
        }

        guard standardized.count <= maxConfigPathLength else {
            NSLog("Ignoring .shuttle.path: normalized path exceeds max length.")
            return nil
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: standardized, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            NSLog("Ignoring .shuttle.path: path is not a regular file.")
            return nil
        }

        guard fileManager.isReadableFile(atPath: standardized) else {
            NSLog("Ignoring .shuttle.path: path is not readable.")
            return nil
        }

        return standardized
    }

    private func validateReadableRegularFile(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              fileManager.isReadableFile(atPath: path) else {
            return false
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let size = attributes[.size] as? NSNumber,
              size.intValue <= maxConfigFileBytes else {
            return false
        }

        return true
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
        let expandedPath = (shuttleConfigFile as NSString).expandingTildeInPath
        guard validateReadableRegularFile(at: expandedPath) else {
            return nil
        }

        let attributes = try? fileManager.attributesOfItem(atPath: expandedPath)
        let size = attributes?[.size] as? NSNumber
        guard size == nil || size?.intValue ?? 0 <= maxConfigFileBytes else {
            return nil
        }

        guard let data = fileManager.contents(atPath: expandedPath),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
            return nil
        }

        let terminalPref = normalizedTerminalPreference(json["terminal"])
        let editorPref = (json["editor"] as? String)?.lowercased() ?? "default"
        let iTermVersionPref = (json["iTerm_version"] as? String)?.lowercased()
        let sanitizedOpenIn = SecurityPolicies.sanitizeOpenMode((json["open_in"] as? String))
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
            openInPref: sanitizedOpenIn,
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
                guard let command = commandForSSHHost(key: key) else {
                    continue
                }
                itemList.add(["name": leaf, "cmd": command])
            }
        }

        hosts = shuttleHosts as? [Any] ?? []
    }

    private func commandForSSHHost(key: String) -> String? {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SecurityPolicies.isSafeHostAlias(trimmedKey) else {
            return nil
        }
        return "ssh \(SecurityPolicies.shellSingleQuote(trimmedKey))"
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
    private let maxIncludeDepth = 16
    private let maxIncludeBytes = 2 * 1024 * 1024
    private let maxLineLength = 2048
    private let wildcardCharacters: Set<Character> = ["*", "?", "["]

    private static let lineRegex: NSRegularExpression = {
        let pattern = "^(#?)[ \\t]*([^ \\t=]+)[ \\t=]+(.*)$"
        return (try? NSRegularExpression(pattern: pattern, options: []))
            ?? (try! NSRegularExpression(pattern: ".*", options: []))
    }()

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

        var visited = Set<String>()
        return parse(filepath: configFile, depth: 0, visited: &visited)
    }

    private func parse(filepath: String, depth: Int, visited: inout Set<String>) -> [String: [String: String]] {
        guard depth < maxIncludeDepth else {
            NSLog("Ignoring ssh include depth over \(maxIncludeDepth) at \(filepath)")
            return [:]
        }

        let expanded = (filepath as NSString).expandingTildeInPath
        let normalizedPath = (expanded as NSString).standardizingPath
        guard validateRegularReadableFile(path: normalizedPath) else {
            return [:]
        }

        guard visited.insert(normalizedPath).inserted else {
            NSLog("Ignoring cyclic ssh include path: \(normalizedPath)")
            return [:]
        }

        guard let includeFileSize = fileSize(at: normalizedPath), includeFileSize <= maxIncludeBytes else {
            NSLog("Ignoring oversized ssh include file at \(normalizedPath)")
            return [:]
        }

        guard let fileContents = (try? String(contentsOfFile: normalizedPath, encoding: .utf8)) else {
            return [:]
        }

        var servers: [String: [String: String]] = [:]
        var key: String?

        for line in fileContents.split(whereSeparator: \.isNewline) {
            if line.utf8.count > maxLineLength {
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let matches = Self.lineRegex.firstMatch(
                in: trimmed,
                options: [],
                range: NSRange(location: 0, length: (trimmed as NSString).length)),
                  matches.numberOfRanges == 4 else {
                continue
            }

            func extract(_ index: Int) -> String {
                let range = matches.range(at: index)
                guard range.location != NSNotFound else { return "" }
                return (trimmed as NSString).substring(with: range)
            }

            let isComment = extract(1) == "#"
            let first = extract(2).lowercased()
            let second = extract(3).trimmingCharacters(in: .whitespacesAndNewlines)

            if isComment, let key, first.hasPrefix("shuttle.") {
                var hostConfig = servers[key] ?? [:]
                hostConfig[String(first.dropFirst(8))] = second
                servers[key] = hostConfig
            }

            if isComment {
                continue
            }

            if first == "include" {
                let includeBaseDirectory = (normalizedPath as NSString).deletingLastPathComponent
                let includeExpressions = second.split(whereSeparator: { $0 == " " || $0 == "\t" })
                for expression in includeExpressions {
                    for includePath in expandedIncludePaths(String(expression), baseDirectory: includeBaseDirectory) {
                        for (includeKey, includeValue) in parse(filepath: includePath, depth: depth + 1, visited: &visited) {
                            servers[includeKey] = includeValue
                        }
                    }
                }
            }

            if first == "host" {
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

    private func fileSize(at path: String) -> Int? {
        let attributes = try? fileManager.attributesOfItem(atPath: path)
        return (attributes?[.size] as? NSNumber)?.intValue
    }

    private func validateRegularReadableFile(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              fileManager.isReadableFile(atPath: path) else {
            return false
        }

        return true
    }

    private func expandedIncludePaths(_ include: String, baseDirectory: String) -> [String] {
        guard !include.isEmpty else {
            return []
        }

        let expanded = (include as NSString).expandingTildeInPath
        let resolved = (expanded as NSString).isAbsolutePath ?
            expanded :
            ((baseDirectory as NSString).appendingPathComponent(expanded) as String)
        let normalized = (resolved as NSString).standardizingPath

        if containsWildcard(normalized) {
            return wildcardIncludeMatches(patternPath: normalized)
        }

        guard validateRegularReadableFile(path: normalized) else {
            return []
        }

        return [normalized]
    }

    private func containsWildcard(_ value: String) -> Bool {
        return value.contains(where: { wildcardCharacters.contains($0) })
    }

    private func wildcardIncludeMatches(patternPath: String) -> [String] {
        let directory = (patternPath as NSString).deletingLastPathComponent
        let pattern = (patternPath as NSString).lastPathComponent
        guard let entries = try? fileManager.contentsOfDirectory(atPath: directory),
              !entries.isEmpty else {
            return []
        }

        let matcher = NSPredicate(format: "SELF LIKE %@", pattern)
        return entries
            .filter { matcher.evaluate(with: $0) }
            .map { (directory as NSString).appendingPathComponent($0) }
            .filter { validateRegularReadableFile(path: $0) }
            .sorted()
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

            let payload = MenuCommandPayload(
                command: menuCommand,
                theme: termTheme,
                title: termTitle,
                window: termWindow,
                fallbackTitle: menuName
            )
            let menuRepObj = payload.serialized()

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

}

struct MenuCommandPayload: Codable {
    let command: String
    let theme: String?
    let title: String?
    let window: String?
    let fallbackTitle: String

    init(command: String, theme: String?, title: String?, window: String?, fallbackTitle: String) {
        self.command = command
        self.theme = theme
        self.title = title
        self.window = window
        self.fallbackTitle = fallbackTitle
    }

    init?(serializedObject: String) {
        guard let data = serializedObject.data(using: .utf8),
              let payload = try? JSONDecoder().decode(MenuCommandPayload.self, from: data) else {
            return nil
        }

        self = payload
    }

    func serialized() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let payload = String(data: data, encoding: .utf8) else {
            return ""
        }

        return payload
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
            if let payload = MenuCommandPayload(serializedObject: representedObject) {
                command = payload.command
                commandTheme = payload.theme ?? "(null)"
                commandTitle = payload.title ?? "(null)"
                commandWindow = payload.window ?? "(null)"
                menuFallbackTitle = payload.fallbackTitle
                return
            }

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

        init?(command: String, theme: String, title: String, mode: OpenMode) {
            let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
            guard SecurityPolicies.isSafeCommand(trimmedCommand) else {
                return nil
            }

            self.command = trimmedCommand
            self.theme = theme
            self.title = title
            self.mode = mode
        }

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

            guard let components = URLComponents(string: command),
                  let scheme = components.scheme?.lowercased(),
                  !scheme.isEmpty else {
                return nil
            }

            guard SecurityPolicies.allowedBrowserSchemes.contains(scheme) else {
                return nil
            }

            guard let commandURL = components.url else {
                return nil
            }

            return commandURL
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
        let runGhosttyDirect: (_ command: String, _ errorHandler: ErrorHandler) -> Void
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
                services.runUIControlledTerminal("Ghostty", request.command, request.mode.rawValue) { message, info, canContinue in
                    if info.contains("Not authorized to send Apple events to System Events") {
                        services.runGhosttyDirect(request.command, errorHandler)
                        return
                    }
                    errorHandler(message, info, canContinue)
                }
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
    private var scriptCache: [String: NSAppleScript] = [:]

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

        guard let launchRequest = TerminalLaunchRequest(
            command: menuCommand.command,
            theme: resolvedTheme(commandTheme: menuCommand.commandTheme),
            title: resolvedTitle(commandTitle: menuCommand.commandTitle, menuFallbackTitle: menuCommand.menuFallbackTitle),
            mode: openMode
        ) else {
            errorHandler(
                "Blocked command",
                NSLocalizedString("The selected command is empty or exceeds configured safety limits.", comment: ""),
                false
            )
            return
        }

        if let url = launchRequest.launchURL {
            guard SecurityPolicies.isAllowedURL(url) else {
                errorHandler(
                    "Blocked launch URL",
                    NSLocalizedString("The selected command includes a URL with a blocked scheme.", comment: ""),
                    false
                )
                return
            }

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
            let normalizedOpenIn = SecurityPolicies.sanitizeOpenMode(openInPref)
            return OpenMode(rawValue: normalizedOpenIn) ?? .tab
        }

        let normalizedCommandWindow = commandWindow
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard SecurityPolicies.allowedOpenModes.contains(normalizedCommandWindow) else {
            let errorMessage = "'\(commandWindow)' " + NSLocalizedString("is not a valid value for inTerminal. Please fix this in the JSON file", comment: "")
            let errorInfo = NSLocalizedString("bad \"inTerminal\":\"VALUE\" in the JSON settings", comment: "")
            errorHandler(errorMessage, errorInfo, false)
            return nil
        }
        return OpenMode(rawValue: normalizedCommandWindow)
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
            runGhosttyDirect: { [weak self] command, errorHandler in
                self?.runCommandInGhosttyDirect(command: command, errorHandler: errorHandler)
            }
        )
    }

    private func runCommandInGhosttyDirect(command: String, errorHandler: (String, String, Bool) -> Void) {
        do {
            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = ["-a", "Ghostty", "--args", "-e", "/bin/zsh", "-lc", command]
            try openTask.run()
        } catch {
            errorHandler("Unable to run command in Ghostty.", error.localizedDescription, false)
        }
    }

    private func runScript(scriptPath: String?, handler handlerName: String, parameters parametersInArray: [String]) {
        guard let scriptPath else {
            return
        }

        guard let appleScript = cachedScript(at: scriptPath) else {
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

    private func cachedScript(at path: String) -> NSAppleScript? {
        if let cached = scriptCache[path] {
            return cached
        }

        let pathURL = URL(fileURLWithPath: path)
        var appleScriptCreationError: NSDictionary?
        guard let appleScript = NSAppleScript(contentsOf: pathURL, error: &appleScriptCreationError) else {
            if let errorDetails = appleScriptCreationError {
                NSLog("Failed to load AppleScript at %@: %@", path, errorDetails)
            }
            return nil
        }

        scriptCache[path] = appleScript
        return appleScript
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

    private func appleScriptEscapedString(_ value: String?) -> String {
        guard let value else {
            return ""
        }

        var escapedValue = value.replacingOccurrences(of: "\\", with: "\\\\")
        escapedValue = escapedValue.replacingOccurrences(of: "\"", with: "\\\"")
        escapedValue = escapedValue.replacingOccurrences(of: "\n", with: "\\n")
        escapedValue = escapedValue.replacingOccurrences(of: "\r", with: "\\r")
        escapedValue = escapedValue.replacingOccurrences(of: "\t", with: "\\t")
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
