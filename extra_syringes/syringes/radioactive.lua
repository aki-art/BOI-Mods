local mod = extraSyringes
local rng = RNG()

RadioActiveHalo = Isaac.GetEntityVariantByName("Radioactive Aura")

local RadioActive = {
    RADIUS = 100,
    DAMAGE_MULTIPLIER = 2,
    DAMAGE_FRAME = 0.5 * 30,
    BLACKHEART_CHANCE = 0.05,
    SERPENTS_KISS_MULTIPLIER = 1.5
}

RadiactiveHaloEntity = nil
RadiactiveHaloCounter = 0

local function GetSerpentsKissMultiplier(player)
    return player:HasCollectible(CollectibleType.COLLECTIBLE_SERPENTS_KISS) and RadioActive.SERPENTS_KISS_MULTIPLIER or 1
end

local function GetLuckMultiplier(player)
    if player.Luck <= 0 then
        return 1
    end
    return math.min(player.Luck, 10) / 10 + 1
end

local function ApplyRadioactiveEffects(player, targets)

    for key, entity in pairs(targets) do
        if entity:IsActiveEnemy() and entity.FrameCount > 0 then

            local damage = player.Damage * RadioActive.DAMAGE_MULTIPLIER * RadiactiveHaloCounter
            entity:AddBurn(EntityRef(player), RadioActive.DAMAGE_FRAME, damage)

            blackHeartChance = RadioActive.BLACKHEART_CHANCE * GetSerpentsKissMultiplier(player) * GetLuckMultiplier(player)
            if (rng:RandomFloat() < blackHeartChance) then
                entity:AddEntityFlags(EntityFlag.FLAG_SPAWN_BLACK_HP)
            end
        end
    end
end

-- TODO: custom fire entity
local function SpawnToxicFire(player, entity)
    local entityPos = entity.Position
    if player.Position:Distance(entityPos) < RadioActive.RADIUS then
        fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, entityPos, Vector(0, 0), player):ToEffect();
    end
end

local function RemoveRadioActiveHalo()
    RadiactiveHaloEntity:Remove()
    RadiactiveHaloEntity = nil
end

local function SpawnRadioActiveHalo(player)
    if (RadiactiveHaloEntity == nil) then
        RadiactiveHaloEntity = Isaac.Spawn(EntityType.ENTITY_EFFECT, RadioActiveHalo, 0, player.Position, Vector(0, 0), player):ToEffect();
        RadiactiveHaloEntity:FollowParent(player)
        RadiactiveHaloEntity:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
    end
end

M_SYR.EFF_TAB[mod.Syringes.Radioactive] = 
{
    ID = mod.Syringes.Radioactive,
    Type = M_SYR.TYPES.Negative,
    Name = "Radioactive",
    Description = "",
    EIDDescription = "",
    Duration = 450,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,

    Effect = 
    {
        [1] = 
        {
            Function = function(_)
                local player = M_SYR.GetPlayerUsingActive()
                if mod:IsCorrectSyringe(player, mod.Syringes.Radioactive) and mod:IsOnFrame(RadioActive.DAMAGE_FRAME) then
                    local targets = Isaac.FindInRadius(player.Position, RadioActive.RADIUS, EntityPartition.ENEMY)
                    ApplyRadioactiveEffects(player, targets)
                end
            end,

            Callback = ModCallbacks.MC_POST_UPDATE
        },
        [2] = 
        {
            Function = function(_, entity)
                local player = M_SYR.GetPlayerUsingActive()
                SpawnToxicFire(player, entity)
            end,
            Callback = ModCallbacks.MC_POST_NPC_DEATH
        },
        [3] = 
        {
            Function = function(_)

            end,
            Callback = ModCallbacks.MC_POST_NPC_DEATH
        }
    },

    OnUse = function(idx)

        local player = M_SYR.GetPlayerUsingActive()
        mod:PositiveFeedback(player)
        SpawnRadioActiveHalo(player)
        RadiactiveHaloCounter = RadiactiveHaloCounter + 1
    end,

    Post = function(player)
        RadiactiveHaloCounter = RadiactiveHaloCounter - 1
        RemoveRadioActiveHalo()
    end
}
