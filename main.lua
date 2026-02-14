require("lib/term")
require("lib/canvas")
require("lib/term-ui")
require("lib/canvas-ui")
require("lib/ui/layout")
require("lib/ui/tool-control")
require("lib/ui/palette-control")
require("lib/ui/canvas-control")

local defaultCanvasWidth = 20
local defaultCanvasHeight = 10
local fileName = ({ ... })[1] or "ansi-art"

local fileHandle = io.open(fileName, "r")
local artCanvas
local renderCanvas
if fileHandle then
    local fileContents = fileHandle:read("*a")
    fileHandle:close()
    artCanvas = Canvas.fromText(fileContents)
else
    artCanvas = Canvas.new(defaultCanvasWidth, defaultCanvasHeight)
end

local paletteWidth = 12
local resizing = false
local tools = {
    {
        name = "Pencil",
        char = "O"
    },
    {
        name = "Eraser"
    },
    {
        name = "Rectangle",
        char = "+"
    },
    {
        name = "Fill",
        char = "."
    },
    {
        name = "Global Fill",
        char = "."
    }
}
local pencil = 1
local eraser = 2
local rectangle = 3
local fill = 4
local globalFill = 5
local state = {
    selectedTool = pencil
}

local function calculateToolbarWidth()
    local maxWidth = 0
    for _, tool in ipairs(tools) do
        if #tool.name > maxWidth then
            maxWidth = #tool.name
        end
    end
    return maxWidth + 4
end

state.toolbarWidth = calculateToolbarWidth()

local function update(inputs)
    for _, input in ipairs(inputs) do
        if input.type == "char" and input.char == "q" then     -- Q
            return false
        elseif input.type == "char" and input.char == "p" then -- P
            state.selectedTool = pencil
        elseif input.type == "char" and input.char == "e" then -- E
            state.selectedTool = eraser
        elseif input.type == "char" and input.char == "r" then -- R
            state.selectedTool = rectangle
        elseif input.type == "raw" and input.hex == "13" then  -- Ctrl + S
            local file = io.open(fileName, "w")
            if file then
                file:write(Canvas.toText(artCanvas))
                file:close()
            else
                error("Could not open file for writing.")
            end
        elseif input.type == "mouse_move" then
            if resizing and input.button == 0 then
                local newWidth = input.x - state.canvasX - 1
                local newHeight = input.y - state.canvasY - 1
                if newWidth >= 1 and newHeight >= 1 then
                    artCanvas = Canvas.resize(artCanvas, newWidth, newHeight)
                end
            elseif state.selectedTool == pencil and input.button == 0 then -- pencil
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.setPixel(artCanvas, x, y, tools[pencil].char)
                end
            elseif state.selectedTool == eraser and input.button == 0 then -- eraser
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.setPixel(artCanvas, x, y, " ")
                end
            elseif state.selectedTool == rectangle and input.button == 0 then -- rectangle
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if tools[rectangle].start then
                    tools[rectangle].fin = { x, y }
                end
            end
        elseif input.type == "mouse_press" then
            if input.x == state.canvasX + artCanvas.width + 1 and input.y == state.canvasY + artCanvas.height + 1 then
                resizing = true
            elseif input.x >= Term.width - state.toolbarWidth + 1 and input.y >= 3 and input.y <= #tools + 2 then
                state.selectedTool = input.y - 2
            elseif state.palette[input.x] and state.palette[input.x][input.y] and input.button == 0 then
                tools[state.selectedTool].char = state.palette[input.x][input.y]
            elseif state.selectedTool == pencil and input.button == 0 then
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.setPixel(artCanvas, x, y, tools[pencil].char)
                end
            elseif state.selectedTool == eraser and input.button == 0 then
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.setPixel(artCanvas, x, y, " ")
                end
            elseif state.selectedTool == rectangle and input.button == 0 then
                tools[rectangle].start = { input.x - state.canvasX, input.y - state.canvasY }
            elseif state.selectedTool == fill and input.button == 0 then
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.fill(artCanvas, x, y, tools[fill].char, false)
                end
            elseif state.selectedTool == globalFill and input.button == 0 then
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.fill(artCanvas, x, y, tools[globalFill].char, true)
                end
            end
        elseif input.type == "mouse_release" then
            resizing = false
            if state.selectedTool == pencil and input.button == 0 then -- pencil
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if x >= 1 and x <= artCanvas.width and y >= 1 and y <= artCanvas.height then
                    Canvas.setPixel(artCanvas, x, y, tools[pencil].char)
                end
            elseif state.selectedTool == rectangle and input.button == 0 then -- rectangle
                local x = input.x - state.canvasX
                local y = input.y - state.canvasY
                if tools[rectangle].start and tools[rectangle].fin then
                    local x1, y1 = tools[rectangle].start[1], tools[rectangle].start[2]
                    local x2, y2 = tools[rectangle].fin[1], tools[rectangle].fin[2]
                    local xMin, xMax = math.min(x1, x2), math.max(x1, x2)
                    local yMin, yMax = math.min(y1, y2), math.max(y1, y2)
                    for x = xMin, xMax do
                        Canvas.trySetPixel(artCanvas, x, yMin, tools[rectangle].char)
                        Canvas.trySetPixel(artCanvas, x, yMax, tools[rectangle].char)
                    end
                    for y = yMin, yMax do
                        Canvas.trySetPixel(artCanvas, xMin, y, tools[rectangle].char)
                        Canvas.trySetPixel(artCanvas, xMax, y, tools[rectangle].char)
                    end
                    tools[rectangle].start = nil
                    tools[rectangle].fin = nil
                end
            end
        elseif input.type == "resize" then
            renderCanvas = Canvas.new(input.width, input.height)
            state.canvasX = math.floor(Term.width / 2 - artCanvas.width / 2)
            state.canvasY = math.floor(Term.height / 2 - artCanvas.height / 2)
            state.palette = {}
            for c = 32, 126 do
                local column = 0
                if c >= 96 then
                    column = 2
                elseif c >= 64 then
                    column = 1
                end
                local x = Term.width - state.toolbarWidth - paletteWidth + 2 + column * 3
                local y = c - 29 - column * 32
                state.palette[x] = state.palette[x] or {}
                state.palette[x][y] = string.char(c)
            end
            state.globalOffsetX = Term.width - state.toolbarWidth - paletteWidth - 1
            state.globalOffsetY = 0
        elseif input.type == "mouse_scroll" then
            local amplify = input.mods.shift and 3 or 1
            if input.mods.ctrl then
                if input.dir == "up" then
                    state.canvasX = state.canvasX + 2 * amplify
                elseif input.dir == "down" then
                    state.canvasX = state.canvasX - 2 * amplify
                end
            else
                if input.dir == "up" then
                    state.canvasY = state.canvasY + 1 * amplify
                elseif input.dir == "down" then
                    state.canvasY = state.canvasY - 1 * amplify
                end
            end
        end
    end

    return true
end

local componentTree = Layout.columns("|",
    { "fill", CanvasControl.new(state, artCanvas, tools, rectangle) },
    { 12, PaletteControl.new(state, tools) },
    { 15, ToolControl.new(tools, state) })

local function render()
    CanvasUI.clear(renderCanvas)
    componentTree:render(renderCanvas)
    TermUI.flipScreenBuffer(Term, renderCanvas)
    Term.flush()
end

Term.runApp(update, render)
