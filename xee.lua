-- // VARIABLES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Remote Reference
local RemoteReferences = {}
RemoteReferences.Net = ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net

RemoteReferences.SellRemote = RemoteReferences.Net["RF/SellAllItems"]
RemoteReferences.BuyRod = RemoteReferences.Net["RF/PurchaseFishingRod"]
RemoteReferences.UpdateAutoFishing = RemoteReferences.Net["RF/UpdateAutoFishingState"]
RemoteReferences.StartMini = RemoteReferences.Net["RF/RequestFishingMinigameStarted"]

-- CONFIG
local Config = {
    FishingV1 = false,
    AutoSell = false,
}

local FishingActive = false

-- CFrame TELEPORT LIST
local TeleportList = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891),
}

----------------------------------------------------------------
-- // AUTO FISHING SYSTEM
----------------------------------------------------------------

local function StartFishingV1()
    if FishingActive then return end
    
    FishingActive = true
    Config.FishingV1 = true

    pcall(function()
        RemoteReferences.UpdateAutoFishing:InvokeServer(true)
    end)

    -- PERFECT CATCH PATCH
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        local old = mt.__namecall

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and self == RemoteReferences.StartMini and Config.FishingV1 then
                return old(self, -1.2331848, 0.9945034)
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end

    task.spawn(function()
        while Config.FishingV1 do task.wait(1) end
        
        pcall(function()
            RemoteReferences.UpdateAutoFishing:InvokeServer(false)
        end)
        FishingActive = false
    end)
end

local function StopFishingV1()
    Config.FishingV1 = false
end

----------------------------------------------------------------
-- AUTO SELL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(3) do
        if Config.AutoSell then
            pcall(function()
                RemoteReferences.SellRemote:InvokeServer()
            end)
        end
    end
end)

----------------------------------------------------------------
-- // UI SYSTEM
----------------------------------------------------------------

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- MAIN WINDOW
local Window = WindUI:CreateWindow({
    Title = "Private Axee | Unpublished",
    Icon = "door-open",
    Author = ".gg/NuGuN5M5xj",
})

----------------------------------------------------
-- TAB 1 : FISHING
----------------------------------------------------
local FishingTab = Window:Tab({
    Title = "Fishing Feature",
    Icon = "fish",
})

-- AUTO FISHING TOGGLE
FishingTab:Toggle({
    Title = "Auto Fishing",
    Desc = "Auto fishing system",
    Value = false,
    Callback = function(state)
        if state then
            StartFishingV1()
        else
            StopFishingV1()
        end
    end
})

-- AUTO SELL
FishingTab:Toggle({
    Title = "Auto Sell",
    Desc = "Automatically sell all fish",
    Value = false,
    Callback = function(state)
        Config.AutoSell = state
    end
})

-- BUY STEAMPUNK BUTTON
FishingTab:Button({
    Title = "Buy Steampunk Rod",
    Desc = "Auto buy the Steampunk Rod",
    Callback = function()
        pcall(function()
            RemoteReferences.BuyRod:InvokeServer("!!! Steampunk Rod")
        end)
    end
})

----------------------------------------------------
-- TAB 2 : TELEPORT
----------------------------------------------------
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})

TeleportTab:Button({
    Title = "Kohana Volcano",
    Callback = function()
        HRP.CFrame = TeleportList.Volcano
    end
})

TeleportTab:Button({
    Title = "Treasure Room",
    Callback = function()
        HRP.CFrame = TeleportList.Treasure
    end
})

TeleportTab:Button({
    Title = "Sisyphus Statue",
    Callback = function()
        HRP.CFrame = TeleportList.Sisyphus
    end
})