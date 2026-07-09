# Sistema de Arma v1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uma fatia jogável de combate FPS no place da favela — atirar (hitscan, 1ª pessoa com viewmodel), dano autoritativo no servidor, recarga, ADS, PC+mobile, contra um boneco de treino.

**Architecture:** Config data-driven em `src/shared`; servidor dono de munição/cadência/dano (valida `FireRequest`, raycast, aplica dano); cliente cuida do feel (viewmodel, recoil por mola, HUD) e manda só a direção. Tudo gated pro place da favela por `PlaceId`. Baseado em `docs/superpowers/specs/2026-07-08-sistema-arma-v1-design.md`.

**Tech Stack:** Roblox Luau, Rojo (filesystem = fonte da verdade), RemoteEvents, RaycastParams, ContextActionService, RunService. Testes: `runChecks()` por `assert` rodável via MCP `execute_luau`; runtime verificado por playtest no place da favela.

---

## Pré-requisitos (fazer 1x antes das tasks)

1. **Studio:** abrir o place da **favela** (`mapa favela`, placeId `108947547992090`) e conectar o **Rojo** (só nesse place; o menu fica fechado). Rojo sincroniza `src/` pra esse place enquanto se testa.
2. **Modelo do dummy (manual, [R6]):** no Studio → aba **Avatar → Rig Builder → R15 → Block Rig**. Renomear o modelo pra `TrainingDummy`. No Explorer, arrastar pra **ServerStorage**. (Não construir rig por código — frágil e quebra o headshot.)
3. Rodar `WeaponConfig.runChecks()` via MCP após a Task 1 pra validar a lógica sem entrar no jogo.

## Mapa de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `src/shared/WeaponConfig.luau` | dados da arma + funções puras (`computeDamage`, `getSprayOffset`) + `runChecks()` |
| `src/shared/WeaponRemotes.luau` | cria/expõe RemoteEvents, ramificando server/client [R5] |
| `src/server/WeaponServer.server.luau` | autoridade: valida, raycast (exclui atirador), aplica dano, responde |
| `src/server/DummyTarget.server.luau` | clona/respawna `TrainingDummy` do ServerStorage |
| `src/client/WeaponClient/init.luau` | gate favela, trava 1ª pessoa, orquestra submódulos |
| `src/client/WeaponClient/Viewmodel.luau` | arma placeholder presa na câmera |
| `src/client/WeaponClient/Recoil.luau` | kick por mola + spray |
| `src/client/WeaponClient/Input.luau` | PC + mobile (BindAction) |
| `src/client/WeaponClient/HUD.luau` | mira, munição (autoritativa), hitmarker |

O `src/client/init.client.luau` (já existe, gated) ganha o branch da favela pra montar o `WeaponClient`.

---

### Task 1: WeaponConfig — dados + lógica pura + runChecks (TDD)

**Files:**
- Create: `src/shared/WeaponConfig.luau`

- [ ] **Step 1: Escrever o config + funções puras + o auto-teste (o teste vem junto, é o `runChecks`)**

```lua
-- src/shared/WeaponConfig.luau
-- Dados da arma (data-driven) + lógica pura de dano/spray + auto-teste.
-- Ver docs/superpowers/specs/2026-07-08-sistema-arma-v1-design.md

local WeaponConfig = {}

WeaponConfig.Rifle = {
	name = "placeholder_rifle",
	automatic = true,
	fireRate = 0.1, -- segundos entre tiros (0.1 = 600 rpm)
	shots = 1, -- pellets por disparo (>1 = shotgun no futuro)
	ammo = { magazine = 30, reserve = 90 },
	reloadTime = 2.2,
	equipTime = 0.6,
	range = 500, -- studs
	damage = {
		base = 36,
		headMult = 4.0,
		legMult = 0.8,
		falloff = { startDist = 40, perStud = 0.5, minDamage = 20 }, -- [R10] studs
	},
	accuracy = { firstBullet = 0, standing = 1.5, crouch = 1.0, moving = 6, jumping = 12 },
	spray = {
		{ 0, 0 }, { 0.1, 1.4 }, { 0.3, 1.1 }, { 0.2, 1.2 },
		{ -0.1, 1.0 }, { -0.3, 0.8 }, { 0.4, 0.6 }, { 0.5, 0.5 },
	}, -- {lado, cima} por bala
	recoilRecovery = 0.3,
	recoilSpring = { mass = 5, force = 50, damping = 4 },
}

local LEG_PARTS = {
	LeftUpperLeg = true, RightUpperLeg = true,
	LeftLowerLeg = true, RightLowerLeg = true,
	LeftFoot = true, RightFoot = true,
}

local function partMultiplier(cfg, hitPartName)
	if hitPartName == "Head" then
		return cfg.damage.headMult
	elseif LEG_PARTS[hitPartName] then
		return cfg.damage.legMult
	end
	return 1
end

-- dano = base reduzido por falloff (>= minDamage) e depois multiplicado pela parte
function WeaponConfig.computeDamage(cfg, dist, hitPartName)
	local d = cfg.damage.base
	local fo = cfg.damage.falloff
	if dist > fo.startDist then
		d -= (dist - fo.startDist) * fo.perStud
	end
	d = math.max(d, fo.minDamage)
	return d * partMultiplier(cfg, hitPartName)
end

-- offset de recuo da bala N (clampa na última — não estoura o array)
function WeaponConfig.getSprayOffset(cfg, shotIndex)
	local i = math.clamp(shotIndex, 1, #cfg.spray)
	local o = cfg.spray[i]
	return Vector2.new(o[1], o[2])
end

function WeaponConfig.runChecks()
	local c = WeaponConfig.Rifle
	local head = WeaponConfig.computeDamage(c, 5, "Head")
	local body = WeaponConfig.computeDamage(c, 5, "UpperTorso")
	local leg = WeaponConfig.computeDamage(c, 5, "LeftUpperLeg")
	assert(head > body, "headshot deve doer mais que corpo")
	assert(body > leg, "corpo deve doer mais que perna")

	local near = WeaponConfig.computeDamage(c, 5, "UpperTorso")
	local far = WeaponConfig.computeDamage(c, 300, "UpperTorso")
	assert(far < near, "falloff deve reduzir dano na distância")
	assert(far >= c.damage.falloff.minDamage, "não pode passar do dano mínimo")

	local clamped = WeaponConfig.getSprayOffset(c, 999)
	local lastReal = WeaponConfig.getSprayOffset(c, #c.spray)
	assert(clamped == lastReal, "spray deve clampar na última bala")
	return true
end

return WeaponConfig
```

- [ ] **Step 2: Rodar o teste e ver PASSAR (via MCP, sem entrar no jogo)**

Rodar via `execute_luau` (o Rojo já sincronizou o módulo pro place):

```lua
local ok, err = pcall(function()
	return require(game.ReplicatedStorage.Shared.WeaponConfig).runChecks()
end)
return "runChecks ok=" .. tostring(ok) .. " err=" .. tostring(err)
```
Esperado: `runChecks ok=true err=nil`. Se falhar, o `err` diz qual assert quebrou.

- [ ] **Step 3: Commit**

```bash
git add src/shared/WeaponConfig.luau
git commit -m "feat(arma): WeaponConfig data-driven + dano/spray + runChecks"
```

---

### Task 2: WeaponRemotes — RemoteEvents com branch server/client [R5]

**Files:**
- Create: `src/shared/WeaponRemotes.luau`

- [ ] **Step 1: Escrever o módulo que ramifica (só servidor cria; cliente espera)**

```lua
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
```

- [ ] **Step 2: Verificar no servidor que os remotes existem (via MCP)**

```lua
require(game.ReplicatedStorage.Shared.WeaponRemotes) -- server context cria
local f = game.ReplicatedStorage:FindFirstChild("WeaponRemotes")
return f and (f:FindFirstChild("FireRequest") ~= nil and f:FindFirstChild("ShotFx") ~= nil)
```
Esperado: `true`.

- [ ] **Step 3: Commit**

```bash
git add src/shared/WeaponRemotes.luau
git commit -m "feat(arma): WeaponRemotes com branch server/client"
```

---

### Task 3: DummyTarget — boneco de treino [R6]

**Files:**
- Create: `src/server/DummyTarget.server.luau`
- Prereq: `TrainingDummy` já em `ServerStorage` do place (ver Pré-requisitos)

- [ ] **Step 1: Escrever o spawner que clona o modelo pronto e respawna na morte**

```lua
-- src/server/DummyTarget.server.luau
-- Clona o TrainingDummy (modelo pronto no ServerStorage) e respawna ao morrer.
-- Só no place da favela.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
if game.PlaceId ~= Config.FavelaPlaceId then
	return
end

local SPAWN_CFRAME = CFrame.new(0, 5, -20) -- ajustar pro ponto desejado no mapa
local RESPAWN_DELAY = 3

local template = ServerStorage:WaitForChild("TrainingDummy")

local function spawnDummy()
	local dummy = template:Clone()
	dummy:PivotTo(SPAWN_CFRAME)
	dummy.Parent = Workspace
	local hum = dummy:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Once(function()
			task.delay(RESPAWN_DELAY, function()
				dummy:Destroy()
				spawnDummy()
			end)
		end)
	end
end

spawnDummy()
```

- [ ] **Step 2: Playtest no place da favela — o boneco aparece**

Playtest (F5). Esperado: o `TrainingDummy` está em pé no ponto. Matar via MCP e ver respawnar:
```lua
local d = workspace:FindFirstChild("TrainingDummy")
local h = d and d:FindFirstChildOfClass("Humanoid")
if h then h.Health = 0 end
return "matou o dummy; deve respawnar em 3s"
```
Esperado: some e reaparece após ~3s.

- [ ] **Step 3: Commit**

```bash
git add src/server/DummyTarget.server.luau
git commit -m "feat(arma): boneco de treino com respawn"
```

---

### Task 4: WeaponServer — tiro autoritativo [R1][R2][R11]

**Files:**
- Create: `src/server/WeaponServer.server.luau`

- [ ] **Step 1: Escrever o servidor (valida, raycast excluindo o atirador, dano, responde)**

```lua
-- src/server/WeaponServer.server.luau
-- Autoridade do tiro: munição/cadência/dano no servidor. Só no place da favela.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
if game.PlaceId ~= Config.FavelaPlaceId then
	return
end

local WeaponConfig = require(Shared:WaitForChild("WeaponConfig"))
local Remotes = require(Shared:WaitForChild("WeaponRemotes"))
local cfg = WeaponConfig.Rifle

local state = {} -- [player] = { mag, reserve, lastShot }

local function initState(player)
	state[player] = { mag = cfg.ammo.magazine, reserve = cfg.ammo.reserve, lastShot = 0 }
end
Players.PlayerAdded:Connect(initState)
for _, p in Players:GetPlayers() do
	initState(p)
end
Players.PlayerRemoving:Connect(function(p)
	state[p] = nil
end)

Remotes.FireRequest.OnServerEvent:Connect(function(player, direction)
	local st = state[player]
	local char = player.Character
	if not st or not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	if typeof(direction) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if now - st.lastShot < cfg.fireRate then
		return
	end
	if st.mag <= 0 then
		return
	end
	st.lastShot = now
	st.mag -= 1

	local headPart = char:FindFirstChild("Head")
	local origin = headPart and headPart.Position or char:GetPivot().Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char } -- [R11]

	local result = Workspace:Raycast(origin, direction.Unit * cfg.range, params)
	local hit, headshot = false, false
	if result and result.Instance then
		local victimHum = result.Instance.Parent
			and result.Instance.Parent:FindFirstChildOfClass("Humanoid")
		if victimHum and victimHum.Health > 0 then
			local dist = (result.Position - origin).Magnitude
			local dmg = WeaponConfig.computeDamage(cfg, dist, result.Instance.Name)
			victimHum:TakeDamage(dmg)
			hit = true
			headshot = result.Instance.Name == "Head"
		end
	end

	-- [R1][R2] confirma pro atirador: hitmarker + munição autoritativa
	Remotes.ShotFx:FireClient(player, { selfShot = true, hit = hit, headshot = headshot, ammo = st.mag })
	-- replica pros outros: tracer/som
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.ShotFx:FireClient(other, { origin = origin, direction = direction })
		end
	end
end)

Remotes.Reload.OnServerEvent:Connect(function(player)
	local st = state[player]
	if not st then
		return
	end
	local need = cfg.ammo.magazine - st.mag
	if need <= 0 or st.reserve <= 0 then
		return
	end
	task.wait(cfg.reloadTime)
	st = state[player]
	if not st then
		return
	end
	local take = math.min(need, st.reserve)
	st.mag += take
	st.reserve -= take
	Remotes.ShotFx:FireClient(player, { selfShot = true, reloaded = true, ammo = st.mag, reserve = st.reserve })
end)
```

- [ ] **Step 2: Verificar dano via MCP (simula um FireRequest do servidor mirando no dummy)**

Com o dummy vivo, dispara um raycast igual ao do servidor pra confirmar que acerta e tira vida:
```lua
local d = workspace:FindFirstChild("TrainingDummy")
local h = d and d:FindFirstChildOfClass("Humanoid")
local before = h and h.Health
-- simula: raycast do (0,6,0) na direção do dummy
local origin = Vector3.new(0, 6, 0)
local dir = (d:GetPivot().Position - origin)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local res = workspace:Raycast(origin, dir.Unit * 500, params)
return ("hit=%s part=%s vidaAntes=%s"):format(tostring(res ~= nil), res and res.Instance.Name or "nil", tostring(before))
```
Esperado: `hit=true` e a `part` é uma parte do dummy. (O dano de verdade é validado no end-to-end da Task 8.)

- [ ] **Step 3: Commit**

```bash
git add src/server/WeaponServer.server.luau
git commit -m "feat(arma): servidor autoritativo (valida, raycast, dano, munição)"
```

---

### Task 5: WeaponClient init + Viewmodel — 1ª pessoa [R7]

**Files:**
- Create: `src/client/WeaponClient/init.luau`
- Create: `src/client/WeaponClient/Viewmodel.luau`
- Modify: `src/client/init.client.luau` (adicionar branch da favela)

- [ ] **Step 1: Viewmodel — arma placeholder presa na câmera**

```lua
-- src/client/WeaponClient/Viewmodel.luau
-- Arma placeholder (bloco) presa à câmera todo frame. Placeholder até modelo real.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Viewmodel = {}
Viewmodel.__index = Viewmodel

local OFFSET = CFrame.new(0.8, -0.8, -1.6) -- direita, baixo, frente

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

	self.conn = RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		part.CFrame = cam.CFrame * self.recoilOffset * OFFSET
	end)
	return self
end

-- recoilCFrame vem do módulo Recoil (kick visual)
function Viewmodel:setRecoil(recoilCFrame)
	self.recoilOffset = recoilCFrame
end

function Viewmodel:destroy()
	if self.conn then self.conn:Disconnect() end
	if self.part then self.part:Destroy() end
end

return Viewmodel
```

- [ ] **Step 2: init.luau — gate, trava 1ª pessoa, monta viewmodel (submódulos entram nas próximas tasks)**

```lua
-- src/client/WeaponClient/init.luau
-- Orquestra o combate no cliente. Trava 1ª pessoa em código [R7] (não no project.json).

local Players = game:GetService("Players")

local Viewmodel = require(script:WaitForChild("Viewmodel"))

local WeaponClient = {}

function WeaponClient.start()
	local player = Players.LocalPlayer
	player.CameraMode = Enum.CameraMode.LockFirstPerson -- [R7]

	local viewmodel = Viewmodel.new()
	WeaponClient.viewmodel = viewmodel
	-- Input, Recoil e HUD são conectados nas Tasks 6-8.
end

return WeaponClient
```

- [ ] **Step 3: Ligar no init.client.luau (branch da favela)**

Modificar `src/client/init.client.luau` — adicionar, depois do branch do menu:

```lua
-- src/client/init.client.luau (versão completa após a mudança)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

if game.PlaceId == Config.StartPlaceId then
	local MainMenu = require(script:WaitForChild("MainMenu"))
	local LobbyCamera = require(script:WaitForChild("LobbyCamera"))
	MainMenu.mount()
	LobbyCamera.start()
elseif game.PlaceId == Config.FavelaPlaceId then
	local WeaponClient = require(script:WaitForChild("WeaponClient"))
	WeaponClient.start()
end
```

- [ ] **Step 4: Playtest no place da favela — 1ª pessoa + arma na tela**

Playtest (F5). Esperado: câmera trava em 1ª pessoa e o bloco-arma aparece no canto inferior direito, acompanhando a câmera.

- [ ] **Step 5: Commit**

```bash
git add src/client/WeaponClient/init.luau src/client/WeaponClient/Viewmodel.luau src/client/init.client.luau
git commit -m "feat(arma): cliente 1ª pessoa + viewmodel placeholder"
```

---

### Task 6: Recoil — kick por mola + spray

**Files:**
- Create: `src/client/WeaponClient/Recoil.luau`
- Modify: `src/client/WeaponClient/init.luau`

- [ ] **Step 1: Recoil — acumula spray no tiro, recupera suave por frame**

```lua
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
	if self.conn then self.conn:Disconnect() end
end

return Recoil
```

- [ ] **Step 2: Instanciar no init.luau**

Adicionar no `WeaponClient.start()` (após criar o viewmodel):
```lua
	local Recoil = require(script:WaitForChild("Recoil"))
	local WeaponConfig = require(game.ReplicatedStorage.Shared.WeaponConfig)
	local recoil = Recoil.new(WeaponConfig.Rifle, viewmodel)
	WeaponClient.recoil = recoil
```
(adicionar `local Recoil = require(...)` no topo junto dos outros requires)

- [ ] **Step 3: Playtest — teste manual do kick via MCP**

Durante o playtest, forçar alguns kicks e ver a câmera subir/andar em padrão:
```lua
-- rodar no cliente do playtest via execute_luau (contexto do jogador)
-- (chamada de exemplo; no jogo real o Input.luau chama recoil:kick())
return "verificar manualmente: ao disparar (Task 7) a câmera sobe em padrão e volta"
```
Esperado (após Task 7): segurando o tiro a mira sobe/espalha e recupera ao soltar.

- [ ] **Step 4: Commit**

```bash
git add src/client/WeaponClient/Recoil.luau src/client/WeaponClient/init.luau
git commit -m "feat(arma): recoil por mola + spray pattern"
```

---

### Task 7: Input — PC + Mobile + envio do tiro [R3][R8]

**Files:**
- Create: `src/client/WeaponClient/Input.luau`
- Modify: `src/client/WeaponClient/init.luau`

- [ ] **Step 1: Input — bind fire/reload/ADS; fire faz feedback local e envia direção**

```lua
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
		if now - lastLocalShot < cfg.fireRate then return end
		if localMag <= 0 then return end
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
	Input.setLocalMag = function(v) localMag = v end
	return Input
end

return Input
```

- [ ] **Step 2: Instanciar no init.luau**

Adicionar no `WeaponClient.start()`:
```lua
	local Input = require(script:WaitForChild("Input"))
	Input.start(WeaponConfig.Rifle, recoil)
	WeaponClient.input = Input
```

- [ ] **Step 3: Playtest (PC) — clicar dispara; ver munição cair no servidor**

Playtest, clicar/segurar. Confirmar no servidor que a munição decrementa:
```lua
-- via MCP, contexto servidor durante playtest
-- (inspeciona o estado; nome do player conforme o playtest)
return "clicar deve chamar FireRequest; validar munição no end-to-end (Task 8)"
```
Esperado: câmera dá recoil ao disparar. **Mobile:** no Studio, aba **Test → Device**, escolher um celular → aparece o botão de toque "Fire".

- [ ] **Step 4: Commit**

```bash
git add src/client/WeaponClient/Input.luau src/client/WeaponClient/init.luau
git commit -m "feat(arma): input PC + mobile + envio do tiro"
```

---

### Task 8: HUD — mira, munição autoritativa, hitmarker + end-to-end [R1][R2]

**Files:**
- Create: `src/client/WeaponClient/HUD.luau`
- Modify: `src/client/WeaponClient/init.luau`

- [ ] **Step 1: HUD — crosshair, contador de munição, hitmarker; escuta ShotFx**

```lua
-- src/client/WeaponClient/HUD.luau
-- Mira + munição (valor AUTORITATIVO do servidor [R2]) + hitmarker [R1].

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = require(game.ReplicatedStorage.Shared.WeaponRemotes)

local HUD = {}

function HUD.start(cfg, onAmmoFromServer)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WeaponHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- crosshair
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(4, 4)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = gui

	-- munição
	local ammo = Instance.new("TextLabel")
	ammo.AnchorPoint = Vector2.new(1, 1)
	ammo.Position = UDim2.new(1, -24, 1, -100)
	ammo.Size = UDim2.fromOffset(160, 40)
	ammo.BackgroundTransparency = 1
	ammo.Font = Enum.Font.GothamBold
	ammo.TextColor3 = Color3.fromRGB(240, 240, 245)
	ammo.TextXAlignment = Enum.TextXAlignment.Right
	ammo.TextSize = 28
	ammo.Text = tostring(cfg.ammo.magazine) .. " / " .. tostring(cfg.ammo.reserve)
	ammo.Parent = gui

	-- hitmarker
	local hm = Instance.new("TextLabel")
	hm.AnchorPoint = Vector2.new(0.5, 0.5)
	hm.Position = UDim2.fromScale(0.5, 0.5)
	hm.Size = UDim2.fromOffset(40, 40)
	hm.BackgroundTransparency = 1
	hm.Font = Enum.Font.GothamBold
	hm.Text = "✕"
	hm.TextSize = 24
	hm.TextColor3 = Color3.fromRGB(255, 80, 80)
	hm.TextTransparency = 1
	hm.Parent = gui

	local reserve = cfg.ammo.reserve
	Remotes.ShotFx.OnClientEvent:Connect(function(data)
		if not data or not data.selfShot then
			return
		end
		if data.ammo then
			reserve = data.reserve or reserve
			ammo.Text = tostring(data.ammo) .. " / " .. tostring(reserve)
			if onAmmoFromServer then
				onAmmoFromServer(data.ammo) -- reconcilia predição do Input [R2]
			end
		end
		if data.hit then
			hm.TextColor3 = data.headshot and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(255, 80, 80)
			hm.TextTransparency = 0
			TweenService:Create(hm, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		end
	end)

	return HUD
end

return HUD
```

- [ ] **Step 2: Ligar no init.luau (reconciliação munição Input↔HUD)**

Adicionar no `WeaponClient.start()`:
```lua
	local HUD = require(script:WaitForChild("HUD"))
	HUD.start(WeaponConfig.Rifle, function(serverAmmo)
		if Input.setLocalMag then Input.setLocalMag(serverAmmo) end
	end)
```

- [ ] **Step 3: Teste END-TO-END (playtest no place da favela)**

Verificar o ciclo completo, mirando no `TrainingDummy`:
- Atirar no corpo → vida do dummy cai, hitmarker vermelho, contador de munição desce.
- Atirar na cabeça → cai bem mais, hitmarker dourado.
- Esvaziar o pente → `R` recarrega (após ~2.2s a munição volta).
- Continuar atirando → mira sobe/espalha em padrão e recupera ao soltar.
- Matar o dummy → ele some e respawna em ~3s.
- Rodar `WeaponConfig.runChecks()` via MCP de novo → `true` (regressão da lógica de dano).

- [ ] **Step 4: Commit**

```bash
git add src/client/WeaponClient/HUD.luau src/client/WeaponClient/init.luau
git commit -m "feat(arma): HUD (mira/munição autoritativa/hitmarker) + fecha v1"
```

---

## Self-Review (feita pelo autor do plano)

**Cobertura do spec:**
- [x] Config data-driven → Task 1
- [x] Autoridade servidor (munição/cadência/dano, raycast exclui atirador [R11]) → Task 4
- [x] Remotes com branch [R5] → Task 2
- [x] Hitmarker + munição autoritativa via ShotFx [R1][R2] → Task 4 (envio) + Task 8 (uso)
- [x] Sem timestamp [R3] → Task 7
- [x] 1ª pessoa em código [R7] → Task 5
- [x] Viewmodel, recoil por mola, ADS*, HUD → Tasks 5,6,8 (*ADS: ver nota abaixo)
- [x] Input PC+mobile, BindAction 3º arg [R8] → Task 7
- [x] Dummy por clone de modelo pronto [R6] → Task 3
- [x] runChecks() por assert via MCP → Task 1
- [x] perStud [R10] → Task 1
- [x] Bookmarks (lag comp, seed spread) → no spec, fora do escopo v1

**Nota de escopo — ADS:** o design lista ADS (mirar). Pra manter as tasks bite-sized e a v1 focada em "atirar e machucar", o ADS (reduzir FOV + aproximar viewmodel no botão direito/toque) fica como **Task 9 opcional** (adição pequena: um BindAction extra + tween de FOV/offset do viewmodel). Não bloqueia o end-to-end. Decidir na execução se entra na v1 ou vira polish.

**Placeholders:** nenhum TODO/TBD; todo passo tem código real ou comando real.

**Consistência de tipos:** `ShotFx` payload usa `selfShot/hit/headshot/ammo/reserve` consistente entre Task 4 (envio) e Task 8 (consumo); `getSprayOffset`/`computeDamage` mesmas assinaturas em Task 1, 4 e 6; `Config.FavelaPlaceId`/`StartPlaceId` já existem em `src/shared/Config.luau`.
