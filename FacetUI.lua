local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()

local protect_gui       = (syn and syn.protect_gui) or (protect_gui) or function() end
local get_hui           = (gethui) or function() return CoreGui end
local http_get          = function(url) return game:HttpGet(url) end
local write_file        = (writefile)  or function() end
local read_file         = (readfile)   or function() return nil end
local is_file           = (isfile)     or function() return false end
local make_folder       = (makefolder) or function() end
local is_folder         = (isfolder)   or function() return false end
local list_files        = (listfiles)  or function() return {} end
local set_clipboard     = (setclipboard) or (toclipboard) or function() end
local queue_teleport    = (queue_on_teleport) or (syn and syn.queue_on_teleport) or function() end

local Theme = {
    Background    = Color3.fromRGB(10, 10, 12),
    Panel         = Color3.fromRGB(18, 18, 22),
    PanelDeep     = Color3.fromRGB(14, 14, 17),
    Element       = Color3.fromRGB(26, 26, 32),
    ElementHover  = Color3.fromRGB(34, 34, 42),
    Border        = Color3.fromRGB(42, 42, 52),
    BorderSoft    = Color3.fromRGB(28, 28, 36),
    Text          = Color3.fromRGB(235, 237, 245),
    TextDim       = Color3.fromRGB(155, 160, 175),
    TextMuted     = Color3.fromRGB(100, 105, 120),
    Accent        = Color3.fromRGB(34, 211, 238),
    AccentDim     = Color3.fromRGB(14, 165, 193),
    AccentGlow    = Color3.fromRGB(80, 220, 245),
    Danger        = Color3.fromRGB(239, 68, 68),
    Warn          = Color3.fromRGB(251, 191, 36),
    Success       = Color3.fromRGB(16, 185, 129),
    Radius        = UDim.new(0, 8),
    RadiusSmall   = UDim.new(0, 6),
    RadiusLarge   = UDim.new(0, 12),
    Font          = Enum.Font.GothamMedium,
    FontBold      = Enum.Font.GothamBold,
    FontLight     = Enum.Font.Gotham,
    TextSize      = 13,
    TitleSize     = 15,
    Easing        = Enum.EasingStyle.Quint,
    EasingDir     = Enum.EasingDirection.Out,
    Duration      = 0.22,
    FastDuration  = 0.12,
}

local Library = {
    Flags           = {},
    Callbacks       = {},
    Windows         = {},
    OpenDropdowns   = {},
    OpenPicker      = nil,
    Hidden          = false,
    ToggleKey       = Enum.KeyCode.RightControl,
    Unloaded        = false,
    _Connections    = {},
    _ConfigFolder   = "FacetUI",
    _AutoSave       = true,
    _CurrentProfile = "default",
    _Author         = "Olivia",
    _Source         = "https://discord.gg/ojailbreaks",
    Theme           = Theme,
    Version         = "1.0.0",
}

local function New(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, child in ipairs(children) do child.Parent = inst end
    end
    return inst
end

local function Tween(obj, props, dur, style, dir)
    local info = TweenInfo.new(dur or Theme.Duration, style or Theme.Easing, dir or Theme.EasingDir)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library._Connections, c)
    return c
end

local Spring = {}
Spring.__index = Spring
function Spring.new(stiffness, damping)
    return setmetatable({
        stiffness = stiffness or 170,
        damping = damping or 26,
        target = 0, pos = 0, vel = 0,
    }, Spring)
end
function Spring:Step(dt)
    local disp = self.pos - self.target
    local accel = -self.stiffness * disp - self.damping * self.vel
    self.vel = self.vel + accel * dt
    self.pos = self.pos + self.vel * dt
    return self.pos
end
function Spring:Set(v) self.target = v end
function Spring:Reset(v) self.pos, self.target, self.vel = v, v, 0 end

local function Dragify(frame, handle)
    handle = handle or frame
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.06, Enum.EasingStyle.Linear)
        end
    end)
end

local function Stroke(parent, color, thickness, trans)
    return New("UIStroke", {
        Parent = parent,
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Corner(parent, radius)
    return New("UICorner", { Parent = parent, CornerRadius = radius or Theme.Radius })
end

local function Padding(parent, p)
    return New("UIPadding", {
        Parent = parent,
        PaddingTop = UDim.new(0, p or 8),
        PaddingBottom = UDim.new(0, p or 8),
        PaddingLeft = UDim.new(0, p or 8),
        PaddingRight = UDim.new(0, p or 8),
    })
end

local function Shadow(parent, intensity)
    local img = New("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 1 - (intensity or 0.5),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 48, 1, 48),
        Position = UDim2.new(0, -24, 0, -24),
        ZIndex = 0,
    })
    return img
end

local function Gradient(parent, c1, c2, rot)
    return New("UIGradient", {
        Parent = parent,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2),
        }),
        Rotation = rot or 90,
    })
end

local function GetText(txt, size, font)
    return TextService:GetTextSize(txt, size or Theme.TextSize, font or Theme.Font, Vector2.new(9999, 9999))
end

local Config = {}

function Config:FolderPath()
    return Library._ConfigFolder .. "/" .. tostring(game.PlaceId)
end

function Config:Ensure()
    if not is_folder(Library._ConfigFolder) then make_folder(Library._ConfigFolder) end
    if not is_folder(self:FolderPath()) then make_folder(self:FolderPath()) end
end

function Config:Save(name)
    self:Ensure()
    name = name or Library._CurrentProfile
    local data = {}
    for flag, value in pairs(Library.Flags) do
        if typeof(value) == "Color3" then
            data[flag] = { __type = "Color3", r = value.R, g = value.G, b = value.B }
        elseif typeof(value) == "EnumItem" then
            data[flag] = { __type = "EnumItem", enum = tostring(value.EnumType), name = value.Name }
        else
            data[flag] = value
        end
    end
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
    if ok then
        write_file(self:FolderPath() .. "/" .. name .. ".json", enc)
        return true
    end
    return false, enc
end

function Config:Load(name)
    name = name or Library._CurrentProfile
    local path = self:FolderPath() .. "/" .. name .. ".json"
    if not is_file(path) then return false, "no config" end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, read_file(path))
    if not ok then return false, data end
    for flag, value in pairs(data) do
        if type(value) == "table" and value.__type == "Color3" then
            value = Color3.new(value.r, value.g, value.b)
        elseif type(value) == "table" and value.__type == "EnumItem" then
            local ok2, enum = pcall(function() return Enum[value.enum:gsub("Enum%.","")][value.name] end)
            if ok2 then value = enum end
        end
        if Library.Callbacks[flag] then
            for _, fn in ipairs(Library.Callbacks[flag]) do pcall(fn, value) end
        end
        Library.Flags[flag] = value
    end
    Library._CurrentProfile = name
    return true
end

function Config:List()
    self:Ensure()
    local out = {}
    for _, f in ipairs(list_files(self:FolderPath())) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    return out
end

function Config:Delete(name)
    local path = self:FolderPath() .. "/" .. name .. ".json"
    if is_file(path) then
        local ok = pcall(function() (delfile or function()end)(path) end)
        return ok
    end
    return false
end

Library.Config = Config

local function AutoSave()
    if Library._AutoSave and not Library.Unloaded then
        task.spawn(function() Config:Save() end)
    end
end

local function SetFlag(flag, value)
    if flag == nil then return end
    Library.Flags[flag] = value
    if Library.Callbacks[flag] then
        for _, fn in ipairs(Library.Callbacks[flag]) do pcall(fn, value) end
    end
    AutoSave()
end

local function BindFlag(flag, fn)
    if not flag then return end
    Library.Callbacks[flag] = Library.Callbacks[flag] or {}
    table.insert(Library.Callbacks[flag], fn)
end

local function MakeRoot()
    local existing = get_hui():FindFirstChild("FacetUI")
    if existing then existing:Destroy() end
    local gui = New("ScreenGui", {
        Name = "FacetUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
    })
    pcall(protect_gui, gui)
    gui.Parent = get_hui()
    return gui
end

local Root = MakeRoot()
Library.Root = Root

local NotifContainer = New("Frame", {
    Parent = Root,
    Name = "Notifs",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 320, 1, -40),
})
New("UIListLayout", {
    Parent = NotifContainer,
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

function Library:Notify(opts)
    opts = opts or {}
    local title    = opts.Title    or "Facet"
    local content  = opts.Content  or ""
    local duration = opts.Duration or 4
    local kind     = opts.Type     or "info"
    local col = ({
        info    = Theme.Accent,
        success = Theme.Success,
        warn    = Theme.Warn,
        danger  = Theme.Danger,
    })[kind] or Theme.Accent

    local toast = New("Frame", {
        Parent = NotifContainer,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.1,
        ClipsDescendants = true,
    })
    Corner(toast, UDim.new(0, 8))
    Stroke(toast, Theme.Border, 1, 0.3)

    local accentBar = New("Frame", {
        Parent = toast,
        BackgroundColor3 = col,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BorderSizePixel = 0,
    })
    Corner(accentBar, UDim.new(1, 0))

    local titleLbl = New("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 10),
        Size = UDim2.new(1, -32, 0, 16),
        Text = title,
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local body = New("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 28),
        Size = UDim2.new(1, -32, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = content,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })

    local progress = New("Frame", {
        Parent = toast,
        BackgroundColor3 = col,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundTransparency = 0.3,
    })

    New("UIPadding", {
        Parent = toast,
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 10),
    })

    toast.Position = UDim2.new(1, 20, 0, 0)
    Tween(toast, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(toast, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.3)
        task.wait(0.3)
        toast:Destroy()
    end)
end

function Library:Key(opts)
    opts = opts or {}
    local title    = opts.Title or "Facet Key"
    local subtitle = opts.Subtitle or "Verification required"
    local note     = opts.Note or "Paste your key below"
    local keys     = opts.Keys or {}
    local keyURL   = opts.KeyURL
    local discord  = opts.Discord
    local saveKey  = opts.SaveKey ~= false
    local keyFile  = Library._ConfigFolder .. "/key.txt"
    local onOK     = opts.OnSuccess or function() end
    local onFail   = opts.OnFail    or function() end

    Config:Ensure()

    local function validate(k)
        for _, v in ipairs(keys) do if v == k then return true end end
        if keyURL then
            local ok, body = pcall(http_get, keyURL)
            if ok and body then
                for line in body:gmatch("[^\r\n]+") do
                    if line:gsub("%s", "") == k then return true end
                end
            end
        end
        return false
    end

    if saveKey and is_file(keyFile) then
        local saved = read_file(keyFile)
        if saved and validate(saved) then
            onOK(saved)
            return true
        end
    end

    local gate = New("Frame", {
        Parent = Root,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 50,
    })

    local card = New("Frame", {
        Parent = gate,
        BackgroundColor3 = Theme.Panel,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 240),
        ZIndex = 51,
    })
    Corner(card, Theme.RadiusLarge)
    Stroke(card, Theme.Border, 1, 0.2)
    Shadow(card, 0.6)

    New("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 18),
        Size = UDim2.new(1, -40, 0, 22),
        Text = title, Font = Theme.FontBold, TextSize = 18,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
    })
    New("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 40),
        Size = UDim2.new(1, -40, 0, 14),
        Text = subtitle, Font = Theme.Font, TextSize = 12,
        TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
    })
    New("TextLabel", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 68),
        Size = UDim2.new(1, -40, 0, 14),
        Text = note, Font = Theme.FontLight, TextSize = 11,
        TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
    })

    local input = New("TextBox", {
        Parent = card, BackgroundColor3 = Theme.Element,
        Position = UDim2.new(0, 20, 0, 94),
        Size = UDim2.new(1, -40, 0, 36),
        PlaceholderText = "key here", PlaceholderColor3 = Theme.TextMuted,
        Text = "", ClearTextOnFocus = false,
        Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, ZIndex = 52,
    })
    Corner(input, UDim.new(0, 6))
    Stroke(input, Theme.BorderSoft, 1, 0.2)
    New("UIPadding", {Parent = input, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

    local submit = New("TextButton", {
        Parent = card, BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 20, 0, 140),
        Size = UDim2.new(1, -40, 0, 34),
        Text = "verify", Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.Background,
        AutoButtonColor = false, ZIndex = 52,
    })
    Corner(submit, UDim.new(0, 6))

    local row = New("Frame", {
        Parent = card, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 184),
        Size = UDim2.new(1, -40, 0, 36), ZIndex = 52,
    })
    local layout = New("UIListLayout", {
        Parent = row, FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    })

    if discord then
        local dbtn = New("TextButton", {
            Parent = row, BackgroundColor3 = Theme.Element,
            Size = UDim2.new(0, 110, 1, 0),
            Text = "copy discord", Font = Theme.Font, TextSize = 12,
            TextColor3 = Theme.Text, AutoButtonColor = false, ZIndex = 52,
        })
        Corner(dbtn, UDim.new(0, 6))
        Stroke(dbtn, Theme.BorderSoft)
        dbtn.MouseButton1Click:Connect(function()
            pcall(set_clipboard, discord)
            Library:Notify({Title = "Copied", Content = "Discord invite in clipboard", Type = "success"})
        end)
    end
    local cancel = New("TextButton", {
        Parent = row, BackgroundColor3 = Theme.Element,
        Size = UDim2.new(0, 80, 1, 0),
        Text = "cancel", Font = Theme.Font, TextSize = 12,
        TextColor3 = Theme.TextDim, AutoButtonColor = false, ZIndex = 52,
    })
    Corner(cancel, UDim.new(0, 6))
    Stroke(cancel, Theme.BorderSoft)
    cancel.MouseButton1Click:Connect(function() gate:Destroy() onFail() end)

    submit.MouseButton1Click:Connect(function()
        local k = input.Text
        if validate(k) then
            if saveKey then pcall(write_file, keyFile, k) end
            Tween(gate, {BackgroundTransparency = 1}, 0.3)
            task.wait(0.3)
            gate:Destroy()
            onOK(k)
        else
            local orig = submit.Text
            submit.Text = "invalid"
            Tween(submit, {BackgroundColor3 = Theme.Danger}, 0.2)
            task.wait(0.9)
            Tween(submit, {BackgroundColor3 = Theme.Accent}, 0.2)
            submit.Text = orig
        end
    end)

    gate.BackgroundTransparency = 1
    Tween(gate, {BackgroundTransparency = 0.2}, 0.25)
end

local function MakeMiniPill(window)
    local pill = New("Frame", {
        Parent = Root, BackgroundColor3 = Theme.Panel,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 180, 0, 36),
        BackgroundTransparency = 0.05,
        Visible = false, ZIndex = 100,
    })
    Corner(pill, UDim.new(1, 0))
    Stroke(pill, Theme.Accent, 1, 0.1)
    Shadow(pill, 0.6)

    local dot = New("Frame", {
        Parent = pill, BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 10, 0.5, -4),
        Size = UDim2.new(0, 8, 0, 8), ZIndex = 101,
    })
    Corner(dot, UDim.new(1, 0))

    local lbl = New("TextLabel", {
        Parent = pill, BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -62, 1, 0),
        Text = window.Title, Font = Theme.FontBold, TextSize = 12,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 101,
    })

    local expand = New("TextButton", {
        Parent = pill, BackgroundColor3 = Theme.Element,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        Text = "+", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.Text,
        AutoButtonColor = false, ZIndex = 101,
    })
    Corner(expand, UDim.new(1, 0))

    task.spawn(function()
        while pill.Parent do
            Tween(dot, {BackgroundTransparency = 0.7}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            Tween(dot, {BackgroundTransparency = 0}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)

    Dragify(pill)
    return pill, expand
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "Facet"
    local subtitle = opts.Subtitle or ""
    local size     = opts.Size     or UDim2.new(0, 560, 0, 400)
    local accent   = opts.Accent
    if accent then Theme.Accent = accent end

    local win = {}
    win.Title = title
    win.Tabs = {}
    win.ActiveTab = nil

    local main = New("Frame", {
        Parent = Root, BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size, BackgroundTransparency = 0.05,
        ClipsDescendants = true,
    })
    Corner(main, Theme.RadiusLarge)
    Stroke(main, Theme.Border, 1, 0.2)
    Shadow(main, 0.5)

    local shimmer = New("Frame", {
        Parent = main, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 2,
    })
    local shimStroke = Stroke(shimmer, Theme.Accent, 1, 0.5)
    task.spawn(function()
        while main.Parent do
            Tween(shimStroke, {Transparency = 0.2}, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2.5)
            Tween(shimStroke, {Transparency = 0.7}, 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(2.5)
        end
    end)

    local titlebar = New("Frame", {
        Parent = main, BackgroundColor3 = Theme.PanelDeep,
        Size = UDim2.new(1, 0, 0, 44), BorderSizePixel = 0, ZIndex = 3,
    })
    Corner(titlebar, Theme.RadiusLarge)
    New("Frame", {
        Parent = titlebar, BackgroundColor3 = Theme.PanelDeep,
        Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 6),
        BorderSizePixel = 0, ZIndex = 3,
    })
    New("Frame", {
        Parent = titlebar, BackgroundColor3 = Theme.Border,
        Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0, BackgroundTransparency = 0.6, ZIndex = 3,
    })

    New("TextLabel", {
        Parent = titlebar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0, 300, 1, 0),
        Text = title, Font = Theme.FontBold, TextSize = Theme.TitleSize,
        TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    })
    if subtitle ~= "" then
        New("TextLabel", {
            Parent = titlebar, BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 22), Size = UDim2.new(0, 300, 0, 14),
            Text = subtitle, Font = Theme.FontLight, TextSize = 10,
            TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
        })
    end

    local ctrl = New("Frame", {
        Parent = titlebar, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 60, 0, 24), ZIndex = 4,
    })
    New("UIListLayout", {
        Parent = ctrl, FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function MakeCtrl(txt, col)
        local b = New("TextButton", {
            Parent = ctrl, BackgroundColor3 = Theme.Element,
            Size = UDim2.new(0, 24, 0, 24), Text = txt,
            Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.Text,
            AutoButtonColor = false, ZIndex = 4,
        })
        Corner(b, UDim.new(1, 0))
        b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = col or Theme.ElementHover}, 0.12) end)
        b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = Theme.Element}, 0.12) end)
        return b
    end
    local minBtn   = MakeCtrl("−", Theme.Warn)
    local closeBtn = MakeCtrl("×", Theme.Danger)

    local tabCol = New("Frame", {
        Parent = main, BackgroundColor3 = Theme.PanelDeep,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, 140, 1, -44),
        BorderSizePixel = 0, BackgroundTransparency = 0.15,
    })
    New("Frame", {
        Parent = tabCol, BackgroundColor3 = Theme.Border,
        Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0, BackgroundTransparency = 0.5,
    })
    local tabList = New("ScrollingFrame", {
        Parent = tabCol, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -48), Position = UDim2.new(0, 0, 0, 10),
        BorderSizePixel = 0, ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    New("UIListLayout", { Parent = tabList, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    New("UIPadding", { Parent = tabList, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    local profileDock = New("Frame", {
        Parent = tabCol, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 32),
    })
    local profileBtn = New("TextButton", {
        Parent = profileDock, BackgroundColor3 = Theme.Element,
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
        Text = "⚙  " .. Library._CurrentProfile, Font = Theme.Font, TextSize = 11,
        TextColor3 = Theme.TextDim, AutoButtonColor = false,
    })
    Corner(profileBtn, UDim.new(0, 6))
    Stroke(profileBtn, Theme.BorderSoft)

    local content = New("Frame", {
        Parent = main, BackgroundTransparency = 1,
        Position = UDim2.new(0, 140, 0, 44),
        Size = UDim2.new(1, -140, 1, -44),
    })

    Dragify(main, titlebar)

    local pill, pillExpand = MakeMiniPill({ Title = title })

    local function Collapse()
        pill.Visible = true
        pill.BackgroundTransparency = 1
        Tween(pill, {BackgroundTransparency = 0.05}, 0.2)
        Tween(main, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = main.Position + UDim2.new(0, main.AbsoluteSize.X / 2, 0, main.AbsoluteSize.Y / 2),
        }, 0.3)
        task.wait(0.3)
        main.Visible = false
    end
    local function Restore()
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        Tween(main, {
            Size = size,
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }, 0.3)
        Tween(pill, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        pill.Visible = false
    end
    local lastClick = 0
    titlebar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local now = tick()
            if now - lastClick < 0.3 then Collapse() end
            lastClick = now
        end
    end)
    pillExpand.MouseButton1Click:Connect(Restore)
    minBtn.MouseButton1Click:Connect(Collapse)
    closeBtn.MouseButton1Click:Connect(function()
        Library:Unload()
    end)

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Hidden = not Library.Hidden
            main.Visible = not Library.Hidden and not pill.Visible
            if Library.Hidden then pill.Visible = false end
        end
    end)

    win.Frame = main
    win.TabList = tabList
    win.Content = content
    win.Pill = pill

    function win:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Name or tabOpts.Title or "Tab"
        local tabIcon = tabOpts.Icon

        local tab = {}
        tab.Name = tabName
        tab.Sections = {}

        local btn = New("TextButton", {
            Parent = tabList, BackgroundColor3 = Theme.Element,
            Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false,
        })
        Corner(btn, UDim.new(0, 6))

        local iconLbl, textLbl
        if tabIcon then
            iconLbl = New("ImageLabel", {
                Parent = btn, BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = (tostring(tabIcon):match("^rbxassetid") or tostring(tabIcon):match("^http")) and tabIcon or ("rbxassetid://" .. tostring(tabIcon)),
                ImageColor3 = Theme.TextDim,
            })
        end
        textLbl = New("TextLabel", {
            Parent = btn, BackgroundTransparency = 1,
            Position = UDim2.new(0, tabIcon and 34 or 12, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            Text = tabName, Font = Theme.Font, TextSize = 12,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        })

        local page = New("ScrollingFrame", {
            Parent = content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
        })
        New("UIListLayout", { Parent = page, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
        New("UIPadding", {
            Parent = page,
            PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        })

        tab.Button, tab.Page = btn, page

        local function Activate()
            for _, t in ipairs(win.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, {BackgroundTransparency = 1}, 0.12)
                Tween(t.Button:FindFirstChildOfClass("TextLabel"), {TextColor3 = Theme.TextDim}, 0.12)
                local ic = t.Button:FindFirstChildOfClass("ImageLabel")
                if ic then Tween(ic, {ImageColor3 = Theme.TextDim}, 0.12) end
            end
            page.Visible = true
            Tween(btn, {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Element}, 0.12)
            Tween(textLbl, {TextColor3 = Theme.Text}, 0.12)
            if iconLbl then Tween(iconLbl, {ImageColor3 = Theme.Accent}, 0.12) end
            win.ActiveTab = tab
        end
        btn.MouseButton1Click:Connect(Activate)
        btn.MouseEnter:Connect(function()
            if win.ActiveTab ~= tab then Tween(btn, {BackgroundTransparency = 0.7}, 0.12) end
        end)
        btn.MouseLeave:Connect(function()
            if win.ActiveTab ~= tab then Tween(btn, {BackgroundTransparency = 1}, 0.12) end
        end)

        table.insert(win.Tabs, tab)
        if #win.Tabs == 1 then Activate() end

        function tab:CreateSection(secOpts)
            secOpts = type(secOpts) == "string" and {Name = secOpts} or (secOpts or {})
            local secName = secOpts.Name or "Section"
            local side    = secOpts.Side or "Left"

            local section = {}

            local secFrame = New("Frame", {
                Parent = page, BackgroundColor3 = Theme.Panel,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 0.3,
            })
            Corner(secFrame, UDim.new(0, 8))
            Stroke(secFrame, Theme.BorderSoft, 1, 0.3)
            local secPad = New("UIPadding", {
                Parent = secFrame,
                PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            })
            local secList = New("UIListLayout", {
                Parent = secFrame, Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            New("TextLabel", {
                Parent = secFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16), Text = secName,
                Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1,
            })

            section.Frame = secFrame

            local function Row(height)
                local r = New("Frame", {
                    Parent = secFrame, BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, height or 34),
                    BackgroundTransparency = 0.2,
                })
                Corner(r, UDim.new(0, 6))
                Stroke(r, Theme.BorderSoft, 1, 0.5)
                return r
            end

            function section:CreateButton(o)
                o = o or {}
                local name = o.Name or "Button"
                local cb   = o.Callback or function() end
                local row = Row(34)
                local btn = New("TextButton", {
                    Parent = row, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, AutoButtonColor = false,
                })
                btn.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                btn.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)
                btn.MouseButton1Click:Connect(function()
                    Tween(row, {BackgroundColor3 = Theme.Accent}, 0.1)
                    task.wait(0.1)
                    Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.2)
                    pcall(cb)
                end)
                return { SetText = function(_, t) btn.Text = t end }
            end

            function section:CreateToggle(o)
                o = o or {}
                local name  = o.Name or "Toggle"
                local def   = o.Default and true or false
                local cb    = o.Callback or function() end
                local flag  = o.Flag
                local state = def

                local row = Row(34)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -56, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local sw = New("Frame", {
                    Parent = row, BackgroundColor3 = Theme.Border,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 34, 0, 18),
                })
                Corner(sw, UDim.new(1, 0))
                local knob = New("Frame", {
                    Parent = sw, BackgroundColor3 = Color3.fromRGB(230,230,240),
                    Position = UDim2.new(0, 2, 0.5, -7),
                    Size = UDim2.new(0, 14, 0, 14),
                })
                Corner(knob, UDim.new(1, 0))

                local function Apply(v, skipCb)
                    state = v
                    Tween(sw,   {BackgroundColor3 = v and Theme.Accent or Theme.Border}, 0.15)
                    Tween(knob, {Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.18)
                    if not skipCb then pcall(cb, v) end
                    if flag then SetFlag(flag, v) end
                end

                local btn = New("TextButton", {
                    Parent = row, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
                })
                btn.MouseButton1Click:Connect(function() Apply(not state) end)
                btn.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                btn.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                if flag then
                    BindFlag(flag, function(v) Apply(v, true) end)
                    Library.Flags[flag] = def
                end
                Apply(def, true)

                return {
                    Set = function(_, v) Apply(v) end,
                    Get = function() return state end,
                }
            end

            function section:CreateSlider(o)
                o = o or {}
                local name   = o.Name   or "Slider"
                local minV   = o.Min    or 0
                local maxV   = o.Max    or 100
                local def    = o.Default or minV
                local inc    = o.Increment or 1
                local suffix = o.Suffix or ""
                local cb     = o.Callback or function() end
                local flag   = o.Flag

                local row = Row(50)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 6),
                    Size = UDim2.new(1, -24, 0, 16),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local valLbl = New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(1, -92, 0, 6), Size = UDim2.new(0, 80, 0, 16),
                    Text = "", Font = Theme.FontBold, TextSize = 12,
                    TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
                })
                local track = New("Frame", {
                    Parent = row, BackgroundColor3 = Theme.Border,
                    Position = UDim2.new(0, 12, 1, -14),
                    Size = UDim2.new(1, -24, 0, 4),
                })
                Corner(track, UDim.new(1, 0))
                local fill = New("Frame", {
                    Parent = track, BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 0, 1, 0),
                })
                Corner(fill, UDim.new(1, 0))
                local knob = New("Frame", {
                    Parent = track, BackgroundColor3 = Theme.Text,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    ZIndex = 3,
                })
                Corner(knob, UDim.new(1, 0))
                Stroke(knob, Theme.Accent, 2)

                local cur = def
                local function Apply(v, skipCb)
                    v = math.clamp(v, minV, maxV)
                    v = math.floor(v / inc + 0.5) * inc
                    if inc < 1 then
                        local dec = tostring(inc):match("%.(%d+)")
                        local d = dec and #dec or 0
                        v = tonumber(string.format("%." .. d .. "f", v)) or v
                    end
                    cur = v
                    local a = (v - minV) / (maxV - minV)
                    Tween(fill, {Size = UDim2.new(a, 0, 1, 0)}, 0.08, Enum.EasingStyle.Linear)
                    Tween(knob, {Position = UDim2.new(a, 0, 0.5, 0)}, 0.08, Enum.EasingStyle.Linear)
                    valLbl.Text = tostring(v) .. (suffix ~= "" and (" " .. suffix) or "")
                    if not skipCb then pcall(cb, v) end
                    if flag then SetFlag(flag, v) end
                end

                local dragging = false
                local function FromMouse(x)
                    local abs = track.AbsolutePosition.X
                    local w   = track.AbsoluteSize.X
                    local a = math.clamp((x - abs) / w, 0, 1)
                    Apply(minV + (maxV - minV) * a)
                end
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true FromMouse(i.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        FromMouse(i.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                if flag then
                    BindFlag(flag, function(v) Apply(v, true) end)
                    Library.Flags[flag] = def
                end
                Apply(def, true)

                return {
                    Set = function(_, v) Apply(v) end,
                    Get = function() return cur end,
                }
            end

            function section:CreateDropdown(o)
                o = o or {}
                local name    = o.Name    or "Dropdown"
                local opts    = o.Options or {}
                local def     = o.Default
                local multi   = o.Multi   or false
                local cb      = o.Callback or function() end
                local flag    = o.Flag
                local selected = multi and {} or def

                if multi and def then
                    for _, v in ipairs(def) do selected[v] = true end
                end

                local row = Row(34)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local disp = New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -28, 0.5, 0),
                    Size = UDim2.new(0.5, -16, 1, 0),
                    Text = "", Font = Theme.Font, TextSize = 12,
                    TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local arrow = New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
                    Text = "▾", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.TextDim,
                })

                local list = New("Frame", {
                    Parent = Root, BackgroundColor3 = Theme.Panel,
                    Visible = false, ZIndex = 60, BackgroundTransparency = 0.05,
                })
                Corner(list, UDim.new(0, 6))
                Stroke(list, Theme.Border, 1, 0.2)
                Shadow(list, 0.5)
                local scroll = New("ScrollingFrame", {
                    Parent = list, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
                    BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 61,
                })
                New("UIListLayout", { Parent = scroll, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
                New("UIPadding", { Parent = scroll, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })

                local function Render()
                    if multi then
                        local arr = {}
                        for k, v in pairs(selected) do if v then table.insert(arr, k) end end
                        disp.Text = #arr == 0 and "none" or table.concat(arr, ", ")
                    else
                        disp.Text = selected and tostring(selected) or "none"
                    end
                end

                local itemFrames = {}
                local function Refresh()
                    for _, f in pairs(itemFrames) do f:Destroy() end
                    itemFrames = {}
                    for _, opt in ipairs(opts) do
                        local ib = New("TextButton", {
                            Parent = scroll, BackgroundColor3 = Theme.Element,
                            Size = UDim2.new(1, 0, 0, 26),
                            Text = tostring(opt), Font = Theme.Font, TextSize = 12,
                            TextColor3 = Theme.TextDim, AutoButtonColor = false,
                            BackgroundTransparency = 0.2, ZIndex = 62,
                        })
                        Corner(ib, UDim.new(0, 4))
                        local isSel = multi and selected[opt] or (selected == opt)
                        if isSel then
                            ib.BackgroundColor3 = Theme.Accent
                            ib.TextColor3 = Theme.Background
                        end
                        ib.MouseButton1Click:Connect(function()
                            if multi then
                                selected[opt] = not selected[opt]
                                local arr = {}
                                for k, v in pairs(selected) do if v then table.insert(arr, k) end end
                                pcall(cb, arr)
                                if flag then SetFlag(flag, arr) end
                            else
                                selected = opt
                                pcall(cb, opt)
                                if flag then SetFlag(flag, opt) end
                                list.Visible = false
                                Tween(arrow, {Rotation = 0}, 0.12)
                            end
                            Render()
                            Refresh()
                        end)
                        itemFrames[opt] = ib
                    end
                end
                Refresh()
                Render()

                local btn = New("TextButton", {
                    Parent = row, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, ZIndex = 2,
                })
                btn.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                btn.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                local function Position()
                    local pos  = row.AbsolutePosition
                    local size = row.AbsoluteSize
                    list.Position = UDim2.new(0, pos.X, 0, pos.Y + size.Y + 4)
                    list.Size = UDim2.new(0, size.X, 0, math.min(#opts * 28 + 8, 180))
                end
                btn.MouseButton1Click:Connect(function()
                    Position()
                    list.Visible = not list.Visible
                    Tween(arrow, {Rotation = list.Visible and 180 or 0}, 0.15)
                end)

                if flag then
                    BindFlag(flag, function(v)
                        if multi and type(v) == "table" then
                            selected = {}
                            for _, k in ipairs(v) do selected[k] = true end
                        else
                            selected = v
                        end
                        Render() Refresh()
                    end)
                    Library.Flags[flag] = def
                end

                return {
                    Set = function(_, v)
                        if multi and type(v) == "table" then
                            selected = {}
                            for _, k in ipairs(v) do selected[k] = true end
                        else selected = v end
                        Render() Refresh()
                        if flag then SetFlag(flag, v) end
                    end,
                    Get = function()
                        if multi then
                            local arr = {}
                            for k, v in pairs(selected) do if v then table.insert(arr, k) end end
                            return arr
                        end
                        return selected
                    end,
                    Refresh = function(_, newOpts, keep)
                        opts = newOpts or {}
                        if not keep then selected = multi and {} or nil end
                        Render() Refresh()
                    end,
                }
            end

            function section:CreateKeybind(o)
                o = o or {}
                local name   = o.Name   or "Keybind"
                local def    = o.Default or Enum.KeyCode.F
                local mode   = o.Mode   or "Toggle"
                local cb     = o.Callback or function() end
                local flag   = o.Flag
                local cur    = def
                local listen = false
                local active = false

                local row = Row(34)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local kbtn = New("TextButton", {
                    Parent = row, BackgroundColor3 = Theme.PanelDeep,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 96, 0, 22),
                    Text = cur.Name, Font = Theme.Font, TextSize = 11,
                    TextColor3 = Theme.TextDim, AutoButtonColor = false,
                })
                Corner(kbtn, UDim.new(0, 4))
                Stroke(kbtn, Theme.BorderSoft)

                kbtn.MouseButton1Click:Connect(function()
                    listen = true kbtn.Text = "..." Tween(kbtn, {BackgroundColor3 = Theme.Accent}, 0.1)
                end)
                Connect(UserInputService.InputBegan, function(input, gpe)
                    if gpe then return end
                    if listen then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            cur = input.KeyCode
                            kbtn.Text = cur.Name
                            Tween(kbtn, {BackgroundColor3 = Theme.PanelDeep}, 0.15)
                            listen = false
                            if flag then SetFlag(flag, cur) end
                        end
                    else
                        if input.KeyCode == cur then
                            if mode == "Toggle" then
                                active = not active pcall(cb, active)
                            elseif mode == "Hold" then
                                active = true pcall(cb, true)
                            else
                                pcall(cb)
                            end
                        end
                    end
                end)
                Connect(UserInputService.InputEnded, function(input, gpe)
                    if mode == "Hold" and input.KeyCode == cur and active then
                        active = false pcall(cb, false)
                    end
                end)
                row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                if flag then
                    BindFlag(flag, function(v)
                        if typeof(v) == "EnumItem" then cur = v kbtn.Text = v.Name end
                    end)
                    Library.Flags[flag] = def
                end

                return {
                    Set = function(_, v) cur = v kbtn.Text = v.Name end,
                    Get = function() return cur end,
                }
            end

            function section:CreateColorpicker(o)
                o = o or {}
                local name = o.Name or "Color"
                local def  = o.Default or Color3.fromRGB(255,255,255)
                local cb   = o.Callback or function() end
                local flag = o.Flag
                local cur  = def

                local row = Row(34)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -56, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local swatch = New("TextButton", {
                    Parent = row, BackgroundColor3 = cur,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 34, 0, 20),
                    Text = "", AutoButtonColor = false,
                })
                Corner(swatch, UDim.new(0, 4))
                Stroke(swatch, Theme.BorderSoft)

                local picker = New("Frame", {
                    Parent = Root, BackgroundColor3 = Theme.Panel,
                    Visible = false, ZIndex = 70, Size = UDim2.new(0, 220, 0, 200),
                    BackgroundTransparency = 0.05,
                })
                Corner(picker, UDim.new(0, 8))
                Stroke(picker, Theme.Border, 1, 0.2)
                Shadow(picker, 0.5)

                local svMap = New("ImageLabel", {
                    Parent = picker, Position = UDim2.new(0, 10, 0, 10),
                    Size = UDim2.new(0, 160, 0, 160), BackgroundColor3 = Color3.fromRGB(255,0,0),
                    Image = "rbxassetid://4155801252", ZIndex = 71,
                })
                local svCursor = New("Frame", {
                    Parent = svMap, BackgroundTransparency = 1, Size = UDim2.new(0, 8, 0, 8),
                    AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 72,
                })
                Stroke(svCursor, Color3.new(1,1,1), 2)
                Corner(svCursor, UDim.new(1, 0))

                local hueBar = New("Frame", {
                    Parent = picker, Position = UDim2.new(0, 180, 0, 10),
                    Size = UDim2.new(0, 16, 0, 160), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 71,
                })
                Corner(hueBar, UDim.new(0, 3))
                local hueGrad = New("UIGradient", {
                    Parent = hueBar, Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
                    }),
                })
                local hueCursor = New("Frame", {
                    Parent = hueBar, BackgroundColor3 = Color3.new(1,1,1),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 4, 0, 2), ZIndex = 72,
                })

                local hexBox = New("TextBox", {
                    Parent = picker, BackgroundColor3 = Theme.Element,
                    Position = UDim2.new(0, 10, 1, -26),
                    Size = UDim2.new(1, -20, 0, 20),
                    Text = "#ffffff", Font = Theme.Font, TextSize = 11,
                    TextColor3 = Theme.Text, ClearTextOnFocus = false, ZIndex = 71,
                })
                Corner(hexBox, UDim.new(0, 4))
                Stroke(hexBox, Theme.BorderSoft)

                local h, s, v = Color3.toHSV(def)
                local function Apply(hh, ss, vv, skipCb)
                    h, s, v = hh, ss, vv
                    cur = Color3.fromHSV(h, s, v)
                    svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueCursor.Position = UDim2.new(0.5, 0, h, 0)
                    swatch.BackgroundColor3 = cur
                    hexBox.Text = string.format("#%02x%02x%02x", math.floor(cur.R*255), math.floor(cur.G*255), math.floor(cur.B*255))
                    if not skipCb then pcall(cb, cur) end
                    if flag then SetFlag(flag, cur) end
                end

                local draggingSV, draggingH = false, false
                svMap.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end
                end)
                hueBar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingH = true end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false draggingH = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement then
                        if draggingSV then
                            local p = svMap.AbsolutePosition
                            local sz = svMap.AbsoluteSize
                            local ns = math.clamp((i.Position.X - p.X) / sz.X, 0, 1)
                            local nv = 1 - math.clamp((i.Position.Y - p.Y) / sz.Y, 0, 1)
                            Apply(h, ns, nv)
                        elseif draggingH then
                            local p = hueBar.AbsolutePosition
                            local sz = hueBar.AbsoluteSize
                            local nh = math.clamp((i.Position.Y - p.Y) / sz.Y, 0, 1)
                            Apply(nh, s, v)
                        end
                    end
                end)
                hexBox.FocusLost:Connect(function()
                    local hx = hexBox.Text:gsub("#", "")
                    if #hx == 6 then
                        local r = tonumber(hx:sub(1,2), 16)
                        local g = tonumber(hx:sub(3,4), 16)
                        local b = tonumber(hx:sub(5,6), 16)
                        if r and g and b then
                            local hh, ss, vv = Color3.toHSV(Color3.fromRGB(r,g,b))
                            Apply(hh, ss, vv)
                        end
                    end
                end)

                swatch.MouseButton1Click:Connect(function()
                    local pos = row.AbsolutePosition
                    local sz  = row.AbsoluteSize
                    picker.Position = UDim2.new(0, pos.X + sz.X - 220, 0, pos.Y + sz.Y + 4)
                    picker.Visible = not picker.Visible
                end)
                row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                if flag then
                    BindFlag(flag, function(v) if typeof(v) == "Color3" then local hh,ss,vv = Color3.toHSV(v) Apply(hh,ss,vv,true) end end)
                    Library.Flags[flag] = def
                end
                Apply(h, s, v, true)

                return {
                    Set = function(_, c) local hh,ss,vv = Color3.toHSV(c) Apply(hh,ss,vv) end,
                    Get = function() return cur end,
                }
            end

            function section:CreateTextbox(o)
                o = o or {}
                local name    = o.Name or "Textbox"
                local def     = o.Default or ""
                local place   = o.Placeholder or ""
                local numeric = o.Numeric or false
                local cb      = o.Callback or function() end
                local flag    = o.Flag

                local row = Row(34)
                New("TextLabel", {
                    Parent = row, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
                    Text = name, Font = Theme.Font, TextSize = Theme.TextSize,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local tb = New("TextBox", {
                    Parent = row, BackgroundColor3 = Theme.PanelDeep,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.5, -14, 0, 24),
                    Text = def, PlaceholderText = place, PlaceholderColor3 = Theme.TextMuted,
                    Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Text,
                    ClearTextOnFocus = false,
                })
                Corner(tb, UDim.new(0, 4))
                Stroke(tb, Theme.BorderSoft)
                New("UIPadding", {Parent = tb, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

                tb.FocusLost:Connect(function(enter)
                    local v = tb.Text
                    if numeric then
                        local n = tonumber(v)
                        if not n then tb.Text = tostring(def) return end
                        v = n
                    end
                    pcall(cb, v, enter)
                    if flag then SetFlag(flag, v) end
                end)
                row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = Theme.ElementHover}, 0.12) end)
                row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = Theme.Element}, 0.12) end)

                if flag then
                    BindFlag(flag, function(v) tb.Text = tostring(v) end)
                    Library.Flags[flag] = def
                end

                return {
                    Set = function(_, v) tb.Text = tostring(v) if flag then SetFlag(flag, v) end end,
                    Get = function() return tb.Text end,
                }
            end

            function section:CreateLabel(text)
                local l = New("TextLabel", {
                    Parent = secFrame, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = text or "", Font = Theme.Font, TextSize = 12,
                    TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
                })
                return { Set = function(_, t) l.Text = t end }
            end

            function section:CreateParagraph(o)
                o = o or {}
                local title = o.Title or ""
                local body  = o.Text  or o.Content or ""
                local f = New("Frame", {
                    Parent = secFrame, BackgroundColor3 = Theme.PanelDeep,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 0.3,
                })
                Corner(f, UDim.new(0, 6))
                Stroke(f, Theme.BorderSoft)
                New("UIPadding", {
                    Parent = f,
                    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                })
                local t = New("TextLabel", {
                    Parent = f, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = title, Font = Theme.FontBold, TextSize = 12,
                    TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                })
                local b = New("TextLabel", {
                    Parent = f, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 20),
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    Text = body, Font = Theme.FontLight, TextSize = 11,
                    TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                })
                return {
                    Set = function(_, nt, nb) t.Text = nt or t.Text b.Text = nb or b.Text end,
                }
            end

            function section:CreateDivider()
                local d = New("Frame", {
                    Parent = secFrame, BackgroundColor3 = Theme.BorderSoft,
                    Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
                    BackgroundTransparency = 0.3,
                })
                return d
            end

            function section:CreateImage(o)
                o = o or {}
                local id   = o.Image or o.Asset or ""
                local size = o.Size or UDim2.new(1, 0, 0, 120)
                local img = New("ImageLabel", {
                    Parent = secFrame, BackgroundTransparency = 1,
                    Size = size, Image = tostring(id),
                    ScaleType = o.Scale or Enum.ScaleType.Fit,
                })
                Corner(img, UDim.new(0, 6))
                return { Set = function(_, nid) img.Image = tostring(nid) end }
            end

            return section
        end

        return tab
    end

    profileBtn.MouseButton1Click:Connect(function()
        local existing = Root:FindFirstChild("FacetProfilePanel")
        if existing then existing:Destroy() return end
        local pnl = New("Frame", {
            Parent = Root, Name = "FacetProfilePanel",
            BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.05,
            Size = UDim2.new(0, 260, 0, 240), ZIndex = 80,
        })
        pnl.Position = UDim2.new(0, main.AbsolutePosition.X + 140, 0, main.AbsolutePosition.Y + main.AbsoluteSize.Y - 240 - 10)
        Corner(pnl, UDim.new(0, 8))
        Stroke(pnl, Theme.Border, 1, 0.2)
        Shadow(pnl, 0.5)

        New("TextLabel", {
            Parent = pnl, BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 10),
            Size = UDim2.new(1, -28, 0, 16),
            Text = "profiles", Font = Theme.FontBold, TextSize = 13,
            TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 81,
        })

        local nameBox = New("TextBox", {
            Parent = pnl, BackgroundColor3 = Theme.Element,
            Position = UDim2.new(0, 14, 0, 32),
            Size = UDim2.new(1, -28, 0, 26),
            Text = Library._CurrentProfile, PlaceholderText = "profile name",
            PlaceholderColor3 = Theme.TextMuted,
            Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Text,
            ClearTextOnFocus = false, ZIndex = 81,
        })
        Corner(nameBox, UDim.new(0, 4))
        Stroke(nameBox, Theme.BorderSoft)
        New("UIPadding", {Parent = nameBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

        local function Mkbtn(txt, pos, col, fn)
            local b = New("TextButton", {
                Parent = pnl, BackgroundColor3 = col or Theme.Element,
                Position = pos, Size = UDim2.new(0.5, -18, 0, 26),
                Text = txt, Font = Theme.FontBold, TextSize = 11, TextColor3 = col == Theme.Accent and Theme.Background or Theme.Text,
                AutoButtonColor = false, ZIndex = 81,
            })
            Corner(b, UDim.new(0, 4))
            Stroke(b, Theme.BorderSoft)
            b.MouseButton1Click:Connect(fn)
            return b
        end

        Mkbtn("save", UDim2.new(0, 14, 0, 66), Theme.Accent, function()
            Library._CurrentProfile = nameBox.Text ~= "" and nameBox.Text or "default"
            local ok = Config:Save()
            Library:Notify({Title = ok and "Saved" or "Save failed", Content = Library._CurrentProfile, Type = ok and "success" or "danger"})
            profileBtn.Text = "⚙  " .. Library._CurrentProfile
        end)
        Mkbtn("load", UDim2.new(0.5, 4, 0, 66), nil, function()
            Library._CurrentProfile = nameBox.Text ~= "" and nameBox.Text or "default"
            local ok, err = Config:Load()
            Library:Notify({Title = ok and "Loaded" or "Load failed", Content = tostring(err or Library._CurrentProfile), Type = ok and "success" or "danger"})
            profileBtn.Text = "⚙  " .. Library._CurrentProfile
        end)

        local listScroll = New("ScrollingFrame", {
            Parent = pnl, BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 102),
            Size = UDim2.new(1, -28, 1, -112),
            BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 81,
        })
        New("UIListLayout", {Parent = listScroll, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})

        for _, n in ipairs(Config:List()) do
            local r = New("TextButton", {
                Parent = listScroll, BackgroundColor3 = Theme.Element,
                Size = UDim2.new(1, 0, 0, 24), Text = n,
                Font = Theme.Font, TextSize = 11, TextColor3 = Theme.TextDim,
                AutoButtonColor = false, BackgroundTransparency = 0.2, ZIndex = 82,
            })
            Corner(r, UDim.new(0, 4))
            r.MouseButton1Click:Connect(function() nameBox.Text = n end)
        end
    end)

    table.insert(Library.Windows, win)
    return win
end

function Library:SetAccent(c)
    Theme.Accent = c
end

function Library:SetToggleKey(key)
    Library.ToggleKey = key
end

function Library:Unload()
    Library.Unloaded = true
    for _, c in ipairs(Library._Connections) do pcall(function() c:Disconnect() end) end
    if Library.Root then Library.Root:Destroy() end
end

function Library:Hide()
    Library.Hidden = true
    for _, w in ipairs(Library.Windows) do w.Frame.Visible = false if w.Pill then w.Pill.Visible = false end end
end

function Library:Show()
    Library.Hidden = false
    for _, w in ipairs(Library.Windows) do w.Frame.Visible = true end
end

function Library:QueueOnTeleport(src)
    pcall(queue_teleport, src)
end

return Library
