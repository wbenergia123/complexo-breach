-- src/client/WeaponClient/Recoil.luau
-- Kick de câmera/viewmodel: soma o offset do spray no tiro e volta ao neutro (recovery).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WeaponConfig = require(game.ReplicatedStorage.Shared.WeaponConfig)

local Recoil = {}
Recoil.__index = Recoil

function Recoil.new(cfg, viewmodel)
	local self = setmetatable({}, Recoil)
	self.cfg = cfg
	self.viewmodel = viewmodel
	self.current = Vector2.new() -- {lado, cima} acumulado
	self.shotIndex = 0

	self.conn = RunService.RenderStepped:Connect(function(dt)
		-- recupera em direção a zero
		local recover = math.clamp(dt / cfg.recoilRecovery, 0, 1)
		self.current = self.current:Lerp(Vector2.new(), recover)
		-- aplica na câmera (pitch = cima, yaw = lado)
		local cam = Workspace.CurrentCamera
		local kick = CFrame.Angles(math.rad(self.current.Y), math.rad(-self.current.X), 0)
		cam.CFrame = cam.CFrame * kick
		-- espelha um tiquinho no viewmodel
		if viewmodel then
			viewmodel:setRecoil(CFrame.Angles(math.rad(self.current.Y * 0.5), 0, 0))
		end
	end)
	return self
end

-- chamado a cada tiro
function Recoil:kick()
	self.shotIndex += 1
	local offset = WeaponConfig.getSprayOffset(self.cfg, self.shotIndex)
	self.current += offset
end

-- resetar quando solta o gatilho / recarrega
function Recoil:reset()
	self.shotIndex = 0
end

function Recoil:destroy()
	if self.conn then
		self.conn:Disconnect()
	end
end

return Recoil
