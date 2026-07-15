-- src/client/WeaponClient/Effects.luau
-- Muzzle flash (partícula, sem luz dinâmica) + fumaça + som por tiro. Só visual/áudio (cliente).
-- Técnica: ParticleEmitters no cano (como Evostrike), texturas nativas do Roblox.

local Effects = {}
Effects.__index = Effects

function Effects.new(viewmodelPart, cfg)
	local self = setmetatable({}, Effects)
	self.part = viewmodelPart
	self.cfg = cfg

	-- ponto do cano: o Viewmodel cria "MuzzlePoint" na ponta (pendurado no osso do
	-- grip, não na part — busca recursiva pelo rig inteiro); fallback se não achar
	local muzzle = viewmodelPart.Parent and viewmodelPart.Parent:FindFirstChild("MuzzlePoint", true)
	if not muzzle then
		muzzle = Instance.new("Attachment")
		muzzle.Name = "MuzzlePoint"
		muzzle.Position = Vector3.new(0, 0, -viewmodelPart.Size.Z / 2)
		muzzle.Parent = viewmodelPart
	end
	self.muzzle = muzzle

	-- flash estilo CS: sprite real do GoldSrc (muzzleflash3 frame1, convertido de
	-- .spr, estrela limpa) — usuário escolheu no contact sheet dos 15 frames (15/jul)
	local flash = Instance.new("ParticleEmitter")
	flash.Texture = "rbxassetid://93733434092821"
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 225, 160))
	flash.LightEmission = 1
	flash.LightInfluence = 0
	-- Size é em studs do MUNDO, não pixels de tela — e o muzzle fica ~0.3-0.5 studs
	-- da câmera (colado no olho). 0.175 studs aí ocupava ~30% da largura da tela por
	-- pura perspectiva (objeto perto = grande na tela), virava o "feixe" na foto do
	-- usuário. Reduzido pra caber como um clarão pequeno de verdade [15/jul]
	flash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0675), -- +50% [usuário 15/jul]
		NumberSequenceKeypoint.new(1, 0.018),
	})
	flash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	flash.Lifetime = NumberRange.new(0.025, 0.025)
	flash.Speed = NumberRange.new(0)
	flash.Rotation = NumberRange.new(0, 360)
	flash.Rate = 0
	flash.Enabled = false
	flash.LockedToPart = true -- gruda no muzzle a vida toda; sem isso a partícula solta
	-- no mundo ao nascer e, com a câmera girando rápido, fica pra trás [usuário 15/jul]
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
	-- mesmo problema de escala do flash (perto da câmera = gigante na tela) — valores
	-- antigos (0.45-1.3) eram maiores até que os do flash, contribuía pro "feixe"
	smoke.Size = NumberSequence.new(0.11, 0.32)
	smoke.Lifetime = NumberRange.new(0.35, 0.55)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Rate = 0
	smoke.Enabled = false
	smoke.LockedToPart = true -- mesmo motivo do flash: gruda no muzzle a vida toda
	smoke.Parent = muzzle
	self.smoke = smoke

	-- SEM PointLight: o CS de verdade não usa luz dinâmica no muzzle flash, só o
	-- sprite 2D — evita brigar com Bloom/SunRays do mapa (a luz colada na câmera
	-- estourava o bloom e virava um feixe gigante na tela) [usuário 15/jul]

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

function Effects:fire()
	-- muzzle flash: clarão + fumaça (sem luz — ver comentário no construtor). O
	-- risco/tracer curto foi removido — depois de virar caixa→cilindro e ainda
	-- confundir, os dois já dão feedback suficiente sozinhos [usuário 15/jul]
	self.flash:Emit(1)
	self.smoke:Emit(3)

	-- som
	if self.sound then
		self.sound:Play()
	end
end

return Effects
