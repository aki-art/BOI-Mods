local game = Game()
local sfx = SFXManager()

function extraSyringes:IsCorrectSyringe(entity, id, checkIfPlayer)
    if entity == nil then 
        return false 
    end

    if checkIfPlayer ~= false then
        if entity.Type ~= EntityType.ENTITY_PLAYER then 
            return false
        end
    end

    syringeID = M_SYR.EFF_TAB[id].ID
    return entity:GetData().SyringeEffects[syringeID] ~= nil
end

function extraSyringes:PositiveFeedback(player)
    sfx:Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
    player:AnimateHappy()
end

function extraSyringes:NegativeFeedback(player)
    sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1)
    player:AnimateSad()
end

function extraSyringes:UpdateCache(player, cacheFlags)
    player:AddCacheFlags(cacheFlags)
    player:EvaluateItems()
end

function extraSyringes:IsOnFrame(frame)
    return game:GetFrameCount() % frame == 0
end