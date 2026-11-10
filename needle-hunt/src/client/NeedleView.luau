-- A needle in 3D inside the UI: a ViewportFrame with the needle (shared/NeedleLook) lit and
-- framed, tilted a little so its shape reads. spin = true turns it slowly (the reveal popup).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))

local NeedleView = {}

function NeedleView.make(parent, typeId, skinId, props, spin)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency, vp.Ambient, vp.LightColor, vp.LightDirection = 1, Color3.fromRGB(150, 150, 160), Color3.new(1, 1, 1), Vector3.new(-0.4, -1, -0.6)
	for k, v in pairs(props or {}) do
		vp[k] = v
	end
	local model = NeedleLook.build(typeId, skinId, 1, 2.2) -- thickened to read well at UI size
	for _, shell in ipairs(model:GetChildren()) do -- an Heirloom's aura: particles don't draw in a
		if shell.Name == "AuraShell" then -- ViewportFrame, so its energy skin becomes a soft glow here
			shell.Material, shell.Transparency = Enum.Material.Neon, 0.8
		end
	end
	model:PivotTo(CFrame.Angles(0, 0, math.rad(25)))
	model.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, 5.4), Vector3.zero)
	camera.Parent = vp
	vp.CurrentCamera = camera
	vp.Parent = parent
	if spin then
		local turn = 0
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			if not vp.Parent then
				conn:Disconnect()
				return
			end
			turn += dt * 0.9
			model:PivotTo(CFrame.Angles(0, turn, math.rad(25)))
		end)
	end
	return vp
end

return NeedleView
