local function handleLayout(mode)
	local function validLayout(layout)
		return type(layout) == "string" and layout:match("^[%w_-]+$") ~= nil
	end

	local home = os.getenv("HOME")
	if not home then
		return
	end

	local path = home .. "/.config/hypr/layout_saved_state"

	if mode == "start" then
		local f = io.open(path, "r")
		if not f then
			return
		end

		local layout = f:read("*l")
		f:close()

		if validLayout(layout) then
			hl.config({ general = { layout = layout } })
		end
	elseif mode == "stop" then
		local layout = hl.get_config("general.layout")
		if not validLayout(layout) then
			return
		end

		local f = io.open(path .. ".tmp", "w")
		if not f then
			return
		end

		f:write(layout, "\n")
		f:close()
		os.rename(path .. ".tmp", path)
	else
		return
	end
end

-- Autostart
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
