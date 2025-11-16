-- Axee Kaitun (WindUI) - single file
-- Requirements: WindUI loader available, sleitnick_net package present, your buy.lua / StartFishingV1 optionally loaded
-- Usage: run in real server (not dev studio) with proper data available

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    return warn("[Kaitun] Must run as LocalPlayer.")
end

-- WindUI loader
local okWind, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not okWind or not WindUI then
    return warn("[Kaitun] Failed to load WindUI.")
end

-- Window
local Window = WindUI:CreateWindow({
    Title = "Axee Unrealesed | v.0.0.1",
    Icon = "door-open",
    Author = "gg/UARyY46axv",
})

-- CFrames (from user)
local CF_KOHANA = CFrame.new(
    -546.500671, 16.2349777, 115.35006,
    1, -8.31874361e-11, -6.0212597e-16,
    8.31874361e-11, 1, 6.64656907e-09,
    6.01573069e-16, -6.64656907e-09, 1
)
local CF_TREASURE = CFrame.new(
    -3570.70264, -279.074188, -1599.13953,
    1, 4.67368437e-08, 9.49238721e-14,
    -4.67368437e-08, 1, 7.08577161e-08,
    -9.16122037e-14, -7.08577161e-08, 1
)
local CF_SISYPHUS = CFrame.new(
    -3737.87354, -135.073914, -888.212891,
    1, 1.06662927e-08, 2.21165402e-14,
    -1.06662927e-08, 1, 9.32448714e-08,
    -2.11219626e-14, -9.32448714e-08, 1
)

-- RemoteReferences table
local RemoteReferences = {}
local function SetupRemoteReferences()
    local suc, err = pcall(function()
        local idx = ReplicatedStorage:WaitForChild("Packages")._Index
        local netPkg = idx["sleitnick_net@0.2.0"]
        if not netPkg then error("sleitnick_net not found") end
        local net = netPkg.net or netPkg:WaitForChild("net")
        RemoteReferences.Net = net

        -- core remotes (use FindFirstChild where possible)
        local function g(n) return net:FindFirstChild(n) end
        RemoteReferences.ChargeRod = g("RF/ChargeFishingRod") or g("ChargeFishingRod")
        RemoteReferences.StartMini = g("RF/RequestFishingMinigameStarted") or g("RequestFishingMinigameStarted")
        RemoteReferences.FinishFish = g("RE/FishingCompleted") or g("FishingCompleted")
        RemoteReferences.FishCaught = g("RE/FishCaught") or g("RF/FishCaught")
        RemoteReferences.EquipHotbar = g("RE/EquipToolFromHotbar") or g("EquipToolFromHotbar")
        RemoteReferences.SellRemote = g("RF/SellAllItems") or g("SellAllItems")
        RemoteReferences.RadarRemote = g("RF/UpdateFishingRadar") or g("UpdateFishingRadar")
        RemoteReferences.UpdateAutoFishing = g("RF/UpdateAutoFishingState") or g("UpdateAutoFishingState")
        RemoteReferences.PurchaseRod = g("RF/PurchaseFishingRod") or g("PurchaseFishingRod")
        RemoteReferences.EquipItem = g("RE/EquipItem") or g("EquipItem")
    end)
    if not suc then
        warn("[Kaitun] SetupRemoteReferences failed:", err)
        return false
    end
    return true
end

-- Try to reuse StartFishingV1 if available (from buy.lua)
-- If not present, script will still attempt UpdateAutoFishing remote as fallback.
local function TryStartFishing()
    if type(StartFishingV1) == "function" then
        pcall(StartFishingV1)
        return true
    elseif type(StartFishingV2) == "function" then
        pcall(StartFishingV2)
        return true
    else
        if RemoteReferences.UpdateAutoFishing then
            pcall(function() RemoteReferences.UpdateAutoFishing:InvokeServer(true) end)
            return true
        end
    end
    return false
end
local function TryStopFishing()
    if type(StopFishingV1) == "function" then
        pcall(StopFishingV1)
    elseif type(StopFishingV2) == "function" then
        pcall(StopFishingV2)
    else
        if RemoteReferences.UpdateAutoFishing then
            pcall(function() RemoteReferences.UpdateAutoFishing:InvokeServer(false) end)
        end
    end
end

-- Read DeepSea progress from tracker GUI
local function GetDeepSeaProgress()
    local menu = Workspace:FindFirstChild("!!! MENU RINGS")
    if not menu then return 0 end
    local tracker = menu:FindFirstChild("Deep Sea Tracker")
    if not tracker then return 0 end
    local ok, label = pcall(function()
        return tracker.Board and tracker.Board:FindFirstChild("Gui")
            and tracker.Board.Gui:FindFirstChild("Content")
            and tracker.Board.Gui.Content:FindFirstChild("Progress")
            and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
    end)
    if not ok or not label then return 0 end
    if label:IsA("TextLabel") then
        local percent = tostring(label.Text):match("([%d%.]+)%%")
        return tonumber(percent) or 0
    end
    return 0
end

-- Coin detection: try Runner, then RF/GetPlayerData, leaderstats, HUD parse
local function TryRunnerCoins()
    local ok, rf = pcall(function()
        local rfsvc = game:GetService("ReplicatedFirst")
        local g = rfsvc:FindFirstChild("GAME")
        if not g then return nil end
        local r = g:FindFirstChild("Runner")
        if not r then return nil end
        local suc, data = pcall(function() return r:WaitForPlayerData() end)
        if suc and type(data) == "table" then
            if data.Coins then return tonumber(data.Coins) end
            if data.Currency and data.Currency.Coins then return tonumber(data.Currency.Coins) end
            if data.EarnedCoins then return tonumber(data.EarnedCoins) end
        end
        return nil
    end)
    if ok then return rf end
    return nil
end

local function TryRemoteGetPlayerDataCoins()
    local suc, net = pcall(function() return ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net end)
    if not suc or not net then return nil end
    local rf = net:FindFirstChild("RF/GetPlayerData") or net:FindFirstChild("GetPlayerData")
    if not rf then return nil end
    local ok, ret = pcall(function() return rf:InvokeServer() end)
    if ok and type(ret) == "table" then
        if ret.Coins then return tonumber(ret.Coins) end
        if ret.EarnedCoins then return tonumber(ret.EarnedCoins) end
    end
    return nil
end

local function TryLeaderstatsCoins()
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        for _,v in pairs(ls:GetChildren()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and (string.match(string.lower(v.Name),"coin") or string.match(string.lower(v.Name),"money")) then
                return tonumber(v.Value)
            end
        end
    end
    return nil
end

local function TryGuiCoins()
    local ok, hud = pcall(function() return player.PlayerGui:FindFirstChild("HUD") end)
    if not ok or not hud then return nil end
    for _,c in ipairs(hud:GetDescendants()) do
        if (c:IsA("TextLabel") or c:IsA("TextButton")) and tostring(c.Text) ~= "" then
            local txt = tostring(c.Text)
            if txt:find("%d+[%d,%.]*%s*[KkMm]?") and (txt:lower():find("coins") or txt:find("$")) then
                local raw = txt:match("(%d+[%d,%.]*%s*[KkMm]?)")
                if raw then
                    raw = raw:gsub(",","")
                    if raw:find("[Kk]") then
                        local v = tonumber(raw:match("(%d+%.?%d*)")) or 0
                        return math.floor(v * 1000)
                    end
                    if raw:find("[Mm]") then
                        local v = tonumber(raw:match("(%d+%.?%d*)")) or 0
                        return math.floor(v * 1000000)
                    end
                    local v = tonumber(raw:match("(%d+%.?%d*)"))
                    if v then return v end
                end
            end
        end
    end
    return nil
end

local function GetPlayerCoins()
    local v = TryRunnerCoins()
    if v and type(v) == "number" then return v end
    v = TryRemoteGetPlayerDataCoins()
    if v and type(v) == "number" then return v end
    v = TryLeaderstatsCoins()
    if v and type(v) == "number" then return v end
    v = TryGuiCoins()
    if v and type(v) == "number" then return v end
    return 0
end

-- Purchase & Equip helpers
local function PurchaseMidnight()
    if RemoteReferences.PurchaseRod then
        pcall(function() RemoteReferences.PurchaseRod:InvokeServer(80) end)
    end
end
local function EquipMidnight()
    if RemoteReferences.EquipItem then
        pcall(function() RemoteReferences.EquipItem:FireServer("6d977940-10bd-49e4-9dfb-aca505d7805e", "Fishing Rods") end)
    elseif RemoteReferences.EquipHotbar then
        pcall(function() RemoteReferences.EquipHotbar:FireServer(1) end)
    end
end
local function PurchaseAres()
    if RemoteReferences.PurchaseRod then
        pcall(function() RemoteReferences.PurchaseRod:InvokeServer(126) end)
    end
end
local function EquipAres()
    if RemoteReferences.EquipItem then
        pcall(function() RemoteReferences.EquipItem:FireServer("a8e8eb6c-ed6a-4e57-a70c-8e20d1ff7fe5", "Fishing Rods") end)
    elseif RemoteReferences.EquipHotbar then
        pcall(function() RemoteReferences.EquipHotbar:FireServer(1) end)
    end
end

-- Teleport helper
local function TeleportTo(cf)
    local ch = player.Character or player.CharacterAdded:Wait()
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf
    end
end

-- AutoSell loop
local AutoSellFlag = false
local function StartAutoSell()
    if AutoSellFlag then return end
    AutoSellFlag = true
    task.spawn(function()
        while AutoSellFlag do
            if RemoteReferences.SellRemote then
                pcall(function() RemoteReferences.SellRemote:InvokeServer() end)
            end
            task.wait(5)
        end
    end)
end
local function StopAutoSell()
    AutoSellFlag = false
end

-- Kaitun main flow
local KaitunFlag = false
local KaitunStage = "Idle"

local function setStage(s)
    KaitunStage = s
    if statusLabel and type(statusLabel.Set) == "function" then
        pcall(function() statusLabel:Set(string.format("Stage: %s | Coins: %d | Progress: %.1f%%", KaitunStage, GetPlayerCoins(), GetDeepSeaProgress())) end)
    end
end

local function StartKaitun()
    if KaitunFlag then return end
    KaitunFlag = true
    task.spawn(function()
        if not SetupRemoteReferences() then
            warn("[Kaitun] remotes not ready")
            KaitunFlag = false
            return
        end

        -- Stage 1: Teleport Kohana & farm starter until 50k coins
        setStage("Teleport -> Kohana")
        TeleportTo(CF_KOHANA)
        setStage("Farming starter rod")
        TryStartFishing()
        repeat task.wait(2) until (not KaitunFlag) or (GetPlayerCoins() >= 50000)
        TryStopFishing()
        if not KaitunFlag then return end

        -- Buy Midnight & equip
        setStage("Buying Midnight")
        PurchaseMidnight()
        task.wait(0.6)
        EquipMidnight()
        task.wait(0.6)

        -- Teleport to Treasure and complete 300 Rare/Epic (progress 25% threshold)
        setStage("Teleport -> Treasure")
        TeleportTo(CF_TREASURE)
        setStage("Farming Rare/Epic")
        TryStartFishing()
        repeat task.wait(2) until (not KaitunFlag) or (GetDeepSeaProgress() >= 25)
        TryStopFishing()
        if not KaitunFlag then return end

        -- If progress < 100 keep farming until either progress 100 or coins 3M
        setStage("Farm until 3M or quest done")
        TryStartFishing()
        repeat task.wait(2) until (not KaitunFlag) or (GetDeepSeaProgress() >= 100) or (GetPlayerCoins() >= 3000000)
        TryStopFishing()
        if not KaitunFlag then return end

        -- If coins >= 3M and not yet progress complete -> buy Ares and go Sisyphus
        if GetPlayerCoins() >= 3000000 and GetDeepSeaProgress() < 100 then
            setStage("Buy Ares & Teleport Sisyphus")
            PurchaseAres()
            task.wait(0.8)
            EquipAres()
            task.wait(0.4)
            TeleportTo(CF_SISYPHUS)
            setStage("Farming Mythic/Secret")
            TryStartFishing()
            repeat task.wait(2) until (not KaitunFlag) or (GetDeepSeaProgress() >= 100)
            TryStopFishing()
        end

        -- Finished
        setStage("Finished")
        -- ensure auto fishing off
        pcall(TryStopFishing)
        KaitunFlag = false
    end)
end

local function StopKaitun()
    KaitunFlag = false
    TryStopFishing()
    StopAutoSell()
    setStage("Stopped")
end

-- ---------- WindUI: Tabs & Controls ----------
local TabMain = Window:Tab({ Title = "Main", Icon = "ship" })
TabMain:Select()

-- Kaitun Toggle
local KaitunToggle = TabMain:Toggle({
    Title = "Kaitun",
    Desc = "Auto run Ghostfinn Kaitun flow",
    Default = false,
    Callback = function(val)
        if val then
            StartKaitun()
        else
            StopKaitun()
        end
    end
})

-- status label (using WindUI Label)
statusLabel = TabMain:Label({ Title = "Status", Desc = "Idle" })
-- update label periodically
task.spawn(function()
    while true do
        pcall(function()
            if statusLabel and statusLabel.Set then
                statusLabel:Set(string.format("Stage: %s | Coins: %d | Progress: %.1f%%", KaitunStage or "Idle", GetPlayerCoins(), GetDeepSeaProgress()))
            end
        end)
        task.wait(1)
    end
end)

-- Auto tab
local TabAuto = Window:Tab({ Title = "Auto", Icon = "settings" })

local AutoSellToggle = TabAuto:Toggle({
    Title = "Sell All",
    Desc = "Sell all fish every 5 seconds",
    Default = false,
    Callback = function(v)
        if v then StartAutoSell() else StopAutoSell() end
    end
})

TabAuto:Button({
    Title = "Force Sell Now",
    Desc = "Invoke Sell remote immediately",
    Callback = function()
        if RemoteReferences.SellRemote then pcall(function() RemoteReferences.SellRemote:InvokeServer() end) end
    end
})

TabAuto:Button({
    Title = "Equip Starter (hotbar 1)",
    Desc = "Equip hotbar slot 1",
    Callback = function()
        if RemoteReferences.EquipHotbar then pcall(function() RemoteReferences.EquipHotbar:FireServer(1) end) end
    end
})

-- expose simple commands in global for fallback
_G.run_kaitun = function() if not KaitunFlag then StartKaitun() end end
_G.stop_kaitun = function() StopKaitun() end
_G.start_autosell = function() StartAutoSell() end
_G.stop_autosell = function() StopAutoSell() end

-- auto setup remotes at load
pcall(SetupRemoteReferences)

print("[Kaitun] WindUI Kaitun ready. Use the WindUI toggles to control.")