return function(services, constants, state, Lib)
    local LocalPlayer = services.LocalPlayer

    local MV = {}

    function MV.toggleShiftLock()
        state.shiftLockEnabled = not state.shiftLockEnabled
        Lib.setToggleState(state.shiftLockButton, state.shiftLockEnabled)
        pcall(function()
            LocalPlayer.DevEnableMouseLock = state.shiftLockEnabled
        end)
    end

    return MV
end
