-- Motion Core UI adapter | Build the Pyramid
-- Keeps Motion Core branding while using the selected UI foundation.
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

local source = httpGet(SOURCE)
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
    options.Theme = options.Theme or "Star Road"
    options.Language = options.Language or "EN"
    options.WatermarkTitle = options.WatermarkTitle or "Motion Core"
    options.Assets = options.Assets or {}
    options.Assets.logo = options.Assets.logo or LOGO
    return originalCreateWindow(self, options)
end

Library.MotionCore = {
    Name = "Motion Core",
    Game = "Build the Pyramid",
    Theme = "Star Road",
    Logo = LOGO,
    Source = SOURCE,
}

return Library
