return function(services, constants, state, Lib)
    local Workspace  = services.Workspace
    local RunService = services.RunService

    local GEN = {}

    -- ── Heuristic: is this generator repaired? ───────────────────────
    function GEN.isGeneratorRepaired(gen)
        local repaired    = false
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

        -- Heuristic via active lights + sound
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

    -- ── Clear all generator ESP objects ──────────────────────────────
    function GEN.clearGenESP()
        if state.genESPObjects then
            for _, obj in ipairs(state.genESPObjects) do
                if obj and obj.Parent then pcall(obj.Destroy, obj) end
            end
        end
        state.genESPObjects = {}
        if state.genHeartbeatConn then
            pcall(function() state.genHeartbeatConn:Disconnect() end)
            state.genHeartbeatConn = nil
        end
        state.genCachedObjects = nil  -- invalidate cache
    end

    -- ── Scan workspace for generators (cached) ────────────────────────
    -- Returns a list of generator objects. Result is cached to avoid
    -- scanning the full workspace every 2.5 seconds.
    function GEN.findGenerators()
        if state.genCachedObjects then return state.genCachedObjects end

        local found   = {}
        local seenAncestors = {}  -- prevent double-highlighting nested models

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Skip if an ancestor has already been identified as a generator
            local skip = false
            local parent = obj.Parent
            while parent and parent ~= Workspace do
                if seenAncestors[parent] then skip = true break end
                parent = parent.Parent
            end
            if skip then continue end

            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                found[#found + 1] = obj
                seenAncestors[obj] = true
            end
        end

        state.genCachedObjects = found
        return found
    end

    -- ── Create billboard label for a generator ───────────────────────
    function GEN.createGenBillboard(obj, repaired, progress)
        local Camera  = services.getCamera()
        local adornee = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj

        local bb = Instance.new("BillboardGui")
        bb.Name        = "GenStatus"
        bb.Adornee     = adornee
        bb.Size        = UDim2.new(0, 110, 0, 22)
        bb.StudsOffset = Vector3.new(0, 5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 1200
        bb.Parent      = Camera

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, 0, 1, 0)
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextStrokeTransparency = 0.5
        lbl.TextSize               = 10
        lbl.Parent                 = bb

        if repaired then
            lbl.Text       = "[ REPAIRED ]"
            lbl.TextColor3 = constants.COLORS.GEN_REPAIRED
        elseif progress ~= "" then
            lbl.Text       = "[ " .. progress .. " ]"
            lbl.TextColor3 = constants.COLORS.GEN_NEEDS_REPAIR
        else
            lbl.Text       = "[ UNREPAIRED ]"
            lbl.TextColor3 = constants.COLORS.GEN_NEEDS_REPAIR
        end

        return bb
    end

    -- ── Update generator status indicators (uses cached list) ─────────
    function GEN.updateGenerators()
        if not state.genESPEnabled then return end

        -- Destroy old billboards/highlights
        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}

        -- Rebuild using cached or freshly-scanned list
        local generators = GEN.findGenerators()
        for _, obj in ipairs(generators) do
            -- Guard: skip destroyed objects and re-scan if needed
            if not obj or not obj.Parent then
                state.genCachedObjects = nil  -- cache invalidated
                continue
            end

            pcall(function()
                local repaired, progress = GEN.isGeneratorRepaired(obj)
                local fillColor = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR

                local hl = Instance.new("Highlight")
                hl.FillColor           = fillColor
                hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency    = repaired and 0.85 or 0.65
                hl.OutlineTransparency = 0.4
                hl.Parent              = obj
                table.insert(state.genESPObjects, hl)

                local bb = GEN.createGenBillboard(obj, repaired, progress)
                table.insert(state.genESPObjects, bb)
            end)
        end
    end

    -- ── Toggle ───────────────────────────────────────────────────────
    function GEN.toggleGenESP()
        state.genESPEnabled = not state.genESPEnabled
        Lib.setToggleState(state.genButton, state.genESPEnabled)

        if not state.genESPEnabled then
            GEN.clearGenESP()
            return
        end

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
