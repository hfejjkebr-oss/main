--[[
    MaruX GUI Library v2.0
    Author  : MaruX Hub
    Discord : https://discord.gg/hWSEePc7NE
    Platform: PC & Mobile Supported
]]

local MaruXLib = {}
MaruXLib.__index = MaruXLib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local Theme = {
    Background   = Color3.fromRGB(13, 17, 23),
    Secondary    = Color3.fromRGB(18, 24, 32),
    Tertiary     = Color3.fromRGB(22, 30, 40),
    Accent       = Color3.fromRGB(0, 200, 200),
    AccentDim    = Color3.fromRGB(0, 120, 120),
    Text         = Color3.fromRGB(220, 235, 235),
    TextDim      = Color3.fromRGB(110, 145, 145),
    Separator    = Color3.fromRGB(0, 180, 180),
    Success      = Color3.fromRGB(50, 200, 100),
    Warning      = Color3.fromRGB(220, 160, 30),
    Error        = Color3.fromRGB(220, 60, 60),
    CheckOn      = Color3.fromRGB(0, 200, 200),
    CheckOff     = Color3.fromRGB(35, 48, 58),
    SliderFill   = Color3.fromRGB(0, 200, 200),
    SliderBG     = Color3.fromRGB(28, 40, 50),
    ButtonHover  = Color3.fromRGB(0, 155, 155),
    ButtonNormal = Color3.fromRGB(22, 32, 42),
    TabActive    = Color3.fromRGB(0, 200, 200),
    TabInactive  = Color3.fromRGB(18, 24, 32),
    Font         = Enum.Font.Code,
    FontBold     = Enum.Font.GothamBold,
    FontSize     = 14,
}

local function Tween(obj, props, t, style, dir)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
    end)
end

local function Create(class, props)
    local ok, obj = pcall(Instance.new, class)
    if not ok then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function Corner(parent, r)
    if not parent then return end
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = parent
end

local function Stroke(parent, color, thick)
    if not parent then return end
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Accent
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
end

local function Padding(parent, top, bot, left, right)
    if not parent then return end
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top   or 6)
    p.PaddingBottom = UDim.new(0, bot   or 6)
    p.PaddingLeft   = UDim.new(0, left  or 8)
    p.PaddingRight  = UDim.new(0, right or 8)
    p.Parent = parent
end

local function ListLayout(parent, spacing, halign)
    if not parent then return end
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, spacing or 0)
    if halign then l.HorizontalAlignment = halign end
    l.Parent = parent
    return l
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function SafeParent(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok or not gui.Parent then
        pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end)
    end
end

local function MakeDraggable(frame, handle)
    if not frame or not handle then return end
    handle = handle or frame
    local dragging, dragStart, startPos, dragConn

    local function EndDrag()
        dragging = false
        if dragConn then dragConn:Disconnect() dragConn = nil end
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            dragConn  = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then EndDrag() end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local abs = frame.AbsoluteSize
        local nx = math.clamp(startPos.X.Offset + d.X, 0, vp.X - abs.X)
        local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - abs.Y)
        frame.Position = UDim2.new(0, nx, 0, ny)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            EndDrag()
        end
    end)
end

local NotifHolder = nil
local function EnsureNotif()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = Create("ScreenGui", {
        Name = "MaruXNotifs",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    SafeParent(sg)
    NotifHolder = Create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -270, 1, -10),
        Size = UDim2.new(0, 255, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        Parent = sg,
    })
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
    l.Padding = UDim.new(0, 6)
    l.Parent = NotifHolder
end

function MaruXLib:Notify(opts)
    opts = opts or {}
    EnsureNotif()
    local aColor = Theme.Accent
    if opts.Type == "success" then aColor = Theme.Success
    elseif opts.Type == "warning" then aColor = Theme.Warning
    elseif opts.Type == "error" then aColor = Theme.Error end

    local card = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = NotifHolder,
    })
    Corner(card, UDim.new(0, 6))
    Stroke(card, aColor, 1)

    local bar = Create("Frame", {BackgroundColor3 = aColor, Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card})
    Corner(bar, UDim.new(0, 3))

    local inner = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    })
    Padding(inner, 8, 8, 4, 8)

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 2)
    ll.Parent = inner

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = opts.Title or "Notification",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 0,
        Parent = inner,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = opts.Message or "",
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = inner,
    })

    Tween(card, {BackgroundTransparency = 0}, 0.25)
    task.delay(opts.Duration or 4, function()
        if card and card.Parent then
            Tween(card, {BackgroundTransparency = 1}, 0.3)
            task.delay(0.35, function()
                if card and card.Parent then card:Destroy() end
            end)
        end
    end)
end

function MaruXLib:SetTheme(custom)
    for k, v in pairs(custom or {}) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

function MaruXLib:CreateWindow(opts)
    opts = opts or {}
    local title   = opts.Title   or "MaruX Hub"
    local version = opts.Version or "v1.0"
    local mobile  = IsMobile()

    local SIDEBAR_W = mobile and 120 or 150
    local TOPBAR_H  = mobile and 48 or 42
    local WIN_W     = mobile and math.min(workspace.CurrentCamera.ViewportSize.X - 20, 580) or 600
    local WIN_H     = mobile and 340 or 380

    local size = opts.Size or UDim2.new(0, WIN_W, 0, WIN_H)

    local ScreenGui = Create("ScreenGui", {
        Name = "MaruXLib_" .. title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
    })
    SafeParent(ScreenGui)

    local startX = math.max(0, (workspace.CurrentCamera.ViewportSize.X - WIN_W) / 2)
    local startY = mobile and 60 or 50

    local Main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Size = size,
        Position = UDim2.new(0, startX, 0, startY),
        ClipsDescendants = false,
        Parent = ScreenGui,
    })
    Corner(Main, UDim.new(0, 8))
    Stroke(Main, Color3.fromRGB(0, 0, 0), 2)

    local InnerClip = Create("Frame", {
        Name = "InnerClip",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = Main,
    })
    Corner(InnerClip, UDim.new(0, 8))

    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, TOPBAR_H),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = InnerClip,
    })

    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = TopBar,
    })

    Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = TopBar,
    })

    local logoId = opts.Logo
    if logoId and logoId ~= "" then
        Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = logoId,
            ScaleType = Enum.ScaleType.Fit,
            Position = UDim2.new(0, 8, 0.5, -14),
            Size = UDim2.new(0, 28, 0, 28),
            ZIndex = 6,
            Parent = TopBar,
        })
    else
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = "✦",
            TextColor3 = Theme.Accent,
            TextSize = 16,
            Font = Theme.FontBold,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0, 24, 1, 0),
            ZIndex = 6,
            Parent = TopBar,
        })
    end

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Theme.FontBold,
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(0, 160, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = TopBar,
    })

    local versionClean = version:gsub("^[Vv]ersion:%s*", ""):gsub("^v", "")
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Version: " .. versionClean,
        TextColor3 = Theme.Accent,
        TextSize = 12,
        Font = Theme.Font,
        Position = UDim2.new(0.38, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 6,
        Parent = TopBar,
    })

    local BtnClose = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(190, 45, 45),
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        Font = Theme.FontBold,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -34, 0.5, -13),
        ZIndex = 7,
        Parent = TopBar,
    })
    Corner(BtnClose, UDim.new(0, 5))

    local BtnMin = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(190, 145, 25),
        Text = "—",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        Font = Theme.FontBold,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -64, 0.5, -13),
        ZIndex = 7,
        Parent = TopBar,
    })
    Corner(BtnMin, UDim.new(0, 5))

    local minimized = false
    BtnClose.MouseButton1Click:Connect(function()
        Tween(Main, {Size = UDim2.new(0, WIN_W, 0, 0)}, 0.25)
        task.delay(0.3, function()
            if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
        end)
    end)

    BtnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(Main, {Size = minimized and UDim2.new(0, WIN_W, 0, TOPBAR_H) or size}, 0.25)
    end)

    MakeDraggable(Main, TopBar)

    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(0, SIDEBAR_W, 1, -TOPBAR_H),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = InnerClip,
    })

    local SideList = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 8),
        Size = UDim2.new(1, 0, 1, -8),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ZIndex = 4,
        Parent = Sidebar,
    })
    ListLayout(SideList, 2)
    Padding(SideList, 6, 6, 6, 6)

    local ContentHolder = Create("Frame", {
        Name = "ContentHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, SIDEBAR_W + 1, 0, TOPBAR_H + 4),
        Size = UDim2.new(1, -(SIDEBAR_W + 5), 1, -(TOPBAR_H + 8)),
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = InnerClip,
    })

    local Window = {}
    Window._tabs   = {}
    Window._active = nil
    Window._gui    = ScreenGui
    Window._main   = Main

    function Window:AddTab(name)
        local idx = #self._tabs + 1

        local TabBtn = Create("TextButton", {
            BackgroundColor3 = Theme.TabInactive,
            Text = "",
            Size = UDim2.new(1, 0, 0, 36),
            LayoutOrder = idx,
            ZIndex = 5,
            Parent = SideList,
        })
        Corner(TabBtn, UDim.new(0, 6))

        local TabAccent = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            Position = UDim2.new(0, 0, 0.15, 0),
            Size = UDim2.new(0, 3, 0.7, 0),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 6,
            Parent = TabBtn,
        })
        Corner(TabAccent, UDim.new(0, 2))

        local TabLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            Font = Theme.FontBold,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextScaled = false,
            ZIndex = 6,
            Parent = TabBtn,
        })

        local Content = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            Visible = false,
            ZIndex = 3,
            Parent = ContentHolder,
        })
        ListLayout(Content, 5)
        Padding(Content, 4, 8, 4, 4)

        local Tab = {
            _content = Content,
            _btn     = TabBtn,
            _label   = TabLabel,
            _accent  = TabAccent,
            _items   = 0,
        }

        local function Activate()
            for _, t in pairs(Window._tabs) do
                pcall(function()
                    Tween(t._btn, {BackgroundColor3 = Theme.TabInactive}, 0.15)
                    t._label.TextColor3 = Theme.TextDim
                    t._label.TextSize   = 13
                    t._accent.Visible   = false
                    t._content.Visible  = false
                end)
            end
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(20, 32, 44)}, 0.15)
            TabLabel.TextColor3 = Theme.Accent
            TabLabel.TextSize   = 14
            TabAccent.Visible   = true
            Content.Visible     = true
            Window._active      = Tab
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        table.insert(self._tabs, Tab)
        if #self._tabs == 1 then Activate() end

        local function NewItem(h)
            Tab._items += 1
            local w = Create("Frame", {
                BackgroundColor3 = Theme.Tertiary,
                Size = UDim2.new(1, -4, 0, h or 40),
                LayoutOrder = Tab._items,
                ClipsDescendants = false,
                Parent = Content,
            })
            Corner(w, UDim.new(0, 6))
            return w
        end

        function Tab:AddSection(sname)
            Tab._items += 1
            local h = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 34),
                LayoutOrder = Tab._items,
                Parent = Content,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = sname:upper(),
                TextColor3 = Theme.Accent,
                TextSize = 11,
                Font = Theme.FontBold,
                Position = UDim2.new(0, 4, 0, 6),
                Size = UDim2.new(1, -8, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = h,
            })
            Create("Frame", {
                BackgroundColor3 = Theme.Separator,
                BackgroundTransparency = 0.3,
                Position = UDim2.new(0, 0, 0, 28),
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
                Parent = h,
            })
        end

        function Tab:AddButton(bopts)
            bopts = bopts or {}
            local w = NewItem(40)
            local btn = Create("TextButton", {
                BackgroundColor3 = Theme.ButtonNormal,
                Text = bopts.Name or "Button",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Size = UDim2.new(1, -12, 0, 30),
                Position = UDim2.new(0, 6, 0.5, -15),
                ZIndex = 4,
                Parent = w,
            })
            Corner(btn, UDim.new(0, 6))
            Stroke(btn, Theme.Accent, 1)

            btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ButtonHover}, 0.15) end)
            btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ButtonNormal}, 0.15) end)
            btn.MouseButton1Click:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.08)
                task.delay(0.14, function() Tween(btn, {BackgroundColor3 = Theme.ButtonNormal}, 0.15) end)
                if bopts.Callback then task.spawn(bopts.Callback) end
            end)

            local api = {}
            function api:SetName(n) btn.Text = n end
            return api
        end

        function Tab:AddToggle(topts)
            topts = topts or {}
            local state  = topts.Default or false
            local CB_SZ  = 26
            local w      = NewItem(44)

            local checkbox = Create("Frame", {
                BackgroundColor3 = state and Theme.CheckOn or Theme.CheckOff,
                Position = UDim2.new(0, 10, 0.5, -CB_SZ / 2),
                Size = UDim2.new(0, CB_SZ, 0, CB_SZ),
                ZIndex = 4,
                Parent = w,
            })
            Corner(checkbox, UDim.new(0, 5))
            Stroke(checkbox, Theme.Accent, 1.5)

            local tick = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "✓",
                TextColor3 = Theme.Background,
                TextSize = 17,
                Font = Theme.FontBold,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Visible = state,
                ZIndex = 5,
                Parent = checkbox,
            })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = topts.Name or "Toggle",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, CB_SZ + 20, 0, 0),
                Size = UDim2.new(1, -(CB_SZ + 24), 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = false,
                ZIndex = 4,
                Parent = w,
            })

            local hit = Create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = w,
            })

            local function SetState(v)
                state = v
                Tween(checkbox, {BackgroundColor3 = state and Theme.CheckOn or Theme.CheckOff}, 0.15)
                tick.Visible = state
            end

            hit.MouseButton1Click:Connect(function()
                SetState(not state)
                if topts.Callback then task.spawn(topts.Callback, state) end
            end)

            local api = {}
            function api:Set(v) SetState(v) end
            function api:Get() return state end
            return api
        end

        function Tab:AddSlider(sopts)
            sopts = sopts or {}
            local smin = sopts.Min     or 0
            local smax = sopts.Max     or 100
            local val  = sopts.Default or smin
            local suf  = sopts.Suffix  or ""
            local w    = NewItem(56)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = sopts.Name or "Slider",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(0.65, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = w,
            })

            local valLbl = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = tostring(val) .. suf,
                TextColor3 = Theme.Accent,
                TextSize = 12,
                Font = Theme.Font,
                Position = UDim2.new(0.65, 0, 0, 5),
                Size = UDim2.new(0.35, -10, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 4,
                Parent = w,
            })

            local trackY = 36
            local track = Create("Frame", {
                BackgroundColor3 = Theme.SliderBG,
                Position = UDim2.new(0, 10, 0, trackY),
                Size = UDim2.new(1, -20, 0, 8),
                ZIndex = 4,
                Parent = w,
            })
            Corner(track, UDim.new(1, 0))

            local fill = Create("Frame", {
                BackgroundColor3 = Theme.SliderFill,
                Size = UDim2.new((val - smin) / (smax - smin), 0, 1, 0),
                ZIndex = 5,
                Parent = track,
            })
            Corner(fill, UDim.new(1, 0))

            local thumbSz = 14
            local thumb = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(225, 238, 238),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((val - smin) / (smax - smin), 0, 0.5, 0),
                Size = UDim2.new(0, thumbSz, 0, thumbSz),
                ZIndex = 6,
                Parent = track,
            })
            Corner(thumb, UDim.new(1, 0))
            Stroke(thumb, Theme.Accent, 1.5)

            local dragging = false
            local function UpdateSlider(input)
                local rel = math.clamp(
                    (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1
                )
                val = math.round(smin + rel * (smax - smin))
                Tween(fill,  {Size = UDim2.new(rel, 0, 1, 0)}, 0.05)
                Tween(thumb, {Position = UDim2.new(rel, 0, 0.5, 0)}, 0.05)
                valLbl.Text = tostring(val) .. suf
                if sopts.Callback then task.spawn(sopts.Callback, val) end
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateSlider(i)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging then return end
                if i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch then
                    UpdateSlider(i)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            local api = {}
            function api:Set(v)
                v = math.clamp(v, smin, smax)
                val = v
                local rel = (v - smin) / (smax - smin)
                Tween(fill,  {Size = UDim2.new(rel, 0, 1, 0)}, 0.1)
                Tween(thumb, {Position = UDim2.new(rel, 0, 0.5, 0)}, 0.1)
                valLbl.Text = tostring(v) .. suf
            end
            function api:Get() return val end
            return api
        end

        function Tab:AddDropdown(dopts)
            dopts = dopts or {}
            local items = dopts.Options or {}
            local sel   = dopts.Default or (items[1] or "None")
            local open  = false
            local w     = NewItem(40)
            w.ClipsDescendants = false
            w.ZIndex = 10

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = dopts.Name or "Dropdown",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0.45, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = w,
            })

            local dBtn = Create("TextButton", {
                BackgroundColor3 = Theme.ButtonNormal,
                Text = "",
                Position = UDim2.new(0.47, 0, 0.5, -14),
                Size = UDim2.new(0.53, -10, 0, 28),
                ZIndex = 11,
                Parent = w,
            })
            Corner(dBtn, UDim.new(0, 5))
            Stroke(dBtn, Theme.Accent, 1)

            local selLbl = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = sel,
                TextColor3 = Theme.Accent,
                TextSize = 12,
                Font = Theme.Font,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12,
                Parent = dBtn,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "▾",
                TextColor3 = Theme.Accent,
                TextSize = 14,
                Font = Theme.FontBold,
                Position = UDim2.new(1, -22, 0, 0),
                Size = UDim2.new(0, 18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 12,
                Parent = dBtn,
            })

            local dList = Create("ScrollingFrame", {
                BackgroundColor3 = Theme.Secondary,
                Position = UDim2.new(0.47, 0, 1, 4),
                Size = UDim2.new(0.53, -10, 0, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Accent,
                ScrollingEnabled = true,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ElasticBehavior = Enum.ElasticBehavior.Never,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 20,
                Parent = w,
            })
            Corner(dList, UDim.new(0, 5))
            Stroke(dList, Theme.Accent, 1)

            local dLayout = Instance.new("UIListLayout")
            dLayout.Padding    = UDim.new(0, 2)
            dLayout.SortOrder  = Enum.SortOrder.LayoutOrder
            dLayout.Parent     = dList
            Padding(dList, 4, 4, 4, 4)

            local function Populate()
                for _, c in pairs(dList:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i, item in ipairs(items) do
                    local ib = Create("TextButton", {
                        BackgroundColor3 = item == sel and Theme.Accent or Theme.ButtonNormal,
                        Text = item,
                        TextColor3 = item == sel and Theme.Background or Theme.Text,
                        TextSize = 12,
                        Font = Theme.Font,
                        Size = UDim2.new(1, 0, 0, 26),
                        LayoutOrder = i,
                        ZIndex = 21,
                        Parent = dList,
                    })
                    Corner(ib, UDim.new(0, 4))
                    ib.MouseButton1Click:Connect(function()
                        sel = item
                        selLbl.Text = sel
                        open = false
                        Tween(dList, {Size = UDim2.new(0.53, -10, 0, 0)}, 0.15)
                        task.delay(0.15, function()
                            if dList and dList.Parent then dList.Visible = false end
                        end)
                        Populate()
                        if dopts.Callback then task.spawn(dopts.Callback, sel) end
                    end)
                end
            end
            Populate()

            dBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Populate()
                    dList.Visible = true
                    local rowH  = 30
                    local maxH  = 160
                    Tween(dList, {Size = UDim2.new(0.53, -10, 0, math.min(#items * rowH, maxH))}, 0.2)
                else
                    Tween(dList, {Size = UDim2.new(0.53, -10, 0, 0)}, 0.15)
                    task.delay(0.15, function()
                        if dList and dList.Parent then dList.Visible = false end
                    end)
                end
            end)

            local api = {}
            function api:Set(v)   sel = v selLbl.Text = v Populate() end
            function api:Get()    return sel end
            function api:Refresh(t) items = t Populate() end
            return api
        end

        function Tab:AddTextbox(xopts)
            xopts = xopts or {}
            local w = NewItem(54)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = xopts.Name or "Input",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -10, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = w,
            })

            local box = Create("TextBox", {
                BackgroundColor3 = Theme.SliderBG,
                Text = xopts.Default or "",
                PlaceholderText = xopts.Placeholder or "Type here...",
                PlaceholderColor3 = Theme.TextDim,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                ClearTextOnFocus = xopts.ClearOnFocus ~= false,
                Position = UDim2.new(0, 10, 0, 26),
                Size = UDim2.new(1, -20, 0, 22),
                ZIndex = 4,
                Parent = w,
            })
            Corner(box, UDim.new(0, 5))
            Stroke(box, Theme.Accent, 1)

            box.FocusLost:Connect(function(enter)
                if xopts.Callback then task.spawn(xopts.Callback, box.Text) end
            end)

            local api = {}
            function api:Get() return box.Text end
            function api:Set(v) box.Text = v end
            return api
        end

        function Tab:AddKeybind(kopts)
            kopts = kopts or {}
            local key       = kopts.Default or Enum.KeyCode.Unknown
            local listening = false
            local w         = NewItem(40)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = kopts.Name or "Keybind",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0.55, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = w,
            })

            local kbBtn = Create("TextButton", {
                BackgroundColor3 = Theme.ButtonNormal,
                Text = key.Name,
                TextColor3 = Theme.Accent,
                TextSize = 12,
                Font = Theme.Font,
                Position = UDim2.new(0.57, 0, 0.5, -13),
                Size = UDim2.new(0.43, -10, 0, 26),
                ZIndex = 4,
                Parent = w,
            })
            Corner(kbBtn, UDim.new(0, 5))
            Stroke(kbBtn, Theme.Accent, 1)

            kbBtn.MouseButton1Click:Connect(function()
                listening = true
                kbBtn.Text = "..."
                kbBtn.TextColor3 = Theme.Warning
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    kbBtn.Text = key.Name
                    kbBtn.TextColor3 = Theme.Accent
                    listening = false
                end
                if not gpe and input.KeyCode == key and kopts.Callback then
                    task.spawn(kopts.Callback)
                end
            end)

            local api = {}
            function api:Get() return key end
            return api
        end

        function Tab:AddColorPicker(copts)
            copts = copts or {}
            local color = copts.Default or Color3.fromRGB(255, 255, 255)
            local h     = Color3.toHSV(color)
            local w     = NewItem(40)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = copts.Name or "Color",
                TextColor3 = Theme.Text,
                TextSize = Theme.FontSize,
                Font = Theme.Font,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = w,
            })

            local preview = Create("TextButton", {
                BackgroundColor3 = color,
                Text = "",
                Position = UDim2.new(1, -52, 0.5, -14),
                Size = UDim2.new(0, 42, 0, 28),
                ZIndex = 4,
                Parent = w,
            })
            Corner(preview, UDim.new(0, 6))
            Stroke(preview, Theme.Accent, 1)

            preview.MouseButton1Click:Connect(function()
                h = (h + 0.083) % 1
                color = Color3.fromHSV(h, 0.8, 0.9)
                preview.BackgroundColor3 = color
                if copts.Callback then task.spawn(copts.Callback, color) end
            end)

            local api = {}
            function api:Get() return color end
            function api:Set(c) color = c preview.BackgroundColor3 = c end
            return api
        end

        function Tab:AddLabel(text, color)
            local w = NewItem(30)
            w.BackgroundTransparency = 1
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = text or "",
                TextColor3 = color or Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                Size = UDim2.new(1, -12, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = 4,
                Parent = w,
            })
        end

        function Tab:AddSeparator()
            Tab._items += 1
            Create("Frame", {
                BackgroundColor3 = Theme.Separator,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, -8, 0, 1),
                LayoutOrder = Tab._items,
                BorderSizePixel = 0,
                Parent = Content,
            })
        end

        return Tab
    end

    function Window:Destroy()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end
    function Window:Toggle()
        if Main then Main.Visible = not Main.Visible end
    end
    function Window:SetVisible(v)
        if Main then Main.Visible = v end
    end

    return Window
end

function MaruXLib:AddMobileToggle(window, iconOrLogo)
    local sg = Create("ScreenGui", {
        Name = "MaruXMobileBtn",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 200,
    })
    SafeParent(sg)

    local btn = Create("TextButton", {
        BackgroundColor3 = Theme.Background,
        Text = "",
        Size = UDim2.new(0, 54, 0, 54),
        Position = UDim2.new(0, 10, 0.5, -27),
        ZIndex = 10,
        Parent = sg,
    })
    Corner(btn, UDim.new(0, 10))

    local isAsset = type(iconOrLogo) == "string" and iconOrLogo:find("rbxassetid://")
    if isAsset then
        Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = iconOrLogo,
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.new(0, 38, 0, 38),
            Position = UDim2.new(0.5, -19, 0.5, -19),
            ZIndex = 11,
            Parent = btn,
        })
    else
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = iconOrLogo or "✦",
            TextColor3 = Theme.Accent,
            TextSize = 24,
            Font = Theme.FontBold,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 11,
            Parent = btn,
        })
    end

    MakeDraggable(btn, btn)
    btn.MouseButton1Click:Connect(function()
        if window then window:Toggle() end
    end)

    return btn
end

return MaruXLib
