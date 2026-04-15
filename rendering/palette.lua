-- Palette auto-detected from the current Omarchy system theme
-- Reads ~/.config/omarchy/current/theme/ghostty.conf on every launch
-- This file is a symlink that always points to the active theme
local Palette = {}

local theme = {}

local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        tonumber(hex:sub(1,2), 16) / 255,
        tonumber(hex:sub(3,4), 16) / 255,
        tonumber(hex:sub(5,6), 16) / 255,
    }
end

function Palette.loadFromSystem()
    -- Omarchy always symlinks the active theme config here
    local path = os.getenv("HOME") .. "/.config/omarchy/current/theme/ghostty.conf"
    local f = io.open(path, "r")
    if not f then
        -- Absolute fallback: white-on-black so the game is always playable
        theme.bg      = {0, 0, 0}
        theme.fg      = {1, 1, 1}
        theme.accent  = {1, 1, 1}
        for i = 0, 15 do
            theme["color" .. i] = {i/15, i/15, i/15}
        end
        theme.dim = theme.color8
        return
    end

    for line in f:lines() do
        local key, val = line:match("^(%S+)%s*=%s*(#%x+)")
        if key and val then
            if key == "background" then theme.bg = hexToRGB(val)
            elseif key == "foreground" then theme.fg = hexToRGB(val)
            elseif key == "cursor-color" then theme.accent = hexToRGB(val)
            end
        end

        local idx, hex = line:match("^palette%s*=%s*(%d+)=(#%x+)")
        if idx and hex then
            theme["color" .. idx] = hexToRGB(hex)
        end
    end
    f:close()

    -- Derive dim from color8 (bright black / muted) which all themes provide
    theme.dim = theme.color8 or theme.color0 or {0.2, 0.2, 0.2}

    -- Safety: ensure all 16 colours exist (some themes might be sparse)
    for i = 0, 15 do
        if not theme["color" .. i] then
            theme["color" .. i] = theme.fg or {1, 1, 1}
        end
    end
    if not theme.bg then theme.bg = {0, 0, 0} end
    if not theme.fg then theme.fg = {1, 1, 1} end
    if not theme.accent then theme.accent = theme.color12 or theme.fg end
end

-- Vector-style palette mapping for the game
-- Maps the 16 ANSI theme colours into game roles
function Palette.get(wave)
    local shift = ((math.ceil(wave / 2) - 1) % 5)

    local primary_colors = {theme.color4, theme.color5, theme.color6, theme.color9, theme.color10}
    local enemy_colors = {theme.color1, theme.color2, theme.color3, theme.color9, theme.color1}

    return {
        sky       = theme.bg,
        ground    = primary_colors[shift + 1],
        missile   = enemy_colors[shift + 1],
        abm       = theme.color6,
        cities    = primary_colors[shift + 1],
        exp1      = theme.accent,
        exp2      = theme.color4,
        crosshair = theme.accent,
        dim       = theme.dim,
        bright    = theme.accent,
        fg        = theme.fg,
        grid      = theme.color0,
        glow      = theme.color4,
    }
end

function Palette.raw()
    return theme
end

return Palette
