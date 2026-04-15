local HighScores = {}

local MAX_SCORES = 10
local SAVE_FILE = "high_scores.dat"

local scores = {}

-- Entry state
local entry = {
    active = false,
    score = 0,
    letters = {"A", "A", "A"},
    position = 1,  -- 1, 2, or 3
    blink = 0,
}

-- ── Data Management ──

function HighScores.init()
    HighScores.load()
end

function HighScores.load()
    scores = {}
    if love.filesystem.getInfo(SAVE_FILE) then
        local data = love.filesystem.read(SAVE_FILE)
        if data then
            for line in data:gmatch("[^\n]+") do
                local initials, score = line:match("^(%a%a%a)%s+(%d+)$")
                if initials and score then
                    table.insert(scores, {initials = initials:upper(), score = tonumber(score)})
                end
            end
        end
    end
    table.sort(scores, function(a, b) return a.score > b.score end)
    -- Trim to max
    while #scores > MAX_SCORES do
        table.remove(scores)
    end
end

function HighScores.save()
    local lines = {}
    for _, entry in ipairs(scores) do
        table.insert(lines, string.format("%s %d", entry.initials, entry.score))
    end
    love.filesystem.write(SAVE_FILE, table.concat(lines, "\n") .. "\n")
end

function HighScores.isHighScore(score)
    if score <= 0 then return false end
    if #scores < MAX_SCORES then return true end
    return score > scores[#scores].score
end

function HighScores.addScore(initials, score)
    table.insert(scores, {initials = initials:upper(), score = score})
    table.sort(scores, function(a, b) return a.score > b.score end)
    while #scores > MAX_SCORES do
        table.remove(scores)
    end
    HighScores.save()
end

function HighScores.getScores()
    local result = {}
    for _, s in ipairs(scores) do
        table.insert(result, {initials = s.initials, score = s.score})
    end
    return result
end

function HighScores.getHighest()
    if #scores > 0 then
        return scores[1].score
    end
    return 0
end

-- ── Entry Screen ──

function HighScores.startEntry(score)
    entry.active = true
    entry.score = score
    entry.letters = {"A", "A", "A"}
    entry.position = 1
    entry.blink = 0
end

function HighScores.isEntryActive()
    return entry.active
end

function HighScores.updateEntry(dt)
    entry.blink = entry.blink + dt
end

function HighScores.keypressedEntry(key)
    if not entry.active then return nil end

    if key == "left" then
        entry.position = math.max(1, entry.position - 1)
    elseif key == "right" then
        entry.position = math.min(3, entry.position + 1)
    elseif key == "up" then
        local b = entry.letters[entry.position]:byte()
        b = b + 1
        if b > 90 then b = 65 end  -- wrap Z -> A
        entry.letters[entry.position] = string.char(b)
    elseif key == "down" then
        local b = entry.letters[entry.position]:byte()
        b = b - 1
        if b < 65 then b = 90 end  -- wrap A -> Z
        entry.letters[entry.position] = string.char(b)
    elseif key == "return" or key == "kpenter" then
        local initials = table.concat(entry.letters)
        local score = entry.score
        entry.active = false
        HighScores.addScore(initials, score)
        return "done", {initials = initials, score = score}
    elseif key:match("^%a$") and #key == 1 then
        -- Direct letter input
        entry.letters[entry.position] = key:upper()
        if entry.position < 3 then
            entry.position = entry.position + 1
        end
    end

    return nil
end

function HighScores.drawEntry(screenW, screenH, palette, fonts)
    local midX = screenW / 2
    local midY = screenH * 0.25

    -- "NEW HIGH SCORE" header
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(palette.bright)
    local t = love.timer.getTime()
    local pulse = 0.7 + math.sin(t * 4) * 0.3
    love.graphics.setColor(palette.bright[1], palette.bright[2], palette.bright[3], pulse)
    love.graphics.printf("NEW HIGH SCORE", 0, midY, screenW, "center")

    -- Score display
    midY = midY + fonts.large:getHeight() + 16
    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(palette.fg)
    love.graphics.printf(string.format("%d", entry.score), 0, midY, screenW, "center")

    -- Letter entry boxes
    midY = midY + fonts.medium:getHeight() + 32
    local boxW = math.floor(screenW * 0.06)
    local boxH = math.floor(boxW * 1.3)
    local gap = math.floor(boxW * 0.4)
    local totalW = boxW * 3 + gap * 2
    local startX = midX - totalW / 2

    love.graphics.setFont(fonts.large)
    local letterH = fonts.large:getHeight()

    for i = 1, 3 do
        local bx = startX + (i - 1) * (boxW + gap)
        local by = midY

        -- Box outline
        local isSelected = (i == entry.position)
        if isSelected then
            local blinkOn = math.floor(entry.blink * 3) % 2 == 0
            if blinkOn then
                love.graphics.setColor(palette.bright)
            else
                love.graphics.setColor(palette.dim)
            end
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(palette.dim)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", bx, by, boxW, boxH)

        -- Up/down arrows for selected position
        if isSelected then
            love.graphics.setColor(palette.bright[1], palette.bright[2], palette.bright[3], 0.5)
            local arrowX = bx + boxW / 2
            -- Up arrow
            local arrowTop = by - 12
            love.graphics.polygon("fill", arrowX - 5, arrowTop + 8, arrowX + 5, arrowTop + 8, arrowX, arrowTop)
            -- Down arrow
            local arrowBot = by + boxH + 4
            love.graphics.polygon("fill", arrowX - 5, arrowBot, arrowX + 5, arrowBot, arrowX, arrowBot + 8)
        end

        -- Letter
        love.graphics.setColor(palette.fg)
        local lw = fonts.large:getWidth(entry.letters[i])
        local lx = bx + (boxW - lw) / 2
        local ly = by + (boxH - letterH) / 2
        love.graphics.print(entry.letters[i], lx, ly)
    end

    -- Instructions
    local instrY = midY + boxH + 32
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(palette.dim)
    love.graphics.printf("TYPE LETTERS  /  ARROWS TO SELECT  /  ENTER TO CONFIRM", 0, instrY, screenW, "center")
end

function HighScores.drawTable(screenW, screenH, palette, fonts)
    local topY = screenH * 0.68
    local lineH = fonts.medium:getHeight() + 4

    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(palette.bright)
    love.graphics.printf("HIGH SCORES", 0, topY, screenW, "center")

    topY = topY + lineH + 8

    love.graphics.setFont(fonts.small)
    local entryH = fonts.small:getHeight() + 3

    if #scores == 0 then
        love.graphics.setColor(palette.dim)
        love.graphics.printf("NO SCORES YET", 0, topY, screenW, "center")
        return
    end

    local colW = math.floor(screenW * 0.4)
    local startX = (screenW - colW) / 2

    for i, s in ipairs(scores) do
        local y = topY + (i - 1) * entryH
        local rankStr = string.format("%2d.", i)
        local scoreStr = string.format("%d", s.score)

        -- Rank and initials
        if i == 1 then
            love.graphics.setColor(palette.bright)
        else
            love.graphics.setColor(palette.fg[1], palette.fg[2], palette.fg[3], 0.8)
        end
        love.graphics.print(rankStr .. " " .. s.initials, startX, y)

        -- Score right-aligned
        local sw = fonts.small:getWidth(scoreStr)
        love.graphics.print(scoreStr, startX + colW - sw, y)

        -- Subtle separator line
        love.graphics.setColor(palette.dim[1], palette.dim[2], palette.dim[3], 0.2)
        love.graphics.setLineWidth(1)
        love.graphics.line(startX, y + entryH - 1, startX + colW, y + entryH - 1)
    end
end

return HighScores
