--// Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FootageSus/WindUI/main/Source.lua"))()

--// Create Window
local Window = WindUI:CreateWindow({
    Title = "Acxll Studio — External Panel",
    Subtitle = "Fishing Controls",
    Size = UDim2.fromOffset(530, 360),
    Theme = "Dark"
})

--=====================================================
-- TAB 1 — Fishing Info
--=====================================================

local FishingTab = Window:CreateTab({
    Title = "Fishing Info",
    Icon = "rbxassetid://10734947462"
})

-- Toggle: Auto Fishing
local autoFish = false
FishingTab:CreateToggle({
    Title = "Auto Fishing",
    Default = false,
    Callback = function(state)
        autoFish = state
        
        if state then
            task.spawn(function()
                while autoFish do
                    pcall(function()
                        -- Ganti remote sesuai game lu
                        game.ReplicatedStorage.Events.Fish:FireServer()
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- Toggle: Auto Sell
local autoSell = false
FishingTab:CreateToggle({
    Title = "Auto Sell",
    Default = false,
    Callback = function(state)
        autoSell = state
        
        if state then
            task.spawn(function()
                while autoSell do
                    pcall(function()
                        -- Ganti remote sesuai game lu
                        game.ReplicatedStorage.Events.SellFish:FireServer()
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

--=====================================================
-- TAB 2 — Teleport
--=====================================================

local TeleportTab = Window:CreateTab({
    Title = "Teleport",
    Icon = "rbxassetid://10734946714"
})

local function tp(pos)
    pcall(function()
        local chr = game.Players.LocalPlayer.Character
        if chr and chr:FindFirstChild("HumanoidRootPart") then
            chr.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)
end

TeleportTab:CreateButton({
    Title = "Teleport to Island 1",
    Callback = function()
        tp(Vector3.new(100, 20, 50))  -- EDIT koordinat
    end
})

TeleportTab:CreateButton({
    Title = "Teleport to Island 2",
    Callback = function()
        tp(Vector3.new(250, 20, -40))  -- EDIT koordinat
    end
})

TeleportTab:CreateButton({
    Title = "Teleport to Island 3",
    Callback = function()
        tp(Vector3.new(-300, 35, 200))  -- EDIT koordinat
    end
})

TeleportTab:CreateButton({
    Title = "Teleport to Island 4",
    Callback = function()
        tp(Vector3.new(500, 50, -300))  -- EDIT koordinat
    end
})