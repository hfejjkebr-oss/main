# MaruX Library V2.0

A lightweight Roblox GUI Library for PC & Mobile.

## Preview

![MaruX Library Preview](./IMG_20260927_152354_533.jpg)

## How to Use

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hfejjkebr-oss/main/refs/heads/main/MaruX_LibraryV2.0.lua"
))()

Library:SetTheme({
    Accent = Color3.fromRGB(0, 210, 210),
    Background = Color3.fromRGB(12, 17, 22),
})

local Window = Library:CreateWindow({
    Title = "Maru x Hub",
    Version = "Version: 268",
    Logo = "rbxassetid://125484418530410",
})

local MainTab = Window:AddTab("Main")

MainTab:AddButton({
    Name = "Test Button",
    Callback = function()
        Library:Notify({
            Title = "MaruX",
            Message = "Hello!",
            Type = "success",
            Duration = 3,
        })
    end,
})

Library:AddMobileToggle(
    Window,
    "rbxassetid://125484418530410"
)
