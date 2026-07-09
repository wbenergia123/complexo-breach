-- src/client/WeaponClient/HUD.luau
-- Mira + munição (valor AUTORITATIVO do servidor [R2]) + hitmarker [R1].

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = require(game.ReplicatedStorage.Shared.WeaponRemotes)

local HUD = {}

function HUD.start(cfg, onAmmoFromServer)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WeaponHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- crosshair
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(4, 4)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = gui

	-- munição
	local ammo = Instance.new("TextLabel")
	ammo.AnchorPoint = Vector2.new(1, 1)
	ammo.Position = UDim2.new(1, -24, 1, -100)
	ammo.Size = UDim2.fromOffset(160, 40)
	ammo.BackgroundTransparency = 1
	ammo.Font = Enum.Font.GothamBold
	ammo.TextColor3 = Color3.fromRGB(240, 240, 245)
	ammo.TextXAlignment = Enum.TextXAlignment.Right
	ammo.TextSize = 28
	ammo.Text = tostring(cfg.ammo.magazine) .. " / " .. tostring(cfg.ammo.reserve)
	ammo.Parent = gui

	-- hitmarker
	local hm = Instance.new("TextLabel")
	hm.AnchorPoint = Vector2.new(0.5, 0.5)
	hm.Position = UDim2.fromScale(0.5, 0.5)
	hm.Size = UDim2.fromOffset(40, 40)
	hm.BackgroundTransparency = 1
	hm.Font = Enum.Font.GothamBold
	hm.Text = "✕"
	hm.TextSize = 24
	hm.TextColor3 = Color3.fromRGB(255, 80, 80)
	hm.TextTransparency = 1
	hm.Parent = gui

	local reserve = cfg.ammo.reserve
	Remotes.ShotFx.OnClientEvent:Connect(function(data)
		if not data or not data.selfShot then
			return
		end
		if data.ammo then
			reserve = data.reserve or reserve
			ammo.Text = tostring(data.ammo) .. " / " .. tostring(reserve)
			if onAmmoFromServer then
				onAmmoFromServer(data.ammo) -- reconcilia predição do Input [R2]
			end
		end
		if data.hit then
			hm.TextColor3 = data.headshot and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(255, 80, 80)
			hm.TextTransparency = 0
			TweenService:Create(hm, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		end
	end)

	return HUD
end

return HUD
