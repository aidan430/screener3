-- Number formatting for the UI. Plain Luau: no Roblox services.
local Format = {}

-- 5000000 -> "5,000,000"
function Format.commas(n)
	local digits = string.format("%.0f", math.floor(math.abs(n)))
	local grouped = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	if string.sub(grouped, 1, 1) == "," then
		grouped = string.sub(grouped, 2)
	end
	if n < 0 then
		return "-" .. grouped
	end
	return grouped
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 1234 -> "1.23K", 5000000 -> "5M", 950 -> "950"
function Format.short(n)
	local value = math.abs(n)
	if value < 1000 then
		return tostring(math.floor(n))
	end
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local text
	if value >= 100 then
		text = string.format("%.0f", value)
	elseif value >= 10 then
		text = string.format("%.1f", value)
	else
		text = string.format("%.2f", value)
	end
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return (if n < 0 then "-" else "") .. text .. SUFFIXES[index]
end

return Format
