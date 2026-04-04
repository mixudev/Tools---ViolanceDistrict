return function(services, constants, state, Lib, PlayerListUI)
    local Players     = services.Players
    local LocalPlayer = services.LocalPlayer
    local RunService  = services.RunService

    local PL = {}

    local CARD_H   = constants.PLAYER_CARD_HEIGHT  -- 48
    local CARD_GAP = constants.PLAYER_CARD_GAP      -- 6

    -- ── Health color helper ──────────────────────────────────────────
    local function healthColor(ratio)
        if ratio > 0.6 then return Color3.fromRGB(70, 200, 100)
        elseif ratio > 0.3 then return Color3.fromRGB(255, 185, 50)
        else return Color3.fromRGB(225, 60, 60) end
    end

    -- ── Clean up all HealthChanged connections ───────────────────────
    local function clearHealthConns()
        for _, conn in pairs(state.playerListHealthConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        state.playerListHealthConns = {}
    end

    -- ── Rebuild the entire player list UI ────────────────────────────
    function PL.updatePlayerList()
        -- 1. Disconnect all old HealthChanged listeners (fixes memory leak)
        clearHealthConns()

        -- 2. Destroy all old frames
        for _, f in ipairs(state.playerListFrames) do
            if f and f.Parent then f:Destroy() end
        end
        state.playerListFrames = {}

        if not state.playerListVisible then return end

        local yOffset = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then continue end

            -- ── Card frame ─────────────────────────────────────────
            local pf = Instance.new("Frame")
            pf.BackgroundColor3 = Color3.fromRGB(21, 21, 28)
            pf.BorderSizePixel  = 0
            pf.Position         = UDim2.new(0, 0, 0, yOffset)
            pf.Size             = UDim2.new(1, 0, 0, CARD_H)
            pf.Parent           = PlayerListUI.Content
            Lib.addCorner(pf, 7)
            Lib.addStroke(pf, Color3.fromRGB(36, 36, 46))
            table.insert(state.playerListFrames, pf)

            local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)

            -- Name label
            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position       = UDim2.new(0, 14, 0, 5)
            nameLabel.Size           = UDim2.new(0.6, 0, 0, 16)
            nameLabel.Font           = Enum.Font.GothamBold
            nameLabel.Text           = player.Name
            nameLabel.TextColor3     = Color3.fromRGB(220, 220, 235)
            nameLabel.TextSize       = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent         = pf

            -- HP value label
            local hpLabel = Instance.new("TextLabel")
            hpLabel.BackgroundTransparency = 1
            hpLabel.Position         = UDim2.new(0.55, 0, 0, 5)
            hpLabel.Size             = UDim2.new(0.42, 0, 0, 16)
            hpLabel.Font             = Enum.Font.GothamMedium
            hpLabel.Text             = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
            hpLabel.TextColor3       = healthColor(ratio)
            hpLabel.TextSize         = 10
            hpLabel.TextXAlignment   = Enum.TextXAlignment.Right
            hpLabel.Parent           = pf

            -- HP bar background
            local hbBg = Instance.new("Frame")
            hbBg.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            hbBg.BorderSizePixel  = 0
            hbBg.Position         = UDim2.new(0, 14, 0, 27)
            hbBg.Size             = UDim2.new(1, -22, 0, 12)
            hbBg.Parent           = pf
            Lib.addCorner(hbBg, 4)

            local hbFill = Instance.new("Frame")
            hbFill.BackgroundColor3 = healthColor(ratio)
            hbFill.BorderSizePixel  = 0
            hbFill.Size             = UDim2.new(ratio, 0, 1, 0)
            hbFill.Parent           = hbBg
            Lib.addCorner(hbFill, 4)

            -- ── HealthChanged connection (stored — disconnected on next rebuild) ──
            local conn = hum.HealthChanged:Connect(function()
                if not hbFill.Parent then return end
                local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local c = healthColor(r)
                Lib.tween(hbFill, 0.15, { Size = UDim2.new(r, 0, 1, 0), BackgroundColor3 = c })
                hpLabel.TextColor3 = c
                hpLabel.Text = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
            end)
            state.playerListHealthConns[player] = conn

            yOffset = yOffset + CARD_H + CARD_GAP
        end

        PlayerListUI.Content.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end

    -- ── Toggle visibility ────────────────────────────────────────────
    function PL.togglePlayerList()
        state.playerListVisible = not state.playerListVisible
        PlayerListUI.Frame.Visible = state.playerListVisible
        Lib.setToggleState(state.playerListButton, state.playerListVisible)

        -- Stop existing update loop
        if state.playerListConn then
            pcall(function() state.playerListConn:Disconnect() end)
            state.playerListConn = nil
        end

        if not state.playerListVisible then
            PL.updatePlayerList()  -- will clear frames and health conns
            return
        end

        PL.updatePlayerList()

        local lastUpdate = tick()
        state.playerListConn = RunService.Heartbeat:Connect(function()
            if not state.playerListVisible then
                if state.playerListConn then state.playerListConn:Disconnect() end
                state.playerListConn = nil
                return
            end
            local t = tick()
            if t - lastUpdate >= constants.PLAYER_LIST_INTERVAL then
                lastUpdate = t
                PL.updatePlayerList()
            end
        end)
    end

    return PL
end
