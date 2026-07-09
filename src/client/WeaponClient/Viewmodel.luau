-- src/client/WeaponClient/Viewmodel.luau
-- Arma placeholder (bloco) presa à câmera todo frame. Placeholder até modelo real.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Viewmodel = {}
Viewmodel.__index = Viewmodel

local HIP = CFrame.new(0.8, -0.8, -1.6) -- direita, baixo, frente
local ADS = CFrame.new(0, -0.35, -1.0) -- centralizado ao mirar

function Viewmodel.new()
	local self = setmetatable({}, Viewmodel)
	local part = Instance.new("Part")
	part.Name = "ViewmodelGun"
	part.Size = Vector3.new(0.3, 0.4, 1.8)
	part.Color = Color3.fromRGB(30, 30, 32)
	part.Material = Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = Workspace
	self.part = part
	self.recoilOffset = CFrame.new()
	self.aiming = false
	self.aimAlpha = 0

	self.conn = RunService.RenderStepped:Connect(function(dt)
		local target = self.aiming and 1 or 0
		self.aimAlpha += (target - self.aimAlpha) * math.clamp(dt * 12, 0, 1)
		local offset = HIP:Lerp(ADS, self.aimAlpha)
		local cam = Workspace.CurrentCamera
		part.CFrame = cam.CFrame * self.recoilOffset * offset
	end)
	return self
end

function Viewmodel:setAiming(aiming)
	self.aiming = aiming
end

-- recoilCFrame vem do módulo Recoil (kick visual)
function Viewmodel:setRecoil(recoilCFrame)
	self.recoilOffset = recoilCFrame
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
