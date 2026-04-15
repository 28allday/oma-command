local World = require("game.world")
local Palette = require("rendering.palette")
local Explosions = require("game.explosions")
local Cities = require("game.cities")
local Batteries = require("game.batteries")
local Missiles = require("game.missiles")

local Fliers = {}

local active = {}
local cooldownTimer = 0
local COOLDOWN_MIN = 5
local COOLDOWN_MAX = 8

-- Flier types
local BOMBER = "bomber"
local SATELLITE = "satellite"
local KILLER_SAT = "killer_sat"

local function canSpawnBomber(wave) return wave >= 2 end
local function canSpawnSatellite(wave) return wave >= 4 end
local function canSpawnKillerSat(wave) return wave >= 8 end

local function pickCooldown()
    return COOLDOWN_MIN + math.random() * (COOLDOWN_MAX - COOLDOWN_MIN)
end

local function spawnFlier(wave)
    local canBomber = canSpawnBomber(wave)
    local canSat = canSpawnSatellite(wave)
    local canKiller = canSpawnKillerSat(wave)
    if not canBomber and not canSat then return end

    -- Pick type — weighted roll
    local ftype
    local r = math.random()
    if canKiller and r < 0.2 then
        ftype = KILLER_SAT
    elseif canSat and canBomber then
        ftype = r < 0.6 and BOMBER or SATELLITE
    elseif canSat then
        ftype = SATELLITE
    else
        ftype = BOMBER
    end

    local fromLeft = math.random() < 0.5
    local speed, y
    if ftype == BOMBER then
        speed = 20
        y = World.GROUND_Y * 0.6
    elseif ftype == KILLER_SAT then
        speed = 45
        y = World.GROUND_Y * 0.25
    else
        speed = 30
        y = World.GROUND_Y * 0.3
    end

    local startX = fromLeft and -8 or (World.GAME_W + 8)
    local endX = fromLeft and (World.GAME_W + 8) or -8
    local dirX = fromLeft and 1 or -1

    table.insert(active, {
        ftype = ftype,
        x = startX,
        y = y,
        speed = speed,
        dirX = dirX,
        endX = endX,
        alive = true,
        birth = love.timer.getTime(),
        launchTimer = 1.5 + math.random() * 1.0,
        hasLaunched = false,
    })
end

function Fliers.init()
    active = {}
    cooldownTimer = pickCooldown()
end

function Fliers.update(dt)
    local wave = World.wave

    -- Cooldown for spawning
    if #active == 0 then
        if canSpawnBomber(wave) or canSpawnSatellite(wave) then
            cooldownTimer = cooldownTimer - dt
            if cooldownTimer <= 0 then
                spawnFlier(wave)
                cooldownTimer = pickCooldown()
            end
        end
    end

    for i = #active, 1, -1 do
        local f = active[i]
        if f.alive then
            f.x = f.x + f.dirX * f.speed * dt

            -- Check explosion collision (use a small radius around the flier)
            if Explosions.checkCollision(f.x, f.y) then
                f.alive = false
                World.addScore(f.ftype == KILLER_SAT and 150 or 100)
                Explosions.add(f.x, f.y)
                table.remove(active, i)
                cooldownTimer = pickCooldown()
            else
                -- Check if off screen
                if (f.dirX > 0 and f.x > World.GAME_W + 10) or
                   (f.dirX < 0 and f.x < -10) then
                    table.remove(active, i)
                    cooldownTimer = pickCooldown()
                else
                    -- Periodically launch missiles while on screen
                    f.launchTimer = f.launchTimer - dt
                    if f.launchTimer <= 0 then
                        if f.ftype == KILLER_SAT then
                            f.launchTimer = 1.2 + math.random() * 0.6
                        else
                            f.launchTimer = 2.0 + math.random() * 1.0
                        end
                        if f.x > 0 and f.x < World.GAME_W then
                            Missiles.spawnFromFlier(f.x, f.y, wave)
                        end
                    end
                end
            end
        end
    end
end

function Fliers.allDone()
    return #active == 0
end

function Fliers.clear()
    active = {}
    cooldownTimer = pickCooldown()
end

function Fliers.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale
    local t = love.timer.getTime()

    for _, f in ipairs(active) do
        if f.alive then
            local pulse = 0.7 + math.sin(t * 12 + f.birth) * 0.3
            local x, y = f.x, f.y
            local d = f.dirX  -- direction multiplier

            if f.ftype == BOMBER then
                -- B-52 style strategic bomber
                -- Fuselage
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse)
                love.graphics.setLineWidth(lw * 1.5)
                love.graphics.line(
                    x + 7*d, y,           -- nose tip
                    x + 5*d, y - 0.8,     -- upper nose
                    x + 2*d, y - 1,       -- cockpit
                    x - 3*d, y - 1,       -- fuselage top
                    x - 6*d, y - 0.5,     -- tail section top
                    x - 8*d, y - 3,       -- vertical stabiliser top
                    x - 8*d, y - 0.5,     -- tail join
                    x - 6*d, y + 0.5,     -- fuselage bottom
                    x + 2*d, y + 1,       -- belly
                    x + 5*d, y + 0.5,     -- lower nose
                    x + 7*d, y            -- back to nose
                )

                -- Swept wings
                love.graphics.setLineWidth(lw * 1.2)
                -- Upper wing
                love.graphics.line(
                    x + 2*d, y - 1,
                    x - 1*d, y - 5,
                    x - 3*d, y - 4.5,
                    x - 3*d, y - 1
                )
                -- Lower wing
                love.graphics.line(
                    x + 2*d, y + 1,
                    x - 1*d, y + 5,
                    x - 3*d, y + 4.5,
                    x - 3*d, y + 1
                )

                -- Engine pods under wings
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse * 0.5)
                love.graphics.setLineWidth(lw)
                love.graphics.line(x, y - 2.5, x - 1*d, y - 3, x - 1.5*d, y - 2.5)
                love.graphics.line(x, y + 2.5, x - 1*d, y + 3, x - 1.5*d, y + 2.5)

                -- Tail horizontal stabiliser
                love.graphics.line(
                    x - 6*d, y - 0.5,
                    x - 7*d, y - 2,
                    x - 8*d, y - 1.5
                )
                love.graphics.line(
                    x - 6*d, y + 0.5,
                    x - 7*d, y + 1.5,
                    x - 8*d, y + 1
                )

                -- Cockpit window detail
                love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse * 0.4)
                love.graphics.line(x + 4*d, y - 0.5, x + 3*d, y - 0.8, x + 2*d, y - 0.8)

            else
                -- Satellite — detailed orbital platform
                local rot = t * 0.8 + f.birth  -- slow rotation for visual interest

                -- Central body (hexagonal)
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse)
                love.graphics.setLineWidth(lw * 1.5)
                local s = 2
                love.graphics.line(
                    x-s, y-s*0.5,
                    x, y-s,
                    x+s, y-s*0.5,
                    x+s, y+s*0.5,
                    x, y+s,
                    x-s, y+s*0.5,
                    x-s, y-s*0.5
                )

                -- Solar panel arrays — two large rectangular panels
                love.graphics.setLineWidth(lw * 1.2)
                -- Left panel
                local px = 3.5
                love.graphics.line(x-s, y, x-s-1.5, y)
                love.graphics.line(
                    x-s-1.5, y-2.5,
                    x-s-px-1.5, y-2.5,
                    x-s-px-1.5, y+2.5,
                    x-s-1.5, y+2.5,
                    x-s-1.5, y-2.5
                )
                -- Panel grid lines
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse * 0.3)
                love.graphics.setLineWidth(lw * 0.7)
                love.graphics.line(x-s-3, y-2.5, x-s-3, y+2.5)
                love.graphics.line(x-s-1.5, y, x-s-px-1.5, y)

                -- Right panel
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse)
                love.graphics.setLineWidth(lw * 1.2)
                love.graphics.line(x+s, y, x+s+1.5, y)
                love.graphics.line(
                    x+s+1.5, y-2.5,
                    x+s+px+1.5, y-2.5,
                    x+s+px+1.5, y+2.5,
                    x+s+1.5, y+2.5,
                    x+s+1.5, y-2.5
                )
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse * 0.3)
                love.graphics.setLineWidth(lw * 0.7)
                love.graphics.line(x+s+3, y-2.5, x+s+3, y+2.5)
                love.graphics.line(x+s+1.5, y, x+s+px+1.5, y)

                -- Antenna dish on top
                love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], pulse * 0.6)
                love.graphics.setLineWidth(lw)
                love.graphics.line(x, y-s, x+0.5, y-s-2)
                love.graphics.line(x-1, y-s-2.5, x+1, y-s-1.5)

                -- Blinking status light
                if math.sin(t * 8 + f.birth) > 0.5 then
                    love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.8)
                    love.graphics.circle("fill", x, y, 0.5, 4)
                end

                -- Killer satellite: add menacing spikes and pulsing red core
                if f.ftype == KILLER_SAT then
                    local killerPulse = 0.6 + math.sin(t * 14 + f.birth) * 0.4
                    love.graphics.setColor(1.0, 0.2, 0.2, killerPulse)
                    love.graphics.setLineWidth(lw * 1.3)
                    -- Spikes around hexagon
                    love.graphics.line(x, y-s, x, y-s-2)
                    love.graphics.line(x, y+s, x, y+s+2)
                    love.graphics.line(x-s, y-s*0.5, x-s-1.5, y-s-1)
                    love.graphics.line(x+s, y-s*0.5, x+s+1.5, y-s-1)
                    love.graphics.line(x-s, y+s*0.5, x-s-1.5, y+s+1)
                    love.graphics.line(x+s, y+s*0.5, x+s+1.5, y+s+1)
                    -- Angry red core
                    love.graphics.circle("fill", x, y, 0.9, 8)
                end
            end
        end
    end
end

return Fliers
