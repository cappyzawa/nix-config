local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local clock = sbar.add("item", "widgets.clock", {
	position = "right",
	icon = {
		string = icons.clock,
		color = colors.background,
		padding_right = 4,
	},
	label = {
		color = colors.background,
		font = { family = settings.font.numbers },
	},
	padding_left = 5,
	padding_right = 5,
	update_freq = 1,
})

local clock_bracket = sbar.add("bracket", "widgets.clock.bracket", { clock.name }, {
	background = {
		color = colors.lantern_mid,
		border_color = colors.lantern_mid,
		border_width = 2,
	},
})

clock:subscribe({ "forced", "routine", "system_woke" }, function(env)
	clock:set({ label = os.date("%H:%M") })
end)

sbar.add("item", { position = "right", width = 6 })
