# Viewmodel FPS Animado (braços + X9-72) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o viewmodel estático de 1ª pessoa por um viewmodel riggado (braços+mãos do Terrorista A + X9-72) com 4 anims mínimas tocadas pelo Animator, mantendo recoil e ADS procedurais — e de quebra corrigir o `gripOffset` da arma na mão em 3ª pessoa.

**Architecture:** Rig autorado no Blender (uma armature: braços deformáveis + osso `gun` rígido filho da `R_hand`), exportado como skinned mesh GLB, importado no Studio como `ViewmodelX9-72` (Model + AnimationController + Animator). O `Viewmodel.luau` carrega o modelo, cola na câmera todo RenderStepped via `PivotTo`, toca as anims pelo Animator e aplica recoil/ADS por cima. Contrato público (`.part`/`setRecoil`/`setAiming`) preservado → Effects/Recoil/Aim/HUD não mudam.

**Tech Stack:** Blender (blender-mcp / text-to-blender skill), Roblox Studio (robloxstudio MCP), Luau, Rojo.

**Spec:** [docs/superpowers/specs/2026-07-14-viewmodel-fps-anim-design.md](../specs/2026-07-14-viewmodel-fps-anim-design.md)

> **Verificação neste plano:** as tarefas de Blender/Studio são interativas — não há teste unitário; a verificação é **screenshot do viewport + playtest**, conforme a regra da casa ("screenshot antes de afirmar"). As tarefas de Luau têm check runnable onde dá (assert de IDs + playtest sem erro no output).

---

## File Structure

**Criar:**
- `assets/viewmodel_x972.blend` — cena Blender do rig (gitignored por `assets/*.blend`; salvar versionado à parte se quiser, ver Task 4).
- `src/shared/ViewmodelAnims.luau` — tabela dos 4 asset IDs + `assertReady()`.

**Modificar:**
- `src/client/WeaponClient/Viewmodel.luau` — rewrite completo (modelo+Animator).
- `src/client/WeaponClient/init.luau:28` — passar `viewmodel` pro `Input.start`.
- `src/client/WeaponClient/Input.luau:14,32,58` — assinatura + chamadas `viewmodel:playFire/playReload`.
- `src/shared/CharacterConfig.luau:33` — novo `gripOffset` da matriz exportada.

**Inalterados (prova do contrato §4 do spec):** `Effects.luau`, `Recoil.luau`, `Aim.luau`, `HUD.luau`.

---

## Fase 1 — Rig no Blender

### Task 1: Localizar e carregar os assets-fonte

**Files:** nenhum (setup Blender).

- [ ] **Step 1: Abrir o Blender e confirmar o MCP**

Garantir que o addon blender-mcp está rodando (porta 9876). Usar a skill `text-to-blender`/`blender-mcp` pra tudo abaixo.

- [ ] **Step 2: Localizar os fontes**

Fonte dos braços = rig do **Terrorista B** (Mixamo direto, ~65 ossos, dedos completos — **já carregado na cena** pelo usuário). Fonte da arma = mesh da X9-72 do Meshy (**já carregada na cena**).

- [ ] **Step 3: Screenshot de verificação**

`get_viewport_screenshot`. Esperado: personagem A e a X9-72 visíveis na cena. Se algum não abrir, resolver import antes de seguir.

---

### Task 2: Isolar antebraço+mão do Terrorista A

**Files:** cena Blender.

- [ ] **Step 1: Separar a geometria dos braços**

Em Edit Mode no mesh do Terrorista A, selecionar apenas os loops do **antebraço + mão + dedos** de ambos os lados (do cotovelo pra baixo) e separar (`P > Selection`) num objeto novo `vm_arms`. Deletar o resto do corpo.

- [ ] **Step 2: Enxugar a armature**

Manter só os ossos do braço: `mixamorig:RightForeArm, mixamorig:RightHand` + dedos (`mixamorig:RightHand*`), idem esquerdo, + `mixamorig:Hips` como root. Deletar o resto (spine/pernas/cabeça). **Manter os nomes `mixamorig:*`** (não renomear) — o rig B é Mixamo direto (65 ossos), já traz dedos, e os nomes casam com a 3ª pessoa e a matriz de grip (Task 11).

- [ ] **Step 3: Screenshot de verificação**

`get_viewport_screenshot`. Esperado: só os antebraços+mãos, sem corpo, com a armature enxuta. Weight paint dos braços deve ter vindo junto (herda do rig original).

---

### Task 3: Montar a arma no rig (arma parenteada à mão)

**Files:** cena Blender.

- [ ] **Step 1: Posicionar a X9-72 no grip**

Posar `R_hand`/`R_fingers` numa pose de grip fechando na coronha/punho da X9-72; mover a arma até assentar na mão. Usar `frame_0150` de [docs/reference/viewmodel-fps-frames/](../../reference/viewmodel-fps-frames/) como referência de enquadramento.

- [ ] **Step 2: Adicionar o osso `gun` e parentear**

Criar osso `gun` como **filho de `R_hand`** (tip #7 do vídeo). Weight da malha da arma = 100% no osso `gun` (rígida, sem deformar).

- [ ] **Step 3: L_hand segue a arma**

Posar `L_hand`/`L_fingers` no handguard. (v1: pose fixa; a constraint fica implícita na pose por action — sem constraint dinâmica pra simplificar.)

- [ ] **Step 4: Screenshot de verificação**

`get_viewport_screenshot` de frente e de lado. Esperado: duas mãos segurando a X9-72 num grip crível, cano pra frente.

---

### Task 4: Finalizar e salvar o .blend

**Files:** Create `assets/viewmodel_x972.blend`.

- [ ] **Step 1: Zerar o root**

`root` na origem, na orientação que vai virar o "frente = -Z da câmera" no Roblox. Aplicar transforms (rotation/scale) nos meshes.

- [ ] **Step 2: Salvar**

Salvar como `assets/viewmodel_x972.blend`. (Nota: `assets/*.blend` é gitignored — se quiser versionar, copiar pra `docs/reference/viewmodel_x972.blend` e commitar. Risco #4 do spec: não reperder a calibração se o Blender cair.)

- [ ] **Step 3: Screenshot final do rig**

`get_viewport_screenshot`. Esperado: rig limpo, pose de idle base pronta pra animar.

---

## Fase 2 — Animações (mínimas, uma Action cada)

> Regra transversal (todas): **só translação de câmera, zero rotação** (tip #5). Nunca autorar frame-a-frame além do mínimo.

### Task 5: Action `idle`

**Files:** cena Blender (Action `vm_idle`).

- [ ] **Step 1: Criar a Action**

Nova Action `vm_idle`, loop de ~2s. Quase-estático: 2 keyframes de respiração sutil (leve sobe/desce da arma, ~0.5cm). O sway "vivo" é procedural no código — não exagerar aqui.

- [ ] **Step 2: Screenshot/contact-sheet**

Renderizar 3-4 frames e conferir que a arma não bloqueia o centro da tela (corridor, tip #3) e a mira fica emoldurada (tip #4).

---

### Task 6: Action `fire`

**Files:** cena Blender (Action `vm_fire`).

- [ ] **Step 1: Criar a Action**

`vm_fire`, ~0.1s, **2-3 keyframes** de tranco: arma recua+sobe rápido e volta. Cortar a anim pra o impacto cair já no **frame 2** (tip #2) — sem anticipation.

- [ ] **Step 2: Screenshot**

Conferir o pico do tranco. Vai somar com o recoil spring do código, então manter discreto.

---

### Task 7: Action `reload` (mímica)

**Files:** cena Blender (Action `vm_reload`).

- [ ] **Step 1: Criar a Action**

`vm_reload`, **2.2s** (= `WeaponConfig.reloadTime`). **Mímica** (spec §6): `L_hand` desce até a base do pente, "troca", sobe de volta e dá um tapinha. O pente **não** destaca (malha sólida — risco #2). Poucos keyframes de bloco, sem detalhe.

- [ ] **Step 2: Screenshot**

Conferir que os 2.2s fecham voltando à pose de idle (senão a transição pro idle dá tranco).

---

### Task 8: Action `equip`

**Files:** cena Blender (Action `vm_equip`).

- [ ] **Step 1: Criar a Action**

`vm_equip`, **0.6s** (= `WeaponConfig.equipTime`). Arma sobe de fora do quadro (baixo) até a pose de idle. Termina exatamente na pose de idle.

- [ ] **Step 2: Screenshot**

Conferir início fora do quadro e fim casando com idle.

---

## Fase 3 — Export, publish e grip

### Task 9: Exportar e montar o `ViewmodelX9-72` no Studio

**Files:** Studio (`ReplicatedStorage/ViewmodelX9-72`).

- [ ] **Step 1: Exportar GLB**

Exportar o rig como **GLB combinado COM textura, root zerado** (receita validada, spec §8). Usar a skill `blender-export`.

- [ ] **Step 2: Importar no Studio**

Import do GLB → vira skinned mesh. Colocar em `ReplicatedStorage`, renomear o Model pra `ViewmodelX9-72`.

- [ ] **Step 3: Montar o contrato do Model (pro Luau achar tudo)**

- Adicionar `AnimationController` + `Animator` dentro do Model.
- Se a arma for parte separável: renomear a MeshPart da arma pra `Gun`. Se for skinned mesh único: definir o `PrimaryPart` = a MeshPart do viewmodel (o Luau usa `PrimaryPart` como fallback pra `.part`).
- Definir `PrimaryPart` do Model (pivô estável pro `PivotTo`).

- [ ] **Step 4: Screenshot de verificação**

`capture_screenshot` do explorer + viewport. Esperado: Model `ViewmodelX9-72` com `AnimationController>Animator`, parte `Gun` (ou PrimaryPart setado).

---

### Task 10: Publicar as 4 animações

**Files:** Studio.

- [ ] **Step 1: Publicar cada Action**

Importar cada Action (idle/fire/reload/equip) no rig via Animation Editor e publicar. **Gotcha (spec §8):** nada de IDs achatados/sem material — se vier sem textura, republicar. Anotar os 4 asset IDs.

- [ ] **Step 2: Verificação**

Tocar cada anim no Animation Editor sobre o rig. Esperado: as 4 rodam sem deformação quebrada.

---

### Task 11: Extrair a matriz de grip pra 3ª pessoa

**Files:** Modify `src/shared/CharacterConfig.luau:33`.

- [ ] **Step 1: Extrair a matriz gun↔R_hand no Blender**

Com a pose de idle, rodar no Blender (via `execute_blender_code`):

```python
import bpy
arm = bpy.data.objects['vm_arms']  # objeto da armature
rhand = arm.pose.bones['mixamorig:RightHand']
gun = arm.pose.bones['gun']
# matriz da arma relativa a mao (ambas em pose space da armature)
rel = rhand.matrix.inverted() @ gun.matrix
print(rel)  # 4x4; usar translacao + eixos pra montar o CFrame
```

- [ ] **Step 2: Converter Blender→Roblox e montar o CFrame**

Blender é Z-up / -Y forward; Roblox é Y-up / -Z forward. Mapear a translação `(x, y, z)_blender → (x, z, -y)_roblox` (studs), e montar `CFrame.fromMatrix(pos, right, up)` relativo ao bone `mixamorig:RightHand`. Substituir a linha 33:

```lua
-- gripOffset relativo ao Bone mixamorig:RightHand (extraido do viewmodel_x972.blend).
	gripOffset = CFrame.fromMatrix(Vector3.new(<x>, <y>, <z>), Vector3.new(<rx>,<ry>,<rz>), Vector3.new(<ux>,<uy>,<uz>)),
```

- [ ] **Step 3: Verificação em 3ª pessoa**

Playtest em `DEBUG_THIRD_PERSON = true` ([init.luau:19](../../../src/client/WeaponClient/init.luau#L19)). `capture_screenshot`. Esperado: arma assentada na mão do traficante sem flutuar/atravessar. Ajustar os números e repetir (é o thread que estava travado).

- [ ] **Step 4: Commit**

```bash
git add src/shared/CharacterConfig.luau
git commit -m "fix(personagem): gripOffset da arma na mao calibrado pela cena do viewmodel"
```

---

## Fase 4 — Código Roblox

### Task 12: Módulo `ViewmodelAnims`

**Files:** Create `src/shared/ViewmodelAnims.luau`.

- [ ] **Step 1: Criar o módulo com os IDs publicados**

```lua
-- src/shared/ViewmodelAnims.luau
-- Asset IDs das anims do viewmodel de 1a pessoa (X9-72). Espelho de PistolAnims (3a pessoa).
-- Rig = bracos do Terrorista A + arma. Preencher com os IDs da Task 10.

local ViewmodelAnims = {
	idle = "",   -- loop quase-estatico (sway "vivo" e procedural no codigo)
	fire = "",   -- tranco curto (2-3 keyframes), impacto no frame 2
	reload = "", -- mimica da troca de pente (~2.2s)
	equip = "",  -- sacar a arma (~0.6s)
}

-- auto-teste: falha alto e claro se algum ID ficou vazio ao usar em runtime.
function ViewmodelAnims.assertReady()
	for name, id in pairs(ViewmodelAnims) do
		if type(id) == "string" then
			assert(id ~= "", "ViewmodelAnims." .. name .. " sem asset ID (publicar a anim na Task 10)")
		end
	end
end

return ViewmodelAnims
```

- [ ] **Step 2: Preencher os 4 IDs**

Colar os asset IDs da Task 10 nos 4 campos.

- [ ] **Step 3: Verificação (runnable)**

No Studio, rodar via `execute_luau`:
```lua
require(game.ReplicatedStorage.Shared.ViewmodelAnims).assertReady()
print("ok")
```
Esperado: imprime `ok` sem erro. Se algum ID vazio, o assert aponta qual.

- [ ] **Step 4: Commit**

```bash
git add src/shared/ViewmodelAnims.luau
git commit -m "feat(viewmodel): modulo ViewmodelAnims com os 4 asset IDs"
```

---

### Task 13: Rewrite do `Viewmodel.luau`

**Files:** Modify `src/client/WeaponClient/Viewmodel.luau` (rewrite completo).

- [ ] **Step 1: Substituir o arquivo inteiro**

```lua
-- src/client/WeaponClient/Viewmodel.luau
-- Viewmodel X9-72 riggado (bracos+maos + arma) colado na camera em 1a pessoa.
-- Anims pelo Animator (idle/fire/reload/equip); recoil + ADS lerp procedurais por cima.
-- Contrato publico preservado: .part (MeshPart da arma), :setRecoil(), :setAiming().

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ViewmodelAnims = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ViewmodelAnims"))

local Viewmodel = {}
Viewmodel.__index = Viewmodel

-- === knobs de calibracao (ADS/FOV mentem no olho — ajustar aqui) ===
local HIP = CFrame.new(0.2, -0.4, -1.0)             -- offset do viewmodel vs camera (hip)
local ADS = CFrame.new(0, -0.2, -0.7)               -- offset na mira
local BASE_ROT = CFrame.Angles(0, math.rad(90), 0)  -- orienta o rig pra -Z da camera
local MUZZLE_POS = Vector3.new(0, 0.05, -1.2)        -- ponta do cano em idle (calibrar)

local function loadTrack(animator, id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	return animator:LoadAnimation(anim)
end

function Viewmodel.new()
	ViewmodelAnims.assertReady() -- falha alto se faltou publicar alguma anim

	local self = setmetatable({}, Viewmodel)

	local template = ReplicatedStorage:WaitForChild("ViewmodelX9-72")
	local model = template:Clone()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true       -- posicao vem do PivotTo; bones animam por cima
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = false
		end
	end
	model.Parent = Workspace
	self.model = model

	-- parte da arma exposta pro Effects (muzzle/tracer) — contrato .part
	self.part = model:FindFirstChild("Gun", true) or model.PrimaryPart

	-- muzzle FIXO na part, posicao do cano em idle (attachment nao segue osso) [spec 7]
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "MuzzlePoint"
	muzzle.Position = MUZZLE_POS
	muzzle.Parent = self.part

	-- animator + tracks
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	self.tracks = {
		idle = loadTrack(animator, ViewmodelAnims.idle),
		fire = loadTrack(animator, ViewmodelAnims.fire),
		reload = loadTrack(animator, ViewmodelAnims.reload),
		equip = loadTrack(animator, ViewmodelAnims.equip),
	}
	self.tracks.idle.Looped = true
	self.tracks.idle:Play()
	self.tracks.equip:Play(0.05) -- saca a arma ao criar/spawnar

	self.recoilOffset = CFrame.new()
	self.aiming = false
	self.aimAlpha = 0

	self.conn = RunService.RenderStepped:Connect(function(dt)
		local target = self.aiming and 1 or 0
		self.aimAlpha += (target - self.aimAlpha) * math.clamp(dt * 12, 0, 1)
		local offset = HIP:Lerp(ADS, self.aimAlpha)
		local cam = Workspace.CurrentCamera
		model:PivotTo(cam.CFrame * self.recoilOffset * offset * BASE_ROT)
	end)
	return self
end

function Viewmodel:playFire()
	local t = self.tracks.fire
	t.TimePosition = 0
	t:Play(0.02)
end

function Viewmodel:playReload()
	self.tracks.reload:Play(0.05)
end

function Viewmodel:playEquip()
	self.tracks.equip:Play(0.05)
end

function Viewmodel:setRecoil(recoilCFrame)
	self.recoilOffset = recoilCFrame
end

function Viewmodel:setAiming(aiming)
	self.aiming = aiming
end

function Viewmodel:destroy()
	if self.conn then
		self.conn:Disconnect()
	end
	for _, t in pairs(self.tracks or {}) do
		t:Stop()
	end
	if self.model then
		self.model:Destroy()
	end
end

return Viewmodel
```

- [ ] **Step 2: Verificação de contrato (estático)**

Confirmar que `.part`, `:setRecoil`, `:setAiming`, `:destroy` continuam existindo com as mesmas assinaturas (Effects/Recoil/Aim/HUD não mudam). Grep:
```bash
grep -nE ':setRecoil|:setAiming|\.part|:destroy' src/client/WeaponClient/Viewmodel.luau
```
Esperado: os 4 membros presentes.

- [ ] **Step 3: Commit**

```bash
git add src/client/WeaponClient/Viewmodel.luau
git commit -m "feat(viewmodel): rewrite pra modelo riggado + Animator (contrato preservado)"
```

---

### Task 14: Fiar as anims no Input

**Files:** Modify `src/client/WeaponClient/init.luau:28`, `src/client/WeaponClient/Input.luau`.

- [ ] **Step 1: Passar o viewmodel pro Input (init.luau)**

Trocar a linha 28:
```lua
	Input.start(WeaponConfig.Rifle, recoil, effects, aim, viewmodel)
```

- [ ] **Step 2: Assinatura do Input.start (Input.luau:14)**

```lua
function Input.start(cfg, recoil, effects, aim, viewmodel)
```

- [ ] **Step 3: Tiro em 1ª pessoa (Input.luau, dentro de tryFire, ao lado do onShot)**

Depois de `CharacterAnimator.onShot()`:
```lua
		CharacterAnimator.onShot() -- tranco do tiro em 3ª pessoa
		viewmodel:playFire()       -- tranco do tiro em 1ª pessoa
```

- [ ] **Step 4: Reload em 1ª pessoa (Input.luau, na action Reload, ao lado do onReload)**

Depois de `CharacterAnimator.onReload()`:
```lua
			CharacterAnimator.onReload() -- recarga em 3ª pessoa
			viewmodel:playReload()       -- recarga em 1ª pessoa
```

- [ ] **Step 5: Verificação (estática)**

```bash
grep -nE 'viewmodel:play(Fire|Reload)' src/client/WeaponClient/Input.luau
```
Esperado: 2 chamadas (fire + reload). Equip já é tocado no `Viewmodel.new()`.

- [ ] **Step 6: Commit**

```bash
git add src/client/WeaponClient/init.luau src/client/WeaponClient/Input.luau
git commit -m "feat(viewmodel): fiar playFire/playReload no Input (espelho da 3a pessoa)"
```

---

### Task 15: Playtest de verificação (gate final)

**Files:** nenhum (verificação).

- [ ] **Step 1: Sync Rojo + playtest**

Rojo sync, `start_playtest`. Deixar `DEBUG_THIRD_PERSON = false` pra travar 1ª pessoa.

- [ ] **Step 2: Exercitar os 4 estados**

Spawnar (equip toca), ficar parado (idle loopando), atirar segurando (fire + recoil somando), apertar R (reload mímica ~2.2s), mirar (ADS lerp sem entortar a arma).

- [ ] **Step 3: Ler o output**

`get_playtest_output`. Esperado: **sem erros** de Animator/anim id/nil. Se `assertReady` falhar, faltou ID (Task 12). Se `PivotTo`/`.part` reclamar de nil, o Model não tem `Gun`/`PrimaryPart` (Task 9 Step 3).

- [ ] **Step 4: Screenshot antes de aprovar (regra da casa)**

`capture_screenshot` em idle, no meio do fire e em ADS. **Só declarar pronto depois de olhar** — enquadramento e grip mentem em número. Ajustar os knobs `HIP`/`ADS`/`MUZZLE_POS` no topo do Viewmodel.luau e repetir.

- [ ] **Step 5: Commit final / finalizar branch**

```bash
git add -A && git commit -m "chore(viewmodel): calibracao final dos knobs (HIP/ADS/muzzle)"
```
Depois: skill `superpowers:finishing-a-development-branch` pra decidir merge/PR.

---

## Self-Review (cobertura do spec)

- §1 Objetivo → Tasks 1-15. ✓
- §2 Escopo v1 (anims mínimas, skin A, mão única) → Tasks 5-8 (mínimas), Task 2 (skin A). ✓
- §3 Arquitetura (Blender rig + Roblox model+Animator) → Tasks 1-4, 9, 13. ✓
- §4 Contrato público → Task 13 Step 2 (verificação) + Task 14. ✓
- §5 Mapa de ossos → Task 2 Step 2. ✓
- §6 4 anims mínimas → Tasks 5-8. ✓
- §7 Muzzle fixo na part → Task 13 (MUZZLE_POS na `.part`). ✓
- §8 Export + grip bônus → Tasks 9, 11. ✓
- §9 Mudanças de código → Tasks 12-14. ✓
- §10 FOV/knob → Task 13 (HIP/ADS/MUZZLE_POS no topo) + Task 15 Step 4. ✓
- §11 Testes → Task 12 Step 3, Task 15. ✓
- §12 Riscos → Task 2 (risco 1), Task 7 (risco 2/mímica), Task 15 (risco 3/FOV), Task 4 Step 2 (risco 4/blend versionado). ✓
- §13 Decisões → refletidas nas tasks. ✓
