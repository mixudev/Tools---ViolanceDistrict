-- ╔══════════════════════════════════════════════════════╗
-- ║  HOOK ESCAPE — Auto Camp / Skill Check Pasing        ║
-- ║                                                      ║
-- ║  Mekanisme Game:                                     ║
-- ║  Harus menahan tombol/klik untuk mengisi bar,        ║
-- ║  kemudian MELEPAS tepat di 100%.                     ║
-- ║  Kurang atau lebih dari 100% = gagal.                ║
-- ╚══════════════════════════════════════════════════════╝
return function(services, constants, state, Lib)
    local RunService  = services.RunService
    local LocalPlayer = services.LocalPlayer
    
    local vim = nil
    pcall(function() vim = game:GetService("VirtualInputManager") end)

    local HE = {}

    -- ── Deteksi Bar 100% (Generic & Heuristic) ────────────────────────
    local cachedEscapeElements = {}
    local lastCacheTime = 0

    local function updateEscapeCache()
        cachedEscapeElements = {}
        
        -- Cache PlayerGui elements
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            local desc = gui:GetDescendants()
            for i = 1, #desc do
                local child = desc[i]
                -- Abaikan UI Core milik script kita
                if child.Name == "VD_ESPMenu_v2" or (child:IsA("ScreenGui") and child.Name:find("VD_")) then
                    continue
                end
                
                -- Hanya simpan objek yang berpotensi menjadi bar progress
                if child:IsA("TextLabel") or child:IsA("Frame") or child:IsA("NumberValue") or child:IsA("IntValue") then
                    table.insert(cachedEscapeElements, child)
                end
            end
        end

        -- Cache Character elements
        if LocalPlayer.Character then
            local desc = LocalPlayer.Character:GetDescendants()
            for i = 1, #desc do
                local child = desc[i]
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    table.insert(cachedEscapeElements, child)
                end
            end
        end
    end

    local function isEscapeBarFull()
        local t = tick()
        -- Update cache maksimal 3x per detik (sangat ringan dibanding 60x per detik)
        if t - lastCacheTime > 0.33 then
            updateEscapeCache()
            lastCacheTime = t
        end

        local foundFull = false
        
        for i = 1, #cachedEscapeElements do
            local child = cachedEscapeElements[i]
            -- Skip jika objek sudah dihancurkan game
            if not child or not child.Parent then continue end
            
            if child:IsA("TextLabel") and child.Visible then
                local txt = child.Text:lower()
                if txt:find("100%%") or txt:find("100/100") then
                    if txt:find("escape") or txt:find("unhook") or txt:find("camp") or txt:find("chance") or txt:find("struggle") then
                        foundFull = true
                        break
                    end
                end
            elseif child:IsA("Frame") and child.Visible then
                local scaleX = child.Size.X.Scale
                if scaleX >= 0.99 and scaleX <= 1.0 then
                    local n = child.Name:lower()
                    if n:find("bar") or n:find("fill") or n:find("prog") or n:find("meter") or n:find("camp") then
                        if child.AbsoluteSize.Y > 0 and child.AbsoluteSize.Y < 50 then
                            foundFull = true
                            break
                        end
                    end
                end
            elseif child:IsA("NumberValue") or child:IsA("IntValue") then
                if child.Value >= 100 or (child.Value >= 0.99 and child.Value <= 1.0) then
                    local n = child.Name:lower()
                    if n:find("prog") or n:find("camp") or n:find("escape") or n:find("chance") or n:find("struggle") then
                        foundFull = true
                        break
                    end
                end
            end
        end

        return foundFull
    end

    -- ── Aksi Utama: Auto Hold & Release tepat di 100% ──────────────────
    function HE.performEscape()
        if state.isEscaping then return end
        state.isEscaping = true
        
        Lib.setButtonRunning(state.autoEscapeButton, true, "HOLDING...")

        -- 1. Tekan (Hold) E
        if vim then
            pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
            -- Sebagai tambahan jika game butuh klik mouse (tahan) alih-alih E
            pcall(function() mouse1press() end)
        end

        local MAX_HOLD_TIME = 8 -- Jangan hold lebih dari 8 detik (timeout)
        local tStart = tick()

        state.autoEscapeConn = RunService.RenderStepped:Connect(function()
            local t = tick()
            local isFinished = false

            -- Evaluasi jika bar menyentuh 100%
            if isEscapeBarFull() then
                isFinished = true
            end

            -- Evaluasi timeout safety
            if t - tStart >= MAX_HOLD_TIME then
                isFinished = true
            end

            if isFinished then
                -- 2. Lepas dengan Cepat! (Release persis di 100%)
                if vim then
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
                    pcall(function() mouse1release() end)
                end

                if state.autoEscapeConn then
                    state.autoEscapeConn:Disconnect()
                    state.autoEscapeConn = nil
                end

                state.isEscaping = false
                Lib.setButtonRunning(state.autoEscapeButton, false)
            end
        end)
    end

    -- Debug tool optional
    _G.VD_DebugEscapeUI = function()
        print("[VD-Debug] Mencari bar progress Hook / Camp...")
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("Frame") and child.Visible and child.Size.X.Scale > 0 and child.Size.X.Scale < 1 then
                    print(("  [Frame] '%s' -> Scale = %.2f"):format(child.Name, child.Size.X.Scale))
                elseif (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Value > 0 then
                    print(("  [Value] '%s' -> %s"):format(child.Name, tostring(child.Value)))
                end
            end
        end
    end

    return HE
end
