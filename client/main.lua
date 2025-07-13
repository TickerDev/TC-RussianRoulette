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
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2, 'revolver_click', 0.6)
    ClearPedTasksImmediately(p)
    Wait(1000)
    detachGun()
end


local function playBangAnim()
    loadDict(clickDict)
    local p = PlayerPedId()
    TaskPlayAnim(p, clickDict, clickAnim, 8.0, -8.0, 1500, 8, 0, false, false, false)
    Wait(700)
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2, 'revolver_shoot', 1.0)
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
        end
        Wait(0)
    end
end)

local function showTurnUI(turn)
    if turn then
        local key1 = GetControlInstructionalButton(2, joaat("turnShoot"), true)
        local key2 = GetControlInstructionalButton(2, joaat("turnForfeit"), true)
        local keyName1 = TranslateKey(key1)
        local keyName2 = TranslateKey(key2)
        lib.showTextUI('[' .. keyName1 .. '] Shoot gun\n[' .. keyName2 .. '] Forfeit', { position = 'bottom-center' })
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

    TriggerServerEvent("TC-RussianRoulette:sendRequestToClosest")
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
    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
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
lib.callback.register("TC-RussianRoulette:GetClosestPlayer", function()
    return GetPlayerServerId(lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 3.0, false))
end)
local function turnShoot()
    if isInRR and myTurn then
        myTurn = false
        showTurnUI(false)
        TriggerServerEvent('TC-RussianRoulette:shoot')
    end
end
RegisterCommand("turnShoot", function()
    turnShoot()
end, false)
RegisterKeyMapping("turnShoot", "Perform shooting in Russian Roulette", "keyboard", Keybinds['Shoot'])
local function turnForfeit()
    if isInRR and myTurn then
        showTurnUI(false)
        detachGun()
        isInRR = false
        TriggerServerEvent('TC-RussianRoulette:forfeit')
    end
end
RegisterCommand("turnForfeit", function()
    turnForfeit()
end, false)
RegisterKeyMapping("turnForfeit", "Forfeit from Russian Roulette", "keyboard", Keybinds['Forfeit'])
