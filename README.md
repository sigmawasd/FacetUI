# FacetUI

A dark glass UI library for Roblox scripts with a collapsible mini player mode.

FacetUI is a UI library for Roblox scripts. It is similar to Wind UI but with a darker glass look and a few extra features. The main one is the mini player mode, where you can double click the title bar to shrink the window into a small floating pill you can drag around.

It has all the normal components like toggles, sliders, dropdowns, multi dropdowns, keybinds, colorpickers, textboxes, and notifications. Configs save automatically per game, and you can have multiple named profiles. There is also a built in keysystem if you want to gate the script.

![preview](preview.png)

## Install

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmawasd/FacetUI/refs/heads/main/FacetUI.lua"))()
```

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmawasd/FacetUI/refs/heads/main/FacetUI.lua"))()

local Window = Library:CreateWindow({
    Title = "My Script",
    Subtitle = "v1.0.0",
    Size = UDim2.new(0, 580, 0, 420),
})

local Main = Window:CreateTab({ Name = "Main" })
local Combat = Main:CreateSection("Combat")

Combat:CreateToggle({
    Name = "Silent Aim",
    Default = false,
    Flag = "silentaim",
    Callback = function(v) print("silent aim:", v) end,
})

Combat:CreateSlider({
    Name = "FOV",
    Min = 10, Max = 500, Default = 120, Suffix = "px",
    Flag = "fov",
    Callback = function(v) print("fov:", v) end,
})

Library:Notify({ Title = "Loaded", Content = "FacetUI is ready", Type = "success" })
```

## Components

### Window

```lua
local Window = Library:CreateWindow({
    Title = "FacetUI",
    Subtitle = "optional small text under the title",
    Size = UDim2.new(0, 580, 0, 420),
    Accent = Color3.fromRGB(34, 211, 238), -- optional
})
```

### Tabs and Sections

```lua
local Tab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://10709791437" })
local Section = Tab:CreateSection("My Section")
```

### Button

```lua
Section:CreateButton({
    Name = "Click Me",
    Callback = function() print("clicked") end,
})
```

### Toggle

```lua
Section:CreateToggle({
    Name = "Toggle Name",
    Default = false,
    Flag = "mytoggle",
    Callback = function(value) print(value) end,
})
```

### Slider

```lua
Section:CreateSlider({
    Name = "Slider Name",
    Min = 0, Max = 100,
    Default = 50,
    Increment = 1,
    Suffix = "%",
    Flag = "myslider",
    Callback = function(value) print(value) end,
})
```

### Dropdown

```lua
Section:CreateDropdown({
    Name = "Choose One",
    Options = {"Red", "Green", "Blue"},
    Default = "Red",
    Flag = "color",
    Callback = function(v) print(v) end,
})
```

### Multi Dropdown

```lua
Section:CreateDropdown({
    Name = "Choose Many",
    Options = {"A", "B", "C", "D"},
    Multi = true,
    Default = {"A"},
    Flag = "picks",
    Callback = function(list) print(table.concat(list, ", ")) end,
})
```

### Keybind

```lua
Section:CreateKeybind({
    Name = "Toggle Something",
    Default = Enum.KeyCode.E,
    Mode = "Toggle", -- "Toggle" / "Hold" / "Always"
    Flag = "mykey",
    Callback = function(state) print(state) end,
})
```

### Colorpicker

```lua
Section:CreateColorpicker({
    Name = "Pick a Color",
    Default = Color3.fromRGB(0, 255, 180),
    Flag = "mycolor",
    Callback = function(c) print(c) end,
})
```

### Textbox

```lua
Section:CreateTextbox({
    Name = "Your Input",
    Placeholder = "type here",
    Default = "",
    Numeric = false,
    Flag = "mytext",
    Callback = function(text, enter) print(text) end,
})
```

### Label, Paragraph, Divider, Image

```lua
Section:CreateLabel("Just some text")

Section:CreateParagraph({
    Title = "Note",
    Text = "A longer block of explanation text here.",
})

Section:CreateDivider()

Section:CreateImage({
    Image = "rbxassetid://123456789",
    Size = UDim2.new(1, 0, 0, 120),
})
```

### Notifications

```lua
Library:Notify({
    Title = "Hello",
    Content = "Something happened",
    Duration = 4,
    Type = "success", -- "info" / "success" / "warn" / "danger"
})
```

## Config System

Configs save automatically per game to `workspace/FacetUI/<PlaceId>/<profile>.json`.

Any component with a `Flag` is tracked. Use the gear icon in the bottom of the tab column to name and switch profiles.

Manual save and load:

```lua
Library.Config:Save("my_profile")
Library.Config:Load("my_profile")

for _, name in ipairs(Library.Config:List()) do
    print(name)
end
```

## Keysystem

Optional gate before the main UI loads.

```lua
Library:Key({
    Title = "My Script",
    Subtitle = "License check",
    Note = "Get a key from discord",
    Keys = {"testkey123"},
    KeyURL = nil, -- or a raw text url with keys on separate lines
    Discord = "https://discord.gg/yourinvite",
    SaveKey = true,
    OnSuccess = function()
        -- build your window here
    end,
    OnFail = function() end,
})
```

## Other API

```lua
Library:SetToggleKey(Enum.KeyCode.RightControl) -- show / hide the UI
Library:Hide()
Library:Show()
Library:Unload()
Library:QueueOnTeleport(source) -- re-inject after a teleport
```

## Features

- Dark glass theme with animated accent shimmer on the window border
- Collapsible mini player mode (double click title bar)
- Full component set (toggle, slider, dropdown, multi dropdown, keybind, colorpicker, textbox, button, label, paragraph, divider, image)
- Notifications with progress bar
- Per game config saving with named profiles
- Optional keysystem with remote key list support
- Works on all major executors

## License

MIT. See [LICENSE](LICENSE).
