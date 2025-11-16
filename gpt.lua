--============================================================--
--  A X E E   K A I T U N   S Y S T E M
--  Wind UI Version (Full Automation)
--  Developer Mode – 100% based on your remotes & CFrames
--============================================================--

-----------------------------
-- LOAD WIND UI
-----------------------------
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-----------------------------
-- WINDOW
-----------------------------
local Window = WindUI:CreateWindow({
    Title  = "Axee Unreleased | v0.0.1",
    Icon   = "door-open",
    Author = "gg/UARyY46axv",
})

-----------------------------------------------------
-- REMOTE REFERENCES (EXACT FROM YOUR PROVIDED LIST)
-----------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Net = RS.Packages._Index["sleitnick_net@0.2.0"].net

local Remote = {
    EquipRod      = Net["RE/EquipToolFromHotbar"],
    AutoFishState = Net["RF/UpdateAutoFishingState"],
    ChargeRod     = Net["RF/ChargeFishingRod"],
    StartMini     = Net["RF/RequestFishingMinigameStarted"],
    FinishFish    = Net["RE/FishingCompleted"],
    EquipItem     = Net["RE/EquipItem"],
    PurchaseRod   = Net["RF/PurchaseFishingRod"],
    SellAll       = Net["RF/SellAllItems"],
}

-----------------------------------------------------
-- CFRAME TELEPORTS (FROM YOUR INFO)
-----------------------------------------------------
local TP = {
    Volcano  = CFrame.new(-546.500671, 16.2349777, 115.35006,
    1, -8.31874361e-11, -6.0212597e-16, 8.31874361e-11, 1, 6.64656907e-09,
    6.01573069e-16, -6.64656907e-09, 1),

    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953,
    1, 4.67368437e-08, 9.49238721e-14, -4.67368437e-08, 1, 7.08577161e-08,
    -9.16122037e-14, -7.08577161e-08, 1),

    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891,
    1, 1.06662927e-08, 2.21165402e-14, -1.06662927e-08, 1, 9.32448714e-08,
    -2.11219626e-14, -9.32448714e-08, 1),
}

local Player = game.Players.LocalPlayer
local HRP = Player.Character and Player.Character:WaitForChild("HumanoidRootPart")

local function Teleport(cf)
    HRP.CFrame = cf
    task.wait(0.5)
end

-----------------------------------------------------
-- AUTO FISHING FUNCTION (REMOTE-BASED)
-----------------------------------------------------
local function FishOnce()
    -- Charge Rod
    Remote.ChargeRod:InvokeServer()
    task.wait(0.2)

    -- Start Minigame (args mimic your example)
    Remote.StartMini:InvokeServer(-1.23318, 0.391523, 1763312000.217342)
    task.wait(0.5)

    -- Complete
    Remote.FinishFish:FireServer()
end

-----------------------------------------------------
-- KAITUN MAIN LOGIC
-----------------------------------------------------
local KaitunRunning = false

local function StartKaitun()
    if KaitunRunning then return end
    KaitunRunning = true

    -- STEP 1: Go Volcano
    Teleport(TP.Volcano)

    -- Auto farm until 50k
    while KaitunRunning and Player.leaderstats.Coins.Value < 50000 do
        FishOnce()
        task.wait(0.3)
    end

    -- STEP 2: Buy Midnight Rod (ID 80)
    Remote.PurchaseRod:InvokeServer(80)
    task.wait(0.2)

    -- Equip Midnight Rod (UUID)
    Remote.EquipItem:FireServer("6d977940-10bd-49e4-9dfb-aca505d7805e", "Fishing Rods")

    -- STEP 3: Teleport to Treasure
    Teleport(TP.Treasure)

    -- Catch 300 Rare/Epic
    _G.CatchRareTreasureRoom = _G.CatchRareTreasureRoom or 0
    while KaitunRunning and _G.CatchRareTreasureRoom < 300 do
        FishOnce()
        task.wait(0.3)
    end

    -- STEP 4: Farm until 3M coins
    while KaitunRunning and Player.leaderstats.Coins.Value < 3000000 do
        FishOnce()
        task.wait(0.3)
    end

    -- STEP 5: Buy Ares Rod (ID 126)
    Remote.PurchaseRod:InvokeServer(126)
    task.wait(0.2)

    -- Equip Ares Rod (UUID)
    Remote.EquipItem:FireServer("a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5", "Fishing Rods")

    -- STEP 6: Teleport to Sisyphus
    Teleport(TP.Sisyphus)

    -- Catch 3 Mythic
    _G.CatchMythicSisy = _G.CatchMythicSisy or 0
    while KaitunRunning and _G.CatchMythicSisy < 3 do
        FishOnce()
        task.wait(0.3)
    end

    -- Catch 1 Secret
    _G.CatchSecretSisy = _G.CatchSecretSisy or 0
    while KaitunRunning and _G.CatchSecretSisy < 1 do
        FishOnce()
        task.wait(0.3)
    end

    KaitunRunning = false
end

local function StopKaitun()
    KaitunRunning = false
end

-----------------------------------------------------
-- SELL ALL LOOP (EVERY 5 SEC)
-----------------------------------------------------
local AutoSell = false

task.spawn(function()
    while true do
        if AutoSell then
            Remote.SellAll:InvokeServer()
        end
        task.wait(5)
    end
end)

-----------------------------------------------------
-- WIND UI – FINAL UI STRUCTURE
-----------------------------------------------------

------------------ TAB 1 (MAIN) ----------------------
local TabMain = Window:Tab({
    Title = "Main",
    Icon  = "ship",
})
TabMain:Select()

local KaitunButton = TabMain:Button({
    Title = "Kaitun",
    Desc  = "Start Ghostfinn Kaitun",
    Callback = function()
        if not KaitunRunning then StartKaitun() else StopKaitun() end
    end
})

------------------ TAB 2 (AUTO) ----------------------
local TabAuto = Window:Tab({
    Title = "Auto",
    Icon  = "settings",
})

local SellToggle = TabAuto:Toggle({
    Title = "Sell All",
    Desc  = "Sell all fish every 5 seconds",
    Default = false,
    Callback = function(v)
        AutoSell = v
    end
})