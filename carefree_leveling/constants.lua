local util = require('openmw.util')

local MW_TEXT_COLOR = util.color.rgb(202 / 255, 165 / 255, 96 / 255)

local FONT_SIZE = 16
local LINE_SPACING = 2
local LINE_HEIGHT = FONT_SIZE + LINE_SPACING
local BORDER_SIZE = 4

return {
    FONT_SIZE = FONT_SIZE,
    LINE_SPACING = LINE_SPACING,
    LINE_HEIGHT = LINE_HEIGHT,
    BORDER_SIZE = BORDER_SIZE,
    STANDARD_TEXT_COLOR = MW_TEXT_COLOR,
}