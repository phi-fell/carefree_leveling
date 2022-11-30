local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local self = require('openmw.self')

-- SETTINGS

-- when pressed, this key brings up a little status menu
-- for a full list of available keys, see https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_input.html##(KEY)
local status_key = input.KEY.P

-- change the 1 to a 5 to be able to get 5 luck on levelups (2, 3, or 4 will also work)
-- if you increase this above 1, you may wish to disable retroactive_luck
local luck_multiplier = 1

-- if true, max health will be recaclulated on levelups to be the amount you would have gotten if you
--  had leveled up endurance +5 every level until it reached your current endurance value.
--
-- this is to say, with this on, two characters at the same level, with the same endurance
-- (and the same starting endurance and starting strength) will have the same health
local retroactive_health = true

-- if true, will check for levelups where less than 3 attributes increase
-- (this would occur if a chosen attribute is capped)
-- in this case, the extra points will go to luck
--
-- e.g. if a character is at a high level and has capped all attributes except luck,
-- then on a levelup they might select Luck, Strength, Speed
-- because Strength and Speed are capped, they would not change,
-- so this mod would add 2 extra points to luck to account for this. (1 for strength, 1 for speed)
local retroactive_luck = true

-- MAIN SCRIPT BODY

local function handle_error(e)
    ui.showMessage('Err: ' .. tostring(e))
end

local function try(f)
    xpcall(f, handle_error)
end

local status_ui = require('carefree_leveling.ui')

local scriptVersion = 0

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
            self.stats[attr].base = self.stats[attr].base + 1
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
            msg = msg .. " to " .. self.stats[attr].base
        end
        cached_attributes[attr] = self.stats[attr].base
        if retroactive_luck then
            while self.stats.luck.base + luck_multiplier <= 100 and self.stats[attr].base + attribute_points_owed[attr] >= 105 do
                attribute_points_owed[attr] = attribute_points_owed[attr] - 5
                self.stats.luck.base = self.stats.luck.base + luck_multiplier
                lpts = lpts + luck_multiplier
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
        msg = msg .. " to " .. self.stats.luck.base
    end
    ui.showMessage(msg)
    if retroactive_health then
        local h = (starting_strength + starting_endurance) / 2
        local l = 1
        local e = starting_endurance
        while l < self.stats.level.current do
            if e + 5 < self.stats.endurance.base then
                e = e + 5
            else
                e = self.stats.endurance.base
            end
            h = h + (e / 10)
            l = l + 1
        end
        self.stats.health.base = h
    end
end

local function cache_attributes()
    if cached_attributes == nil then
        cached_attributes = {}
    end
    for _, attribute in ipairs(attributes) do
        cached_attributes[attribute] = self.stats[attribute].base
    end
end

local function cache_skills()
    if cached_skills then
        for _, skill in ipairs(skills) do
            local dif = self.stats[skill].base - cached_skills[skill]
            if dif > 0 then
                cached_skills[skill] = self.stats[skill].base
                local a = governing_attribute[skill]
                attribute_skill_ups[a] = attribute_skill_ups[a] + dif
                increase_attributes_if_needed(0)
                update_status()
            end
        end
    else
        cached_skills = {}
        for _, skill in ipairs(skills) do
            cached_skills[skill] = self.stats[skill].base
        end
    end
end

local function init_player_stats()
    level = self.stats.level.current
    starting_endurance = self.stats.endurance.base
    starting_strength = self.stats.strength.base
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

    if not data or not data.version or data.version ~= scriptVersion then
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

    if key.code == status_key then
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
        if self.stats.level.current > level then
            level = self.stats.level.current
            local attrs_increased = 0
            local lpts = 0
            for _, attribute in ipairs(attributes) do
                local dif = self.stats[attribute].base - cached_attributes[attribute]
                if dif > 0 then
                    self.stats[attribute].base = self.stats[attribute].base - dif
                    if attribute == 'luck' then
                        self.stats.luck.base = self.stats.luck.base + luck_multiplier
                        lpts = lpts + luck_multiplier
                    else
                        attribute_points_owed[attribute] = attribute_points_owed[attribute] + 5
                    end
                    attrs_increased = attrs_increased + 1
                end
            end
            if retroactive_luck then
                while attrs_increased < 3 do
                    self.stats.luck.base = self.stats.luck.base + luck_multiplier
                    attrs_increased = attrs_increased + 1
                    lpts = lpts + luck_multiplier
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
