-- RefemNPC.server.lua
-- FONTE DE REFERÊNCIA — o script real vive em Workspace.refem_meshy_char.NPCController (dentro do place).
-- NÃO é sincronizado pelo Rojo de propósito: ele precisa estar DENTRO do model da refém (usa script.Parent).
--
-- Sistema da refém (hostage):
--  - ProximityPrompt "E": Resgatar/Soltar
--  - Resgatada: segue o policial andando (anim walk mocap), para a FOLLOW_DIST studs
--  - Policial escoltando tem WalkSpeed reduzido pra 10 (não corre)
--  - Solta: agacha (anim crouch) e congela no fundo do agachamento (frame 26 = 0.83s)
--  - Raycast contínuo mantém os pés no chão (offset calibrado no spawn)
--
-- Animações publicadas (conta wbgam9):
--  walk   = rbxassetid://99605968645296  (Meshy mocap, 32 frames, fix de afundamento)
--  crouch = rbxassetid://124524860483241 (air_squat, 58 frames)
--
-- Pipeline dos assets: Meshy (auto-rig + mocap) -> Blender 5.1 (decimate 10k,
-- fix slot de action p/ export FBX, fix de afundamento do quadril) -> Studio 3D Import (Custom rig).

local RunService = game:GetService("RunService")
local refem = script.Parent
local mesh = refem:WaitForChild("char1")
local controller = refem:WaitForChild("AnimationController")
local animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", controller)

-- animacoes publicadas
local walkAnim = Instance.new("Animation"); walkAnim.AnimationId = "rbxassetid://99605968645296"
local crouchAnim = Instance.new("Animation"); crouchAnim.AnimationId = "rbxassetid://124524860483241"
local walk = animator:LoadAnimation(walkAnim); walk.Looped = true
local crouch = animator:LoadAnimation(crouchAnim); crouch.Looped = false

-- prompt E
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Resgatar"
prompt.ObjectText = "Refem"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = mesh

local SPEED = 6
local FOLLOW_DIST = 6
local CROUCH_FREEZE_T = 0.83  -- fundo do agachamento (frame 26)

local followTarget = nil
local crouched = false
local walkPlaying = false
local savedSpeed = {}

-- offset de altura calibrado (preserva o ajuste fino do chao)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {refem}
local p0 = refem:GetPivot().Position
local hit0 = workspace:Raycast(p0, Vector3.new(0,-50,0), rayParams)
local groundOffset = hit0 and (p0.Y - hit0.Position.Y) or 2.75

local function setCrouch(on)
    if on and not crouched then
        crouched = true
        if walkPlaying then walk:Stop(0.2); walkPlaying = false end
        crouch:Play(0.2)
        crouch:AdjustSpeed(1)
        task.spawn(function()
            while crouched and crouch.IsPlaying and crouch.TimePosition < CROUCH_FREEZE_T do
                task.wait(0.03)
            end
            if crouched and crouch.IsPlaying then crouch:AdjustSpeed(0) end -- congela agachada
        end)
    elseif (not on) and crouched then
        crouched = false
        crouch:Stop(0.3)
    end
end

prompt.Triggered:Connect(function(player)
    local ch = player.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if followTarget == player then
        -- SOLTAR: agacha e espera
        followTarget = nil
        prompt.ActionText = "Resgatar"
        setCrouch(true)
        if hum and savedSpeed[player.UserId] then
            hum.WalkSpeed = savedSpeed[player.UserId]
            savedSpeed[player.UserId] = nil
        end
    else
        -- RESGATAR: segue o policial (que nao pode correr escoltando)
        followTarget = player
        prompt.ActionText = "Soltar"
        setCrouch(false)
        if hum then
            savedSpeed[player.UserId] = hum.WalkSpeed
            hum.WalkSpeed = 10 -- escolta a passo; regra anti-corrida
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not followTarget or crouched then return end
    local ch = followTarget.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myPos = refem:GetPivot().Position
    local flat = Vector3.new(hrp.Position.X - myPos.X, 0, hrp.Position.Z - myPos.Z)
    local dist = flat.Magnitude

    if dist > FOLLOW_DIST then
        local step = math.min(SPEED*dt, dist - FOLLOW_DIST)
        local dir = flat.Unit
        local newPos = myPos + dir*step
        local hit = workspace:Raycast(newPos + Vector3.new(0,8,0), Vector3.new(0,-60,0), rayParams)
        local y = hit and (hit.Position.Y + groundOffset) or myPos.Y
        local target = Vector3.new(hrp.Position.X, y, hrp.Position.Z)
        refem:PivotTo(CFrame.lookAt(Vector3.new(newPos.X, y, newPos.Z), target))
        if not walkPlaying then walk:Play(0.15); walkPlaying = true end
    else
        if walkPlaying then walk:Stop(0.25); walkPlaying = false end
        -- fica de frente pro policial
        refem:PivotTo(CFrame.lookAt(myPos, Vector3.new(hrp.Position.X, myPos.Y, hrp.Position.Z)))
    end
end)

print("[Refem] sistema pronto: E=resgatar/soltar, segue andando, agacha ao soltar")
