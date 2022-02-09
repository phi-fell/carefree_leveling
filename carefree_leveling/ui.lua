local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')

local constants = require('carefree_leveling.constants')
local templates = require('carefree_leveling.templates')

-- Text feed variables
local text_feed_lines = nil
local text_feed_rpy = nil
local text_feed_offset_x = nil
local text_feed_offset_y = nil
-- Start a new text feed, from the top
local function new_text_feed(rpy, x, y)
    text_feed_lines = 0
    text_feed_rpy = rpy
    text_feed_offset_x = x
    text_feed_offset_y = y
end
-- Text is on same line as previous
local function same_line_a(t, rpx, a)
    return {
        type = ui.TYPE.Text,
        template = templates.text,
        props = {
            position = util.vector2(text_feed_offset_x * (0.5 - rpx) * 2, text_feed_offset_y + (text_feed_lines * constants.LINE_HEIGHT)),
            relativePosition = util.vector2(rpx, text_feed_rpy),
            anchor = util.vector2(a, 0),
            text = t,
        },
    }
end
local function same_line(t, a)
    return same_line_a(t, a, a)
end
local function same_line_l(t)
    return same_line(t, 0)
end
local function same_line_c(t)
    return same_line(t, 0.5)
end
local function same_line_r(t)
    return same_line(t, 1)
end
-- Text starts a new line
local function new_line(t, a)
    text_feed_lines = text_feed_lines + 1
    return same_line(t, a)
end
local function new_line_l(t)
    return new_line(t, 0)
end
local function new_line_c(t)
    return new_line(t, 0.5)
end
local function new_line_r(t)
    return new_line(t, 1)
end
-- Text start a new feed
local function start_feed(rpx, rpy, x, y, t)
    new_text_feed(rpy, x, y)
    return same_line(t, rpx)
end
local function start_feed_l(rpy, x, y, t)
    new_text_feed(rpy, x, y)
    return same_line_l(t)
end
local function start_feed_c(rpy, x, y, t)
    new_text_feed(rpy, x, y)
    return same_line_c(t)
end
local function start_feed_r(rpy, x, y, t)
    new_text_feed(rpy, x, y)
    return same_line_r(t)
end

-- State variables
local set_pos = nil
local status_layout = nil
local status_element = nil
local attribute_data = nil

local function update_pos()
    if set_pos then
        status_layout.props.position = set_pos
        status_layout.props.anchor = nil
        status_layout.props.relativePosition = nil
    end
end

local function update_size()
    status_layout.props.size = util.vector2(status_layout.props.size.x, ((text_feed_lines + 1) * constants.LINE_HEIGHT) + (constants.BORDER_SIZE * 4))
end

local function reset_status_layout()
    local content = {
        start_feed_l(0, constants.BORDER_SIZE, constants.BORDER_SIZE, 'Character creation'),
        new_line_l('in progress...')
    }
    if attribute_data then
        local attr_count = 0
        content = {
            start_feed_l(0, constants.BORDER_SIZE, constants.BORDER_SIZE, 'Attribute'),
            same_line_a('Queued', 0.65, 1),
            same_line_r('Skillups'),
        }
        for _, attr in ipairs(attribute_data) do
            if attr.owed ~= 0 or attr.skillups ~= 0 then
                attr_count = attr_count + 1
                table.insert(content, new_line_l(attr.name:gsub("^%l", string.upper)))
                table.insert(content, same_line_a('+'..attr.owed, 0.65, 1))
                table.insert(content, same_line_r(''..attr.skillups))
            end
        end
        if attr_count == 0 then
            content = {
                start_feed_c(0, constants.BORDER_SIZE, constants.BORDER_SIZE, 'You\'re all caught up!'),
                new_line_c('You don\'t have any skill ups,'),
                new_line_c('or banked attribute points.'),
            }
        end
    end
    status_layout = {
        layer = 'Windows',
        type = ui.TYPE.Window,
        template = templates.window,
        props = {
            position = util.vector2(0, 0),
            relativePosition = util.vector2(1, 0),
            anchor = util.vector2(1, 0),
            size = util.vector2(220, 40),
        },
        events = {
            windowDrag = async:callback(function(coord, layout)
                set_pos = coord.position
                layout.props.position = set_pos
                layout.props.anchor = nil
                layout.props.relativePosition = nil
            end),
        },
        content = ui.content(content),
    }
    update_pos()
    update_size()
end


local function show_status() 
    reset_status_layout()
    status_element = ui.create(status_layout)
end
local function hide_status() 
    status_element:destroy()
    status_element = nil
end
local function update_status()
    if not status_element then
        return
    end
    hide_status()
    show_status()
end

return {
    save = function ()
        return {
            show_status = status_element ~= nil,
            set_pos = set_pos,
        }
    end,
    load = function (data)
        set_pos = data.set_pos
        if data.show_status then
            show_status()
        end
    end,
    toggle_status = function()
        if status_element then
            hide_status()
        else
            show_status()
        end
    end,
    update_status_vars = function(v)
        attribute_data = v
        update_status()
    end,
}
