-- Plays a story cinematic (shared/Cinematics): wide black bars ease in, the scene's title fades
-- up and away, and the camera glides through the shots, holding the last one while the
-- characters talk. Cinematic.stop() glides the camera back to you and lifts the bars. Only your
-- own screen's camera moves; nothing in the game pauses.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cinematics = require(Shared:WaitForChild("Cinematics"))
local HeapTerrain = require(Shared:WaitForChild("HeapTerrain"))(Config)
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local Cinematic = {}
local bars, titleLabel = nil, nil
local running = 0 -- a token: a newer scene (or stop) ends the older one's glide

-- The anchor's frame: world positions for offsets in a cinematic.
local function anchorOf(kind)
	if kind == "heap" then
		local plot = player:GetAttribute("Plot")
		local centre = plot and Config.PlotCentres[plot]
		if centre then
			return CFrame.new(HeapTerrain.origin(centre[1], centre[2]))
		end
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		return CFrame.lookAt(root.Position, root.Position + (if look.Magnitude > 0 then look else Vector3.new(0, 0, -1)))
	end
	return nil
end

local function point(anchor, v)
	return anchor * Vector3.new(v[1], v[2], v[3])
end

local function smooth(t)
	return t * t * (3 - 2 * t)
end

function Cinematic.mount(gui)
	bars = {}
	for i, y in ipairs({ 0, 1 }) do
		bars[i] = Ui.make("Frame", { AnchorPoint = Vector2.new(0, y), Position = UDim2.fromScale(0, y), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(14, 10, 6), BorderSizePixel = 0, ZIndex = 40, Parent = gui })
	end
	titleLabel = Ui.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.new(0.7, 0, 0, 48), TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 41, Parent = gui }, 40)
end

-- Starts a cinematic by name, with `title` faded up over it. Returns false if there's none.
function Cinematic.play(name, title)
	local scene = Cinematics[name]
	local camera = workspace.CurrentCamera
	if not scene or not camera or not bars or Config.CinematicsOn == false then
		return false
	end
	local anchor = anchorOf(scene.anchor)
	if not anchor then
		return false
	end
	running += 1
	local token = running
	for _, bar in ipairs(bars) do
		Juice.ease(bar, 0.8, { Size = UDim2.new(1, 0, 0.1, 0) })
	end
	if title then
		titleLabel.Text = title
		Juice.ease(titleLabel, 1.2, { TextTransparency = 0, TextStrokeTransparency = 0.6 })
		task.delay(3.5, function()
			Juice.ease(titleLabel, 1.2, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	task.spawn(function()
		local start = camera.CFrame -- glide in from wherever the camera was
		for i, shot in ipairs(scene.shots) do
			local from, to = point(anchor, shot.from), point(anchor, shot.to)
			local look, lookTo = point(anchor, shot.look), point(anchor, shot.lookTo)
			local t, centre = 0, point(anchor, shot.look)
			while t < shot.time and running == token do
				t += RunService.RenderStepped:Wait()
				local k = smooth(math.clamp(t / shot.time, 0, 1))
				local at
				if shot.around then -- swing round the look point, keeping the distance
					local a, b = from - centre, to - centre
					local from0 = math.atan2(a.X, a.Z)
					local delta = (math.atan2(b.X, b.Z) - from0 + math.pi) % (2 * math.pi) - math.pi -- the short way round
					local turn = from0 + delta * k
					local flat = Vector3.new(a.X, 0, a.Z).Magnitude * (1 - k) + Vector3.new(b.X, 0, b.Z).Magnitude * k
					at = centre + Vector3.new(math.sin(turn) * flat, a.Y + (b.Y - a.Y) * k, math.cos(turn) * flat)
				else
					at = from:Lerp(to, k)
				end
				local goal = CFrame.lookAt(at, look:Lerp(lookTo, k))
				camera.CFrame = if i == 1 and t < 1.2 then start:Lerp(goal, smooth(t / 1.2)) else goal
			end
			if running ~= token then
				return
			end
		end
	end)
	return true
end

-- Ends the cinematic: the camera glides back behind your eyes and the bars lift.
function Cinematic.stop()
	running += 1
	local camera = workspace.CurrentCamera
	for _, bar in ipairs(bars or {}) do
		Juice.ease(bar, 0.8, { Size = UDim2.new(1, 0, 0, 0) })
	end
	if titleLabel then
		titleLabel.TextTransparency = 1
	end
	if camera and camera.CameraType == Enum.CameraType.Scriptable then
		local head = player.Character and player.Character:FindFirstChild("Head")
		if head then
			local from, t = camera.CFrame, 0
			local back = CFrame.lookAt(head.Position, head.Position + head.CFrame.LookVector)
			while t < 0.9 do
				t += RunService.RenderStepped:Wait()
				camera.CFrame = from:Lerp(back, smooth(math.clamp(t / 0.9, 0, 1)))
			end
		end
		camera.CameraType = Enum.CameraType.Custom
	end
end

return Cinematic
