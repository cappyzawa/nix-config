local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
	update_freq = 1,
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 16.0,
		},
		color = colors.lantern_mid,
		highlight = colors.background,
		padding_left = 6,
		padding_right = 2,
	},
	label = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 13.0,
		},
		color = colors.foreground,
		highlight = colors.background,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		height = 34,
		corner_radius = 10,
		border_width = 2,
		border_color = colors.lantern_mid,
	},
	popup = {
		background = {
			border_width = 2,
			corner_radius = 12,
			border_color = colors.popup.border,
			color = colors.popup.bg,
			shadow = { drawing = true },
		},
		blur_radius = 50,
	},
	padding_left = 8,
	padding_right = 8,
})
