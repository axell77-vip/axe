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
RemoteReferences.ChargeRod = RemoteReferences.Net:WaitForChild("RF/ChargeFishingRod")
RemoteReferences.FishingCompleted = RemoteReferences.Net:WaitForChild("RE/FishingCompleted")

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

--== QUEST TRACKING FUNCTION ==--
local function GetQuestProgress(questKey)
    local trackerRoot = WorkspaceService:FindFirstChild("!!! MENU RINGS")
    if not trackerRoot then return 0 end

    local totalProgress = 0
    for _, tracker in ipairs(trackerRoot:GetChildren()) do
        if tracker.Name:find("Tracker") and tracker.Name:lower():find(questKey:lower()) then
            local board = tracker:FindFirstChild("Board")
            if board then
                local gui = board:FindFirstChild("Gui")
                if gui and gui:FindFirstChild("Content") and gui.Content:FindFirstChild("Progress") then
                    local label = gui.Content.Progress:FindFirstChild("ProgressLabel")
                    if label and label:IsA("TextLabel") then
                        local percent = string.match(label.Text, "([%d%.]+)%%")
                        if percent then
                            totalProgress = tonumber(percent) or totalProgress
                        else
                            local current, goal = string.match(label.Text, "(%d+)%s*/%s*(%d+)")
                            if current and goal then
                                totalProgress = math.floor((tonumber(current)/tonumber(goal))*100)
                            end
                        end
                    end
                end
            end
        end
    end
    return totalProgress
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
    Title = "Treasure Quest",
    Content = "Waiting to track Treasure quest..."
})

local TreasureQuestConfig = {
    Active = false,
    Name = "Catch 300 Rare/Epic fish",
    Key = "CatchRareTreasureRoom",
    Value = 300,
    Location = Locations.Treasure,
    LocationName = "Treasure Room"
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
                    task.wait(5)
                    local progress = GetQuestProgress(TreasureQuestConfig.Key)
                    TreasureQuestParagraph:Set({
                        Title = "Treasure Quest",
                        Content = TreasureQuestConfig.Name.." at "..TreasureQuestConfig.LocationName.." - "..progress.."% complete"
                    })
                    if progress >= 100 then
                        StopFishing()
                        TreasureQuestConfig.Active = false
                        break
                    end
                end
            end)
        else
            StopFishing()
        end
    end
})

-- SISYPHUS QUEST
local SisyphusQuestParagraph = TabGhostfinnQuest:CreateParagraph({
    Title = "Sisyphus Quests",
    Content = "Waiting to track Sisyphus quests..."
})

local SisyphusQuestList = {
    {
        Name = "Catch 3 Mythic fish",
        Key = "CatchFish",
        Value = 3,
        Tier = 6,
        Location = Locations.Sisyphus,
        LocationName = "Sisyphus Statue"
    },
    {
        Name = "Catch 1 SECRET fish",
        Key = "CatchFish",
        Value = 1,
        Tier = 7,
        Location = Locations.Sisyphus,
        LocationName = "Sisyphus Statue"
    }
}

TabGhostfinnQuest:CreateToggle({
    Name = "Start Sisyphus Mission",
    CurrentValue = false,
    Flag = "StartSisyphusMission",
    Callback = function(Value)
        local CurrentIndex = 1
        local Active = Value
        if Value then
            task.spawn(function()
                while Active do
                    local quest = SisyphusQuestList[CurrentIndex]
                    if not quest then break end
                    hrp.CFrame = quest.Location
                    StartFishing()
                    while Active do
                        task.wait(5)
                        local progress = GetQuestProgress(quest.Key)
                        SisyphusQuestParagraph:Set({
                            Title = "Sisyphus Quests",
                            Content = quest.Name.." at "..quest.LocationName.." - "..progress.."% complete"
                        })
                        if progress >= 100 then
                            StopFishing()
                            CurrentIndex += 1
                            if CurrentIndex > #SisyphusQuestList then
                                Active = false
                                break
                            else
                                break
                            end
                        end
                    end
                end
            end)
        else
            StopFishing()
        end
    end
})