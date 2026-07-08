-- Teleporte do menu → mapa. TeleportService exige ser chamado do servidor,
-- então o cliente pede via RemoteFunction e o servidor executa.
-- Só ativa no place inicial (menu); nos outros places o remote nem existe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

if game.PlaceId ~= Config.StartPlaceId then
	return
end

local requestTeleport = Instance.new("RemoteFunction")
requestTeleport.Name = "RequestTeleport"
requestTeleport.Parent = ReplicatedStorage

requestTeleport.OnServerInvoke = function(player)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Config.FavelaPlaceId, { player })
	end)
	if not ok then
		warn("Falha ao teleportar", player.Name, ":", err)
	end
	return ok, tostring(err)
end
