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

    function ESP.buildBillboard(player, head, rootPart, espColor)
        local bb = Instance.new("BillboardGui")
        bb.Adornee     = head or rootPart
        bb.Size        = UDim2.new(0, 160, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3.2, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = constants.ESP_MAX_DISTANCE
        bb.Enabled     = state.nameTitleEnabled
        bb.Parent      = Camera

        local bg = Instance.new("Frame")
        bg.BackgroundColor3       = Color3.fromRGB(10, 10, 14)
        bg.BackgroundTransparency = 0.28
        bg.BorderSizePixel        = 0
        bg.AnchorPoint            = Vector2.new(0.5, 0.5)
        bg.Position               = UDim2.new(0.5, 0, 0.5, 0)
        bg.Size                   = UDim2.new(0.92, 0, 0.78, 0)
        bg.Parent                 = bb
        Lib.addCorner(bg, 9)
        Lib.addStroke(bg, espColor, 1.2)

        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = espColor
        dot.BorderSizePixel  = 0
        dot.AnchorPoint      = Vector2.new(0, 0.5)
        dot.Position         = UDim2.new(0, 7, 0.5, 0)
        dot.Size             = UDim2.new(0, 6, 0, 6)
        dot.ZIndex           = 2
        dot.Parent           = bg
        Lib.addCorner(dot, 99)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name                  = "NameLabel"
        nameLbl.BackgroundTransparency= 1
        nameLbl.AnchorPoint           = Vector2.new(0, 0.5)
        nameLbl.Position              = UDim2.new(0, 22, 0.5, 0)
        nameLbl.Size                  = UDim2.new(1, -28, 1, 0)
        nameLbl.Font                  = Enum.Font.GothamBold
        nameLbl.Text                  = player.Name
        nameLbl.TextColor3            = Color3.fromRGB(240, 240, 252)
        nameLbl.TextSize              = 13
        nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
        nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
        nameLbl.Parent                = bg

        return bb, nameLbl
    end

    function ESP.buildESPForPlayer(player)
        if player == LocalPlayer then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            local head = char:FindFirstChild("Head")

            local isKiller = char:FindFirstChild("Knife") ~= nil or char:FindFirstChild("Weapon") ~= nil
            local espColor = isKiller and constants.COLORS.ESP_KILLER or constants.COLORS.ESP_FRIENDLY

            ESP.destroyPlayerESPObjects(player)
            state.espObjects[player] = {}

            local hl = Instance.new("Highlight")
            hl.FillColor           = espColor
            hl.OutlineColor        = espColor
            hl.FillTransparency    = 0.65
            hl.OutlineTransparency = 0.2
            hl.Parent              = char
            table.insert(state.espObjects[player], hl)

            local bb, nameLbl = ESP.buildBillboard(player, head, rootPart, espColor)
            table.insert(state.espObjects[player], bb)

            local renderConn
            renderConn = RunService.RenderStepped:Connect(function()
                if not bb.Parent or not rootPart.Parent then
                    renderConn:Disconnect()
                    return
                end
                local dist  = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local baseScale = math.clamp(280 / dist, 0.5, 1.8)
                
                local killerMult = 1.0
                if isKiller and dist < 70 then
                    killerMult = 1.0 + ((70 - dist) / 70) * 0.4
                end
                
                local finalScale = baseScale * killerMult
                nameLbl.TextSize = math.floor(13 * finalScale)
                bb.Enabled = state.nameTitleEnabled
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
