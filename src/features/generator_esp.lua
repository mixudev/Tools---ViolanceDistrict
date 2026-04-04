return function(services, constants, state, Lib)
    local Workspace  = services.Workspace
    local RunService = services.RunService

    local GEN = {}

    -- ══════════════════════════════════════════════════════════════════
    --  DETEKSI STATUS GENERATOR (Violence District)
    --
    --  Game ini seperti Dead by Daylight:
    --    - Generator punya progress bar 0→100
    --    - Dianggap SELESAI hanya jika progress = 100 (bukan setengah-setengah)
    --    - Lampu HIJAU menyala terang saat generator selesai diperbaiki
    --
    --  Priority check:
    --    1. BoolValue "repaired/fixed/complete/done/on" = true
    --    2. NumberValue progress: >= 100 (skala 0-100) ATAU >= 0.99 (skala 0-1)
    --    3. Lampu HIJAU terang (bukan sembarang lampu)
    -- ══════════════════════════════════════════════════════════════════
    function GEN.isGeneratorRepaired(gen)
        for _, child in ipairs(gen:GetDescendants()) do
            local n = child.Name:lower()

            -- [1] BoolValue status flag = true
            if n:find("repaired") or n:find("fixed") or n:find("complete") or n:find("done") or n:find("finish") then
                if child:IsA("BoolValue") and child.Value then
                    return true
                end
                if (child:IsA("IntValue") or child:IsA("NumberValue")) and child.Value > 0 then
                    return true
                end
                if child:IsA("StringValue") then
                    local v = child.Value:lower()
                    if v == "true" or v == "1" or v == "repaired" or v == "done" then
                        return true
                    end
                end
            end

            -- [2] Progress value — HARUS penuh, bukan setengah-setengah
            --     Skala 0-100: butuh >= 100
            --     Skala 0-1  : butuh >= 0.99
            if n:find("progress") or n:find("repair") or n:find("stage") or n:find("charge") then
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    local v = child.Value
                    -- Skala 0-100
                    if v >= 100 then return true end
                    -- Skala 0-1 (normalized)
                    if v > 1 then
                        -- nilai 1-99 pada skala 0-100 = belum selesai
                    elseif v >= 0.99 then
                        return true
                    end
                end
            end
        end

        -- [3] Heuristik visual: lampu HIJAU TERANG (bukan sembarang lampu)
        --     Lampu selama proses repair biasanya putih/redup
        --     Lampu setelah selesai = hijau cerah dan cukup terang
        for _, child in ipairs(gen:GetDescendants()) do
            if (child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight")) and child.Enabled then
                local c  = child.Color
                local br = child.Brightness
                -- Hijau JELAS: G channel >> R dan B, dan cukup terang
                local isGreen = c.G > 0.5 and c.G > (c.R * 2.0) and c.G > (c.B * 1.5)
                if isGreen and br >= 1.5 then
                    return true
                end
            end
        end

        return false
    end

    -- ── Clear semua generator ESP ────────────────────────────────────
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

    -- ── Scan workspace untuk generator (dengan cache) ─────────────────
    function GEN.findGenerators()
        if state.genCachedObjects then return state.genCachedObjects end

        local found         = {}
        local seenAncestors = {}

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local skip   = false
            local parent = obj.Parent
            while parent and parent ~= Workspace do
                if seenAncestors[parent] then skip = true break end
                parent = parent.Parent
            end
            if skip then continue end

            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                found[#found + 1]  = obj
                seenAncestors[obj] = true
            end
        end

        state.genCachedObjects = found
        return found
    end

    -- ── Update highlight (warna = status, tanpa teks) ─────────────────
    function GEN.updateGenerators()
        if not state.genESPEnabled then return end

        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}

        local generators = GEN.findGenerators()

        for _, obj in ipairs(generators) do
            if not obj or not obj.Parent then
                state.genCachedObjects = nil
                continue
            end

            pcall(function()
                local repaired  = GEN.isGeneratorRepaired(obj)
                local fillColor = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR

                local hl = Instance.new("Highlight")
                hl.FillColor           = fillColor
                hl.OutlineColor        = fillColor
                hl.FillTransparency    = repaired and 0.72 or 0.58
                hl.OutlineTransparency = repaired and 0.25 or 0.18
                hl.Parent              = obj
                table.insert(state.genESPObjects, hl)
            end)
        end
    end

    -- ── Debug: inspect generator terdekat ────────────────────────────
    function GEN.debugNearestGenerator()
        local lp   = services.Players and services.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then warn("[VD-Debug] Tidak ada karakter.") return end

        local nearest, nearestDist = nil, math.huge
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("generator") or n == "gen") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d < nearestDist then nearestDist = d nearest = obj end
                end
            end
        end

        if not nearest then warn("[VD-Debug] Generator tidak ditemukan.") return end

        print(("[VD-Debug] '%s' | %.1f studs | Status: %s"):format(
            nearest.Name, nearestDist,
            GEN.isGeneratorRepaired(nearest) and "REPAIRED ✓" or "UNREPAIRED ✗"))
        print("[VD-Debug] Descendants:")
        for _, child in ipairs(nearest:GetDescendants()) do
            local val = "—"
            pcall(function()
                if child:IsA("ValueBase") then
                    val = tostring(child.Value)
                elseif child:IsA("Light") then
                    val = ("Enabled=%s Brightness=%.2f RGB=(%d,%d,%d)"):format(
                        tostring(child.Enabled), child.Brightness,
                        child.Color.R*255, child.Color.G*255, child.Color.B*255)
                elseif child:IsA("Sound") then
                    val = ("Playing=%s Volume=%.2f"):format(tostring(child.IsPlaying), child.Volume)
                end
            end)
            print(("  [%s] %s = %s"):format(child.ClassName, child.Name, val))
        end
    end
    _G.VD_GenDebug = GEN.debugNearestGenerator

    -- ── Toggle ───────────────────────────────────────────────────────
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
