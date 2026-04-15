local World = require("game.world")
local Palette = require("rendering.palette")
local Fonts = require("rendering.fonts")

local HUD = {}

function HUD.draw()
    local p = Palette.get(World.wave)

    -- Pop out of game transform for crisp text
    love.graphics.pop()

    local font = Fonts.medium or love.graphics.getFont()
    love.graphics.setFont(font)

    local padding = 8

    -- Score (top left)
    love.graphics.setColor(p.bright)
    love.graphics.print(string.format("%06d", World.score), padding, padding)

    -- Wave (top right)
    love.graphics.setColor(p.fg)
    local waveText = "WAVE " .. World.wave
    local tw = font:getWidth(waveText)
    love.graphics.print(waveText, World.screenW - tw - padding, padding)

    -- Thin separator line under HUD
    local lineY = padding + font:getHeight() + 4
    love.graphics.setColor(p.dim)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, lineY, World.screenW, lineY)

    -- Restore game transform
    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)
end

return HUD
