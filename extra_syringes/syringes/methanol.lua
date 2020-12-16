local mod = extraSyringes
local game = Game()

local hideEnemies = false
local hidePickups = false

local function ApplyEffects()
    if(hideEnemies or hidePickups) then
        local seed = game:GetSeeds()

        seed:AddSeedEffect(SeedEffect.SEED_CAMO_ENEMIES )
        seed:AddSeedEffect(SeedEffect.SEED_CAMO_PICKUPS )
    end
    game:Darken(0.7, 450)
end

local function RemoveEffects()
    local seed = game:GetSeeds()
    seed:RemoveSeedEffect(SeedEffect.SEED_CAMO_ENEMIES)
    seed:RemoveSeedEffect(SeedEffect.SEED_CAMO_PICKUPS)
end

M_SYR.EFF_TAB[mod.Syringes.Methanol] = {
    ID = mod.Syringes.Methanol,
    Type = M_SYR.TYPES.Negative,
    Name = "Methanol",
    Description = "",
    EIDDescription = "",
    Duration = 450,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,
    
    Effect = {
        [1] = {
             Function = function(_)
                if mod:IsCorrectSyringe(player, mod.Syringes.Methanol) then
                    local player = M_SYR.GetPlayerUsingActive()
                    player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_CAMO_UNDIES, false)
                end
            end,
            Callback = ModCallbacks.MC_POST_UPDATE 
        },
        [2] = {
             Function = function(_)
                if mod:IsCorrectSyringe(player, mod.Syringes.Methanol) then
                    RemoveEffects()
                end
            end,
            Callback = ModCallbacks.MC_PRE_GAME_EXIT 
        },

    },
    
    OnUse = function(idx)

        local seed = game:GetSeeds()

        hideEnemies = not seed:HasSeedEffect(SeedEffect.SEED_CAMO_ENEMIES)
        hidePickups = not seed:HasSeedEffect(SeedEffect.SEED_CAMO_PICKUPS)

        ApplyEffects() 

        local player = M_SYR.GetPlayerUsingActive()
        mod:NegativeFeedback(player)
    end,
    
    Post = function(player)
        RemoveEffects()
    end,
}

