-- ===============================
-- MASTERPIECE KAITUN SCRIPT
-- ===============================

-- Loader KAVO UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Window
local Window = Library.CreateLib("AxeeHUB | Unrealesed v.0.0.1", "Midnight")

-- ===============================
-- Tab: Main Kaitun Controls
-- ===============================
local Main = Window:NewTab("Main")
local Kaitun = Main:NewSection("Kaitun Controls")

-- Global State
getgenv().AutoFishing = false

-- Player & Stats
local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local Coins = leaderstats:WaitForChild("Coins")

-- Remote References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net
local RemoteReferences = {
   	UpdateAutoFishing = Net:WaitForChild("RF/UpdateAutoFishingState"),
   	RodRemote = Net:WaitForChild("RF/ChargeFishingRod"),
   	StartMini = Net:WaitForChild("RF/RequestFishingMinigameStarted"),
   	FinishFish = Net:WaitForChild("RE/FishingCompleted"),
   	FishCaught = Net:WaitForChild("RE/FishCaught") or Net:WaitForChild("RF/FishCaught"),
   	EquipRemote = Net:WaitForChild("RE/EquipToolFromHotbar"),
   	SellRemote = Net:WaitForChild("RF/SellAllItems"),
	   Teleport = ReplicatedStorage:WaitForChild("Teleport"),
   	CompleteQuest = ReplicatedStorage:WaitForChild("CompleteQuest")
}

-- Locations
local Locations = {
	KohanaVolcano = Vector3.new(-546.500671,16.2349777,115.35006),
	TreasureRoom = Vector3.new(-3570.70264,-279.074188,-1599.13953),
	SisyphusStatue = Vector3.new(-3737.87354,-135.073914,-888.212891)
}

-- Quest Tracking
local CurrentQuest = "BuyMidnight"
local RareEpicCount = 0

-- Helper Functions
local function BuyRod(name)
	pcall(function()
		RemoteReferences.RodRemote:InvokeServer(name)
	end)
end

local function EquipRod(name)
	pcall(function()
		RemoteReferences.EquipRemote:FireServer(name)
	end)
end

local function Teleport(location)
	pcall(function()
		RemoteReferences.Teleport:FireServer(location)
	end)
end

local function CompleteQuest(name)
	pcall(function()
		RemoteReferences.CompleteQuest:FireServer(name)
	end)
end

local function StartAutoFishing()
	getgenv().AutoFishing = true
	pcall(function()
		RemoteReferences.UpdateAutoFishing:FireServer(true)
	end)
end

local function StopAutoFishing()
	getgenv().AutoFishing = false
	pcall(function()
		RemoteReferences.UpdateAutoFishing:FireServer(false)
	end)
end

-- ===============================
-- KAVO UI: Progress Labels & Textboxes
-- ===============================
local ProgressLabel = Kaitun:NewLabel("Quest Progress: 0 / 300")
local CoinTextbox = Kaitun:NewTextBox("Coins", "Current Coins", function(txt) end)
local QuestPhaseTextbox = Kaitun:NewTextBox("Quest Phase", "Current Phase", function(txt) end)

-- ===============================
-- FishCaught Event Handler
-- ===============================
RemoteReferences.FishCaught.OnClientEvent:Connect(function(fish)
	if not getgenv().AutoFishing then return end
	local coin = Coins.Value

	-- Phase 1: Buy Midnight Rod
	if CurrentQuest == "BuyMidnight" then
		if coin >= 50000 then
			BuyRod("Midnight Rod")
			EquipRod("Midnight Rod")
			Teleport(Locations.TreasureRoom)
			CurrentQuest = "TreasureQuest"
		end
	end

	-- Phase 2: Treasure Room Rare/Epic 300
	if CurrentQuest == "TreasureQuest" then
		if fish.Rarity == "Rare" or fish.Rarity == "Epic" then
			RareEpicCount += 1
		end
		if RareEpicCount >= 300 then
			CurrentQuest = "CoinTo3M"
		end
		ProgressLabel:UpdateLabel("Quest Progress: "..RareEpicCount.." / 300")
		CoinTextbox:UpdateTextbox("Coins: "..coin)
		QuestPhaseTextbox:UpdateTextbox("Phase: Treasure Room")
	end

	-- Phase 3: Collect 3M coins → Buy Ares Rod
	if CurrentQuest == "CoinTo3M" then
		if coin >= 3000000 then
			BuyRod("Ares Rod")
			EquipRod("Ares Rod")
			Teleport(Locations.SisyphusStatue)
			CurrentQuest = "SecretQuest"
		end
		CoinTextbox:UpdateTextbox("Coins: "..coin)
		QuestPhaseTextbox:UpdateTextbox("Phase: Coin to 3M")
	end

	-- Phase 4: Secret fish quest → Ghostfinn Rod
	if CurrentQuest == "SecretQuest" then
		if fish.Rarity == "Secret" then
			CompleteQuest("Ghostfinn")
			EquipRod("Ghostfinn Rod")
			CurrentQuest = "Done"
			StopAutoFishing()
			ProgressLabel:UpdateLabel("Quest Completed! Ghostfinn Rod obtained.")
			CoinTextbox:UpdateTextbox("Coins: "..coin)
			QuestPhaseTextbox:UpdateTextbox("Phase: Completed")
		end
	end
end)

-- ===============================
-- KAVO UI Buttons
-- ===============================
Kaitun:NewButton("Start Kaitun", "Mulai auto fishing & quest", function()
	StartAutoFishing()
	Teleport(Locations.KohanaVolcano)
	EquipRod("Starter Rod")
	RareEpicCount = 0
	CurrentQuest = "BuyMidnight"
	CoinTextbox:UpdateTextbox("Coins: "..Coins.Value)
	QuestPhaseTextbox:UpdateTextbox("Phase: Buy Midnight Rod")
end)

Kaitun:NewButton("Stop Kaitun", "Hentikan auto fishing", function()
	StopAutoFishing()
	CurrentQuest = "Stopped"
	CoinTextbox:UpdateTextbox("Coins: "..Coins.Value)
	QuestPhaseTextbox:UpdateTextbox("Phase: Stopped")
end)

-- ===============================
-- Tab: Auto Sell
-- ===============================
local AutoSell = Window:NewTab("Auto Sell")
local AutoSellSection = AutoSell:NewSection("Auto Sell Controls")

getgenv().AutoSellEnabled = false

-- Toggle Auto Sell
AutoSellSection:NewToggle("Enable Auto Sell", "Automatically sell all items", function(state)
	getgenv().AutoSellEnabled = state
end)

-- Label to show status
local AutoSellLabel = AutoSellSection:NewLabel("Status: OFF")

-- Auto Sell Loop
spawn(function()
	while true do
		if getgenv().AutoSellEnabled then
			AutoSellLabel:UpdateLabel("Status: ON")
			pcall(function()
				RemoteReferences.SellRemote:FireServer()
			end)
		else
			AutoSellLabel:UpdateLabel("Status: OFF")
		end
		wait(1) -- jual setiap detik
	end
end)