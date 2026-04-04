return function(services, constants, state, Lib)
    local Workspace  = services.Workspace
    local RunService = services.RunService

    local GEN = {}

    -- ══════════════════════════════════════════════════════════════════
    --  DETEKSI STATUS GENERATOR — Multi-layer, comprehensive
    --
    --  Layer 1: Roblox Attributes (API modern, banyak game pakai ini)
    --  Layer 2: BoolValue/NumberValue bernama repaired/complete/etc
    --  Layer 3: Heuristik lampu HIJAU (G dominant + brightness wajar)
    -- ══════════════════════════════════════════════════════════════════
    local REPAIR_ATTR  = {"Repaired","IsRepaired","Complete","IsComplete","Fixed","Done","Finished","Activated","Active"}
    local PROGRESS_KW  = {"progress","repair","complet","charge","fill","percent"}
    local REPAIRED_KW  = {"repaired","fixed","complet","done","finish","activ"}

    function GEN.isGeneratorRepaired(gen)

        -- ── Layer 1: Roblox Attributes on generator root ──────────────
        for _, attr in ipairs(REPAIR_ATTR) do
            local ok, val = pcall(function() return gen:GetAttribute(attr) end)
            if ok and val ~= nil then
                if val == true then return true end
                if type(val) == "number" then
                    if val >= 100 then return true end
                    if val >= 0.99 and val <= 1.0 then return true end
                end
            end
        end

        -- ── Layer 2: Scan semua descendants ───────────────────────────
        for _, child in ipairs(gen:GetDescendants()) do
            local n = child.Name:lower()

            -- Roblox Attribute pada tiap descendant
            for _, attr in ipairs(REPAIR_ATTR) do
                local ok, val = pcall(function() return child:GetAttribute(attr) end)
                if ok and val ~= nil then
                    if val == true then return true end
                    if type(val) == "number" and val >= 100 then return true end
                    if type(val) == "number" and val >= 0.99 and val <= 1.0 then return true end
                end
            end

            -- BoolValue bernama keyword repaired
            if child:IsA("BoolValue") and child.Value then
                for _, kw in ipairs(REPAIRED_KW) do
                    if n:find(kw) then return true end
                end
            end

            -- NumberValue / IntValue progress — HARUS penuh
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local v = child.Value
                local isProgressName = false
                for _, kw in ipairs(PROGRESS_KW) do
                    if n:find(kw) then isProgressName = true break end
                end
                if isProgressName then
                    if v >= 100 then return true end     -- skala 0-100
                    if v >= 0.99 and v <= 1.0 then return true end  -- skala 0-1
                end
            end

            -- StringValue berisi kata selesai
            if child:IsA("StringValue") then
                local v = child.Value:lower()
                for _, kw in ipairs(REPAIRED_KW) do
                    if v == kw or v == "true" or v == "1" then
                        for _, kw2 in ipairs(REPAIRED_KW) do
                            if n:find(kw2) then return true end
                        end
                    end
                end
            end
        end

        -- ── Layer 3: Lampu HIJAU aktif ────────────────────────────────
        --  Hanya hijau yang jelas: G > R dan G > B, brightness >= 0.8
        --  Tidak terlalu strict supaya tetap mendeteksi berbagai shade hijau
        for _, child in ipairs(gen:GetDescendants()) do
            if (child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight"))
               and child.Enabled then
                local c  = child.Color
                local br = child.Brightness
                -- G harus lebih terang dari R dan B
                if c.G > c.R and c.G > c.B and br >= 0.8 then
                    return true
                end
            end
        end

        return false
    end

    -- ── Clear ─────────────────────────────────────────────────────────
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
        state.genCachedObjects = nil
    end

    -- ── Scan generators (with cache) ──────────────────────────────────
    function GEN.findGenerators()
        if state.genCachedObjects then return state.genCachedObjects end
        local found = {}
        local seen  = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local skip = false
            local p = obj.Parent
            while p and p ~= Workspace do
                if seen[p] then skip = true break end
                p = p.Parent
            end
            if skip then continue end
            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                found[#found + 1] = obj
                seen[obj] = true
            end
        end
        state.genCachedObjects = found
        return found
    end

    -- ── Update highlights (colour only, no text) ───────────────────────
    function GEN.updateGenerators()
        if not state.genESPEnabled then return end
        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}
        for _, obj in ipairs(GEN.findGenerators()) do
            if not obj or not obj.Parent then state.genCachedObjects = nil continue end
            pcall(function()
                local repaired  = GEN.isGeneratorRepaired(obj)
                local col       = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR
                local hl        = Instance.new("Highlight")
                hl.FillColor           = col
                hl.OutlineColor        = col
                hl.FillTransparency    = repaired and 0.72 or 0.58
                hl.OutlineTransparency = repaired and 0.25 or 0.18
                hl.Parent              = obj
                table.insert(state.genESPObjects, hl)
            end)
        end
    end

    -- ── Debug (run _G.VD_GenDebug() in executor console) ─────────────
    function GEN.debugNearestGenerator()
        local lp   = services.Players and services.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then warn("[VD-Debug] No character.") return end
        local nearest, nd = nil, math.huge
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d < nd then nd = d nearest = obj end
                end
            end
        end
        if not nearest then warn("[VD-Debug] No generator found.") return end
        print(("[VD-Debug] '%s'  %.1f studs  →  %s"):format(
            nearest.Name, nd, GEN.isGeneratorRepaired(nearest) and "REPAIRED ✓" or "UNREPAIRED ✗"))
        -- Print attributes
        print("[VD-Debug] Attributes on root:")
        for k, v in pairs(pcall(nearest.GetAttributes, nearest) and nearest:GetAttributes() or {}) do
            print(("  %s = %s"):format(k, tostring(v)))
        end
        -- Print descendants
        print("[VD-Debug] Descendants:")
        for _, child in ipairs(nearest:GetDescendants()) do
            local val = "—"
            pcall(function()
                if child:IsA("ValueBase") then val = tostring(child.Value)
                elseif child:IsA("Light") then
                    val = ("En=%s Br=%.2f RGB=(%d,%d,%d)"):format(
                        tostring(child.Enabled), child.Brightness,
                        child.Color.R*255, child.Color.G*255, child.Color.B*255)
                elseif child:IsA("Sound") then
                    val = ("Play=%s Vol=%.2f"):format(tostring(child.IsPlaying), child.Volume)
                end
            end)
            print(("  [%s] %s = %s"):format(child.ClassName, child.Name, val))
        end
    end
    _G.VD_GenDebug = GEN.debugNearestGenerator

    -- ── Toggle ────────────────────────────────────────────────────────
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
