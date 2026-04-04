return function(services, constants, state, Lib)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "VD_ESPMenu_v2"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent         = game.CoreGui

    -- ── Main Frame — auto-height, no scroll ─────────────────────────
    local MainFrame = Instance.new("Frame")
    MainFrame.BackgroundColor3       = constants.COLORS.BACKGROUND
    MainFrame.BackgroundTransparency = 0.06
    MainFrame.BorderSizePixel        = 0
    MainFrame.Position               = UDim2.new(0.4, 0, 0.3, 0)
    MainFrame.Size                   = UDim2.new(0, 270, 0, 0)  -- height = auto
    MainFrame.AutomaticSize          = Enum.AutomaticSize.Y      -- grows with content
    MainFrame.Active                 = true
    MainFrame.Draggable              = true
    MainFrame.ClipsDescendants       = false
    MainFrame.Parent                 = ScreenGui
    Lib.addCorner(MainFrame, 10)
    Lib.addStroke(MainFrame, Color3.fromRGB(255, 255, 255), 1, 0.92)

    -- Left accent stripe
    local sideAccent = Instance.new("Frame")
    sideAccent.BackgroundColor3 = constants.COLORS.ACCENT_AZURE
    sideAccent.BorderSizePixel  = 0
    sideAccent.Position         = UDim2.new(0, 0, 0, 10)
    sideAccent.Size             = UDim2.new(0, 2, 1, -20)
    sideAccent.ZIndex           = 2
    sideAccent.Parent           = MainFrame
    Lib.addCorner(sideAccent, 4)

    -- ── Title Bar ───────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.BackgroundTransparency = 1
    TitleBar.Size                   = UDim2.new(1, 0, 0, 50)
    TitleBar.Parent                 = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position          = UDim2.new(0, 18, 0.5, -10)
    TitleLabel.Size              = UDim2.new(0.6, 0, 0, 14)
    TitleLabel.Font              = Enum.Font.GothamBold
    TitleLabel.Text              = "VIOLANCE DISTRICT"
    TitleLabel.TextColor3        = constants.COLORS.SOFT_TEXT
    TitleLabel.TextSize          = 13
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    TitleLabel.Parent            = TitleBar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position         = UDim2.new(0, 18, 0.5, 6)
    SubLabel.Size             = UDim2.new(0.6, 0, 0, 10)
    SubLabel.Font             = Enum.Font.Gotham
    SubLabel.Text             = "v2.3  ·  MODULAR"
    SubLabel.TextColor3       = Color3.fromRGB(100, 100, 118)
    SubLabel.TextSize         = 9
    SubLabel.TextXAlignment   = Enum.TextXAlignment.Left
    SubLabel.Parent           = TitleBar

    -- Minimize button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Position         = UDim2.new(1, -66, 0.5, -12)
    MinimizeButton.Size             = UDim2.new(0, 24, 0, 24)
    MinimizeButton.Font             = Enum.Font.GothamBold
    MinimizeButton.Text             = "—"
    MinimizeButton.TextColor3       = Color3.fromRGB(140, 140, 160)
    MinimizeButton.TextSize         = 14
    MinimizeButton.AutoButtonColor  = false
    MinimizeButton.Parent           = TitleBar
    MinimizeButton.MouseEnter:Connect(function()
        Lib.tween(MinimizeButton, 0.12, { TextColor3 = Color3.fromRGB(220, 220, 240) })
    end)
    MinimizeButton.MouseLeave:Connect(function()
        Lib.tween(MinimizeButton, 0.12, { TextColor3 = Color3.fromRGB(140, 140, 160) })
    end)

    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position         = UDim2.new(1, -36, 0.5, -12)
    CloseButton.Size             = UDim2.new(0, 24, 0, 24)
    CloseButton.Font             = Enum.Font.GothamBold
    CloseButton.Text             = "×"
    CloseButton.TextColor3       = Color3.fromRGB(140, 140, 160)
    CloseButton.TextSize         = 20
    CloseButton.AutoButtonColor  = false
    CloseButton.Parent           = TitleBar
    CloseButton.MouseEnter:Connect(function()
        Lib.tween(CloseButton, 0.12, { TextColor3 = Color3.fromRGB(255, 80, 100) })
    end)
    CloseButton.MouseLeave:Connect(function()
        Lib.tween(CloseButton, 0.12, { TextColor3 = Color3.fromRGB(140, 140, 160) })
    end)

    -- Thin separator below title
    local titleSep = Instance.new("Frame")
    titleSep.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    titleSep.BackgroundTransparency = 0.93
    titleSep.BorderSizePixel        = 0
    titleSep.Position               = UDim2.new(0, 10, 0, 49)
    titleSep.Size                   = UDim2.new(1, -20, 0, 1)
    titleSep.Parent                 = MainFrame

    -- ── Content Frame — auto-height, no scroll ──────────────────────
    -- AutomaticSize.Y makes this frame grow to fit all its children.
    -- UIListLayout stacks items vertically.
    local ContentFrame = Instance.new("Frame")
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel        = 0
    ContentFrame.Position               = UDim2.new(0, 10, 0, 56)
    ContentFrame.Size                   = UDim2.new(1, -20, 0, 0)  -- height = auto
    ContentFrame.AutomaticSize          = Enum.AutomaticSize.Y
    ContentFrame.Parent                 = MainFrame

    -- Bottom padding inside ContentFrame
    Lib.setupListLayout(ContentFrame, 4)
    Lib.addPadding(ContentFrame, 4, 10, 0, 0)

    return {
        ScreenGui      = ScreenGui,
        MainFrame      = MainFrame,
        ContentFrame   = ContentFrame,
        MinimizeButton = MinimizeButton,
        CloseButton    = CloseButton,
    }
end
