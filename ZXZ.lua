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

-- LOCATIONS MANUAL (TAB TELEPORT)
local Locations = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953,
        1, 4.67368437e-08, 9.49238721e-14,
        -4.67368437e-08, 1, 7.08577161e-08,
        -9.16122037e-14, -7.08577161e-08, 1),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891,
        1, 1.06662927e-08, 2.21165402e-14,
        -1.06662927e-08, 1, 9.32448714e-08,
        -2.11219626e-14, -9.32448714e-08, 1),
}

-- LOCATIONS QUEST (AUTO QUEST)
local QuestLocations = {
    TreasureQuest = Locations.Treasure,
    SisyphusQuest = Locations.Sisyphus
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

    pcall(function() RemoteReferences.EquipRemote:FireServer() end)
    task.wait(0.5)

    pcall(function() RemoteReferences.UpdateAutoFishing:InvokeServer(true) end)

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

    task.spawn(function()
        while Config.AutoFishing do task.wait(1) end
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
        if Value then StartFishing() else StopFishing() end
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
                pcall(function() RemoteReferences.SellRemote:InvokeServer() end)
            end
        end)
    end
})

TabFishing:CreateButton({
    Name = "Buy Steampunk Rod",
    Callback = function()
        pcall(function()
            local RodId = 6
            local success, response = pcall(function() return RemoteReferences.RodPurchase:InvokeServer(RodId) end)
            if success then
                Rayfield:Notify({Title="✅ Rod Purchase", Content="Steampunk Rod purchase sent!", Duration=5, Image=4483362458})
            else
                Rayfield:Notify({Title="❌ Rod Purchase Failed", Content=tostring(response), Duration=5, Image=4483362458})
            end
        end)
    end
})

--== TAB: TELEPORT ==--
local TabTeleport = Window:CreateTab("Teleport", "map")

TabTeleport:CreateButton({Name="Volcano", Callback=function() hrp.CFrame = Locations.Volcano end})
TabTeleport:CreateButton({Name="Treasure Room", Callback=function() hrp.CFrame = Locations.Treasure end})
TabTeleport:CreateButton({Name="Sisyphus Statue", Callback=function() hrp.CFrame = Locations.Sisyphus end})

--== TAB: GHOSTFINN AUTO ==--
local TabGhostfinn = Window:CreateTab("Ghostfinn Auto", "fish")

local QuestParagraph = TabGhostfinn:CreateParagraph({Title="Quest Info", Content="Waiting to track quests..."})

local GhostfinnConfig = {
    Active = false,
    QuestList = {
        {
            Name = "Catch 300 Rare/Epic fish in Treasure Room",
            Key = "CatchRareTreasureRoom",
            Location = QuestLocations.TreasureQuest
        },
        {
            Name = "Catch 3 Mythic fish at Sisyphus Statue",
            Key = "3mythic",
            Location = QuestLocations.SisyphusQuest
        },
        {
            Name = "Catch 1 SECRET fish at Sisyphus Statue",
            Key = "1secret",
            Location = QuestLocations.SisyphusQuest
        }
    }
}

TabGhostfinn:CreateToggle({
    Name = "Enable Ghostfinn Auto",
    CurrentValue = false,
    Flag = "GhostfinnAuto",
    Callback = function(Value)
        GhostfinnConfig.Active = Value
        if Value then
            task.spawn(function()
                local currentQuestIndex = 1
                while GhostfinnConfig.Active and currentQuestIndex <= #GhostfinnConfig.QuestList do
                    local quest = GhostfinnConfig.QuestList[currentQuestIndex]

                    -- Update paragraph with all quests
                    local statusText = ""
                    for _, q in ipairs(GhostfinnConfig.QuestList) do
                        local tracker = WorkspaceService:FindFirstChild("!!! MENU RINGS") and WorkspaceService["!!! MENU RINGS"]:FindFirstChild(q.Key)
                        local progress = 0
                        if tracker and tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui") then
                            local label = tracker.Board.Gui.Content.Progress.ProgressLabel
                            if label then progress = tonumber(string.match(label.Text, "([%d%.]+)%%")) or 0 end
                        end
                        statusText = statusText..q.Name.." - "..progress.."%\n"
                    end
                    QuestParagraph:Set({Title="Ghostfinn Quest Tracking", Content=statusText})

                    -- Teleport ke quest location only if progress < 100
                    local tracker = WorkspaceService:FindFirstChild("!!! MENU RINGS") and WorkspaceService["!!! MENU RINGS"]:FindFirstChild(quest.Key)
                    local progress = 0
                    if tracker and tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui") then
                        local label = tracker.Board.Gui.Content.Progress.ProgressLabel
                        if label then progress = tonumber(string.match(label.Text, "([%d%.]+)%%")) or 0 end
                    end

                    if progress < 100 then
                        pcall(function() hrp.CFrame = quest.Location end)
                        pcall(StartFishing)
                        repeat task.wait(5)
                            -- Refresh paragraph
                            local statusText2 = ""
                            for _, q in ipairs(GhostfinnConfig.QuestList) do
                                local tracker = WorkspaceService:FindFirstChild("!!! MENU RINGS") and WorkspaceService["!!! MENU RINGS"]:FindFirstChild(q.Key)
                                local progress = 0
                                if tracker and tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui") then
                                    local label = tracker.Board.Gui.Content.Progress.ProgressLabel
                                    if label then progress = tonumber(string.match(label.Text, "([%d%.]+)%%")) or 0 end
                                end
                                statusText2 = statusText2..q.Name.." - "..progress.."%\n"
                            end
                            QuestParagraph:Set({Title="Ghostfinn Quest Tracking", Content=statusText2})
                        until progress >= 100
                        pcall(StopFishing)
                    end

                    currentQuestIndex += 1
                end
            end)
        else
            pcall(StopFishing)
            QuestParagraph:Set({Title="Ghostfinn Auto", Content="Stopped by user"})
        end
    end
})