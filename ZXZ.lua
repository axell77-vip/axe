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

-- LOCATIONS
local Locations = {
    Volcano = CFrame.new(-546.500671, 16.2349777, 115.35006),
    Treasure = CFrame.new(-3570.70264, -279.074188, -1599.13953, 1, 4.67368437e-08, 9.49238721e-14, -4.67368437e-08, 1, 7.08577161e-08, -9.16122037e-14, -7.08577161e-08, 1),
    Sisyphus = CFrame.new(-3737.87354, -135.073914, -888.212891, 1, 1.06662927e-08, 2.21165402e-14, -1.06662927e-08, 1, 9.32448714e-08, -2.11219626e-14, -9.32448714e-08, 1),
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

--== TAB: GHOSTFINN AUTO CLEAN ==--
local TabGhostfinn = Window:CreateTab("Ghostfinn Auto", "fish")

local QuestParagraph = TabGhostfinn:CreateParagraph({
    Title = "Quest Info",
    Content = "Waiting for quests..."
})

local GhostfinnConfig = {
    Active = false,
    QuestList = {
        {Name = "Treasure Quest", Key = "CatchRareTreasureRoom", Location = Locations.Treasure},
        {Name = "Sisyphus Mythic Quest", Key = "3mythic", Location = Locations.Sisyphus},
        {Name = "Sisyphus Secret Quest", Key = "1secret", Location = Locations.Sisyphus},
    }
}

-- HELPER FUNCTIONS
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

TabGhostfinn:CreateToggle({
    Name = "Enable Ghostfinn Auto",
    CurrentValue = false,
    Flag = "GhostfinnAuto",
    Callback = function(Value)
        GhostfinnConfig.Active = Value
        if Value then
            task.spawn(function()
                while GhostfinnConfig.Active do
                    local paragraphContent = ""
                    local allDone = true

                    -- TREASURE QUEST
                    local treasureProg = GetQuestProgress("CatchRareTreasureRoom")
                    paragraphContent = paragraphContent .. "Treasure Quest - " .. treasureProg .. "%\n"
                    if treasureProg < 100 then
                        allDone = false
                        pcall(function() hrp.CFrame = GhostfinnConfig.QuestList[1].Location end)
                        pcall(function() StartFishing() end)
                    end

                    -- SISYPHUS QUESTS
                    if treasureProg >= 100 then
                        local mythicProg = GetQuestProgress("3mythic")
                        paragraphContent = paragraphContent .. "Sisyphus Mythic Quest - " .. mythicProg .. "%\n"
                        if mythicProg < 100 then
                            allDone = false
                            pcall(function() hrp.CFrame = GhostfinnConfig.QuestList[2].Location end)
                            pcall(function() StartFishing() end)
                        end

                        local secretProg = GetQuestProgress("1secret")
                        paragraphContent = paragraphContent .. "Sisyphus Secret Quest - " .. secretProg .. "%\n"
                        if secretProg < 100 then
                            allDone = false
                            pcall(function() hrp.CFrame = GhostfinnConfig.QuestList[3].Location end)
                            pcall(function() StartFishing() end)
                        end
                    end

                    QuestParagraph:Set({
                        Title = "Ghostfinn Auto",
                        Content = paragraphContent
                    })

                    -- StopFishing ketika semua quest selesai
                    if allDone then
                        pcall(function() StopFishing() end)
                        QuestParagraph:Set({
                            Title = "Ghostfinn Auto",
                            Content = "✅ All Quests Completed!"
                        })
                        break
                    end

                    task.wait(5)
                end
            end)
        else
            pcall(function() StopFishing() end)
            QuestParagraph:Set({
                Title = "Ghostfinn Auto",
                Content = "Stopped by user"
            })
        end
    end
})