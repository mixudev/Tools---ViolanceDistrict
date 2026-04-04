return {
    -- ── Player ESP ─────────────────────────────────────────────────
    espEnabled            = false,
    espObjects            = {},      -- [player] = {instances}
    espCharConns          = {},      -- [player] = CharacterAdded connection
    espRenderConns        = {},      -- [player] = RenderStepped connection (per-player, fixes memory leak)
    espPlayerAddedConn    = nil,
    espPlayerRemovingConn = nil,
    espHeartbeatConn      = nil,
    espLastRefresh        = 0,

    -- ── Name Title ─────────────────────────────────────────────────
    nameTitleEnabled      = true,
    nameButton            = nil,

    -- ── Generator ESP ──────────────────────────────────────────────
    genESPEnabled         = false,
    genESPObjects         = {},
    genHeartbeatConn      = nil,
    genButton             = nil,
    genCachedObjects      = nil,     -- cached list of generator objects

    -- ── Player List ────────────────────────────────────────────────
    playerListVisible     = false,
    playerListFrames      = {},      -- [{frame, hbFill, hpLabel}]
    playerListHealthConns = {},      -- [player] = HealthChanged connection (fixes memory leak)
    playerListConn        = nil,
    playerListButton      = nil,

    -- ── Movement / Shift Lock ──────────────────────────────────────
    shiftLockEnabled      = false,
    shiftLockButton       = nil,
    shiftLockConn         = nil,     -- Heartbeat loop connection
    shiftLockOriginalSpeed = nil,    -- WalkSpeed backup (fallback method)

    espButton             = nil,
    genButton             = nil,
}
