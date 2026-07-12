-- src/client/CharacterAnimator/init.luau
-- Anima o PRÓPRIO personagem da facção (replica via Animator). Uma origem só de
-- animação (inclusive death). Camadas: Movement (locomoção) + Action (upper-body).
-- Ver docs/superpowers/specs/2026-07-12-personagem-faccao-design.md

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local PistolAnims = require(ReplicatedStorage.Shared.PistolAnims)
local Remotes = require(ReplicatedStorage.Shared.CharacterRemotes)
local StateResolver = require(script.StateResolver)

-- camadas Action escalonadas: tiro/recarga vencem a mira (senao se misturam na media)
local UPPER_PRIORITY = {
	aimUpper = Enum.AnimationPriority.Action,
	shootUpper = Enum.AnimationPriority.Action3,
	reloadUpper = Enum.AnimationPriority.Action2,
}

local CharacterAnimator = {}

local state = { crouching = false, slowWalk = false, aiming = false }
local tracks: { [string]: AnimationTrack } = {}

local function sendState()
	Remotes.MovementState:FireServer(state)
end

local function loadTracks(animator: Animator)
	table.clear(tracks)
	for key, id in PistolAnims do
		if typeof(id) ~= "string" or id == "" then
			continue
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = UPPER_PRIORITY[key] or Enum.AnimationPriority.Movement
			tracks[key] = track
		else
			warn("[CharacterAnimator] falhou carregar anim:", key)
		end
	end
end

local function onCharacter(char: Model)
	if not char:GetAttribute("FactionRig") then
		return -- avatar padrão (ex: BOPE): não anima
	end
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
	loadTracks(animator)

	-- 1ª pessoa: o engine já esconde o corpo do dono conforme o zoom (automático)

	-- morte: dono toca a death (uma origem de animação só) [spec v2]
	humanoid.Died:Connect(function()
		for _, t in tracks do
			t:Stop(0.1)
		end
		local death = tracks.death
		if death then
			death.Looped = false
			death:Play(0.1)
		end
	end)

	local current: string? = nil
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if humanoid.Health <= 0 or char.Parent == nil then
			conn:Disconnect()
			return
		end
		local moveDir = humanoid.MoveDirection
		local localDir = hrp.CFrame:VectorToObjectSpace(moveDir)
		local hState = humanoid:GetState()
		local target = StateResolver.resolve({
			speed = moveDir.Magnitude * humanoid.WalkSpeed,
			forward = -localDir.Z,
			side = localDir.X,
			aiming = state.aiming,
			crouching = state.crouching,
			slowWalk = state.slowWalk,
			airborne = hState == Enum.HumanoidStateType.Jumping
				or hState == Enum.HumanoidStateType.Freefall,
		})
		if target ~= current then
			-- crouchIdle usa a MESMA track do crouchWalk, congelada (truque da refém)
			local function trackFor(name)
				return name == "crouchIdle" and tracks.crouchWalk or tracks[name]
			end
			local oldT = current and trackFor(current)
			local newT = trackFor(target)
			if oldT ~= newT then
				if oldT then
					oldT:Stop(0.2)
				end
				if newT then
					newT.Looped = true
					newT:Play(0.15)
				end
			end
			if newT then
				if target == "crouchIdle" then
					newT.TimePosition = 0 -- frame neutro (pés juntos)
					newT:AdjustSpeed(0) -- congela agachado
				else
					newT:AdjustSpeed(1)
				end
			end
			current = target
		end
	end)
end

function CharacterAnimator.start()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.defer(onCharacter, player.Character)
	end

	ContextActionService:BindAction("FactionCrouch", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			state.crouching = true
			sendState()
		elseif inputState == Enum.UserInputState.End then
			state.crouching = false
			sendState()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftControl, Enum.KeyCode.C) -- C tambem: Ctrl+clique vira botao direito no macOS

	-- modelo CS: Shift = andar devagar (nao sprint)
	ContextActionService:BindAction("FactionWalk", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			state.slowWalk = true
			sendState()
		elseif inputState == Enum.UserInputState.End then
			state.slowWalk = false
			sendState()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift)
end

-- ==== hooks chamados pelo Input da arma (uma via só, sem duplicar lógica) ====

function CharacterAnimator.setAiming(aiming: boolean)
	state.aiming = aiming
	sendState()
	local t = tracks.aimUpper or tracks.aim
	if not t then
		return
	end
	if aiming then
		t.Looped = true
		t:Play(0.15)
	else
		t:Stop(0.2)
	end
end

function CharacterAnimator.onShot()
	local t = tracks.shootUpper or tracks.shooting
	if t then
		t.Looped = false
		t:Play(0.05)
	end
end

function CharacterAnimator.onReload()
	local t = tracks.reloadUpper or tracks.reload
	if t then
		t.Looped = false
		t:Play(0.1)
	end
end

return CharacterAnimator
