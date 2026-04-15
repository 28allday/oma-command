local World = require("game.world")
local Palette = require("rendering.palette")

local Crosshair = {
    x = 128,
    y = 116,
    targets = {},
}

function Crosshair.update()
    local mx, my = love.mouse.getPosition()
    Crosshair.x, Crosshair.y = World.toGame(mx, my)
end

function Crosshair.addTarget(x, y)
    table.insert(Crosshair.targets, {x = x, y = y, time = 0})
end

function Crosshair.updateTargets(dt)
    for i = #Crosshair.targets, 1, -1 do
        Crosshair.targets[i].time = Crosshair.targets[i].time + dt
    end
end

function Crosshair.removeTarget(x, y)
    for i = #Crosshair.targets, 1, -1 do
        local t = Crosshair.targets[i]
        if math.abs(t.x - x) < 1 and math.abs(t.y - y) < 1 then
            table.remove(Crosshair.targets, i)
            return
        end
    end
end

function Crosshair.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale
    local t = love.timer.getTime()

    -- Target markers: pulsing wireframe squares
    for _, tgt in ipairs(Crosshair.targets) do
        local pulse = 0.3 + math.sin(tgt.time * 15) * 0.3
        love.graphics.setColor(p.crosshair[1], p.crosshair[2], p.crosshair[3], pulse)
        love.graphics.setLineWidth(lw)
        local s = 2.5
        love.graphics.rectangle("line", tgt.x - s, tgt.y - s, s*2, s*2)
    end

    -- Crosshair: vector-style rotating brackets
    local size = 5
    local gap = 1.5
    local rot = t * 0.5  -- slow rotation

    love.graphics.setColor(p.crosshair)
    love.graphics.setLineWidth(lw * 2)

    -- Four corner brackets
    -- Top
    love.graphics.line(Crosshair.x - size, Crosshair.y - gap, Crosshair.x - size, Crosshair.y - size, Crosshair.x - gap, Crosshair.y - size)
    love.graphics.line(Crosshair.x + gap, Crosshair.y - size, Crosshair.x + size, Crosshair.y - size, Crosshair.x + size, Crosshair.y - gap)
    -- Bottom
    love.graphics.line(Crosshair.x + size, Crosshair.y + gap, Crosshair.x + size, Crosshair.y + size, Crosshair.x + gap, Crosshair.y + size)
    love.graphics.line(Crosshair.x - gap, Crosshair.y + size, Crosshair.x - size, Crosshair.y + size, Crosshair.x - size, Crosshair.y + gap)

    -- Centre dot
    love.graphics.setColor(p.bright)
    love.graphics.circle("fill", Crosshair.x, Crosshair.y, 0.5, 6)
end

return Crosshair
