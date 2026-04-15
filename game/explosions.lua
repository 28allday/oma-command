local World = require("game.world")
local Palette = require("rendering.palette")
local Sounds = require("audio.sounds")

local Explosions = {}

local explosions = {}

local EXPAND_TIME = 0.3
local HOLD_TIME = 0.5
local CONTRACT_TIME = 0.3
local MAX_RADIUS = 12
local NUM_RINGS = 4
local MAX_EXPLOSIONS = 8

function Explosions.add(x, y)
    if #explosions >= MAX_EXPLOSIONS then return end
    Sounds.play("explosion")
    table.insert(explosions, {
        x = x,
        y = y,
        radius = 0,
        maxRadius = MAX_RADIUS,
        phase = "expanding",
        timer = 0,
        birth = love.timer.getTime(),
    })
end

function Explosions.update(dt)
    for i = #explosions, 1, -1 do
        local e = explosions[i]
        e.timer = e.timer + dt

        if e.phase == "expanding" then
            e.radius = e.maxRadius * (e.timer / EXPAND_TIME)
            if e.timer >= EXPAND_TIME then
                e.phase = "holding"
                e.timer = 0
                e.radius = e.maxRadius
            end
        elseif e.phase == "holding" then
            e.radius = e.maxRadius
            if e.timer >= HOLD_TIME then
                e.phase = "contracting"
                e.timer = 0
            end
        elseif e.phase == "contracting" then
            e.radius = e.maxRadius * (1 - e.timer / CONTRACT_TIME)
            if e.timer >= CONTRACT_TIME then
                table.remove(explosions, i)
            end
        end
    end
end

function Explosions.checkCollision(x, y)
    for _, e in ipairs(explosions) do
        local dx = e.x - x
        local dy = e.y - y
        if dx * dx + dy * dy <= e.radius * e.radius then
            return true
        end
    end
    return false
end

function Explosions.anyActive()
    return #explosions > 0
end

function Explosions.getActive()
    return explosions
end

function Explosions.clear()
    explosions = {}
end

function Explosions.draw()
    local p = Palette.get(World.wave)
    local t = love.timer.getTime()
    local lw = 1 / World.scale

    for _, e in ipairs(explosions) do
        if e.radius > 0.5 then
            local age = t - e.birth
            local flash = math.sin(age * 40) > 0

            -- Outer glow halo
            love.graphics.setColor(p.glow[1], p.glow[2], p.glow[3], 0.2)
            love.graphics.circle("fill", e.x, e.y, e.radius * 1.4)

            -- Solid fireball — flashes between two theme colours
            if flash then
                love.graphics.setColor(p.exp1)
            else
                love.graphics.setColor(p.exp2)
            end
            love.graphics.circle("fill", e.x, e.y, e.radius)

            -- Bright wireframe edge ring for vector feel
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.6)
            love.graphics.setLineWidth(lw * 1.5)
            love.graphics.circle("line", e.x, e.y, e.radius, 32)
        end
    end
end

return Explosions
