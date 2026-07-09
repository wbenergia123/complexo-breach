# Menu Principal — Plano de Construção

**Estilo alvo:** menu de FPS competitivo (referência: TTK, Evostrike, Blackout)
**Estética:** fundo quase-preto, detalhes vermelhos, fonte monoespaçada estilo terminal, textos em maiúsculo
**Status:** planejamento

---

## Onde o jogo está hoje

O Complexo: Breach está em fase inicial: **mapa da favela + scripts de organização/textura**
(~180 linhas de Lua, maioria aplicando textura). Pelo GDD, todo o gameplay ainda é `[ ]`:

- ❌ Sistema de armas / tiro
- ❌ Rounds, respawn, times
- ❌ Moedas / XP / progressão
- ❌ Matchmaking
- ❌ Economia (Robux / loja)

O menu do TTK é a vitrine de um FPS **completo**. Construir as 5 abas agora seria UI ligada no
vazio: LOJA sem itens, EQUIPAMENTO sem armas, VOTEKICK sem partida. Por isso o plano é **em
camadas** — cada aba nasce quando o sistema de jogo dela existir.

---

## Decisão de arquitetura

O menu deve ser **código no repo** (`src/client`), não instâncias montadas à mão no place.

| Motivo | Detalhe |
|---|---|
| Versionado | Fica no git, com histórico e revisão de PR |
| Seguro | Esposa/filho não apagam sem querer (não está no place editável) |
| Integrável | Liga nos sistemas de jogo conforme eles existirem |
| Padrão do mercado | Blackout/Evostrike fazem a UI toda em código |

> O menu montado via MCP no place (hoje) foi protótipo. A versão final é reescrita em `src/client`.

---

## Fases

### Fase 1 — Casca visual + JOGAR ✅ dá pra fazer já
- Estética TTK (paleta, fonte monoespaçada, barra de abas superior)
- Abas: JOGAR · EQUIPAMENTO · LOJA · CONFIGURAÇÕES · VOTEKICK
- **JOGAR** funcionando (teleporte pro mapa / entrar na partida)
- Abas sem sistema mostram **"🔒 Em breve"**
- **Depende de:** nada

### Fase 2 — CONFIGURAÇÕES 🟡 parcial já
- FOV, volume (Música / Combate / Morte) → funcionam standalone
- Sensibilidade, sensibilidade ADS, keybinds → precisam de câmera/controles do jogo
- **Depende de:** sistema de câmera/input (parcial existe)

### Fase 3 — EQUIPAMENTO 🔴 bloqueado
- Loadout por classe, seleção de arma primária/secundária, equipamento
- **Depende de:** sistema de armas (não existe)

### Fase 4 — LOJA 🔴 bloqueado
- Skins, passes, itens com Robux/GamePass
- **Depende de:** economia + catálogo de itens (não existe)

### Fase 5 — VOTEKICK 🔴 bloqueado
- Votação de kick durante a partida
- **Depende de:** sistema de partida/lista de jogadores (não existe)

---

## Ordem recomendada

1. **Fase 1 agora** — dá o "cara de TTK", é honesto, vira a fundação.
2. **Gameplay** (arma → rounds → moedas) é o que **destrava** as fases 3-5.
   Sem gameplay, menu bonito não faz jogo.
3. Fases 2-5 entram conforme o sistema de cada uma nasce.

---

## Paleta e tipografia (referência de estilo)

| Elemento | Valor |
|---|---|
| Fundo | quase-preto (`~15,15,17`) |
| Detalhe / destaque | vermelho (`~190,40,40`) |
| Texto primário | branco |
| Texto secundário | cinza (`~120,120,120`) |
| Fonte | monoespaçada (`Code` / `RobotoMono`), labels em MAIÚSCULO |
| Barras de acento | linha vermelha fina antes de cada seção |
