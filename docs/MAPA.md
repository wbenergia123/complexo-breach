# Complexo: Breach — Layout do Mapa

## v5 — "Duas Cotas" (ATUAL)

Projeto aprovado (artefato "Projeto Duas Cotas"): o quadrante N/NE virou um **platô em L
na cota Y=20** (Rua do Morro + Rua Alta leste), construído por `tools/plato_v5.luau`.
**Ordem de build**: `build_map.luau` → `decorate_map.luau` → `plato_v5.luau`.

- **Platô**: lajes X175–395/Z310–390 + X335–395/Z88–310, com canais abertos para as
  escadas; muretas de meio-corpo (1,1) na borda com vãos = drops D1 (X200–220, p/ Viela
  do Arrimo) e D2 (Z150–170, p/ Rua de Trás); fachadas de arrimo coloridas na frente.
- **Transições**: escada_E1_beco (beco NW ↔ rua alta), escada_522 (viela ↔ Rua do Morro,
  rota principal da defesa), escada_rotaC (rua sul ↔ Rua Alta leste), escadão+mirante Y40
  (rua de trás → torre, truss de contra-flanco), pinguela + casa-torre (terraço Y20 com
  caixote = **entrada 3 da quadra** por cima da grade norte), drops D1/D2.
- **Re-cotas**: spawn Criminosos (290–318, Y20, 350–360), Mercado Silva (256, 360),
  sobrado_N1 (366, 190 — braço leste), sobrado_C1 (365, 250).
- **Fileira 3D da Rua do Morro**: as 4 casas do pack_meshy (morro_sul) foram clonadas,
  re-escaladas e enfileiradas de X270 a X391, fachadas para o sul na linha Z=346:
  casa da varanda (0.6×), casa azul 3 andares (0.5×), barracos brancos (0.6×, com a
  escadaria metálica própria do mesh) e casa grande verde/vermelha (0.5×). As
  casas-caixa geradas saíram da rua alta; trailer e jipe do pack seguem no cenário sul.
- **Métricas**: A ~19 s (baixada, inalterada); B ~23 s (canyon); C (rua alta, flanco
  profundo) ~45 s, com atalho via D2 ~34 s; **defesa → refém: 8,5 s via drop D1**,
  11,9 s via escada 522. Vantagem de defesa ~10 s ✓.
- **Balance de cota**: da borda/mureta não se vê o refém (linha passa por cima da grade
  de 21); muros N/E ficaram semi-enterrados no platô e viram parapeito de ~5 studs da
  rua alta (aproveitado de propósito).
- Passarelas v3 (passarela_oeste, laje_leste, escada_O1/N1, laje_alta) removidas;
  varanda do complexo + escada_B1 + pulo da grade mantidos (decisão do design).

---

# Histórico — v1

Construído por `tools/build_map.luau` (command bar do Studio). Idempotente: os assets
originais viram templates em `ServerStorage.MapAssets`; cada execução destrói e
reconstrói `workspace.Map` inteiro.

Sistema de coordenadas: chão em Y≈0 (`Chao_Favela`, topo em −0,2). Área jogável
≈ X −38…395, Z 5…360 (~400×400 com o miolo em ~330×320). Y informado = **centro do
bounding box** do model (o script posiciona por bbox, porque os pivôs dos assets são
deslocados).

## Descoberta importante — desnível da quadra

O "gramado em Y≈21.67" do briefing era leitura errada do bounding box: 21,67 é o **topo
do alambrado** (grade de 21 studs). O piso real da quadra (`quadra_tex2`) fica em
**Y≈0,4** — degrau de 0,6 stud para a rua, vencido pelo StepHeight padrão (2,2).
Nenhuma rampa foi necessária. O refém e a cadeira (que estavam em cima da grade)
desceram para o gramado.

## Tabela de posições (X, Y centro bbox, Z, rotação Y, pasta em workspace.Map)

| Instância | X | Y | Z | rY | Pasta |
|---|---|---|---|---|---|
| favela_roblox | 65 | 5.0 | 200 | 180° | Buildings |
| sobrado_A1 | 140 | 17.3 | 68 | 8° | Buildings |
| sobrado_A2 | 185 | 17.3 | 66 | −10° | Buildings |
| sobrado_A3 | 263 | 17.3 | 130 | 95° | Buildings |
| sobrado_A4 | 207 | 17.3 | 120 | −85° | Buildings |
| sobrado_B1 | 158 | 17.3 | 105 | 100° | Buildings |
| sobrado_C1 (laje defensiva) | 318 | 17.3 | 296 | 0° | Buildings |
| sobrado_N1 | 215 | 17.3 | 330 | 12° | Buildings |
| mercado_silva | 272 | 10.8 | 322 | 15° | Buildings |
| mercadinho | 262 | 10.8 | 58 | −75° | Buildings |
| casa_A1 | 110 | 10.6 | 130 | 20° | Buildings |
| casa_B1 | 158 | 10.5 | 268 | −15° | Buildings |
| muro_S0 / S1 / SE | 10 / 200 / 340 | 12.25 | −12 / −12 / −5 | 0/0/−15° | Boundaries |
| muro_E1 / E2 | 390 / 390 | 12.25 | 110 / 290 | 90° | Boundaries |
| muro_N1 / N15 / N2 | 280 / 160 / 40 | 12.25 | 390 / 395 / 390 | 0/8/0° | Boundaries |
| morro_sul (pack_meshy, cenário) | 150 | 29.8 | −90 | 90° | Boundaries |
| caveirao | 85 | 3.75 | 40 | 40° | Props |
| brasilia_A1 | 150 | 2.45 | 28 | 20° | Props |
| brasilia_B1 (pos. defensiva 3) | 226 | 2.45 | 146 | −30° | Props |
| brasilia_C1 | 332 | 2.45 | 355 | −35° | Props |
| brasilia_D1 | 95 | 2.45 | 170 | 75° | Props |
| poste_A1…A4 | 110/170/250/238 | 15.8 | 45/52/85/160 | 0/0/0/90° | Props |
| poste_B1 / B2 | 120 / 135 | 15.8 | 150 / 290 | 0° | Props |
| poste_N1 / E1 | 240 / 330 | 15.8 | 352 / 120 | 90° | Props |
| escadao_C (escada_002) | 348 | 19.8 | 240 | 90° (sobe p/ norte) | Routes |
| escada_B1 (escada_001) | 120 | 9.8 | 240 | −90° (sobe p/ oeste) | Routes |
| escada_E1 (escada_001) | 308 | 9.8 | 200 | 0° (sobe p/ norte) | Routes |
| laje_varanda (+2 colunas) | 95 | 20.5 | 240 | — topo Y21 | Routes |
| laje_alta (+2 colunas) | 348 | 34.5 | 316 | — topo Y35 | Routes |
| laje_pulo (+2 colunas) | 299 | 21.0 | 240 | — topo Y21,5 | Routes |
| truss_defensor (TrussPart escalável) | 364.5 | 17.2 | 318 | — | Routes |
| quadra | 236 | 10.65 | 240 | 0° (abertura p/ sul) | Objective |
| refem | 218 | 3.2 | 265 | 180° | Objective |
| cadeira | 215.5 | 1.85 | 265 | 160° | Objective |
| ExtractionZone (12×12) | 105 | 0.1 | 30 | — | Objective |
| invis_S/N/W/E (paredes invisíveis) | sobre as bordas reais | 60 | — | — | Boundaries |
| spawn_BOPE_1…4 | (70,30) (78,42) (92,28) (98,42) | 0.3 | — | — | Spawns |
| spawn_Criminosos_1…4 | (342,342) (350,352) (336,354) (356,338) | 0.3 | — | — | Spawns |

Times criados em `Teams`: **BOPE** (Really blue) e **Criminosos** (Bright red);
SpawnLocations com `Neutral=false`, `Duration=0`.

## Rotas e callouts

**Rota A — "Beco Principal"** (~303 studs ≈ 19 s): spawn no **Caveirão** → rua leste
margeando o **Muro dos Grafites** (muro_S1) com a **Brasília do Beco** (brasilia_A1)
de cobertura → curva no **Mercadinho** (marco do meio do mapa) → perna norte
("**Beco da Brasília**", gargalo entre sobrado_A4 e sobrado_A3, brasilia_B1 de
cobertura) → **Portão** (abertura sul da quadra, vão nativo de ~25 studs).

**Rota B — "Complexo"** (~364 studs ≈ 23 s): entrada sul do canyon interno do
favela_roblox (**Garagens**) → sobe o canyon quebrado por casa_A1/casa_B1 e a
brasilia_D1 → **Varanda** (laje_varanda Y21 via escada_B1 — posição defensiva 2
"Janela do Complexo", peek de ~90 studs na grade oeste da quadra) → **Viela Oeste**
(faixa entre o complexo e a quadra) → contorna para o Portão, ou segue à **Saída
Norte** → rua do **Mercado Silva** (conector B↔C). Interior dos prédios do pack é
mesh único (não jogável) — a rota "por dentro do complexo" usa a rua interna, lajes
e escadas do próprio pack.

**Rota C — "Escadão"** (~529 studs ≈ 33 s): rua sul até a **Rua de Trás** (corredor
leste, X≈330–360) → base do **Escadão** (escada_002) → sobe até a **Laje Alta**
(Y35) → **Laje do Sobrado** (sobrado_C1, posição defensiva 1) → tiro por cima da
grade norte/leste da quadra ou drop no chão. Defensores contra-flanqueiam pela
**Truss** atrás da Laje Alta (2 s do spawn deles — vantagem de defesa garantida).

**Entradas da quadra:** (1) Portão sul (escolta sai por aqui); (2) **Pulo da Grade** —
escada_E1 → laje_pulo (Y21,5) → salto por cima do alambrado leste (21) para dentro,
sem retorno; (3) drop das lajes C por cima da grade (só tiro/pressão, não escolta).

**Conectores de rotação:** spawn-plaza↔canyon (sul), **Beco do Gato** (vão
sobrado_B1/sobrado_A4, A↔B em Z≈100–170), curva do Mercadinho (A↔C) e rua do
Mercado Silva (B↔C, coberta pela posição defensiva 4 — esquina do mercado).

## Posições defensivas (todas com flanco)

1. **Laje do sobrado_C1** (Y35): domina quadra/leste — cega para a Rua de Trás sul e
   para quem sobe o Escadão colado na parede.
2. **Varanda do Complexo** (Y21): ângulo apertado na grade oeste — flanco pelo canyon
   sul e por baixo da laje.
3. **Brasília do Beco** (brasilia_B1): rasante na perna norte da A — fraca contra
   granada/rush e cega para o Beco do Gato às costas.
4. **Esquina do Mercado Silva**: cobre B↔C — cega para o drop da Laje Alta e para a
   viela norte do sobrado_N1.

## Métricas e checklist

Velocidade padrão 16 studs/s. Defensor → grade norte (refém à vista): 133 studs ≈
8,3 s. Vantagem de defesa sobre a Rota A: ~10 s. ✔ dentro da regra 8–10 s / 10–15 s.

- [x] 3 rotas + 2+ conectores desobstruídos
- [x] Defensores chegam ~10 s antes (8,3 s vs 19 s)
- [x] Sightlines: pernas da A ~90/136 studs; canyon B quebrado em segmentos ≤130 (casas, escada_B1, brasília)
- [x] Sem god-spot: toda laje tem flanco/ângulo cego e exposição na borda
- [x] Spawns protegidos por geometria (BOPE: muro sul + prédio do pack + caveirão; Crime: bolso NE)
- [x] Quadra com 2 entradas jogáveis + drop de pressão; desnível resolvido (piso Y0,4, degrau de 0,6)
- [x] Refém + cadeira no gramado, encostados na grade norte ao lado da trave
- [x] Bordas fechadas com muros/prédios reais + 4 paredes invisíveis por cima
- [x] Cobertura full-body a cada ~25–35 studs nas rotas (brasílias, quinas de sobrado, casas, postes)

## Segundo piso — circuitos de laje (v3)

Dois circuitos elevados de "sobe numa escada, desce em outra", estilo favela da referência:

- **Circuito Oeste (canyon)**: `escada_O1` (102, 85, perto do spawn BOPE) sobe →
  `passarela_oeste` (Y21, X≈95.5, Z 111–235, colada nas fachadas do complexo, com 2
  muretas de meia-cobertura e vãos de peek/drop) → `laje_varanda` (posição defensiva 2)
  → desce na `escada_B1` (120, 240) pro canyon perto da quadra. Drop-down da passarela
  pro canyon em qualquer vão da mureta (sem retorno).
- **Circuito Leste**: `escada_E1` (308, 200) sobe → `laje_pulo` (pulo por cima da grade
  leste da quadra) → `laje_leste` (Y21.5, Z 250–296, mureta contra o escadão) → desce na
  `escada_N1` (265, 297) pra viela norte da quadra (esquina do Mercado Silva). O telhado
  do `sobrado_C1` (rota do escadão) tem drop-down pra `laje_leste` — fecha o loop alto:
  escadão → laje alta → telhado → laje leste → viela.

Junções validadas por raycast: topo O1 Y19.8→passarela 21; topo E1 Y20→pulo 21.5;
topo N1 Y19.8→laje 21.5 (degraus ≤1.7, StepHeight 2.2 OK).

**Fixes de assets herdados de save antigo** (embutidos no build): cadeira/refém sem
escala (cadeira de 88 studs virava uma "rampa branca gigante" na quadra — `ScaleTo` no
template), e `quadra_Material_1737` é mesh quebrado do asset → `Transparency=1` +
`CanCollide=false` (colisão fica nas ColWalls).

## Ambientação (v2 — referência: vila brasileira estilizada do Fortnite)

Aplicada por `tools/decorate_map.luau` (rodar após o build). Reconstrói `workspace.Map.Deco`.

- **Iluminação**: sol de 13h, saturação/contraste up (ColorCorrection), Atmosphere leve,
  Bloom e SunRays sutis. Chão (`Chao_Favela`) em Pavement claro quente.
- **Corrimãos laranja** no escadão (3 trilhos + montantes), lajes coloridas
  (varanda amarela, laje alta terracota, pulo verde-água).
- **Assets do Creator Store** (grátis, baixados via `game:GetObjects`, templates em
  `ServerStorage.MapAssets.Deco`): árvores/arbustos do Yasu's Stylized Tree Pack
  (79689531752352), bush grande (14720410685), bananeira (84220908308255), varal synty
  (8938467357), tabela de basquete (829830744), rampa de skate (10676224985), pilha de
  pneus (9504148189), caixa d'água (11555132922, escala 0,33), prédio de apartamentos
  (15082419807, 3 clones recoloridos), casas de favela (17885393199 e 90347757761003).
- **Distribuição**: ~30 vegetações (perímetro atrás dos muros + poucas no playable, todas
  `CanCollide=false`), 4 pilhas de pneus como cover baixa nas rotas, rampa de skate na
  praça SE (cover jogável), tabela de basquete na grade leste da quadra, varais entre
  fachadas, skyline (prédios/casas/caixa d'água) atrás dos muros N/L/S.
- **Paredão de som** construído em Parts (5 caixas empilhadas + cones), meia-cobertura na
  esquina SW da abertura da quadra — callout "Paredão".

**v4 (fotos da referência):** morro de 17 casas empilhadas geradas por script (blocos
coloridos em socalcos com janela, mureta de terraço, telhadinho de telha e caixa d'água
azul) atrás dos muros N/L/S subindo como encosta; quadra repintada de **azul futsal com
3 círculos amarelos** (overlay sem colisão sobre o gramado); **arquibancada** de 3
degraus na viela oeste olhando a quadra; caixas d'água azuis em 9 telhados jogáveis;
toldos vermelho/amarelo no Mercado Silva e Mercadinho; prédios do skyline recoloridos
de branco (conjunto habitacional).

Nota: `InsertService:LoadAsset` e o insert do MCP falham para assets de terceiros
("not authorized"); `game:GetObjects("rbxassetid://ID")` em contexto de plugin/command
bar é o caminho que funciona.

## Baixada dos Becos (v7)

Labirinto **100% térreo** no miolo sul (decisão do design: sem casas geradas, sem laje
acessível — só as 4 casas 3D do pack). Spawn BOPE agora no caveirão em `(-26, 35)`
(spawns + extração juntos); jipe `(18, 36)` e trailer `(215, 32)` viram cover de rua.
Ilhas: casa_verde colada no B1/casa_A1 (oeste), **casa_azul = torre marco central**
colada no A2, barracos colados no mercadinho (leste), casa_varanda na ilha norte.
Becos resultantes de 8–10 studs (torre↔A4 8,6; varanda↔A4 10,1). Atalho pelos becos
~23,6 s vs defesa 8,5 s (folga ~15 s, teto da regra). Montado por `plato_v5.luau`
(seção Baixada dos Becos).

## Dust2 favelizado no miolo (v8)

Modelo low-poly do Dust2 (Sketchfab, ~9k tris) retrabalhado no Blender: janelas
eliminadas (504 fechadas + passe de faces órfãs), paredes retexturizadas com fotos
ortográficas 4K de 3 scans de muros grafitados (mural + 2 grafites), chão/topos em
concreto (atlas dessaturado). **Roblox = 1 textura por MeshPart**, então cada pedaço
foi separado POR MATERIAL no Blender → 32 peças de material único. **v3**
(`assets/dust2_favela_v3.fbx`): Solidify 0.06 em tudo — o Roblox corta backfaces e o
modelo tinha planos de face única (paredes "estilhaçadas" no play da v2); com espessura,
todas as faces existem dos dois lados (10k→44k tris, maior peça 4,6k).
(v1 multi-material importava branca; v2 single-material mas single-sided.)
Posicionado em `workspace.Map.dust2_favela`: escala ×0.0364 (import vem 55× maior),
ry 90°, centro (200, 118), footprint 182×153 no miolo, `PreciseConvexDecomposition`.
Pendente: tesourada manual das peças que não ficam + remoção dos sobrados antigos
que atravessam os corredores. Créditos Sketchfab (dust2 + scans) antes de publicar.

## Morro 3D de fundo (v6)

Quarteirão de favela gerado no Meshy ("Terraced Brick Village on the Hill", 941k tris),
otimizado no Blender pela receita de **fatiar em 6 chunks + decimação suave** (UV/textura
originais preservados — ver memória do projeto; bake e decimação única falharam).
Exportado em `assets/favela_bloco_3d.fbx` (6 MeshParts de 15,5k tris, textura 4096),
importado 1× via Asset Manager e guardado em `ServerStorage.MapAssets.Deco`.
O `decorate_map.luau` monta 11 clones em socalcos (norte 3+2+1 subindo, leste 2+1,
sul 2, `CanCollide=false`) substituindo as casinhas-caixa geradas (que ficaram como
fallback se o template não existir).

## Pendências / próximo passo

- **Playtest** de colisão real (fidelity dos meshes do pack é Default — conferir se
  alguma fachada "empurra" o player no canyon) e do pulo da grade (laje_pulo → quadra).
- Ambientação fina: decals/grafites já subidos, vegetação, entulho, iluminação.
- Base técnica Evostrike (fork/auditoria) é tarefa separada — ver seção 10 do briefing.
