return function(services, constants, state, Lib)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "VD_ESPMenu_v2"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent         = game.CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.BackgroundColor3 = constants.COLORS.BACKGROUND
    MainFrame.BackgroundTransparency = 0.08
    MainFrame.BorderSizePixel  = 0
    MainFrame.Position         = UDim2.new(0.4, 0, 0.3, 0)
    MainFrame.Size             = UDim2.new(0, 270, 0, constants.FRAME_ORIGINAL_H) -- Narrower and Slimmer
    MainFrame.Active           = true
    MainFrame.Draggable        = true
    MainFrame.Parent           = ScreenGui
    Lib.addCorner(MainFrame, 8)
    Lib.addStroke(MainFrame, Color3.fromRGB(255, 255, 255), 1, 0.94)

    -- Subtle side accent
    local sideAccent = Instance.new("Frame")
    sideAccent.BackgroundColor3 = constants.COLORS.ACCENT_AZURE
    sideAccent.BorderSizePixel  = 0
    sideAccent.Size             = UDim2.new(0, 2, 1, 0)
    sideAccent.ZIndex           = 2
    sideAccent.Parent           = MainFrame
    Lib.addCorner(sideAccent, 4)

    -- ── Title Bar ───────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.BackgroundTransparency = 1
    TitleBar.Size             = UDim2.new(1, 0, 0, 48)
    TitleBar.Parent           = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position          = UDim2.new(0, 16, 0.5, -9)
    TitleLabel.Size              = UDim2.new(0.65, 0, 0, 14)
    TitleLabel.Font              = Enum.Font.GothamBold
    TitleLabel.Text              = "VIOLANCE DISTRICT"
    TitleLabel.TextColor3        = constants.COLORS.SOFT_TEXT
    TitleLabel.TextSize          = 13
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    TitleLabel.Parent            = TitleBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position         = UDim2.new(0, 16, 0.5, 6)
    SubLabel.Size             = UDim2.new(0.65, 0, 0, 10)
    SubLabel.Font             = Enum.Font.Gotham
    SubLabel.Text             = "v2.2 MODULAR"
    SubLabel.TextColor3       = Color3.fromRGB(120, 120, 135)
    SubLabel.TextSize         = 9
    SubLabel.TextXAlignment   = Enum.TextXAlignment.Left
    SubLabel.Parent           = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position         = UDim2.new(1, -34, 0.5, -12)
    CloseButton.Size             = UDim2.new(0, 24, 0, 24)
    CloseButton.Font             = Enum.Font.GothamBold
    CloseButton.Text             = "×"
    CloseButton.TextColor3       = Color3.fromRGB(160, 160, 175)
    CloseButton.TextSize         = 20
    CloseButton.AutoButtonColor  = false
    CloseButton.Parent           = TitleBar

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Position         = UDim2.new(1, -64, 0.5, -12)
    MinimizeButton.Size             = UDim2.new(0, 24, 0, 24)
    MinimizeButton.Font             = Enum.Font.GothamBold
    MinimizeButton.Text             = "—"
    MinimizeButton.TextColor3       = Color3.fromRGB(160, 160, 175)
    MinimizeButton.TextSize         = 16
    MinimizeButton.AutoButtonColor  = false
    MinimizeButton.Parent           = TitleBar

    -- ── Content Frame ─────────────────────────────────────────
    local ContentFrame = Instance.new("Frame")
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 12, 0, 56)
    ContentFrame.Size     = UDim2.new(1, -24, 1, -68)
    ContentFrame.Parent   = MainFrame

    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentFrame = ContentFrame,
        MinimizeButton = MinimizeButton,
        CloseButton = CloseButton,
    }
end
