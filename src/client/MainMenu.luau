-- Menu principal — Fase 1: casca visual estilo lobby FPS (ver docs/menu-plan.md).
-- Overlay por cima do cenário 3D: barra embaixo + painéis laterais (molde).
-- Só JOGAR funciona; o resto mostra "EM BREVE" até o sistema de cada um existir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local COLORS = {
	panel = Color3.fromRGB(16, 20, 28),
	border = Color3.fromRGB(55, 65, 80),
	text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(150, 160, 175),
	play = Color3.fromRGB(64, 160, 72),
	pill = Color3.fromRGB(24, 28, 36),
	accent = Color3.fromRGB(190, 40, 40),
}
local TITLE_FONT = Enum.Font.GothamBold
local BODY_FONT = Enum.Font.Gotham

-- Botões da barra de baixo. Só JOGAR habilitado nesta fase.
local BOTTOM = {
	{ name = "INVENTÁRIO", enabled = false },
	{ name = "LOADOUT", enabled = false },
	{ name = "JOGAR", enabled = true, play = true },
	{ name = "LOJA", enabled = false },
	{ name = "MODOS", enabled = false },
}

local MainMenu = {}
local toastLabel

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(radius, parent)
	make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(color, thickness, parent)
	make("UIStroke", { Color = color, Thickness = thickness }, parent)
end

-- Mostra "EM BREVE" no centro por 1.5s (feedback pras abas sem sistema).
local function toast(text)
	if not toastLabel then
		return
	end
	toastLabel.Text = text
	toastLabel.TextTransparency = 0
	TweenService:Create(toastLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3), {
		TextTransparency = 1,
	}):Play()
end

-- Painel escuro com título (molde pros widgets futuros).
local function panel(title, size, anchor, pos, parent)
	local frame = make("Frame", {
		Name = title,
		BackgroundColor3 = COLORS.panel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AnchorPoint = anchor,
		Position = pos,
		Size = size,
	}, parent)
	corner(8, frame)
	stroke(COLORS.border, 1, frame)

	make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -28, 0, 22),
		Font = TITLE_FONT,
		Text = title,
		TextColor3 = COLORS.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	make("TextLabel", {
		Name = "Soon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, -20, 0, 24),
		Font = BODY_FONT,
		Text = "🔒 EM BREVE",
		TextColor3 = COLORS.dim,
		TextSize = 15,
	}, frame)

	return frame
end

local function bottomButton(tab, parent)
	local isPlay = tab.play == true
	local btn = make("TextButton", {
		Name = tab.name,
		LayoutOrder = 0,
		BackgroundColor3 = isPlay and COLORS.play or COLORS.pill,
		BackgroundTransparency = isPlay and 0 or 0.15,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = isPlay and UDim2.new(0, 220, 0, 60) or UDim2.new(0, 160, 0, 48),
		Font = TITLE_FONT,
		Text = tab.name,
		TextColor3 = COLORS.text,
		TextSize = isPlay and 24 or 16,
	}, parent)
	corner(6, btn)
	if not isPlay then
		stroke(COLORS.border, 1, btn)
	end

	local baseTransparency = btn.BackgroundTransparency
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = math.max(0, baseTransparency - 0.15) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = baseTransparency }):Play()
	end)

	return btn
end

function MainMenu.mount()
	local player = Players.LocalPlayer
	local gui = make("ScreenGui", {
		Name = "MainMenuGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))

	-- Toast central (usado pelas abas sem sistema).
	toastLabel = make("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.35, 0),
		Size = UDim2.new(0, 400, 0, 40),
		Font = TITLE_FONT,
		Text = "",
		TextColor3 = COLORS.text,
		TextSize = 22,
		TextTransparency = 1,
	}, gui)

	-- Painéis-molde (laterais).
	panel("NOTÍCIAS", UDim2.new(0, 300, 0, 180), Vector2.new(0, 0), UDim2.new(0, 24, 0, 90), gui)
	panel("MISSÕES", UDim2.new(0, 360, 0, 300), Vector2.new(1, 0), UDim2.new(1, -24, 0, 90), gui)

	-- Ícones canto superior direito (cosmético).
	local topRight = make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 20),
		Size = UDim2.new(0, 120, 0, 50),
	}, gui)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, topRight)
	for _, sym in { "⚙", "⌂" } do
		local b = make("TextButton", {
			BackgroundColor3 = COLORS.pill,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 50, 0, 50),
			Font = TITLE_FONT,
			Text = sym,
			TextColor3 = COLORS.text,
			TextSize = 24,
		}, topRight)
		corner(8, b)
		stroke(COLORS.border, 1, b)
		b.MouseButton1Click:Connect(function()
			toast("🔒 EM BREVE")
		end)
	end

	-- Barra de baixo.
	local bar = make("Frame", {
		Name = "BottomBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0, 900, 0, 64),
	}, gui)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
	}, bar)

	local requestTeleport = ReplicatedStorage:WaitForChild("RequestTeleport", 10)

	for i, tab in BOTTOM do
		local btn = bottomButton(tab, bar)
		btn.LayoutOrder = i
		if tab.play then
			btn.MouseButton1Click:Connect(function()
				if not requestTeleport then
					warn("RequestTeleport não encontrado")
					return
				end
				btn.Text = "ENTRANDO..."
				btn.Active = false
				local ok, err = requestTeleport:InvokeServer()
				if not ok then
					warn("Teleporte falhou:", err)
					btn.Text = "JOGAR"
					btn.Active = true
				end
			end)
		else
			btn.MouseButton1Click:Connect(function()
				toast(tab.name .. " · 🔒 EM BREVE")
			end)
		end
	end

	return gui
end

return MainMenu
