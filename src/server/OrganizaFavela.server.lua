-- Future Lighting
local Lighting = game:GetService("Lighting")
Lighting.Technology = Enum.Technology.Future
Lighting.Brightness = 2
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(70, 70, 80)
Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 110)

-- Atmosfera
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(199, 199, 199)
atmosphere.Decay = Color3.fromRGB(100, 100, 100)
atmosphere.Glare = 0.1
atmosphere.Haze = 1
atmosphere.Parent = Lighting

-- Bloom
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.3
bloom.Size = 24
bloom.Threshold = 0.95
bloom.Parent = Lighting

-- Color correction
local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness = 0
cc.Contrast = 0.1
cc.Saturation = 0.1
cc.TintColor = Color3.fromRGB(255, 245, 230)
cc.Parent = Lighting

print("Future Lighting ativado!")

-- Organiza e escala todos os models/meshes do workspace
local targetSize = 60
local cols = 5
local spacing = 80
local index = 0

for _, parent in ipairs(workspace:GetChildren()) do
	if parent:IsA("Model") and parent.Name ~= "Camera" and parent.Name ~= "Terrain" and parent.Name ~= "Baseplate" then
		for _, obj in ipairs(parent:GetDescendants()) do
			if obj:IsA("MeshPart") then
				index += 1
				local maxDim = math.max(obj.Size.X, obj.Size.Y, obj.Size.Z)
				if maxDim > 0 then
					obj.Size = obj.Size * (targetSize / maxDim)
				end
				local col = (index - 1) % cols
				local row = math.floor((index - 1) / cols)
				local pos = CFrame.new(col * spacing, 10, row * spacing)
				if parent.Name == "pack_meshy" then
					obj:PivotTo(pos * CFrame.Angles(math.rad(90), 0, 0))
				else
					obj:PivotTo(pos)
				end
			end
		end
	end
end
print("Pronto! " .. index .. " meshes organizados.")
