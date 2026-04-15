local World = {
    GAME_W = 256,
    GAME_H = 231,
    visibleH = 231,   -- actual visible height in game units (adapts to screen)
    scale = 1,
    offsetX = 0,
    offsetY = 0,
    state = "title",
    wave = 1,
    score = 0,
    highScore = 0,
    gameOverTimer = 0,
    waveEndTimer = 0,
    GROUND_Y = 213,
    screenW = 0,
    screenH = 0,
    bonusCities = 0,
    nextBonusAt = 10000,
}

function World.resize(w, h)
    if not w or not h then
        w, h = love.graphics.getDimensions()
    end
    World.screenW = w
    World.screenH = h

    -- Scale to fill width, let height adapt
    World.scale = w / World.GAME_W
    World.visibleH = h / World.scale
    World.offsetX = 0
    -- Anchor the bottom of the game (ground) to the bottom of the screen
    -- Ground is at GROUND_Y, bottom of game area is GAME_H
    World.offsetY = h - (World.GAME_H * World.scale)
end

function World.ensureScale()
    local w, h = love.graphics.getDimensions()
    if w ~= World.screenW or h ~= World.screenH then
        World.resize(w, h)
        local Fonts = require("rendering.fonts")
        Fonts.init(World.scale)
    end
end

function World.toGame(sx, sy)
    local gx = (sx - World.offsetX) / World.scale
    local gy = (sy - World.offsetY) / World.scale
    gx = math.max(0, math.min(World.GAME_W, gx))
    gy = math.max(0, math.min(World.GAME_H, gy))
    return gx, gy
end

function World.toScreen(gx, gy)
    return gx * World.scale + World.offsetX, gy * World.scale + World.offsetY
end

-- Top of the visible area in game coordinates (can be negative on widescreen)
function World.visibleTop()
    return World.GAME_H - World.visibleH
end

function World.addScore(points)
    local Waves = require("data.waves")
    local config = Waves.get(World.wave)
    local earned = points * config.multiplier
    local oldScore = World.score
    World.score = World.score + earned

    -- Check for bonus city threshold crossing
    while World.score >= World.nextBonusAt do
        World.bonusCities = World.bonusCities + 1
        World.nextBonusAt = World.nextBonusAt + 10000
    end

    -- Track high score
    if World.score > World.highScore then
        World.highScore = World.score
    end
end

function World.addScoreRaw(points)
    -- Add points without multiplier (used by tally screen)
    local oldScore = World.score
    World.score = World.score + points

    while World.score >= World.nextBonusAt do
        World.bonusCities = World.bonusCities + 1
        World.nextBonusAt = World.nextBonusAt + 10000
    end

    if World.score > World.highScore then
        World.highScore = World.score
    end
end

return World
