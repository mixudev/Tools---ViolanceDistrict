return function(services, constants, state, Lib)
    local Players     = services.Players
    local RunService  = services.RunService
    local LocalPlayer = services.LocalPlayer

    local ESP = {}

    -- ── Destroy ESP objects for one player (also disconnects their renderConn) ──
    function ESP.destroyPlayerESPObjects(player)
        -- Disconnect this player's render loop first
        local rc = state.espRenderConns[player]
        if rc then
            pcall(function() rc:Disconnect() end)
            state.espRenderConns[player] = nil
        end
        -- Destroy all ESP instances
        local objs = state.espObjects[player]
        if not objs then return end
        for _, obj in ipairs(objs) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.espObjects[player] = nil
    end

    -- ── Disconnect everything and clear all ESP ──────────────────────
    function ESP.clearAllPlayerESP()
        -- Disconnect all per-player render connections
        for _, conn in pairs(state.espRenderConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        state.espRenderConns = {}

        -- Destroy all ESP objects per player
        for player in pairs(state.espObjects) do
            local objs = state.espObjects[player]
            if objs then
                for _, obj in ipairs(objs) do
                    if obj and obj.Parent then pcall(obj.Destroy, obj) end
                end
            end
        end
        state.espObjects = {}

        -- Disconnect character connections
        for _, conn in pairs(state.espCharConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        state.espCharConns = {}

        if state.espPlayerAddedConn    then pcall(function() state.espPlayerAddedConn:Disconnect()    end) state.espPlayerAddedConn    = nil end
        if state.espPlayerRemovingConn then pcall(function() state.espPlayerRemovingConn:Disconnect() end) state.espPlayerRemovingConn = nil end
        if state.espHeartbeatConn      then pcall(function() state.espHeartbeatConn:Disconnect()      end) state.espHeartbeatConn      = nil end
    end

    -- ── Build billboard for a player ─────────────────────────────────
    function ESP.buildBillboard(player, head, rootPart, isKiller)
        local Camera = services.getCamera()
        local bb = Instance.new("BillboardGui")
        bb.Adornee     = head or rootPart
        bb.Size        = UDim2.new(0, 140, 0, 24)
        bb.StudsOffset = Vector3.new(0, 3.0, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = constants.ESP_MAX_DISTANCE
        bb.Enabled     = state.nameTitleEnabled
        bb.Parent      = Camera

        local bg = Instance.new("Frame")
        bg.BackgroundTransparency = 1
        bg.BorderSizePixel        = 0
        bg.Size                   = UDim2.new(1, 0, 1, 0)
        bg.Parent                 = bb

        -- Slim side health bar
        local healthBarBg = Instance.new("Frame")
        healthBarBg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        healthBarBg.BorderSizePixel  = 0
        healthBarBg.Position         = UDim2.new(0, 5, 0.2, 0)
        healthBarBg.Size             = UDim2.new(0, 2, 0.6, 0)
        healthBarBg.Parent           = bg
        Lib.addCorner(healthBarBg, 4)

        local healthBar = Instance.new("Frame")
        healthBar.BackgroundColor3 = constants.COLORS.HEALTH_GOOD
        healthBar.BorderSizePixel  = 0
        healthBar.Size             = UDim2.new(1, 0, 1, 0)
        healthBar.Parent           = healthBarBg
        Lib.addCorner(healthBar, 4)

        -- Killer glow
        if isKiller then
            local glow = Instance.new("Frame")
            glow.BackgroundColor3       = constants.COLORS.ESP_KILLER
            glow.BackgroundTransparency = 0.88
            glow.BorderSizePixel        = 0
            glow.Size                   = UDim2.new(1.1, 0, 1.3, 0)
            glow.AnchorPoint            = Vector2.new(0.5, 0.5)
            glow.Position               = UDim2.new(0.5, 0, 0.5, 0)
            glow.ZIndex                 = -1
            glow.Parent                 = bg
            Lib.addCorner(glow, 12)
        end

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name                   = "NameLabel"
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position               = UDim2.new(0, 12, 0, 0)
        nameLbl.Size                   = UDim2.new(1, -16, 1, 0)
        nameLbl.Font                   = Enum.Font.GothamMedium
        nameLbl.Text                   = player.Name:upper()
        nameLbl.TextColor3             = constants.COLORS.SOFT_TEXT
        nameLbl.TextSize               = 11
        nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
        nameLbl.Parent                 = bg

        return bb, nameLbl, healthBar
    end

    -- ── Build full ESP for one player ────────────────────────────────
    function ESP.buildESPForPlayer(player)
        if player == LocalPlayer then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local human    = char:FindFirstChildOfClass("Humanoid")
            if not rootPart or not human then return end
            local head = char:FindFirstChild("Head")

            local isKiller = char:FindFirstChild("Knife") ~= nil or char:FindFirstChild("Weapon") ~= nil
            local espColor = isKiller and constants.COLORS.ESP_KILLER or constants.COLORS.ESP_FRIENDLY

            -- This call also disconnects the old renderConn for this player
            ESP.destroyPlayerESPObjects(player)
            state.espObjects[player] = {}

            -- Highlight
            local hl = Instance.new("Highlight")
            hl.FillColor           = espColor
            hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency    = 0.8
            hl.OutlineTransparency = 0.4
            hl.Parent              = char
            table.insert(state.espObjects[player], hl)

            local bb, nameLbl, hb = ESP.buildBillboard(player, head, rootPart, isKiller)
            table.insert(state.espObjects[player], bb)

            -- Per-player render connection (stored in dict, not list)
            local renderConn
            renderConn = RunService.RenderStepped:Connect(function()
                if not (bb.Parent and rootPart.Parent) then
                    renderConn:Disconnect()
                    state.espRenderConns[player] = nil
                    return
                end
                local Camera = services.getCamera()
                local dist   = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local base   = math.clamp(280 / dist, 0.4, 1.4)
                local mult   = (isKiller and dist < 80) and (1 + ((80 - dist) / 80) * 0.5) or 1
                local scale  = base * mult

                nameLbl.TextSize = math.floor(11 * scale)
                bb.Size = UDim2.new(0, math.floor(140 * scale), 0, math.floor(24 * scale))
                bb.Enabled = state.nameTitleEnabled

                local hpRatio = math.clamp(human.Health / math.max(human.MaxHealth, 1), 0, 1)
                hb.Size = UDim2.new(1, 0, hpRatio, 0)
                hb.Position = UDim2.new(0, 0, 1 - hpRatio, 0)
                hb.BackgroundColor3 = Color3.fromHSV(hpRatio * 0.35, 0.9, 0.9)
            end)

            -- Store per-player (key = player object)
            state.espRenderConns[player] = renderConn
        end)
    end

    -- ── Refresh all players' ESP ──────────────────────────────────────
    function ESP.refreshAllESP()
        if not state.espEnabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ESP.buildESPForPlayer(p) end
        end
    end

    -- ── Toggle ───────────────────────────────────────────────────────
    function ESP.togglePlayerESP()
        state.espEnabled = not state.espEnabled
        Lib.setToggleState(state.espButton, state.espEnabled)

        if not state.espEnabled then
            ESP.clearAllPlayerESP()
            return
        end

        -- Guard: clear old heartbeat before creating new one
        if state.espHeartbeatConn then
            pcall(function() state.espHeartbeatConn:Disconnect() end)
            state.espHeartbeatConn = nil
        end

        ESP.refreshAllESP()
        state.espLastRefresh = tick()

        state.espHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not state.espEnabled then return end
            local t = tick()
            if t - state.espLastRefresh >= constants.ESP_REFRESH_INTERVAL then
                state.espLastRefresh = t
                ESP.refreshAllESP()
            end
        end)

        state.espPlayerAddedConn = Players.PlayerAdded:Connect(function(player)
            if not state.espEnabled or player == LocalPlayer then return end
            task.wait(1)
            ESP.buildESPForPlayer(player)
            if state.espCharConns[player] then
                pcall(function() state.espCharConns[player]:Disconnect() end)
            end
            state.espCharConns[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                ESP.buildESPForPlayer(player)
            end)
        end)

        state.espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(player)
            ESP.destroyPlayerESPObjects(player)
            if state.espCharConns[player] then
                pcall(function() state.espCharConns[player]:Disconnect() end)
                state.espCharConns[player] = nil
            end
        end)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if state.espCharConns[p] then
                    pcall(function() state.espCharConns[p]:Disconnect() end)
                end
                state.espCharConns[p] = p.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    ESP.buildESPForPlayer(p)
                end)
            end
        end
    end

    -- ── Name Title Toggle ────────────────────────────────────────────
    function ESP.toggleNameTitle()
        state.nameTitleEnabled = not state.nameTitleEnabled
        Lib.setToggleState(state.nameButton, state.nameTitleEnabled)
        for _, objs in pairs(state.espObjects) do
            for _, obj in ipairs(objs) do
                if obj:IsA("BillboardGui") then
                    obj.Enabled = state.nameTitleEnabled
                end
            end
        end
    end

    return ESP
end
