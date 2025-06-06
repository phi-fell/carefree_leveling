local input = require('openmw.input')
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local v2 = util.vector2

local PREFIX = 'PCL'
local NAME = 'Phi\'s Carefree Leveling'

I.Settings.registerPage {
    key = PREFIX,
    l10n = PREFIX,
    name = NAME,
    description = NAME .. " settings",
}

I.Settings.registerGroup {
    key = PREFIX .. 'SettingsActivate',
    l10n = PREFIX,
    page = PREFIX,
    order = 1,
    name = 'Activate',
    permanentStorage = false,
    settings = {
        {
            key = 'activated',
            renderer = 'singleUseButton',
            name = 'Activate Manually',
            description = 'If needed, you can click this button to activate PCL for this character after character creation is completed.  Note that this is PERMANENT, and PCL will not attempt to optimize skill/attribute gains that occurred before activation.',
            default = 0,
        },
    },
}

I.Settings.registerGroup {
    key = PREFIX .. 'SettingsControls',
    l10n = PREFIX,
    page = PREFIX,
    name = 'Controls',
    permanentStorage = false,
    settings = {
        {
            key = 'status_key',
            renderer = 'inputKeySelection',
            name = 'Toggle Status Key',
            description = 'When pressed, this key brings up a little status menu showing banked attribute points and such.',
            default = input.KEY.P,
        },
    },
}

I.Settings.registerGroup {
    key = PREFIX .. 'SettingsUI',
    l10n = PREFIX,
    page = PREFIX,
    name = 'UI',
    permanentStorage = false,
    settings = {
        {
            key = 'status_vertical',
            renderer = 'number',
            name = 'Status Vertical Alignment',
            description = 'Aligns the status window vertically.  0 is top of the screen, 1 is bottom, 0.5 is centered vertically',
            default = 0,
        },
        {
            key = 'status_horizontal',
            renderer = 'number',
            name = 'Status Horizontal Alignment',
            description = 'Aligns the status window horizontally.  0 is left side of the screen, 1 is right side, 0.5 is centered horizontally',
            default = 1,
        },
    },
}

I.Settings.registerGroup {
    key = PREFIX .. 'SettingsMisc',
    l10n = PREFIX,
    page = PREFIX,
    name = 'Misc',
    permanentStorage = false,
    settings = {
        -- In vanilla Morrowind, health starts as the average of endurance and strength and you gain one 10th of your *current* endurance each level.
        -- This means that to have the most health at a given level, you need to prioritize leveling endurance x5 every level until it is capped,
        -- which may not be fun or fit your character's archetype.
        -- Instead, when this setting is enabled, maximum health will be recalculated on each level up to be the amount you would have gotten if you
        -- had prioritized leveling up endurance +5 every level until it reached your current endurance value.
        -- This is to say, with this on, two characters at the same level, with the same endurance
        -- (and the same starting endurance and starting strength) will have the same health regardless of the *order* in which they raised their attributes
        -- (and will have the same health as a vanilla morrowind character who carefully prioritized
        -- their endurance gain at early levels rather than waiting to increase it until later),
        {
            key = 'retroactive_health',
            renderer = 'checkbox',
            name = 'Retroactive Health',
            description = 'When enabled, on each level up your health will be recalculated to be what it would have been if you had your current endurance, but had prioritized raising it in early levels.',
            default = true,
        },
        -- if true, will check for levelups where less than 3 attributes increase
        -- (this would occur if a chosen attribute is capped)
        -- in this case, the extra points will go to luck
        --
        -- e.g. if a character is at a high level and has capped all attributes except luck,
        -- then on a levelup they might select Luck, Strength, Speed
        -- because Strength and Speed are capped, they would not change,
        -- so this mod would add 2 extra points to luck to account for this. (1 for strength, 1 for speed)
        {
            key = 'retroactive_luck',
            renderer = 'checkbox',
            name = 'Retroactive Luck',
            description = 'When enabled, once one or more attributes are maxed - choosing them on a level up (which would normally be a waste) will instead put an extra point (or 2) into luck.  This lets you avoid needing to put 1 point into luck every level without fear that you will waste attribute points later on once you\'ve maxed all non-luck attributes.',
            default = true,
        },
        -- change this to get more luck on levelups
        -- if you increase this above 1, you may wish to disable retroactive_luck
        {
            key = 'luck_multiplier',
            renderer = 'select',
            name = 'Luck Multiplier',
            description = 'A Multiplier to luck gain on level ups.  Since no skills are governed by luck you can normally only gain +1 luck on a level.  Change this value to increase that.  Note that it is recommended to disable Retroactive Luck if you increase this above 1.',
            default = ' 1 ',
            argument = {
                l10n = PREFIX,
                items = { ' 1 ', ' 2 ', ' 3 ', ' 4 ', ' 5 ' },
            },
        },
        -- Changes how much attribute aps increase when selected during a level up
        {
            key = 'attribute_cap_increase',
            renderer = 'select',
            name = 'Attribute Cap Increase On Level Up',
            description = 'How much attribute caps (other than luck) increase when selected during a level up.  Recommended to leave this at 5',
            default = ' 5 ',
            argument = {
                l10n = PREFIX,
                items = { ' 1 ', ' 2 ', ' 3 ', ' 4 ', ' 5 ', ' 6 ', ' 7 ', ' 8 ', ' 9 ', ' 10 ' },
            },
        },
    },
}

return {
    -- We use 0,1,2 for activated because otherwise the setting can persist in wierd ways if you load a file from the same character
    set_activated = function(val)
        local n = 0
        if val then
            n = 1
        end
        storage.playerSection(PREFIX .. 'SettingsActivate'):set('activated', n)
    end,
    get_activated = function()
        return storage.playerSection(PREFIX .. 'SettingsActivate'):get('activated') == 2
    end,
    status_key = function()
        return storage.playerSection(PREFIX .. 'SettingsControls'):get('status_key')
    end,
    status_alignment = function()
        local ui_settings = storage.playerSection(PREFIX .. 'SettingsUI')
        return v2(ui_settings:get('status_horizontal'), ui_settings:get('status_vertical'))
    end,
    luck_multiplier = function()
        -- I cannot explain why this is necessary but without an intermediate variable, tonumber can return nil
        local mul = storage.playerSection(PREFIX .. 'SettingsMisc'):get('luck_multiplier'):gsub("%s+", "")
        return tonumber(mul)
    end,
    attribute_cap_increase = function()
        -- I cannot explain why this is necessary but without an intermediate variable, tonumber can return nil
        local inc = storage.playerSection(PREFIX .. 'SettingsMisc'):get('attribute_cap_increase'):gsub("%s+", "")
        return tonumber(inc)
    end,
    retroactive_luck = function()
        return storage.playerSection(PREFIX .. 'SettingsMisc'):get('retroactive_luck')
    end,
    retroactive_health = function()
        return storage.playerSection(PREFIX .. 'SettingsMisc'):get('retroactive_health')
    end,
}
