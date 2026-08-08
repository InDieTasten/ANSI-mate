ToolControl = {}

function ToolControl.new(state, tools)
    local self = {
        tools = tools,
        state = state
    }

    function self:update(input)

    end

    function self:render(texture)
        CanvasUI.writeLine(texture, 1, 1, "   TOOLS")
        CanvasUI.fillRect(texture, 1, 2, texture.width, 1, "-")
        for i, tool in ipairs(self.tools) do
            local toolLine = ""
            if i == self.state.selectedTool then
                toolLine = "> "
            else
                toolLine = "  "
            end
            CanvasUI.writeLine(texture, 1, i + 2, toolLine .. tool.name)
        end
    end

    return self
end
