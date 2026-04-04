local services = {
    Players          = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService       = game:GetService("RunService"),
    TweenService     = game:GetService("TweenService"),
    Workspace        = game:GetService("Workspace"),
}

services.LocalPlayer = services.Players.LocalPlayer

-- Dynamic camera getter — avoids stale cached reference after workspace changes
function services.getCamera()
    return services.Workspace.CurrentCamera
end

return services
