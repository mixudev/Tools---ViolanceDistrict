return {
    espEnabled            = false,
    espObjects            = {}, -- [player] = {objects}
    espCharConns          = {}, -- [player] = connection
    espRenderConns        = {}, -- {connection, ...}
    espPlayerAddedConn    = nil,
    espPlayerRemovingConn = nil,
    espHeartbeatConn      = nil,
    espLastRefresh        = 0,

    nameTitleEnabled      = true,
    nameButton            = nil,
    
    genESPEnabled         = false,
    genESPObjects         = {},
    genHeartbeatConn      = nil,
    genButton             = nil,

    playerListVisible     = false,
    playerListFrames      = {},
    playerListConn        = nil,
    playerListButton      = nil,

    shiftLockEnabled      = false,
    shiftLockButton       = nil,
}
