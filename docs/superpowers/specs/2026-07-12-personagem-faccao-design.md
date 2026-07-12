# Personagem da Facção (traficante jogável) — Design

Data: 2026-07-12. Aprovado em brainstorm com Willian.

## Objetivo

Quando um jogador do time **Criminosos** spawna no place da favela, o avatar dele vira o
**traficante** (skinned mesh `Terrorista_char`, 16 animações publicadas em
`src/shared/PistolAnims.luau`). Os outros jogadores veem o corpo animado em 3ª pessoa
(idle/walk/run/strafe/crouch/aim/tiro/reload/jump/death); o próprio jogador continua em
1ª pessoa com o viewmodel da X9-72 (sistema existente, intocado). Time BOPE mantém o
avatar padrão do Roblox até existir o personagem policial.

Escopo: **tudo de uma vez** (as 16 anims + mecânica de agachar + sprint + morte),
modular. Gated por `game.PlaceId == Config.FavelaPlaceId`.

## Decisões de mecânica (aprovadas)

- **Agachar:** segurar **Ctrl** (padrão CS) — corpo abaixa, anda mais devagar, hitbox
  encolhe, anims de crouch. Solta = levanta.
- **Sprint:** segurar **Shift** = run (mais rápido). Normal = walk. Mirando (ADS) = walk
  lento (sem sprint enquanto mira).
- **Morte:** toca a anim de morte (corpo cai colado no chão), congela ~3s, respawn.
- Velocidades data-driven em `CharacterConfig`: walk 10, run 18, aimWalk 6, crouch 6
  (ajustáveis depois por playtest).

## Arquitetura (validada por pesquisa — docs oficiais Avatar Evolution)

### 1. Corpo do jogador (receita oficial StarterCharacter skinned mesh)

Modelo `TraficanteRig` guardado em `ServerStorage` (montado uma vez a partir do
`Workspace.Terrorista_char`):

- `HumanoidRootPart` (caixa de colisão ~2×5×1.4, invisível, CanCollide **on**) — física
- `Humanoid` com `AutomaticScalingEnabled=false`, `HipHeight` manual,
  `BreakJointsOnDeath=false` (senão o corpo desmonta na morte), `RequiresNeck=false`
- Mesh skinned soldado (WeldConstraint) na HRP, `CanCollide=false`, **`CanQuery=false`**
  (tiros atravessam o mesh e acertam as hitboxes nomeadas)
- `Animator` dentro do Humanoid

**NÃO** usamos R15 invisível completo: as partes R15 não seguiriam as anims mixamo
(hitbox ficaria em T-pose eterna). Pesquisa: docs oficiais + padrão da comunidade.

O swap: `FactionCharacter.server` escuta `PlayerAdded`/`CharacterAdded`; se
`player.Team == Criminosos`, clona o rig, posiciona no spawn e seta
`player.Character = clone` (respawn manual via `LoadCharacter`-equivalente). BOPE passa
reto (avatar padrão).

### 2. Hitboxes por osso (dano por parte SEM mudar o WeaponServer)

5 partes invisíveis dentro do personagem, **nomeadas como R15** para o
`WeaponConfig.computeDamage` atual funcionar sem alteração:

| Parte | Osso seguido | Tamanho aprox |
|---|---|---|
| `Head` | mixamorig:Head | 0.9³ |
| `UpperTorso` | mixamorig:Spine1 | 1.5×1.5×0.9 |
| `LowerTorso` | mixamorig:Hips | 1.4×0.9×0.9 |
| `LeftUpperLeg` | mixamorig:LeftUpLeg | 0.7×1.6×0.7 |
| `RightUpperLeg` | mixamorig:RightUpLeg | 0.7×1.6×0.7 |

Propriedades: `CanCollide=false`, `CanQuery=true`, `Massless=true`, `Transparency=1`,
`Anchored=false` + soldadas? Não — **CFramadas por Heartbeat no servidor** ao
`Bone.TransformedWorldCFrame` (as anims tocadas pelo dono replicam ao servidor via
Animator, então os bones do servidor refletem a pose real — agachou, hitbox desce).
Custo: 8 jogadores × 5 partes = trivial. O raycast do WeaponServer já exclui o
personagem do atirador; nada muda lá.

### 3. State machine de animação (cliente do dono)

`CharacterAnimator` (módulo do cliente, iniciado pelo `init.client` no place favela)
anima **apenas o próprio personagem**; a replicação do Animator leva as tracks pros
outros clientes e pro servidor automaticamente (padrão Roblox).

Resolução de estado (função **pura**, testável por `runChecks()`):

```
resolveState(moveSpeed, moveDirLocal, aiming, crouching, sprinting, airborne) -> animKey
```

Prioridade: `airborne(jump)` > `crouch*` > `aim parado` > locomoção.
Direção: `moveDirLocal` (MoveDirection no espaço da câmera/HRP) decide
walk/walkBack/strafeLeft/strafeRight (limiar 45°). Sprint só vale andando pra frente e
sem mira. Loop `RenderStepped` barato: troca de track só quando o estado muda
(`Play(0.15)`/`Stop(0.2)` com fade).

Camadas (prioridade de track Roblox):
- **Movement:** idle/walk/run/strafe/crouch/jump (loop)
- **Action (upper-body):** aim (loop enquanto mira), shooting (one-shot por tiro),
  reload (one-shot) — versões **só torço/braços** (poses das pernas removidas da
  KeyframeSequence e republicadas como `aimUpper`/`shootUpper`/`reloadUpper`) para as
  pernas continuarem andando por baixo, estilo CS. Fallback aceitável: usar as
  full-body se as upper falharem (congela perna por ~0.5s no tiro/reload).

Gatilhos de combate: o `Input.luau` existente já sabe quando atira/mira/recarrega — ele
passa a notificar o `CharacterAnimator` local (callback), sem duplicar lógica.

### 4. Replicação de estado + autoridade

- **Anims:** replicam sozinhas (Animator do dono).
- **Velocidade (anti-cheat básico):** cliente envia `MovementState` (RemoteEvent:
  crouching/sprinting/aiming) → servidor valida e seta `Humanoid.WalkSpeed` (servidor é
  dono da velocidade; cliente não seta). Servidor também grava atributos
  (`Crouching`, `Aiming`) no personagem — úteis pra hitbox (crouch encolhe HRP? v1: HRP
  fixa; só a hitbox `Head` desce porque segue o osso) e futuros sistemas.
- **Morte:** `Humanoid.Died` no servidor → toca `death` no Animator do servidor
  (replica), ancora HRP, espera `RespawnDelay` (3s), respawna via swap de novo.
- **Jump:** estado do Humanoid (replica sozinho); anim disparada pelo dono.

### 5. Arquivos

| Arquivo | Papel |
|---|---|
| `src/shared/CharacterConfig.luau` | velocidades, tamanhos de hitbox, mapa osso→parte, respawn, `runChecks()` |
| `src/shared/CharacterRemotes.luau` | RemoteEvent `MovementState` (padrão do WeaponRemotes) |
| `src/shared/PistolAnims.luau` | (existe) IDs; ganha `aimUpper/shootUpper/reloadUpper` |
| `src/server/FactionCharacter.server.luau` | swap de avatar por time, hitboxes+follow, WalkSpeed autoritativo, morte/respawn |
| `src/client/CharacterAnimator/init.luau` | state machine + tracks + camadas |
| `src/client/CharacterAnimator/StateResolver.luau` | função pura `resolveState` + `runChecks` |
| `src/client/init.client.luau` | (modif.) inicia CharacterAnimator no favela |
| `src/client/WeaponClient/Input.luau` | (modif.) callbacks fire/aim/reload pro animator |

Rig: montado uma vez via MCP (`ServerStorage.TraficanteRig`) — fica no place, não no git
(igual X9-72); passos documentados no plano.

## Fluxo de dados (resumo)

```
Input (Ctrl/Shift/mouse) ─→ CharacterAnimator (anima local) ─Animator─→ todos veem
        └─→ MovementState remote ─→ servidor: valida → WalkSpeed + atributos
FireRequest/Reload (existentes) ─→ WeaponServer (dano igual hoje, acerta hitboxes nomeadas)
Humanoid.Died ─→ servidor: death anim + respawn
```

## Erros e casos-borda

- Jogador troca de time no meio: swap só no próximo respawn (v1).
- Rig sem algum osso (nome errado): `FactionCharacter` loga warn e pula a hitbox — não
  derruba o servidor.
- Anim asset falha ao carregar (propagação/moderação): track fica nil, state machine
  ignora aquele estado (personagem continua com as demais).
- Morto não processa MovementState (guard por `Humanoid:GetState() ~= Dead`).
- Primeira pessoa: o dono não deve ver o próprio corpo do traficante na cara —
  `LocalTransparencyModifier = 1` no mesh pro dono (padrão Roblox de 1ª pessoa).

## Teste

- `CharacterConfig.runChecks()` + `StateResolver.runChecks()` por assert (rodável via
  MCP `execute_luau`, padrão do projeto).
- Playtest 2 clientes (Studio "2 Players"): um Criminoso anda/agacha/mira/atira e o
  outro assiste — validação visual das camadas e da replicação.
- Teste de dano: atirar na cabeça do traficante agachado tem que aplicar headshot
  (hitbox seguiu o osso).

## Fora de escopo (v1)

- Personagem BOPE (avatar padrão por enquanto).
- Ragdoll na morte (anim resolve; ragdoll é upgrade futuro).
- HRP encolher no crouch (hitbox Head já desce; caixa de colisão fixa é aceitável).
- Arma visível na mão em 3ª pessoa (próximo projeto; grip das crouch será revisto lá).
- Footsteps/sons.
