-- src/server/FactionCharacter.server.luau
-- Time Criminosos spawna como o traficante: swap de avatar, hitboxes por osso
-- (nomes R15 -> computeDamage intacto), velocidade autoritativa, respawn com delay.
-- Ver docs/superpowers/specs/2026-07-12-personagem-faccao-design.md

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
if game.PlaceId ~= Config.FavelaPlaceId then
	return
end

local CharacterConfig = require(ReplicatedStorage.Shared.CharacterConfig)
local Remotes = require(ReplicatedStorage.Shared.CharacterRemotes)

-- skins da facção: pasta com os rigs; cada spawn sorteia um (variedade estilo CS)
local rigFolder = ServerStorage:WaitForChild("FactionRigs")
local followConns: { [Player]: RBXScriptConnection } = {}

local function pickRigTemplate(): Model
	local rigs = rigFolder:GetChildren()
	return rigs[math.random(#rigs)] :: Model
end

local function pickSpawnCFrame(): CFrame
	local map = workspace:FindFirstChild("Map")
	local spawns = map and map:FindFirstChild("Spawns")
	if spawns then
		local list = spawns:GetChildren()
		if #list > 0 then
			local s = list[math.random(#list)]
			return s:GetPivot() + Vector3.new(0, 4, 0)
		end
	end
	return CFrame.new(0, 10, 0)
end

local function buildHitboxes(character: Model, mesh: MeshPart): RBXScriptConnection
	local bones: { [string]: Bone } = {}
	for _, d in mesh:GetDescendants() do
		if d:IsA("Bone") then
			bones[d.Name] = d
		end
	end
	-- cada entrada segue um osso (hitboxes sem offset; arma com grip offset)
	local follows: { [BasePart]: { bone: Bone, offset: CFrame } } = {}
	local IDENTITY = CFrame.new()
	for _, hb in CharacterConfig.Hitboxes do
		local bone = bones[hb.bone]
		if not bone then
			warn("[FactionCharacter] osso ausente, hitbox pulada:", hb.bone)
			continue
		end
		local p = Instance.new("Part")
		p.Name = hb.part
		p.Size = hb.size
		p.Anchored = true -- [spec v2] raycastavel, zero simulacao
		p.CanCollide = false
		p.CanQuery = true
		p.CanTouch = false
		p.Transparency = 1
		p.CFrame = bone.TransformedWorldCFrame
		p.Parent = character
		follows[p] = { bone = bone, offset = IDENTITY }
	end

	-- (arma de mundo X9-72 removida — a pistola do pack FPS vai substituir na 3ª pessoa)

	return RunService.Heartbeat:Connect(function()
		for p, f in follows do
			p.CFrame = f.bone.TransformedWorldCFrame * f.offset
		end
	end)
end

local function cleanupPlayer(player: Player)
	if followConns[player] then
		followConns[player]:Disconnect()
		followConns[player] = nil
	end
end

local function spawnFaction(player: Player)
	cleanupPlayer(player)
	local old = player.Character -- avatar padrão ou cadáver do respawn
	local rig = pickRigTemplate():Clone()
	rig.Name = player.Name

	-- [spec v2] ordem obrigatória: Character ANTES de parentear no Workspace
	player.Character = rig
	rig.Parent = workspace
	if old and old ~= rig then
		old:Destroy() -- senão cada morte/reset deixa um boneco eterno na cena
	end
	rig:PivotTo(pickSpawnCFrame())

	local humanoid = rig:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = CharacterConfig.Speeds.base
	humanoid.CameraOffset = Vector3.new(0, CharacterConfig.Rig.cameraHeightBoost, 0)

	local mesh = rig:FindFirstChild("Body") :: MeshPart
	followConns[player] = buildHitboxes(rig, mesh)

	humanoid.Died:Connect(function()
		cleanupPlayer(player)
		local hrp = rig:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			hrp.Anchored = true -- corpo fica no lugar; death anim é tocada pelo DONO
		end
		task.delay(CharacterConfig.RespawnDelay, function()
			if player.Parent and player.Team and player.Team.Name == CharacterConfig.TeamName then
				spawnFaction(player)
			elseif player.Parent then
				player:LoadCharacter() -- trocou de time morto: volta avatar padrão
			end
		end)
	end)
end

local function onCharacterAdded(player: Player, character: Model)
	-- swap só pra Criminosos e só se ainda for o avatar padrão (evita loop no rig)
	if character:GetAttribute("FactionRig") then
		return
	end
	if player.Team and player.Team.Name == CharacterConfig.TeamName then
		task.defer(spawnFaction, player)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(c)
		onCharacterAdded(player, c)
	end)
end)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- velocidade autoritativa (anti-speedhack básico): cliente só declara intenção
Remotes.MovementState.OnServerEvent:Connect(function(player, state)
	if typeof(state) ~= "table" then
		return
	end
	local char = player.Character
	if not char or not char:GetAttribute("FactionRig") then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local crouching = state.crouching == true
	local aiming = state.aiming == true
	local slowWalk = state.slowWalk == true
	char:SetAttribute("Crouching", crouching)
	char:SetAttribute("Aiming", aiming)
	-- agachado: encolhe a caixa de colisão (corpo soldado desce junto; ver CharacterConfig)
	local rigCfg = CharacterConfig.Rig
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		local h = crouching and rigCfg.crouchRootHeight or rigCfg.rootSize.Y
		hrp.Size = Vector3.new(rigCfg.rootSize.X, h, rigCfg.rootSize.Z)
	end
	-- modelo CS: base = corrida; Shift/mira = andar; agachado = mais lento
	local s = CharacterConfig.Speeds
	if crouching then
		humanoid.WalkSpeed = s.crouch
	elseif aiming then
		humanoid.WalkSpeed = s.aimWalk
	elseif slowWalk then
		humanoid.WalkSpeed = s.shiftWalk
	else
		humanoid.WalkSpeed = s.base
	end
end)
