local TermUI = require("lib.term-ui")
local Canvas = require("lib.canvas")

describe("TermUI", function()
    describe("drawCanvas", function()
        it("should draw the canvas on the terminal context", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end)
            }
            local canvas = {
                width = 3,
                height = 2,
                pixels = {
                    { "A", "B", "C" },
                    { "D", "E", "F" }
                }
            }
            TermUI.drawCanvas(termContext, canvas, 1, 1)
            assert.stub(termContext.setCursorPos).was.called_with(1, 1)
            assert.stub(termContext.write).was.called_with("ABC")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("DEF")
        end)
    end)

    describe("clear", function()
        it("should clear the terminal context with the specified character", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end),
                width = 3,
                height = 2
            }
            TermUI.clear(termContext, "X")
            assert.stub(termContext.setCursorPos).was.called_with(1, 1)
            assert.stub(termContext.write).was.called_with("XXX")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("XXX")
        end)
    end)

    describe("fillRect", function()
        it("should fill the specified rectangle with the given character", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end)
            }
            TermUI.fillRect(termContext, 1, 1, 3, 2, "X")
            assert.stub(termContext.setCursorPos).was.called_with(1, 1)
            assert.stub(termContext.write).was.called_with("XXX")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("XXX")
        end)
    end)

    describe("flipScreenBuffer", function()
        it("should call drawCanvas when no previous buffer exists", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end),
                previousBufferCanvas = nil
            }
            local canvas = {
                width = 2,
                height = 2,
                pixels = {
                    { "A", "B" },
                    { "C", "D" }
                }
            }

            TermUI.flipScreenBuffer(termContext, canvas)

            assert.stub(termContext.setCursorPos).was.called_with(1, 1)
            assert.stub(termContext.write).was.called_with("AB")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("CD")
            assert.is_not_nil(termContext.previousBufferCanvas)
        end)

        it("should call differentialRender when previous buffer exists", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end),
                previousBufferCanvas = {
                    width = 2,
                    height = 2,
                    pixels = {
                        { "A", "B" },
                        { "C", "D" }
                    }
                }
            }
            local newCanvas = {
                width = 2,
                height = 2,
                pixels = {
                    { "A", "X" },
                    { "C", "Y" }
                }
            }

            TermUI.flipScreenBuffer(termContext, newCanvas)

            -- Should only update changed pixels
            assert.stub(termContext.setCursorPos).was.called_with(2, 1)
            assert.stub(termContext.write).was.called_with("X")
            assert.stub(termContext.setCursorPos).was.called_with(2, 2)
            assert.stub(termContext.write).was.called_with("Y")
            assert.is_not_nil(termContext.previousBufferCanvas)
        end)

        it("should store a copy of the new buffer canvas", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end),
                previousBufferCanvas = nil
            }
            local canvas = Canvas.new(2, 2)
            Canvas.setPixel(canvas, 1, 1, "A")

            TermUI.flipScreenBuffer(termContext, canvas)

            -- Modify original canvas
            Canvas.setPixel(canvas, 1, 1, "B")

            -- Previous buffer should still have original value
            assert.are.equal("A", termContext.previousBufferCanvas.pixels[1][1])
        end)
    end)

    describe("differentialRender", function()
        it("should only update changed pixels when canvas dimensions are the same", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end)
            }
            local oldCanvas = {
                width = 3,
                height = 2,
                pixels = {
                    { "A", "B", "C" },
                    { "D", "E", "F" }
                }
            }
            local newCanvas = {
                width = 3,
                height = 2,
                pixels = {
                    { "A", "X", "C" },
                    { "Y", "E", "Z" }
                }
            }

            TermUI.differentialRender(termContext, oldCanvas, newCanvas)

            -- Should only update changed pixels (B->X, D->Y, F->Z)
            assert.stub(termContext.setCursorPos).was.called_with(2, 1)
            assert.stub(termContext.write).was.called_with("X")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("Y")
            assert.stub(termContext.setCursorPos).was.called_with(3, 2)
            assert.stub(termContext.write).was.called_with("Z")

            -- Should not update unchanged pixels
            assert.stub(termContext.setCursorPos).was.not_called_with(1, 1)
            assert.stub(termContext.setCursorPos).was.not_called_with(3, 1)
            assert.stub(termContext.setCursorPos).was.not_called_with(2, 2)
        end)

        it("should call drawCanvas when canvas dimensions differ", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end)
            }
            local oldCanvas = {
                width = 2,
                height = 2,
                pixels = {
                    { "A", "B" },
                    { "C", "D" }
                }
            }
            local newCanvas = {
                width = 3,
                height = 2,
                pixels = {
                    { "A", "B", "C" },
                    { "D", "E", "F" }
                }
            }

            TermUI.differentialRender(termContext, oldCanvas, newCanvas)

            -- Should redraw entire canvas when dimensions differ
            assert.stub(termContext.setCursorPos).was.called_with(1, 1)
            assert.stub(termContext.write).was.called_with("ABC")
            assert.stub(termContext.setCursorPos).was.called_with(1, 2)
            assert.stub(termContext.write).was.called_with("DEF")
        end)

        it("should handle empty canvases", function()
            local termContext = {
                setCursorPos = spy.new(function() end),
                write = spy.new(function() end)
            }
            local oldCanvas = {
                width = 1,
                height = 1,
                pixels = { { " " } }
            }
            local newCanvas = {
                width = 1,
                height = 1,
                pixels = { { " " } }
            }

            TermUI.differentialRender(termContext, oldCanvas, newCanvas)

            -- Should not make any calls when both canvases are identical
            assert.stub(termContext.setCursorPos).was.not_called()
            assert.stub(termContext.write).was.not_called()
        end)
    end)
end)
