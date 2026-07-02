# Complexo: Breach — Game Design Document

**FPS Tático · Roblox · 4v4 · Objective-based · Em desenvolvimento**

> Police vs Faction, real objectives, Brazilian identity.

---

## Sobre o jogo

**Complexo: Breach** é um FPS tático 4v4 no Roblox inspirado em CS e Rainbow Six Siege, com temática brasileira. Dois times com objetivos assimétricos disputam rounds de 5 minutos com respawn rápido, mantendo a tensão tática sem o tempo morto de jogos sem respawn.

O diferencial é a identidade: mapas e temáticas baseadas na realidade brasileira — favela, porto, aeroporto — com mecânicas de objetivo que nenhum FPS do Roblox explorou com essa profundidade.

---

## Core loop

| Mecânica | Detalhe |
|---|---|
| **4v4 assimétrico** | Policiais vs Facção com objetivos diferentes por time |
| **Rounds de 5 min** | Tensão real sem punição longa de espera |
| **Respawn rápido** | Morreu, voltou em segundos — retenção alta |
| **Moedas + XP** | Progressão por kills, objetivo e MVP do round |

---

## Mapas planejados

### Mapa 1 — Complexo: Resgate de Refém
> Favela com becos e lajes.

Policiais escoltam NPC até ponto de extração. Refém para no lugar se o portador morrer.

### Mapa 2 — Porto: Captura de Território
> Galpão de contêineres com 3 pontos disputados simultaneamente.

### Mapa 3 — Aeroporto: Extração de Carga
> Pista aberta.

Quem carrega a mochila fica mais lento e vira alvo.

### Mapa 4 — Laboratório: Pique Bandeira
> Interior fechado.

Spawn dinâmico cria frentes de batalha móveis.

---

## Sistema de recompensas

| Ação | Moedas |
|---|---|
| Eliminação | +10 |
| Assistência | +5 |
| Objetivo (escolta, captura, extração) | +25 |
| Headshot bônus | +5 |
| Killstreak 3x | +15 |
| Vencer o round | +50 |
| MVP do round | +30 |

---

## Referências técnicas

Ver [pesquisa-repositorios.md](pesquisa-repositorios.md) para análise completa de libs e repos open source.

## Stack técnica

| Ferramenta | Uso |
|---|---|
| Roblox Studio | Engine e mapa |
| Lua | Scripts de gameplay, NPC, rounds |
| Blender + MCP | Modelagem 3D dos assets |
| Future Lighting | Iluminação realista no Roblox |

---

## Status

- [x] Game design document (GDD) definido
- [x] Nome do jogo definido — Complexo: Breach
- [ ] Mapa 1 (Complexo) em desenvolvimento
- [ ] Sistema de NPC do refém
- [ ] Sistema de rounds e moedas
- [ ] Mapas 2, 3 e 4
