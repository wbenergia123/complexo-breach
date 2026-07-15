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

local SCALE = 0.6
-- pivô do rig (bbox center) relativo à câmera — calibração ao vivo 15/jul (loop de
-- screenshot via MCP). Pistola de pé (up.Y +0.99), cano à frente (look.Z -0.99),
-- mão no canto inferior direito (0.35, -0.55). Pré-requisito: clone com ScaleTo(SCALE)
-- e WorldPivot = GetBoundingBox() (mesmo referencial da calibração).
local HIP = CFrame.new(0.2203, -3.3817, -0.1666, 0.9950, 0.0040, 0.0994, 0.0000, 0.9992, -0.0398, -0.0995, 0.0396, 0.9942)
-- ADS: desloca o conjunto (camera-space) pra centralizar/subir a arma; 1º chute,
-- refinar quando montarmos a mira de verdade (Aim.luau)
local ADS = CFrame.new(-0.20, 0.05, 0.20) * HIP

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
	if pistol and not pistol:FindFirstChild("MuzzlePoint") then
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "MuzzlePoint"
		muzzle.Position = Vector3.new(0, pistol.Size.Y / 2, -pistol.Size.Z / 2)
		muzzle.Parent = pistol
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

	self.conn = RunService.RenderStepped:Connect(function(dt)
		local target = self.aiming and 1 or 0
		self.aimAlpha += (target - self.aimAlpha) * math.clamp(dt * 12, 0, 1)
		local cam = Workspace.CurrentCamera
		local offset = HIP:Lerp(ADS, self.aimAlpha)
		rig:PivotTo(cam.CFrame * self.recoilOffset * offset)
	end)
	return self
end

function Viewmodel:setRecoil(recoilCFrame)
	self.recoilOffset = recoilCFrame
end

function Viewmodel:setAiming(aiming)
	self.aiming = aiming
end

function Viewmodel:destroy()
	if self.conn then
		self.conn:Disconnect()
	end
	if self.idleTrack then
		self.idleTrack:Stop()
	end
	if self.rig then
		self.rig:Destroy()
	end
end

return Viewmodel
