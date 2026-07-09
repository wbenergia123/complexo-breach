-- src/shared/WeaponConfig.luau
-- Dados da arma (data-driven) + lógica pura de dano/spray + auto-teste.
-- Ver docs/superpowers/specs/2026-07-08-sistema-arma-v1-design.md

local WeaponConfig = {}

WeaponConfig.Rifle = {
	name = "placeholder_rifle",
	automatic = true,
	fireRate = 0.1, -- segundos entre tiros (0.1 = 600 rpm)
	shots = 1, -- pellets por disparo (>1 = shotgun no futuro)
	ammo = { magazine = 30, reserve = 90 },
	reloadTime = 2.2,
	equipTime = 0.6,
	range = 500, -- studs
	damage = {
		base = 36,
		headMult = 4.0,
		legMult = 0.8,
		falloff = { startDist = 40, perStud = 0.5, minDamage = 20 }, -- [R10] studs
	},
	accuracy = { firstBullet = 0, standing = 1.5, crouch = 1.0, moving = 6, jumping = 12 },
	spray = {
		{ 0, 0 }, { 0.1, 1.4 }, { 0.3, 1.1 }, { 0.2, 1.2 },
		{ -0.1, 1.0 }, { -0.3, 0.8 }, { 0.4, 0.6 }, { 0.5, 0.5 },
	}, -- {lado, cima} por bala
	recoilRecovery = 0.3,
	recoilSpring = { mass = 5, force = 50, damping = 4 },
	-- mira (ADS)
	baseFov = 70,
	adsFov = 55,
	-- som (deixar "" enquanto não escolher um SoundId válido)
	fireSoundId = "",
}

local LEG_PARTS = {
	LeftUpperLeg = true, RightUpperLeg = true,
	LeftLowerLeg = true, RightLowerLeg = true,
	LeftFoot = true, RightFoot = true,
}

local function partMultiplier(cfg, hitPartName)
	if hitPartName == "Head" then
		return cfg.damage.headMult
	elseif LEG_PARTS[hitPartName] then
		return cfg.damage.legMult
	end
	return 1
end

-- dano = base reduzido por falloff (>= minDamage) e depois multiplicado pela parte
function WeaponConfig.computeDamage(cfg, dist, hitPartName)
	local d = cfg.damage.base
	local fo = cfg.damage.falloff
	if dist > fo.startDist then
		d -= (dist - fo.startDist) * fo.perStud
	end
	d = math.max(d, fo.minDamage)
	return d * partMultiplier(cfg, hitPartName)
end

-- offset de recuo da bala N (clampa na última — não estoura o array)
function WeaponConfig.getSprayOffset(cfg, shotIndex)
	local i = math.clamp(shotIndex, 1, #cfg.spray)
	local o = cfg.spray[i]
	return Vector2.new(o[1], o[2])
end

function WeaponConfig.runChecks()
	local c = WeaponConfig.Rifle
	local head = WeaponConfig.computeDamage(c, 5, "Head")
	local body = WeaponConfig.computeDamage(c, 5, "UpperTorso")
	local leg = WeaponConfig.computeDamage(c, 5, "LeftUpperLeg")
	assert(head > body, "headshot deve doer mais que corpo")
	assert(body > leg, "corpo deve doer mais que perna")

	local near = WeaponConfig.computeDamage(c, 5, "UpperTorso")
	local far = WeaponConfig.computeDamage(c, 300, "UpperTorso")
	assert(far < near, "falloff deve reduzir dano na distância")
	assert(far >= c.damage.falloff.minDamage, "não pode passar do dano mínimo")

	local clamped = WeaponConfig.getSprayOffset(c, 999)
	local lastReal = WeaponConfig.getSprayOffset(c, #c.spray)
	assert(clamped == lastReal, "spray deve clampar na última bala")
	return true
end

return WeaponConfig
