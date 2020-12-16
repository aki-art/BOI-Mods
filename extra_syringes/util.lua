local game = Game()
local sfx = SFXManager()
local mod = extraSyringes

function mod:IsCorrectSyringe(player, syringe)
    syringeID = M_SYR.EFF_TAB[syringe].ID
    return M_SYR.CheckForEffect(player, syringeID)
end

function mod:PositiveFeedback(player)
    sfx:Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
    player:AnimateHappy()
end

function mod:NegativeFeedback(player)
    sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1)
    player:AnimateSad()
end

function mod:UpdateCache(player, cacheFlags)
    player:AddCacheFlags(cacheFlags)
    player:EvaluateItems()
end

function mod:IsOnFrame(frame)
    return game:GetFrameCount() % frame == 0
end