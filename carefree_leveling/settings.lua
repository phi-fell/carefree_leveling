--  ignore this
local input = require('openmw.input')





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
-- (and will have the same health as a vanilla morrowind character who carefully maxed their endurance gain at early levels)
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






-- ignore this
return {
    STATUS_KEY = status_key,
    LUCK_MULT = luck_multiplier,
    RETROACTIVE_HEALTH = retroactive_health,
    RETROACTIVE_LUCK = retroactive_luck,
}