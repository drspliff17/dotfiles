-- See https://wiki.hypr.land/Configuring/Keywords/
-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "y"
local menu = "wofi --show drun --columns 3"
local status = "qs"

-- My Scripts
local scr_toggleProgram = "~/.config/hypr/scripts/toggle_program.sh"
local scr_volumeController = "~/.config/hypr/scripts/wofi_volume_controller.sh"
local scr_musicSelector = "~/.config/hypr/scripts/wofi_music_selector.sh"
local scr_commandLauncher = "~/.config/hypr/scripts/wofi_command_launcher.sh"
local scr_keybindLauncher = "~/.config/hypr/scripts/wofi_keybind_launcher.sh"
local scr_firefoxBookmarks = "~/.config/hypr/scripts/wofi_firefox_bookmarks.sh"
local scr_docctl = "~/.config/hypr/scripts/old/dmenu_doc_selector.sh"
local scr_moveCursor = "~/.config/hypr/scripts/move_cursor.sh"
local scr_spdCursor = "~/.config/hypr/scripts/change_cursor_speed.sh"
local scr_swapWallpaper = "~/.config/hypr/scripts/swap_wallpaper.sh"
local scr_themeSelector = "~/.config/hypr/scripts/wofi_theme_selector.sh"
local scr_todo = "~/.config/bash/todo_tool/todo_main.sh"
local scr_qs = "~/.config/bash/scripts/quickshell_command_dispatcher.sh"

local function exec_capture(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local out = handle:read("*a")
	handle:close()
	return (out:gsub("%s+$", ""))
end

-- Core Binds
hl.bind(
	mainMod .. " + SHIFT + Q",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(terminal, { float = true, size = "1000 400" }))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("hyprlock"))

-- Screenshots
hl.bind(
	"PRINT",
	hl.dsp.exec_cmd([[
    grim -g "$(slurp)" -c ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png &&
    notify-send -u low -t 1000 -a center-text "Screenshot taken"
  ]])
)

hl.bind(
	mainMod .. " + PRINT",
	hl.dsp.exec_cmd([[
    grim -c ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png &&
    notify-send -u low -t 1000 -a center-text "Screenshot taken"
  ]])
)

-- Universal Binds
hl.bind(mainMod .. " + escape", hl.dsp.submap("reset"), { submap_universal = true })

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }), { submap_universal = true })
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }), { submap_universal = true })
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { submap_universal = true })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { submap_universal = true })

hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next({ next = true }), { submap_universal = true })
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }), { submap_universal = true })
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.window.cycle_next({ floating = true }), { submap_universal = true })

hl.bind(mainMod .. " + c", hl.dsp.window.close(), { submap_universal = true })

hl.bind(mainMod .. " + a", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { submap_universal = true })

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
end, { submap_universal = true })

hl.bind(mainMod .. " + p", hl.dsp.window.pin(), { submap_universal = true })

-- Global Window Binds
hl.bind(mainMod .. " + SPACE", hl.dsp.window.center())
hl.bind(mainMod .. " + i", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.layout("movetoroot"))
hl.bind(mainMod .. " + s", hl.dsp.layout("swapsplit"))
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen())

-- Special Workspaces
hl.bind(mainMod .. " + SHIFT + m", function()
	local ws = hl.get_workspaces()
	for _, w in ipairs(ws) do
		if w.name == "special:music" then
			hl.dispatch(hl.dsp.workspace.toggle_special("music"))
			return
		end
	end
end)

-- Launch Discord, and toggle it's special workspace
hl.bind(mainMod .. " + SHIFT + d", function()
	local ws = hl.get_workspaces()
	for _, w in ipairs(ws) do
		if w.name == "special:discord" then
			hl.dispatch(hl.dsp.workspace.toggle_special("discord"))
			return
		end
	end
	hl.exec_cmd("/opt/Discord/discord")
end)

-- Swap Workspace Between Two Monitors
hl.bind(mainMod .. " + CTRL + s", function()
	local m = hl.get_active_monitor().id
	if m == 0 then
		hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = m, monitor2 = "1" }))
	else
		hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = m, monitor2 = "0" }))
	end
end)

-- Focus Windows / Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	hl.bind(
		mainMod .. " + SHIFT + CTRL + " .. key,
		hl.dsp.exec_cmd("~/.config/hypr/scripts/move_all_to_workspace.sh " .. key)
	)
end

-- Move Windows (Tiled)
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Resize window with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- My Scripts
hl.bind(mainMod .. " + SHIFT + c", hl.dsp.exec_raw("kitty fish -c cursor_swap"))
hl.bind(mainMod .. " + z", hl.dsp.exec_cmd(scr_toggleProgram .. " " .. status))

-- Wallpaper / Theme
hl.bind(mainMod .. " + w", hl.dsp.exec_cmd(scr_swapWallpaper))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.exec_cmd(scr_themeSelector .. " update"))

-- Wofi Music Selector
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("timeout 60 " .. scr_musicSelector .. " artist"))
hl.bind(mainMod .. " + SHIFT + F1", hl.dsp.exec_cmd("timeout 60 " .. scr_musicSelector .. " files"))
hl.bind(mainMod .. " + CTRL + F1", hl.dsp.exec_cmd(scr_musicSelector .. " update"))

-- Wofi Volume Controller
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController .. " player"))
hl.bind(mainMod .. " + SHIFT + v", hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController))
hl.bind(mainMod .. " + CTRL + v", hl.dsp.exec_cmd("timeout 30 " .. scr_volumeController .. " player"))
hl.bind(mainMod .. " + x", hl.dsp.exec_cmd("timeout 120 " .. scr_commandLauncher))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("timeout 180 " .. scr_keybindLauncher))
hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd("timeout 120 " .. scr_docctl))

-- -- DEFAULT FN F* Binds
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume 1 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true })

-- -- Resize Mode (Active Window)

hl.bind(mainMod .. " + r", hl.dsp.submap("Resize"))
hl.define_submap("Resize", function()
	hl.bind("CTRL + h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("CTRL + j", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("CTRL + k", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("CTRL + l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

	hl.bind("h", hl.dsp.window.resize({ x = -60, y = 0, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = -60, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = 60, relative = true }), { repeating = true })
	hl.bind("l", hl.dsp.window.resize({ x = 60, y = 0, relative = true }), { repeating = true })

	hl.bind("m", hl.dsp.submap("MoveFloat"))
	hl.bind("SPACE", hl.dsp.submap("reset"))
end)

-- Move Mode (Floating Windows)
hl.bind(mainMod .. " + m", hl.dsp.submap("MoveFloat"))
hl.define_submap("MoveFloat", function()
	hl.bind(" + CTRL + h", hl.dsp.window.move({ x = -5, y = 0, relative = true }), { repeating = true })
	hl.bind(" + CTRL + j", hl.dsp.window.move({ x = 0, y = 5, relative = true }), { repeating = true })
	hl.bind(" + CTRL + k", hl.dsp.window.move({ x = 0, y = -5, relative = true }), { repeating = true })
	hl.bind(" + CTRL + l", hl.dsp.window.move({ x = 5, y = 0, relative = true }), { repeating = true })

	hl.bind(" + h", hl.dsp.window.move({ x = -25, y = 0, relative = true }), { repeating = true })
	hl.bind(" + j", hl.dsp.window.move({ x = 0, y = 25, relative = true }), { repeating = true })
	hl.bind(" + k", hl.dsp.window.move({ x = 0, y = -25, relative = true }), { repeating = true })
	hl.bind(" + l", hl.dsp.window.move({ x = 25, y = 0, relative = true }), { repeating = true })

	hl.bind(" + c", hl.dsp.window.center())
	hl.bind(" + r", hl.dsp.submap("Resize"))
	hl.bind(" + SPACE", hl.dsp.submap("reset"))
end)

--Open Mode (Launch Programs)
hl.bind(mainMod .. " + o", hl.dsp.submap("Open"))
hl.define_submap("Open", "reset", function()
	hl.bind("SPACE", hl.dsp.exec_cmd(menu))
	hl.bind("e", hl.dsp.exec_cmd("kitty fish -c " .. fileManager))
	hl.bind("b", hl.dsp.exec_cmd("firefox"))
	hl.bind("w", hl.dsp.exec_cmd(scr_themeSelector))
	hl.bind("s", hl.dsp.exec_cmd("steam"))
	hl.bind("f", hl.dsp.exec_cmd(scr_firefoxBookmarks .. " window"))
	hl.bind("t", hl.dsp.exec_cmd(scr_firefoxBookmarks .. " tab"))
	hl.bind("m", hl.dsp.exec_cmd("kitty --class cmus fish -c cmus"))
	hl.bind("v", hl.dsp.exec_cmd("vlc"))

	hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Cursor Mode

hl.bind(mainMod .. " + g", hl.dsp.submap("Cursor"))
hl.define_submap("Cursor", function()
	hl.bind("SHIFT + 1", hl.dsp.exec_cmd(scr_spdCursor .. " -s 5"))
	hl.bind("SHIFT + 2", hl.dsp.exec_cmd(scr_spdCursor .. " -s 10"))
	hl.bind("SHIFT + 3", hl.dsp.exec_cmd(scr_spdCursor .. " -s 20"))
	hl.bind("SHIFT + j", hl.dsp.exec_cmd(scr_spdCursor .. " -d 10"), { repeating = true })
	hl.bind("SHIFT + k", hl.dsp.exec_cmd(scr_spdCursor .. " -i 10"), { repeating = true })
	hl.bind("g", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/notify_cursor_speed.sh"))
	hl.bind("SHIFT + h", hl.dsp.exec_cmd("wlrctl pointer click left"))
	hl.bind("SHIFT + l", hl.dsp.exec_cmd("wlrctl pointer click right"))
	hl.bind("SHIFT + m", hl.dsp.exec_cmd("wlrctl pointer click middle"))

	hl.bind("f", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wlkbptr.sh"))

	hl.bind("h", hl.dsp.exec_cmd(scr_moveCursor .. " -1 0"), { repeating = true })
	hl.bind("j", hl.dsp.exec_cmd(scr_moveCursor .. " 0 1"), { repeating = true })
	hl.bind("k", hl.dsp.exec_cmd(scr_moveCursor .. " 0 -1"), { repeating = true })
	hl.bind("l", hl.dsp.exec_cmd(scr_moveCursor .. " 1 0"), { repeating = true })

	hl.bind("SPACE", hl.dsp.submap("reset"))
end)

-- Notification Mode
hl.bind(mainMod .. " + n", hl.dsp.submap("Notification"))
hl.define_submap("Notification", function()
	hl.bind("r", hl.dsp.exec_cmd("dunstctl reload"))
	hl.bind("p", hl.dsp.exec_cmd("dunstctl history-pop"))
	hl.bind("n", hl.dsp.exec_cmd("dunstctl close-all"))
	hl.bind("f", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/dunst_history_fzf.sh"))
	hl.bind("c", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/dunst_history_clear.sh"))
	hl.bind("g", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/dunst_history_get.sh"))
	hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Todo Mode
hl.bind(mainMod .. " + t", hl.dsp.submap("Todo"))
hl.define_submap("Todo", "reset", function()
	hl.bind("SPACE", hl.dsp.exec_cmd(scr_todo .. " -i"))
	hl.bind("t", hl.dsp.exec_cmd(scr_todo .. " -m"))
	hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Quickshell Mode
hl.bind(mainMod .. " + q", hl.dsp.submap("Quickshell"))
hl.define_submap("Quickshell", function()
	hl.bind("k", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_qs .. " scp barPreset top"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("j", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_qs .. " scp barPreset bottom"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("h", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_qs .. " scp barPreset left"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("l", function()
		hl.dispatch(hl.dsp.exec_cmd(scr_qs .. " scp barPreset right"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("c", hl.dsp.exec_cmd(scr_qs .. " cbp"))

	hl.bind("catchall", hl.dsp.submap("reset"))
end)
