return function(services, constants, state, Lib)
    local Workspace = services.Workspace
    local RunService = services.RunService

    local GEN = {}

    function GEN.isGeneratorRepaired(gen)
        for _, child in ipairs(gen:GetDescendants()) do
            local n = child.Name:lower()
            if n:find("repaired") or n:find("fixed") or n:find("complete") or n:find("done") then
                if child:IsA("BoolValue") then return child.Value end
                if child:IsA("IntValue") or child:IsA("NumberValue") then return child.Value > 0 end
                return true
            end
            if n:find("progress") then
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    return child.Value >= 100
                end
            end
        end
        local lights, particles, sounds = 0, 0, 0
        for _, child in ipairs(gen:GetDescendants()) do
            if (child:IsA("PointLight") or child:IsA("SpotLight")) and child.Enabled and child.Brightness > 1 then
                lights += 1
            elseif (child:IsA("ParticleEmitter") or child:IsA("Smoke")) and child.Enabled then
                particles += 1
            elseif child:IsA("Sound") and child.IsPlaying and child.Volume > 0.1 then
                sounds += 1
            end
        end
        if lights > 0 and sounds > 0 and particles == 0 then return true end
        if lights > 0 and particles == 0 then return true end
        return false
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

    function GEN.updateGenerators()
        if not state.genESPEnabled then return end
        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}

        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                pcall(function()
                    local repaired = GEN.isGeneratorRepaired(obj)
                    local fillColor = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR
                    
                    local hl = Instance.new("Highlight")
                    hl.FillColor          = fillColor
                    hl.OutlineColor       = fillColor
                    hl.FillTransparency   = repaired and 0.70 or 0.55
                    hl.OutlineTransparency= 0.1
                    hl.Parent             = obj
                    table.insert(state.genESPObjects, hl)
                    count += 1
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
