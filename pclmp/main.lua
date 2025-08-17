-- SETTINGS
-- Edit these as needed

-- multiplier to luck gain (including retroactive luck if that's enabled)
-- it is reccomended to turn off retroactive luck if you increase this above 1
-- reccomended values: 1 (if retroactive luck is true) or 5 (if retroactive luck is false)
local LUCK_MULTIPLIER = 1

-- if true choosing a maxed attribute on levelup will increase luck instead (so you can get +2 or +3 luck on a single level up)
-- note that e.g. an attribute with 85 points in it, and 15 queued points from extra level ups will count as maxed
-- reccomended values: true or false
local RETROACTIVE_LUCK = true

-- if true, health will be recalculated as if one had gotten 5 endurance each level starting from level 1 until it reached its current value
-- if false, the vanilla behavior of getting current_endurance/10 health when you level up will occur
-- reccomended values: true or false
local RETROACTIVE_HEALTH = true

-- END OF SETTINGS



-- MAIN SCRIPT BODY

local pclmp = {
    scriptName = 'PCLMP',
}

-- CONSTANTS

local attributes = {
    'Strength',
    'Intelligence',
    'Willpower',
    'Agility',
    'Speed',
    'Endurance',
    'Personality',
    'Luck',
}

local skills = {
   'Block',
   'Armorer',
   'Mediumarmor',
   'Heavyarmor',
   'Bluntweapon',
   'Longblade',
   'Axe',
   'Spear',
   'Athletics',
   'Enchant',
   'Destruction',
   'Alteration',
   'Illusion',
   'Conjuration',
   'Mysticism',
   'Restoration',
   'Alchemy',
   'Unarmored',
   'Security',
   'Sneak',
   'Acrobatics',
   'Lightarmor',
   'Shortblade',
   'Marksman',
   'Mercantile',
   'Speechcraft',
   'Handtohand',
}

local governing_attribute = {
    Block = 'Agility',
    Armorer = 'Strength',
    Mediumarmor = 'Endurance',
    Heavyarmor = 'Endurance',
    Bluntweapon = 'Strength',
    Longblade = 'Strength',
    Axe = 'Strength',
    Spear = 'Endurance',
    Athletics = 'Speed',
    Enchant = 'Intelligence',
    Destruction = 'Willpower',
    Alteration = 'Willpower',
    Illusion = 'Personality',
    Conjuration = 'Intelligence',
    Mysticism = 'Willpower',
    Restoration = 'Willpower',
    Alchemy = 'Intelligence',
    Unarmored = 'Speed',
    Security = 'Intelligence',
    Sneak = 'Agility',
    Acrobatics = 'Strength',
    Lightarmor = 'Agility',
    Shortblade = 'Speed',
    Marksman = 'Agility',
    Mercantile = 'Personality',
    Speechcraft = 'Personality',
    Handtohand = 'Speed',
}

-- MISC HELPERS

local prefix = '[' .. pclmp.scriptName .. ']: '

local function message_box(pid, msg)
    tes3mp.MessageBox(pid, -1, msg)
end

local function chat_message(pid, msg)
    tes3mp.SendMessage(pid, prefix .. msg .. '\n')
end

-- STAT HELPERS

local function get_current_level(pid)
    return Players[pid].data.stats.level
end

local function get_attribute(pid, attribute)
    return Players[pid].data.attributes[attribute].base
end

local function set_attribute(pid, attribute, val)
    if val > 100 then
        val = 100
    end
    Players[pid].data.attributes[attribute].base = val
    Players[pid].data.customVariables.PCLMP.cached_attributes[attribute] = val
    Players[pid]:LoadAttributes()
end

local function increase_attribute(pid, attribute, val)
    local old = get_attribute(pid, attribute)
    if old < 100 then
        local new = get_attribute(pid, attribute) + val
        -- needed for correct message (set_attribute() also checks)
        if new > 100 then
            new = 100
        end
        set_attribute(pid, attribute, new)
        message_box(pid, attribute .. ' increased to ' .. new .. '!' )
    end
end

local function get_skill(pid, skill)
    return Players[pid].data.skills[skill].base
end

-- GENERAL

local function has_pcl(pid)
    return Players[pid].data.customVariables.PCLMP ~= nil
end

local function get_cached_attribute(pid, attr)
    return Players[pid].data.customVariables.PCLMP.cached_attributes[attr]
end

local function get_attribute_skill_ups(pid, attr)
    return Players[pid].data.customVariables.PCLMP.attribute_skill_ups[attr]
end

local function get_attribute_points_owed(pid, attr)
    return Players[pid].data.customVariables.PCLMP.attribute_points_owed[attr]
end

local function add_attribute_skill_ups(pid, attr, val)
    Players[pid].data.customVariables.PCLMP.attribute_skill_ups[attr] = Players[pid].data.customVariables.PCLMP.attribute_skill_ups[attr] + val
end

local function cache_attributes(pid)
    for _, attribute in ipairs(attributes) do
        Players[pid].data.customVariables.PCLMP.cached_attributes[attribute] = get_attribute(pid, attribute)
    end
end

local function increase_attribute_if_needed(pid, attr)
    local val = 0
    while get_attribute_points_owed(pid, attr) > 0 and get_attribute_skill_ups(pid, attr) >= 2 do
        Players[pid].data.customVariables.PCLMP.attribute_skill_ups[attr] = Players[pid].data.customVariables.PCLMP.attribute_skill_ups[attr] - 2
        Players[pid].data.customVariables.PCLMP.attribute_points_owed[attr] = Players[pid].data.customVariables.PCLMP.attribute_points_owed[attr] - 1
        val = val + 1
    end
    if val > 0 then
        increase_attribute(pid, attr, val)
    end
end

local function increase_attributes_if_needed(pid)
    for _, attribute in ipairs(attributes) do
        increase_attribute_if_needed(pid, attribute)
    end
end

local function update_attribute_multipliers(pid)
    for _, attribute in ipairs(attributes) do
        local s = get_attribute_skill_ups(pid, attribute)
        if get_attribute_points_owed(pid, attribute) > 0 then
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
        elseif s >=2 then
            mul = 0
        end
        Players[pid].data.attributes[attribute].skillIncrease = mul
        Players[pid]:LoadAttributes()
    end
end

local function cache_skills(pid)
    for _, skill in ipairs(skills) do
        Players[pid].data.customVariables.PCLMP.cached_skills[skill] = get_skill(pid, skill)
    end
end

local function get_cached_skill(pid, skill)
    return Players[pid].data.customVariables.PCLMP.cached_skills[skill]
end

local function set_cached_skill(pid, skill, val)
    Players[pid].data.customVariables.PCLMP.cached_skills[skill] = val
end

local function update_cached_skill(pid, skill)
    local new = get_skill(pid, skill)
    local old = get_cached_skill(pid, skill)
    local dif = new - old
    set_cached_skill(pid, skill, new)
    if dif > 0 then
        local a = governing_attribute[skill]
        add_attribute_skill_ups(pid, a, dif)
        increase_attributes_if_needed(pid)
    end
end

local function recalculate_health(pid)
    if RETROACTIVE_HEALTH then
        local s = Players[pid].data.customVariables.PCLMP.starting_strength
        local e = Players[pid].data.customVariables.PCLMP.starting_endurance
        local h = (s + e) / 2
        local l = 1
        while l < get_current_level(pid) do
            if e + 5 < get_attribute(pid, 'Endurance') then
                e = e + 5
            else
                e = get_attribute(pid, 'Endurance')
            end
            h = h + (e / 10)
            l = l + 1
        end
        Players[pid].data.stats.healthBase = h
        tes3mp.SetHealthBase(pid, h)
        tes3mp.SendStatsDynamic(pid)
    end
end

-- EVENTS

function pclmp.init_player(eventStatus, pid)
    data = {
        starting_endurance = get_attribute(pid, 'Endurance'),
        starting_strength = get_attribute(pid, 'Strength'),
        attribute_skill_ups = {},
        attribute_points_owed = {},
        cached_level = get_current_level(pid),
        cached_attributes = {},
        cached_skills = {},
    }

    for _, attribute in ipairs(attributes) do
        data.attribute_skill_ups[attribute] = 0
        data.attribute_points_owed[attribute] = 0
    end

    Players[pid].data.customVariables.PCLMP = data

    cache_attributes(pid)
    cache_skills(pid)

    chat_message(pid, 'Carefree Leveling Initialized!')
end

function pclmp.on_player_skill(eventStatus, pid)
    if has_pcl(pid) then
        for _, skill in ipairs(skills) do
            update_cached_skill(pid, skill)
        end
        update_attribute_multipliers(pid)
        recalculate_health(pid)
    end
end

function pclmp.on_level(eventStatus, pid)
    if has_pcl(pid) then
        if get_current_level(pid) > Players[pid].data.customVariables.PCLMP.cached_level then
            Players[pid].data.customVariables.PCLMP.cached_level = Players[pid].data.customVariables.PCLMP.cached_level + 1

            local attrs_increased = 0
            for _, attribute in ipairs(attributes) do
                if get_attribute(pid, attribute) > get_cached_attribute(pid, attribute) then
                    attrs_increased = attrs_increased + 1
                    if attribute == 'Luck' then
                        local new_luck = Players[pid].data.customVariables.PCLMP.cached_attributes[attribute] + LUCK_MULTIPLIER
                        set_attribute(pid, 'Luck', new_luck)
                    else
                        if get_cached_attribute(pid, attribute) + Players[pid].data.customVariables.PCLMP.attribute_points_owed[attribute] < 100 then
                            Players[pid].data.customVariables.PCLMP.attribute_points_owed[attribute] = Players[pid].data.customVariables.PCLMP.attribute_points_owed[attribute] + 5
                            attrs_increased = attrs_increased + 1
                        end
                    end
                end
                Players[pid].data.attributes[attribute].base = get_cached_attribute(pid, attribute)
            end

            if RETROACTIVE_LUCK then
                while attrs_increased < 3 do
                    attrs_increased = attrs_increased + 1
                    local new_luck = get_attribute(pid, 'Luck') + LUCK_MULTIPLIER
                    set_attribute(pid, 'Luck', new_luck)
                end
            end

            increase_attributes_if_needed(pid)
            update_attribute_multipliers(pid)
            recalculate_health(pid)
        else
            cache_attributes(pid)
        end
    end
end

function pclmp.verbose_cmd(pid, cmd)
    if has_pcl(pid) then
        local msg = ''
        for _, attr in ipairs(attributes) do
            local owed = get_attribute_points_owed(pid, attr)
            local skillups = get_attribute_skill_ups(pid, attr)
            if owed > 0 or skillups > 0 then
                msg = msg .. '\n' .. attr
                if owed > 0 then
                    msg = msg .. ' has ' .. owed .. ' pending point'
                    if owed > 1 then
                        msg = msg .. 's'
                    end
                    msg = msg .. ' which will be added as you increase governed skills, '
                    if skillups > 0 then
                        msg = msg .. 'and'
                    else
                        msg = msg .. 'but'
                    end
                else
                    msg = msg .. ' has no pending points, but'
                end
                local increases = ' has no skill increases'
                if skillups > 0 then
                    increases = ' has '
                    local mul = 0
                    if skillups >= 10 then
                        mul = 5
                    elseif skillups >= 8 then
                        mul = 4
                    elseif skillups >= 6 then
                        mul = 3
                    elseif skillups >= 4 then
                        mul = 2
                    elseif skillups >= 2 then
                        mul = 1
                    end
                    if skillups == 1 then
                        increases = increases ..  '1 skill increase'
                    else
                        increases = increases .. skillups .. ' skill increases'
                    end
                    increases = increases .. ' (x' .. mul .. ' if chosen on your next level up)'
                end
                msg = msg .. increases .. '.'
            end
        end
        if msg == '' then
            msg = 'You\'re all caught up! You don\'t have any pending attribute points or skill increases right now.'
        end
        chat_message(pid, msg)
    end
end

function pclmp.short_cmd(pid, cmd)
    if has_pcl(pid) then
        local msg = ''
        for _, attr in ipairs(attributes) do
            local owed = get_attribute_points_owed(pid, attr)
            local skillups = get_attribute_skill_ups(pid, attr)
            if owed > 0 or skillups > 0 then
                msg = msg .. '\n' .. attr
                if owed > 0 then
                    msg = msg .. '(+' .. owed .. ' pending)'
                end
                if skillups > 0 then
                    msg = msg .. ': ' .. skillups .. ' skill increase'
                    if skillups > 1 then
                        msg = msg .. 's'
                    end
                    msg = msg .. '.'
                end
            end
        end
        if msg == '' then
            msg = 'You\'re all caught up! You don\'t have any pending attribute points or skill increases right now.'
        end
        chat_message(pid, msg)
    end
end

customCommandHooks.registerCommand('pcl', pclmp.short_cmd)
customCommandHooks.registerCommand('pclmp', pclmp.verbose_cmd)

customEventHooks.registerHandler('OnPlayerEndCharGen', pclmp.init_player)
customEventHooks.registerHandler('OnPlayerLevel', pclmp.on_level)
customEventHooks.registerHandler('OnPlayerSkill', pclmp.on_player_skill)

return pclmp
