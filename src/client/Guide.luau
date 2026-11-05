-- When your tool and bucket are full, a soft golden line runs from you to your trader's
-- basket, so you always know the way. It fades once you've dumped.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local Guide = {}

local function basket()
	local plot = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local built = plot and plots and plots:FindFirstChild("Plot" .. plot) and plots["Plot" .. plot]:FindFirstChild("Built")
	for _, model in ipairs(built and built:GetChildren() or {}) do
		if model:GetAttribute("Item") == "trader" then
			return model:FindFirstChild("Basket")
		end
	end
	return nil
end

function Guide.start()
	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0.2) })
	beam.Width0, beam.Width1 = 0.25, 0.6
	beam.LightEmission = 0.6
	beam.FaceCamera = true
	beam.Segments = 20
	beam.CurveSize0, beam.CurveSize1 = 4, -4
	beam.Enabled = false
	local from = Instance.new("Attachment")
	local to = Instance.new("Attachment")
	beam.Attachment0, beam.Attachment1 = from, to
	beam.Parent = workspace.Terrain
	to.Parent = workspace.Terrain
	task.spawn(function()
		while true do
			task.wait(0.5)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local target = basket()
			local carried, capacity = player:GetAttribute("Carried") or 0, player:GetAttribute("Capacity") or 1
			local show = root ~= nil and target ~= nil and carried >= capacity
			if show then
				if from.Parent == nil or not from:IsDescendantOf(workspace) then -- after a respawn
					from = Instance.new("Attachment")
					beam.Attachment0 = from
				end
				from.Parent = root
				from.Position = Vector3.new(0, -1.5, 0)
				to.WorldPosition = target.Position + Vector3.new(0, 2, 0)
			end
			beam.Enabled = show
		end
	end)
end

return Guide
