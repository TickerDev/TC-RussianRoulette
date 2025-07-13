local currentProp          = nil
local idleDict, idleAnim   = 'reaction@intimidation@1h', 'idle_a'
local clickDict, clickAnim = 'mp_suicide', 'pistol'
local gunHash              = `w_pi_revolver`

local function loadDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end
local function loadModel(hash)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
end
local function detachGun()
    if DoesEntityExist(currentProp) then DeleteEntity(currentProp) end
    ClearPedTasksImmediately(PlayerPedId())
    currentProp = nil
end

local function attachGunIdle()
    detachGun()
    loadModel(gunHash)
    loadDict(idleDict)
    local p = PlayerPedId()
    currentProp = CreateObject(gunHash, 0, 0, 0, true, true, false)
    AttachEntityToEntity(currentProp, p, GetPedBoneIndex(p, 57005),
        0.1, 0.0, 0.0, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetCurrentPedWeapon(p, `weapon_unarmed`, true)
    TaskPlayAnim(p, idleDict, idleAnim, 8.0, -8.0, -1, 49, 0, false, false, false)
end



local function playClickAnim()
    loadDict(clickDict)
    local p = PlayerPedId()
    TaskPlayAnim(p, clickDict, clickAnim, 8.0, -8.0, 750, 50, 0, false, false, false)
    Wait(750)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 'revolver_click', 0.6)
    ClearPedTasksImmediately(p)
    Wait(1000)
    detachGun()
end


local function playBangAnim()
    loadDict(clickDict)
    local p = PlayerPedId()
    TaskPlayAnim(p, clickDict, clickAnim, 8.0, -8.0, 1500, 50, 0, false, false, false)
    Wait(700)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 'revolver_shoot', 1.0)
    Wait(800)
    if DoesEntityExist(currentProp) then DeleteEntity(currentProp) end
    SetEntityHealth(p, 0)
end




local isInRR      = false
local myTurn      = false
local opponentId  = nil
local textUIShown = false


CreateThread(function()
    while true do
        if isInRR then
            DisableAllControlActions(0)
            EnableControlAction(0, Keybinds['Shoot'], true)
            EnableControlAction(0, Keybinds['Forfeit'], true)
        end
        Wait(0)
    end
end)

local function showTurnUI(turn)
    if turn then
        lib.showTextUI('[F5] Shoot gun\n[F6] Forfeit', { position = 'bottom-center' })
        textUIShown = true
    elseif textUIShown then
        lib.hideTextUI()
        textUIShown = false
    end
end

RegisterCommand('rroulette', function()
    local ped = PlayerPedId()
    if GetEntityHealth(ped) <= 0 then return end
    local currentWeapon = GetSelectedPedWeapon(ped)
    if not RevolverHashes[currentWeapon] then
        lib.notify({ title = 'Russian Roulette', description = 'You need to be holding a revolver', type = 'error' })
        return
    end
    local players = GetActivePlayers()
    local closest, dist = nil, 9999.0
    local myCoords = GetEntityCoords(ped)

    for _, pid in pairs(players) do
        if pid ~= PlayerId() then
            local tgtPed = GetPlayerPed(pid)
            local d = #(myCoords - GetEntityCoords(tgtPed))
            if d < dist and d < 3.0 then
                dist = d
                closest = GetPlayerServerId(pid)
            end
        end
    end

    if not closest then
        lib.notify({ title = 'Russian Roulette', description = 'No nearby player found', type = 'error' })
    else
        TriggerServerEvent('TC-RussianRoulette:sendRequest', closest)
        lib.notify({ title = 'Russian Roulette', description = 'Invite sent', type = 'info' })
    end
end, false)


RegisterNetEvent('TC-RussianRoulette:receiveRequest', function(fromId)
    local result = lib.alertDialog({
        header = 'Russian Roulette Invite',
        content = ('Player %d wants to play. Accept?'):format(fromId),
        centered = true,
        cancel = true
    })
    if result == 'confirm' then
        TriggerServerEvent('TC-RussianRoulette:accepted', fromId)
    else
        TriggerServerEvent('TC-RussianRoulette:declined', fromId)
    end
end)

RegisterNetEvent('TC-RussianRoulette:declineNotice', function(declinerId)
    lib.notify({ title = 'Russian Roulette', description = ('Player %d declined'):format(declinerId), type = 'error' })
end)


RegisterNetEvent('TC-RussianRoulette:startGame', function(otherId, firstTurn)
    isInRR     = true
    opponentId = otherId
    myTurn     = (firstTurn == GetPlayerServerId(PlayerId()))

    if myTurn then
        attachGunIdle()
        showTurnUI(true)
    end

    lib.notify({ title = 'Russian Roulette', description = 'Game started!', type = 'success' })
end)


RegisterNetEvent('TC-RussianRoulette:yourTurn', function()
    myTurn = true
    attachGunIdle()
    showTurnUI(true)
end)


CreateThread(function()
    while true do
        if isInRR and myTurn then
            if IsControlJustReleased(0, Keybinds['Shoot']) then
                myTurn = false
                showTurnUI(false)
                TriggerServerEvent('TC-RussianRoulette:shoot')
            elseif IsControlJustReleased(0, Keybinds['Forfeit']) then
                showTurnUI(false)
                detachGun()
                isInRR = false
                TriggerServerEvent('TC-RussianRoulette:forfeit')
            end
        end
        Wait(0)
    end
end)

RegisterNetEvent('TC-RussianRoulette:shotResult', function(shooter, killed)
    local me = GetPlayerServerId(PlayerId())


    if shooter == me then
        if killed then
            playBangAnim()
        else
            playClickAnim()
        end
    end


    if killed then
        lib.notify({
            title = 'Bang!',
            description = (shooter == me and 'You died!' or ("opponent" .. ' died!')),
            type = 'error'
        })
        isInRR = false
        showTurnUI(false)
        if shooter ~= me then
            detachGun()
            FreezeEntityPosition(PlayerPedId(), false)
        end
    else
        lib.notify({
            title = 'Click',
            description = (shooter == me and 'Click… you survived.' or "opponent" .. ' survived.'),
            type = 'info'
        })
    end
end)

RegisterNetEvent('TC-RussianRoulette:forfeitNotice', function(looserId)
    if looserId ~= GetPlayerServerId(PlayerId()) then
        lib.notify({ title = 'Russian Roulette', description = 'Opponent forfeited – you win!', type = 'success' })
    end
    showTurnUI(false)
    detachGun()
    FreezeEntityPosition(PlayerPedId(), false)
    isInRR = false
end)

RegisterNetEvent('TC-RussianRoulette:opponentLeft', function()
    lib.notify({ title = 'Russian Roulette', description = 'Opponent left – game cancelled', type = 'error' })
    showTurnUI(false)
    detachGun()
    FreezeEntityPosition(PlayerPedId(), false)
    isInRR = false
end)

lib.callback.register("TC-RussianRoulette:GetHeadingFromVector_2d", function(dx, dy)
    return GetHeadingFromVector_2d(dx, dy)
end)
