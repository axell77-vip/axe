-- LOADER UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- WINDOW
local Window = Rayfield:CreateWindow({
   Name = "Axee | Unpublished",
   Icon = 0,
   LoadingTitle = "Axee Interface",
   LoadingSubtitle = "Private Script",
   ShowText = "Axee",
   Theme = "Bloom"
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

    -- AUTO EQUIP ROD terlebih dahulu
    pcall(function()
        if RemoteReferences.EquipRemote then
            RemoteReferences.EquipRemote:FireServer()
        end
    end)
    task.wait(0.5)

    -- ENABLE AUTO FISHING
    pcall(function()
        if RemoteReferences.UpdateAutoFishing then
            RemoteReferences.UpdateAutoFishing:InvokeServer(true)
        end
    end)

    -- PERFECT CATCH HOOK
    if Config.PerfectCatch then
        local success, mt = pcall(function() return getrawmetatable(game) end)
        if success and mt then
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
            if RemoteReferences.UpdateAutoFishing then
                RemoteReferences.UpdateAutoFishing:InvokeServer(false)
            end
            if RemoteReferences.UnequipRemote then
                RemoteReferences.UnequipRemote:FireServer()
            end
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
                    if RemoteReferences.SellRemote then
                        RemoteReferences.SellRemote:InvokeServer()
                    end
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
        pcall(function() hrp.CFrame = Locations.Volcano end)
    end
})

TabTeleport:CreateButton({
    Name = "Treasure Room",
    Callback = function()
        pcall(function() hrp.CFrame = Locations.Treasure end)
    end
})

TabTeleport:CreateButton({
    Name = "Sisyphus Statue",
    Callback = function()
        pcall(function() hrp.CFrame = Locations.Sisyphus end)
    end
})

--== TAB: GHOSTFINN AUTO ==--
local TabGhostfinn = Window:CreateTab("Ghostfinn Auto", "fish")

local QuestParagraph = TabGhostfinn:CreateParagraph({
    Title = "Quest Info",
    Content = "Waiting to track quests..."
})

-- Consolidated helper functions (single copy)
local function GetHRP()
    local c = player.Character or player.CharacterAdded:Wait()
    return c:WaitForChild("HumanoidRootPart")
end

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
        return tracker.Board and tracker.Board:FindFirstChild("Gui") 
            and tracker.Board.Gui:FindFirstChild("Content")
            and tracker.Board.Gui.Content:FindFirstChild("Progress")
            and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
    end)
    if not ok or not label or not label:IsA("TextLabel") then return 0 end
    local pct = string.match(label.Text, "([%d%.]+)%%")
    return tonumber(pct) or 0
end

-- Define the ordered quest list (sequential)
local GhostfinnQuestList = {
    {
        Id = "treasure",
        Display = "Catch 300 Rare/Epic fish in the Treasure Room",
        SearchKey = "CatchRareTreasureRoom",
        Location = Locations.Treasure,
    },
    {
        Id = "sisyphus_mythic",
        Display = "Catch 3 Mythic fish at Sisyphus Statue",
        SearchKey = "3mythic", -- menggunakan key versi Sisyphus yang lo berikan
        Location = Locations.Sisyphus,
    },
    {
        Id = "sisyphus_secret",
        Display = "Catch 1 SECRET fish at Sisyphus Statue",
        SearchKey = "1secret", -- menggunakan key versi Sisyphus yang lo berikan
        Location = Locations.Sisyphus,
    },
}

-- Single toggle: sequential processing (1 -> 2 -> 3)
TabGhostfinn:CreateToggle({
    Name = "Enable Ghostfinn Auto (Sequential)",
    CurrentValue = false,
    Flag = "GhostfinnAutoSeq",
    Callback = function(state)
        if state then
            Rayfield:Notify({Title = "Ghostfinn Auto", Content = "Started sequential quest runner", Duration = 3})
            task.spawn(function()
                local active = true
                local currentIndex = 1

                while active and currentIndex <= #GhostfinnQuestList do
                    local quest = GhostfinnQuestList[currentIndex]

                    -- Update paragraph to show all 3 progress lines
                    local function UpdateAllProgress()
                        local lines = {}
                        for i, q in ipairs(GhostfinnQuestList) do
                            local p = GetQuestProgressByKey(q.SearchKey) or 0
                            table.insert(lines, string.format("%s: %.1f%%", q.Display, p))
                        end
                        QuestParagraph:Set({
                            Title = "Ghostfinn Quests",
                            Content = table.concat(lines, "\n")
                        })
                    end

                    -- Wait for tracker to exist / detect progress start (0->> or appear)
                    local started = false
                    local teleported = false

                    while not started and state do
                        UpdateAllProgress()
                        local prog = GetQuestProgressByKey(quest.SearchKey)
                        if prog > 0 then
                            started = true
                        else
                            -- also try to find tracker existence as signal
                            if GetQuestTrackerByKey(quest.SearchKey) then
                                started = true
                            end
                        end
                        if not started then
                            task.wait(3)
                        end
                    end

                    -- Teleport once to quest location & start fishing
                    if started then
                        pcall(function()
                            local myhrp = GetHRP()
                            myhrp.CFrame = quest.Location
                        end)

                        pcall(function()
                            Rayfield:Notify({
                                Title = "Teleport",
                                Content = "Teleported to quest location for: "..quest.Display,
                                Duration = 3
                            })
                        end)

                        -- Equip rod and start fishing
                        pcall(function()
                            if RemoteReferences.EquipRemote then
                                RemoteReferences.EquipRemote:FireServer()
                            end
                        end)

                        task.wait(0.5)
                        pcall(function() StartFishing() end)
                        teleported = true
                    end

                    -- Monitor this quest until 100%
                    while state do
                        local curProg = GetQuestProgressByKey(quest.SearchKey) or 0
                        QuestParagraph:Set({
                            Title = "Working: "..quest.Display,
                            Content = string.format("%s - %.1f%% complete\n\n(Other quests listed in main overview)", quest.Display, curProg)
                        })

                        if curProg >= 100 then
                            -- stop fishing for a smooth handoff
                            pcall(function() StopFishing() end)

                            Rayfield:Notify({
                                Title = "Quest Complete",
                                Content = quest.Display.." reached 100%",
                                Duration = 4
                            })

                            -- small cooldown
                            task.wait(1)
                            break
                        end

                        task.wait(5)
                    end

                    -- go to next quest
                    currentIndex = currentIndex + 1

                    -- quick update of all progress before next loop
                    UpdateAllProgress()

                    -- if the user turned off the main toggle -> exit
                    if not state then
                        break
                    end
                end

                -- finished sequence or stopped by user
                if state then
                    Rayfield:Notify({Title = "Ghostfinn Auto", Content = "All quests completed (or no more quests).", Duration = 4})
                    QuestParagraph:Set({Title = "All Quests Completed", Content = "✅ Ghostfinn Auto Finished!"})
                else
                    QuestParagraph:Set({Title = "Ghostfinn Auto", Content = "Stopped by user"})
                end
            end)
        else
            -- user disabled toggle: ensure fishing stopped
            pcall(function() StopFishing() end)
            QuestParagraph:Set({Title = "Ghostfinn Auto", Content = "Stopped by user"})
        end
    end
})