-- src/client/WeaponClient/Viewmodel.luau
-- Arma X9-72 (mesh do Meshy) presa à câmera em 1ª pessoa. Lerp hip<->ADS.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Viewmodel = {}
Viewmodel.__index = Viewmodel

-- posições da arma relativas à câmera
local HIP = CFrame.new(0.55, -0.55, -1.7)
local ADS = CFrame.new(0, -0.35, -1.2)
-- gira o mesh pra o cano (-X do mesh) apontar pra frente (-Z da câmera)
local GUN_ROT = CFrame.Angles(0, math.rad(-90), 0)
local SCALE = 0.5

function Viewmodel.new()
	local self = setmetatable({}, Viewmodel)

	local template = ReplicatedStorage:WaitForChild("X9-72")
	local gun = template:Clone()
	gun.Anchored = true
	gun.CanCollide = false
	gun.CanQuery = false
	gun.CastShadow = false
	if gun:IsA("MeshPart") then
		gun.Size = gun.Size * SCALE
	end
	gun.Parent = Workspace
	self.part = gun

	-- ponto do cano (ponta -X do mesh) pro muzzle flash sair daí
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "MuzzlePoint"
	muzzle.Position = Vector3.new(-gun.Size.X / 2, 0.06 * SCALE, 0)
	muzzle.Parent = gun

	self.recoilOffset = CFrame.new()
	self.aiming = false
	self.aimAlpha = 0

	self.conn = RunService.RenderStepped:Connect(function(dt)
		local target = self.aiming and 1 or 0
		self.aimAlpha += (target - self.aimAlpha) * math.clamp(dt * 12, 0, 1)
		local offset = HIP:Lerp(ADS, self.aimAlpha)
		local cam = Workspace.CurrentCamera
		gun.CFrame = cam.CFrame * self.recoilOffset * offset * GUN_ROT
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
	if self.part then
		self.part:Destroy()
	end
end

return Viewmodel
