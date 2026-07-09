-- src/server/DummyTarget.server.luau
-- Clona o TrainingDummy (modelo pronto no ServerStorage) e respawna ao morrer.
-- Só no place da favela.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
if game.PlaceId ~= Config.FavelaPlaceId then
	return
end

local SPAWN_CFRAME = CFrame.new(0, 5, -20) -- ajustar pro ponto desejado no mapa
local RESPAWN_DELAY = 3

local template = ServerStorage:WaitForChild("TrainingDummy")

local function spawnDummy()
	local dummy = template:Clone()
	dummy:PivotTo(SPAWN_CFRAME)
	dummy.Parent = Workspace
	local hum = dummy:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Once(function()
			task.delay(RESPAWN_DELAY, function()
				dummy:Destroy()
				spawnDummy()
			end)
		end)
	end
end

spawnDummy()
