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

-- NOTA: o loop que reescalava e reorganizava os meshes num grid foi removido.
-- Ele era uma ferramenta de organização inicial (uso único) e estava embaralhando
-- a favela toda a cada Play. O posicionamento agora é definido direto na cena.
