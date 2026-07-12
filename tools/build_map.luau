-- build_map.luau — Complexo: Breach, layout do mapa (rodar no command bar do Studio)
-- Idempotente: 1ª execução move os assets originais do Workspace para ServerStorage.MapAssets
-- (templates); depois reconstrói workspace.Map inteiro a partir deles a cada execução.

local SS = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

-- ---------- templates ----------
local assets = SS:FindFirstChild("MapAssets")
if not assets then
	assets = Instance.new("Folder")
	assets.Name = "MapAssets"
	assets.Parent = SS
end
local templateNames = {
	"favela_roblox", "sobrado_001", "shop_001", "escada_001", "escada_002",
	"poste_002", "brasilia_001", "caveirao_001", "quadra_001", "muro_001",
	"refem_001", "cadeira_001", "pack_meshy",
}
for _, n in ipairs(templateNames) do
	if not assets:FindFirstChild(n) then
		local inst = workspace:FindFirstChild(n)
		assert(inst, "template não encontrado: " .. n)
		inst.Parent = assets
	end
end
-- duas casa_001 no workspace -> casa_001_A / casa_001_B
for _, suffix in ipairs({ "A", "B" }) do
	if not assets:FindFirstChild("casa_001_" .. suffix) then
		local c = workspace:FindFirstChild("casa_001")
		assert(c, "template não encontrado: casa_001_" .. suffix)
		c.Name = "casa_001_" .. suffix
		c.Parent = assets
	end
end
-- saves antigos têm refém/cadeira sem a escala por pivô aplicada (cadeira de 88 studs!)
local function fixScale(model, targetHeight)
	local _, s = model:GetBoundingBox()
	if s.Y > targetHeight * 1.5 then
		model:ScaleTo(model:GetScale() * (targetHeight / s.Y))
	end
end
fixScale(assets.cadeira_001, 2.8)
fixScale(assets.refem_001, 5.5)

-- ---------- mapa ----------
local old = workspace:FindFirstChild("Map")
if old then old:Destroy() end
local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace
local folders = {}
for _, n in ipairs({ "Buildings", "Props", "Routes", "Spawns", "Objective", "Boundaries" }) do
	local f = Instance.new("Folder")
	f.Name = n
	f.Parent = map
	folders[n] = f
end

local function P(x, y, z, ry)
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(ry or 0), 0)
end

-- posiciona pelo CENTRO DO BOUNDING BOX (pivôs dos assets estão deslocados)
local function place(templateName, cloneName, cf, folder)
	local t = assets:FindFirstChild(templateName)
	assert(t, "template? " .. templateName)
	local clone = t:Clone()
	clone.Name = cloneName
	local bboxCF = clone:GetBoundingBox()
	clone:PivotTo(cf * (bboxCF:Inverse() * clone:GetPivot()))
	clone.Parent = folders[folder]
	return clone
end

-- {template, nome, x, y(centro bbox), z, ry, pasta}
local placements = {
	-- Rota B / oeste: complexo (rua interna vira o "canyon" da Rota B, fachadas para +X)
	{ "favela_roblox", "favela_roblox", 65, 5.0, 200, 180, "Buildings" },
	-- sobrados
	{ "sobrado_001", "sobrado_A1", 140, 17.3, 68, 8, "Buildings" },
	{ "sobrado_001", "sobrado_A2", 185, 17.3, 66, -10, "Buildings" },
	{ "sobrado_001", "sobrado_A3", 263, 17.3, 130, 95, "Buildings" },
	{ "sobrado_001", "sobrado_A4", 207, 17.3, 120, -85, "Buildings" },
	{ "sobrado_001", "sobrado_B1", 158, 17.3, 105, 100, "Buildings" },
	{ "sobrado_001", "sobrado_C1", 318, 17.3, 296, 0, "Buildings" }, -- laje defensiva NE
	{ "sobrado_001", "sobrado_N1", 215, 17.3, 330, 12, "Buildings" },
	-- lojas
	{ "shop_001", "mercado_silva", 272, 10.8, 322, 15, "Buildings" }, -- esquina B<->C
	{ "shop_001", "mercadinho", 262, 10.8, 58, -75, "Buildings" }, -- marco da curva da Rota A
	-- casas soltas (quebram sightline do canyon)
	{ "casa_001_A", "casa_A1", 110, 10.6, 130, 20, "Buildings" },
	{ "casa_001_B", "casa_B1", 158, 10.5, 268, -15, "Buildings" },
	-- bordas
	{ "muro_001", "muro_S0", 10, 12.25, -12, 0, "Boundaries" },
	{ "muro_001", "muro_S1", 200, 12.25, -12, 0, "Boundaries" }, -- grafites = marco da Rota A
	{ "muro_001", "muro_SE", 340, 12.25, -5, -15, "Boundaries" },
	{ "muro_001", "muro_E1", 390, 12.25, 110, 90, "Boundaries" },
	{ "muro_001", "muro_E2", 390, 12.25, 290, 90, "Boundaries" },
	{ "muro_001", "muro_N1", 280, 12.25, 390, 0, "Boundaries" },
	{ "muro_001", "muro_N15", 160, 12.25, 395, 8, "Boundaries" },
	{ "muro_001", "muro_N2", 40, 12.25, 390, 0, "Boundaries" },
	{ "pack_meshy", "morro_sul", 150, 29.8, -90, 90, "Boundaries" }, -- cenário atrás do muro
	-- props
	{ "caveirao_001", "caveirao", -26, 3.75, 35, 0, "Props" }, -- spawn BOPE (posição do design)
	{ "brasilia_001", "brasilia_A1", 150, 2.45, 28, 20, "Props" },
	{ "brasilia_001", "brasilia_B1", 226, 2.45, 146, -30, "Props" }, -- posição defensiva 3
	{ "brasilia_001", "brasilia_C1", 332, 2.45, 355, -35, "Props" },
	{ "brasilia_001", "brasilia_D1", 95, 2.45, 170, 75, "Props" },
	{ "poste_002", "poste_A1", 110, 15.8, 45, 0, "Props" },
	{ "poste_002", "poste_A2", 170, 15.8, 52, 0, "Props" },
	{ "poste_002", "poste_A3", 250, 15.8, 85, 0, "Props" },
	{ "poste_002", "poste_A4", 238, 15.8, 160, 90, "Props" },
	{ "poste_002", "poste_B1", 120, 15.8, 150, 0, "Props" },
	{ "poste_002", "poste_B2", 135, 15.8, 290, 0, "Props" },
	{ "poste_002", "poste_N1", 240, 15.8, 352, 90, "Props" },
	{ "poste_002", "poste_E1", 330, 15.8, 120, 90, "Props" },
	-- escadas (Rotas B e C)
	{ "escada_002", "escadao_C", 348, 19.8, 240, 90, "Routes" }, -- sobe para o norte
	{ "escada_001", "escada_B1", 120, 9.8, 240, -90, "Routes" }, -- desce da varanda oeste
	{ "escada_001", "escada_E1", 308, 9.8, 200, 0, "Routes" }, -- sobe para o pulo da grade
	{ "escada_001", "escada_O1", 102, 9.8, 85, 0, "Routes" }, -- sobe do spawn p/ passarela oeste
	{ "escada_001", "escada_N1", 265, 9.8, 297, 90, "Routes" }, -- desce da laje leste p/ viela norte
	-- objetivo
	{ "quadra_001", "quadra", 236, 10.65, 240, 0, "Objective" }, -- abertura nativa para o sul
	{ "refem_001", "refem", 218, 3.2, 265, 180, "Objective" }, -- grade norte, ao lado da trave
	{ "cadeira_001", "cadeira", 215.5, 1.85, 265, 160, "Objective" },
}
for _, p in ipairs(placements) do
	place(p[1], p[2], P(p[3], p[4], p[5], p[6]), p[7])
end

-- ---------- partes estruturais (lajes, colunas, truss, extração, bordas invisíveis) ----------
local function part(name, x, y, z, sx, sy, sz, folder, props, className)
	local pt = Instance.new(className or "Part")
	pt.Name = name
	pt.Size = Vector3.new(sx, sy, sz)
	pt.CFrame = CFrame.new(x, y, z)
	pt.Anchored = true
	pt.Material = Enum.Material.Concrete
	pt.Color = Color3.fromRGB(140, 137, 130)
	if props then
		for k, v in pairs(props) do pt[k] = v end
	end
	pt.Parent = folders[folder]
	return pt
end
-- Varanda do complexo (posição defensiva 2) — topo Y21, acesso pela escada_B1
part("laje_varanda", 95, 20.5, 240, 20, 1, 20, "Routes")
part("laje_varanda_col1", 100, 10, 234, 2, 20, 2, "Routes")
part("laje_varanda_col2", 100, 10, 246, 2, 20, 2, "Routes")
-- Laje alta no topo do escadão (Rota C) — topo Y35, liga na laje do sobrado_C1 (Y34.8)
part("laje_alta", 348, 34.5, 316, 30, 1, 24, "Routes")
part("laje_alta_col1", 337, 17, 318, 2, 34, 2, "Routes")
part("laje_alta_col2", 359, 17, 318, 2, 34, 2, "Routes")
-- Truss: contra-flanco rápido dos defensores para a laje alta
part("truss_defensor", 364.5, 17.2, 318, 2, 34, 2, "Routes", nil, "TrussPart")
-- Pulo da grade: plataforma Y21.5 colada na grade leste da quadra (entrada 2, sem retorno)
part("laje_pulo", 299, 21, 240, 10, 1, 20, "Routes", { Color = Color3.fromRGB(42, 157, 143) })
part("laje_pulo_col1", 299, 10.5, 233, 2, 20, 2, "Routes", { Color = Color3.fromRGB(32, 118, 107) })
part("laje_pulo_col2", 299, 10.5, 247, 2, 20, 2, "Routes", { Color = Color3.fromRGB(32, 118, 107) })
-- ===== segundo piso: circuito OESTE (sobe escada_O1 -> passarela -> varanda -> desce escada_B1) =====
part("passarela_oeste", 95.5, 20.52, 173, 11, 1, 124, "Routes", { Color = Color3.fromRGB(233, 196, 106) })
part("passarela_oeste_col1", 95.5, 10, 130, 2, 20, 2, "Routes", { Color = Color3.fromRGB(175, 147, 80) })
part("passarela_oeste_col2", 95.5, 10, 175, 2, 20, 2, "Routes", { Color = Color3.fromRGB(175, 147, 80) })
part("passarela_oeste_col3", 95.5, 10, 220, 2, 20, 2, "Routes", { Color = Color3.fromRGB(175, 147, 80) })
part("passarela_oeste_mureta1", 100.6, 22.27, 162, 0.7, 2.5, 34, "Routes", { Color = Color3.fromRGB(196, 106, 90) })
part("passarela_oeste_mureta2", 100.6, 22.27, 205, 0.7, 2.5, 30, "Routes", { Color = Color3.fromRGB(196, 106, 90) })
-- ===== segundo piso: circuito LESTE (escada_E1 -> laje_pulo -> laje_leste -> desce escada_N1) =====
part("laje_leste", 296, 21.02, 273, 10, 1, 46, "Routes", { Color = Color3.fromRGB(42, 157, 143) })
part("laje_leste_col1", 296, 10.5, 273, 2, 20, 2, "Routes", { Color = Color3.fromRGB(32, 118, 107) })
part("laje_leste_mureta", 300.6, 22.77, 270, 0.7, 2.5, 34, "Routes", { Color = Color3.fromRGB(196, 106, 90) })
-- Zona de extração do refém, ao lado do caveirão
part("ExtractionZone", -8, 0.1, 28, 12, 0.4, 12, "Objective", {
	Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 255, 100), Transparency = 0.35,
})
-- bordas invisíveis por cima das bordas reais
local iw = { Transparency = 1, CanCollide = true }
part("invis_S", 187.5, 60, -42, 475, 120, 6, "Boundaries", iw)
part("invis_N", 187.5, 60, 417, 475, 120, 6, "Boundaries", iw)
part("invis_W", -42, 60, 187.5, 6, 120, 465, "Boundaries", iw)
part("invis_E", 417, 60, 187.5, 6, 120, 465, "Boundaries", iw)

-- ---------- times e spawns ----------
local function team(name, color)
	local t = Teams:FindFirstChild(name)
	if not t then
		t = Instance.new("Team")
		t.Name = name
		t.Parent = Teams
	end
	t.TeamColor = BrickColor.new(color)
	t.AutoAssignable = true
	return t
end
team("BOPE", "Really blue")
team("Criminosos", "Bright red")

local spawnPos = {
	BOPE = { { -38, 26 }, { -28, 22 }, { -14, 30 }, { -34, 44 } }, -- ao redor do caveirão
	Criminosos = { { 342, 342 }, { 350, 352 }, { 336, 354 }, { 356, 338 } }, -- (plato_v5 re-cota p/ Y20)
}
local spawnColor = { BOPE = "Really blue", Criminosos = "Bright red" }
for teamName, list in pairs(spawnPos) do
	for i, xz in ipairs(list) do
		local s = Instance.new("SpawnLocation")
		s.Name = ("spawn_%s_%d"):format(teamName, i)
		s.Size = Vector3.new(6, 1, 6)
		s.CFrame = CFrame.new(xz[1], 0.3, xz[2])
		s.Anchored = true
		s.Neutral = false
		s.TeamColor = BrickColor.new(spawnColor[teamName])
		s.Duration = 0
		s.Parent = folders.Spawns
	end
end

-- ---------- pós-processo ----------
-- tudo ancorado; fidelity precisa em postes/escadas (Default vira parede invisível em mesh fino)
for _, d in ipairs(map:GetDescendants()) do
	if d:IsA("BasePart") then
		d.Anchored = true
		local top = d:FindFirstAncestorOfClass("Model")
		if d:IsA("MeshPart") and top and (top.Name:match("^poste") or top.Name:match("^escad")) then
			d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		end
	end
end
-- quadra: colisão fica por conta das ColWalls; mesh da gaiola com fidelity Default viraria parede invisível
local quadra = folders.Objective.quadra
for _, d in ipairs(quadra:GetDescendants()) do
	if d:IsA("BasePart") then
		if d.Name == "quadra_Material_1737" then
			d.CanCollide = false
			d.Transparency = 1 -- mesh quebrado do asset (renderiza como "rampa" branca gigante)
		elseif d.Name == "quadra_setka1" then
			d.CanCollide = false
		elseif d:IsA("MeshPart") and (d.Name == "quadra_Black" or d.Name == "quadra_Glasss") then
			d.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		end
	end
end

-- ---------- validação ----------
local speed = 16
local function routeLen(pts)
	local total = 0
	for i = 2, #pts do
		total += (Vector2.new(pts[i][1], pts[i][2]) - Vector2.new(pts[i - 1][1], pts[i - 1][2])).Magnitude
	end
	return total
end
local routes = {
	{ "Rota A (Beco Principal)", { { 85, 40 }, { 150, 35 }, { 232, 50 }, { 232, 204 } } },
	{ "Rota B (Complexo)", { { 85, 40 }, { 115, 60 }, { 125, 240 }, { 173, 250 }, { 180, 208 }, { 236, 206 } } },
	{ "Rota C (Escadao)", { { 85, 40 }, { 160, 30 }, { 330, 35 }, { 348, 120 }, { 348, 174 }, { 348, 300 }, { 348, 316 } } },
	{ "Defensor -> grade norte (refem a vista)", { { 350, 350 }, { 300, 310 }, { 240, 276 } } },
	{ "Defensor -> laje alta (truss)", { { 350, 350 }, { 362, 330 }, { 364, 318 } } },
}
print("== METRICAS (16 studs/s) ==")
for _, r in ipairs(routes) do
	local d = routeLen(r[2])
	print(("%s: %.0f studs ~ %.1f s"):format(r[1], d, d / speed))
end
local q = folders.Objective:FindFirstChild("quadra")
local floorTop
for _, d in ipairs(q:GetDescendants()) do
	if d.Name == "quadra_tex2" then floorTop = d.Position.Y + d.Size.Y / 2 end
	if d:IsA("BasePart") and d.CanCollide and not d.Name:match("Col") and d.Name ~= "quadra_tex2" then
		print("quadra colide (conferir): " .. d.Name)
	end
end
print(("piso da quadra: Y=%.2f (rua Y=-0.2 -> degrau %.2f, StepHeight padrao 2.2 OK)"):format(floorTop, floorTop + 0.2))
print("BUILD OK — " .. #placements .. " assets posicionados")
