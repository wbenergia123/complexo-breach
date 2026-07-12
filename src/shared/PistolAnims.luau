-- src/shared/PistolAnims.luau
-- Asset IDs das animacoes 3a pessoa do traficante com pistola (X9-72).
-- Rig skinned mesh (mixamorig). Receita: GLB combinado COM textura + quadril zerado.
-- IDs antigos descartados (publicados achatados, sem material). Preencher com os novos.

local PistolAnims = {
	walk = "118994148781397", -- andar frente, in-place (republicada no chao)

	idle = "82412506128041", -- parado com pistola, balanco leve

	walkBackward = "99977691939254", -- andar de re, in-place

	strafeLeft = "138240181010490", -- andar de lado esquerda, in-place

	strafeRight = "138969032480135", -- andar de lado direita, in-place

	run = "124991916385940", -- corrida com pistola, in-place

	aim = "74750174341868", -- mira (ADS), braco levantado

	shooting = "91521736289252", -- recuo do tiro

	reload = "123143172339652", -- trocar o pente

	jump = "84800716124182", -- impulso do pulo (fisica faz o arco no codigo)

	kneelingIdle = "136143780114629", -- agachado parado (1 joelho no chao), quadril baixado 1.59

	crouchWalk = "84627411262067", -- agachado andando frente (quadril baixado 0.76); REVER grip com arma na mao

	crouchBack = "96428077598429", -- agachado andando de re (quadril baixado 0.81)

	crouchLeft = "126149355963348", -- agachado de lado esquerda (quadril baixado 0.84)

	crouchRight = "125379093970600", -- agachado de lado direita (quadril baixado 0.85)

	death = "76863593900265", -- morte (headshot), corpo cai colado no chao (quadril baixado frame-a-frame)
}

return PistolAnims
