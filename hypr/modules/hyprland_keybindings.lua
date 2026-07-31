-- See https://wiki.hypr.land/Configuring/Keywords/
-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "y"
local menu = "wofi --show drun --columns 3"
-- local status = "qs"

-- My Scripts
-- local scr_toggleProgram = "~/.config/hypr/scripts/toggle_program.sh"
local scr_volumeController = "~/.config/hypr/scripts/wofi_volume_controller.sh"
local scr_musicSelector = "~/.config/hypr/scripts/wofi_music_selector.sh"
local scr_commandLauncher = "~/.config/hypr/scripts/wofi_command_launcher.sh"
-- local scr_keybindLauncher = "~/.config/hypr/scripts/wofi_keybind_launcher.sh"
local scr_firefoxBookmarks = "~/.config/hypr/scripts/wofi_firefox_bookmarks.sh"
local scr_clipvault = "~/.config/hypr/scripts/wofi_clipvault_selector.sh"
local scr_moveCursor = "~/.config/hypr/scripts/move_cursor.sh"
local scr_spdCursor = "~/.config/hypr/scripts/change_cursor_speed.sh"
local scr_swapWallpaper = "~/.config/hypr/scripts/swap_wallpaper.sh"
local scr_themeSelector = "~/.config/hypr/scripts/theme_selector.sh"
local scr_todo = "~/.config/bash/todo_tool/todo_main.sh"
-- local scr_qs = "~/.config/bash/scripts/quickshell_command_dispatcher.sh"
local scr_translate = "~/.config/hypr/scripts/wofi_translate.sh"
local scr_window = "~/.config/hypr/scripts/wofi_window_menu.sh"
local scr_screenshot = "~/.config/hypr/scripts/grim_screenshot.sh"

-- local function exec_capture(cmd)
-- 	local handle = io.popen(cmd)
-- 	if not handle then
-- 		return nil
-- 	end
-- 	local out = handle:read("*a")
-- 	handle:close()
-- 	return (out:gsub("%s+$", ""))
-- end

-- hl.bind("a", hl.dsp.exec_cmd(scr_commandLauncher .. " $HOME/thing.yml"))

-- Core Binds
hl.bind(
	mainMod .. " + SHIFT + Q",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
	{ description = "Log out of Hyprland" }
)

hl.bind(
	mainMod .. " + SHIFT + RETURN",
	hl.dsp.exec_cmd(terminal, { float = true, size = "1000 400" }, { description = "Floating Terminal" })
)

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Tiled Terminal" })

hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("hyprlock"), { description = "Hyprlock" })

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd(scr_screenshot .. " slurp"), { description = "Screenshot (Slurp)" })

hl.bind(
	mainMod .. " + PRINT",
	hl.dsp.exec_cmd(scr_screenshot .. " global"),
	{ description = "Screenshot (Multi-Monitor)" }
)

-- Universal Binds
hl.bind(mainMod .. " + escape", hl.dsp.submap("reset"), { submap_universal = true, description = "Submap Escape Key" })

hl.bind(
	mainMod .. " + h",
	hl.dsp.focus({ direction = "left" }),
	{ submap_universal = true, description = "Focus Left" }
)

hl.bind(
	mainMod .. " + j",
	hl.dsp.focus({ direction = "down" }),
	{ submap_universal = true, description = "Focus Right" }
)

hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { submap_universal = true, description = "Focus Up" })

hl.bind(
	mainMod .. " + l",
	hl.dsp.focus({ direction = "right" }),
	{ submap_universal = true, description = "Focus Down" }
)

hl.bind(
	mainMod .. " + TAB",
	hl.dsp.window.cycle_next({ next = true }),
	{ submap_universal = true, description = "Cycle Next Window" }
)

hl.bind(
	mainMod .. " + SHIFT + TAB",
	hl.dsp.window.cycle_next({ next = false }),
	{ submap_universal = true, description = "Cycle Prev Window" }
)

hl.bind(
	mainMod .. " + CTRL + TAB",
	hl.dsp.window.cycle_next({ floating = true }),
	{ submap_universal = true, description = "Cycle Floating Window" }
)

hl.bind(mainMod .. " + c", hl.dsp.window.close(), { submap_universal = true, description = "Close Window" })

hl.bind(
	mainMod .. " + a",
	hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }),
	{ submap_universal = true, description = "Toggle Window Opacity" }
)

-- Toggle Float (With Custom Actions)
hl.bind(mainMod .. " + f", function()
	local w = hl.get_active_window()
	if not w then
		return
	end

	hl.dispatch(hl.dsp.window.float(w))
	local class = w.initial_class
	local actions = {
		kitty = function(win)
			hl.dispatch(hl.dsp.window.center({ window = win }))
			hl.dispatch(hl.dsp.window.resize({ x = "1000", y = "400", relative = false, window = win }))
		end,

		firefox = function(win)
			hl.dispatch(hl.dsp.window.center({ window = win }))
			hl.dispatch(hl.dsp.window.resize({ x = "1200", y = "800", relative = false, window = win }))
		end,
	}

	local a = actions[class]
	if a then
		a(w)
	end
end, { submap_universal = true, description = "Toggle Float" })

hl.bind(mainMod .. " + p", hl.dsp.window.pin(), { submap_universal = true, description = "Pin Window" })
--

-- Toggle window screen share prop + manage window private tag
hl.bind(mainMod .. " + SHIFT + p", function()
	local w = hl.get_active_window()
	if not w then
		return
	end
	local wt = w.tags
	local function hasPrivate(tags)
		for _, t in ipairs(tags) do
			if t == "private" then
				return true
			end
		end
		return false
	end

	if hasPrivate(wt) then
		hl.dispatch(hl.dsp.window.tag({ tag = "-private" }))
		hl.dispatch(hl.dsp.window.set_prop({ prop = "no_screen_share", value = "off" }))
	else
		hl.dispatch(hl.dsp.window.tag({ tag = "+private" }))
		hl.dispatch(hl.dsp.window.set_prop({ prop = "no_screen_share", value = "on" }))
	end
end, { description = "Toggle Window Privacy" })

-- Global Window Binds
hl.bind(mainMod .. " + SPACE", hl.dsp.window.center(), { description = "Center Floating Window" })

hl.bind(mainMod .. " + i", hl.dsp.layout("togglesplit"), { description = "Dwindle Toggle Split" })

hl.bind(mainMod .. " + SHIFT + s", hl.dsp.layout("movetoroot"), { description = "Dwindle Move To Root" })

hl.bind(mainMod .. " + s", hl.dsp.layout("swapsplit"), { description = "Dwindle Swap Split" })

hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen(), { description = "Toggle Window Fullscreen" })

-- Special Workspaces
hl.bind(mainMod .. " + SHIFT + m", function()
	local ws = hl.get_workspaces()
	for _, w in ipairs(ws) do
		if w.name == "special:music" then
			hl.dispatch(hl.dsp.workspace.toggle_special("music"))
			return
		end
	end
end, { description = "Special Workspace: Music" })

-- Launch Discord, and toggle it's special workspace
hl.bind(mainMod .. " + SHIFT + d", function()
	local ws = hl.get_workspaces()
	for _, w in ipairs(ws) do
		if w.name == "special:discord" then
			hl.dispatch(hl.dsp.workspace.toggle_special("discord"))
			return
		end
	end
	-- hl.exec_cmd("/opt/Discord/discord")
	hl.exec_cmd("vesktop")
end, { description = "Special Workspace: Discord" })

-- Swap Workspace Between Two Monitors
hl.bind(mainMod .. " + CTRL + s", function()
	local m = hl.get_active_monitor().id
	if m == 0 then
		hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = m, monitor2 = "1" }))
	else
		hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = m, monitor2 = "0" }))
	end
end, { description = "Swap Monitor Workspaces" })

-- Focus Windows / Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Focus Workspace " .. i })
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move Window To Workspace " .. i }
	)
	hl.bind(
		mainMod .. " + SHIFT + CTRL + " .. key,
		hl.dsp.exec_cmd("~/.config/hypr/scripts/move_all_to_workspace.sh " .. key),
		{ description = "Move All Windows On Workspace To Workspace " .. i }
	)
end

-- Move Windows (Tiled)
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }), { description = "Move Tiled Left" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }), { description = "Move Tiled Down" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }), { description = "Move Tiled Up" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }), { description = "Move Tiled Right" })

-- Resize window with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move Window With Mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize Window With Mouse" })

-- My Scripts
hl.bind(mainMod .. " + SHIFT + c", hl.dsp.exec_raw("kitty fish -c cursor_swap"), { description = "Cursor Swap" })
-- hl.bind(mainMod .. " + z", hl.dsp.exec_cmd(scr_toggleProgram .. " " .. status))

-- Wofi Music Selector
hl.bind(
	mainMod .. " + F1",
	hl.dsp.exec_cmd("timeout 60 " .. scr_musicSelector .. " artist"),
	{ description = "Music Selector - Artist" }
)

hl.bind(
	mainMod .. " + SHIFT + F1",
	hl.dsp.exec_cmd("timeout 120 " .. scr_musicSelector .. " files"),
	{ description = "Music Selector - Cache File" }
)

hl.bind(
	mainMod .. " + CTRL + F1",
	hl.dsp.exec_cmd(scr_musicSelector .. " update"),
	{ description = "Music Selector - Update" }
)

hl.bind(mainMod .. " + x", hl.dsp.exec_cmd("timeout 120 " .. scr_commandLauncher), { description = "Command Launcher" })
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("hyprbind menu subkey"), { description = "Hyprbind - Subkey" })
hl.bind(mainMod .. " + SHIFT + b", hl.dsp.exec_cmd("hyprbind menu key"), { description = "Hyprbind - Key" })

-- -- DEFAULT FN F* Binds
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true, description = "Volume +5%" }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume 1 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true, description = "Volume -5%" }
)

hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, description = "Toggle Audio Mute" }
)

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Play Next" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Play Previous" })

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
	{ repeating = true, description = "Monitor Brightness +5%" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
	{ repeating = true, description = "Monitor Brightness -5%" }
)

-- Resize Mode (Active Window)

hl.bind(mainMod .. " + r", hl.dsp.submap("Resize"), { description = "Submap Resize" })
hl.define_submap("Resize", function()
	hl.bind(
		"CTRL + h",
		hl.dsp.window.resize({ x = -10, y = 0, relative = true }),
		{ repeating = true, description = "Resize Window (x-10)" }
	)

	hl.bind(
		"CTRL + j",
		hl.dsp.window.resize({ x = 0, y = -10, relative = true }),
		{ repeating = true, description = "Resize Window (y-10)" }
	)

	hl.bind(
		"CTRL + k",
		hl.dsp.window.resize({ x = 0, y = 10, relative = true }),
		{ repeating = true, description = "Resize Window (y+10)" }
	)

	hl.bind(
		"CTRL + l",
		hl.dsp.window.resize({ x = 10, y = 0, relative = true }),
		{ repeating = true, description = "Resize Window (x+10)" }
	)

	hl.bind(
		"h",
		hl.dsp.window.resize({ x = -60, y = 0, relative = true }),
		{ repeating = true, description = "Resize Window (x-60)" }
	)

	hl.bind(
		"j",
		hl.dsp.window.resize({ x = 0, y = -60, relative = true }),
		{ repeating = true, description = "Resize Window (y-60)" }
	)

	hl.bind(
		"k",
		hl.dsp.window.resize({ x = 0, y = 60, relative = true }),
		{ repeating = true, description = "Resize Window (y+60)" }
	)

	hl.bind(
		"l",
		hl.dsp.window.resize({ x = 60, y = 0, relative = true }),
		{ repeating = true, description = "Resize Window (x+60)" }
	)

	hl.bind("m", hl.dsp.submap("MoveFloat"), { description = "Submap MoveFloat" })

	hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Move Mode (Floating Windows)
hl.bind(mainMod .. " + m", hl.dsp.submap("MoveFloat"), { description = "Submap MoveFloat" })
hl.define_submap("MoveFloat", function()
	hl.bind(
		" + CTRL + h",
		hl.dsp.window.move({ x = -5, y = 0, relative = true }),
		{ repeating = true, description = "Move Window (x-5)" }
	)

	hl.bind(
		" + CTRL + j",
		hl.dsp.window.move({ x = 0, y = 5, relative = true }),
		{ repeating = true, description = "Move Window (y+5)" }
	)

	hl.bind(
		" + CTRL + k",
		hl.dsp.window.move({ x = 0, y = -5, relative = true }),
		{ repeating = true, description = "Move Window (y-5)" }
	)

	hl.bind(
		" + CTRL + l",
		hl.dsp.window.move({ x = 5, y = 0, relative = true }),
		{ repeating = true, description = "Move Window (x+5)" }
	)

	hl.bind(
		" + h",
		hl.dsp.window.move({ x = -25, y = 0, relative = true }),
		{ repeating = true, description = "Move Window (x-25)" }
	)

	hl.bind(
		" + j",
		hl.dsp.window.move({ x = 0, y = 25, relative = true }),
		{ repeating = true, description = "Move Window (y+25)" }
	)

	hl.bind(
		" + k",
		hl.dsp.window.move({ x = 0, y = -25, relative = true }),
		{ repeating = true, description = "Move Window (y-25)" }
	)

	hl.bind(
		" + l",
		hl.dsp.window.move({ x = 25, y = 0, relative = true }),
		{ repeating = true, description = "Move Window (x+25)" }
	)

	hl.bind(" + c", hl.dsp.window.center(), { description = "Center Window" })

	hl.bind(" + r", hl.dsp.submap("Resize"), { description = "Submap Resize" })

	hl.bind(" + SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

--Open Mode (Launch Programs)
hl.bind(mainMod .. " + o", hl.dsp.submap("Open"), { description = "Submap Open" })
hl.define_submap("Open", "reset", function()
	hl.bind("SPACE", hl.dsp.exec_cmd(menu), { description = "Wofi (Run)" })

	hl.bind("e", hl.dsp.exec_cmd("kitty fish -c " .. fileManager), { description = "Yazi" })

	hl.bind("b", hl.dsp.exec_cmd("firefox"), { description = "Firefox" })

	hl.bind("s", hl.dsp.exec_cmd("steam -dev"), { description = "Steam" })

	hl.bind("f", hl.dsp.exec_cmd(scr_firefoxBookmarks .. " window"), { description = "Bookmark Launcher (Window)" })

	hl.bind("t", hl.dsp.exec_cmd(scr_firefoxBookmarks .. " tab"), { description = "Bookmark Launcher (Tab)" })

	hl.bind("m", hl.dsp.exec_cmd("exec /storage/Caprine-2.61.0.AppImage"), { description = "Caprine" })

	hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Cursor Mode
hl.bind(mainMod .. " + g", hl.dsp.submap("Cursor"), { description = "Submap Cursor" })
hl.define_submap("Cursor", function()
	hl.bind("1", hl.dsp.exec_cmd(scr_spdCursor .. " -s 5"), { description = "Set Speed 5" })

	hl.bind("2", hl.dsp.exec_cmd(scr_spdCursor .. " -s 10"), { description = "Set Speed 10" })

	hl.bind("3", hl.dsp.exec_cmd(scr_spdCursor .. " -s 20"), { description = "Set Speed 20" })

	hl.bind(
		"CTRL + d",
		hl.dsp.exec_cmd(scr_spdCursor .. " -d 10"),
		{ repeating = true, description = "Decrease Speed 10" }
	)

	hl.bind(
		"CTRL + u",
		hl.dsp.exec_cmd(scr_spdCursor .. " -i 10"),
		{ repeating = true, description = "Increase Speed 10" }
	)

	hl.bind(
		"g",
		hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/notify_cursor_speed.sh"),
		{ description = "Notify - Cursor Speed" }
	)

	hl.bind("CTRL + j", hl.dsp.exec_cmd("wlrctl pointer click left"), { description = "WLRCTL Left Click" })

	hl.bind("CTRL + k", hl.dsp.exec_cmd("wlrctl pointer click right"), { description = "WLRCTL Right Click" })

	hl.bind("CTRL + m", hl.dsp.exec_cmd("wlrctl pointer click middle"), { description = "WLRCTL Middle Click" })

	hl.bind("u", hl.dsp.exec_cmd("wlrctl pointer scroll -20 0"), { description = "WLRCTL Scroll Up" })

	hl.bind("d", hl.dsp.exec_cmd("wlrctl pointer scroll 20 0"), { description = "WLRCTL Scroll Down" })

	hl.bind("f", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wlkbptr.sh"), { description = "Activate wl-kbptr" })

	hl.bind("h", hl.dsp.exec_cmd(scr_moveCursor .. " -1 0"), { repeating = true, description = "Move Cursor Left" })

	hl.bind("j", hl.dsp.exec_cmd(scr_moveCursor .. " 0 1"), { repeating = true, description = "Move Cursor Down" })

	hl.bind("k", hl.dsp.exec_cmd(scr_moveCursor .. " 0 -1"), { repeating = true, description = "Move Cursor Up" })

	hl.bind("l", hl.dsp.exec_cmd(scr_moveCursor .. " 1 0"), { repeating = true, description = "Move Cursor Right" })

	hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Notification Mode
hl.bind(mainMod .. " + n", hl.dsp.submap("Notification"), { description = "Submap Notification" })
hl.define_submap("Notification", function()
	hl.bind(
		"o",
		hl.dsp.exec_cmd("kitty fish -c 'n ~/dev/data/notifications.json'"),
		{ description = "Open Notification History" }
	)

	hl.bind(
		"r",
		hl.dsp.exec_cmd("makoctl reload && notify-send -a nh-center-text -u low 'Mako Reloaded'"),
		{ description = "Reload Mako" }
	)

	hl.bind(
		"w",
		hl.dsp.exec_cmd(
			[[sh -c 'weather=$(curl -s "wttr.in/?format=2"); notify-send -a nh-center-text -u normal -t 2500 "$weather"']]
		),
		{ description = "Notify Weather" }
	)

	hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Todo Mode
hl.bind(mainMod .. " + t", hl.dsp.submap("Todo"), { description = "Submap Todo" })
hl.define_submap("Todo", "reset", function()
	hl.bind("SPACE", hl.dsp.exec_cmd(scr_todo .. " -i"), { description = "Edit Todo" })

	hl.bind("t", hl.dsp.exec_cmd(scr_todo .. " -m"), { description = "Open Todo Menu" })

	hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Quickshell Mode
hl.bind(mainMod .. " + q", hl.dsp.submap("Quickshell"), { description = "Submap Quickshell" })
hl.define_submap("Quickshell", function()
	hl.bind("i", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/wofi_noctalia_icp.sh"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Wofi Noctalia ICP" })

	hl.bind("c", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call controlCenter toggle"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle Control Center" })

	hl.bind("d", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call calendar toggle"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle Calendar" })

	hl.bind("m", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call systemMonitor toggle"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle System Monitor" })

	hl.bind("s", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call settings open"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle Settings" })

	hl.bind("k", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call bar setPosition 'top' "))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Set Bar Top" })

	hl.bind("j", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call bar setPosition 'bottom' "))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Set Bar Bottom" })

	hl.bind("h", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call bar setPosition 'left' "))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Set Bar Left" })

	hl.bind("l", function()
		hl.dispatch(hl.dsp.exec_cmd("qs -c noctalia-shell ipc call bar setPosition 'right' "))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Set Bar Right" })

	hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Wallpaper
hl.bind(mainMod .. " + w", hl.dsp.submap("Wallpaper"), { description = "Submap Wallpaper" })
hl.define_submap("Wallpaper", function()
	hl.bind("w", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_themeSelector .. " -p -g"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Theme Selector (All)" })

	hl.bind("p", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_themeSelector .. " -p"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Theme Selector (Png)" })

	hl.bind("g", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_themeSelector .. " -g"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Theme Selector (Gif)" })

	hl.bind("q", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_swapWallpaper))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Set Random Wallpaper" })

	hl.bind("CTRL+ w", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_themeSelector .. " update"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Update Theme Selector" })

	-- Fav Wallpapers
	hl.bind("f", hl.dsp.submap("Fav Wallpaper"), { description = "Submap Fav Wallpaper" })
	hl.define_submap("Fav Wallpaper", "reset", function()
		hl.bind("w", hl.dsp.exec_cmd(scr_themeSelector .. " -p -g -f"), { description = "Theme Selector (All)" })

		hl.bind("a", hl.dsp.exec_cmd(scr_themeSelector .. " -p -g -f add"), { description = "Add To Favourites" })

		hl.bind("r", hl.dsp.exec_cmd(scr_themeSelector .. " -p -g -f rm"), { description = "Remove From Favourites" })

		hl.bind("c", hl.dsp.exec_cmd(scr_themeSelector .. " clear fav"), { description = "Clear All Favourites" })

		hl.bind("q", hl.dsp.exec_cmd(scr_swapWallpaper .. " -f"), { description = "Set Random Favourite Wallpaper" })

		hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
	end)

	hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Cursor Zoom
hl.bind(mainMod .. " + z", hl.dsp.submap("Zoom"), { description = "Submap Zoom" })
hl.define_submap("Zoom", function()
	---@param offset number
	---@return nil
	local function zoom(offset)
		local MAX_ZOOM = 5
		local MIN_ZOOM = 1
		local ZOOM_TOGGLE_FACTOR = 1.5
		local current = hl.get_config("cursor.zoom_factor")
		if offset ~= nil then
			current = current + offset
		elseif current ~= MIN_ZOOM then
			current = MIN_ZOOM
		else
			current = ZOOM_TOGGLE_FACTOR
		end
		current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
		hl.config({ cursor = { zoom_factor = current } })
	end

	hl.bind("i", function()
		zoom(0.5)
	end, { repeating = true, description = "Increase Cursor Zoom" })

	hl.bind("o", function()
		zoom(-0.5)
	end, { repeating = true, description = "Decrease Cursor Zoom" })

	hl.bind("h", hl.dsp.exec_cmd(scr_moveCursor .. " -1 0"), { repeating = true, description = "Move Cursor Left" })

	hl.bind("j", hl.dsp.exec_cmd(scr_moveCursor .. " 0 1"), { repeating = true, description = "Move Cursor Down" })

	hl.bind("k", hl.dsp.exec_cmd(scr_moveCursor .. " 0 -1"), { repeating = true, description = "Move Cursor Up" })

	hl.bind("l", hl.dsp.exec_cmd(scr_moveCursor .. " 1 0"), { repeating = true, description = "Move Cursor Right" })

	hl.bind("r", function()
		hl.config({ cursor = { zoom_factor = 1 } })
	end, { description = "Reset Cursor Zoom" })

	-- hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })

	hl.bind("SPACE", function()
		hl.config({ cursor = { zoom_factor = 1 } })
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Reset Cursor And Submap" })
	--
end)

-- Misc
hl.bind(mainMod .. " + u", hl.dsp.submap("Misc"), { description = "Submap Misc" })
hl.define_submap("Misc", function()
	--HTOP
	hl.bind("h", function()
		hl.dispatch(hl.dsp.exec_cmd("kitty htop"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "BTOP" })

	--BTOP
	hl.bind("b", function()
		hl.dispatch(hl.dsp.exec_cmd("kitty btop"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "BTOP" })

	--FETCH (custom size)
	hl.bind("f", function()
		hl.dispatch(hl.dsp.exec_cmd("kitty --class fetch fish -c f"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Open Fetch (with custom float size)" })

	-- Colour Picker
	hl.bind("p", function()
		hl.dispatch(
			hl.dsp.exec_cmd('hyprpicker | wl-copy && notify-send -u low -t 2000 -a center-text "Copied: $(wl-paste)" ')
		)
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Hyprpicker" })

	-- Calculator
	hl.bind("m", function()
		hl.dispatch(hl.dsp.submap("reset"))
		hl.dispatch(hl.dsp.exec_cmd("dcalc"))
	end, { description = "Calculator" })

	-- Emoji Picker
	hl.bind("e", function()
		hl.dispatch(hl.dsp.submap("reset"))
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/wofi_emoji_picker.sh -c"))
	end, { description = "Emoji Picker" })

	-- Wayscriber
	hl.bind("w", function()
		hl.dispatch(hl.dsp.submap("reset"))
		hl.dispatch(hl.dsp.exec_cmd("wayscriber --daemon-toggle"))
	end)

	-- -- Watch Stuff
	-- hl.bind("w", function()
	-- 	hl.dispatch(hl.dsp.exec_cmd("~/.config/bash/scripts/watchstuff.sh -w"))
	-- 	hl.dispatch(hl.dsp.submap("reset"))
	-- end, { description = "Watch Stuff" })

	-- Discord Mode
	hl.bind("d", hl.dsp.submap("Discord"), { description = "Submap Discord" })
	hl.define_submap("Discord", function()
		hl.bind("m", function()
			hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "M", window = "class:^(vesktop)$" }))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Toggle Mute [CTRL+SHIFT+M]" })

		hl.bind("a", function()
			hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "RETURN", window = "class:^(vesktop)$" }))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Accept Incoming Call [CTRL+RETURN]" })

		hl.bind("d", function()
			hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Escape", window = "class:^(vesktop)$" }))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Decline Incoming Call [ESC]" })

		hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
		--
	end)

	-- Clipboard mode
	hl.bind("c", hl.dsp.submap("Clipboard"), { release = true, description = "Submap Clipboard" })
	hl.define_submap("Clipboard", function()
		hl.bind("q", function()
			hl.dispatch(hl.dsp.exec_cmd(scr_clipvault .. " clear"))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Clear Clipvault" })

		hl.bind("r", function()
			hl.dispatch(hl.dsp.exec_cmd("timeout 60 " .. scr_clipvault .. " remove"))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Wofi Clipvault - Remove" })

		hl.bind("c", function()
			hl.dispatch(hl.dsp.exec_cmd("timeout 60 " .. scr_clipvault))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Open Wofi Clipvault" })

		hl.bind("u", hl.dsp.submap("Misc"), { description = "Submap Misc" })

		hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
	end)

	-- Translate Mode
	hl.bind("t", hl.dsp.submap("Translate"), { release = true, description = "Submap Translate" })
	hl.define_submap("Translate", function()
		hl.bind("t", function()
			hl.dispatch(hl.dsp.submap("reset"))
			hl.dispatch(hl.dsp.exec_cmd(scr_translate .. " -s en"))
		end, { description = "Translate (S:en)" })

		hl.bind("f", function()
			hl.dispatch(hl.dsp.submap("reset"))
			hl.dispatch(hl.dsp.exec_cmd(scr_translate .. " -s en -t fr"))
		end, { description = "Translate (S:en T:fr)" })

		hl.bind("g", function()
			hl.dispatch(hl.dsp.submap("reset"))
			hl.dispatch(hl.dsp.exec_cmd(scr_translate .. " -s en -t de"))
		end, { description = "Translate (S:en T:de)" })

		hl.bind("s", function()
			hl.dispatch(hl.dsp.submap("reset"))
			hl.dispatch(hl.dsp.exec_cmd(scr_translate .. " -s en -t es"))
		end, { description = "Translate (S:en T:es)" })

		hl.bind("p", function()
			hl.dispatch(hl.dsp.submap("reset"))
			hl.dispatch(hl.dsp.exec_cmd(scr_translate .. " -p"))
		end, { description = "Wofi Translate" })

		hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
	end)

	hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Volume mode
hl.bind(mainMod .. " + v", hl.dsp.submap("Volume"), { release = true, description = "Submap Volume" })
hl.define_submap("Volume", function()
	hl.bind("v", function()
		hl.dispatch(hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController .. " player"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Wofi Volume (Player)" })

	hl.bind("SHIFT + v", function()
		hl.dispatch(hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Wofi Volume (All)" })

	hl.bind("CTRL + v", function()
		hl.dispatch(hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController .. " system"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Wofi Volume (System)" })

	hl.bind("SPACE", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)

-- Window Mode
hl.bind(mainMod .. " + d", hl.dsp.submap("Window"), { description = "Submap Window" })
hl.define_submap("Window", function()
	hl.bind("SPACE", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_window .. " -r"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Wofi Menu" })

	hl.bind("e", function()
		hl.dispatch(hl.dsp.submap("reset"))
		hl.dispatch(hl.dsp.exec_cmd(scr_window .. " goto"))
	end, { description = "Goto Client" })

	hl.bind("catchall", hl.dsp.submap("reset"), { description = "Submap Reset" })
end)
