# Carefree Leveling
Optimal vanilla leveling for OpenMW 0.48

## What it does
Vanilla Levelling but always optimal, no more worrying about optimizing skill leveling, no more prioritizing endurance early on if you don't want to.

In a nutshell, this keeps track of skill increases and levelups and recalculates your attributes and health to be what they would be if you had leveled optimally (+5 to 3 attributes every level (or 2 and luck), prioritize endurance for the low levels to max out health)

This means you can just play without worrying about optimizing your skill and attribute increases to occur in a certain order.

To be specific, this mod:
 - keeps track of your skill increases
 - Keeps track of your level ups and which attributes you increase
 - If you choose an attribute on leveling up, that attribute's "cap" is raised by 5 points
 - when an attribute is below it's cap, if there have been 2 or more skill increases in a relevant skill, it is increased by 1 (and those skill increases are used up)
 - unlike vanilla, unused skill increases carry over to future levelups
 - (optional) recalculates your health as if you had prioritized endurance for the early levels.
 - (optional) let's you get +2 or +3 luck per level if your other attributes are maxed out (i.e. if you select speed,strength,luck but strength is already at 100, you'll get 2 luck)

for example
 - You start the game with 40 Strength, 50 Speed, 40 Luck
 - You level up a major skill (athletics) 10 times and rest to level up
 - You select speedx5, strengthx1, luckx1
 - You now have 40 strength, 55 (+5!) speed and 41 luck
 - (You have 5 banked strength)
 - You level up acrobatics +1
 - You level up acrobatics again +1, your strength increases to 41
 - You level up acrobatics 8 more times, strength is now 45
 - you level up acrobatics 20 times
 - you level up athletics 10 times, rest and level up
 - you choose strength, speed and luck again
 - your strength increases to 50, your speed to 60, and your luck to 42
 - the remaining 10 acrobatics increases are still tracked, and will be applied if/when you select strength on a level up again

## Installation and Use

CURRENTLY REQUIRES AN UNMERGED BRANCH OF OPENMW: https://gitlab.com/OpenMW/openmw/-/merge_requests/1521
It looks like the API is settled, so this should work in openmw 0.48 when it's released (and nightlies after that merges) but until then if you want to use this, you need to download artifacts from that merge request.

REQUIRES A FRESH SAVE TO WORK.  The scripts should just ignore old saves.

see: https://openmw.readthedocs.io/en/stable/reference/modding/mod-install.html

TL;DR: if you download this mod such the `carefree_leveling.omwscripts` has the path: `OpenMW Mods/Phi's Carefree Leveling/carefree_leveling.omwscripts`

you'd just need to edit your openmw.cfg and add two lines to the end of it:

`data="OpenMW Mods/Phi's Carefree Leveling"`

`content=carefree_leveling.omwscripts`

Press P to toggle the status menu (key changable in `settings.lua`)

## Settings
Check `settings.lua`, you can turn off retroactive health, and retroactive luck, you can also change the luck multiplier, and which key is used to open the status menu (default is P)
