return function(services)
    local TweenService = services.TweenService
    local Lib = {}

    function Lib.addCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 8)
        c.Parent = parent
        return c
    end

    function Lib.addStroke(parent, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color     = color or Color3.fromRGB(50, 50, 56)
        s.Thickness = thickness or 1
        s.Parent    = parent
        return s
    end

    function Lib.tween(inst, dur, props)
        TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    function Lib.createSectionLabel(parent, text, yPos)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position        = UDim2.new(0, 4, 0, yPos)
        lbl.Size            = UDim2.new(1, 0, 0, 18)
        lbl.Font            = Enum.Font.GothamMedium
        lbl.Text            = text:upper()
        lbl.TextColor3      = Color3.fromRGB(65, 105, 165)
        lbl.TextSize        = 10
        lbl.TextXAlignment  = Enum.TextXAlignment.Left
        lbl.Parent          = parent
        return lbl
    end

    function Lib.createToggle(parent, name, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Name             = name
        btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        btn.BorderSizePixel  = 0
        btn.Position         = UDim2.new(0, 0, 0, yPos)
        btn.Size             = UDim2.new(1, 0, 0, 44)
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.Parent           = parent
        Lib.addCorner(btn, 7)
        Lib.addStroke(btn, Color3.fromRGB(36, 36, 44))

        local acBar = Instance.new("Frame")
        acBar.Name             = "Accent"
        acBar.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        acBar.BorderSizePixel  = 0
        acBar.Position         = UDim2.new(0, 0, 0.2, 0)
        acBar.Size             = UDim2.new(0, 3, 0.6, 0)
        acBar.Parent           = btn
        Lib.addCorner(acBar, 2)

        local lbl = Instance.new("TextLabel")
        lbl.Name                 = "Label"
        lbl.BackgroundTransparency = 1
        lbl.Position             = UDim2.new(0, 18, 0, 0)
        lbl.Size                 = UDim2.new(0.68, 0, 1, 0)
        lbl.Font                 = Enum.Font.GothamMedium
        lbl.Text                 = name
        lbl.TextColor3           = Color3.fromRGB(190, 190, 200)
        lbl.TextSize             = 13
        lbl.TextXAlignment       = Enum.TextXAlignment.Left
        lbl.Parent               = btn

        local status = Instance.new("TextLabel")
        status.Name              = "Status"
        status.BackgroundTransparency = 1
        status.Position          = UDim2.new(0.7, 0, 0, 0)
        status.Size              = UDim2.new(0.3, -8, 1, 0)
        status.Font              = Enum.Font.GothamBold
        status.Text              = "OFF"
        status.TextColor3        = Color3.fromRGB(95, 95, 105)
        status.TextSize          = 11
        status.TextXAlignment    = Enum.TextXAlignment.Right
        status.Parent            = btn

        btn.MouseEnter:Connect(function()  Lib.tween(btn, 0.15, { BackgroundColor3 = Color3.fromRGB(28, 28, 36) }) end)
        btn.MouseLeave:Connect(function()  Lib.tween(btn, 0.15, { BackgroundColor3 = Color3.fromRGB(22, 22, 28) }) end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    function Lib.createDivider(parent, yPos)
        local d = Instance.new("Frame")
        d.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
        d.BorderSizePixel  = 0
        d.Position         = UDim2.new(0, 0, 0, yPos)
        d.Size             = UDim2.new(1, 0, 0, 1)
        d.Parent           = parent
    end

    function Lib.setToggleState(btn, state)
        if not btn then return end
        local st = btn:FindFirstChild("Status")
        local ac = btn:FindFirstChild("Accent")
        if not st then return end
        if state then
            st.Text       = "ON"
            st.TextColor3 = Color3.fromRGB(75, 210, 105)
            if ac then ac.BackgroundColor3 = Color3.fromRGB(55, 175, 85) end
        else
            st.Text       = "OFF"
            st.TextColor3 = Color3.fromRGB(95, 95, 105)
            if ac then ac.BackgroundColor3 = Color3.fromRGB(55, 55, 62) end
        end
    end

    return Lib
end
