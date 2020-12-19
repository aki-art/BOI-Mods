
local mod = extraSyringes
local sfx = SFXManager()
local game = Game()

local ToxicFire = 
{
    entityVariant = Isaac.GetEntityVariantByName("Toxic Fire"),
    damageTick = 6,
    radius = 20,
    damage = 1,
    poisonDamage = 1,
    poisonDuration = 60
}

function mod:ToxicFireUpdate(effect)

    if(game:GetFrameCount() % ToxicFire.damageTick ~= 0) then
        return
    end

    local entities = Isaac.FindInRadius(
        effect.Position, 
        ToxicFire.radius, 
        EntityPartition.ENEMY)

    for k, entity in ipairs(entities) do
        if(entity:IsActiveEnemy()) then

            entity:TakeDamage(
                ToxicFire.damage, 
                DamageFlag.DAMAGE_FIRE, 
                EntityRef(fire), 
                0)

            effect:TakeDamage(
                1, 
                DamageFlag.DAMAGE_FIRE, 
                EntityRef(entity), 
                0)

            entity:AddPoison(
                EntityRef(fire), 
                ToxicFire.poisonDuration, 
                ToxicFire.poisonDamage)

            --local sprite = effect:GetSprite()
            effect.Scale = effect.Scale - 0.1

            if(effect.Scale > 0) then
                sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
            else
                effect:Remove()
            end
        end
    end
    if(effect:IsFrame(ToxicFire.damageTick, 0)) then
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ToxicFireUpdate, ToxicFire.entityVariant)