local currentGps = vector3(0,0,0)
local Callback = exports.plouffe_lib:Get("Callback")
local Utils = exports.plouffe_lib:Get("Utils")

function VineFnc:Start()
    TriggerEvent('ooc_core:getCore', function(Core)
        while not Core.Player:IsPlayerLoaded() do
            Wait(500)
        end

        Vine.Player = Core.Player:GetPlayerData()

        self:ExportsAllZones()
        self:RegisterAllEvents()

        if self:IsVineJob(true) then
            self:RegisterKeys()
        elseif self:IsVineJob() then
            self:ActivateOfflineDelivery()
        end
    end)
end

function VineFnc:ExportsAllZones()
    for k,v in pairs(Vine.StartJobCoords) do
        exports.plouffe_lib:ValidateZoneData(v)
    end
end

function VineFnc:RegisterAllEvents()
    AddEventHandler('plouffe_lib:setGroup', function(data)
        Vine.Player[data.type] = data

        if self:IsVineJob(true) then
            self:RegisterKeys()
        end
    end)

    RegisterNetEvent("plouffe_lib:inVehicle", function(inVehicle, vehicleId)
        Vine.Utils.inCar = inVehicle
        Vine.Utils.carId = vehicleId
    end)

    RegisterNetEvent("plouffe_lib:hasWeapon", function(isArmed, weaponHash)
        Vine.Utils.isArmed = isArmed
        Vine.Utils.currentWeaponHash = weaponHash
    end)

    RegisterNetEvent("on_vineyard", function(p)
        if self:IsVineJob(false) then
            if self[p.fnc] then
                self[p.fnc](self,p)
            end
        end
    end)

    RegisterNetEvent("plouffe_vineyard:doCOOLstuff", function(p)
        if self:IsVineJob(false) then
            if self[p.fnc] then
                self[p.fnc](self)
            end
        end
    end)

    RegisterNetEvent("plouffe_vineyard:playpickupanim", function()
        self:PlayAnim("anim","pickup_object","pickup_low",1,false,true,nil)
        Wait(500)
        Vine.Utils.forceAnim = false
    end)

    RegisterNetEvent("plouffe_vineyard:ClientCallback", function(data)
        if data.fnc then
            if self[data.fnc] then
                TriggerServerEvent("plouffe_vineyard:ClientCallback:server", data, self[data.fnc](self,data))
            end
        end
    end)

    RegisterNetEvent("plouffe_vineyard:sync_new_barrel", function(data)
        self:CreateNewBarrel(data)
    end)

    RegisterNetEvent("plouffe_vineyard:enteredVineyard", function(data)
        Vine.Utils.inVineyard = true
        self:CreateAllBarrels()
        self:StartVineyardThread()
    end)

    RegisterNetEvent("plouffe_vineyard:leftVineyard", function(data)
        Vine.Utils.inVineyard = false
        self:DeleteAllBarrels()
    end)

    RegisterNetEvent("plouffe_vineyard:on_barrel_usage", function(item)
        self:UseBarrel(item)
    end)

    RegisterNetEvent("plouffe_vineyard:updatebarrelFromIndex", function(barrelIndex, barrelData)
        if Vine.Barrels[barrelIndex] then
            Vine.Barrels[barrelIndex] = barrelData
        end
    end)

    RegisterNetEvent("plouffe_vineyard:removeBarrel", function(barrelIndex, id)
        self:DeleteBarrel(barrelIndex)
    end)

    RegisterNetEvent("plouffe_vineyard:activateDelivery", function(index)
        exports.plouffe_lib:ValidateZoneData(Vine.DeliveryCoords[index])
        currentGps = Vine.DeliveryCoords[index].coords
    end)

    RegisterCommand("livraison", function()
        SetNewWaypoint(currentGps.x, currentGps.y)
        Utils:Notify("Gps placé!")
    end)

    RegisterNetEvent("plouffe_vineyard:cancelDelivery", function(index)
        exports.plouffe_lib:DestroyZone(index)
    end)
end

function VineFnc:ActivateOfflineDelivery()
    for k,v in pairs(Vine.DeliveryCoords) do
        if v.active then
            exports.plouffe_lib:ValidateZoneData(v)
        end
    end
end

function VineFnc:CreateAllBarrels()
    VineFnc:AssureModel(Vine.barrelHash)
    for k,v in pairs(Vine.Barrels) do
        v.propId = CreateObject(Vine.barrelHash, v.coords, false, true, false)
    end
end

function VineFnc:DeleteAllBarrels()
    for k,v in pairs(Vine.Barrels) do
        DeleteEntity(v.propId)
    end
end

function VineFnc:CreateNewBarrel(data)
    if exports.plouffe_lib:IsInZone("vineyard") then
        VineFnc:AssureModel(Vine.barrelHash)
        data.propId = CreateObject(Vine.barrelHash, data.coords, false, true, false)
    end
    table.insert(Vine.Barrels,data)
end

function VineFnc:DeleteBarrel(barrelIndex)
    if Vine.Barrels[barrelIndex] and DoesEntityExist(Vine.Barrels[barrelIndex].propId) then
        local barrelStr = "barrel_"..tostring(barrelIndex)
        DeleteEntity(Vine.Barrels[barrelIndex].propId)
        exports.plouffe_lib:HideNotif(barrelStr)
        Vine.Utils.shownNotifs[barrelStr] = nil
        table.remove(Vine.Barrels,barrelIndex)
    end
end

function VineFnc:GetarrayLenght(a)
    local cb = 0
    for k,v in pairs(a) do
        cb = cb + 1
    end
    return cb
end

function VineFnc:AlphabeticArray(a)
    local sortedArray = {}
    local indexArray = {}
    local elements = {}

    for k,v in pairs(a) do
        if v.label then
            sortedArray[v.label] = v
            table.insert(indexArray, v.label)
        end
    end

    table.sort(indexArray)

    for k,v in pairs(indexArray) do
        table.insert(elements, sortedArray[v])
    end

    for k,v in pairs(elements) do
        if v.count then
            v.label = v.label.." x "..tostring(v.count)
        elseif v.amount then
            v.label = v.label.." x "..tostring(v.amount)
        end
    end

    return elements
end

function VineFnc:RequestModel(model)
    CreateThread(function()
        RequestModel(model)
    end)
end

function VineFnc:RequestAnimDict(dict)
    CreateThread(function()
        RequestAnimDict(dict)
    end)
end

function VineFnc:AssureModel(model)
    local maxTimes,currentTime = 5000, 0
    VineFnc:RequestModel(model)
    while not HasModelLoaded(model) and currentTime < maxTimes do
        VineFnc:RequestModel(model)
        Wait(0)
        currentTime = currentTime + 1
    end
    return HasModelLoaded(model)
end

function VineFnc:PlayAnim(type,dict,anim,flag,disablemovement,removeweapon,createprop)
    Vine.Utils.forceAnim = true
    Vine.Utils.ped = PlayerPedId()
    Vine.Utils.pedCoords = GetEntityCoords(Vine.Utils.ped)
    local ped = Vine.Utils.ped
    local pedCoords = Vine.Utils.pedCoords

    if createprop then
        local attachCoords = vector3(0,0,0)
        local hash = GetHashKey(createprop.prop)
        local boneindx = GetPedBoneIndex(ped, createprop.bone)

        VineFnc:RequestModel(hash)

        while not HasModelLoaded(hash) do
            Wait(0)
        end

        Vine.Utils.currentProp = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z + 0.2,  true,  true, true)
        -- table.insert(Vine.Utils.currentPropList, Vine.Utils.currentProp)

        SetEntityCollision(Vine.Utils.currentProp, false, true)
        AttachEntityToEntity(Vine.Utils.currentProp, ped, boneindx, createprop.placement.x, createprop.placement.y, createprop.placement.z, createprop.placement.xR, createprop.placement.yR, createprop.placement.zR, true, true, false, true, 1, true)
    end

    if removeweapon then
        if IsPedArmed(ped,7) then
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            Wait(1900)
        end
    end

    if type == "anim" then
        VineFnc:RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            VineFnc:RequestAnimDict(dict)
            Wait(0)
        end

        if not IsEntityPlayingAnim(ped, dict, anim, 3) then
            TaskPlayAnim(ped, dict, anim, 50.0, 0, -1, flag, 0, false, false, false)
        end

        CreateThread(function()
            while Vine.Utils.forceAnim do
                Wait(0)

                if IsPedDeadOrDying(ped, true) then
                    break
                end
                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 50.0, 0, -1, flag, 0, false, false, false)
                end
            end

            Wait(250)

            StopAnimTask(ped, dict, anim, 1.0)
        end)
    elseif type == "scenario" then
        TaskStartScenarioInPlace(ped, dict, 0, true)

        CreateThread(function()
            while Vine.Utils.forceAnim do
                Wait(0)

                if IsPedDeadOrDying(ped, true) then
                    break
                end
            end

            ClearPedTasks(ped)

            if Vine.FoodTruck.intruck then
                Vine.Utils.reAttachToTruck = true
            end
        end)
    end

    CreateThread(function()
        while Vine.Utils.forceAnim do
            Wait(0)

            if disablemovement then
                if IsPedDeadOrDying(ped, true) then
                    break
                end
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
                DisableControlAction(0, 21, true)
            else
                break
            end
        end
    end)
end

function VineFnc:HarvestAnim()
    CreateThread(function()
        repeat
            VineFnc:PlayAnim("anim","mp_ped_interaction","handshake_guy_b",2,true,true,nil)
            Wait(3300)
            Vine.Utils.forceAnim = false
            Wait(500)
        until not Vine.Utils.harvesting
    end)
end

function VineFnc:ScanForHarvest()
    Vine.Utils.ped = PlayerPedId()
    Vine.Utils.pedCoords = GetEntityCoords(Vine.Utils.ped)
    local retval, hit, endCoords, surfaceNormal, entityHit = 0,0,0,0,0
    local xO = GetOffsetFromEntityInWorldCoords(Vine.Utils.ped, 0.0, 2.5, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        Vine.Utils.pedCoords.x, Vine.Utils.pedCoords.y, Vine.Utils.pedCoords.z,
        xO.x, xO.y, xO.z,
        1,
        Vine.Utils.ped,
        1
    )

    retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 then
        return true
    end

    return false
end

function VineFnc:Harvest(params)
    if Vine.Utils.harvesting then
        return
    end

    if not self:ScanForHarvest() then
        return Utils:Notify("error", "Aucune plantation trouver")
    end

    local canHarvest = Callback:Sync("plouffe_vineyard:CanHarvestThere", Vine.Utils.MyAuthKey)

    if not canHarvest then
        return Utils:Notify("error", "Il n'y a plus rien a ramasser ici")
    end

    Vine.Utils.harvesting = true

    self:HarvestAnim()

    Utils:ProgressCircle({
        name = "harvesting_grapes",
        duration = 20000,
        label = 'Ramassage en cours',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    }, function(cancelled)
        Vine.Utils.harvesting = false
        Vine.Utils.forceAnim = false
        if not cancelled then
            TriggerServerEvent("plouffe_vineyard:harvestedZone", params.zone, Vine.Utils.MyAuthKey)
        else
            TriggerServerEvent("plouffe_vineyard:removeTempHarvest",Vine.Utils.MyAuthKey)
        end
    end)
end

function VineFnc.Effralage(item)
    if exports.plouffe_lib:IsInZone("vineyard_water") then
        local dict = "amb@world_human_bum_wash@male@high@idle_a"
        local anim = "idle_a"
        local flag = 1
        local disablemovement = false
        local removeweapon = true

        VineFnc:PlayAnim("anim",dict,anim,flag,disablemovement,removeweapon)

        Utils:ProgressCircle({
            name = "effralage_grapes",
            duration = 15000,
            label = 'Éraflage en cours',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            Vine.Utils.forceAnim = false
            if not cancelled then
                TriggerServerEvent("plouffe_vineyard:effralage", item, Vine.Utils.MyAuthKey)
            end
        end)
    else
        Utils:Notify("error", "Vous avez besoin de la source d'eau du vignoble")
    end
end

function VineFnc:IsVineJob(off)
    if off and Vine.Player.job and (Vine.Player.job.name == "vineyardoff" or Vine.Player.job.name == "vineyard") then
        return true
    elseif not off and Vine.Player.job and Vine.Player.job.name == "vineyard" then
        return true
    end
    return false
end

function VineFnc:GetClosestVehicle()
    Vine.Utils.ped = PlayerPedId()
    Vine.Utils.pedCoords = GetEntityCoords(Vine.Utils.ped)
	local plyOffset = GetOffsetFromEntityInWorldCoords(Vine.Utils.ped, 0.0, 1.0, 0.0)
	local radius = 5.0
	local rayHandle = StartShapeTestCapsule(Vine.Utils.pedCoords.x, Vine.Utils.pedCoords.y, Vine.Utils.pedCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, radius, 10, Vine.Utils.ped, 7)
	local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
	return vehicle
end

function VineFnc:StompGrape()
    exports.ooc_menu:Open(Vine.Menu.selectStomp, function(params)
        if not params then
            return
        end

        if VineFnc:GetItemCount(params.item) >= Vine.StompItems.minimum[params.item] then
            VineFnc:PlayAnim("anim","amb@world_human_jog_standing@male@base","base",1,false,true,nil)
            Utils:ProgressCircle({
                name = "fouling_barel",
                duration = 30000,
                label = 'Foulage en cours..',
                useWhileDead = false,
                canCancel = true,
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(cancelled)
                Vine.Utils.forceAnim = false
                if not cancelled then
                    TriggerServerEvent("plouffe_vineyard:foulageDone",params.item,Vine.Utils.MyAuthKey)
                end
            end)
        else
            Utils:Notify("error", "Vous n'avez pas asser de raisins")
        end
    end)
end

function VineFnc:GetItemCount(item)
    local count = exports.ox_inventory:Search(2, item)
    count = count and count or 0
    return count, item
end

function VineFnc:GetBarrel()
    if VineFnc:IsVineJob() then
        Utils:ProgressCircle({
            name = "taking_barel",
            duration = 5000,
            label = 'Prendre un baril..',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            if not cancelled then
                TriggerServerEvent("plouffe_vineyard:getBarrel",Vine.Utils.MyAuthKey)
            end
        end)
    end
end

function VineFnc:GetOffSetAndPlayAnim(dick)
    Vine.Utils.ped = PlayerPedId()
    local offSet = GetOffsetFromEntityInWorldCoords(Vine.Utils.ped, 0.0, 0.75, -1.05)
    CreateThread(function()
        VineFnc:PlayAnim("anim","pickup_object","pickup_low",1,false,true,nil)
        Wait(500)
        Vine.Utils.forceAnim = false
    end)
    return offSet
end

function VineFnc.UseBarrel(item)
    local weightStr = item.metadata and item.metadata.description and item.metadata.description:gsub(" litres","")

    if not weightStr then
       return Utils:Notify("error", "Ce baril n'est pas présentement plein "..tostring(0).."/100")
    end

    for k,v in pairs(Vine.BarilInfo.desc) do
        weightStr = weightStr:gsub(("%s %s"):format("de", v),"")
    end

    local weight = tonumber(weightStr) or 0

    if weight and weight < 100 then
        return Utils:Notify("error", "Ce baril n'est pas présentement plein "..tostring(0).."/100")
    end

    TriggerServerEvent("plouffe_vineyard:usebarrel", item, Vine.Utils.MyAuthKey)
end
function VineFnc:GetClosestBarrel()
    Vine.Utils.ped = PlayerPedId()
    Vine.Utils.pedCoords = GetEntityCoords(Vine.Utils.ped)
    local dst,closest,index = 2, nil, nil

    for k,v in pairs(Vine.Barrels) do
        local dstCheck = #(Vine.Utils.pedCoords - v.coords)
        if dstCheck < dst then
            dst,closest,index = dstCheck, v, k
        end
    end

    return closest, index
end

function VineFnc:StartVineyardThread()
    Wait(1000)

    if Vine.Utils.inVineyardThread or not VineFnc:IsVineJob(true) then
        return
    end

    Vine.Utils.inVineyardThread = true

    CreateThread(function()
        local str = "barrel_"
        while Vine.Utils.inVineyardThread and Vine.Utils.inVineyard and VineFnc:IsVineJob(true) do
            local sleepTimer = 500
            Vine.Utils.ped = PlayerPedId()
            Vine.Utils.pedCoords = GetEntityCoords(Vine.Utils.ped)

            for k,v in pairs(Vine.Barrels) do
                local dstCheck = #(Vine.Utils.pedCoords - v.coords)
                local barrelStr = str..tostring(k)
                local txt = "[E] pour intéragir avec le baril de "

                if not Vine.Utils.shownNotifs[barrelStr] and dstCheck <= 1.5 then
                    sleepTimer = 0
                    Vine.Utils.shownNotifs[barrelStr] = true
                    exports.plouffe_lib:ShowNotif("blue",barrelStr,txt..tostring(v.type))
                elseif dstCheck > 2 and Vine.Utils.shownNotifs[barrelStr] then
                    Vine.Utils.shownNotifs[barrelStr] = nil
                    exports.plouffe_lib:HideNotif(barrelStr)
                end
            end
            Wait(sleepTimer)
        end

        Vine.Utils.inVineyardThread = false

        for k,v in pairs(Vine.Utils.shownNotifs) do
            exports.plouffe_lib:HideNotif(k)
        end

        Vine.Utils.shownNotifs = {}
    end)
end

function VineFnc:RegisterKeys()
    if Vine.Utils.keysRegistered then
        return
    end

    RegisterCommand("+barrelInteract", function()
        if not LocalPlayer.state.dead and not LocalPlayer.state.cuffed then
            local closestBarrel, barrelIndex = VineFnc:GetClosestBarrel()

            if closestBarrel then
                VineFnc:OpenBarrelInteracionMenu(closestBarrel, barrelIndex)
            end
        end
    end)

    RegisterCommand("-barrelInteract", function()

    end)

    RegisterKeyMapping('+barrelInteract', 'Intéragir avec un baril', 'keyboard', 'E')

    Vine.Utils.keysRegistered = true
end

function VineFnc:InspectBarrel(params,closestBarrel,barrelIndex)
    ExecuteCommand("e inspect")
    Utils:ProgressCircle({
        name = "inspecting_barrel",
        duration = 7000,
        label = 'Inspection en cours',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    }, function(cancelled)
        ExecuteCommand("e c")
        if not cancelled then
           TriggerServerEvent("plouffe_vineyard:inspectbarrel", barrelIndex, Vine.Utils.MyAuthKey)
        end
    end)
end

function VineFnc:OpenBarrelInteracionMenu(closestBarrel,barrelIndex)
    exports.ooc_menu:Open(Vine.Menu.barrelInteract, function(params)
        if not params then
            return
        end

        if self[params.fnc] then
            self[params.fnc](self,params,closestBarrel,barrelIndex)
        end
    end)
end

function VineFnc:OpenBarrelStatus(pasedParams,closestBarrel,barrelIndex)
    local menuData = {
        {
            id = 1,
            header = "Levure",
            txt = tostring(closestBarrel.data.yeast).." / "..tostring(Vine.BarrelTypes[closestBarrel.data.grapeType].maxYeast),
            params = {
                event = "",
                args = {
                    fnc = "pinis"
                }
            }
        },
        {
            id = 2,
            header = "Sucre",
            txt = tostring(closestBarrel.data.sugar).." / "..tostring(Vine.BarrelTypes[closestBarrel.data.grapeType].maxSugar),
            params = {
                event = "",
                args = {
                    fnc = "pinis"
                }
            }
        },
        {
            id = 3,
            header = "Retour",
            txt = "Vous renvoie au menu précédent",
            params = {
                event = "",
                args = {
                    fnc = "pinis"
                }
            }
        }
    }

    exports.ooc_menu:Open(menuData, function(params)
        if not params then
            return
        end

        if self[params.fnc] then
            self[params.fnc](self,params,closestBarrel,barrelIndex)
        elseif params.fnc == "pinis" then
            self:OpenBarrelInteracionMenu(closestBarrel,barrelIndex)
        end
    end)
end

function VineFnc:AddSugar(params,closestBarrel,barrelIndex)
    if VineFnc:GetItemCount("wine_sugar") > 0 then
        ExecuteCommand("e mechanic")
        Utils:ProgressCircle({
            name = "add_sugar_to_barrel",
            duration = 7000,
            label = 'Ajout en cours...',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            ExecuteCommand("e c")
            if not cancelled then
                TriggerServerEvent("plouffe_vineyard:addSugarToBarrel", barrelIndex, closestBarrel.id, Vine.Utils.MyAuthKey)
            end
        end)
    else
        Utils:Notify("error","Vous n'avez pas le néscéssaire pour faire cela",5000)
    end
end

function VineFnc:AddYeast(params,closestBarrel,barrelIndex)
    if VineFnc:GetItemCount("wine_yeast") > 0 then
        ExecuteCommand("e mechanic")
        Utils:ProgressCircle({
            name = "add_yeast_to_barrel",
            duration = 7000,
            label = 'Ajout en cours...',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            ExecuteCommand("e c")
            if not cancelled then
                TriggerServerEvent("plouffe_vineyard:addYeastToBarrel", barrelIndex, closestBarrel.id, Vine.Utils.MyAuthKey)
            end
        end)
    else
        Utils:Notify("error","Vous n'avez pas le néscéssaire pour faire cela",5000)
    end
end

function VineFnc:DestroyBarrel(params,closestBarrel,barrelIndex)
    ExecuteCommand("e mechanic")
    Utils:ProgressCircle({
        name = "destroying_barrel",
        duration = 10000,
        label = 'Destruction en cours',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    }, function(cancelled)
        ExecuteCommand("e c")
        if not cancelled then
            TriggerServerEvent("plouffe_vineyard:destroyBarrel",barrelIndex,closestBarrel.id, Vine.Utils.MyAuthKey)
        end
    end)
end

function VineFnc:HarvestBarrel(params,closestBarrel,barrelIndex)
    if VineFnc:GetItemCount("empty_wine_bottle") >= 100 then
        ExecuteCommand("e mechanic")
        Utils:ProgressCircle({
            name = "harvest_barrel",
            duration = 30000,
            label = 'Recolte en cours',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }
        }, function(cancelled)
            ExecuteCommand("e c")
            if not cancelled then
                TriggerServerEvent("plouffe_vineyard:harvestBarrel",barrelIndex,closestBarrel.id, Vine.Utils.MyAuthKey)
            end
        end)
    else
        Utils:Notify("error","Vous avez besoin de 100 bouteilles vide pour cela",5000)
    end
end

function VineFnc:Deliver(params)
    ExecuteCommand("e box")
    Utils:ProgressCircle({
        name = "wine_delivery",
        duration = 5000,
        label = 'Livraison en cours...',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    }, function(cancelled)
        ExecuteCommand("e c")
        if not cancelled then
            TriggerServerEvent("plouffe_vineyard:delivered", params.zone, Vine.Utils.MyAuthKey)
        end
    end)
end

exports("UseBarrel", VineFnc.UseBarrel)
exports("effralage", VineFnc.Effralage)