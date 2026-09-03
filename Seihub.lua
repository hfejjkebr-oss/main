getgenv().SCRIPT_KEY = "KEYLESS"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

local API_SCRIPTS = {
    [2753915549] = {
        Name = "Blox Fruits",
        URL = "https://api.jnkie.com/api/v1/luascripts/public/e23e752f9b9413c0ef900d5a8e3f28d6983007d5521dddaed6282004840604c1/download",
        Keyless = true
    },

    [73504898027860] = {
        Name = "Grow a Garden",
        URL = "https://api.jnkie.com/api/v1/luascripts/public/142ace4536e8cfc1adf90a15db247fafb625b9791d1dcec3d89ebaafe41c395e/download",
        Keyless = true
    }
}

local function Notify(Text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SEI Hub",
            Text = Text,
            Icon = "rbxassetid://99118312841228",
            Duration = 5
        })
    end)
end

local ScriptData = API_SCRIPTS[PlaceId]

if ScriptData then
    Notify("Loading " .. ScriptData.Name .. "...")

    if ScriptData.Keyless then
        getgenv().SCRIPT_KEY = "KEYLESS"
    end

    local Success, Error = pcall(function()
        local Source = game:HttpGet(ScriptData.URL)

        if not Source or Source == "" then
            error("Failed to download the script")
        end

        local Loader = loadstring(Source)

        if not Loader then
            error("Failed to load the script")
        end

        Loader()
    end)

    if Success then
        Notify(ScriptData.Name .. " loaded successfully!")
    else
        Notify("Failed to load the script")
        warn("[SEI Hub] " .. tostring(Error))
    end
else
    Notify("This game is not supported")

    task.wait(2)

    pcall(function()
        Player:Kick("This game is not supported by SEI Hub")
    end)
end
