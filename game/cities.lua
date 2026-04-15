local World = require("game.world")
local Palette = require("rendering.palette")

local Cities = {}

Cities.destroyedThisWave = 0

-- City outlines: each city has a main profile polyline plus detail lines
-- {outline = {x,y,...}, details = {{x1,y1,x2,y2}, ...}}
-- All coords relative to city centre bottom

local SHAPES = {
    -- 1: Office tower cluster — tall centre, two flanking blocks
    {
        outline = {-7,0, -7,-6, -5,-6, -5,-8, -3,-8, -3,-4, -1,-4, -1,-14, 1,-14, 1,-4, 3,-4, 3,-7, 5,-7, 5,-10, 7,-10, 7,0},
        details = {
            {-1,-14, 0,-16, 1,-14},  -- antenna spire
            {-6,-2, -6,-5},          -- window column left
            {-5.5,-2, -5.5,-5},
            {0,-5, 0,-12},           -- centre line
            {6,-2, 6,-9},            -- window column right
            {5.5,-2, 5.5,-9},
        },
    },
    -- 2: Twin towers with skybridge
    {
        outline = {-7,0, -7,-12, -4,-12, -4,-4, -2,-4, -2,-11, 2,-11, 2,-4, 4,-4, 4,-13, 7,-13, 7,0},
        details = {
            {-4,-8, -2,-8},          -- skybridge
            {-6,-3, -6,-11},         -- left window col
            {-5,-3, -5,-11},
            {5,-3, 5,-12},           -- right window col
            {6,-3, 6,-12},
            {4,-13, 5,-15, 6,-15, 7,-13},  -- right tower top detail
        },
    },
    -- 3: Stepped pyramid / ziggurat
    {
        outline = {-8,0, -8,-4, -6,-4, -6,-7, -4,-7, -4,-10, -2,-10, -2,-13, 2,-13, 2,-10, 4,-10, 4,-7, 6,-7, 6,-4, 8,-4, 8,0},
        details = {
            {-1,-13, 0,-15, 1,-13},  -- antenna
            {-7,-1, -7,-3},          -- tier details
            {-5,-5, -5,-6},
            {-3,-8, -3,-9},
            {3,-8, 3,-9},
            {5,-5, 5,-6},
            {7,-1, 7,-3},
        },
    },
    -- 4: Gothic spire with flying buttresses
    {
        outline = {-6,0, -6,-5, -4,-5, -4,-8, -2,-8, -2,-11, -1,-14, 0,-17, 1,-14, 2,-11, 2,-8, 4,-8, 4,-5, 6,-5, 6,0},
        details = {
            {-6,-5, -4,-8},          -- left buttress
            {6,-5, 4,-8},            -- right buttress
            {-1,-8, -1,-11},         -- internal frame
            {1,-8, 1,-11},
            {-0.5,-11, -0.5,-14},    -- upper spire frame
            {0.5,-11, 0.5,-14},
            {-3,-3, -3,-7},          -- window columns
            {3,-3, 3,-7},
        },
    },
    -- 5: Industrial complex — wide, boxy, with chimney
    {
        outline = {-8,0, -8,-6, -6,-6, -6,-8, -4,-8, -4,-6, -1,-6, -1,-10, 1,-10, 1,-6, 3,-6, 3,-5, 5,-5, 5,-8, 6,-8, 6,-12, 7,-12, 7,-5, 8,-5, 8,0},
        details = {
            {6,-12, 6.5,-14, 7,-12}, -- chimney smoke wisp
            {-7,-2, -7,-5},          -- windows
            {-5,-2, -5,-5},
            {0,-7, 0,-9},            -- centre structure
            {-3,-2, -3,-5},
            {4,-2, 4,-4},
        },
    },
    -- 6: Domed building with towers
    {
        outline = {-7,0, -7,-8, -6,-8, -6,-10, -5,-10, -5,-8, -3,-8, -3,-9, -2,-11, 0,-12, 2,-11, 3,-9, 3,-8, 5,-8, 5,-11, 6,-11, 6,-8, 7,-8, 7,0},
        details = {
            {-2,-11, 0,-12, 2,-11},  -- dome highlight
            {0,-12, 0,-14},          -- dome antenna
            {-6,-8, -6,-10},         -- left tower internal
            {5,-8, 5,-11},           -- right tower internal
            {-5.5,-10, -5.5,-10.5, -6.5,-10.5, -6.5,-10}, -- left tower cap
            {5,-11, 5,-11.5, 6,-11.5, 6,-11},              -- right tower cap
            {-2,-3, -2,-7},          -- window columns
            {2,-3, 2,-7},
        },
    },
}

-- Rubble: broken jagged debris wireframe
local RUBBLE = {
    outline = {-6,0, -5,-2, -4,-1, -3,-3, -1,-1, 0,-2.5, 1,-1, 3,-3, 4,-1.5, 5,-2, 6,0},
    details = {
        {-4,-1, -4.5,-3, -3,-2},
        {1,-1, 0.5,-3, 2,-2},
        {-2,-0.5, -1.5,-2},
        {3,-0.5, 3.5,-2.5},
    },
}

local cities = {}
local POSITIONS = { 40, 68, 96, 160, 188, 216 }

function Cities.init()
    cities = {}
    Cities.destroyedThisWave = 0
    for i = 1, 6 do
        cities[i] = {
            x = POSITIONS[i],
            y = World.GROUND_Y,
            alive = true,
            index = i,
        }
    end
end

function Cities.resetWaveCount()
    Cities.destroyedThisWave = 0
end

function Cities.get()
    return cities
end

function Cities.destroy(index)
    if cities[index] and cities[index].alive then
        if Cities.destroyedThisWave >= 3 then
            -- Max 3 cities destroyed per wave - city survives
            return false
        end
        cities[index].alive = false
        Cities.destroyedThisWave = Cities.destroyedThisWave + 1
        return true
    end
    return false
end

function Cities.allDestroyed()
    for _, c in ipairs(cities) do
        if c.alive then return false end
    end
    return true
end

function Cities.aliveCount()
    local count = 0
    for _, c in ipairs(cities) do
        if c.alive then count = count + 1 end
    end
    return count
end

function Cities.destroyedCount()
    local count = 0
    for _, c in ipairs(cities) do
        if not c.alive then count = count + 1 end
    end
    return count
end

function Cities.deployBonusCities()
    -- Deploy reserve bonus cities to destroyed city slots
    local deployed = 0
    for _, c in ipairs(cities) do
        if not c.alive and World.bonusCities > 0 then
            c.alive = true
            World.bonusCities = World.bonusCities - 1
            deployed = deployed + 1
        end
    end
    return deployed
end

function Cities.getTargets()
    local targets = {}
    for _, c in ipairs(cities) do
        if c.alive then
            table.insert(targets, {x = c.x, y = c.y, type = "city", index = c.index})
        end
    end
    return targets
end

function Cities.draw()
    local p = Palette.get(World.wave)
    local lw = 1 / World.scale
    local t = love.timer.getTime()

    for i, c in ipairs(cities) do
        if c.alive then
            local shape = SHAPES[i]

            -- Main building outline
            love.graphics.setColor(p.cities[1], p.cities[2], p.cities[3], 0.9)
            love.graphics.setLineWidth(lw * 1.5)
            local pts = {}
            for j = 1, #shape.outline, 2 do
                table.insert(pts, c.x + shape.outline[j])
                table.insert(pts, c.y + shape.outline[j+1])
            end
            if #pts >= 4 then
                love.graphics.line(pts)
            end

            -- Architectural details (windows, antennae, internal structure)
            love.graphics.setColor(p.cities[1], p.cities[2], p.cities[3], 0.35)
            love.graphics.setLineWidth(lw)
            for _, d in ipairs(shape.details) do
                local dpts = {}
                for j = 1, #d, 2 do
                    table.insert(dpts, c.x + d[j])
                    table.insert(dpts, c.y + d[j+1])
                end
                if #dpts >= 4 then
                    love.graphics.line(dpts)
                end
            end

            -- Faint glow at base
            love.graphics.setColor(p.glow[1], p.glow[2], p.glow[3], 0.12)
            love.graphics.setLineWidth(lw * 5)
            love.graphics.line(c.x - 8, c.y, c.x + 8, c.y)

            -- Occasional window twinkle
            local twinkle = math.sin(t * 1.5 + i * 2.1)
            if twinkle > 0.85 then
                love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], 0.4)
                local wx = c.x + math.sin(i * 7.3) * 3
                local wy = c.y - 3 - math.abs(math.sin(i * 4.1)) * 6
                love.graphics.circle("fill", wx, wy, 0.4, 4)
            end
        else
            -- Rubble — same for all destroyed cities
            love.graphics.setColor(p.dim[1], p.dim[2], p.dim[3], 0.4)
            love.graphics.setLineWidth(lw)

            -- Main rubble outline
            local pts = {}
            for j = 1, #RUBBLE.outline, 2 do
                table.insert(pts, c.x + RUBBLE.outline[j])
                table.insert(pts, c.y + RUBBLE.outline[j+1])
            end
            if #pts >= 4 then
                love.graphics.line(pts)
            end

            -- Rubble debris details
            love.graphics.setColor(p.dim[1], p.dim[2], p.dim[3], 0.2)
            for _, d in ipairs(RUBBLE.details) do
                local dpts = {}
                for j = 1, #d, 2 do
                    table.insert(dpts, c.x + d[j])
                    table.insert(dpts, c.y + d[j+1])
                end
                if #dpts >= 4 then
                    love.graphics.line(dpts)
                end
            end
        end
    end
end

return Cities
