Layout = {}

function Layout.rows(separator, ...)
    local rows = { ... }

    local self = {
        rows = rows,
        separator = separator,
    }

    function self:update(input)

    end

    function self:render(texture)
        local fixedHeight = 0
        local fillRowCount = 0
        for _, row in ipairs(self.rows) do
            if type(row[1]) == "number" then
                fixedHeight = fixedHeight + row[1]
            elseif row[1] == "fill" then
                fillRowCount = fillRowCount + 1
            else
                error("Invalid row type: " .. tostring(row[1]))
            end
        end
        if self.separator then
            fixedHeight = fixedHeight + #self.rows - 1
        end
        local remainingHeight = texture.height - fixedHeight

        local y = 1
        for i, row in ipairs(self.rows) do
            local rowHeight
            if type(row[1]) == "number" then
                rowHeight = row[1]
            else
                rowHeight = math.floor(remainingHeight / fillRowCount)
                fillRowCount = fillRowCount - 1
            end
            remainingHeight = remainingHeight - rowHeight
            local rowTexture = Canvas.new(texture.width, rowHeight)
            row[2]:render(rowTexture)
            CanvasUI.drawCanvas(texture, rowTexture, 1, y)
            y = y + rowHeight

            if self.separator and i < #self.rows then
                for x = 1, texture.width do
                    Canvas.trySetPixel(texture, x, y, self.separator)
                end
                y = y + 1
                remainingHeight = remainingHeight - 1
            end
        end
    end

    return self
end

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
