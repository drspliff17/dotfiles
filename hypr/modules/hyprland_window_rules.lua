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
	opacity = "0.9 override 0.4 override 1.0",
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
	name = "cmus-move-special",
	match = {
		class = "cmus",
	},
	no_initial_focus = true,
	workspace = "special:music",
})

hl.window_rule({
	name = "wofi-monitor0-on-open",
	match = {
		class = "wofi",
	},
	monitor = "0",
})

hl.window_rule({
	name = "discord-move-special",
	match = {
		initial_class = "discord",
	},
	no_initial_focus = true,
	workspace = "special:discord",
})

hl.window_rule({
	name = "discord-move-special",
	match = {
		initial_class = "vesktop",
	},
	no_initial_focus = true,
	workspace = "special:discord",
})

hl.window_rule({
	name = "theme-switcher",
	match = {
		initial_class = "Nsxiv",
	},
	monitor = "0",
	float = true,
	center = true,
	size = "1200 600",
})

hl.window_rule({
	name = "VS",
	match = {
		initial_class = "Vintage Story",
	},
	confine_pointer = true,
})

hl.window_rule({
	name = "hide-private-tagged",
	match = {
		tag = "private",
	},
	opaque = true,
	border_color = { colors = { color6 } },
	border_size = 4,
})
