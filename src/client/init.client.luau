-- Entrada do cliente. Só monta o menu + câmera no place inicial (lobby);
-- nos outros places (mapa, futuros mapas) fica inerte.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

if game.PlaceId == Config.StartPlaceId then
	local MainMenu = require(script:WaitForChild("MainMenu"))
	local LobbyCamera = require(script:WaitForChild("LobbyCamera"))
	MainMenu.mount()
	LobbyCamera.start()
elseif game.PlaceId == Config.FavelaPlaceId then
	local CharacterAnimator = require(script:WaitForChild("CharacterAnimator"))
	CharacterAnimator.start()
	local WeaponClient = require(script:WaitForChild("WeaponClient"))
	WeaponClient.start()
end
