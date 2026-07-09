-- src/client/WeaponClient/Effects.luau
-- Muzzle flash (partícula + luz) + fumaça + tracer + som por tiro. Só visual/áudio (cliente).
-- Técnica: ParticleEmitters no cano (como Evostrike), texturas nativas do Roblox.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = {}
Effects.__index = Effects

local FLASH_TIME = 0.04
local TRACER_TIME = 0.06

function Effects.new(viewmodelPart, cfg)
	local self = setmetatable({}, Effects)
	self.part = viewmodelPart
	self.cfg = cfg

	-- ponto do cano: o Viewmodel cria "MuzzlePoint" na ponta; fallback se não achar
	local muzzle = viewmodelPart:FindFirstChild("MuzzlePoint")
	if not muzzle then
		muzzle = Instance.new("Attachment")
		muzzle.Name = "MuzzlePoint"
		muzzle.Position = Vector3.new(0, 0, -viewmodelPart.Size.Z / 2)
		muzzle.Parent = viewmodelPart
	end
	self.muzzle = muzzle

	-- flash: flipbook animado (renderizado no Blender), brilho aditivo, rotação aleatória
	local flash = Instance.new("ParticleEmitter")
	flash.Texture = "rbxassetid://89860754097528" -- muzzle flash 4x4 v2 (16 quadros, mais real + fogo forte)
	flash.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	flash.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120)) -- tinge quente
	flash.LightEmission = 1
	flash.LightInfluence = 0
	flash.Size = NumberSequence.new(2.2)
	flash.Lifetime = NumberRange.new(0.06, 0.06)
	flash.Speed = NumberRange.new(0)
	flash.Rotation = NumberRange.new(0, 360)
	flash.Rate = 0
	flash.Enabled = false
	flash.Parent = muzzle
	self.flash = flash

	-- fumaça: cinza, some rápido, deriva pra frente
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(120, 120, 120))
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Size = NumberSequence.new(0.25, 0.8)
	smoke.Lifetime = NumberRange.new(0.2, 0.35)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Rate = 0
	smoke.Enabled = false
	smoke.Parent = muzzle
	self.smoke = smoke

	-- luz do disparo (dá o "pop")
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 140)
	light.Range = 12
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

function Effects:fire(direction)
	local origin = self.muzzle.WorldPosition

	-- muzzle flash: flipbook + fumaça + luz
	self.flash:Emit(1)
	self.smoke:Emit(1)
	self.light.Brightness = 4
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
