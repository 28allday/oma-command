local World = require("game.world")
local Crosshair = require("game.crosshair")
local Cities = require("game.cities")
local Batteries = require("game.batteries")
local Explosions = require("game.explosions")
local ABM = require("game.abm")
local Missiles = require("game.missiles")
local Fliers = require("game.fliers")
local HUD = require("game.hud")
local HighScores = require("game.highscores")
local Palette = require("rendering.palette")
local Fonts = require("rendering.fonts")
local Waves = require("data.waves")
local Sounds = require("audio.sounds")

-- Wave transition / tally state
local tally = {
    phase = "none",     -- "missiles", "cities", "bonus", "done"
    timer = 0,
    tickTimer = 0,
    missilesLeft = 0,
    missilesCounted = 0,
    citiesLeft = 0,
    citiesCounted = 0,
    multiplier = 1,
    bonusCityEarned = false,
    bonusCityDeployed = 0,
    doneTimer = 0,
    scoreAtStart = 0,
    bonusCitiesBefore = 0,
}

local TICK_INTERVAL = 0.12
local DONE_PAUSE = 1.2

local function resetTally()
    tally.phase = "none"
    tally.timer = 0
    tally.tickTimer = 0
    tally.missilesLeft = 0
    tally.missilesCounted = 0
    tally.citiesLeft = 0
    tally.citiesCounted = 0
    tally.multiplier = 1
    tally.bonusCityEarned = false
    tally.bonusCityDeployed = 0
    tally.doneTimer = 0
    tally.scoreAtStart = 0
    tally.bonusCitiesBefore = 0
end

local function startGame()
    World.state = "playing"
    World.wave = 1
    World.score = 0
    World.gameOverTimer = 0
    World.bonusCities = 0
    World.nextBonusAt = 10000
    Cities.init()
    Batteries.init()
    Explosions.clear()
    ABM.clear()
    Fliers.init()
    Cities.resetWaveCount()
    Missiles.spawnWave(1)
    Sounds.play("wave_start")
end

local function startNextWave()
    World.wave = World.wave + 1
    Batteries.rearm()
    Explosions.clear()
    ABM.clear()
    Fliers.clear()
    Cities.resetWaveCount()
    Missiles.spawnWave(World.wave)
    Sounds.play("wave_start")
end

local function beginTally()
    resetTally()
    local config = Waves.get(World.wave)
    tally.multiplier = config.multiplier
    tally.scoreAtStart = World.score
    tally.bonusCitiesBefore = World.bonusCities

    local totalAmmo = 0
    for i = 1, 3 do
        local b = Batteries.get(i)
        if b then totalAmmo = totalAmmo + b.ammo end
    end
    tally.missilesLeft = totalAmmo
    tally.citiesLeft = Cities.aliveCount()

    tally.phase = "missiles"
    tally.timer = 0
    tally.tickTimer = 0
end

local function drawGrid()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale

    love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.8)
    love.graphics.setLineWidth(lw * 2)
    love.graphics.line(0, World.GROUND_Y, 256, World.GROUND_Y)

    love.graphics.setColor(p.grid[1], p.grid[2], p.grid[3], 0.3)
    love.graphics.setLineWidth(lw)

    local numLines = 5
    for i = 1, numLines do
        local y = World.GROUND_Y + i * 3.5
        local alpha = 0.3 * (1 - i / (numLines + 1))
        love.graphics.setColor(p.grid[1], p.grid[2], p.grid[3], alpha)
        love.graphics.line(0, y, 256, y)
    end

    local vanishX = 128
    local vanishY = World.GROUND_Y
    local bottomY = 231
    local numVerts = 12
    love.graphics.setColor(p.grid[1], p.grid[2], p.grid[3], 0.2)
    for i = 0, numVerts do
        local baseX = (i / numVerts) * 256
        love.graphics.line(vanishX, vanishY, baseX, bottomY)
    end
end

local function drawScanlines()
    local top = World.visibleTop()
    love.graphics.setColor(0, 0, 0, 0.06)
    local lw = 0.5 / World.scale
    love.graphics.setLineWidth(lw)
    for y = top, World.GAME_H, 1.5 do
        love.graphics.line(0, y, 256, y)
    end
end

local function drawGameWorld()
    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)

    local p = Palette.get(World.wave)

    local top = World.visibleTop()
    love.graphics.setColor(p.sky)
    love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)

    drawGrid()
    drawScanlines()

    Missiles.draw()
    Fliers.draw()
    ABM.draw()
    Explosions.draw()
    Cities.draw()
    Batteries.draw()
    Crosshair.draw()

    HUD.draw()

    love.graphics.pop()
end

local function drawTitleScreen()
    local p = Palette.get(1)
    local sw, sh = World.screenW, World.screenH
    local t = love.timer.getTime()

    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)

    local top = World.visibleTop()
    love.graphics.setColor(p.sky)
    love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)

    drawGrid()
    drawScanlines()

    local lw = 1 / World.scale
    local cx, cy = 128, World.GROUND_Y * 0.45
    love.graphics.setLineWidth(lw)
    for i = 1, 6 do
        local r = 8 + i * 12 + math.sin(t * 0.5 + i * 0.8) * 3
        local alpha = 0.15 - i * 0.02
        if alpha > 0 then
            love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], alpha)
            love.graphics.line(cx, cy-r, cx+r, cy, cx, cy+r, cx-r, cy, cx, cy-r)
        end
    end

    love.graphics.setLineWidth(lw)
    for i = 1, 5 do
        local mx = 30 + (i - 1) * 50 + math.sin(t * 0.3 + i) * 10
        local my1 = top + 5
        local my2 = top + 30 + math.sin(t * 0.7 + i * 2) * 15
        love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], 0.15)
        love.graphics.line(mx, my1, mx + (i % 2 == 0 and 5 or -5), my2)
    end

    love.graphics.pop()

    local centerY = sh * 0.28

    love.graphics.setFont(Fonts.large)
    love.graphics.setColor(p.bright)
    love.graphics.printf("OMA-COMMAND", 0, centerY, sw, "center")

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.6)
    love.graphics.printf("MISSILE DEFENCE", 0, centerY + Fonts.large:getHeight() + 4, sw, "center")

    -- High score from persistent table
    local highest = HighScores.getHighest()
    if highest > 0 then
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.5)
        love.graphics.printf("HIGH SCORE: " .. string.format("%06d", highest), 0, centerY + Fonts.large:getHeight() + 4 + Fonts.small:getHeight() + 12, sw, "center")
    end

    local pulse = 0.3 + math.sin(t * 3) * 0.3
    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse + 0.2)
    love.graphics.printf("PRESS ENTER TO START", 0, sh * 0.62, sw, "center")

    love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.2)
    love.graphics.setLineWidth(1)
    local bx = sw * 0.15
    local by1 = sh * 0.22
    local by2 = sh * 0.72
    love.graphics.line(bx, by1, sw - bx, by1)
    love.graphics.line(bx, by2, sw - bx, by2)
    local tickLen = sw * 0.03
    love.graphics.line(bx, by1, bx, by1 + tickLen)
    love.graphics.line(sw - bx, by1, sw - bx, by1 + tickLen)
    love.graphics.line(bx, by2, bx, by2 - tickLen)
    love.graphics.line(sw - bx, by2, sw - bx, by2 - tickLen)

    -- Show high score table if scores exist
    local allScores = HighScores.getScores()
    if #allScores > 0 then
        HighScores.drawTable(sw, sh, p, Fonts)
    end
end

local function drawTallyScreen()
    local p = Palette.get(World.wave)
    local sw, sh = World.screenW, World.screenH
    local t = love.timer.getTime()

    local baseY = sh * 0.2
    local lineH = Fonts.medium and Fonts.medium:getHeight() + 6 or 24
    local smallH = Fonts.small and Fonts.small:getHeight() + 4 or 16

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(p.bright)
    love.graphics.printf("BONUS POINTS", 0, baseY, sw, "center")

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.7)
    love.graphics.printf(tally.multiplier .. "x", 0, baseY + lineH, sw, "center")

    local infoY = baseY + lineH * 2 + 8

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(p.fg)
    local missileTotal = tally.missilesCounted * 5 * tally.multiplier
    love.graphics.printf(
        "MISSILES: " .. tally.missilesCounted .. " x 5 = " .. missileTotal,
        0, infoY, sw, "center"
    )

    if tally.phase == "cities" or tally.phase == "bonus" or tally.phase == "done" then
        local cityTotal = tally.citiesCounted * 100 * tally.multiplier
        love.graphics.printf(
            "CITIES: " .. tally.citiesCounted .. " x 100 = " .. cityTotal,
            0, infoY + lineH, sw, "center"
        )
    end

    if tally.phase == "bonus" or tally.phase == "done" then
        if tally.bonusCityEarned then
            local pulse = 0.5 + math.sin(t * 6) * 0.5
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse)
            love.graphics.setFont(Fonts.small)
            love.graphics.printf("+ BONUS CITY", 0, infoY + lineH * 2 + 4, sw, "center")
        end
        if tally.bonusCityDeployed > 0 then
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.8)
            love.graphics.setFont(Fonts.small)
            local deployText = tally.bonusCityDeployed == 1
                and "1 CITY REBUILT"
                or (tally.bonusCityDeployed .. " CITIES REBUILT")
            love.graphics.printf(deployText, 0, infoY + lineH * 2 + 4 + smallH, sw, "center")
        end
    end

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(p.bright)
    love.graphics.printf(string.format("SCORE: %06d", World.score), 0, sh * 0.72, sw, "center")
end

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setLineStyle("smooth")
    Palette.loadFromSystem()
    World.resize(love.graphics.getDimensions())
    Fonts.init(World.scale)
    HighScores.init()
    Sounds.init()
    World.highScore = HighScores.getHighest()
    World.state = "title"
end

function love.resize(w, h)
    World.resize(w, h)
    Fonts.init(World.scale)
end

function love.update(dt)
    World.ensureScale()

    if World.state == "title" then
        return
    end

    if World.state == "playing" then
        Crosshair.update()
        Crosshair.updateTargets(dt)
        ABM.update(dt)
        Missiles.update(dt)
        Fliers.update(dt)
        Explosions.update(dt)

        if Missiles.allDone() and Fliers.allDone() and ABM.count() == 0 and not Explosions.anyActive() then
            if Cities.allDestroyed() and World.bonusCities == 0 then
                World.state = "game_over"
                World.gameOverTimer = 0
                Sounds.play("game_over")
                if World.score > World.highScore then
                    World.highScore = World.score
                end
                Explosions.clear()
                ABM.clear()
                Missiles.clear()
                Fliers.clear()
                return
            end
            World.state = "wave_end"
            beginTally()
        end

    elseif World.state == "wave_end" then
        tally.timer = tally.timer + dt

        if tally.phase == "missiles" then
            tally.tickTimer = tally.tickTimer + dt
            if tally.tickTimer >= TICK_INTERVAL then
                tally.tickTimer = tally.tickTimer - TICK_INTERVAL
                if tally.missilesCounted < tally.missilesLeft then
                    tally.missilesCounted = tally.missilesCounted + 1
                    World.addScoreRaw(5 * tally.multiplier)
                    Sounds.play("bonus_tick")
                else
                    tally.phase = "cities"
                    tally.tickTimer = 0
                end
            end

        elseif tally.phase == "cities" then
            tally.tickTimer = tally.tickTimer + dt
            if tally.tickTimer >= TICK_INTERVAL * 2 then
                tally.tickTimer = tally.tickTimer - TICK_INTERVAL * 2
                if tally.citiesCounted < tally.citiesLeft then
                    tally.citiesCounted = tally.citiesCounted + 1
                    World.addScoreRaw(100 * tally.multiplier)
                    Sounds.play("bonus_tick")
                else
                    tally.bonusCityEarned = (World.bonusCities > tally.bonusCitiesBefore)
                    tally.phase = "bonus"
                    tally.tickTimer = 0

                    if Cities.destroyedCount() > 0 and World.bonusCities > 0 then
                        tally.bonusCityDeployed = Cities.deployBonusCities()
                    end
                end
            end

        elseif tally.phase == "bonus" then
            tally.tickTimer = tally.tickTimer + dt
            if tally.tickTimer >= 1.0 then
                tally.phase = "done"
                tally.doneTimer = 0
            end

        elseif tally.phase == "done" then
            tally.doneTimer = tally.doneTimer + dt
            if tally.doneTimer >= DONE_PAUSE then
                World.state = "playing"
                startNextWave()
            end
        end

    elseif World.state == "game_over" then
        World.gameOverTimer = World.gameOverTimer + dt
        Explosions.update(dt)

    elseif World.state == "high_score_entry" then
        HighScores.updateEntry(dt)
    end
end

function love.draw()
    love.graphics.clear(0, 0, 0)

    local p = Palette.get(World.wave)
    local sw, sh = World.screenW, World.screenH

    if World.state == "title" then
        drawTitleScreen()
        return
    end

    if World.state == "high_score_entry" then
        -- Background
        love.graphics.push()
        love.graphics.translate(World.offsetX, World.offsetY)
        love.graphics.scale(World.scale)
        local top = World.visibleTop()
        love.graphics.setColor(p.sky)
        love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)
        drawGrid()
        drawScanlines()
        love.graphics.pop()

        HighScores.drawEntry(sw, sh, p, Fonts)
        return
    end

    drawGameWorld()

    local midY = sh * 0.4

    if World.state == "wave_end" then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        drawTallyScreen()
    end

    if World.state == "game_over" then
        local t = love.timer.getTime()

        love.graphics.push()
        love.graphics.translate(World.offsetX, World.offsetY)
        love.graphics.scale(World.scale)
        local lw = 1 / World.scale
        local cx, cy = 128, World.visibleTop() + World.visibleH * 0.4
        local numRings = math.min(math.floor(World.gameOverTimer * 4) + 1, 8)
        for i = 1, numRings do
            local r = (World.gameOverTimer * 25 - i * 5)
            if r > 0 and r < 100 then
                local alpha = math.max(0, 1 - r / 100)
                local pulse = 0.5 + math.sin(t * 10 + i) * 0.3
                love.graphics.setColor(p.exp1[1], p.exp1[2], p.exp1[3], alpha * pulse)
                love.graphics.setLineWidth(lw * 2)
                love.graphics.circle("line", cx, cy, r, 24 + i * 4)
            end
        end
        love.graphics.pop()

        if World.gameOverTimer > 0.5 then
            love.graphics.setFont(Fonts.large)
            local textPulse = 0.7 + math.sin(t * 3) * 0.3
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], textPulse)
            love.graphics.printf("THE END", 0, midY, sw, "center")
        end

        if World.gameOverTimer > 1.5 then
            love.graphics.setFont(Fonts.medium)
            love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.7)
            love.graphics.printf("SCORE: " .. string.format("%06d", World.score), 0, midY + Fonts.large:getHeight() + 8, sw, "center")
        end

        if World.gameOverTimer > 2.5 then
            local pulse = 0.3 + math.sin(t * 3) * 0.3
            love.graphics.setFont(Fonts.small)
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse + 0.2)
            love.graphics.printf("PRESS ENTER", 0, midY + Fonts.large:getHeight() + Fonts.medium:getHeight() + 24, sw, "center")
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and World.state == "playing" then
        local gx, gy = World.toGame(x, y)
        local bat = Batteries.findNearest(gx, gy)
        if bat and ABM.count() < 8 then
            if Batteries.fire(bat.index) then
                ABM.fire(bat.x, bat.y, gx, gy, bat.speed)
                Sounds.play("launch")
            end
        end
    end
end

function love.keypressed(key)
    if World.state == "title" then
        if key == "return" then
            startGame()
        end
        if key == "escape" then
            love.event.quit()
        end
        return
    end

    if World.state == "high_score_entry" then
        local result, data = HighScores.keypressedEntry(key)
        if result == "done" then
            World.highScore = HighScores.getHighest()
            World.state = "title"
        end
        return
    end

    if World.state == "playing" then
        local batIndex = nil
        if key == "a" or key == "1" then batIndex = 1
        elseif key == "s" or key == "2" then batIndex = 2
        elseif key == "d" or key == "3" then batIndex = 3
        end

        if batIndex and ABM.count() < 8 then
            local bat = Batteries.get(batIndex)
            if bat and bat.alive and bat.ammo > 0 then
                if Batteries.fire(batIndex) then
                    ABM.fire(bat.x, bat.y, Crosshair.x, Crosshair.y, bat.speed)
                    Sounds.play("launch")
                end
            end
        end
    end

    if World.state == "game_over" then
        if key == "return" and World.gameOverTimer > 2.0 then
            if HighScores.isHighScore(World.score) then
                World.state = "high_score_entry"
                HighScores.startEntry(World.score)
            else
                World.state = "title"
            end
            return
        end
        if key == "escape" then
            World.state = "title"
            return
        end
    end

    if key == "escape" then
        love.event.quit()
    end
end
