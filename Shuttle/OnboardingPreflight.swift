import Cocoa
import ApplicationServices

struct PreflightStatus {
    let configReadable: Bool
    let accessibilityGranted: Bool
    let automationGranted: Bool
    let requiresAccessibility: Bool
    let requiresAutomation: Bool

    var isReady: Bool {
        configReadable && (!requiresAccessibility || accessibilityGranted)
    }
}

final class OnboardingPreflight {
    func evaluate(configPath: String, terminalPref: String, openInPref: String) -> PreflightStatus {
        let expandedPath = (configPath as NSString).expandingTildeInPath
        let configReadable = FileManager.default.isReadableFile(atPath: expandedPath)
        let requiresAccessibility = requiresAccessibility(for: terminalPref, openInPref: openInPref)
        let requiresAutomation = requiresAutomation(for: terminalPref, openInPref: openInPref)
        let accessibilityGranted = AXIsProcessTrusted()
        let automationGranted = probeAutomationToSystemEvents()

        return PreflightStatus(
            configReadable: configReadable,
            accessibilityGranted: accessibilityGranted,
            automationGranted: automationGranted,
            requiresAccessibility: requiresAccessibility,
            requiresAutomation: requiresAutomation
        )
    }

    private func requiresAccessibility(for terminalPref: String, openInPref: String) -> Bool {
        let terminal = terminalPref.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let openMode = SecurityPolicies.sanitizeOpenMode(openInPref)

        guard openMode != "virtual" else {
            return false
        }

        switch terminal {
        case "warp":
            return true
        default:
            return false
        }
    }

    private func requiresAutomation(for terminalPref: String, openInPref: String) -> Bool {
        let terminal = terminalPref.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let openMode = SecurityPolicies.sanitizeOpenMode(openInPref)

        guard openMode != "virtual" else {
            return false
        }

        switch terminal {
        case "warp":
            return true
        default:
            return false
        }
    }

    private func probeAutomationToSystemEvents() -> Bool {
        let source = "tell application \"System Events\" to get name of first process"
        var scriptError: NSDictionary?
        let script = NSAppleScript(source: source)
        _ = script?.executeAndReturnError(&scriptError)
        return scriptError == nil
    }
}
