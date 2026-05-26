-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("dunst")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("wal -R")
end)

-- Wofi, refocus captured monitor on exit
hl.on("window.close", function(win)
	if win.class == "wofi" then
		local path = os.getenv("HOME") .. "/.config/wofi/state/monitor_prelaunch"

		local f = io.open(path, "r")
		if not f then
			return
		end

		local monitor = f:read("*all"):gsub("[\n\r]", "")
		f:close()

		os.remove(path)

		hl.dispatch(hl.dsp.focus({ monitor = monitor }))
	end
end)

-- Hide Discord when it initially opens
hl.on("window.open", function(win)
	if win.initial_class == "discord" then
		local w = hl.get_active_special_workspace()
		if w == nil then
			return
		end
		hl.dispatch(hl.dsp.workspace.toggle_special("discord"))
	end
end)
