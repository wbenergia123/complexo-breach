-- src/shared/CharacterConfig.luau
-- Dados do personagem da facção (velocidades, hitboxes, rig) + auto-teste.
-- Ver docs/superpowers/specs/2026-07-12-personagem-faccao-design.md

local CharacterConfig = {}

CharacterConfig.TeamName = "Criminosos"
CharacterConfig.RespawnDelay = 3

CharacterConfig.Speeds = {
	walk = 10,
	run = 18, -- Shift (sprint)
	aimWalk = 6, -- mirando (ADS)
	crouch = 6, -- Ctrl
}

CharacterConfig.Rig = {
	rootSize = Vector3.new(2, 4.4, 1.4), -- caixa de colisão da HRP
	hipHeight = 0.3, -- calibrado na montagem do rig
}

-- Hitboxes nomeadas como R15: o computeDamage atual funciona sem mudança.
CharacterConfig.Hitboxes = {
	{ part = "Head", bone = "mixamorig:Head", size = Vector3.new(0.9, 0.9, 0.9) },
	{ part = "UpperTorso", bone = "mixamorig:Spine1", size = Vector3.new(1.5, 1.5, 0.9) },
	{ part = "LowerTorso", bone = "mixamorig:Hips", size = Vector3.new(1.4, 0.9, 0.9) },
	{ part = "LeftUpperLeg", bone = "mixamorig:LeftUpLeg", size = Vector3.new(0.7, 1.6, 0.7) },
	{ part = "RightUpperLeg", bone = "mixamorig:RightUpLeg", size = Vector3.new(0.7, 1.6, 0.7) },
}

function CharacterConfig.runChecks()
	local s = CharacterConfig.Speeds
	assert(s.run > s.walk, "run deve ser mais rapido que walk")
	assert(s.crouch < s.walk, "crouch deve ser mais lento que walk")
	assert(s.aimWalk < s.walk, "aimWalk deve ser mais lento que walk")

	local seen = {}
	for _, hb in CharacterConfig.Hitboxes do
		assert(not seen[hb.part], "hitbox duplicada: " .. hb.part)
		seen[hb.part] = true
		assert(hb.size.X > 0 and hb.size.Y > 0 and hb.size.Z > 0, "tamanho invalido: " .. hb.part)
		assert(hb.bone:sub(1, 10) == "mixamorig:", "osso sem prefixo mixamorig: " .. hb.bone)
	end
	assert(seen.Head, "precisa de hitbox Head (headshot)")
	assert(CharacterConfig.Rig.rootSize.Y < 5.5, "HRP nao pode ser mais alta que o boneco")
	return true
end

return CharacterConfig
