-- ╔══════════════════════════════════════════════════════╗
-- ║  DRONE CAMERA (FREECAM)                            ║
-- ║                                                      ║
-- ║  • Kamera menjadi Scriptable (lepas dari Avatar).    ║
-- ║  • Tombol Panah mengontrol gerak Drone.             ║
-- ║  • WASD tetap mengontrol Avatar.                    ║
-- ║  • Right-Click (Tahan) untuk merotasi pandangan.    ║
-- ╚══════════════════════════════════════════════════════╝
return function(services, constants, state, Lib)
    local RunService         = services.RunService
    local UserInputService   = services.UserInputService
    local ContextActionService = game:GetService("ContextActionService")
    local Workspace          = services.Workspace
    local LocalPlayer        = services.LocalPlayer

    local DRONE = {}
    local speed = 50 -- kecepatan dasar drone (studs per second)

    -- Caching state mouse
    local isRightMouseDown = false
    local inputBeganConn = nil
    local inputEndedConn = nil

    local function blockArrowKeys(actionName, inputState, inputObject)
        -- Sink = blokir input agar tidak diteruskan ke karakter Roblox default
        return Enum.ContextActionResult.Sink
    end

    function DRONE.toggleDroneCam()
        state.droneEnabled = not state.droneEnabled
        Lib.setToggleState(state.droneButton, state.droneEnabled)

        local cam = Workspace.CurrentCamera
        
        if state.droneEnabled then
            -- Mencegah panah menggerakkan karakter
            ContextActionService:BindAction("VD_BlockArrows", blockArrowKeys, false, 
                Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

            -- Inisialisasi Scriptable Camera
            cam.CameraType = Enum.CameraType.Scriptable
            
            -- Set up rotasi mouse via event
            isRightMouseDown = false
            inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    isRightMouseDown = true
                end
            end)
            inputEndedConn = UserInputService.InputEnded:Connect(function(input, gpe)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    isRightMouseDown = false
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
            end)

            -- Rotasi awal (Pitch & Yaw) berdasarkan CFrame orientasi asli
            local x, y, z = cam.CFrame:ToOrientation()
            local pitch = math.deg(x)
            local yaw = math.deg(y)

            state.droneConn = RunService.RenderStepped:Connect(function(dt)
                if not state.droneEnabled then return end
                
                -- ── 1. Rotasi (Right Click Panning) ──
                if isRightMouseDown then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                    local delta = UserInputService:GetMouseDelta()
                    local sensitivty = 0.2
                    yaw = yaw - (delta.X * sensitivty)
                    pitch = math.clamp(pitch - (delta.Y * sensitivty), -85, 85)
                    
                    cam.CFrame = CFrame.new(cam.CFrame.Position) 
                               * CFrame.Angles(0, math.rad(yaw), 0)
                               * CFrame.Angles(math.rad(pitch), 0, 0)
                else
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    -- Update orientasi internal walau sedang tidak right-click
                    local nx, ny, nz = cam.CFrame:ToOrientation()
                    pitch = math.deg(nx)
                    yaw = math.deg(ny)
                end

                -- ── 2. Pergerakan (Movement via Arrow Keys) ──
                local lookVector  = cam.CFrame.LookVector
                local rightVector = cam.CFrame.RightVector
                local moveDir     = Vector3.new(0, 0, 0)

                -- Forward/Backward: Panah Atas/Bawah
                if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                    moveDir = moveDir + lookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                    moveDir = moveDir - lookVector
                end
                
                -- Left/Right: Panah Kiri/Kanan
                if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
                    moveDir = moveDir - rightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
                    moveDir = moveDir + rightVector
                end
                
                -- Up/Down: Q / E (opsional)
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end

                if moveDir.Magnitude > 0 then
                    -- Normalisasi agar gerakan diagonal tidak lebih cepat
                    moveDir = moveDir.Unit
                    
                    -- Speed multiplier jika Shift ditahan (Sprint drone)
                    local spd = speed
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        spd = speed * 2.5
                    end
                    
                    cam.CFrame = cam.CFrame + (moveDir * spd * dt)
                end
            end)
        else
            -- Matikan Drone Mode
            if state.droneConn then
                state.droneConn:Disconnect()
                state.droneConn = nil
            end
            if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
            if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
            
            ContextActionService:UnbindAction("VD_BlockArrows")
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            
            -- Kembalikan ke normal
            cam.CameraType = Enum.CameraType.Custom
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then cam.CameraSubject = hum end
            end
        end
    end

    return DRONE
end
