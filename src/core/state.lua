return {
    -- ── Player ESP ─────────────────────────────────────────────────
    espEnabled            = false,
    espObjects            = {},
    espCharConns          = {},
    espRenderConns        = {},      -- [player] = RenderStepped connection
    espPlayerAddedConn    = nil,
    espPlayerRemovingConn = nil,
    espHeartbeatConn      = nil,
    espLastRefresh        = 0,
    espButton             = nil,

    -- ── Name Title ─────────────────────────────────────────────────
    nameTitleEnabled      = true,
    nameButton            = nil,

    -- ── Generator ESP ──────────────────────────────────────────────
    genESPEnabled         = false,
    genESPObjects         = {},
    genHeartbeatConn      = nil,
    genButton             = nil,
    genCachedObjects      = nil,

    -- ── Player List ────────────────────────────────────────────────
    playerListVisible     = false,
    playerListFrames      = {},
    playerListHealthConns = {},
    playerListConn        = nil,
    playerListButton      = nil,

    -- ── Movement / Shift Lock ──────────────────────────────────────
    shiftLockEnabled       = false,
    shiftLockButton        = nil,
    shiftLockConn          = nil,
    shiftLockOriginalSpeed = nil,

    -- ── Drone Camera ───────────────────────────────────────────────
    droneEnabled          = false,
    droneButton           = nil,
    droneConn             = nil,
}
