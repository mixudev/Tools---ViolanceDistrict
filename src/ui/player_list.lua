return function(services, constants, state, Lib, ScreenGui)
    -- ── Outer Frame ─────────────────────────────────────────────────
    local PlayerListFrame = Instance.new("Frame")
    PlayerListFrame.BackgroundColor3       = constants.COLORS.BACKGROUND
    PlayerListFrame.BackgroundTransparency = 0.06
    PlayerListFrame.BorderSizePixel        = 0
    PlayerListFrame.Position               = UDim2.new(0.02, 0, 0.3, 0)
    PlayerListFrame.Size                   = UDim2.new(0, 240, 0, 300)
    PlayerListFrame.Visible                = false
    PlayerListFrame.Active                 = true
    PlayerListFrame.Draggable              = true
    PlayerListFrame.ClipsDescendants       = true   -- prevents corner bleed
    PlayerListFrame.Parent                 = ScreenGui
    Lib.addCorner(PlayerListFrame, 10)
    Lib.addStroke(PlayerListFrame, Color3.fromRGB(255, 255, 255), 1, 0.92)

    -- Left accent stripe
    local sideAccent = Instance.new("Frame")
    sideAccent.BackgroundColor3 = constants.COLORS.ACCENT_AZURE
    sideAccent.BorderSizePixel  = 0
    sideAccent.Position         = UDim2.new(0, 0, 0, 8)
    sideAccent.Size             = UDim2.new(0, 2, 1, -16)
    sideAccent.ZIndex           = 2
    sideAccent.Parent           = PlayerListFrame
    Lib.addCorner(sideAccent, 4)

    -- ── Title Bar ───────────────────────────────────────────────────
    local PlayerListTitle = Instance.new("Frame")
    PlayerListTitle.BackgroundColor3       = constants.COLORS.TITLE_BAR
    PlayerListTitle.BackgroundTransparency = 0
    PlayerListTitle.BorderSizePixel        = 0
    PlayerListTitle.Size                   = UDim2.new(1, 0, 0, 38)
    PlayerListTitle.Parent                 = PlayerListFrame

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position    = UDim2.new(0, 14, 0, 0)
    TitleLbl.Size        = UDim2.new(0.75, 0, 1, 0)
    TitleLbl.Font        = Enum.Font.GothamBold
    TitleLbl.Text        = "PLAYER LIST"
    TitleLbl.TextColor3  = Color3.fromRGB(215, 215, 235)
    TitleLbl.TextSize    = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent      = PlayerListTitle

    -- Thin separator below title
    local sep = Instance.new("Frame")
    sep.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    sep.BackgroundTransparency = 0.93
    sep.BorderSizePixel        = 0
    sep.Position               = UDim2.new(0, 10, 0, 37)
    sep.Size                   = UDim2.new(1, -20, 0, 1)
    sep.Parent                 = PlayerListFrame

    -- Close button (X) — user can close without going back to main menu
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position        = UDim2.new(1, -32, 0.5, -10)
    CloseBtn.Size            = UDim2.new(0, 20, 0, 20)
    CloseBtn.Font            = Enum.Font.GothamBold
    CloseBtn.Text            = "×"
    CloseBtn.TextColor3      = Color3.fromRGB(130, 130, 150)
    CloseBtn.TextSize        = 18
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent          = PlayerListTitle

    CloseBtn.MouseEnter:Connect(function()
        Lib.tween(CloseBtn, 0.12, { TextColor3 = Color3.fromRGB(255, 80, 100) })
    end)
    CloseBtn.MouseLeave:Connect(function()
        Lib.tween(CloseBtn, 0.12, { TextColor3 = Color3.fromRGB(130, 130, 150) })
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        PlayerListFrame.Visible = false
        state.playerListVisible = false
        if state.playerListButton then
            Lib.setToggleState(state.playerListButton, false)
        end
        if state.playerListConn then
            pcall(function() state.playerListConn:Disconnect() end)
            state.playerListConn = nil
        end
    end)

    -- ── Scrollable Content ──────────────────────────────────────────
    local PlayerListContent = Instance.new("ScrollingFrame")
    PlayerListContent.BackgroundTransparency = 1
    PlayerListContent.BorderSizePixel        = 0
    PlayerListContent.Position               = UDim2.new(0, 8, 0, 46)
    PlayerListContent.Size                   = UDim2.new(1, -16, 1, -54)
    PlayerListContent.CanvasSize             = UDim2.new(0, 0, 0, 0)
    PlayerListContent.ScrollBarThickness     = 3
    PlayerListContent.ScrollBarImageColor3   = Color3.fromRGB(70, 70, 88)
    PlayerListContent.Parent                 = PlayerListFrame

    return {
        Frame   = PlayerListFrame,
        Content = PlayerListContent,
    }
end
