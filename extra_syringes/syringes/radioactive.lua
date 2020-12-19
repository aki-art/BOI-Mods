local mod = extraSyringes
local rng = RNG()
local game = Game()

local toxicFireVariant = Isaac.GetEntityVariantByName("Toxic Fire")
local radioactiveAuraVariant = Isaac.GetEntityVariantByName("Radioactive Aura")

local aura = nil

-- Radioactive Aura

    local RadioActiveAura = {
        damageMultiplier = 2,
        radius = 100,
        damageTick = 0.5 * 30,
        bossBurnDuration = 2 * 30,
        entity = nil,
        parent = nil,
        flags = EntityFlag.FLAG_PERSISTENT | EntityFlag.FLAG_DONT_OVERWRITE,
        sprite = nil,
        endOfLifeTime = false,
        disappearAt = 8,
        disappearing = false
    }

    function RadioActiveAura:new(parent)
        self.parent = parent
        return RadioActiveAura
    end

    function RadioActiveAura:Spawn(skipAnimation)
        if (self.entity ~= nil) then
            self.entity:Remove()
        end

        assert(self.parent, "Radioactive Aura parent cannot be null.")
        
        local entity = Isaac.Spawn(
            EntityType.ENTITY_EFFECT, 
            radioactiveAuraVariant, 
            0, 
            self.parent.Position, 
            Vector(0, 0), 
            player):ToEffect()
        
        entity:AddEntityFlags(self.flags)
        entity:FollowParent(self.parent)
        self.entity = entity

        self.sprite = entity:GetSprite()
        if (not skipAnimation) then
            self.sprite:Play("Appear")
        end

        self.endOfLifeTime = false
        self.disappearing = false
    end

    function RadioActiveAura:UpdateState()
        if(self.disappearing) then return end

        local remaining = M_SYR.GetDuration(self.parent, mod.Syringes.Radioactive)
        self.endOfLifeTime = remaining <= self.disappearAt

        if(self.endOfLifeTime) then
            self.sprite:Play("Disappear")
            self.disappearing = true

        elseif(self.sprite:IsFinished("Appear")) then
            self.sprite:Play("Idle")
        end
    end

    function RadioActiveAura:Hide()
        if(self.sprite ~= nil) then
            self.sprite:Play("Disappear")
        end
    end

    function RadioActiveAura:Destroy()
        self.entity:Remove()
        self = nil
    end

    function RadioActiveAura:OnCollision(entity)
        if entity:IsActiveEnemy() then
            local damage = self.parent.Damage * self.damageMultiplier
            entity:AddBurn(EntityRef(self.parent), self.damageTick, damage)
        end
    end

    function RadioActiveAura:BurnEnemies()  
        if(game:GetFrameCount() % self.damageTick == 0) then
            local entities = Isaac.FindInRadius(
                self.parent.Position, 
                self.radius, 
                EntityPartition.ENEMY)

            for k, entity in ipairs(entities) do
                self:OnCollision(entity)
            end
        end
    end

    function RadioActiveAura:GetBlackHeartChance()
        local hasSerpentsKiss = self.parent:HasCollectible(CollectibleType.COLLECTIBLE_SERPENTS_KISS)
        local hasDemonTail = false

        local multiplier = 0
        multiplier = hasSerpentsKiss and multiplier + 0.1 or multiplier
        multiplier = hasDemonTail and multiplier + 0.1 or multiplier

        return multiplier
    end

    function RadioActiveAura:DropBlackHeart(entity)
        local chance = self:GetBlackHeartChance()
        if(rng:RandomFloat() <= chance) then      
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_HEART,
                HeartSubType.HEART_BLACK,
                entity.Position, 
                Vector(0, 0), 
                self.parent)
        end
    end

    function RadioActiveAura:OnKill(entity)
        local distance = entity.Position:Distance(self.parent.Position)
        if(distance <= self.radius) then

            self:DropBlackHeart(entity)
            Isaac.Spawn(
                EntityType.ENTITY_EFFECT, 
                toxicFireVariant, 
                0, 
                entity.Position, 
                Vector(0, 0), 
                self.parent):ToEffect()
        end
    end

-- Syringe
    M_SYR.EFF_TAB[mod.Syringes.Radioactive] =
    {
        ID = mod.Syringes.Radioactive,
        Type = M_SYR.TYPES.Positive,
        Name = "Radioactive",
        Description = "desc.",
        EIDDescription = "eid desc",
        Duration = 5 * 30,
        Counterpart =  M_SYR.TOT_SYR.DPSDampener,
        Weight = 1,

        OnUse = function(idx)
            local player = M_SYR.GetPlayerUsingActive()
            mod:PositiveFeedback(player)

            if(aura == nil) then
                aura = RadioActiveAura:new(player)
            end
            aura:Spawn()
        end,

        Effect =
        {
            [1] =
            {
                Function = function()
                    aura:BurnEnemies()
                    aura:UpdateState()
                end,
                Callback = ModCallbacks.MC_POST_EFFECT_UPDATE,
                Arg1 = radioactiveAuraVariant
            },
            [2] = 
            {
                Function = function()
                    aura = RadioActiveAura:new(player)
                    aura:Spawn(true)
                end,
                Callback = ModCallbacks.MC_POST_GAME_STARTED
            },
            [3] = 
            {
                Function = function(_, entity)
                    aura:OnKill(entity)
                end,
                Callback = ModCallbacks.MC_POST_NPC_DEATH
            },
        },

        Post = function(player)
            if(aura) then
                aura:Destroy()
            end
        end
    }