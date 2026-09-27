local Library = loadstring(game:HttpGet'https://pastefy.app/ABlU0ctl/raw')()

Library:SetTheme({
    Accent     = Color3.fromRGB(0, 210, 210),
    Background = Color3.fromRGB(12, 17, 22),
})

local Window = Library:CreateWindow({
    Title   = "Maru x Hub",
    Version = "Version: 268",
    Logo    = "rbxassetid://74130845694007",
})

local MainTab = Window:AddTab("Main")

MainTab:AddSection("Teleport")

local tpToggle = MainTab:AddToggle({
    Name    = "Start / Stop TP",
    Default = false,
    Callback = function(state)
        print("TP:", state)
    end,
})

MainTab:AddToggle({
    Name    = "Spectate Player",
    Default = false,
    Callback = function(state)
        print("Spectate:", state)
    end,
})

local iceBtn = MainTab:AddButton({
    Name = "RUOK ICE WALL",
    Callback = function()
        Library:Notify({
            Title    = "Ice Wall",
            Message  = "RUOK ICE WALL กำลังทำงาน!",
            Type     = "success",
            Duration = 3,
        })
    end,
})

MainTab:AddSeparator()
MainTab:AddSection("Auto Kill")

MainTab:AddToggle({
    Name    = "Auto Kill Player [Melee]",
    Default = false,
    Callback = function(state)
        print("Auto Melee:", state)
    end,
})

MainTab:AddToggle({
    Name    = "Auto Kill Player [Gun]",
    Default = false,
    Callback = function(state)
        print("Auto Gun:", state)
    end,
})

local PlayerTab = Window:AddTab("Players")

PlayerTab:AddSection("Target")

local playerDrop = PlayerTab:AddDropdown({
    Name    = "Select Player",
    Default = nil,
    Options = (function()
        local list = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            table.insert(list, p.Name)
        end
        return list
    end)(),
    Callback = function(val)
        print("Selected:", val)
    end,
})

game.Players.PlayerAdded:Connect(function()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    playerDrop:Refresh(list)
end)

game.Players.PlayerRemoving:Connect(function()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    playerDrop:Refresh(list)
end)

PlayerTab:AddSeparator()
PlayerTab:AddSection("Aimbot")

PlayerTab:AddToggle({
    Name    = "Aimbot Gun",
    Default = false,
    Callback = function(state)
        print("Aimbot:", state)
    end,
})

local fovSlider = PlayerTab:AddSlider({
    Name    = "FOV",
    Min     = 10,
    Max     = 360,
    Default = 90,
    Suffix  = "°",
    Callback = function(val)
        print("FOV:", val)
    end,
})

PlayerTab:AddSlider({
    Name    = "Prediction",
    Min     = 0,
    Max     = 100,
    Default = 20,
    Suffix  = "%",
    Callback = function(val)
        print("Prediction:", val)
    end,
})

local aimbotKey = PlayerTab:AddKeybind({
    Name    = "Aimbot Key",
    Default = Enum.KeyCode.Q,
    Callback = function()
        print("Aimbot key pressed!")
    end,
})

local StatsTab = Window:AddTab("Stats")

StatsTab:AddSection("Speed & Jump")

local wsSlider = StatsTab:AddSlider({
    Name    = "Walk Speed",
    Min     = 16,
    Max     = 500,
    Default = 16,
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end,
})

local jpSlider = StatsTab:AddSlider({
    Name    = "Jump Power",
    Min     = 50,
    Max     = 500,
    Default = 50,
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end,
})

StatsTab:AddButton({
    Name = "Reset Stats",
    Callback = function()
        wsSlider:Set(16)
        jpSlider:Set(50)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
        Library:Notify({ Title = "Stats Reset", Message = "ค่าถูกรีเซ็ตแล้ว", Type = "warning" })
    end,
})

local FruitTab = Window:AddTab("Devil Fruits")

FruitTab:AddSection("Auto Farm Fruits")

FruitTab:AddToggle({
    Name    = "Auto Collect Fruit",
    Default = false,
    Callback = function(state)
        print("Auto Collect:", state)
    end,
})

local fruitDrop = FruitTab:AddDropdown({
    Name    = "Target Fruit",
    Options = {"Gomu", "Mera", "Hie", "Gura", "Ope", "Magu"},
    Default = "Gomu",
    Callback = function(val)
        print("Target Fruit:", val)
    end,
})

FruitTab:AddButton({
    Name = "Teleport to Fruit",
    Callback = function()
        local selected = fruitDrop:Get()
        Library:Notify({
            Title   = "Fruit Finder",
            Message = "กำลังค้นหา " .. selected .. "...",
            Type    = "info",
        })
    end,
})

local MiscTab = Window:AddTab("Misc")

MiscTab:AddSection("Visual")

MiscTab:AddToggle({
    Name    = "ESP Players",
    Default = false,
    Callback = function(state)
        print("ESP:", state)
    end,
})

MiscTab:AddToggle({
    Name    = "Noclip",
    Default = false,
    Callback = function(state)
        print("Noclip:", state)
    end,
})

local espColor = MiscTab:AddColorPicker({
    Name    = "ESP Color",
    Default = Color3.fromRGB(0, 200, 200),
    Callback = function(color)
        print("Color:", color)
    end,
})

MiscTab:AddSeparator()
MiscTab:AddSection("Info")

local noteBox = MiscTab:AddTextbox({
    Name         = "Server Note",
    Placeholder  = "พิมพ์ข้อความ...",
    Default      = "",
    ClearOnFocus = true,
    Callback = function(text)
        print("Note:", text)
    end,
})

MiscTab:AddLabel("MaruX Hub v2.0 — by MaruX", Color3.fromRGB(0, 200, 200))
MiscTab:AddLabel("สคริปต์นี้ใช้งานเพื่อทดสอบเท่านั้น")

Library:AddMobileToggle(Window, "rbxassetid://74130845694007")

task.delay(0.5, function()
    Library:Notify({
        Title    = "MaruX Hub Loaded!",
        Message  = "สคริปต์โหลดสำเร็จแล้ว",
        Type     = "success",
        Duration = 4,
    })
end)
