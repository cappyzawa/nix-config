return {
	applications = {
		-- Chrome resets to its configured default page zoom, currently 125%.
		["com.google.Chrome"] = {
			connected = { steps = 0, label = "125%" },
			disconnected = { steps = -5, label = "75%" },
		},
		["com.openai.codex"] = {
			rememberWindowZoom = true,
			connected = { steps = 2, label = "120%" },
			disconnected = { steps = -3, label = "70%" },
		},
		["com.tinyspeck.slackmacgap"] = {
			rememberWindowZoom = true,
			connected = { steps = 2, label = "2 steps up" },
			disconnected = { steps = -3, label = "3 steps down" },
		},
		-- Claude is not installed on the trial host; verify its zoom increments there.
		["com.anthropic.claudefordesktop"] = {
			rememberWindowZoom = true,
			connected = { steps = 2, label = "2 steps up (unverified)" },
			disconnected = { steps = -3, label = "3 steps down (unverified)" },
		},
	},
}
