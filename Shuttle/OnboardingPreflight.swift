import Cocoa
import ApplicationServices

struct PreflightStatus {
    let configReadable: Bool
    let accessibilityGranted: Bool
    let automationGranted: Bool

    var isReady: Bool {
        configReadable && accessibilityGranted && automationGranted
    }
}

final class OnboardingPreflight {
    func evaluate(configPath: String) -> PreflightStatus {
        let expandedPath = (configPath as NSString).expandingTildeInPath
        let configReadable = FileManager.default.isReadableFile(atPath: expandedPath)
        let accessibilityGranted = AXIsProcessTrusted()
        let automationGranted = probeAutomationToSystemEvents()

        return PreflightStatus(
            configReadable: configReadable,
            accessibilityGranted: accessibilityGranted,
            automationGranted: automationGranted
        )
    }

    private func probeAutomationToSystemEvents() -> Bool {
        let source = "tell application \"System Events\" to get name of first process"
        var scriptError: NSDictionary?
        let script = NSAppleScript(source: source)
        _ = script?.executeAndReturnError(&scriptError)
        return scriptError == nil
    }
}
