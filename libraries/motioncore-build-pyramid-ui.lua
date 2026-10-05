-- Motion Core UI adapter | Build the Pyramid
-- Runtime adapter for the selected UI foundation.
local SOURCE = "https://raw.githubusercontent.com/xDTaraZz/Roblox-Scripts/refs/heads/main/ui.lua"
local LOGO = "https://raw.githubusercontent.com/revan9868/assets-motioncore/main/LOGO%20MOTIONCORE.png"

local function httpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end

    local requester = request or http_request or (syn and syn.request) or (http and http.request)
    if type(requester) == "function" then
        local sent, response = pcall(requester, { Url = url, Method = "GET" })
        if sent and type(response) == "table" and type(response.Body) == "string" then
            return response.Body
        end
    end

    error("[Motion Core] UI library download failed.", 0)
end

local function replacePlain(text, from, to)
    local first = text:find(from, 1, true)
    if not first then
        return text, false
    end
    return text:sub(1, first - 1) .. to .. text:sub(first + #from), true
end

local source = httpGet(SOURCE)

-- Keep the selected layout/animations, but remove visible upstream branding.
source = source:gsub("Mario Hub", "Motion Core")
source = source:gsub("MarioHub", "MotionCore")
source = source:gsub("mariohub", "motioncore")
source = source:gsub("Mario", "MotionCore")

source = replacePlain(
    source,
    "https://raw.githubusercontent.com/xDTaraZz/Roblox-Scripts/main/logo.png",
    LOGO
)

source = replacePlain(
    source,
    'TitleColors = { "Accent", "Coin", "Good", "Blue" },',
    'TitleColors = { "Accent", "SidebarText", "Accent", "SidebarMuted" },'
)

local motionTheme = [[
    MotionCore = Palette({
        Backdrop = "0B0714", BackdropAlt = "130B22", Topbar = "160D2B", TopbarText = "F8F5FF",
        Sidebar = "120A22", SidebarAlt = "0B0617", SidebarText = "F5EEFF", SidebarMuted = "A996C6",
        TabActive = "7C3AED", TabActiveText = "FFFFFF",
        Panel = "151022", PanelHeader = "1D1530", Element = "201831", Hover = "2B2040",
        Outline = "4C1D95", Shadow = "050308", Text = "F7F2FF", SubText = "C1B3D6",
        Muted = "8D7AA8", Track = "35264F",
        Cloud = "FFFFFF", CloudAlpha = 1,
        Accent = "8B5CF6", AccentDark = "6D28D9",
        Blue = "8B5CF6", BlueDark = "6D28D9", Good = "8B5CF6", GoodDark = "6D28D9",
        Coin = "C4B5FD", CoinDark = "7C3AED", Risky = "A78BFA", RiskyDark = "6D28D9",
        Grass = "8B5CF6", GrassDark = "5B21B6",
        Brick = "2B1748", BrickDark = "160B29",
        Decor = { "Stars", "✦", "C4B5FD" },
        Particle = { "✦", false, "A78BFA" },
    }),
]]

source = source:gsub(
    'Order = %b{}',
    'Order = { "MotionCore", "Dark", "Light" }',
    1
)

if not source:find("MotionCore = Palette", 1, true) then
    source = source:gsub(
        "    Overworld = Palette%(%{",
        motionTheme .. "    Overworld = Palette({",
        1
    )
end

source = replacePlain(source, 'State.ThemeName = "Overworld"', 'State.ThemeName = "MotionCore"')
source = replacePlain(source, 'name = "Overworld"', 'name = "MotionCore"')
source = replacePlain(source, 'Theme.Apply(options.Theme or "Overworld")', 'Theme.Apply(options.Theme or "MotionCore")')
source = replacePlain(source, 'Float.Sprite = Sprite.New(Float.Slot, "qblock", Float.Size)', 'Float.Sprite = Draw.Emblem(Float.Slot, Float.Size)')
source = replacePlain(source, 'local icon = Sprite.New(field, "boo", 12)', 'local icon = Sprite.New(field, "star", 12)')

local chunk, compileError = loadstring(source)
if not chunk then
    error("[Motion Core] UI library compile failed: " .. tostring(compileError), 0)
end

local ok, Library = pcall(chunk)
if not ok or type(Library) ~= "table" then
    error("[Motion Core] UI library initialization failed: " .. tostring(Library), 0)
end

local originalCreateWindow = Library.CreateWindow

function Library:CreateWindow(options)
    options = options or {}
    options.Title = options.Title or "Motion Core"
    options.SubTitle = options.SubTitle or "Build the Pyramid"
    options.Theme = options.Theme or "MotionCore"
    options.Language = options.Language or "EN"
    options.WatermarkTitle = options.WatermarkTitle or "Motion Core"
    options.Assets = options.Assets or {}
    options.Assets.logo = options.Assets.logo or LOGO
    return originalCreateWindow(self, options)
end

Library.MotionCore = {
    Name = "Motion Core",
    Game = "Build the Pyramid",
    Theme = "MotionCore",
    Logo = LOGO,
    Source = SOURCE,
}

return Library
