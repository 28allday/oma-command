local World = require("game.world")
local Palette = require("rendering.palette")

local Batteries = {}

local batteries = {}

local DEFS = {
    { name = "Bravo",  x = 18,  y = World.GROUND_Y + 6, speed = 180, keys = {"a", "1"} },
    { name = "Kilo",   x = 128, y = World.GROUND_Y + 6, speed = 420, keys = {"s", "2"} },
    { name = "Sierra", x = 238, y = World.GROUND_Y + 6, speed = 180, keys = {"d", "3"} },
}

function Batteries.init()
    batteries = {}
    for i, def in ipairs(DEFS) do
        batteries[i] = {
            name = def.name,
            x = def.x,
            y = def.y,
            speed = def.speed,
            ammo = 10,
            alive = true,
            index = i,
        }
    end
end

function Batteries.rearm()
    for _, b in ipairs(batteries) do
        b.ammo = 10
        b.alive = true
    end
end

function Batteries.get(index)
    return batteries[index]
end

function Batteries.getAll()
    return batteries
end

function Batteries.fire(index)
    local b = batteries[index]
    if b and b.alive and b.ammo > 0 then
        b.ammo = b.ammo - 1
        return true
    end
    return false
end

function Batteries.findNearest(gx, gy)
    local centre = batteries[2]
    if centre.alive and centre.ammo > 0 then
        return centre
    end
    local best = nil
    local bestDist = math.huge
    for _, i in ipairs({1, 3}) do
        local b = batteries[i]
        if b.alive and b.ammo > 0 then
            local dist = math.abs(b.x - gx)
            if dist < bestDist then
                bestDist = dist
                best = b
            end
        end
    end
    return best
end

function Batteries.destroy(index)
    if batteries[index] then
        batteries[index].alive = false
        batteries[index].ammo = 0
    end
end

function Batteries.getTargets()
    local targets = {}
    for _, b in ipairs(batteries) do
        if b.alive then
            table.insert(targets, {x = b.x, y = b.y, type = "battery", index = b.index})
        end
    end
    return targets
end

function Batteries.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale
    local t = love.timer.getTime()

    for _, b in ipairs(batteries) do
        local x, y = b.x, b.y
        if b.alive then
            -- Tilt launcher inward toward screen centre
            local tilt
            if b.index == 1 then tilt = 0.35
            elseif b.index == 3 then tilt = -0.35
            else tilt = 0 end
            local ca, sa = math.cos(tilt), math.sin(tilt)

            -- Cab-facing direction: the left battery faces right, the right one faces left, the centre faces right by default
            local dir
            if b.index == 1 then dir = 1
            elseif b.index == 3 then dir = -1
            else dir = 1 end

            -- === TRUCK CHASSIS ===
            love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.9)
            love.graphics.setLineWidth(lw * 1.5)
            -- Flatbed: long rectangle
            love.graphics.line(x-10, y-1.5, x+10, y-1.5)
            love.graphics.line(x-10, y, x+10, y)
            love.graphics.line(x-10, y-1.5, x-10, y)
            love.graphics.line(x+10, y-1.5, x+10, y)

            -- Cab at front (in direction dir)
            local cabX = x + dir * 7
            local cabFront = x + dir * 10
            local cabBack = x + dir * 4
            love.graphics.line(cabBack, y-1.5, cabBack, y-5)       -- cab back wall
            love.graphics.line(cabBack, y-5, cabBack + dir*2, y-5.5) -- roof slope back
            love.graphics.line(cabBack + dir*2, y-5.5, cabFront - dir*0.5, y-5.5) -- roof
            love.graphics.line(cabFront - dir*0.5, y-5.5, cabFront, y-3)  -- windshield slope
            love.graphics.line(cabFront, y-3, cabFront, y-1.5)     -- cab front

            -- Window
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.5)
            love.graphics.setLineWidth(lw)
            love.graphics.line(cabFront - dir*0.3, y-3.2, cabFront - dir*1.6, y-5)

            -- Wheels (4, spaced along chassis)
            love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.9)
            love.graphics.setLineWidth(lw)
            love.graphics.circle("line", x-7, y+0.6, 1.3, 10)
            love.graphics.circle("line", x-3, y+0.6, 1.3, 10)
            love.graphics.circle("line", x+3, y+0.6, 1.3, 10)
            love.graphics.circle("line", x+7, y+0.6, 1.3, 10)

            -- === TURRET mounted on flatbed (offset away from cab) ===
            local turretX = x - dir * 3
            love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.75)
            love.graphics.setLineWidth(lw * 1.3)
            love.graphics.line(turretX-3, y-1.5, turretX-3, y-4, turretX+3, y-4, turretX+3, y-1.5)

            -- === LAUNCH RACK: 3 angled tubes with missiles loaded ===
            -- Tube length, pivot at (x, y-4), rotated by tilt
            local pivotY = y - 4
            local tubeLen = 9
            local function rot(dx, dy)
                return turretX + dx*ca - dy*sa, pivotY + dx*sa + dy*ca
            end

            love.graphics.setLineWidth(lw * 1.3)
            for i = -1, 1 do
                local offX = i * 2.2
                -- Tube walls
                love.graphics.setColor(p.ground[1], p.ground[2], p.ground[3], 0.9)
                local wx1, wy1 = rot(offX - 0.8, 0)
                local wx2, wy2 = rot(offX - 0.8, -tubeLen)
                local wx3, wy3 = rot(offX + 0.8, 0)
                local wx4, wy4 = rot(offX + 0.8, -tubeLen)
                love.graphics.line(wx1, wy1, wx2, wy2)
                love.graphics.line(wx3, wy3, wx4, wy4)
                love.graphics.line(wx2, wy2, wx4, wy4) -- tube mouth

                -- Missile inside tube (only if ammo remains; stagger by index)
                local loaded = b.ammo >= (i + 2)   -- shows 1..3 missiles as ammo fills up
                if loaded then
                    love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.95)
                    love.graphics.setLineWidth(lw * 1.1)
                    -- Missile body
                    local bx1, by1 = rot(offX, -0.5)
                    local bx2, by2 = rot(offX, -tubeLen + 1)
                    love.graphics.line(bx1, by1, bx2, by2)
                    -- Nose cone
                    local nxL, nyL = rot(offX - 0.7, -tubeLen + 1)
                    local nxR, nyR = rot(offX + 0.7, -tubeLen + 1)
                    local ntx, nty = rot(offX, -tubeLen - 1.2)
                    love.graphics.line(nxL, nyL, ntx, nty)
                    love.graphics.line(nxR, nyR, ntx, nty)
                    love.graphics.line(nxL, nyL, nxR, nyR)
                    love.graphics.setLineWidth(lw * 1.3)
                end
            end

            -- === RESERVE AMMO: small warheads tucked under chassis ===
            local reserve = math.max(0, b.ammo - 3)
            love.graphics.setLineWidth(lw)
            for a = 1, reserve do
                local ax = x - 9 + ((a - 1) % 7) * 2.6
                local ay = y - 0.8
                love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.7)
                love.graphics.line(ax, ay, ax, ay-1.6)
                love.graphics.line(ax-0.4, ay-1.6, ax+0.4, ay-1.6)
                love.graphics.line(ax-0.4, ay-1.6, ax, ay-2.2)
                love.graphics.line(ax+0.4, ay-1.6, ax, ay-2.2)
            end

            -- === STATUS LIGHT ===
            if math.sin(t * 4) > 0.3 then
                love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.7)
                love.graphics.circle("fill", x + 8.5, y - 2.8, 0.5, 4)
            end

        else
            -- === DESTROYED SILO ===
            love.graphics.setColor(p.dim[1], p.dim[2], p.dim[3], 0.3)
            love.graphics.setLineWidth(lw)

            -- Cracked outer hull
            love.graphics.line(x-11, y, x-9, y-3, x-7, y-2, x-5, y-4)
            love.graphics.line(x+5, y-3, x+7, y-1, x+9, y-3, x+11, y)
            love.graphics.line(x-12, y, x+12, y)

            -- Rubble and collapsed structure
            love.graphics.setColor(p.dim[1], p.dim[2], p.dim[3], 0.2)
            love.graphics.line(x-4, y, x-3, y-3, x-1, y-1, x+1, y-4, x+3, y-2, x+4, y)
            -- Bent launcher tube sticking out at angle
            love.graphics.line(x-1, y-2, x+2, y-6, x+3, y-5.5)
            love.graphics.line(x, y-2, x+3, y-7)
            -- Scattered debris
            love.graphics.line(x-6, y-1, x-5, y-2.5)
            love.graphics.line(x+6, y-1, x+7, y-2)
        end
    end
end

return Batteries
