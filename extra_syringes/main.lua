extraSyringes = RegisterMod("Extra Syringes", 1)
local mod = extraSyringes
require 'util'

require 'toxicFire'

mod.Syringes = 
{
    --Antidepressant = M_SYR.GetSyringeIdByName("Antidepressant"),
    --Bleach = M_SYR.GetSyringeIdByName("Bleach"),
    --BossRush = M_SYR.GetSyringeIdByName("Boss Rush"),
    --Caffeine = M_SYR.GetSyringeIdByName("Caffeine"),
    Depressant = M_SYR.GetSyringeIdByName("Depressant"),
    --HolyShot = M_SYR.GetSyringeIdByName("Holy Shot"),
    --Methanol = M_SYR.GetSyringeIdByName("Methanol"),
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


require 'syringes.depressant'
require 'syringes.morphine'
--require 'syringes.methanol'
require 'syringes.radioactive'
require 'syringes.redbull'


function mod:OnGameStarted(_, continued)
    
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStarted)

