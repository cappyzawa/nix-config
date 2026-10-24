if displayZoom then
	displayZoom.stop()
end

package.loaded.settings = nil
local settings = require("settings")
local state = { last = "waiting" }
local applied = {}
local builtInDisplays = {}
local pending
local operation
local screenWatcher
local appWatcher

local function displayProfile()
	local screens = hs.screen.allScreens()
	if #screens == 0 then
		return nil
	end
	for _, screen in ipairs(screens) do
		local id = screen:id()
		local builtIn = builtInDisplays[id]
		if builtIn == nil then
			local ok, result = hs.osascript.javascript(
				('ObjC.import("CoreGraphics"); Boolean($.CGDisplayIsBuiltin(%d))'):format(id)
			)
			if not ok or type(result) ~= "boolean" then
				print("display-zoom", "cannot determine whether display is built-in", id)
				return nil
			end
			builtIn = result
			builtInDisplays[id] = builtIn
		end
		if not builtIn then
			return "connected"
		end
	end
	return "disconnected"
end

local function cancel()
	if pending then
		pending:stop()
		pending = nil
	end
	if operation then
		operation.timer:stop()
		operation = nil
	end
end

local function zoomMenus(app)
	local commands = { ["0"] = "reset", ["+"] = "grow", ["-"] = "shrink" }
	local menus = {}
	local function visit(nodes, path)
		for _, node in ipairs(nodes or {}) do
			if node.AXTitle then
				local nextPath = { table.unpack(path) }
				if node.AXTitle ~= "" then
					nextPath[#nextPath + 1] = node.AXTitle
				end
				local command = commands[node.AXMenuItemCmdChar]
				local modifiers = node.AXMenuItemCmdModifiers or {}
				if command and #modifiers == 1 and modifiers[1] == "cmd" then
					menus[command] = nextPath
				end
				visit(node.AXChildren, nextPath)
			else
				visit(node, path)
			end
		end
	end
	visit(app:getMenuItems(), {})
	return menus
end

local function apply()
	local app = hs.application.frontmostApplication()
	local profile = displayProfile()
	local application = app and settings.applications[app:bundleID()]
	if not profile or not application then
		return
	end
	local window = app:focusedWindow()
	local windowID = window and window:id()
	if not windowID then
		return
	end
	local key = app:pid() .. ":" .. windowID
	if application.rememberWindowZoom and applied[key] == profile then
		return
	end

	local zoom = application[profile]
	local count = math.abs(zoom.steps)
	local menus = zoomMenus(app)
	local menu = menus[zoom.steps < 0 and "shrink" or "grow"]
	if not menus.reset or (count > 0 and not menu) then
		state.last = app:bundleID() .. ": zoom menu unavailable"
		print("display-zoom", state.last)
		return
	end

	local step = 0
	applied[key] = nil
	state.last = app:bundleID() .. ": applying " .. zoom.label
	local timer = hs.timer.doEvery(0.2, function()
		local front = hs.application.frontmostApplication()
		local focusedWindow = front and front:focusedWindow()
		if
			not front
			or front:pid() ~= app:pid()
			or not focusedWindow
			or focusedWindow:id() ~= windowID
			or displayProfile() ~= profile
		then
			cancel()
			state.last = "interrupted"
			return
		end
		if not app:selectMenuItem(step == 0 and menus.reset or menu) then
			cancel()
			state.last = app:bundleID() .. ": zoom menu failed"
			print("display-zoom", state.last)
			return
		end
		if step == count then
			cancel()
			if application.rememberWindowZoom then
				applied[key] = profile
			end
			state.last = app:bundleID() .. ": applied " .. zoom.label
			print("display-zoom", state.last)
		end
		step = step + 1
	end)
	operation = { timer = timer, profile = profile }
end

local function schedule()
	cancel()
	pending = hs.timer.doAfter(0.8, function()
		pending = nil
		apply()
	end)
end

screenWatcher = hs.screen.watcher.new(function()
	builtInDisplays = {}
	if operation and operation.profile == displayProfile() then
		return
	end
	schedule()
end):start()
appWatcher = hs.application.watcher.new(function(_, event)
	if event == hs.application.watcher.activated then
		schedule()
	end
end):start()

displayZoom = {
	stop = function()
		cancel()
		screenWatcher:stop()
		appWatcher:stop()
		state.last = "stopped"
	end,
	status = function()
		return { profile = displayProfile(), last = state.last }
	end,
}

schedule()
print("display-zoom", "loaded", displayProfile())
