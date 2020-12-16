extraSyringes = RegisterMod("Extra Syringes", 1)
local mod = extraSyringes
require 'util'

mod.Syringes = 
{
    --Antidepressant = M_SYR.GetSyringeIdByName("Antidepressant"),
    --Bleach = M_SYR.GetSyringeIdByName("Bleach"),
    --BossRush = M_SYR.GetSyringeIdByName("Boss Rush"),
    --Caffeine = M_SYR.GetSyringeIdByName("Caffeine"),
    --Depressant = M_SYR.GetSyringeIdByName("Depressant"),
    --HolyShot = M_SYR.GetSyringeIdByName("Holy Shot"),
    Methanol = M_SYR.GetSyringeIdByName("Methanol"),
    Morphine = M_SYR.GetSyringeIdByName("Morphine"),
    Radioactive = M_SYR.GetSyringeIdByName("Radioactive"),
    --RatPoison = M_SYR.GetSyringeIdByName("Rat Poison"),
    RedBull = M_SYR.GetSyringeIdByName("Red Bull"),
    --RetroJuice = M_SYR.GetSyringeIdByName("Retro Juice")
}

mod.Costumes =
{
    RedBull = Isaac.GetCostumeIdByPath("gfx/characters/wings.anm2")
}

require 'syringes.radioactive'
require 'syringes.morphine'
require 'syringes.methanol'
require 'syringes.redbull'

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function mod:OnGameStarted(_, continued)
    local player = Isaac.GetPlayer(0)
    effects = M_SYR.PlayerSyringeEffects
    Isaac.ConsoleOutput(dump(effects))
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStarted)