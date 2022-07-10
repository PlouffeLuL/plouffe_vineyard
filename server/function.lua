function VineFnc:Init()
    MySQL.query('SELECT * FROM vineyard_barrel', {}, function(barrels)
        if barrels[1] then
            for k,v in ipairs(barrels) do
                local decodedCoords = json.decode(v.coords)

                v.coords = vector3(decodedCoords.x,decodedCoords.y,decodedCoords.z)
                v.data = json.decode(v.data)

                if v.id > Server.nextId then
                    Server.nextId = v.id
                end
            end

            Vine.Barrels = barrels
        end

        self:StartDeliveryThread()
    end)
end

function VineFnc:GetArrayLenght(array)
    local lenght = 0
    for k,v in pairs(array) do
        lenght = lenght + 1
    end
    return lenght
end

function VineFnc:CreateCallbackName()
    local x = {
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "!","@","#","$","%","^","&","*","(",")","_","-","=","+","{","}","[","]",";",":","'","?",">","<",
        "0","1","2","3","4","5","6","7","8","9","penis","PENIS","PLOUFFE","plouffe","KEKW","kekw","MINUCE","minuce"
    }
    local currentName = ""
    local timesDone = 0
    local maxLengh = math.random(10,20)

    repeat
        local randi = math.random(1,#x)
        currentName = currentName..tostring(x[randi])
        timesDone = timesDone + 1
    until timesDone > maxLengh

    return currentName
end

function VineFnc:CreateCallbackKey()
    local x = {
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "!","@","#","$","%","^","&","*","(",")","_","-","=","+","{","}","[","]",";",":","'","?",">","<",
        "0","1","2","3","4","5","6","7","8","9","penis","PENIS","PLOUFFE","plouffe","KEKW","kekw","MINUCE","minuce"
    }
    local currentName = ""
    local timesDone = 0
    local maxLengh = math.random(5,10)

    repeat
        local randi = math.random(1,#x)
        currentName = currentName..tostring(x[randi])
        timesDone = timesDone + 1
    until timesDone > maxLengh

    return currentName
end

function VineFnc:ClientCallback(playerId,cb,data)
    local cbKey = VineFnc:CreateCallbackKey()
    data.cbKey = cbKey
    data.name = VineFnc:CreateCallbackName()
    Server.Callbacks[playerId] = {}
    Server.Callbacks[playerId][data.name] = {cb = cb, cbKey = cbKey, serverTime = os.time()}
    TriggerClientEvent("plouffe_vineyard:ClientCallback",playerId,data)
end

function VineFnc:ValidateCallbackKey(playerId,name,key)
    local reason = "Invalid callback key"
    if Server.Callbacks[playerId][name] then
        if Server.Callbacks[playerId][name].cbKey == key then
            if os.time() - Server.Callbacks[playerId][name].serverTime <= 1000 then
                return true
            else
                reason = "Client timeout on callback"
            end
        end
    end
    VineFnc:SendLogs(reason, playerId)
    return false
end

function VineFnc:IsVine(xPlayer,off,grades)
    if xPlayer.job.name == "vineyard" or (off and xPlayer.job.name == "vineyardoff") then
        if grades then
            if (type(grades) == "number" and grades == xPlayer.job.grade) or (type(grades) == "table" and grades[xPlayer.job.grade]) then
                return true
            end
        else
            return true
        end
    end
    return false
end

function VineFnc:TriggerVineyardEvent(event,...)
    for k,v in pairs(Server.VignePlayer) do
        TriggerClientEvent(event, k, ...)
    end
end

function VineFnc:IsJobVine(job,off,grades)
    if job == "vineyard" or (off and job == "vineyardoff") then
        if grades then
            if (type(grades) == "number" and grades == xPlayer.job.grade) or (type(grades) == "table" and grades[xPlayer.job.grade]) then
                return true
            end
        else
            return true
        end
    end
    return false
end

function VineFnc:StartGrowthThread()
    if Vine.Growth.active then
        return
    end

    Vine.Growth.active = true

    CreateThread(function()
        while #HarvestedZone > 0 do
            Wait(Vine.Growth.interval)
            local currentTime = os.time()
            local toRemove = {}

            for k,v in pairs(HarvestedZone) do
                if currentTime - v.time >= Vine.Growth.rate then
                    table.insert(toRemove, k)
                end
            end

            for k,v in pairs(toRemove) do
                table.remove(HarvestedZone, v)
            end

            toRemove = {}
        end

        Vine.Growth.active = false
    end)
end

function VineFnc:CanHarvestzone(playerId, ignore)
    local coords = GetEntityCoords(GetPlayerPed(playerId))

    for k,v in pairs(HarvestedZone) do
        local dstCheck = #(v.coords - coords)
        if dstCheck <= 1.5 then
            return false
        end
    end

    for k,v in pairs(TempHarvestZone) do
        local dstCheck = #(v - coords)
        if dstCheck <= 1.5 then
            return false
        end
    end

    if not ignore then
        TempHarvestZone[playerId] = coords
    end

    self:StartGrowthThread()

    return true
end

function VineFnc:GiveRewardAfterHarvest(playerId,zone)
    TempHarvestZone[playerId] = nil

    local coords = GetEntityCoords(GetPlayerPed(playerId))

    if self:CanHarvestzone(playerId, true) and #(coords - Vine.StartJobCoords[zone].coords) <= Vine.StartJobCoords[zone].maxDst then
        local randi = math.random(1, #Vine.StartJobCoords[zone].itemsList)
        local itemCount = math.random(Vine.StartJobCoords[zone].itemsList[randi].minAmount, Vine.StartJobCoords[zone].itemsList[randi].maxAmount)
        local item = Vine.StartJobCoords[zone].itemsList[randi].name
        exports.ooc_core:addItem(playerId,item,itemCount)
        table.insert(HarvestedZone, {time = os.time(), coords = coords, harvester = playerId})
    end
end

function VineFnc:CheckBarrelDistance(coords, check)
    local distance = nil

    for k,v in pairs(Vine.Barrels) do
        local dstCheck = #(coords - v.coords)
        if not distance then
            distance = dstCheck
        elseif dstCheck < distance then
            distance = dstCheck
        end
    end

    if distance then
        return distance > check
    else
        return true
    end
end

function VineFnc:IsInVineyard(coords)
    return #(Vine.StartJobCoords.vineyard.coords - coords) <= (Vine.StartJobCoords.vineyard.maxDst / 2)
end

function VineFnc:CreateNewBarel(player,item)
    local playerId = player.playerId
    local ped = GetPlayerPed(playerId)
    local pedCoords = GetEntityCoords(ped)
    local validDistance = self:CheckBarrelDistance(pedCoords, 1.5)
    local isInVineyard = self:IsInVineyard(pedCoords)

    if isInVineyard then
        if validDistance then
            self:ClientCallback(playerId, function(offset)
                Server.nextId = Server.nextId + 1

                local barrelData = {
                    id = Server.nextId,
                    owner = player.identifier,
                    charid = player.characterId,
                    timeAt = os.time(),
                    readyTime = os.time() + Vine.BarrelTypes[item.metadata.grapeType].fermentationTime,
                    type = Vine.BarrelTypes[item.metadata.grapeType].type,
                    coords = offset,
                    data = {coords = offset, desc = item.metadata.description, grapeType = item.metadata.grapeType, sugar = 0, yeast = 0}
                }

                MySQL.query("INSERT INTO vineyard_barrel (id,state_id,timeAt,readyTime,type,coords,data) VALUES (@id,@state_id,@timeAt,@readyTime,@type,@coords,@data)", {
                    ["@id"] = Server.nextId,
                    ["@state_id"] = player.state_id,
                    ["@timeAt"] = os.time(),
                    ["@readyTime"] = os.time() + Vine.BarrelTypes[item.metadata.grapeType].fermentationTime,
                    ["@type"] = Vine.BarrelTypes[item.metadata.grapeType].type,
                    ["@coords"] = json.encode({x = offset.x, y = offset.y, z = offset.z}),
                    ["@data"] = json.encode(barrelData.data)
                }, function(penisMaster)
                    table.insert(Vine.Barrels,barrelData)
                    TriggerClientEvent("plouffe_vineyard:sync_new_barrel",-1,barrelData)
                    exports.ooc_core:removeItem(playerId,item.name,1,nil,item.slot)
                end)
            end, {fnc = "GetOffSetAndPlayAnim"})
        else
            TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'error', text = "Vous etes trop près d'un autre baril", length = 5000})
        end
    else
        TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'error', text = "Vous etes trop loin du vignoble", length = 5000})
    end
end

function VineFnc:Effralage(playerId,item)
    if Vine.GrapePerBranch[item] and exports.ooc_core:getItemCount(playerId,item) > 0 then
        local itemCount = math.random(Vine.GrapePerBranch[item].minAmount, Vine.GrapePerBranch[item].maxAmount)
        local itemName = Vine.GrapePerBranch[item].name
        exports.ooc_core:addItem(playerId,itemName,itemCount)
        exports.ooc_core:removeItem(playerId,item,1)
    end
end

function VineFnc:Foulage(playerId,item)
    if Vine.StompItems.minimum[item] and exports.ooc_core:getItemCount(playerId,item) >= Vine.StompItems.minimum[item] then
        local barrels = exports.ox_inventory:Search(1, 'slots', 'vine_barrel')
        local added = false

        if barrels then
            for k,v in pairs(barrels) do
                local weightStr = not v.metadata.description and v.description:gsub(" litres","") or v.metadata.description:gsub(" litres","")

                for k,v in pairs(Vine.BarilInfo.desc) do
                    weightStr = weightStr:gsub(("%s %s"):format("de", v),"")
                end

                local weight = tonumber(weightStr) or 0

                if weight >= 0 and weight < 100 then
                    weight = weight + 10 < 100 and weight + 10 or 100

                    if not v.metadata then
                        v.metadata = {}
                    end

                    if not v.metadata.grapeType then
                        v.metadata.grapeType = item
                    end

                    if v.metadata.grapeType == item then
                        if v.count > 1 then
                            exports.ooc_core:removeItem(playerId, v.name, 1, v.metadata, v.slot)
                            v.metadata.description = ("%s litres de %s"):format(weight, Vine.BarilInfo.desc[item])
                            exports.ooc_core:addItem(playerId, v.name, 1, v.metadata, v.slot)
                        else
                            v.metadata.description = ("%s litres de %s"):format(weight, Vine.BarilInfo.desc[item])
                            exports.ox_inventory:SetMetadata(playerId, v.slot, v.metadata)
                        end

                        exports.ooc_core:removeItem(playerId, item, Vine.StompItems.minimum[item])

                        added = true
                        break
                    end
                end
            end
        end

        if not added then
            return TriggerClientEvent('plouffe_lib:notify', playerId, { type = "error", text = "Vous avez besoin d'un baril a vin dans le quelle il y a moins de 100 litres", length = 5000})
        end
    end
end

function VineFnc:UseBarrel(playerId,item)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    if not Server.CoolDownPlayers[playerId] then
        Server.CoolDownPlayers[playerId] = true

        local weightStr = item.metadata.description and item.metadata.description:gsub(" litres","")

        if not weightStr then
            return
        end

        for k,v in pairs(Vine.BarilInfo.desc) do
            weightStr = weightStr:gsub(("%s %s"):format("de", v),"")
        end

        local weight = tonumber(weightStr) or 0

        if weight ~= 100 then
            return
        end

        if self:IsVine(xPlayer,false,nil) and weight >= 100 then
            self:CreateNewBarel(xPlayer,item)
        end
        Wait(3000)
        Server.CoolDownPlayers[playerId] = nil
    end
end

function VineFnc:InspectBarrel(playerId,barrelIndex)
    local timeLeft = math.ceil((Vine.Barrels[barrelIndex].readyTime - os.time()) / 60)
    local strTime = ""
    local txt = ""

    txt = "Il reste "..tostring(timeLeft).." minutes aproximativement a la fermentation de ce baril"

    if timeLeft > 60 then
        timeLeft = math.ceil(timeLeft / 60)
        txt = "Il reste "..tostring(timeLeft).." heurs aproximativement a la fermentation de ce baril"
    elseif timeLeft <= 0 then
        txt = "Le baril est prêt a être recolter"
    end

    TriggerClientEvent('plouffe_lib:notify', playerId, { type = "inform", text = txt, length = 5000})
end

function VineFnc:SaveBarrelDataFromIndex(barrelIndex)
    if Vine.Barrels[barrelIndex] then
        MySQL.query("UPDATE vineyard_barrel SET data = @data WHERE id = @id",{
            ["@id"] = Vine.Barrels[barrelIndex].id,
            ["@data"] = json.encode(Vine.Barrels[barrelIndex].data)
        })
    end
end

function VineFnc:AddSugarToBarrel(playerId,barrelIndex,id)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    if Vine.Barrels[barrelIndex] and Vine.Barrels[barrelIndex].id == id and VineFnc:IsVine(xPlayer) then
        if exports.ooc_core:getItemCount(playerId,"wine_sugar") > 0 then
            Vine.Barrels[barrelIndex].data.sugar = Vine.Barrels[barrelIndex].data.sugar + 1
            exports.ooc_core:removeItem(playerId,"wine_sugar",1)
            VineFnc:TriggerVineyardEvent("plouffe_vineyard:updatebarrelFromIndex", barrelIndex, Vine.Barrels[barrelIndex])
            VineFnc:SaveBarrelDataFromIndex(barrelIndex)
        end
    end
end

function VineFnc:AddYeastToBarrel(playerId,barrelIndex,id)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    if Vine.Barrels[barrelIndex] and Vine.Barrels[barrelIndex].id == id and VineFnc:IsVine(xPlayer) then
        if exports.ooc_core:getItemCount(playerId,"wine_yeast") > 0 then
            Vine.Barrels[barrelIndex].data.yeast = Vine.Barrels[barrelIndex].data.yeast + 1
            exports.ooc_core:removeItem(playerId,"wine_yeast",1)
            VineFnc:TriggerVineyardEvent("plouffe_vineyard:updatebarrelFromIndex", barrelIndex, Vine.Barrels[barrelIndex])
            VineFnc:SaveBarrelDataFromIndex(barrelIndex)
        end
    end
end

function VineFnc:DeleteBarrelFromIndex(playerId,barrelIndex,cb)
    if Vine.Barrels[barrelIndex] then
        MySQL.query("DELETE FROM vineyard_barrel WHERE id = @id",{
            ["@id"] = Vine.Barrels[barrelIndex].id
        },cb)
    end
end

function VineFnc:HarvestBarrel(playerId,barrelIndex,id)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    if exports.ooc_core:getItemCount(playerId,"empty_wine_bottle") >= 100 and Vine.Barrels[barrelIndex] and Vine.Barrels[barrelIndex].id == id and Vine.BarrelTypes[Vine.Barrels[barrelIndex].data.grapeType] and VineFnc:IsVine(xPlayer) and Vine.Barrels[barrelIndex].readyTime - os.time() <= 0  then
        if Vine.BarrelTypes[Vine.Barrels[barrelIndex].data.grapeType].maxSugar == Vine.Barrels[barrelIndex].data.sugar and Vine.BarrelTypes[Vine.Barrels[barrelIndex].data.grapeType].maxYeast == Vine.Barrels[barrelIndex].data.yeast then
            VineFnc:DeleteBarrelFromIndex(playerId,barrelIndex,function()
                exports.ooc_core:removeItem(playerId,"empty_wine_bottle", 100)
                exports.ooc_core:addItem(playerId,Vine.BarrelTypes[Vine.Barrels[barrelIndex].data.grapeType].itemName, 100)
                table.remove(Vine.Barrels,barrelIndex)
            end)
        else
            VineFnc:DeleteBarrelFromIndex(playerId,barrelIndex,function()
                TriggerClientEvent('plouffe_lib:notify', playerId, { type = 'error', text = "La qualiter étais mauvaise et vous n'avez rien recolter", length = 5000})
                table.remove(Vine.Barrels,barrelIndex)
            end)
        end
        TriggerClientEvent("plouffe_vineyard:removeBarrel",-1,barrelIndex,id)
    end
end

function VineFnc:DeleteBarrel(playerId,barrelIndex,id)
    local xPlayer = exports.ooc_core:getPlayerFromId(playerId)
    if self:IsVine(xPlayer) then
        self:DeleteBarrelFromIndex(playerId,barrelIndex,function()
            table.remove(Vine.Barrels,barrelIndex)
            TriggerClientEvent("plouffe_vineyard:removeBarrel",-1,barrelIndex,id)
        end)
    end
end

function VineFnc:SendPlayerAlert(playerId,job,txt)
    local player = exports.ooc_core:getPlayerFromId(playerId)
    local phoneNumber = player and player.phone_number
    local messageData = {senderNumber = job, targetNumber = tostring(phoneNumber), message = txt}

    exports.npwd:emitMessage(messageData)
end

function VineFnc:GenerateNewItemsRequest()
    local itemIndex = math.random(1,#Vine.DeliveryItems)
    return {
        label = Vine.DeliveryItems[itemIndex].label,
        name = Vine.DeliveryItems[itemIndex].name,
        price = math.random(Vine.DeliveryItems[itemIndex].price.min,Vine.DeliveryItems[itemIndex].price.max),
        amount = math.random(Vine.DeliveryItems[itemIndex].amount.min,Vine.DeliveryItems[itemIndex].amount.max)
    }
end

function VineFnc:GenerateNewDeliveryRequest()
    CreateThread(function()
        local randi = math.random(1,self:GetArrayLenght(Vine.DeliveryCoords))
        local itemsNeeded = self:GenerateNewItemsRequest()
        local current = 0
        local deliveryIndex = nil
        local smsTxt = ("Nous avons besoin d'une livraison de: %s x %s . Le prix offert est: %s $ Utiliser /livraison pour avoir le gps"):format(itemsNeeded.label,itemsNeeded.amount,itemsNeeded.amount * itemsNeeded.price)
        local deliveryStartTime = os.time()

        for k,v in pairs(Vine.DeliveryCoords) do
            current = current + 1
            if current == randi then
                deliveryIndex = k
                break
            end
        end

        Vine.DeliveryCoords[deliveryIndex].itemsNeeded = itemsNeeded

        self:TriggerVineyardEvent("plouffe_vineyard:activateDelivery", deliveryIndex)

        for k,v in pairs(Server.VignePlayer) do
            self:SendPlayerAlert(k,"Livraison",smsTxt)
        end

        Vine.DeliveryCoords[deliveryIndex].active = true

        while Vine.DeliveryCoords[deliveryIndex].active and os.time() - deliveryStartTime < Server.deliveryDelay do
            Wait(10000)
        end

        if Vine.DeliveryCoords[deliveryIndex].active then
            Vine.DeliveryCoords[deliveryIndex].active = false
            Vine.DeliveryCoords[deliveryIndex].itemsNeeded = {}

            for k,v in pairs(Server.VignePlayer) do
                self:SendPlayerAlert(k,"Livraison","Suite au delay de livraison nous avons décider de faire affaire avec quelqun d'autre")
            end

            self:TriggerVineyardEvent("plouffe_vineyard:cancelDelivery", deliveryIndex)
        end
    end)
end

function VineFnc:StopCurrentDelivery(index)
    if index then
        if Vine.DeliveryCoords[index].active then
            Vine.DeliveryCoords[index].active = false
            Vine.DeliveryCoords[index].itemsNeeded = {}
            self:TriggerVineyardEvent("plouffe_vineyard:cancelDelivery", index)
        end
    else
        for k,v in pairs(Vine.DeliveryCoords) do
            if v.active then
                v.active = false
                v.itemsNeeded = {}
                self:TriggerVineyardEvent("plouffe_vineyard:cancelDelivery", k)
            end
        end
    end
end

function VineFnc:StartDeliveryThread()
    CreateThread(function()
        while true do
            Wait(math.random(Server.deliveryInterval.min,Server.deliveryInterval.max))
            self:GenerateNewDeliveryRequest()
        end
    end)
end

function VineFnc:Delivered(playerId,index)
    if Vine.DeliveryCoords[index] and Vine.DeliveryCoords[index].active then
        Vine.DeliveryCoords[index].active = false

        local price = Vine.DeliveryCoords[index].itemsNeeded.amount * Vine.DeliveryCoords[index].itemsNeeded.price
        local itemCount = exports.ooc_core:getItemCount(playerId, Vine.DeliveryCoords[index].itemsNeeded.name)

        if itemCount >= Vine.DeliveryCoords[index].itemsNeeded.amount then
            exports.plouffe_society:AddSocietyAccountMoney(nil,"society_vineyard","bank",price,function(valid)
                if valid then
                    exports.ooc_core:removeItem(playerId, Vine.DeliveryCoords[index].itemsNeeded.name, Vine.DeliveryCoords[index].itemsNeeded.amount)

                    TriggerClientEvent('plouffe_lib:notify', playerId, {
                        type = 'success',
                        text = ("Vous avez vendu pour %s $ "):format(price),
                        length = 7500
                    })

                    VineFnc:TriggerVineyardEvent("plouffe_vineyard:cancelDelivery", index)
                    Vine.DeliveryCoords[index].itemsNeeded = {}

                    local bags = exports.ox_inventory:Search(playerId, "slots", "money_bag", nil)

                    if not bags then
                        return
                    end

                    for k,v in pairs(bags) do
                        if v.metadata and v.metadata.value then
                            exports.ox_inventory:RemoveItem(playerId, v.name, 1, v.metadata, v.slot)
                            exports.ox_inventory:AddItem(playerId, "money", v.metadata.value)
                            break
                        end
                    end
                end
            end)
        else
            TriggerClientEvent('plouffe_lib:notify', playerId, {
                type = 'error',
                text = ("Vous avez besoin de %s x %s "):format(Vine.DeliveryCoords[index].itemsNeeded.label,Vine.DeliveryCoords[index].itemsNeeded.amount),
                length = 7500
            })

            VineFnc:StopCurrentDelivery(index)
        end
    end
end

RegisterCommand("vineyard_delivery", function(s,a,r)
    if a[1]:lower() == "start" then
        VineFnc:GenerateNewDeliveryRequest()
    elseif a[1]:lower() == "stop" then
        VineFnc:StopCurrentDelivery(a[2])
    end
end,true)