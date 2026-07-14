# Viewmodel FPS animado (braços + X9-72) — 1ª pessoa

**Data:** 2026-07-14
**Status:** design aprovado (aguardando review do spec)
**Contexto:** o viewmodel de 1ª pessoa hoje é procedural puro — `Viewmodel.luau` é um MeshPart
colado na câmera com lerp HIP↔ADS + recoil por mola, **sem animação**. A 3ª pessoa já está
animada (ver `PistolAnims.luau`, pipeline Blender→Roblox validado). Este design cobre o
viewmodel completo com braços+mãos autorado no Blender e tocado pelo Animator, com o procedural
por cima — o "jeito CS".

Ref. de princípios: CG Cookie, "How Great First-Person Animations are Made" (10 tips).

---

## 1. Objetivo

Substituir o viewmodel estático por um viewmodel riggado (braços+mãos reaproveitados do
traficante + X9-72) com 4 animações mínimas tocadas por `AnimationController`+`Animator`,
mantendo recoil e ADS como camadas procedurais. **Bônus:** a mesma cena Blender resolve a
calibração do `gripOffset` da arma na mão em 3ª pessoa (thread travado).

## 2. Escopo v1 (e o que fica pra fase 2)

**Filosofia:** nunca autoramos animação na mão além do mínimo. Reload "bonito" de 2.2s é o item
mais caro do projeto — v1 entrega o esqueleto funcional no jogo, polimento depois.

**Dentro do v1:**
- Rig de viewmodel: braços+mãos (do **Terrorista A**) + X9-72 presa à mão direita.
- 4 anims **mínimas** (§6): idle quase-estático, fire curto, reload-mímica, equip básico.
- Rewrite do `Viewmodel.luau` preservando o contrato público (§4).
- Export da matriz arma↔mão pra corrigir `CharacterConfig.WorldGun.gripOffset` (§8).

**Fase 2 (fora do v1, registrado):**
- Braço por skin (A e B têm braços diferentes) — v1 usa o braço do A pra todos.
- Reload com pente destacando de fato (exige separar geometria da malha) — v1 é mímica.
- Anims de inspect, ADS-idle dedicado, run/sprint pose.
- Dedos totalmente articulados (v1 = 1 osso por mão + polegar).

## 3. Arquitetura

### Blender — `viewmodel_x972.blend`, uma armature
- `root` — origem = ponto de fixação na câmera.
- `R_forearm → R_hand → R_thumb, R_fingers` (extraídos do Terrorista A).
- `L_forearm → L_hand → L_thumb, L_fingers`.
- `gun` — osso **rígido** (malha X9-72 weight 100%), **filho de `R_hand`** (arma parenteada à
  mão, tip #7 do vídeo). `L_hand` segue a `gun`/`R_hand` por constraint, keyframando a
  influência (tip #8).
- **Sem** sub-ossos de `magazine`/`charging_handle` no v1 (malha Meshy é sólida — risco #2).

### Roblox
- `ReplicatedStorage/ViewmodelX9-72` = skinned mesh importado + `AnimationController`+`Animator`.
- `src/shared/ViewmodelAnims.luau` = novo módulo (espelho do `PistolAnims.luau`) com os 4 IDs.
- `Viewmodel.luau` reescrito: carrega o modelo, cola na câmera todo `RenderStepped`, toca anims
  pelo Animator; recoil e ADS lerp continuam procedurais **por cima** do idle.

## 4. Contrato de interface pública do Viewmodel (CRÍTICO)

O rewrite **deve preservar** a interface consumida hoje, senão vira refactor em cadeia:

| Membro | Consumidor | Comportamento a manter |
|---|---|---|
| `.part` (MeshPart da arma) | `init.luau:26` → `Effects.new(viewmodel.part, …)` (lido **1x na construção**) | continua apontando pra MeshPart da X9-72 |
| `:setRecoil(cframe)` | `Recoil.luau:29` | soma offset de recoil sobre a pose atual |
| `:setAiming(bool)` | `Aim.luau:26` | alterna alvo do lerp HIP↔ADS |

**Novos métodos** (só adição, não quebram nada): `:playFire()`, `:playReload()`, `:playEquip()`,
e o idle tocando em loop automático ao criar. Chamados pelo `Input.luau` nos eventos que ele já
dispara. **Nenhuma mudança em Effects/Recoil/Aim/HUD** — é o teste de que o contrato foi mantido.

## 5. Mapa de ossos (contrato do rig)

```
root
├─ R_forearm → R_hand → { R_thumb, R_fingers, gun }
└─ L_forearm → L_hand → { L_thumb, L_fingers }
```
Dedos econômicos: 1 osso `*_fingers` (pose de grip fixa) + `*_thumb` separado só se precisar
reposicionar o polegar no reload.

## 6. As 4 anims v1 (mínimas, princípios do vídeo embutidos)

| Anim | Duração | O que é (v1 mínimo) | Regra do vídeo |
|---|---|---|---|
| **idle** | loop | quase-estático; o sway "vivo" já é procedural no código (delta de mouse/movimento) | não bloquear o corridor (#3), emoldurar mira (#4) |
| **fire** | ~0.1s | 2–3 keyframes de tranco; soma com o recoil spring existente | snappy, **começa no frame 2** in-game (#2) |
| **reload** | 2.2s (=`reloadTime`) | **mímica**: L_hand desce, "troca", volta — pente NÃO destaca (risco #2) | keyframar influência de constraint (#8) |
| **equip** | 0.6s (=`equipTime`) | arma sobe pro enquadramento | translação simples |

**Regra transversal:** zero rotação de câmera nas anims (#5) — só translação. FOV do ADS é
tratado no código, nunca na anim.

## 7. Muzzle (correção do design)

Attachment preso a MeshPart **não segue osso animado** (lição da saga skinned mesh). Como o
recoil é procedural no modelo inteiro e não se atira durante o reload, o muzzle fica **fixo na
`.part`, na posição do cano em idle** (aproximação boa o bastante pro v1). NÃO no osso `gun`.

## 8. Pipeline de export (reusa receita validada) + bônus grip 3ª pessoa

**Anims/modelo:** Blender → **GLB combinado COM textura, root/quadril zerado** → import no Studio
→ publicar cada action → preencher IDs no `ViewmodelAnims.luau`. Gotchas conhecidos: nada de IDs
achatados/sem material — republicar com material.

**Bônus (resolve o thread do gripOffset):** na cena Blender, com `gun` filho de `R_hand`, extrair
a **matriz da `gun` relativa à `R_hand`**, converter Blender→Roblox e pro espaço do bone
`mixamorig:RightHand`, e entregar como CFrame pra substituir `CharacterConfig.WorldGun.gripOffset`
([CharacterConfig.luau:33](../../../src/shared/CharacterConfig.luau)). Um trabalho, dois
problemas.

## 9. Mudanças no código (mínimas)

- `src/client/WeaponClient/Viewmodel.luau` — rewrite pra modelo+Animator, preservando §4.
- `src/shared/ViewmodelAnims.luau` — **novo**, 4 asset IDs.
- `src/client/WeaponClient/Input.luau` — chamar `viewmodel:playFire/playReload/playEquip` nos
  eventos que já dispara (sem lógica nova de estado).
- `src/shared/CharacterConfig.luau` — atualizar `WorldGun.gripOffset` com a matriz exportada (§8).
- Effects/Recoil/Aim/HUD — **inalterados** (prova do contrato §4).

## 10. FOV / knob de calibração

O viewmodel divide o FOV da câmera (70→55 no ADS, `WeaponConfig.Rifle`). Isso distorce a arma na
mira (alerta #5/#6 do vídeo). Mitigação: expor **escala e offset do viewmodel** como constantes no
topo do `Viewmodel.luau` (como os `HIP`/`ADS`/`SCALE` atuais) pra calibrar no olho — não dá pra
acertar de primeira, é tuning físico.

## 11. Testes / verificação

1 check que roda: playtest onde (a) o viewmodel carrega, (b) os 4 IDs do `ViewmodelAnims` resolvem
não-vazios, (c) o Animator toca fire/reload/equip sem erro no output. **Screenshot do viewport
antes de declarar bom** — enquadramento e grip mentem em número (regra da casa).

## 12. Riscos

1. **Extrair antebraço+mão do Terrorista A** — separar geometria e manter só os ossos
   forearm/hand/dedos. Parte fiddly do Blender.
2. **Malha X9-72 sólida (Meshy)** — sem pente separável. Tratado promovendo reload-mímica a plano
   principal do v1 (§6). Separar geometria = fase 2.
3. **FOV do ADS distorce o viewmodel** — mitigado pelo knob de escala/offset (§10).
4. **Blender caindo** (histórico) — a cena do viewmodel é também a fonte da matriz de grip (§8);
   salvar o .blend versionado pra não reperder a calibração.

## 13. Decisões registradas

- Skin: braços do **Terrorista A** pra todos no v1; por-skin é fase 2.
- Reload: **mímica** é o plano principal do v1, não fallback.
- Muzzle: **fixo na part**, não no osso.
- Anims **mínimas** (tranco/mímica), não autoradas a mão; polir depois de estar no jogo.
- Contrato público do Viewmodel (`.part`/`setRecoil`/`setAiming`) **preservado** — Effects/Recoil/
  Aim/HUD não mudam.
