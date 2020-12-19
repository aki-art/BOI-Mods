local mod = extraSyringes
local game = Game()

local FADE_IN_DURATION = 30 * 2
local FADE_OUT_DURATION = 30 * 2
local SYRINGE_DURATION = 450

local shaderStrength = 0
local fadeOut = false
local inactive = true
local lastSyringeExpire = 0

function mod:OnSharedParams(shader)

    if inactive then return 0 end
    
    if fadeOut then
        local elapsedTime = game:GetFrameCount() - lastSyringeExpire
        if elapsedTime <= FADE_OUT_DURATION then
            shaderStrength = 1 - math.max(0, elapsedTime / FADE_OUT_DURATION)
        else 
            shaderStrength = 0
            fadeOut = false
            inactive = true
        end
    end

    return {
        Strength = shaderStrength
    }
end
mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.OnSharedParams)

M_SYR.EFF_TAB[mod.Syringes.Depressant] = 
{
    ID = mod.Syringes.Depressant,
    Type = M_SYR.TYPES.Neutral,
    Name = "Depressant",
    Description = "",
    EIDDescription = "",
    Duration = SYRINGE_DURATION,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,

    OnUse = function(idx)
        local player = M_SYR.GetPlayerUsingActive()
        M_SYR.PlayNeutral(player, idx)
        fadeOut = false
        inactive = false
    end,

    Effect = 
    {
        [1] = 
        {
            Function = function(_)
                local player = M_SYR.GetPlayerUsingActive()

                if M_SYR.CheckForEffect(player,  mod.Syringes.Depressant) then
                    local elapsedTime = SYRINGE_DURATION - M_SYR.GetDuration(player, mod.Syringes.Depressant)
                    shaderStrength = elapsedTime <= FADE_IN_DURATION and elapsedTime / FADE_IN_DURATION or 1
                end

            end,
            Callback = ModCallbacks.MC_POST_UPDATE
        }
    },

    Post = function(player)
        game:GetRoom():SetSlowDown(SYRINGE_DURATION)
        fadeOut = true
        lastSyringeExpire = game:GetFrameCount()
    end
}
