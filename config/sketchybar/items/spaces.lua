-- AeroSpace workspace integration for SketchyBar
--
-- NOTE: sbar.add("space", ...) is for macOS Mission Control, NOT AeroSpace.
-- Use sbar.add("item", ...) instead for AeroSpace workspaces.
--
-- NOTE: sbar.exec() is async and callbacks can get complex.
-- Use io.popen() for synchronous command execution when needed.

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

local spaces = {}
local space_brackets = {}
local space_spacers = {}

-- Custom event triggered by aerospace via exec-on-workspace-change
sbar.add("event", "aerospace_workspace_change")

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
		height = 34,
	},
	padding_left = 4,
	padding_right = 4,
})

-- Helper function to run command synchronously
local function run_cmd(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

-- Function to update workspace visibility and apps
local function update_spaces()
	local focused = run_cmd("aerospace list-workspaces --focused"):gsub("%s+", "")
	local windows_output = run_cmd("aerospace list-windows --all --format '%{workspace}|%{app-name}'")

	-- Parse windows per workspace
	local workspace_apps = {}
	for line in windows_output:gmatch("[^\n]+") do
		local ws, app = line:match("([^|]+)|(.+)")
		if ws and app then
			ws = ws:gsub("%s+", "")
			if not workspace_apps[ws] then
				workspace_apps[ws] = {}
			end
			table.insert(workspace_apps[ws], app)
		end
	end

	-- Update each space
	for i = 1, 9 do
		local ws_str = tostring(i)
		local has_apps = workspace_apps[ws_str] ~= nil
		local is_focused = focused == ws_str

		spaces[i]:set({
			drawing = has_apps,
			icon = { highlight = is_focused },
			label = { highlight = is_focused },
			background = {
				color = is_focused and colors_spaces[i] or colors.transparent,
			},
		})
		space_brackets[i]:set({
			drawing = has_apps,
			background = {
				color = is_focused and colors_spaces[i] or colors.background,
			},
		})
		space_spacers[i]:set({
			drawing = has_apps,
		})

		-- Update app icons
		if has_apps then
			local icon_line = ""
			for _, app in ipairs(workspace_apps[ws_str]) do
				local lookup = app_icons[app]
				local icon = lookup or app_icons["default"]
				icon_line = icon_line .. icon
			end
			spaces[i]:set({ label = icon_line })
		end
	end
end

for i = 1, 9, 1 do
	local space = sbar.add("item", "space." .. i, {
		drawing = false,
		icon = {
			font = {
				family = settings.font.numbers,
				size = 16,
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
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 2,
		padding_left = 2,
		background = {
			color = colors.transparent,
			height = 34,
			border_width = 0,
		},
	})

	-- Spacer after each space
	local spacer = sbar.add("item", "space.spacer." .. i, {
		drawing = false,
		width = 4,
	})

	spaces[i] = space
	space_spacers[i] = spacer

	-- Individual bracket for each space
	local bracket = sbar.add("bracket", "space.bracket." .. i, { space.name }, {
		drawing = false,
		background = {
			color = colors.background,
			border_color = colors_spaces[i],
			border_width = 2,
			height = 34,
		},
	})
	space_brackets[i] = bracket

	space:subscribe("aerospace_workspace_change", function(env)
		update_spaces()
	end)

	space:subscribe("mouse.clicked", function(env)
		sbar.exec("aerospace workspace " .. i)
	end)
end

-- Initial update on load
update_spaces()

sbar.add("item", { width = 6 })
