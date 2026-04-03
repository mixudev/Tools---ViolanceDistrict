return function(services, constants, state, Lib)
    local LocalPlayer = services.LocalPlayer
    local RunService = services.RunService
    local UserInputService = services.UserInputService
    
    -- Try to get VirtualInputManager for better key simulation
    local vim = nil
    pcall(function() vim = game:GetService("VirtualInputManager") end)

    local MV = {}

    function MV.toggleShiftLock()
        state.shiftLockEnabled = not state.shiftLockEnabled
        Lib.setToggleState(state.shiftLockButton, state.shiftLockEnabled)
        
        -- Method 1: VirtualInputManager (Simulate holding Shift)
        if vim then
            pcall(function()
                vim:SendKeyEvent(state.shiftLockEnabled, Enum.KeyCode.LeftShift, false, game)
            end)
        end
        
        -- Method 2: Humanoid.WalkSpeed Fallback (Common sprint speed is 24-28)
        if state.shiftLockEnabled then
            state.shiftLockLoop = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    -- Only set if it's the base speed (16), to avoid conflicts with game logic
                    if hum.WalkSpeed <= 16 and hum.WalkSpeed > 0 then
                        hum.WalkSpeed = 26 -- Force sprint speed
                    end
                end
            end)
        else
            if state.shiftLockLoop then
                state.shiftLockLoop:Disconnect()
                state.shiftLockLoop = nil
            end
            -- Reset speed safely
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed == 26 then
                hum.WalkSpeed = 16
            end
            
            -- Release key if using VIM
            if vim then
                pcall(function()
                    vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                end)
            end
        end
    end

    return MV
end
