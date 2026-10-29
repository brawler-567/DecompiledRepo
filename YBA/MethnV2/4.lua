local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = { Flags = {}, Windows = {}, _z = 0 }

Library.Theme = {
	Background = Color3.fromRGB(20, 16, 20),
	Surface = Color3.fromRGB(24, 19, 24),
	Surface2 = Color3.fromRGB(28, 22, 28),
	Surface3 = Color3.fromRGB(42, 36, 43),
	Stroke = Color3.fromRGB(40, 32, 41),
	StrokeHover = Color3.fromRGB(88, 70, 90),
	Accent = Color3.fromRGB(235, 199, 246),
	AccentDark = Color3.fromRGB(24, 18, 26),
	Text = Color3.fromRGB(233, 229, 234),
	Muted = Color3.fromRGB(125, 115, 126),
	Warning = Color3.fromRGB(240, 176, 108),
	Success = Color3.fromRGB(150, 220, 170),
	Error = Color3.fromRGB(240, 120, 120),
}
Library.Assets = {
	Shadow = "rbxassetid://6014261993",
	Glow = "rbxassetid://8992230677",
	Logo = "rbxassetid://103859712365480",
}
local Theme, Assets = Library.Theme, Library.Assets

local BuilderSans = "rbxasset://fonts/families/BuilderSans.json"
Library.Fonts = {
	Regular = Font.new(BuilderSans, Enum.FontWeight.Regular),
	Medium = Font.new(BuilderSans, Enum.FontWeight.Medium),
	Bold = Font.new(BuilderSans, Enum.FontWeight.SemiBold),
}
local Fonts = Library.Fonts

local FontSources = {
	ValleySans = {
		Regular = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-Regular.ttf",
		Medium = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-Medium.ttf",
		SemiBold = "https://raw.githubusercontent.com/HelsinkiTypeStudio/valley-sans/main/fonts/ttf/ValleySans-SemiBold.ttf",
	},
}
local FontWeights = {
	Regular = { 400, Enum.FontWeight.Regular },
	Medium = { 500, Enum.FontWeight.Medium },
	SemiBold = { 600, Enum.FontWeight.SemiBold },
	Bold = { 700, Enum.FontWeight.Bold },
}

function Library:LoadFont(cfg)
	local fn = "function"
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	if type(writefile) ~= fn or type(isfile) ~= fn or typeof(getcustomasset) ~= fn then
		warn("[Airflow] custom fonts need writefile, isfile and getcustomasset")
		return false
	end
	local name = cfg.Name or "CustomFont"
	local weights = cfg.Weights or FontSources[name]
	if type(weights) ~= "table" then
		warn("[Airflow] no font weights for " .. name)
		return false
	end
	local folder = cfg.Folder or "AirFlowFonts"
	pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then makefolder(folder) end
	end)
	local faces = {}
	for weightName, url in pairs(weights) do
		local info = FontWeights[weightName]
		if info then
			local path, ok = folder .. "/" .. name .. "-" .. weightName .. ".ttf", true
			if not isfile(path) then
				ok = pcall(function() writefile(path, game:HttpGet(url)) end)
			end
			if ok then
				table.insert(faces, { name = weightName, weight = info[1], style = "normal", assetId = getcustomasset(path) })
			else
				warn("[Airflow] could not download " .. weightName .. " weight of " .. name)
			end
		end
	end
	if #faces == 0 then return false end
	local jsonPath = folder .. "/" .. name .. ".json"
	if not pcall(function() writefile(jsonPath, HttpService:JSONEncode({ name = name, faces = faces })) end) then return false end
	local family = getcustomasset(jsonPath)
	local function pick(weightName, fallback)
		local info = FontWeights[weightName]
		if info and weights[weightName] then return Font.new(family, info[2]) end
		return fallback
	end
	Fonts.Regular = pick("Regular", Fonts.Regular)
	Fonts.Medium = pick("Medium", pick("Regular", Fonts.Medium))
	Fonts.Bold = pick("SemiBold", pick("Bold", Fonts.Bold))
	return true
end

local iconLib
local najaIconLib
local NAJA_ICON_URL = "https://raw.githubusercontent.com/ErasedDiavolo/Naja/refs/heads/main/Icon"
local function loadIcons()
	if iconLib ~= nil then return iconLib end
	local ok, res = pcall(function()
		local src = game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua")
		local chunk = loadstring(src)
		if type(chunk) ~= "function" then error("icon source did not compile") end
		return chunk()
	end)
	if ok and type(res) == "table" then
		iconLib = res
	else
		iconLib = false
		warn("[Airflow] lucide icons unavailable: " .. tostring(res))
	end
	return iconLib
end
local function loadNajaIcons()
	if najaIconLib ~= nil then return najaIconLib end
	local cached
	pcall(function() cached = _G.NaJaIcons end)
	if type(cached) == "table" then
		najaIconLib = cached
		return najaIconLib
	end
	local ok, res = pcall(function()
		local src = game:HttpGet(NAJA_ICON_URL)
		local chunk = loadstring(src)
		if type(chunk) ~= "function" then error("icon source did not compile") end
		return chunk()
	end)
	if ok and type(res) == "table" then
		najaIconLib = res
		pcall(function() _G.NaJaIcons = res end)
	else
		najaIconLib = false
		warn("[Airflow] NaJa icons unavailable: " .. tostring(res))
	end
	return najaIconLib
end
function Library:PreloadIcons()
	local lucide = loadIcons()
	local naja = loadNajaIcons()
	return lucide ~= false or naja ~= false
end

local function isAssetString(s)
	return type(s) == "string" and (s:find("^rbxthumb://") or s:find("^rbxassetid://") or s:find("^rbxasset://") or s:find("^http")) ~= nil
end

local function resolveIcon(icon)
	if typeof(icon) == "table" then
		local img = icon.Image
		return img, icon.RectOffset, icon.RectSize, isAssetString(img)
	end
	if type(icon) ~= "string" then return nil end
	if isAssetString(icon) then return icon, nil, nil, true end
	local forceNaja = icon:match("^naja:(.+)$")
	local forceLucide = icon:match("^lucide:(.+)$")
	local name = forceNaja or forceLucide or icon
	if forceNaja then
		local lib = loadNajaIcons()
		local entry = lib and lib[name]
		if type(entry) == "string" then return entry, nil, nil, false end
		warn("[Airflow] unknown NaJa icon: " .. name)
		return nil
	end
	if not forceLucide then
		local naja = loadNajaIcons()
		local entry = naja and naja[name]
		if type(entry) == "string" then return entry, nil, nil, false end
	end
	local lib = loadIcons()
	if not lib then return nil end
	local entry = lib.Icons and lib.Icons[name] or lib[name]
	if type(entry) == "table" then
		local img = entry.Image
		if type(img) == "number" then img = "rbxassetid://" .. tostring(img) end
		local sheet = lib.Spritesheets and lib.Spritesheets[tostring(img)] or img
		return sheet, entry.ImageRectPosition, entry.ImageRectSize, false
	elseif type(entry) == "string" then
		return entry, nil, nil, false
	end
	warn("[Airflow] unknown icon: " .. name)
	return nil
end

local function setIcon(img, icon)
	local image, off, size, raw = resolveIcon(icon)
	if not image then return false end
	img.Image = image
	img.ImageRectOffset = off or Vector2.zero
	img.ImageRectSize = size or Vector2.zero
	if raw then img.ImageColor3 = Color3.new(1, 1, 1) end
	return raw
end

local Touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
Library.Touch = Touch
local ROW_H = Touch and 54 or 48
local DESC_H = Touch and 70 or 64
local OPT_H = Touch and 40 or 34
local CTRL_H = Touch and 34 or 28
local PILL_H = 40
local PILL_TOP = 14

local SPRING = Enum.EasingStyle.Back
local LIQUID = Enum.EasingStyle.Exponential
local QUINT = Enum.EasingStyle.Quint

local infoCache = {}
local function tween(obj, props, time, style, dir)
	time = time or 0.25
	if time <= 0 then
		for k, v in pairs(props) do obj[k] = v end
		return nil
	end
	style = style or QUINT
	dir = dir or Enum.EasingDirection.Out
	local key = time .. style.Name .. dir.Name
	local info = infoCache[key]
	if not info then
		info = TweenInfo.new(time, style, dir)
		infoCache[key] = info
	end
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props.Parent then o.Parent = props.Parent end
	return o
end

local function corner(p, r) return new("UICorner", { CornerRadius = r or UDim.new(0, 8), Parent = p }) end
local function stroke(p, color, transparency, thickness)
	return new("UIStroke", {
		Color = color or Theme.Stroke, Transparency = transparency or 0, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p,
	})
end
local function pad(p, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), Parent = p,
	})
end
local function mkText(props)
	local base = {
		BackgroundTransparency = 1, TextColor3 = Theme.Text, TextSize = 14, FontFace = Fonts.Medium,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for k, v in pairs(props) do base[k] = v end
	return new("TextLabel", base)
end
local function glow(parent, size, pos, transparency, rotation)
	local g = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = pos, Size = size, BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Color3.fromRGB(226, 218, 230), ImageTransparency = transparency,
		ZIndex = 0, Parent = parent,
	})
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Theme.Accent), Rotation = rotation or 90, Parent = g })
	return g
end
local function sheen(parent)
	return new("Frame", {
		Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = .93, BorderSizePixel = 0, ZIndex = 0, Parent = parent,
	})
end
local function iconBox(parent, icon, color, pos)
	local box = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = pos, Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = parent })
	local img = new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, Parent = box })
	setIcon(img, icon)
	return box, img
end

local function getGuiParent()
	local ui
	pcall(function() if typeof(gethui) == "function" then ui = gethui() end end)
	if typeof(ui) == "Instance" then return ui end
	local core
	pcall(function()
		core = game:GetService("CoreGui")
		local f = Instance.new("Folder")
		f.Parent = core
		f:Destroy()
	end)
	if core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local lastInsetT, inset = nil, Vector2.zero
local function mouse()
	local t = time()
	if lastInsetT ~= t then
		lastInsetT = t
		inset = GuiService:GetGuiInset()
	end
	return UIS:GetMouseLocation() - inset
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function fire(cb, ...)
	if type(cb) ~= "function" then return end
	local ok, err = pcall(cb, ...)
	if not ok then warn("[Airflow] callback error: " .. tostring(err)) end
end
local function inside(point, gui)
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
end

local KeyNames = {
	[Enum.KeyCode.LeftControl] = "LCtrl", [Enum.KeyCode.RightControl] = "RCtrl",
	[Enum.KeyCode.LeftShift] = "LShift", [Enum.KeyCode.RightShift] = "RShift",
	[Enum.KeyCode.LeftAlt] = "LAlt", [Enum.KeyCode.RightAlt] = "RAlt",
	[Enum.KeyCode.Return] = "Enter", [Enum.KeyCode.Escape] = "Esc", [Enum.KeyCode.Backspace] = "Backspace",
}
local function keyName(k)
	if k == nil then return "None" end
	return KeyNames[k] or k.Name
end

local function snapper(min, max, step)
	local decimals = 0
	local s = tostring(step)
	local dot = s:find("%.")
	if dot then decimals = #s - dot end
	local fmt = "%." .. decimals .. "f"
	return {
		snap = function(v)
			v = math.floor(v / step + .5) * step
			return math.clamp(v, min, max)
		end,
		format = function(v) return string.format(fmt, v) end,
	}
end

local function norm(opt, aliases)
	local out = {}
	if type(opt) == "string" then
		out.Name = opt
	elseif type(opt) == "table" then
		for k, v in pairs(opt) do out[k] = v end
	end
	for alias, target in pairs(aliases or {}) do
		if out[target] == nil and out[alias] ~= nil then out[target] = out[alias] end
	end
	if out.Range then
		out.Min = out.Min or out.Range[1]
		out.Max = out.Max or out.Range[2]
	end
	return out
end

-- ===================================================================
-- Theme engine: presets, live re-skin and config persistence.
-- Colours are baked into instances when they are created, so a theme switch
-- mutates Library.Theme in place and repaints every live instance
-- (old colour -> new colour). Anything that caches a colour registers a hook.
-- ===================================================================
local themeHooks = setmetatable({}, { __mode = "k" })
local THEME_KEYS = { "Background", "Surface", "Surface2", "Surface3", "Stroke", "StrokeHover", "Accent", "AccentDark", "Text", "Muted", "Warning", "Success", "Error" }
local THEME_PROPS = {
	Frame = { "BackgroundColor3" }, CanvasGroup = { "BackgroundColor3" },
	TextLabel = { "BackgroundColor3", "TextColor3" }, TextButton = { "BackgroundColor3", "TextColor3" },
	TextBox = { "BackgroundColor3", "TextColor3", "PlaceholderColor3" },
	ImageLabel = { "BackgroundColor3", "ImageColor3" }, ImageButton = { "BackgroundColor3", "ImageColor3" },
	ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" }, ViewportFrame = { "BackgroundColor3" },
	UIStroke = { "Color" },
}
Library.Themes = {
	Orchid = table.clone(Library.Theme),
	Midnight = {
		Background = Color3.fromRGB(13, 16, 24), Surface = Color3.fromRGB(17, 21, 31), Surface2 = Color3.fromRGB(21, 26, 38),
		Surface3 = Color3.fromRGB(34, 41, 58), Stroke = Color3.fromRGB(30, 37, 53), StrokeHover = Color3.fromRGB(66, 82, 118),
		Accent = Color3.fromRGB(122, 162, 255), AccentDark = Color3.fromRGB(12, 16, 28), Text = Color3.fromRGB(226, 232, 245),
		Muted = Color3.fromRGB(110, 121, 145),
	},
	Ocean = {
		Background = Color3.fromRGB(11, 19, 22), Surface = Color3.fromRGB(14, 24, 28), Surface2 = Color3.fromRGB(18, 30, 35),
		Surface3 = Color3.fromRGB(30, 47, 54), Stroke = Color3.fromRGB(27, 42, 48), StrokeHover = Color3.fromRGB(58, 96, 108),
		Accent = Color3.fromRGB(94, 214, 236), AccentDark = Color3.fromRGB(8, 22, 28), Text = Color3.fromRGB(224, 238, 242),
		Muted = Color3.fromRGB(106, 127, 134),
	},
	Emerald = {
		Background = Color3.fromRGB(12, 20, 17), Surface = Color3.fromRGB(15, 25, 21), Surface2 = Color3.fromRGB(19, 31, 26),
		Surface3 = Color3.fromRGB(31, 48, 41), Stroke = Color3.fromRGB(28, 43, 37), StrokeHover = Color3.fromRGB(60, 98, 82),
		Accent = Color3.fromRGB(110, 231, 183), AccentDark = Color3.fromRGB(10, 24, 18), Text = Color3.fromRGB(225, 238, 231),
		Muted = Color3.fromRGB(108, 128, 118),
	},
	Crimson = {
		Background = Color3.fromRGB(21, 14, 16), Surface = Color3.fromRGB(26, 17, 19), Surface2 = Color3.fromRGB(32, 21, 24),
		Surface3 = Color3.fromRGB(50, 34, 38), Stroke = Color3.fromRGB(46, 30, 34), StrokeHover = Color3.fromRGB(104, 64, 72),
		Accent = Color3.fromRGB(255, 128, 148), AccentDark = Color3.fromRGB(28, 12, 16), Text = Color3.fromRGB(240, 228, 231),
		Muted = Color3.fromRGB(131, 112, 117),
	},
	Amber = {
		Background = Color3.fromRGB(21, 17, 12), Surface = Color3.fromRGB(26, 21, 15), Surface2 = Color3.fromRGB(32, 26, 18),
		Surface3 = Color3.fromRGB(50, 42, 30), Stroke = Color3.fromRGB(46, 38, 26), StrokeHover = Color3.fromRGB(104, 86, 56),
		Accent = Color3.fromRGB(255, 196, 102), AccentDark = Color3.fromRGB(30, 20, 8), Text = Color3.fromRGB(240, 234, 224),
		Muted = Color3.fromRGB(132, 122, 106),
	},
	Slate = {
		Background = Color3.fromRGB(16, 16, 17), Surface = Color3.fromRGB(21, 21, 22), Surface2 = Color3.fromRGB(26, 26, 28),
		Surface3 = Color3.fromRGB(40, 40, 43), Stroke = Color3.fromRGB(38, 38, 41), StrokeHover = Color3.fromRGB(84, 84, 90),
		Accent = Color3.fromRGB(236, 236, 240), AccentDark = Color3.fromRGB(18, 18, 20), Text = Color3.fromRGB(232, 232, 235),
		Muted = Color3.fromRGB(122, 122, 128),
	},
	Daylight = {
		Background = Color3.fromRGB(238, 235, 243), Surface = Color3.fromRGB(246, 244, 249), Surface2 = Color3.fromRGB(252, 251, 254),
		Surface3 = Color3.fromRGB(224, 220, 232), Stroke = Color3.fromRGB(219, 214, 228), StrokeHover = Color3.fromRGB(170, 162, 190),
		Accent = Color3.fromRGB(124, 77, 214), AccentDark = Color3.fromRGB(250, 248, 255), Text = Color3.fromRGB(34, 28, 44),
		Muted = Color3.fromRGB(128, 120, 142), Warning = Color3.fromRGB(214, 130, 40), Success = Color3.fromRGB(46, 160, 96),
		Error = Color3.fromRGB(214, 72, 72),
	},
}
Library._themeOrder = { "Orchid", "Midnight", "Ocean", "Emerald", "Crimson", "Amber", "Slate", "Daylight" }
Library._themeState = { Preset = "Orchid", Accent = nil }
Library._onTheme = {}
local themeApplied = table.clone(Library.Theme)
local themeStale, themeToken, themeLast, themeQueued, themeWave = {}, 0, 0, false, false
local LIGHT_INK = Color3.fromRGB(247, 245, 249)

local function themeLum(c) return .299 * c.R + .587 * c.G + .114 * c.B end

local function themeBuild(state)
	local base = Library.Themes[state.Preset] or Library.Themes.Orchid
	local out = table.clone(Library.Themes.Orchid)
	for k, v in pairs(base) do out[k] = v end
	if typeof(state.Accent) == "Color3" then
		out.Accent = state.Accent
		local ink = base.AccentDark or out.AccentDark
		if themeLum(state.Accent) > .5 then
			out.AccentDark = themeLum(ink) < .35 and ink or Color3.fromRGB(22, 18, 26)
		else
			out.AccentDark = LIGHT_INK
		end
	end
	return out
end

local function themeMapper(from, to, guard)
	local list = {}
	for _, k in ipairs(THEME_KEYS) do
		local a, b = from[k], to[k]
		if a and b and a ~= b then
			local clash = false
			if guard then
				for _, j in ipairs(THEME_KEYS) do
					if to[j] == a then clash = true break end
				end
			end
			if not clash then list[#list + 1] = { a, b } end
		end
	end
	return function(c)
		for i = 1, #list do
			local e = list[i]
			if e[1] == c then return e[2] end
		end
		return c
	end
end

local function themePaint(inst, map)
	if inst:GetAttribute("AF_NoTheme") then return end
	local cls = inst.ClassName
	local props = THEME_PROPS[cls]
	if props then
		for i = 1, #props do
			local p = props[i]
			local cur = inst[p]
			local nxt = map(cur)
			if nxt ~= cur then inst[p] = nxt end
		end
	elseif cls == "UIGradient" then
		local out, changed = {}, false
		for i, kp in ipairs(inst.Color.Keypoints) do
			local nc = map(kp.Value)
			if nc ~= kp.Value then changed = true end
			out[i] = ColorSequenceKeypoint.new(kp.Time, nc)
		end
		if changed then inst.Color = ColorSequence.new(out) end
	end
end

local function themeWalk(inst, map)
	themePaint(inst, map)
	if inst.ClassName == "ViewportFrame" then return end
	for _, c in ipairs(inst:GetChildren()) do themeWalk(c, map) end
end

local function themeRoots()
	local out, seen = {}, {}
	local function add(r)
		if typeof(r) == "Instance" and not seen[r] then
			seen[r] = true
			out[#out + 1] = r
		end
	end
	for _, w in ipairs(Library.Windows) do
		add(w.Gui)
		for _, fl in ipairs(w._floats or {}) do add(fl.Gui) end
		for _, r in ipairs(w._themeRoots or {}) do add(r) end
	end
	return out
end

local function themeRun(map)
	for _, r in ipairs(themeRoots()) do
		local ok, err = pcall(themeWalk, r, map)
		if not ok then warn("[Airflow] theme repaint error: " .. tostring(err)) end
	end
	for _, fn in pairs(themeHooks) do pcall(fn, map) end
end

local function themeApply(target)
	local from = themeApplied
	for _, k in ipairs(THEME_KEYS) do Theme[k] = target[k] end
	themeApplied = table.clone(target)
	local tc = Library._toastColors
	if tc then
		tc.Success, tc.Warning, tc.Error, tc.Info = Theme.Success, Theme.Warning, Theme.Error, Theme.Accent
	end
	themeRun(themeMapper(from, target))
	table.insert(themeStale, from)
	while #themeStale > 4 do table.remove(themeStale, 1) end
	themeToken += 1
	local token = themeToken
	-- tweens that were already running finish on the old colours, so repaint once more when they are done
	task.delay(.9, function()
		if token ~= themeToken then return end
		local stale = themeStale
		themeStale = {}
		for _, old in ipairs(stale) do themeRun(themeMapper(old, themeApplied, true)) end
	end)
end

local function themeFlush()
	themeQueued = false
	themeLast = os.clock()
	themeApply(themeBuild(Library._themeState))
	if themeWave then
		themeWave = false
		for _, w in ipairs(Library.Windows) do
			if not w._destroyed and w._introDone and w.Open and not w._pill then pcall(w._wave, w) end
		end
	end
end

function Library:_queueTheme()
	if #Library.Windows == 0 then themeFlush() return end
	local wait = .16 - (os.clock() - themeLast)
	if wait <= 0 then themeFlush() return end
	if themeQueued then return end
	themeQueued = true
	task.delay(wait, themeFlush)
end

function Library._snapTheme() themeApplied = table.clone(Theme) end

function Library:_themeChanged(source)
	for _, w in ipairs(Library.Windows) do w:_autoSave() end
	for _, fn in ipairs(Library._onTheme) do pcall(fn, source) end
end

function Library:AddTheme(name, palette)
	local p = {}
	for _, k in ipairs(THEME_KEYS) do
		if typeof(palette[k]) == "Color3" then p[k] = palette[k] end
	end
	if not Library.Themes[name] then table.insert(Library._themeOrder, name) end
	Library.Themes[name] = p
	return p
end

function Library:GetThemes() return table.clone(Library._themeOrder) end
function Library:GetPalette() return themeBuild(Library._themeState) end
function Library:GetTheme() return Library._themeState.Preset, Library._themeState.Accent end

function Library:SetTheme(theme, silent, source)
	if type(theme) == "table" then
		local name = theme.Name or "Custom"
		Library:AddTheme(name, theme)
		theme = name
	end
	if type(theme) ~= "string" or not Library.Themes[theme] then
		warn("[Airflow] unknown theme: " .. tostring(theme))
		return false
	end
	local st = Library._themeState
	st.Preset, st.Accent = theme, nil
	themeWave = true
	Library:_queueTheme()
	if not silent then Library:_themeChanged(source or "api") end
	return true
end

function Library:SetAccent(color, silent, source)
	if color ~= nil and typeof(color) ~= "Color3" then return false end
	Library._themeState.Accent = color
	Library:_queueTheme()
	if not silent then Library:_themeChanged(source or "api") end
	return true
end

-- one pseudo flag so the chosen theme travels with every saved config
Library.Flags.AF_Theme = {
	_type = "Theme", _listeners = {},
	Get = function()
		local st = Library._themeState
		local a = st.Accent
		return { Preset = st.Preset, Accent = a and { a.R, a.G, a.B } or nil }
	end,
	Set = function(_, v)
		local st = Library._themeState
		if type(v) == "string" then v = { Preset = v } end
		if type(v) ~= "table" then return end
		if type(v.Preset) == "string" and Library.Themes[v.Preset] then st.Preset = v.Preset end
		local a = v.Accent
		if type(a) == "table" and tonumber(a[1]) and tonumber(a[2]) and tonumber(a[3]) then
			st.Accent = Color3.new(a[1], a[2], a[3])
		else
			st.Accent = nil
		end
		Library:_queueTheme()
		Library:_themeChanged("config")
	end,
}

local ripplePool = {}
local function ripple(parent)
	local m = mouse()
	local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
	local r = table.remove(ripplePool)
	if not r then
		r = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 })
		corner(r, UDim.new(1, 0))
	end
	r.Position = UDim2.fromOffset(m.X - parent.AbsolutePosition.X, m.Y - parent.AbsolutePosition.Y)
	r.Size = UDim2.fromOffset(0, 0)
	r.BackgroundTransparency = .82
	r.BackgroundColor3 = Theme.Accent
	r.ZIndex = parent.ZIndex + 1
	r.Parent = parent
	tween(r, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, .6, LIQUID)
	task.delay(.6, function()
		r.Parent = nil
		if #ripplePool < 4 then table.insert(ripplePool, r) else r:Destroy() end
	end)
end

local function pulse(st)
	if not st then return end
	tween(st, { Color = Theme.Accent, Transparency = .2 }, .08)
	task.delay(.12, function() tween(st, { Color = Theme.Stroke, Transparency = 0 }, .4) end)
end

local function hover(card, st)
	local ref = { base = card.BackgroundColor3, entered = false }
	ref.lifted = ref.base:Lerp(Theme.Surface3, .35)
	themeHooks[card] = function(map)
		if not card.Parent then
			themeHooks[card] = nil
			return
		end
		ref.base = map(ref.base)
		ref.lifted = ref.base:Lerp(Theme.Surface3, .35)
		card.BackgroundColor3 = ref.entered and ref.lifted or ref.base
	end
	card.MouseEnter:Connect(function()
		ref.entered = true
		tween(st, { Color = Theme.StrokeHover }, .15)
		tween(card, { BackgroundColor3 = ref.lifted }, .2)
	end)
	card.MouseLeave:Connect(function()
		ref.entered = false
		tween(st, { Color = Theme.Stroke }, .3)
		tween(card, { BackgroundColor3 = ref.base }, .35)
	end)
end

local function makeChevron(parent, anchorX, offsetX)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(anchorX, .5), Position = UDim2.new(anchorX, offsetX, .5, 0),
		Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = parent,
	})
	local img = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, ImageColor3 = Theme.Muted, ScaleType = Enum.ScaleType.Fit, Parent = holder,
	})
	setIcon(img, "chevron-down")
	local api = {}
	if img.Image ~= "" then
		function api:Set(open)
			tween(img, { Rotation = open and 180 or 0, ImageColor3 = open and Theme.Accent or Theme.Muted }, .45, SPRING)
		end
		return api
	end
	img:Destroy()
	local arrow = mkText {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(18, 18),
		Text = "›", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Muted, Rotation = 90, Parent = holder,
	}
	function api:Set(open)
		tween(arrow, { Rotation = open and 270 or 90, TextColor3 = open and Theme.Accent or Theme.Muted }, .4, SPRING)
	end
	return api
end

local function glyph(parent, icon, fallback, pos, size)
	size = size or 20
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(0, .5), Position = pos, Size = UDim2.fromOffset(size, size), BackgroundColor3 = Theme.Surface3,
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = parent,
	})
	corner(b, UDim.new(0, 6))
	local sc = new("UIScale", { Parent = b })
	local img = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(size - 6, size - 6),
		BackgroundTransparency = 1, ImageColor3 = Theme.Muted, ScaleType = Enum.ScaleType.Fit, Parent = b,
	})
	setIcon(img, icon)
	local txt
	if img.Image == "" then
		img:Destroy()
		img = nil
		txt = mkText {
			Size = UDim2.fromScale(1, 1), Text = fallback, TextSize = size - 4, TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None, Parent = b,
		}
	end
	local function ink(c)
		if img then tween(img, { ImageColor3 = c }, .15) else tween(txt, { TextColor3 = c }, .15) end
	end
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0 }, .15)
		ink(Theme.Accent)
		tween(sc, { Scale = 1.12 }, .4, SPRING)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 1 }, .25)
		ink(Theme.Muted)
		tween(sc, { Scale = 1 }, .4, SPRING)
	end)
	b.MouseButton1Down:Connect(function() tween(sc, { Scale = .86 }, .1) end)
	b.MouseButton1Up:Connect(function() tween(sc, { Scale = 1.12 }, .5, SPRING) end)
	return b
end

local function popIn(obj, delay, force)
	if not obj.Visible and not obj:GetAttribute("AF_Pop") and not force then return end
	local token = (obj:GetAttribute("AF_PopToken") or 0) + 1
	obj:SetAttribute("AF_PopToken", token)
	obj:SetAttribute("AF_Pop", true)
	obj.Visible = false
	task.delay(delay, function()
		if not obj.Parent or obj:GetAttribute("AF_PopToken") ~= token then return end
		local s = obj:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = obj })
		s.Scale = .9
		obj.Visible = true
		obj:SetAttribute("AF_Pop", nil)
		tween(s, { Scale = 1 }, .55, SPRING)
	end)
end

local function fadeIn(root)
	local list = {}
	local function walk(o)
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then
				table.insert(list, { c, "TextTransparency", c.TextTransparency })
			elseif c:IsA("ImageLabel") or c:IsA("ImageButton") then
				table.insert(list, { c, "ImageTransparency", c.ImageTransparency })
			elseif c:IsA("UIStroke") then
				table.insert(list, { c, "Transparency", c.Transparency })
			elseif c:IsA("Frame") then
				table.insert(list, { c, "BackgroundTransparency", c.BackgroundTransparency })
			end
			walk(c)
		end
	end
	if root:IsA("Frame") then table.insert(list, { root, "BackgroundTransparency", root.BackgroundTransparency }) end
	walk(root)
	for _, e in ipairs(list) do
		e[1][e[2]] = 1
		tween(e[1], { [e[2]] = e[3] }, .3)
	end
end

local floatHosts = setmetatable({}, { __mode = "k" })

local function scaleFor(win, inst)
	local cur = inst
	while cur do
		if floatHosts[cur] then
			local s = cur:FindFirstChildOfClass("UIScale")
			return s and math.max(s.Scale, .01) or 1
		end
		cur = cur.Parent
	end
	return math.max(win.Scale.Scale, .01)
end

local function makeDragger(root, scale, opts)
	local d = { Active = false }
	local tiltTarget = opts.tiltTarget or root
	local grab, vel, tilt = Vector2.zero, Vector2.zero, 0
	local function pointer()
		if type(opts.pointer) == "function" then return opts.pointer() end
		return mouse()
	end
	local function center()
		local g = root:FindFirstAncestorOfClass("ScreenGui")
		return root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint - (g and g.AbsolutePosition or Vector2.zero)
	end
	d.Center = center
	function d:Begin(from, centerOverride)
		d.Active = true
		grab = (from or pointer()) - (centerOverride or center())
		vel, tilt = Vector2.zero, 0
		tween(scale, { Scale = opts.base() * (opts.lift or 1.018) }, .4, SPRING)
		if opts.onLift then opts.onLift(true) end
	end
	function d:Step(dt)
		if not d.Active then return end
		local cur = center()
		local p = cur:Lerp(pointer() - grab, 1 - math.exp(-dt * 24))
		root.Position = UDim2.fromOffset(p.X, p.Y)
		local v = (p - cur) / math.max(dt, 1 / 240)
		vel = vel:Lerp(v, 1 - math.exp(-dt * 12))
		local tiltMax = opts.tiltMax or 2.5
		local tiltMultiplier = opts.tiltMultiplier or .0016
		tilt += (math.clamp(vel.X * tiltMultiplier, -tiltMax, tiltMax) - tilt) * (1 - math.exp(-dt * 10))
		if opts.tilt ~= false then
			tiltTarget.Rotation = tilt
		else
			tiltTarget.Rotation = 0
		end
	end
	function d:End()
		if not d.Active then return end
		d.Active = false
		tween(tiltTarget, { Rotation = 0 }, .8, SPRING)
		tween(scale, { Scale = opts.base() }, .6, SPRING)
		if opts.onLift then opts.onLift(false) end
		if opts.onDrop then opts.onDrop() end
	end
	return d
end

local function makeBlur()
	local ok, b = pcall(function()
		local x = Instance.new("BlurEffect")
		x.Name = "AirflowBlur"
		x.Size = 0
		x.Parent = Lighting
		return x
	end)
	return ok and b or nil
end

local function register(container, cfg, obj, frame, kind)
	obj._type = kind
	obj._frame = frame
	obj._listeners = obj._listeners or {}
	local win = container and container.Window
	if cfg.Flag then
		Library.Flags[cfg.Flag] = obj
		if win then
			local cb = cfg.Callback
			cfg.Callback = function(...)
				if type(cb) == "function" then cb(...) end
				win:_autoSave()
			end
		end
	end
	function obj:Destroy()
		if obj._destroyed then return end
		obj._destroyed = true
		for _, fn in ipairs(obj._listeners) do fn() end
		obj._listeners = {}
		if cfg.Flag and Library.Flags[cfg.Flag] == obj then Library.Flags[cfg.Flag] = nil end
		if win then
			win._controlsDirty = true
			local meta = obj._quickMeta
			if meta then
				local floating = win._quickFloats and win._quickFloats[meta]
				if floating then floating:Destroy() end
				for i, item in ipairs(win._quickItems or {}) do
					if item == meta then table.remove(win._quickItems, i) break end
				end
				if type(meta._pickerRemove) == "function" then pcall(meta._pickerRemove) end
			end
		end
		if frame then frame:Destroy() end
	end
	local quickKinds = { Button = true, Toggle = true, Keybind = true, Slider = true, Stepper = true, Dropdown = true }
	if win and quickKinds[kind] and cfg.Quickable ~= false and not (kind == "Dropdown" and cfg.Multi == true) then
		local meta = {
			Name = tostring(cfg.Name or kind), Desc = tostring(cfg.Desc or ""), Kind = kind,
			Object = obj, Config = cfg,
		}
		if kind == "Button" then
			meta.Activate = function() fire(cfg.Callback) end
		elseif kind == "Toggle" then
			meta.Activate = function() if not obj._destroyed then obj:Set(not obj:Get()) end end
		elseif kind == "Keybind" then
			meta.Activate = function() if not obj._destroyed and obj.Value ~= nil then fire(cfg.Callback, obj.Value) end end
		elseif kind == "Slider" or kind == "Stepper" then
			local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
			local step = tonumber(cfg.Step) or 1
			meta.Activate = function()
				if obj._destroyed then return end
				local current = tonumber(obj:Get()) or min
				local nextValue = current + step
				if nextValue > max then nextValue = min end
				obj:Set(nextValue)
			end
		elseif kind == "Dropdown" then
			meta.Activate = function()
				if obj._destroyed then return end
				local options = cfg.Options or {}
				if #options == 0 then return end
				local current, index = obj:Get(), 0
				for i, option in ipairs(options) do if option == current then index = i break end end
				obj:Set(options[index % #options + 1])
			end
		end
		obj._quickMeta = meta
		win._quickItems = win._quickItems or {}
		win._quickFloats = win._quickFloats or {}
		table.insert(win._quickItems, meta)
	end
	return obj
end

local Container = {}
Container.__index = Container

function Container:_nextOrder()
	self._order += 1
	return self._order
end

local function makeCard(self, class, height)
	local props = {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(), Parent = self.List,
	}
	if class == "TextButton" then
		props.AutoButtonColor = false
		props.Text = ""
	end
	local card = new(class, props)
	card:SetAttribute("NoDrag", true)
	corner(card)
	local st = stroke(card, Theme.Stroke)
	return card, st
end

local function titles(card, name, desc, rightPad, leftOff)
	leftOff = leftOff or 0
	local x = 14 + leftOff
	if desc then
		local top = (DESC_H - 38) / 2
		local t = mkText { Position = UDim2.fromOffset(x, top), Size = UDim2.new(1, -(x + rightPad), 0, 18), Text = name, Parent = card }
		local s = mkText {
			Position = UDim2.fromOffset(x, top + 20), Size = UDim2.new(1, -(x + rightPad), 0, 17), Text = desc,
			TextSize = 13, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = card,
		}
		return t, s
	end
	local t = mkText { Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -(x + rightPad), 1, 0), Text = name, Parent = card }
	return t, nil
end

local function setPad(title, sub, pad_)
	if title then title.Size = UDim2.new(1, -(14 + pad_), title.Size.Y.Scale, title.Size.Y.Offset) end
	if sub then sub.Size = UDim2.new(1, -(14 + pad_), 0, sub.Size.Y.Offset) end
end

local function baseCard(self, cfg, aliases, class, rightPad, fallback)
	cfg = norm(cfg, aliases)
	local h = cfg.Desc and DESC_H or ROW_H
	local card, st = makeCard(self, class or "Frame", h)
	hover(card, st)
	local title, sub
	if rightPad then title, sub = titles(card, cfg.Name or fallback, cfg.Desc, rightPad) end
	return cfg, card, st, h, title, sub
end

local QUICK_KINDS = {
	Button = { Label = "BUTTON", Icon = "zap", Fallback = "✦", W = 188, H = 54 },
	Toggle = { Label = "TOGGLE", Icon = "power", Fallback = "⏻", W = 206, H = 54 },
	Keybind = { Label = "KEYBIND", Icon = "keyboard", Fallback = "⌨", W = 196, H = 54 },
	Slider = { Label = "SLIDER", Icon = "sliders-horizontal", Fallback = "≡", W = 244, H = 74 },
	Stepper = { Label = "STEPPER", Icon = "plus", Fallback = "±", W = 232, H = 80 },
	Dropdown = { Label = "DROPDOWN", Icon = "list", Fallback = "☷", W = 232, H = 80 },
}
local QUICK_ORDER = { "Button", "Toggle", "Keybind", "Slider", "Stepper", "Dropdown" }
local QUICK_PLURAL = { Button = "Buttons", Toggle = "Toggles", Keybind = "Keybinds", Slider = "Sliders", Stepper = "Steppers", Dropdown = "Dropdowns" }

local function removeFromFloats(win, api)
	for i, floating in ipairs(win._floats or {}) do
		if floating == api then table.remove(win._floats, i) break end
	end
end

local function quickScreen(win)
	local screen = Vector2.new(800, 600)
	pcall(function()
		if win.Gui and win.Gui.AbsoluteSize then screen = win.Gui.AbsoluteSize end
	end)
	if screen.X < 100 or screen.Y < 100 then
		local camera = workspace.CurrentCamera
		if camera then screen = camera.ViewportSize end
	end
	return screen
end

local function quickNumber(cfg, value)
	value = tonumber(value) or 0
	local step = tostring(cfg.Step or 1)
	local dot = step:find("%.")
	local decimals = dot and (#step - dot) or 0
	return string.format("%." .. decimals .. "f", value) .. (cfg.Suffix or "")
end

local function quickIcon(parent, iconName, fallback, size, color, z)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1, ZIndex = z or 4, Parent = parent,
	})
	local img = new("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageColor3 = color,
		ScaleType = Enum.ScaleType.Fit, ZIndex = z or 4, Parent = holder,
	})
	setIcon(img, iconName)
	local txt
	if img.Image == "" then
		img:Destroy()
		img = nil
		txt = mkText {
			Size = UDim2.fromScale(1, 1), Text = fallback, TextSize = size, TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None, ZIndex = z or 4, Parent = holder,
		}
	end
	local ctl = { Holder = holder }
	function ctl.Color(c, t)
		if img then tween(img, { ImageColor3 = c }, t or .2) elseif txt then tween(txt, { TextColor3 = c }, t or .2) end
	end
	return ctl
end

local function quickWave(parent, cx, cy, size, transparency, z)
	local wave = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = transparency or .8, BorderSizePixel = 0,
		ZIndex = z or 3, Parent = parent,
	})
	corner(wave, UDim.new(1, 0))
	tween(wave, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, .8, LIQUID)
	task.delay(.85, function() if wave.Parent then wave:Destroy() end end)
end

local function quickPress(button, scale)
	button.MouseEnter:Connect(function() tween(scale, { Scale = 1.08 }, .4, SPRING) end)
	button.MouseLeave:Connect(function() tween(scale, { Scale = 1 }, .4, SPRING) end)
	button.MouseButton1Down:Connect(function() tween(scale, { Scale = .88 }, .1) end)
	button.MouseButton1Up:Connect(function() tween(scale, { Scale = 1.05 }, .45, SPRING) end)
end

local function createQuickShortcut(win, meta)
	win._quickFloats = win._quickFloats or {}
	if win._quickFloats[meta] and not win._quickFloats[meta].Closed then return win._quickFloats[meta] end
	local obj, cfg, kind = meta.Object, meta.Config or {}, meta.Kind
	if not obj or obj._destroyed then return nil end
	local spec = QUICK_KINDS[kind] or QUICK_KINDS.Button
	local width, height = spec.W, spec.H
	local screen, count = quickScreen(win), 0
	for _, floating in pairs(win._quickFloats) do if floating and not floating.Closed and not floating._destroyed then count += 1 end end
	local slotH, colW, firstY = math.max(height + 24, 88), math.max(width + 22, 254), 112
	local perColumn = math.max(1, math.floor((screen.Y - firstY - 12) / slotH))
	local column, slot = math.floor(count / perColumn), count % perColumn
	local cx = math.clamp(screen.X - 14 - width / 2 - column * colW, width / 2 + 8, math.max(width / 2 + 8, screen.X - width / 2 - 8))
	local cy = math.clamp(firstY + slot * slotH + height / 2, height / 2 + 8, math.max(height / 2 + 8, screen.Y - height / 2 - 8))
	local rippleSize = math.sqrt(width * width + height * height) * 2 + 24

	local gui = new("ScreenGui", { Name = "AirflowQuickShortcut", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1200 + Library._z, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	Library._z += 1
	pcall(function() if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then syn.protect_gui(gui) end end)
	gui.Parent = win.Gui and win.Gui.Parent or getGuiParent()
	if type(Library._translationHookRoot) == "function" then pcall(Library._translationHookRoot, Library, gui) end
	local root = new("Frame", { Name = "QuickShortcut", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx + 36, cy), Size = UDim2.fromOffset(width, height), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
	local scale = new("UIScale", { Scale = .72, Parent = root })
	local shadow = new("ImageLabel", {
		Position = UDim2.fromOffset(-20, -16), Size = UDim2.new(1, 40, 1, 34), BackgroundTransparency = 1,
		Image = Assets.Shadow, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0, Parent = root,
	})
	local body = new("CanvasGroup", { Name = "QuickBody", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, GroupTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = 2, Parent = root })
	corner(body, UDim.new(0, 16))
	local bodyStroke = stroke(body, Theme.Stroke, .55)
	new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(170, 100), BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .9, ZIndex = 1, Parent = body })

	local function front()
		Library._z += 1
		gui.DisplayOrder = 1200 + Library._z
	end
	local dragArea = new("TextButton", { Name = "DragArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2, Parent = body })
	local chip = new("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, ZIndex = 4, Parent = body })
	corner(chip, UDim.new(1, 0))
	local chipScale = new("UIScale", { Parent = chip })
	local chipIcon = quickIcon(chip, spec.Icon, spec.Fallback, 16, Theme.Accent, 5)
	local title = mkText { Position = UDim2.fromOffset(52, 11), Size = UDim2.new(1, -110, 0, 16), Text = meta.Name, TextSize = 13, ZIndex = 4, Parent = body }
	local status = mkText { Position = UDim2.fromOffset(52, 27), Size = UDim2.new(1, -110, 0, 14), Text = "", TextSize = 11, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, ZIndex = 4, Parent = body }
	local function reserve(amount)
		title.Size = UDim2.new(1, -(52 + amount), 0, 16)
		status.Size = UDim2.new(1, -(52 + amount), 0, 14)
	end
	local close = new("TextButton", { Name = "Close", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Theme.Surface3, Text = "×", TextColor3 = Theme.Muted, TextSize = 15, FontFace = Fonts.Medium, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 10, Parent = root })
	corner(close, UDim.new(1, 0))
	local closeScale = new("UIScale", { Parent = close })
	close.MouseEnter:Connect(function() tween(close, { TextColor3 = Theme.Text, BackgroundColor3 = Theme.Error:Lerp(Theme.Surface3, .55) }, .15); tween(closeScale, { Scale = 1.16 }, .4, SPRING) end)
	close.MouseLeave:Connect(function() tween(close, { TextColor3 = Theme.Muted, BackgroundColor3 = Theme.Surface3 }, .2); tween(closeScale, { Scale = 1 }, .4, SPRING) end)

	local api = { Root = root, Gui = gui, Meta = meta, Closed = false, _destroyed = false, _listeners = {} }
	local kindRefresh = function() end
	local activateControl, activationEffect
	local function actionAllowed()
		if api.Closed or api._destroyed then return false end
		if not obj or obj._destroyed then api:Close(); return false end
		return true
	end

	if kind == "Toggle" then
		local trackW, trackH, knob = 48, 28, 22
		local track = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(trackW, trackH), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = body })
		corner(track, UDim.new(1, 0))
		local thumb = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(knob, knob), BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, ZIndex = 6, Parent = track })
		corner(thumb, UDim.new(1, 0))
		local glow = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Accent, BackgroundTransparency = .88, BorderSizePixel = 0, ZIndex = 3, Parent = body })
		corner(glow, UDim.new(1, 0))
		reserve(trackW + 26)
		activateControl = track
		kindRefresh = function(animate)
			local on, duration = obj:Get() == true, animate and .3 or 0
			tween(track, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, duration, LIQUID)
			tween(thumb, { Position = on and UDim2.new(0, trackW - 3 - knob, .5, 0) or UDim2.new(0, 3, .5, 0), BackgroundColor3 = on and Theme.AccentDark or Theme.Muted }, animate and .48 or 0, SPRING)
			tween(glow, { Size = on and UDim2.fromOffset(rippleSize, rippleSize) or UDim2.fromOffset(0, 0) }, animate and (on and .8 or .45) or 0, LIQUID)
			tween(chip, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, duration)
			chipIcon.Color(on and Theme.AccentDark or Theme.Accent, duration)
			tween(bodyStroke, { Color = on and Theme.Accent or Theme.Stroke, Transparency = on and .5 or .55 }, duration)
			status.Text = on and "On" or "Off"
			tween(status, { TextColor3 = on and Theme.Accent or Theme.Muted }, duration)
		end
	elseif kind == "Button" then
		local button = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = body })
		corner(button, UDim.new(1, 0))
		local sc = new("UIScale", { Parent = button })
		quickIcon(button, "play", "▶", 14, Theme.AccentDark, 6)
		quickPress(button, sc)
		reserve(58)
		activateControl = button
		activationEffect = function() quickWave(body, width - 28, height / 2, rippleSize, .76, 3) end
		kindRefresh = function() status.Text = meta.Desc ~= "" and meta.Desc or "Tap to run" end
	elseif kind == "Keybind" then
		local cap = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(48, 30), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = body })
		corner(cap, UDim.new(0, 9))
		local sc = new("UIScale", { Parent = cap })
		local label = mkText { Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None, ZIndex = 6, Parent = cap }
		label:SetAttribute("AF_NoTranslate", true)
		quickPress(cap, sc)
		activateControl = cap
		activationEffect = function() quickWave(body, width - 36, height / 2, rippleSize, .78, 3) end
		kindRefresh = function(animate)
			local text = keyName(obj:Get())
			if label.Text ~= text then
				label.Text = text
				local textSize = TextService:GetTextSize(text, 13, Enum.Font.GothamMedium, Vector2.new(300, 30)).X
				local capW = math.max(textSize + 24, 44)
				tween(cap, { Size = UDim2.fromOffset(capW, 30) }, animate and .4 or 0, SPRING)
				reserve(capW + 26)
			end
			status.Text = "Tap the key to trigger"
		end
	elseif kind == "Slider" then
		local min, max = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100
		local valueText = mkText { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12), Size = UDim2.fromOffset(80, 18), TextXAlignment = Enum.TextXAlignment.Right, TextSize = 15, FontFace = Fonts.Bold, TextColor3 = Theme.Accent, TextTruncate = Enum.TextTruncate.None, ZIndex = 4, Parent = body }
		reserve(88)
		local track = new("Frame", { Position = UDim2.fromOffset(16, height - 22), Size = UDim2.new(1, -32, 0, 8), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, ZIndex = 4, Parent = body })
		corner(track, UDim.new(1, 0))
		local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 4, Parent = track })
		corner(fill, UDim.new(1, 0))
		local knobGlow = new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .8, ZIndex = 4, Parent = track })
		local knob = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 5, Parent = track })
		corner(knob, UDim.new(1, 0))
		local hit = new("TextButton", { Position = UDim2.fromOffset(6, height - 36), Size = UDim2.new(1, -12, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 7, Parent = body })
		local dragging = false
		local function fromX(x)
			local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			obj:Set(min + (max - min) * ratio)
		end
		local function grow(on)
			tween(knob, { Size = on and UDim2.fromOffset(22, 22) or UDim2.fromOffset(16, 16) }, .4, SPRING)
			tween(knobGlow, { Size = on and UDim2.fromOffset(54, 54) or UDim2.fromOffset(34, 34), ImageTransparency = on and .6 or .8 }, .25)
		end
		hit.InputBegan:Connect(function(input) if not api.Closed and isPress(input) then dragging = true; grow(true); fromX(mouse().X) end end)
		table.insert(api._listeners, win:_listen("Changed", function(input) if dragging and isMove(input) then fromX(mouse().X) end end))
		table.insert(api._listeners, win:_listen("Ended", function(input) if dragging and isPress(input) then dragging = false; grow(false); kindRefresh(true) end end))
		kindRefresh = function(animate)
			local value = tonumber(obj:Get()) or min
			local ratio = max == min and 0 or math.clamp((value - min) / (max - min), 0, 1)
			local duration = animate and (dragging and .05 or .4) or 0
			tween(fill, { Size = UDim2.new(ratio, 0, 1, 0) }, duration, dragging and Enum.EasingStyle.Linear or LIQUID)
			tween(knob, { Position = UDim2.new(ratio, 0, .5, 0) }, duration, dragging and Enum.EasingStyle.Linear or LIQUID)
			tween(knobGlow, { Position = UDim2.new(ratio, 0, .5, 0) }, duration, dragging and Enum.EasingStyle.Linear or LIQUID)
			valueText.Text = quickNumber(cfg, value)
			status.Text = quickNumber(cfg, min) .. " to " .. quickNumber(cfg, max)
		end
	elseif kind == "Stepper" or kind == "Dropdown" then
		reserve(24)
		local bar = new("Frame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 28), BackgroundColor3 = Theme.Surface3, BackgroundTransparency = .35, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 4, Parent = body })
		corner(bar, UDim.new(1, 0))
		local barFill
		if kind == "Stepper" then
			barFill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BackgroundTransparency = .8, BorderSizePixel = 0, ZIndex = 4, Parent = bar })
			corner(barFill, UDim.new(1, 0))
		end
		local function arrow(side, iconName, fallback)
			local left = side == "L"
			local button = new("TextButton", { AnchorPoint = Vector2.new(left and 0 or 1, .5), Position = UDim2.new(left and 0 or 1, left and 3 or -3, .5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 6, Parent = bar })
			corner(button, UDim.new(1, 0))
			local sc = new("UIScale", { Parent = button })
			local icon = quickIcon(button, iconName, fallback, 13, Theme.Muted, 7)
			quickPress(button, sc)
			button.MouseEnter:Connect(function() icon.Color(Theme.Accent, .12) end)
			button.MouseLeave:Connect(function() icon.Color(Theme.Muted, .2) end)
			return button
		end
		local left, right
		if kind == "Stepper" then left = arrow("L", "minus", "−"); right = arrow("R", "plus", "+") else left = arrow("L", "chevron-left", "‹"); right = arrow("R", "chevron-right", "›") end
		local clip = new("Frame", { Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5, Parent = bar })
		local valueText = mkText { Size = UDim2.fromScale(1, 1), TextSize = 14, FontFace = Fonts.Bold, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5, Parent = clip }
		local valueScale = new("UIScale", { Parent = valueText })
		if kind == "Stepper" then
			local min, max, step = tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100, tonumber(cfg.Step) or 1
			local holdId = 0
			local function stepBy(direction) if actionAllowed() then obj:Set((tonumber(obj:Get()) or min) + direction * step) end end
			local function bindHold(button, direction)
				button.InputBegan:Connect(function(input)
					if not isPress(input) or not actionAllowed() then return end
					holdId += 1
					local id = holdId
					stepBy(direction)
					task.delay(.42, function() while id == holdId and not api.Closed and not api._destroyed do stepBy(direction); task.wait(.09) end end)
				end)
				button.InputEnded:Connect(function(input) if isPress(input) then holdId += 1 end end)
				button.MouseLeave:Connect(function() holdId += 1 end)
			end
			bindHold(left, -1); bindHold(right, 1)
			kindRefresh = function(animate)
				local value = tonumber(obj:Get()) or min
				local text = quickNumber(cfg, value)
				local ratio = max == min and 0 or math.clamp((value - min) / (max - min), 0, 1)
				tween(barFill, { Size = UDim2.new(ratio, 0, 1, 0) }, animate and .5 or 0, LIQUID)
				if valueText.Text ~= text then valueText.Text = text; if animate then valueScale.Scale = 1.2; tween(valueScale, { Scale = 1 }, .45, SPRING) end end
				tween(left, { BackgroundTransparency = value <= min and .55 or 0 }, .15)
				tween(right, { BackgroundTransparency = value >= max and .55 or 0 }, .15)
				status.Text = "Step " .. quickNumber({ Step = cfg.Step }, step)
			end
		else
			local lastIndex, pendingDirection = 0, nil
			local function currentIndex()
				local current = obj:Get()
				for index, option in ipairs(cfg.Options or {}) do if option == current then return index end end
				return 0
			end
			local function cycle(direction)
				if not actionAllowed() then return end
				local options = cfg.Options or {}
				if #options == 0 then return end
				local index = currentIndex()
				pendingDirection = direction
				obj:Set(options[((index - 1 + direction) % #options) + 1])
			end
			left.MouseButton1Click:Connect(function() cycle(-1) end)
			right.MouseButton1Click:Connect(function() cycle(1) end)
			kindRefresh = function(animate)
				local options = cfg.Options or {}
				local index, text = currentIndex(), tostring(obj:Get() or "None")
				if valueText.Text ~= text then
					local direction = pendingDirection or (index >= lastIndex and 1 or -1)
					pendingDirection = nil
					valueText.Text = text
					if animate then valueText.Position = UDim2.fromOffset(direction * 18, 0); valueText.TextTransparency = 1; tween(valueText, { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }, .45, SPRING) end
				end
				lastIndex = index
				status.Text = index > 0 and (tostring(index) .. " of " .. tostring(#options)) or "No selection"
			end
		end
	end

	if activateControl then
		activateControl.MouseButton1Click:Connect(function()
			if not actionAllowed() then return end
			front()
			chipScale.Scale = 1.24
			tween(chipScale, { Scale = 1 }, .5, SPRING)
			if activationEffect then activationEffect() end
			if type(meta.Activate) == "function" then fire(meta.Activate) end
		end)
	end

	local listenersRemoved = false
	function api.Refresh(animate)
		if api._destroyed or not body.Parent or not obj or obj._destroyed then return end
		title.Text = meta.Name
		kindRefresh(animate ~= false)
	end
	local function unhook()
		if listenersRemoved then return end
		listenersRemoved = true
		for _, remove in ipairs(api._listeners) do pcall(remove) end
		api._listeners = {}
		if api.Drag and api.Drag.Active then api.Drag:End() end
		if obj and obj._quickSync == api.Refresh then obj._quickSync = nil end
	end
	local function release()
		if win._quickFloats and win._quickFloats[meta] == api then win._quickFloats[meta] = nil end
		removeFromFloats(win, api)
		if type(meta._pickerRefresh) == "function" then pcall(meta._pickerRefresh) end
	end
	function api.Destroy()
		if api._destroyed then return end
		api.Closed, api._destroyed = true, true
		unhook(); release()
		if gui.Parent then gui:Destroy() end
	end
	function api.Close()
		if api.Closed or api._destroyed then return end
		api.Closed = true
		unhook(); release()
		tween(scale, { Scale = .62 }, .32, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(root, { Position = UDim2.fromOffset(root.Position.X.Offset + 24, root.Position.Y.Offset) }, .32, QUINT)
		tween(body, { GroupTransparency = 1 }, .23, QUINT)
		tween(shadow, { ImageTransparency = 1 }, .2)
		tween(close, { BackgroundTransparency = 1, TextTransparency = 1 }, .15)
		task.delay(.35, function() api.Destroy() end)
	end
	close.MouseButton1Click:Connect(function() api:Close() end)
	local closeDrag = function() front() end
	close.InputBegan:Connect(function(input) if isPress(input) then closeDrag() end end)
	api.Drag = makeDragger(root, scale, {
		pointer = function() return UIS:GetMouseLocation() end, base = function() return 1 end, lift = 1.04,
		tilt = true, tiltTarget = root, tiltMax = 2.4, tiltMultiplier = .0012,
		onLift = function(on) tween(shadow, { ImageTransparency = on and .34 or .62 }, .24); tween(chipScale, { Scale = on and 1.14 or 1 }, .4, SPRING) end,
		onDrop = function()
			local viewport, center = gui.AbsoluteSize, api.Drag.Center()
			local halfW, halfH = root.AbsoluteSize.X / 2, root.AbsoluteSize.Y / 2
			local nx = math.clamp(center.X, math.min(halfW, viewport.X / 2), math.max(viewport.X - halfW, viewport.X / 2))
			local ny = math.clamp(center.Y, math.min(halfH, viewport.Y / 2), math.max(viewport.Y - halfH, viewport.Y / 2))
			if (Vector2.new(nx, ny) - center).Magnitude > .5 then tween(root, { Position = UDim2.fromOffset(nx, ny) }, .48, SPRING) end
		end,
	})
	dragArea.InputBegan:Connect(function(input) if not api.Closed and isPress(input) then front(); api.Drag:Begin() end end)
	table.insert(api._listeners, win:_listen("Ended", function(input) if api.Drag and api.Drag.Active and isPress(input) then api.Drag:End() end end))
	table.insert(api._listeners, win:_listen("Render", function(dt) if api.Drag and not api.Closed then api.Drag:Step(dt) end end))
	table.insert(api._listeners, win:_listen("Began", function(input) if isPress(input) and inside(mouse(), root) then front() end end))
	win._quickFloats[meta] = api
	table.insert(win._floats, api)
	obj._quickSync = api.Refresh
	api.Refresh(false)
	tween(scale, { Scale = 1 }, .62, SPRING)
	tween(root, { Position = UDim2.fromOffset(cx, cy) }, .72, LIQUID)
	tween(body, { GroupTransparency = 0 }, .3, QUINT)
	tween(shadow, { ImageTransparency = .62 }, .4)
	return api
end

local function openQuickAccess(win)
	if win._quickOverlay and not win._quickOverlay._destroyed and not win._quickOverlay.Closed then win._quickOverlay:Close(); return end
	local screen = quickScreen(win)
	local width, height = math.min(400, math.max(280, screen.X - 24)), math.min(560, math.max(360, screen.Y - 40))
	local pillW, pillH = math.floor(width * .5), 46
	local gui = new("ScreenGui", { Name = "AirflowQuickAccessOverlay", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 5000 + Library._z, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	Library._z += 1
	pcall(function() if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then syn.protect_gui(gui) end end)
	gui.Parent = win.Gui and win.Gui.Parent or getGuiParent()
	if type(Library._translationHookRoot) == "function" then pcall(Library._translationHookRoot, Library, gui) end
	local backdrop = new("TextButton", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 1, Parent = gui })
	-- the panel starts as a small droplet and swells open into the full sheet
	local root = new("Frame", { Name = "QuickAccessPanel", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0), Size = UDim2.fromOffset(pillW, pillH), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
	local scale = new("UIScale", { Scale = .9, Parent = root })
	local shadow = new("ImageLabel", { Position = UDim2.fromOffset(-28, -24), Size = UDim2.new(1, 56, 1, 56), BackgroundTransparency = 1, Image = Assets.Shadow, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0, Parent = root })
	local body = new("CanvasGroup", { Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, GroupTransparency = 1, Active = true, ZIndex = 2, Parent = root })
	local bodyCorner = corner(body, UDim.new(0, pillH / 2))
	local bodyStroke = stroke(body, Theme.Stroke, .5)
	-- two slow drifting light blobs behind everything give the sheet its liquid feel
	local blobA = new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.15, .12), Size = UDim2.fromOffset(380, 280), BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .84, ZIndex = 1, Parent = body })
	local blobB = new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.88, .92), Size = UDim2.fromOffset(420, 300), BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .9, ZIndex = 1, Parent = body })
	local content = new("CanvasGroup", { Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 3, Parent = body })

	local countText = mkText { Position = UDim2.fromOffset(24, 12), Size = UDim2.fromOffset(0, 42), AutomaticSize = Enum.AutomaticSize.X, Text = "0", TextSize = 36, FontFace = Fonts.Bold, TextTruncate = Enum.TextTruncate.None, ZIndex = 3, Parent = content }
	local countSub = mkText { Position = UDim2.fromOffset(60, 19), Size = UDim2.fromOffset(190, 16), Text = "controls pinned", TextSize = 13, ZIndex = 3, Parent = content }
	mkText { Position = UDim2.fromOffset(60, 36), Size = UDim2.fromOffset(190, 14), Text = "tap one to float it anywhere", TextSize = 11, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, ZIndex = 3, Parent = content }
	local function placeSub()
		local x = 24 + countText.TextBounds.X / math.max(scale.Scale, .01) + 10
		countSub.Position = UDim2.fromOffset(x, 19)
	end
	countText:GetPropertyChangedSignal("TextBounds"):Connect(placeSub)
	local close = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 16), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Text = "×", TextColor3 = Theme.Muted, TextSize = 22, FontFace = Fonts.Regular, AutoButtonColor = false, ZIndex = 6, Parent = content })
	corner(close, UDim.new(1, 0))
	local closeScale = new("UIScale", { Parent = close })
	quickPress(close, closeScale)

	local search = new("Frame", { Position = UDim2.fromOffset(18, 66), Size = UDim2.new(1, -36, 0, 40), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, ZIndex = 4, Parent = content })
	corner(search, UDim.new(1, 0))
	local searchStroke = stroke(search, Theme.Stroke)
	local searchIcon = new("ImageLabel", { Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ImageColor3 = Theme.Muted, ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = search })
	setIcon(searchIcon, "search")
	local searchBox = new("TextBox", { Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search controls", PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 13, FontFace = Fonts.Regular, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 5, Parent = search })
	searchBox.Focused:Connect(function() tween(search, { BackgroundColor3 = Theme.Surface3 }, .2); tween(searchStroke, { Color = Theme.Accent }, .15) end)
	searchBox.FocusLost:Connect(function() tween(search, { BackgroundColor3 = Theme.Surface2 }, .25); tween(searchStroke, { Color = Theme.Stroke }, .2) end)

	-- filter strip: one accent pill that stretches toward the new choice and then snaps back
	local chipScroll = new("ScrollingFrame", { Position = UDim2.fromOffset(18, 114), Size = UDim2.new(1, -36, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ZIndex = 4, Parent = content })
	local chipInner = new("Frame", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 4, Parent = chipScroll })
	local chipIndicator = new("Frame", { Size = UDim2.fromOffset(0, 34), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false, ZIndex = 4, Parent = chipInner })
	corner(chipIndicator, UDim.new(1, 0))
	local chipBtns = new("Frame", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 5, Parent = chipInner })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), Parent = chipBtns })

	local listTop, footerHeight = 158, 58
	local list = new("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(10, listTop), Size = UDim2.new(1, -20, 1, -(listTop + footerHeight)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = .5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 4, Parent = content })
	pad(list, 8, 8, 4, 10)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = list })
	local empty = mkText { Position = UDim2.fromOffset(24, 210), Size = UDim2.new(1, -48, 0, 48), Text = "", TextSize = 13, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Visible = false, ZIndex = 5, Parent = content }
	local footer = new("Frame", { Position = UDim2.new(0, 0, 1, -footerHeight), Size = UDim2.new(1, 0, 0, footerHeight), BackgroundTransparency = 1, ZIndex = 4, Parent = content })
	local footerText = mkText { Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -150, 1, 0), Text = "", TextSize = 12, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, ZIndex = 5, Parent = footer }
	local unpinAll = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -18, .5, 0), Size = UDim2.fromOffset(100, 34), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Text = "Unpin all", TextColor3 = Theme.Muted, TextSize = 12, FontFace = Fonts.Medium, AutoButtonColor = false, ZIndex = 5, Parent = footer })
	corner(unpinAll, UDim.new(1, 0)); local unpinScale = new("UIScale", { Parent = unpinAll }); quickPress(unpinAll, unpinScale)

	local api = { Root = root, Gui = gui, Closed = false, _destroyed = false, _listeners = {} }
	local rows, chipRefs, kindFilter, listenersRemoved = {}, {}, "All", false
	local function items() return win._quickItems or {} end
	local function currentPinned(meta)
		local floating = win._quickFloats and win._quickFloats[meta]
		return floating ~= nil and not floating.Closed and not floating._destroyed
	end
	local function updateCount()
		local count, total = 0, 0
		for _, meta in ipairs(items()) do if meta.Object and not meta.Object._destroyed then total += 1; if currentPinned(meta) then count += 1 end end end
		countText.Text = tostring(count)
		countSub.Text = count == 1 and "control pinned" or "controls pinned"
		footerText.Text = string.format("%d of %d available", count, total)
		tween(unpinAll, { TextColor3 = count > 0 and Theme.Text or Theme.Muted }, .2)
	end

	local function createTile(meta, order)
		local spec = QUICK_KINDS[meta.Kind] or QUICK_KINDS.Button
		local cell = new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, LayoutOrder = order, Parent = list })
		local tile = new("CanvasGroup", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 16), Size = UDim2.fromScale(.9, .8), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, GroupTransparency = 1, Parent = cell })
		corner(tile, UDim.new(0, 29))
		local tileStroke = stroke(tile, Theme.Stroke, .2)
		-- pinning floods the whole capsule with accent, starting from the dot on the right
		local flood = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, -29, .5, 0), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 1, Parent = tile })
		corner(flood, UDim.new(1, 0))
		local bubble = new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, ZIndex = 2, Parent = tile })
		corner(bubble, UDim.new(1, 0))
		local bubbleScale = new("UIScale", { Parent = bubble })
		local icon = quickIcon(bubble, spec.Icon, spec.Fallback, 17, Theme.Accent, 3)
		local name = mkText { Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -112, 0, 18), Text = meta.Name, TextSize = 14, ZIndex = 3, Parent = tile }
		local tag = mkText { Position = UDim2.fromOffset(60, 29), Size = UDim2.new(1, -112, 0, 16), Text = string.lower(spec.Label), TextSize = 11, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, ZIndex = 3, Parent = tile }
		local pinDot = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -18, .5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, ZIndex = 2, Parent = tile })
		corner(pinDot, UDim.new(1, 0))
		local pinCheck = quickIcon(pinDot, "check", "✓", 12, Theme.Accent, 3)
		local checkScale = new("UIScale", { Scale = 0, Parent = pinCheck.Holder })
		local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 6, Parent = tile })
		local function update(animate)
			local pinned = currentPinned(meta)
			local d = animate and .3 or 0
			name.Text = meta.Name
			tag.Text = pinned and "pinned" or string.lower(spec.Label)
			tween(flood, { Size = pinned and UDim2.fromOffset(900, 900) or UDim2.fromOffset(0, 0) }, animate and (pinned and .85 or .5) or 0, LIQUID)
			tween(name, { TextColor3 = pinned and Theme.AccentDark or Theme.Text }, d)
			tween(tag, { TextColor3 = pinned and Theme.AccentDark or Theme.Muted }, d)
			tween(bubble, { BackgroundColor3 = pinned and Theme.AccentDark or Theme.Surface3 }, d)
			tween(pinDot, { BackgroundColor3 = pinned and Theme.AccentDark or Theme.Surface3 }, d)
			tween(checkScale, { Scale = pinned and 1 or 0 }, animate and .5 or 0, SPRING)
			tween(tileStroke, { Color = pinned and Theme.Accent or Theme.Stroke, Transparency = pinned and .1 or .2 }, d)
			icon.Color(Theme.Accent, d)
		end
		rows[meta] = { Cell = cell, Update = update }
		hit.MouseEnter:Connect(function()
			tween(bubbleScale, { Scale = 1.1 }, .4, SPRING)
			if not currentPinned(meta) then tween(tileStroke, { Color = Theme.StrokeHover }, .15) end
		end)
		hit.MouseLeave:Connect(function()
			tween(bubbleScale, { Scale = 1 }, .4, SPRING)
			tween(tile, { Size = UDim2.fromScale(1, 1) }, .5, SPRING)
			tween(tileStroke, { Color = currentPinned(meta) and Theme.Accent or Theme.Stroke }, .25)
		end)
		hit.MouseButton1Down:Connect(function() tween(tile, { Size = UDim2.fromScale(.96, .88) }, .12) end)
		hit.MouseButton1Up:Connect(function() tween(tile, { Size = UDim2.fromScale(1, 1) }, .6, SPRING) end)
		hit.MouseButton1Click:Connect(function()
			if api.Closed or api._destroyed then return end
			local existing = win._quickFloats and win._quickFloats[meta]
			if existing and not existing.Closed then existing:Close() else createQuickShortcut(win, meta) end
			bubbleScale.Scale = 1.25; tween(bubbleScale, { Scale = 1 }, .55, SPRING)
			update(true); updateCount()
		end)
		update(false)
		task.delay(.26 + math.min(order, 10) * .04, function()
			if not tile.Parent then return end
			tween(tile, { Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(1, 1) }, .7, SPRING)
			tween(tile, { GroupTransparency = 0 }, .3)
		end)
	end

	local indGen = 0
	local function moveIndicator(instant)
		local btn = chipRefs[kindFilter]
		if not btn or not btn.Parent then return end
		local s = math.max(scale.Scale, .01)
		local x = (btn.AbsolutePosition.X - chipInner.AbsolutePosition.X) / s
		local w = btn.AbsoluteSize.X / s
		if w <= 0 then return end
		if instant or not chipIndicator.Visible then
			chipIndicator.Visible = true
			chipIndicator.Position = UDim2.fromOffset(x, 0)
			chipIndicator.Size = UDim2.fromOffset(w, 34)
			return
		end
		indGen += 1
		local gen = indGen
		local x0, w0 = chipIndicator.Position.X.Offset, chipIndicator.Size.X.Offset
		local left, right = math.min(x0, x), math.max(x0 + w0, x + w)
		tween(chipIndicator, { Position = UDim2.fromOffset(left, 0), Size = UDim2.fromOffset(right - left, 34) }, .14)
		task.delay(.12, function()
			if gen ~= indGen or not chipIndicator.Parent then return end
			tween(chipIndicator, { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 34) }, .55, SPRING)
		end)
	end
	local function styleChips(instant)
		local duration = instant and 0 or .23
		for name, button in pairs(chipRefs) do
			tween(button, { TextColor3 = kindFilter == name and Theme.AccentDark or Theme.Muted }, duration)
		end
	end
	local function applyFilter()
		local query, shown, total = string.lower(searchBox.Text or ""), 0, 0
		for _, meta in ipairs(items()) do
			local row = rows[meta]
			if row then
				total += 1
				local haystack = string.lower(meta.Name .. " " .. meta.Kind .. " " .. meta.Desc)
				local match = (query == "" or string.find(haystack, query, 1, true) ~= nil) and (kindFilter == "All" or kindFilter == meta.Kind)
				row.Cell.Visible = match
				if match then shown += 1 end
			end
		end
		empty.Text = total == 0 and "Nothing to pin yet.\nButtons, toggles, keybinds and more will appear here." or "No controls match your search."
		empty.Visible = shown == 0
	end
	local function buildChips()
		for _, button in pairs(chipRefs) do if button.Parent then button:Destroy() end end
		table.clear(chipRefs)
		local present, kinds = {}, { "All" }
		for _, meta in ipairs(items()) do if meta.Object and not meta.Object._destroyed then present[meta.Kind] = true end end
		for _, kind in ipairs(QUICK_ORDER) do if present[kind] then table.insert(kinds, kind) end end
		if kindFilter ~= "All" and not present[kindFilter] then kindFilter = "All" end
		for order, kind in ipairs(kinds) do
			local button = new("TextButton", { Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, BorderSizePixel = 0, Text = kind == "All" and "All" or QUICK_PLURAL[kind], TextSize = 12, FontFace = Fonts.Medium, TextColor3 = Theme.Muted, AutoButtonColor = false, LayoutOrder = order, ZIndex = 6, Parent = chipBtns })
			pad(button, 14, 14)
			local sc = new("UIScale", { Parent = button }); button.MouseButton1Down:Connect(function() tween(sc, { Scale = .92 }, .1) end); button.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, .45, SPRING) end)
			button.MouseButton1Click:Connect(function() kindFilter = kind; styleChips(); moveIndicator(false); applyFilter() end)
			button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if kindFilter == kind then moveIndicator(true) end end)
			chipRefs[kind] = button
		end
		styleChips(true)
		task.defer(moveIndicator, true)
	end
	local function rebuild()
		for _, row in pairs(rows) do if row.Cell.Parent then row.Cell:Destroy() end end
		table.clear(rows)
		local order = 0
		for _, meta in ipairs(items()) do
			if meta.Object and not meta.Object._destroyed then
				order += 1; createTile(meta, order)
				meta._pickerRefresh = function() local row = rows[meta]; if row then row.Update(true) end; updateCount() end
				meta._pickerRemove = function()
					local row = rows[meta]; if row and row.Cell.Parent then row.Cell:Destroy() end
					rows[meta] = nil; buildChips(); applyFilter(); updateCount()
				end
			end
		end
		buildChips(); applyFilter(); updateCount()
	end
	searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
	unpinAll.MouseButton1Click:Connect(function()
		local delayIndex = 0
		for _, meta in ipairs(items()) do
			local floating = win._quickFloats and win._quickFloats[meta]
			if floating and not floating.Closed then delayIndex += 1; task.delay(delayIndex * .045, function() if not floating.Closed then floating:Close() end end) end
		end
	end)

	local function removeListeners()
		if listenersRemoved then return end
		listenersRemoved = true
		for _, remove in ipairs(api._listeners) do pcall(remove) end
		api._listeners = {}
		if api._escapeConnection then api._escapeConnection:Disconnect(); api._escapeConnection = nil end
		for _, meta in ipairs(items()) do meta._pickerRefresh = nil; meta._pickerRemove = nil end
	end
	function api.Destroy()
		if api._destroyed then return end
		api.Closed, api._destroyed = true, true
		removeListeners(); removeFromFloats(win, api)
		if win._quickOverlay == api then win._quickOverlay = nil end
		if gui.Parent then gui:Destroy() end
	end
	function api.Close()
		if api.Closed or api._destroyed then return end
		api.Closed = true; removeListeners()
		if win._quickOverlay == api then win._quickOverlay = nil end
		tween(backdrop, { BackgroundTransparency = 1 }, .3, QUINT)
		tween(content, { GroupTransparency = 1 }, .16, QUINT)
		tween(root, { Size = UDim2.fromOffset(pillW, pillH) }, .45, LIQUID)
		tween(bodyCorner, { CornerRadius = UDim.new(0, pillH / 2) }, .45, LIQUID)
		tween(scale, { Scale = .9 }, .4, QUINT)
		task.delay(.3, function()
			tween(body, { GroupTransparency = 1 }, .18, QUINT)
			tween(shadow, { ImageTransparency = 1 }, .18)
		end)
		task.delay(.52, function() api.Destroy() end)
	end
	close.MouseButton1Click:Connect(function() api:Close() end)
	backdrop.MouseButton1Click:Connect(function() api:Close() end)
	api._escapeConnection = UIS.InputBegan:Connect(function(input, processed)
		if not api.Closed and not processed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then api:Close() end
	end)
	table.insert(api._listeners, win:_listen("Began", function(input) if not api.Closed and isPress(input) and inside(mouse(), root) then Library._z += 1; gui.DisplayOrder = 5000 + Library._z end end))
	table.insert(api._listeners, win:_listen("Render", function()
		local t = os.clock()
		blobA.Position = UDim2.fromScale(.15 + math.sin(t * .7) * .09, .12 + math.cos(t * .5) * .06)
		blobB.Position = UDim2.fromScale(.88 + math.cos(t * .6) * .09, .92 + math.sin(t * .8) * .05)
	end))
	win._quickOverlay = api
	table.insert(win._floats, api)
	rebuild()
	tween(backdrop, { BackgroundTransparency = .5 }, .35, QUINT)
	tween(body, { GroupTransparency = 0 }, .2, QUINT)
	tween(shadow, { ImageTransparency = .5 }, .4)
	tween(root, { Size = UDim2.fromOffset(width, height) }, .8, SPRING)
	tween(bodyCorner, { CornerRadius = UDim.new(0, 28) }, .6, SPRING)
	tween(scale, { Scale = 1 }, .6, SPRING)
	tween(bodyStroke, { Color = Theme.StrokeHover, Transparency = .15 }, .4)
	task.delay(.22, function() if not api.Closed then tween(content, { GroupTransparency = 0 }, .3, QUINT) end end)
	task.defer(placeSub)
end
function Container:Header(name, icon)
	if type(name) == "table" then
		icon = icon or name.Icon
		name = name.Name or name.Title or ""
	end
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = self:_nextOrder(), Parent = self.List })
	local labelX = icon and 24 or 2
	if icon then iconBox(holder, icon, Theme.Muted, UDim2.new(0, 2, 0, 16)) end
	local label = mkText {
		Position = UDim2.fromOffset(labelX, 8), Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
		Text = string.upper(name), TextSize = 12, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.None, Parent = holder,
	}
	local line = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, 0, 16), Size = UDim2.new(1, -12, 0, 1),
		BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = holder,
	})
	local function fit() line.Size = UDim2.new(1, -(label.AbsoluteSize.X + (icon and 36 or 14)), 0, 1) end
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit)
	return register(self, {}, { Set = function(_, t) label.Text = string.upper(t) end }, holder, "Header")
end

function Container:Divider()
	local line = new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, LayoutOrder = self:_nextOrder(), Parent = self.List })
	return register(self, {}, {}, line, "Divider")
end

function Container:Label(cfg)
	cfg = norm(cfg, { Name = "Text", Title = "Text" })
	-- wraps onto new lines at the border and grows in height (18px is the minimum), so long text never ends in "..."
	local label = mkText {
		Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Text or "", TextSize = 13, FontFace = Fonts.Regular,
		TextColor3 = cfg.Color or Theme.Muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = self:_nextOrder(), Parent = self.List,
	}
	pad(label, 2, 2, 1, 1)
	local obj = { Set = function(_, t) label.Text = tostring(t) end, Get = function() return label.Text end }
	if type(cfg.Update) == "function" then
		local rate, alive = math.max(tonumber(cfg.UpdateRate) or 1, .05), true
		obj._listeners = { function() alive = false end }
		task.spawn(function()
			while alive and label.Parent do
				local ok, v = pcall(cfg.Update)
				if ok and v ~= nil then label.Text = tostring(v) elseif not ok then warn("[Airflow] label update error: " .. tostring(v)) end
				task.wait(rate)
			end
		end)
		function obj:SetUpdateRate(r) rate = math.max(tonumber(r) or rate, .05) end
	end
	return register(self, cfg, obj, label, "Label")
end

function Container:Paragraph(cfg)
	cfg = norm(cfg, { Title = "Name" })
	local card = makeCard(self, "Frame", 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	pad(card, 14, 14, 11, 12)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = card })
	if cfg.Name and cfg.Name ~= "" then
		mkText {
			Size = UDim2.new(1, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Name, TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 1, Parent = card,
		}
	end
	local body = mkText {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Content or "", TextSize = 13,
		FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = card,
	}
	return register(self, cfg, { Set = function(_, t) body.Text = tostring(t) end, Get = function() return body.Text end }, card, "Paragraph")
end

function Container:QuickAccess(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc" })
	local win = self.Window
	local userCallback = cfg.Callback
	local obj = self:Button({
		Name = cfg.Name or "Quick access",
		Desc = cfg.Desc or "Pin buttons, toggles and keybinds",
		Icon = cfg.Icon or "zap",
		Style = cfg.Style,
		Flag = cfg.Flag,
		Quickable = false,
		Callback = function()
			openQuickAccess(win)
			fire(userCallback)
		end,
	})
	return obj
end

function Container:Button(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc" })
	local primary = cfg.Style == "Primary"
	local card, st = makeCard(self, "TextButton", cfg.Desc and DESC_H or ROW_H)
	card.ClipsDescendants = true
	local scale = new("UIScale", { Parent = card })
	if primary then
		card.BackgroundColor3 = Theme.Accent
		card.BackgroundTransparency = .12
		st.Color = Theme.Accent
		st.Transparency = .4
		card.MouseEnter:Connect(function()
			tween(card, { BackgroundTransparency = 0 }, .15)
			tween(st, { Transparency = 0 }, .15)
		end)
		card.MouseLeave:Connect(function()
			tween(card, { BackgroundTransparency = .12 }, .3)
			tween(st, { Transparency = .4 }, .3)
		end)
	else
		hover(card, st)
	end
	local ink = primary and Theme.AccentDark or Theme.Text
	local leftOff = 0
	if cfg.Icon then
		iconBox(card, cfg.Icon, primary and Theme.AccentDark or Theme.Accent, UDim2.new(0, 14, .5, 0))
		leftOff = 26
	end
	local title, sub = titles(card, cfg.Name or "Button", cfg.Desc, 30, leftOff)
	if primary then
		title.TextColor3 = ink
		if sub then sub.TextColor3 = ink end
	end
	iconBox(card, "chevron-right", primary and Theme.AccentDark or Theme.Muted, UDim2.new(1, -30, .5, 0))
	card.MouseButton1Down:Connect(function() tween(scale, { Scale = .97 }, .12) end)
	local function release() tween(scale, { Scale = 1 }, .5, SPRING) end
	card.MouseButton1Up:Connect(release)
	card.MouseLeave:Connect(release)
	card.MouseButton1Click:Connect(function()
		ripple(card)
		fire(cfg.Callback)
	end)
	local obj
	obj = { SetText = function(_, t)
		title.Text = t
		if obj._quickMeta then
			obj._quickMeta.Name = tostring(t)
			if type(obj._quickSync) == "function" then obj._quickSync() end
			if type(obj._quickMeta._pickerRefresh) == "function" then obj._quickMeta._pickerRefresh() end
		end
	end }
	return register(self, cfg, obj, card, "Button")
end

function Container:Toggle(cfg)
	local card, st
	cfg, card, st = baseCard(self, cfg, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default" }, "TextButton", 56, "Toggle")
	local trackW, trackH = Touch and 44 or 36, Touch and 24 or 20
	local knob = Touch and 18 or 14
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(trackW, trackH),
		BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = card,
	})
	corner(track, UDim.new(1, 0))
	stroke(track, Theme.Stroke)
	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(knob, knob),
		BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = track,
	})
	corner(thumb, UDim.new(1, 0))
	local halo = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(1, 24, 1, 24),
		BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = 1, ZIndex = 0, Parent = track,
	})
	local obj = { Value = cfg.Default == true }
	local function render(animate)
		local on = obj.Value
		local t = animate and .3 or 0
		tween(track, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, t)
		tween(halo, { ImageTransparency = on and .75 or 1 }, t)
		tween(thumb, {
			Position = on and UDim2.new(0, trackW - 3 - knob, .5, 0) or UDim2.new(0, 3, .5, 0),
			BackgroundColor3 = on and Theme.AccentDark or Theme.Muted,
		}, animate and .5 or 0, SPRING)
		if animate then

			tween(thumb, { Size = UDim2.fromOffset(knob + 8, knob - 2) }, .1)
			task.delay(.1, function() tween(thumb, { Size = UDim2.fromOffset(knob, knob) }, .45, SPRING) end)
		end
	end
	local byClick = false
	function obj:Set(v, silent)
		if cfg.Locked == true then return end
		v = v == true
		if v == obj.Value then return end
		obj.Value = v
		render(true)
		if type(obj._quickSync) == "function" then obj._quickSync() end
		if not byClick then pulse(st) end
		if not silent then fire(cfg.Callback, v) end
	end
	function obj:Get() return obj.Value end
	render(false)
	local function resetTogglePress()
		tween(thumb, { Size = UDim2.fromOffset(knob, knob) }, .18, SPRING)
	end
	card.MouseButton1Down:Connect(function()
		tween(thumb, { Size = UDim2.fromOffset(knob + 4, knob - 2) }, .12)
	end)
	card.MouseButton1Up:Connect(resetTogglePress)
	card.MouseLeave:Connect(resetTogglePress)
	card.MouseButton1Click:Connect(function()
		byClick = true
		obj:Set(not obj.Value)
		byClick = false
	end)
	local reg = register(self, cfg, obj, card, "Toggle")
	if obj.Value and cfg.Locked ~= true then fire(cfg.Callback, true) end
	return reg
end

function Container:Slider(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default", Increment = "Step" })
	local min, max, step, suffix = cfg.Min or 0, cfg.Max or 100, cfg.Step or 1, cfg.Suffix or ""
	local fmt = snapper(min, max, step)
	local SH = math.max(DESC_H, 62)
	local card, st = makeCard(self, "Frame", SH)
	hover(card, st)
	mkText { Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -120, 0, 18), Text = cfg.Name or "Slider", Parent = card }
	if cfg.Desc then
		mkText {
			Position = UDim2.fromOffset(14, 27), Size = UDim2.new(1, -120, 0, 15), Text = cfg.Desc, TextSize = 12,
			FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = card,
		}
	end

	local chip = new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 9), Size = UDim2.fromOffset(40, 24),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, Parent = card,
	})
	corner(chip, UDim.new(0, 6))
	local chipStroke = stroke(chip)
	local valueLabel = mkText {
		Size = UDim2.new(1, 0, 1, 0), TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None, Parent = chip,
	}
	local editBox = new("TextBox", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Text, TextSize = 13,
		FontFace = Fonts.Medium, ClearTextOnFocus = false, Visible = false, Parent = chip,
	})
	local chipBtn = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2, Parent = chip })
	local editing = false
	local function fitChip(instant)
		local w = math.max(valueLabel.TextBounds.X + 18, 36)
		if instant then chip.Size = UDim2.fromOffset(w, 24) else tween(chip, { Size = UDim2.fromOffset(w, 24) }, .35, SPRING) end
	end
	valueLabel:GetPropertyChangedSignal("TextBounds"):Connect(function() if not editing then fitChip(false) end end)
	chipBtn.MouseEnter:Connect(function() tween(chipStroke, { Color = Theme.StrokeHover }, .12) end)
	chipBtn.MouseLeave:Connect(function() if not editBox:IsFocused() then tween(chipStroke, { Color = Theme.Stroke }, .2) end end)

	local trackY = SH - 18
	local trackBar = new("Frame", {
		Position = UDim2.new(0, 14, 0, trackY), Size = UDim2.new(1, -28, 0, 5), BackgroundColor3 = Theme.Surface3,
		BorderSizePixel = 0, Parent = card,
	})
	corner(trackBar, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = trackBar })
	corner(fill, UDim.new(1, 0))
	local halo = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .85, ZIndex = 2, Parent = trackBar,
	})
	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 3, Parent = trackBar,
	})
	corner(thumb, UDim.new(1, 0))
	local hit = new("TextButton", {
		Position = UDim2.new(0, 8, 0, trackY - (Touch and 19 or 13)), Size = UDim2.new(1, -16, 0, Touch and 40 or 28),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = card,
	})

	local obj = { Value = math.clamp(cfg.Default or min, min, max) }
	local dragging = false
	local function ratio() return (max - min) == 0 and 0 or (obj.Value - min) / (max - min) end
	local function place(r, t, style)
		style = style or Enum.EasingStyle.Linear
		tween(fill, { Size = UDim2.new(r, 0, 1, 0) }, t, style)
		tween(thumb, { Position = UDim2.new(r, 0, .5, 0) }, t, style)
		tween(halo, { Position = UDim2.new(r, 0, .5, 0) }, t, style)
	end
	local function refresh(t, style)
		place(ratio(), t, style)
		valueLabel.Text = fmt.format(obj.Value) .. suffix
	end
	function obj:Set(v, silent)
		v = fmt.snap(tonumber(v) or min)
		if v == obj.Value then return end
		obj.Value = v
		if dragging then refresh(.06) else refresh(.45, QUINT) pulse(st) end
		if type(obj._quickSync) == "function" then obj._quickSync() end
		if not silent then fire(cfg.Callback, v) end
	end
	function obj:Get() return obj.Value end

	chipBtn.MouseButton1Click:Connect(function()
		editing = true
		editBox.Text = fmt.format(obj.Value)
		valueLabel.Visible = false
		editBox.Visible = true
		chipBtn.Visible = false
		tween(chipStroke, { Color = Theme.StrokeHover }, .12)
		editBox:CaptureFocus()
	end)
	editBox.FocusLost:Connect(function()
		local n = tonumber(editBox.Text)
		editing = false
		editBox.Visible = false
		valueLabel.Visible = true
		chipBtn.Visible = true
		tween(chipStroke, { Color = Theme.Stroke }, .2)
		if n then obj:Set(n) end
		fitChip(false)
	end)

	local function grow(on)
		tween(thumb, { Size = on and UDim2.fromOffset(17, 17) or UDim2.fromOffset(12, 12) }, on and .35 or .45, SPRING)
		tween(halo, { Size = on and UDim2.fromOffset(46, 46) or UDim2.fromOffset(28, 28), ImageTransparency = on and .68 or .85 }, .25)
	end
	hit.MouseEnter:Connect(function() if not dragging then tween(halo, { ImageTransparency = .78, Size = UDim2.fromOffset(34, 34) }, .2) end end)
	hit.MouseLeave:Connect(function() if not dragging then tween(halo, { ImageTransparency = .85, Size = UDim2.fromOffset(28, 28) }, .25) end end)
	local function fromMouse(x)
		local r = math.clamp((x - trackBar.AbsolutePosition.X) / trackBar.AbsoluteSize.X, 0, 1)
		obj:Set(min + (max - min) * r)
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging = true
			grow(true)
			fromMouse(mouse().X)
		end
	end)
	self.Window:_listen("Changed", function(i) if dragging and isMove(i) then fromMouse(mouse().X) end end, obj)
	self.Window:_listen("Ended", function(i)
		if dragging and isPress(i) then
			dragging = false
			grow(false)
			refresh(.3, QUINT)
		end
	end, obj)

	obj.Value = fmt.snap(obj.Value)
	refresh(0)
	task.defer(fitChip, true)
	return register(self, cfg, obj, card, "Slider")
end

function Container:Dropdown(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc", CurrentOption = "Default", Value = "Default", MultipleOptions = "Multi", Values = "Options" })
	local multi = cfg.Multi == true
	if multi and type(cfg.Default) ~= "table" and cfg.Default ~= nil then
		cfg.Default = { cfg.Default }
	elseif not multi and type(cfg.Default) == "table" then
		cfg.Default = cfg.Default[1]
	end
	local popup = cfg.Style == "Popup" or cfg.Style == "Floating"
	local options = cfg.Options or {}
	local win = self.Window
	local headH = cfg.Desc and DESC_H or ROW_H

	local card, st = makeCard(self, "Frame", headH)
	card.ClipsDescendants = true
	hover(card, st)

	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = card })
	local title, sub = titles(head, cfg.Name or "Dropdown", cfg.Desc, 180)
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(60, CTRL_H),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, Parent = head,
	})
	corner(pill, UDim.new(0, 6))
	local pillStroke = stroke(pill)
	local valueLabel = mkText {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextColor3 = Theme.Muted, TextSize = 13,
		TextTruncate = Enum.TextTruncate.None, ClipsDescendants = true, Parent = pill,
	}
	local chevron = makeChevron(pill, 1, -6)
	local measure = mkText { Size = UDim2.fromOffset(0, CTRL_H), AutomaticSize = Enum.AutomaticSize.X, TextSize = 13, Visible = false, Parent = pill }
	local fullText = ""
	local function clippedText()
		measure.Text = fullText
		if measure.TextBounds.X <= 146 then return fullText end
		local s = fullText
		while #s > 1 do
			s = s:sub(1, -2)
			measure.Text = s .. ".."
			if measure.TextBounds.X <= 146 then return s .. ".." end
		end
		return ".."
	end
	local function fitPill(instant)
		local w = math.clamp(valueLabel.TextBounds.X + 10 + 34, 60, 190)
		setPad(title, sub, w + 20)
		if instant then pill.Size = UDim2.fromOffset(w, CTRL_H) else tween(pill, { Size = UDim2.fromOffset(w, CTRL_H) }, .35, SPRING) end
	end
	valueLabel:GetPropertyChangedSignal("TextBounds"):Connect(function() fitPill(false) end)

	local function popupLayer()
		local cur = card
		while cur do
			local h = floatHosts[cur]
			if h then return h, h, 1 end
			cur = cur.Parent
		end
		return win.Overlay, win.Body, math.max(win.Scale.Scale, .01)
	end

	local host
	local popupFrame, popupScale
	if popup then
		popupFrame = new("Frame", {
			BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 50,
		})
		corner(popupFrame, UDim.new(0, 10))
		local ps = stroke(popupFrame, Theme.StrokeHover)
		popupScale = new("UIScale", { Parent = popupFrame })
		win._themeRoots = win._themeRoots or {}
		table.insert(win._themeRoots, popupFrame)
		host = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = .5, AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(), ZIndex = 51, Parent = popupFrame,
		})
		pad(host, 6, 6, 6, 6)
		popupFrame:SetAttribute("NoDrag", true)
		ps.Name = "PopupStroke"
	else
		host = new("Frame", { Position = UDim2.new(0, 10, 0, headH), Size = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, Parent = card })
	end
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = host })

	local state = { Open = false }
	local selected, rows, query = {}, {}, ""
	local searchAfter = cfg.SearchAfter or 6
	local z = popup and 52 or 1

	local searchRow = new("Frame", { Size = UDim2.new(1, 0, 0, OPT_H), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 0, Visible = false, ZIndex = z, Parent = host })
	corner(searchRow, UDim.new(0, 6))
	local searchStroke = stroke(searchRow, Theme.Stroke, 1)
	local searchBox = new("TextBox", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search",
		PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 13, FontFace = Fonts.Regular, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, TextTransparency = 1, ZIndex = z, Parent = searchRow,
	})

	local function matches(o) return query == "" or string.find(string.lower(tostring(o)), query, 1, true) ~= nil end
	local function getValue()
		if multi then
			local out = {}
			for _, o in ipairs(options) do if selected[o] then table.insert(out, o) end end
			return out
		end
		for _, o in ipairs(options) do if selected[o] then return o end end
		return nil
	end
	local function visibleCount()
		local n = 0
		for _, o in ipairs(options) do if matches(o) then n += 1 end end
		return n
	end
	local function listHeight()
		return (visibleCount() + (searchRow.Visible and 1 or 0)) * (OPT_H + 4)
	end
	local function openHeight()
		if popup then return math.min(listHeight() + 12, 210) end
		return headH + listHeight() + 8
	end

	if multi then
		for _, o in ipairs(cfg.Default or {}) do selected[o] = true end
	elseif cfg.Default ~= nil then
		selected[cfg.Default] = true
	end

	local function setRowShown(row, shown, instant)
		local t = instant and 0 or .2
		local on = row.On and shown
		tween(row.Label, { TextTransparency = shown and 0 or 1, TextColor3 = row.On and Theme.Text or Theme.Muted }, t)
		tween(row.Check, { ImageTransparency = on and 0 or 1 }, t)
		row.Scale.Scale = on and 1 or .6
		tween(row.Stroke, { Transparency = shown and 0 or 1 }, t)
		tween(row.Frame, { BackgroundTransparency = shown and 0 or 1 }, t)
	end

	local function refreshVisual()
		local v = getValue()
		if multi then
			fullText = #v > 0 and table.concat(v, ", ") or "None"
		else
			fullText = v ~= nil and tostring(v) or "None"
		end
		valueLabel.Text = clippedText()
		for o, row in pairs(rows) do
			local on = selected[o] == true
			if row.On ~= on then
				row.On = on
				tween(row.Label, { TextColor3 = on and Theme.Text or Theme.Muted }, .15)
				if state.Open then
					tween(row.Check, { ImageTransparency = on and 0 or 1 }, .15)
					tween(row.Scale, { Scale = on and 1 or .6 }, on and .45 or .15, on and SPRING or QUINT)
				end
			end
		end
		if type(state._quickSync) == "function" then state._quickSync() end
	end

	local function applyFilter()
		for o, row in pairs(rows) do row.Frame.Visible = matches(o) end
	end

	local rowGen = 0
	local function animateRows(open)
		rowGen += 1
		local gen = rowGen
		local list = {}
		for _, o in ipairs(options) do
			local row = rows[o]
			if row and row.Frame.Visible then table.insert(list, row) end
		end
		if open then
			task.spawn(function()
				for i, row in ipairs(list) do
					if i > 1 then
						task.wait(.025)
						if rowGen ~= gen or not state.Open then return end
					end
					setRowShown(row, true)
				end
			end)
		else
			task.spawn(function()
				for i = #list, 1, -1 do
					setRowShown(list[i], false)
					if i > 1 then
						task.wait(.012)
						if rowGen ~= gen or state.Open then return end
					end
				end
			end)
		end
	end

	local lastPopupW = 170
	local backdrop
	local popupFollowRemove
	local outsideInputRemove
	local function popupGeometry(h)
		local _, ref, s = popupLayer()
		local refPos = ref.AbsolutePosition
		local bodyW = ref.AbsoluteSize.X / s
		local bodyH = ref.AbsoluteSize.Y / s
		local relX = (pill.AbsolutePosition.X - refPos.X) / s
		local relY = (pill.AbsolutePosition.Y - refPos.Y) / s
		local psX = pill.AbsoluteSize.X / s
		local psY = pill.AbsoluteSize.Y / s
		local maxW = math.max(bodyW - 16, 170)
		local w = math.min(math.max(psX, 170), maxW)
		h = math.clamp(h, 44, math.max(44, math.min(210, bodyH - 16)))
		local x = math.clamp(relX, 8, math.max(8, bodyW - w - 8))
		local downY = relY + psY + 6
		local up = downY + h > bodyH - 8 and relY - h - 6 >= 8
		local y = up and (relY - h - 6) or downY
		y = math.clamp(y, 8, math.max(8, bodyH - h - 8))
		return x, y, w, h
	end
	local function placePopup(h, animate, moveOnly)
		local x, y, w, safeH = popupGeometry(h)
		lastPopupW = w
		if animate then
			tween(popupFrame, { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, safeH) }, .15, QUINT)
		else
			popupFrame.Position = UDim2.fromOffset(x, y)
			if not moveOnly then popupFrame.Size = UDim2.fromOffset(w, safeH) end
		end
		return w, safeH
	end
	local setOpen
	function setOpen(open)
		open = open == true
		if open and state.Open then
			if popup then placePopup(openHeight(), false) end
			return
		end
		if not open and not state.Open then return end
		if open and win._popupClose and win._popupOwner ~= state then win._popupClose() end
		state.Open = open
		searchRow.Visible = #options > searchAfter
		if not open then
			query = ""
			searchBox.Text = ""
			applyFilter()
		end
		if popup then
			if open then
				local layer = popupLayer()
				popupFrame.Parent = layer
				local h = openHeight()
				local x, y, w, safeH = popupGeometry(h)
				popupFrame.Position = UDim2.fromOffset(x, y)
				popupFrame.Size = UDim2.fromOffset(w, 0)
				popupScale.Scale = .94
				popupFrame.Visible = true
				tween(popupFrame, { Size = UDim2.fromOffset(w, safeH) }, .32, SPRING)
				tween(popupScale, { Scale = 1 }, .35, SPRING)
				backdrop = new("TextButton", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 49, Parent = layer,
				})
				backdrop.MouseButton1Click:Connect(function() setOpen(false) end)
				win._popupClose = function() setOpen(false) end
				win._popupOwner = state
				if not popupFollowRemove then
					popupFollowRemove = win:_listen("Render", function()
						if state.Open and popupFrame.Visible then placePopup(openHeight(), false, true) end
					end)
				end
				if not outsideInputRemove then
					outsideInputRemove = win:_listen("Began", function(input)
						if not state.Open or not isPress(input) then return end
						local point = mouse()
						if not inside(point, popupFrame) and not inside(point, card) then setOpen(false) end
					end)
				end
			else
				local w = lastPopupW
				tween(popupFrame, { Size = UDim2.fromOffset(w, 0) }, .22, QUINT)
				tween(popupScale, { Scale = .96 }, .2)
				local b = backdrop
				backdrop = nil
				if b then b:Destroy() end
				if popupFollowRemove then popupFollowRemove() popupFollowRemove = nil end
				if outsideInputRemove then outsideInputRemove() outsideInputRemove = nil end
				if win._popupOwner == state then win._popupClose = nil win._popupOwner = nil end
				task.delay(.23, function() if not state.Open and popupFrame.Parent then popupFrame.Visible = false end end)
			end
		else
			tween(card, { Size = UDim2.new(1, 0, 0, open and openHeight() or headH) }, .5, open and SPRING or QUINT)
		end
		tween(searchRow, { BackgroundTransparency = open and 0 or 1 }, .2)
		tween(searchStroke, { Transparency = open and 0 or 1 }, .2)
		tween(searchBox, { TextTransparency = open and 0 or 1 }, .2)
		chevron:Set(open)
		tween(pillStroke, { Color = open and Theme.StrokeHover or Theme.Stroke }, .2)
		animateRows(open)
	end
	state.SetOpen = setOpen

	local function buildRows()
		local want = {}
		for i, o in ipairs(options) do want[o] = i end
		for o, row in pairs(rows) do
			if not want[o] then
				row.Frame:Destroy()
				rows[o] = nil
			end
		end
		for i, o in ipairs(options) do
			local row = rows[o]
			if row then
				row.Frame.LayoutOrder = i
			else
				local f = new("TextButton", {
					Size = UDim2.new(1, 0, 0, OPT_H), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, Text = "",
					AutoButtonColor = false, LayoutOrder = i, ZIndex = z, Parent = host,
				})
				corner(f, UDim.new(0, 6))
				local rs = stroke(f, Theme.Stroke, 1)
				local check = new("ImageLabel", {
					AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1, ImageColor3 = Theme.Accent, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = z, Parent = f,
				})
				setIcon(check, "check")
				local cs = new("UIScale", { Scale = .6, Parent = check })
				local label = mkText {
					Position = UDim2.fromOffset(12, -1), Size = UDim2.new(1, -36, 1, 0), Text = tostring(o), TextSize = 13,
					TextColor3 = Theme.Muted, TextTransparency = 1, ZIndex = z, Parent = f,
				}
				local rowObj = { Frame = f, Label = label, Check = check, Scale = cs, Stroke = rs, On = false }
				rows[o] = rowObj
				f.MouseEnter:Connect(function()
					tween(label, { TextColor3 = Theme.Text }, .15)
					if state.Open then tween(rs, { Color = Theme.StrokeHover }, .12) end
				end)
				f.MouseLeave:Connect(function()
					tween(label, { TextColor3 = selected[o] and Theme.Text or Theme.Muted }, .2)
					tween(rs, { Color = Theme.Stroke }, .2)
				end)
				f.MouseButton1Click:Connect(function()
					if selected[o] then
						selected[o] = nil
					else
						if not multi then selected = {} end
						selected[o] = true
					end
					refreshVisual()
					fire(cfg.Callback, getValue())
					if not multi and selected[o] then setOpen(false) end
				end)
			end
		end
		applyFilter()
		if state.Open then
			if popup then
				local h = openHeight()
				tween(popupFrame, { Size = UDim2.fromOffset(lastPopupW, h) }, .3, QUINT)
			else
				card.Size = UDim2.new(1, 0, 0, openHeight())
			end
		end
	end

	local obj = state
	function obj:Set(v, silent)
		selected = {}
		if multi then
			for _, o in ipairs(type(v) == "table" and v or { v }) do selected[o] = true end
		elseif v ~= nil then
			selected[v] = true
		end
		refreshVisual()
		pulse(st)
		if not silent then fire(cfg.Callback, getValue()) end
	end
	function obj:Get() return getValue() end
	function obj:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then selected = {} end
		buildRows()
		refreshVisual()
		if state.Open then setOpen(true) end
	end

	head.MouseButton1Click:Connect(function() setOpen(not state.Open) end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		query = string.lower(searchBox.Text)
		applyFilter()
		if state.Open then
			if popup then
				placePopup(openHeight(), true)
			else
				tween(card, { Size = UDim2.new(1, 0, 0, openHeight()) }, .35, QUINT)
			end
		end
	end)

	buildRows()
	refreshVisual()
	task.defer(fitPill, true)
	if popup then
		obj._listeners = obj._listeners or {}
		table.insert(obj._listeners, function()
			state.Open = false
			if popupFollowRemove then popupFollowRemove() popupFollowRemove = nil end
			if outsideInputRemove then outsideInputRemove() outsideInputRemove = nil end
			if win._popupOwner == state then win._popupClose = nil win._popupOwner = nil end
			if backdrop then backdrop:Destroy() backdrop = nil end
			if popupFrame then
				for i, r in ipairs(win._themeRoots or {}) do
					if r == popupFrame then table.remove(win._themeRoots, i) break end
				end
				popupFrame:Destroy()
			end
		end)
	end
	return register(self, cfg, obj, card, "Dropdown")
end

function Container:Input(cfg)
	local card, st, title, sub
	cfg, card, st, _, title, sub = baseCard(self, cfg, { Title = "Name", Description = "Desc", PlaceholderText = "Placeholder", CurrentValue = "Default", Value = "Default" }, "Frame", 160, "Input")
	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(170, 30),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, Parent = card,
	})
	corner(box, UDim.new(0, 6))
	local boxStroke = stroke(box)
	local icon = cfg.Icon
	if icon then iconBox(box, icon, Theme.Muted, UDim2.new(0, 8, .5, 0)) end
	local input = new("TextBox", {
		Position = UDim2.fromOffset(icon and 30 or 8, 0), Size = UDim2.new(1, icon and -38 or -16, 1, 0), BackgroundTransparency = 1,
		Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text,
		TextSize = 14, FontFace = Fonts.Regular, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.None, ClipsDescendants = true, Parent = box,
	})
	local focused = false
	local extra = (icon and 30 or 8) + 8
	local function fit(instant)
		local avail = card.AbsoluteSize.X / scaleFor(self.Window, card)
		local maxW = math.clamp(avail - 14 - 110 - 20, 100, 200)
		local textW = input.TextBounds.X
		if #input.Text == 0 then textW = math.min(input.TextBounds.X, 90) end
		local w = math.clamp(textW + extra + 12, 90, maxW) + (focused and 8 or 0)
		w = math.min(w, maxW + 8)
		setPad(title, sub, w + 20)
		if instant then box.Size = UDim2.fromOffset(w, 30) else tween(box, { Size = UDim2.fromOffset(w, 30) }, .3, SPRING) end
	end
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit(true) end)
	input:GetPropertyChangedSignal("Text"):Connect(function() fit(false) end)
	input:GetPropertyChangedSignal("TextBounds"):Connect(function() fit(false) end)
	task.defer(fit, true)
	input.Focused:Connect(function()
		focused = true
		tween(boxStroke, { Color = Theme.Accent }, .2)
		fit(false)
	end)
	input.FocusLost:Connect(function(enter)
		focused = false
		tween(boxStroke, { Color = Theme.Stroke }, .25)
		fit(false)
		if cfg.Numeric and not tonumber(input.Text) then
			input.Text = ""
			return
		end
		fire(cfg.Callback, input.Text, enter)
	end)
	return register(self, cfg, {
		Set = function(_, v) input.Text = tostring(v) pulse(st) end,
		Get = function() return input.Text end,
	}, card, "Input")
end

function Container:Keybind(cfg)
	local card, st, title, sub
	cfg, card, st, _, title, sub = baseCard(self, cfg, { Title = "Name", Description = "Desc", CurrentKeybind = "Default", Value = "Default" }, "Frame", 110, "Keybind")
	if type(cfg.Default) == "string" then cfg.Default = Enum.KeyCode[cfg.Default] end
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(44, CTRL_H),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = card,
	})
	corner(btn, UDim.new(0, 6))
	local btnStroke = stroke(btn)
	local label = mkText {
		Size = UDim2.fromScale(1, 1), TextSize = 13, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None, Parent = btn,
	}
	label:SetAttribute("AF_NoTranslate", true)
	local obj = { Value = cfg.Default, Listening = false }
	local function fit(instant)
		local w = math.max(label.TextBounds.X + 20, Touch and 44 or 36)
		setPad(title, sub, w + 20)
		if instant then btn.Size = UDim2.fromOffset(w, CTRL_H) else tween(btn, { Size = UDim2.fromOffset(w, CTRL_H) }, .35, SPRING) end
	end
	label:GetPropertyChangedSignal("TextBounds"):Connect(function() fit(false) end)
	local function render()
		label.Text = obj.Listening and "..." or keyName(obj.Value)
		tween(btnStroke, { Color = obj.Listening and Theme.Accent or Theme.Stroke }, .2)
		tween(label, { TextColor3 = obj.Listening and Theme.Accent or Theme.Muted }, .2)
	end
	function obj:Set(key, silent)
		local was = obj.Listening
		obj.Value = key
		obj.Listening = false
		render()
		if type(obj._quickSync) == "function" then obj._quickSync() end
		if not was then pulse(st) end
		if not silent then fire(cfg.OnChanged, key) end
	end
	function obj:Get() return obj.Value end
	btn.MouseButton1Click:Connect(function()
		obj.Listening = not obj.Listening
		render()
	end)
	self.Window:_listen("Began", function(i, processed)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if obj.Listening then
			self.Window._consumedKey = i.KeyCode
			self.Window._consumedAt = os.clock()
			if i.KeyCode == Enum.KeyCode.Escape then
				obj.Listening = false
				render()
			else
				obj:Set(i.KeyCode)
			end
			return
		end
		if not processed and obj.Value ~= nil and i.KeyCode == obj.Value then fire(cfg.Callback, i.KeyCode) end
	end, obj)
	render()
	task.defer(fit, true)
	return register(self, cfg, obj, card, "Keybind")
end

function Container:ColorPicker(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc", Color = "Default", CurrentValue = "Default", Value = "Default" })
	local win = self.Window
	local headH = cfg.Desc and DESC_H or ROW_H
	local card, st = makeCard(self, "Frame", headH)
	card.ClipsDescendants = true
	hover(card, st)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = card })
	titles(head, cfg.Name or "Color", cfg.Desc, 150)
	local swatchGlow = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, -52, .5, 0), Size = UDim2.fromOffset(66, 46), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .72, ZIndex = 0, Parent = head,
	})
	local swatch = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -34, .5, 0), Size = UDim2.fromOffset(36, 20), BorderSizePixel = 0, Parent = head,
	})
	corner(swatch, UDim.new(0, 6))
	stroke(swatch, Theme.Stroke)
	local hexLabel = mkText {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -78, .5, 0), Size = UDim2.fromOffset(72, 18), TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.None, Parent = head,
	}
	local chevron = makeChevron(head, 1, -12)

	local BODY_H = 214
	local body = new("Frame", { Position = UDim2.fromOffset(14, headH + 2), Size = UDim2.new(1, -28, 0, BODY_H), BackgroundTransparency = 1, Visible = false, Parent = card })

	local sv = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 122), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = body,
	})
	corner(sv, UDim.new(0, 8))
	stroke(sv, Theme.Stroke)
	local svGrad = new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 0, 0)), Parent = sv })
	local dark = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
	corner(dark, UDim.new(0, 8))
	new("UIGradient", { Transparency = NumberSequence.new { NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }, Rotation = 90, Parent = dark })
	local curHalo = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Image = Assets.Glow,
		ImageColor3 = Theme.Accent, ImageTransparency = .6, ZIndex = 3, Parent = sv,
	})
	local cur = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 4, Parent = sv,
	})
	corner(cur, UDim.new(1, 0))
	stroke(cur, Color3.new(1, 1, 1), 0, 2.5)

	local hueBar = new("TextButton", {
		Position = UDim2.fromOffset(0, 132), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = body,
	})
	corner(hueBar, UDim.new(1, 0))
	new("UIGradient", {
		Color = ColorSequence.new {
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}, Rotation = 0, Parent = hueBar,
	})
	local hueThumb = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 5, .5, 0), Size = UDim2.fromOffset(10, 20),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = hueBar,
	})
	corner(hueThumb, UDim.new(1, 0))
	stroke(hueThumb, Color3.new(1, 1, 1), 0, 2)

	local presets = cfg.Presets or {
		Theme.Accent, Color3.fromRGB(255, 107, 129), Color3.fromRGB(255, 176, 102), Color3.fromRGB(255, 230, 109),
		Color3.fromRGB(120, 230, 160), Color3.fromRGB(102, 204, 255), Color3.fromRGB(140, 130, 255), Color3.fromRGB(255, 255, 255),
	}
	local presetRow = new("Frame", { Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = body })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8), Parent = presetRow,
	})

	local hexRow = new("Frame", { Position = UDim2.fromOffset(0, 186), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = body })
	local hexBox = new("Frame", { Size = UDim2.fromOffset(118, 28), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = hexRow })
	corner(hexBox, UDim.new(0, 6))
	local hexStroke = stroke(hexBox)
	local hexInput = new("TextBox", {
		Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = "", TextTruncate = Enum.TextTruncate.None,
		TextColor3 = Theme.Text, TextSize = 13, FontFace = Fonts.Regular, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = hexBox,
	})
	local rgbLabel = mkText {
		Position = UDim2.fromOffset(130, 0), Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 13, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = hexRow,
	}

	local obj = { Open = false }
	local h, s, v = Color3.toHSV(cfg.Default or Theme.Accent)
	local dh, ds, dv = h, s, v
	local settling = false
	local dragMode
	local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5)) end

	local function paint()
		local c = Color3.fromHSV(dh, ds, dv)
		cur.Position = UDim2.fromScale(ds, 1 - dv)
		curHalo.Position = cur.Position
		cur.BackgroundColor3 = c
		curHalo.ImageColor3 = c
		hueThumb.Position = UDim2.new(dh, (.5 - dh) * 10, .5, 0)
		hueThumb.BackgroundColor3 = Color3.fromHSV(dh, 1, 1)
	end
	local function apply(animate)
		local c = Color3.fromHSV(h, s, v)
		obj.Value = c
		local t = animate and .2 or 0
		tween(swatch, { BackgroundColor3 = c }, t)
		tween(swatchGlow, { ImageColor3 = c }, t)
		svGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
		hexLabel.Text = hex(c)
		if not hexInput:IsFocused() then hexInput.Text = hex(c) end
		rgbLabel.Text = string.format("RGB %d, %d, %d", math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5))
	end
	local function commit(animate, silent)
		apply(animate)
		settling = true
		if not silent then fire(cfg.Callback, obj.Value) end
	end
	function obj:Set(c, silent)
		h, s, v = Color3.toHSV(c)
		commit(true, silent)
		pulse(st)
	end
	function obj:Get() return obj.Value end

	win:_listen("Render", function(dt)
		if not (obj.Open or settling) then return end
		local a = 1 - math.exp(-dt * 26)
		dh += (h - dh) * a
		ds += (s - ds) * a
		dv += (v - dv) * a
		if not dragMode and math.abs(dh - h) < .0008 and math.abs(ds - s) < .0008 and math.abs(dv - v) < .0008 then
			dh, ds, dv = h, s, v
			settling = false
		end
		paint()
	end, obj)

	local blooms = { sv, hueBar, presetRow, hexRow }
	local function setOpen(o)
		obj.Open = o
		tween(card, { Size = UDim2.new(1, 0, 0, o and headH + BODY_H + 16 or headH) }, .6, o and SPRING or QUINT)
		chevron:Set(o)
		if o then
			body.Visible = true
			paint()
			for i, el in ipairs(blooms) do
				local sc = el:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = el })
				sc.Scale = .86
				task.delay(.03 + i * .055, function()
					if obj.Open then tween(sc, { Scale = 1 }, .65, SPRING) end
				end)
			end
		else
			task.delay(.4, function() if not obj.Open then body.Visible = false end end)
		end
	end
	function obj:SetOpen(o) setOpen(o == true) end
	head.MouseButton1Click:Connect(function() setOpen(not obj.Open) end)

	for i, c in ipairs(presets) do
		local b = new("TextButton", {
			Size = UDim2.fromOffset(20, 20), BackgroundColor3 = c, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = presetRow,
		})
		corner(b, UDim.new(1, 0))
		local bs = stroke(b, Theme.Stroke)
		local sc = new("UIScale", { Parent = b })
		b.MouseEnter:Connect(function()
			tween(sc, { Scale = 1.25 }, .4, SPRING)
			tween(bs, { Color = Theme.Text }, .15)
		end)
		b.MouseLeave:Connect(function()
			tween(sc, { Scale = 1 }, .4, SPRING)
			tween(bs, { Color = Theme.Stroke }, .2)
		end)
		b.MouseButton1Down:Connect(function() tween(sc, { Scale = .85 }, .1) end)
		b.MouseButton1Click:Connect(function()
			tween(sc, { Scale = 1.25 }, .5, SPRING)
			obj:Set(b.BackgroundColor3)
		end)
	end

	local function grow(el, halo, on)
		tween(el, { Size = on and UDim2.fromOffset(el == cur and 24 or 12, el == cur and 24 or 24) or (el == cur and UDim2.fromOffset(16, 16) or UDim2.fromOffset(10, 20)) }, .45, SPRING)
		if halo then tween(halo, { Size = on and UDim2.fromOffset(70, 70) or UDim2.fromOffset(44, 44), ImageTransparency = on and .35 or .6 }, .3) end
	end
	local function svFrom(m)
		s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		commit(false)
	end
	local function hueFrom(m)
		h = math.clamp((m.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, .999)
		commit(false)
	end
	sv.InputBegan:Connect(function(i)
		if isPress(i) then
			dragMode = "sv"
			grow(cur, curHalo, true)
			svFrom(mouse())
		end
	end)
	hueBar.InputBegan:Connect(function(i)
		if isPress(i) then
			dragMode = "hue"
			tween(hueThumb, { Size = UDim2.fromOffset(14, 26) }, .45, SPRING)
			hueFrom(mouse())
		end
	end)
	win:_listen("Changed", function(i)
		if not dragMode or not isMove(i) then return end
		local m = mouse()
		if dragMode == "sv" then svFrom(m) else hueFrom(m) end
	end, obj)
	win:_listen("Ended", function(i)
		if dragMode and isPress(i) then
			local was = dragMode
			dragMode = nil
			if was == "sv" then grow(cur, curHalo, false) else tween(hueThumb, { Size = UDim2.fromOffset(10, 20) }, .5, SPRING) end
		end
	end, obj)
	hexInput.Focused:Connect(function() tween(hexStroke, { Color = Theme.Accent }, .15) end)
	hexInput.FocusLost:Connect(function()
		tween(hexStroke, { Color = Theme.Stroke }, .2)
		local r, g, b = hexInput.Text:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
		if r then
			obj:Set(Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)))
		else
			hexInput.Text = hex(obj.Value)
		end
	end)
	apply(false)
	paint()
	for _, inst in ipairs({ swatch, swatchGlow, cur, curHalo, hueThumb }) do inst:SetAttribute("AF_NoTheme", true) end
	return register(self, cfg, obj, card, "ColorPicker")
end

function Container:Stepper(cfg)
	local card, st, title, sub
	cfg, card, st, _, title, sub = baseCard(self, cfg, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default", Increment = "Step" }, "Frame", 150, "Stepper")
	local min, max, step, suffix = cfg.Min or 0, cfg.Max or 100, cfg.Step or 1, cfg.Suffix or ""
	local fmt = snapper(min, max, step)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(0, CTRL_H),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = card,
	})
	corner(box, UDim.new(0, 6))
	local boxStroke = stroke(box)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = box })
	local function stepBtn(sym, order)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(CTRL_H, CTRL_H), BackgroundTransparency = 1, Text = sym, TextColor3 = Theme.Muted, TextSize = 18,
			FontFace = Fonts.Medium, AutoButtonColor = false, LayoutOrder = order, Parent = box,
		})
		b.MouseEnter:Connect(function() tween(b, { TextColor3 = Theme.Accent }, .12) end)
		b.MouseLeave:Connect(function() tween(b, { TextColor3 = Theme.Muted }, .2) end)
		return b
	end
	local minus = stepBtn("−", 1)
	local value = mkText {
		Size = UDim2.new(0, 30, 1, 0), TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Parent = box,
	}
	local plus = stepBtn("+", 3)
	value:GetPropertyChangedSignal("TextBounds"):Connect(function()
		tween(value, { Size = UDim2.new(0, math.max(value.TextBounds.X + 12, 30), 1, 0) }, .3, SPRING)
	end)
	box:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		setPad(title, sub, box.AbsoluteSize.X / scaleFor(self.Window, box) + 20)
	end)
	local obj = { Value = math.clamp(cfg.Default or min, min, max) }
	local byButton = false
	local function render()
		value.Text = fmt.format(obj.Value) .. suffix
		tween(minus, { TextTransparency = obj.Value <= min and .6 or 0 }, .15)
		tween(plus, { TextTransparency = obj.Value >= max and .6 or 0 }, .15)
	end
	function obj:Set(v, silent)
		v = fmt.snap(tonumber(v) or min)
		if v == obj.Value then return end
		obj.Value = v
		render()
		if type(obj._quickSync) == "function" then obj._quickSync() end
		if not byButton then pulse(st) end
		if not silent then fire(cfg.Callback, v) end
	end
	function obj:Get() return obj.Value end
	local function nudge(dir)
		byButton = true
		obj:Set(obj.Value + dir * step)
		byButton = false
		tween(boxStroke, { Color = Theme.StrokeHover }, .08)
		task.delay(.12, function() tween(boxStroke, { Color = Theme.Stroke }, .25) end)
	end
	local function holdable(b, dir)
		local down = false
		b.InputBegan:Connect(function(i)
			if not isPress(i) then return end
			down = true
			nudge(dir)
			task.delay(.4, function()
				while down do
					nudge(dir)
					task.wait(.07)
				end
			end)
		end)
		b.InputEnded:Connect(function(i) if isPress(i) then down = false end end)
		b.MouseLeave:Connect(function() down = false end)
	end
	holdable(minus, -1)
	holdable(plus, 1)
	render()
	return register(self, cfg, obj, card, "Stepper")
end

function Container:Progress(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc", CurrentValue = "Default", Value = "Default" })
	local h = cfg.Desc and DESC_H + 10 or ROW_H + 10
	local card, st = makeCard(self, "Frame", h)
	hover(card, st)
	local top = cfg.Desc and (DESC_H - 38) / 2 - 2 or 12
	mkText { Position = UDim2.fromOffset(14, top), Size = UDim2.new(1, -110, 0, 18), Text = cfg.Name or "Progress", Parent = card }
	if cfg.Desc then
		mkText {
			Position = UDim2.fromOffset(14, top + 20), Size = UDim2.new(1, -110, 0, 17), Text = cfg.Desc, TextSize = 13,
			FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = card,
		}
	end
	local pct = mkText {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, top), Size = UDim2.fromOffset(90, 18),
		TextXAlignment = Enum.TextXAlignment.Right, TextSize = 13, TextColor3 = Theme.Accent, Parent = card,
	}
	local bar = new("Frame", { Position = UDim2.new(0, 14, 1, -16), Size = UDim2.new(1, -28, 0, 5), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = card })
	corner(bar, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = cfg.Color or Theme.Accent, BorderSizePixel = 0, Parent = bar })
	corner(fill, UDim.new(1, 0))
	local obj = { Value = math.clamp(cfg.Default or 0, 0, 1) }
	local function render(t)
		tween(fill, { Size = UDim2.new(obj.Value, 0, 1, 0) }, t, LIQUID)
		pct.Text = type(cfg.Format) == "function" and tostring(cfg.Format(obj.Value)) or string.format("%d%%", math.floor(obj.Value * 100 + .5))
	end
	function obj:Set(v, silent)
		v = math.clamp(tonumber(v) or 0, 0, 1)
		if v == obj.Value then return end
		obj.Value = v
		render(.6)
		if not silent then fire(cfg.Callback, v) end
	end
	function obj:Get() return obj.Value end
	function obj:SetColor(c) fill.BackgroundColor3 = c end
	render(0)
	return register(self, cfg, obj, card, "Progress")
end

local function makeFloat(win, col, fromPos, fromSize, onDock)
	local fgui = new("ScreenGui", {
		Name = "AirflowFloat", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000 + Library._z,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function() if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then syn.protect_gui(fgui) end end)
	fgui.Parent = win.Gui.Parent or getGuiParent()
	if type(Library._translationHookRoot) == "function" then pcall(Library._translationHookRoot, Library, fgui) end

	local screen = win.Gui.AbsoluteSize
	local W = math.min(math.max(fromSize.X + 28, 220), math.max(screen.X - 16, 160))
	local host = new("Frame", { Name = "Host", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20, Parent = fgui })
	local startC = fromPos + fromSize / 2
	local root = new("Frame", {
		Name = "Float", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(startC.X, startC.Y),
		Size = UDim2.fromOffset(W, math.max(fromSize.Y, 60)), BackgroundTransparency = 1, Parent = fgui,
	})
	local scale = new("UIScale", { Scale = .92, Parent = root })
	floatHosts[root] = host

	local shadow = new("ImageLabel", {
		Position = UDim2.fromOffset(-25, -25), Size = UDim2.new(1, 50, 1, 50), BackgroundTransparency = 1, Image = Assets.Shadow,
		ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), Parent = root,
	})
	local body = new("CanvasGroup", {
		Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		GroupTransparency = 1, Active = true, ClipsDescendants = true, Parent = root,
	})
	corner(body, UDim.new(0, 12))
	local bs = stroke(body, Theme.StrokeHover)
	sheen(body)
	glow(body, UDim2.fromOffset(340, 120), UDim2.new(.5, 0, 1, 8), .88, 270)

	local bar = new("Frame", { Name = "Bar", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = body })
	local dot = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 14, .5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar })
	corner(dot, UDim.new(1, 0))
	local BTN = Touch and 26 or 22
	local titleBase = 28 + 2 * BTN + 26
	local titleLbl = mkText {
		Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -titleBase, 1, 0), Text = string.upper(col.Name), TextSize = 12, Parent = bar,
	}
	local lockBtn = new("TextButton", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(1, -(2 * BTN + 10), .5, 0), Size = UDim2.fromOffset(BTN, BTN),
		BackgroundColor3 = Theme.Surface3, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = bar,
	})
	corner(lockBtn, UDim.new(0, 6))
	local lockScale = new("UIScale", { Parent = lockBtn })
	local lockIcon = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, Image = "rbxassetid://119201572260567", ImageColor3 = Theme.Muted,
		ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = lockBtn,
	})
	local LOCKED_ICON = "rbxassetid://74027613267551"
	local UNLOCKED_ICON = "rbxassetid://119201572260567"
	local function tintLockIcon(color, duration)
		tween(lockIcon, { ImageColor3 = color }, duration or .15)
	end
	lockBtn.MouseEnter:Connect(function()
		tween(lockBtn, { BackgroundTransparency = col.Locked and .62 or 0 }, .15)
		tintLockIcon(Theme.Accent, .15)
		tween(lockScale, { Scale = 1.12 }, .4, SPRING)
	end)
	lockBtn.MouseLeave:Connect(function()
		tween(lockBtn, { BackgroundTransparency = col.Locked and .78 or 1 }, .25)
		tintLockIcon(col.Locked and Theme.Accent or Theme.Muted, .25)
		tween(lockScale, { Scale = 1 }, .4, SPRING)
	end)
	lockBtn.MouseButton1Down:Connect(function() tween(lockScale, { Scale = .86 }, .1) end)
	lockBtn.MouseButton1Up:Connect(function() tween(lockScale, { Scale = 1.12 }, .5, SPRING) end)
	local dockBtn = glyph(bar, "minimize-2", "×", UDim2.new(1, -(BTN + 8), .5, 0), BTN)
	local dockImg = dockBtn:FindFirstChildOfClass("ImageLabel")
	local dockProp = dockImg and "ImageTransparency" or "TextTransparency"
	if not dockImg then dockImg = dockBtn:FindFirstChildOfClass("TextLabel") end
	local lockChip = new("Frame", {
		Name = "LockedChip", AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -(2 * BTN + 18), .5, 0), Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Accent, BackgroundTransparency = .84, BorderSizePixel = 0, Visible = false, Parent = bar,
	})
	corner(lockChip, UDim.new(1, 0))
	stroke(lockChip, Theme.Accent, .55)
	pad(lockChip, 8, 8)
	local chipScale = new("UIScale", { Parent = lockChip })
	mkText {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "LOCKED", TextSize = 10, FontFace = Fonts.Bold,
		TextColor3 = Theme.Accent, TextTruncate = Enum.TextTruncate.None, Parent = lockChip,
	}
	new("Frame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = body })

	local scroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 35), Size = UDim2.new(1, 0, 1, -35), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = .5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = body,
	})
	pad(scroll, 0, 0, 8, 8)
	local f = col.Frame
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Position = UDim2.fromOffset(14, 0)
	f.Size = UDim2.new(1, -28, 0, 0)
	f.Visible = true
	f.Parent = scroll
	col.Labels[3] = titleLbl

	local api = { Gui = fgui, Root = root, Col = col }
	local closed = false
	local manualSize = false
	local manualHeightOffset = 0
	local resizing = false
	local recalibratingSize = false
	local resizeReady = false
	local resizeStartSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
	local resizeStartMouse = Vector2.zero
	local resizeStartScale = 1
	local resizePending
	local fitTween
	local removes = {}

	local function contentHeight()
		local sc = math.max(scale.Scale, .01)
		return col.Layout.AbsoluteContentSize.Y / sc + 51
	end

	local function fit(instant)
		if resizing or recalibratingSize then return end
		local maxH = math.max(win.Gui.AbsoluteSize.Y - 40, 140)
		local targetW = manualSize and root.Size.X.Offset or W
		local hh = math.clamp(contentHeight() + (manualSize and manualHeightOffset or 0), 110, maxH)
		if manualSize then
			if fitTween then fitTween:Cancel() fitTween = nil end
			root.Size = UDim2.fromOffset(targetW, hh)
			return
		end
		if not instant and math.abs(root.Size.Y.Offset - hh) < 2 and math.abs(root.Size.X.Offset - targetW) < 2 then return end
		if fitTween then fitTween:Cancel() fitTween = nil end
		if instant then root.Size = UDim2.fromOffset(targetW, hh) else fitTween = tween(root, { Size = UDim2.fromOffset(targetW, hh) }, .45, LIQUID) end
	end
	col.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if not closed then fit(false) end end)

	local resizeGrip = new("Frame", {
		Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 30, Parent = root,
	})
	local resizeGlow = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(60, 60),
		BackgroundTransparency = 1, Image = "rbxassetid://120997033468887", ImageColor3 = Theme.Accent,
		ImageTransparency = .8, ZIndex = 30, Parent = resizeGrip,
	})
	local function shake()
		if closed then return end
		tween(lockBtn, { Rotation = -16 }, .06)
		task.delay(.06, function() tween(lockBtn, { Rotation = 16 }, .06) end)
		task.delay(.12, function() tween(lockBtn, { Rotation = 0 }, .45, SPRING) end)
		chipScale.Scale = 1.25
		tween(chipScale, { Scale = 1 }, .5, SPRING)
		tween(bs, { Transparency = 0 }, .08)
		task.delay(.14, function()
			if not closed then tween(bs, { Transparency = col.Locked and .45 or 0 }, .4) end
		end)
	end
	api.Shake = shake
	local lastLocked
	local function refreshLockState()
		local locked = col.Locked == true
		if titleLbl and titleLbl.Parent then
			titleLbl.Text = string.upper(col.Name)
			titleLbl.TextSize = 12
			titleLbl.TextColor3 = Theme.Text
			titleLbl.Size = UDim2.new(1, -(titleBase + (locked and 66 or 0)), 1, 0)
		end
		if col.Labels[2] and col.Labels[2].Parent then
			col.Labels[2].Text = locked and (col.Name .. "  ·  floating locked") or (col.Name .. "  ·  floating")
		end
		if col.GhostButton and col.GhostButton.Parent then
			col.GhostButton.Text = locked and "Locked" or "Dock"
			col.GhostButton.TextColor3 = locked and Theme.Muted or Theme.Accent
		end
		lockIcon.Image = locked and LOCKED_ICON or UNLOCKED_ICON
		tintLockIcon(locked and Theme.Accent or Theme.Muted, .18)
		tween(lockBtn, { BackgroundColor3 = locked and Theme.Accent or Theme.Surface3, BackgroundTransparency = locked and .78 or 1 }, .25)
		lockBtn.Visible = true
		dockBtn.Visible = true
		if dockImg then tween(dockImg, { [dockProp] = locked and .65 or 0 }, .2) end
		lockChip.Visible = locked
		if locked and lastLocked ~= true and lastLocked ~= nil then
			chipScale.Scale = .6
			tween(chipScale, { Scale = 1 }, .55, SPRING)
		end
		lastLocked = locked
		tween(bs, { Color = locked and Theme.Accent or Theme.StrokeHover, Transparency = locked and .45 or 0 }, .3)
		resizeGrip.Visible = resizeReady and not locked and not closed
	end
	col.RefreshFloatStatus = refreshLockState
	col.Locked = false
	lockBtn.MouseButton1Click:Connect(function()
		if closed then return end
		col.Locked = not col.Locked
		if col.Locked and resizing then
			resizing = false
			resizePending = nil
			tween(resizeGlow, { ImageTransparency = .8 }, .25)
		end
		refreshLockState()
		lockScale.Scale = 1.35
		tween(lockScale, { Scale = 1 }, .5, SPRING)
	end)
	resizeGrip.InputBegan:Connect(function(i)
		if closed or col.Locked or not resizeReady or not isPress(i) then return end
		resizing = true
		manualSize = true
		if fitTween then fitTween:Cancel() fitTween = nil end
		resizeStartSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
		resizeStartMouse = mouse()
		resizeStartScale = math.max(scale.Scale, .01)
		resizePending = resizeStartSize
		tween(resizeGlow, { ImageTransparency = .45 }, .12)
	end)
	resizeGrip.MouseEnter:Connect(function()
		if not resizing and not col.Locked then tween(resizeGlow, { ImageTransparency = .55 }, .15) end
	end)
	resizeGrip.MouseLeave:Connect(function()
		if not resizing then tween(resizeGlow, { ImageTransparency = .8 }, .25) end
	end)

	local function clampBack()
		local sc = win.Gui.AbsoluteSize
		local c = api.Drag.Center()
		local hw, hh = root.Size.X.Offset / 2, root.Size.Y.Offset / 2
		local nx = math.clamp(c.X, math.min(hw, sc.X / 2), math.max(sc.X - hw, sc.X / 2))
		local ny = math.clamp(c.Y, math.min(hh, sc.Y / 2), math.max(sc.Y - hh, sc.Y / 2))
		if (Vector2.new(nx, ny) - c).Magnitude > .5 then tween(root, { Position = UDim2.fromOffset(nx, ny) }, .5, SPRING) end
	end
	api.Drag = makeDragger(root, scale, {
		base = function() return 1 end,
		tilt = true,
		tiltTarget = root,
		tiltMax = 1.1,
		tiltMultiplier = .0011,
		onLift = function(on)
			tween(shadow, { ImageTransparency = on and .35 or .55 }, .3)
			tween(bs, { Color = on and Theme.Accent or (col.Locked and Theme.Accent or Theme.StrokeHover) }, .25)
		end,
		onDrop = function() task.delay(.05, clampBack) end,
	})
	local function topAt(m)
		local best, order = nil, -1
		for _, fl in ipairs(win._floats) do
			if fl.Root.Parent and inside(m, fl.Root) and fl.Gui.DisplayOrder > order then best, order = fl, fl.Gui.DisplayOrder end
		end
		return best
	end
	table.insert(removes, win:_listen("Began", function(i)
		if closed or not isPress(i) then return end
		local m = mouse()
		if not inside(m, root) or topAt(m) ~= api then return end
		Library._z += 1
		fgui.DisplayOrder = 1000 + Library._z
		if inside(m, bar) and not inside(m, dockBtn) and not inside(m, lockBtn) then
			if col.Locked then shake() else api.Drag:Begin() end
		end
	end))
	table.insert(removes, win:_listen("Ended", function(i)
		if api.Drag.Active and isPress(i) then api.Drag:End() end
		if resizing and isPress(i) then
			resizing = false
			recalibratingSize = true
			if resizePending then root.Size = UDim2.fromOffset(resizePending.X, resizePending.Y) end
			resizePending = nil
			tween(resizeGlow, { ImageTransparency = col.Locked and .8 or .65 }, .25)
			task.defer(function()
				if closed then return end
				manualHeightOffset = root.Size.Y.Offset - contentHeight()
				recalibratingSize = false
				fit(false)
				clampBack()
			end)
		end
	end))
	table.insert(removes, win:_listen("Render", function(dt)
		api.Drag:Step(dt)
		if not resizing or closed or col.Locked then return end
		local d = (mouse() - resizeStartMouse) / resizeStartScale
		local screenSize = win.Gui.AbsoluteSize
		local minW, minH = 220, 120
		local maxW, maxH = math.max(minW, screenSize.X - 24), math.max(minH, screenSize.Y - 24)
		resizePending = Vector2.new(
			math.clamp(resizeStartSize.X + d.X * 2, minW, maxW),
			math.clamp(resizeStartSize.Y + d.Y * 2, minH, maxH)
		)
		local cur = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
		local alpha = 1 - math.exp(-dt * 35)
		local nextSize = cur:Lerp(resizePending, alpha)
		local nx, ny = math.floor(nextSize.X + .5), math.floor(nextSize.Y + .5)
		if nx ~= cur.X or ny ~= cur.Y then root.Size = UDim2.fromOffset(nx, ny) end
	end))
	dockBtn.MouseButton1Click:Connect(function() if col.Locked then shake() else onDock() end end)

	local target = startC + Vector2.new(30, 26)
	local expectH = math.clamp(col.Layout.AbsoluteContentSize.Y / .92 + 51, 110, math.max(screen.Y - 40, 140))
	target = Vector2.new(
		math.clamp(target.X, W / 2 + 8, math.max(screen.X - W / 2 - 8, W / 2 + 8)),
		math.clamp(target.Y, expectH / 2 + 8, math.max(screen.Y - expectH / 2 - 8, expectH / 2 + 8))
	)
	tween(root, { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(W, expectH) }, .75, LIQUID)
	tween(scale, { Scale = 1 }, .75, SPRING)
	tween(body, { GroupTransparency = 0 }, .3)
	tween(shadow, { ImageTransparency = .55 }, .4)
	task.delay(.1, function() if not closed then fit(false) end end)
	task.delay(.78, function()
		if closed then return end
		resizeReady = true
		refreshLockState()
	end)
	refreshLockState()

	function api.Close(toCenter, done)
		if closed then return end
		closed = true
		for _, r in ipairs(removes) do r() end
		removes = {}
		for i, fl in ipairs(win._floats) do if fl == api then table.remove(win._floats, i) break end end
		if api.Drag.Active then api.Drag:End() end
		resizing = false
		resizeReady = false
		resizeGrip.Visible = false
		if toCenter then tween(root, { Position = UDim2.fromOffset(toCenter.X, toCenter.Y) }, .42, QUINT) end
		tween(scale, { Scale = .86 }, .38, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(body, { GroupTransparency = 1 }, .3)
		tween(shadow, { ImageTransparency = 1 }, .25)
		task.delay(.4, function()
			if done then done() end
			if fgui.Parent then fgui:Destroy() end
		end)
	end
	function api.Destroy()
		if closed then return end
		closed = true
		resizing = false
		resizeReady = false
		for _, r in ipairs(removes) do r() end
		removes = {}
		for i, fl in ipairs(win._floats) do if fl == api then table.remove(win._floats, i) break end end
		fgui:Destroy()
	end
	table.insert(win._floats, api)
	return api
end

function Container:_columns()
	if self._cols then return self._cols end
	if self._order > 0 then

		self:Divider()
	end
	local win = self.Window
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = self:_nextOrder(), Parent = self.List })
	local sep = new("Frame", {
		AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, 0), Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = row,
	})
	local cols = { Row = row, Slots = {}, Window = win }
	local swapping = false
	local update

	local function makeCol(frameName, label)
		local f = new("Frame", { Name = frameName, Size = UDim2.new(.5, -9, 1, 0), BackgroundTransparency = 1, Parent = row })
		local layout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = f })
		local fscale = new("UIScale", { Parent = f })
		local col = { Name = label, Frame = f, Layout = layout, Scale = fscale, Count = 0, Next = 0, Sections = {}, Popped = false, Labels = {} }

		local head = new("Frame", { Name = "ColHead", Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, LayoutOrder = 0, Visible = false, Parent = f })
		corner(head, UDim.new(0, 8))
		stroke(head)
		head:SetAttribute("NoDrag", true)
		local headLabel = mkText {
			Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -90, 1, 0), Text = string.upper(label), TextSize = 11, TextColor3 = Theme.Muted, Parent = head,
		}
		local swapBtn = glyph(head, "arrow-left-right", "⇄", UDim2.new(1, -50, .5, 0), 20)
		local popBtn = glyph(head, "picture-in-picture-2", "⧉", UDim2.new(1, -26, .5, 0), 20)
		local pickBtn = glyph(head, "columns-2", "▥", UDim2.new(1, -74, .5, 0), 20)
		swapBtn.MouseButton1Click:Connect(function() cols.Swap() end)
		popBtn.MouseButton1Click:Connect(function() cols.Pop(col) end)
		pickBtn.MouseButton1Click:Connect(function() cols.Picker(col) end)
		col.Head = head
		col.Labels[1] = headLabel

		local ghost = new("TextButton", {
			Name = frameName .. "Ghost", Size = UDim2.new(.5, -9, 0, 44), BackgroundColor3 = Theme.Surface, BackgroundTransparency = .35,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = false, Parent = row,
		})
		corner(ghost, UDim.new(0, 10))
		local gs = stroke(ghost, Theme.Accent, .55)
		col.Labels[2] = mkText {
			Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -90, 1, 0), Text = label .. "  ·  floating", TextSize = 13, TextColor3 = Theme.Muted, Parent = ghost,
		}
		local gb = mkText {
			AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(60, 18), Text = "Dock", TextSize = 12,
			TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = ghost,
		}
		ghost.MouseEnter:Connect(function() tween(gs, { Transparency = 0 }, .15) end)
		ghost.MouseLeave:Connect(function() tween(gs, { Transparency = .55 }, .25) end)
		ghost.MouseButton1Click:Connect(function() cols.Dock(col) end)
		col.Ghost = ghost
		col.GhostButton = gb

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() update() end)
		return col
	end

	update = function()
		local a, b = cols.Slots[1], cols.Slots[2]
		if not a or not b then return end
		local aOn, bOn = a.Count > 0, b.Count > 0
		local function h(c) return c.Popped and 44 or c.Layout.AbsoluteContentSize.Y end
		row.Size = UDim2.new(1, 0, 0, math.max(aOn and h(a) or 0, bOn and h(b) or 0))
		if swapping then return end
		local both = aOn and bOn
		sep.Visible = both
		local function place(c, on, pos, size)
			if c.Popped then
				c.Ghost.Visible = on
				c.Ghost.Position = pos
				c.Ghost.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 44)
			else
				c.Ghost.Visible = false
				c.Frame.Visible = on
				c.Frame.Position = pos
				c.Frame.Size = size
			end
		end
		local zero, full = UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, 0)
		local halfSize = UDim2.new(.5, -9, 1, 0)
		if both then
			place(a, true, zero, halfSize)
			place(b, true, UDim2.new(.5, 9, 0, 0), halfSize)
		elseif aOn then
			place(a, true, zero, full)
			place(b, false, zero, full)
		else
			place(b, true, zero, full)
			place(a, false, zero, full)
		end
	end
	cols.Update = update

	function cols.Swap()
		if swapping then return end
		win:_closePopups()
		local a, b = cols.Slots[1], cols.Slots[2]
		local animated = a.Count > 0 and b.Count > 0 and not a.Popped and not b.Popped
		if not animated then
			cols.Slots[1], cols.Slots[2] = b, a
			update()
			return
		end
		swapping = true
		a.Frame.ZIndex, b.Frame.ZIndex = 3, 2
		tween(a.Frame, { Position = UDim2.new(.5, 9, 0, 0) }, .62, LIQUID)
		tween(b.Frame, { Position = UDim2.fromOffset(0, 0) }, .62, LIQUID)
		for _, c in ipairs({ a, b }) do
			tween(c.Scale, { Scale = .95 }, .2)
			task.delay(.22, function() tween(c.Scale, { Scale = 1 }, .6, SPRING) end)
		end
		tween(sep, { BackgroundTransparency = 1 }, .15)
		task.delay(.66, function()
			cols.Slots[1], cols.Slots[2] = b, a
			swapping = false
			a.Frame.ZIndex, b.Frame.ZIndex = 1, 1
			update()
			tween(sep, { BackgroundTransparency = 0 }, .3)
		end)
	end

	function cols.SwapSlots(a, b)
		if swapping or not a or not b or a == b then return end
		local ia, ib
		for i, c in ipairs(cols.Slots) do
			if c == a then ia = i elseif c == b then ib = i end
		end
		if not ia or not ib then return end
		if #cols.Slots == 2 then cols.Swap() return end
		cols.Slots[ia], cols.Slots[ib] = b, a
		update()
	end

	function cols.Picker(from)
		if swapping or win._destroyed or not win.Body then return end
		local targets, fromSlot = {}, 1
		for i, c in ipairs(cols.Slots) do
			if c == from then fromSlot = i else table.insert(targets, { col = c, slot = i }) end
		end
		if #targets == 0 then return end
		win:_closePopups()
		if win._dialog then win._dialog.Close() end

		local winScale = math.max(win.Scale.Scale, .01)
		local bodyW = win.Body.AbsoluteSize.X / winScale
		local bodyH = win.Body.AbsoluteSize.Y / winScale
		if bodyW <= 0 then bodyW = 760 end
		if bodyH <= 0 then bodyH = 520 end
		local N = #cols.Slots
		local W = math.clamp(math.min(460, bodyW - 32), 300, 460)
		local P, HEADER, STAGE_H, CARD, GAP, TGAP = 22, 46, 116, 76, 8, 8
		local labelY = P + HEADER + 16 + STAGE_H + 18
		local listY = labelY + 22
		local FOOT = 14 + 38 + P - 4
		local shown = math.min(#targets, 4)
		while shown > 1 and listY + (shown * (CARD + GAP) - GAP + 8) + FOOT > bodyH - 24 do shown -= 1 end
		local listH = shown * (CARD + GAP) - GAP + 8
		local cancelY = listY + listH + 14
		local H = cancelY + 38 + P - 4

		local closed, picked = false, false
		local api = {}
		local fades, slides, pops = {}, {}, {}
		local function fade(inst, prop, target, delay)
			inst[prop] = 1
			table.insert(fades, { inst, prop, target, delay or 0 })
		end
		local function mkIcon(parent, name, fallback, size, color, z)
			local img = new("ImageLabel", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, ZIndex = z, Parent = parent,
			})
			setIcon(img, name)
			if img.Image ~= "" then return img, "ImageTransparency", "ImageColor3" end
			img:Destroy()
			local t = mkText {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(size + 6, size + 6),
				Text = fallback, TextSize = size, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.None, ZIndex = z, Parent = parent,
			}
			return t, "TextTransparency", "TextColor3"
		end

		local backdrop = new("TextButton", {
			Name = "ColumnPickerBackdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, ZIndex = 70, Parent = win.Body,
		})
		local bloom = new("ImageLabel", {
			Name = "LiquidBloom", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(W + 160, H + 120),
			BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = 1, ZIndex = 70, Parent = backdrop,
		})
		local bloomScale = new("UIScale", { Scale = .55, Parent = bloom })
		local box = new("Frame", {
			Name = "ColumnPicker", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 46), Size = UDim2.fromOffset(W, H),
			BackgroundColor3 = Theme.Background, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 71, Parent = backdrop,
		})
		corner(box, UDim.new(0, 20))
		local boxStroke = stroke(box, Theme.Stroke, 1)
		local boxScale = new("UIScale", { Scale = .7, Parent = box })

		-- header
		local chip = new("Frame", {
			Position = UDim2.fromOffset(P, P), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 72, Parent = box,
		})
		corner(chip, UDim.new(0, 14))
		local chipStroke = stroke(chip, Theme.Accent, .6)
		local chipScale = new("UIScale", { Scale = .4, Parent = chip })
		fade(chip, "BackgroundTransparency", .82, .04)
		fade(chipStroke, "Transparency", .6, .04)
		table.insert(pops, { chipScale, .04 })
		local chipIcon, chipProp = mkIcon(chip, "arrow-left-right", "⇄", 22, Theme.Accent, 73)
		fade(chipIcon, chipProp, 0, .06)
		local title = mkText {
			Position = UDim2.fromOffset(P + 56, P + 2), Size = UDim2.new(1, -(P * 2 + 56 + 36), 0, 22), Text = "Switch Column", TextSize = 18, ZIndex = 72, Parent = box,
		}
		fade(title, "TextTransparency", 0, .06)
		local sub = mkText {
			Position = UDim2.fromOffset(P + 56, P + 25), Size = UDim2.new(1, -(P * 2 + 56 + 36), 0, 16), Text = "Choose a column to trade places with " .. tostring(from.Name),
			TextSize = 12, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, ZIndex = 72, Parent = box,
		}
		fade(sub, "TextTransparency", 0, .09)
		local xBtn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W - P, P + 7), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 73, Parent = box,
		})
		corner(xBtn, UDim.new(0, 10))
		local xScale = new("UIScale", { Parent = xBtn })
		local xIcon, xProp, xColor = mkIcon(xBtn, "x", "✕", 14, Theme.Muted, 74)
		fade(xBtn, "BackgroundTransparency", 1, .1)
		fade(xIcon, xProp, 0, .1)
		xBtn.MouseEnter:Connect(function()
			if closed then return end
			tween(xBtn, { BackgroundTransparency = 0 }, .15)
			tween(xIcon, { [xColor] = Theme.Accent }, .15)
			tween(xScale, { Scale = 1.1 }, .4, SPRING)
		end)
		xBtn.MouseLeave:Connect(function()
			if closed then return end
			tween(xBtn, { BackgroundTransparency = 1 }, .25)
			tween(xIcon, { [xColor] = Theme.Muted }, .25)
			tween(xScale, { Scale = 1 }, .4, SPRING)
		end)
		xBtn.MouseButton1Down:Connect(function() tween(xScale, { Scale = .88 }, .1) end)
		xBtn.MouseButton1Click:Connect(function() api.Close() end)

		-- live preview stage
		local stage = new("Frame", {
			Position = UDim2.fromOffset(P, P + HEADER + 16), Size = UDim2.new(1, -P * 2, 0, STAGE_H), BackgroundColor3 = Theme.Surface,
			BorderSizePixel = 0, ZIndex = 72, Parent = box,
		})
		corner(stage, UDim.new(0, 16))
		local stageStroke = stroke(stage, Theme.Stroke, 1)
		fade(stage, "BackgroundTransparency", 0, .08)
		fade(stageStroke, "Transparency", 0, .08)
		local inner = new("Frame", {
			Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, ZIndex = 73, Parent = stage,
		})
		local function tilePos(k) return UDim2.new((k - 1) / N, (k - 1) * TGAP / N, 0, 0) end
		local tiles = {}
		for k, c in ipairs(cols.Slots) do
			local isFrom = c == from
			local d = .12 + (k - 1) * .06
			local tf = new("Frame", {
				Position = tilePos(k), Size = UDim2.new(1 / N, -TGAP * (N - 1) / N, 1, 0), BackgroundColor3 = isFrom and Theme.Accent or Theme.Surface3,
				BorderSizePixel = 0, ZIndex = 74, Parent = inner,
			})
			corner(tf, UDim.new(0, 12))
			local ts = stroke(tf, isFrom and Theme.Accent or Theme.Stroke, 1)
			local tsc = new("UIScale", { Scale = .6, Parent = tf })
			fade(tf, "BackgroundTransparency", isFrom and .8 or 0, d)
			fade(ts, "Transparency", isFrom and .35 or 0, d)
			table.insert(pops, { tsc, d })
			local tag = mkText {
				Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 0, 12), Text = isFrom and "FROM" or "COLUMN", TextSize = 10,
				TextColor3 = isFrom and Theme.Accent or Theme.Muted, ZIndex = 75, Parent = tf,
			}
			fade(tag, "TextTransparency", 0, d)
			local num = mkText {
				Position = UDim2.fromOffset(12, 21), Size = UDim2.new(1, -24, 0, 32), Text = tostring(k), TextSize = 26,
				TextColor3 = isFrom and Theme.Accent or Theme.Text, ZIndex = 75, Parent = tf,
			}
			fade(num, "TextTransparency", 0, d)
			local nm = mkText {
				Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 0, 14), Text = tostring(c.Name), TextSize = 11, FontFace = Fonts.Regular,
				TextColor3 = Theme.Muted, ZIndex = 75, Parent = tf,
			}
			fade(nm, "TextTransparency", 0, d)
			for b = 1, math.min(c.Count, 4) do
				local bar = new("Frame", {
					Position = UDim2.new(0, 12 + (b - 1) * 16, 1, -14), Size = UDim2.fromOffset(12, 4), BackgroundColor3 = isFrom and Theme.Accent or Theme.Muted,
					BorderSizePixel = 0, ZIndex = 75, Parent = tf,
				})
				corner(bar, UDim.new(1, 0))
				fade(bar, "BackgroundTransparency", isFrom and .2 or .55, d + b * .03)
			end
			tiles[c] = { frame = tf, stroke = ts, scale = tsc, tag = tag, num = num, isFrom = isFrom }
		end

		local function preview(on, t)
			if closed then return end
			local ft, tt = tiles[from], tiles[t.col]
			if on then
				tween(ft.frame, { Position = tilePos(t.slot) }, .65, LIQUID)
				tween(tt.frame, { Position = tilePos(fromSlot) }, .65, LIQUID)
				ft.num.Text, tt.num.Text = tostring(t.slot), tostring(fromSlot)
				tt.tag.Text = "TO"
				tween(tt.stroke, { Color = Theme.Accent }, .2)
				tween(tt.tag, { TextColor3 = Theme.Accent }, .2)
				tween(tt.num, { TextColor3 = Theme.Accent }, .2)
				for _, x in ipairs({ ft, tt }) do
					x.scale.Scale = .94
					tween(x.scale, { Scale = 1 }, .6, SPRING)
				end
			else
				tween(ft.frame, { Position = tilePos(fromSlot) }, .55, LIQUID)
				tween(tt.frame, { Position = tilePos(t.slot) }, .55, LIQUID)
				ft.num.Text, tt.num.Text = tostring(fromSlot), tostring(t.slot)
				tt.tag.Text = "COLUMN"
				tween(tt.stroke, { Color = Theme.Stroke }, .25)
				tween(tt.tag, { TextColor3 = Theme.Muted }, .25)
				tween(tt.num, { TextColor3 = Theme.Text }, .25)
			end
		end

		-- list
		local label = mkText {
			Position = UDim2.fromOffset(P + 2, labelY), Size = UDim2.new(1, -P * 2, 0, 16), Text = "SWAP WITH", TextSize = 11,
			TextColor3 = Theme.Muted, ZIndex = 72, Parent = box,
		}
		fade(label, "TextTransparency", 0, .16)
		local list = new("ScrollingFrame", {
			Position = UDim2.fromOffset(P - 4, listY), Size = UDim2.new(1, -(P * 2 - 8), 0, listH), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
			ClipsDescendants = true, ZIndex = 72, Parent = box,
		})
		pad(list, 4, 4, 4, 4)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP), Parent = list })

		for i, t in ipairs(targets) do
			local c = t.col
			local d = .2 + (i - 1) * .06
			local names = {}
			for _, s in ipairs(c.Sections) do
				if #names < 3 then table.insert(names, tostring(s.Name)) end
			end
			local info = tostring(c.Count) .. (c.Count == 1 and " section" or " sections")
			if c.Popped then info = info .. "  ·  floating" end
			if #names > 0 then info = info .. "  ·  " .. table.concat(names, ", ") end

			local holder = new("Frame", { Size = UDim2.new(1, 0, 0, CARD), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 73, Parent = list })
			local card = new("TextButton", {
				Position = UDim2.fromOffset(0, 22), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
				Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 73, Parent = holder,
			})
			corner(card, UDim.new(0, 16))
			local cs = stroke(card, Theme.Stroke, 1)
			local cardScale = new("UIScale", { Parent = card })
			fade(card, "BackgroundTransparency", 0, d)
			fade(cs, "Transparency", 0, d)
			table.insert(slides, { card, d })

			local badge = new("Frame", {
				AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 14, .5, 0), Size = UDim2.fromOffset(46, 46),
				BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, ZIndex = 74, Parent = card,
			})
			corner(badge, UDim.new(0, 14))
			fade(badge, "BackgroundTransparency", 0, d)
			local num = mkText {
				Size = UDim2.fromScale(1, 1), Text = tostring(t.slot), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.None, ZIndex = 75, Parent = badge,
			}
			fade(num, "TextTransparency", 0, d)
			local name = mkText {
				Position = UDim2.fromOffset(74, 16), Size = UDim2.new(1, -74 - 104, 0, 20), Text = tostring(c.Name), TextSize = 15, ZIndex = 74, Parent = card,
			}
			fade(name, "TextTransparency", 0, d)
			local sublbl = mkText {
				Position = UDim2.fromOffset(74, 40), Size = UDim2.new(1, -74 - 104, 0, 16), Text = info, TextSize = 11, FontFace = Fonts.Regular,
				TextColor3 = Theme.Muted, ZIndex = 74, Parent = card,
			}
			fade(sublbl, "TextTransparency", 0, d)

			local pill = new("Frame", {
				AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(82, 32), BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0, ZIndex = 74, Parent = card,
			})
			corner(pill, UDim.new(1, 0))
			local pillStroke = stroke(pill, Theme.Accent, .55)
			fade(pill, "BackgroundTransparency", .86, d)
			fade(pillStroke, "Transparency", .55, d)
			local arrowHolder = new("Frame", {
				AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 10, .5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, ZIndex = 75, Parent = pill,
			})
			local arrow, arrowProp, arrowColor = mkIcon(arrowHolder, "arrow-left-right", "⇄", 14, Theme.Accent, 76)
			fade(arrow, arrowProp, 0, d)
			local pillTxt = mkText {
				Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -38, 1, 0), Text = "Swap", TextSize = 13, TextColor3 = Theme.Accent, ZIndex = 75, Parent = pill,
			}
			fade(pillTxt, "TextTransparency", 0, d)

			card.MouseEnter:Connect(function()
				if closed or picked then return end
				preview(true, t)
				tween(cs, { Color = Theme.Accent }, .2)
				tween(card, { BackgroundColor3 = Theme.Surface3 }, .2)
				tween(badge, { BackgroundColor3 = Theme.Accent }, .2)
				tween(num, { TextColor3 = Theme.AccentDark }, .2)
				tween(pill, { BackgroundTransparency = 0 }, .2)
				tween(pillStroke, { Transparency = 0 }, .2)
				tween(pillTxt, { TextColor3 = Theme.AccentDark }, .2)
				tween(arrow, { [arrowColor] = Theme.AccentDark }, .2)
				tween(arrowHolder, { Rotation = 180 }, .6, SPRING)
				tween(cardScale, { Scale = 1.02 }, .45, SPRING)
			end)
			card.MouseLeave:Connect(function()
				if closed or picked then return end
				preview(false, t)
				tween(cs, { Color = Theme.Stroke }, .25)
				tween(card, { BackgroundColor3 = Theme.Surface2 }, .25)
				tween(badge, { BackgroundColor3 = Theme.Surface3 }, .25)
				tween(num, { TextColor3 = Theme.Text }, .25)
				tween(pill, { BackgroundTransparency = .86 }, .25)
				tween(pillStroke, { Transparency = .55 }, .25)
				tween(pillTxt, { TextColor3 = Theme.Accent }, .25)
				tween(arrow, { [arrowColor] = Theme.Accent }, .25)
				tween(arrowHolder, { Rotation = 0 }, .6, SPRING)
				tween(cardScale, { Scale = 1 }, .45, SPRING)
			end)
			card.MouseButton1Down:Connect(function()
				if closed or picked then return end
				tween(cardScale, { Scale = .965 }, .1)
			end)
			card.MouseButton1Click:Connect(function()
				if closed or picked then return end
				picked = true
				ripple(card)
				preview(true, t)
				tween(card, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = .8 }, .25)
				tween(cs, { Color = Theme.Accent }, .2)
				tween(badge, { BackgroundColor3 = Theme.Accent }, .2)
				tween(num, { TextColor3 = Theme.AccentDark }, .2)
				tween(pill, { BackgroundTransparency = 0 }, .2)
				tween(arrowHolder, { Rotation = 360 }, .6, LIQUID)
				tween(cardScale, { Scale = 1.04 }, .3, SPRING)
				task.delay(.55, function()
					api.Close()
					task.delay(.16, function() cols.SwapSlots(from, c) end)
				end)
			end)
		end

		local cancel = new("TextButton", {
			Position = UDim2.fromOffset(P, cancelY), Size = UDim2.new(1, -P * 2, 0, 38), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, ZIndex = 72, Parent = box,
		})
		corner(cancel, UDim.new(0, 12))
		local cancelStroke = stroke(cancel, Theme.Stroke, 1)
		local cancelScale = new("UIScale", { Parent = cancel })
		local cancelTxt = mkText {
			Size = UDim2.fromScale(1, 1), Text = "Cancel", TextSize = 13, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 73, Parent = cancel,
		}
		local cd = .24 + #targets * .05
		fade(cancel, "BackgroundTransparency", 0, cd)
		fade(cancelStroke, "Transparency", 0, cd)
		fade(cancelTxt, "TextTransparency", 0, cd)
		cancel.MouseEnter:Connect(function()
			if closed then return end
			tween(cancelStroke, { Color = Theme.Accent }, .2)
			tween(cancelTxt, { TextColor3 = Theme.Accent }, .2)
		end)
		cancel.MouseLeave:Connect(function()
			if closed then return end
			tween(cancelStroke, { Color = Theme.Stroke }, .25)
			tween(cancelTxt, { TextColor3 = Theme.Muted }, .25)
			tween(cancelScale, { Scale = 1 }, .4, SPRING)
		end)
		cancel.MouseButton1Down:Connect(function() tween(cancelScale, { Scale = .97 }, .1) end)
		cancel.MouseButton1Click:Connect(function() api.Close() end)
		backdrop.MouseButton1Click:Connect(function() api.Close() end)

		function api.Close()
			if closed then return end
			closed = true
			if win._dialog == api then win._dialog = nil end
			tween(backdrop, { BackgroundTransparency = 1 }, .26)
			tween(box, { BackgroundTransparency = 1, Position = UDim2.new(.5, 0, .5, 18) }, .3, LIQUID)
			tween(boxScale, { Scale = .9 }, .3, LIQUID)
			tween(boxStroke, { Transparency = 1 }, .18)
			for _, f in ipairs(fades) do tween(f[1], { [f[2]] = 1 }, .18) end
			tween(bloom, { ImageTransparency = 1 }, .18)
			tween(bloomScale, { Scale = .7 }, .3, LIQUID)
			task.delay(.34, function()
				if backdrop.Parent then backdrop:Destroy() end
			end)
		end

		-- entrance
		win._dialog = api
		tween(backdrop, { BackgroundTransparency = .4 }, .35, LIQUID)
		tween(bloom, { ImageTransparency = .8 }, .25, LIQUID)
		tween(bloomScale, { Scale = 1.3 }, .8, LIQUID)
		task.delay(.25, function()
			if not closed and bloom.Parent then tween(bloom, { ImageTransparency = .92 }, .7, LIQUID) end
		end)
		tween(box, { BackgroundTransparency = 0, Position = UDim2.fromScale(.5, .5) }, .7, LIQUID)
		tween(boxStroke, { Transparency = 0 }, .3)
		tween(boxScale, { Scale = 1.04 }, .45, LIQUID)
		task.delay(.34, function()
			if not closed and boxScale.Parent then tween(boxScale, { Scale = 1 }, .5, SPRING) end
		end)
		for _, f in ipairs(fades) do
			task.delay(f[4], function()
				if closed or not f[1].Parent then return end
				if picked and f[1]:IsA("TextButton") then return end
				tween(f[1], { [f[2]] = f[3] }, .4)
			end)
		end
		for _, s in ipairs(slides) do
			task.delay(s[2], function()
				if closed or not s[1].Parent then return end
				tween(s[1], { Position = UDim2.fromOffset(0, 0) }, .75, LIQUID)
			end)
		end
		for _, p in ipairs(pops) do
			task.delay(p[2], function()
				if closed or not p[1].Parent then return end
				tween(p[1], { Scale = 1 }, .7, SPRING)
			end)
		end
	end

	function cols.Pop(col)
		if col.Popped or col.Docking or swapping or col.Count == 0 then return end
		win:_closePopups()
		col.Popped = true
		col.Head.Visible = false

		col.Head:SetAttribute("AF_PopToken", (col.Head:GetAttribute("AF_PopToken") or 0) + 1)
		local f = col.Frame
		col.Float = makeFloat(win, col, f.AbsolutePosition, f.AbsoluteSize, function() cols.Dock(col) end)
		update()
	end

	function cols.Dock(col)
		if col.Locked and col.Popped and col.Float and col.Float.Shake then col.Float.Shake() return end
		if not col.Popped or col.Docking or not col.Float or col.Locked then return end
		win:_closePopups()
		col.Docking = true
		local to
		if col.Ghost.Visible then to = col.Ghost.AbsolutePosition + col.Ghost.AbsoluteSize / 2 end
		col.Float.Close(to, function()
			col.Float = nil
			col.Popped = false
			col.Docking = false
			col.Frame.AutomaticSize = Enum.AutomaticSize.None
			col.Frame.Parent = row
			col.Head.Visible = col.Count > 0
			col.Locked = false
			col.RefreshFloatStatus = nil
			update()
			for i, sec in ipairs(col.Sections) do
				if sec._frame then popIn(sec._frame, .03 * i, true) end
			end
		end)
	end

	cols.Slots[1] = makeCol("Left", "Column 1")
	cols.Slots[2] = makeCol("Right", "Column 2")
	self._cols = cols
	return cols
end

function Container:Section(cfg)
	if self._kind == "Section" then return self:Header(cfg) end
	cfg = norm(cfg, { Title = "Name" })
	local win = self.Window
	local cols = self:_columns()
	local side = cfg.Side and string.lower(tostring(cfg.Side)) or nil
	local col
	if side == "left" then
		col = cols.Slots[1]
	elseif side == "right" then
		col = cols.Slots[2]
	else
		col = cols.Slots[1].Count <= cols.Slots[2].Count and cols.Slots[1] or cols.Slots[2]
	end
	col.Count += 1
	col.Next += 1
	col.Head.Visible = not col.Popped
	local parent = col.Frame
	local collapsible = cfg.Collapsible ~= false

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
		LayoutOrder = col.Next, Parent = parent,
	})
	corner(card, UDim.new(0, 10))
	stroke(card, Theme.Stroke)
	pad(card, 10, 10, 6, 10)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = card })
	local cardScale = new("UIScale", { Parent = card })

	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0, Parent = card,
	})
	local dot = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 2, .5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = head })
	corner(dot, UDim.new(1, 0))
	local label = mkText {
		Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -44, 1, 0), Text = string.upper(cfg.Name or "Section"), TextSize = 12,
		TextColor3 = Theme.Text, Parent = head,
	}
	local chevron = collapsible and makeChevron(head, 1, -2) or nil
	if chevron then chevron:Set(true) end

	local bodyClip = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.None, BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1, Parent = card,
	})
	local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = bodyClip })
	pad(body, 2, 2, 2, 2)
	local bodyLayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = body })

	local sec = setmetatable({
		Name = cfg.Name or "Section", Window = win, List = body, _order = 0, _kind = "Section", _compact = self._compact,
	}, Container)

	local collapsed, gen = false, 0
	local function contentHeight()
		local s = scaleFor(win, body)
		return math.ceil(math.max(body.AbsoluteSize.Y / s, bodyLayout.AbsoluteContentSize.Y / s + 4))
	end
	local function setCollapsed(c, instant)
		c = c == true
		if c == collapsed then return end
		if c then
			win:_closePopups()
		else
			body.Visible = true
		end
		collapsed = c
		gen += 1
		local g = gen
		local cur = bodyClip.AbsoluteSize.Y / scaleFor(win, bodyClip)
		local full = contentHeight()
		bodyClip.AutomaticSize = Enum.AutomaticSize.None
		bodyClip.Size = UDim2.new(1, 0, 0, cur)
		if chevron then chevron:Set(not c) end
		tween(dot, { BackgroundTransparency = c and .75 or 0 }, instant and 0 or .22)
		tween(label, { TextColor3 = c and Theme.Muted or Theme.Text }, instant and 0 or .22)
		if instant then
			bodyClip.Size = UDim2.new(1, 0, 0, c and 0 or full)
			body.Visible = not c
		elseif c then
			tween(bodyClip, { Size = UDim2.new(1, 0, 0, 0) }, .42, LIQUID)
			task.delay(.44, function()
				if g == gen and collapsed and bodyClip.Parent then body.Visible = false end
			end)
		else

			if full <= 0 then task.wait() full = contentHeight() end
			tween(bodyClip, { Size = UDim2.new(1, 0, 0, full) }, .48, SPRING)
			task.delay(.5, function()
				if g == gen and not collapsed and bodyClip.Parent then
					local target = contentHeight()
					bodyClip.Size = UDim2.new(1, 0, 0, target)
					if cols.Update then task.defer(cols.Update) end
				end
			end)
		end
		if cols.Update then task.defer(cols.Update) end
	end
	bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if collapsed or not bodyClip.Parent then return end
		local target = contentHeight()
		if math.abs(bodyClip.Size.Y.Offset - target) > 1 then
			if not win._introDone then
				bodyClip.Size = UDim2.new(1, 0, 0, target)
			else
				tween(bodyClip, { Size = UDim2.new(1, 0, 0, target) }, .22, LIQUID)
			end
		end
		if cols.Update then task.defer(cols.Update) end
	end)

	if collapsible then
		head.MouseEnter:Connect(function() tween(label, { TextColor3 = Theme.Accent }, .15) end)
		head.MouseLeave:Connect(function()
			tween(label, { TextColor3 = collapsed and Theme.Muted or Theme.Text }, .25)
			tween(cardScale, { Scale = 1 }, .5, SPRING)
		end)
		head.MouseButton1Down:Connect(function() tween(cardScale, { Scale = .985 }, .1) end)
		head.MouseButton1Up:Connect(function() tween(cardScale, { Scale = 1 }, .6, SPRING) end)
		head.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)
	else
		head.Active = false
	end

	function sec:Set(t) label.Text = string.upper(t) end
	function sec:SetCollapsed(c, instant) setCollapsed(c, instant) end
	function sec:ToggleCollapsed() setCollapsed(not collapsed) end
	function sec:IsCollapsed() return collapsed end

	table.insert(col.Sections, sec)
	local reg = register(self, cfg, sec, card, "Section")
	reg._listeners = { function()
		col.Count = math.max(col.Count - 1, 0)
		for i, s in ipairs(col.Sections) do if s == sec then table.remove(col.Sections, i) break end end
		if col.Count == 0 then
			col.Head.Visible = false
			if col.Popped then
				col.Locked = false
				if col.RefreshFloatStatus then col.RefreshFloatStatus() end
				cols.Dock(col)
			end
		end
		cols.Update()
	end }
	if cfg.Collapsed then setCollapsed(true, true) end
	task.defer(cols.Update)
	return reg
end

local function slotOf(cols, side)
	return cols.Slots[string.lower(tostring(side)) == "right" and 2 or 1]
end

function Container:SetColumnCollapsed(side, collapsed)
	local cols = self._cols
	if not cols then return end
	local col = slotOf(cols, side)
	side = col
	self._columnCollapseTokens = self._columnCollapseTokens or {}
	local token = (self._columnCollapseTokens[side] or 0) + 1
	self._columnCollapseTokens[side] = token
	local sections = table.clone(col.Sections)

	if collapsed then
		for i = #sections, 1, -1 do
			local sec = sections[i]
			task.delay((#sections - i) * 0.035, function()
				if self._columnCollapseTokens[side] == token and sec and sec.SetCollapsed then
					sec:SetCollapsed(collapsed)
				end
			end)
		end
	else
		for i, sec in ipairs(sections) do
			task.delay((i - 1) * 0.035, function()
				if self._columnCollapseTokens[side] == token and sec and sec.SetCollapsed then
					sec:SetCollapsed(collapsed)
				end
			end)
		end
	end
end
function Container:SetAllSectionsCollapsed(collapsed)
	self:SetColumnCollapsed("Left", collapsed)
	self:SetColumnCollapsed("Right", collapsed)
end

function Container:SwapColumns()
	if self._cols then self._cols.Swap() end
end
function Container:PopColumn(side)
	if self._cols then self._cols.Pop(slotOf(self._cols, side)) end
end
function Container:DockColumn(side)
	if self._cols then self._cols.Dock(slotOf(self._cols, side)) end
end
function Container:SetColumnName(side, name)
	if not self._cols then return end
	local col = slotOf(self._cols, side)
	col.Name = tostring(name)
	if col.Labels[1] then col.Labels[1].Text = string.upper(col.Name) end
	if col.Labels[2] then col.Labels[2].Text = col.Locked and (col.Name .. "  ·  floating locked") or (col.Name .. "  ·  floating") end
	if col.Labels[3] then col.Labels[3].Text = string.upper(col.Name) end
	if col.RefreshFloatStatus then col.RefreshFloatStatus() end
end

-- ===================================================================
-- Viewer: a live 3D view of a player, NPC, item or any model.
-- The target is cloned into a ViewportFrame and re-synced every frame,
-- so anything that moves in the world moves in the viewer too.
-- Owner options include Interactive=false (display-only), AutoRotate=true,
-- ShowZoomControls=false, ShowResetView=false, ShowTargetSwitch=false,
-- ShowTargetDropdown=false, ShowPresets=false, ShowHint=false, and ShowHeader=false.
-- The same options can be supplied inside Controls = { ZoomControls=false, ResetView=false, ... }.
-- Use viewer:AddPlayer("username") or viewer:AddPlayer(userId) for online/offline avatar previews.
-- ===================================================================
local VIEWER_STRIP = {
	Script = true, LocalScript = true, ModuleScript = true, Sound = true, SoundGroup = true,
	Animator = true, ForceField = true, BillboardGui = true, SurfaceGui = true, ParticleEmitter = true,
	Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true, ProximityPrompt = true,
	ClickDetector = true, PointLight = true, SpotLight = true, SurfaceLight = true,
}

local function viewerSource(t)
	if typeof(t) ~= "Instance" then return nil end
	if t:IsA("Player") then return t.Character end
	if t:IsA("Humanoid") then return t.Parent end
	return t
end

local function viewerKind(t)
	if typeof(t) ~= "Instance" then return "OBJECT" end
	if t:IsA("Player") then return "PLAYER" end
	if t:GetAttribute("AF_ViewerPlayerPreview") == true then return "PLAYER" end
	local src = viewerSource(t)
	if src and src:IsA("Model") and src:FindFirstChildOfClass("Humanoid") then
		return Players:GetPlayerFromCharacter(src) and "PLAYER" or "NPC"
	end
	if t:IsA("Tool") or t:IsA("Accessory") then return "ITEM" end
	return "OBJECT"
end

local function viewerName(entry)
	if entry.Label then return tostring(entry.Label) end
	local t = entry.Target
	if typeof(t) ~= "Instance" then return tostring(t) end
	if t:IsA("Player") then return t.DisplayName ~= "" and t.DisplayName or t.Name end
	if t:IsA("Humanoid") and t.Parent then return t.Parent.Name end
	return t.Name
end

local function viewerClone(src)
	local changed = {}
	local function mark(i)
		if i.Archivable then return end
		if pcall(function() i.Archivable = true end) then table.insert(changed, i) end
	end
	mark(src)
	for _, d in ipairs(src:GetDescendants()) do mark(d) end
	local ok, c = pcall(function() return src:Clone() end)
	for _, i in ipairs(changed) do pcall(function() i.Archivable = false end) end
	if ok then return c end
	return nil
end

-- Match cloned children by class and name instead of array position. Character
-- descendants can be inserted in a different order; positional matching can leave
-- body parts untracked and make clothing/skin previews look incomplete.
local AF_ROBUST_VIEWPORT_PAIRING = true
local function viewerPair(a, b, list)
    if not a or not b then return end
    if b:IsA("BasePart") then
        pcall(function() b.Anchored = true end)
        if a:IsA("BasePart") then list[#list + 1] = { a, b } end
    end
    local sourceChildren, cloneChildren = a:GetChildren(), b:GetChildren()
    local used = {}
    for _, sourceChild in ipairs(sourceChildren) do
        local matchIndex
        for index, cloneChild in ipairs(cloneChildren) do
            if not used[index] and cloneChild.Parent
                and cloneChild.Name == sourceChild.Name
                and cloneChild.ClassName == sourceChild.ClassName then
                matchIndex = index
                break
            end
        end
        if matchIndex then
            used[matchIndex] = true
            local cloneChild = cloneChildren[matchIndex]
            if VIEWER_STRIP[cloneChild.ClassName] then
                cloneChild:Destroy()
            else
                viewerPair(sourceChild, cloneChild, list)
            end
        end
    end
end
local function wrapAngle(a) return (a + math.pi) % (math.pi * 2) - math.pi end

function Container:Viewer(cfg)
	cfg = norm(cfg, { Title = "Name", Description = "Desc" })
	local win = self.Window
	local order = self:_nextOrder()
	local floatable = cfg.Float ~= false and self._kind ~= "Section"
	local baseH = math.clamp(tonumber(cfg.Height) or 240, 200, 520)
	local floatH = math.clamp(tonumber(cfg.FloatHeight) or (baseH + 80), 200, 640)
	local viewH = baseH
	local hasDesc = type(cfg.Desc) == "string" and cfg.Desc ~= ""
	local controlsCfg = type(cfg.Controls) == "table" and cfg.Controls or {}
	local interactionsEnabled = cfg.Interactive ~= false and cfg.ReadOnly ~= true and cfg.Passive ~= true and cfg.Controls ~= false
	local function controlOption(key, nestedKey, default)
		local value = cfg[key]
		if value == nil then value = controlsCfg[nestedKey or key] end
		if value == nil then return default end
		return value ~= false
	end
	local showHeader = controlOption("ShowHeader", "Header", true)
	local headH = showHeader and (hasDesc and 36 or 26) or 0
	local barH = 32
	local showTargetSelector = controlOption("ShowTargetSelector", "TargetSelector", true)
	local showTargetSwitch = interactionsEnabled and showTargetSelector and controlOption("ShowTargetSwitch", "TargetSwitch", true)
	local showPrevious = showTargetSwitch and controlOption("ShowPreviousButton", "PreviousButton", true)
	local showNext = showTargetSwitch and controlOption("ShowNextButton", "NextButton", true)
	local showTargetDropdown = interactionsEnabled and showTargetSelector and controlOption("ShowTargetDropdown", "TargetDropdown", true)
	local showTargetBar = showPrevious or showNext or showTargetDropdown
	local showHint = interactionsEnabled and controlOption("ShowHint", "Hint", true)
	local allowRotate = interactionsEnabled and controlOption("EnableRotate", "RotateInteraction", true)
	local allowZoom = interactionsEnabled and controlOption("EnableZoom", "ZoomInteraction", true)
	local allowPan = interactionsEnabled and controlOption("EnablePan", "PanInteraction", true)
	local showToolStrip = interactionsEnabled and controlOption("ShowToolStrip", "ToolStrip", true)
	local showZoomControls = showToolStrip and allowZoom and controlOption("ShowZoomControls", "ZoomControls", true)
	local showZoomIn = showZoomControls and controlOption("ShowZoomIn", "ZoomIn", true)
	local showZoomOut = showZoomControls and controlOption("ShowZoomOut", "ZoomOut", true)
	local showPanToggle = showToolStrip and allowPan and controlOption("ShowPanToggle", "PanToggle", true)
	local showRotateToggle = showToolStrip and controlOption("ShowRotateToggle", "RotateToggle", true)
	local showLockFacing = showToolStrip and controlOption("ShowLockFacing", "LockFacing", true)
	local showSpectate = showToolStrip and controlOption("ShowSpectate", "Spectate", true)
	local showResetView = showToolStrip and controlOption("ShowResetView", "ResetView", true)
	local showPresets = interactionsEnabled and controlOption("ShowPresets", "Presets", true)
	local showFloatButton = floatable and showHeader and interactionsEnabled and controlOption("ShowFloatButton", "FloatButton", true)
	local showGlow = controlOption("ShowGlow", "Glow", true)
	local function stageTop() return 10 + headH + (headH > 0 and 8 or 0) end
	local function barTop() return stageTop() + viewH + (showTargetBar and 8 or 0) end
	local function cardHeight() return stageTop() + viewH + (showTargetBar and (8 + barH) or 0) + 10 end

	local obj = { _listeners = {} }
	local destroyed = false
	local avatarFolder = new("Folder", { Name = "AirflowViewerAvatars_" .. tostring(order), Parent = win.Gui })
	local targets, index = {}, 0
	local live = { Pairs = {}, Conns = {}, Model = nil, Anchor = nil, Offset = Vector3.zero, Radius = 4, StaticPose = false }
	local dirtyAt, viewReady, initializing = nil, false, true
	local minDist, maxDist, fitDist = .5, 100, 8
	local yawT, yawD, pitchT, pitchD, distT, distD = math.pi, math.pi, -.14, -.14, 8, 8
	local panXT, panXD, panYT, panYD = 0, 0, 0, 0
	local facingT, facingD = 0, 0
	local initialSpin = cfg.AutoRotate
	if initialSpin == nil then initialSpin = cfg.Spin end
	local spinOn, spinSpeed = initialSpin == true, tonumber(cfg.SpinSpeed) or .7
	local panMode, lockOn, spectating = false, cfg.LockFacing == true, false
	local drag, lastTap, interacted, hintTipOn = nil, 0, false, false
	local pickerOpen, floating, docking = false, false, false
	local lockedScroll, lockedPrev
	local toolPan, toolSpin, toolLock, toolEye
	local refreshUI, selectIndex, removeTarget, closePicker, dock, pop

	-- shell ---------------------------------------------------------
	local host = new("Frame", {
		Name = "Viewer", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = order, Parent = self.List,
	})
	local layout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = host })
	local card = new("Frame", {
		Name = "ViewerCard", Size = UDim2.new(1, 0, 0, cardHeight()), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
		LayoutOrder = 1, Parent = host,
	})
	card:SetAttribute("NoDrag", true)
	corner(card)
	local cardStroke = stroke(card, Theme.Stroke)
	hover(card, cardStroke)

	-- header --------------------------------------------------------
	local header = new("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, headH), BackgroundTransparency = 1, Visible = showHeader, Parent = card })
	local dot = new("Frame", {
		Position = UDim2.fromOffset(0, hasDesc and 6 or 10), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0, Parent = header,
	})
	corner(dot, UDim.new(1, 0))
	local titleW = 14 + 92 + (showFloatButton and 30 or 0)
	local titleLbl = mkText {
		Position = UDim2.fromOffset(14, hasDesc and 0 or 4), Size = UDim2.new(1, -titleW, 0, 18), Text = cfg.Name or "Viewer",
		TextSize = 14, Parent = header,
	}
	if hasDesc then
		mkText {
			Position = UDim2.fromOffset(14, 19), Size = UDim2.new(1, -titleW, 0, 15), Text = cfg.Desc, TextSize = 12,
			FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = header,
		}
	end
	local chip = new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, floatable and -30 or 0, 0, (headH - 20) / 2),
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = header,
	})
	corner(chip, UDim.new(1, 0))
	stroke(chip, Theme.Stroke, .4)
	pad(chip, 9, 9)
	local kindLbl = mkText {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "EMPTY", TextSize = 10, FontFace = Fonts.Bold,
		TextColor3 = Theme.Accent, TextTruncate = Enum.TextTruncate.None, Parent = chip,
	}
	local popBtn = showFloatButton and glyph(header, "picture-in-picture-2", "⧉", UDim2.new(1, -24, .5, 0), 24) or nil

	-- stage (the live view) -----------------------------------------
	local stage = new("Frame", {
		Name = "Stage", Position = UDim2.fromOffset(12, stageTop()), Size = UDim2.new(1, -24, 0, viewH),
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = card,
	})
	stage:SetAttribute("NoDrag", true)
	corner(stage, UDim.new(0, 12))
	local stageStroke = stroke(stage, Theme.Stroke)
	local bgGlow = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .62), Size = UDim2.fromScale(1.15, 1.05), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .86, ZIndex = 1, Visible = showGlow, Parent = stage,
	})
	local vp = new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(160, 150, 168),
		LightColor = Color3.fromRGB(255, 244, 255), LightDirection = Vector3.new(-.6, -1, -.5), ZIndex = 2, Parent = stage,
	})
	corner(vp, UDim.new(0, 12))
	local previewWorld = new("WorldModel", { Name = "PreviewWorld", Parent = vp })
	local cam = new("Camera", { FieldOfView = 42, Parent = vp })
	vp.CurrentCamera = cam
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = interactionsEnabled, Visible = interactionsEnabled, ZIndex = 4, Parent = stage })

	local empty = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(190, 64), BackgroundTransparency = 1,
		ZIndex = 3, Parent = stage,
	})
	local emptyIconHolder = new("Frame", {
		AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 3, Parent = empty,
	})
	quickIcon(emptyIconHolder, "box", "◇", 24, Theme.Muted, 3)
	local emptyText = mkText {
		Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 16), Text = cfg.EmptyText or "Nothing to view", TextSize = 13,
		FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = empty,
	}

	-- hint pill
	local defaultHint = Touch and "Drag to rotate · Pinch to zoom" or "Drag to rotate · Scroll to zoom"
	local hint = new("CanvasGroup", {
		AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -8), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = .2, BorderSizePixel = 0, GroupTransparency = 1, Visible = showHint, ZIndex = 6, Parent = stage,
	})
	corner(hint, UDim.new(1, 0))
	pad(hint, 10, 10)
	local hintLimit = new("UISizeConstraint", { MaxSize = Vector2.new(9999, 22), Parent = hint })
	local hintLbl = mkText {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = defaultHint, TextSize = 11, FontFace = Fonts.Regular,
		TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Center, Parent = hint,
	}
	local function fitHint()
		local s = scaleFor(win, stage)
		hintLimit.MaxSize = Vector2.new(math.max(stage.AbsoluteSize.X / s - 96, 60), 22)
	end
	stage:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitHint)
	task.defer(fitHint)

	-- view presets (top left)
	local presetBar = new("Frame", {
		Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = .25, BorderSizePixel = 0, Visible = showPresets, ZIndex = 6, Parent = stage,
	})
	corner(presetBar, UDim.new(1, 0))
	stroke(presetBar, Theme.Stroke, .3)
	pad(presetBar, 3, 3, 3, 3)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2), Parent = presetBar,
	})

	-- tool strip (right)
	local strip = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 14), Size = UDim2.fromOffset(28, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = .25, BorderSizePixel = 0, ZIndex = 6, Parent = stage,
	})
	corner(strip, UDim.new(0, 14))
	stroke(strip, Theme.Stroke, .3)
	pad(strip, 2, 2, 3, 3)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), Parent = strip,
	})

	-- target picker overlay
	local pickBack = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 20, Parent = stage,
	})
	local pickPanel = new("CanvasGroup", {
		AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, 10), Size = UDim2.new(1, -16, 0, 100), BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 21, Parent = stage,
	})
	corner(pickPanel, UDim.new(0, 12))
	stroke(pickPanel, Theme.StrokeHover)
	local pickScroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = .5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 22, Parent = pickPanel,
	})
	pad(pickScroll, 4, 4, 4, 4)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = pickScroll })

	-- bottom bar: prev / name pill / next ---------------------------
	local bar = new("Frame", {
		Position = UDim2.fromOffset(12, barTop()), Size = UDim2.new(1, -24, 0, barH), BackgroundTransparency = 1, Visible = showTargetBar, Parent = card,
	})
	local function navBtn(left, iconName, fallback)
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(left and 0 or 1, 0), Position = UDim2.new(left and 0 or 1, 0, 0, 0), Size = UDim2.fromOffset(barH, barH),
			BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = bar,
		})
		corner(b, UDim.new(0, 10))
		local bs = stroke(b, Theme.Stroke)
		local sc = new("UIScale", { Parent = b })
		local ic = quickIcon(b, iconName, fallback, 16, Theme.Muted, 3)
		quickPress(b, sc)
		b.MouseEnter:Connect(function() tween(bs, { Color = Theme.StrokeHover }, .12) end)
		b.MouseLeave:Connect(function() tween(bs, { Color = Theme.Stroke }, .25) end)
		return b, ic
	end
	local prevBtn, prevIcon = navBtn(true, "chevron-left", "‹")
	local nextBtn, nextIcon = navBtn(false, "chevron-right", "›")
	prevBtn.Visible = showPrevious
	nextBtn.Visible = showNext
	local leftReserve = showPrevious and (barH + 6) or 0
	local rightReserve = showNext and (barH + 6) or 0
	local pill = new("TextButton", {
		Position = UDim2.fromOffset(leftReserve, 0), Size = UDim2.new(1, -(leftReserve + rightReserve), 1, 0), BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = showTargetDropdown, Parent = bar,
	})
	corner(pill, UDim.new(0, 10))
	local pillStroke = stroke(pill, Theme.Stroke)
	local nameLbl = mkText { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -78, 1, 0), Text = "No target", TextSize = 13, Parent = pill }
	local countLbl = mkText {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -32, .5, 0), Size = UDim2.fromOffset(40, 16), Text = "0", TextSize = 11,
		TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = pill,
	}
	local chevron = makeChevron(pill, 1, -8)
	pill.MouseEnter:Connect(function() tween(pillStroke, { Color = Theme.StrokeHover }, .12) end)
	pill.MouseLeave:Connect(function() tween(pillStroke, { Color = Theme.Stroke }, .25) end)

	-- small helpers -------------------------------------------------
	local function layoutCard(instant)
		local d = instant and 0 or .45
		local off = math.max(0, math.min(14, (viewH - 186) / 2 - 2))
		tween(card, { Size = UDim2.new(1, 0, 0, cardHeight()) }, d, LIQUID)
		tween(stage, { Position = UDim2.fromOffset(12, stageTop()), Size = UDim2.new(1, -24, 0, viewH) }, d, LIQUID)
		tween(bar, { Position = UDim2.fromOffset(12, barTop()) }, d, LIQUID)
		tween(strip, { Position = UDim2.new(1, -8, .5, off) }, d, LIQUID)
	end

	local function setScrollLock(on)
		if on then
			if lockedScroll then return end
			local sf = card:FindFirstAncestorOfClass("ScrollingFrame")
			if sf then
				lockedScroll, lockedPrev = sf, sf.ScrollingEnabled
				sf.ScrollingEnabled = false
			end
		elseif lockedScroll then
			lockedScroll.ScrollingEnabled = lockedPrev ~= false
			lockedScroll = nil
		end
	end

	local function shown()
		local cur = stage
		while cur and not cur:IsA("LayerCollector") do
			if cur:IsA("GuiObject") and not cur.Visible then return false end
			cur = cur.Parent
		end
		if not cur then return false end
		return not cur:IsA("ScreenGui") or cur.Enabled
	end

	local function setHint(text)
		if not showHint then return end
		if text then
			hintLbl.Text = text
			hintTipOn = true
			tween(hint, { GroupTransparency = 0 }, .15)
		else
			hintTipOn = false
			hintLbl.Text = defaultHint
			tween(hint, { GroupTransparency = interacted and 1 or .1 }, .3)
		end
	end
	local function touched()
		if interacted then return end
		interacted = true
		if not hintTipOn then tween(hint, { GroupTransparency = 1 }, .4) end
	end
	task.delay(.7, function()
		if showHint and not destroyed and not interacted then tween(hint, { GroupTransparency = .1 }, .5) end
	end)

	local function setEmpty(on, text)
		if text then emptyText.Text = text end
		empty.Visible = on
	end

	local function targetHumanoid()
		local e = targets[index]
		if not e then return nil end
		local src = viewerSource(e.Target)
		return src and src:FindFirstChildOfClass("Humanoid") or nil
	end

	-- live clone ----------------------------------------------------
	local function clearLive()
		for _, c in ipairs(live.Conns) do c:Disconnect() end
		live.Conns = {}
		if live.Model then live.Model:Destroy() end
		live.Model, live.Anchor, live.Pairs, live.StaticPose = nil, nil, {}, false
	end

	local function resetView(instant)
		local base = lockOn and 0 or facingT
		local goal = base + math.pi
		yawT = instant and goal or (yawD + wrapAngle(goal - yawD))
		pitchT, distT, panXT, panYT = -.14, fitDist, 0, 0
		if instant then yawD, pitchD, distD, panXD, panYD = yawT, pitchT, distT, 0, 0 end
	end

	local function rebuild(keepView)
		clearLive()
		local entry = targets[index]
		if not entry then
			setEmpty(true, cfg.EmptyText or "Nothing to view")
			return
		end
		local src = viewerSource(entry.Target)
		if not src or not src.Parent then
			setEmpty(true, "Waiting for character…")
			return
		end
		local clone = viewerClone(src)
		if not clone then
			setEmpty(true, "Can't preview this")
			return
		end
		local list = {}
		viewerPair(src, clone, list)
		if #list == 0 then
			clone:Destroy()
			setEmpty(true, "Nothing to show")
			return
		end
		local model = new("Model", { Name = "PreviewCharacter" })
		clone.Parent = model
		model.Parent = previewWorld

		local sourceAnchor
		if src:IsA("BasePart") then
			sourceAnchor = src
		elseif src:IsA("Model") then
			sourceAnchor = src.PrimaryPart or src:FindFirstChild("HumanoidRootPart")
		end
		if not (sourceAnchor and sourceAnchor:IsA("BasePart")) then sourceAnchor = list[1][1] end

		-- Character previews are snapshots by default: keep the pose captured at selection
		-- time and do not copy the live player's idle/walk/run animation every frame.
		-- Set LiveCharacterPreview=true only when a live pose is explicitly desired.
		local humanoidClone = clone:IsA("Model") and clone:FindFirstChildOfClass("Humanoid") or nil
		local staticPose = humanoidClone ~= nil and cfg.LiveCharacterPreview ~= true
		local anchor = sourceAnchor
		if staticPose then
			anchor = nil
			for _, pair in ipairs(list) do
				if pair[1] == sourceAnchor then anchor = pair[2] break end
			end
			if not (anchor and anchor:IsA("BasePart")) then anchor = list[1][2] end
			pcall(function()
				humanoidClone.AutoRotate = false
				humanoidClone.WalkSpeed = 0
				humanoidClone.JumpPower = 0
				humanoidClone.JumpHeight = 0
				humanoidClone.PlatformStand = true
				humanoidClone:ChangeState(Enum.HumanoidStateType.Physics)
			end)
		end
		if not (anchor and anchor:IsA("BasePart")) then anchor = list[1][2] end

		local AF_SAFE_VIEWPORT_BOUNDS = true
local cf, size
local boundsOk = pcall(function() cf, size = model:GetBoundingBox() end)
if (not boundsOk or not cf or not size) and src:IsA("Model") then
    pcall(function() cf, size = src:GetBoundingBox() end)
end
if not cf or not size then
    local fallbackPart = list[1] and list[1][2]
    if fallbackPart and fallbackPart.Parent then
        cf, size = fallbackPart.CFrame, fallbackPart.Size
    else
        clone:Destroy()
        setEmpty(true, "Nothing to show")
        return
    end
end

		live.Model, live.Anchor, live.Pairs, live.StaticPose = model, anchor, list, staticPose
		live.Offset = anchor.CFrame:PointToObjectSpace(cf.Position)
		live.Radius = math.clamp(size.Magnitude / 2, .5, 400)
		fitDist = math.max(live.Radius * 2.5, 2)
		minDist, maxDist = math.max(live.Radius * .55, .5), live.Radius * 12

		local look = anchor.CFrame.LookVector
		if look.X * look.X + look.Z * look.Z > .01 then facingT = math.atan2(-look.X, -look.Z) end
		if not viewReady then facingD = facingT end
		if not keepView or not viewReady then
			resetView(not viewReady)
		else
			distT = math.clamp(distT, minDist, maxDist)
		end
		viewReady = true

		local function mark(d)
			if d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("Clothing") or d:IsA("CharacterMesh") or d:IsA("SpecialMesh")
				or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d:IsA("BodyColors") or d:IsA("ShirtGraphic") then
				dirtyAt = os.clock() + .4
			end
		end
		table.insert(live.Conns, src.DescendantAdded:Connect(mark))
		table.insert(live.Conns, src.DescendantRemoving:Connect(mark))
		setEmpty(false)
	end

	-- camera controls -----------------------------------------------
	local function zoomBy(f)
		distT = math.clamp(distT * f, minDist, maxDist)
		touched()
	end
	local function preset(offset)
		local base = lockOn and 0 or facingT
		yawT = yawD + wrapAngle(base + offset - yawD)
		pitchT, panXT, panYT = -.14, 0, 0
		touched()
	end
	local function setSpin(v)
		spinOn = v == true
		if toolSpin then toolSpin.Set(spinOn) end
	end
	local function setPan(v)
		panMode = v == true
		if toolPan then toolPan.Set(panMode) end
	end
	local function setLock(v)
		v = v == true
		if v == lockOn then return end
		if v then
			yawT -= facingD
			yawD -= facingD
		else
			yawT += facingD
			yawD += facingD
		end
		lockOn = v
		if toolLock then toolLock.Set(v) end
	end
	local function restoreCamera()
		local camera = workspace.CurrentCamera
		local ch = LocalPlayer.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if camera and hum and camera.CameraSubject ~= hum then camera.CameraSubject = hum end
	end
	local function setSpectate(v, silent)
		v = v == true
		if v and not targetHumanoid() then
			win:Notify { Title = "Can't spectate", Content = "This target has no character to follow.", Type = "Warning", Duration = 3 }
			return
		end
		if v == spectating then return end
		spectating = v
		if toolEye then toolEye.Set(v) end
		if not v then restoreCamera() end
		if not silent then fire(cfg.OnSpectate, v, targets[index] and targets[index].Target) end
	end

	-- build the buttons ---------------------------------------------
	local toolOrder = 0
	local function makeTool(iconName, fallback, tip, onClick)
		toolOrder += 1
		local t = { On = false, Button = nil }
		local b = new("TextButton", {
			Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Surface3, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
			AutoButtonColor = false, LayoutOrder = toolOrder, ZIndex = 7, Parent = strip,
		})
		corner(b, UDim.new(1, 0))
		t.Button = b
		local sc = new("UIScale", { Parent = b })
		local ic = quickIcon(b, iconName, fallback, 14, Theme.Muted, 8)
		quickPress(b, sc)
		function t.Render(animate)
			local d = animate and .2 or 0
			tween(b, { BackgroundColor3 = t.On and Theme.Accent or Theme.Surface3, BackgroundTransparency = t.On and 0 or 1 }, d)
			ic.Color(t.On and Theme.AccentDark or Theme.Muted, d)
		end
		function t.Set(v)
			t.On = v == true
			t.Render(true)
		end
		b.MouseEnter:Connect(function()
			if not t.On then
				tween(b, { BackgroundTransparency = .3 }, .12)
				ic.Color(Theme.Text, .12)
			end
			setHint(tip)
		end)
		b.MouseLeave:Connect(function()
			t.Render(true)
			setHint(nil)
		end)
		b.MouseButton1Click:Connect(function() onClick(t) end)
		return t
	end
	local toolZoomIn = makeTool("zoom-in", "+", "Zoom in", function() if allowZoom then zoomBy(.8) end end)
	local toolZoomOut = makeTool("zoom-out", "−", "Zoom out", function() if allowZoom then zoomBy(1.25) end end)
	toolPan = makeTool("move", "✥", "Pan mode · drag to move the view", function(t) if allowPan then setPan(not t.On) end end)
	toolSpin = makeTool("rotate-3d", "⟳", "Auto rotate", function(t) setSpin(not t.On) end)
	toolLock = makeTool("lock", "◎", "Follow facing · view turns with the target", function(t) setLock(not t.On) end)
	toolEye = makeTool("eye", "◉", "Spectate · switch your game camera", function(t) setSpectate(not t.On) end)
	local toolReset = makeTool("rotate-ccw", "↺", "Reset view", function() resetView(false) touched() end)
	toolZoomIn.Button.Visible = showZoomIn
	toolZoomOut.Button.Visible = showZoomOut
	toolPan.Button.Visible = showPanToggle
	toolSpin.Button.Visible = showRotateToggle
	toolLock.Button.Visible = showLockFacing
	toolEye.Button.Visible = showSpectate
	toolReset.Button.Visible = showResetView
	strip.Visible = showToolStrip and (showZoomIn or showZoomOut or showPanToggle or showRotateToggle or showLockFacing or showSpectate or showResetView)
	toolSpin.Set(spinOn)
	toolLock.Set(lockOn)

	local function presetChip(text, offset)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 7, Parent = presetBar,
		})
		corner(b, UDim.new(1, 0))
		pad(b, 8, 8)
		local l = mkText {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = text, TextSize = 11, TextColor3 = Theme.Muted,
			TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8, Parent = b,
		}
		b.MouseEnter:Connect(function()
			tween(l, { TextColor3 = Theme.Text }, .12)
			tween(b, { BackgroundTransparency = .85 }, .12)
		end)
		b.MouseLeave:Connect(function()
			tween(l, { TextColor3 = Theme.Muted }, .2)
			tween(b, { BackgroundTransparency = 1 }, .2)
		end)
		b.MouseButton1Click:Connect(function()
			preset(offset)
			tween(b, { BackgroundTransparency = .6 }, .08)
			task.delay(.1, function() tween(b, { BackgroundTransparency = 1 }, .3) end)
		end)
	end
	presetChip("Front", math.pi)
	presetChip("Right", math.pi / 2)
	presetChip("Back", 0)
	presetChip("Left", -math.pi / 2)

	-- target picker -------------------------------------------------
	local function buildRows()
		for _, c in ipairs(pickScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, e in ipairs(targets) do
			local on = i == index
			local row = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Surface3, BackgroundTransparency = on and .5 or 1, BorderSizePixel = 0,
				Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 22, Parent = pickScroll,
			})
			corner(row, UDim.new(0, 8))
			local d = new("Frame", {
				AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 10, .5, 0), Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = on and Theme.Accent or Theme.Muted, BorderSizePixel = 0, ZIndex = 23, Parent = row,
			})
			corner(d, UDim.new(1, 0))
			local nm = mkText {
				Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -92, 1, 0), Text = viewerName(e), TextSize = 13,
				TextColor3 = on and Theme.Text or Theme.Muted, ZIndex = 23, Parent = row,
			}
			mkText {
				AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(56, 14), Text = viewerKind(e.Target),
				TextSize = 10, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 23, Parent = row,
			}
			row.MouseEnter:Connect(function()
				tween(row, { BackgroundTransparency = on and .3 or .7 }, .12)
				tween(nm, { TextColor3 = Theme.Text }, .12)
			end)
			row.MouseLeave:Connect(function()
				tween(row, { BackgroundTransparency = on and .5 or 1 }, .2)
				tween(nm, { TextColor3 = on and Theme.Text or Theme.Muted }, .2)
			end)
			row.MouseButton1Click:Connect(function()
				closePicker()
				selectIndex(i)
			end)
		end
		local h = math.max(math.min(#targets * 32 + 8, viewH - 56), 42)
		pickPanel.Size = UDim2.new(1, -16, 0, h)
	end
	local function openPicker()
		if pickerOpen or #targets == 0 or destroyed then return end
		pickerOpen = true
		buildRows()
		pickBack.Visible, pickPanel.Visible = true, true
		pickPanel.Position = UDim2.new(.5, 0, 1, 10)
		tween(pickBack, { BackgroundTransparency = .45 }, .25)
		tween(pickPanel, { Position = UDim2.new(.5, 0, 1, -8) }, .5, SPRING)
		tween(pickPanel, { GroupTransparency = 0 }, .2)
		chevron:Set(true)
	end
	closePicker = function(instant)
		if not pickerOpen then return end
		pickerOpen = false
		chevron:Set(false)
		local d = instant and 0 or .22
		tween(pickBack, { BackgroundTransparency = 1 }, d)
		tween(pickPanel, { Position = UDim2.new(.5, 0, 1, 10) }, d, QUINT)
		tween(pickPanel, { GroupTransparency = 1 }, d)
		task.delay(instant and 0 or .24, function()
			if not pickerOpen then
				pickBack.Visible, pickPanel.Visible = false, false
			end
		end)
	end
	pill.MouseButton1Click:Connect(function()
		if pickerOpen then closePicker() else openPicker() end
	end)
	pickBack.MouseButton1Click:Connect(function() closePicker() end)

	-- targets -------------------------------------------------------
	local function entryOf(t)
		for i, e in ipairs(targets) do
			if e.Target == t then return e, i end
		end
	end

	refreshUI = function()
		local e = targets[index]
		if e then
			nameLbl.Text = viewerName(e)
			kindLbl.Text = viewerKind(e.Target)
			countLbl.Text = index .. "/" .. #targets
		else
			nameLbl.Text = "No target"
			kindLbl.Text = "EMPTY"
			countLbl.Text = "0"
		end
		nameLbl.TextTransparency = 1
		tween(nameLbl, { TextTransparency = 0 }, .25)
		local multi = #targets > 1
		prevIcon.Color(multi and Theme.Text or Theme.Muted, .2)
		nextIcon.Color(multi and Theme.Text or Theme.Muted, .2)
		if pickerOpen then buildRows() end
	end

	selectIndex = function(i, silent)
		if #targets == 0 then
			index = 0
			clearLive()
			setEmpty(true, cfg.EmptyText or "Nothing to view")
			refreshUI()
			return
		end
		i = ((i - 1) % #targets) + 1
		local changed = i ~= index
		index = i
		rebuild(false)
		refreshUI()
		if changed and not silent then fire(cfg.Callback, targets[index].Target, index) end
	end

	removeTarget = function(t)
		local e, i = entryOf(t)
		if not e then return false end
		for _, c in ipairs(e.Conns) do c:Disconnect() end
		table.remove(targets, i)
		if e.OwnedModel then pcall(function() e.OwnedModel:Destroy() end) end
		if i < index then
			index -= 1
			refreshUI()
		elseif i == index then
			if #targets == 0 then
				selectIndex(1)
			else
				local ni = math.min(i, #targets)
				index = 0
				selectIndex(ni)
			end
		else
			refreshUI()
		end
		return true
	end

	local function addTarget(t, label, select_)
		if type(t) == "table" then
			label = t.Label or t.Name or label
			t = t.Target or t.Instance or t.Object
		end
		if typeof(t) ~= "Instance" then return nil end
		local existing = entryOf(t)
		if existing then return existing end
		local entry = { Target = t, Label = label, Conns = {}, UserId = nil, OwnedModel = nil }
		if t:IsA("Player") then
			entry.UserId = t.UserId
		else
			pcall(function()
				entry.UserId = tonumber(t:GetAttribute("AF_ViewerUserId"))
				if t:GetAttribute("AF_ViewerOwnedAvatar") == true then entry.OwnedModel = t end
			end)
		end
		table.insert(targets, entry)
		if cfg.AutoRemove ~= false then
			table.insert(entry.Conns, t.AncestryChanged:Connect(function(_, parent)
				if parent == nil then removeTarget(t) end
			end))
		end
		if t:IsA("Player") then
			table.insert(entry.Conns, t.CharacterAdded:Connect(function()
				if targets[index] == entry then dirtyAt = os.clock() + .25 end
			end))
		end
		if index == 0 then
			selectIndex(#targets, initializing)
		elseif select_ == true then
			selectIndex(#targets)
		else
			refreshUI()
		end
		return entry
	end

	prevBtn.MouseButton1Click:Connect(function() if #targets > 1 then selectIndex(index - 1) end end)
	nextBtn.MouseButton1Click:Connect(function() if #targets > 1 then selectIndex(index + 1) end end)

	-- input: hold the left mouse button and drag to orbit. Right-click is ignored.
	hit.InputBegan:Connect(function(input)
		if not interactionsEnabled or destroyed or drag or pickerOpen then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		local wantsPan = panMode or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
		local pan = wantsPan and allowPan
		if not pan and not allowRotate then return end
		local startPointer = t == Enum.UserInputType.Touch and Vector2.new(input.Position.X, input.Position.Y) or UIS:GetMouseLocation()
		drag = { Mode = pan and "pan" or "orbit", Touch = t == Enum.UserInputType.Touch, Button = t, Input = input, Moved = 0, LastPointer = startPointer }
		setScrollLock(true)
		touched()
		tween(stageStroke, { Color = Theme.Accent }, .15)
		if showGlow then tween(bgGlow, { ImageTransparency = .74 }, .3) end
	end)

	win:_listen("Changed", function(input)
		if destroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			if allowZoom and not pickerOpen and live.Anchor and inside(UIS:GetMouseLocation(), stage) and shown() then
				zoomBy(1 - input.Position.Z * .12)
			end
			return
		end
		if not drag then return end
		local valid
		if drag.Touch then valid = input == drag.Input and input.UserInputType == Enum.UserInputType.Touch
		else valid = input.UserInputType == Enum.UserInputType.MouseMovement end
		if not valid then return end
		local pointer = drag.Touch and Vector2.new(input.Position.X, input.Position.Y) or UIS:GetMouseLocation()
		local d = pointer - drag.LastPointer
		drag.LastPointer = pointer
		drag.Moved += math.abs(d.X) + math.abs(d.Y)
		if not live.Anchor then return end
		if drag.Mode == "pan" then
			local k = distD * .0022
			local lim = live.Radius * 1.2
			panXT = math.clamp(panXT - d.X * k, -lim, lim)
			panYT = math.clamp(panYT + d.Y * k, -lim, lim)
		else
			local k = drag.Touch and .013 or .011
			yawT -= d.X * k
			pitchT = math.clamp(pitchT - d.Y * k, -1.45, 1)
		end
	end, obj)

	win:_listen("Ended", function(input)
		if not drag then return end
		local ended
		if drag.Touch then ended = input == drag.Input else ended = input.UserInputType == drag.Button end
		if not ended then return end
		local tap = drag.Moved < 4 and drag.Mode == "orbit"
		drag = nil
		setScrollLock(false)
		tween(stageStroke, { Color = Theme.Stroke }, .3)
		if showGlow then tween(bgGlow, { ImageTransparency = .86 }, .4) end
		if tap and controlOption("EnableDoubleTapReset", "DoubleTapReset", true) then
			if os.clock() - lastTap < .32 then
				resetView(false)
				lastTap = 0
			else
				lastTap = os.clock()
			end
		end
	end, obj)

	local pinchBase
	local pinchConn = UIS.TouchPinch:Connect(function(_, scale, _, state)
		if not allowZoom or not drag or destroyed then return end
		if state == Enum.UserInputState.Begin then
			pinchBase = distT
		elseif state == Enum.UserInputState.Change and pinchBase then
			distT = math.clamp(pinchBase / math.max(scale, .05), minDist, maxDist)
		end
	end)
	table.insert(obj._listeners, function() pinchConn:Disconnect() end)

	-- per-frame update ----------------------------------------------
	win:_listen("Render", function(dt)
		if destroyed then return end
		if spectating then
			local hum, camera = targetHumanoid(), workspace.CurrentCamera
			if hum and camera then
				if camera.CameraSubject ~= hum then camera.CameraSubject = hum end
			else
				restoreCamera()
			end
		end
		if not shown() then
			setScrollLock(false)
			return
		end
		if dirtyAt and os.clock() >= dirtyAt then
			dirtyAt = nil
			rebuild(true)
		end
		local anchor = live.Anchor
		if anchor then
			if not anchor.Parent then
				dirtyAt = dirtyAt or (os.clock() + .2)
			else
				if not live.StaticPose then
					local list = live.Pairs
					for i = 1, #list do
						local p = list[i]
						local a, b = p[1], p[2]
						if a.Parent and b.Parent then
							local cf = a.CFrame
							if b.CFrame ~= cf then b.CFrame = cf end
							local tr = a.Transparency
							if b.Transparency ~= tr then b.Transparency = tr end
						end
					end
				end
				local acf = anchor.CFrame
				local look = acf.LookVector
				if look.X * look.X + look.Z * look.Z > .01 then facingT = math.atan2(-look.X, -look.Z) end
				facingD += wrapAngle(facingT - facingD) * (1 - math.exp(-dt * 10))
				if spinOn and not drag then yawT += dt * spinSpeed end
				local a = 1 - math.exp(-dt * (drag and 22 or 12))
				yawD += (yawT - yawD) * a
				pitchD += (pitchT - pitchD) * a
				distD += (distT - distD) * a
				panXD += (panXT - panXD) * a
				panYD += (panYT - panYD) * a
				local focus = acf:PointToWorldSpace(live.Offset)
				local fa = lockOn and facingD or 0
				cam.CFrame = CFrame.new(focus) * CFrame.Angles(0, yawD + fa, 0) * CFrame.Angles(pitchD, 0, 0) * CFrame.new(panXD, panYD, distD)
			end
		end
		local over = false
		if interactionsEnabled and not Touch and not pickerOpen then over = inside(UIS:GetMouseLocation(), stage) end
		setScrollLock(over or drag ~= nil)
	end, obj)

	-- floating (only when this isn't inside a column) ---------------
	local col = { Name = cfg.Name or "Viewer", Frame = host, Layout = layout, Labels = {}, Locked = false }
	local ghost
	if floatable then
		ghost = new("TextButton", {
			Name = "ViewerGhost", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Surface, BackgroundTransparency = .35,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, Visible = false, LayoutOrder = order, Parent = self.List,
		})
		corner(ghost, UDim.new(0, 10))
		local gs = stroke(ghost, Theme.Accent, .55)
		col.Labels[2] = mkText {
			Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -90, 1, 0), Text = col.Name .. "  ·  floating", TextSize = 13,
			TextColor3 = Theme.Muted, Parent = ghost,
		}
		col.GhostButton = mkText {
			AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(60, 18), Text = "Dock", TextSize = 12,
			TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = ghost,
		}
		ghost.MouseEnter:Connect(function() tween(gs, { Transparency = 0 }, .15) end)
		ghost.MouseLeave:Connect(function() tween(gs, { Transparency = .55 }, .25) end)
		ghost.MouseButton1Click:Connect(function() if dock then dock() end end)

		pop = function()
			if floating or docking or destroyed then return end
			win:_closePopups()
			closePicker(true)
			setScrollLock(false)
			floating = true
			if popBtn then popBtn.Visible = false end
			ghost.Visible = true
			viewH = floatH
			layoutCard(true)
			col.Float = makeFloat(win, col, host.AbsolutePosition, host.AbsoluteSize, function() dock() end)
		end
		dock = function()
			if not floating or docking or col.Locked or not col.Float then return end
			win:_closePopups()
			setScrollLock(false)
			docking = true
			local to
			if ghost.Visible then to = ghost.AbsolutePosition + ghost.AbsoluteSize / 2 end
			col.Float.Close(to, function()
				col.Float = nil
				floating, docking = false, false
				col.Locked = false
				col.RefreshFloatStatus = nil
				if destroyed then return end
				viewH = baseH
				host.Position = UDim2.fromOffset(0, 0)
				host.Size = UDim2.new(1, 0, 0, 0)
				host.Parent = self.List
				ghost.Visible = false
				if popBtn then popBtn.Visible = true end
				layoutCard(true)
				popIn(host, 0, true)
			end)
		end
		if popBtn then popBtn.MouseButton1Click:Connect(function() pop() end) end
	end

	-- public api ----------------------------------------------------
	local function onlinePlayerFor(query, userId)
		if userId then
			local ok, found = pcall(function() return Players:GetPlayerByUserId(userId) end)
			if ok and found then return found end
		end
		if type(query) ~= "string" then return nil end
		local needle = query:gsub("^@", ""):lower()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name:lower() == needle then return player end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player.DisplayName:lower() == needle then return player end
		end
		return nil
	end

	local function getAvatarDescription(userId)
		local methods = {
			function() return Players:GetHumanoidDescriptionFromUserIdAsync(userId) end,
			function() return Players:GetHumanoidDescriptionFromUserId(userId) end,
		}
		local lastError
		for _, call in ipairs(methods) do
			local ok, result = pcall(call)
			if ok and result then return result end
			lastError = result
		end
		return nil, lastError or "Roblox did not return an avatar description."
	end

	local function createAvatarModel(description)
		local rigTypes = { Enum.HumanoidRigType.R15, Enum.HumanoidRigType.R6 }
		local lastError
		for _, rigType in ipairs(rigTypes) do
			local ok, result = pcall(function()
				return Players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
			end)
			if ok and result then return result end
			lastError = result
			ok, result = pcall(function()
				return Players:CreateHumanoidModelFromDescription(description, rigType)
			end)
			if ok and result then return result end
			lastError = result
		end
		return nil, lastError or "Roblox could not build the avatar rig."
	end

	local function resolveUserId(query)
		if typeof(query) == "Instance" and query:IsA("Player") then
			return query.UserId, query.Name, query
		end
		local queryText = tostring(query or ""):gsub("^@", "")
		local numericId = tonumber(queryText)
		if numericId then
			local id = math.floor(numericId)
			if id <= 0 then return nil, queryText, nil, "User ID must be a positive number." end
			local player = onlinePlayerFor(queryText, id)
			local username = player and player.Name or nil
			if not username then
				pcall(function() username = Players:GetNameFromUserIdAsync(id) end)
			end
			return id, username or queryText, player
		end
		if queryText == "" then return nil, queryText, nil, "Enter a Roblox username or user ID." end
		local online = onlinePlayerFor(queryText)
		if online then return online.UserId, online.Name, online end
		local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(queryText) end)
		if not ok or not tonumber(id) or tonumber(id) <= 0 then
			return nil, queryText, nil, "Could not find a Roblox account for '" .. queryText .. "'. Use the account username or user ID."
		end
		local player = onlinePlayerFor(queryText, tonumber(id))
		return math.floor(tonumber(id)), (player and player.Name) or queryText, player
	end

	function obj:AddPlayer(query, label, select_)
		if destroyed then return nil end
		if type(query) == "table" then
			label = query.Label or query.DisplayName or query.Name or label
			query = query.UserId or query.Username or query.Target or query.Player or query.Name
		end
		return task.spawn(function()
			local userId, username, online, resolveError = resolveUserId(query)
			if not userId then
				fire(cfg.OnPlayerError, resolveError, query)
				if not destroyed then win:Notify { Title = "Player preview failed", Content = tostring(resolveError), Type = "Warning", Duration = 4 } end
				return
			end
			local defaultId
			if cfg.Default ~= nil then pcall(function() defaultId = tonumber(cfg.Default) end) end
			local defaultText = cfg.Default ~= nil and tostring(cfg.Default):lower() or ""
			local shouldSelect = select_ == true or (cfg.Default ~= nil and (cfg.Default == query or defaultId == userId or defaultText == tostring(username):lower()))
			if select_ == nil then shouldSelect = true end
			for i, existingEntry in ipairs(targets) do
				if existingEntry.UserId == userId then
					if shouldSelect then selectIndex(i) end
					fire(cfg.OnPlayerLoaded, existingEntry.Target, userId, username)
					return
				end
			end
			if online and online.Parent == Players then
				local entry = addTarget(online, label, shouldSelect)
				if entry then entry.UserId = userId end
				fire(cfg.OnPlayerLoaded, online, userId, username)
				return
			end
			local description, descriptionError = getAvatarDescription(userId)
			if not description then
				fire(cfg.OnPlayerError, descriptionError, query)
				if not destroyed then win:Notify { Title = "Player preview failed", Content = tostring(descriptionError), Type = "Warning", Duration = 4 } end
				return
			end
			local model, modelError = createAvatarModel(description)
			pcall(function() description:Destroy() end)
			if not model then
				fire(cfg.OnPlayerError, modelError, query)
				if not destroyed then win:Notify { Title = "Player preview failed", Content = tostring(modelError), Type = "Warning", Duration = 4 } end
				return
			end
			if destroyed or not avatarFolder.Parent then model:Destroy(); return end
			model.Name = username or ("Player_" .. tostring(userId))
			model:SetAttribute("AF_ViewerPlayerPreview", true)
			model:SetAttribute("AF_ViewerOwnedAvatar", true)
			model:SetAttribute("AF_ViewerUserId", userId)
			model.Parent = avatarFolder
			local entry = addTarget(model, label or username, shouldSelect)
			if entry then
				entry.UserId = userId
				entry.OwnedModel = model
			end
			fire(cfg.OnPlayerLoaded, model, userId, username)
		end)
	end
	function obj:LoadPlayer(query, label, select_) return obj:AddPlayer(query, label, select_) end
	function obj:SetPlayer(query, label) return obj:AddPlayer(query, label, true) end
	function obj:Add(t, label, select_)
		if type(t) == "string" or type(t) == "number" then return obj:AddPlayer(t, label, select_) end
		if type(t) == "table" and (t.UserId ~= nil or t.Username ~= nil or type(t.Target) == "string" or type(t.Target) == "number") then
			return obj:AddPlayer(t, label, select_)
		end
		return addTarget(t, label, select_)
	end
	function obj:Remove(t)
		local entry = entryOf(t)
		if not entry and (type(t) == "string" or type(t) == "number") then
			local text = tostring(t):lower()
			for _, candidate in ipairs(targets) do
				if tostring(candidate.UserId or "") == text or tostring(candidate.Label or candidate.Target.Name or ""):lower() == text then entry = candidate; break end
			end
		end
		return entry and removeTarget(entry.Target) or false
	end
	function obj:Clear()
		for _, e in ipairs(targets) do
			for _, c in ipairs(e.Conns) do c:Disconnect() end
			if e.OwnedModel then pcall(function() e.OwnedModel:Destroy() end) end
		end
		targets = {}
		selectIndex(1)
	end
	function obj:Set(t, label)
		if type(t) == "string" or type(t) == "number" or (type(t) == "table" and (t.UserId ~= nil or t.Username ~= nil or type(t.Target) == "string" or type(t.Target) == "number")) then
			return obj:AddPlayer(t, label, true)
		end
		local e, i = entryOf(t)
		if not e then
			addTarget(t, label, true)
		else
			selectIndex(i)
		end
	end
	function obj:Select(i) selectIndex(i) end
	function obj:Next() if #targets > 1 then selectIndex(index + 1) end end
	function obj:Prev() if #targets > 1 then selectIndex(index - 1) end end
	function obj:GetTarget() return targets[index] and targets[index].Target or nil end
	function obj:GetTargets()
		local out = {}
		for i, e in ipairs(targets) do out[i] = e.Target end
		return out
	end
	function obj:Count() return #targets end
	function obj:Refresh() dirtyAt = os.clock() end
	function obj:ResetView() resetView(false) end
	function obj:SetSpin(v, speed)
		if speed then spinSpeed = tonumber(speed) or spinSpeed end
		setSpin(v)
	end
	function obj:SetAutoRotate(v, speed) return obj:SetSpin(v, speed) end
	function obj:IsAutoRotating() return spinOn end
	function obj:SetLockFacing(v) setLock(v) end
	function obj:SetSpectate(v) setSpectate(v) end
	function obj:SetTitle(t)
		col.Name = tostring(t)
		titleLbl.Text = col.Name
		if col.Labels[2] then col.Labels[2].Text = col.Name .. "  ·  floating" end
		if col.RefreshFloatStatus then col.RefreshFloatStatus() end
	end
	function obj:SetHeight(h)
		baseH = math.clamp(tonumber(h) or baseH, 200, 520)
		if not floating then
			viewH = baseH
			layoutCard(false)
		end
	end
	function obj:Pop() if pop then pop() end end
	function obj:Dock() if dock then dock() end end
	function obj:IsFloating() return floating end

	table.insert(obj._listeners, function()
		destroyed = true
		setScrollLock(false)
		if spectating then
			spectating = false
			restoreCamera()
		end
		clearLive()
		for _, e in ipairs(targets) do
			for _, c in ipairs(e.Conns) do c:Disconnect() end
			if e.OwnedModel then pcall(function() e.OwnedModel:Destroy() end) end
		end
		if avatarFolder then pcall(function() avatarFolder:Destroy() end) end
		if col.Float then pcall(col.Float.Destroy) end
		if ghost then ghost:Destroy() end
	end)

	-- initial contents ----------------------------------------------
	for _, t in ipairs(cfg.Targets or {}) do
		if typeof(t) == "Instance" then
			addTarget(t)
		elseif type(t) == "string" or type(t) == "number" or (type(t) == "table" and (t.UserId ~= nil or t.Username ~= nil or type(t.Target) == "string" or type(t.Target) == "number")) then
			obj:AddPlayer(t, nil, false)
		end
	end
	local initialPlayerQuery = cfg.Player or cfg.PlayerName or cfg.UserId
	if initialPlayerQuery ~= nil then obj:AddPlayer(initialPlayerQuery, cfg.PlayerLabel, true) end
	if cfg.Players then
		local function consider(p)
			if p ~= LocalPlayer or cfg.IncludeSelf == true then addTarget(p) end
		end
		for _, p in ipairs(Players:GetPlayers()) do consider(p) end
		local c1 = Players.PlayerAdded:Connect(consider)
		local c2 = Players.PlayerRemoving:Connect(function(p) removeTarget(p) end)
		table.insert(obj._listeners, function()
			c1:Disconnect()
			c2:Disconnect()
		end)
	end
	if cfg.Default ~= nil then
		local e, i = entryOf(cfg.Default)
		if e then selectIndex(i, true) end
	end
	initializing = false
	refreshUI()
	if #targets == 0 then setEmpty(true) end
	layoutCard(true)
	return register(self, cfg, obj, host, "Viewer")
end

function Container:Pages(cfg)
	cfg = norm(cfg, { Title = "Name" })
	local win = self.Window
	local STRIP_H, BTN_H = 28, 22
	local root = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(), Parent = self.List,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7), Parent = root })

	pad(root, 4, 4, 0, 0)
	local stripRow = new("Frame", { Size = UDim2.new(1, -8, 0, STRIP_H), BackgroundTransparency = 1, LayoutOrder = 1, Parent = root })
	local track = new("Frame", { Size = UDim2.fromOffset(6, STRIP_H), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Parent = stripRow })
	corner(track, UDim.new(0, 8))
	stroke(track, Theme.Stroke)
	track:SetAttribute("NoDrag", true)
	local indicator = new("Frame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(0, BTN_H), BackgroundColor3 = Theme.Accent, BackgroundTransparency = .86,
		BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = track,
	})
	corner(indicator, UDim.new(0, 6))
	stroke(indicator, Theme.Accent, .55)
	local buttonRow = new("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(0, BTN_H), BackgroundTransparency = 1, ZIndex = 2, Parent = track })
	local rowLayout = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = buttonRow,
	})
	rowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		buttonRow.Size = UDim2.fromOffset(rowLayout.AbsoluteContentSize.X, BTN_H)
		track.Size = UDim2.fromOffset(rowLayout.AbsoluteContentSize.X + 6, STRIP_H)
	end)
	local holder = new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = root })

	local obj = { _pages = {}, Current = nil }
	local indGen = 0
	local function moveIndicator(entry, instant)
		local s = scaleFor(win, track)
		local x = (entry.Button.AbsolutePosition.X - track.AbsolutePosition.X) / s
		local w = entry.Button.AbsoluteSize.X / s
		if w <= 0 then return end
		if not indicator.Visible or instant then
			indicator.Visible = true
			indicator.Position = UDim2.fromOffset(x, 3)
			indicator.Size = UDim2.fromOffset(w, BTN_H)
			return
		end
		indGen += 1
		local gen = indGen
		local x0, w0 = indicator.Position.X.Offset, indicator.Size.X.Offset
		local left, right = math.min(x0, x), math.max(x0 + w0, x + w)
		tween(indicator, { Position = UDim2.fromOffset(left, 3), Size = UDim2.fromOffset(right - left, BTN_H) }, .14)
		task.delay(.12, function()
			if gen ~= indGen then return end
			tween(indicator, { Position = UDim2.fromOffset(x, 3), Size = UDim2.fromOffset(w, BTN_H) }, .5, SPRING)
		end)
	end

	function obj:Select(which, instant)
		local entry
		for _, e in ipairs(obj._pages) do
			if e.Container == which or e.Name == which or e == which then entry = e end
		end
		if not entry or entry == obj.Current then return end
		local prev = obj.Current
		obj.Current = entry
		win:_closePopups()
		if prev then
			prev.Frame.Visible = false
			tween(prev.Label, { TextColor3 = Theme.Muted }, .2)
			if prev.Icon then tween(prev.Icon, { ImageColor3 = Theme.Muted }, .2) end
		end
		tween(entry.Label, { TextColor3 = Theme.Text }, .2)
		if entry.Icon then tween(entry.Icon, { ImageColor3 = Theme.Accent }, .2) end
		entry.Frame.Visible = true
		if instant or not prev then
			entry.Frame.GroupTransparency = 0
			entry.Padding.PaddingTop = UDim.new(0, 3)
		else
			entry.Frame.GroupTransparency = 1
			entry.Padding.PaddingTop = UDim.new(0, 16)
			tween(entry.Frame, { GroupTransparency = 0 }, .35)
			tween(entry.Padding, { PaddingTop = UDim.new(0, 3) }, .6, SPRING)
		end
		task.defer(moveIndicator, entry, instant or not prev)
	end

	function obj:Page(pcfg)
		pcfg = norm(pcfg, { Title = "Name" })
		local entry = { Name = pcfg.Name or ("Page " .. (#obj._pages + 1)) }
		local btn = new("TextButton", {
			Size = UDim2.fromOffset(0, BTN_H), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			LayoutOrder = #obj._pages + 1, ZIndex = 2, Parent = buttonRow,
		})
		pad(btn, 10, 10)
		local leftOff = 0
		if pcfg.Icon then
			local box, img = iconBox(btn, pcfg.Icon, Theme.Muted, UDim2.new(0, 0, .5, 0))
			box.ZIndex = 3
			img.ZIndex = 3
			entry.Icon = img
			leftOff = 22
		end
		entry.Label = mkText {
			Position = UDim2.fromOffset(leftOff, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = entry.Name,
			TextSize = 13, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.None, ZIndex = 3, Parent = btn,
		}
		entry.Button = btn
		btn.MouseEnter:Connect(function() if obj.Current ~= entry then tween(entry.Label, { TextColor3 = Theme.Text }, .12) end end)
		btn.MouseLeave:Connect(function() if obj.Current ~= entry then tween(entry.Label, { TextColor3 = Theme.Muted }, .2) end end)
		btn.MouseButton1Click:Connect(function() obj:Select(entry) end)
		btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if obj.Current == entry then moveIndicator(entry, true) end
		end)

		local frame = new("CanvasGroup", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = holder,
		})
		entry.Frame = frame

		entry.Padding = pad(frame, 0, 0, 0, 6)
		local frameLayout = new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = frame,
		})
		local content = new("Frame", {
			Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame,
		})
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7), Parent = content })
		local page = setmetatable({ Name = entry.Name, Window = win, List = content, _order = 0, _kind = "Page", _compact = true }, Container)
		entry.Container = page
		table.insert(obj._pages, entry)
		if #obj._pages == 1 then task.defer(function() obj:Select(entry, true) end) end
		win._controlsDirty = true
		return page
	end
	function obj:GetPage(name)
		for _, e in ipairs(obj._pages) do if e.Name == name then return e.Container end end
	end
	return register(self, cfg, obj, root, "Pages")
end

function Container:ConfigPanel(cfg)
	cfg = norm(cfg, { Title = "Name" })
	local win = self.Window
	local rowH = Touch and 38 or 32
	local listH = (rowH + 4) * 3 + 12
	local hasFiles = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
	local card = makeCard(self, "Frame", 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	pad(card, 14, 14, 12, 14)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = card })
	local selected = win.ConfigName
	local obj = {}

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card })
	iconBox(head, cfg.Icon or "save", Theme.Accent, UDim2.new(0, 0, .5, 0))
	mkText { Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -150, 1, 0), Text = cfg.Name or "Configurations", TextSize = 14, Parent = head }
	local chip = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = head,
	})
	corner(chip, UDim.new(1, 0))
	pad(chip, 9, 9)
	local chipLbl = mkText {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = 10, FontFace = Fonts.Bold,
		TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.None, Parent = chip,
	}

	local function makeBtn(parent, text, icon, variant, props)
		local primary = variant == "primary"
		local danger = variant == "danger"
		local base = {
			BackgroundColor3 = primary and Theme.Accent or Theme.Surface, BackgroundTransparency = primary and .12 or 0, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = parent,
		}
		for k, v in pairs(props) do base[k] = v end
		local b = new("TextButton", base)
		corner(b, UDim.new(0, 8))
		local bs = stroke(b, primary and Theme.Accent or Theme.Stroke, primary and .4 or 0)
		local sc = new("UIScale", { Parent = b })
		local ink = primary and Theme.AccentDark or Theme.Text
		local inner = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = b,
		})
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = inner,
		})
		local iimg
		if icon then
			local ibox
			ibox, iimg = iconBox(inner, icon, ink, UDim2.new())
			ibox.LayoutOrder = 1
		end
		local lbl = mkText {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = text, TextSize = 13, TextColor3 = ink,
			TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Parent = inner,
		}
		b.MouseEnter:Connect(function()
			if primary then
				tween(b, { BackgroundTransparency = 0 }, .15)
			else
				tween(bs, { Color = danger and Theme.Error or Theme.StrokeHover }, .15)
			end
			if danger then
				tween(lbl, { TextColor3 = Theme.Error }, .15)
				if iimg then tween(iimg, { ImageColor3 = Theme.Error }, .15) end
			end
		end)
		b.MouseLeave:Connect(function()
			if primary then
				tween(b, { BackgroundTransparency = .12 }, .25)
			else
				tween(bs, { Color = Theme.Stroke }, .25)
			end
			if danger then
				tween(lbl, { TextColor3 = Theme.Text }, .25)
				if iimg then tween(iimg, { ImageColor3 = Theme.Text }, .25) end
			end
			tween(sc, { Scale = 1 }, .5, SPRING)
		end)
		b.MouseButton1Down:Connect(function() tween(sc, { Scale = .94 }, .1) end)
		b.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, .5, SPRING) end)
		b.MouseButton1Click:Connect(function() ripple(b) end)
		return b
	end

	local nameRow = new("Frame", { Size = UDim2.new(1, 0, 0, rowH), BackgroundTransparency = 1, LayoutOrder = 2, Parent = card })
	local box = new("Frame", {
		Size = UDim2.new(1, -96, 1, 0), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, Parent = nameRow,
	})
	corner(box, UDim.new(0, 8))
	local boxStroke = stroke(box)
	local input = new("TextBox", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Config name",
		PlaceholderColor3 = Theme.Muted, TextColor3 = Theme.Text, TextSize = 13, FontFace = Fonts.Regular, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, Parent = box,
	})
	local saveBtn = makeBtn(nameRow, "Save", "save", "primary", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 88, 1, 0) })

	mkText { Size = UDim2.new(1, 0, 0, 14), Text = "SAVED CONFIGS", TextSize = 11, TextColor3 = Theme.Muted, LayoutOrder = 3, Parent = card }
	local listBox = new("Frame", {
		Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = 4, Parent = card,
	})
	corner(listBox, UDim.new(0, 10))
	stroke(listBox)
	local scroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
		ScrollBarImageTransparency = .5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = listBox,
	})
	pad(scroll, 6, 6, 6, 6)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = scroll })
	local emptyLbl = mkText {
		Size = UDim2.fromScale(1, 1), Text = "No saved configs yet", TextSize = 13, FontFace = Fonts.Regular, TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Center, Parent = listBox,
	}

	local actions = new("Frame", { Size = UDim2.new(1, 0, 0, rowH), BackgroundTransparency = 1, LayoutOrder = 5, Parent = card })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = actions })
	local canCopyConfig = type(setclipboard) == "function"
	local actionFraction = canCopyConfig and (1 / 4) or (1 / 3)
	local loadBtn = makeBtn(actions, "Load", "folder-open", nil, { Size = UDim2.new(actionFraction, -6, 1, 0), LayoutOrder = 1 })
	local delBtn = makeBtn(actions, "Delete", "trash-2", "danger", { Size = UDim2.new(actionFraction, -6, 1, 0), LayoutOrder = 2 })
	local refBtn = makeBtn(actions, "Refresh", "refresh-cw", nil, { Size = UDim2.new(actionFraction, -6, 1, 0), LayoutOrder = 3 })
	local copyBtn = canCopyConfig and makeBtn(actions, "Copy", "copy", nil, { Size = UDim2.new(actionFraction, -6, 1, 0), LayoutOrder = 4 }) or nil

	local autoRow = new("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH + 12), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		LayoutOrder = 6, Parent = card,
	})
	corner(autoRow, UDim.new(0, 10))
	local autoStroke = stroke(autoRow)
	mkText { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -78, 0, 18), Text = "Auto save", TextSize = 13, Parent = autoRow }
	mkText {
		Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -78, 0, 15), Text = "Writes the active config when a flagged control changes",
		TextSize = 12, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = autoRow,
	}
	local trackW, trackH = Touch and 44 or 36, Touch and 24 or 20
	local knob = Touch and 18 or 14
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(trackW, trackH),
		BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = autoRow,
	})
	corner(track, UDim.new(1, 0))
	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(knob, knob),
		BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = track,
	})
	corner(thumb, UDim.new(1, 0))

	local autoLoadRow = new("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH + 12), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		LayoutOrder = 7, Parent = card,
	})
	corner(autoLoadRow, UDim.new(0, 10))
	local autoLoadStroke = stroke(autoLoadRow)
	mkText { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -78, 0, 18), Text = "Load on startup", TextSize = 13, Parent = autoLoadRow }
	mkText {
		Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -78, 0, 15), Text = "Load the active config when the UI opens",
		TextSize = 12, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = autoLoadRow,
	}
	local loadTrack = new("Frame", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(trackW, trackH),
		BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = autoLoadRow,
	})
	corner(loadTrack, UDim.new(1, 0))
	local loadThumb = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(knob, knob),
		BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = loadTrack,
	})
	corner(loadThumb, UDim.new(1, 0))

	local footer = mkText {
		Size = UDim2.new(1, 0, 0, 14), Text = "", TextSize = 11, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, LayoutOrder = 8, Parent = card,
	}

	local function renderAuto(animate)
		local on = win._autoSaveEnabled == true
		local t = animate and .3 or 0
		tween(track, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, t)
		tween(thumb, {
			Position = on and UDim2.new(0, trackW - 3 - knob, .5, 0) or UDim2.new(0, 3, .5, 0),
			BackgroundColor3 = on and Theme.AccentDark or Theme.Muted,
		}, animate and .5 or 0, SPRING)
		tween(autoStroke, { Color = on and Theme.StrokeHover or Theme.Stroke }, t)
	end
	local function renderAutoLoad(animate)
		local on = win._autoLoad == true
		local t = animate and .3 or 0
		tween(loadTrack, { BackgroundColor3 = on and Theme.Accent or Theme.Surface3 }, t)
		tween(loadThumb, {
			Position = on and UDim2.new(0, trackW - 3 - knob, .5, 0) or UDim2.new(0, 3, .5, 0),
			BackgroundColor3 = on and Theme.AccentDark or Theme.Muted,
		}, animate and .5 or 0, SPRING)
		tween(autoLoadStroke, { Color = on and Theme.StrokeHover or Theme.Stroke }, t)
	end
	local function refreshStatus()
		local on = win._autoSaveEnabled == true
		chipLbl.Text = hasFiles and (on and "AUTO SAVE ON" or "AUTO SAVE OFF") or "NO FILE API"
		tween(chipLbl, { TextColor3 = (hasFiles and on) and Theme.Accent or Theme.Muted }, .2)
		footer.Text = hasFiles and ("Folder  " .. tostring(win.ConfigFolder) .. "   ·   Active  " .. tostring(win.ConfigName))
			or "This executor cannot read or write files"
	end

	local rows = {}
	local function paintRow(r, instant)
		local on = r.Id == selected
		local active = r.Id == win.ConfigName
		local d = instant and 0 or .2
		tween(r.Frame, { BackgroundColor3 = on and Theme.Surface3 or Theme.Surface2 }, d)
		tween(r.Stroke, { Color = on and Theme.Accent or Theme.Stroke }, d)
		tween(r.Label, { TextColor3 = on and Theme.Text or Theme.Muted }, d)
		tween(r.Dot, { BackgroundTransparency = active and 0 or 1 }, d)
	end
	local function rebuild()
		for _, r in pairs(rows) do r.Frame:Destroy() end
		rows = {}
		local names = win:ListConfigs()
		emptyLbl.Visible = #names == 0
		for i, n in ipairs(names) do
			local f = new("TextButton", {
				Size = UDim2.new(1, 0, 0, rowH - 2), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
				LayoutOrder = i, Parent = scroll,
			})
			corner(f, UDim.new(0, 8))
			local rs = stroke(f)
			local label = mkText { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), Text = n, TextSize = 13, TextColor3 = Theme.Muted, Parent = f }
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = f,
			})
			corner(dot, UDim.new(1, 0))
			label:SetAttribute("AF_NoTranslate", true)
			local r = { Id = n, Frame = f, Stroke = rs, Label = label, Dot = dot }
			rows[i] = r
			f.MouseButton1Click:Connect(function()
				selected = n
				input.Text = n
				for _, other in pairs(rows) do paintRow(other) end
			end)
			paintRow(r, true)
		end
	end

	local function typedName()
		local t = string.gsub(input.Text or "", "[\\/:*?\"<>|]", "")
		return (string.match(t, "^%s*(.-)%s*$")) or ""
	end
	local function notify(ok, okTitle, failTitle, detail)
		win:Notify { Title = ok and okTitle or failTitle, Content = ok and detail or tostring(detail), Type = ok and "Success" or "Error", Duration = 3 }
	end
	local function doSave()
		local name = typedName()
		if name == "" then name = selected end
		if not name or name == "" then
			win:Notify { Title = "Name your config", Content = "Type a name first.", Type = "Warning", Duration = 3 }
			return
		end
		local ok, err = win:SaveConfig(name)
		if ok then selected = name end
		rebuild()
		refreshStatus()
		notify(ok, "Config saved", "Save failed", ok and name or err)
	end
	local function doLoad()
		local name = selected
		if not name or name == "" then name = typedName() end
		if name == "" then
			win:Notify { Title = "Pick a config", Content = "Select one from the list.", Type = "Warning", Duration = 3 }
			return
		end
		local ok, err = win:LoadConfig(name)
		rebuild()
		refreshStatus()
		notify(ok, "Config loaded", "Load failed", ok and name or err)
	end
	local function doDelete()
		local name = selected
		if not name or name == "" then
			win:Notify { Title = "Pick a config", Content = "Select one from the list.", Type = "Warning", Duration = 3 }
			return
		end
		win:Confirm {
			Title = "Delete config", Content = "Remove " .. name .. "? This cannot be undone.", Icon = "trash-2", ConfirmText = "Delete",
			Callback = function()
				local ok, err = win:DeleteConfig(name)
				if ok and selected == name then selected = nil end
				rebuild()
				refreshStatus()
				notify(ok, "Config deleted", "Delete failed", ok and name or err)
			end,
		}
	end

	saveBtn.MouseButton1Click:Connect(doSave)
	loadBtn.MouseButton1Click:Connect(doLoad)
	delBtn.MouseButton1Click:Connect(doDelete)
	refBtn.MouseButton1Click:Connect(function()
		rebuild()
		refreshStatus()
	end)
	if copyBtn then
		copyBtn.MouseButton1Click:Connect(function()
			local ok, err = pcall(function() setclipboard(win:ExportConfig()) end)
			win:Notify {
				Title = ok and "Config copied" or "Copy failed",
				Content = ok and "JSON is on your clipboard" or tostring(err or "Clipboard unavailable"),
				Type = ok and "Success" or "Error", Duration = 3,
			}
		end)
	end
	input.Focused:Connect(function() tween(boxStroke, { Color = Theme.Accent }, .2) end)
	input.FocusLost:Connect(function(enter)
		tween(boxStroke, { Color = Theme.Stroke }, .25)
		if enter then doSave() end
	end)
	autoRow.MouseButton1Click:Connect(function()
		win._autoSaveEnabled = not (win._autoSaveEnabled == true)
		renderAuto(true)
		refreshStatus()
		win:_saveUISettings()
	end)
	autoLoadRow.MouseButton1Click:Connect(function()
		win._autoLoad = not (win._autoLoad == true)
		renderAutoLoad(true)
		win:_saveUISettings()
	end)

	function obj:Refresh()
		rebuild()
		refreshStatus()
		renderAuto(false)
		renderAutoLoad(false)
	end
	function obj:GetSelected() return selected end
	obj:Refresh()
	return register(self, cfg, obj, card, "ConfigPanel")
end

function Container:ConfigManager(cfg)
	cfg = norm(cfg, {})
	local win = self.Window
	local api = {}
	self:Header(cfg.Name or "Configs", cfg.Icon or "naja:database")
	local nameInput = self:Input {
		Name = "Config name", Placeholder = win.ConfigName,
		Callback = function(text, enter) if enter and #text > 0 then api:Save(text) end end,
	}
	local list = self:Dropdown {
		Name = "Saved configs", Options = win:ListConfigs(), Default = win.ConfigName, Style = cfg.DropdownStyle or "Popup",
		Callback = function(v) if v then nameInput:Set(v) end end,
	}
	function api:Refresh() list:Refresh(win:ListConfigs(), true) end
	function api:Save(name)
		name = name or list:Get() or win.ConfigName
		local ok, err = win:SaveConfig(name)
		api:Refresh()
		list:Set(name, true)
		win:Notify { Title = ok and "Config saved" or "Save failed", Content = ok and name or tostring(err), Type = ok and "Success" or "Error", Duration = 3 }
	end
	function api:Load(name)
		name = name or list:Get()
		if not name then return end
		local ok, err = win:LoadConfig(name)
		win:Notify { Title = ok and "Config loaded" or "Load failed", Content = ok and name or tostring(err), Type = ok and "Success" or "Error", Duration = 3 }
	end
	function api:Delete(name)
		name = name or list:Get()
		if not name then return end
		local ok, err = win:DeleteConfig(name)
		api:Refresh()
		win:Notify { Title = ok and "Config deleted" or "Delete failed", Content = ok and name or tostring(err), Type = ok and "Info" or "Error", Duration = 3 }
	end
	self:Button { Name = "Save", Desc = "Writes every flagged element to the selected name", Icon = "save", Style = "Primary",
		Callback = function()
			local n = nameInput:Get()
			api:Save(#n > 0 and n or nil)
		end }
	self:Button { Name = "Load", Icon = "folder-open", Callback = function() api:Load() end }
	self:Button { Name = "Delete", Icon = "trash-2", Callback = function()
		local n = list:Get()
		if not n then return end
		win:Confirm { Title = "Delete config", Content = "Remove " .. n .. "? This cannot be undone.", Icon = "trash-2", ConfirmText = "Delete", Callback = function() api:Delete(n) end }
	end }
	self:Toggle { Name = "Auto save", Desc = "Save whenever a flagged element changes", Default = win._autoSaveEnabled, Callback = function(v) win._autoSaveEnabled = v end }
	return api
end
function Container:SettingsManager(cfg)
	cfg = norm(cfg, {})
	local win = self.Window
	local api = {}
	local built = false
	local function persist() if built then win:_saveUISettings() end end

	self:Header(cfg.Name or "Configuration", "save")

	local card, st = makeCard(self, "Frame", 70)
	hover(card, st)
	local dot = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 18, .5, 0), Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, Parent = card,
	})
	corner(dot, UDim.new(1, 0))
	local ring = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1, Parent = dot,
	})
	corner(ring, UDim.new(1, 0))
	local ringStroke = stroke(ring, Theme.Success, 1, 2)
	local nameLbl = mkText {
		Position = UDim2.fromOffset(40, 14), Size = UDim2.new(1, -54, 0, 20), Text = "", TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	}
	local infoLbl = mkText {
		Position = UDim2.fromOffset(40, 38), Size = UDim2.new(1, -54, 0, 16), Text = "", TextSize = 12,
		FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	}
	local function pulseRing()
		ring.Size = UDim2.fromOffset(10, 10)
		ringStroke.Transparency = .2
		tween(ring, { Size = UDim2.fromOffset(30, 30) }, .6, QUINT)
		tween(ringStroke, { Transparency = 1 }, .6)
	end
	local function status()
		if not card.Parent then return end
		nameLbl.Text = win.ConfigName
		local parts = { win._autoSaveEnabled and "Auto save on" or "Auto save off" }
		if win._lastSaved then table.insert(parts, "saved " .. os.date("%H:%M:%S", win._lastSaved)) end
		infoLbl.Text = table.concat(parts, "  ·  ")
		tween(dot, { BackgroundColor3 = win._autoSaveEnabled and Theme.Success or Theme.Muted }, .25)
	end
	win._cfgListeners = win._cfgListeners or {}
	table.insert(win._cfgListeners, function(kind)
		status()
		if kind == "save" then pulseRing() end
	end)

	local nameInput = self:Input {
		Name = "Config name", Desc = "Type a name and press enter to save it", Placeholder = win.ConfigName,
		Callback = function(text, enter) if enter and #text > 0 then api:Save(text) end end,
	}
	local list = self:Dropdown {
		Name = "Saved configs", Desc = "Pick a config to load or delete", Options = win:ListConfigs(), Default = win.ConfigName,
		Style = "Popup", Callback = function(v) if v then nameInput:Set(v) end end,
	}
	function api:Refresh() list:Refresh(win:ListConfigs(), true) status() end
	function api:Save(name)
		name = name or list:Get() or win.ConfigName
		name = (tostring(name):gsub('[\\/:*?"<>|]', "")):match("^%s*(.-)%s*$")
		if name == "" then
			win:Notify { Title = "Save failed", Content = "Give the config a name first", Type = "Error", Duration = 3 }
			return
		end
		local ok, err = win:SaveConfig(name)
		api:Refresh()
		if ok then list:Set(name, true) end
		win:Notify { Title = ok and "Config saved" or "Save failed", Content = ok and name or tostring(err), Type = ok and "Success" or "Error", Duration = 3 }
	end
	function api:Load(name)
		name = name or list:Get()
		if not name then return end
		local ok, err = win:LoadConfig(name)
		win:Notify { Title = ok and "Config loaded" or "Load failed", Content = ok and name or tostring(err), Type = ok and "Success" or "Error", Duration = 3 }
	end
	function api:Delete(name)
		name = name or list:Get()
		if not name then return end
		local ok, err = win:DeleteConfig(name)
		api:Refresh()
		win:Notify { Title = ok and "Config deleted" or "Delete failed", Content = ok and name or tostring(err), Type = ok and "Info" or "Error", Duration = 3 }
	end
	self:Button { Name = "Save config", Desc = "Writes every flagged element to the selected name", Icon = "save", Style = "Primary",
		Callback = function()
			local n = nameInput:Get()
			api:Save(#n > 0 and n or nil)
		end }
	self:Button { Name = "Load config", Icon = "folder-open", Callback = function() api:Load() end }
	self:Button { Name = "Delete config", Icon = "trash-2", Callback = function()
		local n = list:Get()
		if not n then return end
		win:Confirm { Title = "Delete config", Content = "Remove " .. n .. "? This cannot be undone.", Icon = "trash-2", ConfirmText = "Delete", Callback = function() api:Delete(n) end }
	end }
	if type(setclipboard) == "function" then
		self:Button { Name = "Copy config", Desc = "Copies the current element values as JSON", Icon = "copy", Callback = function()
			local ok = pcall(function() setclipboard(win:ExportConfig()) end)
			win:Notify { Title = ok and "Config copied" or "Copy failed", Content = ok and "JSON is on your clipboard" or "Clipboard unavailable", Type = ok and "Success" or "Error", Duration = 3 }
		end }
	end
	self:Button { Name = "Refresh list", Icon = "refresh-cw", Callback = function() api:Refresh() end }

	self:Header("Auto save", "zap")
	self:Toggle { Name = "Auto save", Desc = "Save whenever a flagged element changes", Default = win._autoSaveEnabled,
		Callback = function(v)
			if v == win._autoSaveEnabled then return end
			win._autoSaveEnabled = v
			status()
			persist()
		end }
	self:Slider { Name = "Auto save delay", Desc = "Wait this long after a change before saving", Min = .25, Max = 5, Step = .25,
		Default = win._autoSaveDelay or .5, Suffix = "s",
		Callback = function(v)
			if v == win._autoSaveDelay then return end
			win._autoSaveDelay = v
			persist()
		end }
	self:Toggle { Name = "Load on startup", Desc = "Load the selected config when the UI opens", Default = win._autoLoad == true,
		Callback = function(v)
			if v == (win._autoLoad == true) then return end
			win._autoLoad = v
			persist()
		end }

	self:Header("Interface", "layout-grid")
	self:Keybind { Name = "Toggle UI", Desc = "Key that shows or hides this window", Default = win.Keybind,
		OnChanged = function(k)
			if k and k ~= win.Keybind then
				win:SetKeybind(k)
				persist()
			end
		end }
	self:Toggle { Name = "Keep on screen", Desc = "Stop the window from being dragged out of view", Default = win.KeepOnScreen,
		Callback = function(v)
			if v == win.KeepOnScreen then return end
			win:SetKeepOnScreen(v)
			persist()
		end }
	self:Toggle { Name = "Pill hover expand", Desc = "Expand the collapsed pill when hovered", Default = win.PillHover,
		Callback = function(v)
			if v == win.PillHover then return end
			win:SetPillHover(v)
			persist()
		end }
	self:Button { Name = "Reset window position", Icon = "move", Callback = function()
		if win._pill or win._destroyed then return end
		tween(win.Root, { Position = UDim2.fromScale(.5, .5) }, .6, LIQUID)
	end }

	self:Header("Session", "power")
	self:Button { Name = "Destroy UI", Desc = "Removes the window completely", Icon = "circle-x", Callback = function()
		win:Confirm { Title = "Destroy UI", Content = "This removes the window completely.", Icon = "circle-x", ConfirmText = "Destroy", Callback = function()
			task.delay(.24, function() if not win._destroyed then win:Destroy() end end)
		end }
	end }

	status()
	task.defer(function()
		built = true
		win._uiSettingsReady = true
		win._persistedName = win.ConfigName
	end)
	return api
end


do
	for name, fn in pairs(table.clone(Container)) do
		if type(fn) == "function" and name:sub(1, 1) ~= "_" then
			Container[name] = function(self, ...)
				if not self._compact then return fn(self, ...) end
				local r, d = ROW_H, DESC_H
				ROW_H, DESC_H = Touch and 46 or 40, Touch and 62 or 56
				local res = table.pack(pcall(fn, self, ...))
				ROW_H, DESC_H = r, d
				if not res[1] then error(res[2], 0) end
				return table.unpack(res, 2, res.n)
			end
		end
	end
end

for name, fn in pairs(table.clone(Container)) do
	if type(fn) == "function" and name:sub(1, 1) ~= "_" and name:sub(1, 6) ~= "Create" then
		Container["Create" .. name] = fn
	end
end

local Window = {}
Window.__index = Window

local function identifyExecutor()
	local n
	pcall(function()
		if typeof(identifyexecutor) == "function" then n = (identifyexecutor())
		elseif typeof(getexecutorname) == "function" then n = getexecutorname() end
	end)
	if type(n) == "string" and #n > 0 then return n end
	return RunService:IsStudio() and "Studio" or "Unknown"
end
local function gameName()
	local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
	if ok and type(info) == "table" and info.Name then return info.Name end
	return "Unknown game"
end
local Countries = {
	US = "United States", GB = "United Kingdom", DE = "Germany", FR = "France", NL = "Netherlands", SG = "Singapore",
	JP = "Japan", AU = "Australia", BR = "Brazil", IN = "India", HK = "Hong Kong", CA = "Canada",
}
local function fetchRegion(cb)
	task.spawn(function()
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		local result
		if type(req) == "function" then
			pcall(function()
				local res = req { Url = "https://ipinfo.io/json", Method = "GET" }
				local body = type(res) == "table" and (res.Body or res.body) or nil
				if type(body) == "string" then
					local data = HttpService:JSONDecode(body)
					if type(data) == "table" and data.country then
						local c = Countries[data.country] or data.country
						result = data.city and (data.city .. ", " .. c) or c
					end
				end
			end)
		end
		cb(result or "Unavailable")
	end)
end

local ToastColors = { Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error, Info = Theme.Accent }
Library._toastColors = ToastColors
local ToastIcons = { Success = "check", Warning = "triangle-alert", Error = "circle-x", Info = "info" }

function Library.Window(_, cfg)
	cfg = norm(cfg, { Name = "Title", LoadingSubtitle = "Subtitle", ToggleUIKeybind = "Keybind" })
	if type(cfg.Keybind) == "string" then cfg.Keybind = Enum.KeyCode[cfg.Keybind] end
	if #Library.Windows == 0 then
		if cfg.Theme ~= nil then Library:SetTheme(cfg.Theme, true) end
		Library._snapTheme()
	elseif cfg.Theme ~= nil then
		Library:SetTheme(cfg.Theme)
	end
	local size = cfg.Size or UDim2.fromOffset(760, 520)
	local keybind = cfg.Keybind or Enum.KeyCode.RightControl

	local win = setmetatable({
		Tabs = {}, CurrentTab = nil, Open = true, Keybind = keybind, _connections = {}, _controls = {},
		_inputListeners = { Began = {}, Changed = {}, Ended = {}, Render = {} }, _frameSteps = {}, _destroyed = false, _floats = {},
		_quickItems = {}, _quickFloats = {}, _quickOverlay = nil,
	}, Window)

	local pillOpt = cfg.MobilePill
	if pillOpt == nil then pillOpt = cfg.OpenButton end
	if pillOpt == nil then pillOpt = Touch end
	win.MobilePill = pillOpt ~= false
	local pillCfg = type(cfg.Pill) == "table" and cfg.Pill or (type(pillOpt) == "table" and pillOpt or {})

	local function dispatch(kind)
		return function(...)
			for _, fn in ipairs(win._inputListeners[kind]) do fn(...) end
		end
	end
	local renderDispatch = dispatch("Render")
	table.insert(win._connections, RunService.RenderStepped:Connect(function(dt)
		renderDispatch(dt)
		for _, step in ipairs(win._frameSteps) do step(dt) end
	end))
	table.insert(win._connections, UIS.InputBegan:Connect(dispatch("Began")))
	table.insert(win._connections, UIS.InputChanged:Connect(dispatch("Changed")))
	table.insert(win._connections, UIS.InputEnded:Connect(dispatch("Ended")))

	local gui = new("ScreenGui", {
		Name = cfg.Name or "AirflowUI", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	win.Gui = gui
	local root = new("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = size,
		BackgroundTransparency = 1, Parent = gui,
	})
	win.Root = root
	local scale = new("UIScale", { Parent = root })
	win.Scale = scale
	local shadow = new("ImageLabel", {
		Position = UDim2.fromOffset(-25, -25), Size = UDim2.new(1, 50, 1, 50), BackgroundTransparency = 1, Image = Assets.Shadow,
		ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = .6, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), Parent = root,
	})
	win.Shadow = shadow
	local body = new("CanvasGroup", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = root })
	win.Body = body
	win.BodyCorner = corner(body, UDim.new(0, 10))
	win.BodyStroke = stroke(body, Theme.Stroke)
	sheen(body)
	glow(body, UDim2.fromOffset(500, 180), UDim2.new(.5, 0, 1, 8), .86, 270)
	glow(body, UDim2.fromOffset(130, 60), UDim2.new(0, -10, 1, -10), .75, 90)
	glow(body, UDim2.fromOffset(520, 240), UDim2.new(1, -14, 0, 10), .92, 90)
	win._pillGlow = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(1, 60, 1, 60), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = 1, ZIndex = 0, Parent = body,
	})

	local main = new("CanvasGroup", {
		Name = "Main", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = body,
	})
	win.Main = main

	local sidebar = new("Frame", { Name = "Sidebar", Size = UDim2.new(0, 170, 1, 0), BackgroundTransparency = 1, Parent = main })
	new("Frame", { Position = UDim2.new(0, 170, 0, 28), Size = UDim2.new(0, 1, 1, -56), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = main })
	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, Parent = sidebar })
	local logo = new("ImageLabel", {
		Position = UDim2.fromOffset(22, 27), Size = UDim2.fromOffset(30, 28), BackgroundTransparency = 1, Image = "",
		ImageColor3 = Theme.Accent, ScaleType = Enum.ScaleType.Fit, Parent = header,
	})
	local headerLogoIsImage = setIcon(logo, cfg.Icon or Assets.Logo)
	if headerLogoIsImage then
		logo.Size = UDim2.fromOffset(28, 28)
		logo.ScaleType = Enum.ScaleType.Crop
		corner(logo, UDim.new(1, 0))
	end
	mkText { Position = UDim2.fromOffset(60, 25), Size = UDim2.new(1, -70, 0, 20), Text = cfg.Title or "Airflow", TextSize = 20, Parent = header }
	mkText {
		Position = UDim2.fromOffset(60, 45), Size = UDim2.new(1, -70, 0, 14), Text = cfg.Subtitle or "", TextSize = 13,
		FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = header,
	}

	local tabList = new("ScrollingFrame", {
		Name = "Tabs", Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -116), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = sidebar,
	})
	win.TabList = tabList
	pad(tabList, 16, 16, 4, 4)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = tabList })
	local indicator = new("Frame", {
		Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
		Visible = false, ZIndex = 2, Parent = sidebar,
	})
	corner(indicator, UDim.new(1, 0))
	win.Indicator = indicator
	-- the line follows the current tab every frame, so scrolling, layout shifts,
	-- pop-in animations and resizes can never leave it on the wrong tab
	local indTop, indBot = 0, 0
	table.insert(win._frameSteps, function(dt)
		local tab = win.CurrentTab
		if not win._indActive or not tab or not win._introDone then return end
		if tab._hidden then
			indicator.Visible = false
			win._indSnap = "grow"
			return
		end
		local btn = tab._button
		if not btn.Parent or not btn.Visible then return end
		local cy = win:_indicatorY(tab)
		local goalTop, goalBot = cy - 9, cy + 9
		if win._indSnap then
			if win._indSnap == "grow" then indTop, indBot = goalTop, goalTop else indTop, indBot = goalTop, goalBot end
			win._indSnap = nil
		else
			local lead, trail = 1 - math.exp(-dt * 26), 1 - math.exp(-dt * 11)
			if goalTop >= indTop then
				indBot += (goalBot - indBot) * lead
				indTop += (goalTop - indTop) * trail
			else
				indTop += (goalTop - indTop) * lead
				indBot += (goalBot - indBot) * trail
			end
		end
		local top = tabList.Position.Y.Offset
		local bottom = top + tabList.AbsoluteSize.Y / math.max(win.Scale.Scale, .01)
		indicator.Visible = cy > top and cy < bottom
		indicator.Position = UDim2.fromOffset(6, indTop)
		indicator.Size = UDim2.fromOffset(3, math.max(indBot - indTop, 0))
	end)

	local hint = new("Frame", { Position = UDim2.new(0, 22, 1, -36), Size = UDim2.new(1, -44, 0, 22), BackgroundTransparency = 1, Parent = sidebar })
	local chip = new("Frame", { Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = hint })
	corner(chip, UDim.new(0, 5))
	stroke(chip)
	pad(chip, 7, 7)
	win._keyChipLabel = mkText {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = keyName(keybind), TextSize = 11, TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.None, Parent = chip,
	}
	local hintText = mkText {
		Size = UDim2.new(1, 0, 1, 0), Text = win.MobilePill and (Touch and "or tap the pill" or "to collapse") or (Touch and "or tap the pill" or "to hide"),
		TextSize = 12, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, Parent = hint,
	}
	local function placeHint() hintText.Position = UDim2.fromOffset(chip.AbsoluteSize.X / win.Scale.Scale + 8, 0) end
	chip:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeHint)
	task.defer(placeHint)

	local content = new("Frame", {
		Name = "Content", Position = UDim2.fromOffset(171, 0), Size = UDim2.new(1, -171, 1, 0), BackgroundTransparency = 1,
		ClipsDescendants = true, Parent = main,
	})
	win.Content = content
	win._outLayer = new("CanvasGroup", { Name = "TransitionOut", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false, ZIndex = 2, Parent = content })
	win._inLayer = new("CanvasGroup", { Name = "TransitionIn", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false, ZIndex = 3, Parent = content })

	local closeBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = Theme.Surface2,
		BackgroundTransparency = 1, Text = "×", TextColor3 = Theme.Muted, TextSize = 28, FontFace = Fonts.Bold, AutoButtonColor = false, ZIndex = 5, Parent = content,
	})
	pad(closeBtn, 0, 0, 1, 0)
	corner(closeBtn, UDim.new(0, 8))
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, .15) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { BackgroundTransparency = 1, TextColor3 = Theme.Muted }, .25) end)
	closeBtn.MouseButton1Click:Connect(function()
		if win._dialog or win._destroyed then return end
		win:Dialog {
			Title = "Close Airflow?",
			Content = "Would you like to close this window or destroy the UI completely?",
			Icon = "circle-x",
			Buttons = {
				{
					Title = "Destroy UI",
					Callback = function()
						task.delay(.24, function()
							if not win._destroyed then win:Destroy() end
						end)
					end,
				},
				{
					Title = "Close UI",
					Variant = "Primary",
					Callback = function()
						task.delay(.24, function()
							if not win._destroyed then win:Toggle(false) end
						end)
					end,
				},
			},
		}
	end)

	local settingsBtn = new("TextButton", {
		Name = "SettingsButton", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -56, 0, 14), Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = content,
	})
	corner(settingsBtn, UDim.new(0, 8))
	local settingsScale = new("UIScale", { Parent = settingsBtn })
	local settingsIcon = quickIcon(settingsBtn, "settings", "⚙", 18, Theme.Muted, 6)
	local settingsOn = false
	win._settingsActive = function(on)
		settingsOn = on == true
		tween(settingsBtn, { BackgroundTransparency = settingsOn and 0 or 1, BackgroundColor3 = settingsOn and Theme.Surface3 or Theme.Surface2 }, .2)
		settingsIcon.Color(settingsOn and Theme.Accent or Theme.Muted, .2)
		tween(settingsIcon.Holder, { Rotation = settingsOn and 90 or 0 }, .6, SPRING)
	end
	settingsBtn.MouseEnter:Connect(function()
		if not settingsOn then
			tween(settingsBtn, { BackgroundTransparency = 0 }, .15)
			settingsIcon.Color(Theme.Text, .15)
		end
		tween(settingsScale, { Scale = 1.1 }, .4, SPRING)
	end)
	settingsBtn.MouseLeave:Connect(function()
		if not settingsOn then
			tween(settingsBtn, { BackgroundTransparency = 1 }, .25)
			settingsIcon.Color(Theme.Muted, .25)
		end
		tween(settingsScale, { Scale = 1 }, .4, SPRING)
	end)
	settingsBtn.MouseButton1Down:Connect(function() tween(settingsScale, { Scale = .88 }, .1) end)
	settingsBtn.MouseButton1Up:Connect(function() tween(settingsScale, { Scale = 1.1 }, .45, SPRING) end)
	settingsBtn.MouseButton1Click:Connect(function()
		if win._dialog or win._destroyed then return end
		win:ToggleSettings()
	end)

	win.Overlay = new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 45, Parent = body })

	local pillTitle = pillCfg.Title or cfg.Title or "Airflow"
	local pillW = math.clamp(TextService:GetTextSize(pillTitle, 13, Enum.Font.GothamMedium, Vector2.new(400, 20)).X + 64, 120, 280)
	win._pillWidth = pillW
	win._islandW = pillCfg.Width or 320
	win._islandOpen = false
	win._islandItems = {}
	win.PillHover = pillCfg.HoverExpand ~= false

	local pillLayer = new("CanvasGroup", {
		Name = "PillLayer", Size = UDim2.new(1, 0, 0, PILL_H), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 55, Parent = body,
	})
	local pillLogoBox = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 14, .5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Parent = pillLayer })
	local pillLogo = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ImageColor3 = Theme.Accent, ScaleType = Enum.ScaleType.Fit, Parent = pillLogoBox,
	})
	local pillLogoIsImage = setIcon(pillLogo, cfg.Icon or pillCfg.Icon or Assets.Logo)
	win._pillLogo = pillLogo
	if pillLogoIsImage then
		corner(pillLogo, UDim.new(1, 0))
		pillLogo.ScaleType = Enum.ScaleType.Crop
	end
	local pillLabel = mkText {
		Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -56, 1, 0), Text = pillTitle, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = pillLayer,
	}
	win._pillHint = mkText {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -16, .5, 0), Size = UDim2.fromOffset(90, PILL_H), Text = Touch and "tap to open" or "click to open",
		TextSize = 11, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 1, Parent = pillLayer,
	}
	local pillBtn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, PILL_H), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60, Parent = body,
	})
	win._pillBtn = pillBtn
	win._pillLayer = pillLayer

	local island = new("CanvasGroup", {
		Name = "Island", Position = UDim2.fromOffset(0, PILL_H), Size = UDim2.new(1, 0, 1, -PILL_H), BackgroundTransparency = 1,
		GroupTransparency = 1, Visible = false, ZIndex = 62, Parent = body,
	})
	win._islandLayer = island
	local ilist = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = island })
	pad(ilist, 12, 12, 2, 12)
	local ilayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = ilist })
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, LayoutOrder = 0, Parent = ilist })

	local avg = 1 / 60
	win:_listen("Render", function(dt)
		avg = avg * .9 + dt * .1
		win._fps = math.floor(1 / math.max(avg, .001) + .5)
	end)
	local builtin = {
		FPS = function() return tostring(win._fps or 0) end,
		Ping = function()
			local ok, v = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
			return (ok and v or 0) .. " ms"
		end,
		Time = function() return os.date(pillCfg.TimeFormat or "%H:%M") end,
		Players = function() return #Players:GetPlayers() .. " / " .. Players.MaxPlayers end,
	}
	local statValues, hasStats, hasActs = {}, false, false
	local names = pillCfg.Stats
	if names == nil then names = { "FPS", "Ping", "Time" } end
	if type(names) == "table" and #names > 0 then
		hasStats = true
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 1, Parent = ilist })
		local n = #names
		for i, s in ipairs(names) do
			local nameText, getter = s, builtin[s]
			if type(s) == "table" then nameText, getter = s.Name or "Stat", s.Get or s.Update end
			local chipF = new("Frame", {
				Position = UDim2.new((i - 1) / n, 3, 0, 0), Size = UDim2.new(1 / n, -6, 1, 0), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Parent = row,
			})
			corner(chipF, UDim.new(0, 10))
			stroke(chipF)
			local sc = new("UIScale", { Parent = chipF })
			mkText { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 14), Text = tostring(nameText), TextSize = 11, TextColor3 = Theme.Muted, Parent = chipF }
			local v = mkText { Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -20, 0, 18), Text = "…", TextSize = 14, TextColor3 = Theme.Accent, Parent = chipF }
			table.insert(statValues, { v, getter })
			table.insert(win._islandItems, sc)
		end
	end
	local function refreshStats()
		for _, e in ipairs(statValues) do
			if e[2] then
				local ok, r = pcall(e[2])
				if ok and r ~= nil then e[1].Text = tostring(r) end
			end
		end
	end
	win._refreshPillStats = refreshStats
	task.spawn(function()
		while not win._destroyed do
			if win._islandOpen then refreshStats() end
			task.wait(.5)
		end
	end)

	local acts = {}
	if pillCfg.Open ~= false then
		table.insert(acts, { Name = pillCfg.OpenText or "Open", Icon = "maximize-2", Primary = true, Callback = function() win:_expand() end })
	end
	for _, a in ipairs(pillCfg.Actions or {}) do table.insert(acts, a) end
	if #acts > 0 then
		hasActs = true
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 2, Parent = ilist })
		local n = #acts
		for i, a in ipairs(acts) do
			local primary = a.Primary == true
			local btn = new("TextButton", {
				Position = UDim2.new((i - 1) / n, 3, 0, 0), Size = UDim2.new(1 / n, -6, 1, 0),
				BackgroundColor3 = primary and Theme.Accent or Theme.Surface2, BackgroundTransparency = primary and .12 or 0,
				BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = row,
			})
			corner(btn, UDim.new(0, 9))
			local bst = stroke(btn, primary and Theme.Accent or Theme.Stroke, primary and .4 or 0)
			local sc = new("UIScale", { Parent = btn })
			local inner = new("Frame", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = btn,
			})
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = inner,
			})
			local ink = primary and Theme.AccentDark or Theme.Text
			if a.Icon then
				local box = iconBox(inner, a.Icon, ink, UDim2.new())
				box.LayoutOrder = 1
			end
			mkText {
				Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = a.Name or "Action", TextSize = 13, TextColor3 = ink,
				TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Parent = inner,
			}
			btn.MouseEnter:Connect(function()
				if primary then tween(btn, { BackgroundTransparency = 0 }, .15)
				else tween(bst, { Color = Theme.StrokeHover }, .15) end
			end)
			btn.MouseLeave:Connect(function()
				if primary then tween(btn, { BackgroundTransparency = .12 }, .25)
				else tween(bst, { Color = Theme.Stroke }, .25) end
				tween(sc, { Scale = 1 }, .5, SPRING)
			end)
			btn.MouseButton1Down:Connect(function() tween(sc, { Scale = .93 }, .1) end)
			btn.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, .55, SPRING) end)
			btn.MouseButton1Click:Connect(function()
				ripple(btn)
				win._islandTouched = os.clock()
				fire(a.Callback, win)
			end)
			table.insert(win._islandItems, sc)
		end
	end

	local panel = new("Frame", {
		Name = "PillPanel", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 3, Visible = false, Parent = ilist,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = panel })
	panel.ChildAdded:Connect(function(c) if c:IsA("GuiObject") then panel.Visible = true end end)
	win.PillPanel = panel
	if type(pillCfg.Build) == "function" then fire(pillCfg.Build, panel, win) end

	win._islandH = 1 + 14 + (hasStats and 54 or 0) + (hasActs and 42 or 0)
	local function measure()
		local h = math.ceil(ilayout.AbsoluteContentSize.Y / math.max(win.Scale.Scale, .01)) + 14
		if h > 20 and h ~= win._islandH then
			win._islandH = h
			if win._islandOpen then win:_applyIsland() end
		end
	end
	win._measureIsland = measure
	ilayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(measure)

	local function pillHover(on)
		if not win._pill or win._morphing or win._pillDragging then return end
		tween(win.BodyStroke, { Color = on and Theme.Accent or Theme.Stroke }, .2)
		tween(win._pillGlow, { ImageTransparency = on and .6 or (win._islandOpen and .75 or .88) }, .3)
		tween(pillLogo, { Rotation = on and 20 or 0, Size = on and UDim2.fromScale(1.15, 1.15) or UDim2.fromScale(1, 1) }, .5, SPRING)
		tween(pillLabel, { TextColor3 = on and Theme.Accent or Theme.Text }, .2)
	end
	pillBtn.MouseEnter:Connect(function() pillHover(true) end)
	pillBtn.MouseLeave:Connect(function()
		pillHover(false)
	end)
	pillBtn.MouseButton1Down:Connect(function()
		if win._pillPressTween then win._pillPressTween:Cancel(); win._pillPressTween = nil end
	end)
	pillBtn.MouseButton1Click:Connect(function()
		if win._dialog or win._dialogPillMode then return end
		if win._pillDragging or os.clock() - (win._pillStamp or 0) < .28 then return end
		if win._pill and not win._morphing then tween(scale, { Scale = 1 }, .5, SPRING) end
		if Touch and win.PillHover and not win._islandOpen then
			win:_setIsland(true)
			return
		end
		win:_expand()
	end)

	local pillDrag = makeDragger(root, scale, {
		pointer = function() return UIS:GetMouseLocation() end,
		base = function() return 1 end,
		lift = 1.05,
		onLift = function(on)
			tween(win.BodyStroke, { Color = on and Theme.Accent or Theme.Stroke }, .25)
			tween(win._pillGlow, { ImageTransparency = on and .45 or .88 }, .3)
			tween(win.Shadow, { ImageTransparency = on and .45 or .75 }, .3)
		end,
		onDrop = function() win:_finishPillDrag() end,
	})
	win._pillDrag = pillDrag
	local pillPress
	pillBtn.InputBegan:Connect(function(i)
		if isPress(i) and win._pill and not win._morphing then pillPress = UIS:GetMouseLocation() end
	end)
	table.insert(win._connections, UIS.InputEnded:Connect(function(i)
		if not isPress(i) then return end
		if pillDrag.Active then
			pillDrag:End()
			win._pillDragging = false
			win._pillStamp = os.clock()
		end
		pillPress = nil
	end))
	table.insert(win._frameSteps, function(dt)
		local startedNow = false
		if pillPress and not pillDrag.Active then
			if not win._pill or win._morphing then
				pillPress = nil
			elseif (UIS:GetMouseLocation() - pillPress).Magnitude > 3 then
				win._pillDragging = true
				win._pillStamp = os.clock()
				if win._posTween then win._posTween:Cancel(); win._posTween = nil end
				if win._sizeTween then win._sizeTween:Cancel(); win._sizeTween = nil end
				if win._pillPressTween then win._pillPressTween:Cancel(); win._pillPressTween = nil end
				scale.Scale = 1
				local w, h
				if win._islandOpen then
					w, h = win:_islandDims()
				else
					w, h = win._pillWidth, PILL_H
				end
				local dragCenter = root.AbsolutePosition + root.AbsoluteSize * root.AnchorPoint - win.Gui.AbsolutePosition
				root.Size = UDim2.fromOffset(w, h)
				root.Position = UDim2.fromOffset(dragCenter.X, dragCenter.Y)
				tween(pillLabel, { TextColor3 = Theme.Accent }, .2)
				pillDrag:Begin(UIS:GetMouseLocation(), dragCenter)
				startedNow = true
			end
		end
		if not startedNow then pillDrag:Step(dt) end
	end)

	local leaveAt
	table.insert(win._frameSteps, function()
		if not win._pill or win._morphing or win._pillDragging or os.clock() < (win._noHoverUntil or 0) then leaveAt = nil return end
		if win._dialogPillMode then
			leaveAt = nil
			win._islandTouched = os.clock()
			if not win._islandOpen then win:_setIsland(true) end
			return
		end
		if not win.PillHover then leaveAt = nil return end
		if Touch then
			if win._islandOpen and os.clock() - (win._islandTouched or 0) > 4 then win:_setIsland(false) end
			return
		end
		local m = mouse()
		local p, s = body.AbsolutePosition, body.AbsoluteSize
		local g = win._islandOpen and 8 or 0
		local over = m.X >= p.X - g and m.X <= p.X + s.X + g and m.Y >= p.Y - g and m.Y <= p.Y + s.Y + g
		if over then
			leaveAt = nil
			if not win._islandOpen then win:_setIsland(true) end
		elseif win._islandOpen then
			leaveAt = leaveAt or os.clock()
			if os.clock() - leaveAt > .2 then
				leaveAt = nil
				win:_setIsland(false)
			end
		end
	end)

	local holder = new("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 300, 1, -40),
		BackgroundTransparency = 1, Parent = gui,
	})
	local function sizeHolder() holder.Size = UDim2.new(0, math.min(300, gui.AbsoluteSize.X - 40), 1, -40) end
	table.insert(win._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeHolder))
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), Parent = holder })
	win.NotifyHolder = holder
	win._notifyOrder = 0
	win._toasts = {}
	win.MaxNotifications = cfg.MaxNotifications or 4

	win._controlsDirty = true
	table.insert(win._connections, body.DescendantAdded:Connect(function() win._controlsDirty = true end))
	table.insert(win._connections, body.DescendantRemoving:Connect(function() win._controlsDirty = true end))

	win:_enableDrag()
	win.MaxSize = cfg.MaxSize
	win.KeepOnScreen = cfg.KeepOnScreen ~= false
	win:_enableResize(cfg.MinSize or Vector2.new(560, 380))

	local saving = cfg.ConfigurationSaving
	if type(saving) == "table" and saving.Enabled ~= false then
		win.ConfigFolder = saving.FolderName or "AirflowUI"
		win.ConfigName = saving.FileName or "default"
		win._autoSaveEnabled = true
	else
		win.ConfigFolder = "AirflowUI"
		win.ConfigName = "default"
		win._autoSaveEnabled = false
	end
	win:_loadUISettings()
	win._uiSettingsReady = true
	win._persistedName = win.ConfigName

	table.insert(win._connections, UIS.InputBegan:Connect(function(i, processed)
		if processed then return end
		if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == win.Keybind then
			task.defer(function()
				local eaten = win._consumedKey == i.KeyCode and os.clock() - (win._consumedAt or 0) < .2
				win._consumedKey = nil
				if not eaten and not win._destroyed then win:Toggle() end
			end)
		end
	end))

	pcall(function() if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then syn.protect_gui(gui) end end)
	gui.Parent = cfg.Parent or getGuiParent()

	scale.Scale = .9
	body.GroupTransparency = 1
	shadow.ImageTransparency = 1
	win.BodyStroke.Transparency = 1
	root.Visible = false
	win:_fitToScreen(true)
	table.insert(win._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		win:_fitToScreen()
		win:_clampToScreen()
		if win._pill and not win._morphing and not win._pillDragging then win:_placePill(true) end
	end))

	win._introDone = false
	table.insert(Library.Windows, win)
	if cfg.Home then win:_buildHome(type(cfg.Home) == "table" and cfg.Home or {}) end
	if cfg.Settings == false then settingsBtn.Visible = false else win:_buildSettings() end

	local loading = cfg.Loading
	if type(loading) == "table" then
		cfg.LoadingDuration = loading.Duration or cfg.LoadingDuration
		cfg.LoadingText = loading.Text or loading.Subtitle or cfg.LoadingText
		cfg.LoadingSteps = loading.Steps or cfg.LoadingSteps
		cfg.LoadingTitle = loading.Title or cfg.LoadingTitle
		loading = loading.Enabled ~= false
	end
	if loading == false then
		task.defer(function() win:_playIntro() end)
	else
		win:_showLoader(cfg)
	end
	return win
end
Library.CreateWindow = Library.Window

function Library:Notify(o) local w = Library.Windows[#Library.Windows] if w then return w:Notify(o) end end
function Library:Confirm(o) local w = Library.Windows[#Library.Windows] if w then return w:Confirm(o) end end
function Library:Dialog(o) local w = Library.Windows[#Library.Windows] if w then return w:Dialog(o) end end

local function visibleThrough(gui, stop, point)
	local cur = gui
	while cur and cur ~= stop and cur:IsA("GuiObject") do
		if not cur.Visible then return false end
		local p = cur.Parent
		if p and p ~= stop and p:IsA("GuiObject") and (p.ClipsDescendants or p:IsA("ScrollingFrame")) and not inside(point, p) then return false end
		cur = p
	end
	return true
end

function Window:_refreshControls()
	local list = {}
	for _, d in ipairs(self.Main:GetDescendants()) do
		if d:IsA("GuiButton") or d:IsA("TextBox") or d:GetAttribute("NoDrag") then table.insert(list, d) end
	end
	self._controls = list
	self._controlsDirty = false
end

function Window:_overControl(point)
	if self._dialog or self._popupClose then return true end
	if self._controlsDirty then self:_refreshControls() end
	for _, c in ipairs(self._controls) do
		if c.Parent and inside(point, c) and visibleThrough(c, self.Main, point) then return true end
	end
	return false
end

function Window:_overFloat(point)
	for _, f in ipairs(self._floats) do
		if f.Root.Parent and inside(point, f.Root) then return true end
	end
	return false
end

function Window:_enableDrag()
	local drag = makeDragger(self.Root, self.Scale, {
		base = function() return self._fitScale or 1 end,
		lift = 1.014,
		tilt = false,
		tiltTarget = self.Root,
		tiltMax = 1.1,
		tiltMultiplier = .0011,
		onLift = function(on)
			tween(self.Shadow, { ImageTransparency = on and .4 or .6 }, .3)
			tween(self.BodyStroke, { Color = on and Theme.StrokeHover or Theme.Stroke }, .3)
		end,
		onDrop = function() task.delay(.05, function() self:_clampToScreen() end) end,
	})
	self._dragger = drag
	table.insert(self._connections, UIS.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		if not self.Open or self._pill or self._morphing or not self.Root.Visible then return end
		local m = mouse()
		if not inside(m, self.Body) or self:_overControl(m) or self:_overFloat(m) then return end
		drag:Begin()
	end))
	table.insert(self._connections, UIS.InputEnded:Connect(function(i)
		if drag.Active and isPress(i) then drag:End() end
	end))
	table.insert(self._frameSteps, function(dt) drag:Step(dt) end)
end

function Window:_enableResize(minSize)
	local maxSize = self.MaxSize or Vector2.new(math.huge, math.huge)
	local handle = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1,
		Active = true, ZIndex = 20, Parent = self.Root,
	})
	self.ResizeHandle = handle
	local glowImg = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, -16, .5, -16), Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 1,
		Image = "rbxassetid://120997033468887", ImageColor3 = Theme.Accent, ImageTransparency = .8, ZIndex = 20, Parent = handle,
	})
	local resizing = false
	local startSize = self.Root.Size
	local startMouse = Vector2.zero
	local pending
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			resizing = true
			startSize = self.Root.Size
			startMouse = mouse()
			tween(glowImg, { ImageTransparency = .35 }, .1)
		end
	end)
	handle.MouseEnter:Connect(function() if not resizing then tween(glowImg, { ImageTransparency = .35 }, .15) end end)
	handle.MouseLeave:Connect(function() if not resizing then tween(glowImg, { ImageTransparency = .8 }, .25) end end)
	table.insert(self._connections, UIS.InputEnded:Connect(function(i)
		if resizing and isPress(i) then
			resizing = false
			tween(glowImg, { ImageTransparency = .8 }, .25)
			if pending then
				self.Root.Size = UDim2.fromOffset(pending.X, pending.Y)
				pending = nil
			end
			self:_fitToScreen()
			self:_clampToScreen()
		end
	end))
	table.insert(self._frameSteps, function(dt)
		if not resizing then return end
		local d = (mouse() - startMouse) / self.Scale.Scale
		pending = Vector2.new(
			math.clamp(startSize.X.Offset + d.X * 2, minSize.X, maxSize.X),
			math.clamp(startSize.Y.Offset + d.Y * 2, minSize.Y, maxSize.Y)
		)
		local cur = Vector2.new(self.Root.Size.X.Offset, self.Root.Size.Y.Offset)
		local alpha = 1 - math.exp(-dt * 35)
		local p = cur:Lerp(pending, alpha)
		p = Vector2.new(math.floor(p.X + .5), math.floor(p.Y + .5))
		if p ~= cur then self.Root.Size = UDim2.fromOffset(p.X, p.Y) end
	end)
end

function Window:_fitToScreen(instant)
	local screen = self.Gui.AbsoluteSize
	if screen.X == 0 or screen.Y == 0 then return end
	local base = self._pill and self._fullSize or self.Root.Size
	local fit = math.min(1, (screen.X - 24) / math.max(base.X.Offset, 1), (screen.Y - 24) / math.max(base.Y.Offset, 1))
	self._fitScale = math.max(fit, .3)
	if self._introDone and self.Open and not self._pill and not self._morphing then
		if instant then self.Scale.Scale = self._fitScale else tween(self.Scale, { Scale = self._fitScale }, .25) end
	end
end

function Window:_clampToScreen()
	if not self.KeepOnScreen or self._pill or self._morphing then return end
	local screen = self.Gui.AbsoluteSize
	local r = self.Root
	local half = r.AbsoluteSize / 2
	local c = r.AbsolutePosition + half - self.Gui.AbsolutePosition
	local clamped = Vector2.new(
		math.clamp(c.X, math.min(half.X, screen.X / 2), math.max(screen.X - half.X, screen.X / 2)),
		math.clamp(c.Y, math.min(half.Y, screen.Y / 2), math.max(screen.Y - half.Y, screen.Y / 2))
	)
	if (clamped - c).Magnitude > .5 then tween(r, { Position = UDim2.fromOffset(clamped.X, clamped.Y) }, .4, SPRING) end
end

function Window:_closePopups()
	if self._popupClose then self._popupClose() end
end

function Window:_revealCards(tab, delay)
	if type(tab) ~= "table" or not tab.List or not tab.List.Parent then return end
	delay = delay or 0
	tab.List.CanvasPosition = Vector2.new(0, 0)
	local n = 0
	local function nextDelay()
		local d = delay + math.min(n, 14) * .035
		n += 1
		return d
	end
	for _, c in ipairs(tab.List:GetChildren()) do
		if c:IsA("GuiObject") then
			local left, right = c:FindFirstChild("Left"), c:FindFirstChild("Right")
			if c:IsA("Frame") and left and right then
				for _, side in ipairs({ left, right }) do
					for _, s in ipairs(side:GetChildren()) do
						if s:IsA("GuiObject") then popIn(s, nextDelay()) end
					end
				end
			else
				popIn(c, nextDelay())
			end
		end
	end
end

function Window:_wave()
	local rs = self.Root.AbsoluteSize
	local w = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = self.Root.Position, Size = UDim2.fromOffset(rs.X * .7, rs.Y * .7), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .5, ZIndex = 0, Parent = self.Gui,
	})
	tween(w, { Size = UDim2.fromOffset(rs.X * 1.9, rs.Y * 1.9), ImageTransparency = 1 }, 1.1, LIQUID)
	task.delay(1.15, function() w:Destroy() end)
end

function Window:_playIntro(fromLoader)
	if self._introDone then return end
	self._introDone = true
	task.delay(1, function()
		self._autoSaveReady = true
		if self._autoLoad and not self._autoLoaded and not self._destroyed then
			self._autoLoaded = true
			self:LoadConfig(self.ConfigName)
		end
	end)
	local root, body, shadow, scale = self.Root, self.Body, self.Shadow, self.Scale
	if self.CurrentTab then self:_revealCards(self.CurrentTab, fromLoader and .15 or .25) end
	root.Visible = true
	if fromLoader then
		scale.Scale = self._fitScale or 1
		root.Position = UDim2.fromScale(.5, .5)
		tween(body, { GroupTransparency = 0 }, .3)
		tween(self.BodyStroke, { Transparency = 0 }, .3)
		tween(shadow, { ImageTransparency = .6 }, .3)
	else
		root.Position = UDim2.new(.5, 0, .5, 24)
		tween(scale, { Scale = self._fitScale or 1 }, .7, SPRING)
		tween(root, { Position = UDim2.fromScale(.5, .5) }, .7, LIQUID)
		tween(body, { GroupTransparency = 0 }, .35)
		tween(self.BodyStroke, { Transparency = 0 }, .35)
		tween(shadow, { ImageTransparency = .6 }, .5)
	end

	self.BodyStroke.Color = Theme.Accent
	task.delay(.25, function() tween(self.BodyStroke, { Color = Theme.Stroke }, .9) end)
	self:_wave()
	for i, tab in ipairs(self.Tabs) do popIn(tab._button, .1 + i * .05, true) end
	self.Indicator.Visible = false
	self._indActive = false
	task.delay(.2 + #self.Tabs * .05, function()
		if self.CurrentTab then self:_placeIndicator(self.CurrentTab, true) end
	end)
end

function Window:_showLoader(cfg)
	local duration = cfg.LoadingDuration or 2.2
	local gui = self.Gui
	local blur = makeBlur()
	self._blur = blur
	if blur then tween(blur, { Size = 16 }, .8) end
	local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 9, Parent = gui })
	tween(dim, { BackgroundTransparency = .55 }, .7)

	local shell = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 18), Size = UDim2.fromOffset(330, 150), BackgroundTransparency = 1, ZIndex = 10, Parent = gui,
	})
	local shellScale = new("UIScale", { Scale = .9, Parent = shell })
	local cardShadow = new("ImageLabel", {
		Position = UDim2.fromOffset(-25, -25), Size = UDim2.new(1, 50, 1, 50), BackgroundTransparency = 1, Image = Assets.Shadow, ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), Parent = shell,
	})
	local card = new("CanvasGroup", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, GroupTransparency = 1, Parent = shell,
	})
	local cardCorner = corner(card, UDim.new(0, 14))
	local cardStroke = stroke(card, Theme.Stroke, 0)
	sheen(card)
	glow(card, UDim2.fromOffset(340, 150), UDim2.new(1, -20, 0, -20), .85, 90)
	glow(card, UDim2.fromOffset(260, 110), UDim2.new(0, 10, 1, 10), .88, 270)

	local ring = new("Frame", { Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, Parent = card })
	corner(ring, UDim.new(1, 0))
	local ringStroke = stroke(ring, Theme.Accent, 0, 2)
	local ringGrad = new("UIGradient", {
		Transparency = NumberSequence.new { NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.5, .9), NumberSequenceKeypoint.new(1, 0) }, Parent = ringStroke,
	})
	local ringSpin = TweenService:Create(ringGrad, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
	ringSpin:Play()
	local logoImg = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(.2, .2), Rotation = -20, BackgroundTransparency = 1,
		ImageColor3 = Theme.Accent, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, Parent = ring,
	})
	local introLogoIsImage = setIcon(logoImg, cfg.Icon or Assets.Logo)
	if introLogoIsImage then
		corner(logoImg, UDim.new(1, 0))
		logoImg.ScaleType = Enum.ScaleType.Crop
	end
	task.delay(.2, function()
		tween(logoImg, { Size = UDim2.fromScale(.68, .68), Rotation = 0, ImageTransparency = 0 }, .9, SPRING)
	end)

	local titleText = cfg.LoadingTitle or cfg.Title or "Airflow"
	local title = mkText {
		Position = UDim2.fromOffset(94, 28), Size = UDim2.new(1, -118, 0, 22), Text = titleText, TextSize = 20, MaxVisibleGraphemes = 0, Parent = card,
	}
	local status = mkText {
		Position = UDim2.fromOffset(94, 52), Size = UDim2.new(1, -118, 0, 16), Text = cfg.LoadingText or cfg.Subtitle or "Loading", TextSize = 13,
		FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextTransparency = 1, Parent = card,
	}
	local pct = mkText {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 1, -52), Size = UDim2.fromOffset(60, 16), Text = "0%", TextSize = 12,
		TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
	}
	local bar = new("Frame", {
		Position = UDim2.new(0, 24, 1, -30), Size = UDim2.new(1, -48, 0, 5), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = card,
	})
	corner(bar, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ClipsDescendants = true, Parent = bar })
	corner(fill, UDim.new(1, 0))
	local shine = new("Frame", {
		Position = UDim2.fromScale(-.5, 0), Size = UDim2.fromScale(.5, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = .5,
		BorderSizePixel = 0, ZIndex = 2, Parent = fill,
	})
	new("UIGradient", { Transparency = NumberSequence.new { NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, 1) }, Parent = shine })
	local shineTween = TweenService:Create(shine, TweenInfo.new(.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), { Position = UDim2.fromScale(1, 0) })
	shineTween:Play()
	local head = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(11, 11), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 3, Parent = bar,
	})
	corner(head, UDim.new(1, 0))
	local headGlow = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1,
		Image = Assets.Glow, ImageColor3 = Theme.Accent, ImageTransparency = .55, ZIndex = 2, Parent = head,
	})

	local function setStatus(t)
		tween(status, { TextTransparency = 1, Position = UDim2.fromOffset(84, 46) }, .12)
		task.delay(.12, function()
			if not card.Parent then return end
			status.Text = t
			status.Position = UDim2.fromOffset(84, 58)
			tween(status, { TextTransparency = 0, Position = UDim2.fromOffset(84, 52) }, .35, SPRING)
		end)
	end

	tween(card, { GroupTransparency = 0 }, .45)
	tween(shell, { Position = UDim2.fromScale(.5, .5) }, .7, LIQUID)
	tween(shellScale, { Scale = 1 }, .7, SPRING)
	tween(cardShadow, { ImageTransparency = .55 }, .5)
	task.delay(.25, function()
		tween(title, { MaxVisibleGraphemes = utf8.len(titleText) or #titleText }, .5, Enum.EasingStyle.Linear)
		tween(status, { TextTransparency = 0 }, .4)
	end)

	local alive = true
	local conn = RunService.RenderStepped:Connect(function()
		if not alive or not bar.Parent then return end
		local r = math.clamp(fill.Size.X.Scale, 0, 1)
		head.Position = UDim2.new(r, 0, .5, 0)
		pct.Text = string.format("%d%%", math.floor(r * 100 + .5))
	end)
	tween(fill, { Size = UDim2.fromScale(.86, 1) }, duration * .85, Enum.EasingStyle.Quart)
	task.spawn(loadIcons)
	task.spawn(loadNajaIcons)
	local steps = cfg.LoadingSteps or { "Preparing interface", "Loading icons", "Almost there" }
	for i, s in ipairs(steps) do
		if i == 1 then
			status.Text = s
		else
			task.delay(duration * (i - 1) / #steps, function() if alive and card.Parent then setStatus(s) end end)
		end
	end

	task.spawn(function()
		local rng = Random.new()
		while alive and card.Parent do
			local sz = rng:NextInteger(3, 9)
			local x = rng:NextNumber(.05, .95)
			local b = new("Frame", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(x, 0, 1, 10), Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = .7, BorderSizePixel = 0, ZIndex = 0, Parent = card,
			})
			corner(b, UDim.new(1, 0))
			local life = rng:NextNumber(1.3, 2.3)
			tween(b, { Position = UDim2.new(x + rng:NextNumber(-.06, .06), 0, rng:NextNumber(.05, .5), 0), BackgroundTransparency = 1 }, life, QUINT)
			task.delay(life + .05, function() b:Destroy() end)
			task.wait(.14)
		end
	end)

	local function cleanup()
		if blur then
			tween(blur, { Size = 0 }, .6)
			task.delay(.7, function() blur:Destroy() end)
		end
		self._blur = nil
	end

	task.delay(duration, function()
		tween(fill, { Size = UDim2.fromScale(1, 1) }, .3, QUINT)
		task.delay(.34, function()
			alive = false
			conn:Disconnect()
			ringSpin:Cancel()
			shineTween:Cancel()
			for _, o in ipairs({ title, status, pct }) do tween(o, { TextTransparency = 1 }, .15) end
			tween(ringStroke, { Transparency = 1 }, .15)
			tween(logoImg, { ImageTransparency = 1 }, .15)
			tween(bar, { BackgroundTransparency = 1 }, .15)
			tween(fill, { BackgroundTransparency = 1 }, .15)
			tween(head, { BackgroundTransparency = 1 }, .15)
			tween(headGlow, { ImageTransparency = 1 }, .15)
			tween(shine, { BackgroundTransparency = 1 }, .1)
			local fit = self._fitScale or 1
			local rs = self.Root.Size

			tween(shell, { Size = UDim2.fromOffset(rs.X.Offset * fit, rs.Y.Offset * fit), Position = UDim2.fromScale(.5, .5) }, .7, LIQUID)
			tween(cardCorner, { CornerRadius = UDim.new(0, 10) }, .7, LIQUID)
			tween(shellScale, { Scale = 1 }, .5)
			tween(dim, { BackgroundTransparency = 1 }, .6)
			cleanup()
			task.delay(.38, function()
				self:_playIntro(true)
				tween(card, { GroupTransparency = 1 }, .3)
				tween(cardStroke, { Transparency = 1 }, .2)
				tween(cardShadow, { ImageTransparency = 1 }, .2)
			end)
			task.delay(.85, function()
				shell:Destroy()
				dim:Destroy()
			end)
		end)
	end)
end

function Window:_islandDims()
	local screenW = self.Gui.AbsoluteSize.X
	local maxW = math.max(screenW - 24, self._pillWidth)
	local w = math.clamp(self._islandW or 320, self._pillWidth, maxW)
	if self._dialogPillWidth then w = math.clamp(math.max(w, self._dialogPillWidth), self._pillWidth, maxW) end
	local h = PILL_H + (self._islandH or 0)
	if self._dialogPillHeight then h = math.max(h, self._dialogPillHeight) end
	return w, h
end

function Window:_pillPos(w, h)
	local sc = self.Gui.AbsoluteSize
	local cx = self._pillCX or (sc.X / 2)
	local top = self._pillTop or PILL_TOP
	cx = math.clamp(cx, w / 2 + 8, math.max(sc.X - w / 2 - 8, w / 2 + 8))
	top = math.clamp(top, 8, math.max(sc.Y - h - 8, 8))
	return UDim2.fromOffset(cx, top + h / 2)
end

function Window:_placePill(animate)
	if not self._pill then return end
	local w, h
	if self._islandOpen then w, h = self:_islandDims() else w, h = self._pillWidth, PILL_H end
	local pos = self:_pillPos(w, h)
	if self._posTween then self._posTween:Cancel() end
	if animate then
		self._posTween = tween(self.Root, { Position = pos }, .6, SPRING)
	else
		self.Root.Position = pos
	end
end

function Window:_finishPillDrag()
	if self._sizeTween then self._sizeTween:Cancel(); self._sizeTween = nil end
	if self._posTween then self._posTween:Cancel(); self._posTween = nil end
	local c = self._pillDrag.Center()
	local w, h
	if self._islandOpen then w, h = self:_islandDims() else w, h = self._pillWidth, PILL_H end
	self.Root.Size = UDim2.fromOffset(w, h)
	self.Root.Position = UDim2.fromOffset(c.X, c.Y)
	self._pillCX = c.X
	self._pillTop = c.Y - h / 2
	self._noHoverUntil = os.clock() + .7
	self:_placePill(false)
end

function Window:_applyIsland(style)
	local w, h = self:_islandDims()
	if self._sizeTween then self._sizeTween:Cancel(); self._sizeTween = nil end
	if self._posTween then self._posTween:Cancel(); self._posTween = nil end
	if self._pillDragging then
		local c = self._pillDrag and self._pillDrag.Center()
		self.Root.Size = UDim2.fromOffset(w, h)
		if c then self.Root.Position = UDim2.fromOffset(c.X, c.Y) end
		return
	end
	self._sizeTween = tween(self.Root, { Size = UDim2.fromOffset(w, h) }, .6, style or SPRING)
	self._posTween = tween(self.Root, { Position = self:_pillPos(w, h) }, .6, style or SPRING)
end

function Window:_setIsland(on)
	if not self._pill or self._morphing or self._islandOpen == on then return end
	if self._sizeTween then self._sizeTween:Cancel(); self._sizeTween = nil end
	if self._posTween then self._posTween:Cancel(); self._posTween = nil end
	self._islandOpen = on
	local layer = self._islandLayer
	if on then
		self._islandTouched = os.clock()
		layer.Visible = true
		self._measureIsland()
		self:_refreshPillStats()
		self:_applyIsland(SPRING)
		tween(layer, { GroupTransparency = 0 }, .3)
		tween(self.BodyCorner, { CornerRadius = UDim.new(0, 22) }, .55, SPRING)
		tween(self._pillHint, { TextTransparency = 0 }, .3)
		tween(self._pillGlow, { ImageTransparency = .75 }, .4)
		tween(self.Shadow, { ImageTransparency = .5 }, .4)
		for i, sc in ipairs(self._islandItems) do
			sc.Scale = .8
			task.delay(.05 + i * .045, function()
				if self._islandOpen then tween(sc, { Scale = 1 }, .55, SPRING) end
			end)
		end
		task.delay(.05, function() if self._islandOpen then self._measureIsland() end end)
	else
		self._sizeTween = tween(self.Root, { Size = UDim2.fromOffset(self._pillWidth, PILL_H) }, .55, LIQUID)
		self._posTween = tween(self.Root, { Position = self:_pillPos(self._pillWidth, PILL_H) }, .55, LIQUID)
		tween(layer, { GroupTransparency = 1 }, .18)
		tween(self.BodyCorner, { CornerRadius = UDim.new(0, PILL_H / 2) }, .55, LIQUID)
		tween(self._pillHint, { TextTransparency = 1 }, .15)
		tween(self._pillGlow, { ImageTransparency = .88 }, .3)
		tween(self.Shadow, { ImageTransparency = .75 }, .4)
		task.delay(.25, function() if not self._islandOpen then layer.Visible = false end end)
	end
end

function Window:SetPillHover(v)
	self.PillHover = v ~= false
	if not self.PillHover then self:_setIsland(false) end
	self:_saveUISettings()
end

function Window:_collapse()
	if self._pill or self._morphing or not self._introDone then return end
	if self._pillLogo then
		tween(self._pillLogo, { Rotation = 0, Size = UDim2.fromScale(1, 1) }, .18, SPRING)
	end
	self._pill = true
	self._morphing = true
	self.Open = false
	self._islandOpen = false
	self._islandLayer.Visible = false
	self._islandLayer.GroupTransparency = 1
	self._pillHint.TextTransparency = 1
	self:_closePopups()
	local root = self.Root
	self._fullSize = root.Size
	self._restorePos = root.Position
	self.Main.Size = UDim2.fromOffset(self._fullSize.X.Offset, self._fullSize.Y.Offset)
	self.ResizeHandle.Visible = false
	tween(self.Main, { GroupTransparency = 1 }, .2)
	self._sizeTween = tween(root, { Size = UDim2.fromOffset(self._pillWidth, PILL_H) }, .75, LIQUID)
	self._posTween = tween(root, { Position = self:_pillPos(self._pillWidth, PILL_H) }, .75, LIQUID)
	tween(self.Scale, { Scale = 1 }, .6, SPRING)
	tween(self.BodyCorner, { CornerRadius = UDim.new(0, PILL_H / 2) }, .65, LIQUID)
	tween(self.Shadow, { ImageTransparency = .75 }, .5)
	task.delay(.22, function()
		if not self._pill then return end
		self._pillLayer.Visible = true
		tween(self._pillLayer, { GroupTransparency = 0 }, .35)
		tween(self._pillGlow, { ImageTransparency = .88 }, .4)
	end)
	task.delay(.6, function()
		self._morphing = false
		if self._pill then self._pillBtn.Visible = true end
	end)
end

function Window:_expand()
	if not self._pill or self._morphing then return end
	if self._pillLogo then
		tween(self._pillLogo, { Rotation = 0, Size = UDim2.fromScale(1, 1) }, .18, SPRING)
	end
	self._morphing = true
	self._pill = false
	self.Open = true
	self._islandOpen = false
	self._pillBtn.Visible = false
	local root = self.Root
	tween(self._islandLayer, { GroupTransparency = 1 }, .15)
	tween(self._pillHint, { TextTransparency = 1 }, .12)
	task.delay(.2, function() if not self._islandOpen then self._islandLayer.Visible = false end end)
	tween(self._pillLayer, { GroupTransparency = 1 }, .15)
	tween(self._pillGlow, { ImageTransparency = 1 }, .25)
	tween(self.BodyStroke, { Color = Theme.Stroke }, .25)
	tween(root, { Rotation = 0 }, .4, SPRING)
	tween(root, { Size = self._fullSize, Position = self._restorePos }, .75, LIQUID)
	tween(self.Scale, { Scale = self._fitScale or 1 }, .7, SPRING)
	tween(self.BodyCorner, { CornerRadius = UDim.new(0, 10) }, .65, LIQUID)
	tween(self.Shadow, { ImageTransparency = .6 }, .5)
	task.delay(.2, function() tween(self.Main, { GroupTransparency = 0 }, .4) end)
	task.delay(.15, function() self._pillLayer.Visible = false end)
	task.delay(.78, function()
		self.Main.Size = UDim2.fromScale(1, 1)
		self.ResizeHandle.Visible = true
		self._morphing = false
		self:_fitToScreen()
		self:_clampToScreen()
	end)
end
function Window:Toggle(state)
	if not self._introDone or self._morphing then return end
	if state == nil then state = not self.Open end
	if state == self.Open then return end
	if not state and self._quickOverlay and not self._quickOverlay.Closed then self._quickOverlay:Close() end
	if self.MobilePill then
		if state then self:_expand() else self:_collapse() end
		return
	end

	self.Open = state
	if state then
		self.Root.Visible = true
		tween(self.Scale, { Scale = self._fitScale or 1 }, .55, SPRING)
		tween(self.Body, { GroupTransparency = 0 }, .25)
		tween(self.BodyStroke, { Transparency = 0 }, .25)
		tween(self.Shadow, { ImageTransparency = .6 }, .3)
	else
		self:_closePopups()
		tween(self.Scale, { Scale = (self._fitScale or 1) * .94 }, .25, QUINT)
		tween(self.Body, { GroupTransparency = 1 }, .18)
		tween(self.BodyStroke, { Transparency = 1 }, .12)
		tween(self.Shadow, { ImageTransparency = 1 }, .18)
		task.delay(.22, function() if not self.Open then self.Root.Visible = false end end)
	end
end

function Window:SetMobilePill(enabled)
	enabled = enabled ~= false
	if not enabled and self._pill then self:_expand() end
	self.MobilePill = enabled
end

function Window:SetKeepOnScreen(v)
	self.KeepOnScreen = v ~= false
	if self.KeepOnScreen then self:_clampToScreen() end
	self:_saveUISettings()
end

function Window:SetKeybind(k)
	self.Keybind = k
	self._keyChipLabel.Text = keyName(k)
	self:_saveUISettings()
end

local function cfgPath(win, name) return win.ConfigFolder .. "/" .. name .. ".json" end
local function fileApi() return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" end
local function ensureFolder(f)
	if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(f) then makefolder(f) end
end

local function uiSettingsPath(win) return win.ConfigFolder .. "/_airflow_ui.settings" end
local function encodeFlag(obj)
	local kind, v = obj._type, obj:Get()
	if kind == "Keybind" then return { Type = kind, Value = v and v.Name or nil }
	elseif kind == "ColorPicker" then return { Type = kind, Value = { v.R, v.G, v.B } } end
	return { Type = kind, Value = v }
end
local function applyFlag(obj, data, silent)
	local kind, v = obj._type, data.Value
	if kind == "Keybind" then
		obj:Set(v and Enum.KeyCode[v] or nil, silent)
	elseif kind == "ColorPicker" then
		if type(v) == "table" then obj:Set(Color3.new(v[1], v[2], v[3]), silent) end
	elseif v ~= nil then
		obj:Set(v, silent)
	end
end

function Window:SaveConfig(name)
	name = name or self.ConfigName
	if not fileApi() then return false, "file API unavailable" end
	ensureFolder(self.ConfigFolder)
	local data = {}
	for flag, obj in pairs(Library.Flags) do
		if obj._type and type(obj.Get) == "function" then data[flag] = encodeFlag(obj) end
	end
	local ok, err = pcall(function() writefile(cfgPath(self, name), HttpService:JSONEncode(data)) end)
	if ok then
		self.ConfigName = name
		self._lastSaved = os.time()
		self:_fireConfig("save")
	end
	return ok, err
end

function Window:LoadConfig(name, silent)
	name = name or self.ConfigName
	if not fileApi() then return false, "file API unavailable" end
	local path = cfgPath(self, name)
	if not isfile(path) then return false, "no config named " .. name end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or type(data) ~= "table" then return false, "config is not valid JSON" end
	local prev = self._autoSaveEnabled
	self._autoSaveEnabled = false
	for flag, entry in pairs(data) do
		local obj = Library.Flags[flag]
		if obj and type(obj.Set) == "function" and type(entry) == "table" and entry.Type == obj._type then
			pcall(applyFlag, obj, entry, silent == true)
		end
	end
	self._autoSaveEnabled = prev
	self._autoSaveReady = true
	self.ConfigName = name
	self:_fireConfig("load")
	return true
end

function Window:DeleteConfig(name)
	if not fileApi() or type(delfile) ~= "function" then return false, "file API unavailable" end
	local path = cfgPath(self, name)
	if not isfile(path) then return false, "no config named " .. name end
	delfile(path)
	return true
end

function Window:ListConfigs()
	local out = {}
	if type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(self.ConfigFolder) then return out end
	for _, path in ipairs(listfiles(self.ConfigFolder)) do
		local n = path:match("([^/\\]+)%.json$")
		if n then table.insert(out, n) end
	end
	table.sort(out)
	return out
end

function Window:_autoSave()
	if not self._autoSaveEnabled or self._destroyed or not self._autoSaveReady then return end
	if self._autoSavePending then return end
	self._autoSavePending = true
	task.delay(self._autoSaveDelay or .5, function()
		self._autoSavePending = false
		if not self._destroyed then self:SaveConfig(self.ConfigName) end
	end)
end

function Window:ExportConfig()
	local data = {}
	for flag, obj in pairs(Library.Flags) do
		if obj._type and type(obj.Get) == "function" then data[flag] = encodeFlag(obj) end
	end
	return HttpService:JSONEncode(data)
end

function Window:_loadUISettings()
	if not fileApi() then return end
	local path = uiSettingsPath(self)
	local ok, data = pcall(function() if isfile(path) then return HttpService:JSONDecode(readfile(path)) end end)
	if not ok or type(data) ~= "table" then return end
	if type(data.AutoSave) == "boolean" then self._autoSaveEnabled = data.AutoSave end
	if type(data.AutoLoad) == "boolean" then self._autoLoad = data.AutoLoad end
	if type(data.ConfigName) == "string" and data.ConfigName ~= "" then self.ConfigName = data.ConfigName end
	if type(data.AutoSaveDelay) == "number" then self._autoSaveDelay = math.clamp(data.AutoSaveDelay, .1, 10) end
	if type(data.KeepOnScreen) == "boolean" then self.KeepOnScreen = data.KeepOnScreen end
	if type(data.PillHover) == "boolean" then self.PillHover = data.PillHover end
	if type(data.Language) == "string" and data.Language ~= "" then
		if Library._tr and Library._tr[data.Language] then
			Library._lang, Library._pendingLang = data.Language, nil
		else
			Library._pendingLang = data.Language -- applied as soon as that language gets registered
		end
	end
	if type(data.Keybind) == "string" then
		local okK, kc = pcall(function() return Enum.KeyCode[data.Keybind] end)
		if okK and kc then self:SetKeybind(kc) end
	end
end

function Window:_saveUISettings()
	if not self._uiSettingsReady or self._destroyed or not fileApi() then return end
	ensureFolder(self.ConfigFolder)
	pcall(function()
		writefile(uiSettingsPath(self), HttpService:JSONEncode({
			AutoSave = self._autoSaveEnabled == true, AutoLoad = self._autoLoad == true, ConfigName = self.ConfigName,
			AutoSaveDelay = self._autoSaveDelay or .5, KeepOnScreen = self.KeepOnScreen, PillHover = self.PillHover,
			Keybind = self.Keybind and self.Keybind.Name or nil,
			Language = Library._pendingLang or Library._lang,
		}))
	end)
end

function Window:_fireConfig(kind)
	for _, fn in ipairs(self._cfgListeners or {}) do pcall(fn, kind) end
	if self._uiSettingsReady and self._persistedName ~= self.ConfigName then
		self._persistedName = self.ConfigName
		self:_saveUISettings()
	end
end

local function emptyState(parent, icon, msg)
	local box = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, -10), Size = UDim2.fromOffset(200, 70), BackgroundTransparency = 1, Parent = parent })
	local img = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
		ImageColor3 = Theme.Muted, ImageTransparency = .15, ScaleType = Enum.ScaleType.Fit, Parent = box,
	})
	setIcon(img, icon)
	mkText {
		Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 16), Text = msg, TextSize = 13, FontFace = Fonts.Regular,
		TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = box,
	}
	return box
end

function Window:Tab(cfg, icon)
	cfg = norm(cfg, { Title = "Name", Description = "Desc" })
	if icon ~= nil and cfg.Icon == nil then cfg.Icon = icon end
	local tab = setmetatable({ Name = cfg.Name or "Tab", Window = self, _order = 0, _kind = "Tab" }, Container)

	local button = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		LayoutOrder = #self.Tabs + 1, Parent = self.TabList,
	})
	corner(button)
	local btnStroke = stroke(button, Theme.Stroke, 1)
	tab._button = button
	tab._stroke = btnStroke
	if cfg.Icon ~= nil then
		local img = new("ImageLabel", {
			AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 12, .5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
			ImageColor3 = Theme.Muted, ScaleType = Enum.ScaleType.Fit, Parent = button,
		})
		setIcon(img, cfg.Icon)
		tab._icon = img
	end
	tab._label = mkText {
		Position = UDim2.fromOffset(cfg.Icon ~= nil and 36 or 14, 0), Size = UDim2.new(1, cfg.Icon ~= nil and -44 or -22, 1, 0), Text = tab.Name,
		TextColor3 = Theme.Muted, Parent = button,
	}

	local page = new("Frame", { Name = tab.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false, Parent = self.Content })
	tab._page = page
	mkText { Position = UDim2.fromOffset(24, 20), Size = UDim2.new(1, -120, 0, 24), Text = tab.Name, TextSize = 22, ZIndex = 20, Parent = page }
	if cfg.Desc then
		mkText {
			Position = UDim2.fromOffset(24, 44), Size = UDim2.new(1, -120, 0, 16), Text = cfg.Desc, TextSize = 13, FontFace = Fonts.Regular,
			TextColor3 = Theme.Muted, ZIndex = 20, Parent = page,
		}
	end
	local top = cfg.Desc and 70 or 58
	local scroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 1, ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = .5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = page,
	})
	pad(scroll, 24, 24, 2, 24)
	new("Frame", {
		Name = "PageHeaderMask", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, top),
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 15, Parent = page,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = scroll })
	tab.List = scroll

	local empty = emptyState(page, cfg.Icon or "layout-grid", cfg.EmptyText or "Nothing here yet")
	local count = 0
	scroll.ChildAdded:Connect(function(c) if c:IsA("GuiObject") then count += 1 empty.Visible = false end end)
	scroll.ChildRemoved:Connect(function(c) if c:IsA("GuiObject") then count = math.max(count - 1, 0) empty.Visible = count <= 0 end end)
	empty.Visible = true

	button.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(button, { BackgroundTransparency = .4 }, .15)
			tween(btnStroke, { Transparency = .5 }, .15)
		end
	end)
	button.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then
			tween(button, { BackgroundTransparency = 1 }, .25)
			tween(btnStroke, { Transparency = 1 }, .25)
		end
	end)
	button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	local bscale = button:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function() tween(bscale, { Scale = .94 }, .1) end)
	button.MouseButton1Up:Connect(function() tween(bscale, { Scale = 1 }, .55, SPRING) end)
	button.MouseLeave:Connect(function() tween(bscale, { Scale = 1 }, .4, SPRING) end)
	if cfg.Hidden or not self._introDone then button.Visible = false end
	if cfg.Hidden then
		tab._hidden = true
		self.SettingsTab = tab
	else
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then task.defer(function() self:SelectTab(tab) end) end
	end
	return tab
end
Window.CreateTab = Window.Tab

function Window:_indicatorY(tab)
	local list = self.TabList
	return (tab._button.AbsolutePosition.Y - list.AbsolutePosition.Y + tab._button.AbsoluteSize.Y / 2) / self.Scale.Scale + list.Position.Y.Offset
end

function Window:_placeIndicator(tab, instant)
	-- only flags the move; the per-frame step in Library.Window animates it toward the live tab position
	local ind = self.Indicator
	self._indActive = true
	if not tab or tab._hidden then
		ind.Visible = false
		self._indSnap = "grow"
		return
	end
	if instant or not ind.Visible then
		self._indSnap = "grow"
		ind.Size = UDim2.fromOffset(3, 0)
		ind.Visible = true
	end
end

function Window:SelectTab(tab)
	if self.CurrentTab == tab then return end
	local prev = self.CurrentTab
	self.CurrentTab = tab
	self:_closePopups()
	self:_settleTransition()
	local gen = (self._transitionGeneration or 0) + 1
	self._transitionGeneration = gen
	if prev then
		tween(prev._button, { BackgroundTransparency = 1 }, .2)
		tween(prev._stroke, { Transparency = 1 }, .2)
		tween(prev._label, { TextColor3 = Theme.Muted }, .2)
		if prev._icon then tween(prev._icon, { ImageColor3 = Theme.Muted }, .2) end
		local out = self._outLayer
		prev._page.Parent = out
		self._outPage = prev._page
		out.GroupTransparency = 0
		out.Position = UDim2.fromOffset(0, 0)
		out.Visible = true
		tween(out, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -12) }, .22)
		task.delay(.22, function() if self._transitionGeneration == gen then self:_settleOut() end end)
	end
	tween(tab._button, { BackgroundTransparency = 0 }, .2)
	tween(tab._stroke, { Transparency = 0 }, .2)
	tween(tab._label, { TextColor3 = Theme.Text }, .2)
	if tab._icon then tween(tab._icon, { ImageColor3 = Theme.Accent }, .2) end
	if prev and not prev._hidden then self._returnTab = prev end
	self:_placeIndicator(tab)
	if self._settingsActive then self._settingsActive(tab._hidden == true) end
	local pg = tab._page
	pg.Position = UDim2.fromOffset(0, 0)
	pg.Visible = true
	pg.Parent = self._inLayer
	self._inPage = pg
	local layer = self._inLayer
	layer.GroupTransparency = 1
	layer.Position = UDim2.fromOffset(0, 22)
	layer.Visible = true
	tween(layer, { Position = UDim2.fromOffset(0, 0) }, .65, SPRING)
	tween(layer, { GroupTransparency = 0 }, .3)
	if self._introDone then self:_revealCards(tab, .05) end
	task.delay(.7, function() if self._transitionGeneration == gen then self:_settleIn() end end)
end
function Window:_settleOut()
	local p = self._outPage
	if p then
		p.Parent = self.Content
		p.Visible = false
		self._outPage = nil
	end
	self._outLayer.Visible = false
end
function Window:_settleIn()
	local p = self._inPage
	if p then
		p.Parent = self.Content
		p.Position = UDim2.fromOffset(0, 0)
		self._inPage = nil
	end
	self._inLayer.Visible = false
end
function Window:_settleTransition()
	self:_settleOut()
	self:_settleIn()
end

function Window:Dialog(cfg)
	cfg = norm(cfg, { Text = "Content", Message = "Content" })
	self._dialogGeneration = (self._dialogGeneration or 0) + 1
	local dialogGeneration = self._dialogGeneration
	local autoCollapse = self._dialogAutoCollapse == true
	local pillIslandDialog = self._dialogPillMode == true and not self.Open and self._pill == true

	if not self.Open then
		if self.MobilePill and self._pill then
			if self._morphing then
				self._morphing = false
				if self._sizeTween then self._sizeTween:Cancel(); self._sizeTween = nil end
				if self._posTween then self._posTween:Cancel(); self._posTween = nil end
			end
			self._dialogPillMode = true
			pillIslandDialog = true
			self._islandTouched = os.clock()
			self:_setIsland(true)
			autoCollapse = true
		else
			-- If there is no active pill, show the ordinary window so the dialog stays inside it.
			self.Open = true
			self.Root.Visible = true
			tween(self.Scale, { Scale = self._fitScale or 1 }, .45, SPRING)
			tween(self.Body, { GroupTransparency = 0 }, .22)
			tween(self.BodyStroke, { Transparency = 0 }, .22)
			tween(self.Shadow, { ImageTransparency = .6 }, .22)
			autoCollapse = true
		end
	end
	if autoCollapse then self._dialogAutoCollapse = true end
	if self._dialog then self._dialog.Close() end

	local dialogParent = self.Body
	local viewportWidth = 300
	if pillIslandDialog then
		local screenW = self.Gui and self.Gui.AbsoluteSize.X or 0
		local availableW = screenW > 100 and math.max(screenW - 24, 220) or (self._islandW or 320)
		viewportWidth = math.min(self._islandW or 320, availableW)
	elseif autoCollapse and self._fullSize and self._fullSize.X.Offset > 0 then
		viewportWidth = self._fullSize.X.Offset
	elseif self.Root and self.Root.Size.X.Offset > 0 and not self._pill then
		viewportWidth = self.Root.Size.X.Offset
	elseif self.Body and self.Body.AbsoluteSize.X > 0 then
		viewportWidth = self.Body.AbsoluteSize.X / math.max(self.Scale.Scale, .01)
	end
	local dialogWidth = math.clamp(math.min(300, viewportWidth - 24), 220, 300)
	local P = 18
	local backdrop = new("TextButton", {
		Name = "DialogBackdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 70, Parent = dialogParent,
	})
	local liquidGlow = new("ImageLabel", {
		Name = "LiquidBloom", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(220, 150), BackgroundTransparency = 1, Image = Assets.Glow,
		ImageColor3 = Theme.Accent, ImageTransparency = 1, ZIndex = 70, Parent = backdrop,
	})
	local liquidGlowScale = new("UIScale", { Scale = .62, Parent = liquidGlow })
	local box = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 22), Size = UDim2.fromOffset(dialogWidth, 120), BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 71, Parent = backdrop,
	})
	corner(box, UDim.new(0, 12))
	local boxStroke = stroke(box, Theme.Stroke, 1)
	local boxScale = new("UIScale", { Scale = .78, Parent = box })
	local fades, iconOff = {}, 0
	if cfg.Icon then
		local frame, img = iconBox(box, cfg.Icon, Theme.Accent, UDim2.new(0, P, 0, P + 9))
		img.ImageTransparency = 1
		frame.ZIndex = 72
		img.ZIndex = 72
		table.insert(fades, { img, "ImageTransparency", 0 })
		iconOff = 24
	end
	local titleLbl = mkText {
		Position = UDim2.fromOffset(P + iconOff, P), Size = UDim2.new(1, -(P * 2 + iconOff), 0, 18), Text = cfg.Title or "Are you sure?", TextSize = 15,
		TextTransparency = 1, ZIndex = 72, Parent = box,
	}
	table.insert(fades, { titleLbl, "TextTransparency", 0 })
	local bodyH = 0
	local buttonRow
	local function layoutBox()
		box.Size = UDim2.fromOffset(dialogWidth, P + 24 + bodyH + 12 + 34 + P)
		if buttonRow then buttonRow.Position = UDim2.fromOffset(P, P + 24 + bodyH + 12) end
		if pillIslandDialog and self._dialogPillMode and self._pill then
			self._dialogPillHeight = math.max(PILL_H + (self._islandH or 0), box.Size.Y.Offset + 30)
			if self._islandOpen then self:_applyIsland(LIQUID) end
		end
	end
	if cfg.Content then
		local lbl = mkText {
			Position = UDim2.fromOffset(P, P + 24), Size = UDim2.new(1, -P * 2, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Content,
			TextSize = 13, FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextWrapped = true, TextTransparency = 1,
			TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 72, Parent = box,
		}
		table.insert(fades, { lbl, "TextTransparency", 0 })
		bodyH = math.max(lbl.TextBounds.Y, 16) + 6
		lbl:GetPropertyChangedSignal("TextBounds"):Connect(function()
			local n = math.max(lbl.TextBounds.Y, 16) + 6
			if n ~= bodyH then bodyH = n layoutBox() end
		end)
	end
	buttonRow = new("Frame", { Name = "ButtonRow", Size = UDim2.new(1, -P * 2, 0, 34), BackgroundTransparency = 1, ZIndex = 72, Parent = box })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8), Parent = buttonRow,
	})
	layoutBox()
	if pillIslandDialog then
		local screenW = self.Gui and self.Gui.AbsoluteSize.X or 0
		local maxW = math.max(screenW - 24, self._pillWidth or 120)
		self._dialogPillWidth = math.clamp(math.max(self._islandW or 320, dialogWidth + 24), self._pillWidth or 120, maxW)
		self._dialogPillHeight = math.max(PILL_H + (self._islandH or 0), box.Size.Y.Offset + 30)
		self._islandTouched = os.clock()
		self:_applyIsland(LIQUID)
	end

	local api, closed = {}, false
	function api.Close()
		if closed then return end
		closed = true
		if self._dialog == api then self._dialog = nil end
		tween(backdrop, { BackgroundTransparency = 1 }, .22)
		tween(box, { BackgroundTransparency = 1, Position = UDim2.new(.5, 0, .5, 10) }, .22)
		tween(boxScale, { Scale = .94 }, .22)
		tween(boxStroke, { Transparency = 1 }, .15)
		for _, f in ipairs(fades) do tween(f[1], { [f[2]] = 1 }, .15) end
		tween(liquidGlow, { ImageTransparency = 1 }, .15)
		tween(liquidGlowScale, { Scale = .7 }, .2, LIQUID)
		task.delay(.25, function()
			if backdrop.Parent then backdrop:Destroy() end
		end)
		if autoCollapse then
			task.delay(.31, function()
				if self._destroyed or self._dialogGeneration ~= dialogGeneration or self._dialog then return end
				if not self._dialogAutoCollapse then return end
				self._dialogAutoCollapse = false
				if self._dialogPillMode then
					self._dialogPillMode = false
					self._dialogPillWidth, self._dialogPillHeight = nil, nil
					if self._pill and self._islandOpen then self:_setIsland(false) end
				elseif self.Open then
					self:Toggle(false)
				end
			end)
		end
	end

	for i, b in ipairs(cfg.Buttons or {}) do
		local primary = b.Variant == "Primary"
		local btn = new("TextButton", {
			Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = primary and Theme.Accent or Theme.Surface2,
			BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true, LayoutOrder = i, ZIndex = 73, Parent = buttonRow,
		})
		corner(btn, UDim.new(0, 8))
		local bs = stroke(btn, primary and Theme.Accent or Theme.Stroke, 1)
		pad(btn, 14, 14)
		local lbl = mkText {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = b.Title or b.Name or "OK", TextSize = 13,
			TextColor3 = primary and Theme.AccentDark or Theme.Text, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, ZIndex = 74, Parent = btn,
		}
		local bgT, stT = primary and .12 or 0, primary and .4 or 0
		table.insert(fades, { btn, "BackgroundTransparency", bgT })
		table.insert(fades, { bs, "Transparency", stT })
		table.insert(fades, { lbl, "TextTransparency", 0 })
		local bscale = new("UIScale", { Parent = btn })
		btn.MouseEnter:Connect(function()
			if closed then return end
			if primary then
				tween(btn, { BackgroundTransparency = 0 }, .15)
				tween(bs, { Transparency = 0 }, .15)
			else
				tween(bs, { Color = Theme.StrokeHover }, .15)
			end
		end)
		btn.MouseLeave:Connect(function()
			if closed then return end
			tween(bscale, { Scale = 1 }, .4, SPRING)
			if primary then
				tween(btn, { BackgroundTransparency = bgT }, .25)
				tween(bs, { Transparency = stT }, .25)
			else
				tween(bs, { Color = Theme.Stroke }, .25)
			end
		end)
		btn.MouseButton1Down:Connect(function() tween(bscale, { Scale = .94 }, .1) end)
		btn.MouseButton1Click:Connect(function()
			ripple(btn)
			api.Close()
			fire(b.Callback)
		end)
	end
	local hasDialogButtons = type(cfg.Buttons) == "table" and #cfg.Buttons > 0
	if cfg.CloseOnBackdrop == true or (cfg.CloseOnBackdrop ~= false and (not pillIslandDialog or not hasDialogButtons)) then
		backdrop.MouseButton1Click:Connect(function()
			api.Close()
			fire(cfg.OnCancel)
		end)
	end
	self._dialog = api
	tween(backdrop, { BackgroundTransparency = .45 }, .3, LIQUID)
	tween(liquidGlow, { ImageTransparency = .84 }, .2, LIQUID)
	tween(liquidGlowScale, { Scale = 1.48 }, .68, LIQUID)
	task.delay(.18, function()
		if not closed and liquidGlow.Parent then tween(liquidGlow, { ImageTransparency = 1 }, .48, LIQUID) end
	end)
	tween(box, { BackgroundTransparency = 0, Position = UDim2.fromScale(.5, .5) }, .55, LIQUID)
	tween(boxStroke, { Transparency = 0 }, .25)
	tween(boxScale, { Scale = 1.035 }, .4, LIQUID)
	task.delay(.32, function()
		if not closed and boxScale.Parent then tween(boxScale, { Scale = 1 }, .38, SPRING) end
	end)
	for _, f in ipairs(fades) do tween(f[1], { [f[2]] = f[3] }, .3) end
	return api
end

function Window:Confirm(cfg)
	cfg = norm(cfg, { Text = "Content", Message = "Content" })
	return self:Dialog {
		Title = cfg.Title or "Are you sure?", Content = cfg.Content, Icon = cfg.Icon, OnCancel = cfg.OnCancel,
		Buttons = {
			{ Title = cfg.CancelText or "Cancel", Callback = cfg.OnCancel },
			{ Title = cfg.ConfirmText or "Confirm", Variant = "Primary", Callback = cfg.Callback },
		},
	}
end

function Window:_listen(kind, fn, owner)
	local list = self._inputListeners[kind]
	table.insert(list, fn)
	local function remove()
		for i, f in ipairs(list) do
			if f == fn then table.remove(list, i) break end
		end
	end
	if owner then
		owner._listeners = owner._listeners or {}
		table.insert(owner._listeners, remove)
	end
	return remove
end

function Window:Notify(cfg)
	cfg = norm(cfg, { Text = "Content", Message = "Content", Image = "Icon" })
	local duration = cfg.Duration or 4
	local kind = cfg.Type or "Info"
	local color = ToastColors[kind] or Theme.Accent
	local iconName = cfg.Icon or ToastIcons[kind] or "bell"
	self._notifyOrder += 1
	-- _Handoff (internal, used by the key system): the real toast is built hidden, already at its resting
	-- spot, so the key window can liquid-split into it. :Reveal() plays the normal fade-in and starts the timer.
	local handoff = cfg._Handoff == true
	local revealed = not handoff

	local slot = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = self._notifyOrder, Parent = self.NotifyHolder })
	local shell = new("Frame", {
		Position = UDim2.fromOffset(handoff and 0 or 340, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = slot,
	})
	local shadow = new("ImageLabel", {
		Position = UDim2.fromOffset(-20, -20), Size = UDim2.new(1, 40, 1, 40), BackgroundTransparency = 1, Image = Assets.Shadow, ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0, Parent = shell,
	})
	local card = new("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Background, BorderSizePixel = 0, GroupTransparency = 1, Parent = shell,
	})
	local cardScale = new("UIScale", { Scale = handoff and 1 or .9, Parent = card })
	corner(card, UDim.new(0, 12))
	local cardStroke = stroke(card, Theme.Stroke)
	sheen(card)
	local tint = glow(card, UDim2.fromOffset(240, 110), UDim2.new(0, 10, 0, 0), .86, 90)
	tint.ImageColor3 = color

	local inner = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
	pad(inner, 14, 14, 14, 24)
	local badge = new("Frame", { Size = UDim2.fromOffset(30, 30), BackgroundColor3 = color, BackgroundTransparency = .86, BorderSizePixel = 0, Parent = inner })
	corner(badge, UDim.new(1, 0))
	stroke(badge, color, .7)
	local badgeIcon = new("ImageLabel", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1,
		ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, Parent = badge,
	})
	setIcon(badgeIcon, iconName)
	mkText {
		Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -42 - 22, 0, 18), Text = cfg.Title or "Notification", TextSize = 14, Parent = inner,
	}
	if cfg.Content then
		mkText {
			Position = UDim2.fromOffset(42, 21), Size = UDim2.new(1, -42, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Content, TextSize = 13,
			FontFace = Fonts.Regular, TextColor3 = Theme.Muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top, Parent = inner,
		}
	end
	local closeBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -6), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "×",
		TextColor3 = Theme.Muted, TextSize = 22, FontFace = Fonts.Bold, AutoButtonColor = false, Parent = inner,
	})
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { TextColor3 = Theme.Text }, .15) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { TextColor3 = Theme.Muted }, .2) end)

	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.new(1, -28, 0, 3), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = card,
	})
	corner(track, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track })
	corner(fill, UDim.new(1, 0))

	local dismissed = false
	local function syncHeight()
		if dismissed then return end
		if handoff then
			slot.Size = UDim2.new(1, 0, 0, shell.AbsoluteSize.Y)
		else
			tween(slot, { Size = UDim2.new(1, 0, 0, shell.AbsoluteSize.Y) }, .5, SPRING)
		end
	end
	shell:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncHeight)
	task.defer(syncHeight)

	local function playEnter()
		if not handoff then tween(shell, { Position = UDim2.fromOffset(0, 0) }, .75, SPRING) end
		tween(card, { GroupTransparency = 0 }, handoff and .26 or .35)
		if not handoff then tween(cardScale, { Scale = 1 }, .7, SPRING) end
		tween(shadow, { ImageTransparency = .6 }, .4)
		task.delay(.2, function() tween(badgeIcon, { Size = UDim2.fromOffset(16, 16) }, .6, SPRING) end)
	end
	if not handoff then playEnter() end

	local function dismiss()
		if dismissed then return end
		dismissed = true
		for i, fn in ipairs(self._toasts) do
			if fn == dismiss then table.remove(self._toasts, i) break end
		end
		tween(shell, { Position = UDim2.fromOffset(340, 0) }, .45, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(card, { GroupTransparency = 1 }, .3)
		tween(cardScale, { Scale = .92 }, .3)
		tween(cardStroke, { Transparency = 1 }, .2)
		tween(shadow, { ImageTransparency = 1 }, .25)
		task.delay(.32, function()
			slot.ClipsDescendants = true
			tween(slot, { Size = UDim2.new(1, 0, 0, -8) }, .35, QUINT)
			task.delay(.37, function() slot:Destroy() end)
		end)
	end

	local remaining, startedAt, timerId, runningTween = duration, 0, 0, nil
	local function startTimer()
		timerId += 1
		local id = timerId
		startedAt = os.clock()
		runningTween = tween(fill, { Size = UDim2.fromScale(0, 1) }, remaining, Enum.EasingStyle.Linear)
		task.delay(remaining, function() if id == timerId then dismiss() end end)
	end
	local function pauseTimer()
		timerId += 1
		if runningTween then runningTween:Cancel() end
		remaining = math.max(remaining - (os.clock() - startedAt), .6)
	end
	card.MouseEnter:Connect(function()
		if dismissed or not revealed then return end
		pauseTimer()
		tween(cardStroke, { Color = color }, .2)
		tween(cardScale, { Scale = 1.02 }, .4, SPRING)
	end)
	card.MouseLeave:Connect(function()
		if dismissed or not revealed then return end
		tween(cardStroke, { Color = Theme.Stroke }, .3)
		tween(cardScale, { Scale = 1 }, .4, SPRING)
		startTimer()
	end)
	if not handoff then startTimer() end
	closeBtn.MouseButton1Click:Connect(dismiss)

	table.insert(self._toasts, dismiss)
	while #self._toasts > self.MaxNotifications do
		local oldest = table.remove(self._toasts, 1)
		oldest()
	end
	local function reveal()
		if revealed or dismissed then return end
		revealed = true
		playEnter()
		startTimer()
	end
	return { Dismiss = dismiss, Reveal = reveal, Card = card }
end

function Window:_buildHome(cfg)
	local tab = self:Tab { Name = cfg.Name or "Home", Desc = cfg.Desc, Icon = cfg.Icon or "house" }
	local list = tab.List
	local pages = cfg.Pages or cfg.Tabs

	local greeting = cfg.Greeting
	if greeting == nil then
		local hour = tonumber(os.date("%H")) or 12
		greeting = "Good " .. (hour < 12 and "morning" or (hour < 18 and "afternoon" or "evening")) .. "."
	end
	local profile = new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, LayoutOrder = tab:_nextOrder(), Parent = list })
	profile:SetAttribute("NoDrag", true)
	corner(profile)
	stroke(profile)
	local avatar = new("ImageLabel", { Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = profile })
	corner(avatar, UDim.new(0, 8))
	stroke(avatar)
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and img then avatar.Image = img end
	end)
	mkText { Position = UDim2.fromOffset(58, 11), Size = UDim2.new(1, -72, 0, 18), Text = (cfg.Welcome or "Hello, ") .. LocalPlayer.DisplayName, TextSize = 15, Parent = profile }
	mkText {
		Position = UDim2.fromOffset(58, 30), Size = UDim2.new(1, -72, 0, 16), Text = greeting, TextSize = 13, FontFace = Fonts.Regular,
		TextColor3 = Theme.Muted, Parent = profile,
	}

	local stats
	if cfg.Sections ~= false then
		tab:Header(cfg.SectionName or "System info")
		local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = tab:_nextOrder(), Parent = list })
		new("UIGridLayout", { CellSize = UDim2.new(.5, -4, 0, 62), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
		local want = {}
		for _, n in ipairs(cfg.Stats or { "FPS", "Ping", "Executor", "Game", "Region", "Time" }) do want[n] = true end
		local order = 0
		local function stat(key, icon, label)
			if not want[key] then return nil end
			order += 1
			local card = new("Frame", { Size = UDim2.new(.5, -4, 0, 62), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, LayoutOrder = order, Parent = grid })
			corner(card)
			stroke(card)
			card:SetAttribute("NoDrag", true)
			if icon then iconBox(card, icon, Theme.Muted, UDim2.new(0, 14, 0, 21)) end
			mkText { Position = UDim2.fromOffset(icon and 36 or 14, 12), Size = UDim2.new(1, -(icon and 50 or 28), 0, 16), Text = label, TextSize = 12, TextColor3 = Theme.Muted, Parent = card }
			return mkText { Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 18), Text = "…", TextSize = 15, Parent = card }
		end
		local fps = stat("FPS", "activity", "FPS")
		local ping = stat("Ping", "wifi", "Ping")
		local exec = stat("Executor", "terminal", "Executor")
		local gname = stat("Game", "gamepad-2", "Game")
		local region = stat("Region", "globe", "Server region")
		local clock = stat("Time", "clock", "Time of day")
		local players = stat("Players", "users", "Players")
		local uptime = stat("Uptime", "timer", "Session")
		if exec then exec:SetAttribute("AF_NoTranslate", true) exec.Text = identifyExecutor() end
		if gname then
			gname:SetAttribute("AF_NoTranslate", true)
			gname.Text = "Loading"
			task.spawn(function() gname.Text = gameName() end)
		end
		if region then
			region:SetAttribute("AF_NoTranslate", true)
			region.Text = "Loading"
			fetchRegion(function(r) region.Text = r end)
		end
		local frames, started = 0, os.clock()
		self:_listen("Render", function() frames += 1 end)
		task.spawn(function()
			while not self._destroyed and tab.List.Parent and tab._page.Parent do
				if not self.Open or self.CurrentTab ~= tab then
					frames = 0
					task.wait(1)
					continue
				end
				if fps then fps.Text = tostring(frames) end
				frames = 0
				if ping then
					local ok, v = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
					ping.Text = (ok and v or 0) .. " ms"
				end
				if clock then clock.Text = os.date(cfg.TimeFormat or "%H:%M") end
				if players then players.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers end
				if uptime then
					local s = math.floor(os.clock() - started)
					uptime.Text = string.format("%d:%02d", math.floor(s / 60), s % 60)
				end
				task.wait(1)
			end
		end)
	end

	if type(pages) == "table" and #pages > 0 then
		local pg = tab:Pages {}
		for _, p in ipairs(pages) do
			local page = pg:Page { Name = p.Name or p.Title or "Page", Icon = p.Icon }
			if type(p.Content) == "string" then page:Paragraph { Name = "", Content = p.Content } end
			if type(p.Entries) == "table" then
				for _, e in ipairs(p.Entries) do
					local body = e.Content or e.Body
					if type(e.Changes) == "table" then body = "• " .. table.concat(e.Changes, "\n• ") end
					local head = e.Title or e.Version or "Update"
					if e.Tag or e.Date then head = head .. "  ·  " .. (e.Tag or e.Date) end
					page:Paragraph { Name = head, Content = body or "" }
				end
			end
			if type(p.Build) == "function" then fire(p.Build, page) end
		end
	end
	tab._order = math.max(tab._order, 10)
	self.Home = tab
	return tab
end

function Window:OpenSettings()
	if self.SettingsTab and self.CurrentTab ~= self.SettingsTab then self:SelectTab(self.SettingsTab) end
end
function Window:CloseSettings()
	if not self.SettingsTab or self.CurrentTab ~= self.SettingsTab then return end
	local back = self._returnTab or self.Tabs[1]
	if back then self:SelectTab(back) end
end
function Window:ToggleSettings()
	if self.CurrentTab == self.SettingsTab then self:CloseSettings() else self:OpenSettings() end
end
function Window:SetTheme(theme) return Library:SetTheme(theme) end
function Window:SetAccent(color) return Library:SetAccent(color) end

function Window:_buildSettings()
	local win = self
	local tab = self:Tab { Name = "Settings", Desc = "Interface, theme and configuration", Icon = "settings", Hidden = true }

	tab:ConfigPanel { Name = "Configurations" }

	tab:Header("Language", "languages")
	local langDrop = tab:Dropdown {
		Name = "Interface language", Desc = "Choose the language you are most comfortable with", Options = Library:GetLanguages(),
		Default = Library._lang, Style = "Popup", Quickable = false,
		Callback = function(v) if v then Library:SetLanguage(v) end end,
	}
	table.insert(Library._onLang, function(name)
		if win._destroyed then return end
		langDrop:Set(name, true)
	end)

	tab:Header("Theme", "palette")
	local themeDrop = tab:Dropdown {
		Name = "Theme", Desc = "Recolors the window, popups and floating panels", Options = Library:GetThemes(),
		Default = Library._themeState.Preset, Style = "Popup", SearchAfter = 99, Quickable = false,
		Callback = function(v) if v then Library:SetTheme(v, false, "dropdown") end end,
	}
	local accent = tab:ColorPicker {
		Name = "Accent color", Desc = "Overrides the accent of the current theme", Default = Library:GetPalette().Accent,
		Callback = function(c) Library:SetAccent(c, false, "picker") end,
	}
	tab:Button {
		Name = "Reset accent", Desc = "Go back to the accent of the selected theme", Icon = "rotate-ccw", Quickable = false,
		Callback = function() Library:SetAccent(nil, false, "reset") end,
	}
	table.insert(Library._onTheme, function(source)
		if win._destroyed then return end
		local pal = Library:GetPalette()
		if source ~= "dropdown" then themeDrop:Set(Library._themeState.Preset, true) end
		if source ~= "picker" then accent:Set(pal.Accent, true) end
	end)

	tab:Header("Interface", "layout-dashboard")
	tab:Keybind {
		Name = "Menu key", Desc = "Show or hide the window", Default = self.Keybind, Flag = "AF_MenuKey", Quickable = false,
		OnChanged = function(k)
			if k then win:SetKeybind(k) end
			win:_autoSave()
		end,
	}
	tab:Toggle {
		Name = "Keep on screen", Desc = "Stops the window from being dragged out of view", Default = self.KeepOnScreen, Flag = "AF_KeepOnScreen", Quickable = false,
		Callback = function(v)
			win.KeepOnScreen = v ~= false
			if win._introDone and win.KeepOnScreen then win:_clampToScreen() end
		end,
	}
	tab:Toggle {
		Name = "Collapse to pill", Desc = "Menu key and close button shrink the window into a floating pill", Default = self.MobilePill, Flag = "AF_Pill", Quickable = false,
		Callback = function(v) if v ~= win.MobilePill then win:SetMobilePill(v) end end,
	}
	tab:Stepper {
		Name = "Max notifications", Desc = "How many toasts can stack at once", Min = 1, Max = 8, Step = 1, Default = self.MaxNotifications,
		Flag = "AF_MaxToasts", Quickable = false, Callback = function(v) win.MaxNotifications = v end,
	}
	tab:Button {
		Name = "Test notification", Desc = "Preview the current theme in a toast", Icon = "bell", Quickable = false,
		Callback = function() win:Notify { Title = "Airflow", Content = "Notifications use the active theme.", Type = "Info", Duration = 3 } end,
	}
	tab:QuickAccess { Name = "Quick access", Desc = "Pin buttons, toggles and keybinds as floating shortcuts" }

	tab:Header("Danger zone", "triangle-alert")
	tab:Button {
		Name = "Destroy UI", Desc = "Removes the window and every floating panel", Icon = "trash-2", Quickable = false,
		Callback = function()
			win:Confirm {
				Title = "Destroy UI?", Content = "This removes the window and every floating panel.", Icon = "trash-2", ConfirmText = "Destroy",
				Callback = function()
					task.delay(.24, function() if not win._destroyed then win:Destroy() end end)
				end,
			}
		end,
	}
	return tab
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for i, w in ipairs(Library.Windows) do
		if w == self then table.remove(Library.Windows, i) break end
	end
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
	self:_closePopups()
	for _, fl in ipairs(table.clone(self._floats)) do fl.Destroy() end
	if self._blur then self._blur:Destroy() self._blur = nil end
	tween(self.Scale, { Scale = .85 }, .3, SPRING)
	tween(self.Body, { GroupTransparency = 1 }, .25)
	tween(self.BodyStroke, { Transparency = 1 }, .15)
	tween(self.Shadow, { ImageTransparency = 1 }, .25)
	task.delay(.3, function() self.Gui:Destroy() end)
end

-- ===================================================================
-- HALLOWEEN THEME  (palette + a full "style layer")
-- Paste this block into your Airflow file directly ABOVE the final `return Library`.
-- It only uses the library's public pieces (AddTheme, _onTheme, Windows), so nothing
-- else needs to change. Pick "Halloween" in Settings > Theme (or Theme = "Halloween"
-- in Library.Window) and the window transforms:
--   * cobwebs in two corners
--   * blood strip with dripping blood along the top edge
--   * a spider dangling on a thread
--   * bats flying across the window
--   * a ghost drifting + bobbing at the bottom
--   * rising embers and purple/orange fog
--   * a flickering candle-lit pumpkin in the corner
--   * sharp gothic corners instead of rounded ones
--   * a Creepster title font
-- Library:SetHalloweenEffects(false) keeps the colors but turns the decorations off.
-- ===================================================================
do
	local HW = "Halloween"
	local WEB = Color3.fromRGB(226, 216, 236)
	local EMBER = Color3.fromRGB(255, 140, 40)
	local rng = Random.new()

	Library:AddTheme(HW, {
		Background = Color3.fromRGB(16, 10, 14),
		Surface = Color3.fromRGB(22, 14, 18),
		Surface2 = Color3.fromRGB(30, 19, 22),
		Surface3 = Color3.fromRGB(52, 32, 30),
		Stroke = Color3.fromRGB(58, 34, 26),
		StrokeHover = Color3.fromRGB(150, 78, 26),
		Accent = Color3.fromRGB(255, 122, 24),
		AccentDark = Color3.fromRGB(24, 10, 4),
		Text = Color3.fromRGB(244, 228, 205),
		Muted = Color3.fromRGB(150, 125, 112),
		Warning = Color3.fromRGB(255, 190, 60),
		Success = Color3.fromRGB(150, 214, 70),
		Error = Color3.fromRGB(220, 50, 50),
	})
	Library.HalloweenFX = true

	-- decoration must never be recolored by the theme engine
	local function mark(i)
		i:SetAttribute("AF_NoTheme", true)
		return i
	end

	local function seg(parent, a, b, thick, color, tr, z)
		local d = b - a
		local mid = (a + b) / 2
		return mark(new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(mid.X, mid.Y),
			Size = UDim2.fromOffset(d.Magnitude + 1, thick), Rotation = math.deg(math.atan2(d.Y, d.X)),
			BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z, Parent = parent,
		}))
	end

	local function web(parent, cornerName, size)
		local br = cornerName == "BR"
		local holder = mark(new("Frame", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), AnchorPoint = br and Vector2.new(1, 1) or Vector2.zero,
			Position = br and UDim2.fromScale(1, 1) or UDim2.fromOffset(0, 0), ZIndex = 42, Parent = parent,
		}))
		local function P(a, r)
			local v = Vector2.new(math.cos(a) * r, math.sin(a) * r)
			if br then v = Vector2.new(size - v.X, size - v.Y) end
			return v
		end
		local n = 6
		for i = 0, n - 1 do
			local a = math.rad(90 * i / (n - 1))
			seg(holder, P(a, 0), P(a, size), 1, WEB, .72, 42)
		end
		for k = 1, 5 do
			local r = size * k / 5.2
			for i = 0, n - 2 do
				local a1, a2 = math.rad(90 * i / (n - 1)), math.rad(90 * (i + 1) / (n - 1))
				local mid = P((a1 + a2) / 2, r * .88) -- the strand sags toward the corner
				seg(holder, P(a1, r), mid, 1, WEB, .74, 42)
				seg(holder, mid, P(a2, r), 1, WEB, .74, 42)
			end
		end
		return holder
	end

	local function sharpen(d)
		local r = d.CornerRadius
		if r.Scale == 0 and r.Offset >= 6 and r.Offset <= 20 and d:GetAttribute("AF_HW") == nil then
			d:SetAttribute("AF_HW", r.Offset)
			d.CornerRadius = UDim.new(0, 2)
		end
	end

	local SKELETON_BASE64 = table.concat({
		"iVBORw0KGgoAAAANSUhEUgAAAaQAAAE0CAYAAABjKkd2AAEAAElEQVR42uz9d7Rl6VWfCz/vymHndPKpXF1dVZ1b3UqtDsoJEVRNkkBCWGDC9XedBwZXF9f3M8MGcx0utrmfMcYY2VUGhAChgGgVCt1qqbvVoXI4dU6dfHbea6+81vv9caqBy7UvNmCwpP2MUeGMqjNq11rvu37rN+d854QJE76+Ebd+TJgwYcKECRMmTJgwYcKE/5prmjBhwmRjTvgaXRdyclkmTJgwEaQJf2okCCQ88cRJcez8ecGJP/YXzsC5o0clwKlTp+R/TXgkiDMnTigAnNj9vhOnz+RCTITqz2EPTq7hhAkTvv4ebidPnlROnzihnj59QpXyv/eFQyClFCdPntTk5Y+bp3/mf7VPfvhdzr/+8If1/9p3nDx5UpEnTypy8nIzYcKEiUOa3MMTJ04oJ4DHz5zJ/vgf/uuf+nA53Y5LZYeKXSlNp3HeiJOo6vUHZcVQSoahV61CqToaesVup18yDEOTea6ZhZJuWJaWJomSZ7lv2G5X19XN0aC3WbC0ZdtxL/S2uy/90M/88vYrDuqzJ0+qj5w6lf2xBTZ5+58wYcJEkL6eOXnypHLs/HnxR0XoR9/2NrNcSw/Pthr37t07c2eeJkc67e6B8XhcCpOkrCmKramKcEtF4rFHBoyDkJEXUC6VSKSCaZrEUchwNCbNFdxiAUPXQVUxVQVd1xBk6KoqkfHNwWD4pCD75flHP/Tk448/ngHIkyc1Tp3KAfk1Lkiv7A/5x37/3/J9EyGeMGEiSF/vQoQCDyunTp1NAU6f/hn7+V//zQeyIHy7Uyi91XKdQ0oSuUmWkMc+ne4Q29JzIZQ8TmVuF4uyYJvEScxwMMJ0XBIEjmUI23bJslygKIRhhD8coRmmLBaLpGkm0zwjSTNZLhVFc2ZG0VShG0ISh37mFIpPFauVXzAP7vnIo49+MAR48uRJ7dFTp9KvIyH646L0XxOe/x7xmjBhwkSQvraQIM6cPqE8/viuI/q3J793b3+78z1BmJwY++HtrWZDtS2Hbn+QtXfaWZ4nMgxCoWlClB0DqWpiHMW0WjPkeY6qaURJJoJgTLFcxh97mKaFW6oisowsi4kziWnYslyrEvkBY29IoVIjCgLiOBJuqSR1Vc0dx1IsQ9U0RcF1nGfdxvS/OXDwwC/N3P3WsZRSnDnz+B987q+jfSH/X5zRRJAmTJgI0tcnDz/8sHb27K4j+tkfeOveYqX2V/NMfijLsnoiNYSiJkGU5CvL60IRuTLdKApDV5BSoug6huWQpTnjOMHUNJC5FLolyvUW3mjAeNgjSXPIU6ZnZ8nyHCFUVFXQ3dmi6LjEWYofp1RLZbY2N0mShL175gmjmH6vj2FZmaZpUslTc++BA1i2/bym6//bWz/047/+ykL7T6dPqF8jwiT+mAv64+LyJ4XkJiG7CRMmgvR15ook4oknEKdOkf+D737rzPTi1A+LPP3BqalWfaM9pDuK49XtnhgOByKNY2SWi8W5GlkYEIYxlWqJcq2O7dqkYUiSpHR7HbI4pdRsYps2CFA0jSxO8McjVFVgGCaqbqLrGjLPUKVk8dBteF7AcDRk+coldEUVC/PThEkiDctl7Ae0d7ZksViUjmXkpq6Zew4exi6WPzXs9X/2XT/4E5/4w//XSUWIU/nXwF74k0Jz/AkuaSJKEyZMBOlrn9MnTqivFCycet9jP+K49o/Nzc3P+H7I9fVuvLK+rbR7IyFlzlTFReaS2akyZSNn7PmkioFqu8LQDQxNQbdMdLsokyTB98c0Wy3Gwz7BoIftFoVbrUrSjCiJGfS6pEmCpmvYdgHdLTM7N8uw28H3A3RdJ0sToQBr6xuUXJe9R47KrY110tCnWCljqiJHKBi6qZuOTcnWP69o2s++8UM//mtIyenTp9UTJx7/n+kck/gviNGfVlQmYjRhwkSQvj7uiTx5UohTp/K1J3+68cnf/uI/ijE+WCgWGYUyvLq0pu3sdEQah1QcnYXpCmma4fkRhpLvPgUVTfgYCMulaiqousF4NMR0bNI0k6VSAZmmQiBJkwTHLeIUChRrdanbBa5fvkxteo5C0eXFL32O1ZubvPr1r2N7/Sa66SLjACTCKhQZj310Q6dSqRGGISvL16WmCDRVZf9tR8nSLNve2RGVUlFfnK1TrxZ/dxiOf/LtH/6Hn/uf1C2JPwdBmjBhwkSQvrY5efKk8sQTT0ghhPzf3vfG716cqf5kHKf7lUI1vr6yxfLqtiIEoj8YU3R1UXcNFqfL0qk0GPs+vW5fZFKhNdVkGOVYtkOlWkWVCTeXruEWigi3QsE2MU2dzupNsjjEqdbQFIFVKFKdmmM8HNBeWyGMYsrVKqpQMBxbXr10mfFozN4D+4iDQCRxjGHbZFGEpqv4YYI39pBJJBUhqTYazEzNIGVOLIxMUWBfq2joqkjn9x/6p4Zb+InF1z4eyNOnVXGrZPx/kj0xEaEJEyaC9I0tRqd2z+7wH/7Otz2xvtU/ado2qmaE6+2hPvAjxkGCSBJcV0cjF7WSTankcOlGmyDOKJZLjIMY29LQdJ0slxi6imnZ1KsldN2kMT1N0N8mT1OSNMPzA3RdRTNsHNdFxiGd3pBqq8W4vc2TX3yOD3zwuzDI5dWVdWSe4g8H+GNfFEslup0utWqF+swMvc1NZJ5iF4syj0PK1Tq6rtPbWkEzLOp7b5c118yE3xaH7rzbGGxvPR2J5IP3v/fvXZTytCrE49lkJUyYMBGkCX+JvJIv+sff/+59dx+s/PMsz9/Z89K4P05Y7XjqRtsjS1OiKMI1FEqOJqZbNYaDEZWiw1rbwwtzSiUHt1DAsQ1Mt4ihCfqDEXqhjBJ6hIFPnuV4owFlx0QxTIrVOmkSk0uJisByXCSQ5pLFAwd4+cIVmQZjSqaK6lYYDwe0pqZRVCHS0KffG6BpCmkYUiyXMU2DLJcyyXMSf0zJNUWeJ6RxJIVdZW5hj3RNZKnWTNXEs0uuvi405wN73vRXPi2ffFITjz6aTlbEhAnfmCiTS/CX7Iweflh7/MyZ7Gd/4D17X3/P7KcHfvLO33t2Obm5M1Kfu7ihbrQ9Bp6PrkpRLWjCNBSRZpKl1R1Wd0ZcvNklRiMTCoZhUKzVEapJv9dnfbvH3IGDWErOYDjAKFapNBqY1WnsqQXKcwep7DnCYBQSBBGKYSNUlVwoaEIw2NkgS3M8b4zlujL2BjIcjwj8MVku2dncptJogJSEacpwOCQIQsxiWahCkKSxSKKALE4wLUeIxEdTpFBUUwnC0BhHaaSSztbr7sdWP/uv3i0efTR98skntcmqmDDhG5PJ5v9L5MSJE+qpM2fSk99xz+zbHlr8T8EoOXDj5nYUpbl+cXlbKkIlT3LqriaQGZ2Bj2OaaIqgUHCp1GqkuSCVKq0ph2KphFGuEg0H5KnEkBlrV6/glMpU6lNUp2ZQDZN9d8/glCrIPIc8wdBUesuXKLemQdFYuXadxtQUzfl5RuzQH3jsO3w72zsdYQ96CFWn3e7R8wIqcYxuGEyXSkSppNfrUZrWyVGEZjj4cUTBBF0kkHlcf/ZJ5g8fxyxUsHRdS+IsUtRcrzbK/7F7/te+vXb00d+ST57UxKOnJk5pwoSJIE34C3FGJ1FO/eSZ7D3HZhcePLLvN11duevFlZ3Ij3Nt5PkyziHNEqYrLrYh2Ol5VIoFCrZFmqQYpk0U54xCyW133EaehGRCI4olil2mUawikJimgWVoRP6ILA3JoiEvXXqJ5sIijuPS397E0A2iOMPrD/B9nyyJ6GzcpFavYWoqSzc3iMJAyCxBEQo7m5vi+P33cVUmKJqOIgSWY2OqJm61SugNKFarqIaFa6nE2yuYmgpWURRnDmCXa2iKKo1SAaEEWhzHmRCqrRv88vLn/q83iof+yrPy9AlVfG11d/hGZlIIMuHPhUnI7i9JjJ54QsqapPTD3/PImUMHpu96+pkrwThI",
		"1DDZ7ZJgKAqztSILrZLoDTzaw4BcCsZBDLpBpupEUsWtVgm8EVkOqcwhzzBtjXDYYzQckSUhO6srmI6L6RSQqaQ+NUsWhmwtX8e0bRTLRAoFQY7f3cHv7ZAGY4SiyLVrF7jjtr1sbmxSKRYplsrs3b8HNU+YmZ2GLMV2TBShyKC3Q9zfZnt1jcT3mN+zQDgcoekKSa4ydfhurEINRREQDzHiEW6lRuZ7ahb6saZp5WrN/ehLH/mbB8TjZzIpT07W59cGf7Rd0oQJf6Y3mwl/wddcnj6hiMfP5C/8X99/xnHsb/vi01eCTCp6O0jFi1e3QUpKjo4ic3YGY+HHKcWCS7lYpOf5ZDns2b8ffzzGsS1M2yRLElrNCpZlM/bGDP0Q13EQyRjbcWguHkTRDfxBTwKEw75QdRW3VMb3xiRenzz0EUmAWy6xtdPBqtRlpTaFbRistftk4wGLCwsIwyIOx6JUa8g8TWhvrYMQaJrGqN+nPDXPueeeI4lCXvP6VwsZDRFZiFANFMMmCTxmG0XywbqcmZ2iPDMPqoHTaKZ6PjC77e7nlWOvfXur9egYYDIEcMKEbwzUySX4ixWjJ588qe57189ln/+n7/+nMwutD37myZfjQYi20ffFldUeaQ6qyOmOQqFrCrZjCV3XCTOJYRpESU6Y5iAlrm2QC4EATLdAuVpCSkESJxiaQaVZRyCozy4SpxLTNGXoDUjCADRd9DodEm+IUBWsYoXE9yCL6UYqxUqNxtQMEoUoSZlZWGB1c5ssGqMbBoqqsrOxRhz6zCzux7JsVEUQxwmWW0FqOpcuXWW6WRPNRpk09EnjELdSY/vmTVxHZ3q2KUAhTRLc5gFk7CtoelIuWfuDm8vHvvxvo//85Z0HxJkz5ycrZ8KEiSBN+HMVo5Mn1Uc/eCr9yn/4Wz+02Cz+5JmPfSUejUJ1EGbi2vqAUZhSL5pkac5UvUTXi8iEIWzTIpUq7VFEpTVDsVKlMTWNROAWS6Q5lByLcDRE1Q0SqYCiE0cJhuuQJCnj0Uh2NtfxOlsU6w1G44hSucLa0jVhmSa9dptKo0ptz1E+9tuf4VWvvp9CrUUUpyiGRblcxQsiri6tcOjAHvqDIU6xzGg0wFBVsjQh8Idi7/H7sWuzZHFEs2xCGompmTmsUgWvu0W13pL1+b1ifWOb5vxBZhb3EfkhmEV0y0UmAyXorSSKahzL3NnuYyf+5VPy9An11JnzE5c0YcLXOZMY/V8QJ08+rD566lT61L//a4/M1oyffvn8SuIPfUXoOi8tdfGTDNfQGIcJ3XEk4gwSoeEnOcIwQdUpV6uYpolp2ziFEkLT2d7cIs1hPPbQdA3dcWm2mjSmp3EqFXRVQxEq9XqDQqFIGCWEnkez5BB0NgiGfbm52cGxLbZ2Rnz8yac5ePgQy9eXOffcc/T6A4q1KXLdoGTp+FHG2sY2wXiMoursO3InSRLS39kgGY/Q04BmSccgpre9gW2bWK5LvdEkCCP53FOfw9RU5vfso7txg9DrYxRKdDZuEkUhmm6gJx0l3L6U1KbnTnmXTt+9m0+Sk7U6YcLEIU34s4sRCnxAvmvBaB7b7/5We6PbuHR9K1N0VXl5qUeYQdkxAYRr6WJ+qkYqdLHRGTH2A1Evl3ZHr+YQBx5hlKCSk8cho+GAMAzRNB3HVDE1jWG3S9DvUKsVGXU6ROMR435b+MMeuqFjGTr9zVXS0KdcsFheXhGRUeajv/clNleXKYiE2VaVgqWI3va2SLMEU4VK0RH33X1UPP3UM2L//LSoT02JnZWrQtcMse+224WuSvJoRHf5Mo5t45RKuMWCMLIx4+4WcwdvJ0szKpWSqNgCU8S49Sl666vU9x5CJCMsK8MwM6TXyxXFdGNvfNdj96q/fOjBq/kTT3yWU6dOTRbUhAkTQZrwp+WJRx5WP3jq32Un33//PzMRj15a6kTdUax+/vymGKdQLjpUSw5JkgsUnUEk2ez5IBSEolAsOmI4DnHLJQSg6jpSSpIopFgusffwEerlAv12G3/sQR6TC5UoSik1GvS7HRxTlVNzcyiKyvXLl8mzDMfSUHSTBx57O7/zid8VD999iMceOM6+xVnK1TLkksZ0A0ORQuap6OxskyUenh/R6w/YO1vlUx/7ONV6Bcu2SXyPbrtDhI5uWpQKDmkUiGDsIdJQ5rlKZ2uTRrVAsdFEJ0IiEFaBbLhJqTUrstEKedjFUHKls7yR1Kam91bL83rp4N//9BPHjqmnzpyZhO4mTJgI0oQ/DadPn1Df9SMfz576mfd+UNfUJ67dHEa9cax98vmbwotyGiWHStGlOxyLQZAQpBBmgjTNqJQKlFwbU1eF4zo4ugpCMg4TbNum4Jrs27ufWqtFd2OVLM2YP3AIu1DALpaxSnUpNIOpmRlib0SuaHTaXaamW5QcA8OyKJYqbIUqw81Vce+dh8k0mzDw8aOcYrmAUygQJxnVRpNmq0GORNU0nn7xCo1ykbmFPeRxAFJiF4qgG2Lp2jWK5SqmbeGWamJq30GWzr2Aoht43pBitUF9fi/ti89iFatUFw+xfuFFFJFjWgZasSmk3yUchEo8TtIsjR/+wfe9ZbnxbT/yvDx9eiJKEyZMBGnCnyZU98M/fE4Wbn5qz/756ulUKta11b586tK2EknBodkaQigoihBr7RFDP0bXdcIoplRwaNYK4vryGqoQtOolMRj6FIpFcjQsQ0dXBJoiWbtxg9W1DQxDx1Qko3HA+uoGrdlp1DRGFZKcHN8bImROGsdEoyGqrjMMMr706d9h75454hzhDYaYpkap3kAkIQJJJgXD/oAsCcn8PlVX5cD8FDEGM7MzJOMR9akWxVIJ0lT6QUijUaXabBF5fbaXLnH0/vtor69jWyqmEiABRdNJhmso5DjVJopZwLQtEBHRyINcE0Gsi/76MpalPPp3/vp3f7T0tg+1n3gC5dSpsxNRmjDh64xJovh/ZKjuiZMIIeQDxxb//tiLm599+lp69qVV9frmgIPTZXZ6Hnmec3NnKMMolaahoyoCU1co2ho3btyUXhBRqJRFuztCNUwst0KhUEDRNCzTZGeng9B1iqZGrWTR7Q8IAx8hctQsFNF4wMaNa3j9AbqqUqrWUAUs3biJVEw+/eULbA3GSE2jUi5TKlhUajWKRRdVV8izFEVVyUKf1StXSOIMz0vJAp+5qsHGTodf/q2zfPXZ58nDIcF4JG47fABVVVlfXqK9cg0laJMN2yzsXaRZKWGkIaYG9UP34LQOkGQghELj0H1obhVVVfCHIzHaWiVOYuHO7EuU9kpFjYd/QwgxEaIJEyaCNOG/h1cGz33yZz/84B376+8LgiT5/Plt9cragHrR3i27dqzd80GaTrNaROaZXN/uoZITB2NMx2J6qkESxmiGiZBSBv5QWoYqZRITxAmxhCSMqM7ME+QGldYs2xvbWJog6PcwHUtkcST8QU8Eox5eZ5NRdxuZ5yxv9yH2+JZ3PMzU9DQIKDca2IUSSZySRAnV2QNUphYZDT0qjQZRmKDpBvXZPWhWkcMLTV5171387pcvoug2s7MtssDj4O23oygmO1vrHH/wAYQQjLsdFKfM9JH7SEZDvPY21cWjGE6VzWsXiPtbBN0NFKeJXpvGH/ewRldlhY6SDruJnuXftXP1t+9XxKl8UnU3YcJEkCb8N9sjkFKK6XL649sbPeM3v3BDZooQc40CzZKLlAqdgY9UBHEu6Qwjhn5CueRSKbk4pRLjMBO25QhN14mTFD8IGfX6+N4QhZwoihgOPcr1Keb2HUJKBVPXeeA1d7MwP02hUkaGPsWiQ71Zo96cQiNnMBjywIP3kmUprzqygGE5JHGKNxwTjXa7eSPAGw4Z97bJozFZllGZXmTm8J2E3gjLLVNqzKKaRd534h38lQ8+zi997LPcXFvnxqWXefYzn6Q1NcWRO++nvdnDrEwxc/AQlcYUSrGFt3GFy1/+POFogFMqU663GK5fRciUbOeirNRc",
		"pg8cwB/1GW9eE1EYZXl/3TWC9o9NLNKECV+fTHJI/wM4feKEevznfi5/UPnSw65Mf/L0k1fz5270FEUR7KlXMHSVle0BsdztiTMMc4I0JculKBccykWXYrFAmilYlk6l7CIUFYGgUi1hWTZxkqBoujAMk2qtxqizQ7lSpt6skscJqdBQgP7WJnGWSV0TbK3exPM8pqYatEcJF68u87oH70M1C+xsbdDu9EW1UsK0bEJ/jKKqaKpAqLthRE3T0RSB49iUWvMkcYCh64Qpcq5RoG7kfPpL51lZWqVZdSk1Z4mTlDQaUywXCEY+eRojEw/FW8bzEoThYpdK5GmEU6rgD4cohik0VZOa5XDz/FViP+S2+44q3eUrqaqKo3/rf/nAVwoLr7o8KXCYMGHikCb8CZw7elQC7J+v/WBnGGqfO7eZS0Xw0J2LKEKQZJJcSkbjkBRV+FEs5sqGODBdREhJ0TWxdQVF5IyGI3Z2euimydWlVUb9Eb12m2A0or21I1UhiX0Pu1jAMlUiz8OptiDL5ag/kLmmScgxLIe5PXtRNMH0ngNcb/scue0QrYUDaJaNPw4pFFzqi7dRXzgEqLTXV/G8MX6/jW65mIaKyDOKjVmEoqKggGZg2A7tdp/FvYv82P/yXdz16GO8dPkGeeyhuwUx6LW58ORvIA0b3xuw9eLvY5fr3Hb/q8nilAyV0I+Iw5DKwm1y59JVOe6P0SvzjNWSeHHZJxoNCP0Ab3tZGMrop5ee/NkKJ85JKeWkH+OECRNBmvBfQt4aRf7Ff/6Be3vd4D2feXYlzTRN/dBb76Bo6MSZxA9j0lxiGLpQ8oSaJRiNQ0ZegGMqMvQ8tts9fD/A92N6o5DllU1s2wJVQVFVvH6PxSlbqIlPpaAx2LjBzspV+lvLcuXlZ2QSjhGqQuwPif0RmlXAcMvMzsyxvb3DSxevIVSN9dUVXv7K0+SaRnF6D5fPn2fU61KfmWc0DtAsh053RBCMGfc7srX/NhmHgRx1NlFUhXF3m+2lS2Shz3A4En6Yiw99x9tEaBTFv/vIb4pyycUuVcWg3+Ols79De+BzY6iTiTKp4uA2Zwn8iEzutjpKvRHSqtHe6BCNBgjFkE8vR3RDHSlzRRFqXDaz26tO8oNCnMr57BMTlz9hwkSQJvwXOXZeAHj9/vuuXOvaz1zvZwemSlQcjdWtIbmUBKkkziDPc5oFndmaS5jkElWTQZTQG/pyZb1NsbI7U0iiEIx9CrYmCqWCiNJUpFKKPBNMzy+QJonc2txGkkunVEV3XOJojKpq2G4R3TAIelusXb0g0yRmc6fDy5evE496bK0scfDQQWSeEQ53cEzYWLpEEo7Ys28fhYKL6zokvicN0+Lqs58jTVLSKGDc2yHLc4xSQxSas2Lm0N2UF+9k0A/40Dc/JEtFl4/86icZdPuYTlXMzNRZu3aZJFVIcgVFNSm2ZhluriF1jTCKuPCVZ1GcaZJM48Zzz1EqFWlVTG6sDqnOzBH0+2L7ysXMKjY+fP7X/r91Hnkim7ikCRO+PpgM6PvzRYjHz2Tve9+b3aKtvOP5/kAmEuUt905z4domwyDZHWZnaERJLFzTwLE0rm565EIRwyCSeZYjCyaGqcvQG4tKuYhpmDSKGRcuL7O5uk6SpSimg1VpMQ4imQUe8/v3SUVKirUWZuAjETRmF+lt3KBWqdBvr5FHIX4YcfuBBR6693a6O20qzhSarnPvnUfpd7vEqOysrVItO8weuA23XCeNY2TQwypVqZanyNOEzNtCL06h6DpC0ehvXMXr7SBlxs6N63JqZg9/9fum5PUtT/zyL32EV+1xGWRbjP0Yq6CRJhnDnTVknrJ14wIz8zMIIVnb2KY6f5DSzO1svLjOf/z1pziyr4WQghCXcRAqbm87NbVw39z+0geEED8j5WkVmAzzmzBh4pAmvMLp0ycUgL/52J4HMe1Dv/H0cvq2u+dEs2ii6gab/QBUlSyTpLmUtqli2g5hlsuVrY4cjsaiXnFEuWBj6JqIogAlj9ENnZEXoGoalutQrZSo12tsrq2xfv2K6O5sM+y0SZKQa+dfxOt3KBZdxu2bFFyX0aCLYxdQdE2Meh2SXKDJnHrZQdM0hr02YRCgmwZBv82Bo7fT7Xa5/tLzrF+7QKU5Tam1gKJopHHAjYsvkivGbgujLGW4uYRm2QhNZ2dtlcLUHFFmUCjY7LNH8sTDR2VhalF+5HcvsLS0zuryMsIt41gaK+deYH7PIvW5WTTLwS2UxcrSEkGUUN5zjHe8fr9IfE9IxeHmqk918QDCronUa0sZ9r//5Sf/RQEez+VktteECRNBmvCHnLj1a9FW3hqrhpIhsvv3FcW1tSEv3xzz8mqbta5HIiVZmiOEItt9XxYcE9s0QIBEIZGK0E0bTdPY3u6w3R0wjAS2ZSAEpGmOjMYo0ZCCqWCqgjwK0ISkVqtSLBaQ0YjUHxJHAYPuNjeXryDRWVyc54VzV+h4AbNTdeE4jmjMLYo0TUSeSxYP34ZpuUSJpNSawjB1yBLsUp2x5xGNB6iGRb83lOP+Dr7Xx6q2QLVwa3OUZ/cz7vfYWlmmt71FnCbIsMvb3/kWfuCH/gq/8+wNnnppBS33cJItlpeucOXyFbJhh80r53j5whXcYlF89ekvilw1hCJVCraKWqqIaytbwuuO0BuHlY1LVxMlHh6pa/E7hEBy+vRkLU+YMBGkCX8YrvvP2Y8exDQ08cb/35mn+fbXLirlgsnIz1jZHlGxDYZeQJZl1EsOWZbhRSnd/liYqkK9XKRUcEGCruvoqkK1XiVOEjRVY32jTWe7TX/QZzjok6cpSZqRI4RUFOGNY5FITYS5QqRXMGtz2OUm1elFeltbcvvGOVzHoTGzl/HAE419B0GzuXHxIs984UtcfO7LdFeu0l1bol6v4ntjwsCnvbHC1vIVvGEP8ozb7n2A6f2HSbwO9bl9mMUa0WCLzSvPoxs6im6gGBZurY6q6tTmbyPQWjz2+lfxwR/8MM9spfzSr/wWvbVLZHEo7UpN3rh2XQ69iGazwub6KtVGk68+9Qyj4RBhFcmMEk65xvPPXxJBrJBpLTlcXsLWwveBgBMn8skSnDDha5tJhdKfEydPopw9i/yNf/LuI8/dGP7dGyt99ZtePSteuNgRVzdihmFKHIVEUmDqGjsDj4prEqcZfpRSKTqUHEuUigW22j2SKMI0bUq1OgC99jZpHGIaBkXXxtY1LEPBMg0yRWPsB5QLLoHv404tiubsIsF4jBACkoDxoCPi0YjAmeNzX36RqLfJ0lpPhElC0l2TtWpRPPzYG1BMCyE04nCMY9tkUUB3ewtVN3GLZQY7a2TBENu2hKEpqLpOMOyRxiGV+rQ03YpIQk8sX7vKoUN7RXdzA2r7EeT4I49HXnMvQRTjxxlLKwOuLLd519tfy9ZmT1TrTcqtebo9j0rR4fr5c8y0KiRCl5nqiHKpyHZvhDcKxeKh2xSr4NLf2Zx//5uO/frc/d/SlidPKqfOTnrcTZgwcUjf4Dxx7IQAqE1P3Xd5uV944HA1zfNU+LnC2iiiqEOW51RLLiXHQlM1RmHKZnfEOAgZ+SFCVcnzjCAIdrsyeGOGgxEyl9QqJY4cXGRuuk6WZvQGHlkuiVKJ7dggJc16lWajQalYYOn5LwoZ+0SjLmtXXuDoPffzheWYz/zek3zr6/fyN3/o23jD3dPy0qXLcs/xe3jsHe+QgTTRnCqlRhNNM8iynHKtweE77qLeaApd0ylWm/h+yPK550hzybi7CVmCW27Q21ymv7ksw2BMoVwWShaBkKDqrC5dYzTosX79EnfPmhQcjR/8wffw/FJH/MJ//BQbaxvy5o0VVAGOZTEaDKg3ilxa7nJlZZuVpetouklregqr0oTSPtDKSavVKswdOf4dt27CJI80YcLEIU144ugJ8cRnP8uzT57533e2/cP3HSjl69ue8qVLA65ue8xXDEZhSrNSYLPrYVsG7aGPFJqwbRPf",
		"D9A0RfhjD1MTOIUCe/ceoFxvsLXTw7W03TlHUrLdGbCy3SNKcoTMUdIIU1PQVAXVMBgM+kSjLiINhKkrQksCMRA1Ar/P937bG9l3/G5006bsmhyYrdIfjukNxjimLsa9NqEfoGgaQlG4ef0aZrGMYVlopk2SSdIsZTgYCkNXMUydNBjhDzpSCEGh1sR0isIyDObnG1x5+UURqmV0VSPyR2S5oGDkXL18Rex1c777xFv59S8uiafPPiNedc9BrFKdNIoY9jv4vTZxGKFbuljb8UiyFNuxyNKUamsWTTVkPriuOlN7S/e88f2/ePz44+lkJU6YMHFI39CcPn1CFadO5V/9xe9/eG07fIdrq9lW29NubIX0fEnB0ukMQ8oFG4AwzRCKIooFV1QrRSrFgig4tohCH9sxcFyLguMwGAzpbm+RZQlRkjIYjsiAKMsYjQPSJMaxdBQF/CghFxCmOeVmi8bcAvVWk1LZ4drGkC/9/u+Jtz/2oHCm9grPz9hcuixGwwGN6Rmm6iXaN5cEikZpahYpVIbdNgo5h+66E9OyyREkSUISB6iqRnNhkWtXb/Dys1+SURDIcmueUmtBZLkUqm5i2xZhGLJ4+920126KXrctvEGffr9HpzfmjgNz9FNDpFLjX/z036YwO8/a6jbrKze4fPkyve1tkjiiWhDoecqe2SIrq1uMUwWJQpqmOHvvVXyqadS+euyh6bV7YLep7WRFTpgwEaRvXM6AEIILV9rf8/tfvCRcGeY73YAwVQgyAMFtC3UQkqX2iFLBYTAOUVSFOIzw/AA/inAdh1LBxfNjklQiNBj7AaoCShrT6Q0Ixz5RFOG6Fq5jk0pBnCscPHoUp1SjXK0j44hGq8Vgax1p1LkZmLzhkdczd/A4qlkgzVLhNmYo1GeEWWoK1XSZnZslSyN0y6Xf7VJutFg4cieNqXnIEob9PnEcMRr0GHserlNg4eAhaZWaBEFIZ32JK89+nmFvG8MuEPg+O0uXmZ6dxrI0slxi6jqGqmLpNmg25y+u8vQzX+XK2U/zHe96HRc3ffEfPvY5hsMxtmtTrxWJx5GI4kw8dN9+Hn3wAAVbY+iPSeJUhoMOiu5mlpqbphZ98+69mITtJkyYCNI3KCdBefzMmWz4n/96a22r/7bbF8vy2P6asj7MZGa6jOOYME4xHZMgyQjjlCjN0PTdVjlxkrCx3SHLMhzHYXOnj6KoFAsOo8GQPE1olB1ajSKOrjLwI44dWKRRdCm4Fju9MXapikhi+tubPPfFp3j5qc+xff0C3mjMf/iVM9w971J0bRKp4HsjgmGf4swh6vvuJMszDKdAsTkrq9OLmLbLgeN3k2QCYVVQ7BJC0xntbMjt9VVUw0YgWV9dkVcvX6ZQroJm4Hk+jblFuXH9moyjiCRJyIRG3N+kXHRYOHA7ldYcUipUmzURqgXOX9ug3fXZGfoocSAevO8YYzTxlcvr4ubOUJSKBXFlfcgwUekmutjsZ2xudkBCu71JPB4Q+qHI8xxdk4/I06dVTjw+qbabMGEiSN+oivSwAvDzv/3Fx77pdQsz9x+qp8+f3xGj2KQzSAjClFrZZWXHZ2Gmgaoq7PRG6KqKqmkMPR8poVwqECcphqYSxzGKzGWl6Miio1O1NRQBpYJLuzfg6uo2pqEzVa9wcL6JJSP6nS02NjakaVvSckryzEef5MkvX+DwTJGpWoE08mmvXCbyPaLAZ/vSs2ThCCQoec6wvS3aN68RjAaUanVmFha48vRn2Lh+Ac2yGQxHolBtoOs6gdcnlxLTLdLbWkPVTBTdJEpS5g4eI4pCRv0u1bkDWPVpks4yvtfFbc2IKE25cfkKj7797Th7DqMWKiKJQ7Y6Q5ZXtnjvY3fxmUsbFAsFaq06iiKIsxw0B0W3ac7MUKlUMWQsFEViNfaISy+dzzXTPHzeeWFeCKQ8OQnbTZgwEaRvQI6db0kAS2RvNRyNJEvp+tAZR6Ld88RCqyQEiDCVeGGKrmoYuoEfRgS+jx9F5FJi2xZCUXadRq0qVd1EAVRFwQsi8hwq5RKP3TmHIiOWNrb5yqVlnr64zI2NNu2Bj1uq0BkGnH35Ote3urzxkfvZt3+enU4Xs1BGsxyicZ+dtZugqkTBmNLUHhRVp7V3H1EY05jfh10soygqrbl5qQpBHMbsv+NeRJoIRdWwbAfHsrnt6B209h0hjGNRrM9gWkWSOCTwBhSqNeJgzHjso6spG1df4urzTxGGPuvbO1x77vM4muCBR94kG5Ualq7Ke+45xrsfOc4D++pcXlrD7w+Ym66SjweE7Q2SYCR2NrcxbQfQ2Lz6MqXpaTF37FVp4nWr1dbCfcCk2m7ChK9RJr3s/gxIEOLMmexvvPlO99jBxqtrtSK/9fGXxC/83jKzrSrNSoHRyCdOc7wAsd4bI4VCkqQ4toVt21RyiaooxFFMHkcITZOOU8TzA+Ikplkto6oa9YoDtbK8dOmSEFJw23wdUxd0vYgrq1tM1SoUqxU+/sw51Dzhwb01qaSh8COHOAzprK8wfeB23GqLGUVFyoz+ziZWmIAiRJam1KemSYIxRrGKPxrQ394QzYW9IDQsQzDa2SJLUxF4Pp2tbXKZUZtaIA1GXHv5BaZnZ8H3SHNBo1EnGns09t5NrhcpFyR+nlIulkkkMo99pkuqWLpwnhlDkmJQac3JUTgWjz98nF89+zLd/oggBd1xyGOfzc2eDDIVKZa4/egxVCmEt/IyjekZaaiRSMbhO4FfgxOTs0gTJnwNMin7/jOF604qZ8+ele953d6D9aL11w0F499/6iqJagghM0Z+TNcLiJMMQ1fpjEJUTcexDDRNxxuPkRJcy8LSFQquI6eaTaJMUigUsEwdmeWYKmJpbZ1zS2tiMBhTrVQpuAVatRpl22Bfq8J8xUa1C2K9M6LlmuxfnGJmpoVhOSJJIrLIJ/HHZEnAeGcN1bLRnTJx6DHq7FCf20OeJ/Q2Vwl8nzxLUYREd0okqPTXbyAUgV1wEDLHKlUJvRGD9RvkcQyqJtI0IZM5uu2I0PeoVErU60WCwQA/Udna2EYqCssrGyiWyeJ0jZ2dAc1Gle7AYyRcwnHCwSmDoR+KGzfbSEVDNSyOHp4nyzKurfXAMFE0g7mFBcysj5YPyKOBmggzv39Y/TfHH388Z9LbbsKEScjuGypcd2vUxGxJPTpbdYo3N8ZpteCK2ZLFKEzQNI2RH2NoCioQJClpkqAqCmmWkmY5lqmjaQphFBPHCavr2ziOSxwnIBVKlTJffOECcQ7vevTVWLZFluf0vYCun7E5SBnkBn4KZTWWrzu+F8gpWRprN24QRzH1xSN4w92DtIOtDYIgRNVtQt8jzxLsYonRzgb9rQ1Uw8LrbdPd3qQ+tw9/1CccdjEsizxNKbcWqc7vx642qC0eItUcjMYsiWKR5IroDkbEGfQGA9a3uiimS6NeZf72+7nj/teg65Yol0siC4Z84fe/zAvnLhONByjkjMchiWqwsrrDQs2WVzsxVzcHFF2LkRcBCvffeYjb9y9QKbloto1aqJOZFdHb7kEazRZeP10DkPK/ySSJ0ydOqCcfflg7+fDD2smTD2tPnnxYmzRqnTBhIkhfczTPbQuAsiHusS2TJBX5OEzl1iBk6KeMxj6VosvhudpuEYCmoyiCNMswNA2hCPI8QxFQrVaQQgjLsYVQEGNvxMbmFnEaMT/d4KF775CXrm3QqFbx/JhiuYxRKOOUyhhWgURzWVnvUdQyHrj7MAt75mm0poWqaZi2jVWqkKGS5GAU66hWEU3dnTArFZXNtTUG3T5pGuNUGuRScvPqZTIpUBVBsdqgue8omWIhNJPID8jShMr0AmmSEKcpGYJBbyjSHKZm5onjhOHmClH3JuHqi2gyo1ip0RsFuJZJpWSJmYZLP0yp16okUYhJihAq/jhgx4tkmORkWc5nn73OJ59ZQrNcqkUXkYYsL90kQ6G9ukacylSVefPgobkDAGfOPK78v4VaT58+",
		"oQLy8TNnslNnz6anzp5NT506mz566mwqQD558qR2y2UJKREndwslJkI1YcL/QCY5pD8DO7cKGooFZ9HQFV6+tiUGcU6Q5DLLcyqVsvCCiJ2BT3sUoWkKuq6jCAFSUnbt3U4LiiBNs91wnm1DmsqC6xD4Ps+/cJH77zoizy+3hZQKumZQq1fx/AhDj1BVFYkgSkGoOuWiy7kbbaws4vBt+ynPzLN57SKKomIUCtjlKsFwwMq5ZykWXRTNRCgatfm9jLa3GOy0cao5umESBgFSCCLfQ5udBTXBW7vB9sp1Zg4dxXVLVOoN1q9fxC0UmV3cA1KhNTVLqWBj6DOYrcNUBzc598knSYwGgVljZ7uDP2MLzSnKPfUpKrZFFASoaKhpgGvA/FSJSrFNGIZ4Yc4LSx0URWVpZZ29+/Yy3thg7foFXnXfLKWFuhjc6KS51zUrM3ccB54+ceIEcOYPRUgizjx+Qjl39KgUp07lPH4m+1vf99rivNt6e+AHB5DSKBRc5e4791z+Rx975mOPnjo1+gMbJQBOSdg9BH3ixOlcCDHJU02YMBGk/2kQrzzwbrbH9kzTZzxOGPoJlqljhKqIkozt/oi86BImu67I1HVUwa5j0lXyDBRldyy5oWm0uz1Zr1VQc4WC42CaJju9gMW9e2lvbxILWN9so5sG1XKFmdlZttsd1ja2KOiCPJPMTVXwBz0x6vex60OK5TLjQZdwOKI2v49o7FGdWaTcnCEYDUDZbesjdB2ZKwjNQDUk080WWZahNFuoCoRhjKpkOI7JzeuXUDWFndUV1m9cIVUMbFMDclYun2d+YR7bMel3+8zOzWNqOdu9Dtt+m5Scl166xoWNofjB9x2USTCiaJuokSSIYkqWQdLLeOj+2zj/4jV6wzG2ZTJVr4jpRoWdrR25sP8guaLTu3GB46/egxq3RLzTY+2F5w8C4tmf/11FnjwpP8tnlc+eOpsLQQ5nMoC/c+J1iw/esffbV7b9D61seLeFSUIYJTSqCndlKv/w/Q9f+rkfevM/evUTn/zI6tNPRz9/8rtnH3nwaOnQcWtJLP6NAAQnd0fVy/+78Zrwl7sfJ/dhIkjfyNx6CZdSaEsrfcZhTJLnZGkqTF2jNxxTcUzyXCIRpFmOEBBEMUJVkUIghEoeJZRKJWzTlINRwGAwQkUSI9i3d45BbyiGgz4F18brd2nUypSKRdyCQ3tnh067TbFUxBQ5Ay/kzruOk4yHbKzdxB15eJ1tVCTFaoObF1/ENAyaC3uJ44idtZtolk0U+NiWSbHWIM0yBu0ddNOkWJtmPOjQ7WxjFsrkUtDafxvFKGZnbR3HsVEtF13TGQ8HVKslLMfl3PPPMj3ThCxl5g33cPjYPjafXibMBc2yizfyUCxbXrh2g3sP7WVnNMAwSpiWjhJIukOflY5PpGjUW3WKNYFl6piGTpgkuLU6BwplrEJMIkFVMtbXu6wOx/sB+fM//yw//+yzOZADPPlT3zLfHqUPffXy1jddWOu+KUmyRnsMNzZ7cZwkcnGmRVVzWB0o1Gv2bZ/87HP/5u/c4/7A0vwbwvZ2dOjsF65WPvXbWxc/8mPv+e0+xr/6q6dOrf0XRGnCXx6T+zARpG9wbkWETF2hO4zwwxjb1JAItntjGmWX0cijWDAoWDpeEOP7AVkuSaMYRVFwHRs/TmgJjTRNKBULNJt1wiCgv9FG5CndIGTPlEOrWWPt5ioySwmjiCzPidMc3bTwRyOaMzVRsHW50x8SeR5+DG5zHs1w6a1eRjEsVM2g1+tR2FhhPBii2xYqGW6xtFu8MD2Dik0cRzJH4eqLXxG+51GuN7n68svcecdR2jdXEKaD6xj0ttc5/ro30llfIQ99kjhDN3OO3ns/gTci8XqMvYj6vmM0zt/ki1d2mK5VILfk/mKTom3iC4vpwwtcfeZF0rTIwUqZqquxfX6VIFP50oWbHJlvUis7BGOPYrVJlsa0SoIsG6Gbs/RGGeWpGVIr2Scvf9zk0NuTu/7GdyzsnS4++vlnr7zrMy/svKFStKZWdwJeuLrJU+dWIsd2lHqpoI6DkI2tNrqmypc1wcc/s56sLV2Xj9x76IHnrnaIzq+hKko2XXXvee/r9t7zrre8+tte8/iJd95117nl8+dPKGfOnPlTd4eQEvHEEycFwBNPnJJCTB6sEyaCNOHPwDjM4iSKEUhmigYX1voyB5HlOaqmEcUJQ88nR+C6NmEUgxDYloWuqNglE5FnZIBtGnQ7PTw/oFqrEEcxrqEjJXhjnzTLMUwLx9QJ4pQ4iAiSiKJjEMcxkSKJNzeEF8Qs7pmjt7WO6zh0eyOqYYxQNUzLJAwirGKJOPBJ84zm4gzFWh0pVDRVp1ytE/lj4jiUpm2JTOaYtiW9wUAkaYphZMRhSGNqirWrF5B5TjTsYjkuimGg+AEjz8Mp2yiGhqZEyDjE1lVsDdlB4fxLL9E07+DgPknaXsMSGakUtAdjmpUCRdsUZiZwak3e8JaH6V95nmcv3OA1zQX67TaRl4r9h/dy7tOfkfXWjCqTIGu2Kkfve/MHfs/Ulfjb3/bgwS88157/nS9dxnZdXMeMNzZ2SNJMAJrn+/hhhGsZjIKQ3tCDjS1eeumS8o7798unrrSTlY2OtE1V1IoFsdkdJv/y155JCja3FxuVHxV3/+Jff/Lkw9qZP8WaOXkShVOwG0rcdVmnTt3KUZ27leeaMGEiSBP++2N2+ThPU1Z2PFlvNHEcm87OgIJp4LgOMsswTYPBOCSIYlRVJU5TVEXBtEwZRzG6oYs8TYnTTBiWKQ3TREHS80LhuEVMXaWzuc6emSbDcUCUJGiaYOSPcR2bZqNG5I0QIIrFEqYZ0+/2mJlfZNhtI1WFOElIshxVM4jiiCQJicOYSqPBsLs76sGyTVANVNOmt7NJY3qecDxG1XXm5hZYv35Z+n4gCsUSw/YOR47fTntniyTNaFQrgCTPc/I0xdA0fD9CL85g+CVCb3f8xHZvzGdfWmauWmBpdYtX3baFY/r011Y5dM+9qGFM14uIUoEXpbhCJUoFnb5PtVZHF4pozi0wvvk0442U3kafCy9vUa435B33VM1D89XXvnxlk3//sS+wsjOKYilpViLF90wVJDLPSdOENJMEaUYQ6YRRxGA0wjR0MQ5iPnNuQximJZoVl4HnE6cpdx89LG5ubOrdnX58bFp86NM//Z2/9ujf/MjnXz55wjj2xOnkv7XQ4eRJlFOndkOJv/WPvnd6ZXXY0ESuNRvVzrc8/os3YVeYHn98N+c1YcJEkCb8iZzbPiMAej1/+OAde3lqaUTBMagXLXF5vUOSw9CPKRVscumhKruVwwogZYaiqSRJQrNZF4HvS7dQEF4QUddVYRgu2+0O3nCI7fqkErY2Nym7Fqqi0fd8dE1leqpJHCeYtoMqBK5r0u8Pue+Be/nqc8/he2OcQpH9R+8kyyRJ2KFcqVJq1MmiENUw6W5uoVs2URhgl8skaY6mGyLPkd2tTXHgrvsZ9Dr0dtrCcgty2OmQ2zbNmSl6vT5hGFOpVnDrTbydDcwoIjYM+jtt/OGQl77wFPfd2SKXksE4l07RYKvvcftCk9sOLRJGPje310jikOeffpqKoxOFIfVqUW7e7IqXrqwQRE/yrofuYEFKyrUqpm3TmrE5//lPcHlN4dL1LoeOpGLf3pY88cid8Ztfczef/MIL4uJqR01yKdr9sRzpIVmeE8UJaZaRS4gkxGlEnqZUCxaDYUAiFTrDMaUi2KZJrVwiTRPWttpEYSKeXfZyUr8U5epf/9EffduXj586E3FKIKVUhBB/3Nn8P0rFT50i/6nvfd2r19rhj37i8xcfG47C4lStoKVJ1H/q//yhTxjV5j+57/FTL8rTp1Xx+OMTUZowEaQJfzIb3n0CnsUtuJ2l1R022iMxN9UgTxOQkvV2j1atRLc3xAsiDF1jPPax7d2JsQqARERRRK3oiHqrSbq5TRjFSEWj1Zqi3xtgFwoEUQyA",
		"bVsEYYJhGqiKij/yMA2dQbeLEAqGoVKolLm5fBOynHa7g5AZlUqJLMsQikIuc+IwxLQdkihBACtXLpELhdr8HizbYOfGEqN+V/hjn8bcAmNvjOU4jHbWhMxTDEOn0ppDN3XGly8i8wyv2yGLI4Kxx9TCHoLBgH4voT/00eqvxbAdVM1HUTXRLLsEcSr9JMfLVMJIw3QLeL0R28OMOEpRLIONzkCWqzUxO91keXmV2VaVfnsHd3oPan6R1XbIi9uG2HtgL1eWN2R8NhdRmKhasc6bHridR+89yjPnlvhPn3tB9MMIRQDyVqUDUHUt0jQhiHP83piKpSEFRHHMTnd33t90o4Hr2Nzc2KbTH4ivXk7V5fuOxW++a+qbHrWTL77t1Lf+255S+U0hxPLpEyfU/3N7W7TOnpVndhPtr7gmceIE4ujRk7LR/dJPfun56z/WGcWK5RZyIPc2h2JpozM18oLvfcsj97z3/G/91PeIdz3+a08+eVJ79NFTr4jSJL804euaSeugPz3ivtlZ5dmNjfz1R6aP5Eny7qudIKsVbUVTVbG0MwYk5YJLLiVDz8cwdLJcoggFIQR5luG4DmmaoOkq/U6HNEnJZU4Y7RY4OIZGGCfUWk267TamAuVyie2dHjLPMQyNsmvTHQwxTJ0kjLDc3XET165cJxkPcYuF3S7iUYJhOwy6XVRVwx8NybOcMPAhTxl5YwZDj+m5edprN7EKJZkmsTANA71YRTUMZBxRKBSoNqeoTM+TxhFSShRVQzccTF2hWCygmxblapXRzhbH772P+SN342+c59nnL5PrlthsD5FZQhIEaOGQIIy4sjUSmqaSRAlRJvGi3Rxcrz/A1gRkKXsXpsTCQp0oSygqXX7iX3yCc9spH3rvWyg6ptCKddFJVGw15fjd9zA1O8VsSeOhO+cY+Qk3tgcgBKamig+/+W7xvW84RtNSePSuveimLs6t9YjznDzLGEW7E3plnqEIlXEY0Bl4HD+0jyMH9oiul8kba935mar7jgfuOfgdP/D+d/cf/fH/49nl5eX8/C0x+vCH79Pvu29Wedfxw3rz0Aey1zRW3mHE/r/aWN1JTNuJjxzYLwqFoqjXKuxdXMgv39yKtaBv3zZfes+P/uh3XLr3kb/78le+8q/1mZ//LXl2sucmTARpwn+Ndx0+rJxdXs5fd3DqYLNkvPfl1UGuarooGhpXt0dC1zRURcGPYvI8R1NVdF1HCEGh4JBlOYamScs0UHKJUBXh2DZZmmCbJmkckScxjmPR6w2wHZuSY7K9uYNumWRpRuCPkXlGmKaocne8eGenQ8FU0WyHnU6HRq2M67oYpoFbq5MEIZmUIgwiEUURkt3SrsV9B9B1jdAf43lDRoOhaE1PYRYqcvbIvWL9xjU52NmgXK4IkDTn5lm9cgVFN7AsC003GHfbTM3PU6hNYegKg+XLXLu+xD2vugchQ85+6vdx6y1xc6vN0POEpcA9B2pkacZyZyyyLBe6puKFCVLRcB1L+GNfpEnC3vkZbj8wx4MPPygaMy69G8/wf5y5gKubvObuo+iWy8LiIlaxJD7x259kfn6GPfsa/ON/+3EGo4S3P3iEA3NNLq5s8thtTZGmCR/70lWubo/wo5RH797HHUf2cGFpk2GYkiOQUjJdr5DlOSubbVrVEqSJGI3HQlNUMYqz9OJKJ61qSeXQlPZNb75n/1TYj/I33XnA+O63PxL97//yk8Gzz27kZ19YTs+ePSsrsfcPhD88ZmhKtNHPjECqoueFwi3YYm66IWZadVVVSDsry3q9pL/7Q9/55q/e96a/felzQsjfO/mwtveRZc6enTilCRNBmvDHaD2wLM6fR+6rueWao31gteeL3jhlulrg0kafKE6J01QIBEEUI5Houo5h6ERhhOu6qJqO7Tj0+n2SJBVpmpHkgjAI0U2TLM+IU0lrZpbpegVNgbXtLnv37yOKYxQJB/YuEIQJ5aJDwbGIkoRep0+x4NIbR0Sex9zsNGmao+g6uRTopiUU3WA8HOAUywgEQtOQQL/TxrIcaq0WkT+WCjnry0tEoy6moTHstIWhKWRJiqopDAd9Rr0u9WoFVVFwShXyPKO3ep21pWtyZ+DhjLYouSGjYZ+d7T7dcSzGY19amsJdB+r0x6loDyJUVSFKMtZ7Y2zHEVvtHkGc4lg6uqqh5YmYX2wwd+csn/jYJ/jFT1ynUrAoWRajcYJbLFGpV+RHP36WTs/n4KyD6Zr8wke/TJDAPQdmuX2xzu89f008da0tO0HMIExY7fk8c2WTsuvygTcdpj8IWO167HZpleiaSpikHFqYIcszRiOPKIo5tH9OSXKhbHX62V3zRl405YP3vPr4d6+s9t4vyL/9La86eOz4YqNSdtzZDz508K39weD7fuMr68azKyPRC3ORC51GqymGfY/bDs6jyFwWXUMszFSyspEa+1/9hve+9u7j1mj5xUs/9h8vDM6eRZ48eVJptVrKiRMnxNmzZyfiNGEiSBPgxAnE2bPIN9+7N7MU+d3jTClt9HzZKFhiaXuA4zrkgKYoYhxEVMtFxn4oVVVD1RRhmSZSSjRdQ9c0hBBCoqCoCkNvjK6rqEJQKJfpdzpcX7rBVL1KoVQiTRJ0oSCQ+OMQ09SRioZl2wx6QxYXptBkhmlZbHd6lEwNP44ZdDqkWY6qGyIOQ7I0xTBNNAWyOMLzPBqtFkIo9Dtd0tBHN1RklkCeI6UgjiOhSYlm6CiKSp6lpKFHbXoKwykgZE6WxhRrU7LvediWwWjoceieV/Gab/1OLn7mt9hqD0SQ5Mg8RQe2ByEomshkTpSrXN3siVRKgjhjrdOnaBnivmOHxcJ0E0v4LDZTPvJbz/O559cxNZVxEHH08CFc16XXHfDJL3yFeq1Gw1WYdiSfe3Ed3TTpjmIO7lngA9/+ZnF9ZZOV7R66quw2Y5WC5a0+/WEkXrtvmlEQszX0SdMMkecIsesl4zgmiGJMy6A7GOONA65vDMTV1RH9fpw27DQ/cvu89e8++uXW2Ate5Zj6tx6Zr37XvUdm3/W7X75ufPXmQCZ5LpI0E34QCN8PcVyb1dVN9u/bK9BMllbbQlXU3E762v7Dex5R/Ozxxx86Uv6Bb3798vf/vZ/tnT9/Xt4SI3H69An1BMeU0+fOc+rUZF9OmAjSNyRnbwX15y5t+q2jc9/S88KFcze7+cGpsggzaI9CwigUYRhjWwZJkskcMHSdNEmFW3BRhBB5ngtdU4QACuUSeZZjWwa6qpClKaZpYLk2q+vbZLkkS9PdXnbmriAolsXmdhuhKPh+SLFYwHZMtrtDDFWh0mhQcE2SOGXkx1iugz8ciiSMKNeqZEnKqN9DCrAME90wSZKYlZVVFCFEa2pKxElGliaMfZ9hfyCKRRunUAQJlVoF17Gxi2UiPyT2+hh2gUqtThL4qFZJdgdDUTFUDhy/gyOveR1PffxjPLc0FAvTJTqDgCDXRC4FUS4Z+rFoD33CJGNn6BMkKa1yQd579AD1ckEcPnYEO1rht568zLOXdnB0le7Qo1R0ed0D97J09YZ46dJ17jyyl9v2tEjDIUtbHmgW1ZJNkqmEQcpb7z/C01+9zDBKAITMpVAVxDBMpJ/mvPWeQ4yjhNXuCE3Z7SAuESiqhmloNGs1hmOfTn9EEIaUi2VRKrrK/rmW2DdflXv3zeXPPX8tfXlpKx+FKU9f3Mg2B5HojX0lzaXI0kyAZOB5ZElCu9OjUHC4+777ELrJ1s5IlC1D1vQwnWlVakvXNx/57LOX3//QHfvufucDh/nnP/p2/+c+9uX+mTPn5Znz5+WpU3DixAn19a+3tf37Xy/Onz8/2aQTJoL0DYQ4ceKEeub8+eyddy++KYyyO75yfTs9umdaGYcxS9sDYWgqWQ6moWPZlojjBE1TSLNcpEmKpuoYug4yQ1F1+qMxQRQh5K5w5UCW59iWw/yePQRBuHuwVlHwxz6mZWIISa8/IIhTNE1luzciGAdkCLww",
		"wVAFvh9wc6vHzNwUluMQ+r4o1+okcYRpmCRJQpxk6LbLeOyT3BLCNMtQFZUky8TG6oaQSCFVHdMwGPsBgTckHPaZ3bOAphkUCo7s7WyJuT37EHnGoNvGNjTWtzrEcSbcoMtUy+XoG17L5z/3AuN+By+VmKYlJNAb+li2iR8mjMKYcRQjgT2NEq+75w5hWbpcPHqnKJbgN377S5y/3kPXVYZRyuZOm6alM1Wv8ZlnXxLPXVllY6uDRk7HS1jZHtHvD7lxc5ObNzfRsgTSmBvbfRRFFVmWEWUZQRTRH4esd0c8eHhebHQGdP2IJM+J04w4TVGEgqHrdAdDysUCi9NNSo6BzAX33X+7WL25IwqGJg7eeUj5pY89pXS8iIEfiShNRZpkpFkGAlQFTF0Xpq4JQc7FS9dJ00wcvf021tc32emNhaEKpVwvZAoyDTO9oGjWHY6pP94Pku/5/ne/7s3vfO3Rve9+8MjsN71qr/8Pf+Gj3Wef3cjPnz8vAXHy5MPaI498gLNnJyUREyaC9PUvSM2mcnZ5OX/ktta9tqE/tNIZZ0MvFALwUxBCCNsyydOcUtElihI0TRW2YxPFCYamoekamiKIoojByMcbj0GoBFFEmqWESU6WZqiaRpJmpFGIadlEcUQwGqAqgoWpGqVSCc8PMHV1d6RFuYRAUjA15msOy+3hbquiwQDDNHGLJWQSUaxUMEwLzxujmyabG5tEcYRpWvhBxI3lFVxTJ711hqdRLXP12jJpkmCIlGa9xOyBo6Ao9LbWUIRk2O9j6Qrra2vEcSoUVRH/5N9/XFq2K/KdbQ4vFPi+H30//jgSL714Raz1AkZ+iB9EBEnGOIxBVcky0EXO/QfnxfHbD0vTskRFi5iZsfjljz7D8s0uiq4yChPCOEPmKXtnZ/jE018lyzPRcHVRdQ1xrR3QH0eMRj6WpuHqBvfedZTv+/73iLNPPkM/TEQic6QEKUEVgjBK6A09YagKmqqh6xrDIIZcogIl1xZ+GAshc2GbhlCEIhBC7HTGdL2Y33/6IntqJkcPTPObX7gociRhGBGnGZmUZBLSPEcRAiGlyPNcWJaJQNDpdMXMTEsYuk4udGrNhphbbKp3HT+cFUq1dBxm+Vdevu4O+uMDaSoeHY2D97rF0ne98/VHH717T2vm9bfvD6eP3r/9cz/38eyVPNPpEyfU0+fOcWoS15swEaSvT0F6ZO9e5ezycv7gwdZ80Ta/5erGIBuEieKYKgM/plmviiiKsW0LXdPJ8lSAwDRN8kyi6QbkOe12F6fgoKoqQgjKlSrb7Q6KpiOzFMs2MU2LQb9HwS1SrtYwLJMkDJmenSaMU1RNJ0ozNrfbNColOt0BfhBSsHXWdwbEQcjlG2u0KiVUTcPUVYqVKkkY/MEb+2g0pFAsEgehzKUQq+sbCEWh5Fh0Oz32799Do1KgWTDYuzjDTrtHmmU0puqMun0ZRzHbnR6zc3Ncv3yRQrlCa36B3tYmKIqQcUyl1qBQLNG9epG3Pno3j967KGacjKpjEOklXryxiWlouw4tSSmrOQ/dc4RatSS21za4784ZKrNVPvapl1m5sSWLRRshBWGciFrJJZM55y4vcd++FhkKVzaHXF7vCxVE3wvEfL0hbts3L+LAF40SNIqG+P2Xb1It2ERJipSQZDlxltHxInq33FG16AqZS8ilUATCMXTGUYRtGsg8R9MUrq6sUyxV6Q3GxBmo5LzlVQcoWRaffv66CJMMKSDOJPmtcoScXORZxsgPyaWkPRjxpefPE4YRtUpRPPPCVdHvDsRUxZS1Zl1Uy0VVSwLlVXcdyH3fS7/03JXs+non8+O8mGTiULs7ekucZe9/9cH6u9/9muPz3/no7f6v/psfaB//qz+TnDp1itOnT6hHj/65FkSIkydRWq0TrxRaTJ4MEyaC9JchSK9U2t02XRLk+QdQdG21PZK6qogoTkAKESQJSZYhhEAAlmmSS0kYxCRJQi4lqqbudtoUCkmcoqqCPM+J45hqtUKeZqRpQp7lWLbJaDggi0IAojDE9wO6/QFxGFEuF0iSjHKpSJQkJFHMylYPSxNkUrKyPWShXmJrq00UBERxQqfTp93tY1smaZygaBpJkor+aMzCbAtNCAzTYDQYUHQdauUCcZKx99AhZuZmMCwHt1AQtiJo1ato6m51Wrla5MDhg2SZ5P5jB5iZakKe0fciXrqwQXdjh8fe//3itW96I+9482v4wPe9kzjKePILL2KZJnGaM+2ovP3RBzhy/DgF12Rw+Tnmjx7h3NUt+fLL19BMEz9KsHRN3HvkIN/53d/MV59/CUHO5c0BGZBk4Do21XKRu287QKlo8szl6/z6735Zdvu+GESS2WaVvTMtio4tmqUCB2eb1Ao2g3GAH6fEcSIMVRFxmqHdul9SSlRFQVEEiiLY6AyYalSxbJtxFKMIDVXTeeD2BV59fD8vXFkVnhcJy1CFIoSQCJHlu/c9RdD3QwTQbNbww5gbqxsM/YBGq8nSjW2Wri4JOfbQ1ZT25rrYM1tV9syUFVdFtBrV3Lb0zLWtFCGMoR8tbLRHj1xf7X73hZdX3/Ndb7yz8t433bv8XT/yHwdnz56VJ06g/vemmU6ePKn8cKulHD1xXjzyCKLVOqGcP38+P3sW+UcKLTh58qQyqQCcMBGkv2Be2dDf/cDhwXLXe69tOVM7wyCN01QpOwZJngnL0BlHCVmWYRkmtmliWbshO4AgDNFUFddxkDInCEOyLKNYKJCkGbZlomkqgR8Qp7tj0LM8Q1VVNE2n743Z2NimXq+RZimOYVAqF7mxtkkYRJiGhqaqWJbDnYs1BqMhy2ttvJGPRGFtY5s4TZmebpJlGWmSkGZS9Ho9VE3HtC12drrs378PKQRrN25gmiaKVcQqVmi2WlSaM6SBh2WbQpE5fiqYm5tB1VTyJMRVBRgWWZoR+T7eaIRTsKm4DuWyJVA1+l7Ijd/7Vb7zHQ9QmNnHRz/5NGQp3/TgQQ7vX8R2y8ztWaRSLlBwJN2x5LlnXmKU7IbadE0Ti1Mt3v3WV/PshSs8++JVGo0KUZJRdB0qlSJH9s7Tqpd58tkXePHaGrkQDIMYqWii6NhEUSQ1VVAvFakWHPbPNjk8XxOrmx0xjnbzR2m+O+Q8kzl5DpqmkktJlCSyWqlwc2ObZrVKmKTCC0LCICYLIo7vb/BXP/BuLr18ie2eR9GxSXOJEIJq0SWMU/wkE1GSYmn67gZVNY4c2MN4HFBqNMVmL2TpxjqzrSp75hpsbe5wfbVDmiaiUTFFFEaKzDJlYapGydIzw1BzL0j0KJFzhm6+2bTc7/neb3po/sd/8FuXf+Tk724DnHz4Ye3s8vIfdJT4oy9cr3y964BQfu7nzuZnzp+XZ88iXxEhKU8qK7/fvvPNr7vr+P/6vW+pnPnUVzbPnj0r5cmTyqmJKE2YCNJf/HX89IW1uGTo9yuads90vZze3Okr+1olel4oZJYR56Cquw+ZXObouk6aJmR5jm6aMsslfrCbe1I0DW80JsszNE1HEeyG+Nh9y5dSIiVkryQ8UHCKBWzLIowihKqhIMgB23VuNXG1yRDEKOxtFmkPRpiWQ7lg0xuOOXL7AUxDI45ioiTFG3mYlsWBfYu4BZdyrYZORjbsUrRVSo0WzcV92IaGaehEYYDvDfD9AKc+R2VuD521G9y4fAHLKeI6JpVqBTVPMTWVJJPCDxKxvd3l+ae+IozRCitf+BSf//IKWeDzXY+/gQcevJe33rOHNxybRxo25dYctltgtL3O3GyD65tjXvzKS5QrJcIwFooCC7OzvO3hu9nqbPH8i1exbYvu0Mc0NCxDJ4kj+ZWXL4n+0EMiKDk2pWJxt2FtFLG23cEbB8RRzP7ZFseO7eNtb3m96La7nF/eRChi95ILyDNJkuW4jo2hqlJRFcbjgDjJaDbqRHEirt3cYDSOEapgZXldKrEv7jm+l489eQ7N0GQuBUXbEgXbZOAHJFmOAJElidCF",
		"FGEYCSl2u8QnSYKum2AV8CJEKjSxM4ZxbpEIjblWmTc8dC/lYlH02j1RdC1lrlFQ7jjQEGmaZl++sJpeudkurG50X720sv2+b339nZXve/ux537k3318DCgnTpxQXimG+KPCdALUnztLfv488sxPfs+x73nna+69f6FWf82h2alvum/xjf/mnz33L1Z6yU8UiuUPmkJ83/e85Y7XvOeRu5+5+9Q/70iJmKSsJkwE6S+Qhx9+WL1x40b+hsNT5e4o+BbHNvObO31FVQRhnIo8z9A0jVwoaIqyO6jvVneENE1BCCzTIs9zIWVOkiTSNE0h2A0DSUDKnCiKURSBpiokSUIQhBSLRfwwRldVZJaTxLsHcIMo3p2XlMSomobjOqiKSqFcJlM06iUXz9sdBHjw4AKVSpkkTfBGIwSCJE5wTIPWVBNDN8mSkGDUJxh0mZtuAgqGqmAYGn6vTRL6XL56k2vLGyxMVehurRP0N5luNUgzSegNSf0xw/YWz758XewMQ4bDAbYKg84O/sgXwcjn6StdTLfI8UMtDh2cZr87plDQsZwSF69tyLk9+xkPPIYbN+j6IS9fXOHhV9/BwnRL9Lp9Wo0adx6awzQiPvv0ZZIsZ+hHSCS2ocvrq1uMxj6KEEJTFWmaBpqus9UbMI5iEArInJl6CVMXXLh4lYvnLot23+dme4C81SQhl8gcKYQA0zCYbtYEeYbrWLiui2maDL2xSLIcU1c4v7zBZ756neXldXqDMV+8vkOa57A7sFF0hmPCNP9DiyJ3/xFNgJRS+OFudWW56FKwLeYXZsTFGztcWN4WUijolsXzX73M7cfmuPfOWfHyMy/heR5xHGM5OvWSIw7MT4tSwc66PS9eWt2yur3eG7q90bv/2nc83P3PZ8+9dP78OXny5MNaq7UbhgY4CeLnIP+Vv/VNs4vN+j+Uqv2zhxab33/h6vL7Op3e92wMgu9YH8rFWnNaKRbdzBuHwtY4cu+R5jf/1E98x2fs2U9tP8HEKU2YCNJfGB9YXuYsyDvma2MNPrjaG1tCEfLmzlAUHUvoCri6gqJqpFKgKBqarqOqGkII0iQVmqoIXVN3cxKaiu8HQr11YDMII4Si7HYxCCN0XSeOU6I4IktTkiQlThIc1wYko5GHUBQUTaPg2MxP1/HGIbppMBx6DPoDchSaVZenL62QZxIhM8JxgK7rZMluaXq5XKJUdEmSmPbGOlkUcPTB19CYnqHcnKY/HEPs7z6ggW67S6FcpFR0hCpz6rOLaMUGF6+ti2trXRGkivjE7z8vbrb7rG3tsLyyRhJGDP2IQSTFhiexqnXGQUZVDKkfOsLIj+icfxZhlTh/eQfHKTAcjkQBD+Hq/OdPv8C+2SaPPPRq8YaHXk17u82+2SJZ1OdTX7qKY+i0qmVZch0urmxiGSpBkqEqCs1ykd7IR6gqBcfC1HRMTdkNn1omzWqJpc2uOLeyxdWN7m4OUOymjlQhhJSQS7BvFaZkWSoswxCapouNdk/c3Nhhs9vnniN7+OHveAt3Hphnvl5mrlVncabJ+eUtvDAhu+V2Bew65FvrKslzJJI4SUizVBimiUxSBv0+860q81N1oQIyjUUSxbz6nsPcux+uP3VWfOrzS3zqxQ0GQcbnz2/RGQs6XsDC7BRzrboyO1WXaZYlo3EwE8Xpe3/oxMPHT7z1gYs/8hO/tnn+PPLJJx/WXms21NG7NuT7j79p5uLN9u92IuMdw1ToH//sc9lzl9e0XiTMYapnumWnge9x5fqKsr3TFSs742i4tdFw0lFr3+sunH7ih1vKqTOTM1ET/mQm3b7/HDgFuZQIIa5d/9tvPfb8IOy+wY/VTCiKaI98TFXB1DJqJY2eF5ELZbfcFzAtE8W2SJIIoajkWY7IEbuvyAJd04iThDAM0V2HIIxQFIUkSUnzFDVNMXUDVVEYeT5CgGpZux0iVAVVUdjY6qLqBlmao6sKhZKDY2hM1WwevG2G82s+9xwts7ndwR+PySVUiwVMTYE8Jwk8xv0u1akZKq15LNNEjnYoOhpZArrjsn7jBiNvzHi7S6vVROQZqztLrG1u0+kOWd/pst3ps90bMA5C8ixHVVVeWu2iCjB1k1q5wN1H9rJnbooL14dMXXyB0r7bMZvzpJrOvoVZyDOSJJeqFvPaRx+j+guf43e/+ALdQch7v+UdvP3Nr2PrwlP4QRfDMFnd6VG2DbpegKkJNCFIc0mt5FKrVQkzSac/oFZ0KZoajmlSLhUI4pQvvnyNvhfwyhx0XQBSSBRu3SAhkJJxGKIIsDQFy0gI/IDVnT4LUw0eOzDLOx57NZ955iKjcShkmsqpusF7Hr6fh47v59e/8BIf/cJLGKpCnv/h5Iqc3Sq8YZTgpxl+mpKkEoGCpgh+6dd/l6l6hXK5gDf0sHSDoq3hvvdbxC/9zG/yq19dYxDD2jBA0w12BgGqIlhaaxNEuSiXi+LOg/PKG15zVzz2PDn2x+8tKuLNv/pT3/+Lv/rpr/6zRx89e/2Vz/Khx9a/s+vFtw8COc6SyAiTTEnTTD53dTVfaNVEtz9SN4feH3z2WtExzl3I0zv3Fd8uv/Tjx8SD/+DcbjeJE3DiRP7fOjdqwkSQJvwpefzxEwqcyWSefXSqoL3hxdW2bBZteuOAOM3xwgTX1imbkn6qIZTdKrpc5mRZTqFQwvfHKKogiVOEojAOAsIowjQNkiTB830M3WAwHKFqKpqqEYUxcRwTxwlxnDDdqqNqOt7YZ+T5kOfUamVKmkGSpiRhyCAMKRYscgGVokvVGvGF5y9x95F9bAcRzWYdy9CI44Q0icmRLB44SLk1y7ULl5iabhJ2d9AUSbfblkkS4/uhOHdtHduyefml8yRxLK5eW2bgR3K178udUUCU/sFon1v5iQwhdh/qVipBSFa3ejx4x23MNGusXlvjsCmYOnic5TWfzZ0rHJuaYWq6iR8I2pev8I6H7+Kn/vFLyDxneXWdxVaVIw3J5fYIBdB0jXKlzOvvv5OSpTEYjXj2wjJCKPhhwrHD+7i52eby0k0OzNYp2BbnlzYYBNEr+RwJu+fJ0jyXCq/MGBcot/7Qv1WcIm2DzsYO5UKB195xmJJlcfTAXl64cINnzy8xCiKGnicKriM/8eWLLJR1/uXfPcGBxSY/85HfExVHR+aQZlLm7DomKXd1L4xTvCDgxtoG8zNT9LwQy01otSzWxm0iMxerW32WVrq8ODS5MUzQVYWwN6Jom4RJjGGYeONAjKMEIRTZ98Z0gljxPR9v7If94dC95+DMX/uR73rz+77v8Td+aun60kd2PPOLH/vUp966sjmQkOuaqgpT06iUi2K6XhSGpfPm1x4liROqrk0QhFimznSrnk8tTjnXl4O/8vTH/+lPv/odf20NzkgAKU8qQkwm4k6YCNL/MI6e2d1sVUv5TVlxTi6UzeIglvlMpcil9Y4QimAYpFQtBamqZIqKoqkYuo6f+MRhiKooux3ADZ0gioiSBFVRSPNstzNCEO2+l6sCVVVxCzb+LbdhmQZSSryxT6lYRAjQNB3LNNBUlXEQYOkafhBhmjqqblKpN2lWiwwTwY2NHqkEyy3gBzG2oWM5NgJJsVDAdotYpRJpFHLxha/S7g5o1suy3+0hNB0/V5jffxvTUxVefOkCL1y4xtBP8KKEONsVIiFuDSPaTcTsfokkB+IsZxxGbO7ssLq6xWvufhUrl3fwvBi97DC9f58snFtFty3qUy00dY7W4oJ4LHXlPy+eFtu9ESvtIb1BHyFbPHmuQ6lgUbYtev0hozDhsYfu5zOfepKhF2DbFkQR11c2WG33yIBaqcCe6RrPXd8gyfI/+MwCyKSUQog/aLOtKLuHZ5N818nEWY4fJUihsHemSRxFLHX69Pp9mq065YKJN/aoFVweuvd2dJGQJylffeky//DDD/O5r1zgxRs71IsuaZrf6q2XEcYx9q2eh3GcIBTBxnabeqWEa1kMRwH79y3QH4ywLIeCKXjf",
		"tzzIp56+gEQQJBlhEuy2mtJ8XMvEcRyqZVf0+iOe/eoFNE2TUZhopZIrv3xxI7q+1qvtmal9Z8XIv1NPhivLW4OZjVEoi46lHt+7IB+88zD33XWIcDBEyzNCfwx5Sp7lOKaBbhqojqOuDpU00sSPqL2b3/Pcr/y9rybj0b/bc3z/J4T4/2zdmoibM5nxNGGSQ/rz5yzIkydR/v7P73Qe3Ft/VRjnR7eHQZKBkktJmGTCi1IcTbKn5tCLdm2CquzmiUzLIs0SFEXgui6aquBYJo1alShJyLJ8t6TbsREIslzi3Kq403QN0zAQCMqlEkmaYNkWrmWhahpplpDECbqusXdxFscy2NjpUi66SAmObbO8vo2uCLZ32lLXNOJhHyULhKUr5FlCv9tFMSxCP2ToxwTjMf7YZ3MQ8qVrW2QoZOFY/P7Tz/PlCzfojCOCJCWXEuWPPMj/7w7plcDkbp84ISVFU8Ufj5lq1nnV616F7/u4pSZGeQZT02hvbpGmkgsvvCT6vQ4PPnSPOP3RT7G0OcTUVRoVh8vrA3rjiJ4XMA5C/CASV2+s0+9skcYxqztDquUSiiLY6Q/xghBH1ziyf47ZeoWLS2tESQ5id7rvbpfB3c+sqQJDU7E0FUBkt/RVFbuOab5Vp1Upc+XmFu3BiKlaiWa9vFtwkiTcf/QA07WyePtDd3Nk/xz/6Xe+yKOvO85cvSB+5TMv3soZxvhxQpykIn9F8NKMLJeYqsCyTNIsYzz2hWkabG13iJOMOEm5cmmV19ze4NLVDW5sDzBu5SFlLomznCzPyNMMkKRpimMaBFEk4iQTSZaLNM+Vc1dv5jc3Oul6u5t//uXlml0qifc89hoef+ebOX5or6gUbLG8si4uXV3l6vIm19faBH6AoghiodANUraGAX0/E+udsRRCcciyfZZpfHMy6H3XD3/vW3qPftu/fO706RPqmUluacJEkP7H0GqhnD+PfMPhxmCr539XlEoZp5kSZRmqEAIE4yhFk7tTWmNUDF0jDEKE2H1wRHFEoeCS55IgCDENA0VV8PwAVdFx7N3ZSLkEy9BeeVgShRFRFKOquwPyVE1D13WQOcPhCNM0yPOcMIzRNI30lhPTdJ3B0OPijVUi38cyDKGqKp3tNq2pJm65IoZ+RJJKUA26fY9GvUaSJNJyCjx/eYmtbh8ZBbx87abYGIzJdqNM/8/Z3X9MkHYHuos/qDGWEmxVYapWYugFlAsOBdOUVmse3TDZWlnDG45BCGG4RX7t9K9zZDbmhYtrLN3s0CxbbPR8NkchgyBGFYKSaxHvNqsV9bLLTK3EVt+nWHDQFIU8B5lnFB0Lx9TRVZXLK1sYhoFl6LfckMorRSeuaWDrOq5poKjabmWeRCgCHNNkulFHSsnyTofeOKDsWMg0pTcYIYWgUStjaMi98w1KxQKeHzI9VRfFpM9vPHWNoR8jpRSplCKTyJzd4oZM7tpKRYB6qwIvveU82/2h8PyQguMQhBlpGHJssc4nn71+60oLUBQ0RYg0R0RxIjojX/RHY7HT7YvAD4SqClEsmGK65or7jyyKhx44KmbqZdGsVfNXHz8sVAnPPH9eXLp8hWDskaQptx+cY3GuzsxUFct1MJ0C2AVSxRLTMzOiUKljFWpic7uXXVppp1dWu2nYG1aPH6y/+1u++eGr73j8X714ercX5MQlTZgI0p8358/Dww+j/cpnOlffecf0keWd0V2xFGmc5Eouc2xLJ8mkGEYZCxUbP5HkQsOxLaIwJM9zqtXq7kNQKPQHQ4SQZFlOnO5W1cksQ9VUgiBE1VSiOCbPctIsJwgD8jwjjnZP+/u+TxxH6JpKFMUMh2PCW66lWiqBUOgPPPI8R8oMQxXUSgUyKbEsi7k9e0ilKjTTJohSVN1g2OvR395GkSmDnU1ubOzghSnt4Zgwl+IPKtH+uBX6L4iSELs/vTLnO2f3sGnFNjE0nTiKqZcL7HT7CLuI394kGPRpzi+K/bft44XnXyLZvsJq2+PijS4AwzAlTPNdMbJNykWHoR/ih4k8sneWVrPJy9fWEEgsw6A7GGFoKmXXQpUZnV6fjd6Y2WadNElIkhRFESAQhqYJQ1VBQphlSCEIoxSJFLmEaqmAa1sMRx6uZZJnOYrMaVQLzDarNCoFVra6NEouit/l2sWLbA0jXvOqY+L8V77Mxc0xN7tj9N2zTvKV6yJviTUCkny3A4aCRFM1NE1gGqaolkrUKkVklrPZC9g7VWSuYvOVq1u3vl+SSUkuJa5jc2TvDHccXOSx+2/jtXcf5q5Dc7zq+H7isc+RA4ukQheXb2wJP8rEKIi4eH0VP/R57d2HxB2HFtk3W6dWdinXmqSaTakxRZjr4v/P3p+HW5bed33o5/euec/7zFPNVT1Uj+puSa2xW5Ysy7KxDbiFbYhjgxMSIIC5BBIS0ipyGa55wiXPZfQlJGBiQG0QtrGMZdnusiZLrZ67q7prrjNPe957zet97x9rn2rZQELuE4GBevvpp/ups8+pfdZe6/29v+/vO2hxRCyb/c6Ql1+/LC+88BK3bm1SaK0O+6G89vZWVjMTefjhE995+uypz/2Bv/6/79x1dbi77s6QvjXLLEzTPG3H+jP3rbY++rXrnRnLsUyWFDKJM2qBayZRKuuHI9ZmaxzkOb7nYtk2Wmsmk5BKtYJtWcy0m6Xx5nQGVK9VwRhcx7lTcKqVirFtG20M0SATPwgwUrovtJp1jC6oVipYoggqFebn5pmMh3QHQ2zLwvNcWs0GTyzci0vKl776Ku3ZOarVKnGaS7vVZP+wyySM2TvsY9kWKk2ZrbqyNRqazihilOly1mKMMcb8H7dF0/8ThVGmHImpKWypjSEpDMqr0GzUmWnV6Q1jzq4eY/f6JTl79jRvvPgiK6eOkQxcvu9jj9Jwe1y89AWKAqJMow2UZqgWeV6QJBlKIDeGi69cZeX2HmGSMtOo4jo2xmiqQZUHTq7wrrNLfO3Vq2z3I5IsozualFCiCEqJ0SI4rk2S5vQnJfvu6PcygO+6xFFMpVqlyHMca8zjD97DvccXsacklv3BhMNun/eeOcli1ZH9yzfZuvSisT1fDnoT1mabVByLJMvkYBSaKCs4uqSFNhiBSZbj2BZ5GGLZipXFJkme88rlG9x/eo2q7/C1qwd8+0PHWWv7/M0vvM2pYys8dGqJ8ycXadcriDb0JwlxksBUd/alr71BUG3w+vVdusMJ/dHE+J4nZxfnOHd8kZXFWcQUhGEkr1/f4tpWl2qtRq8/ZKZdpxZU2NzZp9vrMR6NSfPSOV0pi43dfaIwZGm2Zf2Nz2yn+eSg9n3f/8Hv+6Pw6qc/femuePbuutshfUu6JDBPPYX9D3+10/2Oh5Zj37a+68b+OHNspfLCkBdaPNsiSguanuLsQo3NQUatGlBoTRhF5IXG8zwsy6IoipKNp6diWmMQhMD3TbUSYKnScijwferVCrrICXwf27ak2Wzhuw71ahXXddjd2ScrcoLAYzwakeUpcRTS6XRBG5OFIb3BAI0Sy7IlyQqGozH7ex1yXXDQ7bJ/0MWxDNfWt/jVt3YkLKZdzjcVIvlXFCIlMtXxlLOWEkkqlTcGg1IiSgQlwmKrwVyjwlyzwsrKvNiqkNH+Pg0nJ7At9m5vobOYIg4JfGFmYYaf/9JVwqzAsS3qgcdco0rg2sRJim1ZRFkZGZGmKY5t4ViCawmWbUmtEsjx+RaXrtxiFKVgO+z3RyAgSpEVmplaQK0aEKc59YrPOEkptPlNjgaNwMO2LLr9Ib3BkMBzOH1iBRtjDjs91lZXOOiP5Nrmnjx0clmKcEgjcHnq+75TLl++zs9+9TrVwKUeuDSqPvOthhRai5pSwHV5jcUYI1lhxHcskjgFgThOZTSZMBhPyIvCtGZaRPjy/sfv513338vv/PiTtAKHQb98X7d3e+z3xsy1G9R8x2R5xuLiPAutOtXAY75dZ7FVoeY7nDm+LB/8wBOMJmPeurHNOCmY",
		"n50hKzS7h30mUciVKzfMzvY2Wzu70u8PTBTHYluKLNcURSGD0YQkyxiOJkWS6zzQmbfoxb/4959f//IDD1xSzz13l9xwd90tSN+Sdfs25llQ3kdPvr55e/g7jDErk6TIPddRutBiW0JeFOwNE95zqsUoTokKG8e2GE7GKEvh2DZ5UZCkKeNJWOqOioLA96lUfCwl0y6gFMZWKxU818G2LALfY35mRhrVAN+zGYchzUqN5aV50jRh1B+QZimVSoDvuiRZZvqDMbVajfvOrsibN3Y4d+YUtu3Q6/UZjQbs7x/gOhaWgiSJuLnbp5tkd7qD/7MliOEdNE+YQntqOkNyLEsc26bQmtlmHctoZmZnmAzHqDwlqATUmzPMLi5xOExwgzrn3vUEUZxwsHmb1zaG7PVGNAIP37FJ8pw0L9DAME5J8xI+q9cqOI4tvm3J6sKsKGVTGLi5tcfhYEKYl84OjmPjTLssWylcx+bY4hyTJCVMEskLI7k+YuKBrYSKbTM3N8d+b0AYRdQqnnEtm8BRJGnGtdtbXL6xybsefkDefd9xiEZUXWFuscXbV9f5ua9dZxCnZQxHkjGOEtKsQASxRIlSgjZGDEKuNWmWS5blMoljaTVr3H/2OB944kHe+/h5Tq6tCFjs9BIybbh0dZ3dgx6FKdg7HOLaDo26j0Jz9fa2uGLwPUXgeyR5QWc0od2oMtesUmtW5CsvvMH6/pD1nUMG49Jm6aAz5M2rt9g76IDRVCseGpEwydBGy2gSkWY5RZEjGGwlquJabmGMN0jVrc2d+E+/tjXoP/fc3T3j7rpbkL6lawHU33hxJ12oOLeqrvV7s1ybcVqIa1uIII5lEWcFm92Qx9cq3DgIaTSajMZjxuMQ27KmxAAp48mNoVJ2PgyHYxbmZsSxLWbbbWzLQonQrFVxbAdLKZo1TyquxWK7RsP3qLhQD1yOLc5RGKgGFZYWZ2jUa6VQVRt6o4hKEEijXuPaxjaemkJUSYpSUA88GtWA8STk6v7gSKdTEitkujP/K4dFoKakDhFQSgkiWKJQSonBiOfYiCjSLGOmVuX+s6dYmmtTrfoEFZegWmd2cYlBb0i3P2Hu2CkUKdvr13nr+gaW63L91gGtekCcFUzihGGUMoozMm1wlKJd9VlZmBffdVmdazKJEt68vc3CbJulVg0xBfvDEFGl790gjHBsm2bgU60EPHTmGDudHnvdoViWojAGpQTHUtgIvmNTK6+ncW2L2WaDesWnahs6o5D1/R4L8/NycmkelQxp+Bau5xAPO9xc3+PX39ojKTRJYZgkGUlaRmHkRUGal+GA2iAG8B2bB04v87H3nufb3vMQ3/3RJ3n/I+cY9rpmc+eAvf2OVH2XhfkWthJWFlqszdXwLKHZarHQrtKsOIyGfUyesTLfklolENexZeewQ68fMt+ucvnqLfnqi28RZznLq2u4gc/N9W129jrsdftUAg9TFNi2kGY5w0komdYSJjlRUr7vKNNGBGlW3WEYF1/2ffuf1Reaf/oXXvr9Vy9duqguXeKuJunuujtD+lau56B49lnUn/tz/X/x+9+98o8d0T8QHcSpNtoaxpnJQaqezeYo4c39CfcvVLg6CpmfabO5s8twNOLk8TXAYLTGtW2iKGax3SBLE4bDAQ/ff05sZZnJZILtulgCWaZYXqiRxymTOKdW8alXA9Isx1FQrwaMxlW6wwknVhcotJjLV29iKUW9VqE3znAsCwvD57/0AseXZqlUAxzbZrc7pEgTOqMJYZqjoIz0FjBG7hATvnkdFasp2FSWJwELEVFS+rUphWvbTOJUbGWZumcxW3c43N+jttxiee0Uhbbp7O0yGo1YWZlhuHsDBimDOOeF1zd48j338NkvCGGYTF0NijLWA7AweI4ltYrHcDgi15ooHLPdHZJhmWbVo+4o8oqHNQhxHYdJnODZDpYS4ixjvl3n0o11Ng96iBLyQr+jSULQRoNls3fQIYkjFtotbMdmr9tnbWaZNNfMzs6yMj9jDrsdadsNZn2bJMqYP3WczuQaFdfCthW9KAcgKTS5NjiOTbPqsDjbkLlWlZotPHx2haXZJlocKo02nYM+v/SFr+DYiqXFNo1GjYW6zf7GBllhmIRhaRh7bBm36XPrcEgax4STmCQTnNihZntmf2sfzw3wg4KvvXJFDMLc4gLvevh+Ll3fZBLGZFlKt9sjyXLCNCeOYzzLYDBkhTZRVsi9yzWOLS9i+1X5ng+fM3Y2EF9lBXi/mFaWfupT/93/eiBSDo4+85lnLIBnPvWclru6pLsF6e76Fq0LYDAiWH+mFdgfS/K83aj6uhY4aqMXkRSamqN4aX1A416Hqgii6qwsLXBw2MUYQ71Rp3PQKckJ1QrGGBZnW5gyAQHbEnzfwXcESylqswHrG6Wp6SMPnCSoBugsw69V6Ox3CQKXE7rgg6eewBQZt2/cplWvcX19izCKxXVHZIVhebbBd3/s/fzKV16C4YTlVoXAMhRZwuEwQkShRN8ZHVlSuotPvd6mc6VSoyNTGjh3/lvypMWUm5ijLIwuaWUzFY/7Tyxy/vH3oCYdevtb9PojgqCCzlOWWzaS7dPd2yUqEnqZR2eoOb7Q5NjaDG/c3KdiCVobLAOuY+G5NoU2HPSG5IUhKpPx7sTjvfDWTZYbQWlIWxgsF1zbIp++X9d18WyHLMtwHZs0zzHGGHsKWCoRMUoRZxkCpuL7aK2xBGzfx3UdHrr3FN1RTLvZ5MqVq5ycqxqn2ibs7YtDbuJMy1y7yT0nls1gnEicZVhiWJ1tsrwww/xsG9d3TBxnctjpsT+KefXmTdrNBufPuhRZwrvfdT+eZ2ErJUYbBuOQUZgySgture9y37FZvvz6dSZF2Y3GScKo16ES+Lzy1m2TFyWk2RuFNGqVkn1YqxKlhrdubHHY6dHpDzg8OKQ/GJVFMyuYrTo4lnAwTshzLYs1j6V2g2ajSawdbm+N5CMPzZtmM5jt9qL/6ZVX3/wT//OPfejiJLM+98KV7i9/6lPP7R89Mp955hnrzfPnzac/fcH8y/K1u+suZHd3/f+9Lk4JDp/9yqD7iQeXpOVbH39rd5zP1jx1MI5FRLDK/ZnOJGG55prC8krD1byQLMvK2ZDnoguNrWwW52dwLQVKUa1UaLcbkqWZ2Epz9vQq9VoFdC55rpmZnWVxocWg1ycejzBK6A3GhGHE3GwL0Rn9Toc8N+x0+vSGYyktjUo9VBKOWZhpcPugD0ZTURqdZYxTzSTHlABdORI6KkJKVCmE/SaigyUKe0pgKL9eQnhKlV57jm1jEIzW8vDJBXn84YfQtsfG22/guC7jScSo20XnGZODLazxLpff3mCSgm/5RNrh+GKD+nybl16+QaPikGmwbEXgORggKwxxVlCUXZtxLHWHjaCNIU4LRnFGzXMwCBXfI8syUYIstBpyfGmOnU6P/UkZiigGbKWwlFALAqq+L9oYHEvhORYzzQaNaoXZVovJcEQcpywsLLC3u0+UJqRhwnvf/RC3tnfY29xkmBjZGhuqlRrH5mdYmW3JUrtBo+qzvd8jzrQJ6g2azTozs20J45SlhbbxXEdE4MGzKwS+Rac3lsEkIck1hYFhXDCJC7Z7Y65udTgcjOn2h4TjMaPRiPFkQpokYDRJmhJFCVkxjVgvtKCEKEm5vr7F7t4BRVa6jmdT+UDDtwgcYbMfSZhkopSQatjqxWzs9xkMB9zcGfDWrS6hDvTc6ulifqbRatUqDy3PVH7Xux849oPvvXf13I9+8j3Wn/mRb9v72F/4u9HFixfNhQtl7MUzTz1lPf0jt5mG0Aq/JRrj7vqWrH9n1/nuB/utX+pZYP+DDzU9NXjpK9c6x2/2ksK2bXU4SaTiWNjAOCvMu4610E4N3CpxmjKejMW2HTy3tAXK85yTq4tgNJMw4tjqMmsrS+RFzuxsm/2dLWqBQ+DaHHRGnD9/D+FoyM3b21RrNdqNKp3eAMtxGfT7DLs94zo22iiu",
		"7/d5+/am6ELjuK6p+y6jyURmqy4r7QquLeweDKm6ioMo4/phaCzLBoE0y9FmyqSzSq9qXZiSGViOi0rqwhSPUYhYSu6w8zzHI9cFTdfm+z/2BB/6wKP83Gd/CddSLMyVTMEg8GlUHHxJSHt7DCc5L68XiB/wnR+4F6Uj3MUZfvzT/wCxhIMoL9l8U0fu3JQ5VEopU3VdMHr6ZhRGhP4koubZ0q4GphoE2LZNFCcy26yhEBbaTfPqtdvc7g5QUwo3BjzbKgW0BimKwtiWolWrcM/JVQLXxbYUaTThsD/m+OoStUbd3Lq5SbtRlQdOtPjwu89z7eoVXr95IP/7F69wz/FlszzbYjQOJcnS6RzP4fTakpmdqbG7d8jK8iyNaoWsyOj2JgwGY4ajsRRak2gbLAfbsYiiBK0NkzhDF6UX3mAwLOFFKPVtWU6YpDi2ZTxLYVkWjqVQlqISBOK7LoNxyInjq6RpQjoZMwlLj8XAUcRJytYwZZxp7CO7cgRLCa5dzu0cywJRRiHce+Yk5+87Y2bqFa3jsXr43JKtlOL27S3yLL8ZZ9nPJHn2C7/7d37izfu+508efvODVHZP+3Lp0oI5/9xz5sI7Mq2761tXG/6tXt+7HdK/jfUU1s98cT9sec54tmJ9r2tJFuZiVVybMMtFUbZJtmMxV3VJsZmEEbbjSKE1o9GYIi/wfZ/eYEie5yRZTqVSpVarsbFzgNEwDjPeurnFYWdApdbicL/LxvYhk1yj85zdgx5hkjEcTkgLOHliVbqdLrkIkzhlEKeSZTmB75asKKuMxuiNIwaDEMdxOLXUMtpAmBYUZUprOdS3FCJlt6GU9c4xS8qD1pFhgGNZWFJ6qha6DCrM8pylmse3vec8Kw0HVyf0whzbtstU2UYVpXP2D3rUPSgw7PZygnqLr7y9wQOnZhkeHFD1LTYGCYPuEMexSXNNLfCxLIXvlc4LFdcVg0EbTeC5xHnBIEzwHUUjcKkGAb7nkubFVBBryY3dA0Qb9vojoizH6DIY0QCFLokdWZ6LpaSkeh9bEVspbNumWvEJxyOSLKNWqdCoVXn4vrPMNOvkaSpVpyzkv3F5mytbnVIzlWWMwlg812Zlfobl2SYGkSQKicOQNA5Js4wo0Rwe9tk/7GHZjhx0R4hSRFlBrz/ioDcgSRMmYchBp8dgNGGcJEySlCTLSPMC23Go1ar0xqH044xJkpMVBRiDMlp0npNlGUKBbyuGwyG2GDrjhMNxwt44Iy3MnflhSU/H5NpIlmviNGMSp0RpRlYU7Bx0eevauqzvddV+P5Jf+PVXdCZWnmpLB7bMOqI/EMXxD7566ebvfOap8+968lSz9u2PrSZOuD3+i1+6lF28eFtfunTJXATzzDNYz8w/ZT1/67a5q2P6D6sKfit+7t2Tyzdd42dAPfOZZ/ipZ3/1HwWiv78bm+T2MLMLVCkgDBPCXPP0+RUyq0YnLtg7OGQSxTLbapKmWelXJxB4DmEYs7C4wPLCHN1uj9l2kyLXhElClhe0G1UzGk7Ec20qvstwNMK2LCzbLgWcSULg2azO143YNi+/tU6Y5rK+tcdgOMaylMnynLTQ1DybYw0PjfDoyTkM8OLtQw4nGVlhUAK2ZVFojbIdsrzA6AKkDBM0RsoiUBjjuQ5FUUhhDGleYGHM8ZkG/9kPflIef+JhPv/Pfp5EwzgX7j+1xOp8le3NXa5f38RxFOQRs9WSNbeyssyvf/02jz16im53wiRNmAR1fvqffonjy7P042JKbtBoUQSeR38cMQgnRueln7ayLFxb0fA9ludbVDyPeiVg86CLIyIrC3O8tb7NcByaYZSUoYqlZY/kWmMrZeqBK3mWG9+xWZ6bYWl+hiQtC3u7VmF9e4c0yzi2tMBMs06UpGRpwdOPnca3M57/0qtc2ptwuxtyfGGGdtUXAdqtOqfW5phEKe1mDVGwvrlLrRIYjYgxYm5u7ovt2IBi77BLnudEac4wLKUCSV6Qa40pNMmUiGFJGbsuAo5l06759Mchgyg7umeNAI4S8aedbFpoWhWHhWbA1iCmM06mXowlgJlrI+aOM3o5Jjy6+dXUkcOxFL5to1QJmbrT7nJtvs3cbJtzZ46bB4619bWbm7LbCx2xLBr1AM8ynYpj3WrVKpdas+1XyfOvPH6/fenMp35y8FtnTxcu3HUR/+3Y+fybLvtbVITuFqN3lgHkOTDPfeo5A/zoh080HMuY73V0lmU5yrMd6u0qG90JhTbM1ix6eaknSvOcmVaLOEmJk5hmrQqUwtksSdje2cOxLW7e2sBxXUBIssxs7+xQCQJDkYspMjSCEUXg+xhtjOM4kmuN5zmSp6kZhTFhXM4SXFvRqnkst2dZaVdpOwU7BwNe3h7j2A4PnJxhozciTAtigUolIM0yTJpiC3gVD9eypsFyhYgosrxAlBZT5KbQmCLPaLgWD59c4VPf822sLTS4/LWvMtOqk2HjTSLCQY8XN9a5fnOLiu9gdIZjC0lWcGqmwrs/8V5UnuHYOQv3rvLamzd5+MwSf0c5HAwjlFLkeY5YgtEl02wwCUlyfWe3bAQerapPu1phvlHF8312Dwf0xzEn5lvGc2xp1yrs94bTjVWhzFHLB56txHcd009zbNuiEvj0hxPazQZhnHBtfYvZZgPLdugNhlR8jyu3NvnQex9jMB7z9Pc9zc//2mtEeekyoYFK4FMLXKJMc327SzXwyAmJwpjNw5BKUEiaa1Now2Ack8QRaZqSZRlxlpOkBakuyHJNq+qxNNPkynYHXaRYU9g0m0aBRGnBKEpoBi4VzyFMsqMRGXNVl7WZAGVZ9KIMneb0w4zOuCzMVdfCUmKMEaK8MN/MPPzmk27ZUBpyXRBnRamhE6FZ9ahXfA4GY8KsYK83ksvXGpZliRGx01Yj0Ne3++zsHTZnG8HjgWM9vthq/iepzpKXL8vmT/74d746W3We+10fPPN5+cT/u1sCDXejLf4N9ujftqMa+//mjffu+tdfmynnmfFk7twz1v61v2sp+X1i8vRgkCosS1BCojVLNYvboXBqbZUwioxSFkoJnufiORYYw2gcoqwyMynNckQX5EWBZdskSYJgmEzGNCqBCQKHIslEG6E3SIiTVLKioFGrcfl6xiSKpTeaMBxPeOTMElrXWGrVObc2z/3Hm+zeuk0RRwwnKQQ1Fhfm+NA9I6JkkziHQZphiaLiuRjKuUrguTj1KlGSMgojivK9mSzLWKh4HJtt86H3P879Z44RVCp87Rsvmxvre7SbNen0Blxb36E2FblmRUEUxSXdOs95/6NL/IsXd3n47ZucuXeRG1d2qPoOq8tzLM40efj+E3z1pSvUHSEvyuO+Eci0oTDvfCCOEmaqAa2qj9YFG3sdeqOIMMsJfI8oSQUldEYTsrwQ17FJs9wYQ+nK7joopYjiVPJCgzGmyHMxwM7+Ab7r4Pu+EYQoTnn47BkOukMcy6Lf7dBcbPPX/vY/wWu2ibYGTOKYw+EErbVRSkk18IhyjWPbZFlh0jShyDI0kOdlF4TBuApJspQwLciKkn4pUkbMNwKf/cGYSZLiKEGpkowhCIUxRmtDobUopfBtdVSQmK8HnD82g5iM2WbAA55DHmdYjoPnuwwmIS9c2WdnVGrUHKVQU8GuPrJbkjIJ95vdpAyYXBtyDPkoIowzPMeiXWiqac7W/iFKkFGYqlrFU5Mwohr4pj90Es+2zGtvrRNlqVqea5554S37TKvq/a5vXN5f/6k/9b2fO//u839T5MJrzz6LunDhrrbp/2CP/m27V9+dIf07IDns7OwUP/auJ3++UMP3KeGefpRlk0yrKNdUXZvHjjXk0taISuBT5Bmb2zvMzbSYn5/FtS0sS+EFAWmaUa/X8VyXasUHnRLHMa7jEPgOpsiJ4gRjNI4lgi6wxJQb0xS66Q2H7HcHhEmGbVmcW5tjeXmBaqMlZ06tyUq7ymLboV132e6M2B9mRGnBXNXjzGKdwXBCkmT0o5Qs",
		"K9BFmdszGU8YjkMZhhGWsnBti8VmhQ+eX+N9D5/lY0+9j9ZMi+Ek4uat21y5sUWUpVzfPpCXb+7iuh73Hl/CtW2GwxFgODnvstz0+OJbHV6+PSI+GJiPvHtZuocDDiPhYJiSF5pjy22+9MIVM1/3JCk0UW5I9PSkPj0pqmkE+SROGE5i9vsjDoYh4ySTAiPaGAk8l73OkK1OH4NQ81yyvBBtNI5t4TsOgVuKlqM0Y7ZeEc8ts4uMEkaTkLWFOdnt9gl8j1rgEaY5vdGEYRjh2hY3tw7FWI7s98dyMBiRpClFoekOx5JmpSasKKYQqC7I0oTxZMwoLP324jRnFKdMskLKWU4JkyoRtIEoy+lNYgLHpuI6NCoBgefgODa+XSYUF6YkTKZZDkawFFR9h/1hzO1uyGvrPS5vj4i0zSi3iQqbjz84S1QUvLLex7PtO6JoM73GlogojpiXd/iYpoT5BGtK4jLGUBQF4TikNxoTxSl7gwnDOJXuKJQwKxjHqaR5oQaTSB30hyrNcgbjsNjY6+dXt3rF5Y3e7NZe/4m1xfqP/tk/9In9H/zDX3nRmGfVhQt3DVv/fVvfKsju7vrXL/2ZZ56xPvXcc/nP/tEP/OW/84WrT1eGufI9Yw7GqewNIzrDkJvrt8ULHKPznJW5Op5rUa/4GM/Fr1SIkwzHcjA6RwUOw+GIMNP0o5QonYCU9G1tDIwi8W0LzxKsKbFAiSLKcjphghioeCU7bxQmPHpPg844Jh4OGNgea4tL3NOe5bv6EX/v4nV2x7NoNAtVlw8+dIrt/R6dsGCSFozCCb1JQq1apenbVOs1Fmbb1Os1iiyTx+9dNRu7XX7pK6+RDw6Yb1ZpNGuE4yH94ZjH1+rm6bPHReMzSgzr3TFFnlG34LFjLf7BNzr8+rU+Kw3fXNsN2b61w5mTDfPzX96V2cVlaq0Zzq/NmkblX3B8rmlqcS439gfYppxzmaPhBgZLKSm0MXGaASLW1GvPtW0Cx2YcxoRpRpik1HwXJYJjO6XgdkrKSPKSxSYCnuviuh5RkgCG4SRmY++QrNCy3ekbDawszCG2TRinXF3fleOLbXqTlDhJUVONVl7GlTAJYyZhOBXhGoppNpLRmlxrcl0+dUeEwfIBLF8nxuA4Ftpo2rUAz7YxArVKQOC5pGnMOEqxHRc7isvwRwQxQjVwCTwPXZSi3BPzbebrPvWKh1VtUKk0OPb4Q3zIeoHnvrZROlZI+XeVERmC5zgYrSlMUV53DFlekBfl+ztauQGP8nSky/aJb/oyRaGlKDRxmhtLSr1bnGlRmRZLQcV1iJI0e+XGfvan/vLPVv7sf/6Bv2BuPvvzIhd2p43a3T3pP9KCdPeD/zdcn3ruuQJQZ9orF+faWy/3rnXeE7h2utIKrHFuWGx55v6VOfErFQksZZQpCBp1XNdhZ2ePloHRJGLY7zGKJnQGIw76o38Zoyhpz2KAMCsI78ysSycAVykcW5HkmjDLcS1FnBYcdkZ4jnDj1gbHVp5g4bGPMbz1Bved63Dq1dsk8QR/bpHtcYRVpCy12/LB959lf2+ftdMn6HX7xpGU+x55wrieKzu7e0xGQ9Y39rixeSDtqmWeevdZNtZ9eelrL5tJLuz2JwxizVZnTMVRNKoecZqRZJqiKDgx3+DvfO2Q37g+QAmM00I2hon5wssd8wd+8Bi+2aTiKZpVj8WaxQcfP8NblzepVyvYCK5Twp62snBshyhLKIqSKShK0ah4U/NSRbMWMIkSRlHCNMsK3y6JA7ZlQFwUBmMMWVFuuo5SUy2WIiktdEjyglEU47sueV7I9c1do5Ql7VqN8biMoX/zxgaz7TZxkhgBtNYyiqbpwboM5Su0wXzTgU+mHYiITBW+Wn7rUygCykDF96hWfJSBIPDxPAfHUqVrd5JL4PsmTkt7JSXCQqvCbKOCMYJtK2oVn/lmgw89cR+nT63gOYrd7UPC3pj3PHCMB9facml7YGpeGeiuTQnYFcbg2BaioVkLaFU849sWaZ7heR66KFC2I3Nzc7x0+Tr7/dGd/tWxSn1XkZfzpqPfSJQYx7LIpn8euFaZoeU6UvMdt1nx053r63Nf+mn9kHn22f2f/IM7ljF/O59aVt3dn/4jK0h31/+F9dRTqAcvPJf+9995/08/drz9ni/e7JphUhjHtaTVsHnPg6d5ZSfErVTEs5Xx/DKufDQOGY4m7OwfsNcbEmb5O/Vn6pLwmwD7I5xQ3snUOXpNbgw1y6LhuWWaqDF0B2Nube7wsfc+SCJz5EAejfCbcywdP8mHH7jGel/RbDVlfnGBTqdHUfF44e0dPClYdqp4bZdRZ5/t/T6j0RDftTBOgNgencMhl9f7bGy9SmeUmNv7ozJ/yVG4tjDKcnLEdA4SCVND4Nv4yvC5y30OwwJLoJhCURXf8PxbA759a8TD9y8xLhT7t65TjRt89N1n+Lkvvs13rjQZpzW6k7QU5k5P63mhSYqCWhCIa1smcG2CoyTWKGUUxSRZTmEMgWNNU2/1VH9ksC1FVpQsPse2cRR4rkOhcyyliOIEx1JHsyiKsquRN6/dZHVuBtex6A2GLC/M4Qc+RaFLKyZjTFYUkhVljHlZIplCcEdMNhEzTUwSRIwcBR2WXzVa47suNd+l3W7eibe3LQtRUGQpvdGYNDfkRSiDSYwBTi7PsjbXIvA9qtUKy3MtVhfnWV5oU6+6iGXz9qWrXLl6m539vjm7XOWJM4u8sdlDG8gKjTal2ixKU5zAY6Zepeq76CKn3qpzYnmetYUmp44tSb1RZ3Gmys5+h25/LEY0v/bSVfOFr14izXIW2jXyLKcoCiq+h+95U1mBIkpSqQcOtm1ji5iaa5tGYFmjUTz6hV997faHfuVXNaD/4E/+5B34RpvPWDwHPPOMPirmd9fdgnR3AU8/jb54EdyZ6r/4+GNe3I9x3tztGV8M992zwNd/aY8wjFlbXmQwGnF98yZFkZOlKTudHt1J9A6jaVpkfnMU0Z0DtWHKmjK/pY/VxjBJM/zpPCHXBVXXZnamRXN+Edd32drcZHlzm3sefpisXuE9HwjpfO4iZ8+eNg8/cl5G/T4bm1v87Oe/gm1y1j/7OZSlRGzXWK++JaDwfZfuYMIkzSmylOu7PdnoxaCNOb3cou47iNF4qqDpaiTPqPuW+cj7zvITn70mSRJzZrHGYH1AURyJOsuQuiiHl97u8Yn3HedgoJhbnmf7xg0+9MhZTqy05dyxGWMsV9TBmEJDqnUZ66FzfHGZadSMZSlG45D+NCIhjMvQQ0vAdxyOPI/KbKRyBhJlGY5tl3OaNGW+HmCrkk1W9T2CwKczHFFvNnA9j1EY4bkumbLojEN8S7E016LZqJFEMaJUGewqiNFyB4I7mreU7ZMx08h0c/TxCpjAsUUpRZbnZIXGcx1mmzV8z6VaCaYhg6UWq92o0u/3CVyXQqeESYo2hgdOrnHm2BKLc7MsLc4w6HTwAg/bsXn59bcJx6M7ScWic1Kj2exM6EQJlrIkzbPpwUfKTlQU7WqAJZCnGWePL3H/PSdp1GvoNGKS5Lz58mX2dnep+YE5fmyRio38V7/z3fLjP/w0/8s/+nXz2V96iUrVZaZVLw8TSollKVzHKZOA04w808RZJr1BplsVy3r/vaff/sQP/rf2j/z3/n293d14fzyMjLTC7/uxPz0S+VRx56z2a8/afORCcdc7725BuruACxfQzz6L+rMPfNfN//r/+9NfnKt73663dPreh05Y1Uad7miTwBGuvH2FHJFMa0bDkemMRozT4jeVnH91Jp75TRjPvy43z1DqQ7QxiIZhlLLZi7i50+ORR85hV+vkWtM/PKTWajO3coJjx1aZdHbIw1UaKmT9jVdZCgzjMCGehuzd2jqQhbkWJ5bnGY1DLt3e5/bhiPvmPLb7MWlhmKl4sjpbp9CgswwXgxhteqOMP/RdZ/iHr/Tk6sGo9OzzCnzHZlSk5fsWmMSJLLYa5utv7siH3rXG",
		"sN/DcWPqtSpVR/GffNcT/P3nLkq9ViM3YFkWjaBC2VcISV5mTXUGIyZxYopCEzgOnuNIbFK86eY302hQGEOUZMayjYyjiDjNqAUBaVEgeY6txDiOQ2YQxy4hJ2Ng96CD4zjlzC5OseySJakp2W4lFTygdPUr+xwRg9YGe+qIDmWSrkFECcadumEUungnaTcvjVi1gWY1YGV5Ac9xqFZ9up0+ywuzuL5LFEZlfMlwgrIKRuGY1bk2Z44vM9Nu02o12Nzc4vqNWxRG8f4nHiKKQoaTCLdS5dqtbVxbGEcxUdWlO05o1zwTx6m4qtQ3OVNNWpZl2L7LbKvB2vKC9Hpj85UX3uShc2sMhhMyo1g7e79B2XTSjEgs89WXt+S/+rHv5u/+xMPy/c/c5NN/5afNtZtbrM7VSzhPKRxFmWAsMDtTZaHd4L5zJ6xTi7X8/Onl+2cWZn4jHw/UYs1PlmYqkyKLRpd+7s9vVxeOXRl1u1//9a994xflIxf2P/PMM5Y5/5yRu4y8uwXpP/ZlDMKnn0U+dSH9E5+455Wzi5Vv/8pVy7Qcw4svb0qUg+sohoUmKwoGozF7wxGZ/tcP7Y7SH4z5LV//1xQjJZBrTaYNllLkxhBmOX6lSpTkiHIQ5Uic5Abbwa61MdU5zt13hqtbPbpRRqOIaVcttNR48NwxNve6BL5DIfvUWzPsdYfs7e0zGCecnKvw3ntmuDXeJwtT1uZbFLlmtztmpu5hFTlvdUPetRzwmS/t8Pe/cWiUINqUhAHPKRllUrqFk2Q5ozgTwSeYXcZPIByEXLp1SL1Z4yMPHzd/+adERtmYVsUHR+iPJji2RZjExGk+nfNkv2lHUkcDB5E77grDMDyC40yUZnJk59SsVpnECSJKcm3MKIqoVQIW52YpgOFoQp7nJdyky3lYrV6d6qly5mYajMYReV7SpbV5J9BQG5Dph2kQFAbLUtR9H2N06bZQFCRZfucz912Hdr1KJfBYnp8hjUOkXWOuXcPzXN486DAaTcgKzXhKZNBFwWgckqU5127cJAkn1CsurWqVjY1NROdoLOIoNofjUPI8R0TQYtEZJ1R9l8B1GIcRgefgWhaTOMZgqNUqnD19giQ3fPnFN0nzTHKd8fD5eyjynJvb17j39DHm2i3OrM4wGg74la9cMYszNXn6Y0/zE8WQP/zn/z63dgeszdZKgoe2mWsEPHhmhdl2i3qzxdqxYyS55suX9/x3+euyvb6L59qV40uNmao9ouLr81Xd/FhrZfYPff8nnnz7Y+9/5C/f8x1f/99ERBtj7pIf7hak/3jXs88eifcuWL/yP//oX7l2+caPXr+yns1UXfs33tilbdl0BgNECXFWMAhjRlF8x316uvn8S4pr82/4SAkg06FSKVg0JWIklnEUHHZ7FCdWUKJYWl0iTGOx/appzy/hei7FpIexN+Vwc5Pc1cy2KvQmffq9Hg/df4qDzojj8ykTLRRG0ChmGz6eJQxCzVP3LrHeibCPvNMcm8AWtnqpiY1g+S6dojJlxWlji2G3PxKLks5sTWcmWaHpTyK2ujaHnTF5ntFu1Y1X19zqpjx1dp6H71kxL75+U2qew+EwJCldFrBEkWlj7mQ6ccehXJQSKr6P55ShiaPxmMFkgmW7zNZrkmYZWaEZhiGWZaFNySDr9Ac4fsXkhZbuYGjSNBPPczEGiqJkm63Nt7GnEevtRpU4zRlHMUmRy5EJ+TsJu0w7pyMLJkxeFIySGM+2sJTCntq+Z4WmVfE5vTpfip+LHMeCnX5pkKtEISLMNqr0+yPyPGcclkXDKq8zW3sHpFlqGlWPetWX8ycXObUyT17kvPDWlnl7f4dC66mtkpJxkqNs2yhElmabxI0ajrKIkghRinEc06pVwRhev3bLRGnCQrtOtVphpl7hSy+/xUuXb8rt9S1zz8llrl/xGUwis7G1z1yzztz/+jNmZ3OXTz24yN8f3kbnKfcfm8O1XBYX5xDbI7UCBpOY+PotPMcWt1I1t25vm4rngWXz2lub3HuyZqLurnn1y18zj33021ma4972mvt3Ln92+eP/6K/O/QH4Q6ExF+4SH34brLs6pH/bndGzz6qPXLigf/yZJ2f+2+9/7B/e2uj/8M9fvGJ96P5FCaNM0tzI5Z0hYZSQa02RZyRTFlR6NPj+pobot6SBcycr71+uQdNvknf+YAoJ1XxPDBCnGYHroixFYCsW23UeePgB3njxG2xeu8Q/+/lf5L/7i3+dZqPOd3zbk1JzhfF4SODCXMM1aZ7QP+zyq2+s0x+ncnxlkWs3bpOkmTm5Mi+B7zGJYlquZTRCnBeIKGlVfVzJeW1zwJnFBp4fgBvQHSUkeS4CUvF8GoFHnOSlnEWB1pAUZSe3FAirsx6Dbo8PfOQpxqnN4kKb2xt7fOPyhiw0K2wOIiqeS5xrokKbfFrB1VFnpErALM7yb5q3GQqt2e4OcBxH5psNdFFMAxO98qCgNZ6lmGnUSfKi7BQCjzzP5YgAUQ086tUAXZTEjChL8RyHLC8p3L1RxFECLZTUfNdSWGoKzZoSAiwM5NpMtWUKozVKKY7NNOSRs2scX57HtxSNiku71UBZDraCvDBM4oTbGzuEcUJ3FDGMEnzPYXVulkYt4KA3ZK5V577jizz64D1o5UiaJOwe9sxOZ8DW4YC93pDAd6U/TnAdB9+1aVV8qfoOFrDb6dKqVzkchtSrFe4/ucL125sm14ZaNaDqu/LgueNMxhPSNCVJM2ZbDUnimEs3Ntna6+IFHr1xiCVKMuUy36rx//j4aX73R85TiM96N6Vab3Dq7GmpBB6OBdF4yNbOHtF4KK32jASBpw43bkmWTGTU6aiX3rglg36i7P5tee2Lv5bp/avpA9/+0Ucf/q5PrlTm/sQ/+/SnP2NduPDc3YJ0tyD9x1WM5MIF/d/80He1P/7g7M9vbnQ/9osvbEbrvbE61g7kdz55r8w5IhVHOHdqnmsbPRzHwrIsxklu9G8+wIl1JDqUd/zC7piZHlWm31KQrGlROjJAbfges636nVO559okaca77j3BfueQz37ueV68dIN//MsvyBdfu0Z3OOarL12WG5uHvL2+z9rqGk9+4new8fYlqq5FlBYU0Zjjx1bk2MoSL711izQrePjMMWoVX8gT5mo+u8OEoFLBd2053rTZ7gxNN9Kcma+XcwjHIccSz/fpjGNsDFGcYDuW5FpjKYXWZYdXDXwWGwENO8OSAozN2zsRuzu7LM3U5PNfvUTFdagEAcutGp1RWH7/lMVmIzjKkmmQrVjKIstzojRlkiRllLnWpZA0z9BaEyUJwzglzjSebdGqesZ1HPqTqIyzSBJsy5Ij928lZWFSpduEqfoeudZ0B0MCxxZtYBQlJYlBpOyM5Ih8wp251zs0aEo9j1KcXZvnsftPSqsamOE4lIXZOufOnOTEmZOMej3G45DuKKTbH7Fz2ONwNOFwGGKAiudyfHmhJHEoWF1oY/KcsyeP4ziuPP/lF9ntDIiihN5ojKVE4rQgKQqjtaE3ifFcG9tS3Ng+ENuyWV2aZxynqKle6631HbEFqr4rx1cWaQQuZ0+tcnplnqXZFsMwojecAMKxpTlqQYBrW3JsvmWiLOPK3oSB9nnl1oDnX93ixIkVyYtcDvcPCcdjUYIcO74mSsGNm1vcunGTzY1N8RyLWi1gb++QAotKrUEWG/r9VK22Gyqwo6z94Pkn/uQf+7GRV/++rxhj1IULF+4WpbsF6T8GmO4p+yMX/l7xz3/imaVjNfXZX/36+gd/7dJO0o9Tpx/GbBwOZcGBg86ID55ry+/92HFevbzPtb0yxygttFiiSKcsszt9joCtLJSyppCdIErdCcQ76qasafbQURtlKQutNcszberVCmma0qpV7uB+C606z/3K17m8ecB2b2xysXBU2UukhZZLNzZ54c0bJFHGe598D/c+eF46ezsyf+o+kWgodh5z9dYOW92J2emPOTlXRwSiNJOFdkvmFubo",
		"xzmrDZe1esFrW2Mcx5OHT8xJGkXiB75M4pydzoAkz9FFQVpobMsqhaOlipRCw0KzxrljC8zN1KhbqUTGlVev7slMI5DdzoDnX7nO2mwDz7UZjKPS6WIKeaVFQeC6NCu+VDxPaoFPu17DaKDQFNrQrFRYbreIk4TeJGQSp4zjZKpbMqzNtWnVq2RZirIs0SCWsiQvSgp4ea0NYZpgWxari7Pi2TZKhMKUceSObdMZjqVZrRiMIckLKabCZkHQGJQScW1LjDGSayOilDx4ek3edd9JVhZmSkf4SkVOHF+lVq3Q7fS4vbXHYadHbxITJRnbh707xehojjjfqtOqV1icaeBalizNNWVuti0btzdQeWq01ozjDK1zxkku/TDFtW0RJdiOjdaG27tdalWfVq0iaZYTxSlgOOyP2OlPqPuOHFuaxejS1YI8456TywwnIa9duc0wjGWh3ZR2vSpH1lY7vSFbnRGteklE2e2NWZ5vMpmEsr27z+ry/BTCFer1Km+8flmiNBfbcaRWDWg362xu77F30DOLSws4tktrZo4nHlzFllC98dpN1Zy1i/rJ5Y8/88Gli0v3fPKW+cwz1oXnLt0tSncL0n/YxejChYv5N37qjy9vXu989vrW+P0vb47Sm/s9uz8J0UUh3ThD5QVtXyRNc04sO9S0IU4062PNbKOG53kyiRM5mikczReUUncKiWUdfaSljL8MwhNEvXPqtpTCGEPgOizOzkBRRn4361XyPCfNChbadTYOeiRFUTqJTjN0lJR5Rq6tcC2HN25t8i9+9hcZdTqs7wy458FHOHPvPfS2blCpVsFxxRSawLVxHUd2OyOjbFf8oCLD1MhBt8+5GYvD0DDOkcdOzdH2Sk+1SNv4nsPW4aAMLZySCIqiOKIXGzBS8Rxmqi7nlqosNQzB4imMeBzs9/iNS7d5e6uM1UnSFMd2TLMaoJQicB1AcGyLqu+KEVCi8F23LLxZVpIHipxJHNMLI5Jck2oNIjQqAXmhqVV8oiRBRHFieZE4yyXJMrK81M/YjoPveRSFxrVUmZNk2xRaszI/w0K7SXc4Zrc/whgzhQRLVreaPqT20SEDSHJNo1bhw4/cx3sfOoPjWIyHYzzX5tjxVRYW5tnd2aU/GMloOGa3N8HxXLZ2DzgYTjDmaGZWstaqnmuqgUe7WWV5aVbuOXuG2bkZrr71Np7SstCustEZcTgMZRznKCUopVCisG2Lw/6YiucwUwvQ2ojt2AzDKQQpZe6SKQqW5mfIi4LbO4fc3DpgMBxxY32Xw2FIxXOJ0oxaJcB1LLrDMeuHQ2k3qjxyZoXNnQ6u6+A4tqRJSj1waTbr1Gs1rt+4xaDXRYvCcx3m2s2pnVZAEAQo18K2bcI0p1qvieN5bG7syue/dE1abqjPffQ7HMnjE9X5X/6pp//wm9ztku4WpP/gi9Hf//HfcfalV27+k69f3nnPei+N9vsDZzQe3xliYwx7k1SONX1SrWl7ikbNwtZwtRtj+VVmW3XCMCLOcrGm3YqhNLB0lQUyNbfU+k4PpZSIZVnTDJ9yY3NsG8GwMtOm4jlMwgjXLYMAkyRBY2jXAnZ7Q0ZxWjrKcMejDFspskJLrjUiil6c8uU3bvClN2/y2lu3ePjBBzl/cp7t27fxbRvbssSzbdFAbxLLze0OtmPjVKpEUSzvO9eWSW5LPzY8/cgJut0+JxdbvL09oBfGHExP9EoJrVq19FwTg2NZ4iiFKgq++9ue5J7Tq2SdTQ4GBTu9lFGY8sKVDQ4HY8ZJhmNbxmCoeS5VzyEzBqWgUfGp+D5xltMZjSXJclMYTVEUYqZMO6VKuC2bOlr7joPvOFORl6bmuZLluRS5lvm5ObI8ZzCaYFuK/nhczoVsi2YlIMoy7GmXtthqcNgb0BtNOBhOpvMo6whOFJkai5fuBYok0yzMNPjk+x7i0XtPmFq9wqA3pFH3WVxdRVkON67dIE1yibOCw96QTGt2Dw7LCHdd+uk4toVbWimZqu/TqFVYWpylUa9Tq5fd5NVLbzIKYzkcx3Jlp8dGZ0SSFcLUXDbNUtK07AJXZ1sszrUlSUtIczSOGE4SxnE69bATFubaAsLW7iGWCI/de4J2owoGzp9dI0pzdjs9apWAm7sdcg2PnTsu/eGE/iRiplmTuUadPM9BG1ozMzRqNcaTCfX2DLZAlBSsri5hBA4OulQrFer1hlSqdQmqVXb3uyT4kuOZR8+1edf7zkutmZu3nv/G8v5F88/f94N/ZNc8+6y6cPGuD97dgvQfWjF66in7wt+7mH/jr/3oBz//tWs//+uvrd+3P07jKEntvU5fXKeMmACDKQrGUSqFGDzb4vL2kFOzLplYoGyuHURUAo+K5xHGCVlRiBKFUuoOQeHIyNKedkwyjQk3TB2XReE7NkWWcWJxjuXFeYbDMXGaUa9WGIyGpGmGUjb1wGZ5ts61nS7T4iciggbcqXlnbrQYzBQFLDuWnYMOv/AvnpePPP0hPvD+J7j19hVqngOi2DgYcnJ5Dt+xQRRnz53hxTeu8Ykn7+H0ubP80199le94773kuebWTpf3PHiSq5sdxLYZhjGB6+K7NnGSYilFNfBRQBynnDq2yNp8k+HeNo3FJa7thvRHI770+g2yKcxpTElQyLRmbaZJXDLfxHVdbNemMxozjlKyvKAaBBRFIc1qQLtWxbFt4iwnTjNT81wqroNllXL/QmuqroueMtBGozGteg3PtvEcm7zQDMcTXNtidX4Gp/x95OzqEqMw4vb2PlFeMAxjLFVCrpZlkRdajogoqdZogYdOLfLxJ8/zwH2nTa1WZWd7n7n5GWYbLoUpu4Beb8SV2zuyc9AnyQu2dvfpj8ZA6b8nU5jXUmLSvCTO+J7N2uoCzVqFF7/xGlW3II0Tqo7FxsGAV9c7FNOurTCmpKnrco5ZDzwagUfFtUmSWPqjCXFWEKc5mTGmOCLkiJE4TjjojZhpVknihLNrC5xcWSjjNuKEve6I4SQi14aldh3fsdg57LG20GZ5bkYmYUicpPhBQK1RZzAqu6uZVp1JUrA432Y4HBKPJ9SaDWqNOnmWsrN/yPrmrigL4nDM4SihHdjc94EP49tJUbE9f+nec3t//R9/5fmnP4319/7e7bvapLsF6T+YJc8+9ZR94eLF/Pn/1w9+8vK13X/yM1+6srDRHcdZoe3eeCKF1tKsV3AcC1sJWZaL71hs9CK8SoVhWFB1Fe860+b2XshwkrI/Tji+NEfgunT7gykoJwSeS8XzqXgejm2LKn3ORImgdenAXWhD1bXxLVhbnOPh++4hjmJGUUKcJqRZauI0kzhNcR2Liusgls2N3S6OXZqSmiksWBiDa1lkxvwmMp8xYFmKXCl+9he/KA/cc5bHHjrNxvo69Xab46vzdLpDjq8scv7sCZaXF+kcHvDIqTbLq2tcvb2PbXKeeuIsOk2ZnW+zd9DH8TzWDwZUPId6xSfPCzzXLg08gSBw8S24/9QyB7u72E7A7iDn8s0trmx3pnEL5USt9PXLmatX6E1ibNsWDGWaalQWOt91qHg+thKJkoRxktAZTwjjxDi2TTPw8G0bY5BJHBsQ0jyXvCgLUpSkNGo1GtUAow31SsDxpXnmWg2SJKFWCUiSlP5kwv5hj0EYszMYl154qGnSLpQonSIzmtlGlSfvO8aTD5/m3NkT2LYqoUvlUPcVOzsHdLpDDvsjJlEinc6A0WTE9n6H7d6IRuARpUdR84qylkpJwMgLXAxJkrM4U+d9Tz6CLnLuPzEjSRLy+Zdu0Iuy0vxVEH/qC1iazJabyEyzjmcLYRRLvVqhOy7Fz1O0GAMyDhPGUVzO3rSmVq1y38kVar7H57/6OusHPcKk7GyVgOvYNKs+Rhtc2xIRodVqUa9VsB2bF968QRzF5EWBMtBst6j5Lkkc0ZtEnFhdZnt7h2gS4nkeW50+gePy7R9+D1UbarbhvkfvoXP1smS715RlBQu/53ve9w8++D2fiT8N6sLF",
		"uzTwf9tL3b0E//df02efesq6cPFi/pd/3wf+wBdfuPZPf+7LV5uH4zitVTzHoMUYQ1oURElJ6TbaiGOVxITAsfnilR16MTRqFXa6MbbJeO/JGqdaDgcHHc4dW+b9D5+n5tgilPb9aZ6R5ZkYDGmek+U5hdGlu7LRNDyHlXaDVq3KqdVFijwlDGN8x6Lqe3ieK7XAN4gyUZKZOEvNw6dXWJ2pkxdFyeA7mk4ZQ2bKrsCSb6LyCWK0FoWRWCn+5E/8HW4fhJw9vcbcTJuFxUUGYYrYDmleUA08fu/3fjvD4YSFlTW+40NP8OrbW1y+usnx1Tn+t59/gWvb/XIIDlQ9F0vMtDAFd5y7s1yzujhPu+Wj/IC3b+zQdAy3d7vGEjGuJcaa7vJpoSnj00sMUmtMXpTU6aV2g8Vmg1oQECYJ/TCiFyV0JxFxmhsQHEtIprMlowuKwohSQpIXph/FZhKnoBTD8ZjheIwxejp3M/SHY/rjkN1OH6UU2wddNjt9OpOYJC/JCw3XZs538ZQSEQsjwuPnjvH7v/cjPPbgGRqNJsrzzCQc0x+MmF+cYRyG3NodsT9OOeiP2drZZxKG7PdHbPXGd37vNC9tkwwYEcFRFp5dwoP9SUSWJmx3RnL1+oZMolhu3t7m62/clPVeJGUBKqVruSkNxpWIMQYKIEkS4jijVq1QDzxqnkuzWgY12qLEUUfXrjCWZRmUxV63zytv3+KNq7eJsoz9/rg8IGU57XqAbSnCOGFtoc0wTMyt3Q5ahKAScHOzzJsqtMayLVqzM6S5QWPY2e9QqQTEecHG9gGu77G0tIArmEq9yl6nz053KEaQcW8i6tgH1KtfW89n6u750w/c+2dEMDz9rDK/jYPs7nZId9f/OUQHauEZ5G987nbxhz923x/f3Bv9ja9e2ZeNQawbFd+yrNI2JkxSCZMYx7ZIkkxG40mJtU9Fjo4IN7pj3nd2njzXhIkhynJWZipc2QtRymBbLjPNOnmWMY4ikiwnzsoOJ5uGpB11RfesLvDA6WOsLs9zYmXR5EUh27vlppUkaRmmZ9smStPSikhrahWPdsVltzOUw3H0mxh7gBTaSMX3cZSUBUu9Qzk3xmApIcxybtzeZdYrow+89gKbOwcc9ENOHF9j2O1y+sxp9jdvUOQJK6cfojOcsHXrGmtzVY6tLBDU6/QHEw76EWszdTAaJQpjNLalKLTBth0avlAzMe1WlSjK2RuMeP6NLRxlURhdunpP9xfXtmm4LpMkJUpz4iwrSSJFwSRJSbOcURwTl8a1dzYlZ2qLc0QiSbJMcgP1wJc0y8S1bQHwPRfBMA5jhmFIkmZEcUyUlA7ig/GEMEnpDEdkhSHOczAG11LU3BLii9JCHNfh8bMr/O5PfJiZ+VncSo08TXA9Hy0eeaEZ9Pu8+uZtLM/noDciyXIODruydThgfxRNf1+rdAwXwXVsCl1MZ2A2zrTTEgNztYDxJJJxmNA57LK/f8jXbxwcRZsfNW5MyYVlnHtpcU5RFPQnEaMkk0ZQulKUKLFiaaaBowRXCYFjSen350jglOzDSZzSG4ZM0oxRlLI632Jxpo5jKZRYzLdqWEqVcRmWiCk0lWqZZHtqeY6ZRoUbG7t0+30qtuDW6tRbbeIoZjweUa1VqdXrZuegy7HlORr1BsPxhO2dHdrRBr5VcJDV6e7vmoV68dDv+V3f/XMrn/z0/qefecb69KVLXLi7td0tSP8+wnSffuop60997rb+m3/wg3+xN4z/n9+40Ut7qSZKM2sUxmijSdIMyypV+HmeS54XmOkmbjBUfZeKa6PzgtuDjI8+tIqFIdWKuXrA2zsDRnGG7/u4rsvSwqIsz82gixwwokQIbIfZesCT95/m8XtPsTo/wziMWFlcIEtzrtzcINVatNZYUhYUprOFklKtqPsucZzz4s0dQf0md4g7Eci2VYbUFUU+3ezljrbniAnoOB73rs1we30XXZvh297/KMPOPkElwJGyezh2fIUv/dLn0cbwHT/wwyzM1bn19iU2Dib80Pd9iJ/71ZeYxDlzdW9qoVNaHvmeS1oUYAzvf+A4Vbtg0Btxz9ljfO2tHfPaxgGWssjMHdYaCtCFZhgnJHkhSZYxiVOiNCXPc8IkJU4zCn2HXi+eZZWUa8uaapQKSYscjUgtKOdaarrxG2OIswLf84jSlDgryIoyJjzJMiZRQjQtUFXfw7Ys4iwv2QtGGKUZ2rLk0ftO8ZHH7+UDH/4AKqiYHEdWTp01kkzY397g2vVNrl/f5MatHZTtEMYp65s7DEYjtjsDGcTpnRuz4tnYluA7Lp5bRmd4dgm7WTKFMQtTujsYU3Z+ecGlra5c3xsQONadfC1LEK+kN5ZpsEBg2wSeS2+SkBZGTizNkKYZtemBpebZkOf4tsJWgi4KKYqCauCjjWFzv0uUF/TDGN91WGzVsS2LhXaNhXadOEnZOhxgRIjiWHShqVd8XMdmpu4jCOt7PWaaNcIoYnn1GHmuScYjzp87Tn8wwHU9VlcXJYlimZ+bR4lhqzPEJaPt2fzcS/vyT3/hG3k73K7NNrO1v/Xzb/3jT/OccP4Sn77I3aJ0tyD9ezczsn704sX8z/7Ak3/p9lb/v3l9cxR3Y62yLFfjKCqJAdPEMN+zS1ucsgZg2VbJerLLTJ0oy41rK3a6Ey5vD+WxtRbdScw4MzywVufSxpiq7+AHAcoSHNeVxx+4X+4/dZzFVp3FdoN21efsiWPUqlWGoyH7+wfc3t5n97BDfzyRSRiRZhnoolT92xa6KMRRUg7U84LzJ5foRSn9cYR6x69fjkS3SsHqTPModqCE8/Q7PhIK+MADZ3EoSLQwiTI+/KH38siJFkHF5423brK/d8D8ibM8ev8qr//684SDA+579FH+7j/8Rb748jWeOL+KZQe8vXHAOEo4tTxPbzwBY1iaa9GfxDi2zeOn56nZBbbnU2j44uVdNg4HuLbcKUZ6GllqDJJpLWmhcZQS3ynNQKOsIDPvWPWoKVHEVkqkpLtjtJasKEiKQtJCG8dW2EpJs1rBtsrk1DTT2LZFo1rFthR5UZAXmjzPpwW7jE63bVuiLEMb0MaIBjm+OCPvvu8EH3jiAR573wcIGk0OdvY4fuY0B+s3GPX26XRHDEchBar05vN8hpOQ3nAsu/2RhGl+p61zLEWr6uPZNo1GfUp9t0SUwhKoBq5EWSFRmhOmGb0oYa8zZP2gz8EwxCmla2IrNQ0KBHuqwj5yunCVouI5EmW5WEqwBeqBh6UUgecyjqI7BaScr/nMtKokueZwOKYfpvTChCTXNAOPRsUncB3qlTIi/qA3Zm62SZLmMgxzzFS2gCha9SqOrUhRjCYRS60qqkjRusB3FEoMRhuq1Yps7+zjujaB5woCB70x5083WV5s8dqtEa9c25b3feQD2aP3Lj7wQ7/20/byf/qPf+XTP/Sf25/+5y+a57lblO4WpH9PitFnnnlG/ZHPfa544W//oT+4u9/7Sxdf2Uj2xpmV5ZlMokgEqFUDsunAO80KbKWI0gzbsfEdR8ZRYoxB0jwnyTWiytPk7X7EQZjJQ6s1fuW1bR5a8OiGmjArSOIISxSO45Tu1WnC9u4+2wcdUJap1Ruy1+1x2O0xnITsdAccDMaMk5RJmssoSQnTHKP1ne4q10YQYZKkHJupE6cF272RTN0nTbk1l2FueaFZm2lwenmeznhSOvpM9ULGGM6fWuOhE0vkhWFuYYG5mRbhaMzK6jJVM2T9xjrjxGA7Hk9+9OOcXK6ydelNet0OJ9bmybOU21sdDvqlIeoozjl/YpHrG7ucXp3j7MllNvd61D3HvPehU9KqOHiOohsWfO4b11FTCvU7EFNJWis7JZmaqBrqvi+zteDOPEUA33ZKxqJlYanS5O7IM66Yema4ji3H52ckSlI8t3z9JEqJs4w0y0jTFK/8fPFtG9+2y+4z8HAcm0EUmyQryLVhoV2X958/zkeeuJ/77zvDA489gS2GUffA",
		"jHr7rL99mc7+Pp3+hEp7QTKtRE0hy9Ek5Mr6juwNxmTaUPccKp4zJX9Y1AKPeqVKu9VkHEVobah4PgXgKGEUlZ2ciJS5TErhTuPOLVVq2UTeSawVSvnAtLhjK3AtJXFeWiopNM1aFUQximJs16HZaBAlCYHvsrjQJijdGIjTnL1hhDZl1MbqbBPfs6n4LjONCmEU4zguiJraDNVlaW52GufhoCzFaBxJFKXk2lB1bLI8Y7bVYNDvs7m1Q6USQJHRG47BlI4UzXoVy3KxTUSjrvk7n/kNDkcR41jLubOni1OrzY/88R/5jluNT/1PLz3/7FMWF2+buwXpbkH6bV2IngHrrz/7lPruv/mLxRd+4vf+8S+/eOX/8w9+6bXixsFQ7fVGKopT0UVO4LtobRhHCY5toaQkBsRpNj05l5uSASmmtjiWpUiyXKquJbc7IYvzTc4ttsmTiGMtn5tDQzDVEEVxwo2NTXZ398pZhOeapcVFwiik2+uxud8hTDIs2yIvDJ6tRClFWpQdm2UrHMvCspRBFGleSJSk0q5V5fzJZXnp2ibKUpTcvSMgC4xSKF1wZqGJmILxJMa2LeabNY7Nt/jIux/ijbdv0Go3WFmY4YWXL/HWjQ1MlvPI+540HqGMDvZNdxDS64148uMf4/RKk3/8T57nPR9+t6zO1fnlr77N128esHnQ4333n8CxFJPJhBMrs8w0m4jBtCsuJ5dbkqYFDjlX9of8+msbeErIdHlCtpSIrVSJjGHuuHsbxIRphp5601mWhSVS+shJOW+yoHROMBpjjqx8StudpXa50RoDSZaTF0VJKikKtDakeXGna9TaIEox16zRGYaM4pTAs3ny/HE+/Mhpeej8Oe595DEmgx5pHJkb166xubnL9sY2ibbQyiFNc7YP+hKOJ6ZzeEiaZVzb2JXDcWQAaVUD7j91jCxJmUQJge/TqATMz86SZQVpluHYjjlKzw08h/3BuIw9n0KtrqWwlaJaCXAcm0Jr0aaEc7XBKClnQaq0yhYFYiszFdsqWhWfYysLOJbixs4BruOS5TlaG5YXZiDPiCcR4/GEosgJk5zCQM1zOb26iOe5uI6FpYRKUKHdavD27V3evLHF3ExDVhZny7TfoqDb7aE1Eqep1KsVbNfl2u1doihmdaGN49iMo4Q015yc/uzDTo+ZVoMzp04QZwp9sM3v/tijPPCuB+Ub37gsX/i1NyTtj/RC0/3uP/HHft/e7O//yW98+jPPWDx3SS7ezU+6W5B+W3ZFoHYef1z90X/41fxHP3rvH62K/NVf+MrVYncQoUFmGlUEaNYquLZC7sQzW0enTjzHolH1idNcwiQTcwTpubYEri2WUiRpTmArXrrVxfd96oHPYsPhyn6CsWwsy8FSwmgyxrMVjYqPCBRZKpPxhO39Q+K0jFcYRRm2JQSOI66laAYuVdemOtUJJVkJ9diWRaGNjKOYk0vzZFlOfxxS9bwyc2c60VaisLXh933ft/H7fs938MBSjXuWW7z7vuMstBv84pdfwbEVK/OzLC3MsdIOuL6+xZUbW5y/7z4+8ru+hwU/Z9gfcmN9h7mK8Llff4W//JkvMmtlvPvhM1ze6MmHnniIL712jSfuO0EUhsR5xnyzzoljq4xGY/Ii54GTS/T6Pdqtujz/xoa5utMXx7ZIpkm4RkSyMmS1dHmYesOZMoWVtChIs4LCaDzPpbQlMugpQaQc0AvaIPpOvofGtSx812M4iaaC3VLrZUkpZLWmYuWiKPOKaoFHmJZO3I+eWeG7PvwIjz38IJVqDeX44rcW2NveMDdvbtAbhmzvdlDKxvIqBLUanYOObG/vMJmMpdcfycZBT/phhgNiBGbqNYaTiO1uHwO06lXajQb1IGAURtSqVXzHERACV6g4iu3OEHOHGF9CclOncwk8RywMWZ6X5AVtKIyh5jrkRktm9FT2arAxJNMu6fjSHL5bBulFSVqawAJ5GjMaTRiOJ0RxyjgpSp2YFppVl6rv0hvHJEnK8kIby/FMfxiRZTm2bZMkCfVaVZTtcNDpoVEyHI0J47g0x9UGEUNeFHieS5TkDEZjlGUzCcu/exwlREkuGovNgyHfeGuXRx6+h+/4Yz8uZ6qJJInI4diYLEzUYrv+vX/qv/i+oP09f/WXn3/mGcUzz8jFu6LZuwXpt9lS54G/srOjf/SjD31ajPXnX73ZKdYHCVGSqNXledaW5qhV/DLFMy+oBi61wLtj2SJTHFxN8ySUQOB5YjDYSlEUehqxYNAaLAXXDoa06jXef/8yG3tDhnFBVuRUgoB6pUKz0URZFlmSiIgyxfSkXvV9kizHthTutAPQRotQmnW6tkVWGEZxKs1qBRDJi5xcl1TlJx88x16nz3AywfdcpjpTCq1ZnWvRDmxMEtKqeaw0PAwOG3s9Ci24tqI9N8e7nniChlcG/V3aOMApYpbnZrj3iceFcMArr1/lha9+g9zApf0xvf0DVlseL17ZwzWGg8FE7j+5yPG2T5FnVAKfmudgOQ43tnZ57N4TjMOIarXCz37lbZnEOY1aIGleHMWziyB3Qu+EkiFm7nRKoI1GF2XnGqcZWVFgKQslisLoo89MtDHM1kudUZrneI7Lke+c1gbLso3nOBhjRFQpIo6yrIxq92yOzVb55IfexXsfe5jltZPYfpXxeCJZIYjjmTDK8Bpz9EYxSQ6T8YgszZj0eyiFjMYhO50BvTAp749CIwp8xzGWUuz3RxQG8V2HE8tzrC4uUPE9kixnpt0qu4s8o1lxGYwmHIxC4J3sBVGqFPW6tjhSkh0Eg2crk+caV5UknMwYMZR08LQw6ClkW/FsZuplZ2O0ZhIlNOsVjNHEaUnv7oaZiXIjk7RAyh9Dq+ZJxXMYjCcc9kfGdRyWFxfojyagCzzbApCDTp80LzjoDlhamBOlbN68vj5N0C0/p7wo6I8m2I7HcBIzCRM6gxGDUYhjW4wnIZVaQ4osk2+89pbUgpqcaNoEZsh4FHPi3D2S24E53DkorMH6h//I7/mgs/KXfupXLl68aD7zmWes5+763d0tSL8d1rPPop5/+lk+cvGi/IUf/vBPNiv+j7+9NSyubA/IilwBMprEAtAbjhmMQwLfpeqVgW7aQJYfJb6WLgeebZVhZkGp21ClklByrUkLPZ3JlLY91w6GeJ5PW+UcjhNs1ys1MUYQZaFNOdtxHJvCQBjFUpiyeAhQ9WzSvBzmi5SznihJEZHSb862xbEUuTbYlkWaZcThiKeeOE+BRa8/LNNQpx3D6kyTjd1DXn9rnf29Dl998zZaC48+cA+tVpPhOGRzc4fFpVVOHF/j7ddeI9bCfm8iJopFZSnH1tqyfv2mfPZLl/jk++7hB77nKf75r75Ew3V4/o11DgYjGoEnLoU5PuNJs+KxujRHZxgaQahXXFbnGoyHQyaZ4fMv3hDfs6m6DrXAkzQv5OiK+1PLpXya2ip3KBjv0AdtZU2NUxERNdVhfROjw2iOLy2AMaX3X57j2DbulG2XFSV0l+W5jOKEVBfMNas8+eBpnn73A3z4fY9z8p57qbUXpNAQhiGj4VjsSpV+t0eaxOxtb1NoI9VqVfI0JagEDIdDbtzektv7PYZhKeJVIsRFQWEMdd8TrcsuRRvDyYU5uffUGq1GlW6/j+27zDVLeNXkqbRqHm9v7TNOcr45oc4YQ813pVn1adR8bAtSjVFAzVa0XSWlFk3Es466JsinmiTPsji5PM9Ms0YcR+W8BiHPcjqjiTkYx4QFkupSe+XaIhqRwCkp9fVqUMJxwzGebROGMTPNGpMoIS8KsZQiimNcx2I8GiEi4jiOcaZpvEqE/d4QsR3iJGGm1WDnoMuV2zuEaYYF+I5lBCM3N3fpdrrMLy3SPYxZXJnhxV/7PC0V0qz5snMwkCwKi1Pz/tN/+Ie/Z+UH/tifuPid3/k/xObXnrU//fcu3p0r3S1I/y6L0bPqwoWL+sLFi+ZnL/zA36wH7n/2a69uxrf3h5bn",
		"WSpJU9I0l1a9QlHk9IZjCgO2pahVPMJ4mm2U52WbpRRRmiOippBRTpoX5FMNR5wVZNpQ4v1TtpiB1zc6zDQCmanY7PQiE6WpRGFElsZkaTqNR4hlr9PDsS1J01SyLMdSQprlOJZF4NliprMN33XJi/L06loKz3GwpkE81cBjtzOg2x/wwJnjvOfh+2hXXdpVH8ey2OsNmcQ5oyTl1NoKYZpze6/D3n6Xk8eWOXviBHme0u0c8OijD3NqscrB7h4Ho5SK7yJZxM/+3PM8//oNbu33RdJEPvmBe+UwRj77xTflj//QJ+SzF1+V9z50lo89dlb6vR4L8y2SVFOfmaHbHzI30yRwbYoolOu7A/nqlW2MLp3BSysloRr42LaF0RqN4U6Yx2+RPk5NhqawqoXBSDHV2lhWWbYcZYkpCmzHYTiJSjuivCCe6ri0hjCKqQWO3H9ikacfu4fv/vC7eeyR88zPz5Ebi9nlVdIs53B/n+FgKNGwz+DwkGGvw+7OPmlh2Nrckls3rjOZhKxv7nB1Y5edQShxXmArwULQpoQCHctCUUZS5EXBTL3GubV5mW/XaTUCuoMx7UaDSuCRZxlZGnHQ68vN/QEC08iLafsv0KxW8F1XqpUArbUxSpHnBXNVm4NhLPlUXZvl2iTaHE0W7xT1plcGL9q2zWyrTp5mJslKfz/RhVgCrirDFjGgjdDwLaI4xbYcKp4rge8CQp7nNGoBg3FIkeeyNNtkMJ7guQ7tVp3BcIxtKXzPpVYNqFUrHFtaxFHlvZ2mKQ+cO8XKwhwrsy1OHltiMp6I1ppX3r7FY/ed4PjaKlZQZRgWBF6Fh+5tMT7YJo21NOYWxORp3rnx9nvcyc5H/9R/9czX5z/+P+xcAO66g98tSP+umHTWH/kbf0MffOm/rr93sfW3NvcGP/aFl7eS23tDuzCFaF2QZVlpO+M7BL6H77tMwhjPsUnTlGEYo6bGlkhp1BkmOeMk5YhTHWflaTfMinIgDthWOYgv9DS/RymuHUwwloUyGrSWLMvQRYHr2GWWT5KSFoUoo8tN2BiJc8MkL0i0lkGUMskKwGCrkmSR5pos17hOacuTFZqs0MzPznIwGHN9c3/qNhAxns5MHNumWa9gK4vtwx5nTqyB5XDvmeO88fY11nf2qdZK37LV1QXuu+8slWLA/kEf27KJ0pQkTnn2v/lPuXprl/7BAfONCq12g4uvrvPhB09ybnWR3/k9HycbHXLl5hbNqk+sYRznYkzJYFQgWRrz5mbH3D4YSrMSkGQ5SZYZ33NxbEuqnovRhkmSULzDYZ9mSsmdPKkjiviRklYbfcfuxmiYbzbEEmEYJ7heCXvl2jBJUpKiYHm+xSefeoIf+MST8p6HTuEqRXNmjpVjKxzu7bO+vsWtW+u8dfky/c4h4+FQXNchjmImcSbDMGHU70mapFi2zX5vSGcUEbiOJHlBoUtTWN+273Q0vmNTlIaFuK7LuZVZnnziYZmbm+HGjU1SbagEpZP2fnfAaFgKZweTGM+xflP8sKWEmutQrVaoVAI8MpI4QeuCui3sDhIsMRLlhtQYOVLMHhU1DcYVw2gSycxMC2U7eIEvm1t7ZGksNU/hWcpYSsQSKe9vbVhq+tSqAXGWo02B0QZRpR/jJIxKhqTRHHR6eK5dPitFSQgqdV45ge+htUEXOUWWkqUp48mEXn/EwkwLzw/oHHbLwlXx2drcYmV5idbKcXZ393nr7esMcp+tnsWpU0u0Z1vmxsY+7ZUzSltudrhx68Rs3f/BP/kj36l/9JPf/eryD/3VxDz7rPr000/LXUPWuwXp30ox+tuPP27/p1/4Qv6Hftf7TnRuH372sJd8z2ubYbLbD61cF5KkZWRDpeKjtca2bZRlEScpYZKUm4UuZxOea2OMIc1LuCzOCzAYexoFewTNaVOe1i0RMq0pdDlsLgm45T+Ho5h+nBHnhZTu0SVcp7UmybKp2aeeijMNUV5IZpA0L0/VuTZEmSbONIFdzpccW8rYhIqP6zh0ByPqtQqO45BlOa7nsnPYpz+JgVIMOt9qcGJtieE4ZH5xiUGYEDjCJ556khdefp31jW2SPKNZrzMzN8eptRYPnFvm5Vev8uLbt41fbfCuU0vysY8+zi/88texbYXvWuwNYp5/8S3Or81Tsw2iE+JwQm6EhaVlslyjDZLFqfhKk6QxL904FM92aVY8BmGM7zncc3x1ev1TMVpT9VwC1yktfaakgynb+06/VBalcoBfCkjLudNMvUq7VpUozRhFMYNJiFIWC+0Gj507znc++aD55NNP8vBD92G7nlTmjjGKC67fvMXrr19hrzsyuTGSF5os18ayXbAdOeiO6YwioiwnTxKyPJfBOGRjv8vBOJKZWiAVz2Uwiaf3haLiuoRJBkphWwpKDZucO7Yo95xYkXvOnuX2+jo7nR6WKBZnm0zCBNAk8Zhru12MLiMoLBEcqyxMmTZU3KlvYJGz5Gc4JiXwPe6dr3L/vMd81ZK3OilKFIBRUsKHxpg7qbZ1z5b9wx773QEb2/umPxyIbQvduGBvkssw1UxyQ2bAdyzaFYfAc8l1Kdz1HUdsu7Qe0lqL65YEHttxSfMMA4yjhDjJS32R72J0QZ6mrG9uk2tNo14lzTJq1SpZXjCaRLx9a3squE2oWsKD95zki7/xMm+88go11+BVahRicbDfN6fmXHZ2dtBelZml48ptLOZFlgZ1iT4+nmx99x/+sd9xsPxf/rlLFy5eNL/27FP2//b0be564N0tSN+y9bf/88edP/jPX8z+i+96+MH7lho/UwkqT1zaSqJbO117+6Aj4zBmFMa4novvuiW1Ni/JBqVXnEOaZqVvXa4RMUzijDDNyyiDqa7jiEpsHVnwTA26ixK+E0ukjLEWpJi+Xk1ZT0muZZjkhFnBOMnKSOwoY7ldxZFy0K6k7KySQt/JPT/6NzclNbodlNoV21YoBa16vTTRRPBcl/5whO+5nFhdLGMKqhVsxyGOE47PNTm93GY4DtEodJby8AP38d7HHsKedNg+7ONWapw4scarb9zg17/8sjnsj3hzs8Pa2jJFnMrJOZtC4Ge/9DbzMw3mGwG/8totaoGLSibsH3QZTCKWF2aptmYxysG3FZYyzLaqxHHCKzcPKbQhy4pSJ4NQD3zCOAZEXMcurYM8j5L0oZmtV1idbXB6ZY6V2QataoDn2Ggjpe3QlFlWGHAdB13kYtnCbKPKfccW+ci77uWDD53mvpOLZm1tGSeos7mxw87OPsPBWPxGG235GNulPwrpDyfYto3leGQawjiXXBsmYUgUhvQGA9k5HLDfHzFJc1yrzGvPCk1alPOhqueUM768JKsYDGGa0apXOT7XYmG2xXgy5tbGNrVKhbl2nSgqB/ppOOL23iEHg9h4tiodLKZkDyWlA0PNd5ifabE412LG1cx4FiuzdU7MVXjhyq6stTx6GXSjzKipz+G0q0Sm8fRJriWwgCxB56kYUeyHBf2omEaZlPCg1hDnJQvPV4bCCEqV19qy7DsQNwK2Y2MpIUkLXKf0sgujmDTP8R0LMQZF2SFpsQmqNbSBOE5w/IDbG9tl5xzHvHF1k+OrizQDl/3dXRZn6rjK5uS5e5iEIcNxxO7hiMW5GeaW1tg+GDAYR8qrzpiiMFm4v7naqsin/ssf+viDf/ZP/vClh37fX9u7cBHza089ZZ/8kR/hLhvvbkH6v78Y/eSL2X/y5NmnfvR7H/9nUWqf/cLLW/Glm3uOEkOtWhHXtUtCQOBTC3yyLGEwDnEciyyd6lIKjTZ6ipWXKafalKQAKe12hKmgdCo+NFkJzxlbidhT/c8RlJRPMXvkKGhNRAFJoUkKzSQtSAvDOM05Pdeg6ioTJTlJUdKZcv2bn5OjU3HNs0EbolxTdW2MgUoQkOYFa0vzpFP6eJSkvPfhexmMQgpjpoLFGg8dnyMaDMiKnKQwjHs9ztxzlqX5FpW0x/44MTg+/+QXLrK6PE8vLXjh6lZ5",
		"Om41JY1jDAU/ffESa62AE4sthoOEv/Cnf4Qs1YzGIyzXIy8Kmo0Gw3FEnqcEtiJwhN1hzFcub9KolnCdEsF3HCq+x/LCnMRZjmjI8ozeeEKlWuHYQpvFesD9JxfxbMVisyoPnl7j9NIsK7NtZqoB8/WA00uzPHHPGg+uznJioSXnTy6zujjPk4+c496zJ6m3m6hKgyicMAkTNDAYjNAYxoOh2JZFkabEYSjValButkpxcNhlPOjLzs4uW9u7rO8dst0b3/E2tFQZJ6KBYZyip553vmMTpimWZeE4FpMkx/ccHjqxyCPnzzLXqmJRhjDKNCLCsxWeDfsHHd7a7CK6vKk0U2uoqT2QMYaZRo2FuTbNiseJmbJ4n16bIUxiPv/mHot1S7qTwhxGxZ2O0hwFZ01Fx1FeMIgyJplmmGoOw5wkv3PviXV0U0/nVmmuCawyoFBTapomUUya5YgqSUBJkpMXOXGaoiwLCwicUk81HEeI1gzGEWmuqdeqDMch1UqFq7e22NkrDVlnGlUm45Czy20qjhAlKYNxSLc3xg98hML0h6E4jiWdQSQ3Nw85feoYSwszDEdjbt68KQYlhfKybBLpRpA+9PYbb/7wD37k3pnHH3no0g/9o88NLl68aMxnPmN9+vz5u1De/4Vl370E/wryAqgHnnlGPvWTz2U/82e/9ztmffWZVy/tNX7mN9aTSRTZtm2TFVqG/SFilUmeURTTqFRQyioze6IErTW51uS6IM1Ke2ldHG0ABtGl91tuyh1hGq+j05KjbCq2EmOQQmtlDJLr8rV3hs9HyZ8GtJRRAOabbv0wyXlxo2vuW2qy1K4wjAv2x0lZIH9LRTIGdsYJJ1sBdlaeytMkwXUd4jhCmYJjS7Ns7XfpDUY0XOHBs8d49eo6SjQbuz2+/X0PcbbIKNYPubU/IKidBANnH3mUuL9Lcnufz/7CrxBHKadWl/kjP/JJ9vp/i9evbnNiadZUXCMeOd//sffw4ktvmjBKZLFdYffmTVqtKjduCY8/cIrdnX2KPCOMYyxdsLA4w2jY46uv36A7jtBaU/F9PNc2GMMwjOlPIvIsozcal9cL4cRiGaQ3264ReC6ihDTN2TroyjBKza2dDnO1gGOzTTzXplKtUK/XWZhpMYxStFLgBATtGXb3e2ys30YVKZNEkxQGy3YZxyOSNDOTMBIlgmXZHB4ekhaa0WjMOAyJ45hhmDBKS4Ho1JmHAoMNtGoVxnGKygtqrlNS0KfJv57r3Ande2Btlvc8ep5KUEEnYxzbolav4waaNImoBC7DbofXb+4yjHP8KUPuju2TKanrtlJUAo9WrUoSTxhIVsLOec7sYpPdCK71tTm/WuNyJ0Hu3HemDCSZMhRL6NkwyfWd++ybiA9GjkiLmNLjDtgd5xxredPik5AbQ5jkHA5GLDQqU9PWUvDcGYwJ45yqayGWTZiV5riBrRiGKYXp0aj49Htd7j25Qrc/JM9zBv1B6VifF6ZeCSTRYDsu2Fk5Rx0P5OBwiL+2wvLiDFprfvmXf53H7l/i0fuPM2M8rty4gXEDK0817/aryQMPnq5kh7t/cnfz1g/+jz/0vp++/6H7/pZ86lM3mBIfePO8kQsX7mYs3e2Q/q/Ni5596in7wu3bxXOXLpmf+qMf+2NV1/5bV/fi2vOv7WQHw7FtKSVRHMtoPEGUYImU1OgkJUtjCcNIcn30YMsdbYrWpTv10aBITU+H2mijRHTFsQls5Shj7Om3OoU2NobSjcsgrm0xRW8ksBSeJVOhJ0g5Wz6K9p7CMCUctzuMsByXlWZFbCUkuZ7OTswdvrOihGriwlB1FK2KS8VzKXSOjaHiuQS+x153AKJYma1z7vgCl2/vlsN1Y1iYafChj7yfZNChP5oQJTk6HPC//NTP8JU3bvLytR25vHVAtRrQrNdpeorvfN85/vmX3iBLEqIokVcv3+LHvu+DvHFrj4PuSB6+9xSvvPgaqwsNoxwXVWS4tiU5FkF9hmOnThL1uyRRyBcvbTL5/7H33+GWZld5L/qOOeeXVl5r59qVq7qquzqqW93qViq1IiKIILqFEFiAfeGC4fjaxubgiynVMT7GGIy59uViOL6kawMqfAQHEEgolbI6q0N15bzz3it/cab7x/zWrupG2JhkJLSfp9SPuivttdY3xxxjvO/vLYwbTSoFpV3Uh8cZeqMxjDVUC30oqTHdqiOXEtPtJm7buxNpniMUhCsbQ1zfGOD80jppIsxPOen62HAc2LsLe3bNoxL4VK1GGMUZljd7GA7H6A9HWN3o0cpGHxIC3d4Avf4Aa1t9FFJRoTSyLMd4PMby2jrWN7rYGIwwilNKC4W4MLBlxzxh7xEjTDVqUEojLgp43MVFTOLnfSGgS47gvQdmcPRV92B25x4sLy0hgIECoV6vIU4SLK2so+ozXFnp4pkrGyAia8pCZqyLtqfyolSNAixMt9AIffgo0KkIzNU9cE5YHyT4zJlNdDODnc0QB+fqOLceo8w8cplJ23s419oTfekUB6/s/jgROY8cIVcWkUeAdWO9SYpV5HMXhW4s0qxAb5xBa2c4BtzFb1wopIWG0Q7auznKYWHgc6DIXaS8ZgLVeg3WWoylwTDX2BhkFFar2Ld7B6bbVXBGVghOrekphJ6AEB4t7N0Lw0Msnz2FWxcDVKserq3HlIPj2lrCzl8ZGWkC9bp7drf3zjde0xDpe378+792x3d86xtXdzzyCyvHT5601h5j78NXxQ9fLUh/5mIEfvzkFXXn7Oz+X/pf3vAfp2v+P/7wE0v8U6fWdHeccN/3wRlBagXfE+BCICsKEAG+78HjjLQxyHJJmOQUaYOk0NCAVdqQs7uSNdYaY2E4kQ8QF4xxZcxSrsynLejjxuL3pbE//8Dh2U+3K/7XrPQzqvocFcEhCO62zdwp4qChFgYguPA1d2uFC2EjIgzSHNz3aX/HLXeJcUhjbhQlOBCngUUsDVoVHzNVD0wreAwYFxq1KMDmMIEQAlu9IQ7vnsH11S1cvLaKWrWCwWCEolB43eteiYg0njtzGU+dvYasUPZf/tPvprtu24dPPX2WxmlOt+5dpFqjSfMNQVvdHn3x0jqtbnRdgOBUHRXfx713HsA/+aFvxxc+9RjWezGmpzsQzN24l3spokabatUQG0vXkOQZPn9hreT6udu+Cyh0O7NKEBAsUCsZatYaJIUs0ULARnfgCAp+BC4Ypuo1vP6eI3j1/ffi8OEDuHT5KjhjGAxjDMYJVjb7NBjHMCAXVz4co9sfQghBShvq9YfkeR5ppUgpBaMVRqMR+sMhBnFKaS6pUIo8wRF6PnKtS4WafUnrGngexlmGQhkrOHMwXsbcXglApi0euGUBb3/zG7C49wDOnnoWDAbtVgNpnttKo03DwQBbvYEdDmN89sx15FJvZ0l4jJcFw2GNQIR66GPfjjnsmJmC0DFmqgyD3gB/5+234QtnNvDZc1uYbYQYxAXedvs0rvUy9BJlWflZBMrOvfR8TWJV6CbRCJWfXw4CI7c79Tkjn5MttEUoGDGUxaXcqGaFoaIcKYYeA2eEZsVDqyJQ8T3UPI6KzyDIwiOLSJCTuEuJLM+RFQpFSaZXWoMLgeE4BRMCzPOICR+NWoiVjT61p6ch0xRXLl3CKMnBuaB2e4oGBTCIFe6+bRftmQqRKdDy5oAqtSqFzWn2+GPP6yisqD237G+0696D3OTv/aH3vuXw3/3Wt1ybv+3Y0vGTJ609dlS87w1XvkoR/2pB+tNHdCcBOnkF+m23zn/LO48e+C1m6aHPvLBRLA0VSTAmGEOSplBSUhQG8DzPOcNLV7hgDGmWk5QSyhhLjJAVCtq4/QyVggXOyChtDQGBL0gwRktS2z9Ilf6JTNt/poBfVMDva+ATFjj1q3//W5/9wydPf8fKMGsnymhjLItKCKh0Yz63UAbBEkE7paxlZZUpU2nAiNCLU9IWODTfhtQAiCGVqjSBUnlIMEhjsTnOEAmGdsDR",
		"rHi4vjXG/p1OzLC00UUmFSKy+LrX3I317gjrvRFqtSqe/uKLeOK5c9BeiM3+CM9duG4PHjyIra0x7tzTprv3zuLTz11GzeeoBD64UTh97gre+NC9aE9P49TZS4h8t3+rCYbR2nXkoxhF2EJnqgmtFP7gC+cwNTuPTrPmltf5GJfXB/TpF6+DkSNPEAAhhNVKw2MMylgyFuiNYxetXXLnZqY7mGo2sbzZw1p3BGMJ/cEYm/0henGCFy8tYefiAi5dW8XFlU2MswLX1rZodauH4Sh1Bs7eCONx7EQGhYIuIzzicYw0jpGmKXr9ETYHQ4xzBc4YlDHg3MU2AEBWqBuxHe7dAJEzUbOyk4h8h/MhIiSFRCI17tk3g/vvvg2veMPb8eJzz+LihcvYNddBLhUqtQqq1QpWlpbAjMFz17aw0hs7xWAZYz5RxpXcWTACWtUAh/ftAScgH/ZwcPeUExSM1/HR0z2cXk0wU49Qr0Y4fb1nK4FHG+MCE9pDmbu+3S1tBynd+L8uEReAKDt6lJ2sYI6WXiiDdiSoHnIryv+eKesII2Sdx8hzbZnSBr1YIpUKVI6+a6FAzWfwOZEyFtJYDDOJJJcga+ALjtEopjjNwQVDPI5pHCdY2xrC8zwEgQfPKugiQ7PdBhc+8qJAvz+i2PrYGDNMtWoIdIz+OAFpg4XpFk6dvUZbmWXdrcSsbo7U8MoZv1Ks3zPcWvo73/OOV972977rPed2/+B/Wj1+EvZ9XzXXfrUgvbwreuQR8J8/BUNE9p9+/V3/6OF79v3He+/a3/rjJ67n14dSbI0zKqSLzPY87joKAIPhCIwzpGmGcZLBaI28kCiULgPLHEONESy5xCMTcGYtrK8NhCU8wTj9c1OYH86AX7PACwDi8oHl5Q/vV09+MY8EGavM1xljlbIgbS1VPA6fMTduKWMVmBuZbFMHJv+7rX4iQj/N0aqENN+IoJzOAnEutw8Ma11fZQFYIvQShXEmkUiFvChsu9UgbQGlNLJcYqM/wp6dcxjFGTa7fWitMd9p4cKVJTx55iosY1iYnQIxjqsXr2JHSxAxhmcuLKPmc/zR557D6SsbmGvVcGjvIj71wiVsbo3sfXccwOrKBv7osy9gulmB12yjWa8gTgow5mHvnkWkwz5q1RriYQ+ffvYCXd0cu/GNkiDiZSSfRbNWBRGjYZKgH7swQ10y6hgryRgEbA2GyKXEylYPuVRoNmoYjMZ44cwFzE13cHj/XgRBQACQpjnCMIC1hDzPt9NrR8Mhtra2MBj20R+O0Rsn2BwlGJSAz4rvoRL6zk/GGapRBXkhYbbpGk7S73Fecg+d8q0W+Ag8AWstjTMJ4gxvuH0X3vj6V2PvoSM49cTnsX79CrRWmJ5pYm5mGhYW3fUVXLxwDRdW+7i43geBu+sLTXaH9ia5tqNz7J7r4K6774bNY3gmRWE4OrUAjbqH3/rCMjbHEowIzWqIQVLQuIxGL8pR8Ha6sLVlYS0zzFFW2ckCuyxaosRXeZyQSY1cG9Qjj7QxSJUlwQiCAYJZ+Jyo5jMIBlQ9AmeANpNYEQupYXNtMco1OGFCkCBPkK0FLq4+KxSUtmjWK1DGEGOcsrxAo1ZFu9WANhacBApj0Y8lJDn7w3AwhOcJJGlG40zRpZUBzXbqCEjh8uUlJFmBIpdIswLEBfnEmB+GdnahI+d2NMXOmeAemPQ73/nQvvDw0dd98XXf+dPJ+wB637Fj7KtjvL/lBemRR8BPnYI5dQr2kQcOHnnrnfO/fOf+2R+MwkB/+Ilr+nov5/2kIGUs0iyH54tt/ly3P0SW5SDmcChaaeRSlg+4i4vWxu0yYGGUsdbnzFfG8kzbxzjoR1Jjf7jQ9gnpitCkANmbfpjyB+un6gtTNW+3T3S/NlaCEUuVQeBxCoQ7tMjtgIjKOT5nLo9oIiff5pQRsNyPqepxTNd8BH6ArNBIS5KDC5pjCD0OqSykcUZZSwwrgxRL610aZQVGaYa13ginr67iyvIW+iW9eWFmCo1qDQ/dvhevu2sfHj91hUI/QKdZQ6sWYas/QkAWnz+zRMoYeGGIpfUefI/QiDxcW9nEkb078A/e8xbMT0U4e3kF1XoVs7PTMMbAh0Gz2QCHoc8/9SLt27uILInxoc+/SLHUYLDQ1lrmhCfwGYPWmjKlIZWaEKuhrIXUBqMkRZzlGMcxtDYYJglGmUQgOKq+h2athiDwcW1lHXGSEgDkWYpxHGMUO0FClqUYDkdY29hAdxhjkGToJTkGmcS4cLQNIkfmCD0PvmOygUCIApfcyqwTv+SlApOXMn3BGELBUQkDEAhJoalZ9fCOB2/BQ/fdhZ0HboNMx1i+dgVr3SH2757FYDCC8AUA0GAQ4/SlNZxa7sHCgpdD48l+ZrJlZ8ypPNvVAAd2zsPjDHq4hqYPjHLXDWiV4sTjKyiUQ1oJIVDxGAJBNpMGhbbbkR4l3MJ5i8vLkHUh9zcOn9KQzAluBEeERBl4PkfAGRXKYGmssZUZiqWh3FjKNSAtIZEG48JilBsk0kDDeeIqoYdGxYfHObLCwFrj/gzGEXqcPE6ohRyFVOiN0nJnZ10emceRJClG4wRpnkEai1GSAwBWN7aQZBL33HELNtY2wIxCu1FFP1Z04PAB2rM4iyyJYblw6sBxikGcoICg0aBgG+tj22pV5NSs53cq6uE72+xbvv89by06/+VTT9HDDxv7/kc4jnwV3Pq3sSDRsWNgP//zMJd++b1hv5v+oDXyl9/+mlvvXug08g9+7gJ7+kqXuqOYxkkKqSSiMAQnwjjNYKxFkqQg7jA0suyEtLHIpQHZ7VuizQutpTaBAbgy9rPa2n+UGfxTae0X4bBfYnv/+9K68fIvdu+Dr/2D4dryKxjsEY8xpS1YoQ0FnJeBck6ypMvD7wY09GWzknJ+vxFnNF3zkeYS850mCqWR5AUIQCA88HKUUigDIbjtVENSxkKX/LLuKEFWKNy9bwFH9u1AnOa43h1AcIZxLjFKJfYtTENqjY1hQnPtlgNiDjN88dIq9eMUt+3fhYfuvQNPnbmM5e4QGxtd7JiqI01zfOrzz2BxKkKjUcG+/fsR+hxWFbh0dRWL8x3yfB+H98wjqlbp1OlzePziBkl9IxnWGAulNNKioCyXGKcZCuk8PBMZtC0NnGkmy0JlIbWF1gbtSmjrUVAyAAnaOIaaEBzLq2sgo6BljsFwhO5ojH6cop9JjHLtgv6MO5IZwRmOOUfoCYSBgDQGaSHhCQ95ueOYn2pDCA+b4xhknVk19DwEHkfgCUilMcgk5poBfe39+/CWr3kb/DDC1dPPoLu5Ck4Wi3Oz8HwP1XrNZmmMYW9Apy+t0hfOL6HQenuEZu2NtNeJ4tMAxDmn3XMduvvILZhvR9gZZWg2Ihgvwu5de/H5p0/jc5d6mGhzPCEQegK7mwGIETZGxXaho22iOrYHkc5Fd+OzGbp9qJO2c0eZ55yDjOskpbY0LskUubZIpEUsLeLcQBl3qVDaGWvdKpDQrASYa0bYN1WDJxjAOJQBpLLQ5dg2lRqs7DxlGWOhtHbILEYIwxAgd9n0gwC+52HH7BQqYYBqJcLc7BRajQam221UanWooIbFfXth8hzcD8C8EN3+iJZXNiCCAIoECs2xudpn03PTNvC4DOV4zufs609/9Nde9QPvfs2z8+/+9dWTpfABeMPf2sL0t6UgEQA6evSouHLlijl5Eva9r7v1637vMxd/o+LRe7/x9UeiPFPyxEdfFBe3EkqkYpNuqBIG8DnDOI6RF9JhgJQEAzlFj3VjAaP15MA3WhulNfzcWGGAJyzoH6bG/hNl8UJ5Bkxed4M/Y77KlStXbNTW/5dMcLfS5janFncP+OR3EIKRE13Y7d+YJso7Sy/ZUVgLbIxzaoY+qoKw0G7CWkJcSDDGbS3ySWsNTsxaY9CLMzRCD4UytGO6hXroIc5y+J6HvQsz2DM7ba9tDdyoqxohzgpa6o7RadawtL6FUZzS0kaX",
		"lje3qNAWSZoiEB6mp1oYDsfI0xSvvPMwvv/b34rPPfYsTl3rYt/iNOan2+SFIdWiiK5tDunDT52lu/ctwAsraLWb2Nrs4rEXL9OZpU2EnigxP64gGVum8pXzKQ0LwRnmmnW0qhWEnkC7FqHiexjnzqystPPVaG3IZwTfE6WU30OSJlheWSPAICsU4lxtFyGpUY5oXZCh25s4NM5kJMaIkEmFJJeOvSYERlmBjXGKvJDYNTuDrFDI8hwV33Pm3PK1H0uFe/Z28LUPHaH7HnoIgc9x/dJFjJIc1TAA4wFaUzPIs9TmucRUp4nnXjyPDz11AYU228ZVc1NXtH3bKZV2i9Nt3HfkAB0+uBciH+NQBxhlClc3UmijcX1riBeu91xnAxdt4QuO2SpRI+C0PMgp1+WFrDRu00u6cyJ7054pENxdnsgVN48zYsSgtELAGMWFQqotiGCdFN79njWPo+ozinyx3YVZ66q/xwUi34M1zovHBafNuKC1RNFIGkSBi5wfpcoaa1H1OXkMsMYgSVM35tPGfQ7IpeQWUkJKDWMMkkxiNE5BxFCtR0izHEmcojdIaO/BgwhQgHSKLBmiN0wxTBUuXV3Fuatr5FfbtLXap0+dfI4nY6Vb9Yr2fX44H43f+/fecf/+b3z4nkuHXv1zaydL6sPek1fwty1/6W9FQXrkEfCZGbCTJ68oaz8ulj/+uePnVnq/sH+uOX/voYXCauCZ8xvsfK+g1a0hCcHRajXJCY8YFUVB4zilTCp0e0NobZHmpdRbusRVa421BlppTcoiUNZeNaAfPXCr/cGVdfts+VzeXIj+R79YHKNoGvyuF3kPa2P3FsZqAhHjBK8sRpwIBqBCm+1N8s1z/e2iRA7EaYkhgCFSBRq1itUW6CYpYCwiz4MyGoHH0ar6YBZkrUWcK8y0qlYbg944J24tcu1yhK5v9lAPPQCWpJTYGgyx1hvhytoWVJajU69iz/wUVrsjaFUgywsEgnBopoHX3bYDt+6ZwaXr6+gOExzcsxOVWpM2NzbRnJlHNaqgEzi00ezcPNLxCBsry3jh2haiIMSuqSYa1ch6noDgDFIZJzzmDJHnoeIL7JxqYnGmjXq1goV2Fa96xRE0Ah+yKJDkEqrceyhjbVpIGCUhVYE4zRAnGXKlaZAVGKQF4kKWSafMEQJuRAo5nxCIJpw8wIJzchEUvodmJUI9DFANQoARBnEKjxFa9TrSNC2J6hb9pMB0p4a33LmTvvnNr6Y7HjyKs88/hyuXLmJ5vYfAF9YSUKm2KUly9Pt9aKVw/sI1fPiZS0gL5WgbJRqJnEKTqOxMJuO7KPBx1y276Z7bDoAzi6K/itmKwUY/w9lrPQS+h+eub2G5OwbK2JJ6FCLwPTywt4FGZHFlM8UwN3QTGX27S3cS8BvjgElBMrAwFhR4gsLAg9YGhXumqNAWubnxayY3Pg7nWWIAMcbAGIMxFgFnCH2ByBeYb1XABSdNHMoYxLlEKbjEjnYFf//hA7i8OsQ415ipCuIEeILKsEyDOM0gtYaFRVFIJFlupZLuWSeiF89eRp7GGPZ7EJ6PJC2wNYypKCRVAkOzUy14KNDvJ6i12tixYw4yLzDKNHLrYVQQNdpzrNvPlN+c9m87fPC+TsV8x6MP7dn5rjc/eP5N/88PbJwEnCLvb1Fa7Vd8QTp69Kj44Aev6CtXYH7he9/8pl/997/9a5fXhu+57/BOOd2u6c+/sMS3RpIu9yUyBWq3m9s4HKk1kixDkhfbceMO92O3RxHM+YqMNcZIbQJDUCD8gvHsd2fSfmxjA/ovWIhw01iPx0A+26x+ioz9zlybUFtrA84o5AQGS4IzcGI3HLLlDZJgAbIvExUDaaHQyxRmGhGY0aiEAQLhIckKRIHndlPGggOYqYcUF9pqLSlJCxgLdJOMxnmBoshRKIWtUYLeOKWiKLA5cEbEXTPt8kAwmG3V7Pz0FGVJguEoxs4ds3jXG+/BU+eX8VsfeQbTEUEaYLozjSxX6I0TElxgutPAZx5/FpEgzLbruLrahc8tfI/j6XPLYAQ0alWEviBPCFSDABVfUCMKwQDMNCvYOdPGTMuZYBu1AAwW7UYNrXqlPIAM8kJN3lsyFkiURpJLJLkrWInUdLNUnjMGj7MbnYB9SWdKrOyQOGPwPIFa6EMIhsVOC7XQhyW4Axhwogbt0FPjtIC2wP1HduHvvP0BfM3XvwNhrYlTT3wOG1s9gHkwYKg3m2jP7EFaKLp66bK11uL8tQ2cfPYi+kkB33ObmonSkk9+gEiQY+BJY+jQjml69b1HMN+uYenCeVA6xHAQY5hozNRDXF/bwufOrWGieDMAKoEHjwkcvWMGd+xp4OPPLGMs7XYndDOwlWBLGuANRFbA3c7S44TAExR6HBZUevY4jaSCsi/rEMj9GvebGiIAsiTlegyO+B0FEOUOToMoTt3FhwHwBEM/ye3X3jWLfirxxNIYPmNkt0eZ2IYKw2hwIlQqEaIwKONGNAajGIJzmmq3IJXC2voGPCGQFhKZJmyOJILmFA7s243QjJGOU0zPLaDZnnIx7tUqKKjhhbPXcX0rY8sbsR1JXxpRDZpTU68abV799m97453TNmw/8a2/9KnkfdbS7adO8ROnvvKp4l/JBYne/8gj/Kc/+EH92E9/164qx889fnb5Z/JM7X7lbbuKd735DnZhqceubSYoyEM/zuF5ghgXkFIiTVP3ITXuxpbmhS0K6dhy1sIYBautBazWxnrGkii0/aQm+x2xwi8phVG5I7J/wUL0J4pSPyk2m6G3XPX5O4lIx4WmkDv5uTLOaY+ykDAiCM4Ba7b3SfYl4xr387aSAoHHURNO4VWv15FkBQLBqR4IMtaSYLCRB1LaohsXxBhRYZzKiVtDVzf7FDCiHc0IjIA4V+jUaui0GoiiENfXu4A11B+OcM8tu7DQaSDwfXhk0RunOLuyBaWtPbh3F5S2UABdvrqM+++6Bb4psDEYwiiJPYvzkAbYWFnGKM1xbqWPqXYTU502sjRFNQrQbtRofrqFPEncDkYb+JyhXquhXqugN4xhAMSZK5R3HjkIoxS2usMbuwULshbEGJE2hibiaFZ2nU7B6KIsJkBcR4Qico4w2n4vhODwPLebk9qgFvrwhEAipR2lOWmt0ahXsTUco5+kmG5W8fWvvg3f/e6vxe69BxA1p/D044/j+tIqIASmWjX4nodxHJPHLa5fuwruCTx97io+88JlxHkOzomstttj28k/+SSkkIgyralTi/DgHfuxe34Wg+66DXSGPVM++inQbNUxXRP4yAsruNJP4XGnjFNl+KLPBQ5MefT6Iw1aWhvhzHpxQyhx0/7o5hbJwpliJ146nzN4gsMTHGkuoa2BIMKoHIkzvMTABBcBYsmJb9iNvRVQkuo5dneqCDyGWGr0xhkV5SjRI8AaS7CKpLF0ej2lQWEwlhay/ItXhAtyhLUuW4zB5V5JBWkslDaktcY4STEcJ2DCQ55laNQiFFmG/mCIZDSisNmgZrtFoY1puHKF0iSlfqJoaxDTaJSQBpHnCYCIwqjCCs0tVRqy1p6rHj6057V37Z/+hjfdd3B0x+u/+YUTp05pa9/P3/e+9+P48eNfLUhfXiO6R/ipU6fMiVOn7E//3be+5bHT135nvTs+CkDdc3DB3H3rLv6F06v0qRfXMMxd7IKBxXicUJblGMcJ0rxAkqaI03R77FUoDRgX0ZxLpaUxpDR8abChCT/+9m+2P/DF53HtJrGC/iv49iwAPirUM7PVoKOtfnVcGOlxxngJTxWlz4WIULgZPDixbSf9zRVycpvXxqKb5Mi1QcMjNCoVVGvVUllmEXqeSwRlwP5OgLVEUSINGmXg345OA61qiDiTaEUB9sy0kCmDpd4IsBa5Ugg9gU69ijsO7MS9Bxex3hvgA597AVu9EcIwwPpmH3cc3o+dO+aRpwmMVtSqRehudRE22lho1dFqd1CtNzC35yBIZvjc8xewFRcQQkAI",
		"jlGSYKPXp93zU0jTFEmWoVmvghhDJYwQBj764xRxLlGtRCASGCSpA3VKiaIoMNWqgaxFoTWqvodWPcIoLV5SyCeFxt4sGNlWk934t240JcCY4x0WUiIq86Y8IRBnOQZJhlxr8oUAg8Wr79iD97z9Qdx5xwFI8rG5topnn3oMZy5ex/zcFFpVHwSFWsUD5xy5zLGyvIGz19bxuRevlu89YMp0WyppB5MdjFPXWShYMMHxmiN78dADd6NdD6FGfSKVo1MPAOEjCjyMxjF+5+nrAGfQ2pA0IGuBZjXCdLsGFDkttgTadQ8ff7HndjfbyhoqzbIEC0tm+/VzBY3KC9MkVh6MOSEJAePC7QPpxiu8bXMKGCHwGHmCg4is4AycEzzPgxA+GAyqoYfNUY5xYcAIpI3LkRKcoRYKjHONq/28BMoCubZIy4TmisdQ8ZhT0BYFCC6ZVyqNvJBUKCeM8IIIeVZgOBzZjc0+tVtNq5SlIs+xe9cigs4OTC3uwr0P3IO5JmH96iV0e2MIP8RgOIaSigbjlLS18D2f1pbXaHOzbwrDZafTWqiQ/eZ/8N63Hf3619x6+tCDP3Lt+PHjkwymrxakLwsF3dGj4uc/+EH93qP3z3/HW+/5tysrWz/bHaWtOCnyt9y3j0eVkD57ahWffGHVMeTIIVoKqVDkBWWyQJrlbuJVOtetsdZaCyklCimNVMYQka8slDL4Je0F701y+UenTm2/php/9ctINr9fftQm/oMc9lChrTLWTTN8TmDlgMTN2id4GFs++JMD4sZhyss8m3Gh0c8VFhohFlpVypTBKHFMO8YISaEwSiXuXawhFITI96kfZ0gLZeuVkPpxhvVh6szCnsAod56fWhjgTa+6CwOH2MHmYIT+cIQ4ycHJ8drCMMBMrQJhDfxKgLWtHkEpiLCCVrOOequD+d170F255kLwRj18+PHTAHdYmSTLoaSG8F0IndIGjUYdlTBCp9XEgV3z6PeHWN7sI4pCNCohtDHo94d48fwVe+n6OgRndMvuBUw1q2hXIkw1KhilGUZpsa1eZKVkeVJ8JllAk10dXkIscB2FLwSsccdxoxIhyyV64wRZobE5TtCsBrRvroFvOHoP3vzae3Db7bdhvT/CF595AesbXQg/RKvVQBB4SPMCoedhfWuIK6s9QGp85tnzePryOhi7Qd6mm89yS3A9Mm0XCWkNXnvnAbzzba/FzOwMrpw5Ay5T7Gj78DkwyhVIxvj9xy7iXL8gwUAGBGMJnuC0e7aDWujjrsUK1QKNJJX0kRf70Nt5fRNTtvtj2U0MoVA45qPgbpxpjYbHCdoCo8yl4SalWZhtk0e26z48RvA9Dk9wUspsB2FyLqAtR+AzzLcqGGUS41zDFwxGStSqIQT3sHsmwqWtlLZitf2+Tl63VFukynVj1YCDw9o4k4gzBWOcKs8CpAp3gYnTFFxw8oSAtu4vmyWZFU4tgqWVLduNFS3ccjceeP3rsFC3qLICIWeQSiLNFAptyVqLwjAaxymWVjbZxasbqjtIdd3HgXrof8f/8l3fNPXOb3z4mQPf9u9HkwnQV9oY7yumIJW+Ipy8ckX/6Nff/U1Znvzm0urWmzmDblZC/fp79vJnL3fxieeXMUgVGrUQSirUalXkRYFxkkBpjSTNkMvCjb+UgpYSWmkorZDnUnFGgjMmLOiTlrPvjKX5BaXUoHwtDf76VDG0sQF152zrI3Gh3jXMVUNb2MATVPX59ghJGQPBCYwxWHvDl0Q3CcInhyzImRULbbA2SmFlQbVAwJbKPcGdIdHCCQumKh72TVfBwKhVDbExSqhWcao17nmohhEOLs5ByQLzU20wmeL01VWcXeujP0rgcYapegROhMDzMdV2ENNW5GPc72KUZHTPbbeAtMSli5dx2+2HwayGVRlGvU1cXF7Dx56/6mIHiMrvz8IoBc8TmJ+fRTwawWiDvXt24cLFi84oCaDIcyTxGONxjFGSYhAnZEFYH8S4vrZFoccBYzBKMqz0xtuEdLo5t2MiEilfVyrHYaaUVLOy0FsAUipoa1AJfBRSIi2cqq8eMTp6xy56wz2H8Ogj34Cl1R62+kNcurKEM+euolaroF6tIPBDx9SLC1gWoDdy/1zbHNvPn76Kc6s9iFIZehNg90ZbQTctMQlQ1uCu/TvxbW99Fe64+wguXbiKzY11kEpRDwWlCphqRzh/eRm/81y3HF+6ossIiIIAO6db6NQCzIaSpioWtx6Yw2OnNrEWq5tFCMRsWREnOyBGiEQZMSGcACX0PAjPg1LWFkqDAEqVftnOk7bLnCO5c3iMtou/NhbC80DEIZVCOxKwREhyg8ATJbSWlYZowunV+AY5/6aJIJGjq4wkMCoMOHcqyUJbKG0swVoyhmAMCBaMMzSqVXJRGm6kH6cJXV9ehZISViu6dP4ivvjMs1hd66E2vQCbxbjztkUszLQx26lhOIzR7/WxudnFOMvJaklRtcq8sMrW+qlOC+3tnGm/eqYmHnnPGw8lb3nF3uce/fkT6uPHjolf+cQn7FfKGO8roiB97333eb/+kRVljx2jxcP8p7YG6b+7ujacigTlr71nLz+0b5EuLPfp0y8uwwsCcM6QS4VxmqE3GCDJpTM4SgkwgtEuBtoYDaMttDXGOMRyYEE9Y+2P9Qrz/YUyV/+SBAt/3tGduDpIhr5HsiLo66yFzpShyBNoVHwU0u2UOLkpvLbuod3+DeilM8WJPEy40DraiHP4jDBb9ZHkBUCESuih4nGAGHqxhFYGvaSAshy37pxC4HvYHMQ022pg3+Is0jTB+euruLreBRmNmXYdE7z49FQLlSBAUUiIIABnDKM4w9xMC8gz3PvAQxRUavji86ehlcaRI4dQ67RR9DfR21zD42eXcHFj7PYCFtBaI/B9hGGA0PdQq9XKzje31UpI3PMxGCUQvo8ky5GmuUPwZAU442AMKKRG4AmyRmOrP8bKYIxMOZcn3aT0cocze4l5zJaVwL3e2FY2Ovaco3yMswxpIbEwXcerj+zANz78Srz+jW/C2iBDwAVG8RhpkiHPCqfc6g9AJYV7MBhBBBGur2xia6OHKysbeOLMZax0+9sd2qQY3lyQbnRJJUXcWixONfF1D94OYSVWl1bw2WcvYqs3QMM3aEQeVnoZhsMh/vDZNSwNC9fllNQFY4DIF7h93yIEAXfMcTq4o461boLVjRj7OhVcH0hI42wJBjd4QRP5e8UXMOUFyOccYRDAE57NlUJWSDBGlEq9PS5nL3v9fUbwBCH0yklAaWvwOEcUuqgNWIVqGCBXFmmagXGOQhqE3IkyrvWyl1l18RLgHiOHHPI9jxZaFeqnEoxISG25slbVIkEES1Iq5z9knLzAIYbGcQYmPKuUQRwnxOBUmMxKBEEACw9hNUK9VQdP+miHFhvrmySscgZbrRFGAaIwpM2NHrt0bdluDQqlNaY2ry19w9NPvfC697z17rOP/Jtfvnr8+HF8/Ngx8Ssnv/wxRF/WBenYMbA3nAT925UV/YEfedve//T0E7/y/OWN7z5zdVN36kJ/7YP7+WZq8Yt/8CSdWe6h02pSEAQklSGlLY2TlFzeioSxFtzNyKG1hjETnj60VMbXBtxa+9sc4t3dQv3BTa+f/p/8MrC9t5inmyp8HSwOJMooxsACzsAJyKSCMo5KYMve6MbhVZ5RLsFiMm3C5OAhInTTgiLfw75OBcQIwyRHUij4QmCQK2TaohlydMcx0jxHQEBSSFxa62KzP0AkiOpRGSsNoFWLtrOVIk/AWoLne6hXK5hp1dGqBiSsIb/apP5ggI2NVTTbLUhpcOvhfeAmxXhzHcl4iD96bhlxVmyrBTlnCARHZ6rtCoTWyIvCMsahlKLA9+H7AZI0g1IKaZ6DOIfnCRsFPrQyiHxBtUqAauhjYxgjUe4gmbQdllzsx439kb3h7bqpRSa4g9/AGTgNgGolxL1H9uIbXn833njvftxzz11A0Ma1lS5gCoyGA5d9",
		"ZIEoDLEw2wYDIcslhnGGYZxByQIry2u4sLyB56+s2FRK1xltH/gv16RNuHEExhm0sVjo1PGer30IR9/4GqyurIMskBUGjBOEzmCZQD0S9PzFFXzsXP8mQYGb8xpr0alXMN2qoR4w3LunCgbg4lqO331+E/unfByeb+Hsenzjl9FNCkQiVEtMki8EPE5Q2lheXgio3Ndm2vVzbFuxZ7c7JJ8zN7Zz3T9lSpO2oErgUSgEOvUKFto1QCtsjVzkijIWg6TAjlYAMGCpn4MzTNKC/7RLHwlGuG2hYX3O2FI/e8wXbKS1mecA8wWTudRktEutHY5TpxS0QC4VRdUqJUmKXn+IRqOOXAFGGSilcP7idTz/4hXMzUzBaIV6LbRzMy2qCkZSasrTjFrNOvI0AaylOE4YRKgHmZWHbr/94G23Hfy2f/gt97d/+O++9blXfN/x4XEAHz92TPzql7Gp9su2IL3/kUf4D/78KXMSsO/75ld83/L66NcZY6+UWhd37O2wV925h15cK/ChJ68CIJqZasMCyAonVuj1B1BSbXPexkkCzrjNsxzSFSijtYEx1jcW55gQ39/L1fsSrbt/Beq5P3eXdBTgT2xA3jbX2qj57Ns3Yolm5NEgkZDlQ+gJBs6Y2yM4B+H2fsPCEk2W8fZmwsNklEe0GecY5hI7mhWKAg/DtIAygB/42IpzdOoRKhxu5k8MFZ+Dc4ZBkoETUbsSIgoDWCJsDGOMkxRz023s2TGHnbMddOoV7Jtvoe1rtOoRZtp1pErD6hwHFlrgjKPRbmP/3p2wSiIsNvDk2WV8/nwPncgreX4WRaHAGaCkAhMc2hg7AWlGQUCF0sjzAkmSIM1zd4ADiNMcPnd7jMjn1GnW0B3F2Bil24m+7Kai40CnXslos9vFfXKBJwJCX6AZ+tjRruLQzhkcWJzB215/D77hDfdgui6wur6Jpa0EWxtb2NhYg4BBmmYgBnQ3u+CeD60tLl1fK2PmNZZWN3DmygrOrXSxOU63RSrbXZF9uUYadHOHoYzBzk4TX/vQEbzxLUfR7w+xdH0ZJATScY5avYZAAONMYqEu8IGnlqibSAi6Yaqe1Ib5dh17FhdovhGg42s8dX4TqQKeuDrA1W6Ce/c0sXemhlPLY8cKvOlhqXgCoWCwpXnZ4+7CkOcFkkKWScgGmTa03WmS24FN3jNBhICXfi9OZC0wzhQEIzQqASyANCvAodFLC+QabiqSSxycq4NxhsubCfiNkd+fVpRQaEOjpMBdu6YoENTdGpt3VSK+XkjzCqV0DQQygJJSUW8QU6EKGK2hlSFlFALPRy4V0qLAaJyg2x9hlObgXohWZwoFfKTGw0Ovf5Be8er7UecKizNVqCzD+poDGctyFLh87RrSLGNxYWQ/UYK0fl27UnnXP/j2h/Mf+bf/+IW73vF/zwHAvv/9/H0nTnzZ0cTpy60Q2WPHGN533BLB/voPHd15dXXwv19aHn7n5c0UQegXb79/N88Ux4efXcfF1S3MtmrUblSQFwpSFtDGosgz5NIhSQplrFQSRmsUsrDKhYkpo01YuDyH/6Ma6h9dGWMTN3hz5m/ae/j19y1EZpQ/c24zOagtVC8umBACnmBIc+Xm4CDk0klp3VXaQhqnfLKAvflQvXm3JBhDYQw1It/ev3famYLLpe8wydGsBDCqgFQKllytlkoDjMEYQ/UwgLaEIAzAuIAfVbAw08aO6SZu37+IesTBrEE+7mF1ZQ31mR1ohQbLV68gqE3BkkBYayKqVlFvBqCt8/hXv/00Pnt6HTN1Hz4jmytNhVSw1hWDerViK2GAMAycAVMriqIIwzhFnKSlzFhgME6gtLaCMfI4oRr5yJXGi9c2oGzZO1ogIAZiDk/DiBFnwN6FWTTrFVxdWUfFczRuxjl2zU6h06hgfraNKPAg/ACpJqxu9rHQqWBzcwN5XsAPI6SFRVhKlTnnYIwhTjIEvsAwlRilObq9Pq6tdu1qd4hRVmwXGSe1+dOf5Yk0veQc4tadM/iaV9+Dg3ffgWuXrsInoBYKrK1uYGljjGqtjulQYk+Y4mPPL+G/PrNs/VKxecMyYMnnDA/eeRC3H9iDDmJUij7++PQqZuuR/b3nV4kRYe9UZL/t3il84MlVPLWSbYNOBSPMVgNwAEUp8pjshjzGEEttc2XgMdAgV2XU+U1CkbLoBoyhETAEHkMlEKS0QVoohEGAmWbDGmsx164iHg0xlkCqyQX0aYPDsyE838PHz3bLfDFL9kt3R/AYoeFzFNpgtlHR9++b8i+uD048drX/6D27O0fWN0d/r5DqXcSwI/CYDT0uGSOuNaFRr5LwBKISRSQ4R5xkACPMdZqoRiEajTp8zjE11US7VoUnCM2awK7FDtLNFWytbaA3zjHICcoyZMra6dkZXL2yglqraYbjVC80/XDnXAN7FjtPz8xN/XS8d9eJV77y++SkMOHRRw19mRAfvlw6JDp2DOwNOMof/tVf1cePA//8G+/5gcEw/ZX1fvy6568Niv072+Zb33Qnz42Hz57pYZBmaDer1Gw2MRyNUGiN0TjeNh5KpZHmhc0LBWu0u9EYY4yFVdoExuCLnNHfG0j9M+MCSdkV/XWo5/7HBR0A/52VcbG7GTRHuXpjLK30BWOeYORxDlMy9yYP/zZOiE0gm/SS4Tn9iSUvwSNCIhWW+jGmaiEaPoOGm9frEu3fjXO06hU3rigkBCMEglMlDBBVIgfjjELcsncnXnX3IRzcPYOKD3S7A/j1NvzAw9Ur17H/0C1oTU0BltuwUsPuW45gz/491Ftbsjbv0QvXevitT14oJc9u3FoNfAjBb0A9yY2olNZEjFOSFQgCH4VSSPMCOxdmYLQLTRScl82ORSUKsdEbYZyr7VlmKQqwxroxnLYGke+hVa/BExxZkuEdD99PO3fMYffcNPbuXsTOxXlc78bYsWMHMgWM4gzDJMO5K6sA8wHuwxiCEG50JaVCoYH17hC9YYzCWHQHY1y4sowLSxtY7Y+QSTXp1l6igZ6YcG9+4wgoCQ3uAL//tn34hqOvwNTiLlhj0d/cArSLykjiDI1aFUGthtDkOHd5Gb/19PVtKTZtd4euR2pWA9x95BBakQeR97HVGyCWFlElpGev9aGMwSizWJgK8a0PzOL3n9na9ht4jBBy99fX1kIZS4U2kErBExy5tqRhSTCg0OYGBa9kEFLZITEAPi85eIwTI8fCmwyhiZy3KWLWuvReD9YYstqiVQ9QCQKc3xhNulv6UsWIAWiFniNBWGsHmaReUsjdM427ZuuV9uOXN399rMyHFhrhiTjXibW4kzPUPEaakbFKFaU1GhCehyRJ0Wo1YYxLwzVaQmuFwOfodnuI4wxe4D5/670c1alpHL7tIA7tauL2WxYQ2ALteoUgC3geQyEleULwQjPN/ar2ye68dP7yO/Xq4obNbwAA/shJREFU5tt/9se/R3zTNz58Zs87vy9zo7yjYu8bvgt/0xl59Dej2ByjU6eO04kTfxIwevToUQ6cxMmTUABw5j99991PPnfpx89d2vyWzVGGei3Kjuyd8oRfxYeeWceFtR7GcYbA92hy6K5vbYKYcEtPIZBmOQqpQETWGgNGFkUhlTQmMMZCW/v/5oX9Z11g+D9BPffnfh9fu7vZen5t/NFcmVd4jNLIY57gnHJtEJe3TZ+zEi/k4gaUdiMfbW9EWW9Llyc5TtuZS+6mTcRwcCrC3ukmcuZjGKdgBFxY2aSZRhXVMLBaOm+QsSCtNIIockBP47qnmXqI2/bNgTOO2w7tw9JGFzZLsThdhQLDPa+8366vdyELBY8sAmTYHI6xtL6JD3z+LL14eQOCu12DNcZ6nFErCiwXDDAWjDEI3x1ClUoF1ShAoxphPBqDC45KFCCOM/i+wEZvDAuDahAglxKXV7vItCoN0NtvvPUYA+ccWmtUAh+NSoTeeAwB4OgDd9GuHXMYDEfbkrZra10oY7G4MAsYgyRJsLK+Ad/zUIkC",
		"NGtVlzlUSIS+BwBYWt+EMRZpIbGy2cfGYAxlJmw8OxkhEt28r6I/+emcJMFGgY+vefAO3H9oB9qz87i6tIbVpVWAe+i06ijyDEEUIs0tlLaWj9bxXx87g7VRBrEdI3FDnaetpUOLM/jGr30zsvWrqOohrqz0sDhVx1I/xm88dhVEQNX37EInwsMHInz42U1cGWlwckDTSLjdjwFZVmLAW9UIgSew1B9bY51ooZfmUKW5++ZaYcqU5HbAUAs9+GUw5kQCKYSwXHjo1Gt2yjeQliE1HLmUtNEbYabhY+9UlX7ricvWumJHL3uYLAAEnDDfrMITzPqCkEmDjXFuqz43+6aqwSjOfuS5tfFPTV7+vXX/cKzMjwXcfkdFAIwoJ86FtUQ8iKCUQafTROgHSJMY8zNtpPEYaZoiqlTQbjbgCWdhrIQBPMERhhFu3T+HAwcXMdfwcf30KSSZwVacY2OYW4paUJZjfbOHgJOZrQemErDg9lt3wQu9F6falZ8bbW785iu/7xcHAPD+9z/CnSr5hCH6m3em/c8oSGQt8L73HaM34BPs4eMn1ctv++tHQbMnYU/cJBj43M++d+/GcPyPLl9b+54XL65Xyer8vsMLxJhgl9YS+vz5PtYGCZq1ENpoyrIChZTwPQ6AMIpTECOkeQGpNHzhWaUkYIyVSptCax+gs0T0j3qF/pskWvgzixsAmHbVu1NY/L5SZjdgCwswbS0p7cyQLgTNJcNq4+jWxt441AxcgZooogguHgDlYWjtjfHJjoaPxUYFzHPUgTjNSBmD0PewPkjQqNVQj3xcWV5Du92CMQbDcYIo8HBgvo35eoAgDFHrdNCMAsxNNxFwQpwXttpsI4sTZLkENzmGW+s4tzLE586v4vLGgCqBh1FSwFgDAqwBSDCGdsV3WR6CQ2kD4bmo72oUgHOyPnfjtigM4XkCZK29tt5D6PsU+BwrmwNc3RqUB7+FvkmU6Jz+DIwI9UqIwPPQTxIkWY5b9yzQwsw0ojBw3RljWN3YQpxm8D0Ps7NTLu6+KBAGAYoiR70aYas/QBqnEJwjS1OM0wzdUeqUn0pDbb8V9qYdFZGxNyde3WTMLT1nALBvfgrf8Lq78Or770BSaDz/5LNgno9UGvR6Q1SrEbgQaDdr6I0Ku7a6imfOXcGlzdFklAVedtO6fM8jwenovUfwqlfehTPPPolORNjoZ5iOGJ6+soHPXR4AgK0EAq0oxAMHGhgNYnzs/KDscFyxqQgGXjIGPcGoHoUIggDL/TEYgDhN7VaSl6QGAptke5WFlhHQ8gi1yEM98lAUCgaMlLWWMUfFmO207UzVxyjJwLwAvVFMg3EMYoR3veoW/NLHnsPKMEW5Crx5Ug0AqHocu2YasLC2EbhAzrVRht44s42QYa7q22GSv/N8v/h9AAGAHABmI/+bOOl/63PsCwRXwuVtsVxZNBtNeJ4PayRazbpLX95yFxc/8FGPIlsNOFXCEFpKBGEAbS3mp9s4uG8BctSDTBM8cN9BXFnqIWp1cPn6lj199iqIC+zbswPjcW5qrY4d9Tb8gzub2DVdO6us+c/Tc43//Mrv+vcXtkVhR4+K2//+rH3hhSP2fceP2y8x1qNjx47R7befokdeOGLp+HH7V30x/2spSMeOgZ069QidOHHiT3Qa738E/KG3f9/+f/d7zwaf+OLpa09e7A22/9uxR2qry+sPZoV59+WV/te/cK07u9pL5GuO7NTveviQ+O2Pn8OFtTFiqUkIUSZfEvI8p/VuF9YCrUYNsECaZS5MrShsnktwwaC11sZYT2pLjNhvVKPKDy2PRltfJl3RnzaC1bubzf3DbPwTzNp3Vz0GSyxPlBG5MuDcSRmMcSMQqQ2kuZHgqeyEWj1ZmG/XOghiUKWAYHIoNgNhj8zVMdeqYnNcUFK4MMPlrSGqUYRWrYI4yyA8D1IZVCoh8izHYruGhXYFxDm2hgmiag237tuB3ijF3My0tUZiq4yzMEWB9Y0uHr+yjuevrqHqCzf20GYSVU4eY2DMpYdOVQJUQr8sJgQhOAQnG3gCgjnm38x0B4VUtigkhOekuhyGnr+8im6SO09R+Yhoux0sbln57wUBlcCHJcIgzWjnVAt7d+5AnKSIwhDTM1NYW98EwWI4HKPdaqDZqEFphUroQ0mNjc0tZLnEIE4wSjKXGms1CIRqFCLOcqSFgp5sTkqMTrnEnCSPb/tyUF4mPCHw2tt242uPvhIH7rwT60tXcenSEvIkAWMMWgPd4QjVyEO1XkPVF1he2bAfeeo8Lm8M4Ana9tMwEAQxaLhsrEM7puhr3/hqzDar+OSnP4dGLULke4DM8EfPXsXaMLeCgE4thO/5+PbXL2B3YHH8dy5gI3dE/JA7CoKgMqQwDMiRLCIk0mC9P4SWEmNl7ITUQDdZFSZCkzoHmhUPtdCDhbtcMc6hLRD4AeY6Hdus+Dh1dRmLMzNY2+rRVn8IEgIPHFzA1ijFZ88tgzN6iR1i8md5jLDYrqBSrYJbZQPOaVAY9IYxOIM5MFsXnlUraabe8IWl0fmjAC/p3Hq+VpuxKv0JC/u9ISc0Ql6AGJfakBeEEJwBxBCEIXzPcx2oMxxbZjX5HgMXAs1GA1EQYKrdQJ6llBcSuxam7atfeQv27JmFGvXQ3epha2uAlbWBXdtK0E8UtAiw3huZy0tr9q6Di/4rDu3A/t0z/Yowv+tBnrjl0MHPN9/yz7ZeMqe0oEcfBVtfB73hJMzxL7Erf//7H+GPPnpCf1kWpGPHjjHgOI4fv/GNvWUO1Z/9yR+ojwb5bJyqtzx77vqjj5++drjQhhtjVyIPTyS5enaqHu7fMVU/Wq2Gh9a2Epxf2jKe4EW7XuOHd07Tk+dW8NTldRhjyBMCvu+5pbo1GI3GpLRBpRI5dZFSVpcLVAZAaW0LqYy18JWxW2D40UFufunLsCv6Uu8nh/N+Ykfd+65IsJ9Wyk5Ja2VcGHDuhK7GWGLMeUqyknDMibYLEuFGgJr7je22JFwZA0vOmWOstaHHce/OFuqBoERaCN/H1fU+ZtotMGuxORii026DCQFPCLRrFQgr4cGgOdXG9ZUNrG714fsBwiCw050WZAlsFVAYJgUubgywPEwQMirTXl3xtAA1owB130MmJdbGKQQjzNQcEHMSXlirRRbG7Zq0VhCehzTP4ZdBhFONGuWywOdfvAppDGSZH+QxDkYMCg4bM9m4sVIc73tOLeZxjr075lAUOaQyaDXrqFSrJS3c7SmLLN3e6SRZgTiTGOcuetuWe7AJTqfEU5WLfmWlMa5A3pR5tb0TpBv+sr3zHTxweA/uvWUnwtY02nPTuHb+LEbjFFppGMZQ5AqBR0gyCc8T6G1s4slzK/bMaq88nPW2oJ1sCSk1QORzvOnBu+lrjj6IqxfO4cz5ixCCQRUScZ7jj59bgrawHiNMVX0EYQWv3w18/2sa+MALGv/mo9chmOt4JmGQZCwsLHHOUQkFOOfoxTk8BjvM9U0jSXqJxB4AQg50Ioc3YmTgeR4MSuk7cSxMT9u5VgXX1tZg4GGUZHRlZQOGgMWpFvbPtvCRU1dvfL8vu34GnLDQqiAMAhil0K4GSBXQG7tg59lGpDsVz8+L/Dc/eaH77mMAO36D6q8AYLrCv04X5l81Qnan4CSj0AdnjFnilEuNqFJF4HmQSiIMQ/i+jzxNkUiFOJdYnO2AE6FZq8L9WoBzjsXpFg7snsYtB+YxVWfor17HxsoGpmbn8ORzV+xnn13C89e7WO+P8YZX32umqr4xSomZZsCrAXD7nqkr9ar3h9Od1ofuvH33M3jw21aJ9mU3f///+X/9uvZmgv23H9jdmJudWr3z3T/xYumFYSCyfxVCib+ygvTII+AnTriD/Se/6813XtpM3nFw99TrOpVw7ziJW5u9cSv0/KAfZ6CwYueaVRtLsOX1Lk6dvYysyGFc4FqRFtJYY/iRhTbVaxVc3ozx/PUtmu00HE1BawCENHf+EsEZhYEH",
		"Im61dMvpXKoJTsZ4HuOFMswAfyB88Y+3RsUZ3Lh8fiWgOFj5T1P3cRiGfrzisW/X1upCQxJIaHfNJFWaZW/kJFmryvPOwS9xU+Caw5xLbZwyz06QLm6cd3CmRgc6IawlpFag3WggVwb9OIUGw1S7icFgiLl2A1WfY6M/QlSp2OF4jDhJkEsFRoQoEMiyHMxY5Nbi6laCTGtUAx9KKihjoEoKReT7VPMFBFn00hyZMtvKrNl6iHajgcAT8DxuJxw5ax1SqDuMoVWBarWCqVoFF5fXcGl9RBbWxllOPuduZMmYjUKPBCdkhcYoy2C3iwKByHUS1ShENfAgpZP91mtVeIK74qk0pJTIpESaaxRlhDpKFaPHGXzhAQTkpTydMee1MXBBgjfGdHbbdDspRK1aBfcdWMQ3vfW1oCDC6qXzACcYLqCyHJVqhFwaF1IIDlVk0FpjZXkVF5a3cGa5D09wK5VCYdT2CJeIwIjDGIvDO6foHW89iio3ePa5UyiK3MnbI4FzK318/MVlcEbWus4ZXhDhm+6q4gde5+Na1sKj//4UlNHbRA17U/ejAWoGArtmmlBaY7U7ssMJXLVk+1i6mUJBCDnQCpyPqRp6aDZrSNIcudQQwkOt3sBsPbI1z9C51SEMCN3+GJmUqEQB7tkzg6cureHK1tAJQIz9kwWpGcHzPCitMF0NAeFjlBYopEIUBlZrjemI8lpgHvijU91TZVEyN18Oj8zM1DbH3X/OrP1hzog1Kl6utBG+70EIn4IogiWCLCSiKAJnhG5viFhKdMoJTxT6CD0OWIvA93HowG5MtZuoVwMYldlX3XsL7r5jF0y8hRc+/zROPnEF1zfGeHE1hiQPnUbVhj63eaGNNZpa1cDfOV3BroUpkGD9wWZvae+8v3RueXDx0y925b7F6YOe8I4EHpu749Au/+5DO+J2PXj++ubWf3j1/+0X/os9doy972XNxt9UlR1NipH94A8fuG/f3M/+wWMXfuapsytfc+by+sHT1zanTz55vvbZ56+wS8tdWa/VTOgJe/bqpr28OjArmyMtNYwmbjZHiV3vj1kmDXv3G+9gu2fqdGZ5TN2kIGMNBCcKPI+SvEBWFFDWgDFGnvAglbZSypI9pQBrrbFGOQWdzcH4/zoo9A8lub55RPeV8jUprLzQ2CgM/s+pSFwQjB4mojpnLFfWYfuNgTVO8W0nViRHrAbx7Thqt9qe4Iccl4yRLRfMk25qKy4oVRqvmI9Q8RhI+KhUImdyzAtEnoeZThvEOJJcIi7Jr/F47OIrihzMGhR5gWHsIsD7iQTnjgSttEGhXSS4KVVksiQvK22QOMm+5USkSximIAc1zYsCUeCDSuVZ4AWohKHzJWU54jTHIE7g+74DaEpFnDNwxiyBoLQGsxZaG5p4ZybLK1uaYDOpMEpzNwa1QJLlGCcZBuMUgzjDIJNISrsBY8xBV+lGUqotP4K5VNs7PPMnnK6lJ6g80Dv1Kh68dTe+6TV34XX334m0UKhWQ4AYLlxdcyPBUQpZSGhr0RukUMYgzQsMRzGevbiCc8s9BEIAsKTtpFBOSD9O9t2uBnjFLXvwqntvo2eeeQGFNKgEAtYCggwubsRYHSSo+wLGOsxU6Ac4uLOK19xiUOvU8MGnh+iOim1xwzb/r/yzpDGohR4KqRwCqkz0nfAX6aZwv4msPeROCRkEHJwxSCkhuEAlitCq1dAdj8ljBpk0KAyhVquiFoXlZ4CjGQhc2Rpt+/BuHg8SgHrkIfA9cMYQBAE8z0eSScRpDgCkLGnOKJqtBOMX10YfmX0E7NSp7UutAcA3kiSPlf1IM/SeL5R5bSFVOxBMEgwRY+CMkdYaWgPWGqSZi01vN6qw1n3Ox+MEWZajPxxDlrvYcZJBKotxKvHYFy/judMr2LVrP7QkHDlygG5fqCAyKRq1GprNGtWjkDZ6I4rTggqp9QuXNtRHn7pgnnr+YmXXVDArFQ5wr/7Kw7fse9WBvYu37FyYbo2TnKQ2JhDwZDLcc/jWfe/8kR/7gWblnX//Q5/4hMX7AHb8L1G595ddkOg/fu994qf+f6vq3733oTf91sde/IPf+ey51zx1foN1R7G8vNEzl9e6pjtO7ahQNs5ydvbaOj17/hpdW+tSbzimXEoqlGHEGJvqtMnnRG+97yBedccuPHdhAxvjAu1GDUHgpLxSGaz1huR57hbnAvUkrHWwQgbAaGO0AXKlA87ZF8NK8O0b4+I3ccPz+JVUjF5emBgANijMF+sBOymVvR/ATgJEwBkXjHgoGCcQZwAXxHgoyJZ8Nnsj1I/gYpYcB4yTC0ebRGGXklwaZgrLQ4m5mgfBAOEHIOKo1GqwxoALjt4ohheG4IwhSzOYIkWc5SgsMIolEgXklqCdzJqkAQqtkUr5EqYcgeAxRiFndqw0Wdz4+3qcoxUF0EZTJQxtKQF3TDPGITiH57v8of5ojCwvIDwPTHAM43QikycqC3PoefAFhy8ECSFQjSL4noAhu50yO/nS1lplLJQFaeOUepP8cCr3JtvkBwtL1sIYS4K7ZNrQ9xAFAqKUO9tyN2TKzoIxhsWZJh64fT++8eh9uHNHE1meQxLHytoGllfWkCY54rzAVrmSXe+PUY1C5FIjzQpsbm3hc89fwLWtIRhj24e90nqimygxQRY+53jtnQfx4H1HcObFs4AFRmlOUhuEgjAaJ3js0kY5q7JkLRB4HO1KgHvv2Y/7X7EX481V/PELCVb7+fbojRPBZ2wbZ2QBxFmBWuihWYsQ5wVyZbbhqtsv4OS0t0BFcASCEAQBhO/EDb7vo1WvI/R9gBiaVR9JLjEunNLPkts1DtMMO1tVrA1iSqXGy8WKREAtdNYGx1vkiMIIxNxeEgAi3wdnIII9EFD0G598IhneNG25WZ3PR4U+dXCx8YE4UbdKbQ5HPtdK6XJV50jlfhCCl5BYLgQIQFEo1KoVFxyY5RiNU4xLIYzv+fbFMxdx+sI1RH4AmUl0t0Z0fXkDveGQIpZhuhFgdrqNQltoqWm6GZFUCr7P2QO376Z3v/Uuc++9t+lKs6N2LC7qnbsWtWDcHN5TtwemBEar16nBCiyvrcvq/EG95zVvfO0//ebDu3/nU1d+/44f/EFj7SP8+PG/HMjrX0pBOnbsGJudnWWnTp0yv//kivn0P3lH/Wf/8Isf+e0nLi9c3hwlShsWhgHfvzjNdk412L6FDt1zcBHzUw10WjWMC4mV3hj9OMXGYIRCKRqMxmg2W5jtNBD4gj79zCUI34fULjsnyxUxAlZ7I2SFAgPIWltmGQPGuHu9tdAg+JnUzOPi380f6HznpWvD86Wv6MtRuPDn7pZGhbkWavsbkmETrslRytjnDehDAH0MZB+rBd5vHZiq3Jvlss6IjLEgO1FHcVbu4CyMe723KQCTg5M5Yjid72YAATJNkWYZeoMRAIt+f4g8T5GMRxiPYyRZirVhimuDDJtxAWkBBUImNUa5pFRpFFqTKuM+GW1jOmGs84mAgFSZ7QPFGTMbgLU0zCXm2nWqVaow1mIYJ9Dabj/0UeC5TkoI1KoBGOPYGoyhtKFJu2itJWMd9cJai2oYol2vQTCiVq2KTqWCUZzi5fZKXkaz2psOUgYCx42ugBEgROm4hct61MaAQORx15Emykn2AyFwZM8M3vbgbXj76+/H0dc+CCIOI3z0kgyXVzZRqzcgtUa3PwbBIlcajHHUay6CYzQa4/rKOp46ex29JEcoBDhj4IysdNEqThLGiJjLlsVd+xbxwCtuQ70aIh6OXAepDPmCQ6YJlvoxLm2OSwipsdYA9dDD4uwMbDLC2x5sIxsM8IePb2J5qC13ynxyMNpyHFm+FtKZ0VHxODgs4kKVjHIqBQ0vfY19RqXFyaJe7oyNtfB9AS44LBgCj8Pj5PBI5V0gyTJIpSE4x+5OA1e2hi8pdpOvis8RcBeVUQkDAiyM1mAAskIhzXKq+p4aJVl7ZTA+nWnz1J8ycbEA+Nog7973",
		"mtf95sbSNeRSH2UMwhoj4zRnaV5AKwkhPBjjYtSLQiJOU2itoZUCZxxuOiSglUJ/MMA4SRH4AQ7smIIgDVaMaXaqBsM8QHjY6o0AlWChU0OnEWKtG+OBVxyie+84SFJZXN/K2OdfWKJrazE/d2WDeYHPri5tsufPrtDe3TvpzW+9j2ZqhsJ0SDTuskuf/kghrLq/Mzp1y0MHFk/e9TW/E5eRGH/hs/QvukOiRx4Bm+yKrP10/dM/81/u/tzpy999cWXzezaGeX7bvt1811ybDu7fgVqlQqPuJpbXB+gOxkjyAkIwMLL2+voAXzh9FaevraE3SggAQs9DLfLhM4ZWo4JGtWIXOg1UfI6LS+u0NUqw0hujKCR8QTb0PeKMIZcanmA2zaXS2gaC04bg/Pu6WfGBsvx8OQsX/sIqvJufZwDFy3/SK/d0PhWPk9fCIu9mio8Ki0IbBB4ja6wttAUvb/yMMTI3sfIm0q+J2dAXDM3QQz0Q8FjZKBBHIjWGmbSDMnl2wluz1r78SSa427Sd7KrsTSObTiXAKCtQGEPWwgrGcNtiB3kusTHKKJMKC40KZmamrLZAlhfgvByVCY756TbyvEB/NKJWowKpDZ49exXjvHD5V+VRQgA8wa0zaTrPUuT7qFcjKmThWH3WYpimyAplpbGw1mwfcZPvcRu8Wh7AnDMIwazSFnmhiDOyedmdcQD10MeO6Qb2Ls7i4M4pHNw9jWp7BplkGA5jbG1toZDSMeCYAOMCw37XSdbJCTYqoY/NzS3IosCFpQ2sbA0hy06Tc2597ujwZRIupUWx3bHsnWvjobsO4xV3HrJPP/ks4iynahhCWsBnFvGwi0+8uIJeUoAIlpXtwWy9gn0759EKFb7tbovX3z+Nn/m9VfzcH66U0UgAJ6KAu5HgJIXXlF65qYqHUDBc7aXQZUy8+RIjzIbHUPMFAp+h06xBcA6pDPwgQOAHkNqCyMAnC5BAXDjbR5IVDhklGF65fwcev7CMS5uDiQR8+6sTCsy0ai4a3eNUqVQsEYPSBqvdAfKiwP7plj6zvOGvx/lHCn3sbUTH8d+Yumzvqmci/1uMVv+fUNBs4DGljEUlDFlUjSCVgZTaxYkQIfAEtDYYJWm5NyTrIugNPMbQajXw6rsOY+dcE9YacObRoUN7Ua9XsHPXtLWC4/2//gH6jT9+Ghc3Y/v6Ow9AGoOLy5sQnKPTdBlg1SjATKuOA3t3Yn5uBhsbA7zmlfsxWy/QKlYQUIqt5RW7kZJuVXhQm55+Idp14B8tvu2nP0x/Cbd7+ot0RcePHzcA8Gv/8Jvvjo39gc8+f/lNF5e6B/bMtvCGh+6S7XqdXbq2aUdZToW26PXH5Hkc/bEDmk7GF4FgtlP1waDBOaNhmuOxU5dx+toGxoXaVh0BQL1SwXQtxEzdx9mlTfQzBR9Aq+LZIPChjSGlDbQ2epwrjxE91wj5u9di+QL+BtMW/pqVeOxmX+VkrLcH4FcA+5Zb5343TrO3bQyyzDImVkc5YmloMvc31trAExPJMVnrJMGuWrhZ2iQ44OaHmzN3EBn7J0cj7hHbnmzd7P+hcvFvJ8y6yXWzHnioeAJbcQplQRWfoxH6thaFUAYYJynGaUFVn2HHTBvgnjXGolarwfcExnECRkDgCRSyoGYtQq0S4uK1daz2x+glCbQ2298DY2S9MuIhEG5Uk0mJ0OPYNTNt6/Wq21EZg/5wjCTPkeWK0rxAYQyyQr7sdjDZjTAY5mSMoS/QrkeYb9Vprl3Fod2zOLRvF6J6FaNBD7oosB4bDIYZRuMExhpYbZAWEp4fwBMe0jRGtRKhMzWN7mCMa1evoDccYXlzhO44g8+ZBQFS6e0DOBICxBgyKcsxqcF0PcL9t+7D3XccxrC7BasVljYGboTFOaBSXFlexWfOb05+H0uMQNZiV6uG6alpHOgovHmvwuHDLby4rvHUk2v4P0/F6KYuusErx77GWviMwRKhVfHRDD0orXGpG8Pa8nM38cjd9FUVDFWPoRL6qIYeiJhT3XGBer3hui+tIIsCU806hnGKVCpIpbHVG0IIgYWpGmZrFXzwmQuQWr/EjNQMBKbrFfi+h0YkUKtEYMKDNqBRnCIZjywD7AurA6r5otgx03jj6aXu5/87q4BtwcOO6fqhdBT/lE/0jdWAIfRFDpDItSXf96GN697ttk1DY+wMw26sbiw8snj9K2/H4mzHqTaTHFNTHVSjiGam6qg1qvbaeg9/8OFP0VMXlrHQadhOo4ZxWiCXEhv9EbQxCDwP1cDDzk4DCzNTmGrXsNUbwBiLuU4btx7s4B1vPYID0wKV3fuRSavzs5/y/WoDo2Du537+Q+afvu99UKDjf24Fnvjz+oqOHz9u2u128+++4fA//81PPvv3nzy3HM5NtfHow/epPfMd+/iZFXZh5TTiNCdrLfrDMRFZ9McxFudmYK0GwDDbaSKVhtYHiTWqoJl6hDv2zeHIjmlUKxVsDEe4vNrD5jDBMC3AmMVsq4ZaIHB47wKGucaZi9fsleUeuoksgw1gieAFvvi9V+xrfd+nz2yulN+rwle/7E1d0ksg1dMArgAqTmR3ZZAhVcbO1kPM1RmWymV4ma5JIIIvuB0kGQR3eUReKXrQZVqtKomfrBRHTKgHEwWftTcUehMJM77EoUNE7hbxsqCfQDCMc0nKwt6zq4O5Vg3PXR+SBLdKK2TKQANIpIHSBswqeL6P0WjkFtS+j/F4DK2126/kEhXfQ6dexSgtkEmJsc4x+fvDWpJaOxGDLNCqRjBS2UFWQHT7GGcZpjttzE+13AHaM5Da2B31FjWqkXtNlASMdQm3nMH3PSeQsBr7Fqcx1a6h2e7A80Nw5m76V5bWwPp56WnKMBrnGMYJPCHgCc+OszEI5GIbuE+FsiiSAhv9K7i+tIK13hC9ceb2QZ5nXWz9jfsII0KhNUhrNyqysJHgdO/BHXjzWx4GLxLEvU2MsxytWgQmAuSygFYFLm4kEMRBZErTqinT+DjiLEc/Vri0rjE/V+DxCwXWUov33N/Gz53chMe2cUSw1lHRBYBhkkNJCcFpWzRj/xsfZs4YiBEssRsdtlYwRkFwH7VKgGRsYIocHgO8KHSFt17BMMmw3B1j10wHb3vFIfzeEy9uj6ABwBiXheZbD9YAwzhFreGXYF0NjxNdWB/CAKrm8whS/x0An/8zPIMKAF/eHJ0F4ZtmA+89w1z/61zpxUDwggg8zwz5vg+rtetYy4iNVq2CYZxhlBUYFhoztYjiJLVXltdhjcFMuwmVJbja7eLMhQxxnOPFy6sYpilakSPZv3h5+SXVkjEGaSyGcYoz44QuLK3beiVAveKIEamUOHttDc+f7uLW/bPYM3UGD79+P99x6D5p0j5mo+AfPHrHxXWiX/zfrT3GQMf/egrSpDN6/0/8ncXNteEH/sNvn7z/9EpP/8Nve1P+DQ/dxT71xYvsxMe+SJYYhBBgZLHZH9CllQ3EeY6FdhMWBFZ+YNe3BjDWQmlFvieQmwQXvnAOs60aDh3YBR8CRBy3LM5hYboJJXMUWQZDhH3zArsXptB8x0PYGI5xeXkdL1xYNo+fW/HWuqPfHmbykU+d3tzeNb//kRKbceLElw1s8K+hOG0vXtPy2c+NWcu0xSjXIKR2tlll89ZibZhuu/YzqdAIPUo9p34DAMYZBBFJbaHdFdBKgxty2vJk4fTS0dz2WMu1XJa+VPduzUs6KoKjUjdCYe/fP48wirCZWNQqIeI0wyhJnXeKCJnW6I9TLEx3wIWHPJfo9fvwPR+AG1PAAknqJOBeELiU2yhAIaUb+9wwD8KW2KVBktrQ88owR408z7G6voHNrS5CP0Cc5dDaODWgUrhl9wJa9Sp275gFweLS5WuYnW1DSo00yTA310YvztG7vokw8u2V5Q2KxymC0EdhgFajiTTLMBq4PVxUqdo8KyCLHM1WE5xxcM8glxLrq+vY6I3QHSVICglOBM4ZlNFEjFnOnJyb",
		"Mbfkt+V+TBqgEgg8dPs+PPCqB9Db2sLG8jK2+kMwa8CYwFa/B12k2Oz1sTnM4Jc+JVPKsjl347VGJOz9h1q0sbyGHfN1ii4O7O+/MMIPPxzhdbd08JnzPVRKWXwGvR3VUfMFGAOSwrz0g2pvCkksu+yJHJ7gvj9btt/KGgzGYwRBBe1aC8MkxWA4wuLsNDxfoNAugjwKfGwOx/jUqUt48+0HMVevYG00oYCXCbvWGWdjaUFCgDKJyPfBrMVKP8FIGnAiPsilAey37OxE//J6N13+Mwim3K3cAuuZ/M+755qfHffjn8yVfrTqMwiBQikpAs+D1BqZsuBcoNDSVsIAylik0tBMzYe1IC4EQsFsfzjGKHWKvLhQSAuFQZZjnEvMtGoQjOH2A4tY3RqgO4zJ5wxR4NvQ92C0dLtizyelNTJLWOvF9vTSFmYbIZqtKp46m+OjWwNcOnMOP/wP3sLOfvbTpo6Bah+844ee/8J/+P8S/eBqiR60f6UFyTl5T9Hax4/V/vhDz//nE5945v6uofSzv/7PBEYp/4+/+xidurIKxhn6gxjC51DKSW9nWw3UohCccWjlwqdEzdEVsiRDuxbBWos0LzDVqMH3CN3+AEYbLK10UY1inFvt4tTFZUilsHeujUYgcPbqJoyx9MrD85hr1O2bvvm1lKWJXtsavXKQZh8cxdnvdprND333z/3u5UdP3HAY22PH2InbT9ELLxyxk9HjV4tT+ZRofVlb2Ewb+MqNCJqhh82xm1+7EQrQjzNUPI7EGFIl7cHAkQJ8JywhBm0VAGmc+oqI3FjHuJ/7smZoopJ7KbysPBcmo1trgcjjODjXwt65FtZGBdYHynLGKJcKjDHijEEq7W7sBPTGKTzWp0oUgQluA88lt7LSoMkI8H0P6xtd+J5Au1HBenfgpMRavWR3NamWWhukxlEdtDEw2hBAVnCO3miIYVJAeIIqYYhxkuDUxSW0G1UM0wIEg8FwjKtbI9SqkRWM4emLp6CURrtZA2ecCqWQFAq5di/B5tZVBF4ZhW4BmWUgxuH7rigy4eHilat2dWOTeuMUeenJYuXLqY2B4BzaWGhYeIKDWBkhzmyZc8Vx684ZHH3N/fbI7bfR7//uB5GmCZg11vc40lyiXfWwlsd0bm0EAFBGu/fV3rjfBL5AWkjSUmK2XYExBVShQWD49IUxXn9oBk+c74FZV8gCzgDGEOcuel4QIXMy/htS78ls96Z3wlgLra3zBWk3dkyLAtZYVISPYRyjXabuki0vGdaAyom1tRaF1IgziTOrm7h1cRbrpy9v+7wsAKU0Cc8i8nyUg2mkaWw3hmNsxAU4gQQjKrRVjDBX5+z7APz4TX7A/9bX5OzhV9cGl4joXbPV6MOjIv9JIeV0NfSUmzKAc0bgZDHKCiqU6/pnKz7qoY+oVkNvGOPqyhoZbTDOJAZJBmncLKoaeDTfqeMt99+KO3fPYM/iDNJc4ovPnYHPPesJBm1dR8o8H7WQo131cPDwXgQzu+gLXzyNT3zmSfv8uesYDUaYm2ri5PNj3PqxC3hgvsYo1WpmqjLPk5XvAvCTwPsZ8Oj/8J7+f2iH9P5HHuGPnjihj3/bq37sv37m/L8YaOS/+mPfLp547ho+/IVzGKYFarUKKqGPa6ubCHwPuxdm4AlOaZoj8D2keYGL11bRaNRQCX1wRvAFh1EK0ihU/QDVUCBXGqtbQ8R5jiwrUK1GWJydRpJJGKXQqUcoZIFRnKE/TpDmEnsW5u3CdB0+s9g3U+O75pogI9Gseb1+d/SUJnpsZZw8tjbMHvs3v/nZ5Zd8b+9/hP8tL07bc+1djeAtytj/a5Ap0tqydtWjqYpHV3sJDJjjbnGGXLlRQj0UlEnj5tmc4AkPnmDICgmt3VGujIu6sDc9pfbGRXf7bzDJwqObOip709CmFvrY0api/1wLzPOxNsyQFnoyfEJ/OIRSmrKiQFIU2zJxRoRW6KFeqaBWq1jGGFRRgAho1utU5AWCwEMhC0BrTLebdpCkdPrqCgaptOZPAjjhYOkES+UNnRF5nNuK5yEMPGwNYxRa067pNqphiEIpCMFhtAbnDPVKCN8X0AaWM+Fo5QDG44SCwLO+75E1rtvMsgzSpdmiXqvCGrdl01ojLyQGoxhrvQF64xTa+chujEWtdXlY294ix8abjEYDT0BpCw6LwzvaeO93fAsaPMeLZy+jO8ihjcJgFGO6HiHNcjDB8NFnLmGlN6ZJnhBztwmrLdAMOI7s24layHH/DgsUGV5zZxU/f3KIP3hyA82I4RXzAUAMn700hi+oNOASRrnCdD0EA7A6yiYRTMRKhd3LH05OhHbAUQ0EKqG3TWxJM4VGowY/DFAPAkS+QDPgrpM1FqNcoT9OMBxnGKbuUjE/1cZsI8SnT11Cpp3sUcCiEfpUCyOEoY9KtWIZLEajIa51h0ilBcFuJ8RPRR5bbEXdAvzeF5Z718sX/c96pkzeJH3b/ulb1lcH/5qM+eZGwEGMpDJggSdIGYtenEFrR++YbTfgVWswsGjXIyzOTWG6VcPehQ5CKFQC37bqNTAYYp6PJFV2Y2Md8WgAn4AwirB7to1hnFNvlNokV5QWBeq1CpJBDzum6mhNdeALDghmn1oe4Dd+97PQcYK9UwF+8gcfxO333arXn/y0Z6d3fnLPd/3eG/68HdKfuSA98sgj/MSJE/rT//qdr/yXv/aZjz69Mo4++G++hz75+CX617/5GVQrHuam24iCAIHno1oJAVhkuQSsoV07plHIHN1+jDQvoGSB3iBGpRJtY2kYI0w1q2iGvtVENBwliDMngJidaqNRrZYY9xzDJLWF1NQdDmGVtgd3zkHmOZ64sIzF2Q7qgmwl9O1Cp2YbVeFxWGpFHL4nEIVixePsU0Et+v1xMvrsd/30H1240QVaet/73sBPnTppT5z4WyELf/kDYZpNtBrG/2Ra6NvH0igNsF2tCHEmyXk5CIHgSJXGWGrnNyqX/cw6tEkU+pBao5AanXoFWmsoo0lbQiE1stJTRGVDZP/Ul9mRoefaNTQqIbRUaNUqMJyXI0X3q9NMIkkzaKWRFRK5VpDGbAeNWgCNMMBsuwnBuQ1DD1ZrZGlGQRiAwJDnGaLAB2ew7XoVylh8/sVLyLQGo1LybgxNgvE4mHVjKtfB2NJyIBhDKDg8wSkpJNrVijOeEuB7Hmq1Crr9AWCdAq4WRWBcWMB1Wrxk7nEGckv6AH4YIo1jJEkKL/AxGAxsoQySrMDmYIhxJm9EhWNbtegmTuXoycmjCRO/FueMGAiFtuhUfXv/kb24/bb98IxEsyLwxTPLEJ6PQDAoAzCdQ437eOL6AM9f24LPGClrbsB5XRSEXWxWcXjPTrQDiUOtHFpKLExx/NzHN3BuLUPk+3jNoQZ+7D134Ot+/JMoDBAwQiAYpDIIfY5CW/QzacvLBLGJF+tLHF6dUCDyOSKfl2sClz0kPKc69Ljb10UehyALZdxocJgUGKU5VAkGFMLDqw7P4WNPn8PVrfH2aLjmcerU66iEga3UIqRJjNXuEFtx7piPk52oqz36lqmqH3neLz253P/eRwB+4r+v6KUvoYZVnDEcmGt8Yxyn/4Jbc2cqtRpmhhqRoKlWHbt3zGDvjmns3DGDubl5zM9O21Y9olrkI+CELM0wGPRhLbdKKXQHI8gsQ81jiKIARuXo1AR8pjFKCrBqG73+GNevXIckjsQwyqWGKSRGwwTtTtPuX2hgT8tg192343/7D3+ID/7xk3j7kQZ+5sffZgZXL3rjXF17Yrxw39/9V3+08ecpSn/mkd2RI0csEfDJZy7/kxeu9Ro/8b1vyz/08RfEh55dgecRAs+DtYT+KAYowQyaGI5jXF/bQpxleIXWaFV9DJMce3dMo92MsH/fHjz+zBmkaY57Du/CxmYPkS+cggvW9nsDcAIlaY4dc1O4ttZDYBlIwLY7dVTrFRgzZ+NRAgPCapLiVbcswhiDla0BLW8N6PLKJoy1",
		"2hhrA9+z042IGqFYOLiz8+j+HezRZqU6/OCxd7ywurL1x91h/jtE9PRE/PDxY0fFJz4BHD958m+LMs8A4IMB+iaQH2SW3Sk405nUbJBJdCLf5iqDhYt9CLgL7pPGQisDj7u4j0JpyDi1jDnSGmMMldAn7qKqkWQKdR2gUArKaDLGWF2q71jJnhOCox56VPG5nW5E2DM/jUEq8ZnnLmJUaAR+UC6enQSdMwatnHoq1wqFNjfoo+XXKM/hD4aoVUJ4nBBGEVlQiZ4yYEIgV8rWQx+CMSgt4QkGWWJ+PMHIZ8JR0q2Gc2htc2LshK4gtSl3Mi6QLssLVAMPIIIyGnHi8oeiwKnVXDikJPfa5JBKYardcPBRwZCMh+BCIE4yR5RIUmTSIFf6ppwrbMeKkL0hEJnEvFprJ+RwmDIWnAHIjcWhhQYeuuMQdTotNCqRHY8lVrcSNOo1xKlEf5SjXq/AUwpXBwleuN4FL82s5iaUD7SFz0G1KMTu+SkbpauYbQhkBbDez9FL3E9WVuPpyzGSvMBDh9v4yPNbRNaJVCo+t8NcIlH25l2BtUQu2/gm6vnkZxTaWN9yEOMQzJUvbQAjNZix4MRgCBjEEgEn1Cseap6PqifQrERYH2VI8wKcgK1uH6OsKF+0Uu1jAcE4wsADMxKNSGDJ3MixpzI3CkSwxNjqKJN72vy7H9jb+e0Tl7sf/u8UJXqpjeYR+oEjR3B2ZcX7vl/8RXV2pf+7AH63SvgXlVr0o2+8Y5e9a/8C7rr/fsgsp2bk232H9qHfHWJ9o48r/ZE9ffEK6s0OIp9DKwWlDeLuGuY6VQguEA8zt3tf2I2xATauXcVGL0UYGGTK4Px6htZ0B1FUsZ12QKsbW2gvdrBzxxwSWeCx85ewe08fv/zT34l/9Us78OP/r9/DwV/5BP3odx0xH/zg2Vp7froNYAPvA1nciPP4SytI9tgxRsePm0//1Lsf+pnf+tw7plo1SXHGP3t6k85fX0GulOVEaLZa6A174Nwtuo1RCHyBZr2FPM9Q+ALaaPRGCZa3BogVhx/4lohhaX1A5y4t23GSwfc4mtUQkWCw1tpbdk7TVm+ESsChtbJbwzF2zjYcjyvPIXOn9Go3K9gx04IvOO67fR+G4xQEjrX+iLrDMTUbDRRZBs9j6sJqarZii+mGV5+t8Yem2jMPze8Q//ixf3/nZx5//tJHP/zFlT98+PjJ5yavwcePHRWfwBvM34KRnnWGQ/7bAef/j36uhGCEca5Q9zlCj6GXqm3GXT0IbD/LACJSxvHGiJzM0QCwxmC9O4TncQRCIPA5GHmohD7GeY4i05iq1yj0PctYSV/wXCdrjbFKKXDhI9EMyhAWZzu4urqFWsVAMA5PMMCyUlHF0E+z7UN6O7KBqCwwGnGeo14JSXg+iBiE8MCIIKUCI2alVuiOYhijUatWUK+EkDqFVBrWEhgx+BwwyoCIQZZsNpDdbvPKXD/kUsHCIodG4Hmo+B40XCYUJ4JkEkopMGIgYuBkXeEKPGRpBmUUZOGi6KU2KKRCnEkUL2OulWiFlyhUSv3apHfZNudOuFDaWEAb3LNvDq+/73bc/5Z34OlPfRRnTp9HGDmZcyYNhuMUTAgsr21g2O/hyatbE6o+MdzIXZoYozkB9XoV9YAh3hhhM4ww1wmxPJLYGruOwmqX5/P+j17Aqw/U8ZHnt8AZIc2l1dypvXATS2+SKEs3RbTf/Aqosmoo5QIMqxWHH5JSg2mHMCq0Qa1agSCAM4vV7gA7p1toVQMYAyznOVSRYTjU6MfFn1D8KK0giFD3Cd1hgnEubwRa3oQ/YiAkyppU2gDM/hiAj524sQZ7+cHMygJEnwBw/PhxdeLECZwo/+PRo3vCtx649+CttyzeS1Ts7/VGmG7WKEYV1fYMht2uXR8l2Hj8BXBGiKIAg+46inEXY5mgMt2BsAa+1Zjf2UG93kQmNVYyhScvbqDaJ1y9vopWowYRVPHkM2dw+x234q4HH6S1a1eRFhKra5vYu2sB0lhE1SoVuWfj5hzef/ICHt7q4ke/+yHsv/NW/Mz/9n/gVZ+5Yt74psOVc+PKjLU4h0cfIeDEX36HdOLUKQKAp8+tv+35pV5410Ij/+PHL4jzawlyreF5gqQxEB5HtRLBGA3BYdcHCdKswL4d05ibnYHHLMZJik6jistLa/i9PzqJg3sWoZSClMoWSiFJcwjBMRjF4EQ03aygO4iRlyZFrTXmOnX0hgkaFd8urffQqEXYvWMK1WoNssixf+ciKtUI61s9NCMf/eEQ3cEYWkko5WGcSkornBOA1a2+VkVoLPNsp9MKd+zc89ajnN766jv3/NhPfs/rfmd9a/wrR3/0Nz/98PGTBXAS73/kEY5HgEcfPfGVOs4zANhWqp5crNIfMdhvBGyuLHgvkehEHmRgUWhnlgUUPCIUpRNWGjfC4AQSgkGXD63SBpwU8ljC4woMEYZpBqmd+9zzPOJkIaWElMYaY8AYhwHD5jBFWlgoY0CW0KlXMc5yWAFEgSDlhBd2mGTbir+bD2vBuQvtI3cQF4V0KCGlyLnfHfZfGQ3BBSSAtNDwPIUo8CGSHEobBL5nQ98nRgSvkMiKHNKUFGr70tvuBHejS/XaxnDs2G3M5QCBRuWY2gUmEpFDK5EFMV4WIQWpDLS1zrNUehpYWfK269KEyu7WdbSdUF+OnG7umIgxaKMReh4evHUX3v7WN8ALQzz56Y/Z9fV1dOMCfq5QCSNYMCSFBi8KpFmKJ69sInNEDJooTQQ5goKyFgaEZiXA/t07MRyNaamX2dSrYPdihLAit+Pls0KhVgmxOrR4+BAhKMVxjAgjaTBhbkxGZi9lfH+pD6wTJsAaSKksZ0S+EPBCH+M0L03NLrIkjALMT9WQaYtBJrG/0cB0w6XzemSxMogndRD25j/WeX4IgE2Lctxc2gFuXAgmQZeGD3KZW9jX7GxWvvP6IPllAOLYsWPm9ttP0cwLR2jj9lP20UdP6JsL0IMPPhi98+7Wvl0LC6+qNxsPE8y9ge/tTsdxPYsThGGkr2+MwHmKdNzD1NQU6nUOpR28t+YZ7L79IG6/ZSeEF8ALIkitkWQKqdRIsxyBD3SmLFRvjMcffxr9UYIDe3eAW4WrSyvQWmPXrh7i0RC+x9CsRRbQVAkr6PVHSNOYsvHIGkP44OeXMU7HeNejr8a9C+/Gr/2nj5tGZxCEjf8/e/8dbVl2lYfi31xr7XByuDlUTt1VnaNyt0ILSYAEQtWIDPYzwQjbgMH2w6ZU2ETjxA/kZ3hgPzAgdxkQBpRAtKoldavVOVR15XhzOHnntdb8/bHPvVXdtIQEKFJrjDtGd1Xde8/ZZ+811/zmF1AmAp/6kb763XtgDn2WKIu/zQxJArC7Ror/YaGf/LPvuGtL9ti5jjzfiqngu7AM+K6DqfFR9AcB6tUyRhsVDqMkh2/SjKrlAtrdAVrdPtIsw9RYE0XfQ5ppXu/0obMMUxMjEMhPj46jUC141KwUhrYshDjVaJYL3KwUEGUaQRCjVCpg28wIgjhDr9uHI4HZ0Qqmx0cQZxad1jKqvsAdt+zH0tIqqrXqhvUJWotzufZBKDx/ZhmX2yG7jmObBcGNiq9u3jsjC75jJ6cmnogyc+RSJz7y1h/9bxc2W4kHDkoc3M9EX3NdkwRgxkvyPgnx0UFmUmNZuFKi7MncqTvIfca0sXCkQJDvzC/aOhwpIATBaEtK0tDAM99gHCkRZjmLrFkuwHOcTecCYmalJEkp2Zo8CsIahuOoYXEzSDKDbhDBdfJpb6IN7DD6c2OfdqUkJSTcITU71RmsNVx2HUyMNFDwCwTO1fDGGLZscxPYQgHWaLhSQkiF1U4fS50+JDFqlRJ50oEUhKV2NzfvHUKYuEpjlfuzXRHVuiQ2bTIMeDOG4qUDPLWZQXWloIjc2gfW8jD640X5PbwRzDckjNDVWq6NzXKDCQgAU/UKvuneO3DTjXvQ6oXodDp8+fISotRg",
		"vd3HSMVDpVxCP8qQxBF02MPj51fQiXWekZWH10IQwRV54dWWUXAV9mydxI07t+L82VPMVmPn1Cheua+K//6xk/TpCwOUCwpJaqCUi1fsreG//dgBvPlHH+LznZd4yeXvnYlyRiaBwURk+K+eAR0B1F0JTxG7jiLfdfM549DwVgqB2YkxxKnGIEoxUiti98wYHjt2DntmxzFar+JTT55Aqz/AqVZ/Q5S90fLAFwLjpRLGGhWMlCTmWx0+ttgfXlvAIbH533aorGsWPTta9mRm7Mr0WOO1Dx67fPalr/umCZR+8Du//brdW8dvTZLsFVLQ7eMzUzuLhUJVSIm15SVEg77pBKmuFH34jlBMCrAGUjnwqw0YyxgEEXzfwfEXTmNyZhb9IML8yjq2zUygWq1gbmENhgTSOEbQ66K9vg4IgUFsce7yAnrdLjJtMAhj1KpllAseFQs+HNdFs1ZGu93B7l07MD1ax8raGiSYKyUfq2ttnD9+Cj/5L96FA7sdcNwzCxfXnKdOtf/gf/z58o988LHjS1eTxj6fHKUvpCCZbQ3vt8NMfNdbrhtJn1uIZCZcgpTw/AIcRyLLMiRphvGROmrlAlzXhdYaUZwgjhN0ewHmV1rYOjOOSrGAMI5ZZwZGCLiShlk1eQ6NpySizFCSagYsCSFQK/lMghDFeeRzueBDM8NzXBCBBCxKruI4ye3/M5PHk9+5fwuyNEW55ENKQhYn2LN9GuM1hUoht3Q31mB5aQ2DSENnFgtrPV5c6xupHDE90XTqvgu/WFhTvvdnpUr5/S+09EM/cPjXw43r+MADB8XnSF78amTcAYCcLKg/zyzfK5VIMsPSWouaJxEZpsQAmckV956j0I6yTdiCNww0Re754wgiV0l2laTh8J+1sejGGblKDrOAFJQUrGROfLi6vFnmzegC33XRD6LhDMXQS3nrSgguuS4AptxZWiDOUqTWwFhmScNoasehZqMOV0pYWAyCCAywlJKyNAEbw7MTo1hqdXBprYsgjkkJgpQK1WIRjhLw3Bwe6gYRekGUz5NeYj/jkIAaikZ5yMoTIGRXEQJoMyNow+0i77p8R4FASLTe5L9r5k324MvCHhthfRtMxuGLmR2p4hX7d+EVd9yMSkHi+dMXOBoE0NaiH5s8eymMUS/7qJRc9LtddLt9PHxqEWthOnwPfDX+RLlbd/4nUyNl3Hb9HlQlY2lpgcM0w0yjjLEy8LuPLVAn1HBlbp/k+0Xctq2IP37fN+A7fvJD/MePLkIK4OoGd2NsREPOPV+VlPtiph0w4iv4DqFSKgJDt3ESEtZaKCmwZXwMSWYRJRmY8tyoKIxQLnrIkhTPnZvDydUeYnM1p3MYik5A0/cwUa9ivObh0nqbz64Gmx2rI/JOcaMqCTCUABcd0lFi/CDDAynwbf/q3W8Ye8WrbtvtKXGna7PXSkdd311f3xkGobfB+PR9R3uuY6QAayYRBAkVqnUqVevUDxNYFmgNEpBQkIKwvLSMTqcNaVOESYYozlAqFbC03sPszDhGGzWstPogtlhaWITONGrVCmShjOX1HpZX1+FIApFAY2yMojjBequNctFDwfdQKpewuLgCbS18JVAtOLx1oolBf4C19S7YWLz1VVvx2lsaWD5xgl//7q/nTpg5KxfmT5174fLvP3xu8Ik3vOeHH339698zYGaiqxDkv1FByl0ZYD/4U2/Z9R/+4MlP7pypT1TB5pNneqSlC+E45BcKKBUK6AUBur0Bdm2fgdEaruMgDCN0+wOABAqui7VWB1IJTIw2sbK2zv0oxZ5d2xEHATB0CfZ9hTCMkZpclySIIJWENXnhCOMEJd+DMRYQBEdKmhwbRRSFeahcboTJnuui5LvohxFa7R4KQ/uPmYkmwijFLdfNoFryUJBEs1M17Ng6xSdOzeHs+Tm84ra9cPwSkjTj+Qvz3A8zbq2tOQ5p2rJ1Gv1YH2s2a3920w17PzDy1n/xyCZy/8BB+fFjK3Tv4aPmZS42f9V1SZ68TwN/5ijBaWaFYYYjiUgIgCQSkzO9qgUHUkqsDeJN+59NO//hkyuIyHMUXClYCYLvulgbhBSmGiOVEgqOhDWGlZLQQ9eAbOi2sOFllgyjCVJ9JU9oY0+UglBwHHiOw1IISnOyQN5ZGIMh5w6SBDd9h8ZG6tCWUa+UoZTKE1rDCK7rwFoDKYi3jI+gFwQ4cXkF64Mgt0FnGpqsetg+OZ7LDwYBUm0wSLM8PmL4wuRVseKWGUrkEfKwjHQY9bAR7Z2bjW5eK8ihj5k2llOz0YHlmzK/pBu9gt7RMD8oh48AYHasgduv24G7btyH6w5cj/nFVbzwwgtor7VYyHzTTocWSYoI1bKPJBig0x/gkZPzWA+T/HVhg7G3MfPPJ1MWgK8kbrluB27aMYvuyjyvt7sgpbBnoozzy2186PgqBBExMxwB1Ko1vHJHFf/+h3bhNz54Ab/8gQvsSEJmru7sruIx5GxB2iBovHQTq3sKBUfC9yQKjsyvlJT59zKjVCig5BcAtjnTseBBG42FlTVkWYL5ToTV6MU2ZVeviqNotFLGttESezKlR861EJncu49NDqte/cBPNOu4aecE33rdDly3fRI7Z8afEeXGVMV3p6dnxgC2GMQa/SC2ly8t6sGgi+boKCVhQFJIKtVHsbC4CJNEKJVKaLW6WF5dg7bAjp07sby0jOW1FtZW1lAs+jBaI06y3IbFMtr9ELVqGS7lhsKdfgACo14p03o3YBISaZoiTjOUiz7COKNelKBaKaPguyi4Cr7nwVUKYRxzdxCgWfIAtjCZxnizBiWAoNdDUQe4ezpDMghw05vu5dd83avt4IVPuO7ENP70Dx9FsVR5YfuNe3/uwPf+9v/kKxa2/DeZIdHx46D/9v23O//8tz79G4Yw+X993bh+8PEFko7E5GgFF1cD9sFI4hBFV8EfbdBgMABIotMbYM/2rfmpBATPczE20oDvO1hrdZBkBjMTo+As4yTJkzUHBCrETv5gCQHXcaCEyFM3kav+lRAYhAF8z4NODSJtEEcRtMmdgdnmNp/lYg69WGa4SnDGCu1Ioz+3jjBO6dJqH83mCFzXRaMewrPnaOtYFTu2bOM4A6ywGG1UqO5tpThOsb7mm14vMLFmCjUf8OPswJmLSz/+6V/5R3+51mr/r9r4zIN0/38+tzFDMD/9OnXk+FE+eOSrMt7CABArifnL8aLziSSzb7CMhABpDMMVQGYMsiw3BO1EGSarCjVfoRtrKEGwdEWUKWU++E0yjUwDrpBgC/hKcZxZtAchJU6u0BcpDRly+cwws/nmaixwtZ/dBhwlBbEjFbkyJ04IKSlM06FA0sIysxn6rhR9jz0lyVoLow2k48CSQJSkiMIwj0ZPUxR8Fzw0jRUgeFJCSYU4zeDnUCQbY2hhbX0ztbVRq2HSVYiSDOu9LoIoGZqY8iaUp4hAfCXBbRiKmBfv4WRmw5HaGMvWcg4hDenFdhgv/yI/wOGpfKMbMpzD3pP1Km7aswWvvftmzMxMQ1uLRx9/CmfPzSHOMjiCgCxBahi+o6CNQZymgIlxebmFY/Mt9OM0/yyvxhFx5T0xgQWIpmolTDZqiMIAcZICQkANGYQLvXSz3cgzjvLDQyfMcP7EPEZLtNmKEL3ojQ2hSN6krr9csdg4/WTWIgo13EoRriMglMQgSsEWEMogMxF8JaEEIRhoZDrFen+AQWKok1qWcmPveMkmmM/IODMacaZx/VQZj55dRZZzKFgQMDZSx+7ZMdy4awtu2DWL/dunMN6skusphGGEKDG393pdLF5s67nLl+wg1giCkOC4VK7UJZNEtxfBUS5YKMwvrWBttY1BawWz27ZiECeIwgCCBM6eOY1Ou48oydAL4zwEkgR6CWNypAbLQMoSvTCFyRLoNEGcWVJSYn61y5YE4jRGHKfwHBedIIGQAqPNGtbbXSyvJnCVRLnkY2ZqAtYCtXIZiiwUCWQgVMpFJEmCNNMUJIxPX7R8",
		"6/U78dATCxQVLogdY7uzpvHtG7/t3eK5D7z/+iLS31n8zPtuO3LnD/0EH7kf773/CL/cXOlzdkiH7rlHHT56VP/E19/wD5a68W9WizK774ZRcXE9xbm5PhYCorVEsOe7yFKNerWMTn9AJCSEknjq+ZO49frdUErluLjNmUK+72O11UaxUGAlBdjmQ+xWp4cky2OVrdZUKhUhiBDFyWasgAXDWgvfc/Mk2DghKSWMsdA624iZhhkOxY0xYM4V6nneTA6BKCngOU5+yhZ5Rk+WJJgdbWDXVAPjtSI3m2U0ig6iOMYtN+9DvVpGxWWQ56MdaTu/3LFxnImwteSYJMToSGNlenbi6OnT8//j3b/whx8DkAAAHzwosX+F3puz9L6aUmkFADviyTcmhj+UWWZJEK4gcpQgR0rEQwZYkg+7uVpw0I6yjWA1pg3HhiHTDQCszedOOXUYiPNkYCJiSCGGWUx2U5TPV21PUgqIPB4h7ypE/v9qOC9iZkgpESQR0jSDZbtp1FryXNRLRU6HwY2Vgk+VSjWHXuxwM7YWSklUyyXOrWMYFd/D2fllLPcChKkhQXlHkHvQMXReTTBSq6JZqyLJUkSDAQQRlrp9JJl5USz85okfV6em0uYAn4d6IQLzRkG34CFZRBAxkOHK8H/T/JUEykUPU80qrts6hUa1hK3bZrFlxxY8/8wLWFnrIEpS9IOhrdLQrUFJhUwbXm21UfEkWp0BnVlqc2IslBBIrdn0lKOr4NiN0rSlWaY7rt+NctHDC2fOsa8I9YIHSYBLGT56Yg29JL9uGFoL7Z0Zx0yjjDfsyZBJiX/9/rNXOqRhV0l8RXG6wRN8OWNeMIYMUElRpjFR9lEu+ZxZRj+MkWQGY40aHKkAa1FxFWAyrPQDdMII67GljAlqWNWJaJMYYq3d/H1FKbhZ8rBvwqd1LmBiZitu3D2D67dPYbzqouI5LKVCGITQUGBBsDoDhAM22gpJlGpLYT+AHGY1JUGfnFIRvutgcX4Jy2ttbtQrFEUJLlxeRK/bY8OELDPwPQf9OIWFgOPmYl8SArFmBEEee14rl5BmBv0gwiAMICRBa5OzGOMEUuTwMaREdxDkYYa+R5VSAcpxEMcJwijONYWS4DkOB1ECx3HRLHuo+gpaG0w0qyh5Cs+duUzH5tbx5uuncf83vAoffvQkW8O4564bcdPN+3BysY3dY2zFwmfs/jd/s3fu3Nr/fcO7fuHn+YEHJN1/v/m8C9KGEPbfffcrZu7aN/Pohx8+PVWixN60rUaXVwZ45lwffVmm1ClCug63253cYNP1aNf2LZi7vID1Xh+VUgn9fgBjNJTjIEk1Mp0XJVdJZhCEFJzFEYIwQmYtkkyjPwjgKAFXOaQzDddR+XDbMpTKh7w8FCmSELDWwhgLYoYdalMyk8MkYoiriyEZyXed3LHZdRBECRi5W4SShILnolTwIYTgQsFDP9a4accEyiUfhUIR28ZrIBjcdeM2NCfGEKfE4xMl21u7zJ3VdWd8fEysr7asYDyjDX4nGIR/ePt7fuviiw5zDzwgj+AIDt7/VeGpJwDYuqceiDJzMLWcFKRQniKq+g66UQYSubgy1YYVEfmu4lLBwUI7lJyfITQA6Yj8ibfDE7yS+XzHDucmgkDa5HS9jUE5ONeRbFDJN4Ld5PAEro2F4ziww1lSlgtwYS1vdEfDrB1Cs1xkR+YOEqnWAAPjjRoVPG/z3tDGouAqgIg910G3P0CjWkGaZTg7v4xunA3ZVgwlCCr3hRtmCAk4UsJYg23T46gWC8jSFL0wRKcfoh0mm3CefYlRrCC68kDm8B1vdgUADOed2gZpQV9Fiii6HraMj2Dr5AjGR8pwXAcT42PoD0L0+yH8god2q4f13iDXbBEh1RpFV0LrLKd2I79e8+s9LLYHIIDlUOycWQvNV7HJrnJcLxdc3LxtAjft3UFZEvFqqw22BtZoJIMeuonFZ+YCKCWITT6nKvkOZhpVTI9WgLiFm6d8/MkLPRxfDFhcReoY6shYYshCZEvmZSycGKCCEqgMPeoaJQ+VgofUWA7jFGAmIQWmRpooeIrDIMBiq4+VQYI7t9Ux147pXDt6WV42EaHouxivlbF/dhR7tk1g3/YpzE6Po1ypQTkOrHSwtLSIfpQhtcy+V4Dnuhhp1hB1W2jMbEcShTR/6RIcpdBZa8EYzd3uAJWiR47nYXmthfVWB9bmY4o4TsCUSx2COGE7nK0b5BqrTreHRBsUfA+ZNpykKeIkpUGcQAoJbTTscC65ARk7G4c4CFi2EEpieFAk18lZiFIKJGmGTBs2linONHvDQ7wxhgquRMFRnBlGwZM0Wq9BSgdbJ5q49459eObYSWSWecvUCKSQSFOLt755L7ZNFyz1T8LdcrM+M6/vu/Xr/+2nXo7oQJ9FiJKj0Pyg+sOf/KXf/YNPnb3/8Rfm0l/9obulIIML8z38wZMdnFkLsWPrLOr1GrqDEOtrqyj6Lpq1GvX6ARzX5SzTtLzehu+6uW+UMfnDyIw005zlxpRccHP7IIPcvn8Qxvlgki0EiRw2YCZtclaUNgbR0LfMDu1RQIAdYuF2aKypaMOWBEN67RV/DkbuKqBkXuA2KLmucvLj+jAew5ES1aKHarkM33XQCyPsmBlDqVRAtVTCbQe2cIEDdNdb7PmO7UcJPMHezFgVbPSaEf6DltyPErmffPU/+dXTuEokt+Gpd/DYfn4vgK9AUoQAwBMl50A30p8yQDGfhZCo+w6iVKPgOTCcY9dGaxgmfu3eMTq11Fk914orAiiCSEsiC7DE8AERBDgiz4gU+eCJLPOLnFhz2raAkLkJp7E5G6vo5cLYVOfu22CmJEtz0aq9ggQIIpQ9F0IQKylICeJ+mCA1BtoypusVjNZrpFwHbCyyLMtp2ch3/MxYGKtR8l1kmcZaP8JKd0DaXiUJJYIrxaYux5USBdeBlAKzU+No1CvotLsIkxRhkqIXRrlmRhDiNDdmzYy5mjkH4KqB/lXeM0oIeK5DRVehWSthy2QTI5USpkbrcCTh3PwaprdsQRzGWO/k4ZX9QQjfVcOhXn748j0HSRIjCgKw1Vht9TDfDrgfp+QpmRfE4eeUDa/VS0E7KQk3b5/BzXt3AHGAMOwhMwZsDXSWIAhC+vTlgKOMSci8tDokUFAKe7dNIEsT1FUKRzKKHuHZ+YjPrMWbkOTmTG3j9w4Pm1d73W78lSMIVVcO04IJpdx6CY4S0FlGvutAKQUigfnVDneCBCQI9+4dw7G5Np3vZZgarWG8XsH4+Ai2jI9gemoUMxUfDZdRKTowWQYtJMIkQ7c7QDgIUKxUURkdBbsF1EZGUSx4YG04jROkvQ4uX74EKzwKe10sr6xDuS4q9ToGgzBnHXd6KPg+pMjJKlmaod0PEMYZGrUyhJDcixIMwiifmw9jTIQQSOMIUZwwhGRjDGtjQEJwkmYwQ5uuRBsyxlLuJJFfN0EER+bknCHcSwANUQ2g4DlwleJ0KLwmMISUyLShNMvgO4oLhQI8RbR9agKvuvUARpsVZHGM1fV1VMs+T42PIkkzFCVw69YYu+69Fyvnjun4/Ke9yq33/NbkK//DP+QHDkr6PAoSHTp0iMqDhws7ipXfevDRM/f/2kefTf7lO+9QP3jfDD7x1EV84ngPj85rCM/Hji0zmJmdRaFUwnNPPQmrE4w0arhweQndIMxjqpOU4jTbjP1N0hQ6t/HnNNNDJ2eG5yhOMwMpZR7dqw2iJLVKEAPMikiQAGXGkrFMdvMUlUddb+wRLz1BXX304WFBelHQG8DDDRGSiJQUrISAI/MhecGTQ+afCyEEE4EKxSKEdNGoleEriRt2TcFhDVjD5YJDrX5onz97iWdqrnvvHXswMz2F0anJQS8IT7TX2p/u9/sf+sAHP/Hp3/z0XOuvwuEsPv7e94p7Dxzgr5BOSgHQJUmHhRA/rZnTWFtVUMPr4ggUXRfaGM4yDddzWbBVIH58caB/WjD/iGF+",
		"6/BjyMAQoA07GxpSxCVt/LflvCyJYReVGDucWuTzQ2fYWUVpHozHABQJyobzwo3Nu+AoNIoFNGoVKKW4NwiQpAniVKMXJ9CWUXIdbB1pQLkONFt4Kk+gDcIBkkSjXCzCWotqyYc1BhqE80tr6IbxX71IgqBIwHMkuSoPVAOAarUEz3VQq5RBQuDi3BJecfM+VIoukixDtzfAyloLQjqIM40wTnOXcElcVE5+uBICO7ZMQ9gMBdehctHFTTddB0dJzM0vY2G1j4KrcGF+CalmKKnQH0SQUkIIwZ4jMCSLkLUWAgyrNXq9Ltb7IZZ7EafaUH6i3nyu2AznW2ZINx/qUyEE8a6JGt7yytswMTWB5555DlHYhzEGjiKUpMGp5QF95mJ3aFl0xU2iUS5hz8wouoMBylKjnxn0wxjf+cpt+KUPn+VhXDsNZ26sh4dNOXyaDdsN94nN04sgYKzkgdlymhkUXQkpCPWyB99VpDVjtRtgtZ8xKYltkyPYs2MWt+3fhWpR0Vi9iK3TYyi6CuVqFcYwEsNYXVmDYZtT+zMLv1SDTmMISVBKIewPIKVEpdmANRZLS2tYXVpBt9dHt9NDpVTE5fkldAcBQAJeoQgLRhAmyLSBGfpBUs4MZG0ZURxDW0YvTBAlGaJUQxuNguewJLIbozQCyFOC0iyTzBBJZpDZnGChDV/FtByGVXHuhZ4f8vJnTyGX2AgCpFIo+h5cKXJxORFKvpsf2KWicqmIWqWI5aVlDhMNJYh2bZvCjtkpsGVsnx2DAHD9DTfwdbtHsX72FNyiBxsuQep1jN5wp/nIb/53Z/d19Y/d+WOP3mfzAEv+nAVpw0D19/712w998rG593708bOhdYT7Oz/1DXT0Lz6NT50aoDIygufnu2iOjA6V2WW01lvodLuI0xRT4yO5BYphtNpdSKkoTmO4jju0aWEQCegsQ5JlbJihtbkylLUWJt+TzPCE7gwFeIaZMwZkPp24EhrNf/1MjId2W8QMVDwXlaIPQeC1QYgw1VcG5cOfp4jYUwK+lPCc3CtrY5bhOYJ814VyHBSLRVTLJeycHMFUs4ixkkTZIUzfcDMWA+CDH/m4NVHAO7eMOrftmqAt0xNoNCtIk/Bsr93/tON4D168dOGFxdX5ld94/6dXPtNC76Uv/sFDh9THDx+2h69Ekn+paeA0Bfg9KT5lmG/OLGspSJRchUxrKKk2DTCDzLBhZkcKJYl+OdTmJ1wh35JZ+8MWuBfM/saeR3mS9dCtIH/SBBFvEAUkgRJjeHPWQlfMVi1zznrDlQh1JQhFz0Gj4GNipIn1Xg9CKmRac5xq1kZTmmaItIYZdtaTlTIKvgcSAgXfh7UG1pghfW/YRVMOA4dJipVOH50wvjpE8Gr/OAgCeY6EErmzth2ScTxHDXOiLG7ftxNjow24UmKsWYPvuSiXCgiCPFzv8vwSWp0eZqfGwWw5DEPUalUEQYhWq4vGaIMinReLIIgRximSJEU/GCBN0pw1GKZcrZQQJyl8R6BeKUFrQ8ZopGmCTq+PuVYfvTiDIrASglJjhz56eRAjc/56+SoaH4EwXvFx+75tvHWyiX6nh14QoTvoo150ALYoeRIfOrZCvTjLTVGvYJS0Y2oc06M1rC4voeIrrPRDXG4n+Nl37MHREy189OQ6lLjifGCHKlnKiyNZzovjRj2ifKHuSS57EmmSQmcWmQYsAaWyS7VKGWNjTeyZHeNX3bwTe3ftQnN0FFEQYDDoU5bEsADiIXmgOjoOcssgr5BDsa4HqSR0nKDfWUVrdR1usYT5y0torSyi048QRCksM4JEIwpCMAHlUhFaawRRjCi3JEIviJHEcd5lKpXHdRhGlmW8IaZO0gxxqjfCCwmAyJGfXIS+2TETtCOoo4h6DHQ1sASiM2C6bMguKKKe66gBWO7IsvRXrWXPgNkMYzsU5R6C1VIB5WIBrhIo+C6SRFMYJ+w5ClIKyjID11VwHIcn6wU4QmD31nEYlqSFQsH3MVEvYmxiAtVak0XaRbxyFtffciNcDiBMgEbDtSeeP+XYwdLT5h/86Ctfv+P74pc6WNDLzZQO3bPN86fHHn1+LrnhTx87nb3ppmn1dQdGEWmN+Q5wsRXj8bOrmJqapEqlzOtr6zA2yxlOSuHSwiqU40AIiXa3B2M0KaUQJwk2IDcMoTmdQxUv4s5IgEmQZcsuBIUC9ByARDNfB2CcmTOR715kcWWgKwVICAElchhuQ6U/zN9hApDpBJm2EEJQvVRAtehzpjMsdXPaLrSB4dxDDABrm2tHLMCOIBRdRSVXwRVE/pCe7BaKAAmM1qoYq/ioSoNX7hmjyf03QkzuwtLCCpNOEPZaXJTW3nj9Np5bbFOrF7lJvwNEPcyOluLa5FR/bMfeVQP3dNxfPVuS6cUw6j/33Gr7M9/9E/8zuPrA8OWigVdc+Vat7QctI8vRUCJHEUwea05KCETasJACVU/ZMDVOL85+lYF/CsAKIb6touh/htpyNiQ75CMY3gyf2JDJ00YazSblOIdih10QvZRxVXQdjNdKqJYKKBWLUMrFaqeL+eVVzunngnPyiyE9VNUzA1XPw0ilBKUkvI2UTpmbbUZxnHfrWYaRehkrnT7agwhpliHO7It9BK545+Veo0PyjOs4cKXMnSbACJIUnpIoFzyUi0UIIbF9dgrbZybhOLlLSRLHCKMod1wOI/SDiGEthJQgqaAzTf04giCZZ0AFIawxcJSCchz4vp/TxZMUYZahXvRg0gTdIMB6d0CdIEakr5AV1JAgok0ewuiqPBpGG8uJtZuUcwYwWS9hx3gdY80ap1EATwpEST4MH614yNIMZ9cjnFwNyZG5iNcM4QtfStq9ZRLNegXzc5fRLLo4vz7Aeqjx/a+Zwr7xAn78D87lPmx2CL8PXRGweR9c6ZBeKpQtEFAve9gy0cS2mRGaGath58woJqoeSn4BZrDOkgzS4gxSVcqd56WkysgYKpUKsjRn6yZRCOFXACGRhgHYZFicW0S33UOWRJhbbiHVBkmmsbC8BiKBMEkhHQWyDJIK2RUkCGEUQgytrrIshU51Tj6IUwxSg/Ql4I64YpvCBGhHoC9AcxA0p4S84LhyXgp5yfXFBadQXJwqOb0733hD8Gu/9tHE2r9K6r1969Rt8532R3th2kwsG8tXnp+NztVRAtWij0bJg+vkkLOjJC23eogSzbVyAaP1Eu68fgeqlSJslqFRLVEvzlAq+DBpilqjidrIGM/PzcHVPdywpYKRMsMtKjRqJaviZWepFR5738cKd/36n/5p+PkUJP7Ft++rHHlq+fG5bran1Y/1z33HraIqNP7imRV4lRqeudSClh5GR5pUKBRw6uw5TpIEO2Ynsd4doNsPIaUED+N34yShOElyGu6QlnoVBL9pAylok23ESpKSQjxTcP33rAfBJxlAs+lP68j+5CBOv58At+QoSKXIdRSUlPAcB56jIEhCCmw6/rpKsefkAzytMxQ8B/0gRhDncypjTK5k1wxjNSwbBFGCMNXoRilHeS7LpvRDEqHsSipKIinzgT4JiVLBR8Vz4UjC9VN1uuOWPQgTjR2TVdTqdR4brSEJehj0uxwnKVKh7OTem3lkYoZqZU+srvVUt9PH/EoH8xfPwUcMWIPtW6ePN+vef3/gTx78f//LHz/T+XxVz1+souRL+lVi/LAQIkmMUYIInhTEQ0Fioi3PjtWQpCnW+rEhItdaPpVo84sV1+1NleUDF7qJjY2lq92pNy6yuGpEwAwecgaGlO8XaW5IEFBwHYzVqyi6Cq7rIso0Cp6HKEo4zTJESZJTkYmQphlifYX1hqHSfrxahufmcShCCgghAM7vFyEFBBijtRLW+iEWW10wA/0ogTt08dbakGG+4lp+NSRMtOH+DQFClKUQJDBWq+Q31HC+6Xn+0G2cIJVAHCVDQgMPnw8BqSR5jkSSpJACiIbaEZ1paGuHG4lErVZHEoUcBCEibZBlGbqDAVqDELHOFVmu",
		"FHCEGDYaTCRog26+SbsnIsT6Sqz3eLmIPTNNNKtl6CThOEtRdB0IWBBrWGOw2Inw7GJ/o4shZvBw7ojRcgkjtTI8V1ISBfCE5bOtmIIow2yJ8eP3juFn/3INS2GeHsuCXjpbexHiMVYpYWykivGRBg7snMSWiVHMTI5g61SDypUyVpeX0e0G6PQiuOUK/GIZzMSVxggEct1juV6hLMnQWV8FEbA0v4But49eEGF1vQttLFZbPWRJCm8Yb5Fr4lIkSQY7JM+wVOiHUX6PWsYgiobs37zwi+E9nGYGUWZADLhKwvUVamUPtbIH33VQcBxYwxzFGarlQhZEyWqvH57JMvNkBnOeGS1BvG4FLXR6QSeNkAjAqCZ0qwXbaECaNmQKlBzXvTFj83Xa2IPEPDm8nchc9cxdfXklASXXQcFVGGtWqVwooFGvYK3V4ShK8PWvvwsj9SqttnsY9Acgq1FwBLTOMFpx4boepFdGEMf8/POn8Jo7dyJsreHOW7biyWcumNfsVu7jJ1of/idHzr1tONLkz6VDYgAU3noymPsL99JSmO6dqRVsRZF45NgK2rGFyfqIMguT5Q/5equFTn9AaWY4SjWSNAMRIc1SJGkGJXMqbpzlwVsvp7Te+BNf5S7fqbbKc9SRX//Jd3znu3/mf6cO8y4h5a3JwLzdlXTvWKXoFD2PXEfm1vyOA993AWuQJLlTRKmQOzqDLWAtygUXUkhYyqmcaZJTfIUgwBoUHAIbg2a1gFrZg1ICQhLOXl5FCol2L6RBmGK1F/GF5Q4tDxJ0Ny6iFHCFxSDJMHAV6kUPT15IsNQb4M7do1ydYrLdDkIj4FCKLQ0HU9umUd56i+gXDmB5bon++A8+ws+eOKdnt0xzsznKlcYYPAVkcULWre0fG6v/+/d83zu+403f+Kbv+sb7/8PzzIfEl8GyyAIQseEfLztiPzNez4zEMquIDbtSUGYsEmPRj1IESYpEs6wWnNSVYi+A37TWrrcibQ0zqWGWzkah2TidWGxyCq4w0l700FCuefNcTjJDE80qquVibmyZZIiTFGGYQyI57T+ngqdptpnhtFn8GLCwCJIEnufkJqqaUSoWN7/XGAMNYLU7wEitCmMMllo9VoJIm9wXzncEEqMRanNlMx+WJ8uMKNPIjIHaELuyzWdTxQJAhCTL4zMGYQhBuRuF6ypYJkAIhrXQVoMJPBj04TsOKc+F6+bicyYCsQUcB2HQx/raGsNaDOIU7ThDNITEr56rblxzKfLpnWGbDyYEDYuSgC8EjARSYzBeLuCOfVtw98378PyJs9xPAN9xwAC6QQQJg26U4thSiMzysJ8CCwgIkWdZ1StF1CsFdLptVAsKg0GIbpiiXvYhK0UM/AreeHcZj19MQFmCueUOHN9Hs1ZBvVLCSLWI8WYVk80q7Zqd4OnRJkyWYGJqDKurXYRxBLDB+blVXl45TZOzM3DLk9i6YwKVShVsUmadIGqvYv7SZQSDPtLMoN3tY63dR7HggyEQxCnanR7ml9ZBUqFQKubss05vqBtjGJPvaTkkmVtcZTp3zE60zWfg2iCzV05zNV9i22gB73jNLozXyyDlgATBcVx0BykW1vpodWMEsaHiqMMgOEvGzhZH6lsyrV+faA0IhUEYQlu2IzU31iUTMSEmIcLJLTIxhlUsMjezqEaZHlVQuXCAoaUQ5Ll5xx7EKWKtc62ftrBsyVhGL8kQZoalCnKJhpIo+j7SzOD85SUsrbR5fq1No7US0jSDJwi+KxGGMdq9AKkBb58aQ2wY5y+1EHb7uG52Fd/42i3sRKuYmBy5CJxj3L/ppvU5SQ0SgNnXKH7dqXb4Z7dvbdi7pip0cqVPfrmAk8shgkSjWK6Q6yjwkKTADFZS5CfUJEWr24OxFkmSwlhDV061ArhKY/Iiyxciy8xSCHrM85yfy7R5hSRxn+c42wqeM+o5CpVCAQXPsWmmoZSC7zmolAuIowRGZ6iWSyh6DtI0hSVGo+ghS1Puhwna/RC7phoouQquEnAdhZIH7N0ygiIZOK4D6QiMNKqo1yqo1ErwqzVIMGeGEPQ66HQiPnt+kZ49fp4feuYCnlkJsRykmwd9VxAqjkSt6AIk6K7dI4BOec/WEbzh1ils215FEIaYuflOfOxTq/zYkxdptFlDqDWkUti2dSvW2x20220sLS7BGAakslunx83r79ju33bzlvlnnzvz9lf9g//85IYL+5eDBj5Zxlg7FH9u2N5MQCpIyCzXFxEzs+tIaMOItUHBUSi4ji34Lkqe6wgim6QpMsto9QNk2uZQhrEvssTZcP/2HIWy77LjKBQcF1IwpsdGsdaPcHlpDc1qCVrnHUKa6ZwcwXYzhI6NRaI1kiGTzb4kwUAMnSDGqyUUfQ/a5O7cmdY53GQMlJPrLypFH6P1Ci4trWGl2x92Dzl11pESTIRMD+cmQzjMlRKpyQuhGG74AGO0VEK14CHJTG4HpPM55obGzmgL6ThwXZd1loLYQjlunnLLTEIIFoJgraWcYWqQpCmMMRwmGQaxRqzNJu39xbNW3oyT36DRG2aYYcIuhoasAgQSwP6tY9g1OYKRZg2tTh/nF1e4XCzAIcDoXIAZRCnOtGK0wgxX/QgQAN9RPFL0aGZ8FAWXsDC3iJInePeuadx9937cuW8W9ZE6bdu9C54DpJmBsQlWV7tYvDCHMGRAuBj0o+F7tHCUg9VuhNhaVlKhE6RoNmoYrZVAJkN9cgZjk1OENEKWZZi/fBlryysc9Nt44fhpGFYYxCk6YUrlSgk8NAyOojgnkoCgswyZzotOLwiR5po5xHqYkbVxwLAW8TDd1+QtIYQQqJULKPkOpqs+CoIhjYbyXChXolooIErywMAgzpBqguPlBT6IYoAtF12FkUYdzXqZXVchSRKOwoTOXl7B6EhNNBtV0RsEaFTKQ9s1wnpngG4Y507sgE4yY31XCUGSfM9FEMcA5Y627cFgSOm2SK2lXhCiH8asjYUvBUaqRfIkQQjJjuPkmjuAjLEYq1dQKhag0xT1ahFpFGFprQPluBivl3lypIYtkzUMen3salr+hldN6tbCnK8r4z9z+4995NCDh+5Rrz98VH8+OqSNuJN/dteW+n8a91RWLLkUWKInLrShrcXo2BjpLEOa5aQpBrPW+XyoNwgxiOMXcfnlkEUlh+JIbUyOr/KVRM+N4LeCq4LM2oorJeq1CgqeA0c5ulouMhsjgjCiTj9A0fcwOVqH7ygkWYZSoYBGuYhBGMJxJMq+y2mSIk0SdMIYShKqXh5+Zgxw5w3bsHe2in6UIEoZ7UGCxfUBms0ahGQMjMCrX3U76gUXrquYkwCaFMZpANPrIw4iPPXsCX787BL+8tgiP7sYUgoIBQHPydXtE1UfkixVij5mG1VcP+3ztokaTq8ahLIJuA5GGg0cuH4HPvqxj+PJ509htdUDg3NqbqoBy/B9DzPjTX3fnTu8W3c0n6zvuPHV937f4QQv0/Z+qYpS1fN2RTo9ypZnPCHSjKEya1kS5Z2AICSZyRlSQ8p9yfe44DjC8zys9wawzBitlvMIcGtBIqf4e54LozUcJVArF2Essx0+6MZYuI6CZsKpS4tD9l3OqnIcBUdKRHG88TMpM2YjzntIFLvKb4ABTykQgEaliMlmPXeeT1OQEEjTFI5SiNMUYugEMVIrQ0iBY+cuoxdnMBvO10JQyfdBlM+crMn1Oxsw9UaAn7jK4sdRctNOyFESYGbXdTcIHkS53ooVWTCbjU6PjLHMnCcbZcYgTFKk2lJqmY35q24D8kpB2nTqzqFCkbuBD10SrL1i7pIZg1qxgNt2TeLGnZMouAqPH7+ATpjAcO4J6DkSxBYONM6sBrjUiYffTi+a8VV9F7Wih+nRBlbXWnjlrVvxw992D8aKimEynDx1Ge2QISpjRMJFuVxGqejguuum0CwxFi7OYXGlj243glOqoTfI0O6niA1hpFlBuT4Ct1RD2u9yo15Gv7WMQa8Hli59",
		"4tHnEIcBgjDhKI6w1uqhlxhMjNQRJymlaYok0wjCFHGWgoezP2JAibzLziPDDTIGHJUTnHwpUPEV2v0IlgQSAxSKeWRJvehj1+wYTJpix+wI6iUfQhD6cYpqrYp2e4AgSnKdnUDOuAMwiDWYgUGYIk1irpVcGMO4vLwOIRVVywX0+gOsdSNOdIa9O2YhhUCl4GOp1bHzqx3MNGs02qjBMCjLcp1lZiytd/sQQrDjKBADnufkc3xrKdN5jHt3EGEQp9zu9pGZPHDTkURKgksFD8ViEZ7rkhhKYgQR4jjBWKMKAQvXc9Dt9lFwXZ4YqUOYDGEUIhl0+Ee+YVt2/a56YT0rHLrtn37wZ76QgoR7AHUU0K/eVv3FipA/KVyZtRMWCwMDx/Vhhwy3/mAwFPsRtM5R9DwHZsOlOKebKiE3Ld1p+ID6joOS70ISw5MC/saplFm4rmMblaJpVEtEJEgzyFMSSknEUYRyuYRWpwcw4Ht5ZHSmDfr9AL7roFhwuegItLoDrPdDzIzWaHZyBGmqeXGlgwQSo1UfK60OupGBZoF2b4BBmKBWLsFag0QbpGkGx3Ew0/DRjxJMj1axb6bJkD694d7bceDWW1j15hEtncbDT57Anzx8jj7y3BIGVwWMFRxJRVdia6OMsgNM1oo81zMYmZ5BN0gQRgnKJQ+nzp5HnKbILBClGmwBhwhCMBVcxbVyAZdXu+bnvvNO97vf/fpfnPrGf/8v7U//9JejS9rspIuOc3ui9QdcwiyI0tRaudEZOErA2nyTEyJnwkkilDyXLDO6cYpKwUd5qK/wHAfFgp/7vwlCEEZwlESaZfBdF1JKjpNkc8bheS46QYTlTg+OlPCVymMG2MIM9W6ZsSSG4lLNufiTwZtUZEcqlBwHsda5iWa5lPvmGcuOkjkTSQokmUaiNaoFH76bJyKfnVtEog3CIRsKzCSFgCMVGDzUFtkXAQGuECSH2KcFXqKZAgTRcGYmNt3SBRHkpvVOLgDPBatDndRLYHAxHMq9VHy7oeuxzLQRJigpD+rjF7vwAASMVnzcumcW+7eO4PzcMtY7ETIGUpPbKbDNHVDSJEY7iHGhHWODu8+44vlXdB00yn5uZJoavPGOWXzbvTtx5mwbiwvL6IYpT45WURubprWI0IkJe3bMwnEkRkZHsWVmDNAhJqcacE0f6yceBQkfsjCOxKlioauRWYEoiTC/0uN926fx8COP0vFTlziKU1oLM6RJxiSALE1zUbaSEELAak2DKM67G20QZzoPWATg5xElMIZR9iRGyh5KBQ9F30WqLQwJSKnguC6KhQKmJsZQLbhwJUE5DkarRfQGA0yONwASqBTdfIYZJyj6LlbXe1htdYZ5SgzHcXIjVCJUSj6MNhwkSc6ijGIstnooFzyqV8swmrk1CLFn2zQ9deYy4sxg59QoWv0Qk80a4iTvqAdRhIlmDUGcYrkzQKnoIQojFpRbVA1lNpSkGgXfg2Xwei/A3EobQZJtogkMRtFRPDVSQ9FzyBiTGwQbkxdVAH7BQ7NewdzSKiYaNRQ9h3Wm4QqDe68bsbdsJbNj1vPn++6/uuffHP2Fz1eH9CJBJD9w0L/nJ/78uXaY7WQh9eIgE57nQQiizFj0gjDPuhG0WYhoCDs4UjIY5DgKYCBOk9xA1XUwUi2jUS5CCAxdGSQqxQKUkjCwKBSKqLq59Y9hINEWUggUHIVyqYicjiiR6gxZnOR0yyjeTAl1JXi900eUJHmssXSwd9dW6vZjrHf7WG/3WVuDQRDBsmUpFQqeA99xCJTrLoyxuRNyGEGQgKMEysVCjrdqjUrBQ7NRx+vv3ovX3r0bUzUXIxUXzx+/gCMffgyPnFrBM2eXEWgmAJgsSNRciVaUwSjFtUoZTAqGGd1+MHz9IMM5hOQJCWssYqs3nLO57Lu8e6wkvu2ePdE73nT7LXu++31nHjgIef8RfNlIDiXHuSHW+gEJXK8kktiw4k0X6w1+1gabi+BJBSEJvSQFM1B0HVJSQgwnrhtQbJYZJFmKTGt4Q09DYy0rIUGCNsWxS50eUq2hhvdHrIebCjNcKeEqRQwg1prtVfCxFBL1YmEIzVlEmcZIqZDPBPPixnm+Ug799aMY1VwqgMmxMay2u1habyE1G+akTFcMTnMSQrlYBDMjSvJ7FMYSDwWeVwdqbRRIfgnbil4iRh1mTcHwFTfvDYiNAajhdxjwS2dGDICcYW9kc71XHiEhBYYiSnB+gMKOyRHMjDewe9sEgnabLyy3oFnkQrJMwxV50dGZxUKni8vdBJzzIjZ/pzN0UCk6AgXfQcFzEMYZ/q837sTjz13C8TWNUsFBkGg4QkI6kq/bPkWNShkaElsmx/Ga170KbC3GJyYxWF/GjXfshoxXsPrcw0gHGfz6JMojIzhx8gw+9KkzWIvzmJqFpRUkOs9fY2YkWf4sx1mWow7McB1nqM/JC2uY5ISXgudgpOSjVPAghUC54KJZq8CVAsYyXM/LUSG2qJULaNZKcF2JiqeQJAkqlTIywySlQLngc7FahF8o4twLp+G6AmGcQRCQJAY6S1EbzmKiKEaxVNxMoK3UKhyGAcLEwFUC7W4fUilUCwXKjGXHURhr1KkXBPj4kydRLRYx3qhgYnwUx8/PY35xBY4kjDQqGGvU0B1EMMxYXW8zSYH+IILr5PZD3SAiQQKloo+FlRavdQP0wwRhZjbc62m4B6HgKPhKolYsgCg3vBYgxJnGxEgNQRhh1+wEk82NWAdhyO+8fZqnKqnZNgb/1EL8Pd/722d/+9A9UIePQn++5qr2nnug6P4j0dv2jX60G+sf0myM1pkYJCnG61Vmy+QoBYbJB8AbyviCi0qhCG0tgRmVgoeC66AX5nDKSD2HaDxPwHUkmvVR+BvYuCBIKbHcDhGygSMJvTBFkhp2lETiOBSmGYq+DzlMAc0x0By/TbMMnufyINGIWKKbEERqkGUpEl6EtRb9QZ+NZdZGcxBFXC76TKwRhRm0UoKJyOiM0sywVIpzwYMlY0h0egN4rgNjDPoxQbe6+NDHn8GfP/QUds6M4YYdTdx201b8xA9+CwqTW/DMI4/gzFwX9dE6muUiLp1ZxMWlNXzoMy/Qw6cWWA2x0Q1s35UCJUehXvJRLXhoBzHSzKBccEDE1AtiPHGxZS8eecJvd9JpfuDg+R/4xSPiqrSBL7UBqwqy7HkU8GbE+N8u6G5XUJIZVlc7UjNzPjsZ5vIQ8tN6ktvSsEM5jm0sIzUJwjSFq9TQm5CQZJoSMBzpINMZHCURI2VjDHlKct6NGASJhRn+KkG59Q2szRWBefwD89CxvFwsItM6FxMOvwZJgtFScdMDcSP9WBsD382hYV8p9PuDoW+dxlKrveHvxi9iBxGYrSXHURDwkKQZEmtyGju/mLZ+VTHaZB1ueMdhkxDPm5VFCUAzk72KnbCJQLw4AmMYaJujaBo8NCXKf7BhzokYAIquwkjZx7apcezYPoPFpRV+4ew8Or2A00xDSoE0zeBKgcBoQGt0kwxLgxQbQ+GNEaAjBMXGYKLk4b47r8Mr9m/B3t3jiAYd/Mr/+HM8eG6Qk1e6LxYYn1/p8raxOioFj05fWoDyfSwuLALWYNAPMPa/Cd/y1lux9/p9eOyjn8SpxxcRpRqr3QBPXGhjEOT6MCUFrDGI0gytfoRBkkEPHeGLnoN6uQgaQr0TzQoaJR+uUqiUfdQrZWQ6h8odKVGqFFEuFWFtzr4tFHxUyiWYLEbRMXA9B6VyEVIIVOsNFMolhJ0+0jiGhqQsy9gEPUyMNVCtV8BSwRqN9moLZy8uYqRRwaWlNnZs34KSLziMYvJcF5cXVqhWq/L0RBlnL85hpFnF5PgIOp0eJ6lBwXEpTGL0+wG2jDdzKLIfYHqsikbBwaIQIMrZodWSl6M+SYrp8QaMNkiS3Mat4Cv4rsODKCWZpCh4DpplH1k6dCgxBlGiEQ+fz0GSe4ZGSQZPSVSKLiwYRc+FAGN2fAS+o9Dp",
		"9hGnGQquQj+M8aY7puXKylr05OnkBQDAvbA4+oXFTwgAfPNEaf9cJ/lU2RNVy5SGGqpQKsKCECUJ9cNoU7/QrJRRKRWQDK3QS0Uf1aKPspcLKGu1KsqlIlbW1uA7uQV6lg/0WQDw/QIxJEjmLgA61egHMUzuOQPNFmEYUblYRJym6PSCfHBt8+wjJgFHOey5EkoQe47DAsTGZoiTBGmqRZykUihJmTHIUp0LHxVBZ/lMS1vOZ0YAaW1zQ08ScB1plBDGcxyRZlmO7ysnx+XZMltGEMa4Z/8UvuutN2FsvInJiSJYS1h/lJ4808XSegDHd3HjjlH88vt+B3/06VO8Aa1Uij4VfRfVgoea72CsXkbRldg2PQYlASfs4ru+7228qgX9f7/5Ab3aCb7hjx49/+dfZn3SppNDrYZG2qcjhvmNAMVCkLA5PPsiyZAUBJcEDBipzTOBXCngSrnJUMuGVHxJeWw4CGSHhYxE7n2ZM5tyDJzBPCxyNGSODT9Lu9ldDIPNyVNqGKfuoR/lmiI7dNsGgLFKGa4U5DgOM8COkki1ptyWilnl1jrQxmJqbBS9foCLK6sUpNnLkUehCHCkIsdRkLl0K587kUCSpdDDEMKrGqF8snNVZjdfZSck8lhYtgTBuJIQK+hqI9oNHelV9XFYpfglz3+t4GGiUcJMswrf8yjOGGmWot3pwnMdKJUfAvpBBACkYFgRqJsYXgky0sPPcDM/SBBby/wNr9hH3/S62zE+PYPVxSVeXVmm9c4aHj+zitTxsWN6Aq7VeOr4WRy/vMaJYQilYJlRdxUqvqIt05OI4xhBEGIQhFjvJ2gI4Kd/4C7oTog/fmwR53sGqdZY7wVIDaPoKhS9XEdTKfqolkuYnRzDzi1TKChCxXdRKrrwPAeL84soFjz4CiiVCvCGAmkhJaSSSIIArU6AWr2IyYk6pFeE67qojY6gVHYhYCDdCjprLURxhkE/QJqkKJXKpNMYa6ttvnB5BY1KEUVPYW2tA69QhHAk+t0+XEeChYBQLrIs4fWVFXiuR3GmEQUBSykQJRqCCIM4Rb1chHIdtHsx0kwj0ZayoSrFUQppkgBskGYWg1SjUCigUvLRH4Qg5pwAluTp3O3eAGu9ACQEojgDBGGkWiBHSbbaotUP4Xou+kGc++ulmvLYF0AKoOo5gLWoVwrwXQee5+XxQZ4Lh4gHYYxqycNYSfDuOmWvuq5UOHZu/Q9+9AOXv5UPgenwF+j2ffUA25V4pyfl785UfH89zJIMpECENMfzKc6yoedbAWmmEQ8HhY1KCSXfAyhn45ULPrueC9918gfc5vmTvu8hTjKkSQZjAakksmGEgMpFegy2ufmiZfYdBcd1kKTp0P1Z5G7PxBgEERmTkRw+sGmqwWwhcsgHltFPtFlny/PKEYta86Igmvddp22ZV4W064lGlmZc8RVvd5TcTRa3O5Jeo4Rw67VqGqWpCKKEatUqekFIBOLrt01jrCJx255JjFUcfNM7XwdRcPGpRy/T8+f7aIzUYbIUI6NjQNTG6ePP42d+7yF2lETZ96CNJWstGkUXt+yZxZbpMcSJwcRYEytLS7y+skL/9J98J+6+7y7os4/ZY48dX2tn3u8da+lfec/P/t7Fl8Nkv9TwXbPZrPY77d9ny2/LHRhoI8sGml8819gY7m+6XlPutEAQuMrC7Ar92/KmhZB9SUwADWchQmwSyPDiDiTvLoqei4rvAwQMohhRmuYd9pB0kM+VJJqlAjxHDedNeVFkMOI0g+c4eS6TNaiVy3AdB53BAO1BzsLaiC2/Wi9DQ+dzXznCUTIXHQ4PXUmmN335MmNh2bLJTWaHFkpDS7vcjkxcEU1u/hZxpey8ZBZ05frw0KCSXCnhOgoV38FI2UejUoJSAmyBziA0QRjbod84KSWYjTVRmlnXkQRm0llGg9RiPTZWW2uJYAhklSRWQnCUWfftt+7w73/TreJPnprDqQtLmF9t86tvmMWrb95Fd99+HWbGG3C9Ih7+2COoNJr8wYeexIcfO46LnQiZzrOwfEeSEIQoySHrkWoRN26fwMTMFBwdojd3GY9e7CHLzYPQqFdR8hxMNcoYK/uo16uYaJQxNj7JsAajVY90plGoFOEqhWLJR5ql8BRQqlXhFauAdGEApHEMz/dh0hBBkKBQLoOzCMVKDWkcczDowi/5sHCp0+4jtYCOEyxduoRUWwzCFCutbu5Mow0uLrfQ6YeoV0sQUgEmR6ocJUHg/FBOxMrJ/SHb/ZB8V8FTgksFD90g71yq5QIGUYbuIEQ3jGGZyXUchHGSs90qBTAT4iSDyD8uCEdiEMTQ2mK0UeE00/moJIiAPHqFgjgFwCgO3WgME6IkZWMsksyg6DnwHIdagwjG5rEovhKoeoqkzO9n5ShEST6jE4IwUi7yiK+Y9EBbhnPz1lJ2301jd77lV5593h6C+JsWpM2iVPbV66aK7vsGqTnQjXTquY4weUAXhUkK31EouC6SLJ8NKCVR8F3OtCWjDYy17DqKlZBDI9SrUiFzBTaToDyIjxlsDRlrCESSjSE1JDUIImS5gSCUynVOw/wCOCoP5UrSVGfWBtbyqpI4DdBpgE8BdNayvFAd9VYXFvrrX4h3zmzDfw1n/C8hxdf7ngcpREpSSW0MdXoDvm77DMarBcyWCTftmsDM7h3IvDrOzXUQRglNTDTR6Q3w6Uc+g6XlNcy3AqyFGUYqRQRRDE9J7Jxs4DV334RKpYLWehssXWybnULJk3zh1GmUfKLv+JZX8gvPPI0toyWJuIeLHZo7v6jf9QPv++CjX+ZOSQIwt98O59kn6ecssE0C4UbCs8lRsyyPNCO7YdIO5tyYGBDDyKMEgCbACiIHYBrGAm1wAQyG5t9DhqHN8xkEwcJC2DwpHCIb/lsCrHKVkqVCiWAyshYI0tRYa62FFQLwDZNDxBkskoLr6qrnWCEFa1grICGFQJIkUMpVuTJJgFmbguPZJLOUZplJrDVZlmkDaMAaWBgIWMqJnSwYjoTwpAQkpHVdaYwB+64rCMZm1iaZNUmSGAYgTH5Rh5CsyXMDhluGgdSAMbgi52AYGEKOy/MGvwGwUMoA2iooZ6xa9Goln+ulYiqIbGJTGSQJd7uxCeJYj9Vqmog4CkPrumCfyBC5nCLFYJDCcSDOdzI4w8aTXFjXdbnqeSwF6bv2bbn+jTdt+1+PnVzxP/b0KXtpvSfe/YZb8Ip900gyYHJiDKfPz6MxPoX9+69jkbSxtLiOX/+dD+B8O8TyINkYiG4Q9rB9oonvfP3N2LNtBm/6+jfA9SW6i5fxxJPHkFEJOtW5Xsh34LgFpIaxurqG9soSj42NwlGE1UvnaPvOWRSao/AdhbJHcCpVdNcWUWpOoDk+hs5aC0uLa6g1ami1A9RHahh0+1iaX8PSWhtlT2LQ6/FjL8xj3+4t6IcpOkFK/SDAxYV1HNg5hSzV6IcxLi+vI9UG122f5jjTWO0OyBiDNDUoF33Q8F3WSvlcOmPiJElRcB24nktRkkAQcTGf2SPO8oN1bxAh1Rq1SgnDeTctrbbhSoFqyUNOviRk2rC2ObNzEMQol0v5TN5YOIo47/IZmWEM8uIGQczGMmWZgcidGoaejDm93XDOyBPDPbtRcEkOh5SOkshs7vamJKFc8HhUJlmjQP6lAfcPTFd+7LcfW/x/DwHi5bKQvpCCtLnZ7G6iGiTuL6UWP8AQEFImidYUDJNdS75LgnL3A6kkCSGQZoYAJs9xcnduY0nbfPazwb4SJJCkySb1l4eqd0HCAgiZbUqCOoKxwoyQwasZ8yIxt5QQGQORIOppbXsWpmsF2j65fVUqLbfb7e7nKLT0Egu7lx7M6SpRqCUAdV98a9Hz/+NYrTzteX7aC0KZDIelLgn8yDfsw+tvmsagvB2feK6FIIupVinCGI2PP/IULi6uYm61iyDJ0KwUIUGYGWtgpFzAbXsmsX//Xhi3iPX1Pqa3zKLXWuennn4WE40SyGjc",
		"vrPCe/ZMk23s5mz1fJa2TheeuaAv73/NK9/62m//d8cOHTokDn95mHd4met4bf09WWLI7HvfD77+Jz71zPwvPXRyOb3c6spvefV+eustO3Dk6DGMjY9g6/QI0sxAW8Jdd93Gc2fP47pbbsZDDz4EqQQ+8vBzWG51sdYPkdncVeI1123Dge0TuOGGA9i3fw+WLl/CzfvG4dgY7fYAcCs4deYSTl5axp5du1GulMA6RTrooB9pvmH/XmTZgOpFYNuNt6O3Moel0yeQWELQW8dnnroIp1DCylofUgpkLLCw0oLrOqg36ij6BfQGIUdRjJXVNkZH6yDlYHG1jcyC0jQFhESt5A+70XxWKgWx5/n5SENKEUcRjGU4ns9BlEARQxuNOE5ztp100A8CUmJT48RMBE8pRGnCmdaIkozDPNuIK0WPeJic4CoJAd7Q2rESAswGhplSbaEtUw5MExmjCQzacAUHCELmHoZamzxccail09ayHrrVUE5A5YLrAMysiHN3+OG81VFObrjsKkRRbN9+XcFrZ/Tsw4vm+84udp/8XMXoCy1Im7MCABgreT+cavvTSsnx1DKCOL0SKaByE0k7ZCiZvHvRbDljRioEUgJiQRQaRmaZEwIiJanDzPOW+bIjVJeIupb5ghV6vVj0gxp73dHdu4OdO3fa/33kiPkCdj2BF6dOXP31Wc1YP0tRBgAz5nm7x0eKv1krl14XJVnKgIjTjJquwDtuH8MgkxiIBjraw/hohQZBgLOXFvDC+ctY6QwQZQa+68BXEiXPQbNcAsD4xlcdwK7r92BltYvTFxZw9523oFmv8ZPPPI/ZLTOw0QCD5Qu8o5qSt/u1uPPt34bK+oN68dQJz5/Z98zTZxZf+45/+EuDoSKRv4xFSfxVEOmz+yd+BSz+a14Pf4l//8tdO/5rDgD0hbzme17y74/+Ld7rPQCN74c4chz6nbfP/tb5hc73XOyk6Suun5bXTzZJKBdPnV9BqVxEpeCiXK7g7jtu5FKxhJLvI8tCfOTDR7F12zSOfPhRrPb6MESItEW7H2CqVsKWkSrdtH83Xn33Tbhu3x40Kw7qozVEF5/AyvwSjFcF3BK8xixKjkDcb2HH9bt4ZbGDhAtoNHx69rHHcfbEOWhrcGFuDb0ghqckpxrcjQ36Qcg5VdBs0u9J5JCU5ygGMzr9kKIkoSQzKPquiNMMgIBlpjRLc69ErUlJAQvAc102hjnNsryzEGBjmIVyEMcJK5HvkUlqkLN9FSVptqFLA4NgLJO1hiwgEm1zyyowrMnhTbvRweTG1Mi0BRgoODmRKB3KL7QFDLOWgkIGEjAHjNxYwzIPsxOIiCAtw7FsXRAcAVKWWQFw7dA+TQxhcVcKlF2JgqtQKRWGLimMpi/w1v3V/9Nl8/2/8pcrywcPQh75a9jA6gu87/QGXr0aJL/m+/hTk/H3JtrcwMCKEmKegEVtdR9ArCAjIqGt0akGR66LpEBekookkRGSATgCkDBgBMCpuYL7a/siNiDSNEYHMS4+8QQ98cQTG8WBXvIAv9zDuFF4zBewKXwuVhkBcFaT5MyUqb+t2w9+LTX6e7LMsnJUNj1SFkutGH9+vE1WrWDPrm1o1Au83unSC+fnsLDe39SeZFkGCWB6Zhy37t2K8WYdo/UisjjEyuoKzl26jKm6h+oN+7F39yyCboC1pSWcP3WeaKKEUeccooXjGG025NT2LbFfcW5O6+Y7iei/8oOHFOGw+TJ1K5/tetPnufl/MTf8v8tOj74EBfGL9vkd/Tt8D0cB7D8OwXwIFe9nT483SnjP22/HZKMADcWPnVgnFhKzs5MoFlyEQYzL88uQJHBg/25Mjo3DK/g49fwx/NPvfTs+8Znn8OnnTmG+MwAoh6uCMORHnzpGgyhBqVzBIxcvoSiA7/4n3w2//FEsnrqI6V3TGB3zsTa/xKET44O//3vomAZidrE2fwlzS23MtwawNmPS2maGoYRUY6NVijMNA6DXG8BYA0fk801JAq1+CCUVlCQYptwKzTLQ7YOZEA1HCJatISBxpEiEgAER6X7kGGs9AikAQkmZK3tsHgpohmJkwwxhDII4dx5na/IwPRB0PmwfCKJQSooTbRLLrMHQzJwSKABhYBkRW46YMGBGNzK2TRZ9ELoQTsvChFKIvhFZnwiZlIiVQioEWKkxI8Qqa81Cr0MaQJkCPNfCjRJ2BeAwUHSkHGHmpgVmCdieWd7eT810xlzKLJS1WbfgqNOhwR/+248t/t7GYf7I5yFNUX+De2+j3ZJxjIuAPrxZrV4i0DMv+f1pCqR5qvfLP9VDm/XPAp/x57Hhfak2tgyAeHZ5OQDwvdM197k0Nv8GhNpq34vKfkVJz4XrFSlKUqy1ujh9cZGTzMAOcfFaqYRa0cW28Qbq5RJW2wN4joOx8SaKBRe7tkygWfFw9vQ53rdvN8ZGR6F0grlBB699xc1Q5RG0W13MP/EpnOqvYd91W2mMmWuq/y2HDh36b/j4YctfQe3HX3NooM+zU+GvsALGn2dh+1zf89mg4i/n+/x8u8Sr/x0dvOceS3TYfv3t29w7d00ASYTVtoUml1Lkfm3KK2Df/j04/uxxtFvrFEcxXzh/Dm9725vxlnvuhFeu0pbtW6DjkCuVEv7isePoX1pFP9SYNwFGSh5fWljC408dA+sMBUV47vHjdNOr3gnpfAIOB3zyM4/i08dbmFvp4vKlRbDrU5ymiKKEF1oDa4moUfYUJMt6xcdKK+ifvLiwGCS6lRp02OqBI+Ug0yaApBBs4yQjY21klRSxJeoZyy1tEZIxiSXKCNCGkBitE0GIDSOhfEhExnqOZe1Kdjyp2Otn2mWWrgS5UmrFGkpDOsxm45BtlVJaSJEYQ7Ehk1grAyOyrpSIOETaB7LZWWQTE9BPPA79WdGQF+2SyV9zK6z+1T+KgOiv/EzzV+6KV1pWR7UtI9ISQB/Q6cYNMtzzPq/9+m+7X11dPOivOVX+dQ/dV+PcYfPEv2+8cWMQR/9p60j5DWOVYvzsQtdpjIyiXi5RlsQ4t7CEtV4AbS18z6dKwcdErYQ9W8ZhtcHxC3OQQuJb3vY6dDpd3LZ/KwquwMlT57hRLWFmy3YoR1FRMNdGx/AL/88fIFyeww9+w01IpM+eNLZUctyo1zv+83+88IqHT57s/3V47bV1bf1dPQeHDoEOH4b9ue+699/WXf7RydGilzLRJ55ewMW+hYCgWsXH69/wKuzcsxunnnse4fIczl9Y4BPz67jt1gOYaVaxf/8++rM/+TCXKyVcWo8wt97HsbOXsdrrwzKjJAlTzTJ2bt2CnTOjcF0HjaJLU9OT6HTaXEMLYUx45nwbbDQmqg4EawRxYp+7uO6MjzVQKPg4fm5xYak1eGyqUf6z7iA5yuwunlxf7381fwZ4sY76c3X6X+gB6LPB7FePQF66z4iDAB35AhsH9be8CH/fN7tNX9iTK+3npqam3i7IvD/R5hslKAqCwHGkgNUZ+lGC1OTxACQEp1lKQAnGWPTCNP9shcCJk+dxcX4JJ0+fxZtfcR3a/ZgKrkRrdQFnz85hsRNTZoDlxWW+ccsoLq1FEK6m83MtWl9Z5T3Tlcr12xrOwyev7ZLX1pdmPXDwoLj/8BHz+//yW355ouL/+JMnL+vJnTvp/MUF3LB3hhpdzUFiedAPKQv60FmKUqmIpU4fYZIiyzK0VtYwUS3QX/75g7y81sHkZBNYXMfC8irkMNvMGEM9A6heBHd5BStr63zHjXuo3x3w5XNnsX2qgYfOLeZJvGHCkpgDqWzZd7w0ieViNxyQoz7UOr/4u4u9wSMrIa1cerEwl15mM6fP0sX/bQ7V9LfYaz7XgZ+/yPvcF/Ke7JG/wS+S1x6nv5NlAajBYJDsGPE+0U/sO1Njx/phkmRG82qnB0dJGsQ5EzHTGtPNOpU8B1OjDWSG8ZbX3o7v+aZ70E0sllY7uadWkmBtvY1z86s4fWkFz1xYxcPHL+LpMwu5qWMQ",
		"41PPL+DC8gB/9uwle3Kpq0bL7ge/+2fuf38YHqVfOw4+/BWH2l1bX0vr0KF71Hve90HzgZ966z+6YdfUzz/42OloZKQuHj+xQAsLHao0mmCngCxJsbjeRWxBUyMVXDx5Gh995Fm8cGmNwiimqicR9PtUrVVwYaWDlfUeRmolFHwHJy+vwJKEIJCxFqnO42SiJKWpiXHes2srLl2Yw/6dI9g6MwIn7tizCy17Yr7jCmZFSq4GGr8eGPOPP3ly9X1Lg/RkkCEAIO8B5MW/yrTll5z8X+6Lv0xfX9PrWkH6uy1K8mIr6rpCPTKI41f0k3SmH8WqE8YySlIGCCO1KiQRxmpV2j49gShN4fo+vvWb3sydXp+eOHYJy2trWOv0cXGphURbXF4P8OTZZVxa7yPWFkIKLPUiXG6HGCQZkizDdbN1sXWinl5a773n53/loxdfU7hdPfH9i/zxo8Dha5/NtfXFKEaAOHz0ov3kL769cvzM8m/90YOnmp85u8KlYlE8+vwFOrca0EijjrnFFirlAkZrRay0AnrDG1+DuLOGcDDArXtncGDnNJIoJJMkPNEo4KEnT+LpU/N08/VbMT5SxeJKG0GcIDUGdkhTlmzhOwpBkqKoBJqjI5iZqOLp586Y/iB02wmrTsYXMsP/Za2Hf/zB5+cemG9FqwcBOZYXIQDgi1eKzt+LDf+rAXe8tv5ulwBgm81mNep1vscw3aKZb7PW3jQz0rQ379lJT5w8g4rvYs/WGRR9F+cWluF7DhylML/WRZYmlGQZut0gN8kcGhrWCh72bhnH3ddvA6cB/tfHn+EkMXjdddO471U3YqrmcrNROHN2rn34O/7zB9//wLtYHjwCS9cetGvri7B3HATEEcD8o9ftuPPk5c5DF9YTZdhywfVorFGiubUeZiZGkGSWeoMAY7Uybrx+G7ZsmUSZDAqCMbFtO0rlGv/xA3+IfpDhzffcQt1ej5dafVKuA5IOf+bZsziz1MLJhXUIIUgyY6LicclTKFcqaJQLmJ0YwesPNMwf/OVz7lInPFt21S/v3r7993/9L57oAsCQcvxys45r61pB+vtRlIDc0qbuqf9S9Nx/ctPeXSkzyU8+fwKSgNFqBa7jwFECrUGIKMkQxAnFWe6Jlqdx5hlA182O4fqdMziwYwowGrfvaqI+PcJv+sH/iv2TVfzzf/BNGKl4fPH0CbVjwjcTo4X7/nfrD49+4+Lt8vZff0JfK0rX1hdh7xCHDh3ix//oN/c/eXblUytBWnIEWVeQGHqvQAMgqUgKIE4zNEo+lBAYKTmoFx3cc/ctGBkdw4nnTvCOnbNoNhs0s2MHas1RnHzuKSwtLOGx507zJ45fBimFJEopTFIuu8KOVjzWxhARmRtnSuLNt826v3304pFHL2bvAYIVADgIyCNfHuPha+saZPcVszaSAsT09HRz3Fe/ON6sN0qVGrueS1Gc0HK7R2mmKYxj9MOIeoMQQZyQqyRu2b0Fd+3bhu96y9183237yGQZVrt9bJ8axbapUSRpBul6eMvX34XTL5zDJ47PwQHjwO6ttHVEpdvHhduP4vTbf+r0//mNJxftoUOHxOGjR689kNfW33WHRO87etTuaVZ2MNG3jdbLBSkEr4YJjZR8TNYL1ApiCrM8W8wyEGcGUWYQpLkd7tLyCgYpwy+VCMKhyZ270UkBZgG2Fk8+dwqnLi8jSC1u3bUFUkisBAGYobIkkyRIspDq5t2T0ir3P/3+Ixd+UAjdv43hLAJ8/FpH9FW11N/HB+mqovHFXkbFvQmvUp6K0tSevrxAQhCttLpgIvSTnKrvSAmHiMquwre/4w3YMlKDp4i3jpUxNVbjsgv62f/5F1hu95FZhuc6OH5uBZ/8ww/T1906y+9/8DhOLnbwZ4+cxJ4x4Xzw0RNmfnHtHT/9LbcGlHT/Ex0+fAnXLH2urb/LE9ehQ0SHD5tH/vP3vebspfX3rw+y+lo3MB9+7JT4trfchuvHC3jhUg+djHD84jLmV1pY74UYxCmsYWRG52LXzMel9rE8uoAEVvsh+kGA1fkFvOcffAv6vS6COEE/TECwuH3XlF1rd1Q/jo9CqrCf2bGyMM89fGLxj44t9P+EAbrfsjySi/iv3e/XILtrBemq38O7dzer/aXwqVSbnf1EZ5pZlnwPcZqiWSnjNTfswrapEYzWyvj/PvQpjDebuGXPLColnyebFeycrqFelPQT/78PoBVZHHzDHUjTDMfPzqPbaeO+27fxb3zoGWyZnECSaayur2K0VuJvuHsXH7zvFmfmhhtPUM1718iB7z/GfEgQHb52Yry2/rZLMDMTkfpf/+IdD2/dtv2O+Xaa/PGDT6iJyQrecGAapy8sYj32SHkuRsfG0Gp1sLzewuPPncSz55YRJOnVmU0QRKh4Cru2TGLr9DguXVrEdVNVrAxi/MWzF7B9rMpvvGkXXnXDFvPxp864v/vQ8X8mpPgvb9qx0/vwmTMJABw6BHH48Oazfa0YXeuQvqoK8Be7Y2AA8syZVq/sOb+gtf6v28ZH6IY9O7kXhDhzcZ7e+sobcPf+HfAqPmbHR/Hgky/gydPz2DE1CiEE+rHGw89ewEQJeMW+Sfz+Q6fwkUefx5nLS5hqNvHKG6dx/PR5CJ3iuTMXcd22KXzPN9yDO2/Zh/37d1FdhWExa113/pHT3wfgn+O9EHmw9JfV4w7XNouvcqju4EEiIvubP/T69/7hx1+443X31NK5xRV1dm4Jd90wi488chbKd2nP7m0oNUbRaNRx8x0NDNZXcH5uCaO1Ad59660YhAkuLa/h/NI6gjRDP85w4vw8zl9aQL1WwfElxuJqB/umR3nneBW7t4xj343X0f5d45iqUPOX/uwY7v6OM9mHD0MeBHD48JfNveXv46H+i/IMq2vX9ov+oalbZkcOlH2X3v6m1/Ijxy7i5Pk5VIoen760gkq1iunxOk2MjeK2/Tvx9LlFrHT7WO8N8OzJC4jSFIsrq9g7O4p+nOLEhUV885tei+u3b8H10w7u2vNqOtc1/K4f+w3cuHsHipUmFtYj2i8kHnnsmFp68uP21pt3TwPAkePH+WD+ougayeHa+pusQ4fukYcPH9Gf/o/vftczp1b+xZbtW9Pf/5OHRC9OIInoM8/NI0pTGN0HOyXs9YpYXe3gzrubWFhaxcceP4G3v+oG3PfKW7Br7x6EQYhPPfIZrKx3sdLp4MOPn8IgyWC6faz3ApSKHvZtmyFfCb68NsDFxS7tnfDwbW/Z8ebIJD8HfEcGHLZHvnLu569laPyLfqD/+0hqoC/Ng3tIHD161P7wm27/idFa8V9L5WevuOMGMsqjZ06eg6skukGEx46fgxBEYRBhcbWPFy4sgK3F8lqH5pZXQDrB1okGLiy1qTWI8bbX3IFX3nYjoiTGej+FWx3nZqWAYyfO47lzSwiCARaWW3jqEw+hFM5xBqFuuGlX750//mu//fU/+ZObcN01bdK19TdZPzx+Fx05flzdPlt7n1uqbneK1SyIYvnEC+coSjKM1stYa3ewvN7BC2cuoN8bwFrGSNXDbx35CC4vreFbXn8nrjuwH3GS4ZlTF7Bt2wxmx8q471U3oVr0cfTpM9AQiDONONXo9QO4jkKaGYSJwfzcEk35QdHxxO/9+C+/v3PoEMTRo9cOWF8LRfcay+6LUYwAcfjoUfvOV16/TbH+rYvrkd/ShHJzVDz93Ek8feocRhp1VEpFSpKMLi+v4eSlJTxz9hI6gwCdIELZlXjHa26m192yl+579a34/oNvxOPPnKAgsdi/byeWllYRJhH+5CMPo7ewgCDTeObcEibH6riwsIpWu8vvesMBJFmCNI3rB6ayP6r+3qdW33vwoKTjx6/Nka6tL3gdPAh5+Mhx8847t/0AW/zQqaUwSVmq1e6AVtY6WOyFFA36mKq66AxiLHcjLKx34boKx09ewMc+8yzuu2UPXn3b9YijEMwW/+cjH8czx07hpj3TGJuYgJNFeP78",
		"Ita6AWbqBRhjsR7EWFzvYq3VxcrqOrKgL2yre9m35V/90+OLydGj1z6br5V1DbL7Iqzjwy7s8vL67pbjjl1qh1m5UhMnz82hGyVgZpybX6ZysYBOMECYpPCkgCsFLDMUEb7uFbfglht346OfeobbkcYtt12H63fO4P0ffxY7n34ezXoVTz31LOI4QuX6GnQ4QJwarK93sNbuoTY1jh5X6I1vvTFrXTpR40LlWwG8F/v3X9OeXVt/g44f4vBh2KU//lcTP/Wf/uinY0s8341EL1vFyQvzWA1ibJ+o4d986yvhOAWsJA4uLKzhoadP4qMPPw3Pc0BE6IQR3v/Bj6NaLmN2egLlchHLq21MjDfRqBYwCBMkqcFNW0bx9tfdgsRYPPncaXzyxDytBDGz1sbnRPlUPf77ueh1U/N3Dab76l/y7+CDuLbBvXxB4sAqnl/t3N8L4+p6t8vnLy9QlCQw1qIThhTEEarFIg5sncQPftMb8Z3veAOeOXYGIIE922bQDWJ84skXEKUpLp4+j0GU4MTcGtZbHdSrVUyO1PGGu2/CXQe2Yr3dwdETiyBr0ahW0Gg2KYxBNx/YgQr6stftjx785n/237f/sx/N3nsYdA2yu7a+kDU+DnH8OKwTDH7m+Uvr9916w+40gi8vza/S/GoLSarxQ2+5mZSQePD5RdQaTbzmVbfhTa++A0zA0ycvQBuLTi9Aqxfg4uIann7hLJ44OYeF9S76/QCCGf/rY0/i2QtL/Ip9W/Ga17yC3v2DP4w926ZwZzPhMIz4+HLf6Se6m0L94+VeNIcrQZBf7oJ0bX2FFKSrC9O1DyZfDEAkSdIuuupAlJnbpCAdp5loDQJEaUaCCAd27cC2iXFsnWri9a+6AVu3zmJteQXPnJmHK/Nc+iQz8FwHN1y3DUvL6zi72AIzYI2B6xfQaI5h12QVnojxgU+fRWYtCp4Llxiu52G1m9J1e2bN9NTYhFfWTzb2/MWJ9z7wgDx85Mi1E9219Xl2R4fE+953lM//xj+8/jc/9NSvj401xdYtM/TCpRaFUYRWt4+yKzBWEPSp4/Poa4EgSpGECbbv3o6CAJ47cQ4jRRc//Y/egZ3TIziwfQrf+c1vwA27t+DsUguPHjuP58/M4YVLy1xwXXgO4YWTZ9BZvEgzO/dgWqzz226fkANRXH7i1OI71wbxw/zF7Y7oc3y99O/52t73lQnZXdvkAPChQ4IOH7b/4hvv/l6S6v5jl1q6WqtJt+DhxKUlevrUOVgLCGastloIogB/+rHPoOAQltY6kFJgfr2DatFnAqNRqWL7zAQ8V+GDj59GlBlYy+h0e3jokScwWzyAu7Y10Cy6WA9TrLW7mB6po1atYKWX0kcfvWC+/d5Zp1RWPwDgj3Hw2LXP6dr6/Dv+44cJgP2dDz/+I6cWesV3bBtLnzg+JweDAdrdHtJMwxAoTTW2jddwoc/IrMVnnj+Fj3zqcYRpin4Q4+137cXkWAOtToDZneO47sB+3HYL4fq92/Gv/uP/xKnFFpQQcEhjfrmNWw/sRtET+J1f+Y+47547sHuizv/m2yfw6t3Tl97zvg/SIXxFkHP42t73d7fEtdb17369d/iYnFtqf+PZ+bXy5bWuHZ8YgXQUbtq3k2/bvR2CGIMwAohw+tIiVrohvEIR7SCElBLzq230ohjaaFxaWgGBUCn65EmJJE3z77WMsWYV55YCEAEHZusAAEcKLK+3ce7CZdgkghUFcXE1zILludef/MBPvZbosGU+JK59UtfWX7eGpqTmN37o9bc/fb71vc2qZ8arrggNYRCGEELBkqBeYhBlFooIJc/Dq26+DpMjNfSCECcuLXNqNPdTzX929Cl8+NPP4w//8gmcPHacH33yWTz97Au4/96bsX2yCcOWtkw08epbr6dX3HyAvu5tb8M3v+sduBy49MePLmYm0ZPveNOBfwyA7z30Jb+H+SUF6FoR+gosSF/O+OWvyHX4cF6Y//L5i8eOnpjDfKuH+eU1XF5cxZlLc5COYlcoBFEMx5EoeC4mRhqQUsJ1HAgBJFrjwuIaVUpFIgJSAi0uLGNmpAIpBdb7AVY6PURJim6Y4ZnLId2yd5oAkHLyn73cHeDS4hIWl9u03sls1lv3bHfxXwIAjhy/dni4tj6fkgSA6fJy+989c6lVePX+cWPcCo2MNuG7Ljr9gOIkhTYGibZgZtx8/U5snWogHAQoeB6EEFBS4sJiC4M4RbnoolBwsdzq4dnnz/JHPvkMTp5fyIuZ72P/nl3EIKz1Bjj+/PNojozx2sIS/uShZ+hX/sdfsoraUwDwcXz8S9X5XCs+XyUF6Wrs9BqO+pLlSPoL3xFaSiEXV9toljzYTGNxtQXDEv0wQRQnmBypw+gUZC2a5RK0NgAYgyiBNhZTo03q92Mc2LcNE40SKSkpiBNEqcbCehfMArv27uN7X70fggiDOKFUawziGJ1BhFa3hyeOL8lCfSzdvmP6LWc++DPvpvuPGH7ggWu0/2vrs64HDh6UR44cMf/PP3zNN59b6n9dYm16595pOZA1aMMUZZYgFTJjcwW466BRq6BWKmB8egYWwFovhLWgOM0Qa0trnQAlz8dd+7fBmgyX51fQDRK0whQXl9sQTFheXUcUx1hfb+HUqUu4vLiGVqcHmyYoFX366CdPPoy8In2p4Lhr66usQ7qGo754WQD02rfGn1JED4Ot7EeJdZSDbZMjaNaq8HyFME0Qxik85aAfpti7cwbVkgtjcgeU1Gi0ewHYWGQZsPf667FltAolCMZaGkQxGWNprR/SC5f6dOeN+3HbznEEqUGYGRqEMa2sd6BZkXWK4i8eOiXWlpYwWsJ/+eQf/tIuHDxo+dA16O7aetlFx/Yf4QcO3VO+vB4deujEMm7dOYIERXQTQXEUI4oTBFGUM3iIMF4polwqojHSwOVz55BmWe7lQ0CqDS2sd5Bpg8nJMXiOxM7pJpI0w/7ds5hb7SHj3HT1/PwigihGoVTkQsnn555+ClvHC/ztr92mIovgNz/ywscAAEePXtPTfQ3cZ1d94dpm9EU6Wd2DHHuvFP0/Kvke2MKOjNTgCgHfdRClMRiMIErgOBLrnT6MYYw3aqiVywAAYy0YhCjJQEKiG6SYHCmj4ORcFGMMMm1QLLgYJEA/Jrz5jh15MbMMA0KYJPTcqXMk3RJGdt0gHnrwtDadtfEthejfERHjwAHia53ttfVXuyNx+DCsaTvfe36pd9NcK0hee/N2sZo4kERI0hRhFCPLNACgXvRQLzhIjcXEWANzc4tItUYUxzA2P2BFqcalxRXESYqJ0RpHgzZ2TTcxOVrDajuAEpKNNay14Xq9wecuzmP+wjlw2EFNpfyue7cKkP7EQ+fWTvMhiMPXoiW+5orTtYL0RVrjw26xXPAeLxc8k6SpSFLDBd8FEYMtMwHQxsBqDUnAaquHWrmAiZE6iAhaG0gp0Y+S3D7FdbFtZgIlN0fatNE5gWF5Ca31Fi6sxHjTq26AKwDDjCAIISDQGwzwyNPHsd4KMb13vzh+/JL2gpV3fvBnv+0euv9+gwcOXrsPrq0XbQz3Hzliv/OVN41/9MmLP/bkuWWzf9uI2D45ipVugvX1dSyvrSNKYrhCQkBiquajVvaxc+8u+MUCFpdXsNrqwtrcOBEAXCXhey5cReh0ujQzPYV9u6dxebHN5aLHbAwya2FA6IcRZicnkaYJhAlRbdS4OTOLd71y/GiO1t1z7Z79GjzIX/tQv0hrw+xR1b0LVpu1UqGgLi8ss7EWnuvB930IQZwZzXGaotlsQLkulCBsnxqHlBLGWgyiCBACiystpEmMWtVDs+zmXVCmAWa0uwPMLa3imRPz2Dozhjt3j4MtQxIQxDGYBM7PL+EvP3MMy72MAu2g3++5d9+1/T/+6j8+WAYO4tCha93ytZWvgwcPCgD82gOVX0gys2OpE+t7b5iUi6t9cj2fkjTB0moLAEGovFtvFh00p7cAysOl06fRDyP0",
		"ohTKkZvtt5KSq6UCz88t8eyevXDKVVpf7yDVFiZLQWBIIThKMjsIY1pcWcHO3buxZes0YDUxM0ZqhRcA4N4D49fGA18bcN1mMboG2X1xlwWAe986syQlXawUfYpSw0GUQikFYyys5c0JnBQSkghKKSgl4DgOAGAQxYjiFHFmcP7CZZQrZeyYGck/TSJESYJyqTTE34FE1fCtb7kDANhxJCdJhm4/RKo1Tl2ax4nzK1gNiMKQ02bTve1d33H3/03332++cfr7rxEcrm0OdOjQPerIkSPmL372G+9rBen3PnJ6Oa1WfHXLzibIq2K8UUG/P0A61MKFSQQLg8mROlZ7KTQLTG2bRMICBd9nATA4v8s9R6HgeSDpYPnyPLqrawiDBEmaIrZsIKXcPtb4I7ZmSWstJIGl62F0ejvXfCk91wt7snYOAHBs/7WC9DXQEeElDMZrBemLu8Thw0c1E53Psgyj9TrGxkeQphmkFGCAGcyCwEoIZJZQLhWRZgaS8r+P4pSDOGLPdTlOwaVyjfdsnYQQBGsZQRSj3R0gCAKUCi7mu8AbXnsrj5dd6MyykJJbYcL9MOE4zfjTT59gOCWoxlYxf/p8VqP1f/7cnxx69x0/8OsZP3jomrfhX7Nhfy2fVA8BBBy1Dx66p3zs9OLP///b++9wy7KrvBd+x5wr7rz3ybFydYXOUWqFamUhFAiqlggGbCzJGLj4szF8915b1SVzffmMsT8utkHYYKSLBepqMEYBSXSruxQ6VnWo6srpnDr57BxXmnOO+8epkloN+IKkFlLV+j1PP+fU02uv2rXmXPMdY8wxx/jDL1+kuUaffvj1O6iYyZLwCnRpqYpqswvDQBQnCGMFSwiUCjk02gM42Sx812HHsth3PShjWAjJFgmyBEEKgdnpcYxMTHF/EHIQKyhjjFbaytrWmVfdMPUR17ICNgYjwyUMlwuIFVDJ2yLq9xrHL/aWAQAPHEwF6VpcMNNH8Mq/6HGcLIII680OYAhCCAgSQhBFnmVddB0brmOztF3Ynofx4RIIbABQrBRHcYJEG2hmsLCwe+s0FzPexj5RGCExisMg5Gqtzi8eO8ulnI8337U16SojbccyCYN7QYQkSaDZ4MSZyzh2eo1One7R3DOPy21D4e9+9jd+Zh+94aDiAwesVzDJgb5Hx5C+x/8NfyMm74A8eBDmxKX2ux5+buUOR7K6Z9OQvGNrCcfm2pCuj84gBEPAsSQSpcEAihkXhYwPbQxnHMm1tXW0O31YktgYhmNbKuPaIREIBLSabcTaQAqJKExQbfVNrJTIuvK/fPKrJ16Ukur5bAbLi0scRhqV4TF2zADSy3W+NPza7rU9CqkgpbxC7L/y07XsulEa4yND8HwPQRDAGE1CiIFtWY/3gkgMggjSshGEMYLBgC1JlHGceQIrZiawQZIoBInB+EgJY5U8AHBiNGulESmNy4tLiBLmvnLlB/e/Yb2Sc4/EStsZS5hIGQ6jBIMgxsnzi5hbWAX7BTp5wejzX3ncv3Wz80fHPv9v76CDBxX27xec1iZ8eWjhWp+r4uGtMP/nj95UfuzY+j+1LWn2jmewa8coOoOQZH6Iur0AK2t1hFGMJI7ARsMiYKqcRdG3USnnkOUeuo11xAlDazZRHMucaz8mBZ3Kuq5wBfHwUB4UdVHMOHA9lwdxbBugOjyW/+M4USTANSLC6MgIF3JZyGSAQT9Bu9NvHfpXvxJf0aPUQ0oFKeWbMrGZVrXRYKMRDPrIeg7nsj6YOQFhNUoSSAGE/R5PTY4yEYwUJD3f+QoRupYQQikNYVlYXm+jMjSEoazDAGCUQT8IUGs20Or2QAI4fmpe7dw8OvITb77x9/K++3jGkg5pY5QxaHY6uLzWQK3ZQ70VYmL7bnHmMifttaVxb+30Q3/4U3fO0KFD+tD+NPPurxCla/bE/pvvgDh0CLpej35u82TpzjffMhY/c6kl7to1jlqbQU4WS6vr1A9CBFGIfhAi6wgUXIt3z46wYcOVUh4WMU6evgyQ4PZgwFGiKOt5n44TnRAz8jmXx0aGkM/lUF1ZISnIwLCwSTzy4vn1S7YlGUShZoZl2wAEbFJcyGfRrG+k7R1I161UkFK+eWKjq0IQfN8jaUl4toQxBgCUZVn1KI5NohV1um10Guucz7oMY2AJWiTmJsMgiiNeWVlHLptHsVxAOe+BhIAB0Atj2LYDgGBZkjqB0SpK/B966117bc/+Uc+1FxPAbvYCM4gUNIBnT83hkadO48ipZUzMbpYaCLfsnd38tp/7sd8+cGCftX/Pnlei8kZq1X4X8uD+/eJDR5H8l59/021vuGPzL9yxrRIfeuycHJkaxsRwFusDyZ1exGvVBifaACBoo5FxLM76DnZNl8GODy+bQ6INlHChibnZ69tEWN8yWngiSFRGgTe8/ChGHAZorK2jVMiSBJB15BPaMDEDxhgzCEO0O13UquuwbRvbds2CVBACjAcOHEgHLRWklL8th6787PV7fWZiAUNsDCAkG8NghpGCu0IKI4RAsTKCZquNkVIeQ6UikihpMLDSHkSAsLk/iACSEAxsHq+gXCwim8siShQGQYh6q4NOtw8vkxftkDAxknnbphtaS/l89gMsKe4qQ50wZmUY0nVR7yeYX49wbh0QsbDaS5cjVb389re6ldvo4EHz4P7913vYjl7289pz+xj0vkOH9P/x028c2zLsfawbqsq/e+gF88R8V/yj/bfjzHwfpdFpjI8OI+M6sG0LgzCEANALYh7KuSh4NoYnN2P3jTdeSdMBBqEy/UEobCn/4pFj518AsbaFhOe6KOTzyJXKVCgV0e8HwrUlD5W8M7TxaShmEYQxjDZssWINxd1mA5akPgBgb1qHMRWklG/aI/BdJ3QsUp7roNftIwxjIgIYRkiIHoDIc33atnMHR1pQs9ninO8gjOMBE12MYoXVasMYklhYbUAJB5OVHLKeBS+TgTKMRGn0ghAvvHgKK6urdG6hpYr53OyP3PqWe08uVj9X8N1/KwiWJYQRlsT8ShXr9RZ8z0auPIzTa4IXLtSsP/qvf7Fwdm1QZWY6kfZMutaLatIDDxyg9+7f4+wsid+/MNe46eOfPhY+u9K13veGXaC+Qh8FTIxVsHB5CYPYoNfvw2gFKcjkM65101QR7SDheqsHIYBatYEgCJgkgZnhSuuLlpRakjDlQgaCAKUNuo01xEGfg8QIY0xQ9r3lq0+cDAvfsSGIkcl6KJfKkI6DROnopYZeyve0oUepIP0dYfsZThIFkhZmNs+CCBAkIEgARC0GqTBOqN/uYHR0FCwE2BgwULAkLWij0en3ICXQ7/Zw7uIqpseGkXfExnkmAIMogdYGfjaHTrdH5y+t6Xar5756z8wPA8A9d27+z7aUDc+WtufYTFJgca2Kk6dO45knvoLHvvIsPfL4OXz62Bo//MXHXSLitKvstR1q3CgPdNCMNM1P9vvx249eagadmKx7to3j3fdsx6UqoxfGWFurb7QzubyIbn/AjiUMQHK4lF/NZb32pVogm7UVri+cQRD00AtitDtdaUvRn6jkHv/pf3ibnXFkPu97CAch9TsNdFaXYXQCYwxpQ2ESJO2rD9qypBdHEXK5HI2PjmLQaXOuUECuUq4CX08WSkk9pJRvgk6nQySlUEoj6PfguDZfMREMGx1b0iImYG1tHYV8FoJ5o8Aq87hnW+vMDNd1sbK0iu1bN2PTDXtgEcG3LYRhCCkFoiSGkAL9fgBiYGhoSHS5YEbGx9//7993y+aPvP91yxnXmusPAniWxWOVEmanJ9CPDZ49cxmnlhr06589Zy7Xg80/+hM/9Omzn/3VaQB84MCBayk8koZ6XsL9hw4ZAORZ9o88eabGR+fqdK7WpT2bh9GLJYzl8dT4GNaqdaxU65C2w9oYGMNkmPrFnPcgiKxBpHHH7buRzefRaLYRKsOdQWAJmPkzv/Fb5x7+H6fLnuPkVRJjcmIIu3btxvimrRxFCRQz",
		"elGUjJWtGAB++wO3255tDUkChobLyOYyHIUB2quryOXyrXTUUkFK+RYXwIwrbaMVXMeC7TiQAElBuFLODpYQcKREs9VCfxAi0YaUNlDAmO84kSUIg8FG/6Nmo4Gg08HIcBGjRRe2bUHS1V70hGa7g1a7CykEraysJ4jC0Vfd96pfvPNDv5OUi5nHlWFqNBp6vVpFpztAvRfg+aUmHj1bw9bJsvi9A++P3vFDb96e98R7APAD96Vz5FrkSqYaH/jBu6fWW/0bTy03ebHRE0ZKbJ4o4ff+7Cm0uz3Mzk5gvdZAtzdgA0ar21edIJZM4k9umimGthSF0ZFKksv4lMsXUaoMI0wUh3ECS1onxPvep4M+VSwpCrlsRnueD993MXfmFDqDmFu9ACRg9m6fFgDwx8eCvGGMWLYFgsH66josy0ZpdBSDfj8tpnqNRxzSxeY7IvuODWbhew6iRKEXxBBSsGHOKMZwlCR6MAgxNlRBZaSCXMYlz3XBmrflc14ZBOSzWeF5Pqq1NSgGdt+8F9srNhxLQANIDCMIgo2q4O0ellZW6cyZJfniyYt6NCd/7Lc+9MY9WyfKv+a7zpmlesdbrnfN6eUaTi/VMFYq4mfffS9+6LW70VhdpTOPfJ6DtXkfAFA9mWbGXYNcDcc+t7A2cvRiNXe52jYWDH3onXcgGEToKYHxyWksrazxhcvLLCwLg/7ADGIlFXO3UMr+F4v4NhY2PNejbDaD5vICqtU6wkixKyU8x3qCmeH6YlZKkcn6nhFCoNcboFgowHU9rDW6KPqOmR3emG4qSHwQecV8lovZHKSXRT8I4PoOkjhMBenvxqh+JSILnArSd5irsW6LhMMghEEIrRmxYYoTpQEUEq22EiHRxkAlCmtrNeRyWSrmfDiWNc0kpwjQidaiXCjAkgLVaoOC2ND26SFAJdCa0Y8VBlEEbQwUM1bXWxjbupNWqz1tup3Sna+65cAjz85d/om33vLmTN7/fJ9heY6lN48UccsNm1EZHkZiJFaqXZw5eYnOvXAiBoDHTqxfS2GuVFxf9iz+7Mj8/OXGYKXaDaTjOjzmSbx4oYabdm5GrlBEsxPgxh2bMVzMszZstDGWZ4sH/8Fr956zLedGshx2PJ/ajRaWFxfRanbhWFICrDxXHgGAVjcYA4g8x2LWioRlIefZEBIwxoCMMReWGgwAg17gO1I6koQp5DMIBn2EgwgaEq12EKfD9p2P8PwVv6chu+9lyjmrnCQxVestU6mU4dgWK6UYgBXG8VbXdkUYhrxSbyJhCQJBEIxtWxkYMQRASWnDdjz0+wHiOMCRJ1/A7NQMRgoZGGYoYxBpQ53egLq9Ac2vrJPv2RTaRXlhrqaWTp78wV96561v/Df//elF1qaetQQyluRYGzx94gIefuIYDj83h95Ao1gsoDI+7AFpVeVrNmR3ZW/wz/7lD267adNQsZewrrYHaPZCjE0MY2l5jT/3uUfw3z/zRZy4tMT9IMQgigVAsdbqt9x87u68742tNQfx2JZdND45i+FiEcNDJQZgacONnFu6DACx4s0MQhzGnC9sdES+vN7Gxct1SCmhlJGtQWIBQBj2sq4lPNeR3Ol0ybJsFApZ9AcBzl3uDADgUJpm93dlwL3iopQK0ncAHetNuUwGmazP7VaLBQOOZUMKobWh/dqYoi2lLhaKJL0iglih3wsMG+NFcTxpGCaJYxoEAzCICrk8al2NxaU63bp1YmOmEEFpA8u2kSQJDBHOn7mAoYnNaFsl3rp51N67behfABCWFBcGytB6PzLr7T6avQGa3R46QYJBbDBW8lEq5SbSkbuGeeygAIBHj5x7z73bhoY2F9xkaihPN+2cxtxSA7l8AblshruDkM/OLeHC0poJ4sT2HOv4IMGxOIk+WOsMRC8RGC0XEAUDujy/hJnJcY5iBa303F1vHVomAiCwJ++7KBVz8DwfrXYb/TBCeaQCA8MgyknXywFAaMyolCID1kZrg5nZTdRp94kMMDs9Gn5D6CHlOylK35EjEKkgvYJs9EQisKCbEq0RhiEHUYzL1Tocx4YQAlKIjO+6wvddTE2NgwGE/T6mx0qwpaR6u7c1UZqU1mwRIeh24ds2so4Nz7Vx4/YZ2IJAAIrZDEq5LAxt/PniUhVD45N085vfJc+t6+TWXeNv+KOP3P/ufNb6jaGsexaALwGdzziwpIXhUhFkeVCGsXju0m6AgPsPpXH7a1GPrvw8cqlGT51f55VuhFt2TNDiwgpIEjXbLXTaXfiuA9+10RuEzEYj6zmf+CfvvuuWtbWVt15cXE9+4G2vl/35Uzh97HlcrnYQJ5o7gxCR0Wf+839+Nnnb27a7QsgbhgpZ+J4jLGmhUilh1/ZNcF2H1lqBztgym0TxCABoI3aHiZJxYth2LGquL2FuYZU6rQ5uumGcUz36rvCUUkH6HoQAmP1vvr0YKn3nII7ZaCXq62sIgwBBEBDAZADjuS6ZRNH64jxcSgAi5D0H+YxLnSAYB0HGccTZXBaXltbw9Fe+jLHJCURsYdtwhnZtngQzY3psCJViDkurNV6rt3jTzBTn81l4ZNDuJOxKw/fePPYDp5e79TfeMvVDJU9e6kfKZgPjOhaMYaw3e2Igs9i8Z89t/+EX3ztOADOn6dLXGocPbywygyB5ZqnRJ0VC3HvLDKqdAYZLeR4u5LFl21bavX0L2DAsgiQGijn/tIfgf9VJYodhaHQcoVyp4MypcywIaHf7aPQCDOJ4EQCe+crqFt+xtmZcW3d6PSJJ2DxRgYl6GwdnLcm2JeTltXYZAPphuFVKifHhMhIN5DJZ5LM5jrWEXy5faY+SStL32DqYCtLfNfuvPFu7E94uCZtdx1GFjCscW2Lb7CQJKUkpLbKeJ1zLQsZ34VmEQbsGTxqK44QsKckwW1JKIhDlMi6GRob51JkLiLVBdnIzzpw+hx++dxcxQOcXVlBvtVlaFhrtLlZXVnD58mX+wqc/x1um8pBJQmeePe0DoD96/MKJkbL/Y0qIQbMXUBzHHOoY3YGiuWqisllvdFNW3w4Ahw6lhVavQQwAbN1RfFQrNb9lKOtQFPHz5+so5HK4be8OVNfqUFqTa0kmZitW5vD775nZlbXwntVaL960ZbOc2rKDhsfHkS0U0e6GMORwkGhI0DkAUDreO5TPFn3X0dVaG4MwATke2rUqZkYLGMp5SAxjpd7PkiAEkZ4lIVHIZbF50wz1+l1qVFcw6MfotWL3a7GHlO92EaJvxrtKF5pXaEDW920MSKTCNzrSsmfGR0wu46HZCcgwIU4UGMCO6UmMlPIYBCHYcpHLZ9Hv9ZBoDc+2CABlXYcsIRH2Q9y8Zyc6UYLLc3PYuWMLLN/H1rLE7qkh1LsDnLwwDyklbt65Bd3eAH/66S/is19+HqcvrOE3H3oe//Q3H7vIzADDPbPcfUIAfzRIlAUIvd5oY67WpiNnqxxrC5LUbQAwcm1l2qV8faGQhx6+2B4qZL9ERtHl1Y5OSAJgMBss1+s4c3Ee0pIiVEZNDhW+tHVm5KfLxSxlc1mMTG5GaWQE3V4PwyMVtLp9btSbtGl8yICoaowhAb65mMtAKWWIGDPTkxgZG8allTYuzdVQLGbRDWIQSSMABHEyzQSsrFVpeWUNpdExTM/MoNUOsLjUGEqH7dr1jlJBegW57/CGBZoYurNSKYOEpEw2R7ObppHPZQAwsq6LGzZNozsY4NJKFUdePEvKMGkGrTfaCBMFz7YxWSnBsgjNbhfrzTYmx0c5JBuDXh9vfftrMTxSxNaRHACYRGvUWl2st3pYqDbx/PkFLFSb+JOvnKbfe/QsLjaTVSJiAIYBGs3bH5cMHUSJ7AchSAhYlov1pVWUMvQqALgPh9N9pGuQfVcs2VLOeUoZRqsXQUoLlUoFl5fXUWu0IKVEL4xloHVjqODNPne+uuviWj/pJyQGUYgXnnkGR184hufPLaAfRjh1cRFstCnm3JgEcd5zbrxhyzSEtCjve+Qh",
		"xsknvorGeh2BIeQ8G0GikAgxmBzKb7Mt66ahfE5vnp0UnsWI2m2MTm/GybkqNs2Ob0/9o2ubVJBeIQ4C5i1vuTnrOvbWhfU6hONQvdOHVgrtTg9BGFHWdanZbNBgENDOrbM0UirAxAlet+9VuGXrOMo5D57rQhBhEESwLAv9MMaum29GpZjj06fP85GnXsTM5k0YrWyk2/bCBMuNNp46dYG+8uJ5vDC3hBfmlnF27jL9yj94rf7jX3nfLx7+6AdvB5AcOAD66be860nHFs83un1LM8xSrcnr9RatdWPWg949z/7Gz4/QQZh0H+naY/RK5lQEWrIdB67rUqgMCyFweaUGKS3EiTK9KAaAC9Dam1vviRdXBtRXALSixGiEgz5e+/pXozI2glo3RK3dFwXfT0YYuanRyp2uYA66bXrzm16NdqOBY8+dwPbtM/B8D9VaB4kBev2kU2/13pT1PG+okFPPnbhAfrYI1xFYX1+hdqjR63dmAWD//gdTA+nvwHv5Jjzwv3UyhJWOyytHvKToheqK0xqEmJ6N0Bk4WF5eQ5goGiQJgijG+flF5DIZLC6vYpGAQdjH5FAGg4QpCGMEseZqZ4DhYgaLazWE2mDLRB/12joWFlbAKuKnT87RuaUW+1JcDLSZBSBc28JoOUuzI2Ueyvt4/a1b6Wf+8f3Knpmdbp87/k8A/ARO7rcOHnooLnj2f28G0R0gsO+5qDd7dPpCXb1qkxixMs13Avivjz2wTwKHVTqq1w5XPY2VxqBRzrgmjhSFykBaEo7rIEoUdweBYQaGMs6RVj8MWoHC6FARnuNQGGmEQYTBIEZ1eQmV0VEM9WKsXFoBWTIsj+Z/YHKkPGvZIh4p5sTMzCyO1Ruo1psYHy7illu24UsnFwUboyzbbuoofG3GtWELounRIezetR1KAhYMLbVifPbhJ2eZL/tEFDBAadfYb1kwvuvunQrSKzcg4vDJk72i43xBWuKDL565wFJIDKIIsVJsjCFjGIuNNrxuH44lMTU2hK8+fxaVYgZrzS5q7QE0M613OtA6QXsQ8tzqOqJeG6VCFqeXqqi3+6bZ7tkF3z4xXC4eXq23f250uJJMlgviLffswu17t2NoZBgSjGce/QpNlgSfOn62uvE1TwBgWGQeNsCHQ6Vlkig4jkQ3AkvHgeeIfwjs//hjBzcKcX4HJnPKd3hRmqv1atNb/b42nNm+dcbYjoNSKQ9eqXKzH1DOkXrnxPDD7SDi9Vb3l+rdvsi4LgaJwuGnn8cgSjA9XgIzca3VE2EU93O+74QJ/5zvuQADSiswBMZmtuLYM0epODbNVq7EQ/msNVbOrfaCnlfw3Lt3zIwhn8/S5NgIVhYuY9eubZjZslW8Qxg9UU62LfyP/3gXgC+BDxDoYDoPrzFSQXqFXeLJodzT59dbH2wMwr/y5WmHIVrBxu/LrQ4sIpxbBvTGFhSGh4ZQKOQxPzePTJJQogxXX+hBKYVYawDApqEcpOJLhjBvEbFOYm60W3z0xfN0aWEN42PDFPT6/Pobh3Dx+Tla6QzOAsDKRZ8BYOdQ5tyR5e5anKgZw1CdQUCn52rixpmZZOsO51UnP7/rTXvedugLBw7ssw4ePKzTob22cF03HC1mktLQMFm5IgkCqo0OjDJIDMuCFG3Ls88VHOstS+0Bqo0+HOrRxdUa9Mas5n4UQRCx0dq2pDyXzZCaXxnsefbMnN53+17atWs7zl28BDUIaGJyAl958nlaXq2xm82h4LsqjNUOKeSk1kaNjQzh1pt24LljJ/DUU0dpcnqS3/GWV+tN+a4TZ4s/COBLwN40hJwKUsrflAMAHwSwbWL4HYWMj6XOAEPFEvZum8Vzpy9gqVZHbxDi7t3b0BtEqLW72DI+jNffsQsnLy5gfqWKWqeHaruNKIrg2hYsEKTnkmTDe27YjPGxYeydHRLvedWUfuGFM+/43PHaqQe/fOJiGEbbhFbJyYtLVMhlUe304Ts2HTsd0G2TLu69e6aGh87hR96Z4985CmzfvTl6ZvlYN+v5IGaOI0XlyTwmtu5Ul1cW7NPPHH49gC9MrvTSReAaZOdEzp4YylsJE2prVVSKW6kbBEwC7AsSABq+EK953c7Kv9oz4vB6JEjDQieIsbBSRaMzQKcfMhjCs2V3olQ4IBKqWpZ0e0GM58/OY6SQpcNPHcfkUBGbp0awWOvA9jw4roUk0dK1hQxi5vm1BkXPHOdeqw3Xd2jnDTtw+PHnqduN6bXbLMzMeLtBBOD+dB8pFaSUvyknr3hIl1ab82DG7s2z3O4H8F0H+YwPAsEWgpMw5O1TE/SGu27FaN6jsaEc7r5tDx5/+gU88cIZrLV61O31+KbZccyMDiOfy/CdN96AO26/GYNOG6pXh5vNaj/jOWE/iB1bPB8rtc23JLuOg0I+C1tYuG3XZhZBE6WKj5FyOQCAsy8RmKwtUXBteI6NjOdAG+DMuctSNy6a3/rk0WcB4BO/c/R6C5HQy8Nb15jRhIMA7to2lRGCvFqnz1s3z+LshTkMBgFUFMEVIAEOc658x0q1W5gcH0letWVGPnmmhjdvn4alQ9RaHTz+3Hlu9AK72mit3DG99UtUDPWlavNIpxfcW2svGGMM8p5Di40OllsdLK01YRgYKmQQxkljbLh49MzlWsDgfD+MuNEbYLiYw1q1gTgO8ewLL+KFpzp4213jBBCImJCGjlNBSvmbcXXDeL3X/xwM/kmyvCYNMz/8+FHSYMRhzMYwzi2uWK3OQPX6AV2QgIBGpZRHvd3HxZU6MfNACiFWGh03VobHhoewuF5H7YtfxvFT51C0gds2F+jUUh0Xq43nM7b1XDsJf7g2CMjzXSjNkALs2gKe8JH3LQSDvnzpovvT9/5g9OdfOdXSSiMIIrT6A4SLK3j8hVN0y5SHX/zHb+6//988jPv27cPhw4evNyG6do2m/fsJhw5hKONOza81ncx4Jel0uuL83DLABgRGJZ+BhuH59ZYIooRHO4wTVc1DlTJOnJmn93/fXdzvdFBthjS/WuW1WmPoueVLow983z++/NiRX+83wxgDtRHlDfshqv0QF9ZbAABHCr7c6GCsmP3M0+eWXxzKek/X2r13KcAst7pSLq7jqyeA0YyN9UFCWQJr4k+BzXUzRqkgpXy70ABodsfuR5fPn3nCsLlXSivOl3yRJDGa3YFgxSFJ62K129/t1Bo8VsyhkHEgiKC1NmGibNey/0RKWq/1Bv8siJMk1iwcS4CYESUaBdflC9WetdwI+w55J+4er8w9fOniqUSb3b0gSgrZRGhjQJaD4eEczs2dhVNwGQCWz+QYgHzDwYNq52T5N1ar3Xt6SZ8uNNoAQLduGtU/9d477Ft3D38//g0+f9999+Hg4cOpVXqNsGd948Bz0Xe2h4lGjmCGhspidnIEq2sNtLsDjOZdWFL0Eohzhpm6nS5cP4NYMSaGy/jvn3kMJy6ugh3fzK+sWWGinl5Zrp//+f//r/39Ujbzlm1TY8mOrdOi327Sls3TiLTB0edPI0g0X1yuW5VCNpmq+J9cOn5Zerb0ds2MIec7sFwHK9UGto+XsG20wLmCJ7bv3GR27N5+5M//3r8GHzjAdPBgOoipIKX8LRBHjx5NJov537WkfLW0hHEkEWDBklIkWvc8z/1X/V7wm+1+MFLOZ/VwuUDDRR8r61X2bAtBoh59056bPvnZZ5+9X2s9bYzWQgjaMjUOZgPTr7HnCJqdqJw7/fCx+aOEyLHkIaXxYcPMYIZSGomRGJ2cBdltnDl36S+FovKet7Qqe7BZ0mgxC62B97/pFqh2H48/XhUAcN/etFnfNeUhHT7MIMLiev2W3iDEtqyH4ZFhPP70C+hFMbphjBtyNsZLWXMxkkd6/SAMwsjJZDzesnUz5GCdn764hGyxjJVaW1Zb/YHj2f8/ZoVBkNwjRYhszza7tm8SE6XtsAVh67ZteNPde1Fdr+PY2QW1uLxunbq4sqNYxEWl9R2uhLlx2yy9",
		"7p5bYcA8O1qgsXKGtm0paW80Y7fbwZsAPIn7IHAQ6T5SKkgpfwsYANjix/uDoLF760zJIW0W1lvs2haiKOqPlf3H5gfhWUEY7QYhxxAUG+axco7sxZoi5oufefbowLHkxx0h//e852mljJUvFlAuZGH1mLdUHHzxxdWleSAkAJ5jPRYr8y8BFq5tI4oTNDo9GDDfsH0GGTcqAidw333AwcMboY/1VnuHJS2ZcSieLGbk5MQYPv2VU/KwCczW2cL/AID700Y011RY8hCgH/3wT3gf+8KX75JEiIKQ4jAEmNHtBwAbrHUj5PNZQbZ32hLUDJWe6PcHamJ8hKxIYqyUQSNRutkLHAI+0elHh8EMy5IXwyhBvdvHY48/D2U0lpdrKGVdvmP3LDKejZJn81dWalTrR34RRWoFfVOlHo6dvggyBhNjZVw4q3hipEgnntcI1y6hNFyYB4BD/yk1jq5JCz59BK+8IDlKriqt19mwzGc8tqQEE6CN0b/3y+9pWpZ93nUsOEKykBKL1QYHsbK01i0nIxeZQUO5zGdBUILIjpMY1VoTuWwWw5UCKiMVAHr16l+6fWbsdMYSdWhtkSBWykAIC4srDZAQmJocnQa+ManBc5yLvTBWg1jJxVobl5fXjVShtWc2d/wX3vPOLwHAoUPXpUX6HekD853mwIENQ+TZSxdvdm17W7UTKMdzRaNWg+dKMBsMZSy+3E34VLW/9Pbbd180QDdMFLpBBMEJPNtCwgJBpMQgjI1t0ce1YWIA5YLzRTYcCkFWrdVhz/O4OQg5m8tCELBWb/HR0/PWfK07yPr2U+MjUgfKBLE2otEbYGGtjnqjjTBJ8PCXnzW11VX7xHx74QvPrf35FeMo9Y5SQfrusOy+177w3W9tdzO+v97th+iHCrlsBkobaGbc8cE3G9cSL7LW8HwXWc/GDbPjcB1Bjm23c+y0APCdu286bgzPhXEs2Bjk8xlUq+soZDNYXl3D2flqFQCYYR05Nb+adeRJYwxanR43u330ul0Mun0IPwsicQMA7JzIfW2x3VEpngW4FsaJjJUxIOLvu20K+27f9tmdv/Cb0YP790tcX1lN1/S/de/J/QQAtdbgrYk2nrAsPVwpI4gjVKtNZLI+bR/xePuQQ0rzkf/tY5/p+rbVmxmrwGjFjgU8e/w0Ftfbpph1rTCJFzaNZY8LAgOgv/e2H3xRSDrle65Mopinhot43e27UM64KOUziMLYLNY6ItH6q2c/9PNnnjr38z0iXBhECr4teRCEsOVGGjoEmamKhVtuGPnT//jI6fqD+3G9zcVUkNKF4tv2XenQIWhXyvUwimHZHjzbAZhZChIfetfHXQJfFiSglCZmYNvsGMq+C9eWoc5kQgD0qSee6BqYJ6MkQRwnem2timwmg0LOZ6kSlH0xAIBNm2AREbOQX9IMKKXZsi2srNZARFhbb8Nx/VkAuO/gY/rAledpnEhLQYlhACRRybo0WrShpXrievdwr8Vw3f5Dh8y+TZs8EYXfLx0HN+3aSq4Esq6N0ZEyYDTvHs+4Meg8+/4f/Ysff62XyziDcs5HLuOj025jtOBisuxxEAYQREeOXe60GJAA5Ec+/vGQmZ5hAxTyvpEE3Lh9Eju3jMHPuFxv93il2YclrU/QwYNGiI8YR8jjbAwyns+JMWj3Qtx2y2686pYdlHMJO7YNPw6A9u9P+yGlgpTyLT3jKE6qUgi4tjRCSni2pR0p/FPHjhVhaEEZrRKtaL1aZcuyuFDMwYZRnudpAMTMkCQeiZIEmYyHXi+E0ox6L0EcBdg0nksAYLe9nQFAa/pyrA0nxohEafgZHwlZ1G70YZQeY2abQIwDG19yrDiWaMOJa0nMjFXMpuGsrDe7jblWdBwA9j943YRIrvnzLfv27ZME8GtuzN5cKGRur3Ui1QsiEUQhxWGEnGuBVGJ8i0lY9iOn5tfnT77Yc6WwEs0EP5PlTLGC0YKD0aKHINZwhTzC/PXHxswQkp+6Es+gbq/L9UYbM9OjaFbXWQPOIFbL0xPlz1+d375nnXJsC5FSsB0HjW4flXKZt26eloJYS887D4BxYk/qHaWClPKtYIzpBVEEBsNzHDhSGFuI0vKgPRnHcRXMsdZa2JbFKooQhyFcx5JxHAtcaaZWzPon2RgVBbEwzFhvNLDUjFCoDKOczQgAmC0WDQDk8/ZZAzQAWEmScKQStLoDYsfjXrs1/Ll//+PDG99sQ5F+/9fv6eccq+XbEmEYcz7jiPHhXPuBjz61kQN+/Zz6uNYXu6+N5Eg2+xNLzcBpR0qXi1kiIpydW0ar3YUxjOV6gFFfPA42FLk9I20bjU4fQgArq+uAAKQU6A5iuI449/JnmHGseSIklrQEmLG6VkU+nwWkY8gw5Vzr6WfPXF7BleQqMljRzIi0ISkESoU8omiAZr0uYMv27XfMrgAAHkhr2KWClPItIYUYxEpBCkmea5FtWcYSwu+HwaZc0eoppXUUxXAdG9MzUzRcLkErnRkMBu7VexQkGgLoS0EiVpqDXohX33MbXC+DSkb4APAj78wxANw0vX1dENaZGa5jod/tgQ1jZbWufFeMTBULOwHggb0nCYCQd//nJOvZJyQA17XN/FqbbdcWv/z37hLXwyp9PXH48EY9whMr/XuqATA+MkSuZWF+fhnLa3U0uwMM5Rzh2VK97baZ0wD4th3jSRCEJue7qBRzGB4aQjmXARsjVRyrku8s/qU5z7JrtGatDcJEYXJiBEopXFysoRdEKGWdZ5iB7VfWIWXMQFoWhCCKogjFXAb5QoEreRsgVcWrX934RklNSQUp5ZsTJMvqMTOCIIAwmow2sCXBImxtr/cDEKtcNkuJAYyOkHGIHUmZxE68r3lZdq6pjWknWglLABqM2tIiHCjYMKWXWsGfOnIksKVcjeMYWmuTzeUgiBEmwliuKzIO3/3S641h+K74gtIaSRxTb6C430/sd79rj31d+A3XD3x1UX/kxGL3yPllnFtYw9m5FZw4N484itAPYx6EkbQF2uer3VUAOPlM1diuS8VCFp12nzZNj2O90eN6J5JZWzaHCs7qyz3MOApCGLBtC2p3BshlfbDRqBQz5Aqg7NmnvsF1I8SSCFppZHwfruvi1KnzyNsaIlNsA/ujVI9SQUr5djxo4oSERKs/gE4UpCWJCPBsscPFhLItOUiShJQBhLTgO0K7FhXz2q1cfV/f94EPNJXRtUEQIU4SFiSwvLKKXMaGbckxAKjuHWUAkgSxa4tTidZQhrjaaPHS6ioanQAXLtbhebgXALDR7MwAwJYd5Uc083KrH9iu5ysFyohWWACABx44kK4D1wj7AQEGbpkpLMRRhDML6zi7sIa1Vh+dUKHZj/niWoc0iVM/+JqZ5f3798tDJ0/CsS07ShT6/R6ixiqMjthybCiY9o6pTOvlf48mSpQxRiUaWc9DrDVs1+Fs1hV5h+LZ4cwaAGzfftVq033DRruORXnfQa3RQrvX56jdgGO4SySuNopMzaNUkFK+FcJYKUsIsGYYMOIkoVApeJbY6W81ORgE0pKIoghhlFA2mzV5z/I8FzNXX9ePfOQjRhtUEwZipTlJEkzPTJESHhqdwRBA2H//leQDBizLPg8QlNYIY4VOp49Ouyuc4WnOjUzd+1sfeuMUEfGBAwcIgPzCVxZWFIlP1joDq9rux/1AZ/u9ZAQA9p48mQrStQEdAswHP3iHPZkXO4YLGWyfmUA+m0WkDNbqHaw2e6YbG7yw2HvyDQcPK5w4ITfWCrKJBAr5DAa9Drq9EP1Yw7Os/ptfc0fwcg8JcKCZudntA0JgcmwUq8vrYGZZycjBtiK1ACDvbHzGJSdxLRlmPQ+uIC4Vshgul1Ap5SCB9satU8MoFaSUbz1OYhLdCwaIlILjOsh4DoUacGxrRzFRs0wIwIwoUbhw7hIWLi/x+FCRPIhNVwVpYzkRNdtxkSgNQYDtZagwsQmWtIrAbudKF00CAMN6NWFGP0pICoLr",
		"u7AzPlUbQUJ2bvSNr931egboPjy2sU/ETBlP/AcNbl1cqdnnltrkSHv4qlmd8r3PlQOxnF9q3rDUGtwUsdRhFJAxmkv5DM9MDvNIKUev3V7BjbOjLwDAnv0j5gbAFgLZfhBhYmQIYauBIIjYdR3YAt33f+Sh+OXRtCiKLAZodLiC/iBCHMWoDJfArGl21O3tHaU2AGDvno3FyGKbAcu1BHueS8EgRD9KsNroIevRAABwKDWMUkFK+ZaxXTfvWhay2QyfurAAAkhp1o5tjQ/57lYppep0ukgSDQOBZ84soNMPUM7Z4wDwtagGoR/HEaSUkAJYrzZx6sRpZGxZ+clb7AwA7LtipWpDgdIGUZLAkYQkUmj0QhQzWT755LM4+sSJNxHAjwHAAfA+QFY70UXbpl+sDwLn0nrXWlrrDQHAiRPr6UJwDfDYYxvvfDlbuH2sVMyxMVppTeVSDlJKwLKYCLJs8eD2Kf8FAHjggcN6akelEAdRmRkYrhSQz2fYsm0kiYYjKXiJW/S1X4XFnhRCZGyLi4UMgkEXuYzPpGPU21HzRGC3wUw4ARAIQWhyyrALgIeKeWzeNI1avYtqK8KZuSoDQFq9KhWklG+Bq45F0bEmfduCIwSRJSEI5EjBp1c7sjaIb2A2mUwmgyhW5GUzNDMzCUUCOWdjb2jqivXJBjFIIIoSSCmQzeWIpMCWTSPF6TGVxxVF2lgZtBBEyLoOEqVh2xKf++pxNINYQNg8sX37m/fftWf84EcOqwdPgu4DDDNkEJnf9YT48aPzrU/92ie++ggApJ1irw1+dnQ/A8BIMft2x3VhmFHMZGi8UqBiLkNxrOEIFtvG8kHfxHUAIAL7mcyUJTFskdCD3gBexkMcxcxEACh8yXpCVz0l13ELOc+xOr0BV/JZGqtksbayAgZhMIjDe8ZnEzzwAJ3AxieYuFTIeIAxiJSGZdkIgggTw3lECdvp6F37pMVVX2GuGnTVVicvLRu2bWFqqIJeEKAfxjxfbWK+3t02nM+6thCYnR6FZ9sYGSrT+bkVCKIbAFAVMGCGdCyEYQhJwPzyGur1OskwUmOeLuUzvAnAwmh1w9CwpVVUFKOQ8di1LbQaLcyODaHbatGrbtydjO/YtmlksvyeQ+8/+dGtb/6guP/Q7ygAzIDoG/OJfmg+8ehc6y9Zvinfs9D9hw7pf/aWm7PHzy7dPN8ENk0MUaINChkPlrRQ74RQCZm792zKFstDw8CZZRBQr3d2+Jm8JzyOmY1QcQwNQb1BjH6UDF56KPYqRpsSmKXruZrBkCSgpMut9gDDWTv8vv/rz5P9RBuCBEAyTSmtAWKenppALwhx7MxF3DWhsXd7uQhcOaCd+uqph5TyrdEKo3OdMMZStU4rjSbOLa2h2ukLIgozrrOmtc4xGFopLC8tgQ0L17FZEG7ZXCrNngRiEGALysZKIdEGxoCGKmVURifMIIjEaMnfCwDdeDsRAUbzjY7jwnUdbJoeQ6FcxE03bIblZvDssQv88J98lvuLi/cCQHf5zEtXFMbGntVVizflGuL5hZp3+PhSphsp6ESDiFBrdrjR7nIvjFDtx/qZ0wuy0+3mrs4Gx/OnXcdGosFDpTzW16pUa3RhGLAdK35pNOAlkjQihIBr2yaIEg7DmDO+w1EYIZdx60RkAMAHGEQgQbt924I2jFa3h7FKHjftmKTaIEZ7EE3xiw86RGBO52TqIaV8a2Qca3GlM0Dt7Bx810YQJQBAvm1psCkoIzzXdXh9vU4nozZIa1IkVGJ4KO/Ta9DCPEAIY1UQQqDZ7dH4cAnzK3WaKFpoDQiu474GwEfvmTqvv3CREMbqDsd10Or1cXm5Bte26PzCCr76wkmMOIb6QUQzY6WzAPDAwW/oBMvYaDCYcg16SY+cXq5vLftz83OrW/K+xznfY8uSWG93oQ0xETmPX2g2yVlcvGKQMBszls14sMklSYp6QQiVJCjmPHBkXj53GAB81xrXWqM/CDA6VGCVxGhW11kxQRHWAGB9H+joYagDr3+99fsvPnvLVKUAsKEnjhzDixkfb7/3Jhqxm5iYLU9+9dHPDQNY3pCkVJNSDynlb83VOpBbR0du3Ts5gplKkWcrZbx613bMlgucdaTnSfkmQbCNNpxxbRR8H7ffeQcKuRwnGgiU2QcAH/7whwUbrpTzecyMjaDW7uLzX3men3zhnFhuhVwfqDf+2j96y+jBw1AEIDDmQqc/QG8Q0sXFFTo3v4RWu4sRV+D4QgtH55poVGu9l33lNDR3jfLgg/sFAP7U//qun9k7U351J1LxUqsn5tcbWK630emH3Or1RRwnK6G0/peDnz55ed8+SAA0XMreHCYa3X6fwm4P7WYH1U4ApTTGi54DAHu+Pnc20rhtZ7sxBmGSsCRACAGGgDGMXsB9ALgSXuY/eO65zY4UuzWz2T07SW++ey/e/ppbcd9b30pvev8/TIZGx4d9X94JADh0f7pupR5SyjfD1ayguUbzqYztYtPYCLm2AwNwlCjqB3GcldaApbSYwSAJsl20mw1s3TRL9W6AExdXdjMz3f/qGdcAw65jY7xcRK3VYlIJ8tkM3XXPXerUc0ennv7Kc3cB+IxhRsV3H2v3g3/QDyLEYYSIgawtoeIQLrT41x94C974pnt+avyXf+WjH5tHlI7WtT4ZN368eHZh3+tu3OwJvxwaw2K12cbCehPSypiSJ92bp/Mn/+TZxT/YB1iHD0Ptu2FscyHr3vbifJNZ2iQE0A8SKMMwMFCxyQPAlYbiGx4VQDu0nky0xsRIiVjFePLZM7hh6xTCWKPGOgGA9f6GUdzTwe0Z7VV6QRQlRPKrJ+YxVspDZJ6Bibvm1VMh7KGh2wD82WNpxmcqSCnfNGbjhet9sdrqX15vtmeK+bzSWlMQhuRI0krredf1b+wFIVrdLoQcxwvnFlAq5ZHLZZBAxPffT+JLx7N517GKni3BRtONW2ex64bNCNoNZIZGzI/95HugB423HHqx9hlBhCBO7rQAFPIZ+K6LjO8DOsFtu7bi9XfswA+981UYrM9ndLjRXyYNhFzrxtGGIj30+IXTGcdGPl/C1Mw4tsxO4LYwwCBhMXdpPnnDjuJ9b91dftM/+m/HHwGAvO/dy9pU+lGSjI3khYTBSr0L13Mp1AzXxiR/9uddesdvRgcAcRAwm4YzEybWNxRzGZ3LZsjiGOViHsVCFlnPRafbEQDg2xve1EihcOx8tVmdb/SGzq80tDGasr6HLz53Bu1Om95684S5cfPQKgA88NjhdDBTQUr5JmEAVruNZtlz/lgK/v+wUVqSsCQJFgJ2Ppv5/XPVxrQUuN2zrERdTEQzSNA8v8hXcmgffeghaNvul8putqyM5lq3i+mJUTRbHVyaW8XJX/8o/dhbtqPP1tdq30WxCgUBJAR8z8W2mQlUchlsH89DxH3z0X//2xjO4Yk/WEP/wAEIOoi0C+e17SAxAFQT/amwHf4y1QbWhWoL2ayHmdEKVuotOn25qlXQsV+zc2jk6udmSv7bl1shts+M8c3bJ1HIZnDvXTfSMycu0dLlKg9Je/Zzn396AsDcp++AxFGYMNB7BdGYLYUaKpWEDpq0trCGNU9QKe9jcbWe2TB/GETAYrc9og37ALg5CCEA1sZQOeOZnO9Zz801mnfftOVhADh8OJ2nqSClfKuihIznf0zr+IMkpGtbNsfcI9as+mHkOJYoKGPQiWLETQ1LECoZl2ZGy1olyc8uLNU/WZ7A5fpy9MxKvflGozV3+yGND5Uxv7qG+VqLP//cJfiudRIADAOua70QhgnW2j3RG4REAM5qzWurJXgUYVPZwmix8jngagfR9NThdeCti4Xa4OiN44VH6t3o+8NER2XHlScuLaHe7UNpLc/VwkQ69UUAeOvebTNBrN/seh7PTI6I4xeW6NKyh3v2bMKeHZuoEyhd67XLT57v7AEwN9LeLoDzyHvOvkzGk+VyMYmThPKuh5VmH16mh6FiBrduqUx8",
		"ab6JILlSVSTGa0q+k8tnvGhiuCyjWCHnOfzaO2/GyFBWbfbqhZsmneFf+jgu8IEDoIMH09FMBSnlW1kIllqtY6PZzJFE6X1EImISItHKMmwm8p7nD5UKICkwmvf5nfvugkkiOn7mAj9xai4fALnuZQqzFgadXgDNzI3BOubWajBsMF7M0g/duw333TL1Y/f/6p//Lpj7M5n84Ytxsw7mIWitkzghQQyjNU+O5eX2ERHYrnViw3pOxeh6YB8gDgOm4NuPJiy/PzBAvd2FFAJZ1+FeENujOXtp90xx7qsXe2j32jeutcyEETKZr/fE+ZU6kkSj0+tjdqSErGuZ5dVYPnmpvQvAZ+85fz65PDKSI9v8YCmX4eFCRowPFzFRykLqCAsr69SPEkghZh79yX3eGz52WG0UGabLbAwTGxrJe9g0M4PNW7fw6krV2CZ0lOZT+3/uz04DIDqY9kNKBSnlW/WQJADFzEfZmH1CCBBBW0TuWNGzT612vgzw+3dt3WyMUXKlWoMrwMfPLcp2L2jZGaypAcO1rJnhUh5hlJAGY6xcxKaxEX7Xa3bj+++dxCMPP5kBoD98AOJffaS55Eh6jBR+OO/aWqtEFksFZAtZrmSk2FSWvWOh3UqH5/ph9Iq3nmie11rDtRzkXAfGaIRxbCQAFeuzP3bf9tX/cnhJVsPg6OX1wVnFvMO1pN6zaZwkAWeXariwWEMu6+JyrU1nlBIAcBAwI0H31hLcG/I5X22dnaQoirHaIUxPjSOTcXFmqcWWMpMPryyOAFgEAN+yT/YTFYRR7F5crpooinD20jxfWFw32ys2bS5Zv3UUaO/fD3noUHokIRWklG8LjmM9z4ZhSQHbEhxqhSRWdyTQ/6HZG7z32dPnpACj32tj81iZXc8RkdL1yWylf2HQgGE+HEbJLZ5rm9FiQdx9804+v7CG585f5rmLZ3DkxMIRAOGhQ3AMc+zbzsMB6R8WtgULgBASuVwBwyWI8mS5M6iOhMCXsedQmu59PSGAliuFyRUylLUtjpVCaxCwbwuMV7Jn3nDwsAIgK1KUq7a0u7HiSGmcubyGrGtjMAgRG2YGbAgsStv9U2ycNuB2EBZsKa2F1Xo8CCLRH4Qo5rMoZBwQQGNjw+rMwlLlbJyMAFh473shL75QXKxeXFv3s+7mbi/QqlSgKA656An3pi3l8++5+5ZP/KcnD1E6T1NBSvn2he0AmBeUMV1mZMq5vJ4f1JTvuu/4+3fN/vofHj33x54l35fLZsJqN5S27EKQMK6UGW1ZPgMdTfoPGr3kg2JAdj9MzODoRvVjgkJTt3DbtvLJh8/XsBd7cBInkfXFs0FX61BpkXEsaG2QxAkTJNys0zeLvTgdmuuHq4kNpZyzHCRhbxBGvm1LJilpECnMVjzcPJmpHllsA4D2fe9H7tszvAV+Iaq3O9aL5+bZaI3RoQJsKZAog9u2VOjdt28JfuqjXwQAjBT9Y2vN/lq10x9xlus661nkNLuI4gSuY6O4sCZXm526ZYkGEXDxIsTI1mz3zEU0hBSbR4sFSEEYKZR426aMePWO4rP3HjzUOHAA4mCaeHOtG0op38GwHZTbv0AklgDIoVKec76XtMM4v9LuvCli/lUpKLSI5EixgHIxB82kHdsarzjJKAB0Q/WMYn6UDcskScxqvUkEpuGcQ/ftHcNwTi4CwJ6REQMAN273T0ObS0prSzGbZrfLQRyh2uyi2WzFkz/w98MroZbU8ryO5uHU+HA96zsNsJE61mh0+uQ6Fs2WPUwWrPrVi1thvLxSb2O4kMW7992Nf/Lj78FPvfs+/H8/8F7861/6AN52507T7UfD/+3Lx0eu3jsJ+ScqWX9ISqn62oj1fkyh0qI5iGix2eMTi3XRCdX/Xe3Gc7t3w8nlwH/+5+dizxIdW0g4jmTXdSAFYarswnXdFwDQA3v3p6cSUg8p5du4EIi1NfTHcnwkiZNdYRAaiwiXG13OWmZ3kiS/mlj0pGa+LwzjyGhfKGYNcJ6k2QHgOBiwBX3KteT3+Y6NfMbH1HARxmiSwoNh/6Uej/jCM82OJJxIDG9nEkYKIaMo4UI+i7XV1uAXvu/7/lIfm5RrH9mudy1hNQQnmyuVEgZrVRAzolhjtR3VrkxYulni4QvrncaFx54u7Zlf1rfs3i7OXJjD6ZOn4HmuqbUHzvx6/em5VnQKG/ukOjT6zsliwbp5y0RcLmRxcbVG9V6IYi6D23bMkGdCNDq92/vlbRZw2ACAlIKHPCsxhuFYNvuegyiKSWkJx5WnAXCadpN6SCnfXggAWr3Bf230+mZutSrag0BIacG15Ns+/+Nvyfai+M8HUQwm4nanh6xrs2tb4EBtvnoT1xXPKGMSKaUlpYBtW1Ca2bUlLFuUAGCl1yMAgsHwbOsFbQwAQtb3ECUaOd/DPbduiUH0VxVqTrnGOYrJRAgopTW0YRAIbDQlSqPW0z0AuBOwXlxoX2SYo5YlRbXZ4edOnEWt2UY7iHmt1eXFehuJ0h8DEF01cKNEnai2e6g2uzAADRXy+Nl3vwb/8h+8B/fdsZenSy6iIFSHDx/W973kO2nmjUwfYyiOE2Q8S1RbA91vdNavxhtTUkFK+fahAYh3A4dJ8Jccx3Ynh0qsjOHaIHY/s3w+ZwyeTJQytmUJkgKOZZFj2bBte+9VN2u06M0bNjXLsqRlW7ze7MIwyHVtuK6zBQAm3pljYKP8gu/KMwAQJjG5tgUpCL7nwnGkAoAHHkg9pOstZPfOdx7VtXZPZXwfQRDylTb35NnCbJvIxQAwsh2CGRjJeWeHsi58xzaebcGRgG9Z6IXaFlJ2c1J+/sq9DQDkHPuoVgoLtZZ44dwCLi5X8bHPfBWHnz6GP3vkCfrUU+cxV+v9HgA+eRhi9DAYDCTaWAkzBpFCrA2E0UIIimFRtKFHqSKlgpTybecQoG3ify6J+0EYylBps9qNvS++uD6mgOeN0iut/sAxkCwsm0hIBErfcmD/HgcAnXvd9zUcKeaVSrAR4rCoks+h2Q3RH3Q2mvQ99rU+ffClfckSlIAhtWEUPBdRpKCFzQDwQDok152n/sADYGZOiAhMTAAgpMRaN8ZSI1AAcP7KxUXPni9lPXi+R64tsG20hGzOZ0NSREpfHL/1VYsvFSTHsRYcKVQp6wnXtbmUzyA2jIsLa2at0bYV48L0RP6zVyIG+kHA6A9/WDDDlVIAMBiEEUaLnqhkZNTXG63O9+xJ9zlTQUr5dmMAyHqgjoRR8u/ZsG2TCIuO8AoO3Q2gIy1xPIgjBFHEgBGRMipM9N4vPrt+IwCIhx7SBDq7EWoRRlo2W7YNY7kIIlUCgMlej66eOcn51qIy3CQhhCUESwF0egGCSDsAKBWk60uMAPDvfOgOC8xOECcIghhBnMCWgsaKvnAlOQCw/coHHNtasQTBtiSYBGsQMhmfCYySZ1/60uHD6spaslHl28ieFBQWshnhOw5cKTE7UuKcb/NY3oNH/KeHT1Z7+wB5aOML8c7f/DcTDNrk2jb7rkOdTh+NZgt53+Vqe6NXS0oqSCmvoCjZif41S4rnC57thcqgH5qbAYAIjydxgnZ/AN91yXMdnTA8D/o9Gy89wzAvRHECxYwwSrBcbXKzPUAcqSkAVN561FyJz5DUTkMIqidKEbNh37EhAHTb/eKBA/vtNJX2+mP5jMrmPLeoDeB7LjFA3TDmsaKDmYLnbly1IUmuJQZaayhtMD4xjn5isNbsYyjrYWfJXWUA+/d/PexrhEi0MZrZwHUsZDybh3MeSvkMxgs2MjYew9cTaQgA1jrRuywhJmZGy4kkoh2bJ5H1XX3jjpH8a+7ZOw4ADzxwIB24VJBSXgEYADWATpKYXwKYEg2tGMMAYBQuW4IABjXbPVQKeaGFZWKNv/e2XcMTzIBhbmhmKKPR6HRBzJTNeJBSlgHY+x+EWd8HAgNlz9MEii0p4UiJfm+AbhAZwxjbW8kVAeBAmml3PXlIWFHdQi7jVQTBCBAc",
		"y4YlBRp9jafnax4AnL8StNOaw40MGSJOYiil4DoOZx0B10INANbXQV8XmRAAWFoShg1LAQxVCvBsaTmCBxLqLAC+6sFvfJJ2jpZycIl4tJynW7ZN0Otv2WRYx1YQDCYB4NChk+kcTQUp5RVCA7AaUfQXYP6PGpArfXUaALQxbd91YTs2tfsBfFsSSanO1AZbTq/0X33FxQqYARUnSJRCPuNQkhgM5b2xUaAsBLhahRAEvlyrFQV4lNlwEkc0PV4RtT4nS7Xu9M2juXsBYO+D6RmP64GrnozjeNvDxAwrQMUqoYxrI0m0kQS8fu/MDABMTW0iAIi0Zg0CBDA6UqaZsQpKng1ig0iZ9Zf/Hf2A7cRAOI7DtrBQyvoIo8gobcRYJbuweW95CfjaIV0+8OEDIjbGrncHOHZxCcu1Jh558jj/wcPH5ccfnet06s2LAHDixKF0DykVpJRXEAOA6mHyLxJlDjbC+GMAQMwXAURGGxFGCQDGSCnP3TBBwmYCBDAwKqUACYGc76LbD+mFS7WklM9O/cy7du9jBvYWpiUA1JLwTjDGsp6rbNsmx7Zp797ddP7iGp07frK48bKnTc+uC64kqj07t1ruhaGV9xxjC4GZ8RGMV4pY6cSYHcncCQCj1XkDAJFSlCgNkIBSCp4loLRB0WaM55z2X5rUzLZrS6E1M5jBxqDTDdhoDVb6wh/8xVr/wMbaQwD0b//qr26SUv6oZphaL5DPn1/CU+dX8aljS2Ilsta+7x+94RQAHDyYJjVc66QHY//u4Cv/EYBuxPzAVSOhlSQnwlb38wZ411A+G8+vrIvVVgf5jIvhnDu73IkBzXf4ngsBoDeIoEkiX8ry85ca2Dk79H4AD47XPAMAwhJTglg40koGyshPPf4cJnKuyNuxOb/aWgGAkycPpy/79aFHDAAnF7vnjUBnTFPWZLSJjUY+49JStYeHnrwcAMCJkxufcUg4RggUCwVcml/B9JDPsdbIWRKlrDUAgPuwD4ex0ThP2nA8xwYzw7EtxNogn8sxxQHW6t3jAPDYPggcvpIEkZehGZjeRCVfHh8ZggZoU8Uzt0w6NJK3jmEz4rRsUOohpXznhImwccqdroyJFkIcFUJQL4pMoDTGKiXOuw7CIBrZ/+B7pWPRDTqOwGDK57KolIqwWFFroHDiUn3ywIED4jfPnzcAkLVtpRiYqzXp5OVlvlTv4Jn5dXPTrTvFL//ST/sA8OD+/elIXAccuJIX8J6bJ3IjOdc/t9Ywz11apmdPz+HE3Ap7tkC54DQAYHb7lfCeLW1LEthoVEoFtl0HtW5Aa+0AirkDAI/h611cLcF517YcpbVxbQFLEGqtDgVhCCHoBACMjoKvRgjmq/3VJNHnm50ezS+vm7VaU19aqlpfeu7y/E//pyf+F6KDJm1/lHpIKd9ZUbpaUn/DqxHqQd/y/mk242eH8jkTRiFqvQHGcs4wDgFSiuNGm52J1tzt9zG3tI6g3+WlRhtJksytHj5oNgHOZSBJlN7sSIFSzjcCkONDZb5315iYyYjksS8frQPAofTM4XXB1YX9Uq09mChkuFwoCM1ANwjRDyLcPFvCTMHaDgB5Z8ODsaXIW8IGEcG2JC2vNpiEpEQZtomCl9z+SthXjCqlHSFEbEspLClYgoTSmgeJmQNwtbo8AxBSCFO0ZCtSBiKJudkfQA9IOMOZfxcAy2nLiVSQUv7uMABkL8ZppcJfD6PoI/1+PxBSkGEAzPlDhw7prC3PdlXMHEbQDKw1O1BG097NY/iF7791x+NfXbd/5+hRBQCOJZ5P+hGEY8RwpQSdxPzC+VX72efqL4yj9ywAuv9QumF8Hc0v+tJ8+9h0zj/ies695UIuHi4VhGf38fDJVXzhmH4UAJ6LNwRGGR5lMOIkRhzHqPcDavVDnhryYUn9l8JoRpspkITrOjyIYsp4GfY8V7pAo7ZWvQR8rZgvATCv2z2ce+p0bafj2QySKHjCfu22TOtHX7X5zz5/5qm05cR1RBqy+y5eNOws/hNAC4bhEAkwCS2IdhzYtyfHTL2s51Aln+PRUh4Tw0V84N334Zd/8C7U1qu93zl6lPfv388AMFnKPR4aXllpd+355RVutLum327jppn8Iw8tIti3DxJpte/r7b3XRPqheruHC8vr5uSlBT67VCUmYOemwrGXXtyP1KRmQAoJlSjsnB6F49qkjQaSv3xm1RiaSoyBVgpSSmhjIMGUldzeMeV3Xr7+PH2m8VYD7BFCxiBBU2VfDBectZ17RtYBcFqJPhWklL9bGIDodlEXgj5OJKTnOFoDYT/SU4/Ord6vlfyEUqrjWpY9ks/xVLmIpZUa/7tPfgUfe+zUnwJQJw4dkgCsI5erq4bElxRAQghjCYGbZvK4dVP+KQZwX/q8r8f5BQv4jG+LtudYdjmXZUmEPWNZ3DtblgBQLG4YRhByTxArmCSiOArR7/URBSHKWZdKGcd5qRYxQK5l7bKEgNKGilkPOlEcBAMopdRdxelvCL0RAGXMmz3bEnnPMdtmxrB5NM+37Z6IJ+94V1qhIRWklO+iRYM0xB9HSdLThoVrW6YeJljtRdsjRHOxNo+uNFpivdHS9VabT12Y59G8i1umS5cBwL9j4x7MABF/FQCkIOPbNjJZD3651AKAvaP7OfWQrj9BesvOmy65tjjLDOnYNmccyxQcwiBMJgDgyBGo1+4Y3QLGzUGiud3t0nqrTa1enyaGizxQhGonGgKA0SoEADORw7BtW7d5jg0wBBEB2Mi2i2JlArfKL/8ini2cMNFoDUIsrtb1qaUmnVoYfJHu/FCyf3/qvaeClPLdgAGAQZIcsy3xZSHII5JsmGGYQwAkBX3ZsSSEIGitebhc5lfvHMftMzkPAL0z2ENXX2aCOApAEZFwbbIXa/21ubXuGQA4ke4fXZd89MgRVXCt2LVtAGAhBPuWwM6x7F0AQAR2pHN3PuMOM6DyGQ+vu3UnCxIgBrqRQczuDgBY728SAJBE4m1Siqlixk1GynmSAGKlSRmG4ziZTWObPLxMYSwh+r4l4EliFYf25tF8O3GyHwXSgqqpIKV8t42PtoX4jSSOdRAOwAQuunIMABPTWQCwpBCRMgQ26BmBvhZ7AfDJrwsbjU2pZx2iM1GsbKMTDAbB2X/5J6fmAdBBpOc7rkNow+AxgWNZcCwb5UKOXlwN8PTF5g0P7t8vASDn2beW81maGS2bWBlMTkzgh97+WuyYGYPlOMgV3LtAhN78vAYA3/V/xLIkfM/hLVNjYAamx4dhhGVY0sgiq0kAeODA10tVERvl2xLjxWyyZThnlW3+xK988qlTB5CePUoFKeW7CQ1AVgfRX0RJ/HHPsgq2lGRooxpzxsKAwIgTRdoY9AehmKsNOCL7bQBye06eVFfuI+fnEeYc69+GykhtjJyoeJ8GgCsJDSnXFwxAEhF3I/3F9XYXl2sN7kUJVSODZkzlnXe3PABYarTzc2tNdPshupGizzz2DI48d5IhiUaGK+grc+PS//hw5iiQEAEg07UEoT+IsLBaxZnlGp47cxk3bJ7ADZsmnHo79Da+wtcLpWqGbdhAEyR0PNBq8Luc1lZMSfmutWRpDMgOedafFBy5POx5+wCgYIsfKzg2T+Qz8dahonr1tunkHbdui/7vf/wa9Qc/d9/7AODAvn3WlXsIAlB0xQc2lTL/+549cK7eO33E168xuqmS2110rXYl6ydTlfzgxrE8//idM4f3XTkSMuo7P+ALkYz4brx9uJRsqhTUcMZRe2dG4ju2TvGNY7ljv/bjN2cB4MH9+2XBtR7yhOCcFNGQ76hKxlW+bcXDWZ9vnamc+/m7K4WXzGsJAHmbfnUi7+n7dgzzT901/BAz6EBqLKekfHeHVwBQDhsVwTdeZPH3K77Hs+VCdMvMRPKOm3ck773nxvD794zxz7/1hl98iSC9/D4pKQBAzExjGfvhG8bKfPvsaHdrweWbhzO/ffWCu6aL/6zoWQZAWJCUFB07",
		"AaAAhALgXaO5/+vqtXsKqGwqZRfGizkuuG6Ss4TKO5YCEINg3vuabSeZj9gvF6ScZb1+POfyHVPF6tu2Zffi6xVLUq4z0oOx3zshFgLAPaB2ZdxU1hLHG2GkO2Es+rHCersDIqItoz4STVUAeOyvCNVc+d0gzV667r0kItLTRe/zOkne1I4TY0mBjIPo6gU5z5u4e3OOGjEbw5CGgLVam8uVEqbLPnblg92n13sAQP4OdNeOh3Obx4enR7aXWRmQJGD7pjGuyB4VbP0UcId6SV06DYB6Sn0pZ8Q/rw2SF48uDU5cEaN07ygVpJTvAVHCFQtVrAbqBU+IL7u2dV+cJJEkW944W6a7Jl1FNuoA8LOjh/nwN94nLcGS8tI5BcsRX5AQDxgmwUqxA3avXjBX6z7m29Y/HSkXxUilyL7v0tBtO+HZFl48N49PP7dav3Kp8+xRRIL0o+dWaq/tRRGPlAsgECPs2GdXV+qffG714D//Q+KXeeoMAKuD+N9iEF/1nFIxSgUp5XtlAblq3QJIXJs+orS+13dsGilkzIXVri2iwdp4IXMaAO5Py66k/PUYALSpOjhxIec85brufYaItCQNAAcA8chw4alLq/WFtXYwsxNCqaRJ/moNzV4gTi6sw5fyoZdOTlfIpxM2aPYCqjY6sC1hTNixporOgyDMHfjwX5s5d/W8USpG17PLnj6C71k0AGpH+svM5tl+GDnLjY4mAm8fzfAN05mri0pKyv8MOgwoQDzQC6OgMUiw2NEPAcB/A+yvnF+tOrY8SpKo3ukZA+Zqs8OXq017vOit3zriH36p5+07tOZKK3Ycm0aHS1wpZKiQcTE7nH8EDDp58q/dx9SpGKWkgvS97S1JAMoW1kctISCFUAXf4mLWGmydyHcB4IF0nyjlb+AlLfbCL/XC+PuNUu+cb0ePAhDOlbkjIL9qC0KiNQiMYsYz28YqmCpk1nK53ktr0yFJFEkptC0FBIhHKyWxdbyoNGEJAKcHXVP+Z6Qhu2vBS0qSP8xI+plE69t7YczPLXbP/toj8zVspHqnVmfK38S4ob7+Wg4MAWD/iiD5nnUh0dpYUqCQzTCzZldrDNmI68e/cU/SFnLcEeR6tlRSQDTaXZIjItq9udhNH3NK6iFdBwsJgEiQ/Oex0m3Bxlpuxg8ZZuxLxzflbzeXBL6+l4OjV9WJdcOWUhEEgkRDCAEBRi+IzeFv9LSQ86wfLmcckbEtU8z6GCllWEeBnC7azhWPPSUlFaRrGIMrqbMg8/bE6B85/ptv/xg29gbSjLqUv+1c0i8TKThMkWtJVlpTkiSc8VyESoNBzk/u2/QNUZZA8+gg1nAsi/L5DE8Ml5ApFcWlNXXlunRXM+WvJw3ZXUOeUqBwZL4ZHqH7D+GK55TG61O+lTkFAJBCOkYpoZmNJKJ8xsH5pYSHK07xQ/fdkPnY4fnwinFrupFebgcJ1nohnLUWO2C5Zdg/PydxFgDo4MF0TqakHtJ1soBcDbkgFaOUb5V9V61WCxUhyMr5Hju2Dc+2KOM6Sd63xxut9g4A2L9njwAAX/DliZyPbWNlnsjaZnvFwc0TmYcOXWy29yNtJZGSCtL1xMtDLikp3zKOpPGhnE8Zz2PLtdEPExSzviYS3onL7TsAoBvHBABksD4IYxQ9x0yXc7Ibqc7jZ6ufAIA9qRilpIKUkpLyzTB6RUD6itbXO0HS6fZJaY2jZxZQ73QpMYRnLjbaAHAe579mFGk2WGt2WYPtiYJ1/rVbbjoHAGmbk5T/N9I9pJSUlL+SQ1cEqRmpY8vtfidQplTtdjUbQ0t1TWGQ421D2RY2FAkA0FOGfEeysIRhreETP/s7R48m+wF5KPXeU1JBSklJ+SZhAPBI92ZKmSCEqBCTHs57mBnKkMcx+RnLBoDt27fj/PnzUMCCMkyWZTkkSLHi308fY0pKSkrKtwMJgDblnI9truT5zm2zwY++4a7oTbumzetmi/Nbshh7yXUCgJcV9JnJQoZ3jRV/5cr/S7cGUlIPKSUl5VuGALDj2Z/r9IOfWEwUJXFsshZTyZMvXupjjQGiK1VDAIRemd/fbcd7ljuDp5FW7075W5BaLikpKf8zDAD4jnXad90g5/uSCcj5DrYMZUIAeODA1wqmMgDU6+h2lXrqyp/TzLqUVJBSUlK+LTAA2KwX2KAmiaQjJVtScG6jk+xf51Wla0tKKkgpKSnfdkGiI8vdeqCSC0EUsSWEdi2i9VYwBwB/RUuJtK9RSipIKSkpr8w6QUQca/VQECVCCPhL9a45s9L5JAAcSptApqSkpKR8h7gagvPyUn50Iuc2Kp71v73k/6WkpKSkpHzn8YHJ9CmkpHxvWZQpKdfivL46t9Nwf0pKSkpKanClpKSkpKSkpKSkpKSkpKSkpKSkpKS84vw/g48oHCTZr0gAAAAASUVORK5CYII=",
	})
	local function decodeMascotBase64(data)
		local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local lookup = {}
		for i = 1, #alphabet do lookup[alphabet:sub(i, i)] = i - 1 end
		local output, value, bits = {}, 0, 0
		for i = 1, #data do
			local digit = lookup[data:sub(i, i)]
			if digit ~= nil then
				value = value * 64 + digit
				bits += 6
				if bits >= 8 then
					bits -= 8
					output[#output + 1] = string.char(math.floor(value / (2 ^ bits)) % 256)
					value = value % (2 ^ bits)
				end
			end
		end
		return table.concat(output)
	end
	local function getSkeletonImageAsset()
		local factory = getcustomasset
		if type(factory) ~= "function" then factory = getsynasset end
		if type(factory) ~= "function" then
			warn("[Airflow] Halloween skeleton image needs getcustomasset/getsynasset.")
			return nil
		end
		local path = "AirflowHalloweenSkeletonV5.png"
		if type(writefile) == "function" then
			pcall(function() writefile(path, decodeMascotBase64(SKELETON_BASE64)) end)
		end
		local ok, image = pcall(factory, path)
		if ok and type(image) == "string" then return image end
		warn("[Airflow] Could not load AirflowHalloweenSkeletonV5.png. Keep the PNG in the executor workspace.")
		return nil
	end
	local SKELETON_IMAGE = getSkeletonImageAsset()

	local function createHalloweenMascot(win, st)
		if not SKELETON_IMAGE then return end
		local skeleton = mark(new("ImageLabel", {
			Name = "HalloweenSkeletonImage", AnchorPoint = Vector2.new(.5, 0),
			Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(280, 206),
			BackgroundTransparency = 1, Image = SKELETON_IMAGE, ImageTransparency = 0,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 110, Parent = win.Gui,
		}))
		skeleton:SetAttribute("AF_NoTheme", true)
		st.mascot = skeleton

		local function placeSkeleton()
			if not skeleton.Parent or not win.Root or not win.Root.Parent then return end
			local rootPos = win.Root.AbsolutePosition
			local rootSize = win.Root.AbsoluteSize
			local scale = 1
			pcall(function()
				local guiScale = win.Root:FindFirstChildOfClass("UIScale")
				if guiScale then scale = math.max(guiScale.Scale, .5) end
			end)
			local screen = win.Gui and win.Gui.AbsoluteSize or Vector2.new(1280, 720)
			local viewportScale = math.clamp(math.min(screen.X / 1000, screen.Y / 700), .78, 1)
			scale *= viewportScale
			skeleton.Size = UDim2.fromOffset(280 * scale, 206 * scale)
			-- Keep the exact original screen-space placement, but update after the
			-- window drag step so the image does not trail one frame behind.
			skeleton.Position = UDim2.fromOffset(rootPos.X + rootSize.X * .755, rootPos.Y - 60 * scale)
			skeleton.Visible = win.Open == true and win._pill ~= true
		end

		placeSkeleton()
		local function afterWindowMovement()
			placeSkeleton()
		end
		table.insert(win._frameSteps, afterWindowMovement)
		table.insert(st.removers, function()
			for i, step in ipairs(win._frameSteps) do
				if step == afterWindowMovement then table.remove(win._frameSteps, i) break end
			end
		end)
		-- Still follows the original screen-space coordinates, with no Render listener delay.
	end

	local function disable(win)
		local st = win._hw
		if not st then return end
		st.alive = false
		for _, r in ipairs(st.removers) do pcall(r) end
		for _, c in ipairs(st.conns) do c:Disconnect() end
		if st.decor then st.decor:Destroy() end
		if st.mascot then st.mascot:Destroy() end
		for _, f in ipairs(st.fonts) do
			if f[1].Parent then
				f[1].FontFace, f[1].TextSize = f[2], f[3]
			end
		end
		if win.Body then
			for _, d in ipairs(win.Body:GetDescendants()) do
				if d:IsA("UICorner") then
					local off = d:GetAttribute("AF_HW")
					if off then
						d.CornerRadius = UDim.new(0, off)
						d:SetAttribute("AF_HW", nil)
					end
				end
			end
		end
		win._hw = nil
	end

	local function enable(win)
		if win._hw or win._destroyed or not win.Body then return end
		local st = { alive = true, removers = {}, conns = {}, fonts = {} }
		win._hw = st
		local function alive() return st.alive and not win._destroyed end

		local decor = mark(new("Frame", {
			Name = "HalloweenFX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 40, Parent = win.Body,
		}))
		st.decor = decor
		createHalloweenMascot(win, st)

		-- fog
		local function fogBlob(color, w, h, tr)
			return mark(new("ImageLabel", {
				AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Image = Assets.Glow,
				ImageColor3 = color, ImageTransparency = tr, ZIndex = 40, Parent = decor,
			}))
		end
		local fogA = fogBlob(Color3.fromRGB(120, 60, 170), 560, 170, .88)
		local fogB = fogBlob(Color3.fromRGB(255, 110, 20), 460, 140, .9)

		-- webs
		web(decor, "TL", 92)
		web(decor, "BR", 96)

		-- candle lit pumpkin
		local pumpGlow = mark(new("ImageLabel", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, -34, 1, -34), Size = UDim2.fromOffset(110, 110),
			BackgroundTransparency = 1, Image = Assets.Glow, ImageColor3 = Color3.fromRGB(255, 120, 20), ImageTransparency = .6, ZIndex = 41, Parent = decor,
		}))
		local pumpkin = mark(new("TextLabel", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, -34, 1, -34), Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1, Text = "🎃", TextScaled = true, ZIndex = 45, Parent = decor,
		}))

		-- per frame motion
		local seed = rng:NextNumber(0, 100)
		table.insert(st.removers, win:_listen("Render", function()
			if not decor.Parent then return end
			local hide = win._pill == true
			if decor.Visible == hide then decor.Visible = not hide end
			if hide then return end
			local t = os.clock()
			local flick = math.noise(t * 7, seed) * .5 + math.noise(t * 17, seed + 3) * .25
			pumpGlow.ImageTransparency = math.clamp(.58 + flick * .25, .3, .85)
			local sz = 110 + flick * 26
			pumpGlow.Size = UDim2.fromOffset(sz, sz)
			pumpkin.Rotation = math.sin(t * 1.3) * 4
			fogA.Position = UDim2.new(.3 + math.sin(t * .17) * .16, 0, 1, -10)
			fogB.Position = UDim2.new(.75 + math.cos(t * .21) * .14, 0, 1, -4)
		end))

		-- embers
		task.spawn(function()
			while alive() and decor.Parent do
				task.wait(.32)
				if decor.Visible and win.Open then
					local s = rng:NextInteger(2, 4)
					local x = rng:NextNumber(.04, .96)
					local e = mark(new("Frame", {
						AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(x, 0, 1, 4), Size = UDim2.fromOffset(s, s),
						BackgroundColor3 = EMBER, BackgroundTransparency = .1, BorderSizePixel = 0, ZIndex = 41, Parent = decor,
					}))
					corner(e, UDim.new(1, 0))
					local life = rng:NextNumber(2, 3.6)
					tween(e, {
						Position = UDim2.new(x + rng:NextNumber(-.06, .06), 0, 1 - rng:NextNumber(.3, .8), 0), BackgroundTransparency = 1,
					}, life, Enum.EasingStyle.Quad)
					task.delay(life + .05, function() e:Destroy() end)
				end
			end
		end)

		-- creepy title font
		local sidebar = win.Main and win.Main:FindFirstChild("Sidebar")
		local header = sidebar and sidebar:FindFirstChild("Header")
		if header then
			for _, l in ipairs(header:GetChildren()) do
				if l:IsA("TextLabel") and l.TextSize == 20 then
					table.insert(st.fonts, { l, l.FontFace, l.TextSize })
					l.FontFace = Font.fromEnum(Enum.Font.Creepster)
					l.TextSize = 24
				end
			end
		end

		-- sharp gothic corners (existing and future)
		for _, d in ipairs(win.Body:GetDescendants()) do
			if d:IsA("UICorner") then sharpen(d) end
		end
		table.insert(st.conns, win.Body.DescendantAdded:Connect(function(d)
			if d:IsA("UICorner") and st.alive then sharpen(d) end
		end))
	end

	local function sync()
		local want = Library._themeState.Preset == HW and Library.HalloweenFX ~= false
		for _, w in ipairs(Library.Windows) do
			if want then enable(w) else disable(w) end
		end
	end
	table.insert(Library._onTheme, function() sync() end)

	function Library:SetHalloweenEffects(on)
		Library.HalloweenFX = on ~= false
		sync()
	end

	local origWindow = Library.Window
	Library.Window = function(self, cfg)
		local w = origWindow(self, cfg)
		task.defer(sync)
		return w
	end
	Library.CreateWindow = Library.Window
end

-- ===================================================================
-- TOMOCHAN!!! THEME (palette + Tomo mascot + UI-only falling sakura)
-- Choose "TomoChan!!!" in Settings > Theme or pass Theme = "TomoChan!!!".
-- The petals are clipped to the UI panel. Halloween and its decorations remain unchanged.
-- Library:SetTomoChanEffects(false) keeps the palette and hides the portrait/petals.
-- ===================================================================
do
	local TOMO = "TomoChan!!!"
	local rng = Random.new()

	Library:AddTheme(TOMO, {
		Background = Color3.fromRGB(23, 13, 20),
		Surface = Color3.fromRGB(30, 18, 27),
		Surface2 = Color3.fromRGB(38, 22, 33),
		Surface3 = Color3.fromRGB(62, 34, 49),
		Stroke = Color3.fromRGB(59, 35, 49),
		StrokeHover = Color3.fromRGB(154, 75, 106),
		Accent = Color3.fromRGB(246, 94, 137),
		AccentDark = Color3.fromRGB(38, 15, 27),
		Text = Color3.fromRGB(249, 237, 242),
		Muted = Color3.fromRGB(179, 145, 162),
		Warning = Color3.fromRGB(255, 190, 128),
		Success = Color3.fromRGB(153, 222, 184),
		Error = Color3.fromRGB(255, 105, 126),
	})
	Library.TomoChanFX = true

	local function markTomo(inst)
		inst:SetAttribute("AF_NoTheme", true)
		return inst
	end

local TOMO_IMAGE_BASE64 = table.concat({
    "iVBORw0KGgoAAAANSUhEUgAAAnYAAAHMCAYAAABY7eV3AAEAAElEQVR42uz9eZxl2VXfif7W3uecO8WNOXKeK6uyKmsSCAkJCZdAIAQC24BTRgZj3Bhs056w/fzcfNoU9Wzz/Nz2Aw+PNsbQphsLrGzAmAaLwRaFoIUQyCoNJdU85VA5RWQMdzrn7LXeH3vvc/YNiTZ2CySV1rc+UZkZcePec8+9ce8v1vD7AYqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqi",
    "KIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqi",
    "KIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKIqiKJ9dkJ4CRVE+XUh4Tfm+5LXl+8JH+LvsewESPWuKoigq7BRF+Sx6HXkYoHtxgTZwnW7gUXk74H6vC78LsB/DQ3QvHpULAKu4UxRF",
    "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",
})
	local function decodeTomoBase64(data)
		local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local lookup = {}
		for i = 1, #alphabet do lookup[alphabet:sub(i, i)] = i - 1 end
		local output, value, bits = {}, 0, 0
		for i = 1, #data do
			local digit = lookup[data:sub(i, i)]
			if digit ~= nil then
				value = value * 64 + digit
				bits += 6
				if bits >= 8 then
					bits -= 8
					output[#output + 1] = string.char(math.floor(value / (2 ^ bits)) % 256)
					value = value % (2 ^ bits)
				end
			end
		end
		return table.concat(output)
	end

	local function getTomoImageAsset()
		local factory = getcustomasset
		if type(factory) ~= "function" then factory = getsynasset end
		if type(factory) ~= "function" then
			warn("[Airflow] TomoChan portrait needs getcustomasset/getsynasset.")
			return nil
		end
		local path = "AirflowTomoChanMascot.png"
		if type(writefile) == "function" then
			local ok, err = pcall(function() writefile(path, decodeTomoBase64(TOMO_IMAGE_BASE64)) end)
			if not ok then warn("[Airflow] Could not write TomoChan portrait: " .. tostring(err)) end
		end
		local ok, image = pcall(factory, path)
		if ok and type(image) == "string" then return image end
		warn("[Airflow] Could not load AirflowTomoChanMascot.png. Check your executor's custom-asset/file support.")
		return nil
	end

	local TOMO_IMAGE = getTomoImageAsset()

	local function createTomoMascot(win, st)
		if not TOMO_IMAGE then return end
		local portrait = markTomo(new("ImageLabel", {
			Name = "TomoChanMascot",
			AnchorPoint = Vector2.new(.5, 0),
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(315, 230),
			BackgroundTransparency = 1,
			Image = TOMO_IMAGE,
			ImageTransparency = 0,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 110,
			Parent = win.Gui,
		}))
		st.mascot = portrait

		local function placeTomo()
			if not portrait.Parent or not win.Root or not win.Root.Parent then return end
			local rootPos = win.Root.AbsolutePosition
			local rootSize = win.Root.AbsoluteSize
			local scale = 1
			pcall(function()
				local guiScale = win.Root:FindFirstChildOfClass("UIScale")
				if guiScale then scale = math.max(guiScale.Scale, .5) end
			end)
			local screen = win.Gui and win.Gui.AbsoluteSize or Vector2.new(1280, 720)
			local viewportScale = math.clamp(math.min(screen.X / 1000, screen.Y / 700), .78, 1)
			scale *= viewportScale
			portrait.Size = UDim2.fromOffset(315 * scale, 230 * scale)
			-- Restore the original Tomo placement exactly, including its negative Y offset.
			portrait.Position = UDim2.fromOffset(rootPos.X + rootSize.X * .755, rootPos.Y - 147 * scale)
			portrait.Visible = st.enabled == true and win.Open == true and win._pill ~= true and win.Root.Visible == true
		end

		placeTomo()
		local function afterWindowMovement()
			placeTomo()
		end
		table.insert(win._frameSteps, afterWindowMovement)
		table.insert(st.removers, function()
			for i, step in ipairs(win._frameSteps) do
				if step == afterWindowMovement then table.remove(win._frameSteps, i) break end
			end
		end)
	end


	-- Keep the same effect instance while the theme/effect is switched off.
	-- Hiding it instead of destroying it preserves each petal's position and phase.
	local function disable(win)
		local st = win._tomo
		if not st then return end
		st.enabled = false
		if st.decor then st.decor.Visible = false end
		if st.mascot then st.mascot.Visible = false end
	end

	local function enable(win)
		if win._destroyed or not win.Body or not win.Root then return end
		local existing = win._tomo
		if existing then
			existing.enabled = true
			return
		end

		local st = { alive = true, enabled = true, removers = {}, ready = false, lastWidth = 0, lastHeight = 0 }
		win._tomo = st

		local decor = markTomo(new("Frame", {
			Name = "TomoChanSakuraFX",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 40,
			Parent = win.Body,
		}))
		st.decor = decor
		createTomoMascot(win, st)

		-- Sakura petals follow the reference weather design: soft pink capsules,
		-- pale gradients, subtle outlines and a fluttering side-to-side turn.
		local petals = {}
		st.petals = petals

		local function dimensions()
			local bounds = decor.AbsoluteSize
			local width, height = bounds.X, bounds.Y
			local scale = 1
			pcall(function()
				local guiScale = win.Root:FindFirstChildOfClass("UIScale")
				if guiScale then scale = math.max(guiScale.Scale, .05) end
			end)
			-- AbsoluteSize is in screen pixels. Convert it back to the panel's
			-- unscaled offset space so particles fill the whole panel at any UIScale.
			if width > 0 and height > 0 then
				width, height = width / scale, height / scale
			end
			if width < 80 or height < 80 then
				local root = win.Root
				if root then
					local sx, sy = root.Size.X.Offset, root.Size.Y.Offset
					if sx >= 80 and sy >= 80 then width, height = sx, sy end
				end
			end
			return width, height
		end

		for i = 1, 26 do
			local petalWidth = rng:NextNumber(7, 14)
			local petalHeight = rng:NextNumber(4.5, 9)
			local color = Color3.fromRGB(255, 205, 220):Lerp(Color3.fromRGB(255, 140, 180), rng:NextNumber(0, 1))
			local alpha = rng:NextNumber(.08, .34)
			local petal = markTomo(new("Frame", {
				Name = "TomoSakuraPetal",
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromOffset(-100, -100),
				Size = UDim2.fromOffset(petalWidth, petalHeight),
				BackgroundColor3 = color,
				BackgroundTransparency = alpha,
				BorderSizePixel = 0,
				Rotation = rng:NextNumber(0, 360),
				Visible = false,
				ZIndex = 41,
				Parent = decor,
			}))
			corner(petal, UDim.new(1, 0))
			markTomo(new("UIGradient", {
				Rotation = 35,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 249)),
					ColorSequenceKeypoint.new(.52, Color3.fromRGB(255, 221, 233)),
					ColorSequenceKeypoint.new(1, color),
				}),
				Parent = petal,
			}))
			markTomo(new("UIStroke", {
				Color = Color3.fromRGB(255, 232, 241),
				Transparency = .52,
				Thickness = .5,
				Parent = petal,
			}))
			table.insert(petals, {
				Label = petal,
				X = 0,
				Y = 0,
				W = petalWidth,
				H = petalHeight,
				VX = rng:NextNumber(18, 45),
				VY = rng:NextNumber(35, 70),
				Sway = rng:NextNumber(14, 34),
				Frequency = rng:NextNumber(.6, 1.4),
				Flutter = rng:NextNumber(1.2, 2.6),
				Phase = rng:NextNumber(0, math.pi * 2),
				Spin = rng:NextNumber(-90, 90),
				Rotation = petal.Rotation,
			})
		end

		local function distribute(width, height)
			-- Do not seed particles until Roblox has laid out the panel. This avoids
			-- an initial width of 0/1 causing every petal to spawn along the left edge.
			for _, p in ipairs(petals) do
				p.X = rng:NextNumber(0, width)
				p.Y = rng:NextNumber(-p.H, height)
				p.Label.Position = UDim2.fromOffset(p.X, p.Y)
				p.Label.Visible = true
			end
			st.lastWidth, st.lastHeight = width, height
			st.ready = true
		end

		table.insert(st.removers, win:_listen("Render", function(dt)
			if not st.alive or not decor.Parent then return end
			local width, height = dimensions()
			if width < 80 or height < 80 then
				decor.Visible = false
				return
			end

			if not st.ready then
				distribute(width, height)
			elseif st.lastWidth > 0 and st.lastHeight > 0 then
				local sx, sy = width / st.lastWidth, height / st.lastHeight
				if math.abs(sx - 1) > .025 or math.abs(sy - 1) > .025 then
					for _, p in ipairs(petals) do
						p.X *= sx
						p.Y *= sy
					end
					st.lastWidth, st.lastHeight = width, height
				end
			end

			local show = st.enabled == true and Library._themeState.Preset == TOMO
				and Library.TomoChanFX ~= false and win.Open == true
				and win._pill ~= true and win.Root.Visible == true
			if decor.Visible ~= show then decor.Visible = show end
			if not show then return end
			if type(dt) ~= "number" then dt = 1 / 60 end
			dt = math.clamp(dt, 0, 1 / 20)

			local now = os.clock()
			for _, p in ipairs(petals) do
				p.Y += p.VY * dt
				p.X += p.VX * dt
				p.Rotation += p.Spin * dt
				if p.Y > height + p.H then
					p.Y = -p.H - rng:NextNumber(4, 24)
					p.X = rng:NextNumber(0, width)
					p.VX = rng:NextNumber(18, 45)
					p.VY = rng:NextNumber(35, 70)
					p.Phase = rng:NextNumber(0, math.pi * 2)
					p.Sway = rng:NextNumber(14, 34)
					p.Frequency = rng:NextNumber(.6, 1.4)
					p.Flutter = rng:NextNumber(1.2, 2.6)
				end
				if p.X > width + p.W then p.X = -p.W elseif p.X < -p.W then p.X = width + p.W end
				local swayX = math.sin(now * p.Frequency + p.Phase) * p.Sway
				local flutter = .3 + math.abs(math.cos(now * p.Flutter + p.Phase)) * .7
				p.Label.Size = UDim2.fromOffset(p.W * flutter, p.H)
				p.Label.Position = UDim2.fromOffset(p.X + swayX, p.Y)
				p.Label.Rotation = p.Rotation
			end
		end))
	end

	local function syncTomo()
		local want = Library._themeState.Preset == TOMO and Library.TomoChanFX ~= false
		for _, win in ipairs(Library.Windows) do
			if want then enable(win) else disable(win) end
		end
	end

	table.insert(Library._onTheme, function() syncTomo() end)

	function Library:SetTomoChanEffects(on)
		Library.TomoChanFX = on ~= false
		syncTomo()
	end

	local previousWindow = Library.Window
	Library.Window = function(self, cfg)
		local win = previousWindow(self, cfg)
		task.defer(syncTomo)
		return win
	end
	Library.CreateWindow = Library.Window
end


-- ===================================================================
-- LANGUAGES
-- Settings > Language lets the player pick the language they are used to.
-- The choice is saved in the UI settings file and loaded automatically
-- every time the UI starts, until the player changes it again.
--
-- Built in: English (default), Russian, Vietnamese, Spanish, Portuguese,
-- Indonesian, Filipino.
--
-- API:
--   Library:SetLanguage("Русский")      Library:GetLanguage()      Library:GetLanguages()
--   Library:AddLanguage("Deutsch", { ["Settings"] = "Einstellungen" }, nil, "de")   (4th arg = online translate code)
--   Library:AddTranslations({ ["Aimbot"] = { ["Русский"] = "Аимбот", ["Tiếng Việt"] = "Aimbot" } })
--     (use AddTranslations to translate your own tab / toggle / button names)
-- Every text label in the UI is translated: hand written dictionary first, then an online translator
-- (cached in the AirflowTranslations folder), so YOUR tabs, sections, toggles, buttons, etc. are covered too.
-- Needs an executor with HTTP (request / HttpGet). Library:SetAutoTranslate(false) turns the online part off,
-- Library:ProtectText("MyBrand") keeps a text untouched. Set attribute AF_NoTranslate on a label to skip it.
-- ===================================================================
do
	local ORDER = { "English", "Русский", "Tiếng Việt", "Español", "Português", "Bahasa Indonesia", "Filipino" }

	-- { English, ru, vi, es, pt, id, fil }
	local ROWS = {
		{ "Settings", "Настройки", "Cài đặt", "Ajustes", "Configurações", "Pengaturan", "Mga Setting" },
		{ "Interface, theme and configuration", "Интерфейс, тема и конфигурация", "Giao diện, chủ đề và cấu hình", "Interfaz, tema y configuración", "Interface, tema e configuração", "Antarmuka, tema, dan konfigurasi", "Interface, tema at configuration" },
		{ "Configurations", "Конфигурации", "Cấu hình", "Configuraciones", "Configurações", "Konfigurasi", "Mga Configuration" },
		{ "Config name", "Имя конфига", "Tên cấu hình", "Nombre de la config", "Nome da config", "Nama konfigurasi", "Pangalan ng config" },
		{ "Saved configs", "Сохранённые конфиги", "Cấu hình đã lưu", "Configs guardadas", "Configs salvas", "Konfigurasi tersimpan", "Mga naka-save na config" },
		{ "No saved configs yet", "Пока нет сохранённых конфигов", "Chưa có cấu hình nào được lưu", "Aún no hay configs guardadas", "Nenhuma config salva ainda", "Belum ada konfigurasi tersimpan", "Wala pang naka-save na config" },
		{ "Save", "Сохранить", "Lưu", "Guardar", "Salvar", "Simpan", "I-save" },
		{ "Load", "Загрузить", "Tải", "Cargar", "Carregar", "Muat", "I-load" },
		{ "Delete", "Удалить", "Xóa", "Eliminar", "Excluir", "Hapus", "Burahin" },
		{ "Refresh", "Обновить", "Làm mới", "Actualizar", "Atualizar", "Segarkan", "I-refresh" },
		{ "Copy", "Копировать", "Sao chép", "Copiar", "Copiar", "Salin", "Kopyahin" },
		{ "Auto save", "Автосохранение", "Tự động lưu", "Autoguardado", "Salvamento automático", "Simpan otomatis", "Auto-save" },
		{ "Writes the active config when a flagged control changes", "Записывает активный конфиг при изменении отмеченного элемента", "Ghi cấu hình đang dùng khi một mục được đánh dấu thay đổi", "Escribe la config activa cuando cambia un control marcado", "Grava a config ativa quando um controle marcado muda", "Menulis konfigurasi aktif saat kontrol yang ditandai berubah", "Isinusulat ang aktibong config kapag nagbago ang may-flag na control" },
		{ "Load on startup", "Загрузка при запуске", "Tải khi khởi động", "Cargar al iniciar", "Carregar ao iniciar", "Muat saat memulai", "I-load sa pagsisimula" },
		{ "Load the active config when the UI opens", "Загружать активный конфиг при открытии интерфейса", "Tải cấu hình đang dùng khi giao diện mở", "Carga la config activa al abrir la interfaz", "Carrega a config ativa ao abrir a interface", "Muat konfigurasi aktif saat UI dibuka", "I-load ang aktibong config kapag bumukas ang UI" },
		{ "Auto save on", "Автосохранение вкл", "Tự động lưu: bật", "Autoguardado activado", "Salvamento automático ligado", "Simpan otomatis aktif", "Naka-on ang auto-save" },
		{ "Auto save off", "Автосохранение выкл", "Tự động lưu: tắt", "Autoguardado desactivado", "Salvamento automático desligado", "Simpan otomatis nonaktif", "Naka-off ang auto-save" },
		{ "No file API", "Нет файлового API", "Không có API tệp", "Sin API de archivos", "Sem API de arquivos", "Tanpa API file", "Walang file API" },
		{ "This executor cannot read or write files", "Этот экзекьютор не может читать и записывать файлы", "Executor này không thể đọc hoặc ghi tệp", "Este ejecutor no puede leer ni escribir archivos", "Este executor não pode ler nem gravar arquivos", "Executor ini tidak dapat membaca atau menulis file", "Hindi makabasa o makasulat ng file ang executor na ito" },
		{ "Theme", "Тема", "Chủ đề", "Tema", "Tema", "Tema", "Tema" },
		{ "Recolors the window, popups and floating panels", "Перекрашивает окно, всплывающие и плавающие панели", "Đổi màu cửa sổ, popup và bảng nổi", "Cambia el color de la ventana, ventanas emergentes y paneles flotantes", "Muda a cor da janela, pop-ups e painéis flutuantes", "Mengubah warna jendela, popup, dan panel mengambang", "Binabago ang kulay ng window, popup at floating panel" },
		{ "Accent color", "Акцентный цвет", "Màu nhấn", "Color de acento", "Cor de destaque", "Warna aksen", "Kulay ng accent" },
		{ "Overrides the accent of the current theme", "Заменяет акцент текущей темы", "Ghi đè màu nhấn của chủ đề hiện tại", "Reemplaza el acento del tema actual", "Substitui o destaque do tema atual", "Menimpa aksen tema saat ini", "Pinapalitan ang accent ng kasalukuyang tema" },
		{ "Reset accent", "Сбросить акцент", "Đặt lại màu nhấn", "Restablecer acento", "Redefinir destaque", "Atur ulang aksen", "I-reset ang accent" },
		{ "Go back to the accent of the selected theme", "Вернуть акцент выбранной темы", "Quay lại màu nhấn của chủ đề đã chọn", "Volver al acento del tema seleccionado", "Voltar ao destaque do tema selecionado", "Kembali ke aksen tema yang dipilih", "Ibalik ang accent ng napiling tema" },
		{ "Interface", "Интерфейс", "Giao diện", "Interfaz", "Interface", "Antarmuka", "Interface" },
		{ "Menu key", "Клавиша меню", "Phím menu", "Tecla del menú", "Tecla do menu", "Tombol menu", "Menu key" },
		{ "Show or hide the window", "Показать или скрыть окно", "Hiện hoặc ẩn cửa sổ", "Mostrar u ocultar la ventana", "Mostrar ou ocultar a janela", "Tampilkan atau sembunyikan jendela", "Ipakita o itago ang window" },
		{ "Keep on screen", "Держать на экране", "Giữ trong màn hình", "Mantener en pantalla", "Manter na tela", "Tetap di layar", "Panatilihin sa screen" },
		{ "Stops the window from being dragged out of view", "Не даёт вытащить окно за пределы экрана", "Ngăn cửa sổ bị kéo ra khỏi màn hình", "Evita que la ventana se arrastre fuera de la vista", "Impede que a janela seja arrastada para fora da tela", "Mencegah jendela diseret keluar dari layar", "Pinipigilan ang window na mahila palabas ng screen" },
		{ "Collapse to pill", "Свернуть в капсулу", "Thu gọn thành viên thuốc", "Contraer en píldora", "Recolher em pílula", "Ciutkan menjadi pil", "I-collapse bilang pill" },
		{ "Menu key and close button shrink the window into a floating pill", "Клавиша меню и кнопка закрытия сворачивают окно в плавающую капсулу", "Phím menu và nút đóng thu nhỏ cửa sổ thành viên thuốc nổi", "La tecla del menú y el botón de cerrar reducen la ventana a una píldora flotante", "A tecla do menu e o botão de fechar reduzem a janela a uma pílula flutuante", "Tombol menu dan tombol tutup mengecilkan jendela menjadi pil mengambang", "Pinaliliit ng menu key at close button ang window bilang floating pill" },
		{ "Max notifications", "Макс. уведомлений", "Số thông báo tối đa", "Máx. de notificaciones", "Máx. de notificações", "Maks. notifikasi", "Max na notification" },
		{ "How many toasts can stack at once", "Сколько уведомлений может быть одновременно", "Số thông báo có thể xếp chồng cùng lúc", "Cuántas notificaciones pueden apilarse a la vez", "Quantas notificações podem se empilhar ao mesmo tempo", "Berapa banyak notifikasi yang dapat ditumpuk sekaligus", "Ilang notification ang puwedeng sabay-sabay" },
		{ "Test notification", "Тестовое уведомление", "Thông báo thử", "Notificación de prueba", "Notificação de teste", "Notifikasi uji", "Test na notification" },
		{ "Preview the current theme in a toast", "Предпросмотр текущей темы в уведомлении", "Xem trước chủ đề hiện tại trong thông báo", "Vista previa del tema actual en una notificación", "Prévia do tema atual em uma notificação", "Pratinjau tema saat ini di notifikasi", "I-preview ang kasalukuyang tema sa notification" },
		{ "Notifications use the active theme.", "Уведомления используют активную тему.", "Thông báo dùng chủ đề đang hoạt động.", "Las notificaciones usan el tema activo.", "As notificações usam o tema ativo.", "Notifikasi menggunakan tema aktif.", "Gumagamit ng aktibong tema ang mga notification." },
		{ "Quick access", "Быстрый доступ", "Truy cập nhanh", "Acceso rápido", "Acesso rápido", "Akses cepat", "Mabilis na access" },
		{ "Pin buttons, toggles and keybinds as floating shortcuts", "Закрепляйте кнопки, переключатели и бинды как плавающие ярлыки", "Ghim nút, công tắc và phím tắt thành lối tắt nổi", "Fija botones, interruptores y atajos como accesos flotantes", "Fixe botões, interruptores e atalhos como atalhos flutuantes", "Sematkan tombol, sakelar, dan pintasan sebagai pintasan mengambang", "I-pin ang mga button, toggle at keybind bilang floating shortcut" },
		{ "Danger zone", "Опасная зона", "Vùng nguy hiểm", "Zona de peligro", "Zona de perigo", "Zona berbahaya", "Delikadong zone" },
		{ "Destroy UI", "Уничтожить UI", "Hủy giao diện", "Destruir UI", "Destruir UI", "Hancurkan UI", "Sirain ang UI" },
		{ "Removes the window and every floating panel", "Удаляет окно и все плавающие панели", "Xóa cửa sổ và mọi bảng nổi", "Elimina la ventana y todos los paneles flotantes", "Remove a janela e todos os painéis flutuantes", "Menghapus jendela dan semua panel mengambang", "Inaalis ang window at lahat ng floating panel" },
		{ "Destroy UI?", "Уничтожить UI?", "Hủy giao diện?", "¿Destruir UI?", "Destruir UI?", "Hancurkan UI?", "Sirain ang UI?" },
		{ "This removes the window and every floating panel.", "Это удалит окно и все плавающие панели.", "Thao tác này sẽ xóa cửa sổ và mọi bảng nổi.", "Esto elimina la ventana y todos los paneles flotantes.", "Isso remove a janela e todos os painéis flutuantes.", "Ini akan menghapus jendela dan semua panel mengambang.", "Aalisin nito ang window at lahat ng floating panel." },
		{ "Delete config", "Удалить конфиг", "Xóa cấu hình", "Eliminar config", "Excluir config", "Hapus konfigurasi", "Burahin ang config" },
		{ "Cancel", "Отмена", "Hủy", "Cancelar", "Cancelar", "Batal", "Kanselahin" },
		{ "Confirm", "Подтвердить", "Xác nhận", "Confirmar", "Confirmar", "Konfirmasi", "Kumpirmahin" },
		{ "Language", "Язык", "Ngôn ngữ", "Idioma", "Idioma", "Bahasa", "Wika" },
		{ "Interface language", "Язык интерфейса", "Ngôn ngữ giao diện", "Idioma de la interfaz", "Idioma da interface", "Bahasa antarmuka", "Wika ng interface" },
		{ "Choose the language you are most comfortable with", "Выберите язык, который вам привычнее", "Chọn ngôn ngữ bạn quen dùng nhất", "Elige el idioma con el que te sientas más cómodo", "Escolha o idioma com que você se sente mais confortável", "Pilih bahasa yang paling Anda kuasai", "Piliin ang wikang pinaka-komportable ka" },
		{ "Home", "Главная", "Trang chủ", "Inicio", "Início", "Beranda", "Home" },
		{ "System info", "Информация о системе", "Thông tin hệ thống", "Información del sistema", "Informações do sistema", "Info sistem", "Impormasyon ng system" },
		{ "Ping", "Пинг", "Ping", "Ping", "Ping", "Ping", "Ping" },
		{ "Executor", "Экзекьютор", "Executor", "Ejecutor", "Executor", "Executor", "Executor" },
		{ "Game", "Игра", "Trò chơi", "Juego", "Jogo", "Game", "Laro" },
		{ "Server region", "Регион сервера", "Khu vực máy chủ", "Región del servidor", "Região do servidor", "Wilayah server", "Rehiyon ng server" },
		{ "Time of day", "Время суток", "Thời gian", "Hora del día", "Hora do dia", "Waktu", "Oras" },
		{ "Players", "Игроки", "Người chơi", "Jugadores", "Jogadores", "Pemain", "Mga manlalaro" },
		{ "Session", "Сессия", "Phiên", "Sesión", "Sessão", "Sesi", "Session" },
		{ "Close Airflow?", "Закрыть Airflow?", "Đóng Airflow?", "¿Cerrar Airflow?", "Fechar o Airflow?", "Tutup Airflow?", "Isara ang Airflow?" },
		{ "Would you like to close this window or destroy the UI completely?", "Закрыть это окно или полностью уничтожить интерфейс?", "Bạn muốn đóng cửa sổ này hay hủy hoàn toàn giao diện?", "¿Quieres cerrar esta ventana o destruir la interfaz por completo?", "Deseja fechar esta janela ou destruir a interface por completo?", "Ingin menutup jendela ini atau menghancurkan UI sepenuhnya?", "Isasara mo ba ang window na ito o tuluyang sisirain ang UI?" },
		{ "Close UI", "Закрыть UI", "Đóng giao diện", "Cerrar UI", "Fechar UI", "Tutup UI", "Isara ang UI" },
		{ "Search controls", "Поиск элементов", "Tìm điều khiển", "Buscar controles", "Buscar controles", "Cari kontrol", "Maghanap ng control" },
		{ "Search", "Поиск", "Tìm kiếm", "Buscar", "Pesquisar", "Cari", "Maghanap" },
		{ "No controls match your search.", "Ничего не найдено.", "Không có điều khiển nào khớp.", "Ningún control coincide con tu búsqueda.", "Nenhum controle corresponde à busca.", "Tidak ada kontrol yang cocok.", "Walang control na tumutugma." },
		{ "Unpin all", "Открепить все", "Bỏ ghim tất cả", "Desfijar todo", "Desafixar tudo", "Lepas semua", "I-unpin lahat" },
		{ "controls pinned", "закреплено", "đã ghim", "fijados", "fixados", "disematkan", "naka-pin" },
		{ "control pinned", "закреплён", "đã ghim", "fijado", "fixado", "disematkan", "naka-pin" },
		{ "tap one to float it anywhere", "нажмите, чтобы разместить где угодно", "chạm để thả nổi ở bất kỳ đâu", "toca uno para flotarlo donde quieras", "toque em um para flutuá-lo em qualquer lugar", "ketuk satu untuk mengambangkannya di mana saja", "pindutin para ilagay kahit saan" },
		{ "All", "Все", "Tất cả", "Todo", "Tudo", "Semua", "Lahat" },
		{ "Buttons", "Кнопки", "Nút", "Botones", "Botões", "Tombol", "Mga button" },
		{ "Toggles", "Переключатели", "Công tắc", "Interruptores", "Interruptores", "Sakelar", "Mga toggle" },
		{ "Keybinds", "Бинды", "Phím tắt", "Atajos", "Atalhos", "Pintasan tombol", "Mga keybind" },
		{ "Sliders", "Ползунки", "Thanh trượt", "Deslizadores", "Controles deslizantes", "Penggeser", "Mga slider" },
		{ "Steppers", "Счётчики", "Bộ tăng giảm", "Contadores", "Contadores", "Penghitung", "Mga stepper" },
		{ "Dropdowns", "Списки", "Danh sách thả", "Desplegables", "Listas suspensas", "Dropdown", "Mga dropdown" },
		{ "Nothing here yet", "Здесь пока пусто", "Chưa có gì ở đây", "Aún no hay nada aquí", "Nada aqui ainda", "Belum ada apa-apa di sini", "Wala pa rito" },
		{ "Dock", "Закрепить", "Gắn lại", "Acoplar", "Encaixar", "Pasang", "I-dock" },
		{ "Locked", "Заблокировано", "Đã khóa", "Bloqueado", "Bloqueado", "Terkunci", "Naka-lock" },
		{ "Config saved", "Конфиг сохранён", "Đã lưu cấu hình", "Config guardada", "Config salva", "Konfigurasi disimpan", "Na-save ang config" },
		{ "Save failed", "Не удалось сохранить", "Lưu thất bại", "Error al guardar", "Falha ao salvar", "Gagal menyimpan", "Hindi na-save" },
		{ "Config loaded", "Конфиг загружен", "Đã tải cấu hình", "Config cargada", "Config carregada", "Konfigurasi dimuat", "Na-load ang config" },
		{ "Load failed", "Не удалось загрузить", "Tải thất bại", "Error al cargar", "Falha ao carregar", "Gagal memuat", "Hindi na-load" },
		{ "Config deleted", "Конфиг удалён", "Đã xóa cấu hình", "Config eliminada", "Config excluída", "Konfigurasi dihapus", "Nabura ang config" },
		{ "Delete failed", "Не удалось удалить", "Xóa thất bại", "Error al eliminar", "Falha ao excluir", "Gagal menghapus", "Hindi nabura" },
		{ "Config copied", "Конфиг скопирован", "Đã sao chép cấu hình", "Config copiada", "Config copiada", "Konfigurasi disalin", "Nakopya ang config" },
		{ "Copy failed", "Не удалось скопировать", "Sao chép thất bại", "Error al copiar", "Falha ao copiar", "Gagal menyalin", "Hindi nakopya" },
		{ "JSON is on your clipboard", "JSON в буфере обмена", "JSON đã có trong bộ nhớ tạm", "El JSON está en tu portapapeles", "O JSON está na área de transferência", "JSON ada di clipboard Anda", "Nasa clipboard mo na ang JSON" },
		{ "Clipboard unavailable", "Буфер обмена недоступен", "Không có bộ nhớ tạm", "Portapapeles no disponible", "Área de transferência indisponível", "Clipboard tidak tersedia", "Hindi available ang clipboard" },
		{ "Name your config", "Назовите конфиг", "Đặt tên cho cấu hình", "Ponle nombre a tu config", "Dê um nome à sua config", "Beri nama konfigurasi", "Pangalanan ang config" },
		{ "Type a name first.", "Сначала введите имя.", "Hãy nhập tên trước.", "Escribe un nombre primero.", "Digite um nome primeiro.", "Ketik nama terlebih dahulu.", "Mag-type muna ng pangalan." },
		{ "Pick a config", "Выберите конфиг", "Chọn một cấu hình", "Elige una config", "Escolha uma config", "Pilih konfigurasi", "Pumili ng config" },
		{ "Select one from the list.", "Выберите из списка.", "Chọn một mục trong danh sách.", "Selecciona una de la lista.", "Selecione uma da lista.", "Pilih satu dari daftar.", "Pumili mula sa listahan." },
		{ "Open", "Открыть", "Mở", "Abrir", "Abrir", "Buka", "Buksan" },
		{ "tap to open", "нажмите, чтобы открыть", "chạm để mở", "toca para abrir", "toque para abrir", "ketuk untuk membuka", "pindutin para buksan" },
		{ "click to open", "нажмите, чтобы открыть", "nhấp để mở", "haz clic para abrir", "clique para abrir", "klik untuk membuka", "i-click para buksan" },
		{ "Good morning.", "Доброе утро.", "Chào buổi sáng.", "Buenos días.", "Bom dia.", "Selamat pagi.", "Magandang umaga." },
		{ "Good afternoon.", "Добрый день.", "Chào buổi chiều.", "Buenas tardes.", "Boa tarde.", "Selamat siang.", "Magandang hapon." },
		{ "Good evening.", "Добрый вечер.", "Chào buổi tối.", "Buenas noches.", "Boa noite.", "Selamat malam.", "Magandang gabi." },
		{ "Preparing interface", "Подготовка интерфейса", "Đang chuẩn bị giao diện", "Preparando la interfaz", "Preparando a interface", "Menyiapkan antarmuka", "Inihahanda ang interface" },
		{ "Loading icons", "Загрузка иконок", "Đang tải biểu tượng", "Cargando iconos", "Carregando ícones", "Memuat ikon", "Nilo-load ang mga icon" },
		{ "Almost there", "Почти готово", "Sắp xong rồi", "Casi listo", "Quase lá", "Hampir selesai", "Malapit na" },
		{ "Loading", "Загрузка", "Đang tải", "Cargando", "Carregando", "Memuat", "Naglo-load" },
		{ "None", "Нет", "Không có", "Ninguno", "Nenhum", "Tidak ada", "Wala" },
	}

	-- { Lua pattern, ru, vi, es, pt, id, fil }  (for text with changing parts)
	local PATTERNS = {
		{ "^Remove (.+)%? This cannot be undone%.$", "Удалить %1? Это действие нельзя отменить.", "Xóa %1? Không thể hoàn tác.", "¿Eliminar %1? Esta acción no se puede deshacer.", "Excluir %1? Isso não pode ser desfeito.", "Hapus %1? Tindakan ini tidak dapat dibatalkan.", "Burahin ang %1? Hindi na ito mababawi." },
		{ "^Hello, (.+)$", "Привет, %1", "Xin chào, %1", "Hola, %1", "Olá, %1", "Halo, %1", "Kumusta, %1" },
		{ "^(%d+) of (%d+) available$", "%1 из %2 доступно", "%1 trong %2 khả dụng", "%1 de %2 disponibles", "%1 de %2 disponíveis", "%1 dari %2 tersedia", "%1 sa %2 available" },
		{ "^Folder  (.-)   ·   Active  (.+)$", "Папка  %1   ·   Активный  %2", "Thư mục  %1   ·   Đang dùng  %2", "Carpeta  %1   ·   Activa  %2", "Pasta  %1   ·   Ativa  %2", "Folder  %1   ·   Aktif  %2", "Folder  %1   ·   Aktibo  %2" },
	}

	local CODES = {
		["Русский"] = "ru", ["Tiếng Việt"] = "vi", ["Español"] = "es", ["Português"] = "pt",
		["Bahasa Indonesia"] = "id", ["Filipino"] = "tl",
	}
	-- extra languages: no hand-written dictionary, they are translated online (and cached) on demand
	local EXTRA = {
		{ "Deutsch", "de" }, { "Français", "fr" }, { "Italiano", "it" }, { "Türkçe", "tr" }, { "Polski", "pl" },
		{ "Українська", "uk" }, { "中文", "zh-CN" }, { "日本語", "ja" }, { "한국어", "ko" }, { "ภาษาไทย", "th" }, { "Bahasa Melayu", "ms" },
	}

	Library._lang = "English"
	Library._pendingLang = nil
	Library._tr = { English = { map = {}, patterns = {} } }
	Library._langOrder = { "English" }
	Library._onLang = {}
	Library._protect = { airflow = true }   -- lower-case texts that must never be translated (brand / window titles)
	Library.AutoTranslate = true            -- translate texts that have no dictionary entry through the online translator

	local tracked = setmetatable({}, { __mode = "k" })
	local hooked = setmetatable({}, { __mode = "k" })
	local PROPS = { TextLabel = { "Text" }, TextButton = { "Text" }, TextBox = { "PlaceholderText" } }
	local token = 0
	local refresh

	local SPECIAL_UP = { [0x103] = true, [0x111] = true, [0x129] = true, [0x169] = true, [0x1A1] = true, [0x1B0] = true }
	local function upperCP(c)
		if c >= 97 and c <= 122 then return c - 32 end
		if c >= 0xE0 and c <= 0xFE and c ~= 0xF7 then return c - 32 end
		if SPECIAL_UP[c] then return c - 1 end
		if c >= 0x1EA1 and c <= 0x1EF9 and c % 2 == 1 then return c - 1 end
		if c >= 0x430 and c <= 0x44F then return c - 32 end
		if c >= 0x450 and c <= 0x45F then return c - 80 end
		return c
	end
	local function upperUtf8(s)
		local ok, res = pcall(function()
			local out = {}
			for _, c in utf8.codes(s) do out[#out + 1] = utf8.char(upperCP(c)) end
			return table.concat(out)
		end)
		return ok and res or string.upper(s)
	end

	-- ---------------------------------------------------------------
	-- online translation + disk cache
	-- ---------------------------------------------------------------
	local FOLDER = "AirflowTranslations"
	local caches, savingCache = {}, {}
	local waiting, failed, queue = {}, {}, {}
	local activeWorkers, warned = 0, false
	local MAX_TRANSLATION_WORKERS = 4
	local MAX_BATCH_ITEMS = 10
	local MAX_BATCH_CHARS = 1200

	local function fsOk() return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" end

	local function cacheFor(lang)
		local c = caches[lang]
		if c then return c end
		c = {}
		caches[lang] = c
		local L = Library._tr[lang]
		if L and L.code and fsOk() then
			pcall(function()
				local path = FOLDER .. "/" .. L.code .. ".cache"
				if isfile(path) then
					local data = HttpService:JSONDecode(readfile(path))
					if type(data) == "table" then
						for k, v in pairs(data) do if type(v) == "string" then c[k] = v end end
					end
				end
			end)
		end
		return c
	end

	local function saveCache(lang)
		if not fsOk() or savingCache[lang] then return end
		local L = Library._tr[lang]
		if not (L and L.code) then return end
		savingCache[lang] = true
		task.delay(3, function()
			savingCache[lang] = false
			pcall(function()
				if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(FOLDER) then makefolder(FOLDER) end
				writefile(FOLDER .. "/" .. L.code .. ".cache", HttpService:JSONEncode(caches[lang] or {}))
			end)
		end)
	end

	local function decodeTranslation(body)
		if type(body) ~= "string" or body == "" then return nil end
		local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok or type(data) ~= "table" or type(data[1]) ~= "table" then return nil end
		local parts = {}
		for _, seg in ipairs(data[1]) do
			if type(seg) == "table" and type(seg[1]) == "string" then
				parts[#parts + 1] = seg[1]
			end
		end
		local out = table.concat(parts)
		return out ~= "" and out or nil
	end

	local function fetchTranslationBody(url)
		local body
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		if type(req) == "function" then
			local ok, res = pcall(req, {
				Url = url,
				Method = "GET",
				Headers = { ["Accept"] = "application/json" },
			})
			if ok and type(res) == "table" then
				local status = tonumber(res.StatusCode or res.Status or res.status_code)
				if not status or (status >= 200 and status < 400) then
					body = res.Body or res.body
				end
			end
		end
		if type(body) ~= "string" or not decodeTranslation(body) then
			local ok, res = pcall(function() return HttpService:GetAsync(url) end)
			if ok and type(res) == "string" then body = res end
		end
		if type(body) ~= "string" or not decodeTranslation(body) then
			local ok, res = pcall(function() return game:HttpGet(url) end)
			if ok and type(res) == "string" then body = res end
		end
		return body
	end

	local function fetchRawBody(url)
		local body
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		if type(req) == "function" then
			local ok, res = pcall(req, {
				Url = url,
				Method = "GET",
				Headers = { ["Accept"] = "application/json" },
			})
			if ok and type(res) == "table" then
				local status = tonumber(res.StatusCode or res.Status or res.status_code)
				if not status or (status >= 200 and status < 400) then body = res.Body or res.body end
			end
		end
		if type(body) ~= "string" or body == "" then
			local ok, res = pcall(function() return HttpService:GetAsync(url) end)
			if ok and type(res) == "string" then body = res end
		end
		if type(body) ~= "string" or body == "" then
			local ok, res = pcall(function() return game:HttpGet(url) end)
			if ok and type(res) == "string" then body = res end
		end
		return body
	end

	local function decodeMyMemory(body)
		if type(body) ~= "string" or body == "" then return nil end
		local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok or type(data) ~= "table" or type(data.responseData) ~= "table" then return nil end
		local out = data.responseData.translatedText
		if type(out) ~= "string" or out == "" then return nil end
		-- MyMemory may HTML-encode punctuation and accented text.
		out = out:gsub("&quot;", '"'):gsub("&#39;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
		return out
	end

	local function googleTranslate(code, text)
		local encoded = HttpService:UrlEncode(text)
		local primary = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" .. code .. "&dt=t&q=" .. encoded
		local translated = decodeTranslation(fetchTranslationBody(primary))
		if translated then return translated end

		-- Try Google's alternate host before using a separate translation provider.
		local backup = "https://translate.google.com/translate_a/single?client=gtx&sl=en&tl=" .. code .. "&dt=t&q=" .. encoded
		translated = decodeTranslation(fetchTranslationBody(backup))
		if translated then return translated end

		-- Independent fallback for executors or networks that cannot reach Google Translate.
		local memoryUrl = "https://api.mymemory.translated.net/get?q=" .. encoded .. "&langpair=en%7C" .. HttpService:UrlEncode(code)
		return decodeMyMemory(fetchRawBody(memoryUrl))
	end

	local function batchMarker(i)
		return "QZXAFLOW" .. string.format("%04d", i) .. "XZQ"
	end

	-- Translate several labels in one request instead of making one HTTP call per label.
	-- The markers let us split the response back into the correct UI elements.
	local function googleTranslateBatch(code, items)
		if #items == 1 then
			local one = googleTranslate(code, items[1][2])
			if one then return { one }, true end
			return nil, false
		end
		local parts, markers = {}, {}
		for i, item in ipairs(items) do
			markers[i] = batchMarker(i)
			parts[#parts + 1] = markers[i] .. "\n" .. item[2] .. "\n"
		end
		markers[#items + 1] = batchMarker(#items + 1)
		parts[#parts + 1] = markers[#items + 1]
		local translated = googleTranslate(code, table.concat(parts))
		if not translated then return nil, false end
		local results, cursor = {}, 1
		for i = 1, #items do
			local markerStart = translated:find(markers[i], cursor, true)
			if not markerStart then return nil, true end
			local textStart = markerStart + #markers[i]
			local markerEnd = translated:find(markers[i + 1], textStart, true)
			if not markerEnd then return nil, true end
			local value = translated:sub(textStart, markerEnd - 1)
			value = value:gsub("^%s+", ""):gsub("%s+$", "")
			if value == "" then return nil, true end
			results[i] = value
			cursor = markerEnd + #markers[i + 1]
		end
		return results, true
	end

	local function finish(lang, base, result)
		local id = lang .. "\0" .. base
		local list = waiting[id]
		waiting[id] = nil
		if result then
			cacheFor(lang)[base] = result
			saveCache(lang)
			if Library._lang == lang and list then
				for _, w in ipairs(list) do pcall(refresh, w[1], w[2], w[3]) end
			end
		else
			failed[id] = os.clock()
		end
	end

	local function takeQueuedBatch()
		-- Work on the selected language first, and group nearby labels into one request.
		local targetLang
		for _, item in ipairs(queue) do
			if item[1] == Library._lang then targetLang = Library._lang break end
		end
		targetLang = targetLang or (queue[1] and queue[1][1])
		if not targetLang then return nil end

		local batch, chars, i = {}, 0, 1
		while i <= #queue and #batch < MAX_BATCH_ITEMS do
			local item = queue[i]
			if item[1] == targetLang then
				local size = #item[2]
				if #batch > 0 and chars + size > MAX_BATCH_CHARS then
					i += 1
				else
					table.remove(queue, i)
					table.insert(batch, item)
					chars += size
				end
			else
				i += 1
			end
		end
		return batch
	end

	local function pump()
		while activeWorkers < MAX_TRANSLATION_WORKERS and #queue > 0 do
			activeWorkers += 1
			task.spawn(function()
				while true do
					local batch = takeQueuedBatch()
					if not batch or #batch == 0 then break end
					local lang = batch[1][1]
					local L = Library._tr[lang]
					local results, markerParseFailed
					if L and L.code then results, markerParseFailed = googleTranslateBatch(L.code, batch) end

					if results then
						for i, item in ipairs(batch) do finish(item[1], item[2], results[i]) end
					elseif #batch == 1 then
						finish(batch[1][1], batch[1][2], nil)
					elseif markerParseFailed then
						-- The provider translated the combined text but changed our markers.
						-- Fall back per label so the text still gets translated correctly.
						for _, item in ipairs(batch) do
							local res = L and L.code and googleTranslate(L.code, item[2]) or nil
							if not res and not warned then
								warned = true
								warn("[Airflow] online translation failed; check executor HTTP access")
							end
							finish(item[1], item[2], res)
						end
					else
						-- If the provider rejects a combined request, retry each item by itself.
						-- Some providers accept short phrases even when they reject a batch.
						for _, item in ipairs(batch) do
							local res = L and L.code and googleTranslate(L.code, item[2]) or nil
							if not res and not warned then
								warned = true
								warn("[Airflow] online translation failed; check executor HTTP access")
							end
							finish(item[1], item[2], res)
						end
					end
				end
				activeWorkers -= 1
				if #queue > 0 then pump() end
			end)
		end
	end

	local function enqueue(lang, base, inst, prop, rec)
		local id = lang .. "\0" .. base
		if failed[id] and os.clock() - failed[id] < 12 then return end
		local list = waiting[id]
		if not list then
			list = {}
			waiting[id] = list
			table.insert(queue, { lang, base })
			pump()
		end
		if inst then list[#list + 1] = { inst, prop, rec } end
	end

	local function reserved(key)
		for _, n in ipairs(Library._themeOrder or {}) do
			if string.lower(n) == key then return true end
		end
		for n in pairs(Library._tr) do
			if string.lower(n) == key then return true end
		end
		return false
	end

	local function isTranslatable(s)
		if #s < 2 or #s > 400 then return false end
		if not s:find("%a") then return false end
		if s:match("^%s*[%d%p%s]+%s*$") then return false end -- numbers and punctuation only
		if not s:find("%s") then
			if s:find("%l%u") then return false end -- key names and camelCase identifiers
			if #s <= 4 and s == s:upper() then return false end -- short acronyms such as FPS/RAM
			if s:match("^[%a_]+%d+$") or s:match("^%d+[%a_]+$") then return false end -- compact IDs/versions
		end
		return true
	end

	local function translate(orig, inst, prop, rec)
		local lang = Library._lang
		if lang == "English" or type(orig) ~= "string" or orig == "" then return orig end
		local L = Library._tr[lang]
		if not L then return orig end
		if inst and inst:GetAttribute("AF_NoTranslate") then return orig end
		local key = string.lower(orig)
		if Library._protect[key] then return orig end
		local allcaps = orig == string.upper(orig) and orig ~= key
		local out = L.map[key]
		if out then
			if allcaps then out = upperUtf8(out) end
			return out
		end
		for _, p in ipairs(L.patterns) do
			local r, n = string.gsub(orig, p[1], p[2])
			if n > 0 then return r end
		end
		-- no dictionary entry: use the cached / online translation (this is what translates YOUR tabs and elements)
		if not (Library.AutoTranslate and L.code and isTranslatable(orig)) or reserved(key) then return orig end
		local base = allcaps and (string.sub(orig, 1, 1) .. string.sub(key, 2)) or orig
		local cached = cacheFor(lang)[base]
		if cached then return allcaps and upperUtf8(cached) or cached end
		enqueue(lang, base, inst, prop, rec)
		return orig
	end

	refresh = function(inst, prop, rec)
		local cur = inst[prop]
		if cur ~= rec.shown then
			rec.orig = cur -- someone else changed the text, treat it as the new original
		end
		local out = translate(rec.orig, inst, prop, rec)
		rec.shown = out
		if out ~= cur then inst[prop] = out end
	end

	local function track(inst)
		if tracked[inst] then return end
		local props = PROPS[inst.ClassName]
		if not props then return end
		if inst:GetAttribute("AF_NoTranslate") then return end
		local recs = {}
		tracked[inst] = recs
		for _, prop in ipairs(props) do
			local rec = { orig = inst[prop], shown = inst[prop] }
			recs[prop] = rec
			inst:GetPropertyChangedSignal(prop):Connect(function() refresh(inst, prop, rec) end)
			if Library._lang ~= "English" then refresh(inst, prop, rec) end
		end
	end

	local function retranslateAll()
		token += 1
		local my = token
		local list = {}
		for inst, recs in pairs(tracked) do list[#list + 1] = { inst, recs } end
		task.spawn(function()
			for i, e in ipairs(list) do
				if my ~= token then return end
				for prop, rec in pairs(e[2]) do
					pcall(refresh, e[1], prop, rec)
				end
				if i % 400 == 0 then task.wait() end
			end
		end)
	end

	local hookRoot
	hookRoot = function(root)
		if typeof(root) ~= "Instance" or hooked[root] then return end
		hooked[root] = true
		track(root)
		for _, d in ipairs(root:GetDescendants()) do track(d) end
		root.DescendantAdded:Connect(function(d)
			track(d)
			-- A newly parented frame can already contain labels before it enters this tree.
			for _, child in ipairs(d:GetDescendants()) do track(child) end
			if d:IsA("LayerCollector") then hookRoot(d) end
		end)
	end

	-- Other Airflow modules use separate ScreenGuis for floating and quick-access panels.
	function Library:_translationHookRoot(root)
		hookRoot(root)
		if Library._lang ~= "English" then retranslateAll() end
		return true
	end

	local function hookWindow(win)
		if win._langHooked then return end
		win._langHooked = true
		hookRoot(win.Gui)
		for _, root in ipairs(win._themeRoots or {}) do hookRoot(root) end
		-- Floating panels and pinned controls use separate ScreenGuis from the main window.
		win:_listen("Render", function()
			for _, fl in ipairs(win._floats or {}) do
				if fl.Gui then hookRoot(fl.Gui) end
			end
			for _, fl in pairs(win._quickFloats or {}) do
				if fl.Gui then hookRoot(fl.Gui) end
			end
			for _, root in ipairs(win._themeRoots or {}) do hookRoot(root) end
		end)
	end

	local function ensure(name, code)
		if not Library._tr[name] then
			Library._tr[name] = { map = {}, patterns = {} }
			table.insert(Library._langOrder, name)
		end
		if code then Library._tr[name].code = code end
		if Library._pendingLang == name then
			Library._pendingLang = nil
			Library._lang = name
			retranslateAll()
		end
		return Library._tr[name]
	end

	for i = 2, #ORDER do
		local L = ensure(ORDER[i], CODES[ORDER[i]])
		for _, row in ipairs(ROWS) do L.map[string.lower(row[1])] = row[i] end
		for _, p in ipairs(PATTERNS) do table.insert(L.patterns, { p[1], p[i] }) end
	end
	for _, e in ipairs(EXTRA) do ensure(e[1], e[2]) end

	-- map = hand written English -> text entries (optional), code = Google language code for online translation
	function Library:AddLanguage(name, map, patterns, code)
		if type(name) ~= "string" or name == "English" then return false end
		local L = ensure(name, code)
		for en, txt in pairs(map or {}) do L.map[string.lower(tostring(en))] = tostring(txt) end
		for _, p in ipairs(patterns or {}) do
			if type(p) == "table" and type(p[1]) == "string" and type(p[2]) == "string" then table.insert(L.patterns, { p[1], p[2] }) end
		end
		if Library._lang == name then retranslateAll() end
		for _, fn in ipairs(Library._onLang) do pcall(fn, Library._lang, true) end
		return true
	end

	function Library:AddTranslations(tbl)
		for en, per in pairs(tbl or {}) do
			for lang, txt in pairs(per) do
				if lang ~= "English" then
					local L = ensure(lang)
					L.map[string.lower(tostring(en))] = tostring(txt)
				end
			end
		end
		if Library._lang ~= "English" then retranslateAll() end
	end

	function Library:SetAutoTranslate(on)
		Library.AutoTranslate = on ~= false
		retranslateAll()
	end
	function Library:ProtectText(text) -- never translate this exact text (case-insensitive)
		Library._protect[string.lower(tostring(text))] = true
	end
	function Library:GetLanguages() return table.clone(Library._langOrder) end
	function Library:GetLanguage() return Library._lang end
	function Library:T(text) return translate(text) end

	function Library:SetLanguage(name, silent)
		if type(name) ~= "string" or not Library._tr[name] then
			warn("[Airflow] unknown language: " .. tostring(name))
			return false
		end
		Library._pendingLang = nil
		Library._lang = name
		-- A user retrying a language should not be blocked by an earlier HTTP failure.
		local prefix = name .. "\0"
		for id in pairs(failed) do
			if string.sub(id, 1, #prefix) == prefix then failed[id] = nil end
		end
		retranslateAll()
		pump()
		for _, fn in ipairs(Library._onLang) do pcall(fn, name) end
		if not silent then
			for _, w in ipairs(Library.Windows) do w:_saveUISettings() end
		end
		return true
	end
	function Window:SetLanguage(name) return Library:SetLanguage(name) end
	function Window:GetLanguage() return Library._lang end

	local prevWindow = Library.Window
	Library.Window = function(self, cfg)
		-- brand / window titles are never translated
		if type(cfg) == "table" then
			local pill = type(cfg.Pill) == "table" and cfg.Pill.Title or nil
			local protected = {
				cfg.Title, cfg.Name, cfg.Subtitle, cfg.LoadingTitle, cfg.LoadingSubtitle,
				cfg.Author, cfg.Creator, cfg.Credits, pill,
			}
			for _, t in ipairs(protected) do
				if type(t) == "string" and t ~= "" then Library._protect[string.lower(t)] = true end
			end
		end
		local w = prevWindow(self, cfg)
		hookWindow(w)
		return w
	end
	Library.CreateWindow = Library.Window
end


-- ===================================================================
-- BUNDLED AMETHYST KEY SYSTEM
-- Based on the custom KeySystem source supplied with this request.
-- The system can be configured with cfg.KeySystem in Library.Window(...).
-- ===================================================================
local __AirflowBundledKeySystem
 do
local __modules = {}
local __cache = {}

local function import(path)
	local cached = __cache[path]
	if cached ~= nil then
		return cached
	end
	local loader = __modules[path]
	if not loader then
		error("module not found: " .. tostring(path))
	end
	local value = loader()
	__cache[path] = value
	return value
end

__modules["components/nothing.com/yeahnothing"] = function()

end

__modules["components/window/dialog"] = function()
-- was been removed from ui and not working anymore, dont try to add back pls

local Dialog = {}

function Dialog.new(ctx, callbacks)
	callbacks = callbacks or {}

	local C = ctx.C
	local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local state, Images, FONT_BOLD = ctx.state, ctx.images, ctx.FONT_BOLD

	local popup = make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
		Visible = false,
	}, ctx.canvas)

	local dim = make("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, popup)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, dim)

	local popupCard = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 270, 0, 132),
		BackgroundColor3 = "card",
		BorderSizePixel = 0,
	}, popup)
	round(popupCard, 12, "stroke")

	local badge = frame(popupCard, 22, 20, 32, 32, "input", 0)
	round(badge, 16, "stroke")
	make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = Images.CLOSE_ICON,
		ImageColor3 = ctx.tintIcons and "accent" or Color3.fromRGB(255, 255, 255),
	}, badge)

	local popupTitle = text(popupCard, "Close Key System?", 66, 19, 182, 16, 14, "text")
	popupTitle.FontFace = FONT_BOLD
	local popupDesc = text(popupCard, "Are you sure you want to close the Key System?", 66, 38, 182, 30, 12, "muted")
	popupDesc.TextWrapped = true
	popupDesc.TextYAlignment = Enum.TextYAlignment.Top

	local function popupButton(label, x, primary)
		local btn = make("TextButton", {
			Position = UDim2.new(0, x, 0, 86),
			Size = UDim2.new(0, 109, 0, 32),
			BackgroundColor3 = primary and "submitBg" or "btn2",
			BackgroundTransparency = primary and 0.12 or 0,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = label,
			TextSize = 13,
			TextColor3 = primary and "submitText" or "text",
			FontFace = ctx.FONT,
		}, popupCard)
		if primary then
			round(btn, 8)
		else
			round(btn, 8, "stroke")
		end
		return btn
	end

	local cancelBtn = popupButton("Cancel", 22, false)
	local confirmBtn = popupButton("Close", 139, true)

	cancelBtn.MouseEnter:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(cancelBtn, 0.15, { BackgroundColor3 = C.btn2Hover })
	end)
	cancelBtn.MouseLeave:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(cancelBtn, 0.15, { BackgroundColor3 = C.btn2 })
	end)
	confirmBtn.MouseEnter:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(confirmBtn, 0.15, { BackgroundTransparency = 0 })
	end)
	confirmBtn.MouseLeave:Connect(function()
		if state.closing or not state.popupOpen then
			return
		end
		tween(confirmBtn, 0.15, { BackgroundTransparency = 0.12 })
	end)

	local popupItems = prep(popup)
	fade(popupItems, 0)

	local function show()
		if not state.ready or state.popupOpen or state.closing then
			return
		end
		state.popupOpen = true
		popup.Visible = true
		popupCard.Position = UDim2.new(0.5, 0, 0.5, 8)
		if callbacks.onOpen then
			callbacks.onOpen()
		end
		fade(popupItems, 1, 0.22)
		tween(popupCard, 0.35, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quint)
	end

	local function hide()
		if not state.popupOpen or state.closing then
			return
		end
		state.popupOpen = false
		fade(popupItems, 0, 0.18)
		task.delay(0.2, function()
			if not state.popupOpen then
				popup.Visible = false
			end
		end)
	end

	cancelBtn.MouseButton1Click:Connect(hide)
	confirmBtn.MouseButton1Click:Connect(function()
		if callbacks.onConfirm then
			callbacks.onConfirm()
		end
	end)

	return {
		popup = popup,
		items = popupItems,
		show = show,
		hide = hide,
	}
end

return Dialog
end

__modules["components/window/notification"] = function()
local Lighting = game:GetService("Lighting")

local Notification = {}

-- NotifStyle: "1" Stripe | "2" Pill | "3" Island | "4" Ring | "5" Solid (names work too)
local STYLE_BY_NAME = { stripe = "1", pill = "2", island = "3", ring = "4", solid = "5" }

function Notification.new(ctx)
	local C = ctx.C
	local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local root, cfg, Images = ctx.root, ctx.cfg, ctx.images
	local FONT, FONT_BOLD = ctx.FONT, ctx.FONT_BOLD
	local markBoldFont = ctx.markBoldFont

	local NOTIF_W = cfg.NOTIF_W
	local NOTIF_TRANSPARENCY = cfg.NOTIF_TRANSPARENCY
	local NOTIF_COLOR = cfg.NOTIF_COLOR
	local NOTIF_BLUR = cfg.NOTIF_BLUR

	local ISLAND_W = 260
	local RING_DOTS = 28
	local MAX_NOTIFS = 4

	local WHITE = Color3.fromRGB(255, 255, 255)
	local DARK = Color3.fromRGB(11, 11, 11)

	local ICONS = {
		key = { Images.KEY, 18 },
		submit = { Images.SUBMIT, 18 },
		link = { Images.LINK, 18 },
		discord = { Images.DISCORD, 18 },
		close = { Images.CLOSE_ICON, 14 },
		moon = { Images.MOON_ICON, 14 },
	}

	local function kindColor(kind)
		if kind == "success" then
			return C.success
		elseif kind == "warn" then
			return C.warn
		elseif kind == "error" then
			return C.error
		end
		return C.accent
	end

	-- Readable icon/text color on top of a filled color
	local function contrastOn(color)
		local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
		return luminance > 0.55 and DARK or WHITE
	end

	local function cardHover()
		return NOTIF_COLOR == "bg" and C.card or C.btn2
	end

	-- Bottom-right stack (Stripe, Pill, Ring, Solid)
	local cornerHolder = make("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -8),
		Size = UDim2.new(0, NOTIF_W, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, cornerHolder)

	-- Top-center stack (Island)
	local islandHolder = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0, ISLAND_W, 1, -24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, islandHolder)

	local notifCount = 0
	local activeNotifs = {}

	local Blur = { effect = nil, users = 0 }

	function Blur.to(size, time)
		if NOTIF_BLUR <= 0 then
			return
		end
		if not Blur.effect then
			local ok, effect = pcall(function()
				local e = Instance.new("BlurEffect")
				e.Name = "AirflowBlur"
				e.Size = 0
				e.Parent = Lighting
				return e
			end)
			if not ok then
				return
			end
			Blur.effect = effect
		end
		tween(Blur.effect, time, { Size = size })
	end

	function Blur.acquire()
		Blur.users += 1
		Blur.to(NOTIF_BLUR, 0.35)
	end

	function Blur.release()
		Blur.users = math.max(Blur.users - 1, 0)
		if Blur.users == 0 and Blur.effect then
			Blur.to(0, 0.5)
		end
	end

	root.Destroying:Connect(function()
		if Blur.effect then
			Blur.effect:Destroy()
			Blur.effect = nil
		end
	end)

	-- Shared builders

	local function newWrapper(holder, width, height)
		return make("Frame", {
			LayoutOrder = notifCount,
			Size = UDim2.new(0, width, 0, height + 8),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, holder)
	end

	local function newToast(wrapper, props, radius, strokeColor)
		props.BorderSizePixel = 0
		props.AutoButtonColor = false
		props.ClipsDescendants = true
		props.Text = ""
		local toast = make("TextButton", props, wrapper)
		round(toast, radius, strokeColor)
		local stroke = toast:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Transparency = 0.35
		end
		return toast
	end

	local function label(parent, str, x, y, w, h, size, color, bold)
		local l = text(parent, str, x, y, w, h, size, color)
		if bold then
			-- Route through markBoldFont (not a raw FontFace assign) so this label
			-- is registered as bold in fontBindings; otherwise the next
			-- SetUIFont/SetTitleFont call flattens it back to the regular weight.
			markBoldFont(l)
		end
		l.TextTruncate = Enum.TextTruncate.AtEnd
		return l
	end

	local function iconImage(parent, spec, color, size)
		return make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, size, 0, size),
			BackgroundTransparency = 1,
			Image = spec[1],
			ImageColor3 = color,
		}, parent)
	end

	-- 1 · Stripe: color bar on the left + countdown line at the bottom
	local function buildStripe(title, message, color)
		local W, H = NOTIF_W, 62
		local wrapper = newWrapper(cornerHolder, W, H)
		local toast = newToast(wrapper, {
			Position = UDim2.new(0, 40, 0, 0),
			Size = UDim2.new(0, W, 0, H),
			BackgroundColor3 = C[NOTIF_COLOR],
			BackgroundTransparency = NOTIF_TRANSPARENCY,
		}, 10, C.stroke)

		round(frame(toast, 8, 10, 3, H - 20, color, 0), 2)
		label(toast, title, 22, 11, W - 36, 18, 13, C.text, true)
		label(toast, message, 22, 30, W - 36, 16, 12, C.muted)

		local trackW = W - 44
		round(frame(toast, 22, H - 9, trackW, 2, color, 0.8), 1)
		local fill = frame(toast, 22, H - 9, trackW, 2, color, 0)
		round(fill, 1)

		return {
			wrapper = wrapper,
			toast = toast,
			startPos = UDim2.new(0, 40, 0, 0),
			restPos = UDim2.new(0, 0, 0, 0),
			baseColor = C[NOTIF_COLOR],
			hoverColor = cardHover(),
			progress = function(fraction)
				tween(
					fill,
					0.06,
					{ Size = UDim2.new(0, math.floor(trackW * fraction), 0, 2) },
					Enum.EasingStyle.Linear
				)
			end,
		}
	end

	-- 2 · Pill: compact capsule; long text wraps to more lines (never cut)
	local function escapeRich(str)
		return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end

	local function buildPill(title, message, color, spec)
		local H = 36
		local wrapper = make("Frame", {
			LayoutOrder = notifCount,
			Size = UDim2.new(0, NOTIF_W, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, cornerHolder)
		make("UIPadding", { PaddingBottom = UDim.new(0, 8) }, wrapper)

		local toast = newToast(wrapper, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 40, 0, 0),
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = C[NOTIF_COLOR],
			BackgroundTransparency = NOTIF_TRANSPARENCY,
		}, H / 2, C.stroke)
		make("UISizeConstraint", { MinSize = Vector2.new(0, H) }, toast)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}, toast)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, toast)

		local badge = make("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(0, 24, 0, 24),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, toast)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
		iconImage(badge, spec, contrastOn(color), math.min(spec[2], 14))

		local rich = "<b>" .. escapeRich(title) .. "</b>"
		if message ~= "" then
			rich = rich .. '  <font color="#' .. C.muted:ToHex() .. '">' .. escapeRich(message) .. "</font>"
		end
		local body = make("TextLabel", {
			LayoutOrder = 2,
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			RichText = true,
			TextWrapped = true,
			Text = rich,
			TextSize = 13,
			TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			FontFace = FONT,
		}, toast)
		make("UISizeConstraint", { MaxSize = Vector2.new(NOTIF_W - 52, math.huge) }, body)

		return {
			wrapper = wrapper,
			toast = toast,
			startPos = UDim2.new(1, 40, 0, 0),
			restPos = UDim2.new(1, 0, 0, 0),
			baseColor = C[NOTIF_COLOR],
			hoverColor = cardHover(),
		}
	end

	-- 3 · Island: dark capsule at the top center that expands in
	local function buildIsland(title, message, color, spec)
		local W, H = ISLAND_W, 52
		local border = Color3.fromRGB(42, 42, 48)
		local wrapper = newWrapper(islandHolder, W, H)
		local toast = newToast(wrapper, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -70),
			Size = UDim2.new(0, H, 0, H),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.06,
		}, H / 2, border)

		local badge = frame(toast, 10, 10, 32, 32, color, 0)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
		iconImage(badge, spec, contrastOn(color), spec[2])

		label(toast, title, 54, 9, W - 70, 16, 13, Color3.fromRGB(244, 244, 245), true)
		label(toast, message, 54, 27, W - 70, 14, 12, Color3.fromRGB(154, 154, 162))

		return {
			wrapper = wrapper,
			toast = toast,
			baseColor = Color3.fromRGB(0, 0, 0),
			hoverColor = Color3.fromRGB(22, 22, 26),
			enter = function(items)
				fade(items, 1, 0.25)
				tween(toast, 0.4, { Position = UDim2.new(0.5, 0, 0, 0) }, Enum.EasingStyle.Quint)
				task.delay(0.12, function()
					tween(toast, 0.5, { Size = UDim2.new(0, W, 0, H) }, Enum.EasingStyle.Quint)
				end)
			end,
			leave = function(items)
				fade(items, 0, 0.25)
				tween(
					toast,
					0.3,
					{ Size = UDim2.new(0, H, 0, H) },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.In
				)
				task.delay(0.15, function()
					tween(
						toast,
						0.3,
						{ Position = UDim2.new(0.5, 0, 0, -70) },
						Enum.EasingStyle.Quint,
						Enum.EasingDirection.In
					)
				end)
			end,
		}
	end

	-- 4 · Ring: icon inside a circular timer
	local function buildRing(title, message, color, spec)
		local W, H = NOTIF_W, 60
		local wrapper = newWrapper(cornerHolder, W, H)
		local toast = newToast(wrapper, {
			Position = UDim2.new(0, 40, 0, 0),
			Size = UDim2.new(0, W, 0, H),
			BackgroundColor3 = C[NOTIF_COLOR],
			BackgroundTransparency = NOTIF_TRANSPARENCY,
		}, 10, C.stroke)

		local ringBox = frame(toast, 10, 10, 40, 40)
		local dots = {}
		for i = 0, RING_DOTS - 1 do
			local angle = (i / RING_DOTS) * math.pi * 2 - math.pi / 2
			local dot = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5 + math.cos(angle) * 0.425, 0, 0.5 + math.sin(angle) * 0.425, 0),
				Size = UDim2.new(0, 3, 0, 3),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
			}, ringBox)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			dots[#dots + 1] = dot
		end
		iconImage(ringBox, spec, ctx.tintIcons and color or WHITE, math.min(spec[2], 18))

		label(toast, title, 62, 11, W - 76, 18, 13, C.text, true)
		label(toast, message, 62, 31, W - 76, 16, 12, C.muted)

		local lastLit = RING_DOTS
		return {
			wrapper = wrapper,
			toast = toast,
			startPos = UDim2.new(0, 40, 0, 0),
			restPos = UDim2.new(0, 0, 0, 0),
			baseColor = C[NOTIF_COLOR],
			hoverColor = cardHover(),
			progress = function(fraction)
				local lit = math.ceil(fraction * RING_DOTS)
				if lit >= lastLit then
					return
				end
				for i = lit + 1, lastLit do
					tween(dots[i], 0.15, { BackgroundTransparency = 0.82 })
				end
				lastLit = lit
			end,
		}
	end

	-- 5 · Solid: filled with the status color
	local function buildSolid(title, message, color, spec)
		local W, H = NOTIF_W, 58
		local onColor = contrastOn(color)
		local wrapper = newWrapper(cornerHolder, W, H)
		local toast = newToast(wrapper, {
			Position = UDim2.new(0, 40, 0, 0),
			Size = UDim2.new(0, W, 0, H),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.04,
		}, 10, nil)

		local iconBox = frame(toast, 14, (H - 22) / 2, 22, 22)
		iconImage(iconBox, spec, onColor, math.min(spec[2] + 4, 22))

		label(toast, title, 48, 10, W - 62, 18, 13, onColor, true)
		label(toast, message, 48, 30, W - 62, 16, 12, onColor:Lerp(color, 0.35))

		return {
			wrapper = wrapper,
			toast = toast,
			startPos = UDim2.new(0, 40, 0, 0),
			restPos = UDim2.new(0, 0, 0, 0),
			baseColor = color,
			hoverColor = color:Lerp(WHITE, 0.12),
		}
	end

	local STYLES = {
		["1"] = buildStripe,
		["2"] = buildPill,
		["3"] = buildIsland,
		["4"] = buildRing,
		["5"] = buildSolid,
	}

	local function resolveKey()
		local raw = ctx.getStyle and ctx.getStyle() or "1"
		local key = (tostring(raw):lower():gsub("%s+", ""))
		key = STYLE_BY_NAME[key] or key
		return STYLES[key] and key or "1"
	end

	local function resolveStyle()
		return STYLES[resolveKey()]
	end

	local function notify(title, message, kind, iconKey, duration)
		kind = kind or "info"
		duration = duration or 3.5
		title = tostring(title or "")
		message = tostring(message or "")
		local color = kindColor(kind)
		local spec = ICONS[iconKey] or (kind == "error" and ICONS.close or ICONS.key)

		notifCount += 1
		Blur.acquire()

		local n = resolveStyle()(title, message, color, spec)
		local wrapper, toast = n.wrapper, n.toast

		local items = prep(toast)
		fade(items, 0)

		local handle = {}
		local dismissed = false
		function handle.dismiss()
			if dismissed then
				return
			end
			dismissed = true
			Blur.release()
			local idx = table.find(activeNotifs, handle)
			if idx then
				table.remove(activeNotifs, idx)
			end
			if n.leave then
				n.leave(items)
			else
				fade(items, 0, 0.25)
				tween(toast, 0.3, { Position = n.startPos }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			end
			task.delay(0.28, function()
				local size = wrapper.Size
				local height = wrapper.AbsoluteSize.Y
				wrapper.AutomaticSize = Enum.AutomaticSize.None
				wrapper.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, height)
				tween(wrapper, 0.2, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0) })
				task.delay(0.22, function()
					wrapper:Destroy()
				end)
			end)
		end

		toast.MouseButton1Click:Connect(handle.dismiss)

		if n.enter then
			n.enter(items)
		else
			fade(items, 1, 0.3)
			tween(toast, 0.45, { Position = n.restPos }, Enum.EasingStyle.Quint)
		end

		local hovering, hoverSince = false, 0
		toast.MouseEnter:Connect(function()
			if dismissed then
				return
			end
			hovering = true
			hoverSince = os.clock()
			tween(toast, 0.15, { BackgroundColor3 = n.hoverColor })
		end)
		toast.MouseLeave:Connect(function()
			if dismissed then
				return
			end
			hovering = false
			tween(toast, 0.15, { BackgroundColor3 = n.baseColor })
		end)

		task.spawn(function()
			local remaining = duration
			local started = os.clock()
			local last = started
			while not dismissed do
				task.wait(0.05)
				local now = os.clock()
				if not (hovering and now - hoverSince < 8) then
					remaining -= now - last
				end
				last = now
				if n.progress and now - started > 0.35 then
					n.progress(math.clamp(remaining / duration, 0, 1))
				end
				if remaining <= 0 then
					handle.dismiss()
					break
				end
			end
		end)

		table.insert(activeNotifs, handle)
		while #activeNotifs > MAX_NOTIFS do
			activeNotifs[1].dismiss()
		end

		return handle
	end

	local function dismissAll()
		for i = #activeNotifs, 1, -1 do
			activeNotifs[i].dismiss()
		end
	end

	return {
		notify = notify,
		dismissAll = dismissAll,
		styleKey = resolveKey,
		blur = Blur,
	}
end

return Notification
end

__modules["components/window/pages"] = function()
-- src/components/window/pages.lua
-- Page 2 of the window. It sits right below the Key System: a down arrow at the bottom
-- of the Key System slides the Key System up and brings this page in (a topbar, the Tabs
-- under it, and the content of the selected Tab: Sections and Paragraphs).
--
--   local OphynWindow = KeySystem.new({ ... })
--
--   local Tab = OphynWindow({ Title = "Main", Icon = "rbxassetid://..." })
--
--   Tab:Section({ Title = "Section", Icon = "rbxassetid://..." })
--
--   -- Tabs style: KeySystem:SetTabsStyle("1") = column on the left (default),
--   --             KeySystem:SetTabsStyle("2") = row right under the topbar.
--
--   -- Every Icon also accepts a Lucide icon name (https://lucide.dev/icons), loaded from
--   -- github.com/Footagesus/Icons the first time one is used:
--   local Tab = OphynWindow({ Title = "Main", Icon = "house" })
--   Tab:Section({ Title = "Section", Icon = "lucide:settings" })
--
--   Tab:Paragraph({
--       Title = "Paragraph",
--       Desc = "Test Paragraph",
--       Color = "Red", -- leave it blank to follow the theme
--       Buttons = { { Icon = "rbxassetid://...", Title = "Button 1", Callback = function() end } },
--   })

local Pages = {}

local NAMED_COLORS = {
	red = Color3.fromRGB(229, 57, 53),
	orange = Color3.fromRGB(245, 124, 0),
	yellow = Color3.fromRGB(250, 204, 21),
	green = Color3.fromRGB(34, 160, 80),
	teal = Color3.fromRGB(20, 160, 150),
	cyan = Color3.fromRGB(6, 182, 212),
	blue = Color3.fromRGB(59, 130, 246),
	indigo = Color3.fromRGB(99, 102, 241),
	purple = Color3.fromRGB(147, 51, 234),
	pink = Color3.fromRGB(236, 72, 153),
	grey = Color3.fromRGB(100, 100, 108),
	gray = Color3.fromRGB(100, 100, 108),
	white = Color3.fromRGB(245, 245, 245),
	black = Color3.fromRGB(16, 16, 16),
}

-- Accepts a Color3, a color name ("Red", "Blue", ...) or a hex string ("#RRGGBB").
-- Returns nil for anything else, which makes the Paragraph follow the theme.
local function parseColor(value)
	if value == nil or value == "" then
		return nil
	end
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		local named = NAMED_COLORS[value:lower()]
		if named then
			return named
		end
		local hex = value:match("^#?(%x%x%x%x%x%x)$")
		if hex then
			return Color3.fromHex(hex)
		end
	end
	return nil
end

function Pages.new(ctx)
	local C, make, round = ctx.C, ctx.make, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local setRole, icon, assetId = ctx.setRole, ctx.icon, ctx.assetId
	local contrastOn, iconRole, logoRole = ctx.contrastOn, ctx.iconRole, ctx.logoRole
	local FONT, FONT_BOLD, Images = ctx.FONT, ctx.FONT_BOLD, ctx.images
	local state, content, canvas = ctx.state, ctx.content, ctx.canvas
	local W, H = ctx.width, ctx.height

	local TOPBAR_H = 38
	local SIDE_W = 124
	local SLIDE_TIME = 0.55
	local Quint = Enum.EasingStyle.Quint

	-- Section title look: a bit bigger than before and slightly see-through
	local SECTION_TEXT_SIZE = 15
	local SECTION_TEXT_TRANSPARENCY = 0.35

	-- Switching Tabs: the content rises a few pixels while its elements fade in one after
	-- the other (the stagger is capped so a Tab with many elements doesn't feel slow)
	local TAB_SLIDE = 10
	local TAB_IN_TIME = 0.32
	local TAB_STAGGER = 0.045
	local TAB_STAGGER_MAX = 0.4

	-- Both arrows (down: show the Tabs / up: back to the Key System) reuse the Submit
	-- button's icon. If that icon points right, 90 turns it to point down and -90 up;
	-- change this if the arrows end up facing the wrong way.
	local NEXT_ARROW_ROTATION = 90
	local BACK_ARROW_ROTATION = -NEXT_ARROW_ROTATION

	-- Tabs style 2 (a row under the topbar)
	local TABS_BAR_H = 34
	local TAB_H_STYLE2 = 26

	-- false when "Change icons color" is off: icons stay white and are never recolored
	local tintIcons = type(iconRole("muted")) == "string"

	-- The arrows: the Submit button's icon in one single ImageLabel, rotated on the label
	-- itself (not on a parent frame) and placed with plain offsets, so it renders right
	-- from the first frame. `drop` pushes it down a few pixels inside its button.
	local function arrowIcon(parent, rotation, drop)
		local img = make("ImageLabel", {
			Name = "ArrowIcon",
			Position = UDim2.new(0.5, -8, 0.5, -8 + (drop or 0)),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			Image = Images.SUBMIT,
			ImageColor3 = iconRole("muted"),
			Rotation = rotation,
			ZIndex = 6,
		}, parent)
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ img })
			end)
		end)
		return img
	end

	local function tintArrow(img, color)
		if tintIcons then
			tween(img, 0.15, { ImageColor3 = color })
		end
	end

	local function line(parent, x, y, w, h)
		return make("Frame", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, w, 0, h),
			BackgroundColor3 = "stroke",
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, parent)
	end

	---------------------------------------------------------------------------
	-- The page itself: starts one window-height below, hidden
	---------------------------------------------------------------------------
	local page = make("Frame", {
		Name = "Page2",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, H),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, canvas)

	-- Topbar: logo + title on the left, back arrow + close on the right
	local topbar = make("Frame", {
		Name = "Topbar",
		Size = UDim2.new(0, W, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, page)

	make("ImageLabel", {
		Position = UDim2.new(0, 14, 0, 9),
		Size = UDim2.new(0, 24, 0, 20),
		BackgroundTransparency = 1,
		Image = ctx.logo,
		ImageColor3 = logoRole("accent"),
		ScaleType = Enum.ScaleType.Fit,
	}, topbar)

	local pageTitle = make("TextLabel", {
		Position = UDim2.new(0, 46, 0, 0),
		Size = UDim2.new(0, W - 46 - 84, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = ctx.title,
		TextSize = 14,
		TextColor3 = "text",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = FONT_BOLD,
	}, topbar)
	ctx.markTitleFont(pageTitle)

	local function topButton(rightOffset)
		local btn = make("TextButton", {
			Name = "TopButton",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -rightOffset, 0, 6),
			Size = UDim2.new(0, 26, 0, 26),
			BackgroundColor3 = "card",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 5,
		}, topbar)
		make("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
		return btn
	end

	local closeBtn = topButton(12)
	local closeIcon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = Images.CLOSE_ICON,
		ImageColor3 = iconRole("muted"),
		ZIndex = 6,
	}, closeBtn)

	local backBtn = topButton(40)
	local backIcon = arrowIcon(backBtn, BACK_ARROW_ROTATION, 0)

	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.15, { BackgroundTransparency = 0 })
		if tintIcons then
			tween(closeIcon, 0.15, { ImageColor3 = C.text })
		end
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.15, { BackgroundTransparency = 1 })
		if tintIcons then
			tween(closeIcon, 0.15, { ImageColor3 = C.muted })
		end
	end)
	backBtn.MouseEnter:Connect(function()
		tween(backBtn, 0.15, { BackgroundTransparency = 0 })
		tintArrow(backIcon, C.text)
	end)
	backBtn.MouseLeave:Connect(function()
		tween(backBtn, 0.15, { BackgroundTransparency = 1 })
		tintArrow(backIcon, C.muted)
	end)

	-- Tabs style: "1" = column on the left, "2" = row right under the topbar
	local tabsStyle = "1"
	local function normalizeStyle(value)
		value = tostring(value or "1"):lower()
		if value == "2" or value == "horizontal" or value == "row" then
			return "2"
		end
		return "1"
	end
	if ctx.getTabsStyle then
		tabsStyle = normalizeStyle(ctx.getTabsStyle())
	end

	-- Style 1 draws the line under the topbar; style 2 draws it under the row of Tabs
	local topLine = line(page, 14, TOPBAR_H, W - 28, 1)
	local tabsLine = line(page, 14, TOPBAR_H + TABS_BAR_H, W - 28, 1)
	local sideLine = line(page, SIDE_W, TOPBAR_H + 10, 1, H - TOPBAR_H - 20)

	-- Tabs (a column in style 1, a row in style 2)
	local sidebar = make("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollBarThickness = 0,
	}, page)
	local sideLayout = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	local sidePadding = make("UIPadding", {}, sidebar)

	-- Where the selected Tab's content shows up
	local holder = make("Frame", {
		Name = "TabContent",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, page)

	-- mouse wheel scrolls the row sideways in style 2
	sidebar.InputChanged:Connect(function(input)
		if tabsStyle == "2" and input.UserInputType == Enum.UserInputType.MouseWheel then
			local maxX = math.max(0, sidebar.AbsoluteCanvasSize.X - sidebar.AbsoluteWindowSize.X)
			local x = sidebar.CanvasPosition.X - input.Position.Z * 30
			sidebar.CanvasPosition = Vector2.new(math.clamp(x, 0, maxX), 0)
		end
	end)

	local tabs = {}
	local current = nil

	local function applyTabsStyle()
		local row = tabsStyle == "2"

		topLine.Visible = not row
		sideLine.Visible = not row
		tabsLine.Visible = row

		sidebar.CanvasPosition = Vector2.new(0, 0)
		sidebar.AutomaticCanvasSize = Enum.AutomaticSize.None
		sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
		if row then
			sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H)
			sidebar.Size = UDim2.new(0, W, 0, TABS_BAR_H)
			sidebar.ScrollingDirection = Enum.ScrollingDirection.X
			sidebar.AutomaticCanvasSize = Enum.AutomaticSize.X
			sideLayout.FillDirection = Enum.FillDirection.Horizontal
			sideLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			sidePadding.PaddingTop = UDim.new(0, 0)
			sidePadding.PaddingBottom = UDim.new(0, 0)
			sidePadding.PaddingLeft = UDim.new(0, 12)
			sidePadding.PaddingRight = UDim.new(0, 12)

			holder.Position = UDim2.new(0, 0, 0, TOPBAR_H + TABS_BAR_H + 1)
			holder.Size = UDim2.new(0, W, 0, H - TOPBAR_H - TABS_BAR_H - 1)
		else
			sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H + 1)
			sidebar.Size = UDim2.new(0, SIDE_W, 0, H - TOPBAR_H - 1)
			sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
			sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
			sideLayout.FillDirection = Enum.FillDirection.Vertical
			sideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			sidePadding.PaddingTop = UDim.new(0, 10)
			sidePadding.PaddingBottom = UDim.new(0, 10)
			sidePadding.PaddingLeft = UDim.new(0, 10)
			sidePadding.PaddingRight = UDim.new(0, 10)

			holder.Position = UDim2.new(0, SIDE_W + 1, 0, TOPBAR_H + 1)
			holder.Size = UDim2.new(0, W - SIDE_W - 1, 0, H - TOPBAR_H - 1)
		end

		for _, tab in ipairs(tabs) do
			tab.applyStyle()
		end
		if current then
			current.refresh()
		end
	end

	---------------------------------------------------------------------------
	-- Sliding between the Key System and this page
	---------------------------------------------------------------------------
	local opened, moving = false, false

	local function open()
		if opened or moving then
			return
		end
		opened, moving = true, true
		if ctx.onOpen then
			ctx.onOpen()
		end
		if current then
			current.refresh()
		end
		page.Visible = true
		tween(page, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Quint)
		tween(content, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, -H) }, Quint)
		task.delay(SLIDE_TIME + 0.05, function()
			moving = false
		end)
	end

	local function back()
		if not opened or moving then
			return
		end
		opened, moving = false, true
		tween(page, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, H) }, Quint)
		tween(content, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Quint)
		task.delay(SLIDE_TIME + 0.05, function()
			if not opened then
				page.Visible = false
			end
			moving = false
		end)
	end

	-- Used when the whole UI closes while this page is showing
	local function fadeOut(time)
		if not page.Visible then
			return
		end
		fade(prep(page), 0, time)
		task.delay(time, function()
			page.Visible = false
		end)
	end

	-- The down arrow, in the middle of the bottom of the Key System. It only shows up
	-- once there is at least one Tab, so a script that never creates one doesn't end up
	-- with an arrow that leads to an empty page.
	local nextBtn = make("TextButton", {
		Name = "NextPage",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0, W / 2, 0, H - 2),
		Size = UDim2.new(0, 40, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 5,
	}, content)
	-- Same icon as the Submit button (Images.SUBMIT), turned to point down
	local nextIcon = arrowIcon(nextBtn, NEXT_ARROW_ROTATION, 2)

	nextBtn.MouseEnter:Connect(function()
		tintArrow(nextIcon, C.text)
	end)
	nextBtn.MouseLeave:Connect(function()
		tintArrow(nextIcon, C.muted)
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		open()
	end)

	backBtn.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		back()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		ctx.requestClose()
	end)

	---------------------------------------------------------------------------
	-- Tabs
	---------------------------------------------------------------------------
	local function styleTab(tab, on)
		tween(tab.btn, 0.15, { BackgroundTransparency = on and 0 or 1 })
		setRole(tab.label, "TextColor3", on and "text" or "muted")
		if tab.iconImage then
			local role = iconRole(on and "accent" or "muted")
			if type(role) == "string" then
				setRole(tab.iconImage, "ImageColor3", role)
			end
		end
		tab.scroll.Visible = on
	end

	-- originals[inst][prop] = the resting transparency of that property, captured only once.
	-- Switching Tabs quickly (while an animation is still running) then never records a
	-- half-faded value as the "normal" one.
	local originals = setmetatable({}, { __mode = "k" })

	local function snapshot(child)
		local items = prep(child)
		for _, it in ipairs(items) do
			local saved = originals[it[1]]
			if not saved then
				saved = {}
				originals[it[1]] = saved
			end
			if saved[it[2]] == nil then
				saved[it[2]] = it[3]
			else
				it[3] = saved[it[2]]
			end
		end
		return items
	end

	-- Plays when a Tab becomes the selected one: the whole content rises a little and
	-- every element (Section / Paragraph) fades in, one after the other.
	local function animateIn(tab)
		tab.animId = (tab.animId or 0) + 1
		local id = tab.animId

		local children = {}
		for _, child in ipairs(tab.scroll:GetChildren()) do
			if child:IsA("GuiObject") then
				children[#children + 1] = child
			end
		end
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		if #children == 0 then
			return
		end

		local lists = {}
		for i, child in ipairs(children) do
			local items = snapshot(child)
			fade(items, 0) -- start fully transparent
			lists[i] = items
		end

		tab.scroll.Position = UDim2.new(0, 0, 0, TAB_SLIDE)
		tween(tab.scroll, TAB_IN_TIME + 0.08, { Position = UDim2.new(0, 0, 0, 0) }, Quint)

		local step = math.min(TAB_STAGGER, TAB_STAGGER_MAX / #children)
		for i, items in ipairs(lists) do
			task.delay((i - 1) * step, function()
				if tab.animId ~= id then
					return -- a newer animation took over this Tab
				end
				fade(items, 1, TAB_IN_TIME)
			end)
		end
	end

	local function selectTab(tab, animate)
		if current == tab then
			return
		end
		if current then
			styleTab(current, false)
		end
		current = tab
		styleTab(tab, true)
		tab.refresh()
		if animate ~= false and (opened or page.Visible) then
			animateIn(tab)
		end
	end

	-- OphynWindow({ Title = "...", Icon = "..." }) -> Tab
	local function createTab(props)
		if type(props) ~= "table" then
			props = { Title = props }
		end
		local title = props.Title ~= nil and tostring(props.Title) or "Tab"
		local image = assetId(props.Icon)

		local tab = {}

		-- Tab button: the icon comes first, then the text. The icon + text live in `inner`
		-- (it holds the layout and the side padding, so the button can size itself to the
		-- text in style 2).
		tab.btn = make("TextButton", {
			Name = "Tab",
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = "card",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = #tabs + 1,
		}, sidebar)
		round(tab.btn, 7)

		tab.inner = make("Frame", {
			Name = "Inner",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, tab.btn)
		tab.pad = make("UIPadding", {}, tab.inner)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tab.inner)

		if image then
			local iconHolder = icon(tab.inner, 0, 0, "muted", image)
			iconHolder.LayoutOrder = 1
			tab.iconImage = iconHolder:FindFirstChild("iconimage")
		end

		tab.label = make("TextLabel", {
			Size = UDim2.new(1, image and -22 or 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = title,
			TextSize = 12,
			TextColor3 = "muted",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = FONT,
			LayoutOrder = 2,
		}, tab.inner)

		-- Lays the button out for the current Tabs style (also runs when the style changes)
		tab.applyStyle = function()
			if tabsStyle == "2" then
				tab.btn.Size = UDim2.new(0, 0, 0, TAB_H_STYLE2)
				tab.btn.AutomaticSize = Enum.AutomaticSize.X
				tab.inner.Size = UDim2.new(0, 0, 1, 0)
				tab.inner.AutomaticSize = Enum.AutomaticSize.X
				tab.pad.PaddingLeft = UDim.new(0, 10)
				tab.pad.PaddingRight = UDim.new(0, 12)
				tab.label.Size = UDim2.new(0, 0, 1, 0)
				tab.label.AutomaticSize = Enum.AutomaticSize.X
			else
				tab.btn.AutomaticSize = Enum.AutomaticSize.None
				tab.btn.Size = UDim2.new(1, 0, 0, 30)
				tab.inner.AutomaticSize = Enum.AutomaticSize.None
				tab.inner.Size = UDim2.new(1, 0, 1, 0)
				tab.pad.PaddingLeft = UDim.new(0, 12)
				tab.pad.PaddingRight = UDim.new(0, 8)
				tab.label.AutomaticSize = Enum.AutomaticSize.None
				tab.label.Size = UDim2.new(1, image and -22 or 0, 1, 0)
			end
		end
		tab.applyStyle()

		-- The content of this Tab
		tab.scroll = make("ScrollingFrame", {
			Name = "TabContent",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			ScrollBarThickness = 2,
			ScrollBarImageTransparency = 0.45,
			Visible = false,
		}, holder)
		setRole(tab.scroll, "ScrollBarImageColor3", "muted")

		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tab.scroll)
		make("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 14),
		}, tab.scroll)

		tab.refresh = function()
			tab.scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(tab.refresh)

		tab.btn.MouseEnter:Connect(function()
			if current ~= tab then
				tween(tab.btn, 0.12, { BackgroundTransparency = 0.5 })
			end
		end)
		tab.btn.MouseLeave:Connect(function()
			if current ~= tab then
				tween(tab.btn, 0.12, { BackgroundTransparency = 1 })
			end
		end)
		tab.btn.MouseButton1Click:Connect(function()
			if state.closing then
				return
			end
			selectTab(tab)
		end)

		tabs[#tabs + 1] = tab
		if not nextBtn.Visible then
			nextBtn.Visible = true
			-- first time the arrow shows up: make the engine request/draw its image again
			task.defer(function()
				nextIcon.Image = ""
				nextIcon.Image = Images.SUBMIT
			end)
		end
		if not current then
			selectTab(tab, false)
		end

		-- Tab:Section / Tab:Paragraph
		local order = 0
		local function nextOrder()
			order = order + 1
			return order
		end

		local obj = {}

		function obj:Select()
			selectTab(tab)
			return self
		end

		-- Tab:Section({ Title = "...", Icon = "..." }): the icon comes first, then the text
		function obj:Section(p)
			p = type(p) == "table" and p or {}
			local sectionImage = assetId(p.Icon)

			local row = make("Frame", {
				Name = "Section",
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, tab.scroll)
			make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 7),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, row)

			if sectionImage then
				local iconHolder = icon(row, 0, 0, "accent", sectionImage)
				iconHolder.LayoutOrder = 1
			end

			local label = make("TextLabel", {
				Size = UDim2.new(1, sectionImage and -23 or 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = p.Title ~= nil and tostring(p.Title) or "Section",
				TextSize = SECTION_TEXT_SIZE,
				TextColor3 = "text",
				TextTransparency = SECTION_TEXT_TRANSPARENCY,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = FONT_BOLD,
				LayoutOrder = 2,
			}, row)

			local section = { Frame = row }
			function section:SetTitle(str)
				label.Text = tostring(str)
				return self
			end
			function section:Destroy()
				row:Destroy()
			end
			return section
		end

		-- Tab:Paragraph({ Title, Desc, Color, Buttons = { { Icon, Title, Callback } } })
		function obj:Paragraph(p)
			p = type(p) == "table" and p or {}
			local color = parseColor(p.Color) -- nil: follows the theme
			local onColor = color and contrastOn(color) or nil

			local box = make("Frame", {
				Name = "Paragraph",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = color or "card",
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, tab.scroll)
			round(box, 8, (not color) and "stroke" or nil)
			make("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, box)
			make("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, box)

			local function paragraphLabel(layoutOrder, size, font, textColor, str, transparency)
				return make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = str,
					TextSize = size,
					TextColor3 = textColor,
					TextTransparency = transparency,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					FontFace = font,
					LayoutOrder = layoutOrder,
					Visible = str ~= "",
				}, box)
			end

			local titleText = p.Title ~= nil and tostring(p.Title) or ""
			local descText = p.Desc ~= nil and tostring(p.Desc) or ""
			local titleLabel = paragraphLabel(1, 13, FONT_BOLD, onColor or "text", titleText, 0)
			local descLabel = paragraphLabel(2, 12, FONT, onColor or "muted", descText, onColor and 0.2 or 0)

			local buttons = type(p.Buttons) == "table" and p.Buttons or {}
			if #buttons > 0 then
				local row = make("Frame", {
					Name = "Buttons",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 3,
				}, box)
				make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Wraps = true,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, row)

				for i, b in ipairs(buttons) do
					if type(b) == "table" then
						local btn = make("TextButton", {
							Name = "Button",
							Size = UDim2.new(0, 0, 0, 26),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundColor3 = color and onColor or "btn2",
							BackgroundTransparency = color and 0.86 or 0,
							BorderSizePixel = 0,
							AutoButtonColor = false,
							Text = "",
							LayoutOrder = i,
						}, row)
						round(btn, 7, (not color) and "stroke" or nil)
						make("UIPadding", {
							PaddingLeft = UDim.new(0, 9),
							PaddingRight = UDim.new(0, 10),
						}, btn)
						make("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 6),
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}, btn)

						-- icon first, then the text
						local buttonImage = assetId(b.Icon)
						if buttonImage then
							local iconHolder = icon(btn, 0, 0, onColor or "text", buttonImage)
							iconHolder.LayoutOrder = 1
						end
						make("TextLabel", {
							Size = UDim2.new(0, 0, 1, 0),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = b.Title ~= nil and tostring(b.Title) or "Button",
							TextSize = 12,
							TextColor3 = onColor or "text",
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							FontFace = FONT,
							LayoutOrder = 2,
						}, btn)

						btn.MouseEnter:Connect(function()
							if color then
								tween(btn, 0.12, { BackgroundTransparency = 0.72 })
							else
								tween(btn, 0.12, { BackgroundColor3 = C.btn2Hover })
							end
						end)
						btn.MouseLeave:Connect(function()
							if color then
								tween(btn, 0.12, { BackgroundTransparency = 0.86 })
							else
								tween(btn, 0.12, { BackgroundColor3 = C.btn2 })
							end
						end)
						btn.MouseButton1Click:Connect(function()
							if state.closing or type(b.Callback) ~= "function" then
								return
							end
							task.spawn(function()
								local ok, err = pcall(b.Callback)
								if not ok then
									warn("[Ophyn] Button callback error: " .. tostring(err))
								end
							end)
						end)
					end
				end
			end

			local paragraph = { Frame = box }
			function paragraph:SetTitle(str)
				titleLabel.Text = tostring(str)
				titleLabel.Visible = titleLabel.Text ~= ""
				return self
			end
			function paragraph:SetDesc(str)
				descLabel.Text = tostring(str)
				descLabel.Visible = descLabel.Text ~= ""
				return self
			end
			function paragraph:Destroy()
				box:Destroy()
			end
			return paragraph
		end

		return obj
	end

	applyTabsStyle()

	-- KeySystem:SetTabsStyle("1" / "2") works before or after the window exists: ui.lua
	-- calls this applier whenever the style changes. It returns false once the window is gone.
	if ctx.registerTabsStyle then
		ctx.registerTabsStyle(function()
			if not page.Parent then
				return false
			end
			local style = normalizeStyle(ctx.getTabsStyle and ctx.getTabsStyle())
			if style ~= tabsStyle then
				tabsStyle = style
				applyTabsStyle()
			end
			return true
		end)
	end

	return {
		createTab = createTab,
		open = open,
		back = back,
		fadeOut = fadeOut,
		isOpen = function()
			return opened
		end,
	}
end

return Pages
end

__modules["components/window/ui"] = function()
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local Images = import("images/images")
local Notification = import("components/window/notification")
local Variables = import("variables")
local Jnkie = import("utilities/jnkie")
local Platoboost = import("utilities/platoboost")
local Panda = import("utilities/panda")
local Pages = import("components/window/pages")
local Lucide = import("utilities/lucide")

local FONT = Font.new(Images.FONT, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new(Images.FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local GLOW = Images.GLOW
local CLOSE_ICON = Images.CLOSE_ICON
local MOON_ICON = Images.MOON_ICON

local FINAL_W, FINAL_H = 460, 260

local NOTIF_W, NOTIF_H = 300, 70
local NOTIF_TRANSPARENCY = 0.28
local NOTIF_COLOR = "bg"
local NOTIF_BLUR = 6

local CHECK_TIME = 1
local SAVED_CHECK_TIME = 0.15

local WHITE = Color3.fromRGB(255, 255, 255)
local settings = { tintIcons = true, tintLogo = true }

local function asBool(v, default)
	if v == nil then
		return default
	end
	if type(v) == "string" then
		return v:lower() == "true"
	end
	return v == true
end

local function assetId(v)
	if v == nil or v == "" then
		return nil
	end
	local str = tostring(v)
	if str:match("^%d+$") then
		return "rbxassetid://" .. str
	end
	return str
end

local function iconRole(role)
	return settings.tintIcons and role or WHITE
end
local function logoRole(role)
	return settings.tintLogo and role or WHITE
end

local THEME_ORDER = {
	"Carmim",
	"Plant",
	"Plant-Dark",
	"Dark",
	"Light",
	"Violet",
	"Midnight",
	"Amber",
	"Indigo",
	"Amethyst",
}

local THEMES = {
	Amethyst = {
		bg = Color3.fromRGB(20, 16, 20),
		input = Color3.fromRGB(24, 19, 24),
		card = Color3.fromRGB(28, 22, 28),
		stroke = Color3.fromRGB(40, 32, 41),
		btn2 = Color3.fromRGB(42, 36, 43),
		btn2Hover = Color3.fromRGB(54, 47, 55),
		text = Color3.fromRGB(233, 229, 234),
		muted = Color3.fromRGB(125, 115, 126),
		accent = Color3.fromRGB(235, 199, 246),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 210, 140),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(235, 199, 246),
		submitText = Color3.fromRGB(24, 18, 26),

		glowBase = Color3.fromRGB(226, 218, 230),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(235, 199, 246),

		confetti = {
			Color3.fromRGB(235, 199, 246),
			Color3.fromRGB(120, 210, 140),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(150, 190, 255),
		},
	},

	Carmim = {
		bg = Color3.fromRGB(10, 10, 10),
		input = Color3.fromRGB(16, 14, 14),
		card = Color3.fromRGB(20, 17, 17),
		stroke = Color3.fromRGB(38, 32, 32),
		btn2 = Color3.fromRGB(32, 28, 28),
		btn2Hover = Color3.fromRGB(46, 40, 40),
		text = Color3.fromRGB(240, 236, 236),
		muted = Color3.fromRGB(130, 122, 122),
		accent = Color3.fromRGB(230, 45, 55),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 210, 140),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(139, 17, 27),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 120, 120),
		glowFrom = Color3.fromRGB(255, 90, 90),
		glowTo = Color3.fromRGB(200, 20, 35),

		confetti = {
			Color3.fromRGB(230, 45, 55),
			Color3.fromRGB(255, 120, 120),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(150, 20, 30),
		},
	},

	Plant = {
		bg = Color3.fromRGB(28, 94, 56),
		input = Color3.fromRGB(23, 78, 46),
		card = Color3.fromRGB(34, 108, 65),
		stroke = Color3.fromRGB(58, 140, 92),
		btn2 = Color3.fromRGB(44, 122, 74),
		btn2Hover = Color3.fromRGB(56, 140, 88),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(188, 226, 202),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(200, 255, 210),
		error = Color3.fromRGB(255, 150, 150),

		submitBg = Color3.fromRGB(96, 205, 122),
		submitText = Color3.fromRGB(14, 66, 36),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(235, 255, 240),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(150, 235, 170),
			Color3.fromRGB(96, 205, 122),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(210, 255, 220),
		},
	},

	["Plant-Dark"] = {
		bg = Color3.fromRGB(10, 10, 10),
		input = Color3.fromRGB(14, 16, 14),
		card = Color3.fromRGB(18, 22, 19),
		stroke = Color3.fromRGB(34, 42, 36),
		btn2 = Color3.fromRGB(28, 34, 29),
		btn2Hover = Color3.fromRGB(40, 48, 42),
		text = Color3.fromRGB(238, 242, 238),
		muted = Color3.fromRGB(122, 132, 124),
		accent = Color3.fromRGB(70, 214, 110),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 220, 150),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(22, 101, 52),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(110, 255, 150),
		glowFrom = Color3.fromRGB(90, 240, 130),
		glowTo = Color3.fromRGB(30, 170, 70),

		confetti = {
			Color3.fromRGB(70, 214, 110),
			Color3.fromRGB(150, 245, 175),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(22, 101, 52),
		},
	},

	Dark = {
		bg = Color3.fromRGB(10, 10, 10),
		input = Color3.fromRGB(18, 18, 18),
		card = Color3.fromRGB(23, 23, 23),
		stroke = Color3.fromRGB(46, 46, 46),
		btn2 = Color3.fromRGB(34, 34, 34),
		btn2Hover = Color3.fromRGB(48, 48, 48),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(150, 150, 150),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(240, 176, 108),
		success = Color3.fromRGB(120, 210, 140),
		error = Color3.fromRGB(240, 120, 120),

		submitBg = Color3.fromRGB(66, 66, 66),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(210, 210, 210),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(200, 200, 200),
			Color3.fromRGB(140, 140, 140),
			Color3.fromRGB(240, 176, 108),
			Color3.fromRGB(120, 210, 140),
		},
	},

	Light = {
		bg = Color3.fromRGB(255, 255, 255),
		input = Color3.fromRGB(240, 240, 240),
		card = Color3.fromRGB(245, 245, 245),
		stroke = Color3.fromRGB(216, 216, 216),
		btn2 = Color3.fromRGB(232, 232, 232),
		btn2Hover = Color3.fromRGB(218, 218, 218),
		text = Color3.fromRGB(10, 10, 10),
		muted = Color3.fromRGB(110, 110, 110),
		accent = Color3.fromRGB(10, 10, 10),
		warn = Color3.fromRGB(196, 116, 24),
		success = Color3.fromRGB(28, 150, 72),
		error = Color3.fromRGB(210, 58, 58),

		submitBg = Color3.fromRGB(20, 20, 20),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(30, 30, 30),
		glowFrom = Color3.fromRGB(60, 60, 60),
		glowTo = Color3.fromRGB(0, 0, 0),

		confetti = {
			Color3.fromRGB(10, 10, 10),
			Color3.fromRGB(90, 90, 90),
			Color3.fromRGB(160, 160, 160),
			Color3.fromRGB(230, 150, 50),
			Color3.fromRGB(50, 170, 100),
		},
	},

	Violet = {
		bg = Color3.fromRGB(94, 64, 162),
		input = Color3.fromRGB(78, 52, 140),
		card = Color3.fromRGB(108, 78, 180),
		stroke = Color3.fromRGB(136, 108, 204),
		btn2 = Color3.fromRGB(120, 90, 192),
		btn2Hover = Color3.fromRGB(136, 106, 208),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(214, 202, 242),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(200, 255, 210),
		error = Color3.fromRGB(255, 160, 170),

		submitBg = Color3.fromRGB(58, 32, 112),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(240, 232, 255),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(214, 190, 255),
			Color3.fromRGB(170, 130, 255),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(58, 32, 112),
		},
	},

	Midnight = {
		bg = Color3.fromRGB(26, 44, 104),
		input = Color3.fromRGB(18, 32, 80),
		card = Color3.fromRGB(34, 56, 124),
		stroke = Color3.fromRGB(62, 88, 158),
		btn2 = Color3.fromRGB(44, 70, 142),
		btn2Hover = Color3.fromRGB(58, 86, 164),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(190, 204, 240),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 214, 140),
		success = Color3.fromRGB(190, 255, 215),
		error = Color3.fromRGB(255, 150, 160),

		submitBg = Color3.fromRGB(52, 92, 196),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(226, 236, 255),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(170, 200, 255),
			Color3.fromRGB(100, 150, 255),
			Color3.fromRGB(255, 214, 140),
			Color3.fromRGB(52, 92, 196),
		},
	},

	Amber = {
		bg = Color3.fromRGB(160, 84, 16),
		input = Color3.fromRGB(132, 68, 10),
		card = Color3.fromRGB(176, 98, 28),
		stroke = Color3.fromRGB(206, 132, 62),
		btn2 = Color3.fromRGB(186, 108, 38),
		btn2Hover = Color3.fromRGB(200, 122, 52),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(255, 228, 196),
		accent = Color3.fromRGB(255, 255, 255),
		warn = Color3.fromRGB(255, 240, 170),
		success = Color3.fromRGB(215, 255, 205),
		error = Color3.fromRGB(110, 18, 18),

		submitBg = Color3.fromRGB(110, 50, 6),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(255, 255, 255),
		glowFrom = Color3.fromRGB(255, 255, 255),
		glowTo = Color3.fromRGB(255, 240, 220),

		confetti = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 220, 160),
			Color3.fromRGB(255, 180, 90),
			Color3.fromRGB(255, 240, 170),
			Color3.fromRGB(110, 50, 6),
		},
	},

	Indigo = {
		bg = Color3.fromRGB(20, 14, 58),
		input = Color3.fromRGB(15, 10, 46),
		card = Color3.fromRGB(28, 20, 76),
		stroke = Color3.fromRGB(50, 40, 112),
		btn2 = Color3.fromRGB(38, 29, 96),
		btn2Hover = Color3.fromRGB(52, 42, 122),
		text = Color3.fromRGB(240, 238, 255),
		muted = Color3.fromRGB(150, 142, 204),
		accent = Color3.fromRGB(150, 132, 255),
		warn = Color3.fromRGB(240, 190, 120),
		success = Color3.fromRGB(120, 220, 160),
		error = Color3.fromRGB(255, 120, 140),

		submitBg = Color3.fromRGB(84, 64, 210),
		submitText = Color3.fromRGB(255, 255, 255),

		glowBase = Color3.fromRGB(160, 140, 255),
		glowFrom = Color3.fromRGB(140, 120, 255),
		glowTo = Color3.fromRGB(90, 70, 230),

		confetti = {
			Color3.fromRGB(150, 132, 255),
			Color3.fromRGB(200, 190, 255),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(240, 190, 120),
			Color3.fromRGB(84, 64, 210),
		},
	},
}

local themeIndex = 1

local C = {}
local function loadTheme(theme)
	for k, v in pairs(theme) do
		C[k] = v
	end
end

local COLOR_PROPS = {
	BackgroundColor3 = true,
	TextColor3 = true,
	ImageColor3 = true,
	Color = true,
	PlaceholderColor3 = true,
}
local bindings = {}
local gradients = {}

-- UI/Title font (Ophyn:SetUIFont / Ophyn:SetTitleFont). Every label built through make()
-- with FontFace = FONT or FONT_BOLD is tracked here so both setters can restyle text that
-- already exists, not just text built afterwards.
local fontBindings = {}
local fontSettings = { ui = nil, title = nil }

local function fontFor(entryFont)
	if entryFont.title and fontSettings.title then
		local t = fontSettings.title
		if entryFont.bold then
			return Font.new(t.Family, Enum.FontWeight.Bold, t.Style)
		end
		return t
	end
	if fontSettings.ui then
		local u = fontSettings.ui
		if entryFont.bold then
			return Font.new(u.Family, Enum.FontWeight.Bold, u.Style)
		end
		return u
	end
	return entryFont.bold and FONT_BOLD or FONT
end

local function applyFontAll()
	for _, entryFont in ipairs(fontBindings) do
		if entryFont.inst.Parent then
			entryFont.inst.FontFace = fontFor(entryFont)
		end
	end
end

-- Marks an already-created label as the window title, so SetTitleFont targets only it
-- (SetUIFont still applies to it too, as a fallback, same as everything else).
local function markTitleFont(inst)
	for _, entryFont in ipairs(fontBindings) do
		if entryFont.inst == inst then
			entryFont.title = true
			inst.FontFace = fontFor(entryFont)
			return
		end
	end
end

-- Same idea for a bold label created via text() then switched to FONT_BOLD afterwards,
-- so SetUIFont/SetTitleFont don't flatten it back to the regular weight later.
local function markBoldFont(inst)
	for _, entryFont in ipairs(fontBindings) do
		if entryFont.inst == inst then
			entryFont.bold = true
			inst.FontFace = fontFor(entryFont)
			return
		end
	end
end

-- Accepts a Font instance, a Roblox Enum.Font name ("Gotham", "SourceSansBold", ...), a
-- custom font family asset ("rbxassetid://..." or a bare numeric id), or a table
-- { Family = ..., Weight = ..., Style = ... }.
local function resolveFont(input)
	if input == nil then
		return nil
	end
	if typeof(input) == "Font" then
		return input
	end
	if type(input) == "table" then
		return Font.new(input.Family or input.family, input.Weight or Enum.FontWeight.Regular, input.Style or Enum.FontStyle.Normal)
	end
	local name = tostring(input)
	local ok, enumFont = pcall(function()
		return Enum.Font[name]
	end)
	if ok and typeof(enumFont) == "EnumItem" then
		return Font.fromEnum(enumFont)
	end
	local family = name
	if family:match("^%d+$") then
		family = "rbxassetid://" .. family
	end
	return Font.new(family, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if type(v) == "string" and COLOR_PROPS[k] then
			bindings[#bindings + 1] = { inst, k, v }
			inst[k] = C[v]
		elseif k == "FontFace" and (v == FONT or v == FONT_BOLD) then
			fontBindings[#fontBindings + 1] = { inst = inst, bold = (v == FONT_BOLD), title = false }
			inst[k] = v
		else
			inst[k] = v
		end
	end
	inst.Parent = parent
	return inst
end

local function unbind(inst, prop)
	for i = #bindings, 1, -1 do
		local b = bindings[i]
		if b[1] == inst and b[2] == prop then
			table.remove(bindings, i)
		end
	end
end

local function setRole(inst, prop, role)
	local found = false
	for _, b in ipairs(bindings) do
		if b[1] == inst and b[2] == prop then
			b[3] = role
			found = true
			break
		end
	end
	if not found then
		bindings[#bindings + 1] = { inst, prop, role }
	end
	inst[prop] = C[role]
end

local function frame(parent, x, y, w, h, color, transparency)
	return make("Frame", {
		Position = UDim2.new(0, x, 0, y),
		Size = UDim2.new(0, w, 0, h),
		BackgroundColor3 = color or C.bg,
		BackgroundTransparency = transparency or 1,
		BorderSizePixel = 0,
	}, parent)
end

local function text(parent, str, x, y, w, h, size, color, align)
	return make("TextLabel", {
		Position = UDim2.new(0, x, 0, y),
		Size = UDim2.new(0, w, 0, h),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = str,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = FONT,
	}, parent)
end

local function round(parent, radius, strokeColor)
	make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
	if strokeColor then
		make("UIStroke", {
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Color = strokeColor,
		}, parent)
	end
end

local function icon(parent, x, y, color, image)
	local holder = frame(parent, x, y, 16, 16)
	make("ImageLabel", {
		Name = "iconglow",
		Size = UDim2.new(2, 0, 2, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = color,
		ImageTransparency = 0.9,
		ZIndex = 0,
	}, holder)
	local img = make("ImageLabel", {
		Name = "iconimage",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ImageColor3 = iconRole(color),
	}, holder)
	-- `image` can be an asset id or a Lucide icon name ("house" / "lucide:house")
	Lucide.apply(img, image)
	return holder
end

local function decor(parent, w, h, x, y, transparency, rotation)
	local img = make("ImageLabel", {
		Size = UDim2.new(0, w, 0, h),
		Position = UDim2.new(0, x, 0, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = "glowBase",
		ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Stretch,
	}, parent)
	local grad = make("UIGradient", {
		Rotation = rotation,
		Color = ColorSequence.new(C.glowFrom, C.glowTo),
	}, img)
	gradients[#gradients + 1] = grad
	return img
end

local function centered(parent, w, h)
	return make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, w, 0, h),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)
end

local function tween(inst, time, props, style, dir)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function ring(parent, size, thickness, color, transparency)
	local f = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, size, 0, size),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	local stroke = make("UIStroke", { Thickness = thickness, Color = color, Transparency = transparency }, f)
	return f, stroke
end

local function comet(stroke)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0),
			NumberSequenceKeypoint.new(0.7, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, stroke)
end

local function prep(container)
	local items = {}
	local function add(inst)
		if inst:IsA("GuiObject") then
			items[#items + 1] = { inst, "BackgroundTransparency", inst.BackgroundTransparency }
			if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
				items[#items + 1] = { inst, "TextTransparency", inst.TextTransparency }
			elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
				items[#items + 1] = { inst, "ImageTransparency", inst.ImageTransparency }
			elseif inst:IsA("ScrollingFrame") then
				items[#items + 1] = { inst, "ScrollBarImageTransparency", inst.ScrollBarImageTransparency }
			end
		elseif inst:IsA("UIStroke") then
			items[#items + 1] = { inst, "Transparency", inst.Transparency }
		end
	end
	add(container)
	for _, d in ipairs(container:GetDescendants()) do
		add(d)
	end
	return items
end

local function fade(items, alpha, time)
	for _, it in ipairs(items) do
		local inst, prop, orig = it[1], it[2], it[3]
		local target = 1 - (1 - orig) * alpha
		if time and time > 0 then
			tween(inst, time, { [prop] = target })
		else
			inst[prop] = target
		end
	end
end

local function tintTo(inst, color)
	if settings.tintIcons then
		tween(inst, 0.15, { ImageColor3 = color })
	end
end

local function applyTheme(name, time)
	local theme = THEMES[name]
	if not theme then
		return
	end

	local oldFrom, oldTo = C.glowFrom, C.glowTo
	loadTheme(theme)

	local style, dir = Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
	for i = #bindings, 1, -1 do
		local b = bindings[i]
		local inst = b[1]
		if inst.Parent == nil then
			table.remove(bindings, i)
		else
			tween(inst, time, { [b[2]] = C[b[3]] }, style, dir)
		end
	end

	local newFrom, newTo = C.glowFrom, C.glowTo
	local driver = Instance.new("NumberValue")
	local conn = driver.Changed:Connect(function(a)
		local seq = ColorSequence.new(oldFrom:Lerp(newFrom, a), oldTo:Lerp(newTo, a))
		for _, g in ipairs(gradients) do
			g.Color = seq
		end
	end)
	local t = tween(driver, time, { Value = 1 }, style, dir)
	t.Completed:Connect(function()
		conn:Disconnect()
		driver:Destroy()
		for _, g in ipairs(gradients) do
			g.Color = ColorSequence.new(newFrom, newTo)
		end
	end)
end

local UI = {}
UI.Jnkie = Jnkie

-- Get key button customisation (KeySystem:SetGetkeyTitle / :SetGetkeyIcon).
-- Stored here so it works before or after KeySystem.new, and updates a UI that is already open.
local getkeySettings = { title = nil, icon = nil }
local getkeyAppliers = {}

local function applyGetkeyAll()
	for _, apply in ipairs(getkeyAppliers) do
		apply()
	end
end

-- Get key dropdown (KeySystem:GetMethod). Each call adds one option:
-- Ophyn:GetMethod({ Title = "...", Icon = "rbxassetid://...", URL = "..." })
-- or, for a dynamic link (matches a custom service's GetKeyLink(ctx)):
-- Ophyn:GetMethod({ Title = "...", Icon = "...", GetKeyLink = function(ctx) return url end })
-- Once 2+ methods are registered, the get key button grows an arrow that opens a dropdown
-- to pick between them; picking one only changes the button's text/icon (SetGetkeyTitle
-- keeps working as the fallback label when no method is selected yet).
local getMethods = {}
local selectedMethodIndex = nil

function UI.GetMethod(entry)
	entry = entry or {}
	local method = {
		title = entry.Title ~= nil and tostring(entry.Title) or nil,
		icon = entry.Icon,
		url = entry.URL,
		getKeyLink = entry.GetKeyLink or entry.getKeyLink,
		fields = entry, -- extra custom fields, passed back as ctx to GetKeyLink
	}
	table.insert(getMethods, method)
	if not selectedMethodIndex then
		selectedMethodIndex = 1
	end
	applyGetkeyAll()
	return #getMethods
end

-- Readable icon/text color on top of a filled color
local function contrastOn(color)
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return luminance > 0.55 and Color3.fromRGB(11, 11, 11) or Color3.fromRGB(255, 255, 255)
end

-- Notification style (NotifStyle / KeySystem:SetNotifStyle). Read every time a notification is shown.
local notifSettings = { style = nil }

function UI.SetNotifStyle(style)
	notifSettings.style = style ~= nil and tostring(style) or nil
end

-- Tabs style (TabsStyle / KeySystem:SetTabsStyle): "1" Tabs in a column on the left (default),
-- "2" Tabs in a row right under the topbar. Works before or after KeySystem.new: windows that
-- already exist re-layout themselves through the appliers they registered.
local tabsSettings = { style = nil }
local tabsAppliers = {}

function UI.SetTabsStyle(style)
	tabsSettings.style = style ~= nil and tostring(style) or nil
	for i = #tabsAppliers, 1, -1 do
		if tabsAppliers[i]() == false then
			table.remove(tabsAppliers, i)
		end
	end
end

function UI.SetUIFont(font)
	fontSettings.ui = resolveFont(font)
	applyFontAll()
end

function UI.SetTitleFont(font)
	fontSettings.title = resolveFont(font)
	applyFontAll()
end

function UI.SetGetkeyTitle(title)
	getkeySettings.title = title ~= nil and tostring(title) or nil
	applyGetkeyAll()
end

function UI.SetGetkeyIcon(icon)
	getkeySettings.icon = icon
	applyGetkeyAll()
end

function UI.new(options)
	local cfg = {}
	for k, v in pairs(Variables) do
		cfg[k] = v
	end
	for k, v in pairs(options or {}) do
		cfg[k] = v
	end

	local HUB_NAME = tostring(cfg.Title)
	local HUB_SUBTITLE = tostring(cfg.Description)
	local FOLDER = cfg.Folder
	local LOGO = assetId(cfg.Logo) or Images.LOGO

	-- Preloads every icon (+ the logo) as early as possible. The Key System content
	-- only becomes visible/interactive once this finishes (see `iconsPreloaded`
	-- below), so icons and images are guaranteed to be loaded before the Key
	-- System is shown to the user.
	local iconsPreloaded = false
	task.spawn(function()
		pcall(function()
			local list = {}
			for _, id in pairs(Images) do
				if type(id) == "string" then
					table.insert(list, id)
				end
			end
			table.insert(list, LOGO)
			game:GetService("ContentProvider"):PreloadAsync(list)
		end)
		iconsPreloaded = true
	end)

	local INTRO_SIZE = tonumber(cfg.startintro_size) or 80
	local LOADING_TIME = 3 -- fixed: icons/images preload during this time
	local SQUARE_TIME = tonumber(cfg.squareintro_time) or 1.2
	local SHOW_SQUARE_CONTORN = asBool(cfg.squarecontorn, true)

	settings.tintLogo = asBool(cfg.Changelogocolor, true)
	settings.tintIcons = asBool(cfg.Changeiconscolor, true)
	local SHOW_GETKEY = asBool(cfg.getkey, true)
	local SHOW_CHANGE_THEME = asBool(cfg.ChangeTheme, true)

	local themeName = cfg.Theme
	if not THEMES[themeName] then
		themeName = "Amethyst"
	end
	themeIndex = table.find(THEME_ORDER, themeName) or 1
	loadTheme(THEMES[themeName])

	local DISCORD_LINK = tostring(cfg.discord_link or "")
	local WEBSITE_LINK = tostring(cfg.website_link or "")
	local HAS_DISCORD = DISCORD_LINK ~= ""
	local HAS_WEBSITE = WEBSITE_LINK ~= ""

	-- card = whether each card shows up at all, separate from whether a link is set.
	-- Discord and Information default to shown; Website defaults to whatever HAS_WEBSITE
	-- is (most people don't have one, so it stays hidden unless a link is actually given).
	-- What the person passes to KeySystem.new wins over the defaults in variables.lua.
	-- Accepts Discord/Website (or lowercase) as true/false or "true"/"false".
	local function cardFlag(default, ...)
		for _, source in ipairs({ options or {}, Variables }) do
			for _, key in ipairs({ ... }) do
				if source[key] ~= nil then
					return asBool(source[key], default)
				end
			end
		end
		return default
	end

	local SHOW_DISCORD_CARD = cardFlag(true, "Discord", "discord")
	local SHOW_WEBSITE_CARD = cardFlag(HAS_WEBSITE, "Website", "website")
	local SHOW_INFO_CARD = cardFlag(true, "Informations", "Information", "informations", "information")
	-- Only Discord enabled (no Website card): it starts expanded to fill the free space
	local SHOW_INTRO = cardFlag(true, "Intro", "intro")

	-- Keyless mode: Keyless = { disabletextbox, disablegetkey, showcard, autoconfirm }.
	-- Passing the table turns it on (enabled = false keeps it off); Keyless = true/false also works.
	-- What the person passes to KeySystem.new wins over variables.lua.
	local KL = { disabletextbox = true, disablegetkey = true, showcard = true, autoconfirm = false }
	local KEYLESS = false
	do
		local raw
		for _, source in ipairs({ options or {}, Variables }) do
			local v = source.Keyless
			if v == nil then
				v = source.keyless
			end
			if v ~= nil then
				raw = v
				break
			end
		end
		if type(raw) == "table" then
			KEYLESS = asBool(raw.enabled, true)
			for k, default in pairs(KL) do
				KL[k] = asBool(raw[k], default)
			end
		elseif raw ~= nil then
			KEYLESS = asBool(raw, false)
		end
	end
	local SHOW_KEYLESS_CARD = KEYLESS and KL.showcard

	-- With the Keyless card on, Discord starts collapsed so both cards fit
	local DISCORD_STARTS_OPEN = SHOW_DISCORD_CARD and not SHOW_WEBSITE_CARD and HAS_DISCORD and not SHOW_KEYLESS_CARD

	-- Notification style: "1" Stripe, "2" Pill, "3" Island, "4" Ring, "5" Solid
	local NOTIF_STYLE = "1"
	for _, source in ipairs({ options or {}, Variables }) do
		local value = source.NotifStyle
		if value == nil then
			value = source.notifstyle
		end
		if value ~= nil then
			NOTIF_STYLE = tostring(value)
			break
		end
	end

	local INVITE_DISPLAY, INVITE_URL, INVITE_CODE = "Not Configured", "", ""
	if HAS_DISCORD then
		local invite = DISCORD_LINK
		if not invite:find("[/.]") then
			invite = "discord.gg/" .. invite
		end
		INVITE_DISPLAY = invite:gsub("^https?://", "")
		INVITE_URL = invite:match("^https?://") and invite or ("https://" .. invite)
		INVITE_CODE = (INVITE_DISPLAY:gsub("[?#].*$", "")):match("([^/]+)/*$") or INVITE_DISPLAY
	end

	local WEBSITE_DISPLAY, WEBSITE_URL = "Not Configured", ""
	if HAS_WEBSITE then
		WEBSITE_DISPLAY = WEBSITE_LINK:gsub("^https?://", "")
		WEBSITE_URL = WEBSITE_LINK:match("^https?://") and WEBSITE_LINK or ("https://" .. WEBSITE_LINK)
	end


	-- KeySystem = { Key = {"1234", "5678"} or function(key) -> valid, reason, URL = "...", SaveKey = false,
	--               API = { { Type = "platoboost" | "panda" | "jnkie", ... } } }
	local KEY_CFG = cfg.KeySystem or {}
	local KEY_LIST = KEY_CFG.Key

	-- Key services (KeySystem.API). Each entry is built by its Type.
	local SERVICE_BUILDERS = {
		platoboost = function(entry)
			return Platoboost.new(entry)
		end,
		-- { Type = "panda", ServiceId = "..." }
		panda = function(entry)
			return Panda.new(entry)
		end,
		-- { Type = "jnkie", Service = "...", Identifier = "...", Provider = "Mixed" }
		jnkie = function(entry)
			local instance = Jnkie.new(entry)
			return {
				CheckKey = function(_, key)
					local result = instance:CheckKey(key)
					local reason = result and (result.error or result.message)
					return result ~= nil and result.valid == true, reason
				end,
				GetKeyLink = function()
					return instance:GetKeyLink()
				end,
			}
		end,
	}

	-- Your own service:
	-- { Type = "custom", ServiceId = 1234, --[[ any fields you want ]]
	--   CheckKey = function(key, ctx) return valid, reason end,   -- required
	--   GetKeyLink = function(ctx) return url end }               -- optional ("Get a key" button)
	-- ctx = every field of the entry (ServiceId, Secret, ...) + ctx.Request
	-- (the executor's HTTP function, or nil). GetKeyLink can return nil, "reason" on failure.
	local function customRequestFunction()
		return request or http_request or (syn and syn.request) or (http and http.request)
	end

	SERVICE_BUILDERS.custom = function(entry)
		local checker = entry.CheckKey or entry.checkKey
		if type(checker) ~= "function" then
			error("KeySystem.API custom entry needs a CheckKey function")
		end
		local getLink = entry.GetKeyLink or entry.getKeyLink

		-- Built on every call, so the person's own fields can override Request.
		local function context()
			local ctx = { Request = customRequestFunction() }
			for k, v in pairs(entry) do
				ctx[k] = v
			end
			return ctx
		end

		return {
			CheckKey = function(_, key)
				local valid, why = checker(key, context())
				return valid == true, why
			end,
			GetKeyLink = (type(getLink) == "function") and function()
				return getLink(context())
			end or nil,
		}
	end

	SERVICE_BUILDERS.pandaauth = SERVICE_BUILDERS.panda -- alias

	local apiEntries = type(KEY_CFG.API) == "table" and KEY_CFG.API or {}
	if apiEntries.Type ~= nil or apiEntries.type ~= nil then
		apiEntries = { apiEntries } -- a single entry without the outer list
	end

	local API_SERVICES = {}
	for i, entry in ipairs(apiEntries) do
		local kind = type(entry) == "table" and tostring(entry.Type or entry.type or ""):lower() or ""
		local builder = SERVICE_BUILDERS[kind]
		if builder then
			local ok, instance = pcall(builder, entry)
			if ok and instance then
				table.insert(API_SERVICES, instance)
			else
				warn("[" .. HUB_NAME .. "] KeySystem.API[" .. i .. "] failed to load: " .. tostring(instance))
			end
		else
			warn("[" .. HUB_NAME .. "] KeySystem.API[" .. i .. "] has an unknown Type: '" .. kind .. "'")
		end
	end

	if KEY_LIST == nil and #API_SERVICES == 0 then
		KEY_LIST = KEY_CFG.RequireConfiguredKey == true and {} or { "key" }
	end
	local KEY_URL = tostring(KEY_CFG.URL or "")
	local KEY_SAVE = asBool(KEY_CFG.SaveKey, false)

	-- Links usados pelos botões (Get a key / Discord / Website)
	local LINKS = {
		getKey = KEY_URL,
		website = WEBSITE_URL,
		discord = INVITE_URL,
	}

	local function isCallable(v)
		if type(v) == "function" then
			return true
		end
		local mt = type(v) == "table" and getmetatable(v)
		return mt ~= nil and mt.__call ~= nil
	end

	-- Auto-detect a Jnkie.Validator() adapter so "Get a key" can call
	-- Jnkie:GetKeyLink() on its own, with no KeySystem.URL required.
	-- Also accepts a *raw* Jnkie instance (Key = jnkie instead of
	-- Key = jnkie:Validator()) and upgrades it automatically.
	if type(KEY_LIST) == "table" and KEY_LIST.__isJnkieInstance and not KEY_LIST.__isJnkie then
		KEY_LIST = KEY_LIST:Validator()
	end
	local KEY_JNKIE = type(KEY_LIST) == "table" and KEY_LIST.__isJnkie and KEY_LIST.__instance or nil

	-- Retorna valid (boolean) e reason (string quando inválida).
	-- Erros aqui são pegos pelo pcall do runKeyCheck ("Something went wrong").
	local function validateKey(key)
		local reason

		-- Key = { "a", "b" } | "a" | function(key) | Jnkie:Validator()
		if KEY_LIST ~= nil then
			if isCallable(KEY_LIST) then
				local valid, why = KEY_LIST(key)
				if valid then
					return true
				end
				reason = why
			elseif type(KEY_LIST) == "table" then
				for _, k in ipairs(KEY_LIST) do
					if tostring(k) == key then
						return true
					end
				end
			elseif tostring(KEY_LIST) == key then
				return true
			end
		end

		-- KeySystem.API (Platoboost / Panda / Jnkie)
		for _, service in ipairs(API_SERVICES) do
			local ok, valid, why = pcall(service.CheckKey, service, key)
			if ok and valid then
				return true
			end
			reason = (ok and why) or (not ok and tostring(valid)) or reason
		end

		return false, reason
	end

	local function safeIsFile(path)
		if not isfile then
			return false
		end
		local ok, res = pcall(isfile, path)
		return ok and res == true
	end

	local function safeReadFile(path)
		if not readfile then
			return nil
		end
		local ok, res = pcall(readfile, path)
		if ok and type(res) == "string" then
			return res
		end
		return nil
	end

	local function safeWriteFile(path, contents)
		if not writefile then
			return false
		end
		if FOLDER and FOLDER ~= "" and isfolder and makefolder then
			local ok, exists = pcall(isfolder, FOLDER)
			if ok and not exists then
				pcall(makefolder, FOLDER)
			end
		end
		return pcall(writefile, path, contents) == true
	end

	-- Nome do arquivo da key = hash gerada (determinística: mesmo Folder + Title = mesmo arquivo)
	local function hashName(seed)
		local bxor = bit32 and bit32.bxor
		local parts = {}
		for round = 1, 4 do
			local h = (2166136261 + round * 16777619) % 4294967296
			local input = seed .. "|" .. round
			for i = 1, #input do
				local b = input:byte(i)
				h = bxor and bxor(h, b) or ((h + b) % 4294967296)
				h = (h * 16777619) % 4294967296
			end
			parts[round] = string.format("%08x", h)
		end
		return table.concat(parts)
	end

	local KEY_HASH = hashName(tostring(FOLDER or "") .. "|" .. HUB_NAME)
	local KEY_FILE = (FOLDER and FOLDER ~= "" and (FOLDER .. "/" .. KEY_HASH)) or KEY_HASH

	local SAVED_KEY = nil
	if KEY_SAVE and safeIsFile(KEY_FILE) then
		local contents = safeReadFile(KEY_FILE)
		if contents then
			contents = contents:match("^%s*(.-)%s*$")
			if contents ~= "" then
				SAVED_KEY = contents
			end
		end
	end

	-- Information card stats: how many key checks were valid, how many came back
	-- expired, and when a key last passed. Stored locally per Folder + Title, same
	-- as the saved key, just under a different hashed file name.
	local STATS_HASH = hashName(tostring(FOLDER or "") .. "|" .. HUB_NAME .. "|stats")
	local STATS_FILE = (FOLDER and FOLDER ~= "" and (FOLDER .. "/" .. STATS_HASH)) or STATS_HASH

	local STATS = { valid = 0, expired = 0, last = 0 }
	do
		local contents = safeReadFile(STATS_FILE)
		if contents then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(contents)
			end)
			if ok and type(data) == "table" then
				STATS.valid = tonumber(data.valid) or 0
				STATS.expired = tonumber(data.expired) or 0
				STATS.last = tonumber(data.last) or 0
			end
		end
	end

	local function saveStats()
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(STATS)
		end)
		if ok then
			safeWriteFile(STATS_FILE, encoded)
		end
	end

	local function formatAgo(ts)
		if not ts or ts <= 0 then
			return "Never"
		end
		local diff = os.time() - ts
		if diff < 60 then
			return "Just now"
		elseif diff < 3600 then
			return math.floor(diff / 60) .. " min ago"
		elseif diff < 86400 then
			return math.floor(diff / 3600) .. " h ago"
		else
			return math.floor(diff / 86400) .. " d ago"
		end
	end

	local state = { ready = false, closing = false }
	local snapLocked = false

	local root = Instance.new("ScreenGui")
	root.Name = "ophyn-ui-wow"
	root.Enabled = true
	root.DisplayOrder = 999
	root.IgnoreGuiInset = true
	root.ResetOnSpawn = false
	root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	root.ClipToDeviceSafeArea = true

	local main = make("Frame", {
		Name = "Frame",
		Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, root)

	local shadow = make("ImageLabel", {
		Size = UDim2.new(1, 50, 1, 50),
		Position = UDim2.new(0, -25, 0, -25),
		BackgroundTransparency = 1,
		Image = Images.SHADOW,
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
	}, main)

	local canvas = make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = "bg",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, main)
	local canvasCorner = make("UICorner", { CornerRadius = UDim.new(0, 10) }, canvas)

	local borderStroke = make("UIStroke", {
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = "accent",
		Transparency = 1,
	}, canvas)

	local decorGroup = make("CanvasGroup", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, canvas)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, decorGroup)

	local bgFrame = centered(decorGroup, FINAL_W, FINAL_H)
	decor(bgFrame, 380, 140, 230, 266, 0.86, 270)
	decor(bgFrame, 100, 46, -8, 252, 0.75, 90)
	decor(bgFrame, 400, 184, 450, 8, 0.92, 90)
	decor(bgFrame, 70, 138, 5, -5, 0.78, 90)

	local ctx = {
		C = C,
		make = make,
		frame = frame,
		text = text,
		round = round,
		tween = tween,
		prep = prep,
		fade = fade,
		images = Images,
		FONT = FONT,
		FONT_BOLD = FONT_BOLD,
		markBoldFont = markBoldFont,
		root = root,
		canvas = canvas,
		state = state,
		tintIcons = settings.tintIcons,
		getStyle = function()
			return notifSettings.style or NOTIF_STYLE
		end,
		cfg = {
			NOTIF_W = NOTIF_W,
			NOTIF_H = NOTIF_H,
			NOTIF_TRANSPARENCY = NOTIF_TRANSPARENCY,
			NOTIF_COLOR = NOTIF_COLOR,
			NOTIF_BLUR = NOTIF_BLUR,
		},
	}

	local notifs = Notification.new(ctx)
	local notifyInternal = notifs.notify
	local function notify(title, message, kind, iconKey, duration)
		if type(cfg.MainNotify) == "function" then
			local ok, result = pcall(cfg.MainNotify, title, message, kind, iconKey, duration)
			if ok then return result end
		end
		return notifyInternal(title, message, kind, iconKey, duration)
	end
	local Blur = notifs.blur

	local intro = centered(canvas, FINAL_W, FINAL_H)

	local introLogo = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 58),
		BackgroundTransparency = 1,
		Image = LOGO,
		ImageColor3 = logoRole("accent"),
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
	}, intro)

	local spinnerHolder = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 36),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, intro)

	local ringTrack = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, spinnerHolder)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, ringTrack)
	make("UIStroke", { Thickness = 2.5, Color = "muted", Transparency = 0.75 }, ringTrack)

	local spinner = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, spinnerHolder)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, spinner)
	local spinnerStroke = make("UIStroke", { Thickness = 2.5, Color = "accent" }, spinner)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0),
			NumberSequenceKeypoint.new(0.7, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, spinnerStroke)

	local spin = TweenService:Create(
		spinner,
		TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
		{ Rotation = 360 }
	)

	local checkScreen = centered(canvas, FINAL_W, FINAL_H)
	checkScreen.Visible = false

	local ringHolder = centered(checkScreen, 64, 64)
	ringHolder.Position = UDim2.new(0.5, 0, 0.5, -12)
	local ringScale = make("UIScale", { Scale = 1 }, ringHolder)

	ring(ringHolder, 56, 3, "accent", 0)

	local P1, P2, P3 = Vector2.new(-12, 0), Vector2.new(-4, 9), Vector2.new(13, -9)
	local function makeBar(a, b)
		local d = b - a
		local bar = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, a.X, 0.5, a.Y),
			Size = UDim2.new(0, 0, 0, 3),
			Rotation = math.deg(math.atan2(d.Y, d.X)),
			BackgroundColor3 = "accent",
			BorderSizePixel = 0,
			Visible = false,
		}, ringHolder)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
		return { frame = bar, a = a, b = b, len = d.Magnitude }
	end
	local checkBar1 = makeBar(P1, P2)
	local checkBar2 = makeBar(P2, P3)

	local fxLayer = frame(checkScreen, 0, 0, FINAL_W, FINAL_H)
	fxLayer.ZIndex = 3

	local checkText = text(checkScreen, "Correct Key!", 0, 156, FINAL_W, 22, 16, "text", Enum.TextXAlignment.Center)
	markBoldFont(checkText)
	checkText.TextTransparency = 1

	local ringItems = prep(ringHolder)
	fade(ringItems, 0)

	local morph = centered(canvas, NOTIF_W, 62)
	morph.Visible = false

	-- "Loading Script.." card. It follows NotifStyle: the window shrinks into that notification's shape.
	local MORPH_TITLE, MORPH_HINT = "Loading Script..", "Can take 1-2s..."

	local function morphLoader(parent, size, thickness, arcColor, trackColor, trackTransparency)
		ring(parent, size, thickness, trackColor, trackTransparency)
		local arc, arcStroke = ring(parent, size, thickness, arcColor, 0)
		comet(arcStroke)
		return TweenService:Create(
			arc,
			TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
			{ Rotation = 360 }
		)
	end

	local function morphLabel(x, y, w, h, str, size, color, bold)
		local l = text(morph, str, x, y, w, h, size, color)
		if bold then
			markBoldFont(l)
		end
		return l
	end

	local function buildMorph(key)
		morph:ClearAllChildren()

		local w, h = NOTIF_W, 62
		local spec = {
			top = false,
			radius = 10,
			bg = C[NOTIF_COLOR],
			bgTransparency = NOTIF_TRANSPARENCY,
			border = C.stroke,
			borderTransparency = 0.35,
		}
		local spin

		if key == "2" then
			-- Pill
			w, h = 240, 36
			spec.radius = 18
			local box = frame(morph, 6, 6, 24, 24)
			spin = morphLoader(box, 20, 2, "accent", "muted", 0.75)
			make("TextLabel", {
				Position = UDim2.new(0, 38, 0, 0),
				Size = UDim2.new(0, w - 52, 0, h),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				RichText = true,
				Text = "<b>Loading script..</b>  <font color=\"#" .. C.muted:ToHex() .. "\">1-2s</font>",
				TextSize = 13,
				TextColor3 = "text",
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = FONT,
			}, morph)
		elseif key == "3" then
			-- Island
			w, h = 260, 52
			spec.top = true
			spec.radius = 26
			spec.bg = Color3.fromRGB(0, 0, 0)
			spec.bgTransparency = 0.06
			spec.border = Color3.fromRGB(42, 42, 48)
			local badge = frame(morph, 10, 10, 32, 32, "accent", 0.86)
			round(badge, 16, "accent")
			badge.UIStroke.Transparency = 0.6
			spin = morphLoader(badge, 16, 2, "accent", "muted", 0.75)
			morphLabel(54, 9, w - 70, 16, MORPH_TITLE, 13, Color3.fromRGB(244, 244, 245), true)
			morphLabel(54, 27, w - 70, 14, MORPH_HINT, 12, Color3.fromRGB(154, 154, 162))
		elseif key == "4" then
			-- Ring
			h = 60
			local box = frame(morph, 10, 10, 40, 40)
			spin = morphLoader(box, 34, 3, "accent", "muted", 0.75)
			morphLabel(62, 11, w - 76, 18, MORPH_TITLE, 13, "text", true)
			morphLabel(62, 31, w - 76, 16, MORPH_HINT, 12, "muted")
		elseif key == "5" then
			-- Solid
			h = 58
			local accent = C.accent
			local onColor = contrastOn(accent)
			spec.bg = accent
			spec.bgTransparency = 0.04
			spec.borderTransparency = 1
			local box = frame(morph, 14, (h - 22) / 2, 22, 22)
			spin = morphLoader(box, 20, 3, onColor, onColor, 0.75)
			morphLabel(48, 10, w - 62, 18, MORPH_TITLE, 13, onColor, true)
			morphLabel(48, 30, w - 62, 16, MORPH_HINT, 12, onColor:Lerp(accent, 0.35))
		else
			-- Stripe
			round(frame(morph, 8, 10, 3, h - 20, "accent", 0), 2)
			morphLabel(22, 11, w - 36, 18, MORPH_TITLE, 13, "text", true)
			morphLabel(22, 30, w - 36, 16, MORPH_HINT, 12, "muted")
			local trackW = w - 44
			round(frame(morph, 22, h - 9, trackW, 2, "accent", 0.8), 1)
			local fill = frame(morph, 22, h - 9, 0, 2, "accent", 0)
			round(fill, 1)
			spin = TweenService:Create(
				fill,
				TweenInfo.new(2.2, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(0, trackW, 0, 2) }
			)
		end

		morph.Size = UDim2.new(0, w, 0, h)
		local items = prep(morph)
		fade(items, 0)

		spec.w, spec.h, spec.spin, spec.items = w, h, spin, items
		return spec
	end

	local content = centered(canvas, FINAL_W, FINAL_H)
	content.Visible = false

	local left = frame(content, 0, 0, 272, 260)

	make("ImageLabel", {
		Position = UDim2.new(0, 22, 0, 20),
		Size = UDim2.new(0, 36, 0, 32),
		BackgroundTransparency = 1,
		Image = LOGO,
		ImageColor3 = logoRole("accent"),
		ScaleType = Enum.ScaleType.Fit,
	}, left)

	local hubTitle = text(left, HUB_NAME, 66, 20, 190, 22, 20, "text")
markTitleFont(hubTitle)
	hubTitle.TextTruncate = Enum.TextTruncate.AtEnd
	local hubSubtitle = text(left, HUB_SUBTITLE, 66, 42, 190, 14, 12, "muted")
	hubSubtitle.TextTruncate = Enum.TextTruncate.AtEnd


	-- Draggable key window: drag from the title/subtitle strip.
	local dragHandle = make("TextButton", {
		Name = "KeySystemDragHandle",
		Position = UDim2.new(0, 62, 0, 8),
		Size = UDim2.new(0, 198, 0, 52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 9,
	}, left)
	local dragActive, dragStart, dragOrigin = false, nil, nil
	local dragConnections = {}
	dragHandle.InputBegan:Connect(function(input)
		if not state.ready or state.closing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragActive = true
		dragStart = input.Position
		dragOrigin = main.Position
	end)
	dragConnections[#dragConnections + 1] = UserInputService.InputChanged:Connect(function(input)
		if not dragActive or not dragStart or not dragOrigin then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		main.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
	end)
	dragConnections[#dragConnections + 1] = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragActive, dragStart, dragOrigin = false, nil, nil
		end
	end)
	root.Destroying:Connect(function()
		dragActive = false
		for _, connection in ipairs(dragConnections) do pcall(function() connection:Disconnect() end) end
	end)

	local licenseLabel = text(left, "License key", 22, 78, 228, 14, 11, "muted")

	local inputBox = frame(left, 22, 96, 228, 36, "input", 0)
	inputBox.ClipsDescendants = true
	round(inputBox, 8, "stroke")
	icon(inputBox, 12, 10, "muted", Images.KEY)

	local KEY_MAX_LENGTH = 256

	local keyBox = make("TextBox", {
		Name = "TextBox",
		Position = UDim2.new(0, 38, 0, 0),
		Size = UDim2.new(1, -48, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		TextSize = 13,
		TextColor3 = "text",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		PlaceholderText = "Paste your key here",
		PlaceholderColor3 = "muted",
		ClearTextOnFocus = false,
		MultiLine = false,
		FontFace = FONT,
	}, inputBox)

	keyBox:GetPropertyChangedSignal("Text"):Connect(function()
		if #keyBox.Text > KEY_MAX_LENGTH then
			keyBox.Text = keyBox.Text:sub(1, KEY_MAX_LENGTH)
		end
	end)

	local submit = make("TextButton", {
		Name = "TextButton",
		Position = UDim2.new(0, 22, 0, 142),
		Size = UDim2.new(0, 110, 0, 34),
		BackgroundColor3 = "submitBg",
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "Submit",
		TextSize = 13,
		TextColor3 = "submitText",
		FontFace = FONT,
	}, left)
	round(submit, 8)
	make("UIPadding", { PaddingLeft = UDim.new(0, 24) }, submit)
	icon(submit, -12, 9, "submitText", Images.SUBMIT)

	local getKey = make("TextButton", {
		Name = "TextButton",
		Position = UDim2.new(0, 140, 0, 142),
		Size = UDim2.new(0, 110, 0, 34),
		BackgroundColor3 = "btn2",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "Get a key",
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = 13,
		TextColor3 = "text",
		FontFace = FONT,
	}, left)
	round(getKey, 8, "stroke")
	local getKeyPadding = make("UIPadding", { PaddingLeft = UDim.new(0, 24) }, getKey)
	local getKeyIcon = icon(getKey, -12, 9, "text", Images.KEY)

	-- Dropdown arrow: a separate hit area over the button's right edge, only visible
	-- once there are 2+ methods (see Ophyn:GetMethod above). Being its own TextButton on
	-- top of "getKey" means clicking it never also fires getKey's own click below.
	local methodArrow = make("TextButton", {
		Name = "TextButton",
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 26, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "\226\150\190", -- U+25BE, small down-pointing triangle
		TextSize = 11,
		TextColor3 = "text",
		FontFace = FONT,
		Visible = false,
	}, getKey)

	-- Dropdown list, parented to "main" (not "canvas") so it isn't clipped by the
	-- window's edges when it opens above/below the button.
	local methodDropdown = make("Frame", {
		Name = "GetKeyDropdown",
		BackgroundColor3 = "card",
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 50,
		ClipsDescendants = true,
	}, main)
	round(methodDropdown, 8, "stroke")

	local function closeMethodDropdown()
		methodDropdown.Visible = false
	end

	local function rebuildMethodDropdown()
		for _, child in ipairs(methodDropdown:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local rowH = 32
		for i, m in ipairs(getMethods) do
			local row = make("TextButton", {
				Name = "TextButton",
				Position = UDim2.new(0, 0, 0, (i - 1) * rowH),
				Size = UDim2.new(1, 0, 0, rowH),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 51,
			}, methodDropdown)
			icon(row, 10, 8, "text", assetId(m.icon) or Images.KEY)
			local label = text(row, m.title or ("Method " .. i), 34, 0, 96, rowH, 12, "text")
			label.ZIndex = 52
			row.MouseButton1Click:Connect(function()
				selectedMethodIndex = i
				applyGetkeyAll()
				closeMethodDropdown()
			end)
		end
		methodDropdown.Size = UDim2.new(0, 140, 0, rowH * math.max(#getMethods, 1))
	end

	methodArrow.MouseButton1Click:Connect(function()
		if not state.ready or state.closing or #getMethods < 2 or (KEYLESS and KL.disablegetkey) then
			return
		end
		if methodDropdown.Visible then
			closeMethodDropdown()
			return
		end
		rebuildMethodDropdown()
		local pos = getKey.AbsolutePosition - main.AbsolutePosition
		local h = methodDropdown.AbsoluteSize.Y
		methodDropdown.Position = UDim2.new(0, pos.X, 0, pos.Y - h - 6) -- opens upward
		methodDropdown.Visible = true
	end)

	local function applyGetkey()
		local method = getMethods[selectedMethodIndex or 0]
		local title = method and method.title
		local iconValue = method and method.icon
		if not title or title == "" then
			title = getkeySettings.title
		end
		getKey.Text = (title and title ~= "") and title or "Get a key"
		local image = getKeyIcon:FindFirstChild("iconimage")
		if image then
			Lucide.apply(image, assetId(iconValue) or assetId(getkeySettings.icon) or Images.KEY)
		end
		local showArrow = #getMethods > 1
		methodArrow.Visible = showArrow
		getKeyPadding.PaddingRight = showArrow and UDim.new(0, 20) or UDim.new(0, 0)
		if not showArrow then
			closeMethodDropdown()
		end
	end
	applyGetkey()
	table.insert(getkeyAppliers, applyGetkey)
	root.Destroying:Connect(function()
		local index = table.find(getkeyAppliers, applyGetkey)
		if index then
			table.remove(getkeyAppliers, index)
		end
	end)

	if not SHOW_GETKEY then
		getKey.Visible = false
		submit.Size = UDim2.new(0, 228, 0, 34)
	end


	-- Avatar + "Welcome Back / <nome>!"
	local avatar = make("ImageLabel", {
		Position = UDim2.new(0, 22, 0, 214),
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = "input",
		BorderSizePixel = 0,
		Image = player and ("rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150") or "",
		ScaleType = Enum.ScaleType.Crop,
	}, left)
	round(avatar, 16, "stroke")

	text(left, "Welcome Back", 62, 215, 188, 14, 11, "muted")
	local welcomeName = text(left, ((player and player.DisplayName) or "User") .. "!", 62, 229, 188, 16, 14, "text")
	markBoldFont(welcomeName)
	welcomeName.TextTruncate = Enum.TextTruncate.AtEnd

	frame(content, 272, 20, 1, 220, "stroke", 0)

	local right = frame(content, 273, 0, 187, 260)

	text(right, "Detected game", 20, 24, 147, 14, 11, "muted")

	local gameCard = frame(right, 20, 42, 147, 52, "card", 0)
	round(gameCard, 8)

	local gameImg = make("ImageLabel", {
		Position = UDim2.new(0, 9, 0, 9),
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundColor3 = "input",
		BorderSizePixel = 0,
		Image = Images.GAME_PLACEHOLDER,
		ScaleType = Enum.ScaleType.Stretch,
	}, gameCard)
	round(gameImg, 7, "stroke")

	local gameName = text(gameCard, "Loading...", 52, 10, 90, 14, 12, "text")
	gameName.TextTruncate = Enum.TextTruncate.AtEnd
	local gameStatus = text(gameCard, "Checking...", 52, 27, 90, 13, 11, "muted")

	local rows = frame(right, 0, 0, 187, 260)

	text(rows, "Executor", 20, 106, 60, 14, 11, "muted")
	local executorLabel = text(rows, "Detecting...", 80, 106, 87, 14, 11, "text", Enum.TextXAlignment.Right)
	executorLabel.TextTruncate = Enum.TextTruncate.AtEnd

	text(rows, "Status", 20, 126, 60, 14, 11, "muted")
	local statusValue = text(rows, "Key required", 80, 126, 87, 14, 11, "warn", Enum.TextXAlignment.Right)

	local rightDivider = frame(right, 20, 148, 147, 1, "stroke", 0)

	-- Scrollable card list. Cards are laid out inside it (see layoutCards); once they
	-- no longer fit it can be scrolled with the wheel, by touch, or by dragging.
	-- CARD_PAD leaves room for the 1px outer card strokes, which would be clipped otherwise.
	local CARD_PAD = 2
	local CARD_VIEW_BOTTOM = 256 -- bottom edge of the visible card area
	local cardScroll = make("ScrollingFrame", {
		Name = "Cards",
		Position = UDim2.new(0, 20 - CARD_PAD, 0, 158 - CARD_PAD),
		Size = UDim2.new(0, 147 + CARD_PAD + 5, 0, CARD_VIEW_BOTTOM - 158 + CARD_PAD),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 0.45,
		ClipsDescendants = true,
	}, right)
	setRole(cardScroll, "ScrollBarImageColor3", "muted")

	local function linkButton(y, title, subtitle, image)
		local btn = make("TextButton", {
			Name = "TextButton",
			Position = UDim2.new(0, 20, 0, y),
			Size = UDim2.new(0, 147, 0, 40),
			BackgroundColor3 = "card",
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
		}, cardScroll)
		round(btn, 8, "stroke")
		local iconHolder = icon(btn, 11, 12, "accent", image)
		local titleLabel = text(btn, title, 36, 6, 106, 14, 12, "text")
		local subLabel = text(btn, subtitle, 36, 21, 106, 13, 11, "muted")
		subLabel.TextTruncate = Enum.TextTruncate.AtEnd
		return btn, iconHolder, titleLabel, subLabel
	end

	local discord, discordIcon, discordTitle, discordSub = linkButton(158, "Discord", INVITE_DISPLAY, Images.DISCORD)
	local website = linkButton(206, "Website", WEBSITE_DISPLAY, Images.LINK)
	discord.Visible = SHOW_DISCORD_CARD
	website.Visible = SHOW_WEBSITE_CARD
	discordTitle.TextTruncate = Enum.TextTruncate.AtEnd

	discord.ClipsDescendants = true

	local discordExtra = frame(discord, 0, 0, 147, 82)
	discordExtra.Visible = false

	local serverIcon = make("ImageLabel", {
		Position = UDim2.new(0, 9, 0, 7),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = "input",
		BorderSizePixel = 0,
		Image = LOGO,
		ImageColor3 = logoRole("accent"),
		ScaleType = Enum.ScaleType.Fit,
	}, discordExtra)
	round(serverIcon, 8, "stroke")

	local linkHit = make("TextButton", {
		Position = UDim2.new(0, 40, 0, 19),
		Size = UDim2.new(0, 102, 0, 17),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, discordExtra)

	frame(discordExtra, 10, 41, 127, 1, "stroke", 0)

	local function statBlock(x, label, dotColor)
		local num = text(discordExtra, "...", x, 47, 62, 16, 13, "text")
		markBoldFont(num)
		local dot = frame(discordExtra, x, 66, 6, 6, dotColor, 0)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		text(discordExtra, label, x + 10, 62, 50, 14, 10, "muted")
		return num
	end

	local onlineNum = statBlock(12, "Online", "success")
	local offlineNum = statBlock(80, "Offline", "muted")

	local extraItems = prep(discordExtra)
	local rowsItems = prep(rows)
	local discordIconItems = prep(discordIcon)

	-- Information card: local stats only (valid keys, expired keys, last used)
	local infoCard, infoIcon, infoTitle, infoSub = linkButton(254, "Information", "Tap to view", Images.KEY)
	infoCard.Visible = SHOW_INFO_CARD
	infoCard.ClipsDescendants = true
	infoTitle.TextTruncate = Enum.TextTruncate.AtEnd

	-- Expanded Information card: same look as the expanded Discord card
	local INFO_OPEN_H = 92
	-- Grouped in one table: UI.new is close to Lua's limit of 200 local variables.
	local infoUI = {}
	do
		local extra = frame(infoCard, 0, 0, 147, INFO_OPEN_H)
		extra.Visible = false
		infoUI.extra = extra

		local iconBox = frame(extra, 9, 7, 26, 26, "input", 0)
		round(iconBox, 8, "stroke")
		icon(iconBox, 5, 5, "accent", Images.KEY)

		frame(extra, 10, 41, 127, 1, "stroke", 0)

		local function stat(x, label, dotColor)
			local num = text(extra, "0", x, 46, 62, 16, 13, "text")
			markBoldFont(num)
			local dot = frame(extra, x, 66, 6, 6, dotColor, 0)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			text(extra, label, x + 10, 62, 50, 14, 10, "muted")
			return num
		end
		infoUI.valid = stat(12, "Valid", "success")
		infoUI.expired = stat(80, "Expired", "warn")

		text(extra, "Last used", 12, 77, 56, 13, 10, "muted")
		local lastUsed = text(extra, "Never", 66, 77, 69, 13, 11, "text", Enum.TextXAlignment.Right)
		lastUsed.TextTruncate = Enum.TextTruncate.AtEnd
		infoUI.lastUsed = lastUsed
	end
	infoUI.extraItems = prep(infoUI.extra)
	infoUI.iconItems = prep(infoIcon)

	-- Keyless Mode card: informational only (no click)
	local keylessCard = linkButton(206, "Keyless Mode", "No key needed", Images.KEYLESS)
	keylessCard.Visible = SHOW_KEYLESS_CARD

	local closeBtn = make("TextButton", {
		Name = "CloseButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = "card",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 5,
	}, content)
	make("UICorner", { CornerRadius = UDim.new(0, 7) }, closeBtn)

	local closeIcon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = CLOSE_ICON,
		ImageColor3 = iconRole("muted"),
		ZIndex = 6,
	}, closeBtn)

	local moonBtn = make("TextButton", {
		Name = "ThemeButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -38, 0, 12),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = "card",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 5,
	}, content)
	make("UICorner", { CornerRadius = UDim.new(0, 7) }, moonBtn)

	local moonIcon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Image = MOON_ICON,
		ImageColor3 = iconRole("muted"),
		ZIndex = 6,
	}, moonBtn)
	moonBtn.Visible = SHOW_CHANGE_THEME

	local closeGui

	-- Page 2: a down arrow at the bottom of the Key System slides it up and brings in the
	-- topbar + Tabs (OphynWindow({ Title, Icon }), Tab:Section, Tab:Paragraph). Kept in ctx
	-- so it doesn't take another local in UI.new (already close to Lua's limit). It is built
	-- before prep(content) on purpose, so the arrow fades in and out with the Key System.
	ctx.pages = Pages.new({
		C = C,
		make = make,
		round = round,
		tween = tween,
		prep = prep,
		fade = fade,
		setRole = setRole,
		icon = icon,
		assetId = assetId,
		contrastOn = contrastOn,
		iconRole = iconRole,
		logoRole = logoRole,
		markTitleFont = markTitleFont,
		-- SetTabsStyle wins over TabsStyle from KeySystem.new({ ... }) / variables.lua
		getTabsStyle = function()
			if tabsSettings.style then
				return tabsSettings.style
			end
			for _, source in ipairs({ options or {}, Variables }) do
				local value = source.TabsStyle
				if value == nil then
					value = source.tabsstyle
				end
				if value ~= nil then
					return tostring(value)
				end
			end
			return "1"
		end,
		registerTabsStyle = function(apply)
			table.insert(tabsAppliers, apply)
		end,
		FONT = FONT,
		FONT_BOLD = FONT_BOLD,
		images = Images,
		canvas = canvas,
		content = content,
		state = state,
		width = FINAL_W,
		height = FINAL_H,
		title = HUB_NAME,
		logo = LOGO,
		onOpen = function()
			closeMethodDropdown()
		end,
		requestClose = function()
			if not state.ready or state.closing then
				return
			end
			task.spawn(closeGui)
		end,
	})

	-- Keyless mode: dim + lock the disabled parts. This runs BEFORE prep(content) on
	-- purpose, so the dimmed transparencies become the "original" values that
	-- fade() restores (a later fade-in would otherwise undo the dimming).
	if KEYLESS then
		local DIM = 0.5
		local function dim(container)
			local function apply(inst)
				if inst:IsA("GuiObject") then
					inst.BackgroundTransparency = 1 - (1 - inst.BackgroundTransparency) * DIM
					if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
						inst.TextTransparency = 1 - (1 - inst.TextTransparency) * DIM
					elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
						inst.ImageTransparency = 1 - (1 - inst.ImageTransparency) * DIM
					end
				elseif inst:IsA("UIStroke") then
					inst.Transparency = 1 - (1 - inst.Transparency) * DIM
				end
			end
			apply(container)
			for _, d in ipairs(container:GetDescendants()) do
				apply(d)
			end
		end

		if KL.disabletextbox then
			dim(licenseLabel)
			dim(inputBox)
			pcall(function()
				keyBox.TextEditable = false
				keyBox.Active = false
				keyBox.Interactable = false
			end)
			keyBox.Focused:Connect(function()
				keyBox:ReleaseFocus()
			end)
		end

		if KL.disablegetkey then
			dim(getKey)
			pcall(function()
				getKey.Active = false
				getKey.Interactable = false
				methodArrow.Active = false
				methodArrow.Interactable = false
			end)
		end

		statusValue.Text = "Keyless"
		setRole(statusValue, "TextColor3", "accent")
	end

	local spinnerItems = prep(spinnerHolder)
	local contentItems = prep(content)
	fade(spinnerItems, 0)
	fade(contentItems, 0)

	local SUPPORTED_GAMES = {} -- [PlaceId] = true
	-- SupportedGames: { [PlaceId] = true, ... } or a plain list { PlaceId, PlaceId, ... }.
	-- What the person passes to KeySystem.new wins over the default in variables.lua.
	for _, source in ipairs({ options or {}, Variables }) do
		local value = source.SupportedGames
		if value == nil then
			value = source.supportedgames
		end
		if type(value) == "table" then
			for k, v in pairs(value) do
				if type(v) == "number" then
					SUPPORTED_GAMES[v] = true
				elseif v then
					SUPPORTED_GAMES[tonumber(k) or k] = true
				end
			end
			break
		end
	end

	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if state.closing then
			return
		end
		gameName.Text = (ok and type(info) == "table" and info.Name) or "Unknown game"

		if game.GameId ~= 0 then
			gameImg.Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150"
		end

		if SUPPORTED_GAMES[game.PlaceId] then
			gameStatus.Text = "Supported"
			setRole(gameStatus, "TextColor3", "success")
		else
			gameStatus.Text = "Not in our list"
			setRole(gameStatus, "TextColor3", "muted")
		end
	end)

	local function detectExecutor()
		local ok, name = pcall(function()
			if identifyexecutor then
				return identifyexecutor()
			elseif getexecutorname then
				return getexecutorname()
			end
		end)
		if ok and name and tostring(name) ~= "" then
			return tostring(name)
		end
		return "Unknown"
	end

	executorLabel.Text = detectExecutor()

	local function copyLink(url, label, iconKey)
		if not state.ready or state.closing then
			return false
		end
		local fn = setclipboard or toclipboard
		local ok = fn and pcall(fn, url)
		if ok then
			notify(label .. " copied", "The link is in your clipboard.", "success", iconKey)
			return true
		end
		notify("Couldn't copy", url, "warn", iconKey, 5)
		return false
	end

	local fetchingKeyLink = false

	getKey.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		if KEYLESS and KL.disablegetkey then
			return
		end

		if #getMethods > 0 then
			local method = getMethods[selectedMethodIndex or 1]
			if not method then
				return
			end
			if method.url and method.url ~= "" then
				copyLink(method.url, "Key link", "link")
				return
			end
			if type(method.getKeyLink) == "function" then
				if fetchingKeyLink then
					return
				end
				fetchingKeyLink = true
				task.spawn(function()
					local req = request or http_request or (syn and syn.request) or (http and http.request)
					local ctx = { Request = req }
					for k, v in pairs(method.fields or {}) do
						ctx[k] = v
					end
					local ok, link, err = pcall(method.getKeyLink, ctx)
					fetchingKeyLink = false
					if not state.ready or state.closing then
						return
					end
					if ok and link then
						copyLink(link, "Key link", "link")
					else
						notify("Couldn't get a key", tostring((not ok) and link or err or "Try again."), "warn", "link", 5)
					end
				end)
			end
			return
		end

		if LINKS.getKey ~= "" then
			copyLink(LINKS.getKey, "Key link", "link")
			return
		end

		-- Services that can generate a key link (KeySystem.API and Jnkie)
		local linkProviders = {}
		for _, service in ipairs(API_SERVICES) do
			if service.GetKeyLink then
				table.insert(linkProviders, function()
					return service:GetKeyLink()
				end)
			end
		end
		if KEY_JNKIE then
			table.insert(linkProviders, function()
				return KEY_JNKIE:GetKeyLink()
			end)
		end

		if #linkProviders > 0 then
			if fetchingKeyLink then
				return
			end
			fetchingKeyLink = true
			task.spawn(function()
				local link, err
				for _, getLink in ipairs(linkProviders) do
					local ok, res, res2 = pcall(getLink)
					if ok and res then
						link = res
						break
					end
					err = ok and res2 or (not ok and res) or err
				end
				fetchingKeyLink = false
				if not state.ready or state.closing then
					return
				end
				if link then
					copyLink(link, "Key link", "link")
				elseif err == "RATE_LIMITED" then
					notify("Slow down", "Wait 5 minutes before requesting another link.", "warn", "link", 5)
				else
					notify("Couldn't get a link", tostring(err or "Unknown error"), "warn", "link", 5)
				end
			end)
			return
		end

		if LINKS.website ~= "" then
			copyLink(LINKS.website, "Key link", "link")
			return
		end

		notify("No link set", "The key link isn't set.", "warn", "link")
	end)

	local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

	local discordInfo = { fetching = false, ok = false, iconLoaded = false, last = 0, online = 0, offline = 0 }

	local discordOpen = false
	local infoOpen = false

	local function anyCardOpen()
		return discordOpen or infoOpen
	end

	local function refreshDiscordTitle()
		local target = (discordOpen and discordInfo.name) or "Discord"
		if discordTitle.Text == target then
			return
		end
		if not state.ready then
			discordTitle.Text = target
			return
		end
		tween(discordTitle, 0.12, { TextTransparency = 1 })
		task.delay(0.12, function()
			if state.closing then
				return
			end
			discordTitle.Text = (discordOpen and discordInfo.name) or "Discord"
			tween(discordTitle, 0.15, { TextTransparency = 0 })
		end)
	end

	local function formatNumber(n)
		local reversed = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
		return (reversed:gsub("^,", ""))
	end

	local function applyDiscordInfo()
		if discordInfo.ok then
			onlineNum.Text = formatNumber(discordInfo.online)
			offlineNum.Text = formatNumber(discordInfo.offline)
		elseif discordInfo.fetching then
			onlineNum.Text = "..."
			offlineNum.Text = "..."
		else
			onlineNum.Text = "N/A"
			offlineNum.Text = "N/A"
		end
	end

	local function fetchDiscord()
		if discordInfo.fetching then
			return
		end
		discordInfo.fetching = true
		applyDiscordInfo()

		if httpRequest then
			local ok, res = pcall(httpRequest, {
				Url = "https://discord.com/api/v10/invites/" .. INVITE_CODE .. "?with_counts=true",
				Method = "GET",
			})
			if ok and res and res.StatusCode == 200 and res.Body then
				local okJson, data = pcall(function()
					return HttpService:JSONDecode(res.Body)
				end)
				if okJson and type(data) == "table" and data.approximate_member_count then
					local online = data.approximate_presence_count or 0
					discordInfo.online = online
					discordInfo.offline = math.max(data.approximate_member_count - online, 0)
					discordInfo.ok = true
					discordInfo.last = os.clock()
					if type(data.guild) == "table" and data.guild.name then
						discordInfo.name = data.guild.name
					end

					local guild = data.guild
					local getAsset = getcustomasset or getsynasset
					if guild and guild.icon and not discordInfo.iconLoaded and writefile and getAsset then
						local url = ("https://cdn.discordapp.com/icons/%s/%s.png?size=128"):format(guild.id, guild.icon)
						local okI, resI = pcall(httpRequest, { Url = url, Method = "GET" })
						if okI and resI and resI.StatusCode == 200 and resI.Body and #resI.Body > 0 then
							local okW, asset = pcall(function()
								local fileName = "discord_" .. INVITE_CODE .. ".png"
								if FOLDER and FOLDER ~= "" then
									if isfolder and makefolder and not isfolder(FOLDER) then
										makefolder(FOLDER)
									end
									fileName = FOLDER .. "/" .. fileName
								end
								writefile(fileName, resI.Body)
								return getAsset(fileName)
							end)
							if okW and asset then
								serverIcon.Image = asset
								unbind(serverIcon, "ImageColor3")
								serverIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
								serverIcon.ScaleType = Enum.ScaleType.Crop
								discordInfo.iconLoaded = true
							end
						end
					end
				end
			end
		end

		discordInfo.fetching = false
		applyDiscordInfo()
		refreshDiscordTitle()
	end

	if HAS_DISCORD then
		task.spawn(fetchDiscord)
	end

	-- Stacks whichever cards are enabled (Discord, Keyless, Website, Information, in
	-- that order) inside the scroll frame. Expanding a card (Discord / Information)
	-- pushes the cards below it down and moves the whole list up, hiding the
	-- Executor / Status rows. Anything that doesn't fit becomes scrollable.
	local CARD_GAP = 8
	local cardOrder = {}
	if SHOW_DISCORD_CARD then
		table.insert(cardOrder, discord)
	end
	if SHOW_KEYLESS_CARD then
		table.insert(cardOrder, keylessCard)
	end
	if SHOW_WEBSITE_CARD then
		table.insert(cardOrder, website)
	end
	if SHOW_INFO_CARD then
		table.insert(cardOrder, infoCard)
	end

	local function cardHeight(card)
		if card == discord and discordOpen then
			return 82
		end
		if card == infoCard and infoOpen then
			return INFO_OPEN_H
		end
		return 40
	end

	local layoutToken = 0

	-- focusCard: scrolled into view when the layout changes (used when a card expands)
	local function layoutCards(instant, focusCard)
		local Quint = Enum.EasingStyle.Quint
		local open = anyCardOpen()
		local divider = open and 106 or 148
		local top = open and 114 or 158

		local y = CARD_PAD
		local focusTop, focusBottom
		for _, card in ipairs(cardOrder) do
			local h = cardHeight(card)
			if card == focusCard then
				focusTop, focusBottom = y - CARD_PAD, y + h + CARD_PAD
			end
			if instant then
				card.Position = UDim2.new(0, CARD_PAD, 0, y)
				card.Size = UDim2.new(0, 147, 0, h)
			else
				tween(card, 0.55, {
					Position = UDim2.new(0, CARD_PAD, 0, y),
					Size = UDim2.new(0, 147, 0, h),
				}, Quint)
			end
			y = y + h + CARD_GAP
		end

		local canvasH = math.max(y - CARD_GAP + CARD_PAD, 0)
		local viewH = CARD_VIEW_BOTTOM - top + CARD_PAD
		local maxPos = math.max(canvasH - viewH, 0)
		local pos = cardScroll.CanvasPosition.Y
		local targetPos = math.clamp(pos, 0, maxPos)
		if focusTop then
			if focusBottom > targetPos + viewH then
				targetPos = focusBottom - viewH
			end
			if focusTop < targetPos then
				targetPos = focusTop
			end
			targetPos = math.clamp(targetPos, 0, maxPos)
		end

		local scrollPos = UDim2.new(0, 20 - CARD_PAD, 0, top - CARD_PAD)
		local scrollSize = UDim2.new(0, 147 + CARD_PAD + 5, 0, viewH)
		local canvasSize = UDim2.new(0, 0, 0, canvasH)

		layoutToken += 1
		local token = layoutToken

		if instant then
			rightDivider.Position = UDim2.new(0, 20, 0, divider)
			cardScroll.Position = scrollPos
			cardScroll.Size = scrollSize
			cardScroll.CanvasSize = canvasSize
			cardScroll.CanvasPosition = Vector2.new(0, targetPos)
			return
		end

		tween(rightDivider, 0.55, { Position = UDim2.new(0, 20, 0, divider) }, Quint)

		-- Grow the canvas right away (so the scroll target is reachable); shrink it only
		-- once the cards finished moving (so the position doesn't get clamped mid-tween).
		if canvasH >= cardScroll.CanvasSize.Y.Offset then
			cardScroll.CanvasSize = canvasSize
		else
			task.delay(0.58, function()
				if token == layoutToken then
					cardScroll.CanvasSize = canvasSize
				end
			end)
		end
		tween(cardScroll, 0.55, {
			Position = scrollPos,
			Size = scrollSize,
			CanvasPosition = Vector2.new(0, targetPos),
		}, Quint)
	end
	layoutCards(true)

	-- Dragging the card list with the mouse (the wheel and touch scroll natively).
	-- A drag never counts as a click on the card under the cursor.
	local suppressClick = false
	do
	local dragging, dragStartY, dragStartCanvas = false, 0, 0
	local function onPress(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or dragging or not state.ready then
			return
		end
		if cardScroll.CanvasSize.Y.Offset <= cardScroll.AbsoluteSize.Y then
			return
		end
		dragging = true
		dragStartY = input.Position.Y
		dragStartCanvas = cardScroll.CanvasPosition.Y
	end
	cardScroll.InputBegan:Connect(onPress)
	for _, card in ipairs(cardOrder) do
		card.InputBegan:Connect(onPress)
	end
	local dragMove = UserInputService.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local delta = input.Position.Y - dragStartY
		if not suppressClick and math.abs(delta) < 5 then
			return
		end
		suppressClick = true
		local maxPos = math.max(cardScroll.CanvasSize.Y.Offset - cardScroll.AbsoluteSize.Y, 0)
		cardScroll.CanvasPosition = Vector2.new(0, math.clamp(dragStartCanvas - delta, 0, maxPos))
	end)
	local dragEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not dragging then
			return
		end
		dragging = false
		task.delay(0.1, function()
			suppressClick = false
		end)
	end)
	root.Destroying:Connect(function()
		dragMove:Disconnect()
		dragEnd:Disconnect()
	end)
	end

	local discordToken = 0

	local function setDiscord(open)
		discordOpen = open
		refreshDiscordTitle()
		discordToken += 1
		local token = discordToken
		local Quint = Enum.EasingStyle.Quint

		layoutCards(false, open and discord or nil)

		local textX = open and 40 or 36
		tween(discordTitle, 0.4, { Position = UDim2.new(0, textX, 0, 6) }, Quint)
		tween(discordSub, 0.4, {
			Position = UDim2.new(0, textX, 0, 21),
			Size = UDim2.new(0, open and 102 or 106, 0, 13),
		}, Quint)

		fade(rowsItems, anyCardOpen() and 0 or 1, 0.25)
		fade(discordIconItems, open and 0 or 1, 0.2)

		if open then
			discordExtra.Visible = true
			fade(extraItems, 0)
			task.delay(0.15, function()
				if token == discordToken then
					fade(extraItems, 1, 0.3)
				end
			end)
			if not discordInfo.fetching and (not discordInfo.ok or os.clock() - discordInfo.last > 60) then
				task.spawn(fetchDiscord)
			end
		else
			fade(extraItems, 0, 0.15)
			tween(discordSub, 0.15, { TextColor3 = C.muted })
			task.delay(0.17, function()
				if token == discordToken then
					discordExtra.Visible = false
				end
			end)
		end
	end

	-- Same end state as setDiscord(true), without animation (content is still hidden at launch)
	if DISCORD_STARTS_OPEN then
		discordOpen = true
		discordToken += 1
		layoutCards(true)
		discordTitle.Position = UDim2.new(0, 40, 0, 6)
		discordSub.Position = UDim2.new(0, 40, 0, 21)
		discordSub.Size = UDim2.new(0, 102, 0, 13)
		fade(rowsItems, 0)
		fade(discordIconItems, 0)
		discordExtra.Visible = true
	end

	discord.MouseButton1Click:Connect(function()
		if not state.ready or state.closing or suppressClick then
			return
		end
		if not HAS_DISCORD then
			notify("Not configured", "No Discord link has been set.", "warn", "discord")
			return
		end
		setDiscord(not discordOpen)
	end)

	linkHit.MouseButton1Click:Connect(function()
		if suppressClick then
			return
		end
		copyLink(LINKS.discord, "Discord invite", "discord")
	end)
	linkHit.MouseEnter:Connect(function()
		if discordOpen then
			tween(discordSub, 0.15, { TextColor3 = C.accent })
		end
	end)
	linkHit.MouseLeave:Connect(function()
		tween(discordSub, 0.15, { TextColor3 = C.muted })
	end)
	website.MouseButton1Click:Connect(function()
		if not state.ready or state.closing or suppressClick then
			return
		end
		if not HAS_WEBSITE then
			notify("Not configured", "No website link has been set.", "warn", "link")
			return
		end
		copyLink(LINKS.website, "Website link", "link")
	end)

	local function refreshInfo()
		infoUI.valid.Text = formatNumber(STATS.valid)
		infoUI.expired.Text = formatNumber(STATS.expired)
		infoUI.lastUsed.Text = formatAgo(STATS.last)
	end
	refreshInfo()

	do
	local function setLabelText(label, str)
		if label.Text == str then
			return
		end
		if not state.ready then
			label.Text = str
			return
		end
		tween(label, 0.12, { TextTransparency = 1 })
		task.delay(0.12, function()
			if state.closing then
				return
			end
			label.Text = str
			tween(label, 0.15, { TextTransparency = 0 })
		end)
	end

	local infoToken = 0

	local function setInfo(open)
		infoOpen = open
		infoToken += 1
		local token = infoToken
		local Quint = Enum.EasingStyle.Quint

		if open then
			refreshInfo()
		end
		setLabelText(infoSub, open and "Key history" or "Tap to view")

		layoutCards(false, open and infoCard or nil)

		local textX = open and 40 or 36
		tween(infoTitle, 0.4, { Position = UDim2.new(0, textX, 0, 6) }, Quint)
		tween(infoSub, 0.4, {
			Position = UDim2.new(0, textX, 0, 21),
			Size = UDim2.new(0, open and 102 or 106, 0, 13),
		}, Quint)

		fade(rowsItems, anyCardOpen() and 0 or 1, 0.25)
		fade(infoUI.iconItems, open and 0 or 1, 0.2)

		if open then
			infoUI.extra.Visible = true
			fade(infoUI.extraItems, 0)
			task.delay(0.15, function()
				if token == infoToken then
					fade(infoUI.extraItems, 1, 0.3)
				end
			end)
		else
			fade(infoUI.extraItems, 0, 0.15)
			task.delay(0.17, function()
				if token == infoToken then
					infoUI.extra.Visible = false
				end
			end)
		end
	end

	infoCard.MouseButton1Click:Connect(function()
		if not state.ready or state.closing or suppressClick then
			return
		end
		setInfo(not infoOpen)
	end)
	end

	local checkingKey = false

	-- While a card is expanded the Executor/Status rows stay hidden, and the small
	-- icon of the expanded card is replaced by its bigger one
	local fadeContent
	do
	local rowsHidden, discordIconHidden, infoIconHidden = {}, {}, {}
	for _, it in ipairs(rowsItems) do
		rowsHidden[it[1]] = true
	end
	for _, it in ipairs(discordIconItems) do
		discordIconHidden[it[1]] = true
	end
	for _, it in ipairs(infoUI.iconItems) do
		infoIconHidden[it[1]] = true
	end

	function fadeContent(alpha, time)
		if anyCardOpen() and alpha > 0 then
			local filtered = {}
			for _, it in ipairs(contentItems) do
				local inst = it[1]
				local hide = rowsHidden[inst] or (discordOpen and discordIconHidden[inst]) or (infoOpen and infoIconHidden[inst])
				if not hide then
					filtered[#filtered + 1] = it
				end
			end
			fade(filtered, alpha, time)
		else
			fade(contentItems, alpha, time)
		end
	end
	end

	local function resetCheckScreen()
		ringScale.Scale = 0.6
		for _, b in ipairs({ checkBar1, checkBar2 }) do
			b.frame.Visible = false
			b.frame.Size = UDim2.new(0, 0, 0, 3)
		end
		checkText.TextTransparency = 1
		checkText.Position = UDim2.new(0, 0, 0, 162)
		fade(ringItems, 0)
	end

	local function drawBar(bar, time)
		bar.frame.Size = UDim2.new(0, 0, 0, 3)
		bar.frame.Position = UDim2.new(0.5, bar.a.X, 0.5, bar.a.Y)
		bar.frame.Visible = true
		local mid = (bar.a + bar.b) / 2
		tween(bar.frame, time, {
			Size = UDim2.new(0, bar.len, 0, 3),
			Position = UDim2.new(0.5, mid.X, 0.5, mid.Y),
		})
	end

	local function confetti(count, withPulse)
		local colors = C.confetti
		for i = 1, count do
			local angle = (i / count) * math.pi * 2 + math.random() * 0.3
			local dist = 70 + math.random() * 45
			local piece = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -12),
				Size = UDim2.new(0, math.random(4, 7), 0, math.random(3, 5)),
				BackgroundColor3 = colors[math.random(#colors)],
				BorderSizePixel = 0,
				Rotation = math.random(0, 360),
				ZIndex = 3,
			}, fxLayer)
			make("UICorner", { CornerRadius = UDim.new(0, 2) }, piece)

			local t = 0.55 + math.random() * 0.3
			tween(piece, t, {
				Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, -12 + math.sin(angle) * dist * 0.85 + 14),
				Rotation = piece.Rotation + math.random(-260, 260),
			}, Enum.EasingStyle.Quint)
			task.delay(t * 0.6, function()
				tween(piece, t * 0.8, { BackgroundTransparency = 1 })
			end)
			task.delay(t * 1.5 + 0.2, function()
				piece:Destroy()
			end)
		end

		if withPulse then
			local pulse, pulseStroke = ring(fxLayer, 56, 2, C.accent, 0.2)
			pulse.Position = UDim2.new(0.5, 0, 0.5, -12)
			tween(pulse, 0.7, { Size = UDim2.new(0, 150, 0, 150) }, Enum.EasingStyle.Quint)
			tween(pulseStroke, 0.7, { Transparency = 1 })
			task.delay(0.8, function()
				pulse:Destroy()
			end)
		end
	end

	local function runKeyCheck(key, isSavedKey)
		checkingKey = true
		state.ready = false
		notifs.dismissAll()

		local result
		task.spawn(function()
			if KEYLESS then
				result = { ok = true, valid = true }
				return
			end
			local ok, valid, reason = pcall(validateKey, key)
			result = { ok = ok, valid = valid, reason = reason }
		end)

		fadeContent(0, 0.25)
		task.wait(0.25)
		content.Visible = false
		spinnerHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
		spin:Play()
		fade(spinnerItems, 1, 0.25)

		local minCheckTime = isSavedKey and SAVED_CHECK_TIME or CHECK_TIME
		local t0 = os.clock()
		repeat
			task.wait()
		until (result and os.clock() - t0 >= minCheckTime) or os.clock() - t0 > 15

		if not (result and result.ok and result.valid) then
			fade(spinnerItems, 0, 0.25)
			task.wait(0.25)
			spin:Cancel()
			content.Visible = true
			fadeContent(1, 0.35)
			if result and result.ok then
				local detail = result.reason and tostring(result.reason) or "That key isn't valid. Get a new one."
				if detail:lower():find("expir") then
					STATS.expired += 1
					saveStats()
					refreshInfo()
				end
				notify("Invalid key", detail, "error")
				task.spawn(function()
					local base = main.Position
					for _, dx in ipairs({ -10, 8, -6, 4, -2, 0 }) do
						tween(main, 0.05, { Position = UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset) }, Enum.EasingStyle.Sine)
						task.wait(0.05)
					end
				end)
			else
				local detail = result and result.valid and tostring(result.valid) or "Couldn't check your key. Try again."
				notify("Something went wrong", detail, "error")
			end
			task.wait(0.35)
			state.ready = true
			checkingKey = false
			return
		end

		if KEYLESS then
			statusValue.Text = "Keyless"
			setRole(statusValue, "TextColor3", "accent")
			checkText.Text = "Keyless Access!"
		else
			statusValue.Text = "Key valid"
			setRole(statusValue, "TextColor3", "success")
			checkText.Text = isSavedKey and "Saved Key Found!" or "Correct Key!"

			if KEY_SAVE then
				safeWriteFile(KEY_FILE, key)
			end

			STATS.valid += 1
			STATS.last = os.time()
			saveStats()
		end

		fade(spinnerItems, 0, 0.25)
		task.wait(0.25)
		spin:Cancel()
		resetCheckScreen()
		checkScreen.Visible = true
		fade(ringItems, 1, 0.25)
		tween(ringScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		task.wait(isSavedKey and 0.15 or 0.4)

		drawBar(checkBar1, 0.14)
		task.wait(0.14)
		drawBar(checkBar2, 0.22)
		task.wait(0.22)

		if isSavedKey then
			confetti(10, false)
		else
			confetti(22, true)
			task.delay(0.3, function()
				confetti(12, false)
			end)
		end

		task.wait(isSavedKey and 0.2 or 1)
		tween(checkText, 0.3, { TextTransparency = 0, Position = UDim2.new(0, 0, 0, 156) }, Enum.EasingStyle.Quint)
		task.wait(isSavedKey and 0.35 or 1)

		snapLocked = true
		fade(ringItems, 0, 0.2)
		tween(checkText, 0.2, { TextTransparency = 1 })
		task.wait(0.2)
		checkScreen.Visible = false
		-- ===== Liquid split: the key window stretches like liquid and divides in two. One half lands as the
		-- real Airflow notification (built by Window:Notify, so it is the default one), the other grows into
		-- the real Airflow window. Falls back to the classic morph when there is no gated window. =====
		do
			local MT = cfg.MainTransition
			if type(MT) == "table" and type(MT.Prepare) == "function" and type(MT.Target) == "function" then
				local RS = game:GetService("RunService")
				local toast, target, rect
				tween(decorGroup, 0.2, { GroupTransparency = 1 })
				local okP, resP = pcall(MT.Prepare, key)
				if okP and type(resP) == "table" then toast = resP end
				if toast then
					local okT, resT = pcall(MT.Target)
					if okT and type(resT) == "table" then target = resT end
				end
				if toast and target then
					-- give the real notification a few frames to lay itself out, then read where it rests
					local waitFrom, frames = os.clock(), 0
					while os.clock() - waitFrom < 1.2 do
						RS.RenderStepped:Wait()
						frames += 1
						local card = toast.Card
						if frames >= 3 and card and card.Parent and card.AbsoluteSize.Y > 8 then
							rect = { pos = card.AbsolutePosition, size = card.AbsoluteSize }
							break
						end
					end
				end
				if toast and not rect then pcall(toast.Dismiss) end

				if rect then
					if type(cfg.OnAcceptedStart) == "function" then
						local ok, err = pcall(cfg.OnAcceptedStart, key, true)
						if not ok then warn("[KeySystem] OnAcceptedStart failed: " .. tostring(err)) end
					end

					local U = 1.5
					local c0 = main.AbsolutePosition + main.AbsoluteSize / 2
					local s0 = main.AbsoluteSize
					local cA, sA = rect.pos + rect.size / 2, rect.size
					local cB, sB, radB = target.Center, target.Size, target.Radius or 10
					local drop = Vector2.new(112, 60)
					local dv = cA - c0
					local dl = math.max(dv.Magnitude, 1)
					local dirX, dirY = math.abs(dv.X) / dl, math.abs(dv.Y) / dl
					local colorFrom, colorTo, edgeTo = canvas.BackgroundColor3, Theme.Background, Theme.Stroke
					local layer
					local aFired, bFired, aAt, bAt = false, false, 0, 0

					local okRun, errRun = pcall(function()
						local function smooth(p) return p * p * (3 - 2 * p) end
						local function easeIO(p)
							if p < 0.5 then return 4 * p * p * p end
							return 1 - ((-2 * p + 2) ^ 3) / 2
						end
						local function easeOut3(p) return 1 - (1 - p) ^ 3 end
						local function easeExpo(p)
							if p >= 1 then return 1 end
							return 1 - 2 ^ (-10 * p)
						end
						local function easeBack(p)
							local c1 = 1.25
							return 1 + (c1 + 1) * (p - 1) ^ 3 + c1 * (p - 1) ^ 2
						end

						layer = make("Frame", { Name = "LiquidSplit", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 150 }, root)
						local function sub(z)
							return make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z }, layer)
						end
						-- shadows < outlines < fills, so the outline only shows around the merged liquid shape
						local shLayer, edgeLayer, fillLayer = sub(1), sub(2), sub(3)
						local function newShape(parent)
							local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = colorFrom, BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 0) }, parent)
							local c = make("UICorner", { CornerRadius = UDim.new(0, 10) }, f)
							return { f = f, c = c }
						end
						local function newShadow()
							return make("ImageLabel", {
								AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = Images.SHADOW,
								ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.6, ScaleType = Enum.ScaleType.Slice,
								SliceCenter = Rect.new(49, 49, 450, 450), Size = UDim2.new(0, 0, 0, 0),
							}, shLayer)
						end
						local shB, shA = newShadow(), newShadow()
						local neckE, neckF = {}, {}
						local N = 8
						for i = 1, N do neckE[i] = newShape(edgeLayer) end
						local bEdge, aEdge = newShape(edgeLayer), newShape(edgeLayer)
						for i = 1, N do neckF[i] = newShape(fillLayer) end
						local bFill, aFill = newShape(fillLayer), newShape(fillLayer)

						local function place(s, cx, cy, w, h, radius, rot, grow, color, alpha)
							local g = grow or 0
							local ww = math.max(math.floor(w + 0.5) + g * 2, 0)
							local hh = math.max(math.floor(h + 0.5) + g * 2, 0)
							s.f.Position = UDim2.fromOffset(math.floor(cx + 0.5), math.floor(cy + 0.5))
							s.f.Size = UDim2.fromOffset(ww, hh)
							s.f.Rotation = rot or 0
							s.c.CornerRadius = UDim.new(0, math.max(math.floor(radius + g + 0.5), 0))
							s.f.BackgroundColor3 = color
							s.f.BackgroundTransparency = alpha or 0
							s.f.Visible = ww > 0 and hh > 0
						end

						local function apply(u)
							-- A: the half that becomes the notification
							local pA = math.clamp((u - 0.16) / 0.62, 0, 1)
							local travel = easeIO(pA)
							local ax = c0.X + (cA.X - c0.X) * travel
							local ay = c0.Y + (cA.Y - c0.Y) * travel
							local shrink = easeOut3(math.clamp(pA / 0.45, 0, 1))
							local aw, ah, arad
							if pA < 0.62 then
								aw = s0.X + (drop.X - s0.X) * shrink
								ah = s0.Y + (drop.Y - s0.Y) * shrink
								arad = 10 + 20 * shrink
							else
								local ex = easeBack(math.clamp((pA - 0.62) / 0.38, 0, 1))
								aw = drop.X + (sA.X - drop.X) * ex
								ah = drop.Y + (sA.Y - drop.Y) * ex
								arad = 30 + (12 - 30) * ex
							end
							-- stretch along the direction of travel, squeeze the other axis
							local vel = math.sin(math.pi * pA)
							aw = aw * (1 + 0.30 * vel * dirX - 0.10 * vel * dirY)
							ah = ah * (1 + 0.30 * vel * dirY - 0.10 * vel * dirX)
							local ant = u < 0.16 and math.sin(math.pi * u / 0.16) or 0
							local breath = 1 - 0.035 * ant
							aw, ah = aw * breath, ah * breath

							-- B: the half that becomes the window (recoils when A pinches off, then blooms)
							local pB = math.clamp((u - 0.62) / 0.75, 0, 1)
							local gB = easeExpo(pB)
							local recoil = math.exp(-(((u - 0.70) / 0.06) ^ 2))
							local bs = (1 - 0.04 * recoil) * breath
							local bw = (s0.X + (sB.X - s0.X) * gB) * bs
							local bh = (s0.Y + (sB.Y - s0.Y) * gB) * bs
							local bx = c0.X + (cB.X - c0.X) * gB
							local by = c0.Y + (cB.Y - c0.Y) * gB
							local brad = 10 + (radB - 10) * gB

							if not aFired and pA >= 0.93 then
								aFired, aAt = true, u
								task.spawn(function() pcall(toast.Reveal) end)
							end
							if not bFired and pB >= 0.45 then
								bFired, bAt = true, u
								task.spawn(function() pcall(MT.Reveal) end)
							end
							-- the blobs only fade once the real notification / window above them is fully opaque
							local fa = aFired and smooth(math.clamp((u - aAt - 0.32) / 0.12, 0, 1)) or 0
							local fb = bFired and smooth(math.clamp((u - bAt - 0.32) / 0.12, 0, 1)) or 0

							local cm = smooth(math.clamp((u - 0.30) / 0.60, 0, 1))
							local fc = colorFrom:Lerp(colorTo, cm)
							local ec = colorFrom:Lerp(edgeTo, cm)

							-- the liquid bridge between the two halves: tapered, then pinches in the middle and snaps
							local q = math.clamp((u - 0.34) / 0.36, 0, 1)
							local f = 1 - q * q
							local rB0, rA0 = 0.40 * s0.Y, 0.45 * ah
							local dxN, dyN = ax - bx, ay - by
							local ang = math.deg(math.atan2(dyN, dxN))
							local seg = math.sqrt(dxN * dxN + dyN * dyN) / N
							local function neckR(t)
								return (rB0 + (rA0 - rB0) * t) * f * (1 - 0.62 * q * math.sin(math.pi * t))
							end
							for i = 1, N do
								local t0, t1 = (i - 1) / N, i / N
								local thick = neckR(t0) + neckR(t1)
								if f > 0.02 and thick > 2 then
									local mx = bx + dxN * (t0 + t1) / 2
									local my = by + dyN * (t0 + t1) / 2
									place(neckF[i], mx, my, seg + thick * 0.5, thick, thick / 2, ang, 0, fc, 0)
									place(neckE[i], mx, my, seg + thick * 0.5, thick, thick / 2, ang, 1, ec, 0)
								else
									neckF[i].f.Visible = false
									neckE[i].f.Visible = false
								end
							end

							place(bFill, bx, by, bw, bh, brad, 0, 0, fc, fb)
							place(bEdge, bx, by, bw, bh, brad, 0, 1, ec, fb)
							place(aFill, ax, ay, aw, ah, arad, 0, 0, fc, fa)
							place(aEdge, ax, ay, aw, ah, arad, 0, 1, ec, fa)
							shB.Position = UDim2.fromOffset(math.floor(bx + 0.5), math.floor(by + 0.5))
							shB.Size = UDim2.fromOffset(math.floor(bw + 50.5), math.floor(bh + 50.5))
							shB.ImageTransparency = 0.6 + 0.4 * fb
							shA.Position = UDim2.fromOffset(math.floor(ax + 0.5), math.floor(ay + 0.5))
							shA.Size = UDim2.fromOffset(math.floor(aw + 50.5), math.floor(ah + 50.5))
							shA.ImageTransparency = 0.6 + 0.4 * fa
						end

						-- swap the key window for the identical liquid shapes in one frame, then play
						apply(0)
						main.Visible = false
						local started = os.clock()
						while true do
							RS.RenderStepped:Wait()
							local u = os.clock() - started
							if u >= U then break end
							apply(u)
						end
						if not aFired then pcall(toast.Reveal) end
						if not bFired then pcall(MT.Reveal) end
					end)
					if not okRun then
						warn("[KeySystem] liquid split failed: " .. tostring(errRun))
						pcall(toast.Reveal)
						pcall(MT.Reveal)
					end
					if layer then pcall(function() layer:Destroy() end) end

					-- run the user's script exactly like the classic flow does
					local runError
					task.spawn(function()
						local callback = cfg.Callback
						if type(callback) == "string" and callback ~= "" then
							if not loadstring then
								runError = "loadstring is not available"
								return
							end
							local fn, compileError = loadstring(callback)
							if not fn then
								runError = compileError
								return
							end
							callback = fn
						end
						if type(callback) == "function" then
							local ok, err = pcall(callback, key)
							if not ok then runError = err end
						end
					end)
					task.wait(0.3)
					if runError then
						notify("Script error", tostring(runError):sub(1, 80), "error", nil, 5)
						task.wait(0.2)
					end
					root:Destroy()
					return
				end
			end
		end

		local morphSpec = buildMorph(notifs.styleKey())
		morph.Visible = true
		morphSpec.spin:Play()
		Blur.acquire()

		-- Liquid multiply transition: keep the original branch as the key-system's
		-- notification morph, and send a duplicate branch toward the hidden main Airflow UI.
		local uiBranch
		pcall(function()
			uiBranch = morph:Clone()
			uiBranch.Name = "AirflowMainUIBranch"
			uiBranch.AnchorPoint = Vector2.new(.5, .5)
			uiBranch.Parent = root
			uiBranch.Position = UDim2.fromOffset(root.AbsoluteSize.X / 2, root.AbsoluteSize.Y / 2)
			uiBranch.Size = UDim2.fromOffset(math.max(64, morphSpec.w * .72), math.max(28, morphSpec.h * .72))
			uiBranch.BackgroundColor3 = morphSpec.bg
			uiBranch.BackgroundTransparency = morphSpec.bgTransparency
			uiBranch.ClipsDescendants = true
			uiBranch.ZIndex = 200
			local cr = Instance.new("UICorner")
			cr.CornerRadius = UDim.new(0, morphSpec.radius)
			cr.Parent = uiBranch
			local st = Instance.new("UIStroke")
			st.Color = morphSpec.border
			st.Transparency = morphSpec.borderTransparency
			st.Thickness = 1
			st.Parent = uiBranch
			local function liftZ(obj)
				for _, child in ipairs(obj:GetChildren()) do
					if child:IsA("GuiObject") then child.ZIndex = math.max(child.ZIndex, 201) end
					liftZ(child)
				end
			end
			liftZ(uiBranch)
		end)

		if type(cfg.OnAcceptedStart) == "function" then
			local ok, err = pcall(cfg.OnAcceptedStart, key)
			if not ok then warn("[KeySystem] OnAcceptedStart failed: " .. tostring(err)) end
		end

		local vp = root.AbsoluteSize
		local targetX, targetY
		if morphSpec.top then
			targetX = vp.X / 2
			targetY = 12 + morphSpec.h / 2
		else
			targetX = vp.X - 16 - morphSpec.w / 2
			targetY = vp.Y - 16 - morphSpec.h / 2
		end
		tween(main, 0.7, {
			Size = UDim2.new(0, morphSpec.w, 0, morphSpec.h),
			Position = UDim2.new(0, targetX, 0, targetY),
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		if uiBranch and uiBranch.Parent then
			local target = nil
			pcall(function()
				local gated = Library and Library.Windows and Library.Windows[1]
				if gated and gated.Root and gated.Root.Parent then
					target = gated.Root
				end
			end)
			local branchPos = target and (target.AbsolutePosition + target.AbsoluteSize / 2) or Vector2.new(vp.X / 2, vp.Y / 2)
			local branchSize = target and target.AbsoluteSize or Vector2.new(math.min(vp.X * .72, 760), math.min(vp.Y * .72, 520))
			TweenService:Create(uiBranch, TweenInfo.new(.82, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
				Position = UDim2.fromOffset(branchPos.X, branchPos.Y),
				Size = UDim2.fromOffset(math.max(180, branchSize.X), math.max(120, branchSize.Y)),
				BackgroundTransparency = 1,
			}):Play()
			local branchStroke = uiBranch:FindFirstChildOfClass("UIStroke")
			if branchStroke then TweenService:Create(branchStroke, TweenInfo.new(.72, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), { Transparency = 1 }):Play() end
			task.delay(.9, function() if uiBranch and uiBranch.Parent then uiBranch:Destroy() end end)
		end
		tween(canvas, 0.7, { BackgroundColor3 = morphSpec.bg, BackgroundTransparency = morphSpec.bgTransparency })
		tween(canvasCorner, 0.7, { CornerRadius = UDim.new(0, morphSpec.radius) })
		tween(decorGroup, 0.4, { GroupTransparency = 1 })
		tween(shadow, 0.5, { ImageTransparency = 1 })
		tween(borderStroke, 0.5, { Transparency = morphSpec.borderTransparency, Color = morphSpec.border })
		task.delay(0.35, function()
			fade(morphSpec.items, 1, 0.3)
		end)
		task.wait(0.75)

		task.wait(isSavedKey and 0.2 or 1)

		local runError
		task.spawn(function()
			local callback = cfg.Callback
			if type(callback) == "string" and callback ~= "" then
				if not loadstring then
					runError = "loadstring is not available"
					return
				end
				local fn, compileError = loadstring(callback)
				if not fn then
					runError = compileError
					return
				end
				callback = fn
			end
			if type(callback) == "function" then
				local ok, err = pcall(callback, key)
				if not ok then
					runError = err
				end
			end
		end)
		task.wait(0.3)

		morphSpec.spin:Cancel()
		Blur.release()
		fade(morphSpec.items, 0, 0.25)
		tween(canvas, 0.3, { BackgroundTransparency = 1 })
		tween(borderStroke, 0.3, { Transparency = 1 })
		task.wait(0.35)

		if runError then
			notify("Script error", tostring(runError):sub(1, 80), "error", nil, 5)
			task.wait(5.5)
		end
		if uiBranch and uiBranch.Parent then uiBranch:Destroy() end
		root:Destroy()
	end

	submit.MouseButton1Click:Connect(function()
		if not state.ready or state.closing or checkingKey then
			return
		end

		if KEYLESS then
			runKeyCheck("") -- the Callback receives an empty key in keyless mode
			return
		end

		local key = keyBox.Text:match("^%s*(.-)%s*$")
		if key == "" then
			notify("Empty key", "Paste your key in the box first.", "warn", "key")
			return
		end

		runKeyCheck(key)
	end)

	-- Fechar a UI (o X fecha direto, sem popup de confirmação)
	closeGui = function()
		if state.closing then
			return
		end
		state.closing = true
		state.ready = false
		notifs.dismissAll()

		tintTo(closeIcon, C.muted)
		tween(closeBtn, 0.15, { BackgroundTransparency = 1 })

		if not SHOW_INTRO then
			-- No intro: plain fade-out
			fadeContent(0, 0.3)
			ctx.pages.fadeOut(0.3)
			tween(canvas, 0.35, { BackgroundTransparency = 1 })
			tween(decorGroup, 0.35, { GroupTransparency = 1 })
			tween(borderStroke, 0.35, { Transparency = 1 })
			tween(shadow, 0.35, { ImageTransparency = 1 })
			task.wait(0.4)
			root:Destroy()
			return
		end

		fadeContent(0, 0.2)
		ctx.pages.fadeOut(0.2)

		task.wait(0.2)
		content.Visible = false

		introLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
		tween(introLogo, 0.4, { ImageTransparency = 0 })
		tween(borderStroke, 0.5, { Transparency = 0.55 })
		tween(main, 0.65, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		task.wait(0.7)

		tween(canvas, 0.35, { BackgroundTransparency = 1 })
		tween(decorGroup, 0.35, { GroupTransparency = 1 })
		tween(introLogo, 0.35, { ImageTransparency = 1 })
		tween(borderStroke, 0.35, { Transparency = 1 })
		tween(shadow, 0.35, { ImageTransparency = 1 })
		task.wait(0.4)
		root:Destroy()
	end

	closeBtn.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		task.spawn(closeGui)
	end)

	-- Hovers
	closeBtn.MouseEnter:Connect(function()
		if not state.ready or state.closing then
			return
		end
		tween(closeBtn, 0.15, { BackgroundTransparency = 0 })
		tintTo(closeIcon, C.text)
	end)
	closeBtn.MouseLeave:Connect(function()
		if not state.ready or state.closing then
			return
		end
		tween(closeBtn, 0.15, { BackgroundTransparency = 1 })
		tintTo(closeIcon, C.muted)
	end)
	moonBtn.MouseEnter:Connect(function()
		if not state.ready or state.closing then
			return
		end
		tween(moonBtn, 0.15, { BackgroundTransparency = 0 })
		tintTo(moonIcon, C.text)
	end)
	moonBtn.MouseLeave:Connect(function()
		tween(moonBtn, 0.15, { BackgroundTransparency = 1 })
		tintTo(moonIcon, C.muted)
	end)

	local THEME_ANIM_TIME = 1.6
	local switchingTheme = false

	local function switchTheme()
		if not state.ready or state.closing or checkingKey or switchingTheme then
			return
		end
		switchingTheme = true
		state.ready = false
		notifs.dismissAll()

		tintTo(moonIcon, C.muted)
		tween(moonBtn, 0.15, { BackgroundTransparency = 1 })
		fadeContent(0, 0.25)
		task.wait(0.25)
		content.Visible = false
		spinnerHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
		spin:Play()
		fade(spinnerItems, 1, 0.25)
		task.wait(0.4)

		themeIndex = themeIndex % #THEME_ORDER + 1
		local name = THEME_ORDER[themeIndex]
		applyTheme(name, THEME_ANIM_TIME)
		task.wait(THEME_ANIM_TIME + 0.3)

		fade(spinnerItems, 0, 0.25)
		task.wait(0.25)
		spin:Cancel()
		content.Visible = true
		fadeContent(1, 0.35)
		notify("Theme: " .. name, "Theme applied.", "info", "moon")
		task.wait(0.35)

		state.ready = true
		switchingTheme = false
	end

	moonBtn.MouseButton1Click:Connect(function()
		task.spawn(switchTheme)
	end)

	local guiParent
	pcall(function()
		if type(gethui) == "function" then guiParent = gethui() end
	end)
	if not guiParent then pcall(function() guiParent = game:GetService("CoreGui") end) end
	if not guiParent then guiParent = player:WaitForChild("PlayerGui") end
	root.Parent = guiParent

	local function snap()
		if snapLocked then
			return
		end
		local size = root.AbsoluteSize
		main.Position = UDim2.new(0, math.floor(size.X / 2), 0, math.floor(size.Y / 2))
	end
	snap()
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(snap)

	task.spawn(function()
		if SHOW_INTRO then
			main.Size = UDim2.new(0, INTRO_SIZE - 20, 0, INTRO_SIZE - 20)
			tween(main, 0.6, { Size = UDim2.new(0, INTRO_SIZE, 0, INTRO_SIZE) }, Enum.EasingStyle.Quint)
			tween(canvas, 0.5, { BackgroundTransparency = 0 })
			tween(decorGroup, 0.5, { GroupTransparency = 0 })
			tween(introLogo, 0.5, { ImageTransparency = 0 })
			if SHOW_SQUARE_CONTORN then
				tween(borderStroke, 0.5, { Transparency = 0.55 })
			end
			tween(shadow, 0.5, { ImageTransparency = 0.6 })
			task.wait(SQUARE_TIME)

			tween(borderStroke, 0.7, { Transparency = 1 })
			tween(main, 0.85, { Size = UDim2.new(0, FINAL_W, 0, FINAL_H) }, Enum.EasingStyle.Quint)
			tween(introLogo, 0.7, { Position = UDim2.new(0.5, 0, 0.5, -20) }, Enum.EasingStyle.Quint)
			task.wait(0.35)
			spin:Play()
			fade(spinnerItems, 1, 0.4)

			task.wait(LOADING_TIME)

			fade(spinnerItems, 0, 0.3)
			tween(introLogo, 0.3, { ImageTransparency = 1 })
			task.wait(0.2)
			spin:Cancel()
		else
			-- No intro animation: sit at final size, invisible, for LoadingTime (still
			-- needed to detect the game/executor and let icons finish preloading),
			-- then simply fade the whole window in.
			main.Size = UDim2.new(0, FINAL_W, 0, FINAL_H)
			task.wait(LOADING_TIME)

			tween(canvas, 0.5, { BackgroundTransparency = 0 })
			tween(decorGroup, 0.5, { GroupTransparency = 0 })
			tween(shadow, 0.5, { ImageTransparency = 0.6 })
			task.wait(0.25)
		end

		-- Make sure every icon/image finished preloading before the Key System
		-- content itself is loaded and shown.
		while not iconsPreloaded do
			task.wait()
		end

		content.Visible = true
		fadeContent(1, 0.45)
		task.wait(0.3)
		state.ready = true

		if KEYLESS then
			if KL.autoconfirm and not checkingKey then
				task.wait(0.15)
				runKeyCheck("") -- the Callback receives an empty key in keyless mode
			end
		elseif SAVED_KEY and not checkingKey then
			keyBox.Text = SAVED_KEY
			task.wait(0.15)
			runKeyCheck(SAVED_KEY, true)
		end
	end)

	-- KeySystem.new(...) returns this object: :SetGetkeyTitle / :SetGetkeyIcon, and everything else
	-- (Destroy, Enabled, Parent, ...) is forwarded to the ScreenGui.
	local api = {}
	function api:SetGetkeyTitle(title)
		UI.SetGetkeyTitle(title)
		return self
	end
	function api:SetGetkeyIcon(icon)
		UI.SetGetkeyIcon(icon)
		return self
	end
	function api:SetNotifStyle(style)
		UI.SetNotifStyle(style)
		return self
	end
	api.NotifStyle = api.SetNotifStyle
	function api:SetTabsStyle(style)
		UI.SetTabsStyle(style)
		return self
	end
	api.TabsStyle = api.SetTabsStyle
	function api:GetMethod(entry)
		UI.GetMethod(entry)
		return self
	end
	function api:SetUIFont(font)
		UI.SetUIFont(font)
		return self
	end
	function api:SetTitleFont(font)
		UI.SetTitleFont(font)
		return self
	end
	-- OphynWindow:Tab({ Title = "...", Icon = "..." }) -> Tab (same as OphynWindow({ ... }))
	function api:Tab(props)
		return ctx.pages.createTab(props)
	end
	api.Gui = root

	return setmetatable(api, {
		__call = function(_, props)
			return ctx.pages.createTab(props)
		end,
		__index = function(_, key)
			local value = root[key]
			if type(value) == "function" then
				return function(_, ...)
					return value(root, ...)
				end
			end
			return value
		end,
		__newindex = function(_, key, value)
			root[key] = value
		end,
	})
end

return UI
end

__modules["images/images"] = function()
-- src/images/images.lua
-- All Roblox asset IDs (images, icons, and font) used by the UI.

local Images = {
	FONT = "rbxassetid://12187365364",
	KEY = "rbxassetid://96510194465420",
	SUBMIT = "rbxassetid://113692007244654",
	LINK = "rbxassetid://114238209622913",
	DISCORD = "rbxassetid://127255077587058",
	GLOW = "rbxassetid://8992230677",
	LOGO = "rbxassetid://111673746737789",
	CLOSE_ICON = "rbxassetid://110786993356448",
	MOON_ICON = "rbxassetid://83380517901735",
	SHADOW = "rbxassetid://6014261993",
	GAME_PLACEHOLDER = "rbxassetid://74584987850498",
	KEYLESS = "rbxassetid://130551565616516",
}

return Images
end

__modules["utilities/jnkie"] = function()
local SDK_URL = "https://jnkie.com/sdk/library.lua"

local Jnkie = {}
Jnkie.__index = Jnkie

local function safeLoad(url)
	if not loadstring then
		return nil, "loadstring is not available"
	end
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		return nil, tostring(result)
	end
	local fn, compileErr = loadstring(result)
	if not fn then
		return nil, tostring(compileErr)
	end
	local okRun, lib = pcall(fn)
	if not okRun then
		return nil, tostring(lib)
	end
	return lib
end

function Jnkie.new(config)
	config = config or {}
	local self = setmetatable({}, Jnkie)
	self.__isJnkieInstance = true
	self.service = config.Service or config.service
	self.identifier = config.Identifier or config.identifier
	self.provider = config.Provider or config.provider or "Mixed"
	self.client = nil
	self.loadError = nil

	if not self.service or self.service == "" then
		warn("[Jnkie] Service is missing — check your dashboard for the exact name")
	end
	if not self.identifier or self.identifier == "" then
		warn("[Jnkie] Identifier is missing — check your dashboard for your user ID")
	end

	return self
end

function Jnkie:_client()
	if self.client then
		return self.client
	end
	local lib, err = safeLoad(SDK_URL)
	if not lib then
		self.loadError = err
		warn("[Jnkie] failed to load SDK: " .. tostring(err))
		return nil
	end
	lib.service = self.service
	lib.identifier = self.identifier
	lib.provider = self.provider
	self.client = lib
	return lib
end

local function isSuccess(result)
	if type(result) ~= "table" then
		return false
	end
	if result.valid == true or result.success == true then
		return true
	end
	if result.message == "KEY_VALID" or result.message == "KEYLESS" then
		return true
	end
	return false
end

function Jnkie:CheckKey(key)
	local lib = self:_client()
	if not lib then
		return { valid = false, error = self.loadError or "SDK_LOAD_FAILED" }
	end
	local ok, result = pcall(lib.check_key, key)
	if not ok then
		return { valid = false, error = tostring(result) }
	end
	if type(result) ~= "table" then
		return { valid = false, error = "UNEXPECTED_RESPONSE: " .. tostring(result) }
	end
	result.valid = isSuccess(result)
	return result
end

function Jnkie:GetKeyLink()
	local lib = self:_client()
	if not lib then
		return nil, self.loadError or "SDK_LOAD_FAILED"
	end
	local ok, link, err = pcall(lib.get_key_link)
	if not ok then
		return nil, tostring(link)
	end
	return link, err
end

function Jnkie:Validator()
	local instance = self
	local adapter = setmetatable({
		__isJnkie = true,
		__instance = instance,
	}, {
		__call = function(_, key)
			local result = instance:CheckKey(key)
			local reason = result and (result.error or result.message)
			return result and result.valid == true, reason
		end,
	})
	return adapter
end

return Jnkie
end

__modules["utilities/lucide"] = function()
-- src/utilities/lucide.lua
-- Lucide icon support, backed by https://github.com/Footagesus/Icons (lucide/dist/Icons.lua).
--
-- Anywhere the UI takes an `Icon`, you can now pass a Lucide name instead of an asset id:
--
--   Tab:Section({ Title = "Main", Icon = "house" })
--   Tab:Section({ Title = "Main", Icon = "lucide:house" }) -- same thing, explicit prefix
--
-- Asset ids ("rbxassetid://...", a bare number, "rbxthumb://...") keep working exactly as before.
--
-- The icon pack is a spritesheet: every icon is a rect inside a bigger image, so a resolved
-- icon is { Image, RectSize, RectOffset } and not just one asset id. The pack is only
-- downloaded the first time a Lucide name is actually used (and cached after that), so
-- scripts that only use asset ids never pay for it.

local Lucide = {}

local PACK_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
local PREFIX = "lucide:"

local pack = nil -- the loaded icon pack
local failed = false -- the download/parse failed, don't keep retrying
local loading = false
local preloaded = {} -- spritesheets that already went through ContentProvider
local warned = {} -- names that already printed a warning

local function fetch(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	ok, body = pcall(function()
		return game:HttpGetAsync(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	return nil
end

local function loadPack()
	if pack or failed then
		return pack
	end
	if loading then
		-- another thread is already downloading it: wait for that one
		while loading do
			task.wait()
		end
		return pack
	end

	loading = true
	local ok, result = pcall(function()
		local body = fetch(PACK_URL)
		if not body then
			error("could not download the icon pack")
		end
		local chunk, err = loadstring(body)
		if not chunk then
			error(err)
		end
		return chunk()
	end)
	loading = false

	if ok and type(result) == "table" then
		pack = result
	else
		failed = true
		warn("[Ophyn] Lucide icons unavailable: " .. tostring(result))
	end
	return pack
end

-- "rbxassetid://123" / 123 / "123" -> "rbxassetid://123"; anything else string-like is kept
local function toAsset(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(math.floor(value))
	end
	if type(value) == "string" and value:match("^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

-- true when `value` should be looked up in the Lucide pack (instead of used as an asset id)
function Lucide.isName(value)
	if type(value) ~= "string" or value == "" then
		return false
	end
	if value:match("^%d+$") then
		return false -- bare asset id
	end
	if value:match("^rbx%a*://") or value:match("^https?://") then
		return false -- rbxassetid:// / rbxthumb:// / rbxasset:// / urls
	end
	return true
end

local function stripPrefix(name)
	if name:sub(1, #PREFIX):lower() == PREFIX then
		return name:sub(#PREFIX + 1)
	end
	return name
end

local function preload(sheet)
	if preloaded[sheet] then
		return
	end
	preloaded[sheet] = true
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ sheet })
		end)
	end)
end

-- Returns { Image = "rbxassetid://...", RectSize = Vector2, RectOffset = Vector2 }
-- or nil when the name is unknown (or the pack could not be loaded).
function Lucide.resolve(value)
	if not Lucide.isName(value) then
		return nil
	end

	local name = stripPrefix(value):lower():gsub("_", "-")
	local loaded = loadPack()
	if not loaded then
		return nil
	end

	local icons = loaded.Icons or loaded
	local entry = type(icons) == "table" and icons[name] or nil
	if type(entry) ~= "table" then
		if not warned[name] then
			warned[name] = true
			warn('[Ophyn] unknown Lucide icon "' .. tostring(value) .. '"')
		end
		return nil
	end

	local sheet = entry.Image
	if type(loaded.Spritesheets) == "table" and loaded.Spritesheets[tostring(entry.Image)] ~= nil then
		sheet = loaded.Spritesheets[tostring(entry.Image)]
	end
	sheet = toAsset(sheet)
	if type(sheet) ~= "string" then
		return nil
	end

	preload(sheet)
	return {
		Image = sheet,
		RectSize = entry.ImageRectSize or Vector2.new(0, 0),
		RectOffset = entry.ImageRectPosition or entry.ImageRectOffset or Vector2.new(0, 0),
	}
end

-- Points an ImageLabel/ImageButton at `value`, which can be a Lucide name or an asset id.
-- Always resets the sprite rect, so an icon can be swapped between the two kinds safely.
function Lucide.apply(label, value)
	local sprite = Lucide.resolve(value)
	if sprite then
		label.Image = sprite.Image
		label.ImageRectSize = sprite.RectSize
		label.ImageRectOffset = sprite.RectOffset
		return true
	end

	label.ImageRectSize = Vector2.new(0, 0)
	label.ImageRectOffset = Vector2.new(0, 0)
	if Lucide.isName(value) then
		label.Image = "" -- a Lucide name that could not be resolved: draw nothing
		return false
	end
	label.Image = value or ""
	return value ~= nil
end

return Lucide
end

__modules["utilities/panda"] = function()
local LIB_URL = "https://secure.pandauth.com/pv4/lib"

local REASONS = {
	INVALID_KEY = "key is invalid or expired.",
	RATE_LIMITED = "you are being rate limited, please wait a moment and try again.",
	NETWORK = "network error, please try again.",
	NO_SERVICE = "Panda ServiceId is missing or invalid.",
	NO_KEY = "key is empty.",
	NO_HTTP = "your executor doesn't support HTTP requests.",
	IDENTITY = "couldn't verify the Panda server identity, please try again later.",
	PROTOCOL = "Panda protocol error, please try again later.",
}

local Panda = {}
Panda.__index = Panda

function Panda.new(config)
	config = config or {}
	local self = setmetatable({}, Panda)

	local serviceId = config.ServiceId or config.Service or config.serviceId
	self.serviceId = serviceId ~= nil and tostring(serviceId) or ""
	self.debug = config.Debug == true

	self.lib = nil
	self.loading = false

	if self.serviceId == "" then
		warn("[Panda] ServiceId is missing — check your Panda dashboard")
	end

	return self
end

function Panda:_load()
	while self.loading do
		task.wait(0.1)
	end
	if self.lib then
		return self.lib
	end
	if self.serviceId == "" then
		return nil, REASONS.NO_SERVICE
	end

	self.loading = true
	local lib, err

	local okFetch, src = pcall(function()
		return game:HttpGet(LIB_URL)
	end)
	if not okFetch or type(src) ~= "string" or src == "" then
		err = "couldn't download the Panda library."
	elseif not loadstring then
		err = "loadstring is not available."
	else
		local fn, compileError = loadstring(src)
		if not fn then
			err = "couldn't load the Panda library: " .. tostring(compileError)
		else
			local okRun, result = pcall(fn)
			if okRun and type(result) == "table" and type(result.configure) == "function" then
				local okConfig, configError = pcall(result.configure, {
					serviceId = self.serviceId,
					debug = self.debug,
					kickOnDetect = false,
				})
				if okConfig then
					lib = result
				else
					err = "couldn't configure the Panda library: " .. tostring(configError)
				end
			else
				err = "Panda library failed to initialize."
			end
		end
	end

	self.loading = false
	if lib then
		self.lib = lib
		return lib
	end
	return nil, err
end

function Panda:CheckKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then
		return false, REASONS.NO_KEY
	end

	local lib, err = self:_load()
	if not lib then
		return false, err
	end

	if type(lib.validateEx) == "function" then
		local ok, valid, reason = pcall(lib.validateEx, key)
		if not ok then
			return false, tostring(valid)
		end
		if valid == true then
			return true
		end
		return false, REASONS[reason] or ("Panda error: " .. tostring(reason))
	end

	local ok, result = pcall(lib.validate, key)
	if not ok then
		return false, tostring(result)
	end
	if type(result) == "table" and result.success == true then
		return true
	end
	local reason = type(result) == "table" and (result.reason or result.error) or nil
	return false, REASONS[reason] or tostring(reason or "key is invalid.")
end

function Panda:GetKeyLink()
	local lib, err = self:_load()
	if not lib then
		return nil, err
	end
	if type(lib.getKeyUrl) ~= "function" then
		return nil, "Panda library has no getKeyUrl."
	end
	local ok, url = pcall(lib.getKeyUrl)
	if ok and type(url) == "string" and url ~= "" then
		return url
	end
	return nil, "Failed to get link."
end

return Panda
end

__modules["utilities/platoboost"] = function()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- SHA-256 (hex digest) from the official Platoboost library.
local sha256 = (function()
local a=2^32;local b=a-1;local function c(d,e)local f,g=0,1;while d~=0 or e~=0 do local h,i=d%2,e%2;local j=(h+i)%2;f=f+j*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return f%a end;local function k(d,e,l,...)local m;if e then d=d%a;e=e%a;m=c(d,e)if l then m=k(m,l,...)end;return m elseif d then return d%a else return 0 end end;local function n(d,e,l,...)local m;if e then d=d%a;e=e%a;m=(d+e-c(d,e))/2;if l then m=n(m,l,...)end;return m elseif d then return d%a else return b end end;local function o(p)return b-p end;local function q(d,r)if r<0 then return lshift(d,-r)end;return math.floor(d%2^32/2^r)end;local function s(p,r)if r>31 or r<-31 then return 0 end;return q(p%a,r)end;local function lshift(d,r)if r<0 then return s(d,-r)end;return d*2^r%2^32 end;local function t(p,r)p=p%a;r=r%32;local u=n(p,2^r-1)return s(p,r)+lshift(u,32-r)end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(x)return string.gsub(x,".",function(l)return string.format("%02x",string.byte(l))end)end;local function y(z,A)local x=""for B=1,A do local C=z%256;x=string.char(C)..x;z=(z-C)/256 end;return x end;local function D(x,B)local A=0;for B=B,B+3 do A=A*256+string.byte(x,B)end;return A end;local function E(F,G)local H=64-(G+9)%64;G=y(8*G,8)F=F.."\128"..string.rep("\0",H)..G;assert(#F%64==0)return F end;local function I(J)J[1]=0x6a09e667;J[2]=0xbb67ae85;J[3]=0x3c6ef372;J[4]=0xa54ff53a;J[5]=0x510e527f;J[6]=0x9b05688c;J[7]=0x1f83d9ab;J[8]=0x5be0cd19;return J end;local function K(F,B,J)local L={}for M=1,16 do L[M]=D(F,B+(M-1)*4)end;for M=17,64 do local N=L[M-15]local O=k(t(N,7),t(N,18),s(N,3))N=L[M-2]L[M]=(L[M-16]+O+L[M-7]+k(t(N,17),t(N,19),s(N,10)))%a end;local d,e,l,P,Q,R,S,T=J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8]for B=1,64 do local O=k(t(d,2),t(d,13),t(d,22))local U=k(n(d,e),n(d,l),n(e,l))local V=(O+U)%a;local W=k(t(Q,6),t(Q,11),t(Q,25))local X=k(n(Q,R),n(o(Q),S))local Y=(T+W+X+v[B]+L[B])%a;T=S;S=R;R=Q;Q=(P+Y)%a;P=l;l=e;e=d;d=(Y+V)%a end;J[1]=(J[1]+d)%a;J[2]=(J[2]+e)%a;J[3]=(J[3]+l)%a;J[4]=(J[4]+P)%a;J[5]=(J[5]+Q)%a;J[6]=(J[6]+R)%a;J[7]=(J[7]+S)%a;J[8]=(J[8]+T)%a end;local function Z(F)F=E(F,#F)local J=I({})for B=1,#F,64 do K(F,B,J)end;return w(y(J[1],4)..y(J[2],4)..y(J[3],4)..y(J[4],4)..y(J[5],4)..y(J[6],4)..y(J[7],4)..y(J[8],4))end;
	return Z
end)()

local Platoboost = {}
Platoboost.__index = Platoboost

-- Tried in this order; the first one that answers is used.
local HOSTS = { "https://api.platoboost.app", "https://api.platoboost.com", "https://api.platoboost.net" }
local LINK_CACHE_TIME = 10 * 60
local RATE_LIMIT_MESSAGE = "you are being rate limited, please wait 20 seconds and try again."
local BAD_STATUS_MESSAGE = "server returned an invalid status code, please try again later."
local JSON_HEADERS = { ["Content-Type"] = "application/json" }

local rng = Random.new()

local function getRequestFunction()
	return request or http_request or (syn and syn.request) or (http and http.request)
end

local function getHwid()
	if gethwid then
		local ok, hwid = pcall(gethwid)
		if ok and hwid ~= nil and tostring(hwid) ~= "" then
			return tostring(hwid)
		end
	end
	local lp = Players.LocalPlayer
	return tostring(lp and lp.UserId or 0)
end

local function generateNonce()
	local chars = table.create(16)
	for i = 1, 16 do
		chars[i] = string.char(rng:NextInteger(97, 122))
	end
	return table.concat(chars)
end

local function decode(body)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, body)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

function Platoboost.new(config)
	config = config or {}
	local self = setmetatable({}, Platoboost)
	self.__isPlatoboostInstance = true

	local service = config.ServiceId or config.Service or config.service
	self.service = tonumber(service) or service
	self.secret = config.Secret or config.secret

	local useNonce = config.UseNonce
	if useNonce == nil then
		useNonce = config.useNonce
	end
	self.useNonce = useNonce ~= false

	-- Optional: force one API host, e.g. Host = "https://api.platoboost.app"
	local host = config.Host or config.host
	if type(host) == "string" and host ~= "" then
		host = host:gsub("/+$", "")
		if not host:match("^https?://") then
			host = "https://" .. host
		end
		self.host = host
	end
	self.identifier = nil
	self.requestSending = false
	self.cachedLink = nil
	self.cachedTime = 0

	if self.service == nil or self.service == "" then
		warn("[Platoboost] ServiceId is missing — check your Platoboost dashboard")
	end
	if self.useNonce and (type(self.secret) ~= "string" or self.secret == "") then
		warn("[Platoboost] Secret is missing — keys can't be verified without it")
	end

	return self
end

-- Picks the first host that answers /public/connectivity (200 or 429).
-- If none answers, the first one in HOSTS is used.
function Platoboost:_host()
	if self.host then
		return self.host
	end
	local req = getRequestFunction()
	if req then
		for _, host in ipairs(HOSTS) do
			local ok, res = pcall(req, { Url = host .. "/public/connectivity", Method = "GET" })
			if ok and type(res) == "table" and (res.StatusCode == 200 or res.StatusCode == 429) then
				self.host = host
				return self.host
			end
		end
	end
	self.host = HOSTS[1]
	return self.host
end

function Platoboost:_identifier()
	if not self.identifier then
		self.identifier = sha256(getHwid())
	end
	return self.identifier
end

function Platoboost:_send(options)
	local req = getRequestFunction()
	if not req then
		return nil, "your executor doesn't support HTTP requests."
	end
	local ok, res = pcall(req, options)
	if not ok then
		return nil, tostring(res)
	end
	if type(res) ~= "table" then
		return nil, "invalid response from server."
	end
	return res
end

-- Returns link, or nil + reason
function Platoboost:GetKeyLink()
	if self.cachedLink and self.cachedTime + LINK_CACHE_TIME > os.time() then
		return self.cachedLink
	end
	if self.service == nil or self.service == "" then
		return nil, "Platoboost ServiceId is missing."
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/start",
		Method = "POST",
		Body = HttpService:JSONEncode({
			service = self.service,
			identifier = self:_identifier(),
		}),
		Headers = JSON_HEADERS,
	})
	if not res then
		return nil, err
	end

	if res.StatusCode == 200 then
		local decoded = decode(res.Body)
		if decoded then
			if decoded.success == true and type(decoded.data) == "table" and decoded.data.url then
				self.cachedLink = decoded.data.url
				self.cachedTime = os.time()
				return self.cachedLink
			end
			return nil, tostring(decoded.message or "Failed to get link.")
		end
	elseif res.StatusCode == 429 then
		return nil, RATE_LIMIT_MESSAGE
	end
	return nil, "Failed to get link."
end

-- With UseNonce the server signs its answer with the secret; check it.
function Platoboost:_integrityOk(data, nonce)
	if not self.useNonce then
		return true
	end
	return data.hash == sha256("true" .. "-" .. nonce .. "-" .. tostring(self.secret))
end

function Platoboost:_redeem(key)
	local nonce = generateNonce()
	local body = {
		identifier = self:_identifier(),
		key = key,
	}
	if self.useNonce then
		body.nonce = nonce
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/redeem/" .. tostring(self.service),
		Method = "POST",
		Body = HttpService:JSONEncode(body),
		Headers = JSON_HEADERS,
	})
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, RATE_LIMIT_MESSAGE
	end
	if res.StatusCode ~= 200 then
		return false, BAD_STATUS_MESSAGE
	end

	local decoded = decode(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		local message = tostring(decoded.message or "request failed.")
		if message:sub(1, 27) == "unique constraint violation" then
			return false, "you already have an active key, please wait for it to expire before redeeming it."
		end
		return false, message
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid ~= true then
		return false, "key is invalid."
	end
	if not self:_integrityOk(data, nonce) then
		return false, "failed to verify integrity."
	end
	return true
end

function Platoboost:_verify(key)
	local nonce = generateNonce()
	local url = self:_host()
		.. "/public/whitelist/"
		.. tostring(self.service)
		.. "?identifier="
		.. self:_identifier()
		.. "&key="
		.. HttpService:UrlEncode(key)
	if self.useNonce then
		url = url .. "&nonce=" .. nonce
	end

	local res, err = self:_send({ Url = url, Method = "GET" })
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, RATE_LIMIT_MESSAGE
	end
	if res.StatusCode ~= 200 then
		return false, BAD_STATUS_MESSAGE
	end

	local decoded = decode(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		return false, tostring(decoded.message or "request failed.")
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid == true then
		if not self:_integrityOk(data, nonce) then
			return false, "failed to verify integrity."
		end
		return true
	end

	-- Keys from the Platoboost site start with KEY_ and must be redeemed first
	if key:sub(1, 4) == "KEY_" then
		return self:_redeem(key)
	end
	return false, "key is invalid."
end

-- Returns valid (boolean), reason (string when invalid)
function Platoboost:CheckKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then
		return false, "key is empty."
	end
	if self.service == nil or self.service == "" then
		return false, "Platoboost ServiceId is missing."
	end
	if self.useNonce and (type(self.secret) ~= "string" or self.secret == "") then
		return false, "Platoboost Secret is missing."
	end
	if self.requestSending then
		return false, "a request is already being sent, please slow down."
	end

	self.requestSending = true
	local ok, valid, reason = pcall(self._verify, self, key)
	self.requestSending = false

	if not ok then
		return false, tostring(valid)
	end
	return valid == true, reason
end

function Platoboost:Validator()
	local instance = self
	return setmetatable({
		__isPlatoboost = true,
		__instance = instance,
	}, {
		__call = function(_, key)
			return instance:CheckKey(key)
		end,
	})
end

return Platoboost
end

__modules["variables"] = function()
return {
	-- Window Config
	Title = "Ophyn",
	Description = "Key System",
	Logo = "rbxassetid://111673746737789", -- rbxassetid
	Theme = "Plant-Dark",
	Folder = "Ophyn-KSY",

	-- Buttons Config
	getkey = true,

	-- Intro Config
	Intro = "true", -- "false": fade-in on open, fade-out on close
	startintro_size = 80, -- initial square size
	squareintro_time = 1.2,
	squarecontorn = "true", -- "false": removes the outline around the intro square

	-- Themes Config
	Changelogocolor = true,
	Changeiconscolor = true,
	ChangeTheme = "true", -- "false": disable moon icon to change Theme

	-- Section Config
	discord_link = "",
	website_link = "",

	-- Cards ("true" / "false")
	Discord = "true",
	Website = "false",
	Informations = "true",

	-- Keyless mode: no key needed. Status becomes "Keyless" and Submit runs the Callback directly.
	Keyless = {
		enabled = false, -- true: turns keyless mode on
		disabletextbox = true, -- dims the key box and blocks typing
		disablegetkey = true, -- dims "Get a key" and blocks clicks
		showcard = true, -- shows the "Keyless Mode" card
		autoconfirm = false, -- true: runs the Callback automatically when the UI opens
	},

	-- Notification style
	NotifStyle = "1",

	-- Tabs style: "1" = Tabs in a column on the left, "2" = Tabs in a row under the topbar
	TabsStyle = "1",

	-- Games
	SupportedGames = {},

	-- Script Execution
	Callback = function(key)
		-- your script here
	end,
}
end

local KeySystem = {}

function KeySystem.new(options)
	return import("components/window/ui").new(options)
end

-- Works as KeySystem:SetGetkeyTitle("...") or KeySystem.SetGetkeyTitle("...")
local function firstArg(a, b)
	if a == KeySystem then
		return b
	end
	return a
end

function KeySystem.SetGetkeyTitle(a, b)
	import("components/window/ui").SetGetkeyTitle(firstArg(a, b))
	return KeySystem
end

function KeySystem.SetGetkeyIcon(a, b)
	import("components/window/ui").SetGetkeyIcon(firstArg(a, b))
	return KeySystem
end

-- Works as KeySystem:SetNotifStyle("3") / KeySystem:NotifStyle("3")
function KeySystem.SetNotifStyle(a, b)
	import("components/window/ui").SetNotifStyle(firstArg(a, b))
	return KeySystem
end

KeySystem.NotifStyle = KeySystem.SetNotifStyle

-- Works as KeySystem:SetTabsStyle("2") / KeySystem.SetTabsStyle("2") ("1": Tabs on the left,
-- "2": Tabs in a row under the topbar), before or after KeySystem.new(...).
function KeySystem.SetTabsStyle(a, b)
	import("components/window/ui").SetTabsStyle(firstArg(a, b))
	return KeySystem
end

KeySystem.TabsStyle = KeySystem.SetTabsStyle

-- Works as KeySystem:GetMethod({...}) / KeySystem.GetMethod({...}), same as the
-- other Set* helpers above: usable standalone, before KeySystem.new(...) exists.
function KeySystem.GetMethod(a, b)
	return import("components/window/ui").GetMethod(firstArg(a, b))
end

-- Works as KeySystem:SetUIFont("...") / KeySystem.SetUIFont("...")
function KeySystem.SetUIFont(a, b)
	import("components/window/ui").SetUIFont(firstArg(a, b))
	return KeySystem
end

-- Works as KeySystem:SetTitleFont("...") / KeySystem.SetTitleFont("...")
function KeySystem.SetTitleFont(a, b)
	import("components/window/ui").SetTitleFont(firstArg(a, b))
	return KeySystem
end

KeySystem.Jnkie = import("utilities/jnkie")

__AirflowBundledKeySystem = KeySystem

 end


-- ===================================================================
-- MAIN UI KEY GATE
-- Enable with Key = true. Example:
-- Library:Window({ Key = true, KeyValue = "USER-KEY", Keys = {"ALT-KEY"},
--   AdminKey = "ADMIN-KEY", KeyURL = "https://your-key-link", KeyAPI = {...} })
-- KeyURL is only a link; generated keys require a verifier configured in KeyAPI.
-- Legacy KeySystem = {...} still works.
-- ===================================================================
local __AirflowWindowBeforeKeyGate = Library.Window
local __AirflowGatedWindows = {}
local __AirflowKeyGateStarted = false
local __AirflowKeyGateUnlocked = false
local __AirflowKeyGateRole = "User"

local function __AirflowKeyList(value)
	local out = {}
	if value == nil then return out end
	if type(value) == "table" then
		for _, item in ipairs(value) do
			if item ~= nil and tostring(item) ~= "" then out[#out + 1] = tostring(item) end
		end
	elseif tostring(value) ~= "" then
		out[1] = tostring(value)
	end
	return out
end

local function __AirflowContainsKey(list, key)
	for _, candidate in ipairs(__AirflowKeyList(list)) do
		if candidate == tostring(key or "") then return true end
	end
	return false
end

local function __AirflowShowWindow(win)
	if not win or win._destroyed or not win.Root or not win.Root.Parent then return end
	win.Gui.Enabled = true
	win.Open = true
	win.Root.Visible = true
	if win.Scale then win.Scale.Scale = win._fitScale or 1 end
	if win.Body then win.Body.GroupTransparency = 0 end
	if win.BodyStroke then win.BodyStroke.Transparency = 0 end
	if win.Shadow then win.Shadow.ImageTransparency = .6 end
end

-- Instant reveal (used by the plain key flow and as the safety net of the split transition).
-- Kept as a Library field so the file doesn't gain more top-level locals.
Library._GateReveal = function(announce)
	if Library._GateRevealed then return end
	Library._GateRevealed = true
	for _, entry in ipairs(__AirflowGatedWindows) do
		if entry.connection then pcall(function() entry.connection:Disconnect() end) end
		local win = entry.window
		if win and not win._destroyed then
			win.Gui.DisplayOrder = 999
			win.KeyRole = __AirflowKeyGateRole
			win.IsAdmin = __AirflowKeyGateRole == "Admin"
			__AirflowShowWindow(win)
			if announce then
				pcall(function()
					win:Notify({ Title = "Access granted", Content = __AirflowKeyGateRole == "Admin" and "Admin key accepted. Welcome." or "Key accepted. Welcome.", Type = "Success", Duration = 3 })
				end)
			end
		end
	end
end

local function __AirflowUnlockKeyGate(keyConfig, key, deferReveal)
	if __AirflowKeyGateUnlocked then return end
	__AirflowKeyGateUnlocked = true
	local adminKeys = type(keyConfig) == "table" and (keyConfig.AdminKeys or keyConfig.AdminKey) or nil
	__AirflowKeyGateRole = __AirflowContainsKey(adminKeys, key) and "Admin" or "User"
	Library.KeyRole = __AirflowKeyGateRole
	Library.IsAdmin = __AirflowKeyGateRole == "Admin"
	local callback = type(keyConfig) == "table" and keyConfig.Callback or nil
	if type(callback) == "function" then
		local ok, err = pcall(callback, key, __AirflowKeyGateRole)
		if not ok then warn("[Airflow] KeySystem callback failed: " .. tostring(err)) end
	end
	if deferReveal then
		-- the key UI reveals the window itself at the end of its liquid split; this is only a safety net
		task.delay(12, function() Library._GateReveal(true) end)
		return
	end
	task.delay(.9, function() Library._GateReveal(true) end)
end

-- Pieces the key UI uses to split into "the real notification" + "the real window".
Library._GateTransition = function(keySettings)
	local function gated()
		local e = __AirflowGatedWindows[1]
		local w = e and e.window
		if w and not w._destroyed and w.Root and w.Root.Parent and w.NotifyHolder then return w end
	end
	return {
		-- Builds the real Airflow notification, hidden and already at its resting position.
		Prepare = function(key)
			local win = gated()
			if not win then return nil end
			local admin = __AirflowContainsKey(keySettings.AdminKeys or keySettings.AdminKey, key)
			local ok, handle = pcall(function()
				return win:Notify({
					Title = "Access granted", Content = admin and "Admin key accepted. Welcome." or "Key accepted. Welcome.",
					Type = "Success", Duration = 3, _Handoff = true,
				})
			end)
			if ok and type(handle) == "table" and handle.Card and handle.Reveal then return handle end
			return nil
		end,
		-- Where the real window will be (screen pixels).
		Target = function()
			local win = gated()
			if not win then return nil end
			local g = win.Gui.AbsoluteSize
			if g.X < 2 or g.Y < 2 then
				local cam = workspace.CurrentCamera
				g = cam and cam.ViewportSize or Vector2.new(1280, 720)
			end
			local S, P = win.Root.Size, win.Root.Position
			local fit = win._fitScale or 1
			local size = Vector2.new(S.X.Scale * g.X + S.X.Offset, S.Y.Scale * g.Y + S.Y.Offset) * fit
			local center = Vector2.new(P.X.Scale * g.X + P.X.Offset, P.Y.Scale * g.Y + P.Y.Offset)
			local radius = win.BodyCorner and win.BodyCorner.CornerRadius.Offset or 10
			return { Center = center, Size = size, Radius = radius }
		end,
		-- Fades the real window in, growing out of the blob that is about to land on it.
		Reveal = function()
			if Library._GateRevealed then return end
			Library._GateRevealed = true
			for _, entry in ipairs(__AirflowGatedWindows) do
				if entry.connection then pcall(function() entry.connection:Disconnect() end) end
				local win = entry.window
				if win and not win._destroyed then
					win.KeyRole = __AirflowKeyGateRole
					win.IsAdmin = __AirflowKeyGateRole == "Admin"
					if win.Root and win.Root.Parent then
						local fit = win._fitScale or 1
						win.Gui.Enabled = true
						win.Open = true
						if win.Body then win.Body.GroupTransparency = 1 end
						if win.BodyStroke then win.BodyStroke.Transparency = 1 end
						if win.Shadow then win.Shadow.ImageTransparency = 1 end
						if win.Scale then win.Scale.Scale = fit * .975 end
						win.Root.Visible = true
						if win.Body then tween(win.Body, { GroupTransparency = 0 }, .3) end
						if win.BodyStroke then tween(win.BodyStroke, { Transparency = 0 }, .3) end
						if win.Shadow then tween(win.Shadow, { ImageTransparency = .6 }, .5) end
						if win.Scale then tween(win.Scale, { Scale = fit }, .8, LIQUID) end
					end
					-- the key UI is gone by then; go back to the normal display order
					task.delay(2.5, function() if not win._destroyed then win.Gui.DisplayOrder = 999 end end)
				end
			end
		end,
	}
end

Library.Window = function(self, cfg)
	cfg = cfg or {}
	local legacyKeyConfig = cfg.KeySystem
	local enabled
	if cfg.Key ~= nil then
		enabled = cfg.Key == true
	elseif legacyKeyConfig ~= nil then
		enabled = legacyKeyConfig ~= false and not (type(legacyKeyConfig) == "table" and legacyKeyConfig.Enabled == false)
	else
		enabled = false
	end
	local keyConfig = legacyKeyConfig
	local baseCfg = cfg
	if enabled and not __AirflowKeyGateUnlocked then
		baseCfg = table.clone(cfg)
		baseCfg.Loading = false
	end
	local win = __AirflowWindowBeforeKeyGate(self, baseCfg)
	if not enabled or __AirflowKeyGateUnlocked then return win end

	local entry = { window = win, connection = nil }
	table.insert(__AirflowGatedWindows, entry)
	win.Gui.Enabled = false
	win.Gui.DisplayOrder = 1000
	entry.connection = RunService.RenderStepped:Connect(function()
		if __AirflowKeyGateUnlocked or win._destroyed then
			if entry.connection then entry.connection:Disconnect() entry.connection = nil end
			return
		end
		if win.Root and win.Root.Parent then
			win.Root.Visible = false
			win.Open = false
		end
	end)
	task.spawn(function()
		while not __AirflowKeyGateUnlocked and not win._destroyed and not win._introDone do task.wait(0.05) end
		if __AirflowKeyGateUnlocked or win._destroyed then return end
		task.wait(1.2) -- allow the hidden intro glow to finish before enabling the GUI notification layer
		if __AirflowKeyGateUnlocked or win._destroyed then return end
		if win.Root and win.Root.Parent then win.Root.Visible = false end
		win.Open = false
		win.Gui.DisplayOrder = 1000
		win.Gui.Enabled = true
	end)

	if not __AirflowKeyGateStarted then
		__AirflowKeyGateStarted = true
		local keySettings = {}
		if type(keyConfig) == "table" then
			for k, v in pairs(keyConfig) do keySettings[k] = v end
		end

		-- Simple public configuration. Key=true only enables the gate; the actual keys
		-- are supplied separately so users don't have to build a nested KeySystem table.
		local normalKeys = __AirflowKeyList(cfg.KeyValue)
		for _, value in ipairs(__AirflowKeyList(cfg.Keys)) do table.insert(normalKeys, value) end
		local adminKeys = __AirflowKeyList(cfg.AdminKey)
		for _, value in ipairs(__AirflowKeyList(cfg.AdminKeys)) do table.insert(adminKeys, value) end
		if #normalKeys > 0 then
			local merged = __AirflowKeyList(keySettings.Key)
			for _, value in ipairs(normalKeys) do table.insert(merged, value) end
			keySettings.Key = merged
		end
		if #adminKeys > 0 then
			local merged = __AirflowKeyList(keySettings.Key)
			for _, value in ipairs(adminKeys) do table.insert(merged, value) end
			keySettings.Key = merged
			keySettings.AdminKeys = adminKeys
		end
		if cfg.KeyURL ~= nil then keySettings.URL = cfg.KeyURL end
		if cfg.KeyLink ~= nil then keySettings.URL = cfg.KeyLink end
		if cfg.KeyAPI ~= nil then keySettings.API = cfg.KeyAPI end
		if cfg.KeySave ~= nil then keySettings.SaveKey = cfg.KeySave end
		if cfg.KeyTheme ~= nil then keySettings.Theme = cfg.KeyTheme end
		if cfg.KeyTitle ~= nil then keySettings.Title = cfg.KeyTitle end
		if cfg.KeyDescription ~= nil then keySettings.Description = cfg.KeyDescription end
		-- Do not silently fall back to the public key "key" when the new simple
		-- Key=true mode is enabled but no validator is configured. Fail closed instead.
		keySettings.RequireConfiguredKey = cfg.Key == true
		if keySettings.Key == nil and type(keySettings.API) ~= "table" then
			if cfg.Key == true then
				keySettings.Key = {}
				keySettings.Description = keySettings.Description or "Configure KeyValue, Keys, or KeyAPI in Library.Window"
			else
				keySettings.Key = { "key" }
			end
		end
		keySettings.Enabled = nil
		local keyUiOptions = {}
		for k, v in pairs(keySettings) do keyUiOptions[k] = v end
		keyUiOptions.KeySystem = keySettings
		keyUiOptions.Theme = keySettings.Theme or "Amethyst"
		keyUiOptions.Title = keySettings.Title or cfg.Title or cfg.Name or "Airflow"
		keyUiOptions.Description = keySettings.Description or "Enter your key to continue"
		keyUiOptions.Folder = keySettings.Folder or "Airflow-KeySystem"
		keyUiOptions.MainNotify = function(title, message, kind, iconKey, duration)
			local typeMap = { success = "Success", warn = "Warning", warning = "Warning", error = "Error", info = "Info" }
			local iconMap = { key = "key-round", submit = "check", link = "link", discord = "message-circle", close = "x", moon = "moon" }
			local target = __AirflowGatedWindows[1] and __AirflowGatedWindows[1].window
			if not target or target._destroyed then return nil end
			return target:Notify({
				Title = tostring(title or "Notification"), Content = tostring(message or ""),
				Type = typeMap[tostring(kind or "info"):lower()] or "Info",
				Icon = iconMap[tostring(iconKey or "key"):lower()] or "key-round",
				Duration = tonumber(duration) or 4,
			})
		end
		keyUiOptions.Callback = function(key)
			__AirflowUnlockKeyGate(keySettings, key)
		end
		-- Start unlocking as the success morph begins, not after the key UI disappears.
		-- The key UI's notification branch remains visible while the second liquid branch
		-- expands toward the main window; the normal Airflow success toast appears too.
		keyUiOptions.MainTransition = Library._GateTransition(keySettings)
		keyUiOptions.OnAcceptedStart = function(key, deferReveal)
			__AirflowUnlockKeyGate(keySettings, key, deferReveal == true)
		end
		task.spawn(function()
			local firstWindow = __AirflowGatedWindows[1] and __AirflowGatedWindows[1].window
			while firstWindow and not __AirflowKeyGateUnlocked and not firstWindow._destroyed and not firstWindow._introDone do task.wait(0.05) end
			if __AirflowKeyGateUnlocked or not firstWindow or firstWindow._destroyed then return end
			task.wait(1.2)
			if __AirflowKeyGateUnlocked or firstWindow._destroyed then return end
			for _, item in ipairs(__AirflowGatedWindows) do
				local target = item.window
				if target and not target._destroyed then
					if target.Root and target.Root.Parent then target.Root.Visible = false end
					target.Open = false
					target.Gui.DisplayOrder = 1000
					target.Gui.Enabled = true
				end
			end
			local ok, keyGui = pcall(function()
				return __AirflowBundledKeySystem.new(keyUiOptions)
			end)
			if not ok then
				warn("[Airflow] Could not start KeySystem: " .. tostring(keyGui))
				__AirflowKeyGateUnlocked = true
				for _, item in ipairs(__AirflowGatedWindows) do
					if item.connection then pcall(function() item.connection:Disconnect() end) end
					__AirflowShowWindow(item.window)
				end
			else
				Library.KeySystemGui = keyGui.Gui
			end
		end)
	end
	return win
end
Library.CreateWindow = Library.Window

return Library
