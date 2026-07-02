# Pesquisa de Repositórios — Complexo: Breach

Pesquisa profunda no GitHub para auxiliar no desenvolvimento do Mapa 1 (Resgate de Refém).

> **Constatação crítica:** Não existe sistema de escort/hostage pronto para Roblox com qualidade production-ready. O sistema será construído do zero usando o `npc-engine` como base (FSM + Pathfinder).

> **Correção da pesquisa anterior:** O `beters02/Evostrike` tem um sistema de balas completo e próprio — Raycast + wallbang + spray patterns calibrados + bullet visual + partículas. Não precisa de FastCast2 + Hindsight separados. Evostrike é a base principal para o sistema de tiro.

---

## Sistema de Tiro (Prioridade 1)

### beters02/Evostrike ⭐ PRINCIPAL
**URL:** https://github.com/beters02/Evostrike
**Estrelas:** 8 | **Atualizado:** fev/2026

FPS tático completo inspirado em Counter-Strike e Source Engine. Tem sistema de balas **próprio e completo**, sem depender de libs externas:

**Sistema de balas:**
- Raycast para hit detection com `ShotResultData` completo (shooter, resultado, personagem atingido)
- Bullet visual animado com TweenService a 900 studs/seg
- **Wallbang** por material — LightMetal 70%, HeavyMetal 40%, LightWood 85%, HeavyWood 50%
- Bullet holes com partículas e weld no ambiente
- Damage falloff por distância, headshot multiplier, leg multiplier, helmet/destroyHelmet

**Armas incluídas:** AK47, AK103, Glock17, Desert Eagle, HK P30, MP5, Vityaz, Intervention (sniper), Faca, Bomba

**Config por arma (exemplo AK47):**
```lua
damage = {
    base = 40, min = 33,
    headMultiplier = 5,
    legMultiplier = 0.9,
    damageFalloffPerMeter = 0.7,
    damageFalloffDistance = 40,
    damageFalloffMinimumDamage = 20,
    destroysHelmet = true,
},
accuracy = { firstBullet = 2, base = 5, crouch = 4, walk = 200, run = 200, jump = 150 },
ammo = { magazine = 30, total = 90 },
fireRate = 0.1 -- 600 RPM
```

**Padrões de spray:** `spraypattern.lua` por arma — calibrado como CSGO

**FPSState:** lean esquerdo/direito (estilo Rainbow Six Siege), agachado, sprint

**WeaponController:** gerencia slots primary/secondary/ternary, input debounce, ViewModel com springs

**Uso no Breach:** base completa para o sistema de tiro. Adaptar armas e configs para o estilo favela.

---

### REALEncryptal/Hindsight (alternativa avançada)
**URL:** https://github.com/REALEncryptal/Hindsight
**Wally:** `realencryptal/hindsight@^0.2`
**Estrelas:** 1 | **Atualizado:** mai/2026

Server-authoritative com rollback e lag compensation via Actors. Mais complexo de integrar que o Evostrike.

**Uso no Breach:** alternativa se quiser lag compensation mais rigoroso. Secundário ao Evostrike.

---

### weenachuangkud/FastCast2
**URL:** https://github.com/weenachuangkud/FastCast2
**Wally:** `weenachuangkud/fastcast2@0.1.2`
**Estrelas:** 22 | **Atualizado:** jun/2026

**Uso no Breach:** ~~prioridade 1~~ → dispensável se usar Evostrike como base. O Evostrike já resolve o visual de balas com TweenService.

---

## NPC do Refém (Prioridade 2)

### ppeter2/npc-engine
**URL:** https://github.com/ppeter2/npc-engine
**Wally:** `ppeter2/npc-engine@0.1.0`
**Estrelas:** 0 | **Atualizado:** jun/2026

FSM (Finite State Machine), BehaviorTree, Pathfinder, Perception (visão/audição), AnimationController, GroupAI. Presets: `Ambient`, `Patrol`, `Guard`, `Merchant`, `Boss`.

**Uso no Breach:** base do NPC refém com estados `Idle → Following → Rescued`. A lógica "para quando o portador morre":
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

Character controller server-authoritative com rollback. Sistema de Bots com `BotThink` function customizável. `Hitpoints.lua` gerencia saúde.

**Uso no Breach:** character controller do NPC refém com anti-cheat de movimento nativo.

---

## Infraestrutura / Utilitários (Prioridade 3)

### Sleitnick/RbxUtil
**URL:** https://github.com/Sleitnick/RbxUtil
**Estrelas:** 421 | **Atualizado:** jul/2026

- `sleitnick/timer` — contagem regressiva dos rounds
- `sleitnick/spring` — recuo e sway da arma
- `sleitnick/shake` — camera shake ao disparar
- `sleitnick/trove` — cleanup de conexões entre rounds
- `sleitnick/signal` — eventos (`HostageRescued:Fire()`)

---

### Breezy1214/EZ-Hitbox
**URL:** https://github.com/Breezy1214/EZ-Hitbox
**Wally:** `breezy1214/hitbox@5.0.0`
**Estrelas:** 5 | **Atualizado:** abr/2026

Hitbox por área — Sphere, Box, fromPart. Velocity prediction, debugging.

**Uso no Breach:** zona de extração do refém (trigger quando time chega ao extraction point) e granadas.

---

### manas879rbx/Team-Based-Round-System
**URL:** https://github.com/manas879rbx/Team-Based-Round-System
**Estrelas:** 0 | **Atualizado:** jan/2026

Esqueleto de round system com times em Lua puro. Base para o `RoundService` do Breach.

---

## Prioridade de Integração (atualizada)

| Prioridade | Repo | Uso |
|---|---|---|
| 1 ⭐ | **beters02/Evostrike** | Sistema de tiro completo — balas, armas, wallbang, spray, lean |
| 2 | ppeter2/npc-engine | FSM + Pathfinder do NPC refém |
| 2 | easy-games/chickynoid | Character controller server-auth + bots |
| 3 | Sleitnick/RbxUtil | Spring, Timer, Signal, Shake |
| 3 | Breezy1214/EZ-Hitbox | Zona de extração / granadas |
| 4 | manas879rbx/Team-Based-Round-System | Esqueleto de rounds/times |
| 5 | REALEncryptal/Hindsight | Alternativa avançada de lag compensation |
| 5 | weenachuangkud/FastCast2 | Dispensável se usar Evostrike |
| 5 | 1axen/secure-cast | Referência arquivada de lag compensation |
