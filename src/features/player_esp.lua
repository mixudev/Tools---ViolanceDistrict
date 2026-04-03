return function(services, constants, state, Lib)
    local Players = services.Players
    local Camera = services.Camera
    local RunService = services.RunService
    local LocalPlayer = services.LocalPlayer

    local ESP = {}

    function ESP.destroyPlayerESPObjects(player)
        local objs = state.espObjects[player]
        if not objs then return end
        for _, obj in ipairs(objs) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.espObjects[player] = nil
    end

    function ESP.clearAllPlayerESP()
        if state.espRenderConns then
            for _, conn in ipairs(state.espRenderConns) do
                if conn then pcall(conn.Disconnect, conn) end
            end
        end
        state.espRenderConns = {}
        for player in pairs(state.espObjects) do ESP.destroyPlayerESPObjects(player) end
        state.espObjects = {}
        for _, conn in pairs(state.espCharConns) do
            if conn then pcall(conn.Disconnect, conn) end
        end
        state.espCharConns = {}
        if state.espPlayerAddedConn    then pcall(state.espPlayerAddedConn.Disconnect,    state.espPlayerAddedConn)    state.espPlayerAddedConn    = nil end
        if state.espPlayerRemovingConn then pcall(state.espPlayerRemovingConn.Disconnect, state.espPlayerRemovingConn) state.espPlayerRemovingConn = nil end
        if state.espHeartbeatConn      then pcall(state.espHeartbeatConn.Disconnect,      state.espHeartbeatConn)      state.espHeartbeatConn      = nil end
    end

    function ESP.buildBillboard(player, head, rootPart, espColor, isKiller)
        local bb = Instance.new("BillboardGui")
        bb.Adornee     = head or rootPart
        bb.Size        = UDim2.new(0, 140, 0, 24)
        bb.StudsOffset = Vector3.new(0, 3.0, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = constants.ESP_MAX_DISTANCE
        bb.Enabled     = state.nameTitleEnabled
        bb.Parent      = Camera

        -- Ultra-slim Pill Container
        local bg = Instance.new("Frame")
        bg.BackgroundColor3       = Color3.fromRGB(12, 12, 15)
        bg.BackgroundTransparency = 0.25
        bg.BorderSizePixel        = 0
        bg.Size                   = UDim2.new(1, 0, 1, 0)
        bg.Parent                 = bb
        Lib.addCorner(bg, 12)
        Lib.addStroke(bg, espColor, 1, 0.7)

        -- Elegant Side Health Bar
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

        -- Killer Glow Effect
        if isKiller then
            local glow = Instance.new("Frame")
            glow.BackgroundColor3      = constants.COLORS.ESP_KILLER
            glow.BackgroundTransparency= 0.88
            glow.BorderSizePixel       = 0
            glow.Size                  = UDim2.new(1.1, 0, 1.3, 0)
            glow.AnchorPoint           = Vector2.new(0.5, 0.5)
            glow.Position              = UDim2.new(0.5, 0, 0.5, 0)
            glow.ZIndex                = -1
            glow.Parent                = bg
            Lib.addCorner(glow, 12)
        end

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name                  = "NameLabel"
        nameLbl.BackgroundTransparency= 1
        nameLbl.Position              = UDim2.new(0, 12, 0, 0)
        nameLbl.Size                  = UDim2.new(1, -16, 1, 0)
        nameLbl.Font                  = Enum.Font.GothamMedium
        nameLbl.Text                  = player.Name:upper()
        nameLbl.TextColor3            = constants.COLORS.SOFT_TEXT
        nameLbl.TextSize              = 11
        nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
        nameLbl.Parent                = bg

        return bb, nameLbl, healthBar
    end

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

            ESP.destroyPlayerESPObjects(player)
            state.espObjects[player] = {}

            -- Elegant Thin Highlight
            local hl = Instance.new("Highlight")
            hl.FillColor           = espColor
            hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency    = 0.8
            hl.OutlineTransparency = 0.4
            hl.Parent              = char
            table.insert(state.espObjects[player], hl)

            local bb, nameLbl, hb = ESP.buildBillboard(player, head, rootPart, espColor, isKiller)
            table.insert(state.espObjects[player], bb)

            local renderConn
            renderConn = RunService.RenderStepped:Connect(function()
                if not bb.Parent or not rootPart.Parent then
                    renderConn:Disconnect()
                    return
                end
                local dist  = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local baseScale = math.clamp(280 / dist, 0.4, 1.4)
                
                local killerMult = 1.0
                if isKiller and dist < 80 then
                    killerMult = 1.0 + ((80 - dist) / 80) * 0.5
                end
                
                local finalScale = baseScale * killerMult
                nameLbl.TextSize = math.floor(11 * finalScale)
                bb.Size = UDim2.new(0, math.floor(140 * finalScale), 0, math.floor(24 * finalScale))
                bb.Enabled = state.nameTitleEnabled

                -- Health update
                local hpRatio = math.clamp(human.Health / human.MaxHealth, 0, 1)
                hb.Size = UDim2.new(1, 0, hpRatio, 0)
                hb.Position = UDim2.new(0, 0, 1 - hpRatio, 0)
                hb.BackgroundColor3 = Color3.fromHSV(hpRatio * 0.35, 0.9, 0.9)
            end)
            table.insert(state.espRenderConns, renderConn)
        end)
    end

    function ESP.refreshAllESP()
        if not state.espEnabled then return end
        if state.espRenderConns then
            for _, conn in ipairs(state.espRenderConns) do
                if conn then pcall(conn.Disconnect, conn) end
            end
        end
        state.espRenderConns = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ESP.buildESPForPlayer(p) end
        end
    end

    function ESP.togglePlayerESP()
        state.espEnabled = not state.espEnabled
        Lib.setToggleState(state.espButton, state.espEnabled)
        if not state.espEnabled then ESP.clearAllPlayerESP() return end

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
            state.espCharConns[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                ESP.buildESPForPlayer(player)
            end)
        end)

        state.espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(player)
            ESP.destroyPlayerESPObjects(player)
            if state.espCharConns[player] then
                pcall(state.espCharConns[player].Disconnect, state.espCharConns[player])
                state.espCharConns[player] = nil
            end
        end)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if state.espCharConns[p] then pcall(state.espCharConns[p].Disconnect, state.espCharConns[p]) end
                state.espCharConns[p] = p.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    ESP.buildESPForPlayer(p)
                end)
            end
        end
    end

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
