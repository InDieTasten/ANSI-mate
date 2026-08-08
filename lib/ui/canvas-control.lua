CanvasControl = {}

function CanvasControl.new(state, tools, rectangle)
    local self = {
        state = state,
        tools = tools,
        rectangle = rectangle
    }

    function self:drawOverlayPixel(texture, x, y, char)
        local posX = x + self.state.canvasX
        local posY = y + self.state.canvasY

        Canvas.trySetPixel(texture, posX, posY, char)
    end

    function self:update(input)

    end

    function self:render(texture)
        --canvas area
        CanvasUI.clear(texture, "+")
        CanvasUI.drawCanvas(texture, self.state.artCanvas, self.state.canvasX + 1, self.state.canvasY + 1)
        -- --current tool overlay
        if self.state.selectedTool == self.rectangle and self.tools[self.rectangle].start and self.tools[self.rectangle].fin then
            local x1, y1 = self.tools[self.rectangle].start[1], self.tools[self.rectangle].start[2]
            local x2, y2 = self.tools[self.rectangle].fin[1], self.tools[self.rectangle].fin[2]
            local xMin, xMax = math.min(x1, x2), math.max(x1, x2)
            local yMin, yMax = math.min(y1, y2), math.max(y1, y2)
            for x = xMin, xMax do
                self:drawOverlayPixel(texture, x, yMin, self.tools[self.rectangle].char)
                self:drawOverlayPixel(texture, x, yMax, self.tools[self.rectangle].char)
            end
            for y = yMin, yMax do
                self:drawOverlayPixel(texture, xMin, y, self.tools[self.rectangle].char)
                self:drawOverlayPixel(texture, xMax, y, self.tools[self.rectangle].char)
            end
        end
        Canvas.trySetPixel(texture,
            self.state.canvasX + self.state.artCanvas.width + 1,
            self.state.canvasY + self.state.artCanvas.height + 1,
            "%")
    end

    return self
end
