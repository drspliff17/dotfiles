require("modules.hypr_functions")

-- Save / Load layout state. Mode can be either start, or stop - in respect of the hyprland.x event
local function handleLayout(mode)
	if mode == "start" then
		Load_Layout_State()
	elseif mode == "stop" then
		Save_Layout_State()
	else
		return
	end
end

hl.on("hyprland.start", function()
	handleLayout("start")

	hl.exec_cmd("hyprsunset")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("awww restore")
	hl.exec_cmd("wal -R")
	hl.exec_cmd("oshell")
	hl.exec_cmd("wl-paste --watch clipvault store")
end)

hl.on("hyprland.shutdown", function()
	handleLayout("stop")
end)

hl.on("window.close", function(win)
	-- Wofi, refocus captured monitor on exit
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

hl.on("window.open", function(win)
	-- Hide Discord when it initially opens
	if win.initial_class == "discord" then
		local w = hl.get_active_special_workspace()
		if w == nil then
			return
		end
		hl.dispatch(hl.dsp.workspace.toggle_special("discord"))
	end
end)
