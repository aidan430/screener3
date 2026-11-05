-- Builds a case's clues from where the needle is hidden. Every clue is true of the needle's
-- haystack and rules some others out; the last clue names a trace only one place could leave.
-- Plain Luau: no Roblox services.
local Clues = {}

local FACTS = {
	water = {
		[true] = "The straw around the needle was damp. It was hidden near water.",
		[false] = "The straw around the needle was bone dry, far from any water.",
	},
	building = {
		[true] = "A farmhand heard it drop right next to a building.",
		[false] = "It was dropped out in the open, away from every building.",
	},
	animals = {
		[true] = "Animal tracks lead straight to the hiding place.",
		[false] = "No animal has been anywhere near the hiding place.",
	},
}

local function textFor(attribute, value)
	if attribute == "side" then
		return "Someone saw a glint on the " .. value .. " side of the farm."
	end
	return FACTS[attribute][value]
end

function Clues.ids(piles)
	local ids = {}
	for _, pile in ipairs(piles) do
		table.insert(ids, pile.id)
	end
	return ids
end

-- piles: the list from Piles.json. pick(n) returns a whole number from 1 to n.
-- Returns { {text = string, possible = {pile ids still possible}}, ... }
function Clues.generate(piles, needleId, pick)
	local needle = nil
	for _, pile in ipairs(piles) do
		if pile.id == needleId then
			needle = pile
		end
	end
	assert(needle ~= nil, "no haystack called " .. tostring(needleId))

	local attributes = { "side", "water", "building", "animals" }
	for i = #attributes, 2, -1 do
		local j = pick(i)
		attributes[i], attributes[j] = attributes[j], attributes[i]
	end

	local candidates = table.clone(piles)
	local clues = {}
	for _, attribute in ipairs(attributes) do
		local keep = {}
		for _, pile in ipairs(candidates) do
			if pile[attribute] == needle[attribute] then
				table.insert(keep, pile)
			end
		end
		-- a useful clue rules something out but leaves the final answer to the last clue
		if #keep < #candidates and #keep >= 2 then
			candidates = keep
			table.insert(clues, { text = textFor(attribute, needle[attribute]), possible = Clues.ids(keep) })
		end
	end
	table.insert(clues, { text = "Stuck to the thread: " .. needle.trace .. ".", possible = { needle.id } })
	return clues
end

return Clues
