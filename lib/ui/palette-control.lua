PaletteControl = {}

function PaletteControl.new(state, tools)
    local self = {
        state = state,
        tools = tools
    }

    function self:update(input)

    end

    function self:render(texture)
        CanvasUI.writeLine(texture, 1, 1, "  PALETTE")
        CanvasUI.fillRect(texture, 1, 2, texture.width, 1, "-")
        for x, v in pairs(self.state.palette) do
            for y, c in pairs(v) do
                if self.tools[self.state.selectedTool].char == c then
                    Canvas.trySetPixel(texture, x - 1 - self.state.globalOffsetX, y - self.state.globalOffsetY, ">")
                    Canvas.trySetPixel(texture, x + 1 - self.state.globalOffsetX, y - self.state.globalOffsetY, "<")
                end
                Canvas.trySetPixel(texture, x - self.state.globalOffsetX, y - self.state.globalOffsetY, c)
            end
        end
    end

    return self
end
