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
        
        -- Release key if using VIM
        if vim then
            pcall(function()
                vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
            end)
        end
    end

    return MV
end
