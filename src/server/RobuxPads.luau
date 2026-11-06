-- The Robux corner: one round pad per Robux item (Config.RobuxPads), in two arcs beside where
-- you arrive. The server builds the plain, anchored pads and looks up each item's icon and
-- price; client/RobuxPads.luau adds the hologram, the gentle colours and the purchase prompt.
-- Purchases are granted by Monetization.luau as before; nothing here grants anything.
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Build = require(script.Parent.Build)

local RobuxPads = {}

local function idOf(entry)
	local list = if entry.kind == "pass" then Config.GamePasses else Config.Products
	return list and list[entry.key] or 0
end

-- Icon and price from Roblox. Either can be missing (unpublished place, Roblox busy): the
-- client then shows the pad's name with "Robux" in place of a price.
local function lookUp(model, entry, id)
	local infoType = if entry.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
	for attempt = 1, 3 do
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and type(info) == "table" then
			local icon = tonumber(info.IconImageAssetId)
			if icon and icon > 0 then
				model:SetAttribute("Icon", "rbxassetid://" .. icon)
			end
			local price = tonumber(info.PriceInRobux)
			if price and price > 0 then
				model:SetAttribute("Price", price)
			end
			if type(info.Name) == "string" then
				model:SetAttribute("RobloxName", info.Name)
			end
			return
		end
		task.wait(5 * attempt)
	end
	warn("[RobuxPads] Couldn't look up " .. entry.key .. " (" .. id .. "); its pad shows no icon or price.")
end

local function pad(folder, entry, id, origin, facing)
	local size = Config.RobuxPadSize
	local at = origin + Vector3.new(entry.at[1], 0, entry.at[2])
	local look = Vector3.new(facing.X, at.Y, facing.Z)
	local cf = if (look - at).Magnitude > 0.1 then CFrame.lookAt(at, look) else CFrame.new(at)
	local model = Instance.new("Model")
	model.Name = entry.key
	-- the platform: a low disc you step up onto (0.8 studs, an easy step)
	local base = Build.part({ name = "Top", shape = "Cylinder", size = Vector3.new(0.8, size, size), cframe = cf * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 46, 52, 70 }, material = "SmoothPlastic", parent = model })
	-- the glowing ring round its edge (the client eases its colour round the rainbow)
	Build.part({ name = "Ring", shape = "Cylinder", size = Vector3.new(0.5, size + 0.8, size + 0.8), cframe = cf * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 150, 200, 255 }, material = "Neon", collide = false, shadow = false, parent = model })
	-- a soft inner glow under the hologram
	Build.part({ name = "Glow", shape = "Cylinder", size = Vector3.new(0.1, size - 1.6, size - 1.6), cframe = cf * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 170, 220, 255 }, material = "Neon", transparency = 0.6, collide = false, shadow = false, parent = model })
	-- where the floating panel hangs (invisible; the client puts the hologram on it)
	local anchor = Build.part({ name = "Panel", size = Vector3.new(1, 1, 1), cframe = cf * CFrame.new(0, Config.RobuxPadPanelHeight, 0), transparency = 1, collide = false, shadow = false, parent = model })
	local light = Instance.new("PointLight")
	light.Brightness = 0.8
	light.Range = 10
	light.Color = Color3.fromRGB(170, 210, 255)
	light.Shadows = false
	light.Parent = anchor
	-- the fallback: E (or the prompt's tap button) does what stepping on does
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if entry.key == "WheelSpin" then "See the odds" else "Look"
	prompt.ObjectText = entry.key
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = size
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", "robuxpad")
	prompt.Parent = base
	model.PrimaryPart = base
	model:SetAttribute("Kind", entry.kind)
	model:SetAttribute("Key", entry.key)
	model:SetAttribute("ItemId", id)
	model:SetAttribute("Radius", size / 2)
	model.Parent = folder
	task.spawn(lookUp, model, entry, id)
end

function RobuxPads.build()
	local old = workspace:FindFirstChild("RobuxPads")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "RobuxPads"
	local e, f = Config.FarmEntrance, Config.RobuxPadFacing
	local origin = Vector3.new(e[1], e[2], e[3])
	local facing = origin + Vector3.new(f[1], 0, f[2])
	for _, entry in ipairs(Config.RobuxPads) do
		local id = idOf(entry)
		if type(id) == "number" and id ~= 0 then
			pad(folder, entry, id, origin, facing)
		end
	end
	folder.Parent = workspace
end

return RobuxPads
