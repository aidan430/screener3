-- The poke, the Power Poke and the Thimble on your own device (Config.Combo, Power, Guard, Lunge,
-- Knock), and what a hit feels like. The server decides every hit (server/CombatPoke).
--   Poke: click (R2, a tap). It goes at once, at whoever client/AimAssist says you meant, and
--     carries you a little way towards them (the lunge).
--   Power Poke: keep holding. A ring at the reticle closes as it charges and turns gold when it's
--     full; let go then for 2 hearts and a longer lunge. Letting go early cancels it.
--   Thimble: hold R (L2, or the GUARD button): a silver bubble blocks pokes and throws.
--   A hit you land: a marker round the reticle. A hit you take: a small camera kick and a push back.
-- "Reduce effects" in Settings turns the kick off. Nothing flashes.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local AimAssist = require(script.Parent.AimAssist)
local Mover = require(script.Parent.Mover)
local StanceFx = require(script.Parent.StanceFx)
local ViewModel = require(script.Parent.ViewModel)

local player = Players.LocalPlayer
local MovesFx = {}
MovesFx.lastPoke = -math.huge -- when you last poked (client/CooldownBars)
local C, P, G, L = Config.Combat, Config.Power, Config.Guard, Config.Lunge
local held, pressId, chargeStart = false, 0, nil
local ring, marker, silver
local kick = 0
local bubbles = {}

local function pokeReady()
	return workspace:GetServerTimeNow() >= (player:GetAttribute("PokeAt") or 0) - 0.05 and not player:GetAttribute("NeedleAway") and not player:GetAttribute("Guarding")
end

local function poke(power)
	local target, distance, dir = AimAssist.target(C.reach + (if power then L.powerRange else L.range))
	MovesFx.lastPoke = os.clock()
	Remotes.Poke:FireServer(if typeof(target) == "Instance" then target.UserId else target, if power then true else nil)
	ViewModel.play("jab")
	Effects.sound("whoosh", if power then 1.2 else 1.6)
	if target and distance > L.from then -- the lunge: only towards someone
		local speed = if power then L.powerSpeed else L.speed
		Mover.push(dir, speed, speed, math.min(if power then L.powerSeconds else L.seconds, (distance - L.from) / speed))
	end
end

local function endCharge(release)
	if chargeStart then
		local full = os.clock() - chargeStart >= P.charge
		chargeStart = nil
		ring.Visible = false
		StanceFx.slow("charge", nil)
		if release and full then
			poke(true)
		else
			Remotes.Charge:FireServer(false)
		end
	end
end

-- The poke button went down (the Needle tool's Activated).
function MovesFx.press()
	held = true
	pressId += 1
	local id = pressId
	if pokeReady() and os.clock() - MovesFx.lastPoke > 0.2 then
		poke(false)
	end
	task.delay(P.hold, function() -- still holding: charge, once the poke is ready again
		while held and pressId == id and not chargeStart do
			if pokeReady() and os.clock() - MovesFx.lastPoke >= P.hold then
				chargeStart = os.clock()
				Remotes.Charge:FireServer(true)
				StanceFx.slow("charge", P.slow)
				ring.Visible = true
				break
			end
			task.wait(0.05)
		end
	end)
end

-- The poke button came up (the tool's Deactivated).
function MovesFx.release()
	held = false
	endCharge(true)
end

local function guard(on)
	Remotes.Guard:FireServer(on)
	if on then
		endCharge(false)
	end
end

-- A hit: Remotes.Hit's message (client/CombatFx passes it on).
function MovesFx.hit(m)
	local mine, me = m.from == player.UserId, m.to == player.UserId
	local dir = if typeof(m.dir) == "Vector3" then m.dir else Vector3.zero
	if mine then -- the marker: white, orange for 2 hearts, gold for a tag-out, grey if blocked
		local colour = if m.result == "blocked" then Color3.fromRGB(170, 174, 184) elseif m.hearts == 0 then UiKit.colors.gold elseif (m.amount or 1) > 1 then Color3.fromRGB(255, 150, 60) else Color3.new(1, 1, 1)
		for _, bar in ipairs(marker:GetChildren()) do
			bar.BackgroundColor3, bar.BackgroundTransparency = colour, 0
			UiKit.ease(bar, 0.22, { BackgroundTransparency = 1 })
		end
		Effects.sound("click", if m.result == "blocked" then 2 else 1.4)
		if m.result == "blocked" then
			Mover.push(-dir, Config.Knock.blocked[1], Config.Knock.blocked[2], Config.Knock.blocked[3]) -- bounced off the Thimble
		end
	end
	if me and m.result ~= "blocked" then
		local k = Config.Knock[if m.kind == "power" then "power" elseif m.kind == "throw" then "throw" elseif m.combo == 2 then "combo" else "poke"]
		Mover.push(dir, k[1], k[2], k[3])
		if not Effects.settings.reduceEffects then
			kick = if m.kind == "power" then 3.5 else 2.5
		end
	end
end

function MovesFx.start(gui)
	Mover.start()
	local mid = { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = gui }
	ring = UiKit.make("Frame", { AnchorPoint = mid.AnchorPoint, Position = mid.Position, Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, Visible = false, ZIndex = 6, Parent = gui }, { UiKit.corner(32), UiKit.stroke(Color3.new(1, 1, 1), 3) })
	marker = UiKit.make("Frame", { AnchorPoint = mid.AnchorPoint, Position = mid.Position, Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, ZIndex = 6, Parent = gui })
	for i = 0, 3 do -- four short bars in an X
		local a = math.rad(45 + i * 90)
		UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.cos(a) * 16, 0.5, math.sin(a) * 16), Size = UDim2.fromOffset(12, 3), Rotation = 45 + i * 90, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = marker })
	end
	silver = UiKit.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 39, Parent = gui }, { UiKit.stroke(Color3.fromRGB(200, 208, 222), 10) })
	silver:FindFirstChildOfClass("UIStroke").Transparency = 1
	local button = UiKit.button("Guard (R)", UiKit.colors.card, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -366), Size = UDim2.fromOffset(150, 46), Visible = UserInputService.TouchEnabled, Parent = gui })
	UiKit.autoScale(button)
	button.MouseButton1Down:Connect(function()
		guard(true)
	end)
	button.MouseButton1Up:Connect(function()
		guard(false)
	end)
	ContextActionService:BindAction("Thimble", function(_, state)
		if state == Enum.UserInputState.Begin then
			guard(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			guard(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonL2)
	player:GetAttributeChangedSignal("Guarding"):Connect(function()
		local up = player:GetAttribute("Guarding") == true
		StanceFx.slow("guard", if up then G.slow else nil)
		UiKit.ease(silver:FindFirstChildOfClass("UIStroke"), 0.1, { Transparency = if up then 0.5 else 1 })
	end)
	player:GetAttributeChangedSignal("Charging"):Connect(function() -- the server ended your charge (you were hit)
		if not player:GetAttribute("Charging") and chargeStart and os.clock() - chargeStart > 0.3 then
			chargeStart = nil
			ring.Visible = false
			StanceFx.slow("charge", nil)
		end
	end)
	RunService:BindToRenderStep("MovesFx", Enum.RenderPriority.Camera.Value + 2, function(dt)
		if chargeStart then -- the ring closes as the charge fills, gold and steady when full
			local f = math.clamp((os.clock() - chargeStart) / P.charge, 0, 1)
			ring.Size = UDim2.fromOffset(64 - 24 * f, 64 - 24 * f)
			ring:FindFirstChildOfClass("UIStroke").Color = if f >= 1 then UiKit.colors.gold else Color3.new(1, 1, 1)
			if os.clock() - chargeStart >= P.charge + P.auto then
				endCharge(true) -- held too long: it goes by itself
			end
		end
		if kick > 0.01 then -- a hit taken: the view tips up a touch and settles
			local camera = workspace.CurrentCamera
			camera.CFrame *= CFrame.Angles(math.rad(kick), 0, 0)
			kick *= math.exp(-14 * dt)
		end
		for _, p in ipairs(Players:GetPlayers()) do -- a silver bubble round anyone behind a Thimble
			local root = p:GetAttribute("Guarding") and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			local bubble = bubbles[p]
			if root and not bubble then
				bubble = UiKit.make("Part", { Shape = Enum.PartType.Ball, Size = Vector3.one * 6, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(210, 216, 228), Transparency = 0.8, Parent = workspace })
				bubbles[p] = bubble
			end
			if bubble and root then
				bubble.CFrame = root.CFrame
			elseif bubble then
				bubble:Destroy()
				bubbles[p] = nil
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if bubbles[p] then
			bubbles[p]:Destroy()
			bubbles[p] = nil
		end
	end)
end

return MovesFx
