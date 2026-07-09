-- src/shared/WeaponRemotes.luau
-- Só o servidor pode criar RemoteEvent (instância do cliente não replica) [R5].
-- Servidor: cria. Cliente: WaitForChild (evita race se carregar antes do servidor).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = { "FireRequest", "Reload", "ShotFx" }
local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("WeaponRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "WeaponRemotes"
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
	local folder = ReplicatedStorage:WaitForChild("WeaponRemotes")
	for _, name in NAMES do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
