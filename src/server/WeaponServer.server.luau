-- src/server/WeaponServer.server.luau
-- Autoridade do tiro: munição/cadência/dano no servidor. Só no place da favela.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
if game.PlaceId ~= Config.FavelaPlaceId then
	return
end

local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local Remotes = require(Shared:WaitForChild("WeaponRemotes"))
local cfg = WeaponConfig.Rifle

local state = {} -- [player] = { mag, reserve, lastShot }

local function initState(player)
	state[player] = { mag = cfg.ammo.magazine, reserve = cfg.ammo.reserve, lastShot = 0 }
end
Players.PlayerAdded:Connect(initState)
for _, p in Players:GetPlayers() do
	initState(p)
end
Players.PlayerRemoving:Connect(function(p)
	state[p] = nil
end)

Remotes.FireRequest.OnServerEvent:Connect(function(player, direction)
	local st = state[player]
	local char = player.Character
	if not st or not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	if typeof(direction) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if now - st.lastShot < cfg.fireRate then
		return
	end
	if st.mag <= 0 then
		return
	end
	st.lastShot = now
	st.mag -= 1

	local headPart = char:FindFirstChild("Head")
	local origin = headPart and headPart.Position or char:GetPivot().Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char } -- [R11] exclui o atirador

	local result = Workspace:Raycast(origin, direction.Unit * cfg.range, params)
	local hit, headshot = false, false
	if result and result.Instance then
		local victimHum = result.Instance.Parent
			and result.Instance.Parent:FindFirstChildOfClass("Humanoid")
		if victimHum and victimHum.Health > 0 then
			local dist = (result.Position - origin).Magnitude
			local dmg = WeaponConfig.computeDamage(cfg, dist, result.Instance.Name)
			victimHum:TakeDamage(dmg)
			hit = true
			headshot = result.Instance.Name == "Head"
		end
	end

	-- [R1][R2] confirma pro atirador: hitmarker + munição autoritativa
	Remotes.ShotFx:FireClient(player, { selfShot = true, hit = hit, headshot = headshot, ammo = st.mag })
	-- replica pros outros: tracer/som
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.ShotFx:FireClient(other, { origin = origin, direction = direction })
		end
	end
end)

Remotes.Reload.OnServerEvent:Connect(function(player)
	local st = state[player]
	if not st then
		return
	end
	local need = cfg.ammo.magazine - st.mag
	if need <= 0 or st.reserve <= 0 then
		return
	end
	task.wait(cfg.reloadTime)
	st = state[player]
	if not st then
		return
	end
	local take = math.min(need, st.reserve)
	st.mag += take
	st.reserve -= take
	Remotes.ShotFx:FireClient(player, { selfShot = true, reloaded = true, ammo = st.mag, reserve = st.reserve })
end)
