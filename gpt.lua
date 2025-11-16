--============================================================--
--   A X E E   K A I T U N   F I N A L   (1 FILE RAW READY)
--   WindUI • AutoFishingOnly • RodDetector • KaitunFlow
--============================================================--

-----------------------------
-- LOAD SERVICES
-----------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

repeat task.wait() until Player.Character

-----------------------------
-- LOAD WIND UI
-----------------------------
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-----------------------------
-- CREATE SINGLE WINDOW
-----------------------------
local Window = WindUI:CreateWindow({
    Title = "Axee Unreleased | v0.0.1",
    Icon = "door-open",
    Author = "gg/UARyY46axv",
})

-----------------------------
-- REMOTE REFERENCES
-----------------------------
local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local Remote = {
    EquipHotbar = Net["RE/EquipToolFromHotbar"],
    AutoFish    = Net["RF/UpdateAutoFishingState"],
    PurchaseRod = Net["RF/PurchaseFishingRod"],
    EquipItem   = Net["RE/EquipItem"],
    SellAll     = Net["RF/SellAllItems"],
}

-----------------------------
-- TELEPORT CFRAMES
-----------------------------
local TP = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891),
}

-----------------------------
-- RODS ID + UUID
-----------------------------
local RODS = {
    Midnight = { id = 80,  uuid = "6d977940-10bd-49e4-9dfb-aca505d7805e" },
    Ares     = { id = 126, uuid = "a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5" },
}

-----------------------------
-- ROD DELAYS (DETECTION)
-----------------------------
local RodDelays = {
    ["Starter Rod"]  = 4.3,
    ["Midnight Rod"] = 3.3,
    ["Ares Rod"]     = 1.45,
}

local CurrentRod = "None"
local CurrentDelay = 1.0

-----------------------------
-- ROD DETECTOR
-----------------------------
local function DetectRod()
    local char = Player.Character
    if not char then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and RodDelays[tool.Name] then
            CurrentRod = tool.Name
            CurrentDelay = RodDelays[tool.Name]
            return
        end
    end

    local bp = Player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and RodDelays[tool.Name] then
                CurrentRod = tool.Name
                CurrentDelay = RodDelays[tool.Name]
                return
            end
        end
    end

    CurrentRod = "None"
    CurrentDelay = 1.0
end

task.spawn(function()
    while true do
        DetectRod()
        task.wait(0.4)
    end
end)

-----------------------------
-- HELPER FUNCTIONS
-----------------------------
local function Teleport(cf)
    local hrp = Player.Character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = cf
    task.wait(0.4)
end

local function Coins()
    local ls = Player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Coins") then
        return ls.Coins.Value
    end
    return 0
end

-----------------------------
-- AUTO FISH ON/OFF
-----------------------------
local function AutoFishON()
    -- wait rod detected
    local tries = 0
    while CurrentRod == "None" and tries < 20 do
        tries += 1
        task.wait(0.2)
    end
    pcall(function()
        Remote.AutoFish:InvokeServer(true)
    end)
end

local function AutoFishOFF()
    pcall(function()
        Remote.AutoFish:InvokeServer(false)
    end)
end

-----------------------------
-- QUEST COUNTERS
-----------------------------
_G.CatchRareTreasureRoom = _G.CatchRareTreasureRoom or 0
_G.CatchMythicSisy = _G.CatchMythicSisy or 0
_G.CatchSecretSisy = _G.CatchSecretSisy or 0

-----------------------------
-- KAITUN STATE
-----------------------------
local Running = false
local Stage = "Idle"

-----------------------------
-- KAITUN CORE FLOW
-----------------------------
local function Kaitun()
    Running = true

    Stage = "Teleport Volcano"
    Teleport(TP.Volcano)
    Stage = "Farm to 50k"
    AutoFishON()
    repeat task.wait(.3) until not Running or Coins() >= 50000
    AutoFishOFF()

    if not Running then return end

    Stage = "Buy Midnight"
    Remote.PurchaseRod:InvokeServer(RODS.Midnight.id)
    task.wait(.3)
    Remote.EquipItem:FireServer(RODS.Midnight.uuid, "Fishing Rods")
    task.wait(.4)

    Stage = "Teleport Treasure"
    Teleport(TP.Treasure)
    Stage = "Catch 300 Rare/Epic"
    AutoFishON()
    repeat task.wait(.3) until not Running or _G.CatchRareTreasureRoom >= 300
    AutoFishOFF()

    if not Running then return end

    Stage = "Farm to 3M"
    AutoFishON()
    repeat task.wait(.3) until not Running or Coins() >= 3000000
    AutoFishOFF()

    if not Running then return end

    Stage = "Buy Ares"
    Remote.PurchaseRod:InvokeServer(RODS.Ares.id)
    task.wait(.3)
    Remote.EquipItem:FireServer(RODS.Ares.uuid, "Fishing Rods")

    Stage = "Teleport Sisyphus"
    Teleport(TP.Sisyphus)
    Stage = "Catch 3 Mythic"
    AutoFishON()
    repeat task.wait(.3) until not Running or _G.CatchMythicSisy >= 3

    Stage = "Catch 1 Secret"
    repeat task.wait(.3) until not Running or _G.CatchSecretSisy >= 1

    AutoFishOFF()
    Stage = "Finished"
    Running = false
end

local function Stop()
    Running = false
    AutoFishOFF()
    Stage = "Stopped"
end

-----------------------------
-- AUTO SELL EVERY 5 SEC
-----------------------------
local AutoSell = false
task.spawn(function()
    while true do
        if AutoSell then
            pcall(function()
                Remote.SellAll:InvokeServer()
            end)
        end
        task.wait(5)
    end
end)

-----------------------------
-- WIND UI SETUP
-----------------------------
local TabMain = Window:Tab({ Title = "Main", Icon = "ship" })
TabMain:Select()

TabMain:Toggle({
    Title = "Kaitun",
    Desc = "Start / Stop Kaitun",
    Default = false,
    Callback = function(v)
        if v then
            task.spawn(Kaitun)
        else
            Stop()
        end
    end
})

local Status = TabMain:Label({
    Title = "Status",
    Desc = "Idle"
})

task.spawn(function()
    while true do
        Status:Set(
            "Stage: "..Stage..
            " | Coins: "..Coins()..
            " | Rod: "..CurrentRod..
            " | Delay: "..CurrentDelay
        )
        task.wait(0.5)
    end
end)

local TabAuto = Window:Tab({
    Title = "Auto",
    Icon = "settings"
})

TabAuto:Toggle({
    Title = "Sell All",
    Desc = "Sell fish every 5 seconds",
    Default = false,
    Callback = function(v)
        AutoSell = v
    end
})