-- ╔══════════════════════════════════════════════════════╗
-- ║  MOVEMENT — Shift Lock (Auto-Hold Shift)             ║
-- ║  VIM Method: continuously fires LeftShift heartbeat   ║
-- ║  Fallback : boosts WalkSpeed if VIM unavailable      ║
-- ╚══════════════════════════════════════════════════════╝
return function(services, constants, state, Lib)
    local RunService   = services.RunService
    local LocalPlayer  = services.LocalPlayer

    -- Try VirtualInputManager (available on most exploit executors)
    local vim = nil
    pcall(function() vim = game:GetService("VirtualInputManager") end)

    local MV = {}

    -- ── Internal helpers ────────────────────────────────────────────

    local function stopShiftLoop()
        if state.shiftLockConn then
            pcall(function() state.shiftLockConn:Disconnect() end)
            state.shiftLockConn = nil
        end
    end

    local function sendShift(isDown)
        if vim then
            pcall(function()
                vim:SendKeyEvent(isDown, Enum.KeyCode.LeftShift, false, game)
            end)
        end
    end

    local function getHumanoid()
        local char = LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    -- ── Shift Lock Toggle ───────────────────────────────────────────

    function MV.toggleShiftLock()
        state.shiftLockEnabled = not state.shiftLockEnabled
        Lib.setToggleState(state.shiftLockButton, state.shiftLockEnabled)

        if state.shiftLockEnabled then
            -- ── Method A: VirtualInputManager (preferred) ──────────
            if vim then
                -- Send shift keydown every heartbeat frame while enabled.
                -- This continuously simulates the player holding LeftShift,
                -- triggering the game's own sprint/run detection logic.
                state.shiftLockConn = RunService.Heartbeat:Connect(function()
                    if not state.shiftLockEnabled then
                        stopShiftLoop()
                        sendShift(false)  -- release key on disable
                        return
                    end
                    sendShift(true)
                end)

            -- ── Method B: WalkSpeed multiplier (fallback) ───────────
            else
                local function applySpeed(char)
                    if not state.shiftLockEnabled then return end
                    task.wait(0.1)  -- wait for humanoid to init
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    -- Store original speed only once
                    if not state.shiftLockOriginalSpeed then
                        state.shiftLockOriginalSpeed = hum.WalkSpeed
                    end
                    hum.WalkSpeed = state.shiftLockOriginalSpeed * 1.5
                end

                -- Apply immediately on current character
                applySpeed(LocalPlayer.Character)

                -- Reapply after each respawn
                state.shiftLockConn = LocalPlayer.CharacterAdded:Connect(applySpeed)
            end

        else
            -- ── Disable ─────────────────────────────────────────────
            stopShiftLoop()
            sendShift(false)

            -- Restore WalkSpeed if we used the fallback method
            if not vim then
                local hum = getHumanoid()
                if hum and state.shiftLockOriginalSpeed then
                    hum.WalkSpeed = state.shiftLockOriginalSpeed
                end
                state.shiftLockOriginalSpeed = nil
            end
        end
    end

    return MV
end
