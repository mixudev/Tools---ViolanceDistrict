return function(services, constants, state, Lib, ScreenGui)
    local PlayerListFrame = Instance.new("Frame")
    PlayerListFrame.BackgroundColor3 = constants.COLORS.BACKGROUND
    PlayerListFrame.BorderSizePixel  = 0
    PlayerListFrame.Position         = UDim2.new(0.02, 0, 0.3, 0)
    PlayerListFrame.Size             = UDim2.new(0, 230, 0, 300)
    PlayerListFrame.Visible          = false
    PlayerListFrame.Active           = true
    PlayerListFrame.Draggable        = true
    PlayerListFrame.Parent           = ScreenGui
    Lib.addCorner(PlayerListFrame, 10)
    Lib.addStroke(PlayerListFrame, Color3.fromRGB(40, 40, 46))

    local PlayerListTitle = Instance.new("TextLabel")
    PlayerListTitle.BackgroundColor3 = constants.COLORS.TITLE_BAR
    PlayerListTitle.BorderSizePixel  = 0
    PlayerListTitle.Size             = UDim2.new(1, 0, 0, 36)
    PlayerListTitle.Font             = Enum.Font.GothamBold
    PlayerListTitle.Text             = "PLAYER LIST"
    PlayerListTitle.TextColor3       = Color3.fromRGB(235, 235, 245)
    PlayerListTitle.TextSize         = 12
    PlayerListTitle.Parent           = PlayerListFrame
    Lib.addCorner(PlayerListTitle, 10)

    local PlayerListContent = Instance.new("ScrollingFrame")
    PlayerListContent.BackgroundTransparency = 1
    PlayerListContent.Position              = UDim2.new(0, 8, 0, 44)
    PlayerListContent.Size                  = UDim2.new(1, -16, 1, -52)
    PlayerListContent.CanvasSize            = UDim2.new(0, 0, 0, 0)
    PlayerListContent.ScrollBarThickness    = 3
    PlayerListContent.ScrollBarImageColor3  = Color3.fromRGB(75, 75, 88)
    PlayerListContent.BorderSizePixel       = 0
    PlayerListContent.Parent                = PlayerListFrame

    return {
        Frame = PlayerListFrame,
        Content = PlayerListContent
    }
end
