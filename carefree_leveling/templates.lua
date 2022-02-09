local ui = require('openmw.ui')
local util = require('openmw.util')

local constants = require('carefree_leveling.constants')

local BORDER_SIZE = constants.BORDER_SIZE

local v00 = util.vector2(0, 0)
local v01 = util.vector2(0, 1)
local v10 = util.vector2(1, 0)
local v11 = util.vector2(1, 1)

local function border(name)
    local is_h = false
    if name == 'top' or name == 'bottom' then
        is_h = true
    end

    local s = util.vector2(BORDER_SIZE, -2 * BORDER_SIZE)
    if is_h then
        s = util.vector2(-2 * BORDER_SIZE, BORDER_SIZE)
    end
    local rs = v01
    if is_h then
        rs = v10
    end
    local p = util.vector2(0, BORDER_SIZE)
    if is_h then
        p = util.vector2(BORDER_SIZE, 0)
    end
    local rpx = 0
    local rpy = 0
    if name == 'right' then
        rpx = 1
    end
    if name == 'bottom' then
        rpy = 1
    end
    local rp = util.vector2(rpx, rpy)
    local a = rp
    local props = {
        path = 'textures/menu_thin_border_' .. name .. '.dds',
        size = s,
        relativeSize = rs,
        position = p,
        relativePosition = rp,
        anchor = a,
    }
    if is_h then
        props.tileH = true
    else
        props.tileV = true
    end

    local bt = {
        props = props,
    }

    return {
        type = ui.TYPE.Image,
        template = bt,
    }
end

local function corner(v, h)
    local rpx = 0
    local rpy = 0
    if h == 'right' then
        rpx = 1
    end
    if v == 'bottom' then
        rpy = 1
    end
    local rp = util.vector2(rpx, rpy)
    local a = rp

    local ct = {
        props = {
            path = 'textures/menu_thin_border_' .. v .. '_' .. h .. '_corner.dds',
            size = util.vector2(BORDER_SIZE, BORDER_SIZE),
            relativeSize = v00,
            position = v00,
            relativePosition = rp,
            anchor = a,
        },
    }

    return {
        type = ui.TYPE.Image,
        template = ct,
    }
end

local function slot(inset)
    return {
        external = {
            slot = true,
        },
        props = {
            position = util.vector2(inset, inset),
            size = util.vector2(-2 * inset, -2 * inset),
            relativeSize = v11,
        },
    }
end

local function background(rs)
    return {
        template = {
            skin = 'BlackBG',
            props = {
                relativeSize = rs,
            },
        }
    }
end

return {
    window = {
        content = ui.content {
            {
                props = {
                    relativeSize = v11,
                },
                content = ui.content {
                    background(v11),
                    border('top'),
                    border('bottom'),
                    border('left'),
                    border('right'),
                    corner('top', 'left'),
                    corner('top', 'right'),
                    corner('bottom', 'left'),
                    corner('bottom', 'right'),
                    slot(BORDER_SIZE),
                }
            },
            {
                props = {
                    relativeSize = v11,
                },
                external = {
                    action = true,
                    move = v11,
                    resize = v00,
                },
            },
        },
    },
    text = {
        props = {
            textSize = constants.FONT_SIZE,
            textColor = constants.STANDARD_TEXT_COLOR,
        },
    },
}
