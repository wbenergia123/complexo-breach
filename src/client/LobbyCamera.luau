-- Trava a câmera enfrentando o personagem no lobby (visual de lobby FPS).
-- O personagem fica parado; a câmera olha pra frente dele.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LobbyCamera = {}

function LobbyCamera.start()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	local function frame(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if not hrp then
			return
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end

		camera.CameraType = Enum.CameraType.Scriptable

		local function update()
			if not hrp.Parent then
				return
			end
			local pos = hrp.Position
			local camPos = pos + hrp.CFrame.LookVector * 9 + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(camPos, pos + Vector3.new(0, 0.5, 0))
		end

		update()
		RunService:BindToRenderStep("LobbyCam", Enum.RenderPriority.Camera.Value, update)
	end

	if player.Character then
		frame(player.Character)
	end
	player.CharacterAdded:Connect(frame)
end

return LobbyCamera
