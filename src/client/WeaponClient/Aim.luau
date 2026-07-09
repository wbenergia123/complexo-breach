-- src/client/WeaponClient/Aim.luau
-- ADS: reduz o FOV e aproxima o viewmodel do centro ao mirar.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Aim = {}
Aim.__index = Aim

local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

function Aim.new(cfg, viewmodel)
	local self = setmetatable({}, Aim)
	self.cfg = cfg
	self.viewmodel = viewmodel
	self.aiming = false
	return self
end

function Aim:set(aiming)
	self.aiming = aiming
	local cam = Workspace.CurrentCamera
	local fov = aiming and self.cfg.adsFov or self.cfg.baseFov
	TweenService:Create(cam, TWEEN, { FieldOfView = fov }):Play()
	if self.viewmodel.setAiming then
		self.viewmodel:setAiming(aiming)
	end
end

return Aim
