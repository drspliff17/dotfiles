-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("qs -c noctalia-shell")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("wal -R")
	hl.exec_cmd("wl-paste --watch clipvault store")
	hl.exec_cmd("notif_log")
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

-- hl.on("workspace.created", function(w)
-- 	if not w then
-- 		return
-- 	end
-- 	local mon1 = "ENTER_NAME"
-- 	local mon2 = "ENTER_NAME"
-- 	local mon1_thres = 5
-- 	local id = w.id
-- 	if id <= mon1_thres then
-- 		hl.dispatch(hl.dsp.workspace.move({ monitor = mon1 }))
-- 	else
-- 		hl.dispatch(hl.dsp.workspace.move({ monitor = mon2 }))
-- 	end
-- end)
