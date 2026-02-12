Layout = {}

function Layout.columns(separator, ...)
    local columns = { ... }

    local self = {
        columns = columns,
        separator = separator,
    }

    function self:update(input)

    end

    function self:render(texture)
        local fixedWidth = 0
        local fillColumnCount = 0
        for _, column in ipairs(self.columns) do
            if type(column[1]) == "number" then
                fixedWidth = fixedWidth + column[1]
            elseif column[1] == "fill" then
                fillColumnCount = fillColumnCount + 1
            else
                error("Invalid column type: " .. tostring(column[1]))
            end
        end
        if self.separator then
            fixedWidth = fixedWidth + #self.columns - 1
        end
        local remainingWidth = texture.width - fixedWidth

        local x = 1
        for i, col in ipairs(self.columns) do
            local colWidth
            if type(col[1]) == "number" then
                colWidth = col[1]
            else
                colWidth = math.floor(remainingWidth / fillColumnCount)
                fillColumnCount = fillColumnCount - 1
            end
            remainingWidth = remainingWidth - colWidth
            local colTexture = Canvas.new(colWidth, texture.height)
            col[2]:render(colTexture)
            CanvasUI.drawCanvas(texture, colTexture, x, 1)
            x = x + colWidth

            if self.separator and i < #self.columns then
                for y = 1, texture.height do
                    Canvas.trySetPixel(texture, x, y, self.separator)
                end
                x = x + 1
                remainingWidth = remainingWidth - 1
            end
        end
    end

    return self
end

function Layout.none()
    local self = {}

    function self:update(input)

    end

    function self:render(texture)

    end

    return self
end
