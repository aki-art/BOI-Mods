local mod = RegisterMod("Syringes! Refill Pack", 1)
local debug = true

local game = Game()
local sfx = SFXManager()
local music = MusicManager()
local rng = RNG()

-- #region Enums

local PlayerVariant = {
    PLAYER = 0,
    COOP_BABY = 1,
}

local Stat = {
    DAMAGE = 0,
    FIRERATE = 1,
    RANGE = 2,
    SHOT_SPEED = 3,
    MOVEMENT_SPEED = 4,
    LUCK = 5
}

local LaserVariant = {
    BRIMSTONE = 1,
    TECH = 2,
    ANGEL = 5
}

-- #endregion

-- #region Constants

local Colors = {
    RED = Color(1, 0, 0, 1, 1, 1, 1),
    ELECTRIC_BLUE = Color(1, 1, 1, 1, 0, 0, 0):SetColorize(1, 2, 4, 1)
}

mod.ENTITY_REFILL_PACK = Isaac.GetEntityTypeByName("Toxic Fire")
mod.EntityVariants = 
{
    TOXIC_FIRE = Isaac.GetEntityVariantByName("Toxic Fire"),
    RADIOACTIVE_AURA = Isaac.GetEntityVariantByName("Radioactive Aura"),
    HEART_COLLISION_SHIELD = Isaac.GetEntityVariantByName("Heart Collision Shield")
}

mod.Costumes =
{
    RedBull = Isaac.GetCostumeIdByPath("gfx/characters/wings.anm2")
}

local COLLECTIBLE_DEALERS_JACKET = Isaac.GetItemIdByName("Dealer's Jacket")

local ButtonOpposites = 
{
    [ButtonAction.ACTION_LEFT] = ButtonAction.ACTION_RIGHT,
    [ButtonAction.ACTION_RIGHT] = ButtonAction.ACTION_LEFT,
    [ButtonAction.ACTION_UP] = ButtonAction.ACTION_DOWN,
    [ButtonAction.ACTION_DOWN] = ButtonAction.ACTION_UP,
}

-- #endregion

-- #region Variables

local SyringeIds = {
    Amatoxin = M_SYR.GetSyringeIdByName("Amatoxin"),
    AntiElectrolyte = M_SYR.GetSyringeIdByName("AntiElectrolyte"),
    BatteryAcid = M_SYR.GetSyringeIdByName("BatteryAcid"),
    Bleach = M_SYR.GetSyringeIdByName("Bleach"),
    BloodSample = M_SYR.GetSyringeIdByName("BloodSample"),
    BossRush = M_SYR.GetSyringeIdByName("BossRush"),
    BossStrength = M_SYR.GetSyringeIdByName("BossStrength"),
    CaffeineShot = M_SYR.GetSyringeIdByName("CaffeineShot"),
    Decaf = M_SYR.GetSyringeIdByName("Decaf"),
    -- Depressant = M_SYR.GetSyringeIdByName("Depressant"),
    -- GummyberryJuice = M_SYR.GetSyringeIdByName("GummyberryJuice"),
    -- Lead = M_SYR.GetSyringeIdByName("Lead"),
    -- Mercury = M_SYR.GetSyringeIdByName("Mercury"),
    -- Monster = M_SYR.GetSyringeIdByName("Monster"),
    Morphine = M_SYR.GetSyringeIdByName("Morphine"),
    RadioActive = M_SYR.GetSyringeIdByName("Radioactive"),
    -- RatPoison = M_SYR.GetSyringeIdByName("Rat Poison"),
    RedBull = M_SYR.GetSyringeIdByName("Red Bull")
}


-- dictionary of default modifier functions
local Stats =
{
    [Stat.DAMAGE] = { 
        flag = CacheFlag.CACHE_DAMAGE,
        func = function(player, value) player.Damage = player.Damage * value end
    },
    [Stat.FIRERATE] = { 
        flag = CacheFlag.CACHE_FIREDELAY ,
        func = function(player, value) player.MaxFireDelay = player.MaxFireDelay * value end
    },
    [Stat.SHOT_SPEED] = { 
        flag = CacheFlag.CACHE_SHOTSPEED ,
        func = function(player, value) player.ShotSpeed = player.ShotSpeed + value end
    },
    [Stat.MOVEMENT_SPEED] = { 
        flag = CacheFlag.CACHE_SPEED ,
        func = function(player, value) player.MoveSpeed = player.MoveSpeed + value end
    },
    [Stat.LUCK] = { 
        flag = CacheFlag.CACHE_LUCK ,
        func = function(player, value) player.Luck = player.Luck + value end
    },
    [Stat.RANGE] = { 
        flag = CacheFlag.CACHE_RANGE ,
        func = function(player, value) player.TearHeight = player.TearHeight * value end
    }
}


local SyringeLookup = {
    -- CurrentRunPool
    CurrentRunIdx = {
        -- SyringeID
        -- Card
    },
    -- Doesn't exist
    SyringeIDs = {
        -- CurrentRunIndex,
        -- Card
    },
    -- CurrentIDPool
    Cards = {
        -- SyringeID
        -- CurrentRunIndex
    }
}

-- #endregion

-- #region Utilities

local function GetSyringeRNG(player, syringeID)        
    local cardID = SyringeLookup.SyringeIDs[syringeID].Card
    return player:GetCardRNG(cardID)
end

local function ToFrames(seconds) return seconds * 30 end

local function PickWeighted(table, rng)
                
    if (not table) then return false end

    local totalWeight = 0
    for k, item in ipairs(table) do
        totalWeight = totalWeight + item.weight
    end

    local threshold = rng:RandomFloat() * totalWeight
    for k, item in ipairs(table) do
        totalWeight = totalWeight - item.weight
        if (totalWeight < threshold) then
            return item
        end
    end

    return false
end

local function Contains(table, value)
    for key, val in ipairs(table) do
        if val == value then return true end
    end
    return false
end


local Vector2 = {

    zero = Vector(0, 0),
    one = Vector(1, 1),

    RandomInUnitCircle = function()
        local angle = math.random(0, 359)
        local vec = Vector(0, 1)
        vec = vec:Rotated(angle)

        return vec
    end
}

local Debug = {

    -- logs that only appear if debug is set to true
    Log = function(message)
        if debug then 
            local msg = string.format("[%s] [RFP] %s", Isaac.GetFrameCount(), tostring(message))
            print(tostring(msg))
            Isaac.DebugString(msg)
        end
    end,

    ReplaceSyringePool = function()
        local i = 1
        for key, value in pairs(SyringeIds) do
            local newSyringe = M_SYR.EFF_TAB[value]
            local color = M_SYR.CurrentRunPool[i].Color

            M_SYR.CurrentIDPool[color].Syringe = newSyringe.ID
            M_SYR.CurrentRunPool[i].Syringe = newSyringe.ID
            
            M_SYR.UpdateDescription(color, newSyringe.EIDDescription, newSyringe.Name)
            table.insert(testSyringes, color)
            i = i + 1
        end
    end
}

-- Clones Syringes data to a lookup table
local function PopulateSyringeLookup()

    for key, value in ipairs(M_SYR.EFF_TAB) do
        SyringeLookup.SyringeIDs[key] = {}
    end

    for key, value in pairs(M_SYR.CurrentIDPool) do
        SyringeLookup.Cards[key] =
        {
            SyringeID = value.Syringe,
            CurrentRunIndex = value.Index
        }

        SyringeLookup.SyringeIDs[value.Syringe].Card = key
        SyringeLookup.SyringeIDs[value.Syringe].CurrentRunIndex = value.Index
    end

    for key, value in ipairs(M_SYR.CurrentRunPool) do
        SyringeLookup.CurrentRunIdx[key] = {
            SyringeID = value.Syringe,
            Card = value.Color
        }
    end
end

-- #endregion

-- #region Entities

-- #entity Toxic Fire

local ToxicFire = 
{
    damageTick = 6,
    radius = 20,
    damage = 1,
    poisonDamage = 1,
    poisonDuration = 60
}

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    effect.SpriteScale = Vector2.one * 0.7
end, mod.EntityVariants.ToxicFire)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if(effect:IsFrame(ToxicFire.damageTick, 0)) then
        
        local entities = Isaac.FindInRadius(
            effect.Position, 
            ToxicFire.radius, 
            EntityPartition.ENEMY)

        for k, entity in ipairs(entities) do
            if(entity:IsActiveEnemy()) then
        
                -- hurt and poison
                entity:TakeDamage(ToxicFire.damage, DamageFlag.DAMAGE_FIRE, EntityRef(fire), 0)
                entity:AddPoison( EntityRef(fire), ToxicFire.poisonDuration, ToxicFire.poisonDamage)
                    
                -- diminish and disappear
                effect:TakeDamage(1, DamageFlag.DAMAGE_FIRE, EntityRef(entity), 0)

                local height = effect.SpriteScale.Y
                effect.SpriteScale = Vector2.one * (height - 0.1)
                
                if(height > 0.1) then
                    sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
                else
                        effect:Remove()
                end
            end
        end
    end
end, mod.EntityVariants.ToxicFire)

-- #endentity

-- #entity Radioactive Aura

local RadioActiveAura = {
    radius = 100,
    entity = nil
}

function RadioActiveAura.Spawn(player)

    if RadioActiveAura.entity then return end -- only one should exist

    aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.EntityVariants.RADIOACTIVE_AURA, 0, player.Position, Vector2.zero, player):ToEffect()
    aura.Parent = player
    aura:FollowParent(player)
    aura:AddEntityFlags(EntityFlag.FLAG_PERSISTENT | EntityFlag.FLAG_DONT_OVERWRITE)
    aura:GetSprite():Play("Appear")

    aura:GetData().RFP_Appearing = true
    aura:GetData().RFP_Disappearing = false

    RadioActiveAura.entity = aura

end

function RadioActiveAura.SetEntitiesOnFire(player, tick)
    
    if(game:GetFrameCount() % tick == 0) then

        local entities = Isaac.FindInRadius(
            player.Position, 
            RadioActiveAura.radius, 
            EntityPartition.ENEMY)

        for k, entity in ipairs(entities) do
            if entity:IsActiveEnemy() then
                local damage = player.Damage * 2
                local duration = entity:IsBoss() and tick * 10 or tick
                entity:AddBurn(EntityRef(player), duration, damage)
            end
        end
    end
end

function RadioActiveAura.GetBlackHeartChance(player)

    local baseChance = 0.1 -- high value for testing
    local multiplier = 1

    if player:HasCollectible(CollectibleType.COLLECTIBLE_SERPENTS_KISS) then
        multiplier = multiplier + 0.25
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_VIRUS) then
        multiplier = multiplier + 0.25
    end

    if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
        multiplier = 0
    elseif player:GetName() == "Fiend" then
        multiplier = multiplier + 0.33
    end

    return baseChance * multiplier
end

function RadioActiveAura.Update(_, entity)
    local data = entity:GetData()
    local sprite = entity:GetSprite()
    local player = M_SYR.GetPlayerUsingActive()

    if data.RFP_Disappearing and sprite:IsFinished("Disappear") then
        RadioActiveAura.Destroy()

    elseif M_SYR.CheckForEffect(player, SyringeIds.RadioActive) then

        -- Update animation
        if data.RFP_Appearing and sprite:IsFinished("Appear") then
            entity:GetData().RFP_Appearing = false
            sprite:Play("Idle")
        end

        -- Do damage
        local damageTick = 6
        RadioActiveAura.SetEntitiesOnFire(player, damageTick)
        
    else 
        entity:GetData().RFP_Disappearing = true
        sprite:Play("Disappear")
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, RadioActiveAura.Update, mod.EntityVariants.RADIOACTIVE_AURA)

function RadioActiveAura.OnEntityDeath(_, entity)

    if RadioActiveAura.entity == nil then return end

    local player = RadioActiveAura.entity.Parent:ToPlayer()

    local distance = entity.Position:Distance(RadioActiveAura.entity.Position)
    if(distance <= RadioActiveAura.radius) then

        local heartChance = RadioActiveAura.GetBlackHeartChance(player)

        local syringeRNG = GetSyringeRNG(player, SyringeIds.RadioActive)

        -- spawn black heart
        if syringeRNG:RandomFloat() < heartChance then
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_HEART,
                HeartSubType.HEART_BLACK,
                entity.Position, 
                Vector2.zero, 
                player)
        end

        -- spawn a green fire
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT, 
            mod.EntityVariants.TOXIC_FIRE, 
            0, 
            entity.Position, 
            Vector2.zero, 
            player):ToEffect()
    end
end

RadioActiveAura.Destroy = function(entity)
    RadioActiveAura.entity:Remove()
    RadioActiveAura.entity = nil
end       

-- manage this better

-- #endentity

-- #endregion

-- #region Syringe Helpers

local function Effect(stat, value)
    return 
    {
        Function = function(_, player, cacheFlag)
            Stats[stat].func(player, value)
        end,
        Callback = ModCallbacks.MC_EVALUATE_CACHE,
        Arg1 = Stats[stat].flag
    }
end

local function HasJacketOrVirgo(player)
    player = player or M_SYR.GetPlayerUsingActive() or Isaac.GetPlayer(0)
    local hasJacket = player:HasCollectible(COLLECTIBLE_DEALERS_JACKET)
    local hasVirgo = player:HasCollectible(CollectibleType.COLLECTIBLE_VIRGO)

    return hasJacket or hasVirgo
end

local function React(type, player, idx)

    player = player or M_SYR.GetPlayerUsingActive()

    if(type == M_SYR.TYPES.Neutral) then
        M_SYR.PlayNeutral(player, idx)
		Sfx:Play(SoundEffect.SOUND_THUMBSUP, 1, 0, false, 1)

    elseif type == M_SYR.TYPES.Positive then
        sfx:Play(SoundEffect.SOUND_POWERUP_SPEWER, 1, 0, false, 1)
        player:AnimateHappy()

    elseif type == M_SYR.TYPES.Negative then
        sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1)
        player:AnimateSad()
    end

end

local function UpdateCache(player, flag)
    player:AddCacheFlags(flag)
    player:EvaluateItems()
end

-- #endregion

-- #syringe Amatoxin

-- approximation of the scaredy heart effect
-- speed 15 and no max: the hearts are about unpickable
local function MakeHeartsRunAway(source, radius, speed, maxSpeed)   

    local pickups = Isaac.FindInRadius(source.Position, radius, EntityPartition.PICKUP)

    for k, pickup in pairs(pickups) do
        if pickup.Variant == PickupVariant.PICKUP_HEART then
            local direction = (pickup.Position - source.Position):Normalized()
            local sqrDistance = pickup.Position:DistanceSquared(source.Position)
            vec = direction * math.min(maxSpeed, (radius / sqrDistance))
            pickup:AddVelocity(vec * speed) 
        end
    end
end

-- why tf is this so massively complicated to do!?
-- determines what heart should be dropped next
local function LastHeart(player, ignoreGold)    
    
    if not ignoreGold and player:GetGoldenHearts() > 0 then
        return HeartSubType.HEART_GOLDEN, 1
    end

    local numRed = player:GetHearts()
    local numSoul = player:GetSoulHearts()
    local numBone = player:GetBoneHearts()
    local health = numRed + numBone + numSoul

    if health < 2 then return nil, 0 end

    local numBoneRed = math.max(0, numRed - player:GetMaxHearts())
    local extra = math.ceil(numSoul / 2) + numBone

    if extra == 0 then
        if player:GetEternalHearts() > 0 then 
            return HeartSubType.HEART_ETERNAL, 1
        elseif numRed > 2 then
            return HeartSubType.HEART_FULL, 2
        elseif numRed == 2 then 
            return HeartSubType.HEART_HALF, 1
        end
    end

    if player:IsBoneHeart(extra - 1) then

        if numBoneRed >= 2 then
            return HeartSubType.HEART_FULL, 2
        elseif numBoneRed == 1 then
            return HeartSubType.HEART_HALF, 1
        else
            return HeartSubType.HEART_BONE, 1
        end

    elseif numSoul > 1 then

        local lastSoul = extra * 2 - 2
        local isBlack = player:IsBlackHeart(lastSoul + 1)

        if numSoul >= 2 then
            if isBlack then 
                return HeartSubType.HEART_BLACK, 2 
            else
                return HeartSubType.HEART_SOUL, 2
            end
        elseif not isBlack then 
            return HeartSubType.HEART_HALF_SOUL, 1
        -- else it's half a black heart, just leaving that alone
        end
    end

    return nil, 0
end

-- throws a heart from Isaacs HP bar to the ground
local function ThrowHeart(player, subType, amount)

    if not subType or not amount then return end

    if subType == HeartSubType.HEART_FULL or subType == HeartSubType.HEART_HALF then
        player:AddHearts(-amount)
    elseif subType == HeartSubType.HEART_SOUL or subType == HeartSubType.HEART_HALF_SOUL then
        player:AddSoulHearts(-amount)
    elseif subType == HeartSubType.HEART_BLACK then
        player:AddBlackHearts(-amount)
    elseif subType == HeartSubType.HEART_ETERNAL then
        player:AddEternalHearts(-amount)
    elseif subType == HeartSubType.HEART_BONE then
        player:AddBoneHearts(-amount)
    elseif subType == HeartSubType.HEART_GOLDEN then
        player:AddGoldenHearts(-amount)
    else 
        return
    end
        
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, subType, player.Position, Vector2.RandomInUnitCircle() * math.random(5, 10) / 10, player)
end


local function UpdateAmatoxin(_, player)
    if M_SYR.CheckForEffect(player, SyringeIds.Amatoxin) then
        if player:IsFrame(30, 0) then
            local subType, amount = LastHeart(player)
            ThrowHeart(player, subType, amount)
        end
        MakeHeartsRunAway(player, 100, 12, 0.3) 
    end
end

M_SYR.EFF_TAB[SyringeIds.Amatoxin] = {
	ID = SyringeIds.Amatoxin,
	Type = M_SYR.TYPES.Positive,
	Name = "Amatoxin",
	Description = "Amatoxin",
	EIDDescription = "#Drop hearts on floor#All hearts are repelled",
	Duration = ToFrames(30),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
	
	Effect = {
		{
            Function = UpdateAmatoxin,
            Callback = ModCallbacks.MC_POST_PLAYER_UPDATE,
            Arg1 = PlayerVariant.PLAYER
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Positive) 
    end
}

-- #endsyringe

-- #syringe Anti-Electrolyte

-- todo: subcharge type items
local function PersistCharge()
    local player = M_SYR.GetPlayerUsingActive()
    if M_SYR.CheckForEffect(player, SyringeIds.AntiElectrolyte) then
        player:SetActiveCharge(player:GetActiveCharge() - 1) -- this shouldn't work, but it does
    end
end


M_SYR.EFF_TAB[SyringeIds.AntiElectrolyte] = {
	ID = SyringeIds.AntiElectrolyte,
	Type = M_SYR.TYPES.Positive,
	Name = "Anti-Electrolyte",
	Description = "Anti-Electrolyte",
	EIDDescription = "\1 Prevents active item charges from room clears",
	Duration = ToFrames(10),
	Counterpart = SyringeIds.BatteryAcid,
	
	Effect = {
		{
            Function = PersistCharge,
            Callback = ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD 
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Negative)
    end
}
 
-- #endsyringe

-- #syringe Battery Acid

local function ChargeKinetic(_, player)

    if M_SYR.CheckForEffect(player, SyringeIds.BatteryAcid) then

        local activeItemID = player:GetActiveItem()

        if player:IsFrame(6, 0) and activeItemID and
            player:GetRecentMovementVector():Length() > 0 then

            local syringeRNG = GetSyringeRNG(player, SyringeIds.BatteryAcid)
            local currentCharge = player:GetActiveCharge()
            local activeItem = Isaac.GetItemConfig():GetCollectible(activeItemID)

            if currentCharge < activeItem.MaxCharges then
                if syringeRNG:RandomFloat() < 0.1 then
                    player:SetActiveCharge(currentCharge + 1)
                end
            else 
                if syringeRNG:RandomFloat() < 0.3 then

                    local color = Color(1, 1, 1, 1, 0, 0, 0)
                    color:SetColorize(2, 3, 4, 1)

                    for i = 1, syringeRNG:RandomInt(4) + 1 do
                        local laser = EntityLaser.ShootAngle(LaserVariant.TECH, player.Position, math.random() * 359, 5, Vector2.zero, player)
                        laser:GetSprite().Color = color
                    end

                end
            end
        end
    end
end

M_SYR.EFF_TAB[SyringeIds.BatteryAcid] = {
	ID = SyringeIds.BatteryAcid,
	Type = M_SYR.TYPES.Positive,
	Name = "Battery Acid",
	Description = "Battery Acid",
	EIDDescription = "\1 Kinetic charge #\1 Power release on full charge",
	Duration = ToFrames(10),
	Counterpart = SyringeIds.AntiElectrolyte,
	
	Effect = {
		{
            Function = ChargeKinetic,
            Callback = ModCallbacks.MC_POST_PLAYER_UPDATE,
            Arg1 = PlayerVariant.PLAYER
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Positive) 
    end
}

-- #endsyringe

-- #syringe Bleach

local function SpawnRedCreep(player)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector2.zero, player)
end

local function VomitBlood(player)
    local count = math.random(1, 6)
    for i=1, count do
        local speed = math.random() * 15
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, player.Position, Vector2.RandomInUnitCircle() * speed, player):ToTear()

        tear.FallingSpeed = -30
        tear.CollisionDamage = player.Damage * 0.3
        tear.FallingAcceleration = 2
    end
end

local function BleachShots(_, player)

    if M_SYR.CheckForEffect(player, SyringeIds.Bleach) then

        local speed = math.floor(player.Velocity:Length())
        local frameCheck = math.max(0, 8 - speed)

        if player:IsFrame(frameCheck, 0) then
            SpawnRedCreep(player)
        end

        if math.random() < 0.03 then
            VomitBlood(player)
        end
    end
end

M_SYR.EFF_TAB[SyringeIds.Bleach] = {
	ID = SyringeIds.Bleach,
	Type = M_SYR.TYPES.Positive,
	Name = "Bleach",
	Description = "Bleach",
	EIDDescription = "\1 x1.7 Damage #\1 x0.7 Tear Delay",
	Duration = ToFrames(10),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
	
	Effect = {
		{
            Function = BleachShots,
            Callback = ModCallbacks.MC_POST_PLAYER_UPDATE,
            Arg1 = PlayerVariant.PLAYER
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Positive) 
    end
}

-- #endsyringe

-- #syringe BloodSample

local bloodStat = nil
local bloodDesc = ""
local bloodEffectorValue = 0
local bloodGood = false
local bloodRNG = RNG()
local bloodOptions = 
{
    {
        description = "Damage",
        stat = Stat.DAMAGE,
        badRange = Vector(0.5, 0.8),
        goodRange = Vector(1.2, 1.7),
        weight = 1
    },
    {
        description = "Tears",
        stat = Stat.FIRERATE,
        badRange = Vector(1.4, 2),
        goodRange = Vector(0.5, 0.8),
        weight = 1
    },
    {
        description = "Range",
        stat = Stat.RANGE,
        badRange = Vector(0.3, 0.6),
        goodRange = Vector(1.5, 2),
        weight = 0.5
    },
    {
        description = "Range",
        stat = Stat.LUCK,
        badRange = Vector(-1, -8),
        goodRange = Vector(2, 10),
        weight = 0.5
    }
}

local function FormatBloodDescription(stat, value, good)
    local append = good and "Up" or "Down"
    return string.format("#%s %s#Randomized per seed", stat, append)
end

local function RollBloodSample(force)

    local entry = SyringeLookup.SyringeIDs[SyringeIds.BloodSample]
    if not force and not entry then return end -- syringe wasn't chosen for this pool

    bloodRNG:SetSeed(game:GetSeeds():GetStartSeed(), 13)

    local chosen = PickWeighted(bloodOptions, bloodRNG)

    bloodGood = HasJacketOrVirgo() or bloodRNG:RandomFloat() > 0.4
    local range = bloodGood and chosen.goodRange or chosen.badRange
    local value = bloodRNG:RandomFloat()
    
    bloodEffectorValue = (range.Y - range.X) * value + range.X
    bloodEffectorValue = math.ceil(bloodEffectorValue * 20) / 20 

    bloodStat = chosen.stat
    bloodDesc = chosen.description

    if entry and entry.Card and M_SYR.CurrentRunPool[entry.CurrentRunIndex].Known then 
        M_SYR.UpdateDescription(
            entry.Card,
            FormatBloodDescription(bloodDesc, bloodEffectorValue, bloodGood), 
            "Blood Sample")
    end

    Debug.Log("Chosen stat" .. chosen.description .. ": " .. bloodEffectorValue)
end

local function UpdateBloodEffect()
    if not bloodGood and HasJacketOrVirgo() then
        RollBloodSample()
    end
end

local function ApplyBloodStat(_, player, cacheFlag)
    if bloodStat and cacheFlag == Stats[bloodStat].flag then
        Stats[bloodStat].func(player, bloodEffectorValue)
    end
end

M_SYR.EFF_TAB[SyringeIds.BloodSample] = {
	ID = SyringeIds.BloodSample,
	Type = M_SYR.TYPES.Neutral,
	Name = "Blood Sample",
	Description = "Blood Sample",
	EIDDescription = "???# Randomized per seed",
	Duration = ToFrames(10),
	
	Effect = {
        {
            Function = ApplyBloodStat,
            Callback = ModCallbacks.MC_EVALUATE_CACHE
        }
        -- TODO: on jacket
    },
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        local reaction = bloodGood and M_SYR.TYPES.Positive or M_SYR.TYPES.Negative
        React(reaction, player) 
        UpdateBloodEffect()
        UpdateCache(player, CacheFlag.CACHE_ALL)
        M_SYR.UpdateDescription(
            idx, 
            FormatBloodDescription(bloodDesc, bloodEffectorValue, bloodGood),
            "Blood Sample")
    end,

    Post = function(player)       
        UpdateCache(player, CacheFlag.CACHE_ALL)
    end
}
-- #endsyringe

-- #syringe Boss Rush

local function OnEntityTakeDamage(_, entity, amount, flags, source, countDownFrames)

    local player = M_SYR.GetPlayerUsingActive()

    if M_SYR.CheckForEffect(player, SyringeIds.BossRush) then
        local npc = entity:ToNPC()
        if npc and npc:IsBoss() and npc:IsVulnerableEnemy() and source.Entity.SpawnerType == EntityType.ENTITY_PLAYER then
            npc.HitPoints = npc.HitPoints - amount * 10 -- there is probably a better way
        end

    elseif M_SYR.CheckForEffect(player, SyringeIds.BossStrength) then
        local npc = entity:ToNPC()
        if npc and npc:IsBoss() and npc:IsVulnerableEnemy() and source.Entity.SpawnerType == EntityType.ENTITY_PLAYER then
            npc.HitPoints = npc.HitPoints + amount / 2 -- there is probably a better way 2
        end
    end

end

M_SYR.EFF_TAB[SyringeIds.BossRush] = {
	ID = SyringeIds.BossRush,
	Type = M_SYR.TYPES.Positive,
	Name = "Boss Rush",
	Description = "Boss Rush",
	EIDDescription = "\1 x2 Damage to bosses",
	Duration = ToFrames(10),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
	
	Effect = {
		{
            Function = OnEntityTakeDamage,
            Callback = ModCallbacks.MC_ENTITY_TAKE_DMG
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Positive)  
    end
}

-- #endsyringe

-- #syringe Boss Strength
-- needs a better name

M_SYR.EFF_TAB[SyringeIds.BossStrength] = {
	ID = SyringeIds.BossStrength,
	Type = M_SYR.TYPES.Positive,
	Name = "Boss Strength",
	Description = "Boss Strength",
	EIDDescription = "\1 x0.5 Damage to bosses",
	Duration = ToFrames(10),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
    -- Exclusive = true,
	
	Effect = {
		{
            Function = OnEntityTakeDamage,
            Callback = ModCallbacks.MC_ENTITY_TAKE_DMG
        }
	},
	
    OnUse = function(idx) 
        React(M_SYR.TYPES.Positive)  
    end
}

-- #endsyringe

-- #syringe Caffeine Shot
-- needs a better name

M_SYR.EFF_TAB[SyringeIds.CaffeineShot] = {
	ID = SyringeIds.CaffeineShot,
	Type = M_SYR.TYPES.Positive,
	Name = "Caffeine Shot",
	Description = "Caffeine Shot",
	EIDDescription = "\1 0.3 Speed Up\1 x0.7 Tear Delay Down\1 x1.5 Shot Speed Up",
	Duration = ToFrames(10),
	Counterpart = SyringeIds.Decaf,
	
	Effect = {
        Effect(Stat.MOVEMENT_SPEED, 0.3),
        Effect(Stat.SHOT_SPEED, 0.5),
        Effect(Stat.FIRERATE, 0.7)
	},
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        React(M_SYR.TYPES.Positive, player)  
        UpdateCache(player, CacheFlag.CACHE_SPEED | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_FIREDELAY)
    end,

    Post = function(player)       
        UpdateCache(player, CacheFlag.CACHE_SPEED | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_FIREDELAY)
    end
}

-- #endsyringe

-- #syringe Decaf

M_SYR.EFF_TAB[SyringeIds.Decaf] = {
	ID = SyringeIds.Decaf,
	Type = M_SYR.TYPES.Negative,
    Name = "Decaf",
    Description = "Decaf",
	EIDDescription = "\1 Tears Down\1Shotspeed Down",
	Duration = ToFrames(10),
	Counterpart = SyringeIds.CaffeineShot,
    -- Exclusive = true,
	
	Effect = {
        Effect(Stat.FIRERATE, 1.3),
        Effect(Stat.SHOT_SPEED, -0.3)
    },
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        React(M_SYR.TYPES.Negative, player)  
        UpdateCache(player, CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_SHOTSPEED)
    end,

    Post = function(player)       
        UpdateCache(player, CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_SHOTSPEED)
    end
}
-- #endsyringe

-- #syringe Morphine

local function ReverseControls(_, entity, hook, action)
    if not entity or entity.Type ~= EntityType.ENTITY_PLAYER then return end

    local player = entity:ToPlayer()
    local negativesBlocked = HasJacketOrVirgo(player)

    if not negativesBlocked then
    local switched = ButtonOpposites[action]
        if switched then 
            return Input.GetActionValue(switched, player.ControllerIndex)
        end
    end
end

M_SYR.EFF_TAB[SyringeIds.Morphine] = {
	ID = SyringeIds.Morphine,
	Type = M_SYR.TYPES.Positive,
	Name = "Morphine",
	Description = "Morphine",
	EIDDescription = "\1 2X Damage\1 -0.1 Shotspeed\1 Reversed Controls",
	Duration = ToFrames(10),
	Counterpart = SyringeIds.Decaf,
	
	Effect = {
        Effect(Stat.DAMAGE, 2),
        Effect(Stat.SHOT_SPEED, -0.1),
        {
            Function = ReverseControls,
            Callback = ModCallbacks.MC_INPUT_ACTION,
            Arg1 = InputHook.GET_ACTION_VALUE
        }
	},
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        React(M_SYR.TYPES.Positive, player)  
        UpdateCache(player, CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED )
    end,

    Post = function(player)       
        UpdateCache(player, CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED )
    end
}

-- #endsyringe

-- #syringe Radioactive

    
M_SYR.EFF_TAB[SyringeIds.RadioActive] = {
	ID = SyringeIds.RadioActive,
	Type = M_SYR.TYPES.Positive,
	Name = "RadioActive",
	Description = "RadioActive",
	EIDDescription = "\1 Burning #\1 x0.7 Tear Delay",
	Duration = ToFrames(10),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
	
	Effect = {
        {
            Function = RadioActiveAura.OnEntityDeath,
            Callback = ModCallbacks.MC_POST_NPC_DEATH
        }
	},
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        React(M_SYR.TYPES.Positive, player)  
        RadioActiveAura.Spawn(player)
    end
}

-- #endsyringe

-- #syringe Red Bull

local function EnableFlight (_, player, cacheFlag)
    if M_SYR.CheckForEffect(player, SyringeIds.RedBull) then
        player.CanFly = true
    end
end

local function EquipWings(player)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EnableFlight, CacheFlag.CACHE_FLYING)    
    player:AddNullCostume(mod.Costumes.RedBull)
    UpdateCache(player, CacheFlag.CACHE_FLYING)
end

local function RemoveWings()
    local player = M_SYR.GetPlayerUsingActive()

    mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, RemoveWings)
    mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, EnableFlight)

    player:TryRemoveNullCostume(mod.Costumes.RedBull)
    UpdateCache(player, CacheFlag.CACHE_FLYING)
end

local function QueueRemoveWings()
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, RemoveWings)
end

M_SYR.EFF_TAB[SyringeIds.RedBull] = {
	ID = SyringeIds.RedBull,
	Type = M_SYR.TYPES.Positive,
	Name = "Red Bull",
	Description = "Red Bull",
	EIDDescription = "\1 Grants flight",
	Duration = ToFrames(10),
	Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,
	
	Effect = {},
	
    OnUse = function(idx) 
        local player = M_SYR.GetPlayerUsingActive()
        React(M_SYR.TYPES.Positive, player)  
        UpdateCache(player, CacheFlag.CACHE_FLYING)
        EquipWings(player)
    end,

    Post = function(player)       
        UpdateCache(player, CacheFlag.CACHE_FLYING)
        QueueRemoveWings()
    end
}

-- #endsyringe

-- #region testing and debug and random stuff, delete before release

local testSyringes = {}

mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, str, params)
    if str == "heart" then
        local res, val = LastHeart(Isaac.GetPlayer(0))
        print(tostring(res) .. " " .. val)
    end

    if str == "syr" then

        Debug.ReplaceSyringePool()

        Isaac.ExecuteCommand("syringes.revealall")
        Isaac.ExecuteCommand("debug 8")
        Isaac.ExecuteCommand("debug 3")

        for _, color in ipairs(testSyringes) do
            Isaac.ExecuteCommand("spawn 5.300." .. color)
        end

    end
end)
        
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if game:GetFrameCount() % 15 == 0 then
        -- HeartShield.Spawn(Vector(160, 100))
    end
end)

-- #endregion

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    PopulateSyringeLookup()
    RollBloodSample()

    local color = Color(1, 1, 1, 1, 0, 0, 0)
    color:SetColorize(4, 0, 4, 1)

    print(string.format("%s, %s, %s, %s, %s, %s, %s", color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO))
end)