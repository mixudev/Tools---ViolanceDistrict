return function(services)
    local TweenService = services.TweenService
    local Lib = {}

    function Lib.addCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 6)
        c.Parent = parent
        return c
    end

    function Lib.addStroke(parent, color, thickness, trans)
        local s = Instance.new("UIStroke")
        s.Color     = color or Color3.fromRGB(45, 45, 52)
        s.Thickness = thickness or 1
        s.Transparency = trans or 0.4
        s.Parent    = parent
        return s
    end

    function Lib.tween(inst, dur, props)
        TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
    end

    function Lib.createSectionLabel(parent, text, yPos)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position        = UDim2.new(0, 6, 0, yPos)
        lbl.Size            = UDim2.new(1, 0, 0, 16)
        lbl.Font            = Enum.Font.GothamBold
        lbl.Text            = text:upper()
        lbl.TextColor3      = Color3.fromRGB(80, 150, 255)
        lbl.TextSize        = 9
        lbl.TextXAlignment  = Enum.TextXAlignment.Left
        lbl.Parent          = parent
        
        -- Subtle glow effect for section labels
        local shadow = Instance.new("TextLabel")
        shadow.BackgroundTransparency = 1
        shadow.Position = UDim2.new(0, 1, 0, 1)
        shadow.Size = UDim2.new(1, 0, 1, 0)
        shadow.Font = lbl.Font
        shadow.Text = lbl.Text
        shadow.TextColor3 = Color3.fromRGB(0, 80, 160)
        shadow.TextSize = lbl.TextSize
        shadow.TextTransparency = 0.6
        shadow.TextXAlignment = lbl.TextXAlignment
        shadow.ZIndex = 0
        shadow.Parent = lbl

        return lbl
    end

    function Lib.createToggle(parent, name, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Name             = name
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel  = 0
        btn.Position         = UDim2.new(0, 0, 0, yPos)
        btn.Size             = UDim2.new(1, 0, 0, 42)
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.Parent           = parent
        Lib.addCorner(btn, 6)
        Lib.addStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.92)

        local indicator = Instance.new("Frame")
        indicator.Name             = "Indicator"
        indicator.BackgroundColor3 = Color3.fromRGB(60, 64, 72)
        indicator.BorderSizePixel  = 0
        indicator.Position         = UDim2.new(1, -32, 0.5, -3)
        indicator.Size             = UDim2.new(0, 20, 0, 6)
        indicator.Parent           = btn
        Lib.addCorner(indicator, 10)

        local glow = Instance.new("Frame")
        glow.Name                  = "Glow"
        glow.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
        glow.BackgroundTransparency= 1
        glow.BorderSizePixel       = 0
        glow.Position              = UDim2.new(0.5, -12, 0.5, -12)
        glow.Size                  = UDim2.new(0, 24, 0, 24)
        glow.ZIndex                = 0
        glow.Parent                = indicator
        Lib.addCorner(glow, 99)

        local lbl = Instance.new("TextLabel")
        lbl.Name                 = "Label"
        lbl.BackgroundTransparency = 1
        lbl.Position             = UDim2.new(0, 14, 0, 0)
        lbl.Size                 = UDim2.new(0.7, 0, 1, 0)
        lbl.Font                 = Enum.Font.GothamMedium
        lbl.Text                 = name
        lbl.TextColor3           = Color3.fromRGB(210, 210, 225)
        lbl.TextSize             = 12
        lbl.TextXAlignment       = Enum.TextXAlignment.Left
        lbl.Parent               = btn

        btn.MouseEnter:Connect(function()  
            Lib.tween(btn, 0.2, { BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(28, 28, 34) }) 
        end)
        btn.MouseLeave:Connect(function()  
            Lib.tween(btn, 0.2, { BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(20, 20, 24) }) 
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    function Lib.createDivider(parent, yPos)
        local d = Instance.new("Frame")
        d.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        d.BackgroundTransparency = 0.94
        d.BorderSizePixel  = 0
        d.Position         = UDim2.new(0, 4, 0, yPos)
        d.Size             = UDim2.new(1, -8, 0, 1)
        d.Parent           = parent
    end

    function Lib.setToggleState(btn, state)
        if not btn then return end
        local ind = btn:FindFirstChild("Indicator")
        if not ind then return end
        local glow = ind:FindFirstChild("Glow")
        
        if state then
            Lib.tween(ind, 0.2, { BackgroundColor3 = Color3.fromRGB(0, 180, 255) })
            if glow then Lib.tween(glow, 0.2, { BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(0, 180, 255) }) end
        else
            Lib.tween(ind, 0.2, { BackgroundColor3 = Color3.fromRGB(60, 64, 72) })
            if glow then Lib.tween(glow, 0.2, { BackgroundTransparency = 1 }) end
        end
    end

    return Lib
end
