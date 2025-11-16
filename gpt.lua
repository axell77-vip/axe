--============================================================--
--  A X E E   K A I T U N   S Y S T E M
--  Wind UI Version (Full Automation)
--  Developer Mode – 100% BASED ON YOUR REMOTES
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
-- REMOTE REFERENCES
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
-- CFRAME TELEPORTS (YOUR EXACT CFRAMES)
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
-- FISHING FUNCTION (BASED ON YOUR REMOTES)
-----------------------------------------------------
local function FishOnce()
    Remote.ChargeRod:InvokeServer()
    task.wait(0.2)

    Remote.StartMini:InvokeServer(-1.23318, 0.391523, 1763312000.217342)
    task.wait(0.5)

    Remote.FinishFish:FireServer()
end

-----------------------------------------------------
-- KAITUN SYSTEM
-----------------------------------------------------
local KaitunRunning = false

local function StartKaitun()
    KaitunRunning = true

    ----------------------------  
    -- STEP 1: FARM UNTIL 50k  
    ----------------------------
    Teleport(TP.Volcano)

    while KaitunRunning and Player.leaderstats.Coins.Value < 50000 do
        FishOnce()
        task.wait(0.3)
    end

    ----------------------------  
    -- STEP 2: BUY MIDNIGHT  
    ----------------------------
    Remote.PurchaseRod:InvokeServer(80)  -- purchase id
    task.wait(0.2)
    Remote.EquipItem:FireServer("6d977940-10bd-49e4-9dfb-aca505d7805e", "Fishing Rods")

    ----------------------------
    -- STEP 3: TREASURE → 300 RARE/EPIC
    ----------------------------
    Teleport(TP.Treasure)

    _G.CatchRareTreasureRoom = _G.CatchRareTreasureRoom or 0
    while KaitunRunning and _G.CatchRareTreasureRoom < 300 do
        FishOnce()
        task.wait(0.3)
    end

    ----------------------------
    -- STEP 4: FARM UNTIL 3,000,000
    ----------------------------
    while KaitunRunning and Player.leaderstats.Coins.Value < 3000000 do
        FishOnce()
        task.wait(0.3)
    end

    ----------------------------
    -- STEP 5: BUY ARES
    ----------------------------
    Remote.PurchaseRod:InvokeServer(126)
    task.wait(0.2)
    Remote.EquipItem:FireServer("a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5", "Fishing Rods")

    ----------------------------
    -- STEP 6: SISYPHUS → MYTHIC + SECRET
    ----------------------------
    Teleport(TP.Sisyphus)

    _G.CatchMythicSisy = _G.CatchMythicSisy or 0
    while KaitunRunning and _G.CatchMythicSisy < 3 do
        FishOnce()
        task.wait(0.3)
    end

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
-- AUTO SELL LOOP
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

---------------------- TAB MAIN ----------------------
local TabMain = Window:Tab({
    Title = "Main",
    Icon  = "ship",
})
TabMain:Select()

TabMain:Toggle({
    Title = "Kaitun",
    Desc  = "Start/Stop Ghostfinn Kaitun",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(StartKaitun)
        else
            StopKaitun()
        end
    end
})

---------------------- TAB AUTO ----------------------
local TabAuto = Window:Tab({
    Title = "Auto",
    Icon  = "settings",
})

TabAuto:Toggle({
    Title = "Sell All",
    Desc  = "Auto sell all every 5 seconds",
    Default = false,
    Callback = function(v)
        AutoSell = v
    end
})