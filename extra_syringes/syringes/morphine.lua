local mod = extraSyringes
local music = MusicManager()

MORPHINE_DAMAGE_MULTIPLIER = 2.5
MORPHINE_SHOTSPEED_MODIFIED = -0.3

DealersJacket = Isaac.GetItemIdByName("Dealer's Jacket")
reversedControls = false

M_SYR.EFF_TAB[mod.Syringes.Morphine] = {
    ID = mod.Syringes.Morphine,
    Type = M_SYR.TYPES.Positive,
    Name = "Morphine",
    Description = "",
    EIDDescription = "",
    Duration = 1200,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,
    
    Effect = {
        [1] = {
            Function = function(_, player)
                if mod:IsCorrectSyringe(player, mod.Syringes.Morphine) then
                    player.Damage = player.Damage * MORPHINE_DAMAGE_MULTIPLIER
                end
            end,
            Callback = ModCallbacks.MC_EVALUATE_CACHE,
            Arg1 = CacheFlag.CACHE_DAMAGE,
        },
        [2] = {
            Function = function(_, player)
                if mod:IsCorrectSyringe(player, mod.Syringes.Morphine) then
                    player.ShotSpeed =  player.ShotSpeed + MORPHINE_SHOTSPEED_MODIFIED
                end
            end,
            Callback = ModCallbacks.MC_EVALUATE_CACHE,
            Arg1 = CacheFlag.CACHE_SHOTSPEED,
        }
    },
    
    OnUse = function(idx)
        reversedControls = true
        music:PitchSlide(0.5)
        local player = M_SYR.GetPlayerUsingActive()
        mod:NegativeFeedback(player)
        mod:UpdateCache(player, CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED)
    end,
    
    Post = function(player)
        reversedControls = false
        music:ResetPitch()
        mod:UpdateCache(player, CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED)
    end,
} 

function mod:ReverseControls(entity, hook, action)
    if entity ~= nil then
        player = M_SYR.GetPlayerUsingActive()

        if not (player:HasCollectible(CollectibleType.COLLECTIBLE_VIRGO) or player:HasCollectible(DealersJacket)) then
            if reversedControls and player and hook == InputHook.GET_ACTION_VALUE then
                if(action == ButtonAction.ACTION_LEFT) then
                    return Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
                elseif(action == ButtonAction.ACTION_RIGHT) then
                    return Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex)
                elseif(action == ButtonAction.ACTION_UP) then
                    return Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex)
                elseif(action == ButtonAction.ACTION_DOWN) then
                    return Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex)
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION , mod.ReverseControls)
