local mod = extraSyringes
local game = Game()
local rng = RNG()

M_SYR.EFF_TAB[mod.Syringes.RatPoison] = {
    ID = mod.Syringes.RatPoison,
    Type = M_SYR.TYPES.Negative,
    Name = "Rat Poison",
    Description = "",
    EIDDescription = "",
    Duration = 450,
    Counterpart = M_SYR.TOT_SYR.DPSDampener,
    Weight = 1,
    
    Effect = {
        [1] = {
             Function = function(_)
                if mod:IsCorrectSyringe(player, mod.Syringes.RatPoison) and game:GetFrameCount() % 6 == 0 then
                    if(rng:RandomFloat() > 0.5) then
                        position = mod:FindRandomPoopLocation()
                        if position then
                            Isaac.GridSpawn(GridEntityType.GRID_POOP, 1, position, false)
                        end
                    end
                end
            end,
            Callback = ModCallbacks.MC_POST_UPDATE 
       }
    },
    
    OnUse = function(idx)
        local player = M_SYR.GetPlayerUsingActive()
        mod:NegativeFeedback(player)
    end
}

function mod:FindRandomPoopLocation()
    -- TODO: dont spawn in doorways
    minRange = 75
    maxRange = 125

    room = game:GetRoom()
    gridSize = room:GetGridSize()
    local player = M_SYR.GetPlayerUsingActive()

    local possibleTargets = {}
    local length = 0

    for i = 0, gridSize do
        if not room:GetGridEntity(i) then 
            local distance = room:GetGridPosition(i):Distance(player.Position)
            if distance > minRange and distance < maxRange then
                table.insert(possibleTargets, i)
                length = length + 1
            end
        end
    end

    if(length > 0) then
        return room:GetGridPosition(possibleTargets[math.random(1, length - 1)])
    else 
        return false
    end

end