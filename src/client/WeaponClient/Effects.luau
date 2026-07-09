-- src/client/WeaponClient/Effects.luau
-- Muzzle flash + tracer + som por tiro. Puramente visual/áudio (cliente).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = {}
Effects.__index = Effects

local FLASH_TIME = 0.05
local TRACER_TIME = 0.06

function Effects.new(viewmodelPart, cfg)
	local self = setmetatable({}, Effects)
	self.part = viewmodelPart
	self.cfg = cfg

	-- luz do disparo (presa no cano)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 140)
	light.Range = 10
	light.Brightness = 0
	light.Parent = viewmodelPart
	self.light = light

	-- som (opcional; só se houver SoundId configurado)
	if cfg.fireSoundId and cfg.fireSoundId ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = cfg.fireSoundId
		sound.Volume = 0.5
		sound.Parent = viewmodelPart
		self.sound = sound
	end

	return self
end

local function muzzlePos(part)
	return (part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)).Position
end

function Effects:fire(direction)
	local origin = muzzlePos(self.part)

	-- muzzle flash
	self.light.Brightness = 3
	task.delay(FLASH_TIME, function()
		if self.light then
			self.light.Brightness = 0
		end
	end)

	-- tracer: raycast visual do cliente pra achar o fim do rastro
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local char = Players.LocalPlayer.Character
	params.FilterDescendantsInstances = { self.part, char }
	local result = Workspace:Raycast(origin, direction.Unit * self.cfg.range, params)
	local finish = result and result.Position or (origin + direction.Unit * self.cfg.range)

	local dist = (finish - origin).Magnitude
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CastShadow = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 230, 150)
	tracer.Size = Vector3.new(0.08, 0.08, dist)
	tracer.CFrame = CFrame.lookAt(origin, finish) * CFrame.new(0, 0, -dist / 2)
	tracer.Parent = Workspace
	Debris:AddItem(tracer, TRACER_TIME)

	-- som
	if self.sound then
		self.sound:Play()
	end
end

return Effects
