-- Who a poke is aimed at: of the players (and your Time Trial's dummies) within `range`, roughly
-- where the camera faces and in plain sight, the one nearest the middle of your view. The server
-- checks every poke again (server/CombatPoke), so this only decides who you meant.
local Players = game:GetService("Players")

local AimAssist = {}
local player = Players.LocalPlayer

-- Returns the target (a Player, or a dummy's id), how far it is on the flat, and the flat
-- direction to it; or nil.
function AimAssist.target(range)
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not me or not camera then
		return nil
	end
	local look = camera.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.01 then
		return nil
	end
	look = look.Unit
	local yard = workspace:FindFirstChild("PracticeYard_" .. player.UserId) -- your Time Trial's dummies
	local skip, candidates = {}, {}
	local inRound = player:GetAttribute("InRound") == true
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(skip, p.Character)
		local root = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and (not inRound or p:GetAttribute("InRound") == true) then
			table.insert(candidates, { p, root.Position, 0 })
		end
	end
	for _, m in ipairs(yard and yard:GetChildren() or {}) do
		local post = m:GetAttribute("DummyId") and not m:GetAttribute("Out") and m.PrimaryPart
		if post then
			table.insert(skip, m)
			table.insert(candidates, { m:GetAttribute("DummyId"), post.Position, 1.5 })
		end
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, skip, true
	local best, bestDot, bestDist, bestDir = nil, 0.3, nil, nil
	for _, c in ipairs(candidates) do
		local offset = c[2] - me.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local dot = if flat.Magnitude < 0.5 then 1 else look:Dot(flat.Unit)
		if flat.Magnitude <= range + c[3] and math.abs(offset.Y) <= 6 and dot > bestDot then
			local from = camera.CFrame.Position
			if not workspace:Raycast(from, c[2] - from, params) then
				best, bestDot, bestDist, bestDir = c[1], dot, flat.Magnitude, if flat.Magnitude > 0.1 then flat.Unit else look
			end
		end
	end
	return best, bestDist, bestDir
end

return AimAssist
