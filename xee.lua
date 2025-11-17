-- // SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- // LOAD WINDUI *DIATAS SEMUA*
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- // BUILD WINDOW DULU
local Window = WindUI:CreateWindow({
    Title = "Private Axee | Unpublished",
    Icon = "door-open",
    Author = ".gg/NuGuN5M5xj",
})

----------------------------------------------------
-- TAB 1 : FISHING FEATURE
----------------------------------------------------
local FishingTab = Window:Tab({
    Title = "Fishing Feature",
    Icon = "fish",
})

----------------------------------------------------
-- TAB 2 : TELEPORT
----------------------------------------------------
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})

----------------------------------------------------
-- SELESAI UI
-- MULAI SETTING GAME & LOGIC
----------------------------------------------------

local Character = player.Character or player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- REMOTES
local Net = ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net

local RemoteReferences = {
    SellRemote = Net["RF/SellAllItems"],
    UpdateAutoFishing = Net["RF/UpdateAutoFishingState"],
    StartMini = Net["RF/RequestFishingMinigameStarted"],
    BuyRod = Net["RF/PurchaseFishingRod"],
}

local Config = {
    FishingV1 = false,
    AutoSell = false,
}

local FishingActive = false
local SteampunkName = "!!! Steampunk Rod"

-- TELEPORT DATA
local TeleportList = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891),
}

----------------------------------------------------------------
-- AUTO FISHING LOGIC
----------------------------------------------------------------
local function StartFishingV1()
    if FishingActive then return end

    FishingActive = true
    Config.FishingV1 = true

    pcall(function()
        RemoteReferences.UpdateAutoFishing:InvokeServer(true)
    end)

    -- PERFECT CATCH
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
-- AUTO SELL LOOP
----------------------------------------------------------------
task.spawn(function()
    while task.wait(2) do
        if Config.AutoSell then
            pcall(function()
                RemoteReferences.SellRemote:InvokeServer()
            end)
        end
    end
end)

----------------------------------------------------------------
-- CONNECT UI TO FUNCTIONS
----------------------------------------------------------------

-- AUTO FISHING
FishingTab:Toggle({
    Title = "Auto Fishing",
    Desc = "Enable automatic fishing",
    Value = false,
    Callback = function(state)
        if state then StartFishingV1() else StopFishingV1() end
    end
})

-- AUTO SELL
FishingTab:Toggle({
    Title = "Auto Sell",
    Desc = "Sell fish automatically",
    Value = false,
    Callback = function(state)
        Config.AutoSell = state
    end
})

-- BUY STEAMPUNK
FishingTab:Button({
    Title = "Buy Steampunk Rod",
    Desc = "Purchase Steampunk Rod",
    Callback = function()
        pcall(function()
            RemoteReferences.BuyRod:InvokeServer(SteampunkName)
        end)
    end
})

-- TELEPORT BUTTONS
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