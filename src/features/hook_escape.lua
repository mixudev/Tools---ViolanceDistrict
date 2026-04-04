-- ╔══════════════════════════════════════════════════════╗
-- ║  HOOK ESCAPE — Auto Camp Escape                      ║
-- ║                                                      ║
-- ║  Mekanisme game:                                     ║
-- ║   • Saat digantung di hook, ada chance kecil (4%)   ║
-- ║     untuk kabur sendiri                              ║
-- ║   • Jika killer CAMPING (dekat hook), anti-camp      ║
-- ║     mechanic aktif → chance naik ke 100%             ║
-- ║   • Fitur ini: auto-tekan tombol escape berkala      ║
-- ║     sambil menunggu chance 100% aktif                ║
-- ║                                                      ║
-- ║  Deteksi "sedang digantung":                         ║
-- ║   1. Cek Attribute / BoolValue "Hooked" di karakter  ║
-- ║   2. Cek Humanoid immobile + dekat hook object       ║
-- ║   3. Cek HumanoidState = PlatformStanding           ║
-- ╚══════════════════════════════════════════════════════╝
return function(services, constants, state, Lib)
    local RunService   = services.RunService
    local LocalPlayer  = services.LocalPlayer
    local Workspace    = services.Workspace

    -- VirtualInputManager untuk simulasi key press
    local vim = nil
    pcall(function() vim = game:GetService("VirtualInputManager") end)

    local HE = {}

    -- ── Internal: apakah player sedang di-hook ────────────────────────
    local HOOK_ATTRS  = {"Hooked","IsHooked","OnHook","Hung","Sacrifice","Caught"}
    local HOOK_KWDS   = {"hook","hang","hung","sacrific","caught","impale"}

    local function isHooked()
        local char = LocalPlayer.Character
        if not char then return false end

        -- Method 1: Roblox Attributes pada Character
        for _, attr in ipairs(HOOK_ATTRS) do
            local ok, val = pcall(function() return char:GetAttribute(attr) end)
            if ok and val == true then return true end
        end

        -- Method 2: BoolValue / StringValue bertanda hooked
        for _, child in ipairs(char:GetDescendants()) do
            local n = child.Name:lower()
            local isHookName = false
            for _, kw in ipairs(HOOK_KWDS) do
                if n:find(kw) then isHookName = true break end
            end
            if isHookName then
                if child:IsA("BoolValue") and child.Value then return true end
                if child:IsA("StringValue") then
                    local v = child.Value:lower()
                    if v == "true" or v == "hooked" or v == "hung" then return true end
                end
            end
        end

        -- Method 3: HumanoidState = PlatformStanding (Roblox standard saat hook)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.PlatformStanding then
                return true
            end
            -- Fallback: WalkSpeed=0 dan JumpPower=0 + dekat hook object
            if hum.WalkSpeed == 0 and hum.JumpPower == 0 and hum.Health > 0 then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        local n = obj.Name:lower()
                        if obj:IsA("BasePart") then
                            for _, kw in ipairs(HOOK_KWDS) do
                                if n:find(kw) then
                                    if (root.Position - obj.Position).Magnitude < 8 then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return false
    end

    -- ── Internal: percobaan kabur dari hook ───────────────────────────
    local function attemptEscape()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Cari ProximityPrompt di hook object terdekat
        -- (fireproximityprompt = executor function yang bypass jarak/cooldown)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            local isHookObj = false
            for _, kw in ipairs(HOOK_KWDS) do
                if n:find(kw) then isHookObj = true break end
            end

            if isHookObj then
                local refPart = obj:IsA("BasePart") and obj
                             or obj:FindFirstChildOfClass("BasePart")
                if refPart and (root.Position - refPart.Position).Magnitude < 15 then
                    -- Cari ProximityPrompt di obj dan anak-anaknya
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                or obj:FindFirstChild("ProximityPrompt", true)
                    if prompt then
                        -- fireproximityprompt = exploit executor API
                        pcall(function() fireproximityprompt(prompt) end)
                        return
                    end
                end
            end
        end

        -- Fallback: simulasi klik E (tombol interaksi default Roblox)
        if vim then
            pcall(function() vim:SendKeyEvent(true,  Enum.KeyCode.E, false, game) end)
            task.wait(0.05)
            pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        end
    end

    -- ── Toggle Auto Escape ────────────────────────────────────────────
    function HE.toggleAutoEscape()
        state.autoEscapeEnabled = not state.autoEscapeEnabled
        Lib.setToggleState(state.autoEscapeButton, state.autoEscapeEnabled)

        -- Hentikan loop lama
        if state.autoEscapeConn then
            pcall(function() state.autoEscapeConn:Disconnect() end)
            state.autoEscapeConn = nil
        end

        if not state.autoEscapeEnabled then return end

        -- Interval antar percobaan escape (0.5 detik)
        local ESCAPE_INTERVAL = 0.5
        local lastTry         = 0

        state.autoEscapeConn = RunService.Heartbeat:Connect(function()
            if not state.autoEscapeEnabled then return end
            local t = tick()
            if t - lastTry < ESCAPE_INTERVAL then return end
            lastTry = t

            if isHooked() then
                attemptEscape()
            end
        end)
    end

    return HE
end
