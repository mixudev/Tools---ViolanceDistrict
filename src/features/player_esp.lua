return function(services, constants, state, Lib)
    local Players     = services.Players
    local RunService  = services.RunService
    local LocalPlayer = services.LocalPlayer

    local ESP = {}

    function ESP.destroyPlayerESPObjects(player)
        local rc = state.espRenderConns[player]
        if rc then pcall(function() rc:Disconnect() end) state.espRenderConns[player] = nil end
        local objs = state.espObjects[player]
        if not objs then return end
        for _, obj in ipairs(objs) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.espObjects[player] = nil
    end

    function ESP.clearAllPlayerESP()
        for _, conn in pairs(state.espRenderConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        state.espRenderConns = {}
        for player in pairs(state.espObjects) do
            local objs = state.espObjects[player]
            if objs then for _, obj in ipairs(objs) do
                if obj and obj.Parent then pcall(obj.Destroy, obj) end
            end end
        end
        state.espObjects = {}
        for _, conn in pairs(state.espCharConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        state.espCharConns = {}
        if state.espPlayerAddedConn    then pcall(function() state.espPlayerAddedConn:Disconnect()    end) state.espPlayerAddedConn    = nil end
        if state.espPlayerRemovingConn then pcall(function() state.espPlayerRemovingConn:Disconnect() end) state.espPlayerRemovingConn = nil end
        if state.espHeartbeatConn      then pcall(function() state.espHeartbeatConn:Disconnect()      end) state.espHeartbeatConn      = nil end
    end

    -- ════════════════════════════════════════════════════════════════
    --  NAMETAG — Minimal & Elegan
    --
    --  Hanya nama saja. Tidak ada kotak, tidak ada bar.
    --  Text mengambang dengan TextStroke sebagai bayangan.
    --
    --    ● PLAYERNAME
    --    (Killer: warna merah-muda, Friendly: putih bersih)
    -- ════════════════════════════════════════════════════════════════
    function ESP.buildBillboard(player, head, rootPart, isKiller)
        local Camera   = services.getCamera()
        local espColor = isKiller and constants.COLORS.ESP_KILLER or constants.COLORS.ESP_FRIENDLY
        local txtColor = isKiller and Color3.fromRGB(255, 100, 120) or Color3.fromRGB(240, 242, 255)

        local bb = Instance.new("BillboardGui")
        bb.Adornee     = head or rootPart
        bb.Size        = UDim2.new(0, 150, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = constants.ESP_MAX_DISTANCE
        bb.Enabled     = state.nameTitleEnabled
        bb.Parent      = Camera

        local root = Instance.new("Frame")
        root.BackgroundTransparency = 1
        root.BorderSizePixel        = 0
        root.Size                   = UDim2.new(1, 0, 1, 0)
        root.Parent                 = bb

        -- Titik indikator kecil (●)
        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = espColor
        dot.BorderSizePixel  = 0
        dot.AnchorPoint      = Vector2.new(0, 0.5)
        dot.Position         = UDim2.new(0, 0, 0.5, 0)
        dot.Size             = UDim2.new(0, 4, 0, 4)
        dot.Parent           = root
        Lib.addCorner(dot, 99)

        -- Nama pemain — floating text, tanpa background
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name                   = "NameLabel"
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position               = UDim2.new(0, 8, 0, 0)
        nameLbl.Size                   = UDim2.new(1, -8, 1, 0)
        nameLbl.Font                   = Enum.Font.GothamBold
        nameLbl.Text                   = player.Name
        nameLbl.TextColor3             = txtColor
        nameLbl.TextSize               = 11
        nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
        -- Shadow hitam tebal = terbaca di semua background tanpa kotak
        nameLbl.TextStrokeTransparency = 0.22
        nameLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        nameLbl.Parent                 = root

        -- Glow sangat tipis untuk killer saja
        if isKiller then
            local glow = Instance.new("Frame")
            glow.BackgroundColor3       = constants.COLORS.ESP_KILLER
            glow.BackgroundTransparency = 0.93
            glow.BorderSizePixel        = 0
            glow.Size                   = UDim2.new(1.05, 0, 1.3, 0)
            glow.AnchorPoint            = Vector2.new(0.5, 0.5)
            glow.Position               = UDim2.new(0.5, 0, 0.5, 0)
            glow.ZIndex                 = -1
            glow.Parent                 = root
            Lib.addCorner(glow, 6)
        end

        return bb, nameLbl
    end

    -- ── Build ESP untuk satu player ───────────────────────────────────
    function ESP.buildESPForPlayer(player)
        if player == LocalPlayer then return end
        pcall(function()
            local char     = player.Character
            if not char then return end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local human    = char:FindFirstChildOfClass("Humanoid")
            if not rootPart or not human then return end
            local head     = char:FindFirstChild("Head")
            local isKiller = char:FindFirstChild("Knife") ~= nil or char:FindFirstChild("Weapon") ~= nil
            local espColor = isKiller and constants.COLORS.ESP_KILLER or constants.COLORS.ESP_FRIENDLY

            ESP.destroyPlayerESPObjects(player)
            state.espObjects[player] = {}

            -- Highlight karakter
            local hl = Instance.new("Highlight")
            hl.FillColor           = espColor
            hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency    = 0.82
            hl.OutlineTransparency = 0.45
            hl.Parent              = char
            table.insert(state.espObjects[player], hl)

            local bb, nameLbl = ESP.buildBillboard(player, head, rootPart, isKiller)
            table.insert(state.espObjects[player], bb)

            -- Render loop per-player
            local renderConn
            renderConn = RunService.RenderStepped:Connect(function()
                if not (bb.Parent and rootPart.Parent) then
                    renderConn:Disconnect()
                    state.espRenderConns[player] = nil
                    return
                end
                local Camera = services.getCamera()
                local dist   = (Camera.CFrame.Position - rootPart.Position).Magnitude
                local scale  = math.clamp(200 / dist, 0.55, 1.25)

                nameLbl.TextSize = math.floor(11 * scale)
                bb.Size  = UDim2.new(0, math.floor(150 * scale), 0, math.floor(20 * scale))
                bb.Enabled = state.nameTitleEnabled
            end)
            state.espRenderConns[player] = renderConn
        end)
    end

    function ESP.refreshAllESP()
        if not state.espEnabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ESP.buildESPForPlayer(p) end
        end
    end

    function ESP.togglePlayerESP()
        state.espEnabled = not state.espEnabled
        Lib.setToggleState(state.espButton, state.espEnabled)
        if not state.espEnabled then ESP.clearAllPlayerESP() return end

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
            if state.espCharConns[player] then pcall(function() state.espCharConns[player]:Disconnect() end) end
            state.espCharConns[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5) ESP.buildESPForPlayer(player)
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
                if state.espCharConns[p] then pcall(function() state.espCharConns[p]:Disconnect() end) end
                state.espCharConns[p] = p.CharacterAdded:Connect(function()
                    task.wait(0.5) ESP.buildESPForPlayer(p)
                end)
            end
        end
    end

    function ESP.toggleNameTitle()
        state.nameTitleEnabled = not state.nameTitleEnabled
        Lib.setToggleState(state.nameButton, state.nameTitleEnabled)
        for _, objs in pairs(state.espObjects) do
            for _, obj in ipairs(objs) do
                if obj:IsA("BillboardGui") then obj.Enabled = state.nameTitleEnabled end
            end
        end
    end

    return ESP
end
