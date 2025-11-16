-- Axee UI using WindUI (custom FF4444 / 0B0A08 theme)
-- OFFICIAL WindUI loader from docs

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

------------------------------------------------
-- UPDATED THEME (YOUR EXACT COLORS)
------------------------------------------------
local Theme = {
    WindowBackground = Color3.fromRGB(11, 10, 8),       -- #0B0A08
    TopBar = Color3.fromRGB(11, 10, 8),                 -- #0B0A08
    TopBarText = Color3.fromRGB(255, 68, 68),           -- #FF4444

    TabBackground = Color3.fromRGB(255, 68, 68),        -- #FF4444
    TabText = Color3.fromRGB(11, 10, 8),                -- text dark
    TabActive = Color3.fromRGB(230, 54, 54),            -- slightly darker red
    TabActiveText = Color3.fromRGB(255, 188, 188),      

    SectionBackground = Color3.fromRGB(11, 10, 8),      -- #0B0A08
    SectionStroke = Color3.fromRGB(255, 68, 68),        -- #FF4444
    SectionText = Color3.fromRGB(255, 68, 68),          -- #FF4444

    StrokeColor = Color3.fromRGB(255, 68, 68),          -- #FF4444
    StrokeThickness = 5,

    CornerRadius = 12,
}

------------------------------------------------
-- CREATE WINDOW
------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "WINDOW NAME",
    Size = UDim2.new(0, 750, 0, 500),
    Draggable = true,
    Resizable = true,
    Theme = Theme
})

------------------------------------------------
-- CREATE 3 TABS
------------------------------------------------
local Tab1 = Window:CreateTab("TAB")
local Tab2 = Window:CreateTab("TAB")
local Tab3 = Window:CreateTab("TAB")

------------------------------------------------
-- ADD 3 SECTIONS PER TAB
------------------------------------------------

-- Tab 1
local T1S1 = Tab1:CreateSection("SECTION")
local T1S2 = Tab1:CreateSection("SECTION")
local T1S3 = Tab1:CreateSection("SECTION")

-- Tab 2
local T2S1 = Tab2:CreateSection("SECTION")
local T2S2 = Tab2:CreateSection("SECTION")
local T2S3 = Tab2:CreateSection("SECTION")

-- Tab 3
local T3S1 = Tab3:CreateSection("SECTION")
local T3S2 = Tab3:CreateSection("SECTION")
local T3S3 = Tab3:CreateSection("SECTION")

print("Axee UI Loaded with new theme!")