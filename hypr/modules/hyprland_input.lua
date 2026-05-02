-- https://wiki.hypr.land/Configuring/Variables/#input
hl.config({
	input = {
		kb_layout = "gb",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		numlock_by_default = true,
		follow_mouse = 1,
		sensitivity = 0, -- -1.0 -> 1.0, no means no modification

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- See https://wiki.hypr.land/Configuring/Gestures
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
