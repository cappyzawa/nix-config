local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

local front_app_icon = sbar.add("item", "front_app_icon", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = "sketchybar-app-font:Regular:16.0",
		color = colors.cyan,
		padding_left = 8,
		padding_right = 0,
	},
	padding_left = 4,
	padding_right = 0,
	updates = true,
})

local front_app = sbar.add("item", "front_app", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = {
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		color = colors.cyan,
		padding_left = 4,
		padding_right = 8,
	},
	padding_left = 0,
	padding_right = 4,
	updates = true,
})

sbar.add("bracket", "front_app.bracket", { front_app_icon.name, front_app.name }, {
	background = {
		color = colors.background,
		border_color = colors.cyan,
		border_width = 2,
		height = 28,
		corner_radius = 8,
	},
})

front_app:subscribe("front_app_switched", function(env)
	local app_name = env.INFO
	local lookup = app_icons[app_name]
	local icon = ((lookup == nil) and app_icons["default"] or lookup)

	front_app_icon:set({ label = { string = icon } })
	front_app:set({ label = { string = app_name } })
end)

sbar.add("item", { width = 6 })
