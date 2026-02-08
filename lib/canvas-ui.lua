CanvasUI = {}

function CanvasUI.drawCanvas(targetCanvas, canvas, x, y)
    for i = 1, canvas.height do
        for j = 1, canvas.width do
            local char = canvas.pixels[i][j]
            Canvas.trySetPixel(targetCanvas, x + j - 1, y + i - 1, char)
        end
    end
end

function CanvasUI.clear(targetCanvas, char)
    for y = 1, targetCanvas.height do
        for x = 1, targetCanvas.width do
            Canvas.setPixel(targetCanvas, x, y, char or " ")
        end
    end
end

function CanvasUI.fillRect(targetCanvas, x, y, width, height, char)
    for i = 1, height do
        for j = 1, width do
            Canvas.trySetPixel(targetCanvas, x + j - 1, y + i - 1, char or " ")
        end
    end
end

function CanvasUI.writeLine(targetCanvas, x, y, text)
    for i = 1, #text do
        local char = text:sub(i, i)
        Canvas.trySetPixel(targetCanvas, x + i - 1, y, char)
    end
end

return CanvasUI
