local World = require("game.world")
local Palette = require("rendering.palette")
local Explosions = require("game.explosions")
local Cities = require("game.cities")
local Batteries = require("game.batteries")
local Waves = require("data.waves")
local Sounds = require("audio.sounds")

local Missiles = {}

local active = {}
local queue = {}
local spawnTimer = 0

-- Gather all alive targets (cities + batteries)
local function gatherTargets()
    local targets = {}
    local cityTargets = Cities.getTargets()
    local batTargets = Batteries.getTargets()
    for _, t in ipairs(cityTargets) do table.insert(targets, t) end
    for _, t in ipairs(batTargets) do table.insert(targets, t) end
    return targets
end

-- Determine MIRV chance based on wave
local function mirvChance(wave)
    if wave <= 2 then return 0
    elseif wave <= 4 then return 0.2
    else return math.min(0.3 + (wave - 5) * 0.02, 0.4)
    end
end

-- Determine smart bomb chance based on wave
local function smartBombChance(wave)
    if wave <= 4 then return 0
    elseif wave <= 6 then return 0.15
    else return math.min(0.25, 0.25)
    end
end

-- Create a missile record from a definition and insert into active
local function activateMissile(def)
    local dx = def.targetX - def.startX
    local dy = def.targetY - def.startY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then return end

    table.insert(active, {
        startX = def.startX,
        startY = def.startY,
        targetX = def.targetX,
        targetY = def.targetY,
        targetType = def.targetType,
        targetIndex = def.targetIndex,
        x = def.startX,
        y = def.startY,
        speed = def.speed,
        dirX = dx / dist,
        dirY = dy / dist,
        totalDist = dist,
        alive = true,
        birth = love.timer.getTime(),
        isMIRV = def.isMIRV or false,
        mirvSplit = false,
        mirvSplitFrac = def.mirvSplitFrac or 0,
        isSmartBomb = def.isSmartBomb or false,
    })
end

function Missiles.spawnWave(wave)
    active = {}
    queue = {}
    -- Prime timer so the first missile launches almost immediately
    spawnTimer = (Waves.get(wave).spawn_interval or 2) - 0.3

    local config = Waves.get(wave)
    local targets = gatherTargets()

    if #targets == 0 then return end

    local mChance = mirvChance(wave)
    local sChance = smartBombChance(wave)

    for i = 1, config.missile_count do
        local target = targets[math.random(#targets)]
        local startX = math.random(10, 246)
        local startY = math.random(0, 5)

        local isMIRV = false
        local isSmartBomb = false

        -- Determine type: MIRV and smart bomb are mutually exclusive
        if math.random() < mChance then
            isMIRV = true
        elseif math.random() < sChance then
            isSmartBomb = true
        end

        table.insert(queue, {
            startX = startX,
            startY = startY,
            targetX = target.x,
            targetY = target.y,
            targetType = target.type,
            targetIndex = target.index,
            speed = config.missile_speed,
            isMIRV = isMIRV,
            isSmartBomb = isSmartBomb,
            mirvSplitFrac = isMIRV and (0.4 + math.random() * 0.2) or 0,
        })
    end
end

local function spawnOne()
    if #queue == 0 then return end
    local def = table.remove(queue, 1)
    activateMissile(def)
end

-- Spawn a missile from a flier position toward a random target
function Missiles.spawnFromFlier(startX, startY, wave)
    local targets = gatherTargets()
    if #targets == 0 then return end

    local target = targets[math.random(#targets)]
    local config = Waves.get(wave)

    activateMissile({
        startX = startX,
        startY = startY,
        targetX = target.x,
        targetY = target.y,
        targetType = target.type,
        targetIndex = target.index,
        speed = config.missile_speed,
    })
end

function Missiles.update(dt)
    local config = Waves.get(World.wave)

    spawnTimer = spawnTimer + dt
    if #queue > 0 and spawnTimer >= config.spawn_interval then
        spawnTimer = 0
        spawnOne()
    end

    -- Collect new MIRV children to add after iteration
    local newMissiles = {}

    for i = #active, 1, -1 do
        local m = active[i]
        if m.alive then
            -- Smart bomb steering
            if m.isSmartBomb then
                local exps = Explosions.getActive()
                local steerX, steerY = 0, 0
                for _, e in ipairs(exps) do
                    local edx = m.x - e.x
                    local edy = m.y - e.y
                    local eDist = math.sqrt(edx * edx + edy * edy)
                    if eDist < 20 and eDist > 0.1 then
                        local strength = (20 - eDist) / 20
                        steerX = steerX + (edx / eDist) * strength * 40
                        steerY = steerY + (edy / eDist) * strength * 40
                    end
                end
                -- Blend steering with original direction
                local newDirX = m.dirX * m.speed + steerX
                local newDirY = m.dirY * m.speed + steerY
                local newLen = math.sqrt(newDirX * newDirX + newDirY * newDirY)
                if newLen > 0.1 then
                    m.dirX = newDirX / newLen
                    m.dirY = newDirY / newLen
                end
            end

            local step = m.speed * dt
            m.x = m.x + m.dirX * step
            m.y = m.y + m.dirY * step

            -- MIRV split check
            if m.isMIRV and not m.mirvSplit then
                local dx = m.x - m.startX
                local dy = m.y - m.startY
                local traveled = math.sqrt(dx * dx + dy * dy)
                if traveled >= m.totalDist * m.mirvSplitFrac then
                    m.mirvSplit = true
                    Sounds.play("mirv_split")
                    -- Spawn 2-3 new warheads from current position
                    local targets = gatherTargets()
                    if #targets > 0 then
                        local numChildren = math.random(2, 3)
                        for c = 1, numChildren do
                            local target = targets[math.random(#targets)]
                            table.insert(newMissiles, {
                                startX = m.x,
                                startY = m.y,
                                targetX = target.x,
                                targetY = target.y,
                                targetType = target.type,
                                targetIndex = target.index,
                                speed = m.speed,
                            })
                        end
                    end
                end
            end

            if Explosions.checkCollision(m.x, m.y) then
                m.alive = false
                World.addScore(m.isSmartBomb and 125 or 25)
                Explosions.add(m.x, m.y)
                table.remove(active, i)
            else
                local dx = m.x - m.startX
                local dy = m.y - m.startY
                local traveled = math.sqrt(dx * dx + dy * dy)

                if traveled >= m.totalDist or m.y >= m.targetY then
                    Explosions.add(m.targetX, m.targetY)
                    if m.targetType == "city" then
                        if Cities.destroy(m.targetIndex) then
                            Sounds.play("city_destroyed")
                        else
                            Sounds.play("impact")
                        end
                    elseif m.targetType == "battery" then
                        Batteries.destroy(m.targetIndex)
                        Sounds.play("impact")
                    end
                    table.remove(active, i)
                end
            end
        end
    end

    -- Activate MIRV children
    for _, def in ipairs(newMissiles) do
        activateMissile(def)
    end
end

function Missiles.allDone()
    return #active == 0 and #queue == 0
end

function Missiles.clear()
    active = {}
    queue = {}
end

function Missiles.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale
    local t = love.timer.getTime()

    for _, m in ipairs(active) do
        local age = t - m.birth

        -- Faint trail glow
        love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], 0.2)
        love.graphics.setLineWidth(lw * 4)
        love.graphics.line(m.startX, m.startY, m.x, m.y)

        -- Main vector trail
        love.graphics.setColor(p.missile[1], p.missile[2], p.missile[3], 0.8)
        love.graphics.setLineWidth(lw * 1.5)
        love.graphics.line(m.startX, m.startY, m.x, m.y)

        -- Warhead shape depends on type
        local pulse = 0.6 + math.sin(age * 20) * 0.4
        love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse)
        love.graphics.setLineWidth(lw * 1.5)

        if m.isSmartBomb then
            -- Small wireframe triangle for smart bombs
            local s = 2
            love.graphics.line(
                m.x, m.y - s,
                m.x + s * 0.87, m.y + s * 0.5,
                m.x - s * 0.87, m.y + s * 0.5,
                m.x, m.y - s
            )
        else
            -- Standard pulsing wireframe diamond
            local s = 1.5
            love.graphics.line(m.x, m.y-s, m.x+s, m.y, m.x, m.y+s, m.x-s, m.y, m.x, m.y-s)
        end
    end
end

return Missiles
