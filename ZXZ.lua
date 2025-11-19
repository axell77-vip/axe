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

--== TAB: GHOSTFINN AUTO ==--
local TabGhostfinn = Window:CreateTab("Ghostfinn Auto", "fish")

local QuestParagraph = TabGhostfinn:CreateParagraph({
    Title = "Quest Info",
    Content = "Waiting to track quests..."
})

local GhostfinnConfig = {
    Active = false,
    QuestList = {
        {Name="Treasure Room Quest", Key="CatchRareTreasureRoom", Location=Locations.Treasure},
        {Name="Sisyphus Mythic Quest", Key="3mythic", Location=Locations.Sisyphus},
        {Name="Sisyphus Secret Quest", Key="1secret", Location=Locations.Sisyphus},
    }
}

local function GetQuestProgressByKey(key)
    local menu = WorkspaceService:FindFirstChild("!!! MENU RINGS")
    if not menu then return 0 end
    for _, inst in ipairs(menu:GetChildren()) do
        if inst.Name:find("Tracker") and inst.Name:lower():find(key:lower()) then
            local ok, label = pcall(function()
                return inst.Board
                    and inst.Board:FindFirstChild("Gui")
                    and inst.Board.Gui:FindFirstChild("Content")
                    and inst.Board.Gui.Content:FindFirstChild("Progress")
                    and inst.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
            end)
            if ok and label and label:IsA("TextLabel") then
                local pct = string.match(label.Text, "([%d%.]+)%%")
                return tonumber(pct) or 0
            end
        end
    end
    return 0
end

local function SafeTeleport(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if typeof(cf) == "CFrame" then
        hrp.CFrame = cf
    end
end

TabGhostfinn:CreateToggle({
    Name = "Enable Ghostfinn Auto",
    CurrentValue = false,
    Flag = "GhostfinnAuto",
    Callback = function(state)
        GhostfinnConfig.Active = state
        if state then
            task.spawn(function()
                local teleported = {}
                while GhostfinnConfig.Active do
                    local allDone = true
                    local contentLines = {}
                    for i, quest in ipairs(GhostfinnConfig.QuestList) do
                        local progress = GetQuestProgressByKey(quest.Key)
                        table.insert(contentLines, quest.Name.." - "..progress.."%")

                        if progress < 100 then
                            allDone = false
                            -- teleport & start fishing jika belum teleport untuk quest ini
                            if not teleported[i] then
                                -- pastikan urutan: Sisyphus hanya setelah Treasure selesai
                                if quest.Name:find("Sisyphus") and GetQuestProgressByKey("CatchRareTreasureRoom") < 100 then
                                    break
                                end
                                SafeTeleport(quest.Location)
                                teleported[i] = true
                                if not Config.AutoFishing then
                                    StartFishing()
                                end
                            end
                        end
                    end

                    -- update paragraph real-time
                    QuestParagraph:Set({
                        Title = "Ghostfinn Quest Tracking",
                        Content = table.concat(contentLines, "\n")
                    })

                    -- semua quest 100% → stop fishing saja
                    if allDone then
                        StopFishing()
                        QuestParagraph:Set({
                            Title = "Ghostfinn Auto",
                            Content = "✅ All Quests Completed (Fishing stopped)"
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