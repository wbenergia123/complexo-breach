-- Aplica SurfaceAppearance com texturas PBR em todos os meshes do favela_roblox
-- Materiais mapeados pelo penúltimo token do nome do mesh (ex: "gate1_gate3_0" → "gate3")
-- IDs obtidos via upload pela API apis.roblox.com/assets/user-auth (conta wbgam9)

local workspace = game:GetService("Workspace")

local favela = workspace:WaitForChild("favela_roblox", 10)
if not favela then
	warn("favela_roblox não encontrado no Workspace!")
	return
end

-- Ancora todas as partes para a física não derrubar o modelo ao entrar no jogo
local anchored = 0
for _, desc in ipairs(favela:GetDescendants()) do
	if desc:IsA("BasePart") and not desc.Anchored then
		desc.Anchored = true
		anchored += 1
	end
end
if anchored > 0 then
	print(string.format("AplicaTexturas: %d partes ancoradas", anchored))
end

local TEXTURES = {
	gate3 = {
		ColorMap     = "rbxassetid://128853824306743",
		RoughnessMap = "rbxassetid://140431700078474",
	},
	gate4 = {
		ColorMap     = "rbxassetid://100837393594480",
		RoughnessMap = "rbxassetid://103068004375207",
	},
	gate5 = {
		ColorMap     = "rbxassetid://71553671572485",
		RoughnessMap = "rbxassetid://125668845793011",
	},
	spikes = { -- LB_gate_spikes
		ColorMap     = "rbxassetid://77239094768956",
		RoughnessMap = "rbxassetid://130684482661746",
	},
	windows = { -- MB_windows
		ColorMap     = "rbxassetid://118895154328107",
		NormalMap    = "rbxassetid://102828962509165",
		RoughnessMap = "rbxassetid://72625045523147",
	},
	leftbuilding = {
		ColorMap     = "rbxassetid://94752323498941",
		NormalMap    = "rbxassetid://85440470476866",
		RoughnessMap = "rbxassetid://83977507514916",
	},
	middlebuilding = {
		ColorMap     = "rbxassetid://113185645254284",
		NormalMap    = "rbxassetid://103384162223129",
		RoughnessMap = "rbxassetid://139684223284029",
	},
	powercables = {
		ColorMap     = "rbxassetid://138455788486568",
		NormalMap    = "rbxassetid://85869652041468",
		RoughnessMap = "rbxassetid://133983867170770",
	},
	props1 = {
		ColorMap     = "rbxassetid://105375236529392",
		NormalMap    = "rbxassetid://105082975196732",
		RoughnessMap = "rbxassetid://74860813674325",
	},
	props2 = {
		ColorMap     = "rbxassetid://97824852348326",
		NormalMap    = "rbxassetid://90540196138889",
		RoughnessMap = "rbxassetid://97860530304029",
	},
	props3 = {
		ColorMap     = "rbxassetid://131827140524464",
		NormalMap    = "rbxassetid://89402610954046",
		RoughnessMap = "rbxassetid://71791207993679",
	},
	rightbuilding = {
		ColorMap     = "rbxassetid://94628155884415",
		NormalMap    = "rbxassetid://98241930666755",
		RoughnessMap = "rbxassetid://127995666779189",
	},
	road = {
		ColorMap     = "rbxassetid://84832594897058",
		NormalMap    = "rbxassetid://122658254569224",
		RoughnessMap = "rbxassetid://111963885142563",
	},
	windowgrill1 = {
		ColorMap     = "rbxassetid://132073058746009",
		RoughnessMap = "rbxassetid://109599750797785",
	},
	windowgrill2 = {
		ColorMap     = "rbxassetid://93005312346048",
		RoughnessMap = "rbxassetid://113945284516830",
	},
}

local function getMaterial(meshName)
	local name = meshName:match("^(.-)%.[0-9]+$") or meshName
	local parts = {}
	for part in name:gmatch("[^_]+") do
		table.insert(parts, part)
	end
	if #parts >= 2 then
		return parts[#parts - 1]
	end
	return nil
end

-- NÃO-DESTRUTIVO: só aplica textura em mesh que estiver SEM SurfaceAppearance.
-- Os meshes que já vêm texturizados do modelo permanecem intactos (evita ficar
-- cinza no Play por destruir e recriar os 239 de uma vez).
local applied, jaTinha, skipped = 0, 0, 0

for _, desc in ipairs(favela:GetDescendants()) do
	if desc:IsA("MeshPart") then
		if desc:FindFirstChildOfClass("SurfaceAppearance") then
			jaTinha += 1
		else
			local mat = getMaterial(desc.Name)
			local textures = mat and TEXTURES[mat]

			if textures then
				local sa = Instance.new("SurfaceAppearance")
				sa.AlphaMode = Enum.AlphaMode.Overlay
				if textures.ColorMap     then sa.ColorMap     = textures.ColorMap     end
				if textures.NormalMap    then sa.NormalMap    = textures.NormalMap    end
				if textures.RoughnessMap then sa.RoughnessMap = textures.RoughnessMap end
				sa.Parent = desc
				applied += 1
			else
				skipped += 1
			end
		end
	end
end

print(string.format("AplicaTexturas: %d aplicados agora, %d já tinham, %d sem mapeamento", applied, jaTinha, skipped))
