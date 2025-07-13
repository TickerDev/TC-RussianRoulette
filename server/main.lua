local games = {}
local pendingRequests = {}


RegisterNetEvent('TC-RussianRoulette:sendRequestToClosest', function()
    local src = source
    local closestPlayer = lib.callback.await("TC-RussianRoulette:GetClosestPlayer", src)
    if not closestPlayer then
        lib.notify(src, { title = 'Russian Roulette', description = 'No nearby player found', type = 'error' })
        return
    end
    if pendingRequests[src] then
        lib.notify(src,
            { title = 'Russian Roulette', description = 'You already have a pending request', type = 'error' })
        return
    end

    pendingRequests[src] = true
    SetTimeout(15000, function()
        pendingRequests[src] = nil
    end)
    print(closestPlayer)
    lib.notify(src, { title = 'Russian Roulette', description = 'Invite sent', type = 'info' })
    TriggerClientEvent('TC-RussianRoulette:receiveRequest', closestPlayer, src)
end)


RegisterNetEvent('TC-RussianRoulette:declined', function(challengerId)
    local src = source
    if pendingRequests[src] then
        pendingRequests[src] = nil
        TriggerClientEvent('TC-RussianRoulette:declineNotice', challengerId, src)
    end
end)
local function makeEntityFaceEntity(source, entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)


    local dx1 = p2.x - p1.x
    local dy1 = p2.y - p1.y
    local heading1 = lib.callback.await('TC-RussianRoulette:GetHeadingFromVector_2d', source, dx1, dy1)
    SetEntityHeading(entity1, heading1)


    local dx2 = p1.x - p2.x
    local dy2 = p1.y - p2.y
    local heading2 = lib.callback.await('TC-RussianRoulette:GetHeadingFromVector_2d', source, dx2, dy2)
    SetEntityHeading(entity2, heading2)
end


RegisterNetEvent('TC-RussianRoulette:accepted', function(challengerId)
    local accepter      = source
    local challengerPed = GetPlayerPed(challengerId)
    local accepterPed   = GetPlayerPed(accepter)


    if not challengerPed or not accepterPed then return end

    if not pendingRequests[challengerId] then
        lib.notify(accepter,
            {
                title = 'Russian Roulette',
                description = 'Something went wrong, please ask for another invite',
                type = 'error'
            })
        return
    end
    pendingRequests[challengerId] = nil

    makeEntityFaceEntity(source, challengerPed, accepterPed)

    FreezeEntityPosition(challengerPed, true)
    FreezeEntityPosition(accepterPed, true)

    games[challengerId] = { p1 = challengerId, p2 = accepter, turn = challengerId }

    TriggerClientEvent('TC-RussianRoulette:startGame', challengerId, accepter, challengerId)
    TriggerClientEvent('TC-RussianRoulette:startGame', accepter, challengerId, challengerId)
end)


RegisterNetEvent('TC-RussianRoulette:shoot', function()
    local shooter = source
    local game
    for k, v in pairs(games) do
        if v.p1 == shooter or v.p2 == shooter then
            game = v
            break
        end
    end
    if not game or game.turn ~= shooter then return end


    local hit = (math.random(1, 6) == math.random(1, 6))

    if hit then
        TriggerClientEvent('TC-RussianRoulette:shotResult', game.p1, shooter, true)
        TriggerClientEvent('TC-RussianRoulette:shotResult', game.p2, shooter, true)
        games[game.p1] = nil
    else
        local nextTurn = (shooter == game.p1) and game.p2 or game.p1
        game.turn = nextTurn
        TriggerClientEvent('TC-RussianRoulette:shotResult', game.p1, shooter, false)
        TriggerClientEvent('TC-RussianRoulette:shotResult', game.p2, shooter, false)
        TriggerClientEvent('TC-RussianRoulette:yourTurn', nextTurn)
    end
end)


RegisterNetEvent('TC-RussianRoulette:forfeit', function()
    local quitter = source
    local game
    for k, v in pairs(games) do
        if v.p1 == quitter or v.p2 == quitter then
            game = v
            break
        end
    end
    if not game then return end
    local winner = (quitter == game.p1) and game.p2 or game.p1
    TriggerClientEvent('TC-RussianRoulette:forfeitNotice', winner, quitter)
    TriggerClientEvent('TC-RussianRoulette:forfeitNotice', quitter, quitter)
    games[game.p1] = nil
end)

AddEventHandler('playerDropped', function(id)
    for k, v in pairs(games) do
        if v.p1 == id or v.p2 == id then
            local other = (v.p1 == id) and v.p2 or v.p1
            TriggerClientEvent('TC-RussianRoulette:opponentLeft', other)
            games[k] = nil
        end
    end
end)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for k, v in pairs(games) do
            TriggerClientEvent('TC-RussianRoulette:gameEnded', v.p1, 'Resource stopped')
            TriggerClientEvent('TC-RussianRoulette:gameEnded', v.p2, 'Resource stopped')

            local p1Ped = GetPlayerPed(v.p1)
            local p2Ped = GetPlayerPed(v.p2)
            if p1Ped then FreezeEntityPosition(p1Ped, false) end
            if p2Ped then FreezeEntityPosition(p2Ped, false) end
        end

        games = {}
    end
end)
