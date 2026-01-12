local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local cpu = sbar.add("item", "widgets.cpu", {
	position = "right",
	icon = {
		string = icons.cpu,
		color = colors.blue,
		padding_right = 4,
	},
	label = {
		string = "??%",
		color = colors.blue,
		font = { family = settings.font.numbers },
	},
	padding_right = 5,
	padding_left = 5,
	update_freq = 2,
})

local bracket = sbar.add("bracket", "widgets.cpu.bracket", { cpu.name }, {
	background = { color = colors.background, border_color = colors.blue, border_width = 2 },
})

cpu:subscribe({ "routine", "forced" }, function()
	sbar.exec("ps -A -o %cpu | awk '{s+=$1} END {printf \"%.0f\", s}'", function(result)
		local load = tonumber(result) or 0
		local color = colors.blue

		if load > 80 then
			color = colors.red
		elseif load > 60 then
			color = colors.orange
		elseif load > 30 then
			color = colors.yellow
		end

		cpu:set({
			label = { string = load .. "%", color = color },
			icon = { color = color },
		})
		bracket:set({ background = { border_color = color } })
	end)
end)

cpu:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("item", { position = "right", width = 6 })
