local colors = require("colors")
local settings = require("settings")

local spaces = {}

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
			padding_right = 8,
			color = colors_spaces[i],
			highlight_color = colors.background,
		},
		label = {
			drawing = false,
		},
		padding_right = 4,
		padding_left = 4,
		background = {
			color = colors.transparent,
			height = 24,
			border_width = 0,
			corner_radius = 6,
		},
	})

	spaces[i] = space

	-- Padding space
	sbar.add("space", "space.padding." .. i, {
		space = i,
		script = "",
		width = settings.group_paddings,
	})

	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		space:set({
			icon = { highlight = selected },
			background = {
				color = selected and colors_spaces[i] or colors.transparent,
				border_color = selected and colors_spaces[i] or colors.transparent,
			},
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		-- Use aerospace to switch workspaces
		sbar.exec("aerospace workspace " .. env.SID)
	end)
end

sbar.add("bracket", {
	spaces[1].name,
	spaces[2].name,
	spaces[3].name,
	spaces[4].name,
	spaces[5].name,
	spaces[6].name,
	spaces[7].name,
	spaces[8].name,
	spaces[9].name,
}, {
	background = {
		color = colors.background,
		border_color = colors.lantern_mid,
		border_width = 2,
	},
})

sbar.add("item", { width = 6 })
