return function(services, constants, state, Lib)
    local Workspace  = services.Workspace
    local RunService = services.RunService

    local GEN = {}

    -- ══════════════════════════════════════════════════════════════════
    --  DETEKSI STATUS GENERATOR
    --
    --  Logic: generator dianggap "repaired" jika SALAH SATU kondisi
    --  terpenuhi di antara semua descendant-nya (bukan semua harus match).
    --
    --  Urutan prioritas:
    --    1. BoolValue  bernama *repaired / fixed / complete / done*  = true
    --    2. NumberValue bernama *repaired / fixed / complete / done* > 0
    --    3. NumberValue bernama *progress* >= 1  (ada progress apapun)
    --    4. Heuristik lampu: ada PointLight/SpotLight aktif yang terlihat
    --       hijau (G dominan) ATAU sangat terang (Brightness > 2)
    -- ══════════════════════════════════════════════════════════════════
    function GEN.isGeneratorRepaired(gen)
        for _, child in ipairs(gen:GetDescendants()) do
            local n = child.Name:lower()

            -- Prioritas 1 & 2: named bool/number indicators
            if n:find("repaired") or n:find("fixed") or n:find("complete") or n:find("done") then
                if child:IsA("BoolValue") and child.Value then
                    return true
                end
                if (child:IsA("IntValue") or child:IsA("NumberValue")) and child.Value > 0 then
                    return true
                end
            end

            -- Prioritas 3: progress >= 1 (partial juga dihitung repaired di game ini)
            if n:find("progress") then
                if (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Value >= 1 then
                    return true
                end
            end
        end

        -- Prioritas 4: heuristik visual — lampu hijau / lampu sangat terang
        -- Menggunakan OR, bukan AND (cukup salah satu tanda)
        for _, child in ipairs(gen:GetDescendants()) do
            if (child:IsA("PointLight") or child:IsA("SpotLight")) and child.Enabled then
                local c  = child.Color
                local br = child.Brightness
                -- Lampu berwarna hijau (channel G dominan)
                if c.G > 0.35 and c.G > c.R * 1.15 and br > 0.3 then
                    return true
                end
                -- Lampu sangat terang (menyala aktif) tanpa spesifik warna
                if br > 2.5 then
                    return true
                end
            end
            -- Sound yang sedang berjalan juga cukup sebagai tanda
            if child:IsA("Sound") and child.IsPlaying and child.Volume > 0.15 then
                return true
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

        local found        = {}
        local seenAncestors = {}

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Skip jika ancestor-nya sudah masuk daftar (cegah double-highlight)
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

    -- ── Update highlight tiap generator (NO billboard text) ───────────
    --  Bedanya hanya dari warna:
    --    Hijau  (GEN_REPAIRED)     = sudah diperbaiki
    --    Orange (GEN_NEEDS_REPAIR) = belum diperbaiki
    function GEN.updateGenerators()
        if not state.genESPEnabled then return end

        -- Hapus highlight lama
        for _, obj in ipairs(state.genESPObjects) do
            if obj and obj.Parent then pcall(obj.Destroy, obj) end
        end
        state.genESPObjects = {}

        local generators = GEN.findGenerators()

        for _, obj in ipairs(generators) do
            if not obj or not obj.Parent then
                state.genCachedObjects = nil  -- invalidate jika ada yang hilang
                continue
            end

            pcall(function()
                local repaired  = GEN.isGeneratorRepaired(obj)
                local fillColor = repaired and constants.COLORS.GEN_REPAIRED or constants.COLORS.GEN_NEEDS_REPAIR

                local hl = Instance.new("Highlight")
                hl.FillColor           = fillColor
                hl.OutlineColor        = fillColor  -- outline sesuai status juga
                hl.FillTransparency    = repaired and 0.75 or 0.60
                hl.OutlineTransparency = repaired and 0.30 or 0.20
                hl.Parent              = obj
                table.insert(state.genESPObjects, hl)
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
