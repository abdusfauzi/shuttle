on scriptRun(argsCmd, argsTheme, argsTitle)
	set withCmd to argsCmd
	set _unusedTheme to argsTheme
	set _unusedTitle to argsTitle
	CommandRun(withCmd)
end scriptRun

on CommandRun(withCmd)
	tell application "Warp" to activate
	delay 0.2
	tell application "System Events"
		tell process "Warp"
			keystroke "t" using {command down}
			delay 0.1
			keystroke withCmd
			key code 36
		end tell
	end tell
end CommandRun
