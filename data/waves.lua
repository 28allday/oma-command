local Waves = {}

-- Returns wave config for a given wave number
-- Tuned for a gentler ramp: wave 1-3 should feel learnable,
-- real challenge starts around wave 6-8, brutal by wave 15+
function Waves.get(wave)
    -- Missiles: gentler ramp — start low, add ~1/wave, cap at 26
    local missile_count = math.min(7 + wave, 26)
    missile_count = math.floor(missile_count)

    -- Speed: very slow early, gentler ramp, caps at 50
    local missile_speed
    if wave <= 4 then
        missile_speed = 6 + wave * 1.5          -- 7.5, 9, 10.5, 12
    elseif wave <= 10 then
        missile_speed = 12 + (wave - 4) * 2.5   -- 14.5..27
    elseif wave <= 18 then
        missile_speed = 27 + (wave - 10) * 2.8  -- 29.8..49.4
    else
        missile_speed = 50
    end

    -- Spawn interval: generous early, tighter later
    local spawn_interval
    if wave <= 4 then
        spawn_interval = 2.2 - wave * 0.12      -- 2.08, 1.96, 1.84, 1.72
    elseif wave <= 10 then
        spawn_interval = 1.7 - (wave - 4) * 0.12 -- 1.58..0.98
    else
        spawn_interval = math.max(1.0 - (wave - 10) * 0.04, 0.5)
    end

    local multiplier
    if wave <= 2 then multiplier = 1
    elseif wave <= 4 then multiplier = 2
    elseif wave <= 6 then multiplier = 3
    elseif wave <= 8 then multiplier = 4
    elseif wave <= 10 then multiplier = 5
    else multiplier = 6
    end

    return {
        missile_count = missile_count,
        missile_speed = missile_speed,
        spawn_interval = spawn_interval,
        multiplier = multiplier,
    }
end

return Waves
