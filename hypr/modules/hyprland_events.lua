hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("dunst")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("wal -R")
end)

hl.on("window.close", function(win)
	if win.class ~= "wofi" then
		return
	end

	local path = os.getenv("HOME") .. "/.config/wofi/state/monitor_prelaunch"

	local f = io.open(path, "r")
	if not f then
		return
	end

	local monitor = f:read("*all"):gsub("[\n\r]", "")
	f:close()

	os.remove(path)

	hl.dispatch(hl.dsp.focus({ monitor = monitor }))
end)
