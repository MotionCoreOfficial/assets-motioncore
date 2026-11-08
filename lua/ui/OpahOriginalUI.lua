local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Flags = {},
	Items = {},
	Version = "2.6.0",
	_nid = 0,
	_premiumFlags = {},
}


local Theme = {
	Glass = Color3.fromRGB(26, 28, 44),
	GlassAlpha = 0.28,
	GlassTop = Color3.fromRGB(86, 94, 142),
	GlassBottom = Color3.fromRGB(24, 27, 48),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceAlpha = 0.92,
	Element = Color3.fromRGB(255, 255, 255),
	ElementAlpha = 0.88,
	ElementHoverAlpha = 0.8,
	Inset = Color3.fromRGB(0, 0, 0),
	Track = Color3.fromRGB(100, 102, 124),
	Stroke = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(10, 132, 255),
	Accent2 = Color3.fromRGB(100, 210, 255),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(226, 228, 242),
	Success = Color3.fromRGB(48, 209, 88),
	Warning = Color3.fromRGB(255, 214, 10),
	Danger = Color3.fromRGB(255, 69, 58),
}
Library.Theme = Theme


local function resolveFamily(kind)
	local enumFont = kind == "Sans" and Enum.Font.BuilderSans or Enum.Font.RobotoMono
	local ok, fam = pcall(function()
		return Font.fromEnum(enumFont).Family
	end)
	return ok and fam or "rbxasset://fonts/families/GothamSSm.json"
end
local FamilyAsset = resolveFamily("Mono")
local WEIGHT = {
	Regular = Enum.FontWeight.Medium,
	Medium = Enum.FontWeight.SemiBold,
	SemiBold = Enum.FontWeight.Bold,
	Bold = Enum.FontWeight.Bold,
	Heavy = Enum.FontWeight.Heavy,
}

----------------------------------------------------------------------
-- ANIMATION PRESETS
----------------------------------------------------------------------
local EASE = {
	Instant = TweenInfo.new(0),
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Spring = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local function tween(obj, props, info)
	local t = TweenService:Create(obj, info or EASE.Smooth, props)
	t:Play()
	return t
end

local accentRegs, accentHooks = {}, {}
local function pruneAccent()
	for i = #accentRegs, 1, -1 do
		if not accentRegs[i][1].Parent then
			table.remove(accentRegs, i)
		end
	end
end
local function accented(inst, prop)
	table.insert(accentRegs, { inst, prop })
	return inst
end
local function bindAccent(fn)
	table.insert(accentHooks, fn)
	return fn
end
local function accentIcon(inst)
	if inst then
		accented(inst, inst:IsA("ImageLabel") and "ImageColor3" or "TextColor3")
	end
	return inst
end


local function create(class, props, children)
	local inst = Instance.new(class)

	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("GuiButton") then
		inst.AutoButtonColor = false
	end
	local isText = inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")
	if isText then
		inst.FontFace = Font.new(FamilyAsset, WEIGHT.Medium)
		inst.TextColor3 = Theme.Text
		inst.TextSize = 13
		inst.TextStrokeColor3 = Color3.new(0, 0, 0)
		inst.TextStrokeTransparency = 0.62
	end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") then
		inst.Text = ""
		inst.BackgroundTransparency = 1
	end
	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		inst.BackgroundTransparency = 1
	end

	for k, v in pairs(props or {}) do
		if k == "Weight" then
			inst.FontFace = Font.new(FamilyAsset, WEIGHT[v] or WEIGHT.Medium)
		elseif k == "Accent" then
			table.insert(accentRegs, { inst, v })
		elseif k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, l, t, r, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = parent,
	})
end

local function listLayout(parent, gap, horizontal)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

local function safe(fn, ...)
	if typeof(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[NebulaUI] Callback error: " .. tostring(err))
	end
end

local function round(n, inc)
	inc = (inc and inc > 0) and inc or 1
	local r = math.floor(n / inc + 0.5) * inc
	return tonumber(string.format("%.6g", r))
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function mountGui(gui)
	local ok = pcall(function()
		local host = (typeof(gethui) == "function" and gethui()) or CoreGui
		local old = host:FindFirstChild(gui.Name)
		if old then
			old:Destroy()
		end
		gui.Parent = host
	end)
	if not ok or not gui.Parent then
		local pg = LocalPlayer:WaitForChild("PlayerGui")
		local old = pg:FindFirstChild(gui.Name)
		if old then
			old:Destroy()
		end
		gui.Parent = pg
	end
end

local rippleLayers = setmetatable({}, { __mode = "k" })

local function ripple(frame, _input)

	local flash = rippleLayers[frame]
	if not flash then
		return
	end
	flash.BackgroundTransparency = 0.72
	tween(flash, { BackgroundTransparency = 1 }, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
end


local Icons = {}
local iconSources = {
	lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
	craft = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
	geist = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
	solar = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
}

local function loadIconPack(libName)
	if Icons[libName] ~= nil then
		return Icons[libName]
	end
	local ok, result = pcall(function()
		return loadstring(game:HttpGetAsync(iconSources[libName]))()
	end)
	Icons[libName] = (ok and type(result) == "table") and result or {}
	return Icons[libName]
end

local function resolveIcon(str)
	if not str or str == "" then
		return ""
	end
	str = tostring(str)
	if string.find(str, "^rbxasset") then
		return str
	end
	if tonumber(str) then
		return "rbxassetid://" .. str
	end
	if not string.find(str, ":", 1, true) then
		str = "lucide:" .. str
	end
	local lib, name = str:match("^([^:]+):(.+)$")
	if lib and name and iconSources[lib] then
		return loadIconPack(lib)[name] or ""
	end
	return ""
end

Library.Icons = Icons
Library.ResolveIcon = resolveIcon

-- Gambar custom (assetid / rbxasset) = berwarna penuh, jangan di-tint gelap.
-- Ikon library (lucide dll) = satu warna, boleh di-tint sesuai kontras.
local function isCustomImage(str)
	if str == nil or str == "" then
		return false
	end
	local raw = tostring(str)
	return tonumber(raw) ~= nil or string.find(raw, "^rbxasset") ~= nil
end

local function makeIcon(parent, str, size, color, fallback, props)
	local asset = resolveIcon(str)
	local inst
	if asset ~= "" then
		inst = create("ImageLabel", {
			Size = UDim2.fromOffset(size, size),
			Image = asset,
			ImageColor3 = color or Theme.Text,
			Parent = parent,
		})
	elseif fallback then
		inst = create("TextLabel", {
			Size = UDim2.fromOffset(size, size),
			Text = fallback,
			TextSize = math.floor(size * 0.9),
			Weight = "Bold",
			TextColor3 = color or Theme.Text,
			Parent = parent,
		})
	end
	if inst and props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	return inst
end

local function setIconColor(inst, color, info)
	if not inst then
		return
	end
	local prop = inst:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
	tween(inst, { [prop] = color }, info or EASE.Smooth)
end

function Library:SetAccent(c1, c2, instant)
	if typeof(c1) ~= "Color3" then
		return
	end
	if typeof(c2) ~= "Color3" then
		local h, s, v = c1:ToHSV()
		c2 = Color3.fromHSV((h + 0.07) % 1, math.clamp(s * 0.65, 0, 1), math.clamp(v + 0.15, 0, 1))
	end
	Theme.Accent, Theme.Accent2 = c1, c2
	pruneAccent()
	for _, r in ipairs(accentRegs) do
		local inst, prop = r[1], r[2]
		if inst.Parent then
			if instant then
				inst[prop] = c1
			else
				tween(inst, { [prop] = c1 }, EASE.Smooth)
			end
		end
	end
	for _, fn in ipairs(accentHooks) do
		safe(fn, c1, c2)
	end
end

local function luma(c)
	return c.R * 0.299 + c.G * 0.587 + c.B * 0.114
end

local function imageAsset(str)
	if str == nil or str == "" then
		return ""
	end
	if tonumber(str) then
		return "rbxassetid://" .. tostring(str)
	end
	local a = resolveIcon(str)
	if a ~= "" then
		return a
	end
	return tostring(str)
end

local NAMED_COLORS = {
	Red = Color3.fromRGB(255, 69, 58),
	Orange = Color3.fromRGB(255, 159, 10),
	Yellow = Color3.fromRGB(255, 214, 10),
	Green = Color3.fromRGB(48, 209, 88),
	Teal = Color3.fromRGB(64, 200, 224),
	Blue = Color3.fromRGB(10, 132, 255),
	Purple = Color3.fromRGB(191, 90, 242),
	Pink = Color3.fromRGB(255, 55, 95),
	Grey = Color3.fromRGB(142, 142, 147),
	White = Color3.fromRGB(235, 235, 245),
}
local function namedColor(c)
	if typeof(c) == "Color3" then
		return c
	end
	if type(c) == "string" and c ~= "" then
		return NAMED_COLORS[c:sub(1, 1):upper() .. c:sub(2):lower()]
	end
	return nil
end


local function encode(v)
	local t = typeof(v)
	if t == "Color3" then
		return { __t = "Color3", r = v.R, g = v.G, b = v.B }
	elseif t == "EnumItem" then
		return { __t = "Key", name = v.Name }
	end
	return v
end

local function decode(v)
	if type(v) == "table" and v.__t == "Color3" then
		return Color3.new(v.r, v.g, v.b)
	elseif type(v) == "table" and v.__t == "Key" then
		return Enum.KeyCode[v.name]
	end
	return v
end

local CONFIG_DIR = "NebulaUI"

local function configRoot()
	return Library.Folder or CONFIG_DIR
end

local function ensureFolder(path)
	return (pcall(function()
		if typeof(makefolder) ~= "function" then
			error("makefolder tidak tersedia")
		end
		local acc = ""
		for part in string.gmatch(path, "[^/\\]+") do
			acc = (acc == "") and part or (acc .. "/" .. part)
			if typeof(isfolder) ~= "function" or not isfolder(acc) then
				makefolder(acc)
			end
		end
	end))
end

function Library:SetFolder(name)
	if type(name) == "string" and name ~= "" then
		Library.Folder = name
		ensureFolder(name)
		ensureFolder(name .. "/configs")
	end
	return Library.Folder
end

local function configPath(name)
	return configRoot() .. "/configs/" .. name .. ".json"
end

function Library:SaveConfig(name)
	name = name or "default"
	local ok, err = pcall(function()
		local data = {}
		for flag, value in pairs(self.Flags) do
			data[flag] = encode(value)
		end
		ensureFolder(configRoot() .. "/configs")
		writefile(configPath(name), HttpService:JSONEncode(data))
	end)
	if not ok then
		warn("[NebulaUI] SaveConfig gagal: " .. tostring(err))
	end
	return ok
end

function Library:LoadConfig(name)
	name = name or "default"
	local ok, err = pcall(function()
		local path = configPath(name)
		if not isfile(path) then
			error("file tidak ditemukan")
		end
		local data = HttpService:JSONDecode(readfile(path))
		for flag, value in pairs(data) do
			local item = self.Items[flag]
			-- cegah bypass: config tidak boleh mengaktifkan fitur premium untuk user non-premium
			if Library._premiumFlags[flag] and not Library:IsPremium() then
				item = nil
			end
			if item and item.Set then
				local okItem, errItem = pcall(function()
					item:Set(decode(value))
				end)
				if not okItem then
					warn("[NebulaUI] Flag '" .. tostring(flag) .. "' dilewati: " .. tostring(errItem))
				end
			end
		end
	end)
	if not ok then
		warn("[NebulaUI] LoadConfig gagal: " .. tostring(err))
	end
	return ok
end

function Library:ListConfigs()
	local list = {}
	pcall(function()
		for _, f in ipairs(listfiles(configRoot() .. "/configs")) do
			local n = string.match(f, "([^/\\]+)%.json$")
			if n then
				table.insert(list, n)
			end
		end
	end)
	return list
end

function Library:DeleteConfig(name)
	return (pcall(function()
		delfile(configPath(name))
	end))
end


local function getNotifHolder()
	if Library._notifHolder and Library._notifHolder.Parent then
		return Library._notifHolder
	end
	local gui = create("ScreenGui", {
		Name = "NebulaUI_Notifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
	})
	mountGui(gui)
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 330, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = holder,
	})
	Library._notifHolder = holder
	return holder
end

function Library:Notify(cfg)
	task.spawn(function()
		Library:_notify(cfg)
	end)
end

function Library:_notify(cfg)
	cfg = cfg or {}
	local holder = getNotifHolder()
	local kinds = {
		Info = { Theme.Accent, "lucide:info", "i" },
		Success = { Theme.Success, "lucide:circle-check", "ok" },
		Warning = { Theme.Warning, "lucide:triangle-alert", "!" },
		Error = { Theme.Danger, "lucide:circle-x", "x" },
	}
	local kind = kinds[cfg.Type or "Info"] or kinds.Info
	local accent = kind[1]
	local duration = cfg.Duration or 4

	Library._nid += 1
	local Wrap = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = Library._nid,
		Parent = holder,
	})
	local Card = create("Frame", {
		Position = UDim2.new(1.3, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.05,
		Parent = Wrap,
	})
	corner(Card, 18)
	create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Color3.fromRGB(78, 86, 130), Color3.fromRGB(30, 33, 54)),
		Parent = Card,
	})
	create("UISizeConstraint", { MinSize = Vector2.new(0, 64), Parent = Card })
	local rim = stroke(Card, Color3.new(1, 1, 1), 1.2, 0)
	create("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.9),
			NumberSequenceKeypoint.new(1, 0.62),
		}),
		Parent = rim,
	})

	local Chip = create("Frame", {
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.78,
		Parent = Card,
	})
	corner(Chip, 11)
	makeIcon(Chip, kind[2], 20, accent, kind[3], {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(40, 14),
		Text = cfg.Time or "now",
		TextSize = 11,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Card,
	})

	local Inner = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Card,
	})
	padding(Inner, 62, 14, 58, 20)
	listLayout(Inner, 2)
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = cfg.Title or "Notification",
		TextSize = 13,
		Weight = "Bold",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 1,
		Parent = Inner,
	})
	if cfg.Content and cfg.Content ~= "" then
		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = cfg.Content,
			TextSize = 12,
			Weight = "Regular",
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent = Inner,
		})
	end

	local closed = false

	task.spawn(function()
		task.wait(0.05)
		local tries = 0
		while Card.AbsoluteSize.Y < 10 and tries < 20 do
			task.wait(0.05)
			tries += 1
		end
		local h = Card.AbsoluteSize.Y
		Card.AutomaticSize = Enum.AutomaticSize.None
		Card.Size = UDim2.new(1, 0, 0, h)
		local Bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -8),
			Size = UDim2.new(1, -32, 0, 3),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.25,
			Parent = Card,
		})
		corner(Bar, 999)
		local Click = create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = Card })
		Click.MouseButton1Click:Connect(function()
			closed = true
		end)
		tween(Wrap, { Size = UDim2.new(1, 0, 0, h + 10) }, EASE.Smooth)
		task.wait(0.1)
		tween(Card, { Position = UDim2.new(0, 0, 0, 0) }, EASE.Spring)
		tween(Bar, { Size = UDim2.new(0, 0, 0, 3) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))
		local t0 = os.clock()
		while not closed and os.clock() - t0 < duration do
			task.wait(0.05)
		end
		tween(Card, { Position = UDim2.new(1.3, 0, 0, 0) },
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)).Completed:Wait()
		tween(Wrap, { Size = UDim2.new(1, 0, 0, 0) }, EASE.Smooth).Completed:Wait()
		Wrap:Destroy()
	end)
end


----------------------------------------------------------------------
-- PREMIUM + KEY VALIDATION (core)
----------------------------------------------------------------------
local premiumState = false
local premiumRegs, premiumHooks = {}, {}
local premiumPrompt = nil

function Library:IsPremium()
	return premiumState
end

function Library:SetPremium(state, silent)
	state = state == true
	if state == premiumState then
		return
	end
	premiumState = state
	for i = #premiumRegs, 1, -1 do
		local r = premiumRegs[i]
		if r.inst.Parent then
			r.apply(state)
		else
			table.remove(premiumRegs, i)
		end
	end
	for _, fn in ipairs(premiumHooks) do
		safe(fn, state)
	end
	if state and not silent then
		Library:Notify({
			Title = "Premium aktif",
			Content = "Semua fitur premium sudah terbuka.",
			Type = "Success",
		})
	end
end

function Library:OnPremiumChanged(fn)
	table.insert(premiumHooks, fn)
	return fn
end

-- ganti perilaku saat fitur premium diklik oleh user non-premium
function Library:SetPremiumPrompt(fn)
	premiumPrompt = type(fn) == "function" and fn or nil
end

function Library:_premiumDenied(name)
	if premiumPrompt then
		safe(premiumPrompt, name)
		return
	end
	Library:Notify({
		Title = "Fitur Premium",
		Content = (name and ('"' .. tostring(name) .. '" ') or "Fitur ini ") .. "hanya untuk pengguna premium.",
		Type = "Warning",
	})
end

-- gating dari sisi script: if not Library:CheckPremium("Auto Win") then return end
function Library:CheckPremium(feature)
	if premiumState then
		return true
	end
	Library:_premiumDenied(feature)
	return false
end

function Library:PremiumOnly(fn, feature)
	return function(...)
		if Library:CheckPremium(feature) then
			return fn(...)
		end
	end
end

local function trimKey(s)
	s = tostring(s or "")
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	return s
end

local function toList(v)
	if type(v) == "string" then
		return { v }
	elseif type(v) == "table" then
		return v
	end
	return {}
end

-- return "premium" | "free" | nil
local function checkKey(cfg, key)
	key = trimKey(key)
	if key == "" then
		return nil
	end
	if type(cfg.Validate) == "function" then
		local ok, res = pcall(cfg.Validate, key)
		if ok then
			if res == "premium" then
				return "premium"
			end
			if res == true or res == "free" then
				return "free"
			end
		end
	end
	for _, k in ipairs(toList(cfg.PremiumKeys)) do
		if key == k then
			return "premium"
		end
	end
	for _, k in ipairs(toList(cfg.Keys)) do
		if key == k then
			return "free"
		end
	end
	return nil
end

local function keyPath(name)
	return configRoot() .. "/" .. tostring(name) .. ".key"
end

local function readKey(name)
	local ok, res = pcall(function()
		local p = keyPath(name)
		if isfile(p) then
			return readfile(p)
		end
	end)
	if ok and type(res) == "string" then
		return trimKey(res)
	end
	return nil
end

local function writeKey(name, value)
	pcall(function()
		ensureFolder(configRoot())
		writefile(keyPath(name), value)
	end)
end

local function deleteKey(name)
	pcall(function()
		delfile(keyPath(name))
	end)
end

function Library:ClearSavedKey(name)
	deleteKey(name or "key")
end

-- Aktifkan premium langsung dari sebuah key (tanpa UI key system)
-- cfg: PremiumKeys / Keys (list), Validate(key)->true, Save (default true), FileName, Silent
function Library:ActivatePremium(key, cfg)
	cfg = cfg or {}
	local validate
	if type(cfg.Validate) == "function" then
		validate = function(k)
			local r = cfg.Validate(k)
			if r == true or r == "premium" then
				return "premium"
			end
			return false
		end
	end
	local tier = checkKey({
		PremiumKeys = cfg.PremiumKeys or cfg.Keys,
		Validate = validate,
	}, key)
	if tier == "premium" then
		if cfg.Save ~= false then
			writeKey(cfg.FileName or "premium", trimKey(key))
		end
		Library:SetPremium(true, cfg.Silent)
		return true
	end
	return false
end

-- Pulihkan premium dari key yang pernah tersimpan
function Library:RestorePremium(cfg)
	cfg = cfg or {}
	local saved = readKey(cfg.FileName or "premium")
	if saved and saved ~= "" then
		return Library:ActivatePremium(saved, {
			PremiumKeys = cfg.PremiumKeys or cfg.Keys,
			Validate = cfg.Validate,
			Save = false,
			Silent = true,
		})
	end
	return false
end

local Elements = {}
Elements.__index = Elements

function Elements:_next()
	self._order = (self._order or 0) + 1
	return self._order
end


local stackOf = setmetatable({}, { __mode = "k" })


local function bindHeight(frame, source)
	local function update()
		frame.Size = UDim2.new(1, 0, 0, source.AbsoluteSize.Y)
	end
	source:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

local function makeCard(self, cfg, tint)
	local baseT = tint and 0.8 or Theme.ElementAlpha
	local hoverT = tint and 0.7 or Theme.ElementHoverAlpha
	local F = create("Frame", {
		Name = cfg.Name or "Element",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = tint or Theme.Element,
		BackgroundTransparency = baseT,
		ClipsDescendants = true,
		LayoutOrder = self:_next(),
		Parent = self._parent,
	})
	corner(F, 14)
	local st = stroke(F, tint or Theme.Stroke, 1, tint and 0.55 or 0.88)
	local Stack = create("Frame", {
		Name = "Stack",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = F,
	})
	listLayout(Stack, 0)
	stackOf[F] = Stack

	local Flash = create("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Accent,
		Accent = "BackgroundColor3",
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = F,
	})
	corner(Flash, 14)
	rippleLayers[F] = Flash
	bindHeight(F, Stack)

	local Lock = create("TextButton", {
		Name = "Lock",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		ZIndex = 20,
		Parent = F,
	})
	corner(Lock, 14)
	makeIcon(Lock, "lucide:lock", 16, Theme.SubText, "L", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		ZIndex = 21,
	})

	local function setLocked(a, b)
		local state = a
		if type(a) == "table" then
			state = b
		end
		Lock.Visible = state == true
	end
	setLocked(cfg.Locked)

	-- Premium = true di config elemen apa pun: terkunci sampai Library:SetPremium(true)
	if cfg.Premium then
		if cfg.Flag then
			Library._premiumFlags[cfg.Flag] = true
		end
		local Gate = create("TextButton", {
			Name = "PremiumGate",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			ZIndex = 22,
			Parent = F,
		})
		corner(Gate, 14)
		local dark = Color3.fromRGB(20, 22, 32)
		local Pill = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Warning,
			ZIndex = 23,
			Parent = Gate,
		})
		corner(Pill, 8)
		padding(Pill, 8, 0, 10, 0)
		local pl = listLayout(Pill, 5, true)
		pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		makeIcon(Pill, "lucide:crown", 14, dark, nil, { LayoutOrder = 1, ZIndex = 24 })
		create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "PREMIUM",
			TextSize = 10,
			Weight = "Bold",
			TextColor3 = dark,
			TextStrokeTransparency = 1,
			LayoutOrder = 2,
			ZIndex = 24,
			Parent = Pill,
		})
		Gate.MouseButton1Click:Connect(function()
			Library:_premiumDenied(cfg.Name)
		end)
		table.insert(premiumRegs, {
			inst = F,
			apply = function(state)
				Gate.Visible = not state
			end,
		})
		Gate.Visible = not premiumState
	end

	F.MouseEnter:Connect(function()
		tween(F, { BackgroundTransparency = hoverT }, EASE.Fast)
		tween(st, { Transparency = tint and 0.35 or 0.7 }, EASE.Fast)
	end)
	F.MouseLeave:Connect(function()
		tween(F, { BackgroundTransparency = baseT }, EASE.Fast)
		tween(st, { Transparency = tint and 0.55 or 0.88 }, EASE.Fast)
	end)

	return F, Stack, st, setLocked
end

local function baseElement(self, cfg, rightWidth, minH)
	cfg.Name = cfg.Name or cfg.Title
	cfg.Description = cfg.Description or cfg.Desc
	if self._tab then
		table.insert(self._tab._titles, string.lower(tostring(cfg.Name or "")))
		if cfg.Description then
			table.insert(self._tab._titles, string.lower(tostring(cfg.Description)))
		end
	end

	local F, Stack, st, setLocked = makeCard(self, cfg, cfg.CardColor)

	local Top = create("Frame", {
		Name = "Top",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = Stack,
	})
	create("UISizeConstraint", { MinSize = Vector2.new(0, minH or 52), Parent = Top })

	local Text = create("Frame", {
		Name = "Text",
		Size = UDim2.new(1, -(rightWidth or 0), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Top,
	})
	padding(Text, 14, 12, 8, 12)
	local tl = listLayout(Text, 4)
	tl.VerticalAlignment = Enum.VerticalAlignment.Center
	create("UISizeConstraint", { MinSize = Vector2.new(0, minH or 52), Parent = Text })

	local Title = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = cfg.Name or "Element",
		TextSize = 13,
		Weight = "Bold",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		Parent = Text,
	})
	if cfg.Description then
		create("TextLabel", {
			Name = "Desc",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = cfg.Description,
			TextSize = 12,
			Weight = "Regular",
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
			Parent = Text,
		})
	end

	return F, Top, st, Title, setLocked
end

local function makeExtra(F, height)
	return create("Frame", {
		Name = "Extra",
		Size = UDim2.new(1, 0, 0, height or 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = stackOf[F],
	})
end

local function leadIcon(Top, icon, color, side, symmetric)
	if not icon then
		return nil
	end
	side = side or "Left"
	local ic = makeIcon(Top, icon, 18, color or Theme.SubText, nil, {
		AnchorPoint = Vector2.new(side == "Right" and 1 or 0, 0.5),
		Position = UDim2.new(side == "Right" and 1 or 0, side == "Right" and -14 or 14, 0.5, 0),
	})
	if ic then
		local Text = Top:FindFirstChild("Text")
		local pad = Text and Text:FindFirstChildOfClass("UIPadding")
		if pad then
			if side == "Left" or symmetric then
				pad.PaddingLeft = UDim.new(0, 44)
			end
			if symmetric then
				pad.PaddingRight = UDim.new(0, 44)
			end
		end
	end
	return ic
end

local function register(flag, obj, value)
	if flag then
		Library.Flags[flag] = value
		Library.Items[flag] = obj
	end
end

local function dragInput(window, frame, onMove, onState)
	local active = false
	local sf = frame:FindFirstAncestorOfClass("ScrollingFrame")
	frame.InputBegan:Connect(function(input)
		if isPointer(input) then
			active = true
			if sf then
				sf.ScrollingEnabled = false
			end
			if onState then
				onState(true)
			end
			onMove(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	window:_track(UserInputService.InputChanged:Connect(function(input)
		if active and isMove(input) then
			onMove(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))
	window:_track(UserInputService.InputEnded:Connect(function(input)
		if active and isPointer(input) then
			active = false
			if sf then
				sf.ScrollingEnabled = true
			end
			if onState then
				onState(false)
			end
		end
	end))
end


function Elements:CreateSection(arg)
	local cfg = type(arg) == "table" and arg or { Name = arg }
	local collapsible = cfg.Collapsible ~= false
	local open = cfg.Open ~= false

	local Card = create("Frame", {
		Name = "Section_" .. tostring(cfg.Name),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceAlpha,
		LayoutOrder = self:_next(),
		Parent = self._parent,
	})
	corner(Card, 20)
	stroke(Card, Theme.Stroke, 1, 0.84)
	listLayout(Card, 0)

	local Head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = Card,
	})
	local x = 16
	local secIcon = cfg.Icon and makeIcon(Head, cfg.Icon, 20, Theme.Accent, nil, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
	})
	if secIcon then
		x = 44
		accentIcon(secIcon)
	end
	create("TextLabel", {
		Position = UDim2.fromOffset(x, 0),
		Size = UDim2.new(1, -(x + 48), 1, 0),
		Text = tostring(cfg.Name or "Section"),
		TextSize = 15,
		Weight = "Bold",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Head,
	})
	local Chevron
	if collapsible then
		Chevron = makeIcon(Head, "lucide:chevron-down", 18, Theme.SubText, "v", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -24, 0.5, 0),
			Rotation = open and 180 or 0,
		})
	end
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.9,
		Parent = Head,
	})

	local Clip = create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = Card,
	})
	local Inner = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Clip,
	})
	padding(Inner, 12, 12, 12, 12)
	listLayout(Inner, 8)

	local function setOpen(state)
		open = state
		if Chevron then
			tween(Chevron, { Rotation = state and 180 or 0 }, EASE.Smooth)
		end
		if state then
			Clip.AutomaticSize = Enum.AutomaticSize.None
			Clip.Size = UDim2.new(1, 0, 0, Clip.AbsoluteSize.Y)
			tween(Clip, { Size = UDim2.new(1, 0, 0, Inner.AbsoluteSize.Y) }, EASE.Smooth).Completed:Connect(function(s)
				if open and s == Enum.PlaybackState.Completed then
					Clip.AutomaticSize = Enum.AutomaticSize.Y
					Clip.Size = UDim2.new(1, 0, 0, 0)
				end
			end)
		else
			Clip.AutomaticSize = Enum.AutomaticSize.None
			Clip.Size = UDim2.new(1, 0, 0, Clip.AbsoluteSize.Y)
			tween(Clip, { Size = UDim2.new(1, 0, 0, 0) }, EASE.Smooth)
		end
	end

	if collapsible then
		local HeadClick = create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = Head })
		HeadClick.MouseButton1Click:Connect(function()
			setOpen(not open)
		end)
	end

	local Section = setmetatable({ _window = self._window, _parent = Inner, _order = 0, _tab = self._tab }, Elements)
	if self._tab and cfg.Name then
		table.insert(self._tab._titles, string.lower(tostring(cfg.Name)))
	end
	function Section:SetOpen(state)
		if state ~= open then
			setOpen(state)
		end
	end
	return Section
end

function Elements:CreateSubTab(name, icon)
	if not self._bar then
		self._bar = create("ScrollingFrame", {
			Name = "SubTabBar",
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			LayoutOrder = self:_next(),
			Parent = self._parent,
		})
		listLayout(self._bar, 6, true)
		self._subs = {}
	end
	local owner = self

	local Pill = create("TextButton", {
		Name = name,
		Size = UDim2.new(0, 0, 0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 1,
		LayoutOrder = #self._subs + 1,
		Parent = self._bar,
	})
	corner(Pill, 16)
	local pst = stroke(Pill, Theme.Stroke, 1, 1)
	padding(Pill, 12, 0, 14, 0)
	local pl = listLayout(Pill, 7, true)
	pl.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local ico = icon and makeIcon(Pill, icon, 16, Theme.Accent, nil, { LayoutOrder = 1 })
	accentIcon(ico)
	local Label = create("TextLabel", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = name,
		TextSize = 12,
		Weight = "Bold",
		TextColor3 = Theme.SubText,
		LayoutOrder = 2,
		Parent = Pill,
	})

	local Page = create("CanvasGroup", {
		Name = "SubPage_" .. name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		LayoutOrder = self:_next(),
		Parent = self._parent,
	})
	padding(Page, 1, 1, 1, 1)
	listLayout(Page, 8)

	local Sub = setmetatable({ _window = self._window, _parent = Page, _order = 0, _tab = self._tab }, Elements)
	function Sub._select()
		Page.Visible = true
		Page.GroupTransparency = 1
		tween(Page, { GroupTransparency = 0 }, EASE.Smooth)
		tween(Pill, { BackgroundTransparency = 0.88 }, EASE.Smooth)
		tween(pst, { Transparency = 0.7 }, EASE.Smooth)
		tween(Label, { TextColor3 = Theme.Text }, EASE.Smooth)
	end
	function Sub._deselect()
		Page.Visible = false
		tween(Pill, { BackgroundTransparency = 1 }, EASE.Smooth)
		tween(pst, { Transparency = 1 }, EASE.Smooth)
		tween(Label, { TextColor3 = Theme.SubText }, EASE.Smooth)
	end
	Pill.MouseButton1Click:Connect(function()
		if owner._activeSub ~= Sub then
			if owner._activeSub then
				owner._activeSub._deselect()
			end
			owner._activeSub = Sub
			Sub._select()
		end
	end)

	table.insert(self._subs, Sub)
	if not self._activeSub then
		self._activeSub = Sub
		Sub._select()
	end
	return Sub
end

function Elements:CreateLabel(text)
	local L = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text or "",
		TextSize = 12,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = self:_next(),
		Parent = self._parent,
	})
	padding(L, 4, 2, 4, 2)
	local obj = {}
	function obj:Set(t)
		L.Text = t
	end
	return obj
end


function Elements:CreateButton(cfg)
	cfg = cfg or {}
	local center = cfg.Justify == "Center"
	local iconRight = cfg.IconAlign == "Right"
	local hasIcon = cfg.Icon ~= nil
	cfg.CardColor = typeof(cfg.Color) == "Color3" and cfg.Color or nil

	local rightW = center and 0 or ((hasIcon and not iconRight) and 14 or 44)
	local F, Top, st, Title, setLockedRaw = baseElement(self, cfg, rightW)
	local normalTitle = Title.Text
	local TextFrame = Top:FindFirstChild("Text")

	local ic
	if hasIcon then
		ic = leadIcon(Top, cfg.Icon, cfg.IconColor or Theme.Accent, iconRight and "Right" or "Left", center)
	end
	if center then
		Title.TextXAlignment = Enum.TextXAlignment.Center
		local Desc = TextFrame and TextFrame:FindFirstChild("Desc")
		if Desc then
			Desc.TextXAlignment = Enum.TextXAlignment.Center
		end
		if not ic then
			local pad = TextFrame and TextFrame:FindFirstChildOfClass("UIPadding")
			if pad then
				pad.PaddingLeft = UDim.new(0, 14)
				pad.PaddingRight = UDim.new(0, 14)
			end
		end
	elseif not hasIcon then
		create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(20, 24),
			Text = "›",
			TextSize = 22,
			Weight = "Bold",
			TextColor3 = Theme.Accent,
			Accent = "TextColor3",
			Parent = Top,
		})
	end

	local Click = create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = F })
	Click.InputBegan:Connect(function(input)
		if isPointer(input) then
			ripple(F, input)
		end
	end)
	Click.MouseButton1Click:Connect(function()
		st.Color = Theme.Accent
		tween(st, { Color = Theme.Stroke }, EASE.Slow)
		safe(cfg.Callback)
	end)

	local obj = {}
	local function setLocked(a, b)
		local state = a
		if type(a) == "table" then
			state = b
		end
		state = state == true
		setLockedRaw(state)
		if cfg.LockedTitle then
			Title.Text = state and cfg.LockedTitle or normalTitle
		end
	end
	obj.SetLocked = setLocked
	if cfg.Locked then
		setLocked(true)
	end
	function obj:SetText(t)
		normalTitle = t
		Title.Text = t
	end
	if cfg.Flag then
		Library.Items[cfg.Flag] = obj
	end
	return obj
end


function Elements:CreateToggle(cfg)
	cfg = cfg or {}
	local value = cfg.Value == true or cfg.Default == true
	local isBox = cfg.Type == "Checkbox"
	local F, Top, st, Title, setLocked = baseElement(self, cfg, isBox and 52 or 70)
	leadIcon(Top, cfg.Icon, cfg.IconColor)

	local Track, Knob, Glow, Check
	if isBox then
		Track = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = Theme.Track,
			Parent = Top,
		})
		corner(Track, 8)
		Glow = accented(stroke(Track, Theme.Accent, 1.5, 1), "Color")
		Check = makeIcon(Track, "lucide:check", 16, Color3.new(1, 1, 1), "✓", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Visible = false,
		})
	else
		Track = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(42, 24),
			BackgroundColor3 = Theme.Track,
			Parent = Top,
		})
		corner(Track, 999)
		Glow = accented(stroke(Track, Theme.Accent, 1.5, 1), "Color")
		Knob = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Track,
		})
		corner(Knob, 999)
	end

	local function render(animate)
		tween(Track, { BackgroundColor3 = value and Theme.Accent or Theme.Track },
			animate and EASE.Smooth or EASE.Instant)
		if Knob then
			tween(Knob, {
				Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}, animate and EASE.Spring or EASE.Instant)
		end
		if Check then
			Check.Visible = value
		end
		tween(Glow, { Transparency = value and 0.55 or 1 }, EASE.Smooth)
	end
	bindAccent(function(c)
		if value then
			Track.BackgroundColor3 = c
		end
	end)

	local obj = { SetLocked = setLocked }
	function obj:Set(v, silent)
		value = v == true
		render(true)
		if cfg.Flag then
			Library.Flags[cfg.Flag] = value
		end
		if not silent then
			safe(cfg.Callback, value)
		end
	end
	function obj:Get()
		return value
	end

	local Click = create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = F })
	Click.MouseButton1Click:Connect(function()
		obj:Set(not value)
	end)
	if Knob then
		Click.MouseButton1Down:Connect(function()
			tween(Knob, {
				Size = UDim2.fromOffset(22, 18),
				Position = value and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}, EASE.Fast)
		end)
		local function release()
			tween(Knob, {
				Size = UDim2.fromOffset(18, 18),
				Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}, EASE.Fast)
		end
		Click.MouseButton1Up:Connect(release)
		Click.MouseLeave:Connect(release)
	end

	register(cfg.Flag, obj, value)
	render(false)
	return obj
end

function Elements:CreateSlider(cfg)
	cfg = cfg or {}

	local vt = type(cfg.Value) == "table" and cfg.Value or {}
	local min, max = vt.Min or cfg.Min or 0, vt.Max or cfg.Max or 100
	if min > max then
		min, max = max, min
	end
	local inc = cfg.Step or cfg.Increment or 1
	local suffix = cfg.Suffix or ""
	local start = vt.Default
	if start == nil then
		start = type(cfg.Value) == "number" and cfg.Value or cfg.Default
	end
	local value = math.clamp(start or min, min, max)

	local F, Top, st, Title, setLocked = baseElement(self, cfg, 100)
	leadIcon(Top, cfg.Icon, cfg.IconColor)
	local ValueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(90, 18),
		TextSize = 12,
		Weight = "Bold",
		TextColor3 = Theme.Accent,
		Accent = "TextColor3",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Top,
	})

	local Extra = makeExtra(F, 28)
	local Bar = create("Frame", {
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Theme.Track,
		Parent = Extra,
	})
	corner(Bar, 999)
	local Fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Bar,
	})
	corner(Fill, 999)
	local fillGrad = create("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Parent = Fill })
	bindAccent(function(a, b)
		fillGrad.Color = ColorSequence.new(a, b)
	end)
	local Knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Fill,
	})
	corner(Knob, 999)
	accented(stroke(Knob, Theme.Accent, 2, 0), "Color")

	local function render(animate)
		local rel = (max == min) and 0 or (value - min) / (max - min)
		tween(Fill, { Size = UDim2.new(rel, 0, 1, 0) }, animate and EASE.Fast or EASE.Instant)
		ValueLabel.Text = tostring(value) .. suffix
	end

	local obj = { SetLocked = setLocked }
	function obj:Set(v, silent)
		v = math.clamp(round(tonumber(v) or min, inc), min, max)
		local changed = v ~= value
		value = v
		render(true)
		if cfg.Flag then
			Library.Flags[cfg.Flag] = value
		end
		if changed and not silent then
			safe(cfg.Callback, value)
		end
	end
	function obj:Get()
		return value
	end

	local Hit = create("TextButton", {
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		ZIndex = 3,
		Parent = Extra,
	})
	dragInput(self._window, Hit, function(pos)
		local rel = math.clamp((pos.X - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
		obj:Set(min + (max - min) * rel)
	end, function(active)
		tween(Knob, { Size = active and UDim2.fromOffset(19, 19) or UDim2.fromOffset(14, 14) }, EASE.Fast)
	end)

	register(cfg.Flag, obj, value)
	render(false)
	return obj
end


function Elements:CreateDropdown(cfg)
	cfg = cfg or {}
	local multi = cfg.Multi == true
	local value = multi and {} or nil
	local open = false
	local items = {}
	local rows = {}
	local created = {}
	local actionMenu = false

	local F, Top, _, _, setLocked = baseElement(self, cfg, 170)
	leadIcon(Top, cfg.Icon, cfg.IconColor)

	local Selected = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0.5, 0),
		Size = UDim2.fromOffset(130, 20),
		TextSize = 12,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Top,
	})
	local Arrow = makeIcon(Top, "lucide:chevron-down", 18, Theme.SubText, "v", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -22, 0.5, 0),
	})

	local Extra = makeExtra(F, 0)
	local Holder = create("ScrollingFrame", {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 0, 0),
		BackgroundColor3 = Theme.Inset,
		BackgroundTransparency = 0.62,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		Accent = "ScrollBarImageColor3",
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Extra,
	})
	corner(Holder, 10)
	padding(Holder, 4, 4, 4, 4)
	listLayout(Holder, 2)

	local function normalize(list)
		items = {}
		for _, v in ipairs(list or {}) do
			if type(v) == "table" then
				if v.Type == "Divider" then
					table.insert(items, { divider = true })
				else
					local t = tostring(v.Title or v.Name or v.Value or "Item")
					table.insert(items, {
						value = t, title = t,
						desc = v.Desc or v.Description,
						icon = v.Icon,
						callback = v.Callback,
					})
				end
			else
				table.insert(items, { value = v, title = tostring(v) })
			end
		end
	end

	local function isSelected(v)
		if multi then
			return table.find(value, v) ~= nil
		end
		return value == v
	end

	local function itemH(it)
		if it.divider then
			return 9
		end
		return it.desc and 46 or ((it.icon and 32) or 28)
	end

	local function listHeight()
		local h = 8
		for i, it in ipairs(items) do
			h += itemH(it) + (i > 1 and 2 or 0)
		end
		return math.min(h, 190)
	end

	local function paint()
		for _, r in pairs(rows) do
			local on = isSelected(r.value)
			tween(r.btn, { BackgroundTransparency = on and 0.86 or 1 }, EASE.Fast)
			tween(r.title, { TextColor3 = on and Theme.Accent or Theme.Text }, EASE.Fast)
		end
	end
	bindAccent(function()
		paint()
	end)

	local function display()
		if multi then
			local names = {}
			for _, it in ipairs(items) do
				if not it.divider and table.find(value, it.value) then
					table.insert(names, tostring(it.title))
				end
			end
			Selected.Text = #names > 0 and table.concat(names, ", ") or "None"
		else
			Selected.Text = value ~= nil and tostring(value) or "Select..."
		end
	end

	local function setOpen(state)
		open = state
		Holder.Size = UDim2.new(1, -24, 0, listHeight())
		tween(Extra, { Size = UDim2.new(1, 0, 0, state and (listHeight() + 12) or 0) }, EASE.Smooth)
		if Arrow then
			tween(Arrow, { Rotation = state and 180 or 0 }, EASE.Smooth)
			setIconColor(Arrow, state and Theme.Accent or Theme.SubText)
		end
	end

	local function commit(silent)
		display()
		paint()
		if cfg.Flag then
			Library.Flags[cfg.Flag] = value
		end
		if not silent then
			safe(cfg.Callback, value)
		end
	end

	local function build()
		for _, o in ipairs(created) do
			o:Destroy()
		end
		pruneAccent()
		created, rows = {}, {}
		for i, it in ipairs(items) do
			if it.divider then
				local d = create("Frame", {
					Size = UDim2.new(1, 0, 0, 9),
					BackgroundTransparency = 1,
					LayoutOrder = i,
					Parent = Holder,
				})
				create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -12, 0, 1),
					BackgroundColor3 = Theme.Stroke,
					BackgroundTransparency = 0.88,
					Parent = d,
				})
				table.insert(created, d)
			else
				local h = itemH(it)
				local b = create("TextButton", {
					Size = UDim2.new(1, 0, 0, h),
					BackgroundColor3 = Theme.Accent,
					Accent = "BackgroundColor3",
					BackgroundTransparency = 1,
					LayoutOrder = i,
					Parent = Holder,
				})
				corner(b, 8)
				local x = it.icon and 34 or 10
				if it.icon then
					makeIcon(b, it.icon, 16, Theme.SubText, nil, {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 10, 0.5, 0),
					})
				end
				local tl = create("TextLabel", {
					Position = UDim2.new(0, x, 0, it.desc and 6 or 0),
					Size = UDim2.new(1, -(x + 6), 0, it.desc and 16 or h),
					Text = it.title,
					TextSize = 12,
					Weight = it.desc and "Bold" or "Medium",
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = b,
				})
				if it.desc then
					create("TextLabel", {
						Position = UDim2.new(0, x, 0, 24),
						Size = UDim2.new(1, -(x + 6), 0, 16),
						Text = it.desc,
						TextSize = 11,
						Weight = "Regular",
						TextColor3 = Theme.SubText,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Parent = b,
					})
				end
				b.MouseEnter:Connect(function()
					if not isSelected(it.value) then
						tween(b, { BackgroundTransparency = 0.94 }, EASE.Fast)
					end
				end)
				b.MouseLeave:Connect(function()
					if not isSelected(it.value) then
						tween(b, { BackgroundTransparency = 1 }, EASE.Fast)
					end
				end)
				b.MouseButton1Click:Connect(function()
					if multi then
						local idx = table.find(value, it.value)
						if idx then
							table.remove(value, idx)
						else
							table.insert(value, it.value)
						end
					elseif actionMenu then
						setOpen(false)
						safe(cfg.Callback, it.value)
						safe(it.callback, it.value)
						return
					else
						value = it.value
						setOpen(false)
					end
					commit()
					safe(it.callback, it.value)
				end)
				table.insert(created, b)
				table.insert(rows, { btn = b, title = tl, value = it.value })
			end
		end
	end

	local obj = { SetLocked = setLocked }
	function obj:Set(v, silent)
		if multi then
			value = type(v) == "table" and table.clone(v) or {}
		else
			value = v
		end
		commit(silent)
	end
	function obj:Get()
		return value
	end
	function obj:Refresh(newValues, keep)
		normalize(newValues)
		if not keep then
			value = multi and {} or nil
		end
		build()
		commit(true)
		if open then
			setOpen(true)
		end
	end

	local Click = create("TextButton", { Size = UDim2.new(1, 0, 0, 0), ZIndex = 3, Parent = F })
	bindHeight(Click, Top)
	Click.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	normalize(cfg.Values or cfg.Options)
	if not multi and cfg.Value == nil and cfg.Default == nil then
		local count = 0
		actionMenu = true
		for _, it in ipairs(items) do
			if not it.divider then
				count += 1
				if not it.callback then
					actionMenu = false
				end
			end
		end
		actionMenu = actionMenu and count > 0
	end
	build()
	local default = cfg.Value
	if default == nil then
		default = cfg.Default
	end
	if default ~= nil then
		obj:Set(default, true)
	else
		commit(true)
	end
	register(cfg.Flag, obj, value)
	return obj
end


function Elements:CreateTextBox(cfg)
	cfg = cfg or {}
	local value = cfg.Value
	if value == nil then
		value = cfg.Default or ""
	end
	value = tostring(value)
	local area = cfg.Type == "Textarea"
	local F, Top, _, _, setLocked = baseElement(self, cfg, area and 20 or 180)

	local Wrap
	if area then
		local Extra = makeExtra(F, 108)
		Wrap = create("Frame", {
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -24, 0, 92),
			BackgroundColor3 = Theme.Inset,
			BackgroundTransparency = 0.6,
			Parent = Extra,
		})
	else
		Wrap = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(160, 30),
			BackgroundColor3 = Theme.Inset,
			BackgroundTransparency = 0.6,
			Parent = Top,
		})
	end
	corner(Wrap, 10)
	local bs = stroke(Wrap, Theme.Stroke, 1, 0.85)

	local leftPad = 10
	if cfg.Icon then
		local ic = makeIcon(Wrap, cfg.Icon, 14, Theme.SubText, nil, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, area and 0 or 0.5, area and 16 or 0),
		})
		if ic then
			leftPad = 32
		end
	end

	local Box = create("TextBox", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = value,
		PlaceholderText = cfg.Placeholder or "Type here...",
		PlaceholderColor3 = Theme.SubText,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = area and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		MultiLine = area,
		TextWrapped = area,
		Parent = Wrap,
	})
	padding(Box, leftPad, area and 8 or 0, 10, area and 8 or 0)

	Box.Focused:Connect(function()
		tween(bs, { Color = Theme.Accent, Transparency = 0 }, EASE.Fast)
	end)

	local obj = { SetLocked = setLocked }
	function obj:Set(v, silent)
		value = tostring(v)
		Box.Text = value
		if cfg.Flag then
			Library.Flags[cfg.Flag] = value
		end
		if not silent then
			safe(cfg.Callback, value)
		end
	end
	function obj:Get()
		return value
	end

	Box.FocusLost:Connect(function()
		tween(bs, { Color = Theme.Stroke, Transparency = 0.85 }, EASE.Smooth)
		local text = Box.Text
		if cfg.Numeric then
			local n = tonumber(text)
			text = n and tostring(n) or value
		end
		obj:Set(text)
	end)

	register(cfg.Flag, obj, value)
	return obj
end

local function keyName(k)
	if k == Enum.KeyCode.Unknown then
		return "-"
	end
	local n = k.Name
	n = n:gsub("Left", "L")
	n = n:gsub("Right", "R")
	n = n:gsub("Control", "Ctrl")
	return n
end

function Elements:CreateKeybind(cfg)
	cfg = cfg or {}
	local key = cfg.Value
	if key == nil then
		key = cfg.Default
	end
	if typeof(key) == "string" then
		local okKey, kc = pcall(function()
			return Enum.KeyCode[key]
		end)
		key = okKey and kc or nil
	end
	key = key or Enum.KeyCode.Unknown
	local listening = false
	local locked = cfg.Locked == true
	local F, Top, st, Title, setLockedRaw = baseElement(self, cfg, 80)
	local function setLocked(a, b)
		local state = a
		if type(a) == "table" then
			state = b
		end
		locked = state == true
		if locked then
			listening = false
		end
		setLockedRaw(state)
	end
	leadIcon(Top, cfg.Icon, cfg.IconColor)

	local Btn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Inset,
		BackgroundTransparency = 0.6,
		TextSize = 12,
		Weight = "Bold",
		TextColor3 = Theme.Text,
		ZIndex = 3,
		Parent = Top,
	})
	corner(Btn, 10)
	padding(Btn, 10, 0, 10, 0)
	create("UISizeConstraint", { MinSize = Vector2.new(34, 32), Parent = Btn })
	local bs = stroke(Btn, Theme.Stroke, 1, 0.82)

	local function label()
		Btn.Text = keyName(key)
	end
	label()

	local obj = { SetLocked = setLocked }
	function obj:Set(k, silent)
		if typeof(k) == "string" then
			local okK, kc = pcall(function()
				return Enum.KeyCode[k]
			end)
			k = okK and kc or nil
		end
		key = k or Enum.KeyCode.Unknown
		label()
		if cfg.Flag then
			Library.Flags[cfg.Flag] = key
		end
		if not silent then
			safe(cfg.Changed, key)
		end
	end
	function obj:Get()
		return key
	end

	Btn.MouseButton1Click:Connect(function()
		if locked then
			return
		end
		listening = true
		Btn.Text = "..."
		tween(bs, { Color = Theme.Accent, Transparency = 0 }, EASE.Fast)
	end)

	self._window:_track(UserInputService.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				tween(bs, { Color = Theme.Stroke, Transparency = 0.82 }, EASE.Smooth)
				if input.KeyCode == Enum.KeyCode.Escape then
					label()
				else
					obj:Set(input.KeyCode)
				end
			end
		elseif not locked and not gp and key ~= Enum.KeyCode.Unknown and input.KeyCode == key
			and (not cfg.Premium or premiumState) then
			safe(cfg.Callback, key.Name)
		end
	end))

	register(cfg.Flag, obj, key)
	return obj
end


function Elements:CreateColorPicker(cfg)
	cfg = cfg or {}
	local color = cfg.Default or Theme.Accent
	local h, s, v = color:ToHSV()
	local hasAlpha = cfg.Transparency ~= nil
	local alpha = math.clamp(tonumber(cfg.Transparency) or 0, 0, 1)
	local open = false
	local PICK_H = 110
	local EXTRA_H = PICK_H + (hasAlpha and 28 or 0) + 14

	local F, Top, _, _, setLocked = baseElement(self, cfg, 150)

	local Hex = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -60, 0.5, 0),
		Size = UDim2.fromOffset(76, 20),
		TextSize = 11,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Top,
	})
	local Swatch = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = color,
		BackgroundTransparency = alpha,
		Parent = Top,
	})
	corner(Swatch, 7)
	stroke(Swatch, Color3.new(1, 1, 1), 1, 0.7)

	local Extra = makeExtra(F, 0)

	local SV = create("Frame", {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -62, 0, PICK_H),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		ClipsDescendants = true,
		Parent = Extra,
	})
	corner(SV, 10)
	local White = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = SV,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = White,
	})
	local Black = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Parent = SV,
	})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = Black,
	})
	local SVCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = SV,
	})
	corner(SVCursor, 999)
	stroke(SVCursor, Color3.new(1, 1, 1), 2, 0)

	local HueBar = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		Size = UDim2.fromOffset(20, PICK_H),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Extra,
	})
	corner(HueBar, 8)
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0.999 or i / 6, 1, 1)))
	end
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = HueBar })
	local HueCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 4, 0, 5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = HueBar,
	})
	corner(HueCursor, 3)
	stroke(HueCursor, Color3.fromRGB(20, 20, 30), 1, 0.2)

	local AlphaBar, AlphaCursor
	if hasAlpha then
		AlphaBar = create("Frame", {
			Position = UDim2.new(0, 14, 0, PICK_H + 10),
			Size = UDim2.new(1, -28, 0, 14),
			BackgroundColor3 = color,
			Parent = Extra,
		})
		corner(AlphaBar, 7)
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = AlphaBar,
		})
		stroke(AlphaBar, Color3.new(1, 1, 1), 1, 0.8)
		AlphaCursor = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 20),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 3,
			Parent = AlphaBar,
		})
		corner(AlphaCursor, 3)
		stroke(AlphaCursor, Color3.fromRGB(20, 20, 30), 1, 0.2)
	end

	local obj = { SetLocked = setLocked }
	local function refresh(silent)
		color = Color3.fromHSV(h, s, v)
		SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		SVCursor.Position = UDim2.fromScale(s, 1 - v)
		HueCursor.Position = UDim2.fromScale(0.5, h)
		if AlphaBar then
			AlphaBar.BackgroundColor3 = color
			AlphaCursor.Position = UDim2.fromScale(alpha, 0.5)
		end
		tween(Swatch, { BackgroundColor3 = color, BackgroundTransparency = alpha }, EASE.Fast)
		Hex.Text = "#" .. color:ToHex():upper()
		if cfg.Flag then
			Library.Flags[cfg.Flag] = color
		end
		if not silent then
			if cfg.ApplyToTheme then
				Library:SetAccent(color, nil, true)
			end
			safe(cfg.Callback, color, alpha)
		end
	end

	function obj:Set(c, silent)
		h, s, v = c:ToHSV()
		refresh(silent)
	end
	function obj:SetTransparency(a, silent)
		alpha = math.clamp(tonumber(a) or 0, 0, 1)
		refresh(silent)
	end
	function obj:Get()
		return color, alpha
	end

	dragInput(self._window, SV, function(pos)
		s = math.clamp((pos.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((pos.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
		refresh()
	end)
	dragInput(self._window, HueBar, function(pos)
		h = math.clamp((pos.Y - HueBar.AbsolutePosition.Y) / math.max(HueBar.AbsoluteSize.Y, 1), 0, 0.999)
		refresh()
	end)
	if AlphaBar then
		dragInput(self._window, AlphaBar, function(pos)
			alpha = math.clamp((pos.X - AlphaBar.AbsolutePosition.X) / math.max(AlphaBar.AbsoluteSize.X, 1), 0, 1)
			refresh()
		end)
	end

	local Click = create("TextButton", { Size = UDim2.new(1, 0, 0, 0), ZIndex = 4, Parent = F })
	bindHeight(Click, Top)
	Click.MouseButton1Click:Connect(function()
		open = not open
		tween(Extra, { Size = UDim2.new(1, 0, 0, open and EXTRA_H or 0) }, EASE.Smooth)
	end)

	register(cfg.Flag, obj, color)
	refresh(true)
	return obj
end


function Elements:CreateParagraph(cfg)
	cfg = cfg or {}
	cfg.Name = cfg.Name or cfg.Title
	cfg.Description = cfg.Description or cfg.Desc
	if self._tab then
		table.insert(self._tab._titles, string.lower(tostring(cfg.Name or "")))
		if cfg.Description then
			table.insert(self._tab._titles, string.lower(tostring(cfg.Description)))
		end
	end
	local tint = namedColor(cfg.Color)
	local F, Stack, _, setLocked = makeCard(self, cfg, tint)

	local hasThumb = cfg.Thumbnail ~= nil and cfg.Thumbnail ~= ""
	local thumbH = cfg.ThumbnailSize or 80
	if hasThumb then
		local Wrap = create("Frame", {
			Size = UDim2.new(1, 0, 0, thumbH + 12),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = Stack,
		})
		padding(Wrap, 12, 12, 12, 0)
		local img = create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			Image = imageAsset(cfg.Thumbnail),
			ScaleType = Enum.ScaleType.Crop,
			BackgroundColor3 = Theme.Inset,
			BackgroundTransparency = 0.6,
			Parent = Wrap,
		})
		corner(img, 10)
	end

	local hasImg = cfg.Image ~= nil and cfg.Image ~= ""
	local imgSize = cfg.ImageSize or 30
	local Head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = Stack,
	})
	padding(Head, 14 + (hasImg and (imgSize + 10) or 0), 12, 14, 12)
	listLayout(Head, 4)
	if hasImg then
		local im = create("ImageLabel", {
			Position = UDim2.fromOffset(14, hasThumb and (thumbH + 24) or 12),
			Size = UDim2.fromOffset(imgSize, imgSize),
			Image = imageAsset(cfg.Image),
			Parent = F,
		})
		corner(im, 8)
	end
	local Title = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = cfg.Name or "Paragraph",
		TextSize = 13,
		Weight = "Bold",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		Parent = Head,
	})
	local Desc = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = cfg.Description or "",
		Visible = cfg.Description ~= nil,
		TextSize = 12,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		Parent = Head,
	})

	if type(cfg.Buttons) == "table" and #cfg.Buttons > 0 then
		local Row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Parent = Stack,
		})
		padding(Row, 12, 0, 12, 12)
		local rl = listLayout(Row, 8, true)
		rl.Wraps = true
		rl.VerticalAlignment = Enum.VerticalAlignment.Top
		for i, b in ipairs(cfg.Buttons) do
			local Btn = create("TextButton", {
				Size = UDim2.new(0, 0, 0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.86,
				LayoutOrder = i,
				Parent = Row,
			})
			corner(Btn, 10)
			local bst = stroke(Btn, Theme.Stroke, 1, 0.8)
			padding(Btn, 12, 0, 14, 0)
			local bl = listLayout(Btn, 6, true)
			bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
			if b.Icon then
				local btnTint = b.IconColor or (isCustomImage(b.Icon) and Color3.new(1, 1, 1)) or tint or Theme.Accent
				makeIcon(Btn, b.Icon, 15, btnTint, nil, { LayoutOrder = 1 })
			end
			create("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = b.Title or b.Name or "Button",
				TextSize = 12,
				Weight = "Bold",
				LayoutOrder = 2,
				Parent = Btn,
			})
			Btn.MouseEnter:Connect(function()
				tween(Btn, { BackgroundTransparency = 0.74 }, EASE.Fast)
			end)
			Btn.MouseLeave:Connect(function()
				tween(Btn, { BackgroundTransparency = 0.86 }, EASE.Fast)
			end)
			Btn.MouseButton1Click:Connect(function()
				bst.Color = tint or Theme.Accent
				tween(bst, { Color = Theme.Stroke }, EASE.Slow)
				safe(b.Callback)
			end)
		end
	end

	local obj = { SetLocked = setLocked }
	function obj:SetTitle(t)
		Title.Text = t
	end
	function obj:SetDesc(t)
		Desc.Text = t
		Desc.Visible = t ~= nil and t ~= ""
	end
	function obj:Destroy()
		F:Destroy()
	end
	return obj
end


function Elements:CreateProgressBar(cfg)
	cfg = cfg or {}
	local indeterminate = cfg.Indeterminate == true
	local idleText = cfg.IndeterminateText or "Loading..."
	local min, max = cfg.Min or 0, cfg.Max or 100
	local value = math.clamp(cfg.Default or cfg.Value or 0, min, max)
	local speed = math.max(cfg.Speed or 1, 0.1)

	local F, Top, _, Title, setLocked = baseElement(self, cfg, 130)
	local Label = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(120, 18),
		TextSize = 12,
		Weight = "Bold",
		TextColor3 = Theme.Accent,
		Accent = "TextColor3",
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Top,
	})

	local Extra = makeExtra(F, 24)
	local Track = create("Frame", {
		Position = UDim2.new(0, 14, 0, 4),
		Size = UDim2.new(1, -28, 0, 8),
		BackgroundColor3 = Theme.Track,
		ClipsDescendants = true,
		Parent = Extra,
	})
	corner(Track, 999)
	local Fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Track,
	})
	corner(Fill, 999)
	local grad = create("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Parent = Fill })
	bindAccent(function(a, b)
		grad.Color = ColorSequence.new(a, b)
	end)

	local loop
	local function render(animate)
		if loop then
			loop:Cancel()
			loop = nil
		end
		if indeterminate then
			Fill.Size = UDim2.fromScale(0.4, 1)
			Fill.Position = UDim2.fromScale(-0.4, 0)
			loop = TweenService:Create(Fill, TweenInfo.new(
				1.4 / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false
			), { Position = UDim2.fromScale(1, 0) })
			loop:Play()
			Label.Text = idleText
		else
			Fill.Position = UDim2.fromScale(0, 0)
			local rel = (max == min) and 0 or (value - min) / (max - min)
			tween(Fill, { Size = UDim2.fromScale(rel, 1) }, animate and EASE.Smooth or EASE.Instant)
			Label.Text = string.format("%d%%", math.floor(rel * 100 + 0.5))
		end
	end

	local obj = { SetLocked = setLocked }
	function obj:Set(v)
		value = math.clamp(tonumber(v) or min, min, max)
		indeterminate = false
		render(true)
	end
	function obj:Get()
		return value
	end
	function obj:SetIndeterminate(state, text)
		indeterminate = state == true
		if text then
			idleText = text
		end
		render(true)
	end
	function obj:SetTitle(t)
		Title.Text = t
	end
	function obj:SetDesc(t)
		local tf = Top:FindFirstChild("Text")
		local d = tf and tf:FindFirstChild("Desc")
		if d then
			d.Text = t
		end
	end

	render(false)
	return obj
end


local DEFAULT_CODE_THEME = {
	numbers = Color3.fromHex("#FAB387"),
	boolean = Color3.fromHex("#FAB387"),
	operator = Color3.fromHex("#94E2D5"),
	lua = Color3.fromHex("#CBA6F7"),
	rbx = Color3.fromHex("#F38BA8"),
	str = Color3.fromHex("#A6E3A1"),
	comment = Color3.fromHex("#9399B2"),
	null = Color3.fromHex("#F38BA8"),
	call = Color3.fromHex("#89B4FA"),
	self_call = Color3.fromHex("#89B4FA"),
	local_property = Color3.fromHex("#CBA6F7"),
	text = Color3.fromHex("#CDD6F4"),
}

local LUA_KEYWORDS = {}
for _, w in ipairs({ "local", "function", "end", "if", "then", "else", "elseif", "for", "while", "do",
	"return", "and", "or", "not", "in", "repeat", "until", "break", "continue" }) do
	LUA_KEYWORDS[w] = true
end
local RBX_GLOBALS = {}
for _, w in ipairs({ "game", "workspace", "script", "Instance", "Enum", "Vector2", "Vector3", "CFrame", "Color3",
	"UDim", "UDim2", "TweenInfo", "Font", "Random", "BrickColor", "NumberSequence", "ColorSequence", "Rect",
	"task", "math", "string", "table", "os", "utf8", "coroutine", "debug", "buffer", "bit32",
	"print", "warn", "error", "assert", "typeof", "type", "pairs", "ipairs", "next", "select", "pcall", "xpcall",
	"tostring", "tonumber", "require", "setmetatable", "getmetatable", "rawget", "rawset", "unpack", "tick", "wait", "spawn" }) do
	RBX_GLOBALS[w] = true
end

local function escRich(t)
	t = t:gsub("&", "&amp;")
	t = t:gsub("<", "&lt;")
	t = t:gsub(">", "&gt;")
	t = t:gsub('"', "&quot;")
	t = t:gsub("'", "&apos;")
	return t
end

local function highlightLua(code, theme)
	code = tostring(code)
	local out = {}
	local i, n = 1, #code
	local prev = ""
	local function put(text, color)
		if color then
			table.insert(out, '<font color="#' .. color:ToHex() .. '">' .. escRich(text) .. "</font>")
		else
			table.insert(out, escRich(text))
		end
	end
	while i <= n do
		local c = code:sub(i, i)
		if code:sub(i, i + 1) == "--" then
			local lb = code:match("^%-%-%[(=*)%[", i)
			local e
			if lb then
				local _, ce = code:find("]" .. lb .. "]", i, true)
				e = ce or n
			else
				local nl = code:find("\n", i, true)
				e = nl and (nl - 1) or n
			end
			put(code:sub(i, e), theme.comment)
			i = e + 1
			prev = ""
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n do
				local d = code:sub(j, j)
				if d == "\\" then
					j += 2
				elseif d == c or d == "\n" then
					break
				else
					j += 1
				end
			end
			put(code:sub(i, math.min(j, n)), theme.str)
			i = math.min(j, n) + 1
			prev = ""
		elseif c == "[" and code:match("^%[=*%[", i) then
			local lb = code:match("^%[(=*)%[", i)
			local _, ce = code:find("]" .. lb .. "]", i, true)
			local e = ce or n
			put(code:sub(i, e), theme.str)
			i = e + 1
			prev = ""
		elseif c:match("%d") or (c == "." and (code:sub(i + 1, i + 1)):match("%d")) then
			local num = code:match("^0[xX]%x+", i) or code:match("^%d*%.?%d+[eE][%+%-]?%d+", i) or code:match("^%d*%.?%d*", i)
			if num == nil or #num == 0 then
				num = c
			end
			put(num, theme.numbers)
			i += #num
			prev = ""
		elseif c:match("[%a_]") then
			local word = code:match("^[%w_]+", i)
			local after = code:match("^%s*(.)", i + #word)
			local color
			if word == "true" or word == "false" then
				color = theme.boolean
			elseif word == "nil" then
				color = theme.null
			elseif LUA_KEYWORDS[word] then
				color = theme.lua
			elseif prev == ":" then
				color = theme.self_call
			elseif prev == "." then
				color = (after == "(") and theme.call or theme.local_property
			elseif RBX_GLOBALS[word] then
				color = theme.rbx
			elseif after == "(" then
				color = theme.call
			end
			put(word, color)
			i += #word
			prev = ""
		elseif c == "." and code:sub(i + 1, i + 1) == "." then
			put("..", theme.operator)
			i += 2
			prev = ""
		elseif c == "." or c == ":" then
			put(c, nil)
			i += 1
			prev = c
		elseif c:match("[%+%-%*/%%%^#=<>~]") then
			put(c, theme.operator)
			i += 1
			prev = ""
		elseif c:match("%s") then
			put(c, nil)
			i += 1
		else
			put(c, nil)
			i += 1
			prev = ""
		end
	end
	return table.concat(out)
end


function Elements:CreateCode(cfg)
	cfg = cfg or {}
	local codeText = tostring(cfg.Code or "")
	if not codeText:find("\n", 1, true) and codeText:find("\\n", 1, true) then
		codeText = (codeText:gsub("\\n", "\n"))
	end
	local theme = {}
	for k, v in pairs(DEFAULT_CODE_THEME) do
		theme[k] = (cfg.CodeTheme and cfg.CodeTheme[k]) or v
	end
	local canCopy = cfg.CanCopied ~= false

	local F, Top, _, _, setLocked = baseElement(self, cfg, canCopy and 56 or 0, 48)
	local Extra = makeExtra(F, 132)

	local Box = create("ScrollingFrame", {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 0, 120),
		BackgroundColor3 = Theme.Inset,
		BackgroundTransparency = 0.45,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		Accent = "ScrollBarImageColor3",
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		Parent = Extra,
	})
	corner(Box, 10)
	padding(Box, 12, 10, 12, 10)

	local Label = create("TextLabel", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		RichText = true,
		TextSize = cfg.CodeSize or 14,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = false,
		TextStrokeTransparency = 1,
		Parent = Box,
	})
	Label.FontFace = Font.new(resolveFamily("Mono"), WEIGHT.Regular)

	local function setHeight(h)
		Box.Size = UDim2.new(1, -24, 0, h)
		Extra.Size = UDim2.new(1, 0, 0, h + 12)
	end

	local function render()
		Label.Text = highlightLua(codeText, theme)
	end
	render()

	if cfg.Height ~= nil then
		local function update()
			local h
			if type(cfg.Height) == "number" then
				h = cfg.Height
			else
				local sf = F:FindFirstAncestorOfClass("ScrollingFrame")
				local base = sf and sf.AbsoluteSize.Y or 300
				h = cfg.Height.Scale * base + cfg.Height.Offset - Top.AbsoluteSize.Y - 28
			end
			setHeight(math.max(60, h))
		end
		local sf = F:FindFirstAncestorOfClass("ScrollingFrame")
		if sf then
			sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		end
		update()
	else
		local function update()
			setHeight(math.clamp(Label.AbsoluteSize.Y + 24, 60, 320))
		end
		Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		update()
	end

	local CopyBtn, copyIcon
	if canCopy then
		CopyBtn = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = Theme.Inset,
			BackgroundTransparency = 0.6,
			Parent = Top,
		})
		corner(CopyBtn, 10)
		stroke(CopyBtn, Theme.Stroke, 1, 0.85)
		local function setIcon(name, color, fallback)
			if copyIcon then
				copyIcon:Destroy()
			end
			copyIcon = makeIcon(CopyBtn, name, 16, color, fallback, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			})
		end
		setIcon("lucide:copy", Theme.SubText, "cp")
		CopyBtn.MouseButton1Click:Connect(function()
			local clip = (typeof(setclipboard) == "function" and setclipboard)
				or (typeof(toclipboard) == "function" and toclipboard) or nil
			local ok = false
			if clip then
				ok = pcall(clip, codeText)
			end
			setIcon(ok and "lucide:check" or "lucide:x", ok and Theme.Success or Theme.Danger, ok and "ok" or "x")
			task.delay(1.2, function()
				setIcon("lucide:copy", Theme.SubText, "cp")
			end)
			if ok then
				safe(cfg.OnCopy)
			end
		end)
	end

	local obj = { SetLocked = setLocked }
	function obj:SetCode(text)
		codeText = tostring(text or "")
		render()
	end
	function obj:Get()
		return codeText
	end
	return obj
end

Elements.Paragraph = Elements.CreateParagraph
Elements.Colorpicker = Elements.CreateColorPicker
Elements.ProgressBar = Elements.CreateProgressBar
Elements.Button = Elements.CreateButton
Elements.Toggle = Elements.CreateToggle
Elements.Slider = Elements.CreateSlider
Elements.Dropdown = Elements.CreateDropdown
Elements.Input = Elements.CreateTextBox
Elements.Keybind = Elements.CreateKeybind
Elements.Label = Elements.CreateLabel
Elements.Section = Elements.CreateSection
Elements.Code = Elements.CreateCode


local WindowClass = {}
WindowClass.__index = WindowClass

function WindowClass:_track(conn)
	table.insert(self._conns, conn)
	return conn
end

local function makeDraggable(window, handle, target)
	local dragging, startInput, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			startInput = input.Position
			startPos = target.Position
		end
	end)
	window:_track(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMove(input) then
			local d = input.Position - startInput
			tween(target, {
				Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				),
			}, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		end
	end))
	window:_track(UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			dragging = false
		end
	end))
end


----------------------------------------------------------------------
-- KEY SYSTEM
----------------------------------------------------------------------
-- local ok, key, tier = Library:KeySystem({
--     Title = "Opah Hub", Subtitle = "...", Icon = "123456789",
--     Keys = { "FREE-KEY" }, PremiumKeys = { "VIP-KEY" },
--     Validate = function(key) return key == "x" and "premium" end, -- opsional (boleh HTTP)
--     GetKeyLink = "https://...", Note = "...", SaveKey = true, MaxAttempts = 5,
--     OnSuccess = function(key, tier) end,
-- })
-- if not ok then return end
function Library:KeySystem(cfg)
	cfg = cfg or {}
	local fileName = cfg.FileName or "key"
	local canSave = cfg.SaveKey ~= false

	local function finish(tier, key)
		if tier == "premium" then
			Library:SetPremium(true, true)
		end
		safe(cfg.OnSuccess, key, tier)
	end

	-- key tersimpan masih valid: lewati UI
	if canSave then
		local saved = readKey(fileName)
		if saved and saved ~= "" then
			local tier = checkKey(cfg, saved)
			if tier then
				finish(tier, saved)
				return true, saved, tier
			end
			deleteKey(fileName)
		end
	end

	local tracker = setmetatable({ _conns = {} }, WindowClass)
	local Gui = create("ScreenGui", {
		Name = "NebulaUI_KeySystem",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1001,
	})
	mountGui(Gui)

	local Dim = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Active = true,
		Parent = Gui,
	})
	-- dim layar hanya kalau diminta (Dim = true); default tanpa dim.
	-- Dim tetap Active supaya klik tidak tembus ke game.
	if cfg.Dim == true then
		tween(Dim, { BackgroundTransparency = cfg.DimTransparency or 0.6 }, EASE.Slow)
	end

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local CW = math.min(cfg.Width or 380, vp.X - 24)
	local CH = 300

	local Card = create("CanvasGroup", {
		Name = "KeyCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CW * 0.9, CH * 0.9),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = Gui,
	})
	corner(Card, 22)

	local Base = create("Frame", {
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = Theme.GlassAlpha,
		Parent = Card,
	})
	create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.GlassTop, Theme.GlassBottom),
		Parent = Base,
	})
	local Sheen = create("Frame", {
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Card,
	})
	create("UIGradient", {
		Rotation = 115,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.4, 0.97),
			NumberSequenceKeypoint.new(1, 0.99),
		}),
		Parent = Sheen,
	})

	-- logo
	local logoSrc = cfg.Icon
	local logo
	if logoSrc and isCustomImage(logoSrc) then
		logo = makeIcon(Card, logoSrc, 52, Color3.new(1, 1, 1), nil, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 22),
		})
		if logo then
			corner(logo, 14)
		end
	end
	if not logo then
		local Tile = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 22),
			Size = UDim2.fromOffset(52, 52),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Card,
		})
		corner(Tile, 16)
		local tg = create("UIGradient", {
			Rotation = 45,
			Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
			Parent = Tile,
		})
		bindAccent(function(a, b)
			tg.Color = ColorSequence.new(a, b)
		end)
		makeIcon(Tile, logoSrc or "lucide:key-round", 26, Color3.new(1, 1, 1), "K", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		})
	end

	create("TextLabel", {
		Position = UDim2.fromOffset(20, 84),
		Size = UDim2.new(1, -40, 0, 22),
		Text = cfg.Title or "Key System",
		TextSize = 17,
		Weight = "Bold",
		Parent = Card,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(20, 108),
		Size = UDim2.new(1, -40, 0, 32),
		Text = cfg.Subtitle or "Masukkan key untuk melanjutkan.",
		TextSize = 12,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = Card,
	})

	-- input
	local InputWrap = create("Frame", {
		Position = UDim2.fromOffset(20, 148),
		Size = UDim2.new(1, -40, 0, 40),
		BackgroundColor3 = Theme.Inset,
		BackgroundTransparency = 0.6,
		Parent = Card,
	})
	corner(InputWrap, 12)
	local ibs = stroke(InputWrap, Theme.Stroke, 1, 0.85)
	makeIcon(InputWrap, "lucide:key-round", 16, Theme.SubText, "K", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})
	local Box = create("TextBox", {
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = cfg.Placeholder or "Paste key di sini...",
		PlaceholderColor3 = Theme.SubText,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = InputWrap,
	})
	Box.Focused:Connect(function()
		tween(ibs, { Color = Theme.Accent, Transparency = 0 }, EASE.Fast)
	end)

	local Status = create("TextLabel", {
		Position = UDim2.fromOffset(20, 194),
		Size = UDim2.new(1, -40, 0, 16),
		TextSize = 11,
		Weight = "Bold",
		TextColor3 = Theme.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Card,
	})
	local function setStatus(text, color)
		Status.Text = text or ""
		Status.TextColor3 = color or Theme.SubText
	end

	-- tombol
	local link = cfg.GetKeyLink or cfg.Link
	local rowW = CW - 40
	local Row = create("Frame", {
		Position = UDim2.fromOffset(20, 218),
		Size = UDim2.new(1, -40, 0, 40),
		BackgroundTransparency = 1,
		Parent = Card,
	})
	listLayout(Row, 10, true)

	local fgOn = luma(Theme.Accent) > 0.62 and Color3.fromRGB(20, 22, 32) or Color3.new(1, 1, 1)
	local function makeBtn(text, icon, w, filled, order)
		local B = create("TextButton", {
			Size = UDim2.fromOffset(w, 40),
			BackgroundColor3 = filled and Color3.new(1, 1, 1) or Theme.Surface,
			BackgroundTransparency = filled and 0 or 0.88,
			LayoutOrder = order,
			Parent = Row,
		})
		corner(B, 12)
		stroke(B, Color3.new(1, 1, 1), 1, filled and 0.55 or 0.8)
		if filled then
			local g = create("UIGradient", {
				Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
				Parent = B,
			})
			bindAccent(function(a, b)
				g.Color = ColorSequence.new(a, b)
			end)
		end
		local Inner = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = B,
		})
		local il = listLayout(Inner, 6, true)
		il.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local fg = filled and fgOn or Theme.Text
		makeIcon(Inner, icon, 16, fg, nil, { LayoutOrder = 1 })
		create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = text,
			TextSize = 13,
			Weight = "Bold",
			TextColor3 = fg,
			TextStrokeTransparency = (filled and luma(Theme.Accent) > 0.62) and 1 or 0.62,
			LayoutOrder = 2,
			Parent = Inner,
		})
		if not filled then
			B.MouseEnter:Connect(function()
				tween(B, { BackgroundTransparency = 0.78 }, EASE.Fast)
			end)
			B.MouseLeave:Connect(function()
				tween(B, { BackgroundTransparency = 0.88 }, EASE.Fast)
			end)
		end
		return B
	end

	local btnW = link and math.floor((rowW - 10) / 2) or rowW
	local GetBtn = link and makeBtn("Get Key", "lucide:link", btnW, false, 1) or nil
	local VerifyBtn = makeBtn("Verify", "lucide:shield-check", btnW, true, 2)

	if cfg.Note then
		create("TextLabel", {
			Position = UDim2.fromOffset(20, 266),
			Size = UDim2.new(1, -40, 0, 22),
			Text = tostring(cfg.Note),
			TextSize = 10,
			Weight = "Regular",
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			Parent = Card,
		})
	end

	local Rim = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = Card,
	})
	corner(Rim, 22)
	local rs = stroke(Rim, Color3.new(1, 1, 1), 1.4, 0)
	create("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 0.62),
		}),
		Parent = rs,
	})

	-- state + logika
	local done, okResult, keyResult, tierResult = false, false, nil, nil
	local attempts = 0
	local busy = false
	local closing = false

	local function shutdown()
		if closing then
			return
		end
		closing = true
		tween(Card, {
			Size = UDim2.fromOffset(CW * 0.92, CH * 0.92),
			GroupTransparency = 1,
		}, EASE.Smooth)
		tween(Dim, { BackgroundTransparency = 1 }, EASE.Smooth)
		task.delay(0.4, function()
			for _, c in ipairs(tracker._conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			Gui:Destroy()
		end)
	end

	local function shake()
		task.spawn(function()
			local p = Card.Position
			for _, dx in ipairs({ 10, -10, 6, -6, 0 }) do
				tween(Card, {
					Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset),
				}, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
				task.wait(0.05)
			end
		end)
	end

	local function verify()
		if busy or closing or done then
			return
		end
		local key = trimKey(Box.Text)
		if key == "" then
			setStatus("Key tidak boleh kosong.", Theme.Warning)
			shake()
			return
		end
		busy = true
		setStatus("Memeriksa key...", Theme.SubText)
		local tier = checkKey(cfg, key)
		busy = false
		if tier then
			setStatus(tier == "premium" and "Key premium valid!" or "Key valid!", Theme.Success)
			if canSave then
				writeKey(fileName, key)
			end
			done, okResult, keyResult, tierResult = true, true, key, tier
			busy = true
			finish(tier, key)
			task.delay(0.6, shutdown)
		else
			attempts += 1
			shake()
			local left = cfg.MaxAttempts and (cfg.MaxAttempts - attempts) or nil
			if left and left <= 0 then
				busy = true
				setStatus("Terlalu banyak percobaan.", Theme.Danger)
				safe(cfg.OnMaxAttempts, attempts)
				if cfg.KickOnFail then
					pcall(function()
						LocalPlayer:Kick(cfg.KickMessage or "Terlalu banyak percobaan key salah.")
					end)
				end
				task.delay(1.2, function()
					done = true
					shutdown()
				end)
			else
				setStatus(left and ("Key salah. Sisa percobaan: " .. left) or "Key salah.", Theme.Danger)
			end
			safe(cfg.OnWrong, key, attempts)
		end
	end

	VerifyBtn.MouseButton1Click:Connect(verify)
	Box.FocusLost:Connect(function(enter)
		tween(ibs, { Color = Theme.Stroke, Transparency = 0.85 }, EASE.Smooth)
		if enter then
			verify()
		end
	end)

	if GetBtn then
		GetBtn.MouseButton1Click:Connect(function()
			local clip = (typeof(setclipboard) == "function" and setclipboard)
				or (typeof(toclipboard) == "function" and toclipboard) or nil
			local copied = false
			if clip then
				copied = pcall(clip, tostring(link))
			end
			setStatus(copied and "Link disalin ke clipboard." or tostring(link),
				copied and Theme.Success or Theme.SubText)
			safe(cfg.OnGetKey, link)
		end)
	end

	if cfg.AllowClose ~= false then
		local Close = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Theme.Danger,
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = Card,
		})
		corner(Close, 9)
		local ci = makeIcon(Close, "lucide:x", 16, Theme.SubText, "x", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 6,
		})
		Close.MouseEnter:Connect(function()
			tween(Close, { BackgroundTransparency = 0.78 }, EASE.Fast)
			setIconColor(ci, Theme.Text, EASE.Fast)
		end)
		Close.MouseLeave:Connect(function()
			tween(Close, { BackgroundTransparency = 1 }, EASE.Fast)
			setIconColor(ci, Theme.SubText, EASE.Fast)
		end)
		Close.MouseButton1Click:Connect(function()
			if done then
				return
			end
			done = true
			shutdown()
			safe(cfg.OnClose)
		end)
	end

	makeDraggable(tracker, Card, Card)
	tween(Card, { Size = UDim2.fromOffset(CW, CH), GroupTransparency = 0 }, EASE.Spring)

	if cfg.Wait == false then
		return { Close = shutdown }
	end
	while not done and Gui.Parent do
		task.wait(0.1)
	end
	if not done then
		-- GUI dihapus dari luar (mis. script dieksekusi ulang): bersihkan dan jangan menggantung
		done, closing = true, true
		for _, c in ipairs(tracker._conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	return okResult, keyResult, tierResult
end

local function createDock(Window, Gui, dcfg, appIcon, appTitle)
	local touch = UserInputService.TouchEnabled
	local base = dcfg.IconSize or (touch and 38 or 46)
	local maxScale = touch and 1 or (dcfg.Magnify or 1.5)
	local barH = base + 20
	local range = base * 2.6
	local offset = dcfg.Offset or 12

	local Root = create("Frame", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -offset),
		Size = UDim2.new(0, 0, 0, barH),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = Theme.GlassAlpha,
		ZIndex = 40,
		Parent = Gui,
	})
	corner(Root, 24)
	create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.GlassTop, Theme.GlassBottom),
		Parent = Root,
	})
	local rim = stroke(Root, Color3.new(1, 1, 1), 1.2, 0)
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(0.5, 0.88),
			NumberSequenceKeypoint.new(1, 0.7),
		}),
		Parent = rim,
	})
	padding(Root, 10, 0, 10, 0)
	local rl = listLayout(Root, 2, true)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local items = {}
	local customOrder = 1000
	local colorIdx = 0
	local colorful = dcfg.Colorful ~= false
	local PALETTE = {
		Color3.fromHex("#0A84FF"), Color3.fromHex("#30D158"), Color3.fromHex("#BF5AF2"),
		Color3.fromHex("#FF375F"), Color3.fromHex("#64D2FF"), Color3.fromHex("#FF9F0A"),
		Color3.fromHex("#5E5CE6"), Color3.fromHex("#FFD60A"),
	}
	local function lighten(c, a)
		return Color3.new(c.R + (1 - c.R) * a, c.G + (1 - c.G) * a, c.B + (1 - c.B) * a)
	end
	local mouseX = 0
	local rootHover = false

	local function applySize(it)
		local sz = base * it.cur
		it.slot.Size = UDim2.fromOffset(sz + 6, barH)
		it.btn.Size = UDim2.fromOffset(sz, sz)
	end

	local function remove(it)
		for i, v in ipairs(items) do
			if v == it then
				table.remove(items, i)
				break
			end
		end
		it.slot:Destroy()
	end

	local function bounce(btn)
		tween(btn, { Position = UDim2.new(0.5, 0, 1, -26) },
			TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.delay(0.16, function()
			tween(btn, { Position = UDim2.new(0.5, 0, 1, -10) },
				TweenInfo.new(0.34, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out))
		end)
	end

	local function addItem(def, order)
		def = def or {}
		if not order then
			customOrder += 1
			order = customOrder
		end

		if def.Type == "Divider" then
			local d = create("Frame", {
				Size = UDim2.fromOffset(9, barH),
				BackgroundTransparency = 1,
				LayoutOrder = order,
				Parent = Root,
			})
			create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(0, 1, 0, base * 0.8),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
				Parent = d,
			})
			local it = { divider = true, slot = d }
			table.insert(items, it)
			return { Destroy = function() remove(it) end }
		end

		local title = tostring(def.Title or def.Name or "")
		local accentTile = def.Accent == true
		-- Bare: ikon gambar custom tampil penuh tanpa tile berwarna
		local bare = def.Bare == true and def.Icon ~= nil and resolveIcon(def.Icon) ~= ""
		if bare then
			accentTile = false
		end
		if def.Color == nil and not accentTile and not bare and colorful then
			colorIdx += 1
			def.Color = PALETTE[((colorIdx - 1) % #PALETTE) + 1]
		end
		local solid = typeof(def.Color) == "Color3" and not bare

		local slot = create("Frame", {
			Size = UDim2.fromOffset(base + 6, barH),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 1,
			Parent = Root,
		})
		local btn = create("TextButton", {
			Name = "Item",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.fromOffset(base, base),
			BackgroundColor3 = (solid or accentTile) and Color3.new(1, 1, 1) or Theme.Surface,
			BackgroundTransparency = bare and 1 or ((solid or accentTile) and 0 or 0.3),
			Text = "",
			Parent = slot,
		})
		create("UICorner", { CornerRadius = UDim.new(0.27, 0), Parent = btn })
		stroke(btn, Color3.new(1, 1, 1), 1, bare and 1 or 0.75)
		if solid then
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(lighten(def.Color, 0.28), def.Color),
				Parent = btn,
			})
		end
		if accentTile then
			local g = create("UIGradient", {
				Rotation = 45,
				Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
				Parent = btn,
			})
			bindAccent(function(a, b)
				g.Color = ColorSequence.new(a, b)
			end)
		end

		local colored = solid or accentTile
		local fg = Theme.Text
		if colored then
			fg = (solid and luma(def.Color) > 0.62) and Color3.fromRGB(20, 22, 32) or Color3.new(1, 1, 1)
		end
		local letter = string.upper(string.sub(title ~= "" and title or "?", 1, 1))
		local ic
		if def.Icon then
			-- gambar custom (assetid) jangan di-tint gelap, biar warna aslinya tampil
			local dockTint = def.IconColor or (isCustomImage(def.Icon) and Color3.new(1, 1, 1)) or fg
			ic = makeIcon(btn, def.Icon, 24, dockTint, letter, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = bare and UDim2.fromScale(1, 1) or UDim2.fromScale(0.56, 0.56),
			})
			if ic and bare then
				create("UICorner", { CornerRadius = UDim.new(0.27, 0), Parent = ic })
			end
		end
		if ic and ic:IsA("TextLabel") then
			ic.TextScaled = true
		end
		if not ic then
			create("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				Text = letter,
				TextScaled = true,
				Weight = "Bold",
				TextColor3 = fg,
				Parent = btn,
			})
		end

		local dot = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.fromOffset(4, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Parent = slot,
		})
		corner(dot, 999)

		local Tip = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -10),
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Glass,
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 20,
			Parent = btn,
		})
		corner(Tip, 8)
		local tipStroke = stroke(Tip, Color3.new(1, 1, 1), 1, 1)
		padding(Tip, 10, 0, 10, 0)
		local tipLabel = create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = title,
			TextSize = 12,
			Weight = "Bold",
			TextTransparency = 1,
			ZIndex = 21,
			Parent = Tip,
		})

		local it = { slot = slot, btn = btn, cur = 1, hover = false }
		table.insert(items, it)

		local function showTip(on)
			if title == "" then
				return
			end
			if on then
				Tip.Visible = true
			else
				task.delay(0.15, function()
					if not it.hover then
						Tip.Visible = false
					end
				end)
			end
			tween(Tip, { BackgroundTransparency = on and 0.1 or 1 }, EASE.Fast)
			tween(tipStroke, { Transparency = on and 0.7 or 1 }, EASE.Fast)
			tween(tipLabel, { TextTransparency = on and 0 or 1 }, EASE.Fast)
		end
		btn.MouseEnter:Connect(function()
			it.hover = true
			slot.ZIndex = 5
			showTip(true)
		end)
		btn.MouseLeave:Connect(function()
			it.hover = false
			slot.ZIndex = 1
			showTip(false)
		end)

		local api = {}
		function api:SetActive(v)
			it.active = v == true
			tween(dot, { BackgroundTransparency = v and 0.05 or 1 }, EASE.Smooth)
		end
		function api:SetTitle(t)
			title = tostring(t)
			tipLabel.Text = title
		end
		function api:Destroy()
			remove(it)
		end
		btn.MouseButton1Click:Connect(function()
			bounce(btn)
			safe(def.Callback, api)
		end)
		if def.Active then
			api:SetActive(true)
		end
		return api
	end

	Window:_track(UserInputService.InputChanged:Connect(function(input)
		if isMove(input) then
			mouseX = input.Position.X
		end
	end))
	Root.MouseEnter:Connect(function()
		rootHover = true
	end)
	Root.MouseLeave:Connect(function()
		rootHover = false
	end)
	local function isHot()
		if rootHover then
			return true
		end
		for _, it in ipairs(items) do
			if it.hover then
				return true
			end
		end
		return false
	end
	Window:_track(RunService.RenderStepped:Connect(function(dt)
		if maxScale <= 1 then
			return
		end
		local hot = isHot()
		local a = math.min(1, (dt or 0.016) * 16)
		for _, it in ipairs(items) do
			if not it.divider then
				local target = 1
				if hot then
					local pos = it.slot.AbsolutePosition or Vector2.new(0, 0)
					local size = it.slot.AbsoluteSize or Vector2.new(0, 0)
					local d = math.abs(mouseX - (pos.X + size.X / 2))
					if d < range then
						target = 1 + (maxScale - 1) * (0.5 + 0.5 * math.cos(math.pi * d / range))
					end
				end
				if math.abs(target - it.cur) > 0.002 then
					it.cur += (target - it.cur) * a
					applySize(it)
				end
			end
		end
	end))

	local Dock = { Root = Root, Items = items }
	local appItem
	local tabItems = {}
	local tabCount = 0

	function Dock:AddItem(def)
		return addItem(def)
	end
	function Dock:AddDivider()
		return addItem({ Type = "Divider" })
	end
	function Dock:SetVisible(v)
		tween(Root, { Position = UDim2.new(0.5, 0, 1, v and -offset or (barH + 30)) }, EASE.Smooth)
	end

	function Dock:_sync()
		if appItem then
			appItem:SetActive(Window._visible)
		end
		for tab, api in pairs(tabItems) do
			api:SetActive(Window._visible and Window._active == tab)
		end
	end

	function Dock:AddTab(tab, name, icon, color)
		if dcfg.Tabs == false then
			return
		end
		tabCount += 1
		tabItems[tab] = addItem({
			Title = name,
			Icon = icon,
			Color = color,
			Callback = function()
				Window:SelectTab(tab)
				if not Window._visible then
					Window:SetVisible(true)
				elseif Window._minimized then
					Window:Collapse()
				end
			end,
		}, 100 + tabCount)
		self:_sync()
	end

	if dcfg.App ~= false then
		appItem = addItem({
			Title = appTitle or "Nebula UI",
			Icon = appIcon or "lucide:sparkles",
			Accent = true,
			Bare = appIcon ~= nil, -- logo custom tampil penuh tanpa tile accent
			Callback = function()
				Window:Toggle()
			end,
		}, 1)
		addItem({ Type = "Divider" }, 2)
	end
	if dcfg.Items and #dcfg.Items > 0 then
		addItem({ Type = "Divider" }, 999)
		for _, def in ipairs(dcfg.Items) do
			addItem(def)
		end
	end
	Dock:_sync()
	return Dock
end

local TOP_H = 46

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then
		Theme.Accent = cfg.Accent
	end
	if cfg.Accent2 then
		Theme.Accent2 = cfg.Accent2
	end
	FamilyAsset = resolveFamily(cfg.Font or "Mono")
	if type(cfg.GlassAlpha) == "number" then
		Theme.GlassAlpha = math.clamp(cfg.GlassAlpha, 0, 1)
	end
	local TOP_H = (cfg.Topbar and tonumber(cfg.Topbar.Height)) or 46
	local macStyle = cfg.Topbar ~= nil and cfg.Topbar.ButtonsType == "Mac"
	if cfg.Folder then
		Library:SetFolder(cfg.Folder)
	end

	local Window = setmetatable({
		Tabs = {},
		_conns = {},
		_visible = true,
		_minimized = false,
		_active = nil,
	}, WindowClass)

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local W = math.min(cfg.Width or 640, vp.X - 24)
	local H = math.min(cfg.Height or 420, vp.Y - 24)
	local sideW = W < 540 and 132 or 172
	Window._curH = H

	local Gui = create("ScreenGui", {
		Name = "NebulaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	mountGui(Gui)
	Window.Gui = Gui

	local Main = create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W * 0.9, H * 0.9),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = Gui,
	})
	corner(Main, 18)
	Window.Main = Main

	local GlassBase = create("Frame", {
		Name = "GlassBase",
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = Theme.GlassAlpha,
		Parent = Main,
	})
	create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.GlassTop, Theme.GlassBottom),
		Parent = GlassBase,
	})
	local Sheen = create("Frame", {
		Name = "Sheen",
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Main,
	})
	create("UIGradient", {
		Rotation = 115,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.4, 0.97),
			NumberSequenceKeypoint.new(1, 0.99),
		}),
		Parent = Sheen,
	})


	local BgFrame = create("Frame", {
		Name = "Background",
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Main,
	})
	local BgImage = create("ImageLabel", {
		Name = "ImageLabel",
		ZIndex = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		ImageTransparency = 0.5,
		Visible = false,
		Parent = BgFrame,
	})
	Window.UIElements = { Main = Main, Background = BgFrame }
	Window.BackgroundImageTransparency = 0.5

	function Window:SetBackgroundImage(image)
		local asset = imageAsset(image)
		BgImage.Image = asset
		BgImage.Visible = asset ~= ""
	end

	function Window:SetBackgroundImageTransparency(t)
		t = math.clamp(tonumber(t) or 0.5, 0, 1)
		t = math.floor(t * 10 + 0.5) / 10
		BgImage.ImageTransparency = t
		self.BackgroundImageTransparency = t
	end

	if cfg.BackgroundImageTransparency ~= nil then
		Window:SetBackgroundImageTransparency(cfg.BackgroundImageTransparency)
	end
	if cfg.Background ~= nil then
		Window:SetBackgroundImage(cfg.Background)
	end

	local blurSize = cfg.Blur == false and 0 or (cfg.BlurSize or 16)
	local Blur = Instance.new("BlurEffect")
	Blur.Name = "NebulaBlur"
	Blur.Size = 0
	pcall(function()
		local old = Lighting:FindFirstChild("NebulaBlur")
		if old then
			old:Destroy()
		end
		Blur.Parent = Lighting
	end)
	function Window:_setBlur(on)
		tween(Blur, { Size = on and blurSize or 0 }, EASE.Slow)
	end

	local TopBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, TOP_H),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.92,
		Parent = Main,
	})

	local MinBtn, CloseBtn, MaxBtn
	local leftX = 14
	if macStyle then
		leftX = 88
		local glyphs = {}
		local function dot(color, x, glyph)
			local b = create("TextButton", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, x, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = color,
				BackgroundTransparency = 0,
				Parent = TopBar,
			})
			corner(b, 999)
			local g = create("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Text = glyph,
				TextSize = 11,
				Weight = "Bold",
				TextColor3 = Color3.fromRGB(80, 30, 20),
				TextTransparency = 1,
				Parent = b,
			})
			table.insert(glyphs, g)
			return b
		end
		CloseBtn = dot(Color3.fromRGB(255, 95, 86), 14, "×")
		MinBtn = dot(Color3.fromRGB(255, 189, 46), 36, "–")
		MaxBtn = dot(Color3.fromRGB(39, 201, 63), 58, "+")
		for _, b in ipairs({ CloseBtn, MinBtn, MaxBtn }) do
			b.MouseEnter:Connect(function()
				for _, g in ipairs(glyphs) do
					tween(g, { TextTransparency = 0 }, EASE.Fast)
				end
			end)
			b.MouseLeave:Connect(function()
				for _, g in ipairs(glyphs) do
					tween(g, { TextTransparency = 1 }, EASE.Fast)
				end
			end)
		end
	else
		local function topButton(iconName, fallback, xOffset, hoverColor)
			local b = create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, xOffset, 0.5, 0),
				Size = UDim2.fromOffset(30, 30),
				BackgroundColor3 = hoverColor,
				BackgroundTransparency = 1,
				Parent = TopBar,
			})
			corner(b, 9)
			local ic = makeIcon(b, iconName, 16, Theme.SubText, fallback, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			})
			b.MouseEnter:Connect(function()
				tween(b, { BackgroundTransparency = 0.78 }, EASE.Fast)
				setIconColor(ic, Theme.Text, EASE.Fast)
			end)
			b.MouseLeave:Connect(function()
				tween(b, { BackgroundTransparency = 1 }, EASE.Fast)
				setIconColor(ic, Theme.SubText, EASE.Fast)
			end)
			return b
		end
		MinBtn = topButton("lucide:minus", "-", -46, Theme.Accent)
		CloseBtn = topButton("lucide:x", "x", -12, Theme.Danger)
	end

	-- LOGO: tanpa kotak gradient di belakang kalau ada Icon custom
	local Logo = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, leftX, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, -- default transparan, tanpa background
		Parent = TopBar,
	})
	corner(Logo, 9)
	local logoGrad = create("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
		Enabled = false, -- hanya aktif kalau tidak ada ikon
		Parent = Logo,
	})
	bindAccent(function(a, b)
		logoGrad.Color = ColorSequence.new(a, b)
	end)

	-- ikon custom memenuhi seluruh area logo, warna aslinya tidak diubah
	local logoIcon = cfg.Icon and makeIcon(Logo, cfg.Icon, 28, Color3.new(1, 1, 1), nil, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	if logoIcon then
		corner(logoIcon, 9) -- opsional: hapus baris ini kalau tidak mau sudut membulat
	else
		-- fallback: tidak ada ikon, pakai kotak gradient + huruf pertama judul
		Logo.BackgroundTransparency = 0
		logoGrad.Enabled = true
		create("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = string.upper(string.sub(cfg.Title or "N", 1, 1)),
			TextSize = 15,
			Weight = "Heavy",
			TextColor3 = Color3.new(1, 1, 1),
			Parent = Logo,
		})
	end

	local Left = create("Frame", {
		Name = "Left",
		Position = UDim2.fromOffset(leftX + 38, 0),
		Size = UDim2.new(1, -(leftX + 38 + (macStyle and 14 or 100)), 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = TopBar,
	})
	listLayout(Left, 10, true)
	local TitleBlock = create("Frame", {
		Size = UDim2.new(0, 0, 0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = Left,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0, 0, 0, 17),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = cfg.Title or "Nebula UI",
		TextSize = 14,
		Weight = "Bold",
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TitleBlock,
	})
	create("TextLabel", {
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(0, 0, 0, 13),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = cfg.SubTitle or ("v" .. Library.Version),
		TextSize = 10,
		Weight = "Regular",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TitleBlock,
	})
	local Tags = create("Frame", {
		Size = UDim2.new(0, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = Left,
	})
	listLayout(Tags, 6, true)

	local tagCount = 0
	function Window:Tag(t)
		t = t or {}
		tagCount += 1
		local solid = typeof(t.Color) == "Color3"
		local bg = solid and t.Color or Theme.Surface
		local fg = (solid and luma(bg) > 0.62) and Color3.fromRGB(20, 22, 32) or Color3.new(1, 1, 1)
		local Pill = create("Frame", {
			Size = UDim2.new(0, 0, 0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = bg,
			BackgroundTransparency = solid and 0 or 0.85,
			LayoutOrder = tagCount,
			Parent = Tags,
		})
		corner(Pill, 8)
		if t.Border then
			stroke(Pill, Theme.Stroke, 1, 0.7)
		end
		padding(Pill, 8, 0, 9, 0)
		listLayout(Pill, 5, true)
		if t.Icon then
			-- gambar custom: warna asli (putih = tanpa tint); ikon library: ikut kontras
			local tagTint = t.IconColor or (isCustomImage(t.Icon) and Color3.new(1, 1, 1)) or fg
			makeIcon(Pill, t.Icon, 12, tagTint, nil, { LayoutOrder = 1 })
		end
		local Label = create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = tostring(t.Title or "Tag"),
			TextSize = 10,
			Weight = "Bold",
			TextColor3 = fg,
			TextStrokeTransparency = (solid and luma(bg) > 0.62) and 1 or 0.62,
			LayoutOrder = 2,
			Parent = Pill,
		})
		local tag = {}
		function tag:SetTitle(v)
			Label.Text = tostring(v)
		end
		function tag:Destroy()
			Pill:Destroy()
		end
		return tag
	end
	for _, t in ipairs(cfg.Tags or {}) do
		Window:Tag(t)
	end

	create("Frame", {
		Position = UDim2.fromOffset(0, TOP_H),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.88,
		Parent = Main,
	})
	local Shine = create("Frame", {
		Position = UDim2.fromOffset(0, TOP_H),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Main,
	})
	local ShineGrad = create("UIGradient", {
		Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = Shine,
	})
	bindAccent(function(a, b)
		ShineGrad.Color = ColorSequence.new(a, b)
	end)
	tween(ShineGrad, { Offset = Vector2.new(1, 0) },
		TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true))

	local Body = create("CanvasGroup", {
		Name = "Body",
		Position = UDim2.fromOffset(0, TOP_H + 1),
		Size = UDim2.new(1, 0, 0, H - (TOP_H + 1)),
		BackgroundTransparency = 1,
		Parent = Main,
	})
	local Sidebar = create("Frame", {
		Size = UDim2.new(0, sideW, 1, 0),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.93,
		Parent = Body,
	})
	create("Frame", {
		Position = UDim2.fromOffset(sideW, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.88,
		Parent = Body,
	})

	local profileSpace = (cfg.User == nil or cfg.User.Enabled ~= false) and 64 or 10
	local searchOffset = 0
	local SearchInput
	if cfg.HideSearchBar ~= true then
		searchOffset = 48
		local SearchBox = create("Frame", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(1, -20, 0, 32),
			BackgroundColor3 = Theme.Inset,
			BackgroundTransparency = 0.62,
			Parent = Sidebar,
		})
		corner(SearchBox, 12)
		local sbs = stroke(SearchBox, Theme.Stroke, 1, 0.88)
		makeIcon(SearchBox, "lucide:search", 14, Theme.SubText, "?", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
		})
		SearchInput = create("TextBox", {
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(1, -40, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search",
			PlaceholderColor3 = Theme.SubText,
			ClearTextOnFocus = false,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = SearchBox,
		})
		SearchInput.Focused:Connect(function()
			tween(sbs, { Color = Theme.Accent, Transparency = 0 }, EASE.Fast)
		end)
		SearchInput.FocusLost:Connect(function()
			tween(sbs, { Color = Theme.Stroke, Transparency = 0.88 }, EASE.Smooth)
		end)
	end

	local TabList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, searchOffset),
		Size = UDim2.new(1, 0, 1, -(searchOffset + profileSpace)),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	})
	padding(TabList, 10, 6, 10, 6)
	listLayout(TabList, 4)
	Window._TabList = TabList

	local userCfg = cfg.User or {}
	local userEnabled = userCfg.Enabled ~= false
	local anonymous = userCfg.Anonymous == true
	if userEnabled then
		local Profile = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -20, 0, 44),
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 0.88,
			Parent = Sidebar,
		})
		corner(Profile, 14)
		stroke(Profile, Theme.Stroke, 1, 0.88)
		local Avatar = create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = Theme.Track,
			BackgroundTransparency = 0,
			Parent = Profile,
		})
		corner(Avatar, 999)
		accented(stroke(Avatar, Theme.Accent, 1.5, 0.2), "Color")
		local AvatarIcon = makeIcon(Avatar, "lucide:user", 16, Theme.SubText, "?", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Visible = false,
		})
		local NameLabel = create("TextLabel", {
			Position = UDim2.fromOffset(44, 6),
			Size = UDim2.new(1, -50, 0, 16),
			TextSize = 11,
			Weight = "Bold",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Profile,
		})
		local HandleLabel = create("TextLabel", {
			Position = UDim2.fromOffset(44, 22),
			Size = UDim2.new(1, -50, 0, 14),
			TextSize = 10,
			Weight = "Regular",
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Profile,
		})

		local thumb = nil
		local function applyUser()
			NameLabel.Text = anonymous and "Anonymous" or LocalPlayer.DisplayName
			HandleLabel.Text = anonymous and "@hidden" or ("@" .. LocalPlayer.Name)
			Avatar.Image = (not anonymous and thumb) or ""
			if AvatarIcon then
				AvatarIcon.Visible = anonymous or thumb == nil
			end
		end
		function Window:SetAnonymous(state)
			anonymous = state == true
			applyUser()
		end
		applyUser()

		Profile.MouseEnter:Connect(function()
			tween(Profile, { BackgroundTransparency = 0.8 }, EASE.Fast)
		end)
		Profile.MouseLeave:Connect(function()
			tween(Profile, { BackgroundTransparency = 0.88 }, EASE.Fast)
		end)
		Profile.MouseButton1Click:Connect(function()
			safe(userCfg.Callback)
		end)

		task.spawn(function()
			local ok, img = pcall(function()
				return Players:GetUserThumbnailAsync(
					LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok then
				thumb = img
				applyUser()
			end
		end)
	else
		function Window:SetAnonymous() end
	end

	local Content = create("Frame", {
		Position = UDim2.fromOffset(sideW + 1, 0),
		Size = UDim2.new(1, -(sideW + 1), 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Body,
	})
	padding(Content, 14, 10, 8, cfg.Footer and 26 or 12)
	Window._Content = Content

	if cfg.Footer then
		create("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -8),
			Size = UDim2.fromOffset(260, 14),
			Text = cfg.Footer,
			TextSize = 10,
			Weight = "Regular",
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
			Parent = Body,
		})
	end

	local Rim = create("Frame", {
		Name = "Rim",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = Main,
	})
	corner(Rim, 18)
	local RimStroke = stroke(Rim, Color3.new(1, 1, 1), 1.4, 0)
	create("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 0.62),
		}),
		Parent = RimStroke,
	})


	makeDraggable(Window, TopBar, Main)

	function Window:SetVisible(state)
		self._visible = state
		self:_setBlur(state)
		if self.Dock then
			self.Dock:_sync()
		end
		if self._setOpenBtn then
			self._setOpenBtn(not state)
		end
		if state then
			Main.Visible = true
			Main.Size = UDim2.fromOffset(W * 0.92, self._curH * 0.92)
			tween(Main, { Size = UDim2.fromOffset(W, self._curH), GroupTransparency = 0 }, EASE.Spring)
		else
			tween(Main, {
				Size = UDim2.fromOffset(W * 0.92, self._curH * 0.92),
				GroupTransparency = 1,
			}, EASE.Smooth)
			task.delay(0.3, function()
				if not self._visible then
					Main.Visible = false
				end
			end)
		end
	end

	function Window:Toggle()
		self:SetVisible(not self._visible)
	end


	function Window:Minimize()
		local mode = cfg.Topbar and cfg.Topbar.MinimizeMode
		local canRestore = self._setOpenBtn ~= nil or self.Dock ~= nil
		if mode ~= "Collapse" and canRestore and not self._minimized then
			self:SetVisible(not self._visible)
			return
		end
		self:Collapse()
	end

	function Window:Collapse()
		self._minimized = not self._minimized
		self:_setBlur(not self._minimized)
		local newH = self._minimized and TOP_H + 1 or H
		local dh = newH - self._curH
		self._curH = newH
		local p = Main.Position
		if self._minimized then
			tween(Body, { GroupTransparency = 1 }, EASE.Fast)
			task.delay(0.15, function()
				if self._minimized then
					Body.Visible = false
				end
			end)
		else
			Body.Visible = true
			tween(Body, { GroupTransparency = 0 }, EASE.Smooth)
		end
		tween(Main, {
			Size = UDim2.fromOffset(W, newH),
			Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + dh / 2),
		}, EASE.Smooth)
	end

	function Window:Destroy()
		for _, c in ipairs(self._conns) do
			c:Disconnect()
		end
		self:_setBlur(false)
		tween(Main, {
			Size = UDim2.fromOffset(W * 0.88, self._curH * 0.88),
			GroupTransparency = 1,
		}, EASE.Smooth)
		task.delay(0.65, function()
			Gui:Destroy()
			Blur:Destroy()
		end)
	end

	function Window:SetGlassAlpha(a)
		Theme.GlassAlpha = math.clamp(tonumber(a) or Theme.GlassAlpha, 0, 1)
		tween(GlassBase, { BackgroundTransparency = Theme.GlassAlpha }, EASE.Smooth)
	end

	function Window:Notify(opts)
		Library:Notify(opts)
	end

	function Window:SetPremium(state, silent)
		Library:SetPremium(state, silent)
	end

	function Window:IsPremium()
		return Library:IsPremium()
	end

	function Window:ActivatePremium(key, pcfg)
		return Library:ActivatePremium(key, pcfg)
	end

	function Window:SetAccent(a, b)
		Library:SetAccent(a, b)
	end

	local origW, origH = W, H
	local maximized = false
	function Window:ToggleMaximize()
		if self._minimized then
			return
		end
		maximized = not maximized
		local camNow = workspace.CurrentCamera
		local vpNow = camNow and camNow.ViewportSize or vp
		if maximized then
			W, H = math.max(origW, vpNow.X - 48), math.max(origH, vpNow.Y - 48)
		else
			W, H = origW, origH
		end
		self._curH = H
		Body.Size = UDim2.new(1, 0, 0, H - (TOP_H + 1))
		tween(Main, { Size = UDim2.fromOffset(W, H), Position = UDim2.fromScale(0.5, 0.5) }, EASE.Smooth)
	end

	MinBtn.MouseButton1Click:Connect(function()
		Window:Minimize()
	end)
	CloseBtn.MouseButton1Click:Connect(function()
		if cfg.Topbar and cfg.Topbar.HideOnClose then
			Window:SetVisible(false)
		else
			Window:Destroy()
		end
	end)
	if MaxBtn then
		MaxBtn.MouseButton1Click:Connect(function()
			Window:ToggleMaximize()
		end)
	end

	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	Window:_track(UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == toggleKey then
			Window:Toggle()
		end
	end))

	local ob = cfg.OpenButton or {}
	local obEnabled = ob.Enabled ~= false and cfg.FloatingButton ~= false
	if ob.OnlyMobile == true and not UserInputService.TouchEnabled then
		obEnabled = false
	end
	if obEnabled then
		-- default: glass ala iOS (sama dengan window). Warna solid hanya kalau Style = "Solid"
		local solid = ob.Style == "Solid"
		local colSeq
		if solid then
			colSeq = typeof(ob.Color) == "ColorSequence" and ob.Color or ColorSequence.new(Theme.Accent, Theme.Accent2)
		else
			colSeq = ColorSequence.new(Theme.GlassTop, Theme.GlassBottom)
		end
		local first = (colSeq.Keypoints and colSeq.Keypoints[1] and colSeq.Keypoints[1].Value) or Theme.Accent
		local fg = (solid and luma(first) > 0.62) and Color3.fromRGB(20, 22, 32) or Color3.new(1, 1, 1)

		local OpenBtn = create("TextButton", {
			Name = "OpenButton",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 16),
			Size = UDim2.new(0, 0, 0, 42),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = solid and 0 or (ob.GlassAlpha or 0.18),
			Visible = false,
			ZIndex = 50,
			Parent = Gui,
		})
		create("UICorner", { CornerRadius = ob.CornerRadius or UDim.new(1, 0), Parent = OpenBtn })
		create("UIGradient", { Color = colSeq, Parent = OpenBtn })
		local thickness = ob.StrokeThickness
		if thickness == nil then
			thickness = solid and 2 or 1.2
		end
		if thickness > 0 then
			local rimStroke = stroke(OpenBtn, Color3.new(1, 1, 1), thickness, solid and 0.55 or 0)
			if not solid then
				-- kilau tepi ala iOS glass
				create("UIGradient", {
					Rotation = 45,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.4),
						NumberSequenceKeypoint.new(0.5, 0.9),
						NumberSequenceKeypoint.new(1, 0.62),
					}),
					Parent = rimStroke,
				})
			end
		end
		padding(OpenBtn, 18, 0, 20, 0)
		local pl = listLayout(OpenBtn, 8, true)
		pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local obIcon = ob.Icon or cfg.Icon
		if obIcon then
			local custom = isCustomImage(obIcon)
			-- gambar custom: putih = warna asli tidak berubah
			-- ikon library: ikut kontras tombol
			local tint = ob.IconColor or (custom and Color3.new(1, 1, 1)) or fg
			-- ukuran default: logo custom hampir memenuhi tinggi tombol (42), ikon library sedikit lebih kecil
			local iconSize = ob.IconSize or (custom and 30 or 20)
			local obImg = makeIcon(OpenBtn, obIcon, iconSize, tint, nil, { LayoutOrder = 1 })
			if obImg and custom then
				corner(obImg, math.floor(iconSize * 0.25)) -- sudut membulat proporsional
			end
		end
		create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = ob.Title or (cfg.Title or "Open UI"),
			TextSize = 13,
			Weight = "Bold",
			TextColor3 = fg,
			TextStrokeTransparency = luma(fg) < 0.5 and 1 or 0.62,
			LayoutOrder = 2,
			Parent = OpenBtn,
		})
		local obScale = ob.Scale or 1
		local sc = create("UIScale", { Scale = 0, Parent = OpenBtn })

		Window._setOpenBtn = function(show)
			if show then
				OpenBtn.Visible = true
				sc.Scale = 0
				tween(sc, { Scale = obScale }, EASE.Spring)
			else
				tween(sc, { Scale = 0 }, EASE.Fast)
				task.delay(0.15, function()
					if Window._visible then
						OpenBtn.Visible = false
					end
				end)
			end
		end

		local dragging, moved, dStart, dPos = false, false, nil, nil
		OpenBtn.InputBegan:Connect(function(input)
			if isPointer(input) then
				dragging = ob.Draggable ~= false
				moved = false
				dStart = input.Position
				dPos = OpenBtn.Position
			end
		end)
		Window:_track(UserInputService.InputChanged:Connect(function(input)
			if dragging and dStart and isMove(input) then
				local d = input.Position - dStart
				if math.abs(d.X) + math.abs(d.Y) > 8 then
					moved = true
				end
				if moved then
					OpenBtn.Position = UDim2.new(
						dPos.X.Scale, dPos.X.Offset + d.X,
						dPos.Y.Scale, dPos.Y.Offset + d.Y
					)
				end
			end
		end))
		Window:_track(UserInputService.InputEnded:Connect(function(input)
			if isPointer(input) then
				dragging = false
			end
		end))
		OpenBtn.MouseButton1Click:Connect(function()
			if moved then
				moved = false
				return
			end
			Window:SetVisible(true)
		end)
	end

	local dcfg = cfg.Dock
	if dcfg == true then
		dcfg = {}
	end
	if type(dcfg) == "table" and dcfg.Enabled ~= false then
		Window.Dock = createDock(Window, Gui, dcfg, cfg.Icon, cfg.Title)
	end

	Main.Visible = true
	tween(Main, { Size = UDim2.fromOffset(W, H), GroupTransparency = 0 }, EASE.Spring)
	Window:_setBlur(true)


	function Window:CreateTab(name, icon, dockColor)
		local Tab = setmetatable({ _window = self, _order = 0, Name = name, _titles = {} }, Elements)
		Tab._tab = Tab

		local Btn = create("TextButton", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Accent,
			Accent = "BackgroundColor3",
			BackgroundTransparency = 1,
			LayoutOrder = #self.Tabs + 1,
			Parent = self._TabList,
		})
		corner(Btn, 12)
		local Bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(3, 0),
			BackgroundColor3 = Theme.Accent,
			Accent = "BackgroundColor3",
			Parent = Btn,
		})
		corner(Bar, 3)

		local Icon = icon and makeIcon(Btn, icon, 18, Theme.SubText, nil, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
		})
		if not Icon then
			Icon = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 17, 0.5, 0),
				Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = Theme.SubText,
				Parent = Btn,
			})
			corner(Icon, 999)
		end
		local function iconColor(c)
			if Icon:IsA("ImageLabel") then
				tween(Icon, { ImageColor3 = c }, EASE.Smooth)
			else
				tween(Icon, { BackgroundColor3 = c }, EASE.Smooth)
			end
		end

		bindAccent(function(c)
			if self._active == Tab then
				iconColor(c)
			end
		end)

		local Label = create("TextLabel", {
			Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -46, 1, 0),
			Text = name,
			TextSize = 12,
			Weight = "Bold",
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Btn,
		})

		local Page = create("CanvasGroup", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			Parent = self._Content,
		})
		local Head = create("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Parent = Page,
		})
		local hx = 4
		if icon then
			local hi = makeIcon(Head, icon, 20, Theme.Accent, nil, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 4, 0.5, 0),
			})
			if hi then
				hx = 34
				accentIcon(hi)
			end
		end
		create("TextLabel", {
			Position = UDim2.fromOffset(hx, 0),
			Size = UDim2.new(1, -(hx + 4), 1, 0),
			Text = name,
			TextSize = 16,
			Weight = "Bold",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Head,
		})
		create("Frame", {
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Stroke,
			BackgroundTransparency = 0.88,
			Parent = Head,
		})

		local Scroll = create("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 48),
			Size = UDim2.new(1, 0, 1, -48),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			Accent = "ScrollBarImageColor3",
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = Page,
		})
		padding(Scroll, 1, 1, 8, 6)
		listLayout(Scroll, 10)
		Tab._parent = Scroll

		function Tab:_select()
			Page.Visible = true
			Page.Position = UDim2.fromOffset(0, 18)
			Page.GroupTransparency = 1
			tween(Page, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, EASE.Smooth)
			tween(Btn, { BackgroundTransparency = 0.8 }, EASE.Smooth)
			tween(Bar, { Size = UDim2.fromOffset(3, 18) }, EASE.Spring)
			tween(Label, { TextColor3 = Theme.Text }, EASE.Smooth)
			iconColor(Theme.Accent)
		end
		function Tab:_deselect()
			Page.Visible = false
			tween(Btn, { BackgroundTransparency = 1 }, EASE.Smooth)
			tween(Bar, { Size = UDim2.fromOffset(3, 0) }, EASE.Smooth)
			tween(Label, { TextColor3 = Theme.SubText }, EASE.Smooth)
			iconColor(Theme.SubText)
		end

		Btn.MouseEnter:Connect(function()
			if self._active ~= Tab then
				tween(Btn, { BackgroundTransparency = 0.94 }, EASE.Fast)
			end
		end)
		Btn.MouseLeave:Connect(function()
			if self._active ~= Tab then
				tween(Btn, { BackgroundTransparency = 1 }, EASE.Fast)
			end
		end)
		Btn.MouseButton1Click:Connect(function()
			self:SelectTab(Tab)
		end)

		Tab._btn = Btn
		table.insert(self.Tabs, Tab)
		if self.Dock then
			self.Dock:AddTab(Tab, name, icon, dockColor)
		end
		if not self._active then
			self:SelectTab(Tab)
		end
		return Tab
	end

	function Window:SelectTab(tab)
		if self._active == tab then
			return
		end
		if self._active then
			self._active:_deselect()
		end
		self._active = tab
		tab:_select()
		if self.Dock then
			self.Dock:_sync()
		end
	end

	if SearchInput then
		local function applySearch()
			local q = SearchInput.Text or ""
			q = q:gsub("^%s+", "")
			q = q:gsub("%s+$", "")
			q = string.lower(q)
			for _, tab in ipairs(Window.Tabs) do
				local show = q == ""
				if not show then
					show = string.find(string.lower(tab.Name), q, 1, true) ~= nil
					if not show then
						for _, t in ipairs(tab._titles) do
							if string.find(t, q, 1, true) then
								show = true
								break
							end
						end
					end
				end
				tab._btn.Visible = show
			end
		end
		SearchInput:GetPropertyChangedSignal("Text"):Connect(applySearch)
		SearchInput.FocusLost:Connect(function(enter)
			if enter then
				for _, tab in ipairs(Window.Tabs) do
					if tab._btn.Visible then
						Window:SelectTab(tab)
						break
					end
				end
			end
		end)
	end


	function Window:_destroyNow()
		for _, c in ipairs(self._conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		self._conns = {}
		pcall(function()
			Gui:Destroy()
		end)
		pcall(function()
			Blur:Destroy()
		end)
	end
	pcall(function()
		local env = (typeof(getgenv) == "function" and getgenv()) or _G
		local prev = env.__NebulaUI_Last
		if type(prev) == "function" then
			pcall(prev)
		end
		env.__NebulaUI_Last = function()
			Window:_destroyNow()
		end
	end)

	Window.ConfigManager = {
		CreateConfig = function(_, name)
			return {
				Save = function() return Library:SaveConfig(name) end,
				Load = function() return Library:LoadConfig(name) end,
				Delete = function() return Library:DeleteConfig(name) end,
			}
		end,
		AllConfigs = function() return Library:ListConfigs() end,
	}

	return Window
end

return Library
