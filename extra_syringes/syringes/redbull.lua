
local mod = extraSyringes

queueRemoveFlight = false

M_SYR.EFF_TAB[mod.Syringes.RedBull] = {
    ID = mod.Syringes.RedBull,
    Type = M_SYR.TYPES.Positive,
    Name = "Red Bull",
    Description = "",
    EIDDescription = "",
    Duration = 100,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,
    
    Effect = {
        [1] = {
            Function = function(_, player)
                if mod:IsCorrectSyringe(player, mod.Syringes.RedBull) then
                    player.CanFly = true
                end
            end,
            Callback = ModCallbacks.MC_EVALUATE_CACHE,
            Arg1 = CacheFlag.CACHE_FLYING,
        }
    },
    
    OnUse = function(idx)
        local player = M_SYR.GetPlayerUsingActive()
        player:AddNullCostume(mod.Costumes.RedBull)
        mod:PositiveFeedback(player)
        mod:UpdateCache(player, CacheFlag.CACHE_FLYING)
        queueRemoveWings = false
    end,
    
    Post = function(player)
        queueRemoveWings = true
    end,
}

function mod:refreshWingsCostume(player)
    if(queueRemoveWings) then
        local player = M_SYR.GetPlayerUsingActive()
        player:TryRemoveNullCostume(mod.Costumes.RedBull)
        mod:UpdateCache(player, CacheFlag.CACHE_FLYING)
        queueRemoveWings = false
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM , mod.refreshWingsCostume, 0)