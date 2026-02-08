TermUI = {}

function TermUI.drawCanvas(termContext, canvas, x, y)
    for i = 1, canvas.height do
        termContext.setCursorPos(x, y + i - 1)
        termContext.write(table.concat(canvas.pixels[i]))
    end
end

function TermUI.flipScreenBuffer(termContext, newBufferCanvas)
    if termContext.previousBufferCanvas then
        TermUI.differentialRender(termContext, termContext.previousBufferCanvas, newBufferCanvas)
    else
        TermUI.drawCanvas(termContext, newBufferCanvas, 1, 1)
    end
    termContext.previousBufferCanvas = Canvas.copy(newBufferCanvas)
end

function TermUI.differentialRender(termContext, oldBufferCanvas, newBufferCanvas)
    assert(type(termContext) == "table", "termContext must be a table")
    assert(type(oldBufferCanvas) == "table", "oldBufferCanvas must be a table")
    assert(type(newBufferCanvas) == "table", "newBufferCanvas must be a table")

    if oldBufferCanvas.width == newBufferCanvas.width and oldBufferCanvas.height == newBufferCanvas.height then
        for y = 1, newBufferCanvas.height do
            for x = 1, newBufferCanvas.width do
                local oldChar = oldBufferCanvas.pixels[y][x]
                local newChar = newBufferCanvas.pixels[y][x]
                if oldChar ~= newChar then
                    termContext.setCursorPos(x, y)
                    termContext.write(newChar)
                end
            end
        end
    else
        TermUI.drawCanvas(termContext, newBufferCanvas, 1, 1)
    end
end

function TermUI.clear(termContext, char)
    for y = 1, termContext.height do
        termContext.setCursorPos(1, y)
        termContext.write(string.rep(char or " ", termContext.width))
    end
end

function TermUI.fillRect(termContext, x, y, width, height, char)
    for i = 1, height do
        termContext.setCursorPos(x, y + i - 1)
        termContext.write(string.rep(char or " ", width))
    end
end

return TermUI
