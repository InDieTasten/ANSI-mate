ToolControl = {}

local pencil = 1
local eraser = 2
local rectangle = 3
local fill = 4
local globalFill = 5

function ToolControl.new(state, tools)
    local self = {
        tools = tools,
        state = state
    }

    function self:update(input)
        if input.type == "char" then
            if input.char == "1" or input.char == "p" then
                self.state.selectedTool = pencil
                return true
            elseif input.char == "2" or input.char == "e" then
                self.state.selectedTool = eraser
                return true
            elseif input.char == "3" or input.char == "r" then
                self.state.selectedTool = rectangle
                return true
            elseif input.char == "4" or input.char == "f" then
                self.state.selectedTool = fill
                return true
            elseif input.char == "5" or input.char == "F" then
                self.state.selectedTool = globalFill
                return true
            end
        end
        return false
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
