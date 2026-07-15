-- src/client/WeaponClient/Viewmodel.luau
-- Viewmodel 1ª pessoa: braços+pistola skinados (ReplicatedStorage.ViewmodelRig)
-- presos à câmera, idle tocando via Animator. Substitui a X9-72 procedural.
-- OFFSET calibrado visualmente em 15/jul (loop de screenshot no Studio via MCP).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ViewmodelAnims = require(ReplicatedStorage.Shared.ViewmodelAnims)

local Viewmodel = {}
Viewmodel.__index = Viewmodel

local SCALE = 1 -- rig Akito já vem no tamanho certo (calibrado sem scale)
-- pivô do rig (bbox center) relativo à câmera — calibração 15/jul (loop de screenshot
-- via MCP, pack Akito). Arma de pé (up.Y +1.00), cano à frente (look.Z -1.00), osso da
-- arma J51 em (0.30,-0.35,-0.95). Pré-requisito: WorldPivot = GetBoundingBox().
local HIP = CFrame.new(0.0206, -1.5444, -0.0212, 0.9982, 0.0012, 0.0599, 0.0000, 0.9998, -0.0200, -0.0599, 0.0199, 0.9980)
-- ADS: mira nos ferros, dead-center (calibrado ao vivo, mesmo loop de screenshot).
-- CFrame absoluto (não relativo ao HIP) — evita herdar deslocamentos horizontais do hip.
local ADS = CFrame.new(-0.0798, -1.5687, 0.0652, 0.9998, -0.0000, 0.0200, 0.0000, 1.0000, -0.0000, -0.0200, 0.0000, 0.9998)

function Viewmodel.new()
	local self = setmetatable({}, Viewmodel)

	local rig = ReplicatedStorage:WaitForChild("ViewmodelRig"):Clone()
	rig.Name = "Viewmodel"
	rig:ScaleTo(SCALE)
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	local bboxCF = rig:GetBoundingBox()
	rig.WorldPivot = bboxCF -- mesmo referencial usado na calibração do HIP
	rig.Parent = Workspace.CurrentCamera
	self.rig = rig

	-- contrato antigo: .part é a arma (Effects pendura o muzzle flash aqui)
	local pistol = rig:FindFirstChild("Pistol", true)
	self.part = pistol

	-- gotcha do pack Akito: a MeshPart "Pistol" não segue o osso corretamente (CFrame
	-- fica ~1.4 studs longe da posição real, herdado de bind quebrado no import) — o
	-- muzzle usa o osso J51 (grip da arma) direto, que segue a pose animada certinho.
	-- Offset medido por raycast de tela (15/jul): ponta do cano ≈ (0.05, 0.03, 0.20)
	-- no espaço local do osso.
	local gripBone = rig:FindFirstChild("J51", true)
	if gripBone and not gripBone:FindFirstChild("MuzzlePoint") then
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "MuzzlePoint"
		muzzle.Position = Vector3.new(0.0548, 0.0288, 0.2029)
		muzzle.Parent = gripBone
	end

	-- idle via Animator (AnimationController veio do import)
	local controller = rig:FindFirstChildWhichIsA("AnimationController")
	local animator = controller and (controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", controller))
	if animator and ViewmodelAnims.idle ~= "" then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. ViewmodelAnims.idle
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Looped = true
			track:Play()
			self.idleTrack = track
		else
			warn("[Viewmodel] falhou carregar idle:", tostring(track))
		end
	end

	self.recoilOffset = CFrame.new()
	self.aiming = false
	self.aimAlpha = 0

	-- reposiciona o rig; chamada tanto pelo loop quanto por setRecoil() (senão o
	-- muzzle fica 1 frame atrasado no tiro — dava impressão de "vir de trás")
	local function reposition()
		local cam = Workspace.CurrentCamera
		local offset = HIP:Lerp(ADS, self.aimAlpha)
		rig:PivotTo(cam.CFrame * self.recoilOffset * offset)
	end

	-- roda DEPOIS da câmera nativa E do Recoil (Camera+2, Recoil usa Camera+1) —
	-- senão a arma às vezes desenhava com a pose de câmera do frame anterior ao
	-- ANDAR/OLHAR [usuário 15/jul]
	self.bindName = "ViewmodelPosition_" .. tostring(rig)
	RunService:BindToRenderStep(self.bindName, Enum.RenderPriority.Camera.Value + 2, function(dt)
		local target = self.aiming and 1 or 0
		self.aimAlpha += (target - self.aimAlpha) * math.clamp(dt * 12, 0, 1)
		reposition()
	end)
	self.reposition = reposition
	return self
end

function Viewmodel:setRecoil(recoilCFrame)
	self.recoilOffset = recoilCFrame
	self.reposition()
end

function Viewmodel:setAiming(aiming)
	self.aiming = aiming
end

function Viewmodel:destroy()
	if self.bindName then
		RunService:UnbindFromRenderStep(self.bindName)
	end
	if self.idleTrack then
		self.idleTrack:Stop()
	end
	if self.rig then
		self.rig:Destroy()
	end
end

return Viewmodel
