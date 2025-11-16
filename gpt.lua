--========================================================--
--   A X E E   K A I T U N   F I N A L   B U I L D
--   WindUI + FishingV1 + AutoQuest + AutoSell + Inline Tracker
--========================================================--

---------------------------
-- SERVICES & PLAYER
---------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

---------------------------
-- WIND UI LOADER
---------------------------
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

----------------------------------------------
-- REMOTE REFERENCES
----------------------------------------------
local RemoteReferences = {}

local function SetupRemotes()
    local idx = ReplicatedStorage:WaitForChild("Packages")._Index
    local net = idx["sleitnick_net@0.2.0"].net

    local function GR(n) return net:FindFirstChild(n) end

    RemoteReferences.UpdateAutoFishing = GR("RF/UpdateAutoFishingState")
    RemoteReferences.StartMini = GR("RF/RequestFishingMinigameStarted")
    RemoteReferences.ChargeRod = GR("RF/ChargeFishingRod")
    RemoteReferences.FinishFish = GR("RE/FishingCompleted")
    RemoteReferences.FishCaught = GR("RE/FishCaught") or GR("RF/FishCaught")
    RemoteReferences.PurchaseRod = GR("RF/PurchaseFishingRod")
    RemoteReferences.EquipItem = GR("RE/EquipItem")
    RemoteReferences.EquipHotbar = GR("RE/EquipToolFromHotbar")
    RemoteReferences.SellRemote = GR("RF/SellAllItems")
end

SetupRemotes()

---------------------------------------------------
-- TELEPORT CFRAME
---------------------------------------------------
local CF_KOHANA = CFrame.new(-546.500671, 16.2349777, 115.35006)
local CF_TREASURE = CFrame.new(-3570.70264, -279.074188, -1599.13953)
local CF_SISYPHUS = CFrame.new(-3737.87354, -135.073914, -888.212891)

local function Teleport(cf)
    local c = player.Character or player.CharacterAdded:Wait()
    local hrp = c:WaitForChild("HumanoidRootPart")
    hrp.CFrame = cf
end

---------------------------------------------------
-- QUEST PROGRESS
---------------------------------------------------
local function GetDeepSeaProgress()
    local m = Workspace:FindFirstChild("!!! MENU RINGS")
    if not m then return 0 end

    local t = m:FindFirstChild("Deep Sea Tracker")
    if not t then return 0 end

    local label = t.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
    if not label then return 0 end

    local num = label.Text:match("([%d%.]+)%%")
    return tonumber(num) or 0
end

-------------------------------------------
-- FINAL COIN SCANNER (REMOTE + RUNNER)
-- Cache refresh: 120s (super aman)
-------------------------------------------

local CoinScanDelay = 120
local LastCoinScan = 0
local CachedCoins = 0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local Remote_GetPlayerData = Net:WaitForChild("RF/GetPlayerData")

local Runner = ReplicatedFirst:WaitForChild("GAME"):WaitForChild("Runner")
local WaitForPlayerData = require(Runner:WaitForChild("WaitForPlayerData"))


local function ScanCoins()
    -- Try Remote first
    local okRemote, rawData = pcall(function()
        return Remote_GetPlayerData:InvokeServer()
    end)
    if okRemote and rawData then
        -- Try Runner parser
        local okRunner, parsed = pcall(function()
            return WaitForPlayerData(rawData)
        end)
        if okRunner and parsed then
            -- Try known fields
            if parsed.Coins then return parsed.Coins end
            if parsed.coins then return parsed.coins end
            if parsed.stats and parsed.stats.coins then return parsed.stats.coins end
        end
    end

    return nil
end


function GetCoins()
    local now = os.clock()

    if now - LastCoinScan >= CoinScanDelay then
        LastCoinScan = now

        local coins = ScanCoins()
        if coins then
            CachedCoins = coins
        end
    end

    return CachedCoins
end
---------------------------------------------------
-- FISHING V1 ENGINE
---------------------------------------------------
local FishingActive = false
local FishingV1Enabled = false
local PerfectCatch = true
local OriginalNamecall

local function EnablePerfectCatch()
    if not PerfectCatch then return end
    if not RemoteReferences.StartMini then return end

    local mt = getrawmetatable(game)
    if not mt then return end

    setreadonly(mt, false)
    if not OriginalNamecall then
        OriginalNamecall = mt.__namecall
    end

    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "InvokeServer"
        and self == RemoteReferences.StartMini
        and FishingV1Enabled then

            return OriginalNamecall(self,
                -1.233184814453125,
                0.9945034885633273
            )
        end
        return OriginalNamecall(self, ...)
    end)

    setreadonly(mt, true)
end

function StartFishingV1()
    if FishingActive then return end
    FishingActive = true
    FishingV1Enabled = true

    pcall(function()
        RemoteReferences.UpdateAutoFishing:InvokeServer(true)
    end)

    EnablePerfectCatch()

    task.spawn(function()
        while FishingV1Enabled do
            task.wait(1)
        end

        pcall(function()
            RemoteReferences.UpdateAutoFishing:InvokeServer(false)
        end)

        FishingActive = false
    end)
end

function StopFishingV1()
    FishingV1Enabled = false
end

---------------------------------------------------
-- AUTO SELL
---------------------------------------------------
local AutoSell = false

local function StartAutoSell()
    AutoSell = true
    task.spawn(function()
        while AutoSell do
            pcall(function()
                RemoteReferences.SellRemote:InvokeServer()
            end)
            task.wait(5)
        end
    end)
end

local function StopAutoSell()
    AutoSell = false
end

---------------------------------------------------
-- INLINE STATUS TRACKER
---------------------------------------------------
local InlineLabel = MainTab:Label({
    Title = "Status",
    Desc = "Rod=None | Stage=0/4 | Progress=0%"
})

local CurrentStage = 0
function SetStage(n)
    CurrentStage = n
end

local function GetRodName()
    local char = player.Character
    if not char then return "None" end

    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v.Name
        end
    end
    return "None"
end

local function UpdateInline()
    InlineLabel:Set(
        "Rod="..GetRodName()..
        " | Stage="..CurrentStage.."/4"..
        " | Progress="..(GetDeepSeaProgress() or 0).."%"
    )
end

task.spawn(function()
    while true do
        UpdateInline()
        task.wait(1)
    end
end)

---------------------------------------------------
-- KAITUN MAIN SYSTEM
---------------------------------------------------
local KaitunRunning = false

local function KaitunFlow()
    KaitunRunning = true

    ----------------------------------------------------
    -- STAGE 1 → Starter → 50k
    ----------------------------------------------------
    SetStage(1)
    Teleport(CF_KOHANA)
    task.wait(1)

    StartFishingV1()
    while KaitunRunning and GetCoins() < 50000 do task.wait(1) end
    StopFishingV1()
    if not KaitunRunning then return end

    ----------------------------------------------------
    -- BUY MIDNIGHT
    ----------------------------------------------------
    pcall(function() RemoteReferences.PurchaseRod:InvokeServer(80) end)
    task.wait(.5)

    pcall(function()
        RemoteReferences.EquipItem:FireServer(
            "6d977940-10bd-49e4-9dfb-aca505d7805e",
            "Fishing Rods"
        )
    end)
    task.wait(1)

    ----------------------------------------------------
    -- STAGE 2 → Rare/Epic 25%
    ----------------------------------------------------
    SetStage(2)
    Teleport(CF_TREASURE)
    task.wait(1)

    StartFishingV1()
    while KaitunRunning and GetDeepSeaProgress() < 25 do task.wait(1) end
    StopFishingV1()

    if not KaitunRunning then return end

    ----------------------------------------------------
    -- STAGE 3 → Farm to 100% / 3M
    ----------------------------------------------------
    SetStage(3)
    StartFishingV1()

    while KaitunRunning do
        if GetDeepSeaProgress() >= 100 then break end
        if GetCoins() >= 3000000 then break end
        task.wait(1)
    end

    StopFishingV1()
    if not KaitunRunning then return end

    ----------------------------------------------------
    -- BUY ARES & SISYPHUS
    ----------------------------------------------------
    if GetCoins() >= 3000000 and GetDeepSeaProgress() < 100 then
        pcall(function() RemoteReferences.PurchaseRod:InvokeServer(126) end)
        task.wait(.5)

        pcall(function()
            RemoteReferences.EquipItem:FireServer(
                "a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5",
                "Fishing Rods"
            )
        end)
        task.wait(.5)

        ----------------------------------------------------
        -- STAGE 4 → Mythic + Secret
        ----------------------------------------------------
        SetStage(4)
        Teleport(CF_SISYPHUS)
        task.wait(1)

        StartFishingV1()
        while KaitunRunning and GetDeepSeaProgress() < 100 do task.wait(1) end
        StopFishingV1()
    end

    KaitunRunning = false
end
----------------------------------------------------
----------------------------------------------

---------------------------
-- UI CREATION
---------------------------

local Window = WindUI:CreateWindow({
    Title = "Axee Unreleased | Final",
    Icon = "ship",
    Author = "gg/UARyY46axv",
})

local MainTab = Window:Tab({
    Title = "Main",
})
MainTab:Select()

local AutoTab = Window:Tab({
    Title = "Auto"
})


local Toggle = MainTab:Toggle({
    Title = "Start Kaitun",
    Desc = "Auto full Ghostfinn Quest",
    Default = false,
    Callback = function(v)
        if v then
            KaitunRunning = false
            task.wait(.1)
            task.spawn(KaitunFlow)
        else
            KaitunRunning = false
            StopFishingV1()
        end
    end
})

local Toggle = AutoTab:Toggle({
    Title = "Auto Sell",
    Desc = "Sell every 5 seconds",
    Default = false,
    Callback = function(v)
        if v then StartAutoSell() else StopAutoSell() end
    end
})

---------------------------------------------------
print("AXEE KAITUN FINAL BUILD LOADED ✓")