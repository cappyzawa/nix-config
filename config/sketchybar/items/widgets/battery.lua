local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	icon = {
		font = {
			style = settings.font.style_map["Regular"],
			size = 19.0,
		},
		padding_left = 9,
		padding_right = 0,
	},
	label = {
		font = { family = settings.font.numbers },
		color = colors.orange,
	},
	padding_left = 0,
	padding_right = 5,
	update_freq = 60,
	popup = {
		align = "center",
		background = {
			color = colors.background,
			border_color = colors.orange,
			border_width = 2,
		},
	},
})

local remaining_time = sbar.add("item", {
	position = "popup." .. battery.name,
	icon = {
		padding_left = 0,
		padding_right = 0,
		string = "Charging:",
		color = colors.orange,
		width = 55,
		align = "left",
		font = { size = 13.0 },
	},
	label = {
		string = "??:??h",
		width = 90,
		align = "right",
	},
})

battery:subscribe({ "routine", "power_source_change", "system_woke", "forced" }, function()
	sbar.exec("pmset -g batt", function(batt_info)
		local icon = "!"
		local label = "?"

		local found, _, charge = batt_info:find("(%d+)%%")
		if found then
			charge = tonumber(charge)
			label = charge .. "%"
		end

		local color = colors.green
		local charging, _, _ = batt_info:find("AC Power")

		if charging then
			icon = icons.battery.charging
		else
			if found and charge > 80 then
				icon = icons.battery._100
				color = colors.green
			elseif found and charge > 60 then
				icon = icons.battery._75
				color = colors.green
			elseif found and charge > 40 then
				icon = icons.battery._50
				color = colors.yellow
			elseif found and charge > 20 then
				icon = icons.battery._25
				color = colors.yellow
			else
				icon = icons.battery._0
				color = colors.red
			end
		end

		local lead = ""
		if found and charge < 10 then
			lead = "0"
		end

		battery:set({
			icon = { string = icon, color = color },
			label = { string = lead .. label, color = color },
		})
		battery_bracket:set({
			background = { border_color = color },
		})
	end)
end)

battery:subscribe("mouse.clicked", function(env)
	local drawing = battery:query().popup.drawing
	battery:set({ popup = { drawing = "toggle" } })

	if drawing == "off" then
		sbar.exec("pmset -g batt", function(batt_info)
			local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
			local label = found and remaining .. "h" or "No estimate"
			remaining_time:set({ label = { string = label, color = colors.orange } })
		end)
	end
end)

battery:subscribe("mouse.exited.global", function(env)
	battery:set({ popup = { drawing = false } })
end)

local battery_bracket = sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
	background = { color = colors.background, border_color = colors.green, border_width = 2 },
})

sbar.add("item", { position = "right", width = 6 })
