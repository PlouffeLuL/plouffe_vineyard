Vine = {}
VineFnc = {} 
TriggerServerEvent("plouffe_vineyard:sendConfig")

RegisterNetEvent("plouffe_vineyard:getConfig",function(list)
	if list == nil then
		CreateThread(function()
			while true do
				Wait(0)
				Vine = nil
				VineFnc = nil
				ESX = nil
			end
		end)
	else
		Vine = list
		VineFnc:Start()
	end
end)