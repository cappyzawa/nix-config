-- Akari Night theme colors for sketchybar
return {
	-- Akari Night palette
	lantern_ember = 0xffD65A3A,
	lantern_near = 0xffD25046,
	lantern_mid = 0xffE26A3B,
	lantern_far = 0xffD4A05A,

	life = 0xff7FAF6A,
	night = 0xff7A8FA2,
	rain = 0xff6F8F8A,
	muted = 0xff8E7BA0,

	background = 0xff25231F,
	foreground = 0xffE6DED3,

	-- Functional colors
	transparent = 0x00000000,
	accent = 0xffE26A3B,

	-- Bar colors
	bar = {
		bg = 0xf025231F,
		border = 0xff25231F,
	},
	popup = {
		bg = 0xc025231F,
		border = 0xff7A8FA2,
	},

	-- Surface colors
	bg1 = 0xff2E2C28,
	bg2 = 0xff3A3834,

	grey = 0xff7A8FA2,

	-- Semantic colors
	red = 0xffD25046,
	orange = 0xffE26A3B,
	yellow = 0xffD4A05A,
	green = 0xff7FAF6A,
	cyan = 0xff6F8F8A,
	blue = 0xff7A8FA2,
	magenta = 0xff8E7BA0,
	white = 0xffE6DED3,
	black = 0xff1E1C18,

	-- Helper function
	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
