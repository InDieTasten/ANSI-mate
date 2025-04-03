local stty = require("lib/stty")
local Canvas = require("lib/canvas")

Term = {}
Term.internalInputBuffer = ""
Term.internalOutputBuffer = ""
Term.width = 0
Term.height = 0
Term.previousFrame = nil
Term.currentFrame = nil

--- Decodes mouse scroll, move, press and release events from xterm
--- according to DECSET 1006
function Term.decodeMouseEvent(functionalCode, x, y, action)
    local eventType
    local mods = {}
    if action == "m" then
        eventType = "mouse_release"
    elseif action == "M" then
        eventType = "mouse_press"
    end

    if functionalCode >= 64 then
        eventType = "mouse_scroll"
        functionalCode = functionalCode - 64
    elseif functionalCode >= 32 then
        eventType = "mouse_move"
        functionalCode = functionalCode - 32
    end

    if functionalCode >= 16 then
        mods.ctrl = true
        functionalCode = functionalCode - 16
    end
    if functionalCode >= 8 then
        mods.alt = true
        functionalCode = functionalCode - 8
    end
    if functionalCode >= 4 then
        mods.shift = true
        functionalCode = functionalCode - 4
    end

    local button = functionalCode
    if eventType == "mouse_scroll" then
        if functionalCode == 0 then
            return { type = eventType, x = x, y = y, mods = mods, dir = "up" }
        elseif functionalCode == 1 then
            return { type = eventType, x = x, y = y, mods = mods, dir = "down" }
        end
    elseif eventType == "mouse_move" and button == 3 then
        button = nil
    end

    return { type = eventType, x = x, y = y, mods = mods, button = button }
end

function Term.parseInput(inputText)
    local parsedInputs = {}
    if inputText == nil then
        return parsedInputs
    end
    local i = 1
    while i <= #inputText do
        local char = inputText:sub(i, i)
        local funcCode, x, y, action = inputText:match("^\27%[<(%d+);(%d+);(%d+)([Mm])", i)
        if funcCode then
            table.insert(parsedInputs, Term.decodeMouseEvent(tonumber(funcCode), tonumber(x), tonumber(y), action))
            i = i + #string.match(inputText, "^\27%[<%d+;%d+;%d+[Mm]", i)
        else
            if (string.byte(char) >= 32 and string.byte(char) <= 126) then
                table.insert(parsedInputs, { type = "char", char = char })
            else
                table.insert(parsedInputs, { type = "raw", hex = string.format("%02X", string.byte(char)) })
            end
            i = i + 1
        end
    end
    return parsedInputs
end

function Term.runApp(updateFunction, renderFunction)
    Term.enterRawMode()
    Term.enableMouseEvents()
    Term.hideCursor()
    local function main()
        local previousWidth
        local previousHeight
        while true do
            local inputText = Term.tryRead(1)
            if #Term.internalInputBuffer > 0 then
                inputText = inputText .. Term.read(#Term.internalInputBuffer)
            end
            local parsedInputs = Term.parseInput(inputText)

            if Term.width ~= previousWidth or Term.height ~= previousHeight then
                previousWidth = Term.width
                previousHeight = Term.height
                table.insert(parsedInputs, { type = "resize", width = Term.width, height = Term.height })
                Term.previousFrame = Canvas.new(Term.width, Term.height)
                Term.currentFrame = Canvas.new(Term.width, Term.height)
            end

            if not updateFunction(parsedInputs) then
                break
            end

            -- Render to the current frame
            renderFunction(Term.currentFrame)

            -- Perform diff between frames
            local diffs = Canvas.diff(Term.previousFrame, Term.currentFrame)

            -- Apply diffs to the terminal
            for _, diff in ipairs(diffs) do
                Term.setCursorPos(diff.x, diff.y)
                Term.write(diff.char)
            end

            -- Flush the output buffer
            Term.flush()

            -- Swap frames
            Term.previousFrame, Term.currentFrame = Term.currentFrame, Term.previousFrame
        end
    end

    local status = xpcall(main, function(err)
        Term.showCursor()
        Term.disableMouseEvents()
        Term.flush()
        Term.tryRead(1)
        Term.leaveRawMode()
        local traceback = debug.traceback()
        io.stderr:write(err .. "\n" .. traceback .. "\n")
        if os.getenv("DEBUG") == "1" then
            debug.debug()
        end
    end)

    if status then
        Term.showCursor()
        Term.disableMouseEvents()
        Term.flush()
        Term.tryRead(1)
        Term.leaveRawMode()
    end
end

--- Sets the cursor position to the specified coordinates
--- @param x number: X position of cursor (1 indexed)
--- @param y number: Y position of cursor (1 indexed)
function Term.setCursorPos(x, y)
    Term.write("\27[" .. tostring(y) .. ";" .. tostring(x) .. "H")
end

--- Hides the cursor
function Term.hideCursor()
    Term.write("\27[?25l")
end

--- Shows the cursor
function Term.showCursor()
    Term.write("\27[?25h")
end

--- Enters raw mode for the terminal
--- This will disable echo and line buffering
--- It will also switch to the alternate screen buffer
function Term.enterRawMode()
    stty.enableRawMode()
    stty.disableEcho()
    io.write("\27[?1049h")
    io.flush()
end

--- Leaves raw mode for the terminal
--- This will re-enable echo and line buffering
--- It will also switch back to the main screen buffer
function Term.leaveRawMode()
    io.write("\27[?1049l")
    io.flush()
    stty.enableEcho()
    stty.disableRawMode()
end

--- Requests the cursor position from the terminal.
--- Terminal will respond with a sequence like `\27[<row>;<col>R`.
--- We capture the response from stdin and parse it.
--- If other input is received, it is stored in backlog for later processing.
--- @return number row: X position of cursor (0 indexed)
--- @return number col: Y position of cursor (0 indexed)
function Term.getCursorPosition()
    io.write("\27[6n")
    io.flush()
    local readBack = ""
    while true do
        local current = io.read(1)
        if #readBack > 0 or current == "\27" then
            readBack = readBack .. current
        else
            Term.internalInputBuffer = Term.internalInputBuffer .. current
        end
        if current == "R" then
            break
        end
        assert(#readBack < 1000, "Readback too long")
        assert(#Term.internalInputBuffer < 1000, "Backlog too long")
    end

    local row = tonumber(string.match(readBack, "%[(%d+);"))
    local col = tonumber(string.match(readBack, ";(%d+)"))

    assert(type(row) == "number", "Failed to parse row")
    assert(type(col) == "number", "Failed to parse col")

    return row, col
end

--- Reads n characters from the terminal
--- If there are characters in the backlog, they are used first
--- @param n number: number of characters to read
--- @return string input: input read from stdin
function Term.read(n)
    assert(n > 0, "n must be greater than 0")
    local input = ""
    if #Term.internalInputBuffer > 0 then
        input = input .. string.sub(Term.internalInputBuffer, 1, n)
        Term.internalInputBuffer = string.sub(Term.internalInputBuffer, n + 1)
    end
    if #input < n then
        input = input .. io.read(n - #input)
    end
    return input
end

--- Reads n characters from the stdin when input is available.
--- @param n number: number of characters to read
--- @return string? input: input read from string, or nil, if we ran into the specified timeout
function Term.tryRead(n)
    assert(n > 0, "n must be greater than 0")

    -- If we have enough characters in the backlog, we can return them immediately.
    if #Term.internalInputBuffer >= n then
        return Term.read(n)
    end

    -- Here we wait for the timeout to expire. This is the time frame in which users can queue up input.
    --os.execute("/bin/sleep " .. timeout)
    -- Before we try to read form the input buffer, we need to make sure we can receive something immediately, if the user has not queued anything up.
    -- We use the cursor position request for this.
    io.write("\27\55\27[999;999H\27[6n\27\56")
    io.flush()
    local buffer = ""
    local lastEscapeIndex
    while true do
        local current = io.read(1)
        buffer = buffer .. current
        if current == "\27" then
            lastEscapeIndex = #buffer
        end
        if lastEscapeIndex then
            local height, width = string.match(buffer, "\27%[(%d+);(%d+)R$", lastEscapeIndex)
            if height and width then
                Term.height = tonumber(height)
                Term.width = tonumber(width)
                Term.internalInputBuffer = Term.internalInputBuffer .. buffer:sub(1, lastEscapeIndex - 1)
                break
            end
        end
        assert(#buffer < 1000, "Readback too long: " .. buffer)
    end

    if #Term.internalInputBuffer < n then
        return nil
    else
        return Term.read(n)
    end
end

function Term.enableMouseEvents()
    Term.write("\27[?1000h")
    Term.write("\27[?1002h")
    Term.write("\27[?1003h")
    Term.write("\27[?1015h")
    Term.write("\27[?1006h")
    Term.flush()
end

function Term.disableMouseEvents()
    Term.write("\27[?1000l")
    Term.write("\27[?1002l")
    Term.write("\27[?1003l")
    Term.write("\27[?1015l")
    Term.write("\27[?1006l")
    Term.flush()
end

--- Allows to write to the output buffer without flushing it.
--- Useful to ensure that an entire rerenderd frame is queued in the buffer before flushing to the terminal.
--- Also, intermediate terminal requests can be made while building the frame without interfering with the output.
--- Be sure to call Term.flush() after you are done writing to the buffer.
--- @param str string: string to write to the output buffer
function Term.write(str)
    Term.internalOutputBuffer = Term.internalOutputBuffer .. str
end

--- Flushes the output buffer to the terminal.
--- This will write the entire buffer to the terminal and flush it.
function Term.flush()
    io.write(Term.internalOutputBuffer)
    io.flush()
    Term.internalOutputBuffer = ""
end

return Term
