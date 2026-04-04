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
    local function isEscapeBarFull()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return false end

        local foundFull = false
        
        for _, child in ipairs(gui:GetDescendants()) do
            -- Abaikan UI Core milik script kita
            if child.Name == "VD_ESPMenu_v2" or child:IsA("ScreenGui") and child.Name:find("VD_") then
                continue
            end
            
            -- Cek TextLabel yang berisi indikator 100% atau persentase penuh
            if child:IsA("TextLabel") and child.Visible then
                local txt = child.Text:lower()
                if txt:find("100%%") or txt:find("100/100") then
                    -- Pastikan ini bar untuk unhook/escape/camp
                    if txt:find("escape") or txt:find("unhook") or txt:find("camp") or txt:find("chance") or txt:find("struggle") then
                        foundFull = true
                        break
                    end
                end
            end
            
            -- Cek UI Bar (Frame) yang ukurannya terisi penuh
            if child:IsA("Frame") and child.Visible then
                -- Biasa bar mengisi frame, scale X mendekati 1.0 (100%)
                local scaleX = child.Size.X.Scale
                if scaleX >= 0.99 and scaleX <= 1.0 then
                    local n = child.Name:lower()
                    if n:find("bar") or n:find("fill") or n:find("prog") or n:find("meter") or n:find("camp") then
                        -- Syarat: tinggi bar cukup kecil (biasanya bar itu horizontal)
                        if child.AbsoluteSize.Y > 0 and child.AbsoluteSize.Y < 50 then
                            foundFull = true
                            break
                        end
                    end
                end
            end
            
            -- Cek NumberValue/IntValue jika game menyimpan progress di UI
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                if child.Value >= 100 or (child.Value >= 0.99 and child.Value <= 1.0) then
                    local n = child.Name:lower()
                    if n:find("prog") or n:find("camp") or n:find("escape") or n:find("chance") then
                        foundFull = true
                        break
                    end
                end
            end
        end

        -- Cek progress value di Character
        if not foundFull and LocalPlayer.Character then
            for _, child in ipairs(LocalPlayer.Character:GetDescendants()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    if child.Value >= 100 or (child.Value >= 0.99 and child.Value <= 1.0) then
                        local n = child.Name:lower()
                        if n:find("prog") or n:find("camp") or n:find("escape") or n:find("chance") or n:find("struggle") then
                            foundFull = true
                            break
                        end
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
