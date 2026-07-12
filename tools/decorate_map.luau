-- decorate_map.luau — Complexo: Breach, camada de ambientação (rodar no command bar APÓS build_map.luau)
-- Referência visual: vila brasileira estilizada (cores vivas, vegetação, skyline, paredão).
-- Idempotente: baixa os assets do Creator Store 1x (templates em ServerStorage.MapAssets.Deco),
-- depois reconstrói workspace.Map.Deco inteiro a cada execução.

local SS = game:GetService("ServerStorage")
local L = game:GetService("Lighting")

-- ---------- 1. iluminação / atmosfera ----------
L.ClockTime = 13.3
L.GeographicLatitude = -15
L.Brightness = 2.6
L.ExposureCompensation = 0.15
L.OutdoorAmbient = Color3.fromRGB(130, 135, 145)
L.Ambient = Color3.fromRGB(90, 95, 105)
L.ColorShift_Top = Color3.fromRGB(255, 240, 215)
L.GlobalShadows = true
L.ShadowSoftness = 0.25
L.EnvironmentDiffuseScale = 1
L.EnvironmentSpecularScale = 1
for _, n in ipairs({ "Atmosphere", "MapaBloom", "MapaColor", "MapaSunRays" }) do
	local e = L:FindFirstChild(n)
	if e then e:Destroy() end
end
local atm = Instance.new("Atmosphere")
atm.Density = 0.3; atm.Offset = 0.25
atm.Color = Color3.fromRGB(199, 210, 222); atm.Decay = Color3.fromRGB(106, 112, 125)
atm.Glare = 0.2; atm.Haze = 1.2; atm.Parent = L
local bloom = Instance.new("BloomEffect")
bloom.Name = "MapaBloom"; bloom.Intensity = 0.4; bloom.Size = 24; bloom.Threshold = 1.4; bloom.Parent = L
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "MapaColor"; cc.Saturation = 0.22; cc.Contrast = 0.06; cc.Brightness = 0.01
cc.TintColor = Color3.fromRGB(255, 250, 240); cc.Parent = L
local sr = Instance.new("SunRaysEffect")
sr.Name = "MapaSunRays"; sr.Intensity = 0.06; sr.Spread = 0.6; sr.Parent = L

-- calçamento claro quente (pedra portuguesa vibe)
local chao = workspace:FindFirstChild("Chao_Favela")
if chao then
	chao.Material = Enum.Material.Pavement
	chao.Color = Color3.fromRGB(172, 163, 148)
end

-- ---------- 2. corrimãos laranja do escadão ----------
local map = workspace.Map
local routes = map.Routes
for _, old in ipairs(routes:GetChildren()) do
	if old.Name:match("^corrimao") then old:Destroy() end
end
local function rail(name, x)
	local p1 = Vector3.new(x, 3.4, 178)
	local p2 = Vector3.new(x, 36.4, 302)
	local r = Instance.new("Part")
	r.Name = name
	r.Size = Vector3.new(0.5, 0.5, (p2 - p1).Magnitude)
	r.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
	r.Anchored = true; r.Material = Enum.Material.SmoothPlastic
	r.Color = Color3.fromRGB(255, 120, 30); r.Parent = routes
	for t = 0, 1, 0.14 do
		local pos = p1:Lerp(p2, t)
		local post = Instance.new("Part")
		post.Name = name .. "_poste"
		post.Size = Vector3.new(0.4, 3, 0.4)
		post.CFrame = CFrame.new(pos.X, pos.Y - 1.5, pos.Z)
		post.Anchored = true; post.Material = Enum.Material.SmoothPlastic
		post.Color = Color3.fromRGB(255, 120, 30); post.Parent = routes
	end
end
rail("corrimao_1", 341)
rail("corrimao_2", 348)
rail("corrimao_3", 355)

-- ---------- 3. templates do Creator Store (baixa 1x via GetObjects) ----------
local assets = SS.MapAssets
local deco = assets:FindFirstChild("Deco")
if not deco then
	deco = Instance.new("Folder"); deco.Name = "Deco"; deco.Parent = assets
end
-- fonte -> {assetId, caminho dentro do asset (nil = primeiro Model/BasePart)}
local sources = {
	arvore_1 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Trees", "Models", "Tree_01" } },
	arvore_2 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Trees", "Models", "Tree_12" } },
	arvore_3 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Trees", "Models", "Tree_14" } },
	arvore_4 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Trees", "Models", "Tree_16" } },
	arvore_5 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Trees", "Models", "Tree_13" } },
	bush_1 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Bushes", "Models", "Bush_01" } },
	bush_2 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Bushes", "Models", "Bush_02" } },
	bush_3 = { 79689531752352, { "Yasu's_Stylized_Tree_Pack", "Models_Bushes", "Models", "Bush_03" } },
	bush_grande = { 14720410685 },
	bananeira = { 84220908308255 },
	varal = { 8938467357 },
	tabela_basquete = { 829830744 },
	rampa_skate = { 10676224985 },
	pneus = { 9504148189 },
	caixa_dagua = { 11555132922 },
	predio_apto = { 15082419807 },
	casa_favela = { 17885393199 },
	casa_favela_terrea = { 90347757761003 },
}
local cacheById = {}
for name, src in pairs(sources) do
	if not deco:FindFirstChild(name) then
		local id, path = src[1], src[2]
		if not cacheById[id] then
			local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
			assert(ok and objs and #objs > 0, "falha ao baixar asset " .. id .. ": " .. tostring(objs))
			local holder = Instance.new("Folder")
			for _, o in ipairs(objs) do o.Parent = holder end
			cacheById[id] = holder
		end
		local node = cacheById[id]
		if path then
			for _, seg in ipairs(path) do node = node:FindFirstChild(seg) or error(name .. ": não achei " .. seg) end
		else
			node = node:FindFirstChildOfClass("Model") or node:FindFirstChildOfClass("MeshPart")
				or node:FindFirstChildOfClass("UnionOperation") or error(name .. ": asset vazio")
		end
		local c = node:Clone(); c.Name = name; c.Parent = deco
	end
end
for _, holder in pairs(cacheById) do holder:Destroy() end

-- ---------- 4. distribuição ----------
local dfold = map:FindFirstChild("Deco") or Instance.new("Folder")
dfold.Name = "Deco"; dfold.Parent = map
dfold:ClearAllChildren()

local counter = {}
local function put(tname, x, z, ry, scale, opts)
	opts = opts or {}
	local t = deco:FindFirstChild(tname)
	if not t then print("sem template " .. tname) return end
	counter[tname] = (counter[tname] or 0) + 1
	local c = t:Clone()
	c.Name = ("deco_%s_%d"):format(tname, counter[tname])
	local wrap = c
	if c:IsA("BasePart") then
		wrap = Instance.new("Model"); c.Parent = wrap; wrap.Name = c.Name
	end
	if scale and scale ~= 1 then wrap:ScaleTo(scale) end
	local bcf, bs = wrap:GetBoundingBox()
	local y = bs.Y / 2 - 0.2 + (opts.dy or 0)
	local target = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(ry or 0), 0)
	wrap:PivotTo(target * (bcf:Inverse() * wrap:GetPivot()))
	for _, d in ipairs(wrap:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			if opts.nocollide then d.CanCollide = false end
			if opts.tint then d.Color = d.Color:Lerp(opts.tint, 0.45) end
		end
	end
	wrap.Parent = dfold
	return wrap
end

local NC = { nocollide = true }
-- árvores: perímetro (atrás dos muros) + poucas dentro do playable (sem colisão)
put("arvore_1", 40, -45, 20, 0.9, NC);   put("arvore_5", 150, -55, 130, 1.0, NC)
put("arvore_2", 260, -45, 250, 0.9, NC); put("arvore_3", 350, -42, 70, 1.0, NC)
put("arvore_2", 80, 428, 40, 1.0, NC);   put("arvore_4", 170, 432, 200, 1.1, NC)
put("arvore_1", 250, 426, 310, 0.85, NC); put("arvore_5", 335, 430, 15, 0.9, NC)
put("arvore_3", 428, 70, 75, 1.0, NC);   put("arvore_1", 433, 185, 160, 0.8, NC)
put("arvore_4", 428, 305, 280, 1.0, NC)
put("arvore_3", 200, 350, 45, 0.75, NC)
put("arvore_4", 312, 48, 220, 0.8, NC)
put("arvore_2", 126, 62, 300, 0.7, NC)
-- arbustos
put("bush_1", 118, 57, 15, 1.2, NC);   put("bush_2", 200, 19, 80, 1.4, NC)
put("bush_3", 296, 44, 150, 1.3, NC);  put("bush_grande", 362, 122, 40, 1.5, NC)
put("bush_1", 356, 258, 200, 1.3, NC); put("bush_2", 242, 347, 310, 1.2, NC)
put("bush_grande", 152, 352, 75, 1.4, NC); put("bush_3", 182, 202, 260, 1.2, NC)
-- bananeiras
put("bananeira", 102, 54, 40, 1.0, NC);  put("bananeira", 176, 256, 160, 1.1, NC)
put("bananeira", 289, 340, -70, 1.0, NC); put("bananeira", 352, 147, 230, 0.9, NC)
-- varais
put("varal", 152, 57, 4, 1.0, { nocollide = true, dy = 9 })
put("varal", 95, 222, 88, 1.0, { nocollide = true, dy = 11 })
put("varal", 344, 333, 15, 1.0, { nocollide = true, dy = 9 })
-- quadra e praças
put("tabela_basquete", 286, 240, -90, 1.0, { dy = 0.6 })
put("rampa_skate", 303, 58, 15, 1.0)
put("pneus", 146, 207, 10, 1.5); put("pneus", 229, 183, -25, 1.5)
put("pneus", 338, 148, 40, 1.5); put("pneus", 355, 343, 0, 1.3)
-- skyline
put("caixa_dagua", 140, 442, 0, 0.33)
put("predio_apto", -5, 448, 20, 1.0)
put("casa_favela", 72, 434, 5, 1.0)
put("casa_favela_terrea", 438, 52, -90, 1.1)
-- (2 prédios extras e casa_favela duplicada removidos à mão pelo design)

-- ---------- 5. paredão de som (parts) ----------
local paredao = Instance.new("Model"); paredao.Name = "deco_paredao_som"
local base = CFrame.new(194, 0, 193) * CFrame.Angles(0, math.rad(35), 0)
for i, off in ipairs({ { -2.1, 2 }, { 2.1, 2 }, { -2.1, 6 }, { 2.1, 6 }, { 0, 10 } }) do
	local b = Instance.new("Part")
	b.Name = "caixa_" .. i
	b.Size = Vector3.new(4, 4, 3)
	b.CFrame = base * CFrame.new(off[1], off[2], 0)
	b.Anchored = true; b.Material = Enum.Material.Wood
	b.Color = Color3.fromRGB(25, 25, 28)
	b.Parent = paredao
	for _, dy in ipairs({ 0.9, -0.9 }) do
		local cone = Instance.new("Part")
		cone.Shape = Enum.PartType.Cylinder
		cone.Size = Vector3.new(0.3, 2.1, 2.1)
		cone.CFrame = base * CFrame.new(off[1], off[2] + dy, -1.55) * CFrame.Angles(0, math.rad(90), 0)
		cone.Anchored = true; cone.Material = Enum.Material.Fabric
		cone.Color = Color3.fromRGB(60, 60, 64)
		cone.Parent = paredao
	end
end
paredao.Parent = dfold

-- ---------- 6. v4: morro de casas empilhadas, quadra azul, arquibancada, caixas d'água, toldos ----------
local CORES = {
	{ Color3.fromRGB(232, 185, 35), Enum.Material.Concrete },
	{ Color3.fromRGB(168, 202, 58), Enum.Material.Concrete },
	{ Color3.fromRGB(198, 105, 55), Enum.Material.Brick },
	{ Color3.fromRGB(226, 160, 60), Enum.Material.Concrete },
	{ Color3.fromRGB(120, 180, 190), Enum.Material.Concrete },
	{ Color3.fromRGB(215, 130, 150), Enum.Material.Concrete },
}
local CINZA = Color3.fromRGB(160, 158, 150)
local AZUL_CAIXA = Color3.fromRGB(35, 95, 170)
local function mkpart(parent, sz, cf, color, mat)
	local p = Instance.new("Part")
	p.Size = sz; p.CFrame = cf; p.Anchored = true
	p.Color = color; p.Material = mat or Enum.Material.Concrete
	p.Parent = parent
	return p
end
local function caixaDagua(parent, cf)
	local c = Instance.new("Part")
	c.Shape = Enum.PartType.Cylinder
	c.Size = Vector3.new(3.2, 3.4, 3.4)
	c.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	c.Anchored = true; c.Color = AZUL_CAIXA
	c.Material = Enum.Material.SmoothPlastic
	c.Parent = parent
end
local morroN = 0
local function casa(x, z, ry, w, d, h1, corIdx, elev, doisPisos, temCaixa)
	morroN += 1
	local m = Instance.new("Model")
	m.Name = "morro_casa_" .. morroN
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(ry), 0)
	local cor1 = CORES[(corIdx - 1) % #CORES + 1]
	local y1 = elev + h1 / 2
	mkpart(m, Vector3.new(w, h1, d), base * CFrame.new(0, y1, 0), cor1[1], cor1[2])
	for _, jx in ipairs({ -w / 4, w / 4 }) do
		mkpart(m, Vector3.new(3, 3.6, 0.35), base * CFrame.new(jx, y1 + h1 * 0.15, -d / 2 - 0.1), Color3.fromRGB(35, 40, 48), Enum.Material.Glass)
	end
	local topo1 = elev + h1
	local recuo = d * 0.45
	if doisPisos then
		local cor2 = CORES[corIdx % #CORES + 1]
		local w2, d2, h2 = w * 0.72, d - recuo, h1 * 0.8
		mkpart(m, Vector3.new(w2, h2, d2), base * CFrame.new(-w * 0.1, topo1 + h2 / 2, recuo / 2), cor2[1], cor2[2])
		mkpart(m, Vector3.new(2.6, 3.2, 0.35), base * CFrame.new(-w * 0.1, topo1 + h2 * 0.55, recuo / 2 - d2 / 2 - 0.1), Color3.fromRGB(35, 40, 48), Enum.Material.Glass)
		mkpart(m, Vector3.new(w, 1.1, 0.5), base * CFrame.new(0, topo1 + 0.55, -d / 2 + 0.25), CINZA)
		mkpart(m, Vector3.new(0.5, 1.1, recuo), base * CFrame.new(-w / 2 + 0.25, topo1 + 0.55, -d / 2 + recuo / 2), CINZA)
		mkpart(m, Vector3.new(0.5, 1.1, recuo), base * CFrame.new(w / 2 - 0.25, topo1 + 0.55, -d / 2 + recuo / 2), CINZA)
		mkpart(m, Vector3.new(w * 0.5, 0.25, recuo * 0.9), base * CFrame.new(w * 0.22, topo1 + 4.4, -d / 2 + recuo / 2), Color3.fromRGB(125, 125, 122), Enum.Material.CorrodedMetal)
		if temCaixa then caixaDagua(m, base * CFrame.new(w * 0.2, topo1 + h2 + 1.7, recuo / 2 + d2 / 4)) end
	else
		mkpart(m, Vector3.new(w, 1.1, 0.5), base * CFrame.new(0, topo1 + 0.55, -d / 2 + 0.25), CINZA)
		if temCaixa then caixaDagua(m, base * CFrame.new(w / 4, topo1 + 1.7, d / 4)) end
	end
	m.Parent = dfold
end
-- MORRO 3D (bloco do Meshy otimizado — assets/favela_bloco_3d.fbx importado uma vez
-- via Asset Manager e guardado em ServerStorage.MapAssets.Deco.favela_bloco_3d).
-- Fallback: se o template não existir, gera casinhas-caixa com casa() como antes.
local USAR_MORRO_3D = true
local bloco3d = USAR_MORRO_3D and deco:FindFirstChild("favela_bloco_3d") or nil
if bloco3d then
	local pasta = dfold:FindFirstChild("morro3d") or Instance.new("Folder")
	pasta.Name = "morro3d"; pasta.Parent = dfold
	pasta:ClearAllChildren()
	local layout = {
		-- {x, yCentro, z, ry, escala} — norte 3+2+1 subindo, leste 2+1, sul 2
		{ 115, 27.4, 465, 0, 0.62 }, { 235, 27.4, 470, 0, 0.62 }, { 355, 27.4, 463, 0, 0.62 },
		{ 172, 65.7, 528, 0, 0.70 }, { 305, 65.7, 533, 0, 0.70 },
		{ 240, 100.4, 592, 0, 0.75 },
		{ 455, 27.4, 150, 90, 0.62 }, { 452, 27.4, 300, 90, 0.62 },
		{ 512, 65.7, 225, 90, 0.70 },
		{ -96, 32.1, 141, -90, 0.60 }, -- oeste (reposicionado à mão pelo design)
		{ 320, 25.4, -115, 180, 0.60 },
	}
	for i, e in ipairs(layout) do
		local c = bloco3d:Clone()
		c.Name = "morro3d_" .. i
		c.Parent = pasta
		c:ScaleTo(e[5])
		local bcf = c:GetBoundingBox()
		c:PivotTo(CFrame.new(e[1], e[2], e[3]) * CFrame.Angles(0, math.rad(e[4]), 0) * (bcf:Inverse() * c:GetPivot()))
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
		end
	end
else
	-- morro norte (2 fileiras subindo)
	casa(70, 420, 0, 22, 16, 10, 1, 6, true, true)
	casa(120, 424, 8, 18, 14, 9, 2, 7, true, false)
	casa(168, 421, -5, 20, 15, 10, 3, 6, true, true)
	casa(215, 425, 4, 24, 16, 11, 4, 8, true, false)
	casa(262, 420, -7, 18, 14, 9, 5, 6, true, true)
	casa(310, 424, 6, 22, 15, 10, 6, 7, true, false)
	casa(95, 445, -3, 26, 18, 12, 3, 15, true, true)
	casa(185, 448, 5, 24, 16, 11, 1, 16, true, false)
	casa(280, 446, -4, 26, 18, 12, 2, 15, true, true)
	casa(428, 90, 90, 20, 15, 10, 4, 6, true, true)
	casa(432, 160, 85, 22, 16, 11, 1, 7, true, false)
	casa(428, 235, 95, 20, 15, 10, 2, 6, true, true)
	casa(430, 310, 88, 22, 15, 10, 5, 7, true, false)
	casa(452, 200, 90, 24, 17, 12, 3, 15, true, true)
	casa(60, -55, 180, 22, 15, 10, 2, 6, true, true)
	casa(255, -52, 175, 20, 15, 10, 5, 7, true, false)
	casa(390, -40, 160, 22, 16, 11, 6, 6, true, true)
end

-- quadra azul de futsal + círculos amarelos (sobre o gramado do asset)
local v4q = Instance.new("Model"); v4q.Name = "v4_quadra_pintura"
local piso = mkpart(v4q, Vector3.new(108, 0.18, 54), CFrame.new(236, 0.58, 240), Color3.fromRGB(32, 108, 158))
piso.CanCollide = false
for _, cxr in ipairs({ 200, 236, 272 }) do
	local circ = Instance.new("Part")
	circ.Shape = Enum.PartType.Cylinder
	circ.Size = Vector3.new(0.1, 13, 13)
	circ.CFrame = CFrame.new(cxr, 0.7, 240) * CFrame.Angles(0, 0, math.rad(90))
	circ.Anchored = true; circ.CanCollide = false
	circ.Color = Color3.fromRGB(238, 195, 50)
	circ.Material = Enum.Material.Concrete
	circ.Parent = v4q
end
v4q.Parent = dfold
-- arquibancada na viela oeste olhando a quadra
local arq = Instance.new("Model"); arq.Name = "v4_arquibancada"
for i = 1, 3 do
	mkpart(arq, Vector3.new(2.4, 1.2 * i, 30), CFrame.new(178.2 - i * 2.4, (1.2 * i) / 2 - 0.2, 230), CINZA)
end
arq.Parent = dfold
-- caixas d'água nos telhados dos sobrados/casas
local cxm = Instance.new("Model"); cxm.Name = "v4_caixas_dagua"
for _, e in ipairs({
	{ 132, 36.6, 62 }, { 192, 36.6, 72 }, { 268, 36.6, 122 }, { 199, 36.6, 112 },
	{ 152, 36.6, 98 }, { 312, 36.6, 290 }, { 222, 36.6, 336 }, { 110, 23.4, 124 }, { 162, 23.2, 262 },
}) do
	caixaDagua(cxm, CFrame.new(e[1], e[2], e[3]))
end
cxm.Parent = dfold
-- toldos das lojas
local toldos = Instance.new("Model"); toldos.Name = "v4_toldos"
local t1 = mkpart(toldos, Vector3.new(16, 0.25, 5), CFrame.new(272, 17.5, 310.5) * CFrame.Angles(math.rad(-14), math.rad(15), 0), Color3.fromRGB(200, 40, 45), Enum.Material.Fabric)
t1.CanCollide = false
local t2 = mkpart(toldos, Vector3.new(14, 0.25, 4.5), CFrame.new(251.5, 17.5, 62) * CFrame.Angles(math.rad(-14), math.rad(-75), 0), Color3.fromRGB(235, 190, 50), Enum.Material.Fabric)
t2.CanCollide = false
toldos.Parent = dfold
-- prédios do skyline em branco (conjunto habitacional)
local branco = Color3.fromRGB(238, 238, 232)
for _, m in ipairs(dfold:GetChildren()) do
	if m.Name:match("^deco_predio_apto") then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then d.Color = d.Color:Lerp(branco, 0.75) end
		end
	end
end
for _, d in ipairs(dfold:GetDescendants()) do
	if d:IsA("BasePart") then d.Anchored = true end
end

print("DECORAÇÃO OK — " .. #dfold:GetChildren() .. " instâncias em Map.Deco")
