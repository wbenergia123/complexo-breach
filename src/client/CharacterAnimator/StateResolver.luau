-- src/client/CharacterAnimator/StateResolver.luau
-- Resolve o estado de animação a partir de um snapshot. PURO (testável).
-- Prioridade: airborne > crouch > aim parado > locomoção.
-- Convenção: forward > 0 = frente, side > 0 = direita (chamador converte
-- MoveDirection pro espaço da HRP). Campos ausentes = false/0.

local StateResolver = {}

function StateResolver.resolve(input)
	local speed = input.speed or 0
	local forward = input.forward or 0
	local side = input.side or 0
	local moving = speed > 0.5

	if input.airborne then
		return "jump"
	end

	if input.crouching then
		if not moving then
			-- estilo CS: agachado parado = MESMA postura do crouchWalk (congelada
			-- pelo animator via AdjustSpeed 0). Kneeling profundo fica pra poses futuras.
			return "crouchIdle"
		end
		if math.abs(side) > math.abs(forward) then
			return side > 0 and "crouchRight" or "crouchLeft"
		end
		return forward < 0 and "crouchBack" or "crouchWalk"
	end

	if not moving then
		return input.aiming and "aim" or "idle"
	end

	if math.abs(side) > math.abs(forward) then
		return side > 0 and "strafeRight" or "strafeLeft"
	end
	if forward < 0 then
		return "walkBackward"
	end
	-- modelo CS: base = corrida; Shift/mira = andar
	if input.slowWalk or input.aiming then
		return "walk"
	end
	return "run"
end

function StateResolver.runChecks()
	local r = StateResolver.resolve
	assert(r({}) == "idle", "vazio = idle")
	assert(r({ speed = 16, forward = 1 }) == "run", "frente = corrida (base CS)")
	assert(r({ speed = 10, forward = 1, slowWalk = true }) == "walk", "shift = andar devagar")
	assert(r({ speed = 10, forward = 1, aiming = true }) == "walk", "mirando anda (nao corre)")
	assert(r({ speed = 10, forward = -1 }) == "walkBackward", "re")
	assert(r({ speed = 10, side = 1 }) == "strafeRight", "direita")
	assert(r({ speed = 10, side = -1 }) == "strafeLeft", "esquerda")
	assert(r({ aiming = true }) == "aim", "mira parado")
	assert(r({ crouching = true }) == "crouchIdle", "agachado parado (postura do walk congelada)")
	assert(r({ speed = 6, forward = 1, crouching = true }) == "crouchWalk", "agachado frente")
	assert(r({ speed = 6, forward = -1, crouching = true }) == "crouchBack", "agachado re")
	assert(r({ speed = 6, side = 1, crouching = true }) == "crouchRight", "agachado dir")
	assert(r({ speed = 6, side = -1, crouching = true }) == "crouchLeft", "agachado esq")
	assert(r({ speed = 10, forward = 1, airborne = true }) == "jump", "no ar = jump")
	assert(r({ speed = 6, forward = 1, crouching = true, aiming = true }) == "crouchWalk", "crouch vence aim")
	return true
end

return StateResolver
