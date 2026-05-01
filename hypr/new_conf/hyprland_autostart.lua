---@diagnostic disable
hl.on("hyprland.start", function()
	hl.exec_cmd(status)
	hl.exec_cmd(notifier)
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("wal -r")
end)
