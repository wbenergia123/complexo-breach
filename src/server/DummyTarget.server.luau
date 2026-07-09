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

local RESPAWN_DELAY = 3

local template = ServerStorage:WaitForChild("TrainingDummy")

-- Boneco em cima da ExtractionZone (objetivo do mapa), referência dinâmica.
local function spawnCFrame()
	local map = Workspace:FindFirstChild("Map")
	local obj = map and map:FindFirstChild("Objective")
	local zone = obj and obj:FindFirstChild("ExtractionZone")
	if zone and zone:IsA("BasePart") then
		local top = zone.Position + Vector3.new(0, zone.Size.Y / 2 + 3, 0)
		return CFrame.new(top)
	end
	return CFrame.new(0, 5, 0) -- fallback
end

local function spawnDummy()
	local dummy = template:Clone()
	dummy:PivotTo(spawnCFrame())
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
