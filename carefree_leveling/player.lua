local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local settings = require('carefree_leveling.settings')

local function handle_error(e)
    ui.showMessage('Err: ' .. tostring(e))
end

local function try(f)
    xpcall(f, handle_error)
end

local status_ui = require('carefree_leveling.ui')

local scriptVersion = 1

local status_menu_element = nil

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

local skills = {
   'block',
   'armorer',
   'mediumarmor',
   'heavyarmor',
   'bluntweapon',
   'longblade',
   'axe',
   'spear',
   'athletics',
   'enchant',
   'destruction',
   'alteration',
   'illusion',
   'conjuration',
   'mysticism',
   'restoration',
   'alchemy',
   'unarmored',
   'security',
   'sneak',
   'acrobatics',
   'lightarmor',
   'shortblade',
   'marksman',
   'mercantile',
   'speechcraft',
   'handtohand',
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
local cached_skills = nil

-- General Functions

local function getCurrentLevel()
    return types.Player.stats.level(self).current
end

local function getSkillLevel(skill)
    return types.Player.stats.skills[skill](self).base
end
local function setSkillLevel(skill, val)
    types.Player.stats.skills[skill](self).base = val
end
local function modSkillLevel(skill, amnt)
    types.Player.stats.skills[skill](self).base = types.Player.stats.skills[skill](self).base + amnt
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
        while attribute_points_owed[attr] > 0 and attribute_skill_ups[attr] >= 2 do
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
        if settings.RETROACTIVE_LUCK then
            while getAttribute('luck') + settings.LUCK_MULTIPLIER <= 100 and getAttribute(attr) + attribute_points_owed[attr] >= 105 do
                attribute_points_owed[attr] = attribute_points_owed[attr] - 5
                modAttribute('luck', settings.LUCK_MULTIPLIER)
                lpts = lpts + settings.LUCK_MULTIPLIER
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
    if settings.RETROACTIVE_HEALTH then
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

local function cache_skills()
    if cached_skills then
        for _, skill in ipairs(skills) do
            local dif = getSkillLevel(skill) - cached_skills[skill]
            if dif > 0 then
                cached_skills[skill] = getSkillLevel(skill)
                local a = governing_attribute[skill]
                attribute_skill_ups[a] = attribute_skill_ups[a] + dif
                increase_attributes_if_needed(0)
                update_status()
            end
        end
    else
        cached_skills = {}
        for _, skill in ipairs(skills) do
            cached_skills[skill] = getSkillLevel(skill)
        end
    end
end

local function init_player_stats()
    level = getCurrentLevel()
    starting_endurance = getAttribute('endurance')
    starting_strength = getAttribute('strength')
    ui.showMessage('Carefree Leveling Initialized!')
    update_status()
end

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
        error(msg)
        ui.showMessage(msg)
        return
    end

    if not data.version then
        local msg = 'Warning: Carefree Leveling was saved with an unknown version of the script. Errors may occur.'
        error(msg)
        ui.showMessage(msg)
    end

    if data.version ~= scriptVersion then
        local msg = 'Warning: Carefree Leveling was saved with a different version of the script. Errors may occur.'
        error(msg)
        ui.showMessage(msg)
    end

    status_ui.load(data.ui)
    character_creation_complete = data.character_creation_complete
    level = data.level
    starting_endurance = data.starting_endurance
    starting_strength = data.starting_strength
    attribute_points_owed = data.attribute_points_owed
    attribute_skill_ups = data.attribute_skill_ups
    if character_creation_complete then
        update_status()
    end
end

local on_key_press_key = nil
local function onKeyPress()
    local key = on_key_press_key

    if key.code == settings.STATUS_KEY then
        status_ui.toggle_status()
    end
end

local on_update_dt = nil
local function onUpdate()
    local dt = on_update_dt

    if not character_creation_complete then
        if papers_present() then
            character_creation_complete = true
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
                        modAttribute('luck', settings.LUCK_MULTIPLIER)
                        lpts = lpts + settings.LUCK_MULTIPLIER
                    else
                        attribute_points_owed[attribute] = attribute_points_owed[attribute] + 5
                    end
                    attrs_increased = attrs_increased + 1
                end
            end
            if settings.RETROACTIVE_LUCK then
                while attrs_increased < 3 do
                    modAttribute('luck', settings.LUCK_MULTIPLIER)
                    attrs_increased = attrs_increased + 1
                    lpts = lpts + settings.LUCK_MULTIPLIER
                end
            end
            increase_attributes_if_needed(lpts)
            update_status()
        end
        cache_attributes()
        cache_skills()
    end
end

return {
    engineHandlers = {
        onSave = function()
            try(onSave)
        end,
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
