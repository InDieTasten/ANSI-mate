require("../lib/term")
local Canvas = require("../lib/canvas")

local cursorX
local cursorY

local function update(inputs)
    for _, input in ipairs(inputs) do
        if input.type == "char" and input.char == "q" then
            Term.showCursor()
            return false
        elseif input.type == "mouse_move" then
            cursorX = input.x
            cursorY = input.y
        end
    end

    return true
end

local function render(targetCanvas)
    -- Clear the target canvas
    for y = 1, targetCanvas.height do
        for x = 1, targetCanvas.width do
            Canvas.setPixel(targetCanvas, x, y, " ")
        end
    end

    -- Render the text
    local text = "Press Q to quit."
    for i = 1, #text do
        Canvas.setPixel(targetCanvas, i, 1, text:sub(i, i))
    end

    text = "Dimensions: " .. Term.width .. "x" .. Term.height
    for i = 1, #text do
        Canvas.setPixel(targetCanvas, i, 2, text:sub(i, i))
    end

    if cursorX and cursorY then
        Canvas.setPixel(targetCanvas, cursorX, cursorY, "X")
    end
end

Term.runApp(update, render)
