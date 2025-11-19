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
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

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

    -- ENABLE AUTO FISHING
    pcall(function()
        RemoteReferences.UpdateAutoFishing:InvokeServer(true)
    end)

    -- AUTO EQUIP ROD
    pcall(function()
        RemoteReferences.EquipRemote:FireServer()
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

    -- LOOP UNTUK AUTO FISHING
    task.spawn(function()
        while Config.AutoFishing do
            task.wait(1)
        end

        -- STOP AUTO FISHING + UNEQUIP ROD
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

-- Toggle Auto Fishing
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

-- Toggle Auto Sell
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

-- Button Buy Steampunk Rod (InvokeServer + Notif)
TabFishing:CreateButton({
    Name = "Buy Steampunk Rod",
    Callback = function()
        pcall(function()
            local RodId = 6 -- Steampunk Rod ID
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
        hrp.CFrame = Locations.Volcano
    end
})

TabTeleport:CreateButton({
    Name = "Treasure Room",
    Callback = function()
        hrp.CFrame = Locations.Treasure
    end
})

TabTeleport:CreateButton({
    Name = "Sisyphus Statue",
    Callback = function()
        hrp.CFrame = Locations.Sisyphus
    end
})

--== TAB: GHOSTFINN QUEST ==--
local TabGhostfinnQuest = Window:CreateTab("Ghostfinn Quest", "fish")

-- TREASURE QUEST
local TreasureQuestParagraph = TabGhostfinnQuest:CreateParagraph({
    Title = "Treasure Quest Info",
    Content = "Waiting to track Treasure Quest..."
})

local TreasureQuestConfig = {
    Active = false,
    Name = "Catch 300 Rare/Epic fish in the Treasure Room",
    Key = "CatchRareTreasureRoom",
    Value = 300,
    Location = Locations.Treasure
}

TabGhostfinnQuest:CreateToggle({
    Name = "Start Treasure Mission",
    CurrentValue = false,
    Flag = "StartTreasureMission",
    Callback = function(Value)
        TreasureQuestConfig.Active = Value
        if Value then
            task.spawn(function()
                hrp.CFrame = TreasureQuestConfig.Location
                StartFishing()

                while TreasureQuestConfig.Active do
                    local function GetQuestTracker(questName)
                        local menu = WorkspaceService:FindFirstChild("!!! MENU RINGS")
                        if not menu then return nil end
                        for _, instance in ipairs(menu:GetChildren()) do
                            if instance.Name:find("Tracker") and instance.Name:lower():find(questName:lower()) then
                                return instance
                            end
                        end
                        return nil
                    end

                    local function GetQuestProgress(questName)
                        local tracker = GetQuestTracker(questName)
                        if not tracker then return 0 end
                        local label = tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui")
                            and tracker.Board.Gui:FindFirstChild("Content")
                            and tracker.Board.Gui.Content:FindFirstChild("Progress")
                            and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
                        if label and label:IsA("TextLabel") then
                            local percent = string.match(label.Text, "([%d%.]+)%%")
                            return tonumber(percent) or 0
                        end
                        return 0
                    end

                    local progress = GetQuestProgress(TreasureQuestConfig.Name)
                    TreasureQuestParagraph:Set({
                        Title = "Treasure Quest Progress",
                        Content = TreasureQuestConfig.Name.." - "..progress.."% complete"
                    })
                    if progress >= 100 then
                        StopFishing()
                        TreasureQuestConfig.Active = false
                        TreasureQuestParagraph:Set({
                            Title = "Treasure Quest Completed",
                            Content = "✅ Treasure Quest Finished!"
                        })
                        break
                    end
                    task.wait(5)
                end
            end)
        else
            StopFishing()
        end
    end
})

-- SISYPHUS QUEST
local SisyphusQuestParagraph = TabGhostfinnQuest:CreateParagraph({
    Title = "Sisyphus Quest Info",
    Content = "Waiting to track Sisyphus Quest..."
})

local SisyphusQuestConfig = {
    Active = false,
    Quests = {
        {
            Name = "Catch 3 Mythic fish at Sisyphus Statue",
            Key = "CatchFish",
            Value = 3,
            Tier = 6,
            Location = Locations.Sisyphus
        },
        {
            Name = "Catch 1 SECRET fish at Sisyphus Statue",
            Key = "CatchFish",
            Value = 1,
            Tier = 7,
            Location = Locations.Sisyphus
        }
    }
}

TabGhostfinnQuest:CreateToggle({
    Name = "Start Sisyphus Mission",
    CurrentValue = false,
    Flag = "StartSisyphusMission",
    Callback = function(Value)
        SisyphusQuestConfig.Active = Value
        if Value then
            task.spawn(function()
                for _, quest in ipairs(SisyphusQuestConfig.Quests) do
                    hrp.CFrame = quest.Location
                    StartFishing()

                    while SisyphusQuestConfig.Active do
                        local function GetQuestTracker(questName)
                            local menu = WorkspaceService:FindFirstChild("!!! MENU RINGS")
                            if not menu then return nil end
                            for _, instance in ipairs(menu:GetChildren()) do
                                if instance.Name:find("Tracker") and instance.Name:lower():find(questName:lower()) then
                                    return instance
                                end
                            end
                            return nil
                        end

                        local function GetQuestProgress(questName)
                            local tracker = GetQuestTracker(questName)
                            if not tracker then return 0 end
                            local label = tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui")
                                and tracker.Board.Gui:FindFirstChild("Content")
                                and tracker.Board.Gui.Content:FindFirstChild("Progress")
                                and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
                            if label and label:IsA("TextLabel") then
                                local percent = string.match(label.Text, "([%d%.]+)%%")
                                return tonumber(percent) or 0
                            end
                            return 0
                        end

                        local progress = GetQuestProgress(quest.Name)
                        SisyphusQuestParagraph:Set({
                            Title = "Sisyphus Quest Progress",
                            Content = quest.Name.." - "..progress.."% complete"
                        })
                        if progress >= 100 then
                            StopFishing()
                            break
                        end
                        task.wait(5)
                    end
                end

                SisyphusQuestConfig.Active = false
                SisyphusQuestParagraph:Set({
                    Title = "All Sisyphus Quests Completed",
                    Content = "✅ Sisyphus Missions Finished!"
                })
            end)
        else
            StopFishing()
        end
    end
})