require("lib/term")
require("lib/canvas")
require("lib/term-ui")

local defaultCanvasWidth = 20
local defaultCanvasHeight = 10
local fileName = ({ ... })[1] or "ascii-art"

local fileHandle = io.open(fileName, "r")
local canvas
if fileHandle then
    local fileContents = fileHandle:read("*a")
    fileHandle:close()
    canvas = Canvas.fromText(fileContents)
else
    canvas = Canvas.new(defaultCanvasWidth, defaultCanvasHeight)
end

local cursorX
local cursorY
local canvasX
local canvasY

local function update(inputs)
    for _, input in ipairs(inputs) do
        if input.type == "char" and input.char == "q" then
            Term.showCursor()
            return false
        elseif input.type == "raw" and input.hex == "13" then -- Ctrl + S
            local file = io.open(fileName, "w")
            if file then
                file:write(Canvas.toText(canvas))
                file:close()
            else
                error("Could not open file for writing.")
            end
        elseif input.type == "mouse_move" then
            cursorX = input.x
            cursorY = input.y
        elseif input.type == "mouse_press" then
            if input.x > canvasX and input.x <= canvasX + canvas.width and
                input.y > canvasY and input.y <= canvasY + canvas.height then
                Canvas.setPixel(canvas, input.x - canvasX, input.y - canvasY, "O")
            end
        elseif input.type == "resize" then
            canvasX = math.floor(Term.width / 2 - canvas.width / 2)
            canvasY = math.floor(Term.height / 2 - canvas.height / 2)
        end
    end

    return true
end

local function render()
    Term.clear()

    if canvas then
        TermUI.drawCanvas(Term, canvas, canvasX + 1, canvasY + 1)
    end

    Term.setCursorPos(1, 1)
    Term.write("Press Q to quit.")

    Term.setCursorPos(1, 2)
    Term.write("Dimensions: " .. Term.width .. "x" .. Term.height)

    if cursorX and cursorY then
        Term.setCursorPos(cursorX, cursorY)
        Term.write("X")
    end
    Term.flush()
end

Term.hideCursor()
Term.runApp(update, render)
