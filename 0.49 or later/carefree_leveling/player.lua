local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local settings = require('carefree_leveling.settings')

local function handle_error(e)
    ui.showMessage('Err: ' .. tostring(e))
end

local function try(f)
    xpcall(f, handle_error)
end

local status_ui = require('carefree_leveling.ui')

local scriptVersion = 1

local attributes = {
    'strength',
    'intelligence',
    'willpower',
    'agility',
    'speed',
    'endurance',
    'personality',
    'luck',
}

local governing_attribute = {
    block = 'agility',
    armorer = 'strength',
    mediumarmor = 'endurance',
    heavyarmor = 'endurance',
    bluntweapon = 'strength',
    longblade = 'strength',
    axe = 'strength',
    spear = 'endurance',
    athletics = 'speed',
    enchant = 'intelligence',
    destruction = 'willpower',
    alteration = 'willpower',
    illusion = 'personality',
    conjuration = 'intelligence',
    mysticism = 'willpower',
    restoration = 'willpower',
    alchemy = 'intelligence',
    unarmored = 'speed',
    security = 'intelligence',
    sneak = 'agility',
    acrobatics = 'strength',
    lightarmor = 'agility',
    shortblade = 'speed',
    marksman = 'agility',
    mercantile = 'personality',
    speechcraft = 'personality',
    handtohand = 'speed',
}

local character_creation_complete = false
local starting_endurance = nil
local starting_strength = nil
local attribute_skill_ups = {}
local attribute_points_owed = {}

for _, attribute in ipairs(attributes) do
    attribute_skill_ups[attribute] = 0
    attribute_points_owed[attribute] = 0
end

local level = 1

local cached_attributes = nil

-- General Functions

local function getCurrentLevel()
    return types.Player.stats.level(self).current
end

local function getAttribute(attr)
    return types.Player.stats.attributes[attr](self).base
end
local function setAttribute(attr, val)
    types.Player.stats.attributes[attr](self).base = val
end
local function modAttribute(attr, amnt)
    types.Player.stats.attributes[attr](self).base = types.Player.stats.attributes[attr](self).base + amnt
end

local function setHealth(val)
    types.Player.stats.dynamic.health(self).base = val
end

local function update_attribute_multipliers()
    for _, attribute in ipairs(attributes) do
        local s = attribute_skill_ups[attribute]
        if attribute_points_owed[attribute] > 0 then
            s = 0
        end
        local mul = 0
        if s >= 10 then
            mul = 10
        elseif s >= 8 then
            mul = 8
        elseif s >= 6 then
            mul = 5
        elseif s >= 4 then
            mul = 1
        elseif s >= 2 then
            mul = 0
        end
        types.Player.stats.level(self).skillIncreasesForAttribute[attribute] = mul
    end
end

local function update_status()
    local v = {}
    for _, attribute in ipairs(attributes) do
        table.insert(v, {
            name = attribute,
            owed = attribute_points_owed[attribute],
            skillups = attribute_skill_ups[attribute],
        })
    end
    status_ui.update_status_vars(v)
end

local function papers_present()
    for _, item in ipairs(nearby.items) do
        if item.recordId == 'chargen statssheet' then
            return true
        end
    end
    return false
end

local function increase_attributes_if_needed(lpts)
    local msg = ""
    for _, attr in ipairs(attributes) do
        local pts = 0
        while getAttribute(attr) < 100 and attribute_points_owed[attr] > 0 and attribute_skill_ups[attr] >= 2 do
            modAttribute(attr, 1)
            attribute_points_owed[attr] = attribute_points_owed[attr] - 1
            attribute_skill_ups[attr] = attribute_skill_ups[attr] - 2
            pts = pts + 1
        end
        if pts > 0 then
            if msg ~= "" then
                msg = msg .. ", "
            end
            msg = msg .. attr:gsub("^%l", string.upper) .. " increased"
            if pts > 1 then
                msg = msg .. " (+" .. pts .. ")"
            end
            msg = msg .. " to " .. getAttribute(attr)
        end
        cached_attributes[attr] = getAttribute(attr)
        if settings.retroactive_luck() then
            while getAttribute('luck') < 100 and getAttribute(attr) + attribute_points_owed[attr] >= 105 do
                local luck_to_add = settings.luck_multiplier()
                local new_luck = getAttribute('luck') + settings.luck_multiplier()
                if new_luck > 100 then
                    luck_to_add = luck_to_add - (new_luck - 100)
                end
                attribute_points_owed[attr] = attribute_points_owed[attr] - 5
                modAttribute('luck', luck_to_add)
                lpts = lpts + luck_to_add
            end
        end
    end
    if lpts > 0 then
        if msg ~= "" then
            msg = msg .. ", "
        end
        msg = msg .. "Luck increased"
        if lpts > 1 then
            msg = msg .. " (+" .. lpts .. ")"
        end
        msg = msg .. " to " .. getAttribute('luck')
    end
    ui.showMessage(msg)
    if settings.retroactive_health() then
        local h = (starting_strength + starting_endurance) / 2
        local l = 1
        local e = starting_endurance
        while l < getCurrentLevel() do
            if e + 5 < getAttribute('endurance') then
                e = e + 5
            else
                e = getAttribute('endurance')
            end
            h = h + (e / 10)
            l = l + 1
        end
        setHealth(h)
    end
end

local function cache_attributes()
    if cached_attributes == nil then
        cached_attributes = {}
    end
    for _, attribute in ipairs(attributes) do
        cached_attributes[attribute] = getAttribute(attribute)
    end
end

local function init_player_stats()
    level = getCurrentLevel()
    starting_endurance = getAttribute('endurance')
    starting_strength = getAttribute('strength')
    ui.showMessage('Carefree Leveling Initialized!')
    update_status()
end

-- On skill increase

I.SkillProgression.addSkillLevelUpHandler(function(skillid, options)
    local a = governing_attribute[skillid]
    attribute_skill_ups[a] = attribute_skill_ups[a] + 1
    increase_attributes_if_needed(0)
    update_status()
end)

-- Engine Handlers

local function onSave()
    return {
        version = scriptVersion,
        ui = status_ui.save(),
        character_creation_complete = character_creation_complete,
        level = level,
        starting_endurance = starting_endurance,
        starting_strength = starting_strength,
        attribute_points_owed = attribute_points_owed,
        attribute_skill_ups = attribute_skill_ups,
    }
end

local on_load_data = nil
local function onLoad()
    local data = on_load_data

    if not data then
        local msg = 'Warning: Carefree Leveling save data is missing for this character.'
        ui.printToConsole(msg, ui.CONSOLE_COLOR.Error)
        ui.showMessage(msg)
        return
    end

    if not data.version then
        local msg = 'Warning: Carefree Leveling was saved with an unknown version of the script. Errors may occur.'
        ui.printToConsole(msg, ui.CONSOLE_COLOR.Error)
        ui.showMessage(msg)
    end

    if data.version ~= scriptVersion then
        local msg = 'Warning: Carefree Leveling was saved with a different version of the script. Errors may occur.'
        ui.printToConsole(msg, ui.CONSOLE_COLOR.Error)
        ui.showMessage(msg)
    end

    character_creation_complete = data.character_creation_complete
    level = data.level
    starting_endurance = data.starting_endurance
    starting_strength = data.starting_strength
    attribute_points_owed = data.attribute_points_owed
    attribute_skill_ups = data.attribute_skill_ups

    settings.set_activated(character_creation_complete)

    if character_creation_complete then
        update_status()
    end
end

local on_key_press_key = nil
local function onKeyPress()
    local key = on_key_press_key

    if key.code == settings.status_key() then
        status_ui.toggle_status()
    end
end

local on_update_dt = nil
local function onUpdate()
    local dt = on_update_dt

    if not character_creation_complete then
        if papers_present() or settings.get_activated() then
            character_creation_complete = true
            settings.set_activated(character_creation_complete)
            init_player_stats()
        end
    else
        if getCurrentLevel() > level then
            level = getCurrentLevel()
            local attrs_increased = 0
            local lpts = 0
            for _, attribute in ipairs(attributes) do
                local dif = getAttribute(attribute) - cached_attributes[attribute]
                if dif > 0 then
                    modAttribute(attribute, -dif)
                    if attribute == 'luck' then
                        modAttribute('luck', settings.luck_multiplier())
                        lpts = lpts + settings.luck_multiplier()
                    else
                        attribute_points_owed[attribute] = attribute_points_owed[attribute] +
                            settings.attribute_cap_increase()
                    end
                    attrs_increased = attrs_increased + 1
                end
            end
            if settings.retroactive_luck() then
                while attrs_increased < 3 do
                    local current = getAttribute('luck')
                    local mul = settings.luck_multiplier()
                    if current + mul > 100 then
                        mul = mul - ((current + mul) - 100)
                    end
                    if mul > 0 then
                        modAttribute('luck', mul)
                        lpts = lpts + mul
                    end
                    attrs_increased = attrs_increased + 1
                end
            end
            increase_attributes_if_needed(lpts)
            update_status()
        end
        cache_attributes()
        update_attribute_multipliers()
    end
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = function(data)
            on_load_data = data
            try(onLoad)
        end,
        onKeyPress = function(key)
            on_key_press_key = key
            try(onKeyPress)
        end,
        onUpdate = function(dt)
            on_update_dt = dt
            try(onUpdate)
        end,
    }
}
