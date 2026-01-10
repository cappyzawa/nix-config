local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local popup_width = 250

local wifi = sbar.add("item", "widgets.wifi", {
	position = "right",
	icon = {
		string = icons.wifi.disconnected,
		color = colors.magenta,
		font = { size = 16 },
	},
	label = { drawing = false },
	padding_right = 5,
	padding_left = 5,
	update_freq = 30,
	popup = {
		align = "center",
		background = {
			color = colors.bg1,
			border_color = colors.magenta,
			border_width = 2,
		},
	},
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		font = { size = 13.0, style = settings.font.style_map["Bold"] },
		string = icons.wifi.router,
		color = colors.magenta,
	},
	width = popup_width,
	align = "center",
	label = {
		font = { style = settings.font.style_map["Bold"] },
		max_chars = 18,
		string = "????????????",
		color = colors.magenta,
	},
	background = {
		height = 2,
		color = colors.grey,
		y_offset = -15,
		border_color = colors.magenta,
	},
})

local hostname = sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		font = { size = 13.0 },
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
		color = colors.magenta,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
		color = colors.magenta,
	},
})

local ip = sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		font = { size = 13.0 },
		align = "left",
		string = "IP:",
		width = popup_width / 2,
		color = colors.magenta,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		color = colors.magenta,
	},
})

wifi:subscribe({ "wifi_change", "system_woke", "routine", "forced" }, function()
	sbar.exec("/usr/sbin/ipconfig getifaddr en0", function(result)
		local connected = result ~= ""
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.magenta or colors.grey,
			},
		})
	end)
end)

local function hide_details()
	wifi:set({ popup = { drawing = false } })
end

local function toggle_details()
	local should_draw = wifi:query().popup.drawing == "off"
	if should_draw then
		wifi:set({ popup = { drawing = true } })
		sbar.exec("/usr/sbin/networksetup -getcomputername", function(result)
			hostname:set({ label = result })
		end)
		sbar.exec("/usr/sbin/ipconfig getifaddr en0", function(result)
			ip:set({ label = result ~= "" and result or "Not connected" })
		end)
		sbar.exec("/usr/sbin/ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
			ssid:set({ label = result ~= "" and result or "Not connected" })
		end)
	else
		hide_details()
	end
end

wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
	local label = sbar.query(env.NAME).label.value
	sbar.exec('echo "' .. label .. '" | pbcopy')
	sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	sbar.delay(1, function()
		sbar.set(env.NAME, { label = { string = label, align = "right" } })
	end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)

sbar.add("bracket", "widgets.wifi.bracket", { wifi.name }, {
	background = { color = colors.bg1, border_color = colors.magenta, border_width = 2 },
})

sbar.add("item", { position = "right", width = 6 })
