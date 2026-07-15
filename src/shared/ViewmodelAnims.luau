-- src/shared/ViewmodelAnims.luau
-- Asset IDs das animações do viewmodel 1ª pessoa (braços+pistola do pack FPS).
-- Rig: ReplicatedStorage.ViewmodelRig (ossos J** — renomeados contra bug do
-- importador de jun/2026 que inverte rotação de ossos com nomes padrão).
-- Mapa osso original -> J** em assets/viewmodel_bone_map.json (mão direita = J53).

return {
	idle = "108388516293596", -- "pistola idle" (15/jul/2026)
	-- próximas: fire, reload, aim, walk, run, equip (mesmo pipeline do idle)
}
