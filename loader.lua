-- ╔══════════════════════════════════════════════════════╗
-- ║        VIOLANCE DISTRICT — MODULAR LOADER v2.2        ║
-- ║    Support: Local (Offline) & GitHub (Online)         ║
-- ╚══════════════════════════════════════════════════════╝

-- KONFIGURASI GITHUB
local GITHUB_USER   = "mixudev"
local GITHUB_REPO   = "Tools---ViolanceDistrict"
local GITHUB_BRANCH = "main"

-- KONFIGURASI JALUR
local LOCAL_PATH    = "VD/src/"
local ONLINE_BASE   = string.format("https://raw.githubusercontent.com/%s/%s/%s/src/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)

-- Deteksi apakah harus menggunakan mode online secara otomatis
local isOnline = true
pcall(function()
    -- Jika executor mendukung isfile dan file lokal ada, gunakan mode lokal demi kecepatan
    if isfile and isfile(LOCAL_PATH .. "core/services.lua") then
        isOnline = false
    end
end)

-- Loader Function: Mendukung transisi mulus antara file lokal dan cloud
local function loadModule(path)
    local content = nil
    local fullPath = path .. ".lua"
    
    -- 1. Coba baca secara lokal jika bukan mode online
    if not isOnline then
        local success, res = pcall(readfile, LOCAL_PATH .. fullPath)
        if success then 
            content = res 
        else
            -- Jika gagal baca lokal, paksa coba via online
            isOnline = true
        end
    end
    
    -- 2. Ambil dari cloud jika mode online atau pembacaan lokal gagal
    if not content or isOnline then
        local success, res = pcall(game.HttpGet, game, ONLINE_BASE .. fullPath)
        if success then 
            content = res 
        end
    end

    if not content or content == "" then 
        warn("[VD] Gagal memuat modul: " .. fullPath)
        return function() return {} end
    end

    local fn, err = loadstring(content)
    if not fn then 
        warn("[VD] Syntax error di " .. fullPath .. ": " .. err)
        return function() return {} end
    end
    
    return fn()
end

print(string.format("[VD] Menginisialisasi sistem via %s mode...", isOnline and "ONLINE" or "LOCAL"))

-- 1. LOAD CORE DATA
local services  = loadModule("core/services")
local constants = loadModule("core/constants")
local state     = loadModule("core/state")

-- 2. LOAD UI LIBRARY
local Lib = loadModule("ui/library")(services)

-- 3. LOAD UI COMPONENTS
local MainUI       = loadModule("ui/main_menu")(services, constants, state, Lib)
local PlayerListUI = loadModule("ui/player_list")(services, constants, state, Lib, MainUI.ScreenGui)

-- 4. LOAD FEATURE LOGIC
local PlayerESP       = loadModule("features/player_esp")(services, constants, state, Lib)
local GenESP          = loadModule("features/generator_esp")(services, constants, state, Lib)
local Movement        = loadModule("features/movement")(services, constants, state, Lib)
local PlayerListLogic = loadModule("features/player_list_logic")(services, constants, state, Lib, PlayerListUI)

-- 5. ASSEMBLE MENU CONTENT
Lib.createSectionLabel(MainUI.ContentFrame, "Visibility", 2)
state.espButton = Lib.createToggle(MainUI.ContentFrame, "Player ESP", 20, PlayerESP.togglePlayerESP)
state.genButton = Lib.createToggle(MainUI.ContentFrame, "Generator ESP", 70, GenESP.toggleGenESP)

Lib.createDivider(MainUI.ContentFrame, 124)
Lib.createSectionLabel(MainUI.ContentFrame, "Player Name", 132)
state.nameButton = Lib.createToggle(MainUI.ContentFrame, "Hide Name Title", 150, PlayerESP.toggleNameTitle)
Lib.setToggleState(state.nameButton, true)

Lib.createSectionLabel(MainUI.ContentFrame, "Info", 204)
state.playerListButton = Lib.createToggle(MainUI.ContentFrame, "Player Health List", 220, PlayerListLogic.togglePlayerList)

Lib.createDivider(MainUI.ContentFrame, 270)
Lib.createSectionLabel(MainUI.ContentFrame, "Movement", 278)
state.shiftLockButton = Lib.createToggle(MainUI.ContentFrame, "Shift Lock", 294, Movement.toggleShiftLock)

-- 6. WINDOW CONTROLS
MainUI.CloseButton.MouseButton1Click:Connect(function()
    PlayerESP.clearAllPlayerESP()
    GenESP.clearGenESP()
    if state.playerListConn then pcall(state.playerListConn.Disconnect, state.playerListConn) end
    MainUI.ScreenGui:Destroy()
end)

local minimized = false
MainUI.MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Lib.tween(MainUI.MainFrame, 0.25, { Size = UDim2.new(0, 320, 0, 44) })
        MainUI.ContentFrame.Visible = false
        MainUI.MinimizeButton.Text  = "+"
    else
        Lib.tween(MainUI.MainFrame, 0.25, { Size = UDim2.new(0, 320, 0, constants.FRAME_ORIGINAL_H) })
        MainUI.ContentFrame.Visible = true
        MainUI.MinimizeButton.Text  = "—"
    end
end)

services.UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == constants.MENU_TOGGLE_KEY then
        MainUI.MainFrame.Visible = not MainUI.MainFrame.Visible
    end
end)

services.Players.PlayerAdded:Connect(function()
    if state.playerListVisible then task.wait(0.5) PlayerListLogic.updatePlayerList() end
end)
services.Players.PlayerRemoving:Connect(function()
    if state.playerListVisible then task.wait(0.2) PlayerListLogic.updatePlayerList() end
end)

print("[VD] Modular ESP v2.2 Berhasil Dimuat dari " .. (isOnline and "GitHub" or "Local Workspace"))