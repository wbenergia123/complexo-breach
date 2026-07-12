-- src/shared/CharacterRemotes.luau
-- Remotes do personagem. Servidor cria, cliente espera (padrão WeaponRemotes).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = { "MovementState" }
local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("CharacterRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CharacterRemotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		local r = folder:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
		Remotes[name] = r
	end
else
	local folder = ReplicatedStorage:WaitForChild("CharacterRemotes")
	for _, name in NAMES do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
