-- The portal worlds on your own screen: each world's light eased in on arrival (and the farm's
-- eased back on return), its name on screen, low gravity on the Moon, the lava's gentle nudge
-- back to the bank, the fish of Bubble City, the portal prompts' words and the stadium
-- scoreboard. The server decides unlocking, travel and every coin (server/Worlds.luau).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local Worlds = {}
local byId = {}
for _, w in ipairs(Config.Worlds) do
	byId[w.id] = w
end

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- The light as one flat table, so a fade can ease every value together.
local function read()
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	return {
		clock = Lighting.ClockTime, brightness = Lighting.Brightness, ambient = Lighting.Ambient, outdoor = Lighting.OutdoorAmbient, shift = Lighting.ColorShift_Top,
		density = atmo and atmo.Density, color = atmo and atmo.Color, decay = atmo and atmo.Decay, haze = atmo and atmo.Haze, glare = atmo and atmo.Glare,
	}
end

local function mood(id)
	local m = Config.WorldMoods[id]
	return { clock = m.clock, brightness = m.brightness, ambient = rgb(m.ambient), outdoor = rgb(m.outdoor), shift = rgb(m.shift), density = m.density, color = rgb(m.color), decay = rgb(m.decay), haze = m.haze, glare = m.glare }
end

local function write(a, b, e)
	local function mix(x, y)
		if typeof(x) == "Color3" then
			return x:Lerp(y, e)
		end
		return x + (y - x) * e
	end
	local delta = ((b.clock - a.clock + 12) % 24) - 12 -- the short way round the clock: no sudden noon
	Lighting.ClockTime = (a.clock + delta * e) % 24
	Lighting.Brightness = mix(a.brightness, b.brightness)
	Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ColorShift_Top = mix(a.ambient, b.ambient), mix(a.outdoor, b.outdoor), mix(a.shift, b.shift)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and a.density and b.density then
		atmo.Density, atmo.Haze, atmo.Glare = mix(a.density, b.density), mix(a.haze, b.haze), mix(a.glare, b.glare)
		atmo.Color, atmo.Decay = mix(a.color, b.color), mix(a.decay, b.decay)
	end
end

local farm = nil -- the farm's light, kept while you're away
local fade = nil -- { from, to, start, done }
local function fadeTo(target, done)
	fade = { from = read(), to = target, start = os.clock(), done = done }
end

local function worldAt(position)
	for _, w in ipairs(Config.Worlds) do
		local flat = Vector3.new(position.X - w.x, 0, position.Z - w.z)
		if flat.Magnitude < Config.WorldInside then
			return w
		end
	end
	return nil
end

-- Moon gravity: a VectorForce lifting part of your weight.
local lift = nil
local function setLift(root)
	if not root then
		if lift then
			lift.force:Destroy()
			lift.attachment:Destroy()
			lift = nil
		end
		return
	end
	if not lift or lift.force.Parent ~= root then
		setLift(nil)
		local attachment = Instance.new("Attachment")
		attachment.Name = "MoonLiftAttachment"
		attachment.Parent = root
		local force = Instance.new("VectorForce")
		force.Name = "MoonLift"
		force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ApplyAtCenterOfMass = true
		force.Parent = root
		lift = { force = force, attachment = attachment }
	end
	lift.force.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * Config.MoonLift, 0)
end

-- Lava: standing on it hops you gently back towards the nearer bank.
local lastPush, lastToast = 0, 0
local function lavaCheck(root, character, notify)
	if os.clock() - lastPush < Config.LavaPush.every then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), params)
	local part = hit and hit.Instance
	if not part or part:GetAttribute("Lava") ~= true then
		return
	end
	lastPush = os.clock()
	local rel = part.CFrame:PointToObjectSpace(root.Position)
	local dir = if part.Size.X <= part.Size.Z then part.CFrame.RightVector * (if rel.X >= 0 then 1 else -1) else part.CFrame.LookVector * (if rel.Z >= 0 then -1 else 1)
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.3 then -- a round pool: straight out from its middle
		dir = Vector3.new(root.Position.X - part.Position.X, 0, root.Position.Z - part.Position.Z)
	end
	dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.xAxis
	root.AssemblyLinearVelocity = dir * Config.LavaPush.out + Vector3.new(0, Config.LavaPush.up, 0)
	if os.clock() - lastToast > Config.LavaPush.toastEvery then
		lastToast = os.clock()
		notify.toast("Warm toes! The lava nudges you back to the bank.", Ui.colors.wood)
	end
end

-- Bubble City's fish swim slow circles (only drawn moving while you're there).
local function swim(folder)
	local t = os.clock()
	for _, fish in ipairs(folder:GetChildren()) do
		local r, h, speed, phase = fish:GetAttribute("Radius"), fish:GetAttribute("Height"), fish:GetAttribute("Speed"), fish:GetAttribute("Phase")
		if fish:IsA("Model") and r and h and speed and phase then
			local w = byId.atlantis
			local a = phase + speed * t
			local p = Vector3.new(w.x + math.cos(a) * r, h + math.sin(t * 0.6 + phase) * 1.5, w.z + math.sin(a) * r)
			local heading = Vector3.new(-math.sin(a), 0, math.cos(a)) * (if speed >= 0 then 1 else -1)
			fish:PivotTo(CFrame.lookAt(p, p + heading))
		end
	end
end

-- The portal prompts say "Travel" once open, or the price until then.
local function promptWords(root)
	for _, prompt in ipairs(root:GetDescendants()) do
		local w = prompt:IsA("ProximityPrompt") and prompt:GetAttribute("Action") == "portal" and byId[prompt:GetAttribute("World")]
		if w then
			prompt.ActionText = if player:GetAttribute("World_" .. w.id) then "Travel" else "Open for " .. Format.short(w.price) .. " coins"
		end
	end
end

local function scoreText(root)
	local label = root:FindFirstChild("field") and root.field:FindFirstChild("ScoreText", true)
	if label and label:IsA("TextLabel") then
		local needles = player:GetAttribute("WorldNeedles_field") or 0
		local straws = player:GetAttribute("WorldStraws_field") or 0
		label.Text = "YOUR WORLD SCORE\n" .. Format.commas(needles) .. " NEEDLE" .. (if needles == 1 then "" else "S") .. "  |  " .. Format.commas(straws) .. " STRAWS"
	end
end

function Worlds.start(gui, notify)
	local title = Ui.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.26), Size = UDim2.new(0.8, 0, 0, 70), TextTransparency = 1, TextStrokeTransparency = 1, Parent = gui }, 64)
	local subtitle = Ui.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.26, 52), Size = UDim2.new(0.8, 0, 0, 30), TextTransparency = 1, TextStrokeTransparency = 1, TextColor3 = Ui.colors.hay, Parent = gui }, 26)
	local titleToken = 0
	local function showTitle(text, sub)
		titleToken += 1
		local token = titleToken
		title.Text, subtitle.Text = text, sub
		for _, label in ipairs({ title, subtitle }) do
			Juice.ease(label, 1, { TextTransparency = 0, TextStrokeTransparency = 0.4 })
		end
		task.delay(Config.WorldTitleSeconds, function()
			if token == titleToken then
				for _, label in ipairs({ title, subtitle }) do
					Juice.ease(label, 1.2, { TextTransparency = 1, TextStrokeTransparency = 1 })
				end
			end
		end)
	end

	local root = workspace:FindFirstChild("Worlds")
	task.spawn(function() -- (never hold up the other parts of the screen while waiting)
		root = root or workspace:WaitForChild("Worlds", 60)
		if root then
			promptWords(root)
			scoreText(root)
		end
	end)
	for _, w in ipairs(Config.Worlds) do
		player:GetAttributeChangedSignal("World_" .. w.id):Connect(function()
			if root then
				promptWords(root)
			end
		end)
	end
	for _, name in ipairs({ "WorldNeedles_field", "WorldStraws_field" }) do
		player:GetAttributeChangedSignal(name):Connect(function()
			if root then
				scoreText(root)
			end
		end)
	end

	local inside = nil
	RunService.Heartbeat:Connect(function()
		if fade then
			local t = math.clamp((os.clock() - fade.start) / Config.WorldFadeSeconds, 0, 1)
			write(fade.from, fade.to, (1 - math.cos(math.pi * t)) / 2)
			if t >= 1 then
				local done = fade.done
				fade = nil
				if done then
					done()
				end
			end
		end
		local character = player.Character
		local body = character and character:FindFirstChild("HumanoidRootPart")
		if not body then
			setLift(nil)
			return
		end
		local here = worldAt(body.Position)
		if here ~= inside then
			inside = here
			if here then
				farm = farm or read()
				fadeTo(mood(here.id))
				showTitle(here.name, "Hay pays " .. here.multiplier .. "x here. Find this world's own needle!")
			elseif farm then
				fadeTo(farm, function()
					farm = nil
				end)
				showTitle(Config.FarmName, "Welcome home.")
			end
		end
		setLift(if here and here.id == "moon" then body else nil)
		if here and here.id == "lava" then
			lavaCheck(body, character, notify)
		end
	end)
	RunService.RenderStepped:Connect(function()
		local fish = inside and inside.id == "atlantis" and root and root:FindFirstChild("atlantis") and root.atlantis:FindFirstChild("Fish")
		if fish then
			swim(fish)
		end
	end)

	Remotes.Announce.OnClientEvent:Connect(function(message)
		if message.kind ~= "worldneedle" then
			return
		end
		if message.finderId == player.UserId then
			Juice.confetti()
			notify.banner("YOU FOUND THE NEEDLE ON " .. string.upper(message.name) .. "!", "You earned " .. Format.short(message.prize) .. " coins. A fresh haystack with a new needle is waiting.", 10)
		else
			notify.toast(message.finder .. " found the needle on " .. message.name .. "!", Ui.colors.hay)
		end
	end)
end

return Worlds
