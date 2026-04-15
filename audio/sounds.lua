local Sounds = {}

local sources = {}
local SAMPLE_RATE = 44100

local function makeSoundData(duration, generator)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sd = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)
    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE  -- time in seconds
        local p = i / samples       -- progress 0..1
        local val = generator(t, p)
        val = math.max(-1, math.min(1, val))
        sd:setSample(i, val)
    end
    return sd
end

local function makeSource(soundData)
    return love.audio.newSource(soundData, "static")
end

-- ── Sound Generators ──

local function genLaunch(t, p)
    -- Ascending frequency sweep, sine wave
    local freq = 300 + p * 1200
    local env = 1 - p  -- fade out
    return math.sin(2 * math.pi * freq * t) * env * 0.4
end

local function genExplosion(t, p)
    -- Low sine + noise burst with decay
    local env = (1 - p) ^ 2
    local sine = math.sin(2 * math.pi * (60 + 40 * (1 - p)) * t) * 0.5
    local noise = (math.random() * 2 - 1) * 0.5
    return (sine + noise) * env * 0.5
end

local function genImpact(t, p)
    -- Sharp noise burst
    local env = (1 - p) ^ 4
    local noise = (math.random() * 2 - 1)
    return noise * env * 0.6
end

local function genCityDestroyed(t, p)
    -- Low rumble: noise + low sine, longer decay
    local env = (1 - p) ^ 1.5
    local sine = math.sin(2 * math.pi * (40 + 20 * (1 - p)) * t) * 0.6
    local noise = (math.random() * 2 - 1) * 0.4
    -- Add a sub-bass throb
    local throb = math.sin(2 * math.pi * 25 * t) * 0.3 * env
    return (sine + noise + throb) * env * 0.5
end

local function genMirvSplit(t, p)
    -- Quick high chirp
    local freq = 2000 - p * 800
    local env = (1 - p) ^ 2
    return math.sin(2 * math.pi * freq * t) * env * 0.35
end

local function genWaveStart(t, p)
    -- Two-tone beep
    local freq
    if p < 0.5 then
        freq = 800
    else
        freq = 1100
    end
    local env = 0.8
    -- Small fade at edges
    if p < 0.05 then env = p / 0.05 * 0.8 end
    if p > 0.9 then env = (1 - p) / 0.1 * 0.8 end
    return math.sin(2 * math.pi * freq * t) * env * 0.3
end

local function genBonusTick(t, p)
    -- Short click/pip
    local freq = 1500
    local env = (1 - p) ^ 6
    return math.sin(2 * math.pi * freq * t) * env * 0.4
end

local function genGameOver(t, p)
    -- Long descending sweep + noise
    local freq = 600 * (1 - p * 0.7)
    local env = (1 - p) ^ 0.8
    local sine = math.sin(2 * math.pi * freq * t) * 0.4
    local noise = (math.random() * 2 - 1) * 0.2 * p  -- noise increases
    -- Add a pulsing effect
    local pulse = 0.7 + math.sin(2 * math.pi * 3 * t) * 0.3
    return (sine + noise) * env * pulse * 0.5
end

-- ── Public API ──

function Sounds.init()
    sources = {}

    local defs = {
        launch         = {0.15, genLaunch},
        explosion      = {0.4,  genExplosion},
        impact         = {0.1,  genImpact},
        city_destroyed = {0.6,  genCityDestroyed},
        mirv_split     = {0.08, genMirvSplit},
        wave_start     = {0.3,  genWaveStart},
        bonus_tick     = {0.05, genBonusTick},
        game_over      = {1.5,  genGameOver},
    }

    for name, def in pairs(defs) do
        local duration, generator = def[1], def[2]
        local sd = makeSoundData(duration, generator)
        sources[name] = makeSource(sd)
    end
end

function Sounds.play(name)
    local src = sources[name]
    if not src then return end
    -- Clone to allow overlapping playback
    local clone = src:clone()
    clone:play()
end

return Sounds
