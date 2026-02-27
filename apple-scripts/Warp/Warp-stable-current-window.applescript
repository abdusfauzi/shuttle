on scriptRun(argsCmd)
	set withCmd to argsCmd
	CommandRun(withCmd)
end scriptRun

on CommandRun(withCmd)
	tell application "Warp" to activate
	delay 0.2
	tell application "System Events"
		tell process "Warp"
			keystroke withCmd
			key code 36
		end tell
	end tell
end CommandRun
