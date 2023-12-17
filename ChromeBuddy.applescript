on open location targetURL
	tell application "Google Chrome"
		set newTab to make new tab at end of tabs of window 1
		set URL of newTab to targetURL
		activate
	end tell
end open location

on run
	display alert "ChromeBuddy" message "Version x.x.x
designed & developed by Andrey Grebennik" as informational buttons {"OK"} default button "OK"
end run