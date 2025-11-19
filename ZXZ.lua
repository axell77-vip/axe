-- LOADER UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- WINDOW
local Window = Rayfield:CreateWindow({
   Name = "Axee | Unpublished",
   Icon = 0,
   LoadingTitle = "Axee Interface",
   LoadingSubtitle = "Private Script",
   ShowText = "Axee",
   Theme = "Default"
})

-- SERVICES
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local WorkspaceService = game:GetService("Workspace")
local player = Players.LocalPlayer

-- SAFE HRP FUNCTION
local function GetHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
end

-- SAFE TELEPORT FUNCTION
local function SafeTeleport(cf)
    local root = GetHRP()
    if typeof(cf) == "CFrame" then
        root.CFrame = cf
    else
        warn("Invalid CFrame for teleport.")
    end
end

-- REMOTES
local RemoteReferences = {}
RemoteReferences.Net = RepStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net
RemoteReferences.EquipRemote = RemoteReferences.Net:WaitForChild("RE/EquipToolFromHotbar")
RemoteReferences.UnequipRemote = RemoteReferences.Net:WaitForChild("RE/UnequipToolFromHotbar")
RemoteReferences.UpdateAutoFishing = RemoteReferences.Net:WaitForChild("RF/UpdateAutoFishingState")
RemoteReferences.SellRemote = RemoteReferences.Net:WaitForChild("RF/SellAllItems")
RemoteReferences.RodPurchase = RemoteReferences.Net:WaitForChild("RF/PurchaseFishingRod")
RemoteReferences.StartMini = RemoteReferences.Net:WaitForChild("RF/RequestFishingMinigameStarted")

-- LOCATIONS
local Locations = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891),
}

-- CONFIG
local Config = {
    AutoFishing = false,
    AutoSell = false,
    PerfectCatch = true,
}
local FishingActive = false

--== FISHING FUNCTIONS ==--
local function StartFishing()
    if FishingActive then return end
    FishingActive = true
    Config.AutoFishing = true

    -- AUTO EQUIP ROD
    pcall(function()
        RemoteReferences.EquipRemote:FireServer()
    end)
    task.wait(0.5)

    -- ENABLE AUTO FISHING
    pcall(function()
        RemoteReferences.UpdateAutoFishing:InvokeServer(true)
    end)

    -- PERFECT CATCH HOOK
    if Config.PerfectCatch then
        local mt = getrawmetatable(game)
        if mt then
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "InvokeServer" and self == RemoteReferences.StartMini and Config.AutoFishing then
                    return oldNamecall(self, -1.233184814453125, 0.9945034885633273)
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end
    end

    -- AUTO FISHING LOOP
    task.spawn(function()
        while Config.AutoFishing do
            task.wait(1)
        end
        pcall(function()
            RemoteReferences.UpdateAutoFishing:InvokeServer(false)
            RemoteReferences.UnequipRemote:FireServer()
        end)
        FishingActive = false
    end)
end

local function StopFishing()
    Config.AutoFishing = false
end

--== TAB: FISHING FEATURE ==--
local TabFishing = Window:CreateTab("Fishing Feature", "bird")

TabFishing:CreateToggle({
    Name = "Auto Fishing",
    CurrentValue = false,
    Flag = "AutoFishing",
    Callback = function(Value)
        if Value then
            StartFishing()
        else
            StopFishing()
        end
    end
})

TabFishing:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(Value)
        Config.AutoSell = Value
        task.spawn(function()
            while Config.AutoSell do
                task.wait(3)
                pcall(function()
                    RemoteReferences.SellRemote:InvokeServer()
                end)
            end
        end)
    end
})

TabFishing:CreateButton({
    Name = "Buy Steampunk Rod",
    Callback = function()
        pcall(function()
            local RodId = 6
            local success, response = pcall(function()
                return RemoteReferences.RodPurchase:InvokeServer(RodId)
            end)
            if success then
                Rayfield:Notify({
                    Title = "✅ Rod Purchase",
                    Content = "Steampunk Rod purchase sent!",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "❌ Rod Purchase Failed",
                    Content = tostring(response),
                    Duration = 5,
                    Image = 4483362458
                })
            end
        end)
    end
})

--== TAB: TELEPORT ==--
local TabTeleport = Window:CreateTab("Teleport", "map")

TabTeleport:CreateButton({
    Name = "Volcano",
    Callback = function()
        SafeTeleport(Locations.Volcano)
    end
})

TabTeleport:CreateButton({
    Name = "Treasure Room",
    Callback = function()
        SafeTeleport(Locations.Treasure)
    end
})

TabTeleport:CreateButton({
    Name = "Sisyphus Statue",
    Callback = function()
        SafeTeleport(Locations.Sisyphus)
    end
})

--== TAB: GHOSTFINN AUTO ==--
local TabGhostfinn = Window:CreateTab("Ghostfinn Auto", "fish")

local QuestParagraph = TabGhostfinn:CreateParagraph({
    Title = "Quest Info",
    Content = "Waiting to track quests..."
})

-- GHOSTFINN CONFIG: semua quest digabung 1 paragraph
local GhostfinnConfig = {
    Active = false,
    QuestList = {
        {
            Name = "Treasure Room Quest",
            Key = "CatchRareTreasureRoom",
            Location = Locations.Treasure
        },
        {
            Name = "Sisyphus Mythic Quest",
            Key = "3mythic",
            Location = Locations.Sisyphus
        },
        {
            Name = "Sisyphus Secret Quest",
            Key = "1secret",
            Location = Locations.Sisyphus
        }
    }
}

-- helper tracker/progress
local function GetQuestTrackerByKey(key)
    local menu = WorkspaceService:FindFirstChild("!!! MENU RINGS")
    if not menu then return nil end
    for _, inst in ipairs(menu:GetChildren()) do
        if inst.Name:find("Tracker") and inst.Name:lower():find(key:lower()) then
            return inst
        end
    end
    return nil
end

local function GetQuestProgressByKey(key)
    local tracker = GetQuestTrackerByKey(key)
    if not tracker then return 0 end
    local ok, label = pcall(function()
        return tracker.Board
            and tracker.Board:FindFirstChild("Gui")
            and tracker.Board.Gui:FindFirstChild("Content")
            and tracker.Board.Gui.Content:FindFirstChild("Progress")
            and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
    end)
    if not ok or not label or not label:IsA("TextLabel") then return 0 end
    local pct = string.match(label.Text, "([%d%.]+)%%")
    return tonumber(pct) or 0
end

-- CREATE 1 TOGGLE 1 PARAGRAPH
TabGhostfinn:CreateToggle({
    Name = "Enable Ghostfinn Auto",
    CurrentValue = false,
    Flag = "GhostfinnAuto",
    Callback = function(Value)
        GhostfinnConfig.Active = Value
        if Value then
            task.spawn(function()
                local teleported = {}
                while GhostfinnConfig.Active do
                    local contentLines = {}
                    local allDone = true
                    for _, quest in ipairs(GhostfinnConfig.QuestList) do
                        local progress = GetQuestProgressByKey(quest.Key)
                        table.insert(contentLines, quest.Name .. " - " .. progress .. "%")
                        if progress < 100 then
                            allDone = false
                            -- teleport & start fishing if progress > 0 and not teleported yet
                            if progress > 0 and not teleported[quest.Key] then
                                SafeTeleport(quest.Location)
                                teleported[quest.Key] = true
                                -- equip rod & start fishing
                                pcall(function()
                                    if RemoteReferences.EquipRemote then
                                        RemoteReferences.EquipRemote:FireServer()
                                    end
                                    task.wait(0.5)
                                    StartFishing()
                                end)
                            end
                        end
                    end

                    -- update single paragraph
                    QuestParagraph:Set({
                        Title = "Ghostfinn Quest Tracking",
                        Content = table.concat(contentLines, "\n")
                    })

                    -- stop fishing jika semua done
                    if allDone then
                        StopFishing()
                        GhostfinnConfig.Active = false
                        Rayfield:Notify({
                            Title = "Ghostfinn Auto",
                            Content = "✅ All Quests Completed",
                            Duration = 5
                        })
                        break
                    end

                    task.wait(5)
                end
            end)
        else
            StopFishing()
            QuestParagraph:Set({
                Title = "Ghostfinn Auto",
                Content = "Stopped by user"
            })
        end
    end
})