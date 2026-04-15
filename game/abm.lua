local World = require("game.world")
local Palette = require("rendering.palette")
local Explosions = require("game.explosions")
local Crosshair = require("game.crosshair")

local ABM = {}

local missiles = {}
local MAX_IN_FLIGHT = 8

function ABM.fire(startX, startY, targetX, targetY, speed)
    if #missiles >= MAX_IN_FLIGHT then return false end

    local dx = targetX - startX
    local dy = targetY - startY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then return false end

    table.insert(missiles, {
        startX = startX,
        startY = startY,
        targetX = targetX,
        targetY = targetY,
        x = startX,
        y = startY,
        speed = speed,
        dirX = dx / dist,
        dirY = dy / dist,
        totalDist = dist,
        birth = love.timer.getTime(),
    })

    Crosshair.addTarget(targetX, targetY)
    return true
end

function ABM.update(dt)
    for i = #missiles, 1, -1 do
        local m = missiles[i]
        local step = m.speed * dt
        m.x = m.x + m.dirX * step
        m.y = m.y + m.dirY * step

        local dx = m.x - m.startX
        local dy = m.y - m.startY
        local traveled = math.sqrt(dx * dx + dy * dy)

        if traveled >= m.totalDist then
            m.x = m.targetX
            m.y = m.targetY
            Explosions.add(m.targetX, m.targetY)
            Crosshair.removeTarget(m.targetX, m.targetY)
            table.remove(missiles, i)
        end
    end
end

function ABM.count()
    return #missiles
end

function ABM.clear()
    missiles = {}
end

function ABM.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale

    for _, m in ipairs(missiles) do
        -- Glow trail
        love.graphics.setColor(p.abm[1], p.abm[2], p.abm[3], 0.2)
        love.graphics.setLineWidth(lw * 4)
        love.graphics.line(m.startX, m.startY, m.x, m.y)

        -- Main vector trail
        love.graphics.setColor(p.abm[1], p.abm[2], p.abm[3], 0.9)
        love.graphics.setLineWidth(lw * 1.5)
        love.graphics.line(m.startX, m.startY, m.x, m.y)

        -- Bright head dot
        love.graphics.setColor(p.bright)
        love.graphics.circle("line", m.x, m.y, 1, 8)
    end
end

return ABM
