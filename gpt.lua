--============================================================--
--  AXEE KAITUN - FINAL (WITH ROD DETECTOR)
--  WindUI | AutoFishing only | Ready to execute
--============================================================--

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
if not Player then
    return warn("[Kaitun] Script must run as LocalPlayer.")
end

-- WIND UI loader
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- REMOTES (your net)
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local RemoteReferences = {}
RemoteReferences.Net = Net
RemoteReferences.ChargeRod = Net:WaitForChild("RF/ChargeFishingRod")
RemoteReferences.StartMini = Net:WaitForChild("RF/RequestFishingMinigameStarted")
RemoteReferences.FinishFish = Net:WaitForChild("RE/FishingCompleted")
RemoteReferences.FishCaught = Net:FindFirstChild("RE/FishCaught") or Net:FindFirstChild("RF/FishCaught")
RemoteReferences.EquipRemote = Net:WaitForChild("RE/EquipToolFromHotbar")
RemoteReferences.SellRemote = Net:WaitForChild("RF/SellAllItems")
RemoteReferences.FavoriteRemote = Net:WaitForChild("RE/FavoriteItem")
RemoteReferences.RadarRemote = Net:WaitForChild("RF/UpdateFishingRadar")
RemoteReferences.EquipOxy = Net:WaitForChild("RF/EquipOxygenTank")
RemoteReferences.UnequipOxy = Net:WaitForChild("RF/UnequipOxygenTank")
RemoteReferences.PurchaseWeather = Net:WaitForChild("RF/PurchaseWeatherEvent")
RemoteReferences.UpdateAutoFishing = Net:WaitForChild("RF/UpdateAutoFishingState")
RemoteReferences.RodRemote = Net:WaitForChild("RF/ChargeFishingRod")
RemoteReferences.MiniGameRemote = Net:WaitForChild("RF/RequestFishingMinigameStarted")
RemoteReferences.FinishRemote = Net:WaitForChild("RE/FishingCompleted")
RemoteReferences.PurchaseRod = Net:WaitForChild("RF/PurchaseFishingRod")
RemoteReferences.EquipItem = Net:WaitForChild("RE/EquipItem")
RemoteReferences.UnequipTool = Net:WaitForChild("RE/UnequipToolFromHotbar")

-- TELEPORT CFRAMES
local TP = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006,
        1, -8.31874361e-11, -6.0212597e-16, 8.31874361e-11, 1, 6.64656907e-09,
        6.01573069e-16, -6.64656907e-09, 1),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953,
        1, 4.67368437e-08, 9.49238721e-14, -4.67368437e-08, 1, 7.08577161e-08,
        -9.16122037e-14, -7.08577161e-08, 1),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891,
        1, 1.06662927e-08, 2.21165402e-14, -1.06662927e-08, 1, 9.32448714e-08,
        -2.11219626e-14, -9.32448714e-08, 1),
}

-- RODS (IDs & UUIDs from your input)
local RODS = {
    Midnight = { id = 80,  uuid = "6d977940-10bd-49e4-9dfb-aca505d7805e", name = "Midnight Rod" },
    Ares     = { id = 126, uuid = "a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5", name = "Ares Rod" },
    Starter  = { name = "Starter Rod" },
}

-- ROD DELAYS (from your buy.lua mapping)
local RodDelays = {
    ["Bamboo Rod"]   = 1.12,
    ["Element Rod"]  = 1.12,
    ["Ares Rod"]     = 1.45,
    ["Midnight Rod"] = 3.3,
    ["Starter Rod"]  = 4.3,
}

-- UTILS
local function safeInvoke(remote, ...)
    if not remote then return false end
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    return ok, res
end
local function safeFire(remote, ...)
    if not remote then return false end
    local ok, res = pcall(function() return remote:FireServer(...) end)
    return ok, res
end

local function TeleportTo(cf)
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf
        task.wait(0.45)
    end
end

local function GetCoins()
    local ok, val = pcall(function()
        if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Coins") then
            return Player.leaderstats.Coins.Value
        end
        return 0
    end)
    return ok and val or 0
end

-- QUEST counters (game should increment these)
_G.CatchRareTreasureRoom = _G.CatchRareTreasureRoom or 0
_G.CatchMythicSisy = _G.CatchMythicSisy or 0
_G.CatchSecretSisy = _G.CatchSecretSisy or 0

-- STATE
local KaitunRunning = false
local KaitunStage = "Idle"
local CurrentRodName = "Unknown"
local CurrentRodDelay = 1.0

local function setStage(s) KaitunStage = s end

-- ROD DETECTOR
local function detectRodFromCharacter()
    local char = Player.Character
    if not char then return nil end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            if RodDelays[obj.Name] then
                return obj.Name
            else
                return obj.Name -- if tool name unknown, still return it
            end
        end
    end
    -- also check Backpack
    local bp = Player:FindFirstChild("Backpack")
    if bp then
        for _, obj in ipairs(bp:GetChildren()) do
            if obj:IsA("Tool") and RodDelays[obj.Name] then
                return obj.Name
            end
        end
    end
    return nil
end

-- continuous detector loop
task.spawn(function()
    while true do
        local r = detectRodFromCharacter()
        if r then
            CurrentRodName = r
            CurrentRodDelay = RodDelays[r] or CurrentRodDelay
        else
            CurrentRodName = "None"
            CurrentRodDelay = RodDelays["Starter Rod"] or 1.0
        end
        task.wait(0.5)
    end
end)

-- AUTO FISH ON/OFF (only these should be used)
local function AutoFishON()
    if not RemoteReferences.UpdateAutoFishing then return false end
    -- ensure rod detected before turning on
    local tries = 0
    while (CurrentRodName == "None" or CurrentRodName == "Unknown") and tries < 6 do
        tries = tries + 1
        task.wait(0.4)
    end
    if CurrentRodName == "None" then
        -- try to equip starter slot 1 as fallback
        pcall(function() RemoteReferences.EquipRemote:FireServer(1) end)
        task.wait(0.5)
    end
    pcall(function() RemoteReferences.UpdateAutoFishing:InvokeServer(true) end)
    return true
end
local function AutoFishOFF()
    if RemoteReferences.UpdateAutoFishing then
        pcall(function() RemoteReferences.UpdateAutoFishing:InvokeServer(false) end)
    end
end

-- PURCHASE & EQUIP helpers
local function PurchaseRodById(id)
    if not RemoteReferences.PurchaseRod then return false end
    local ok = pcall(function() RemoteReferences.PurchaseRod:InvokeServer(id) end)
    return ok
end
local function EquipByUUID(uuid, category)
    if not RemoteReferences.EquipItem then return false end
    local ok = pcall(function() RemoteReferences.EquipItem:FireServer(uuid, category) end)
    return ok
end

-- CORE KAITUN FLOW (AutoFish only)
local function StartKaitunFlow()
    if KaitunRunning then return end
    KaitunRunning = true
    setStage("Start")

    -- STEP 1: Volcano -> farm until 50k
    setStage("Teleport -> Volcano")
    TeleportTo(TP.Volcano)
    setStage("Farming Starter -> to 50k")
    AutoFishON()
    repeat task.wait(0.5) until (not KaitunRunning) or GetCoins() >= 50000
    AutoFishOFF()
    if not KaitunRunning then return end

    -- STEP 2: Buy Midnight & Equip
    setStage("Buying Midnight")
    PurchaseRodById(RODS.Midnight.id)
    task.wait(0.3)
    EquipByUUID(RODS.Midnight.uuid, "Fishing Rods")
    task.wait(0.4)

    -- STEP 3: Treasure -> complete 300 Rare/Epic
    setStage("Teleport -> Treasure")
    TeleportTo(TP.Treasure)
    setStage("Catching Rare/Epic (300)")
    AutoFishON()
    repeat task.wait(0.5) until (not KaitunRunning) or (_G.CatchRareTreasureRoom >= 300)
    AutoFishOFF()
    if not KaitunRunning then return end

    -- STEP 4: Farm until 3M coins
    setStage("Farming to 3M")
    AutoFishON()
    repeat task.wait(0.5) until (not KaitunRunning) or GetCoins() >= 3000000
    AutoFishOFF()
    if not KaitunRunning then return end

    -- STEP 5: Buy Ares & Equip
    setStage("Buying Ares")
    PurchaseRodById(RODS.Ares.id)
    task.wait(0.3)
    EquipByUUID(RODS.Ares.uuid, "Fishing Rods")
    task.wait(0.4)

    -- STEP 6: Teleport Sisyphus -> Mythic(3) then Secret(1)
    setStage("Teleport -> Sisyphus")
    TeleportTo(TP.Sisyphus)
    setStage("Catching Mythic (3)")
    AutoFishON()
    repeat task.wait(0.5) until (not KaitunRunning) or (_G.CatchMythicSisy >= 3)
    setStage("Catching Secret (1)")
    repeat task.wait(0.5) until (not KaitunRunning) or (_G.CatchSecretSisy >= 1)
    AutoFishOFF()
    if not KaitunRunning then return end

    setStage("Finished")
    KaitunRunning = false
end

local function StopKaitunFlow()
    KaitunRunning = false
    AutoFishOFF()
    setStage("Stopped")
end

-- AUTO SELL loop
local AutoSell = false
task.spawn(function()
    while true do
        if AutoSell then
            pcall(function() RemoteReferences.SellRemote:InvokeServer() end)
        end
        task.wait(5)
    end
end)

-- WIND UI
local WindowUI = WindUI:CreateWindow({
    Title = "Axee Unreleased | v0.0.1",
    Icon = "door-open",
    Author = "gg/UARyY46axv",
})

-- MAIN TAB
local TabMain = WindowUI:Tab({ Title = "Main", Icon = "ship" })
TabMain:Select()

TabMain:Toggle({
    Title = "Kaitun",
    Desc  = "Start/Stop Ghostfinn Kaitun (AutoFish mode)",
    Default = false,
    Callback = function(value)
        if value then
            task.spawn(StartKaitunFlow)
            WindowUI:Notify({ Title = "Kaitun", Content = "Started", Duration = 2 })
        else
            StopKaitunFlow()
            WindowUI:Notify({ Title = "Kaitun", Content = "Stopped", Duration = 2 })
        end
    end
})

-- Status label
local statusLabel = TabMain:Label({ Title = "Status", Desc = "Idle" })
task.spawn(function()
    while true do
        local coin = GetCoins()
        local desc = string.format("Stage:%s | Coins:%d | Rod:%s | Delay:%.2f", KaitunStage or "Idle", coin or 0, CurrentRodName or "None", CurrentRodDelay or 0)
        pcall(function() statusLabel:Set(desc) end)
        task.wait(0.7)
    end
end)

-- AUTO TAB
local TabAuto = WindowUI:Tab({ Title = "Auto", Icon = "settings" })

TabAuto:Toggle({
    Title = "Sell All",
    Desc  = "Sell all fish every 5 seconds",
    Default = false,
    Callback = function(v)
        AutoSell = v
        WindowUI:Notify({ Title = "Auto Sell", Content = (v and "Enabled" or "Disabled"), Duration = 2 })
    end
})

TabAuto:Button({
    Title = "Force Sell Now",
    Desc = "Instant sell",
    Callback = function()
        pcall(function() RemoteReferences.SellRemote:InvokeServer() end)
        WindowUI:Notify({ Title = "Sell", Content = "Forced sell executed", Duration = 2 })
    end
})

TabAuto:Button({
    Title = "Equip Starter (slot 1)",
    Desc = "Equip hotbar index 1",
    Callback = function()
        pcall(function() RemoteReferences.EquipRemote:FireServer(1) end)
    end
})

print("[Kaitun] Final script loaded. Rod detector active. Use UI to control.")