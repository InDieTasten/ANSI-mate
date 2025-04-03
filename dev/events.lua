require("../lib/term")

local lastInputs = {}

local function formatTable(tbl)
    local str = "{ "
    local kvps = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            v = formatTable(v)
        elseif type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        local kvp = k .. " = " .. tostring(v)
        table.insert(kvps, kvp)
    end
    str = str .. table.concat(kvps, ", ") .. " }"
    return str
end
local function formatEvent(event)
    return formatTable(event)
end

local function update(inputs)
    if #inputs > 0 then
        lastInputs = inputs
    end

    for _, input in ipairs(inputs) do
        if input.type == "char" and input.char == "q" then
            return false
        end
    end

    return true
end

local function render(targetCanvas)
    -- Clear the target canvas
    for y = 1, targetCanvas.height do
        for x = 1, targetCanvas.width do
            Canvas.setPixel(targetCanvas, x, y, " ")
        end
    end

    -- Render the last inputs
    local line = 1
    Canvas.setPixel(targetCanvas, 1, line, "Last inputs: ")
    line = line + 1
    for _, event in ipairs(lastInputs) do
        local eventStr = formatEvent(event)
        for i = 1, #eventStr do
            Canvas.setPixel(targetCanvas, i, line, eventStr:sub(i, i))
        end
        line = line + 1
    end
end

Term.runApp(update, render)
