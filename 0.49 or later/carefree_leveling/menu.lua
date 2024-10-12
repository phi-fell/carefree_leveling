local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

I.Settings.registerRenderer('inputKeySelection', function(value, set)
    local name = 'No Key Set'
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = name,
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                set(e.code)
                            end),
                        },
                    },
                },
            },
        },

    }
end)

I.Settings.registerRenderer('singleUseButton', function(value, set, arg)
    -- This is commented out because the value persists wierdly, even though it's being set repeatedly
    --
    -- if value > 0 then
    --     return {
    --         template = I.MWUI.templates.textHeader,
    --         props = {
    --             text = 'Already Active',
    --         },
    --     }
    -- end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = 'Activate Manually',
                        },
                        events = {
                            mouseClick = async:callback(function(e)  
                                -- We use 0,1,2 for activated because otherwise the setting can persist in wierd ways if you load a file from the same character
                                set(2)
                            end),
                        },
                    },
                },
            },
        },
    }
end)