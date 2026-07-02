# Pesquisa de Repositórios — Complexo: Breach

Pesquisa profunda no GitHub para auxiliar no desenvolvimento do Mapa 1 (Resgate de Refém).

> **Constatação crítica:** Não existe sistema de escort/hostage pronto para Roblox com qualidade production-ready. O sistema será construído do zero usando o `npc-engine` como base (FSM + Pathfinder).

---

## Sistema de Balas

### REALEncryptal/Hindsight
**URL:** https://github.com/REALEncryptal/Hindsight
**Wally:** `realencryptal/hindsight@^0.2`
**Estrelas:** 1 | **Atualizado:** mai/2026

O mais avançado. Simulação de projéteis server-authoritative com rollback, hitscan com lag compensation, penetração de parede, ricochete e paralelismo via Actors. API limpa, documentação completa, Luau estrito.

**Uso no Breach:** sistema principal de balas com validação server-side.

---

### weenachuangkud/FastCast2
**URL:** https://github.com/weenachuangkud/FastCast2
**Wally:** `weenachuangkud/fastcast2@0.1.2`
**Estrelas:** 22 | **Atualizado:** jun/2026

Continuação do FastCast original. Simula milhares de projéteis sem física replicada. Suporta Parallel Luau, Raycast + Blockcast + Spherecast.

**Uso no Breach:** balas visuais no cliente. Combinado com Hindsight: FastCast2 para visual, Hindsight para validação server-side.

---

### 1axen/secure-cast ⚠️ Arquivado
**URL:** https://github.com/1axen/secure-cast
**Estrelas:** 31 | **Atualizado:** mai/2026

Server-authoritative com lag compensation, Multi-threading, bullet drop, granadas, ricochetes, penetração de parede. Arquivado por falta de tempo do autor — código completo e MIT.

**Uso no Breach:** referência de arquitetura para lag compensation.

---

## NPC do Refém

### ppeter2/npc-engine
**URL:** https://github.com/ppeter2/npc-engine
**Wally:** `ppeter2/npc-engine@0.1.0`
**Estrelas:** 0 | **Atualizado:** jun/2026

FSM (Finite State Machine), BehaviorTree, Pathfinder, Perception (visão/audição), AnimationController, GroupAI. Presets: `Ambient`, `Patrol`, `Guard`, `Merchant`, `Boss`.

**Uso no Breach:** base do NPC refém com estados `Idle → Following → Rescued`. A lógica "para quando o portador morre" é uma conexão sobre o FSM:
```lua
Humanoid.Died:Connect(function()
    npc:setState("Idle")
end)
```

---

### easy-games/chickynoid
**URL:** https://github.com/easy-games/chickynoid
**Wally:** `easy-games/chickynoid@0.1.4`
**Estrelas:** 266 | **Atualizado:** jun/2026

Character controller server-authoritative com rollback e lag compensation. Sistema de Bots com `BotThink` function customizável — exatamente o padrão para o NPC refém. `Hitpoints.lua` gerencia saúde de NPCs.

**Uso no Breach:** character controller do NPC refém com anti-cheat de movimento nativo.

---

## Referência de FPS Completo

### cataclysmic-studios/Blackout ⚠️ Arquivado
**URL:** https://github.com/cataclysmic-studios/Blackout
**Estrelas:** 3 | **Atualizado:** nov/2025

FPS completo em roblox-ts. Tem:
- `view-model.ts` — ViewModel com mouse sway e breathing animation
- `recoil.ts` — sistema de recuo com spring
- `FPSState` — lean esquerdo/direito (estilo Rainbow Six Siege), agachado, deitado, sprint
- `WeaponData` — dano por distância, RPM, muzzle velocity, multiplicadores por parte do corpo (head 2x, torso 1.5x)

**Uso no Breach:** referência de arquitetura. Lean (`LeanState: -1 | 0 | 1`) é diferencial tático.

---

### JonathanKwak/gun-system
**URL:** https://github.com/JonathanKwak/gun-system
**Estrelas:** 0 | **Atualizado:** jun/2025

Gun system em Lua puro (sem TypeScript). Hitscan + projétil via FastCast, validação server-side com verificação de linha de visão, compatível com mobile, R6 e R15.

**Uso no Breach:** ponto de partida se não quiser usar TypeScript. Mais simples de integrar.

---

## Sistema de Rounds e Times

### manas879rbx/Team-Based-Round-System
**URL:** https://github.com/manas879rbx/Team-Based-Round-System
**Estrelas:** 0 | **Atualizado:** jan/2026

Esqueleto de round system com times em Lua puro. Simples — sem polish, mas serve de base para o `RoundService` do Breach.

**Uso no Breach:** adicionar lógica de "round termina quando refém é resgatado OU todos os atacantes morrem".

---

## Infraestrutura / Utilitários

### Sleitnick/RbxUtil
**URL:** https://github.com/Sleitnick/RbxUtil
**Estrelas:** 421 | **Atualizado:** jul/2026

Coleção de utilitários de alto padrão. Pacotes relevantes:
- `sleitnick/timer` — base do sistema de rounds (contagem regressiva)
- `sleitnick/spring` — animações de recuo e sway da arma
- `sleitnick/shake` — camera shake ao disparar
- `sleitnick/trove` — cleanup de conexões (evita memory leak entre rounds)
- `sleitnick/signal` — eventos customizados (`HostageRescued:Fire()`)

---

### Breezy1214/EZ-Hitbox
**URL:** https://github.com/Breezy1214/EZ-Hitbox
**Wally:** `breezy1214/hitbox@5.0.0`
**Estrelas:** 5 | **Atualizado:** abr/2026

Hitbox flexível para áreas de efeito — Sphere, Box, fromPart. Hit point detection, velocity prediction, debugging tools.

**Uso no Breach:** zona de extração do refém (trigger de área quando o time chega ao extraction point) e granadas.

---

## Prioridade de Integração

| Prioridade | Repo | Uso |
|---|---|---|
| 1 | REALEncryptal/Hindsight | Balas server-side com lag compensation |
| 1 | weenachuangkud/FastCast2 | Visual de projéteis no cliente |
| 2 | ppeter2/npc-engine | FSM + Pathfinder do NPC refém |
| 2 | easy-games/chickynoid | Character controller server-auth + bots |
| 3 | cataclysmic-studios/Blackout | Referência de ViewModel, WeaponData, lean |
| 3 | Sleitnick/RbxUtil | Spring, Timer, Signal, Shake |
| 4 | JonathanKwak/gun-system | Gun system em Lua puro (alternativa simples) |
| 4 | Breezy1214/EZ-Hitbox | Zona de extração / objetivos por área |
| 5 | 1axen/secure-cast | Referência de lag compensation (arquivado) |
| 5 | manas879rbx/Team-Based-Round-System | Esqueleto de rounds/times |
