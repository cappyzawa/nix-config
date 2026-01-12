local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local date = sbar.add("item", "widgets.date", {
	position = "right",
	icon = {
		string = icons.calendar,
		color = colors.lantern_mid,
		padding_right = 4,
	},
	label = {
		color = colors.lantern_mid,
		font = { family = settings.font.numbers },
	},
	padding_left = 5,
	padding_right = 5,
	update_freq = 60,
})

local date_bracket = sbar.add("bracket", "widgets.date.bracket", { date.name }, {
	background = {
		color = colors.background,
		border_color = colors.lantern_mid,
		border_width = 2,
	},
})

date:subscribe({ "forced", "routine", "system_woke" }, function(env)
	date:set({ label = os.date("%m/%d (%a)") })
end)

sbar.add("item", { position = "right", width = 6 })
