# Sistema de Arma v1 — Design

**Data:** 2026-07-08
**Status:** aprovado + revisão técnica incorporada (pronto pro plano)
**Contexto:** primeiro tijolo de gameplay do Complexo: Breach. Roda no place da **favela**, não no menu.

---

## Objetivo

Uma fatia jogável de combate: equipar uma arma, mirar em primeira pessoa, atirar (hitscan),
causar dano com autoridade no servidor, recarregar, contra um boneco de treino. Base
data-driven pra crescer pra várias armas depois.

## Requisitos (decididos no brainstorm)

| # | Decisão |
|---|---|
| Escopo | 1 arma funcionando (equipar, atirar, dano, vida, recarregar) |
| Câmera | **Primeira pessoa completa** com viewmodel (arma placeholder) |
| Hit | **Hitscan** (raycast), sem projétil |
| Autoridade | **Servidor** dono de munição, cadência e dano (anti-cheat) |
| Plataforma | **PC + Mobile** |
| Alvo de teste | Boneco (dummy) que toma dano e respawna |
| Fora de escopo | Times, rounds, loja, loadout, múltiplas armas (config já prepara) |
| Onde roda | Só no place da **favela** (gate por PlaceId) |

## Licença / origem do código

Código **próprio (clean-room)**. Inspirado nos *padrões e ideias* de Evostrike e Xonotic
(config data-driven, spray pattern, precisão por movimento, tiro no servidor, `shots` por
disparo, ADS pelo olho) — **sem copiar código** (ambos são GPL). MIT-livre pra publicar/monetizar.

---

## 1. Arquitetura e onde o código vive

Tudo gated pro place da favela (`game.PlaceId == Config.FavelaPlaceId`), igual o menu é gated
pro place inicial.

```
src/shared/          (ReplicatedStorage.Shared)
  WeaponConfig.luau  → dados da arma + função runChecks() de auto-teste
  WeaponRemotes.luau → cria/expõe os RemoteEvents (ver nota de replicação abaixo)

src/server/          (ServerScriptService.Server)  [gate: favela]
  WeaponServer.server.luau  → autoridade: valida cadência/munição/vivo, raycast, aplica dano
  DummyTarget.server.luau   → clona/respawna o boneco de treino (modelo pronto, não rig por código)

src/client/          (StarterPlayerScripts.Client)  [gate: favela]
  WeaponClient/
    init.luau        → orquestra input + tiro + feedback; trava 1ª pessoa (ver nota câmera)
    Viewmodel.luau   → arma placeholder presa na câmera (1ª pessoa)
    Recoil.luau      → recuo de câmera/viewmodel por mola + spray pattern
    Input.luau       → PC (mouse/R/dir) + Mobile (ContextActionService touch)
    HUD.luau         → mira, munição (valor autoritativo), hitmarker
```

Cada arquivo tem um propósito único e testável isoladamente. O gate no `init.client` cresce:
place do menu → menu (já existe); place da favela → WeaponClient. Idem no servidor.

**[R5] Nota de replicação do WeaponRemotes.** Só o **servidor** pode criar RemoteEvents
(instância criada pelo cliente não replica). O módulo tem que ramificar:
`if RunService:IsServer() then Instance.new("RemoteEvent") ... else remote = folder:WaitForChild(name)`.
Indexação direta no cliente quebra se ele carregar antes do servidor criar os remotes.

**[R7] Nota de câmera 1ª pessoa.** NÃO vai no `default.project.json` (é compartilhado entre os
places e travaria a `LobbyCamera` cinematográfica do menu). Fica **em código**, dentro do gate
da favela: `LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson` no `WeaponClient/init`.

## 2. Rede e autoridade do servidor

Fluxo do tiro:

1. **Cliente aperta atirar** → checa local (munição>0, cadência) só pra feedback → mostra na
   hora (flash, tracer, recuo, som) → envia `FireRequest{ direção }` ao servidor.
   **[R3]** Sem timestamp — relógio do cliente é falsificável e sem uso sem lag compensation.
2. **Servidor** valida (vivo? cadência pelo relógio do servidor? munição? direção plausível?) →
   decrementa munição → raycast da cabeça do personagem na direção recebida, até `range`, com
   spread por precisão → se acertar Humanoid: `dano = base × falloff(dist) × mult(cabeça/perna)`
   e aplica → responde ao atirador e replica pros outros (ver remotes).
3. **Cliente atirador** recebe a resposta → **[R1]** hitmarker se `hit`, **[R2]** e atualiza o
   HUD com a **munição autoritativa** devolvida pelo servidor.

**Anti-cheat:** cliente só manda a direção que mirou; nunca dano/acerto/munição. Munição,
cadência e dano vivem no servidor.

**Remotes** (em ReplicatedStorage, criados por `WeaponRemotes` — ver [R5]):
- `FireRequest` (RemoteEvent, cliente→servidor): `{ direção }`
- `Reload` (RemoteEvent, cliente→servidor)
- `ShotFx` (RemoteEvent, servidor→clientes): **duplo uso** —
  - pros **outros** clientes: replica o tiro do fulano (tracer/som deles);
  - **[R1]** pro **atirador**: `FireClient(atirador, { hit, headshot, ammo })` — confirma
    acerto (hitmarker) e devolve a munição autoritativa. Sem 4º remote.

**[R2] Munição no HUD.** Fonte da verdade = servidor. O cliente pode **prever** o decremento
pra HUD instantânea, mas **reconcilia** com o `ammo` devolvido em cada tiro/reload. O HUD
nunca confia só no contador local (divergiria em lag/reload cancelado).

**[R4] Limitação conhecida (v1):** o cliente mostra o tracer na hora com a direção que mirou; o
servidor rola o próprio spread. Às vezes o tracer "acerta" e o servidor diz que errou (sem
hitmarker). Aceitável contra dummy parado. Bookmark: eliminar com **seed de spread compartilhado**
(cliente e servidor sorteiam o mesmo spread) quando houver PvP.

## 3. Sensação no cliente (feel)

- **Câmera 1ª pessoa + viewmodel:** trava 1ª pessoa em código no gate da favela ([R7]); arma
  placeholder presa na câmera.
- **Recoil por mola (spring):** cada tiro dá um kick na câmera/viewmodel seguindo o spray
  pattern do config, e volta suave ao soltar (`recoilRecovery`). Procedural — sem animação
  (evita o problema de re-upload de animação).
- **ADS (mirar):** botão direito/toque → aproxima viewmodel, reduz FOV, atira "pelo olho"
  (preciso — lição do Xonotic).
- **HUD mínima:** crosshair, contador de munição (valor autoritativo [R2]), hitmarker.
- **Controles:**
  - PC: clique = atirar, `R` = recarregar, botão direito = ADS.
  - Mobile: **[R8]** botões de toque via `ContextActionService:BindAction(nome, fn, true, ...)`
    — o 3º argumento (`createTouchButton = true`) cria o botão na tela. (Não existe
    `CreateTouchButton`.)

## 4. Boneco de treino + testes

- **[R6] Dummy:** **não** montar rig R15 por código (frágil; junta errada quebra o headshot na
  parte "Head"). Ter um **modelo pronto** e o `DummyTarget.server` só **clonar no spawn/respawn**
  (~20 linhas). **v1: modelo mora no `ServerStorage` do place da favela** (opção mais simples,
  consistente com o mapa que já vive no place, não no git). Alternativa futura: `.rbxm`
  versionado no repo + mapeado no `project.json`.
- O dummy toma dano (vida nativa do Humanoid), mostra a vida, respawna poucos segundos após
  morrer. Valida atirar → dano → headshot → morte → respawn.
- **Auto-teste (sem framework):** `WeaponConfig.runChecks()` valida por `assert`:
  - headshot > corpo > perna
  - falloff reduz dano com distância, respeitando o dano mínimo
  - índice do spray pattern clampa na última bala (não estoura)
  - Rodável via MCP `execute_luau` sem entrar no jogo.
- **End-to-end (manual):** atirar no boneco na favela e observar vida/morte/respawn.

---

## Schema do WeaponConfig (data-driven)

Informado por Evostrike + Xonotic. Balancear = mexer só nesses números; adicionar arma = novo config.

```lua
{
  name = "placeholder_rifle",
  automatic = true,          -- segura o gatilho vs clique por tiro
  fireRate = 0.1,            -- segundos entre tiros (0.1 = 600 rpm)
  shots = 1,                 -- pellets por disparo (>1 = shotgun no futuro)
  ammo = { magazine = 30, reserve = 90 },
  reloadTime = 2.2,
  equipTime = 0.6,
  range = 500,               -- alcance máx do raycast (studs)
  damage = {
    base = 36,
    headMult = 4.0,
    legMult = 0.8,
    -- [R10] tudo em studs (Roblox não tem "metro")
    falloff = { startDist = 40, perStud = 0.5, minDamage = 20 },
  },
  accuracy = {               -- spread (graus) por estado de movimento
    firstBullet = 0, standing = 1.5, crouch = 1.0, moving = 6, jumping = 12,
  },
  spray = { {0,0}, {0.1,1.4}, {0.3,1.1}, --[[...]] },  -- {lado, cima} por bala (exemplo)
  recoilRecovery = 0.3,      -- quão rápido o spray reseta ao soltar
  recoilSpring = { mass = 5, force = 50, damping = 4 }, -- kick procedural
}
```

## Unidades e dependências

| Unidade | Faz | Depende de |
|---|---|---|
| `WeaponConfig` | dados + auto-teste de dano | nada |
| `WeaponRemotes` | cria/expõe os RemoteEvents (ramifica server/client [R5]) | RunService |
| `WeaponServer` | valida, raycast (exclui o atirador), aplica dano | Config, Remotes |
| `DummyTarget` | clona/respawna o boneco (modelo do ServerStorage) | — |
| `WeaponClient/init` | orquestra input/tiro/feedback; trava 1ª pessoa | Config, Remotes, submódulos |
| `Viewmodel` | arma na câmera | nada |
| `Recoil` | kick + spray | Config |
| `Input` | PC + mobile | — |
| `HUD` | mira/munição/hitmarker | — |

## Notas de implementação

- **[R11]** O raycast do servidor exclui o character do atirador via
  `RaycastParams.FilterDescendantsInstances` (senão o jogador atira no próprio braço).

## Fora de escopo (bookmarks pro futuro)

- **[R9] Lag compensation:** hitscan validado no servidor erra alvo em movimento proporcional ao
  ping. Irrelevante contra dummy parado; é o primeiro problema no PvP real.
- **[R4] Seed de spread compartilhado:** elimina o mismatch tracer/acerto quando houver PvP.
- **Times/rounds/objetivo (plantar-desarmar bomba):** referência de design em
  [solcloud/Counter-Strike](https://github.com/solcloud/Counter-Strike) (condições de vitória,
  bomba). Fase de rounds — ver `docs/menu-plan.md`.
- **Loja/loadout/múltiplas armas:** config já é data-driven; entra quando o menu (Fase 3-4)
  e a economia existirem.
