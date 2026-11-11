local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmawasd/FacetUI/refs/heads/main/FacetUI.lua"))()

Library:Key({
    Title = "FacetUI Example",
    Subtitle = "Key required",
    Note = "Paste your key below",
    Keys = {"testkey123"},
    Discord = "https://discord.gg/yourinvite",
    SaveKey = true,
    OnSuccess = function() Build() end,
})

function Build()
    local Window = Library:CreateWindow({
        Title = "FacetUI",
        Subtitle = "v1.0.0",
        Size = UDim2.new(0, 580, 0, 420),
        Accent = Color3.fromRGB(34, 211, 238),
    })

    local Main = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://10709791437" })
    local Combat = Main:CreateSection("Combat")

    Combat:CreateToggle({
        Name = "Silent Aim",
        Default = false,
        Flag = "silentaim",
        Callback = function(v) print("silent aim:", v) end,
    })

    Combat:CreateSlider({
        Name = "FOV",
        Min = 10, Max = 500, Default = 120, Increment = 5, Suffix = "px",
        Flag = "fov",
        Callback = function(v) print("fov:", v) end,
    })

    Combat:CreateDropdown({
        Name = "Hit Part",
        Options = {"Head", "Torso", "Legs", "Random"},
        Default = "Head",
        Flag = "hitpart",
        Callback = function(v) print("hitpart:", v) end,
    })

    Combat:CreateDropdown({
        Name = "Prediction Models",
        Options = {"Linear", "Spline", "Quadratic"},
        Multi = true,
        Default = {"Linear"},
        Flag = "preds",
        Callback = function(list) print("preds:", table.concat(list, ", ")) end,
    })

    Combat:CreateKeybind({
        Name = "Toggle Aimlock",
        Default = Enum.KeyCode.E,
        Mode = "Hold",
        Flag = "aimkey",
        Callback = function(down) print("aim held:", down) end,
    })

    Combat:CreateColorpicker({
        Name = "ESP Color",
        Default = Color3.fromRGB(0, 255, 180),
        Flag = "espcolor",
        Callback = function(c) print("color:", c) end,
    })

    local Visual = Main:CreateSection("Visual")

    Visual:CreateToggle({
        Name = "Box ESP",
        Flag = "boxesp",
        Callback = function(v) end,
    })

    Visual:CreateToggle({
        Name = "Name ESP",
        Flag = "nameesp",
        Callback = function(v) end,
    })

    Visual:CreateSlider({
        Name = "Box Thickness",
        Min = 1, Max = 5, Default = 2,
        Flag = "boxthick",
        Callback = function(v) end,
    })

    local Util = Window:CreateTab({ Name = "Utility" })
    local Misc = Util:CreateSection("Misc")

    Misc:CreateButton({
        Name = "Rejoin Server",
        Callback = function()
            local ts = game:GetService("TeleportService")
            ts:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end,
    })

    Misc:CreateTextbox({
        Name = "Walkspeed",
        Placeholder = "16",
        Numeric = true,
        Flag = "ws",
        Callback = function(n)
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = n
            end
        end,
    })

    Misc:CreateParagraph({
        Title = "Notes",
        Text = "Configs save automatically per game under workspace/FacetUI/<PlaceId>/. Use the gear icon at the bottom of the tab list to switch profiles.",
    })

    Misc:CreateDivider()
    Misc:CreateLabel("built with FacetUI")

    Library:SetToggleKey(Enum.KeyCode.RightControl)
    Library:Notify({
        Title = "Loaded",
        Content = "FacetUI example is ready",
        Type = "success",
        Duration = 4,
    })
end
