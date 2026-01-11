local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

local spaces = {}
local space_brackets = {}

-- Workspace colors using akari-night palette
local colors_spaces = {
	[1] = colors.lantern_mid,
	[2] = colors.lantern_far,
	[3] = colors.life,
	[4] = colors.rain,
	[5] = colors.night,
	[6] = colors.muted,
	[7] = colors.lantern_near,
	[8] = colors.lantern_ember,
	[9] = colors.foreground,
}

-- Apple logo at the start
local apple = sbar.add("item", "apple", {
	icon = {
		string = icons.apple,
		font = { size = 16 },
		color = colors.lantern_mid,
		padding_left = 8,
		padding_right = 8,
	},
	label = { drawing = false },
	background = {
		color = colors.background,
		border_color = colors.lantern_mid,
		border_width = 2,
		height = 28,
		corner_radius = 8,
	},
	padding_left = 4,
	padding_right = 4,
})

for i = 1, 9, 1 do
	local space = sbar.add("space", "space." .. i, {
		space = i,
		icon = {
			font = {
				family = settings.font.numbers,
				size = 14,
			},
			string = i,
			padding_left = 8,
			padding_right = 4,
			color = colors_spaces[i],
			highlight_color = colors.background,
		},
		label = {
			padding_right = 8,
			padding_left = 0,
			color = colors_spaces[i],
			highlight_color = colors.background,
			font = "sketchybar-app-font:Regular:14.0",
			y_offset = -1,
		},
		padding_right = 2,
		padding_left = 2,
		background = {
			color = colors.transparent,
			height = 28,
			border_width = 0,
		},
	})

	spaces[i] = space

	-- Individual bracket for each space
	local bracket = sbar.add("bracket", "space.bracket." .. i, { space.name }, {
		background = {
			color = colors.background,
			border_color = colors_spaces[i],
			border_width = 2,
			height = 28,
			corner_radius = 8,
		},
	})
	space_brackets[i] = bracket

	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		space:set({
			icon = { highlight = selected },
			label = { highlight = selected },
			background = {
				color = selected and colors_spaces[i] or colors.transparent,
			},
		})
		bracket:set({
			background = {
				color = selected and colors_spaces[i] or colors.background,
			},
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		sbar.exec("aerospace workspace " .. env.SID)
	end)
end

-- Observer for window changes in spaces
local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_window_observer:subscribe("space_windows_change", function(env)
	local icon_line = ""
	local no_app = true
	for app, _ in pairs(env.INFO.apps) do
		no_app = false
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["default"] or lookup)
		icon_line = icon_line .. icon
	end

	if no_app then
		icon_line = ""
	end

	sbar.animate("tanh", 10, function()
		spaces[env.INFO.space]:set({ label = icon_line })
	end)
end)

sbar.add("item", { width = 6 })
