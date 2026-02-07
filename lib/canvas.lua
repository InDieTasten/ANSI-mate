Canvas = {}

function Canvas.new(width, height)
    local canvas = {}
    canvas.width = width
    canvas.height = height
    canvas.pixels = {}
    for y = 1, height do
        canvas.pixels[y] = {}
        for x = 1, width do
            canvas.pixels[y][x] = " "
        end
    end
    return canvas
end

function Canvas.setPixel(canvas, x, y, char)
    assert(type(canvas) == "table", "canvas must be a table")
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    assert(type(char) == "string", "char must be a string")
    assert(x >= 1, "x must be greater than or equal to 1")
    assert(x <= canvas.width, "x must be less than or equal to the canvas width")
    assert(y >= 1, "y must be greater than or equal to 1")
    assert(y <= canvas.height, "y must be less than or equal to the canvas height")

    canvas.pixels[y][x] = char
end

function Canvas.trySetPixel(canvas, x, y, char)
    assert(type(canvas) == "table", "canvas must be a table")
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    assert(type(char) == "string", "char must be a string")

    if x >= 1 and x <= canvas.width and y >= 1 and y <= canvas.height then
        canvas.pixels[y][x] = char
    end
end

function Canvas.toText(canvas)
    assert(type(canvas) == "table", "canvas must be a table")

    local text = ""
    for y = 1, canvas.height do
        for x = 1, canvas.width do
            text = text .. canvas.pixels[y][x]
        end
        text = text .. "\n"
    end
    return text
end

function Canvas.fromText(text)
    assert(type(text) == "string", "text must be a string")

    local lines = {}
    local maxWidth = 0
    for line in string.gmatch(text, "([^\n]+)") do
        table.insert(lines, line)
        if #line > maxWidth then
            maxWidth = #line
        end
    end
    local width = maxWidth
    local height = #lines
    local canvas = Canvas.new(width, height)
    for y = 1, height do
        local line = lines[y]
        for x = 1, width do
            local char = line:sub(x, x)
            if char == "" then char = " " end
            Canvas.setPixel(canvas, x, y, char)
        end
    end
    return canvas
end

function Canvas.resize(canvas, newWidth, newHeight)
    assert(type(canvas) == "table", "canvas must be a table")
    assert(type(newWidth) == "number", "newWidth must be a number")
    assert(type(newHeight) == "number", "newHeight must be a number")
    assert(newWidth >= 1, "newWidth must be greater than or equal to 1")
    assert(newHeight >= 1, "newHeight must be greater than or equal to 1")

    local newCanvas = Canvas.new(newWidth, newHeight)
    for y = 1, math.min(canvas.height, newHeight) do
        for x = 1, math.min(canvas.width, newWidth) do
            newCanvas.pixels[y][x] = canvas.pixels[y][x]
        end
    end
    return newCanvas
end

function Canvas.fill(canvas, x, y, char, global)
    assert(type(canvas) == "table", "canvas must be a table")
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    assert(type(char) == "string", "char must be a string")
    assert(x >= 1, "x must be greater than or equal to 1")
    assert(x <= canvas.width, "x must be less than or equal to the canvas width")
    assert(y >= 1, "y must be greater than or equal to 1")
    assert(y <= canvas.height, "y must be less than or equal to the canvas height")
    assert(type(global) == "boolean", "global must be a boolean")

    if global then
        local oldChar = canvas.pixels[y][x]
        for i = 1, canvas.height do
            for j = 1, canvas.width do
                if canvas.pixels[i][j] == oldChar then
                    canvas.pixels[i][j] = char
                end
            end
        end
    else
        local oldChar = canvas.pixels[y][x]
        canvas.pixels[y][x] = char
        if canvas.pixels[y - 1] and canvas.pixels[y - 1][x] == oldChar then
            Canvas.fill(canvas, x, y - 1, char, false)
        end
        if canvas.pixels[y + 1] and canvas.pixels[y + 1][x] == oldChar then
            Canvas.fill(canvas, x, y + 1, char, false)
        end
        if canvas.pixels[y][x - 1] == oldChar then
            Canvas.fill(canvas, x - 1, y, char, false)
        end
        if canvas.pixels[y][x + 1] == oldChar then
            Canvas.fill(canvas, x + 1, y, char, false)
        end
    end
end

return Canvas
