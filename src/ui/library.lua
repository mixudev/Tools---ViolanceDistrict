return function(services)
    local TweenService = services.TweenService
    local Lib = {}

    -- ═══════════════════════════════════════════════════════════════
    --  PRIMITIVE HELPERS
    -- ═══════════════════════════════════════════════════════════════

    function Lib.addCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 6)
        c.Parent = parent
        return c
    end

    function Lib.addStroke(parent, color, thickness, trans)
        local s = Instance.new("UIStroke")
        s.Color        = color or Color3.fromRGB(45, 45, 52)
        s.Thickness    = thickness or 1
        s.Transparency = trans or 0.4
        s.Parent       = parent
        return s
    end

    function Lib.tween(inst, dur, props)
        TweenService:Create(
            inst,
            TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            props
        ):Play()
    end

    -- ═══════════════════════════════════════════════════════════════
    --  LAYOUT HELPERS
    -- ═══════════════════════════════════════════════════════════════

    --- Adds a UIListLayout (vertical auto-stack) to a frame/scrollframe.
    function Lib.setupListLayout(parent, spacing)
        local layout = Instance.new("UIListLayout")
        layout.FillDirection       = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment   = Enum.VerticalAlignment.Top
        layout.Padding             = UDim.new(0, spacing or 4)
        layout.SortOrder           = Enum.SortOrder.LayoutOrder
        layout.Parent              = parent
        return layout
    end

    --- Adds UIPadding to a frame.
    function Lib.addPadding(parent, top, bottom, left, right)
        local p = Instance.new("UIPadding")
        p.PaddingTop    = UDim.new(0, top    or 0)
        p.PaddingBottom = UDim.new(0, bottom or 0)
        p.PaddingLeft   = UDim.new(0, left   or 0)
        p.PaddingRight  = UDim.new(0, right  or 0)
        p.Parent        = parent
        return p
    end

    -- ═══════════════════════════════════════════════════════════════
    --  SECTION LABEL  (no yPos — UIListLayout handles positioning)
    -- ═══════════════════════════════════════════════════════════════

    function Lib.createSectionLabel(parent, text)
        local wrapper = Instance.new("Frame")
        wrapper.BackgroundTransparency = 1
        wrapper.BorderSizePixel        = 0
        wrapper.Size                   = UDim2.new(1, 0, 0, 22)
        wrapper.Parent                 = parent

        -- Shadow pass
        local shadow = Instance.new("TextLabel")
        shadow.BackgroundTransparency = 1
        shadow.Position       = UDim2.new(0, 9, 0, 5)
        shadow.Size           = UDim2.new(1, -9, 1, -5)
        shadow.Font           = Enum.Font.GothamBold
        shadow.Text           = text:upper()
        shadow.TextColor3     = Color3.fromRGB(0, 80, 160)
        shadow.TextSize       = 9
        shadow.TextTransparency = 0.55
        shadow.TextXAlignment = Enum.TextXAlignment.Left
        shadow.ZIndex         = 1
        shadow.Parent         = wrapper

        -- Main label
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position       = UDim2.new(0, 8, 0, 4)
        lbl.Size           = UDim2.new(1, -8, 1, -4)
        lbl.Font           = Enum.Font.GothamBold
        lbl.Text           = text:upper()
        lbl.TextColor3     = Color3.fromRGB(80, 150, 255)
        lbl.TextSize       = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex         = 2
        lbl.Parent         = wrapper

        return wrapper
    end

    -- ═══════════════════════════════════════════════════════════════
    --  TOGGLE  (modern pill-switch, no yPos)
    -- ═══════════════════════════════════════════════════════════════

    function Lib.createToggle(parent, name, callback)
        local btn = Instance.new("TextButton")
        btn.Name                   = name
        btn.BackgroundColor3       = Color3.fromRGB(20, 20, 26)
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel        = 0
        btn.Size                   = UDim2.new(1, 0, 0, 40)
        btn.Text                   = ""
        btn.AutoButtonColor        = false
        btn.Parent                 = parent
        Lib.addCorner(btn, 7)
        Lib.addStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.93)

        -- Feature name
        local lbl = Instance.new("TextLabel")
        lbl.Name                   = "Label"
        lbl.BackgroundTransparency = 1
        lbl.Position               = UDim2.new(0, 14, 0, 0)
        lbl.Size                   = UDim2.new(0.65, 0, 1, 0)
        lbl.Font                   = Enum.Font.GothamMedium
        lbl.Text                   = name
        lbl.TextColor3             = Color3.fromRGB(195, 195, 215)
        lbl.TextSize               = 12
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = btn

        -- Pill track (outer)
        local pill = Instance.new("Frame")
        pill.Name             = "PillToggle"
        pill.BackgroundColor3 = Color3.fromRGB(50, 52, 62)
        pill.BorderSizePixel  = 0
        pill.AnchorPoint      = Vector2.new(1, 0.5)
        pill.Position         = UDim2.new(1, -12, 0.5, 0)
        pill.Size             = UDim2.new(0, 36, 0, 18)
        pill.Parent           = btn
        Lib.addCorner(pill, 9)

        -- Knob (inner circle)
        local knob = Instance.new("Frame")
        knob.Name             = "Knob"
        knob.BackgroundColor3 = Color3.fromRGB(175, 175, 195)
        knob.BorderSizePixel  = 0
        knob.AnchorPoint      = Vector2.new(0, 0.5)
        knob.Position         = UDim2.new(0, 2, 0.5, 0)   -- OFF = left
        knob.Size             = UDim2.new(0, 14, 0, 14)
        knob.Parent           = pill
        Lib.addCorner(knob, 7)

        -- Hover effects
        btn.MouseEnter:Connect(function()
            Lib.tween(btn, 0.15, {
                BackgroundColor3 = Color3.fromRGB(27, 27, 35),
                BackgroundTransparency = 0.05,
            })
        end)
        btn.MouseLeave:Connect(function()
            Lib.tween(btn, 0.15, {
                BackgroundColor3 = Color3.fromRGB(20, 20, 26),
                BackgroundTransparency = 0.2,
            })
        end)

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- ═══════════════════════════════════════════════════════════════
    --  DIVIDER  (no yPos)
    -- ═══════════════════════════════════════════════════════════════

    function Lib.createDivider(parent)
        local wrapper = Instance.new("Frame")
        wrapper.BackgroundTransparency = 1
        wrapper.BorderSizePixel        = 0
        wrapper.Size                   = UDim2.new(1, 0, 0, 12)
        wrapper.Parent                 = parent

        local d = Instance.new("Frame")
        d.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
        d.BackgroundTransparency = 0.94
        d.BorderSizePixel        = 0
        d.AnchorPoint            = Vector2.new(0, 0.5)
        d.Position               = UDim2.new(0, 4, 0.5, 0)
        d.Size                   = UDim2.new(1, -8, 0, 1)
        d.Parent                 = wrapper

        return wrapper
    end

    -- ═══════════════════════════════════════════════════════════════
    --  ACTION BUTTON  (satu kali klik, bukan toggle on/off)
    --  Cocok untuk aksi seperti "Escape Hook", "Teleport", dll.
    -- ═══════════════════════════════════════════════════════════════

    function Lib.createButton(parent, name, callback)
        local btn = Instance.new("TextButton")
        btn.Name                   = name
        btn.BackgroundColor3       = Color3.fromRGB(10, 110, 210)
        btn.BackgroundTransparency = 0.05
        btn.BorderSizePixel        = 0
        btn.Size                   = UDim2.new(1, 0, 0, 40)
        btn.Text                   = ""
        btn.AutoButtonColor        = false
        btn.Parent                 = parent
        Lib.addCorner(btn, 7)
        Lib.addStroke(btn, Color3.fromRGB(0, 170, 255), 1, 0.45)

        -- Label
        local lbl = Instance.new("TextLabel")
        lbl.Name                   = "Label"
        lbl.BackgroundTransparency = 1
        lbl.Position               = UDim2.new(0, 14, 0, 0)
        lbl.Size                   = UDim2.new(1, -40, 1, 0)
        lbl.Font                   = Enum.Font.GothamBold
        lbl.Text                   = name
        lbl.TextColor3             = Color3.fromRGB(220, 235, 255)
        lbl.TextSize               = 12
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = btn

        -- Arrow icon (kanan)
        local icon = Instance.new("TextLabel")
        icon.Name                   = "Icon"
        icon.BackgroundTransparency = 1
        icon.AnchorPoint            = Vector2.new(1, 0.5)
        icon.Position               = UDim2.new(1, -12, 0.5, 0)
        icon.Size                   = UDim2.new(0, 18, 0, 18)
        icon.Font                   = Enum.Font.GothamBold
        icon.Text                   = "▶"
        icon.TextColor3             = Color3.fromRGB(130, 195, 255)
        icon.TextSize               = 10
        icon.Parent                 = btn

        -- Hover
        btn.MouseEnter:Connect(function()
            Lib.tween(btn, 0.12, {
                BackgroundColor3       = Color3.fromRGB(0, 140, 240),
                BackgroundTransparency = 0,
            })
        end)
        btn.MouseLeave:Connect(function()
            Lib.tween(btn, 0.12, {
                BackgroundColor3       = Color3.fromRGB(10, 110, 210),
                BackgroundTransparency = 0.05,
            })
        end)

        -- Click ripple + callback
        btn.MouseButton1Click:Connect(function()
            Lib.tween(btn, 0.06, { BackgroundColor3 = Color3.fromRGB(0, 200, 255) })
            task.delay(0.08, function()
                Lib.tween(btn, 0.2, { BackgroundColor3 = Color3.fromRGB(10, 110, 210) })
            end)
            callback()
        end)

        return btn
    end

    --- Ubah tampilan button saat sedang running / idle.
    --- running=true  → tombol redup + label berubah + icon spinner
    --- running=false → kembali normal
    function Lib.setButtonRunning(btn, running, runningText)
        if not btn then return end
        local lbl  = btn:FindFirstChild("Label")
        local icon = btn:FindFirstChild("Icon")
        if running then
            Lib.tween(btn, 0.15, {
                BackgroundColor3       = Color3.fromRGB(5, 70, 130),
                BackgroundTransparency = 0.2,
            })
            if lbl  then lbl.Text  = runningText or "RUNNING..." end
            if icon then icon.Text = "◼" end
        else
            Lib.tween(btn, 0.15, {
                BackgroundColor3       = Color3.fromRGB(10, 110, 210),
                BackgroundTransparency = 0.05,
            })
            if lbl  then lbl.Text  = btn.Name end
            if icon then icon.Text = "▶" end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    --  SET TOGGLE STATE  (animates the pill switch)
    -- ═══════════════════════════════════════════════════════════════

    function Lib.setToggleState(btn, active)
        if not btn then return end
        local pill = btn:FindFirstChild("PillToggle")
        if not pill then return end
        local knob = pill:FindFirstChild("Knob")
        local lbl  = btn:FindFirstChild("Label")

        if active then
            Lib.tween(pill, 0.18, { BackgroundColor3 = Color3.fromRGB(0, 155, 255) })
            if knob then
                Lib.tween(knob, 0.18, {
                    Position         = UDim2.new(0, 20, 0.5, 0),  -- slide right = ON
                    BackgroundColor3 = Color3.fromRGB(235, 242, 255),
                })
            end
            if lbl then
                Lib.tween(lbl, 0.18, { TextColor3 = Color3.fromRGB(225, 230, 255) })
            end
        else
            Lib.tween(pill, 0.18, { BackgroundColor3 = Color3.fromRGB(50, 52, 62) })
            if knob then
                Lib.tween(knob, 0.18, {
                    Position         = UDim2.new(0, 2, 0.5, 0),   -- slide left = OFF
                    BackgroundColor3 = Color3.fromRGB(175, 175, 195),
                })
            end
            if lbl then
                Lib.tween(lbl, 0.18, { TextColor3 = Color3.fromRGB(195, 195, 215) })
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    --  TOAST NOTIFICATION
    -- ═══════════════════════════════════════════════════════════════

    function Lib.showToast(screenGui, message, duration)
        if not screenGui then return end
        duration = duration or 1.8

        -- Remove any existing toast to avoid stacking
        local existing = screenGui:FindFirstChild("VD_Toast")
        if existing then existing:Destroy() end

        local toast = Instance.new("Frame")
        toast.Name                   = "VD_Toast"
        toast.BackgroundColor3       = Color3.fromRGB(16, 16, 24)
        toast.BackgroundTransparency = 0.06
        toast.BorderSizePixel        = 0
        toast.AnchorPoint            = Vector2.new(0.5, 1)
        toast.Position               = UDim2.new(0.5, 0, 1, 10)  -- off-screen
        toast.Size                   = UDim2.new(0, 220, 0, 34)
        toast.ZIndex                 = 30
        toast.Parent                 = screenGui
        Lib.addCorner(toast, 9)
        Lib.addStroke(toast, Color3.fromRGB(0, 155, 255), 1, 0.4)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, -20, 1, 0)
        lbl.Position               = UDim2.new(0, 10, 0, 0)
        lbl.Font                   = Enum.Font.GothamMedium
        lbl.Text                   = message
        lbl.TextColor3             = Color3.fromRGB(215, 220, 245)
        lbl.TextSize               = 11
        lbl.TextXAlignment         = Enum.TextXAlignment.Center
        lbl.ZIndex                 = 31
        lbl.Parent                 = toast

        -- Slide up
        Lib.tween(toast, 0.28, { Position = UDim2.new(0.5, 0, 1, -55) })

        task.delay(duration, function()
            if toast and toast.Parent then
                Lib.tween(toast, 0.22, { Position = UDim2.new(0.5, 0, 1, 10) })
                task.delay(0.25, function()
                    if toast and toast.Parent then toast:Destroy() end
                end)
            end
        end)
    end

    return Lib
end
