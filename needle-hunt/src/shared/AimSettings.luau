-- The aim settings a player can choose (Config.Aim), and the check every saved value goes through
-- (server/DataManager on load, server/Requests on save): numbers are clamped to their range and
-- step, and shapes and colours must be on the list. Anything else is ignored.
local Config = require(script.Parent.Config)

local AimSettings = {}
local A = Config.Aim

AimSettings.defaults = {
	sensitivity = A.sensitivity[4], fov = A.fov[4], reticleSize = A.reticleSize[4], reticleThickness = A.reticleThickness[4],
	reticleOpacity = A.reticleOpacity[4], reticleOutlineThickness = A.reticleOutlineThickness[4],
	reticle = A.reticles[1], reticleColour = A.colours[1][1], reticleOutline = A.outlines[1],
}
local NUMBERS = { sensitivity = true, fov = true, reticleSize = true, reticleThickness = true, reticleOpacity = true, reticleOutlineThickness = true }

local function listed(list, value, at)
	for _, row in ipairs(list) do
		if (if at then row[at] else row) == value then
			return true
		end
	end
	return false
end

-- The value to keep for `key`, or nil if it isn't an aim setting or the value isn't allowed.
function AimSettings.clean(key, value)
	if NUMBERS[key] then
		local r = A[key]
		if type(value) ~= "number" or value ~= value then
			return nil
		end
		value = math.clamp(value, r[1], r[2])
		return math.floor((value - r[1]) / r[3] + 0.5) * r[3] + r[1]
	elseif key == "reticle" then
		return if type(value) == "string" and listed(A.reticles, value) then value else nil
	elseif key == "reticleOutline" then
		return if type(value) == "string" and listed(A.outlines, value) then value else nil
	elseif key == "reticleColour" then
		return if type(value) == "string" and listed(A.colours, value, 1) then value else nil
	end
	return nil
end

function AimSettings.colour(name)
	for _, row in ipairs(A.colours) do
		if row[1] == name then
			return Color3.fromRGB(row[2], row[3], row[4])
		end
	end
	return Color3.new(1, 1, 1)
end

return AimSettings
