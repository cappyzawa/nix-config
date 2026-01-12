local settings = require("settings")
local colors = require("colors")

-- Upper row: time (added first with width=0 to stack with date below)
local cal_clock = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.lantern_mid,
		padding_right = 0,
		align = "center",
		font = { family = settings.font.numbers },
	},
	width = 0,
	y_offset = 6,
	position = "right",
	update_freq = 1,
})

-- Lower row: date (determines the actual width)
local cal_date = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.lantern_mid,
		padding_right = 0,
		align = "center",
		font = { family = settings.font.numbers },
	},
	y_offset = -6,
	position = "right",
	update_freq = 1,
	padding_right = 10,
})

sbar.add("bracket", { cal_clock.name, cal_date.name }, {
	background = {
		color = colors.bg1,
		height = 34,
		border_color = colors.lantern_mid,
		border_width = 2,
	},
})

sbar.add("item", { position = "right", width = settings.group_paddings })

cal_clock:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_clock:set({ label = os.date("%H:%M") })
end)

cal_date:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_date:set({ label = os.date("%m/%d (%a)") })
end)

sbar.add("item", { position = "right", width = 6 })
