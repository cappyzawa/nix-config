local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local memory = sbar.add("item", "widgets.memory", {
	position = "right",
	icon = {
		string = icons.memory,
		font = { size = 20 },
		color = colors.life,
		padding_right = 4,
	},
	label = {
		string = "??%",
		color = colors.life,
		font = { family = settings.font.numbers },
	},
	padding_right = 5,
	padding_left = 5,
	update_freq = 5,
})

local bracket = sbar.add("bracket", "widgets.memory.bracket", { memory.name }, {
	background = { color = colors.background, border_color = colors.life, border_width = 2 },
})

memory:subscribe({ "routine", "forced" }, function()
	sbar.exec(
		"memory_pressure | grep 'System-wide memory free percentage' | awk '{print 100 - $5}' | tr -d '%'",
		function(result)
			local used = tonumber(result) or 0
			local color = colors.life

			if used > 80 then
				color = colors.red
			elseif used > 60 then
				color = colors.orange
			elseif used > 30 then
				color = colors.yellow
			end

			memory:set({
				label = { string = used .. "%", color = color },
				icon = { color = color },
			})
			bracket:set({ background = { border_color = color } })
		end
	)
end)

memory:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

sbar.add("item", { position = "right", width = 6 })
