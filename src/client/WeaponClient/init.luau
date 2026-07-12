-- src/client/WeaponClient/init.luau
-- Orquestra o combate no cliente. Trava 1ª pessoa em código [R7] (não no project.json).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))
local Viewmodel = require(script:WaitForChild("Viewmodel"))
local Recoil = require(script:WaitForChild("Recoil"))
local Effects = require(script:WaitForChild("Effects"))
local Aim = require(script:WaitForChild("Aim"))
local Input = require(script:WaitForChild("Input"))
local HUD = require(script:WaitForChild("HUD"))

local WeaponClient = {}

function WeaponClient.start()
	local player = Players.LocalPlayer
	local DEBUG_THIRD_PERSON = false -- true = destrava a camera pra ver o proprio corpo (debug de anims)
	if not DEBUG_THIRD_PERSON then
		player.CameraMode = Enum.CameraMode.LockFirstPerson -- [R7]
	end

	local viewmodel = Viewmodel.new()
	local recoil = Recoil.new(WeaponConfig.Rifle, viewmodel)
	local effects = Effects.new(viewmodel.part, WeaponConfig.Rifle)
	local aim = Aim.new(WeaponConfig.Rifle, viewmodel)
	Input.start(WeaponConfig.Rifle, recoil, effects, aim)
	HUD.start(WeaponConfig.Rifle, function(serverAmmo)
		if Input.setLocalMag then
			Input.setLocalMag(serverAmmo)
		end
	end)

	WeaponClient.viewmodel = viewmodel
	WeaponClient.recoil = recoil
	WeaponClient.effects = effects
	WeaponClient.aim = aim
	WeaponClient.input = Input
end

return WeaponClient
