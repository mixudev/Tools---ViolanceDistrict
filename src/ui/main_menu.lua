return function(services, constants, state, Lib)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "VD_ESPMenu"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent         = game.CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.BackgroundColor3 = constants.COLORS.BACKGROUND
    MainFrame.BorderSizePixel  = 0
    MainFrame.Position         = UDim2.new(0.4, 0, 0.3, 0)
    MainFrame.Size             = UDim2.new(0, 320, 0, constants.FRAME_ORIGINAL_H)
    MainFrame.Active           = true
    MainFrame.Draggable        = true
    MainFrame.Parent           = ScreenGui
    Lib.addCorner(MainFrame, 10)
    Lib.addStroke(MainFrame, Color3.fromRGB(40, 40, 46))

    -- ── Title Bar ───────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.BackgroundTransparency = 1
    TitleBar.BorderSizePixel  = 0
    TitleBar.Size             = UDim2.new(1, 0, 0, 44)
    TitleBar.Parent           = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position          = UDim2.new(0, 16, 0, 2)
    TitleLabel.Size              = UDim2.new(0.65, 0, 0.55, 0)
    TitleLabel.Font              = Enum.Font.GothamBold
    TitleLabel.Text              = "VIOLANCE DISTRICT"
    TitleLabel.TextColor3        = Color3.fromRGB(235, 235, 245)
    TitleLabel.TextSize          = 13
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    TitleLabel.ZIndex            = 2
    TitleLabel.Parent            = TitleBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position         = UDim2.new(0, 16, 0.55, 0)
    SubLabel.Size             = UDim2.new(0.65, 0, 0.42, 0)
    SubLabel.Font             = Enum.Font.Gotham
    SubLabel.Text             = "ESP MENU  v2.1"
    SubLabel.TextColor3       = Color3.fromRGB(80, 120, 185)
    SubLabel.TextSize         = 10
    SubLabel.TextXAlignment   = Enum.TextXAlignment.Left
    SubLabel.ZIndex           = 2
    SubLabel.Parent           = TitleBar

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
    MinimizeButton.BorderSizePixel  = 0
    MinimizeButton.Position         = UDim2.new(1, -52, 0.5, -10)
    MinimizeButton.Size             = UDim2.new(0, 20, 0, 20)
    MinimizeButton.Font             = Enum.Font.GothamBold
    MinimizeButton.Text             = "—"
    MinimizeButton.TextColor3       = Color3.fromRGB(180, 180, 185)
    MinimizeButton.TextSize         = 12
    MinimizeButton.AutoButtonColor  = false
    MinimizeButton.ZIndex           = 3
    MinimizeButton.Parent           = TitleBar
    Lib.addCorner(MinimizeButton, 4)

    local CloseButton = Instance.new("TextButton")
    CloseButton.BackgroundColor3 = Color3.fromRGB(155, 40, 40)
    CloseButton.BorderSizePixel  = 0
    CloseButton.Position         = UDim2.new(1, -26, 0.5, -10)
    CloseButton.Size             = UDim2.new(0, 20, 0, 20)
    CloseButton.Font             = Enum.Font.GothamBold
    CloseButton.Text             = "×"
    CloseButton.TextColor3       = Color3.fromRGB(255, 215, 215)
    CloseButton.TextSize         = 16
    CloseButton.AutoButtonColor  = false
    CloseButton.ZIndex           = 3
    CloseButton.Parent           = TitleBar
    Lib.addCorner(CloseButton, 4)

    -- ── Content Frame ─────────────────────────────────────────
    local ContentFrame = Instance.new("Frame")
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 14, 0, 54)
    ContentFrame.Size     = UDim2.new(1, -28, 1, -64)
    ContentFrame.Parent   = MainFrame

    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentFrame = ContentFrame,
        MinimizeButton = MinimizeButton,
        CloseButton = CloseButton,
    }
end
