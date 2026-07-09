# Sistema de Arma v1 — Design

**Data:** 2026-07-08
**Status:** aprovado (aguardando revisão do spec escrito)
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
  WeaponRemotes.luau → cria/expõe os RemoteEvents (FireRequest, Reload, ShotFx)

src/server/          (ServerScriptService.Server)  [gate: favela]
  WeaponServer.server.luau  → autoridade: valida cadência/munição/vivo, raycast, aplica dano
  DummyTarget.server.luau   → cria e respawna o boneco de treino

src/client/          (StarterPlayerScripts.Client)  [gate: favela]
  WeaponClient/
    init.luau        → orquestra input + tiro + feedback
    Viewmodel.luau   → arma placeholder presa na câmera (1ª pessoa)
    Recoil.luau      → recuo de câmera/viewmodel por mola + spray pattern
    Input.luau       → PC (mouse/R/dir) + Mobile (ContextActionService touch)
    HUD.luau         → mira, munição, hitmarker
```

Cada arquivo tem um propósito único e testável isoladamente. O gate no `init.client` cresce:
place do menu → menu (já existe); place da favela → WeaponClient. Idem no servidor.

## 2. Rede e autoridade do servidor

Fluxo do tiro:

1. **Cliente aperta atirar** → checa local (munição>0, cadência) só pra feedback → mostra na
   hora (flash, tracer, recuo, som) → envia `FireRequest{ direção, timestamp }` ao servidor.
2. **Servidor** valida (vivo? cadência? munição? direção plausível?) → decrementa munição →
   raycast da cabeça do personagem na direção recebida, até `range`, com spread por precisão →
   se acertar Humanoid: `dano = base × falloff(dist) × mult(cabeça/perna)` e aplica →
   replica "tiro do fulano" pros outros clientes (tracer/som).
3. **Cliente atirador** recebe confirmação → mostra hitmarker se acertou.

**Anti-cheat:** cliente só manda a direção que mirou; nunca dano/acerto. Munição, cadência e
dano vivem no servidor. Trapaça no máximo erra a própria mira.

**Remotes** (em ReplicatedStorage, criados por `WeaponRemotes`):
- `FireRequest` (RemoteEvent, cliente→servidor)
- `Reload` (RemoteEvent, cliente→servidor)
- `ShotFx` (RemoteEvent, servidor→clientes: replica efeitos de tiro dos outros)

## 3. Sensação no cliente (feel)

- **Câmera 1ª pessoa + viewmodel:** arma placeholder presa na câmera.
- **Recoil por mola (spring):** cada tiro dá um kick na câmera/viewmodel seguindo o spray
  pattern do config, e volta suave ao soltar (`recoilRecovery`). Procedural — sem animação
  (evita o problema de re-upload de animação).
- **ADS (mirar):** botão direito/toque → aproxima viewmodel, reduz FOV, atira "pelo olho"
  (preciso — lição do Xonotic).
- **HUD mínima:** crosshair, contador de munição, hitmarker.
- **Controles:**
  - PC: clique = atirar, `R` = recarregar, botão direito = ADS.
  - Mobile: botões de toque via `ContextActionService` (`CreateTouchButton`) pra atirar/recarregar/ADS.

## 4. Boneco de treino + testes

- **Dummy:** rig R15 com Humanoid num ponto fixo da favela. Toma dano (vida nativa do
  Humanoid), mostra a vida, respawna poucos segundos após morrer. Criado por
  `DummyTarget.server` (gate favela). Valida atirar → dano → headshot → morte → respawn.
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
    falloff = { startDist = 40, perMeter = 0.5, minDamage = 20 },
  },
  accuracy = {               -- spread (graus) por estado de movimento
    firstBullet = 0, standing = 1.5, crouch = 1.0, moving = 6, jumping = 12,
  },
  spray = { {0,0}, {0.1,1.4}, {0.3,1.1}, ... },  -- {lado, cima} por bala
  recoilRecovery = 0.3,      -- quão rápido o spray reseta ao soltar
  recoilSpring = { mass = 5, force = 50, damping = 4 }, -- kick procedural
}
```

## Unidades e dependências

| Unidade | Faz | Depende de |
|---|---|---|
| `WeaponConfig` | dados + auto-teste de dano | nada |
| `WeaponRemotes` | cria os RemoteEvents | nada |
| `WeaponServer` | valida, raycast, aplica dano | Config, Remotes |
| `DummyTarget` | boneco de treino | nada |
| `WeaponClient/init` | orquestra input/tiro/feedback | Config, Remotes, submódulos |
| `Viewmodel` | arma na câmera | nada |
| `Recoil` | kick + spray | Config |
| `Input` | PC + mobile | — |
| `HUD` | mira/munição/hitmarker | — |

## Fora de escopo (bookmarks pro futuro)

- **Times/rounds/objetivo (plantar-desarmar bomba):** referência de design em
  [solcloud/Counter-Strike](https://github.com/solcloud/Counter-Strike) (condições de vitória,
  bomba). Fase de rounds — ver `docs/menu-plan.md`.
- **Loja/loadout/múltiplas armas:** config já é data-driven; entra quando o menu (Fase 3-4)
  e a economia existirem.
