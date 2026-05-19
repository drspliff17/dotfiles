-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Can disable rules by storing to local var and using:
-- local someRule = hl.window_rule({ ... })
-- someRule:set_enabled(false)

-- hl.window_rule({
-- 	name = "surpress-maximize-events",
-- 	match = { class = ".*" },
--
-- 	surpress_event = "maximize",
-- })

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "pinned-change-border",
	match = { pin = true },
	rounding = 0,
	border_size = 3,
	border_color = { colors = { color4 } },
	opacity = "0.9 override 0.4 override 1.0",
})

hl.window_rule({
	name = "waypaper-float",
	match = { class = "waypaper" },
	animation = "slide",
	float = true,
	size = "800 600",
	move = "10 (monitor_h-(window_h)*0.5-(window_h*0.20)",
})

hl.window_rule({
	name = "kitty-fullscreen",
	match = {
		class = "kitty",
		fullscreen = true,
	},
	opacity = "0.94 override 0.9 override 0.9 override",
})

hl.window_rule({
	name = "cmus-monitor1-on-open",
	match = {
		class = "cmus",
	},
	workspace = "10",
	monitor = "1",
})
