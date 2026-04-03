local services = {
    Players          = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService       = game:GetService("RunService"),
    TweenService     = game:GetService("TweenService"),
    Workspace        = game:GetService("Workspace"),
}
services.LocalPlayer = services.Players.LocalPlayer
services.Camera      = services.Workspace.CurrentCamera

return services
