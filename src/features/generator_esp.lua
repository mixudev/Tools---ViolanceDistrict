return function(services, constants, state, Lib)
    local Workspace = services.Workspace
    local RunService = services.RunService
    local Camera = Workspace.CurrentCamera

    local GEN = {}

    function GEN.isGeneratorRepaired(gen)
        local repaired = false
        local progressText = ""
        
        for _, child in ipairs(gen:GetDescendants()) do
            local n = child.Name:lower()
            if n:find("repaired") or n:find("fixed") or n:find("complete") or n:find("done") then
                if child:IsA("BoolValue") then repaired = child.Value end
                if child:IsA("IntValue") or child:IsA("NumberValue") then repaired = child.Value > 0 end
                if repaired then break end
            end
            if n:find("progress") then
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    progressText = string.format("%d%%", math.floor(child.Value))
                    repaired = child.Value >= 100
                end
            end
        end
        
        -- Heuristic detection via lights/sound
        if not repaired then
            local lights, sounds = 0, 0
            for _, child in ipairs(gen:GetDescendants()) do
                if (child:IsA("PointLight") or child:IsA("SpotLight")) and child.Enabled and child.Brightness > 1 then
                    lights += 1
                elseif child:IsA("Sound") and child.IsPlaying and child.Volume > 0.1 then
                    sounds += 1
                end
            end
            if lights > 0 and sounds > 0 then repaired = true end
        end
        
        return repaired, progressText
    end

    function GEN.clearGenESP()
        if state.genESPObjects then
            for _, obj in ipairs(state.genESPObjects) do
                if obj and obj.Parent then pcall(obj.Destroy, obj) end
            end
        end
        state.genESPObjects = {}
        if state.genHeartbeatConn then
            pcall(state.genHeartbeatConn.Disconnect, state.genHeartbeatConn)
            state.genHeartbeatConn = nil
        end
    end

    function GEN.createGenBillboard(obj, repaired, progress)
        local bb = Instance.new("BillboardGui")
        bb.Name         = "GenStatus"
        bb.Adornee      = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
        bb.Size         = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset  = Vector3.new(0, 5, 0)
        bb.AlwaysOnTop  = true
        bb.MaxDistance  = 1200
        bb.Parent       = Camera

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size            = UDim2.new(1, 0, 1, 0)
        lbl.Font            = Enum.Font.GothamBold
        lbl.Text            = repaired and "[ REPAIRED ]" or (progress ~= "" and "[ " .. progress .. " ]" or "[ UNREPAIRED ]")
        lbl.TextColor3      = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR
        lbl.TextSize        = 10
        lbl.TextStrokeTransparency = 0.5
        lbl.Parent          = bb
        
        return bb
    end

    function GEN.updateGenerators()
        if not state.genESPEnabled then return end
        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                pcall(function()
                    local repaired, progress = GEN.isGeneratorRepaired(obj)
                    local fillColor = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR
                    
                    -- Highlight
                    local hl = Instance.new("Highlight")
                    hl.FillColor          = fillColor
                    hl.OutlineColor       = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency   = repaired and 0.85 or 0.65
                    hl.OutlineTransparency= 0.4
                    hl.Parent             = obj
                    table.insert(state.genESPObjects, hl)

                    -- Billboard
                    local bb = GEN.createGenBillboard(obj, repaired, progress)
                    table.insert(state.genESPObjects, bb)
                end)
            end
        end
    end

    function GEN.toggleGenESP()
        state.genESPEnabled = not state.genESPEnabled
        Lib.setToggleState(state.genButton, state.genESPEnabled)
        if not state.genESPEnabled then GEN.clearGenESP() return end

        GEN.updateGenerators()
        local lastUpdate = tick()
        state.genHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not state.genESPEnabled then return end
            local t = tick()
            if t - lastUpdate >= constants.GEN_UPDATE_INTERVAL then
                lastUpdate = t
                GEN.updateGenerators()
            end
        end)
    end

    return GEN
end
