-- src/client/WeaponClient/Input.luau
-- PC (mouse/R/dir) + Mobile (botão de toque = 3º arg do BindAction [R8]).
-- Fire: feedback local (recoil) + envia SÓ a direção da câmera [R3] (sem timestamp).

local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game.ReplicatedStorage.Shared.WeaponRemotes)

local Input = {}

function Input.start(cfg, recoil)
	local firing = false
	local lastLocalShot = 0
	local localMag = cfg.ammo.magazine -- predição; HUD reconcilia com servidor [R2]

	local function tryFire()
		local now = os.clock()
		if now - lastLocalShot < cfg.fireRate then
			return
		end
		if localMag <= 0 then
			return
		end
		lastLocalShot = now
		localMag -= 1
		recoil:kick() -- feedback instantâneo
		local dir = Workspace.CurrentCamera.CFrame.LookVector
		Remotes.FireRequest:FireServer(dir) -- [R3] só direção
	end

	-- loop de fogo automático enquanto segura
	RunService.RenderStepped:Connect(function()
		if firing and cfg.automatic then
			tryFire()
		end
	end)

	CAS:BindAction("Fire", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			firing = true
			tryFire() -- primeiro tiro imediato
		elseif inputState == Enum.UserInputState.End then
			firing = false
			recoil:reset()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch) -- [R8] 3º arg cria botão mobile

	CAS:BindAction("Reload", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Remotes.Reload:FireServer()
			recoil:reset()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.R)

	-- expõe pro HUD reconciliar munição autoritativa
	Input.setLocalMag = function(v)
		localMag = v
	end
	return Input
end

return Input
