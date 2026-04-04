-- ╔══════════════════════════════════════════════════════╗
-- ║        VIOLANCE DISTRICT — MODULAR LOADER v2.3        ║
-- ║    Support: Local (Offline) & GitHub (Online)         ║
-- ╚══════════════════════════════════════════════════════╝

-- KONFIGURASI GITHUB
local GITHUB_USER   = "mixudev"
local GITHUB_REPO   = "Tools---ViolanceDistrict"
local GITHUB_BRANCH = "main"

-- KONFIGURASI JALUR
local LOCAL_PATH  = "VD/src/"
local ONLINE_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/src/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

-- ── Mode detection ───────────────────────────────────────────────────
local isOnline = true
pcall(function()
    if isfile and isfile(LOCAL_PATH .. "core/services.lua") then
        isOnline = false
    end
end)

-- ── Module loader ────────────────────────────────────────────────────
-- Returns the result of executing the module, or errors loudly so
-- callers know immediately rather than getting a silent {}
local function loadModule(path)
    local content = nil
    local fullPath = path .. ".lua"

    -- 1. Try local file
    if not isOnline then
        local ok, res = pcall(readfile, LOCAL_PATH .. fullPath)
        if ok and res and res ~= "" then
            content = res
        else
            isOnline = true  -- fall through to online
        end
    end

    -- 2. Try GitHub
    if not content then
        local ok, res = pcall(game.HttpGet, game, ONLINE_BASE .. fullPath)
        if ok and res and res ~= "" then
            content = res
        end
    end

    if not content or content == "" then
        error(string.format("[VD] Gagal memuat modul '%s' (online=%s)", fullPath, tostring(isOnline)))
    end

    local fn, err = loadstring(content)
    if not fn then
        error(string.format("[VD] Syntax error di '%s': %s", fullPath, tostring(err)))
    end

    return fn()
end

print(string.format("[VD] Menginisialisasi via %s mode...", isOnline and "ONLINE" or "LOCAL"))

-- ╔══════════════════════════════════════════════════════╗
-- ║  1. CORE DATA                                         ║
-- ╚══════════════════════════════════════════════════════╝
local services  = loadModule("core/services")
local constants = loadModule("core/constants")
local state     = loadModule("core/state")

-- ╔══════════════════════════════════════════════════════╗
-- ║  2. UI LIBRARY                                        ║
-- ╚══════════════════════════════════════════════════════╝
local Lib = loadModule("ui/library")(services)

-- ╔══════════════════════════════════════════════════════╗
-- ║  3. UI COMPONENTS                                     ║
-- ╚══════════════════════════════════════════════════════╝
local MainUI       = loadModule("ui/main_menu")(services, constants, state, Lib)
local PlayerListUI = loadModule("ui/player_list")(services, constants, state, Lib, MainUI.ScreenGui)

-- ╔══════════════════════════════════════════════════════╗
-- ║  4. FEATURE LOGIC                                     ║
-- ╚══════════════════════════════════════════════════════╝
local PlayerESP       = loadModule("features/player_esp")(services, constants, state, Lib)
local GenESP          = loadModule("features/generator_esp")(services, constants, state, Lib)
local Movement        = loadModule("features/movement")(services, constants, state, Lib)
local PlayerListLogic = loadModule("features/player_list_logic")(services, constants, state, Lib, PlayerListUI)
local HookEscape      = loadModule("features/hook_escape")(services, constants, state, Lib)

-- ╔══════════════════════════════════════════════════════╗
-- ║  5. BUILD MENU CONTENT                                ║
-- ║  No yPos! UIListLayout auto-arranges everything.     ║
-- ╚══════════════════════════════════════════════════════╝
local SG = MainUI.ScreenGui

-- ── Visibility section ───────────────────────────────────────────────
Lib.createSectionLabel(MainUI.ContentFrame, "Visibility")

state.espButton = Lib.createToggle(MainUI.ContentFrame, "Player ESP", function()
    PlayerESP.togglePlayerESP()
    Lib.showToast(SG, state.espEnabled and "Player ESP  ON" or "Player ESP  OFF")
end)

state.genButton = Lib.createToggle(MainUI.ContentFrame, "Generator ESP", function()
    GenESP.toggleGenESP()
    Lib.showToast(SG, state.genESPEnabled and "Generator ESP  ON" or "Generator ESP  OFF")
end)

Lib.createDivider(MainUI.ContentFrame)

-- ── Player name section ──────────────────────────────────────────────
Lib.createSectionLabel(MainUI.ContentFrame, "Player Name")

state.nameButton = Lib.createToggle(MainUI.ContentFrame, "Show Name Title", function()
    PlayerESP.toggleNameTitle()
end)
Lib.setToggleState(state.nameButton, true)   -- default ON

Lib.createDivider(MainUI.ContentFrame)

-- ── Info section ─────────────────────────────────────────────────────
Lib.createSectionLabel(MainUI.ContentFrame, "Info")

state.playerListButton = Lib.createToggle(MainUI.ContentFrame, "Player Health List", function()
    PlayerListLogic.togglePlayerList()
    Lib.showToast(SG, state.playerListVisible and "Health List  ON" or "Health List  OFF")
end)

Lib.createDivider(MainUI.ContentFrame)

-- ── Movement section ─────────────────────────────────────────────────
Lib.createSectionLabel(MainUI.ContentFrame, "Movement")

state.shiftLockButton = Lib.createToggle(MainUI.ContentFrame, "Shift Lock (Auto-Run)", function()
    Movement.toggleShiftLock()
    Lib.showToast(SG, state.shiftLockEnabled and "Auto-Run  ON" or "Auto-Run  OFF")
end)

Lib.createDivider(MainUI.ContentFrame)

-- ── Survival section ──────────────────────────────────────────────────
Lib.createSectionLabel(MainUI.ContentFrame, "Survival")

-- Auto Escape: saat digantung di hook, ini akan auto-hold "E"
-- dan mencari indikator 100% di layar/sistem sebelum melepas (skill check timing).
state.autoEscapeButton = Lib.createButton(MainUI.ContentFrame, "Auto Escape (Hook - 100%)", function()
    HookEscape.performEscape()
end)
-- ╔══════════════════════════════════════════════════════╗
-- ║  6. WINDOW CONTROLS                                   ║
-- ╚══════════════════════════════════════════════════════╝

-- Close: clean up all ESP and destroy GUI
MainUI.CloseButton.MouseButton1Click:Connect(function()
    PlayerESP.clearAllPlayerESP()
    GenESP.clearGenESP()
    if state.playerListConn then
        pcall(function() state.playerListConn:Disconnect() end)
    end
    if state.shiftLockConn then
        pcall(function() state.shiftLockConn:Disconnect() end)
    end
    if state.autoEscapeConn then
        pcall(function() state.autoEscapeConn:Disconnect() end)
    end
    MainUI.ScreenGui:Destroy()
end)

-- Minimize / restore (compatible with AutomaticSize.Y)
local minimized = false
MainUI.MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- 1. Lock size first, then disable AutomaticSize
        MainUI.MainFrame.AutomaticSize = Enum.AutomaticSize.None
        Lib.tween(MainUI.MainFrame, 0.2, { Size = UDim2.new(0, 270, 0, 50) })
        MainUI.ContentFrame.Visible = false
        MainUI.MinimizeButton.Text  = "+"
    else
        -- 1. Show content, then re-enable AutomaticSize
        MainUI.ContentFrame.Visible = true
        MainUI.MainFrame.AutomaticSize = Enum.AutomaticSize.Y
        MainUI.MinimizeButton.Text  = "—"
    end
end)

-- Toggle menu visibility with hotkey
services.UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == constants.MENU_TOGGLE_KEY then
        MainUI.MainFrame.Visible = not MainUI.MainFrame.Visible
    end
end)

-- Player list hot-update on join/leave
services.Players.PlayerAdded:Connect(function()
    if state.playerListVisible then task.wait(0.5) PlayerListLogic.updatePlayerList() end
end)
services.Players.PlayerRemoving:Connect(function()
    if state.playerListVisible then task.wait(0.2) PlayerListLogic.updatePlayerList() end
end)

print(string.format("[VD] Modular ESP v2.3 loaded · %s mode", isOnline and "GitHub" or "Local"))