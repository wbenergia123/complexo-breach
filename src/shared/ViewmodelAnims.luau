-- src/shared/ViewmodelAnims.luau
-- Asset IDs das animações do viewmodel 1ª pessoa (braços+pistola do pack FPS).
-- Rig: ReplicatedStorage.ViewmodelRig (ossos J** — renomeados contra bug do
-- importador de jun/2026 que inverte rotação de ossos com nomes padrão).
-- Mapa osso original -> J** em assets/viewmodel_bone_map.json (mão direita = J53).

return {
	-- pack Akito (GhostWire): ossos J**, arma Base=J51/Slide=J52/Mag=J53 (assets/akito_bone_map.json)
	idle = "129974690939308", -- "pistola 2" (15/jul/2026)
	-- o pack tem prontas no viewmodel_akito_base.blend: Reload, Shoot, Take (equip)
	-- pack antigo (backup ServerStorage.ViewmodelRig_pistol_v1_backup): idle=108388516293596
}
