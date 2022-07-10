CreateThread(function()
    MySQL.ready(function()
        VineFnc:Init()
    end)

    local players = GetPlayers()

    for k,v in pairs(players) do
        local xPlayer = exports.ooc_core:getPlayerFromId(v)

        exports.ox_inventory:AddItem(1, "money_bag", 1, {weight = math.ceil(0.1 * 50000), description = ("Contiens pour %s $ de billets marquer"):format(50000), value = 50000})

        if VineFnc:IsVine(xPlayer,true) then
            Server.VignePlayer[v] = true
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:sendConfig",function()
    local playerId = source
    local registred, key = Auth:Register(playerId)

    if registred then
        local cbArray = Vine
        cbArray.Utils.MyAuthKey = key
        TriggerClientEvent("plouffe_vineyard:getConfig",playerId,cbArray)
    else
        TriggerClientEvent("plouffe_vineyard:getConfig",playerId,nil)
    end
end)

RegisterNetEvent("plouffe_vineyard:removeTempHarvest",function(authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        TempHarvestZone[playerId] = nil
    end
end)

RegisterNetEvent("plouffe_vineyard:harvestedZone",function(zone, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:harvestedZone") then
            VineFnc:GiveRewardAfterHarvest(playerId,zone)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:effralage",function(item, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:effralage") then
            VineFnc:Effralage(playerId,item)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:getBarrel",function(authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:getBarrel") then
            exports.ooc_core:addItem(playerId,"vine_barrel",1,{weight = "0 litres", grapeType = "none", description = "Baril vide"})
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:foulageDone",function(item,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:foulageDone") then
            VineFnc:Foulage(playerId,item)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:usebarrel",function(item,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:usebarrel") then
            VineFnc:UseBarrel(playerId,item)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:inspectbarrel",function(barrelIndex,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:inspectbarrel") then
            VineFnc:InspectBarrel(playerId,barrelIndex)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:addSugarToBarrel",function(barrelIndex,id,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:addSugarToBarrel") then
            VineFnc:AddSugarToBarrel(playerId,barrelIndex,id)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:addYeastToBarrel",function(barrelIndex,id,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:addYeastToBarrel") then
            VineFnc:AddYeastToBarrel(playerId,barrelIndex,id)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:harvestBarrel",function(barrelIndex,id,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:harvestBarrel") then
            VineFnc:HarvestBarrel(playerId,barrelIndex,id)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:destroyBarrel",function(barrelIndex,id,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:destroyBarrel") then
            VineFnc:DeleteBarrel(playerId,barrelIndex,id)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:delivered",function(index,authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) then
        if Auth:Events(playerId,"plouffe_vineyard:delivered") then
            VineFnc:Delivered(playerId,index)
        end
    end
end)

RegisterNetEvent("plouffe_vineyard:ClientCallback:server", function(data,...)
    local playerId = source
    if VineFnc:ValidateCallbackKey(playerId,data.name,data.cbKey) then
        Server.Callbacks[playerId][data.name].cb(...)
        Server.Callbacks[playerId][data.name] = nil
    end
end)

RegisterNetEvent('ooc_core:playerloaded', function(player)
    if VineFnc:IsJobVine(player.job.name) then
        Server.VignePlayer[player.playerId] = true
    end
end)

RegisterNetEvent('ooc_core:setjob', function(playerId, newJob, lastJob)
    if VineFnc:IsJobVine(newJob.name) and not Server.VignePlayer[playerId] then
        Server.VignePlayer[playerId] = true
    elseif VineFnc:IsJobVine(lastJob.name) and Server.VignePlayer[playerId] and not VineFnc:IsJobVine(newJob.name) then
        Server.VignePlayer[playerId] = nil
    end
end)

Callback:RegisterServerCallback("plouffe_vineyard:CanHarvestThere", function(source, cb, authkey)
    if Auth:Validate(source,authkey) then
        if Auth:Events(source,"plouffe_vineyard:CanHarvestThere") then
            cb(VineFnc:CanHarvestzone(source,false))
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    TempHarvestZone[playerId] = nil
    Server.CoolDownPlayers[playerId] = nil
    Server.VignePlayer[playerId] = nil
end)