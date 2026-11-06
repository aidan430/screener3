-- Animated skins, drawn on every screen for every equipped skinned tool (Tools.make sets the
-- tool's "Skin" attribute). From each skin's Config.Wheel entry: `flow` slides the pattern along
-- the tool (Lava's cracks run down it, Candy Cane's stripes roll like a barber's pole), `pulse`
-- slowly swells and fades its glow, and `gleam` sweeps a soft shine along it every few seconds.
-- Twinkles are particles the server adds. Everything eases; nothing flashes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SkinFx = {}
local skins = {}
for _, prize in ipairs(Config.Wheel) do
	skins[prize.id] = prize
end
local cache = setmetatable({}, { __mode = "k" }) -- [tool] = its textures, glow and gleam light

-- What to move on a tool, found once.
local function parts(tool, skin)
	local found = cache[tool]
	if found then
		return found
	end
	local handle = tool:FindFirstChild("Handle")
	found = { textures = {}, glow = handle and handle:FindFirstChild("SkinGlow") }
	for _, item in ipairs(tool:GetDescendants()) do
		if item:IsA("Texture") then
			table.insert(found.textures, item)
		end
	end
	if found.glow then
		found.base = found.glow.Brightness
	end
	if skin.gleam and handle then
		local size = handle.Size -- the shine runs along the handle's longest side
		local axis = if size.Z > size.Y then Vector3.zAxis * size.Z elseif size.X > size.Y then Vector3.xAxis * size.X else Vector3.yAxis * size.Y
		local spot = Instance.new("Attachment")
		spot.Name = "SkinGleam"
		spot.Parent = handle
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(skin.head[1], skin.head[2], skin.head[3]):Lerp(Color3.new(1, 1, 1), 0.6)
		light.Range, light.Brightness = 3, 0
		light.Parent = spot
		found.gleam, found.spot, found.axis = light, spot, axis
	end
	cache[tool] = found
	return found
end

local function animate(tool, skin, t)
	local p = parts(tool, skin)
	if skin.flow and #p.textures > 0 then
		local u = (t * skin.flow[1]) % Config.SkinTextureStuds
		local v = (t * skin.flow[2]) % Config.SkinTextureStuds
		for _, texture in ipairs(p.textures) do
			texture.OffsetStudsU, texture.OffsetStudsV = u, v
		end
	end
	if skin.pulse and p.glow then
		p.glow.Brightness = p.base * (1 + skin.pulse * math.sin(t * math.pi * 2 / Config.SkinPulseSeconds))
	end
	if p.gleam then
		local phase = (t % skin.gleam) / Config.SkinGleamSeconds -- 0..1 while the shine runs
		if phase < 1 then
			p.spot.Position = p.axis * (phase - 0.5)
			p.gleam.Brightness = 2.5 * math.sin(phase * math.pi)
		else
			p.gleam.Brightness = 0
		end
	end
end

function SkinFx.start()
	local wait = 0
	RunService.RenderStepped:Connect(function(dt)
		wait += dt
		if wait < 1 / 30 then
			return
		end
		wait = 0
		local t = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
			local skin = tool and skins[tool:GetAttribute("Skin") or ""]
			if skin then
				animate(tool, skin, t)
			end
		end
	end)
end

return SkinFx
