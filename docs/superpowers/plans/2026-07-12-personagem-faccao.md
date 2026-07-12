# Personagem da Facção — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Jogador do time Criminosos spawna como o traficante (skinned mesh) com as 16
animações dirigidas por state machine, hitboxes por osso (dano por parte intacto),
Ctrl agacha / Shift corre, morte com anim + respawn.

**Architecture:** Receita oficial StarterCharacter skinned mesh (HRP+Humanoid+mesh
soldado), hitboxes ancoradas seguindo `Bone.TransformedWorldCFrame` no servidor,
animações todas tocadas pelo cliente dono (uma origem só), velocidade autoritativa no
servidor via remote `MovementState`. Spec: `docs/superpowers/specs/2026-07-12-personagem-faccao-design.md`.

**Tech Stack:** Luau + Rojo (src/ → Studio), MCP robloxstudio (montagem de rig, testes
via `execute_luau`, screenshots), padrão `runChecks()` por assert.

**Contexto pro executor:** tasks marcadas **[STUDIO]** rodam via MCP + usuário no
Studio (não são código em git). Tasks de código commitam em git. O place da favela tem
`Workspace.Terrorista_char` (rig fonte), times `BOPE`/`Criminosos`, e
`ServerStorage.RBX_ANIMSAVES.Terrorista_char` com as KeyframeSequences `*_OK`.

---

### Task 1: CharacterConfig (dados + runChecks)

**Files:**
- Create: `src/shared/CharacterConfig.luau`

- [ ] **Step 1: Escrever o módulo com runChecks**

```lua
-- src/shared/CharacterConfig.luau
-- Dados do personagem da facção (velocidades, hitboxes, rig) + auto-teste.
-- Ver docs/superpowers/specs/2026-07-12-personagem-faccao-design.md

local CharacterConfig = {}

CharacterConfig.TeamName = "Criminosos"
CharacterConfig.RespawnDelay = 3

CharacterConfig.Speeds = {
	walk = 10,
	run = 18, -- Shift (sprint)
	aimWalk = 6, -- mirando (ADS)
	crouch = 6, -- Ctrl
}

CharacterConfig.Rig = {
	rootSize = Vector3.new(2, 4.4, 1.4), -- caixa de colisão da HRP
	hipHeight = 0.3, -- calibrado na montagem (Task 4)
}

-- Hitboxes nomeadas como R15: o computeDamage atual funciona sem mudança.
CharacterConfig.Hitboxes = {
	{ part = "Head", bone = "mixamorig:Head", size = Vector3.new(0.9, 0.9, 0.9) },
	{ part = "UpperTorso", bone = "mixamorig:Spine1", size = Vector3.new(1.5, 1.5, 0.9) },
	{ part = "LowerTorso", bone = "mixamorig:Hips", size = Vector3.new(1.4, 0.9, 0.9) },
	{ part = "LeftUpperLeg", bone = "mixamorig:LeftUpLeg", size = Vector3.new(0.7, 1.6, 0.7) },
	{ part = "RightUpperLeg", bone = "mixamorig:RightUpLeg", size = Vector3.new(0.7, 1.6, 0.7) },
}

function CharacterConfig.runChecks()
	local s = CharacterConfig.Speeds
	assert(s.run > s.walk, "run deve ser mais rapido que walk")
	assert(s.crouch < s.walk, "crouch deve ser mais lento que walk")
	assert(s.aimWalk < s.walk, "aimWalk deve ser mais lento que walk")

	local seen = {}
	for _, hb in CharacterConfig.Hitboxes do
		assert(not seen[hb.part], "hitbox duplicada: " .. hb.part)
		seen[hb.part] = true
		assert(hb.size.X > 0 and hb.size.Y > 0 and hb.size.Z > 0, "tamanho invalido: " .. hb.part)
		assert(hb.bone:sub(1, 10) == "mixamorig:", "osso sem prefixo mixamorig: " .. hb.bone)
	end
	assert(seen.Head, "precisa de hitbox Head (headshot)")
	assert(CharacterConfig.Rig.rootSize.Y < 5.5, "HRP nao pode ser mais alta que o boneco")
	return true
end

return CharacterConfig
```

- [ ] **Step 2: Rodar o runChecks via MCP**

Run (MCP `execute_luau`): `return require(game.ReplicatedStorage.Shared.CharacterConfig).runChecks()`
Expected: `true` (Rojo precisa ter sincado; se módulo não achado, checar Rojo conectado)

- [ ] **Step 3: Commit**

```bash
git add src/shared/CharacterConfig.luau
git commit -m "feat(personagem): CharacterConfig (velocidades, hitboxes por osso, runChecks)"
```

---

### Task 2: CharacterRemotes

**Files:**
- Create: `src/shared/CharacterRemotes.luau`

- [ ] **Step 1: Escrever o módulo (mesmo padrão do WeaponRemotes)**

```lua
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
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/CharacterRemotes.luau
git commit -m "feat(personagem): CharacterRemotes (MovementState)"
```

---

### Task 3: StateResolver (função pura + runChecks)

**Files:**
- Create: `src/client/CharacterAnimator/StateResolver.luau`

- [ ] **Step 1: Escrever o resolver**

Convenção do snapshot: `forward > 0` = andando pra frente, `side > 0` = direita
(o chamador converte MoveDirection pro espaço da HRP). Campos ausentes = false/0.

```lua
-- src/client/CharacterAnimator/StateResolver.luau
-- Resolve o estado de animação a partir de um snapshot. PURO (testável).
-- Prioridade: airborne > crouch > aim parado > locomoção.

local StateResolver = {}

function StateResolver.resolve(input)
	local speed = input.speed or 0
	local forward = input.forward or 0
	local side = input.side or 0
	local moving = speed > 0.5

	if input.airborne then
		return "jump"
	end

	if input.crouching then
		if not moving then
			return "kneelingIdle"
		end
		if math.abs(side) > math.abs(forward) then
			return side > 0 and "crouchRight" or "crouchLeft"
		end
		return forward < 0 and "crouchBack" or "crouchWalk"
	end

	if not moving then
		return input.aiming and "aim" or "idle"
	end

	if math.abs(side) > math.abs(forward) then
		return side > 0 and "strafeRight" or "strafeLeft"
	end
	if forward < 0 then
		return "walkBackward"
	end
	if input.sprinting and not input.aiming then
		return "run"
	end
	return "walk"
end

function StateResolver.runChecks()
	local r = StateResolver.resolve
	assert(r({}) == "idle", "vazio = idle")
	assert(r({ speed = 10, forward = 1 }) == "walk", "frente = walk")
	assert(r({ speed = 18, forward = 1, sprinting = true }) == "run", "shift = run")
	assert(r({ speed = 18, forward = 1, sprinting = true, aiming = true }) == "walk", "mira cancela sprint")
	assert(r({ speed = 10, forward = -1 }) == "walkBackward", "re")
	assert(r({ speed = 10, side = 1 }) == "strafeRight", "direita")
	assert(r({ speed = 10, side = -1 }) == "strafeLeft", "esquerda")
	assert(r({ aiming = true }) == "aim", "mira parado")
	assert(r({ crouching = true }) == "kneelingIdle", "agachado parado")
	assert(r({ speed = 6, forward = 1, crouching = true }) == "crouchWalk", "agachado frente")
	assert(r({ speed = 6, forward = -1, crouching = true }) == "crouchBack", "agachado re")
	assert(r({ speed = 6, side = 1, crouching = true }) == "crouchRight", "agachado dir")
	assert(r({ speed = 6, side = -1, crouching = true }) == "crouchLeft", "agachado esq")
	assert(r({ speed = 10, forward = 1, airborne = true }) == "jump", "no ar = jump")
	assert(r({ speed = 6, forward = 1, crouching = true, aiming = true }) == "crouchWalk", "crouch vence aim")
	return true
end

return StateResolver
```

- [ ] **Step 2: Rodar runChecks via MCP**

Run: `return require(game.StarterPlayer.StarterPlayerScripts.Client.CharacterAnimator.StateResolver).runChecks()`
(caminho conforme o Rojo mapeia `src/client`; conferir com `get_project_structure` se falhar)
Expected: `true`

- [ ] **Step 3: Commit**

```bash
git add src/client/CharacterAnimator/StateResolver.luau
git commit -m "feat(personagem): StateResolver puro com runChecks (16 estados)"
```

---

### Task 4 [STUDIO]: Montar TraficanteRig no ServerStorage

Rig = Model { HumanoidRootPart, Humanoid+Animator, mesh soldado }. Fica no place (não
no git), igual a X9-72. Rodar via MCP `execute_luau`:

- [ ] **Step 1: Montar o rig**

```lua
local ServerStorage = game:GetService("ServerStorage")
local old = ServerStorage:FindFirstChild("TraficanteRig")
if old then old:Destroy() end

local src = workspace.Terrorista_char:FindFirstChildWhichIsA("MeshPart")
local mesh = src:Clone()
-- limpa sobras de sessões (scripts, animsaves refs)
for _, c in mesh:GetChildren() do
	if c:IsA("Script") or c:IsA("LocalScript") then c:Destroy() end
end
mesh.Name = "Body"
mesh.Anchored = false
mesh.CanCollide = false
mesh.CanQuery = false -- tiros atravessam o mesh, acertam as hitboxes nomeadas
mesh.Massless = true

local rig = Instance.new("Model")
rig.Name = "TraficanteRig"
rig:SetAttribute("FactionRig", true)

local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2, 4.4, 1.4)
hrp.Transparency = 1
hrp.CanCollide = true
hrp.CanQuery = false -- [spec v2] senão a caixa engole os tiros e headshot morre
hrp.Anchored = false

-- alinha: base da HRP 0.3 acima do pé do mesh (HipHeight compensa)
-- mesh está em pé no mundo; usa a posição atual do source como referência
local meshCf = src.CFrame
local feetY = meshCf.Position.Y - src.Size.Y / 2
hrp.CFrame = CFrame.new(meshCf.Position.X, feetY + 0.3 + 4.4 / 2, meshCf.Position.Z)
	* (meshCf.Rotation)
mesh.CFrame = meshCf

hrp.Parent = rig
mesh.Parent = rig
rig.PrimaryPart = hrp

local weld = Instance.new("WeldConstraint")
weld.Part0 = hrp
weld.Part1 = mesh
weld.Parent = hrp

local humanoid = Instance.new("Humanoid")
humanoid.AutomaticScalingEnabled = false
humanoid.HipHeight = 0.3
humanoid.BreakJointsOnDeath = false -- senão o corpo desmonta na morte
humanoid.RequiresNeck = false
humanoid.Parent = rig
Instance.new("Animator").Parent = humanoid -- criado no SERVIDOR (regra de replicação)

rig.Parent = ServerStorage
return "TraficanteRig montado em ServerStorage"
```

- [ ] **Step 2: Verificar estrutura**

Run: listar filhos do rig, checar `HumanoidRootPart.CanQuery == false`,
`Body.CanQuery == false`, Humanoid com Animator, WeldConstraint presente, atributo
`FactionRig == true`, e contar Bones do Body (esperado 52).

---

### Task 5: FactionCharacter.server (swap + hitboxes + velocidade + respawn)

**Files:**
- Create: `src/server/FactionCharacter.server.luau`

- [ ] **Step 1: Escrever o script**

```lua
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

local rigTemplate = ServerStorage:WaitForChild("TraficanteRig")
local followConns: { [Player]: RBXScriptConnection } = {}

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
	local parts: { [BasePart]: Bone } = {}
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
		parts[p] = bone
	end
	return RunService.Heartbeat:Connect(function()
		for p, bone in parts do
			p.CFrame = bone.TransformedWorldCFrame
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
	local rig = rigTemplate:Clone()
	rig.Name = player.Name

	-- [spec v2] ordem obrigatória: Character ANTES de parentear no Workspace
	player.Character = rig
	rig.Parent = workspace
	rig:PivotTo(pickSpawnCFrame())

	local humanoid = rig:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = CharacterConfig.Speeds.walk

	local mesh = rig:FindFirstChild("Body") :: MeshPart
	followConns[player] = buildHitboxes(rig, mesh)

	humanoid.Died:Connect(function()
		cleanupPlayer(player)
		local hrp = rig:FindFirstChild("HumanoidRootPart")
		if hrp then
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
	local sprinting = state.sprinting == true
	char:SetAttribute("Crouching", crouching)
	char:SetAttribute("Aiming", aiming)
	local s = CharacterConfig.Speeds
	if crouching then
		humanoid.WalkSpeed = s.crouch
	elseif aiming then
		humanoid.WalkSpeed = s.aimWalk
	elseif sprinting then
		humanoid.WalkSpeed = s.run
	else
		humanoid.WalkSpeed = s.walk
	end
end)
```

- [ ] **Step 2: Teste #0 embutido — validar a premissa dos bones no servidor**

Com o usuário em Play (personagem trocado, idle tocando): rodar via MCP no contexto
servidor um snippet que amostra `Head` hitbox CFrame 3× com 0.3s de intervalo e
compara com a posição do osso. Expected: posições variando junto com a animação
(idle balança). Se congelado: PARAR — premissa falhou, redesenhar hitbox (fallback:
hitboxes soldadas na HRP, estáticas).

- [ ] **Step 3: Playtest do swap (usuário)**

Usuário entra no time Criminosos → Play. Expected: vira o traficante (visto em
3ª pessoa se destravar a câmera; o corpo aparece pros outros). Screenshot obrigatório
(regra: print antes de afirmar).

- [ ] **Step 4: Commit**

```bash
git add src/server/FactionCharacter.server.luau
git commit -m "feat(personagem): swap de avatar da facção + hitboxes por osso + velocidade autoritativa + respawn"
```

---

### Task 6: CharacterAnimator (state machine no cliente dono)

**Files:**
- Create: `src/client/CharacterAnimator/init.luau`

- [ ] **Step 1: Escrever o módulo**

```lua
-- src/client/CharacterAnimator/init.luau
-- Anima o PRÓPRIO personagem da facção (replica via Animator). Uma origem só de
-- animação (inclusive death). Camadas: Movement (locomoção) + Action (upper-body).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local PistolAnims = require(ReplicatedStorage.Shared.PistolAnims)
local Remotes = require(ReplicatedStorage.Shared.CharacterRemotes)
local StateResolver = require(script.StateResolver)

local UPPER_KEYS = { aimUpper = true, shootUpper = true, reloadUpper = true }

local CharacterAnimator = {}

local state = { crouching = false, sprinting = false, aiming = false }
local tracks: { [string]: AnimationTrack } = {}
local aimTrack: AnimationTrack? = nil

local function sendState()
	Remotes.MovementState:FireServer(state)
end

local function loadTracks(animator: Animator)
	table.clear(tracks)
	for key, id in PistolAnims do
		if typeof(id) ~= "string" or id == "" then
			continue
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = UPPER_KEYS[key] and Enum.AnimationPriority.Action
				or Enum.AnimationPriority.Movement
			tracks[key] = track
		else
			warn("[CharacterAnimator] falhou carregar anim:", key)
		end
	end
end

local function onCharacter(char: Model)
	if not char:GetAttribute("FactionRig") then
		return -- avatar padrão (ex: trocou de time): não anima
	end
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
	loadTracks(animator)

	-- 1ª pessoa: dono não vê o próprio corpo
	local mesh = char:FindFirstChild("Body")
	if mesh and mesh:IsA("BasePart") then
		mesh.LocalTransparencyModifier = 1
	end

	-- morte: dono toca a death (uma origem de animação só) [spec v2]
	humanoid.Died:Connect(function()
		for _, t in tracks do
			t:Stop(0.1)
		end
		local death = tracks.death
		if death then
			death.Looped = false
			death:Play(0.1)
		end
	end)

	local current: string? = nil
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if humanoid.Health <= 0 or char.Parent == nil then
			conn:Disconnect()
			return
		end
		local moveDir = humanoid.MoveDirection
		local localDir = hrp.CFrame:VectorToObjectSpace(moveDir)
		local hState = humanoid:GetState()
		local target = StateResolver.resolve({
			speed = moveDir.Magnitude * humanoid.WalkSpeed,
			forward = -localDir.Z,
			side = localDir.X,
			aiming = state.aiming,
			crouching = state.crouching,
			sprinting = state.sprinting,
			airborne = hState == Enum.HumanoidStateType.Jumping
				or hState == Enum.HumanoidStateType.Freefall,
		})
		if target ~= current then
			if current and tracks[current] then
				tracks[current]:Stop(0.2)
			end
			local t = tracks[target]
			if t then
				t.Looped = true
				t:Play(0.15)
			end
			current = target
		end
	end)
end

function CharacterAnimator.start()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.defer(onCharacter, player.Character)
	end

	ContextActionService:BindAction("FactionCrouch", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			state.crouching = true
			sendState()
		elseif inputState == Enum.UserInputState.End then
			state.crouching = false
			sendState()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftControl)

	ContextActionService:BindAction("FactionSprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			state.sprinting = true
			sendState()
		elseif inputState == Enum.UserInputState.End then
			state.sprinting = false
			sendState()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift)
end

-- ==== hooks chamados pelo Input da arma (uma via só, sem duplicar lógica) ====

function CharacterAnimator.setAiming(aiming: boolean)
	state.aiming = aiming
	sendState()
	local t = tracks.aimUpper or tracks.aim
	if not t then
		return
	end
	if aiming then
		t.Looped = true
		t:Play(0.15)
	else
		t:Stop(0.2)
	end
end

function CharacterAnimator.onShot()
	local t = tracks.shootUpper or tracks.shooting
	if t then
		t.Looped = false
		t:Play(0.05)
	end
end

function CharacterAnimator.onReload()
	local t = tracks.reloadUpper or tracks.reload
	if t then
		t.Looped = false
		t:Play(0.1)
	end
end

return CharacterAnimator
```

- [ ] **Step 2: Commit**

```bash
git add src/client/CharacterAnimator/init.luau
git commit -m "feat(personagem): CharacterAnimator (state machine + camadas + death pelo dono)"
```

---

### Task 7: Ligar no init.client e no Input da arma

**Files:**
- Modify: `src/client/init.client.luau`
- Modify: `src/client/WeaponClient/Input.luau`

- [ ] **Step 1: init.client — iniciar o animator no favela**

No branch `elseif game.PlaceId == Config.FavelaPlaceId then`:

```lua
elseif game.PlaceId == Config.FavelaPlaceId then
	local CharacterAnimator = require(script:WaitForChild("CharacterAnimator"))
	CharacterAnimator.start()
	local WeaponClient = require(script:WaitForChild("WeaponClient"))
	WeaponClient.start()
end
```

- [ ] **Step 2: Input.luau — notificar o animator (3 pontos)**

No topo do módulo:

```lua
local CharacterAnimator = require(script.Parent.Parent.CharacterAnimator)
```

Dentro de `tryFire()`, logo após `effects:fire(dir)`:

```lua
CharacterAnimator.onShot()
```

No bind de `Reload`, após `Remotes.Reload:FireServer()`:

```lua
CharacterAnimator.onReload()
```

No bind de `Aim`: substituir os dois `aim:set(...)` por:

```lua
aim:set(true)
CharacterAnimator.setAiming(true)
-- ... e no End:
aim:set(false)
CharacterAnimator.setAiming(false)
```

- [ ] **Step 3: Rodar runChecks de regressão via MCP**

Run: `return require(game.ReplicatedStorage.Shared.WeaponConfig).runChecks()`
Expected: `true` (nada da arma quebrou)

- [ ] **Step 4: Commit**

```bash
git add src/client/init.client.luau src/client/WeaponClient/Input.luau
git commit -m "feat(personagem): liga CharacterAnimator no init e nos eventos da arma"
```

---

### Task 8 [STUDIO]: Playtest 1 — locomoção completa

- [ ] **Step 1:** Usuário no time Criminosos → Play. Testar: parado (idle), WASD
  (walk/strafes/ré), Shift (run + mais rápido), Ctrl (agacha + mais lento +
  crouch anims), espaço (jump), mirar (aim + mais lento), atirar (tranco), R (reload),
  morrer (death + respawn 3s).
- [ ] **Step 2:** Print/vídeo de cada estado problemático; corrigir e re-testar até
  passar. Calibrar `hipHeight`/`rootSize` se afundar/flutuar (editar template no
  ServerStorage + CharacterConfig).
- [ ] **Step 3:** Teste de servidor 2 players (Studio → Test → 2 Players): o segundo
  cliente VÊ o primeiro animando (replicação).

---

### Task 9 [STUDIO]: Upper-body variants (aim/shoot/reload só tronco)

Estilo CS: pernas continuam na locomoção enquanto o tronco mira/atira/recarrega.
Fallback já embutido no código (`tracks.aimUpper or tracks.aim`), então esta task é
polish — se der problema, pular sem quebrar nada.

- [ ] **Step 1: Gerar as 3 KS upper via MCP** — para cada uma de
  `Aim_OK`/`Shooting_OK`/`Reload_OK` em `ServerStorage.RBX_ANIMSAVES.Terrorista_char`:
  clonar, renomear `Aim_Upper`/`Shoot_Upper`/`Reload_Upper`, e em TODAS as keyframes
  setar `Weight = 0` nas Poses de `mixamorig:Hips` (o container), `mixamorig:LeftUpLeg`,
  `mixamorig:RightUpLeg` **e todos os descendentes das pernas** (LeftLeg, LeftFoot,
  LeftToeBase, RightLeg, RightFoot, RightToeBase) — pernas ficam com a track Movement.
- [ ] **Step 2: Usuário publica as 3** (Load → Publish) e manda os IDs.
- [ ] **Step 3: Adicionar em PistolAnims.luau:**

```lua
	-- upper-body (só tronco/braços; pernas seguem a locomoção):
	aimUpper = "<ID>",
	shootUpper = "<ID>",
	reloadUpper = "<ID>",
```

- [ ] **Step 4: Playtest** — correr mirando/atirando/recarregando: pernas continuam
  correndo, tronco faz a ação. Commit:

```bash
git add src/shared/PistolAnims.luau
git commit -m "feat(personagem): anims upper-body (aim/shoot/reload) pra camada Action"
```

---

### Task 10 [STUDIO]: Validação de dano (hitboxes)

- [ ] **Step 1:** 2 Players: um BOPE atira no Criminoso. Verificar dano no corpo
  (36), headshot (multiplicador 4x — mata), perna (0.8x). Com o Criminoso AGACHADO,
  headshot na altura nova da cabeça tem que funcionar (hitbox seguiu o osso).
- [ ] **Step 2:** Confirmar que tiro NÃO acerta a HRP (adicionar print temporário do
  `hitPartName` no WeaponServer se necessário; remover depois).
- [ ] **Step 3:** Commit final + merge:

```bash
git add -A && git commit -m "feat(personagem): validação de dano por hitbox"
```

---

## Fora do plano (registrado)

- Hitbox de braços/canelas (+4 partes depois)
- `CharacterAutoLoads=false` (anti-flash do avatar padrão)
- RigidConstraint hitbox→Bone (upgrade se Teste #0 mostrar que segue no servidor)
- Personagem BOPE, ragdoll, sons de passos
