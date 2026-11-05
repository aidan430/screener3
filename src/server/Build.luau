-- Helpers for building the world out of simple anchored parts.
local Build = {}

function Build.rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- spec: name, size (Vector3), cframe, color ({r, g, b} or Color3), material ("Wood"),
-- shape ("Ball" | "Cylinder"), collide (default true), shadow (default true), transparency, class
function Build.part(spec)
	local p = Instance.new(spec.class or "Part")
	p.Name = spec.name or "Part"
	p.Anchored = true
	if spec.shape then
		p.Shape = Enum.PartType[spec.shape]
	end
	p.Size = spec.size
	p.CFrame = spec.cframe
	if typeof(spec.color) == "Color3" then
		p.Color = spec.color
	elseif spec.color then
		p.Color = Build.rgb(spec.color)
	end
	p.Material = Enum.Material[spec.material or "SmoothPlastic"]
	p.CanCollide = spec.collide ~= false
	p.CastShadow = spec.shadow ~= false
	p.Transparency = spec.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = spec.parent
	return p
end

-- A standing cylinder: bottom centre at `base` (CFrame), `height` tall.
function Build.post(spec, base, height, diameter)
	spec.shape = "Cylinder"
	spec.size = Vector3.new(height, diameter, diameter)
	spec.cframe = base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	return Build.part(spec)
end

-- A gable roof: a block turned 45 degrees, its lower half hidden inside the walls.
-- `top` is the CFrame of the ridge line's centre at wall height; the ridge runs along Z.
function Build.roof(spec, top, width, depth)
	local side = width / math.sqrt(2)
	spec.size = Vector3.new(side, side, depth)
	spec.cframe = top * CFrame.Angles(0, 0, math.rad(45))
	return Build.part(spec)
end

-- Text on one face of a part. Returns the TextLabel.
function Build.text(part, face, text, options)
	options = options or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = options.pixels or 40
	gui.LightInfluence = 0.6
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = options.font or Enum.Font.FredokaOne
	label.TextColor3 = options.color or Color3.fromRGB(58, 38, 22)
	label.TextWrapped = true
	label.Parent = gui
	return label
end

return Build
