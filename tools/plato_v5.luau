-- plato_v5.luau — Complexo: Breach, "Duas Cotas" (projeto v5 aprovado)
-- ORDEM DE BUILD: 1) build_map.luau  2) decorate_map.luau  3) este script.
-- Ele remove as passarelas v3, ergue o platô em L (Y0..20) com canais de escada,
-- escadarias, escadão+mirante Y40, casa-torre+pinguela, re-cota spawn criminoso /
-- Mercado Silva / sobrados, cria os quarteirões da rua alta e corrige os decos.

local map = workspace.Map
local routes = map.Routes
local assets = game:GetService("ServerStorage").MapAssets

-- ---------- remoções (v3) ----------
local remover = { "passarela_oeste", "laje_leste", "escada_N1", "escada_O1", "laje_alta", "truss_defensor", "escadao_C" }
for _, c in ipairs(routes:GetChildren()) do
	for _, r in ipairs(remover) do
		if c.Name == r or c.Name:match("^" .. r .. "_") or c.Name:match("^corrimao") then c:Destroy() break end
	end
end

-- ---------- platô ----------
local old = map:FindFirstChild("Plato"); if old then old:Destroy() end
local plato = Instance.new("Folder"); plato.Name = "Plato"; plato.Parent = map

local PAV = Color3.fromRGB(181, 173, 157)
local CINZA = Color3.fromRGB(160, 158, 150)
local ARR = {
	{ Color3.fromRGB(232, 185, 35), Enum.Material.Concrete },
	{ Color3.fromRGB(168, 202, 58), Enum.Material.Concrete },
	{ Color3.fromRGB(198, 105, 55), Enum.Material.Brick },
	{ Color3.fromRGB(215, 130, 150), Enum.Material.Concrete },
	{ Color3.fromRGB(120, 180, 190), Enum.Material.Concrete },
}
local function part(name, x0, z0, x1, z1, y0, y1, color, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Anchored = true
	p.Color = color or PAV
	p.Material = mat or Enum.Material.Concrete
	p.Parent = plato
	return p
end

-- lajes (canais abertos: E1 = X175..235/Z310..330, E2 = X243..267/Z310..348)
part("plato_A", 175, 330, 235, 390, 0, 20)
part("plato_B", 235, 310, 243, 390, 0, 20)
part("plato_C", 243, 348, 267, 390, 0, 20)
part("plato_D", 267, 310, 395, 390, 0, 20)
part("plato_G", 335, 88, 395, 310, 0, 20)
-- muretas de borda (vãos: D1 X200..220, E2, pinguela X282..288, D2 Z150..170)
part("mureta_N1", 175, 309.6, 200, 310.4, 20, 21.1, CINZA)
part("mureta_N2", 220, 309.6, 243, 310.4, 20, 21.1, CINZA)
part("mureta_N3", 267, 309.6, 282, 310.4, 20, 21.1, CINZA)
part("mureta_N4", 288, 309.6, 335, 310.4, 20, 21.1, CINZA)
part("mureta_E1", 334.6, 90, 335.4, 150, 20, 21.1, CINZA)
part("mureta_E2", 334.6, 170, 335.4, 310, 20, 21.1, CINZA)
part("mureta_W", 174.6, 330, 175.4, 390, 20, 21.1, CINZA)
part("mureta_S", 335, 87.6, 395, 88.4, 20, 21.1, CINZA)
-- fachadas de arrimo
part("arrimo_1", 177, 302, 209, 310, 0, 20, ARR[1][1], ARR[1][2])
part("arrimo_2", 211, 302, 241, 310, 0, 20, ARR[2][1], ARR[2][2])
part("arrimo_3", 269, 302, 301, 310, 0, 20, ARR[4][1], ARR[4][2])
part("arrimo_4", 303, 302, 335, 310, 0, 20, ARR[5][1], ARR[5][2])
part("arrimo_5", 327, 92, 335, 148, 0, 20, ARR[3][1], ARR[3][2])
part("arrimo_6", 327, 172, 335, 184, 0, 20, ARR[1][1], ARR[1][2])
part("arrimo_7", 362, 82, 394, 88, 0, 20, ARR[2][1], ARR[2][2])

-- ---------- escadarias ----------
local function place(templateName, cloneName, cf)
	local clone = assets[templateName]:Clone()
	clone.Name = cloneName
	local b = clone:GetBoundingBox()
	clone:PivotTo(cf * (b:Inverse() * clone:GetPivot()))
	clone.Parent = routes
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d:IsA("MeshPart") then d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end
		end
	end
end
local function P(x, y, z, ry) return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(ry or 0), 0) end
place("escada_001", "escada_E1_beco", P(205, 9.8, 318, 90)) -- beco NW: sobe p/ leste
place("escada_001", "escada_522", P(255, 9.8, 318, 0)) -- viela -> rua do morro
place("escada_001", "escada_rotaC", P(348, 9.8, 58, 0)) -- rua sul -> rua alta leste
place("escada_002", "escadao_mirante", P(320, 19.8, 250.5, 90)) -- rua de trás -> Y40

-- mirante
part("mirante_torre", 315, 314, 339, 338, 0, 40, ARR[3][1], Enum.Material.Brick)
part("mirante_laje", 312, 311, 342, 341, 40, 41.2, Color3.fromRGB(224, 106, 21))
part("mirante_mureta_S", 312, 310.6, 342, 311.4, 41.2, 42.3, CINZA)
local truss = Instance.new("TrussPart")
truss.Name = "mirante_truss"
truss.Size = Vector3.new(2, 20, 2)
truss.CFrame = CFrame.new(343.5, 30, 326)
truss.Anchored = true
truss.Parent = plato

-- casa-torre + pinguela (entrada 3 da quadra: terraço -> caixote -> pula a grade norte)
part("torre_corpo", 268, 274, 290, 296, 0, 20, Color3.fromRGB(141, 134, 116))
part("torre_mureta_S", 268, 273.6, 290, 274.4, 20, 21.1, CINZA)
part("torre_mureta_W", 267.6, 274, 268.4, 296, 20, 21.1, CINZA)
part("torre_mureta_E", 289.6, 274, 290.4, 296, 20, 21.1, CINZA)
part("torre_mureta_N1", 268, 295.6, 276, 296.4, 20, 21.1, CINZA)
part("torre_mureta_N2", 288, 295.6, 290, 296.4, 20, 21.1, CINZA)
part("torre_caixote", 276, 274.8, 279.5, 278.2, 20, 22.3, Color3.fromRGB(150, 110, 60), Enum.Material.WoodPlanks)
part("pinguela", 282, 296, 288, 310, 20, 21, ARR[5][1])
part("pinguela_rail1", 281.7, 296, 282.3, 310, 21, 22, CINZA)
part("pinguela_rail2", 287.7, 296, 288.3, 310, 21, 22, CINZA)

-- corrimãos do escadão
for i, x in ipairs({ 312, 320, 328 }) do
	local p1 = Vector3.new(x, 23.2, 190)
	local p2 = Vector3.new(x, 56.2, 312)
	local r = Instance.new("Part")
	r.Name = "corrimao_" .. i
	r.Size = Vector3.new(0.5, 0.5, (p2 - p1).Magnitude)
	r.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
	r.Anchored = true; r.Material = Enum.Material.SmoothPlastic
	r.Color = Color3.fromRGB(255, 120, 30); r.Parent = routes
	for t = 0, 1, 0.14 do
		local pos = p1:Lerp(p2, t)
		local post = Instance.new("Part")
		post.Name = "corrimao_" .. i .. "_poste"
		post.Size = Vector3.new(0.4, 3, 0.4)
		post.CFrame = CFrame.new(pos.X, pos.Y - 1.5, pos.Z)
		post.Anchored = true; post.Material = Enum.Material.SmoothPlastic
		post.Color = Color3.fromRGB(255, 120, 30); post.Parent = routes
	end
end

-- ---------- re-cotas ----------
local function moveBBox(model, cf)
	local b = model:GetBoundingBox()
	model:PivotTo(cf * (b:Inverse() * model:GetPivot()))
end
moveBBox(map.Buildings.sobrado_C1, P(365, 37.3, 250, -90))
moveBBox(map.Buildings.sobrado_N1, P(366, 37.3, 190, -90)) -- braço leste: quebra sightline da Rua Alta
moveBBox(map.Buildings.mercado_silva, P(256, 30.8, 360, 0)) -- reto, alinhado com a fileira
local novas = { { 290, 352 }, { 300, 358 }, { 310, 350 }, { 318, 360 } }
local i = 0
for _, s in ipairs(map.Spawns:GetChildren()) do
	if s.Name:match("^spawn_Criminosos") then
		i += 1
		s.CFrame = CFrame.new(novas[i][1], 20.5, novas[i][2])
	end
end

-- ---------- fileira de casas 3D na Rua do Morro ----------
-- Aproveita os meshes do pack_meshy (morro_sul): fachadas para o sul, frente na linha Z=346,
-- lado a lado a partir de X=270 (leste do Mercado Silva).
-- morro_sul foi desagrupado (cada casa é um Model "sul_*" em Boundaries);
-- a busca recursiva pelo nome do mesh funciona nos dois formatos
local ms = map.Boundaries
local fila = {
	-- {mesh no pack, novo nome, escala, largura frente, profundidade, giro de compensação}
	-- (a geometria desses meshes vem torta de fábrica; o giro endireita o telhado no esquadro)
	{ "Meshy_Weathered Two-Story House_Mesh_0", "ruaalta_casa_varanda", 0.6, 36, 25.9, -39 },
	{ "Meshy_Meshy_Model_Mesh_0.004", "ruaalta_casa_azul", 0.5, 14.1, 11.1, 0 },
	{ "Meshy_Dilapidated Industrial Facade_Mesh_0.008", "ruaalta_barracos", 0.6, 36, 27.6, -30 },
	{ "Meshy_Meshy_Model_Mesh_0.006", "ruaalta_casa_grande", 0.5, 30, 22.8, -25 },
}
-- coladas sem fresta: 1 stud de interpenetração; fachadas exatas na linha Z=346
local xCursor = 270
local SOBRE = 1
for _, f in ipairs(fila) do
	local mesh = ms:FindFirstChild(f[1], true)
	if mesh then
		local wrap = Instance.new("Model")
		wrap.Name = f[2]
		mesh:Clone().Parent = wrap
		wrap.Parent = plato
		wrap:ScaleTo(f[3])
		-- orienta (fachada p/ sul + compensação da torção do mesh) e mede extensão em eixos de mundo
		local bcf, bs = wrap:GetBoundingBox()
		wrap:PivotTo(CFrame.new(bcf.Position) * CFrame.Angles(0, math.rad(-90 + f[6]), 0) * (bcf:Inverse() * wrap:GetPivot()))
		bcf, bs = wrap:GetBoundingBox()
		local wx = math.abs(bcf.XVector.X) * bs.X + math.abs(bcf.YVector.X) * bs.Y + math.abs(bcf.ZVector.X) * bs.Z
		local wz = math.abs(bcf.XVector.Z) * bs.X + math.abs(bcf.YVector.Z) * bs.Y + math.abs(bcf.ZVector.Z) * bs.Z
		local alvo = Vector3.new(xCursor + wx / 2, 20 + bs.Y / 2, 346 + wz / 2)
		wrap:PivotTo(wrap:GetPivot() + (alvo - bcf.Position))
		for _, d in ipairs(wrap:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end
		end
		xCursor = xCursor + wx - SOBRE
	end
end

-- ---------- correções de deco (enterrados/órfãos após o platô) ----------
local dfold = map.Deco
local props = map.Props
local function lift(inst, dy)
	if inst then inst:PivotTo(inst:GetPivot() * CFrame.new(0, dy, 0)) end
end
local function moveTo(inst, x, y, z, ry)
	if inst then
		local b = inst:GetBoundingBox()
		inst:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(ry or 0), 0) * (b:Inverse() * inst:GetPivot()))
	end
end
local D = {}
for _, c in ipairs(dfold:GetChildren()) do D[c.Name] = c end
moveTo(D.deco_bush_2_2, 230, 3.5, 292)
for _, c in ipairs(props:GetChildren()) do
	if c.Name == "poste_N1" then moveTo(c, 300, 35.8, 372) end
	if c.Name == "brasilia_C1" then moveTo(c, 300, 22.45, 340, -35) end
end
moveTo(D.deco_pneus_3, 322, 3.2, 148)
lift(D.deco_pneus_4, 20)
lift(D.deco_varal_3, 20)
moveTo(D.deco_bananeira_3, 246, 8.5, 296)
lift(D.deco_bush_1_2, 20)
for _, nome in ipairs({ "deco_arvore_2_2", "deco_arvore_4_1", "deco_arvore_1_3", "deco_arvore_5_2",
	"deco_arvore_3_2", "deco_arvore_1_4", "deco_arvore_4_3", "deco_arvore_3_3" }) do
	lift(D[nome], 20)
end
for _, c in ipairs(dfold:GetChildren()) do
	if c.Name:match("^morro_casa_") then
		local cf = c:GetBoundingBox()
		-- só sobe onde há platô atrás (NW em X<175 continua baixada)
		if (cf.Z > 400 and cf.X >= 175) or cf.X > 410 then lift(c, 20) end
	end
end
lift(D.deco_predio_apto_2, 20)
lift(D.deco_predio_apto_3, 20)
lift(D.deco_casa_favela_2, 20)
local cxs = dfold:FindFirstChild("v4_caixas_dagua")
if cxs then
	for _, c in ipairs(cxs:GetChildren()) do
		local p = c.Position
		if math.abs(p.X - 312) < 2 and math.abs(p.Z - 290) < 2 then c.CFrame = CFrame.new(368, 56.6, 245) * CFrame.Angles(0, 0, math.rad(90)) end
		if math.abs(p.X - 222) < 2 and math.abs(p.Z - 336) < 2 then c.CFrame = CFrame.new(208, 56.6, 340) * CFrame.Angles(0, 0, math.rad(90)) end
	end
end
local toldos = dfold:FindFirstChild("v4_toldos")
if toldos then
	for _, t in ipairs(toldos:GetChildren()) do
		if t.Color == Color3.fromRGB(200, 40, 45) then
			-- fachada sul do mercado (reto), acima do letreiro
			t.CFrame = CFrame.new(256, 34.2, 347.6) * CFrame.Angles(math.rad(-14), 0, 0)
		end
	end
end
-- jipe e trailer (do pack sul) viram props jogáveis
local function achaVeiculo(nomeModel, nomeMesh)
	return map.Props:FindFirstChild(nomeModel) or map.Boundaries:FindFirstChild(nomeModel)
		or (map.Boundaries:FindFirstChild(nomeMesh, true) and map.Boundaries:FindFirstChild(nomeMesh, true).Parent)
end
local jipe = achaVeiculo("sul_jipe", "Meshy_Meshy_Model_Mesh_0.002")
local trailer = achaVeiculo("sul_trailer", "Meshy_Meshy_Model_Mesh_0.003")
if jipe then moveBBox(jipe, P(18, 4.5, 36, 70)); jipe.Parent = map.Props end
if trailer then moveBBox(trailer, P(215, 5.7, 32, 10)); trailer.Parent = map.Props end

-- ---------- Baixada dos Becos (labirinto 100% térreo, só casas 3D — projeto v7) ----------
local lab = map:FindFirstChild("Labirinto") or Instance.new("Folder")
lab.Name = "Labirinto"; lab.Parent = map
-- {model sul_*, escala, x, z, ry (facing + giro de compensação do mesh)}
local becos = {
	{ "sul_casa_verde", 0.45, 130, 102, -25 }, -- ilha oeste, colada no B1/casa_A1
	{ "sul_casa_azul", 0.50, 196, 85, -90 }, -- TORRE marco central, colada no A2
	{ "sul_barracos", 0.60, 259, 90, -120 }, -- ilha leste, colada no mercadinho
	{ "sul_casa_varanda", 0.60, 168, 171, -129 }, -- ilha norte (frente pro miolo)
}
for _, e in ipairs(becos) do
	local m = map.Boundaries:FindFirstChild(e[1]) or map.Props:FindFirstChild(e[1]) or lab:FindFirstChild(e[1])
	if m then
		m.Parent = lab
		if math.abs(m:GetScale() - e[2]) > 0.01 then m:ScaleTo(e[2]) end
		local bcf, bs = m:GetBoundingBox()
		m:PivotTo(CFrame.new(bcf.Position) * CFrame.Angles(0, math.rad(e[5]), 0) * (bcf:Inverse() * m:GetPivot()))
		bcf, bs = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + (Vector3.new(e[3], bs.Y / 2 - 0.2, e[4]) - bcf.Position))
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true; d.CanCollide = true
				d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end
		end
	end
end
-- clones que adensam e selam as pontas abertas dos barracos (mesh é fileira sem tampas)
local clonesLab = {
	{ "sul_casa_varanda", "lab_varanda2", 0.5, 228, 92, -129 }, -- sela ponta oeste dos barracos
	{ "sul_barracos", "lab_barracos2", 0.5, 289, 107, -30 }, -- sela ponta leste, borda leste
	{ "sul_casa_verde", "lab_verde2", 0.5, 215, 152, 65 }, -- fecha o vão largo do meio
}
for _, e in ipairs(clonesLab) do
	local velho = lab:FindFirstChild(e[2]); if velho then velho:Destroy() end
	local src = lab:FindFirstChild(e[1])
	if src then
		local c = src:Clone()
		c.Name = e[2]
		c.Parent = lab
		c:ScaleTo(e[3])
		local bcf, bs = c:GetBoundingBox()
		c:PivotTo(CFrame.new(bcf.Position) * CFrame.Angles(0, math.rad(e[6]) - select(2, bcf:ToEulerAnglesYXZ()), 0) * (bcf:Inverse() * c:GetPivot()))
		bcf, bs = c:GetBoundingBox()
		c:PivotTo(c:GetPivot() + (Vector3.new(e[4], bs.Y / 2 - 0.2, e[5]) - bcf.Position))
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true; d.CanCollide = true
				d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end
		end
	end
end

for _, d in ipairs(plato:GetDescendants()) do
	if d:IsA("BasePart") then d.Anchored = true end
end
print("PLATO v5 OK — duas cotas construídas, fileira 3D na Rua do Morro")
