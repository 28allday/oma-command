local Fonts = {}

Fonts.small = nil
Fonts.medium = nil
Fonts.large = nil
Fonts.currentH = 0
Fonts.fontPath = nil

-- Detect the system font from Omarchy's waybar config (same method as omarchy-font-current)
function Fonts.detectSystemFont()
    local home = os.getenv("HOME")
    local f = io.open(home .. "/.config/waybar/style.css", "r")
    if not f then return nil end

    local content = f:read("*a")
    f:close()

    local fontName = content:match("font%-family:%s*[\"']?([^;\"']+)")
    if not fontName then return nil end

    fontName = fontName:match("^%s*(.-)%s*$")  -- trim whitespace

    -- Use fc-match to find the actual font file
    local handle = io.popen('fc-match "' .. fontName .. '" --format="%{file}"')
    if not handle then return nil end

    local path = handle:read("*a")
    handle:close()

    if path and path ~= "" and io.open(path, "r") then
        io.open(path, "r"):close()
        return path
    end

    return nil
end

function Fonts.init(scale)
    local h = love.graphics.getHeight()
    if h == Fonts.currentH then return end
    Fonts.currentH = h

    -- Detect system font on first init
    if not Fonts.fontPath then
        Fonts.fontPath = Fonts.detectSystemFont() or false
    end

    local sSmall = math.max(10, math.floor(h * 0.018))
    local sMedium = math.max(12, math.floor(h * 0.025))
    local sLarge = math.max(16, math.floor(h * 0.045))

    if Fonts.fontPath and not Fonts.fontData then
        -- Love2D sandboxes file access, so read the font via io and create FileData
        local f = io.open(Fonts.fontPath, "rb")
        if f then
            local data = f:read("*a")
            f:close()
            Fonts.fontData = love.filesystem.newFileData(data, "systemfont.ttf")
        else
            Fonts.fontPath = false
        end
    end

    if Fonts.fontData then
        Fonts.small = love.graphics.newFont(Fonts.fontData, sSmall)
        Fonts.medium = love.graphics.newFont(Fonts.fontData, sMedium)
        Fonts.large = love.graphics.newFont(Fonts.fontData, sLarge)
    else
        Fonts.small = love.graphics.newFont(sSmall)
        Fonts.medium = love.graphics.newFont(sMedium)
        Fonts.large = love.graphics.newFont(sLarge)
    end
end

return Fonts
