-- Every number you might want to tune lives here. Change it, rebuild, play-test.
-- This module requires nothing, so the server, the client and the checks can all read it.
local Config = {}

Config.Title = "Needle in the Haystack"
Config.FarmName = "Hollow Creek Farm"

-- Plots: each player gets one, with their own pile. Four per server, around the hub.
Config.PlotSize = 140
Config.PlotCentres = { { 85, 85 }, { -85, 85 }, { -85, -85 }, { 85, -85 } }

-- The heap: 5,000,000 straws in clumps, one smooth terrain haystack 80 studs (22 m) high and
-- 88 across: steep sides and a rounded top, like a beehive haystack.
-- Each clump is one 4-stud terrain cell (the terrain grid size, so keep ClumpSize = 4).
Config.TotalStraws = 5000000
Config.Clumps = 5000 -- each holds TotalStraws / Clumps = 1,000 straws
Config.ClumpSize = 4
Config.PileLayers = 20 -- 20 layers x 4 studs = 80 studs
Config.PileRadiusBottom = 44
Config.PileRadiusTop = 4
-- radius at height share t: top + (bottom - top) x (1 - t ^ PileDome) ^ PileCurve
Config.PileDome = 2.5 -- above 1: the sides stay wide for longer, then round over
Config.PileCurve = 0.7 -- below 1: a fuller, rounder top
Config.HeapColour = { 222, 186, 92 } -- straw gold (the terrain Grass material is the heap)
-- Your hay texture: upload garden-hay.jpg (and its normal map) in Studio (Asset Manager > Import),
-- paste the IDs here ("rbxassetid://123"), rebuild. The heap, the hay on tools and the bundles
-- then wear it. Empty = plain straw-gold Grass.
Config.HayTexture = "rbxassetid://92326825877863"
Config.HayNormal = ""
Config.HayTextureStuds = 3 -- how many studs one copy of the texture covers
-- The hay model you imported and uploaded (a Model or a mesh ID): lumps on tools, flying hay,
-- bundles, bales' neighbours and the mounds round the heap use it. 0 = rounded hay balls.
Config.HayModel = 0
-- Or a bare mesh ID and its texture (used only if HayModel is 0 or doesn't load).
Config.HayMesh = ""
Config.HayMeshTexture = ""
Config.HayTint = { 255, 246, 225 }
-- The fields and plot floors (terrain and parts of the LeafyGrass material), the same way.
Config.GroundTexture = "rbxassetid://92652087782912" -- the owner's grass (gltf_embedded_2)
Config.GroundNormal = "rbxassetid://81088945047843" -- its normal map (gltf_embedded_3)
Config.GroundTextureStuds = 6
Config.GroundTint = { 230, 236, 210 } -- the ground's colour with the texture on
Config.HeapMounds = 16 -- loose hay mounds round the foot of each heap (just for looks) -- the heap's colour with the texture on (white = the image as is)
Config.MaxSlopeAngle = 46 -- players can't walk up anything steeper: they build to climb
-- The needle hides deep inside the upper heap: between these shares of the height, and no
-- further from the middle than this share of the heap's width there. Machines peel the heap
-- from the outside in, so they reach it last; climbing up and digging in finds it sooner.
Config.NeedleHeight = { 0.5, 0.8 }
Config.NeedleCore = 0.4
Config.Reach = 18 -- studs from your head to a clump you can harvest
Config.SearchCooldown = 0.3 -- seconds between harvests (the Swift perk shortens it)
Config.MerchantRange = 16

Config.CoinsPerStraw = 1

-- Tools: power = straws per click, capacity = straws you can carry before selling.
-- Any tool can wear a model imported in Studio: model = its asset ID, length = studs long. It's
-- held straight out in front, working end forward. flip = false if it points backwards,
-- roll = degrees to turn it about its length (so a scoop faces up), bladeTop = studs from the
-- middle of the blade to where hay sits on it, loadAt = how far along the hay sits (0..0.5),
-- loadSize = how big the hay on it gets. Without a model a tool is built as a pitchfork.
Config.Tools = {
	{ name = "Garden Trowel", model = 139238222017221, length = 3, power = 1, capacity = 300, price = 0, shaft = { 112, 82, 58 }, head = { 128, 98, 78 }, material = "CorrodedMetal" },
	{ name = "Wooden Pitchfork", power = 2, capacity = 1000, price = 400, shaft = { 160, 116, 72 }, head = { 176, 128, 82 }, material = "Wood" },
	{ name = "Iron Pitchfork", power = 3, capacity = 2500, price = 2400, shaft = { 150, 108, 66 }, head = { 165, 170, 178 }, material = "Metal" },
	{ name = "Steel Rake", power = 5, capacity = 5000, price = 10000, shaft = { 120, 84, 50 }, head = { 190, 196, 204 }, material = "Metal" },
	{ name = "Golden Rake", power = 7, capacity = 9000, price = 40000, shaft = { 120, 84, 50 }, head = { 245, 200, 66 }, material = "Metal" },
	{ name = "Hay Blower", power = 9, capacity = 18000, price = 120000, shaft = { 70, 72, 84 }, head = { 232, 92, 60 }, material = "SmoothPlastic" },
	{ name = "Super Sifter", power = 12, capacity = 32000, price = 320000, shaft = { 60, 64, 78 }, head = { 90, 200, 255 }, material = "Neon" },
	{ name = "Magnet Gloves", power = 15, capacity = 50000, price = 800000, shaft = { 200, 200, 210 }, head = { 220, 40, 40 }, material = "SmoothPlastic" },
	{ name = "Twin Turbines", power = 19, capacity = 75000, price = 1700000, shaft = { 40, 44, 52 }, head = { 255, 170, 40 }, material = "Metal" },
	{ name = "Needle Detector", power = 22, capacity = 100000, price = 3400000, shaft = { 40, 44, 52 }, head = { 70, 255, 150 }, material = "Neon" },
}
Config.DetectorLevel = 10
Config.LoadSize = 2.4 -- studs across the hay on a full tool

-- Buckets hang at your hip and carry what the tool can't: tool fills first, then the bucket.
Config.Buckets = {
	{ name = "No bucket", capacity = 0, price = 0, size = 0 },
	{ name = "Tin Pail", capacity = 600, price = 1500, size = 1.2 },
	{ name = "Hay Bucket", capacity = 2000, price = 9000, size = 1.6 },
	{ name = "Big Tub", capacity = 6000, price = 60000, size = 2 },
	{ name = "Hay Barrel", capacity = 20000, price = 400000, size = 2.4 },
	{ name = "Giant Basket", capacity = 60000, price = 2500000, size = 2.8 },
} -- from this tool on, the HUD shows how close the needle is

-- The silo on your plot holds what your machines harvest until you next sell.
Config.Silos = {
	{ name = "Hay Shed", size = 2000, price = 0 },
	{ name = "Small Silo", size = 10000, price = 15000 },
	{ name = "Big Silo", size = 40000, price = 150000 },
	{ name = "Twin Silos", size = 150000, price = 1000000 },
	{ name = "Grain Tower", size = 500000, price = 5000000 },
}

-- Machines harvest the top of your pile into the silo, while you're in the game, if your
-- generators make enough power. rate = straws a second, draw = power used.
Config.Machines = {
	{ id = "hen", name = "Clockwork Hen", rate = 0.15, draw = 2, price = 1600, max = 10, size = { 4, 4, 4 }, color = { 236, 180, 70 } },
	{ id = "sieve", name = "Sorting Sieve", rate = 0.6, draw = 6, price = 20000, max = 10, size = { 5, 5, 5 }, color = { 150, 150, 160 } },
	{ id = "thresher", name = "Steam Thresher", rate = 1.5, draw = 12, price = 160000, max = 8, size = { 6, 6, 6 }, color = { 90, 70, 60 } },
	{ id = "vacuum", name = "Hay Vacuum", rate = 3.6, draw = 24, price = 900000, max = 6, size = { 7, 7, 7 }, color = { 200, 80, 60 } },
	{ id = "magnetron", name = "Needle Magnetron", rate = 7.5, draw = 45, price = 4000000, max = 4, size = { 8, 8, 8 }, color = { 70, 255, 150 } },
}

-- Generators power the machines. power = units made.
Config.Generators = {
	{ id = "crank", name = "Hand-Crank Dynamo", power = 4, price = 1200, max = 10, size = { 4, 4, 4 }, color = { 140, 110, 80 } },
	{ id = "diesel", name = "Diesel Generator", power = 15, price = 15000, max = 10, size = { 5, 5, 6 }, color = { 90, 120, 70 } },
	{ id = "wind", name = "Wind Turbine", power = 40, price = 110000, max = 8, size = { 4, 20, 4 }, color = { 236, 236, 230 } },
	{ id = "steam", name = "Steam Engine", power = 100, price = 700000, max = 6, size = { 7, 8, 9 }, color = { 120, 80, 60 } },
	{ id = "lightning", name = "Lightning Rod Array", power = 260, price = 4000000, max = 4, size = { 6, 24, 6 }, color = { 120, 170, 255 } },
}

-- Building pieces for climbing your pile, placed anywhere on your plot.
Config.Pieces = {
	{ id = "ladder", name = "Ladder", price = 200, size = { 4, 20, 2 }, model = 111414262141412, text = "Climb 20 studs straight up. Stack them to go higher." },
	{ id = "stairs", name = "Stairs", price = 300, size = { 8, 10, 10 }, text = "Climbs 10 studs over 10 studs." },
	{ id = "landing", name = "Landing", price = 150, size = { 10, 1, 10 }, text = "A 10 by 10 floor to stand and turn on." },
	{ id = "pillar", name = "Pillar", price = 100, size = { 2, 10, 2 }, text = "A 10-stud post to hold things up." },
	{ id = "escalator", name = "Escalator", price = 4000, size = { 8, 10, 10 }, text = "Stairs that carry you up 10 studs." },
	{ id = "elevator", name = "Elevator", price = 30000, size = { 10, 51, 10 }, text = "A 50-stud lift. Press E at the bottom or top." },
	{ id = "teleporter", name = "Teleporter Pad", price = 25000, size = { 8, 1, 8 }, text = "Step on, press E, pick any of your other pads." },
	{ id = "conveyor", name = "Conveyor Belt", price = 800, size = { 6, 1, 12 }, text = "Carries dropped hay (G) along, towards its arrow." },
	{ id = "chute", name = "Conveyor Down", price = 1500, size = { 6, 10, 12 }, text = "A belt that carries hay down 10 studs, off a platform." },
	{ id = "baler", name = "Bale Maker", price = 60000, max = 3, size = { 8, 7, 10 }, text = "Feed it hay at the back; it pushes out bales. Trucks carry bales 3x as easily." },
	{ id = "trader", name = "Trader's Stall", price = 0, max = 1, size = { 12, 12, 8 }, text = "Your trader. Dump your hay in the basket. Move it anywhere, even up a platform." },
}
Config.TraderDistance = 57 -- your trader's stall starts this far from your plot's centre, towards the hub
Config.BasketDrainSeconds = 4 -- how fast the basket's hay level eases down after a dump (just for show)

-- Hauling: what you dump waits in your trader's basket. The trader himself buys TraderRate
-- straws a second; trucks fetch more (rate = straws a second each, as one load a trip).
-- Baled hay packs tighter: a truck or the trader moves BaleCompaction times as much of it.
Config.TraderRate = 8
Config.TruckTripSeconds = 40
Config.Trucks = {
	{ id = "van", name = "Farm Van", rate = 15, price = 8000, max = 2, size = { 6, 6, 11 }, color = { 236, 236, 228 } },
	{ id = "mini", name = "Mini Truck", rate = 35, price = 60000, max = 2, size = { 6, 6, 13 }, color = { 70, 130, 200 } },
	{ id = "semi", name = "Semi Truck", rate = 90, price = 500000, max = 2, size = { 8, 9, 24 }, color = { 196, 72, 56 } },
	{ id = "big", name = "Large Truck", rate = 220, price = 3000000, max = 2, size = { 9, 10, 30 }, color = { 60, 120, 70 } },
}
Config.BasketShowFull = 5000 -- straws waiting at which the basket looks full

-- Loose hay: press DropKey to drop what you carry as a bundle. Conveyors carry bundles; your
-- trader's basket and bale makers take them in. Bundles and bales left lying for
-- LooseHayMinutes go to your basket by themselves, and so does everything when you leave.
Config.DropKey = "G"
Config.MaxLooseHay = 40 -- bundles and bales on one plot at once
Config.LooseHayMinutes = 10
Config.ConveyorSpeed = 10 -- studs a second
Config.BaleStraws = 2000 -- straws in one bale
Config.BaleCompaction = 3
Config.BuildGrid = 1 -- placement snaps to this many studs
Config.MaxPlaced = 400 -- pieces, machines and generators on one plot

-- Perks are bought per tool (they reset when you buy a new tool).
Config.Perks = {
	{ id = "sharp", name = "Sharpened", per_level = 0.15, levels = 5, price = 120, growth = 1.6, text = "+15% straws a click per level" },
	{ id = "swift", name = "Swift", per_level = 0.10, levels = 5, price = 120, growth = 1.6, text = "-10% cooldown per level" },
	{ id = "lucky", name = "Lucky", per_level = 0.004, levels = 5, price = 150, growth = 1.6, text = "+0.4% chance of a lucky find per level" },
}

Config.LuckyChance = 0.006
Config.LuckyValueSearches = 60

-- Sounds: paste asset IDs from the Studio Toolbox (e.g. "rbxassetid://12345"). "" = silent.
-- The rbxasset://sounds/... files ship inside every Roblox client (the default character and
-- classic gear sounds), so they can't go private or be removed. Check them in Studio.
Config.Sounds = {
	harvest = "rbxasset://sounds/action_footsteps_plastic.mp3", -- a soft, muffled touch
	pop = "rbxasset://sounds/action_jump_land.mp3", -- a soft "fwump" when a clump empties
	coins = "rbxasset://sounds/electronicpingshort.wav", -- a short, gentle chime
	cheer = "rbxasset://sounds/electronicpingshort.wav", -- the same chime, lower and fuller
	spin = "",
}
-- Per sound: volume (0-1), pitch multiplier, wobble = random pitch +/- so clicks don't tire.
Config.SoundSettings = {
	harvest = { volume = 0.25, pitch = 1.1, wobble = 0.06 },
	pop = { volume = 0.4, pitch = 0.85 },
	coins = { volume = 0.3, pitch = 1 },
	cheer = { volume = 0.35, pitch = 0.7 },
}

-- Background music: soft acoustic / country instrumentals, looping on each player's side
-- with a gentle fade between tracks and a music on/off button (top right). A track that
-- won't load is skipped quietly. Licensed library tracks Roblox uploaded for every game:
Config.Music = {
	{ id = "rbxassetid://1844140274", name = "Country Folk Picking" }, -- found online, check in Studio
	{ id = "rbxassetid://1842101902", name = "Acoustic Nomad" }, -- found online, check in Studio
}
Config.MusicVolume = 0.25
Config.MusicFadeSeconds = 3 -- fade out at a track's end, fade in the next
Config.MusicLoadSeconds = 10 -- a track that hasn't loaded by then is skipped

-- Jetpack (Robux game pass, Config.GamePasses.Jetpack). Hold Space in the air to rise, let go
-- to drift gently down, or press the hover key to stay put; steer with WASD as usual.
Config.Jetpack = {
	riseSpeed = 18, -- studs a second going up
	fallSpeed = 7, -- studs a second drifting down after you let go (a soft landing)
	thrust = 2.5, -- most force it pushes with, in body weights: it can never fling you
	ease = 5, -- how quickly the speed eases to its target (higher = snappier)
	ceiling = 275, -- no lift above this height (the pile is 255 high; the loft starts at 300)
	fuelSeconds = 0, -- seconds of flight before you land to refuel; 0 = unlimited
	refuelSeconds = 4, -- seconds on the ground to refill a full tank
	hoverKey = "H", -- F already places things in build mode
}

-- One friendly Robux suggestion per session, after this many clumps harvested. It lists only
-- items whose ID is set, has a "No thanks" button as big as the others, and never comes back.
Config.OfferAfterClumps = 25

Config.DataStoreName = "NeedleHaystack_v5" -- v5: the lower, wider haystack numbers clumps differently
Config.AutosaveSeconds = 120

-- Robux. Nothing shows in the shop until you create the item on the Creator Dashboard
-- (after publishing) and paste its ID here. 0 = switched off.
Config.GamePasses = {
	AutoSell = 0, -- what you carry sells itself when your tool is full
	VIP = 0, -- +25% coins, a golden name tag, and machines keep running an hour after you leave
	DoubleMachines = 0, -- every machine works twice as fast (same power)
	Jetpack = 0, -- hold Space in the air to fly up and hover over your pile (see Config.Jetpack)
}
Config.Products = {
	SpeedBoost = 0, -- 2x straws a click for 1 hour
	CoinBoost = 0, -- 2x coins from the merchant for 1 hour
	MerchantWhistle = 0, -- sell anywhere, 10 times
	StrawBlast = 0, -- harvest 100,000 straws from the top of your pile at once
	LuckyCharm = 0, -- 5x lucky finds for 1 hour
	WheelSpin = 0, -- one spin of the Wheel of Fortune
}
Config.BoostSeconds = 3600
Config.WhistleUses = 10
Config.StrawBlastAmount = 100000
Config.VipCoinBonus = 0.25
Config.VipOfflineSeconds = 3600

-- The Wheel of Fortune (Robux). Every spin wins something. The odds are shown on the wheel
-- before buying, and the wheel is hidden where paid random items aren't allowed.
-- weight / total weight = chance. A skin you already own pays `WheelDuplicateSearches` instead.
Config.Wheel = {
	{ id = "rose", name = "Rose Gold skin", weight = 3000, shaft = { 120, 70, 60 }, head = { 232, 160, 150 }, material = "Metal" },
	{ id = "ice", name = "Ice skin", weight = 2500, shaft = { 180, 220, 240 }, head = { 210, 240, 255 }, material = "Ice" },
	{ id = "lava", name = "Lava skin", weight = 2000, shaft = { 60, 30, 20 }, head = { 255, 90, 30 }, material = "Neon" },
	{ id = "candy", name = "Candy Cane skin", weight = 1500, shaft = { 245, 245, 245 }, head = { 230, 40, 60 }, material = "SmoothPlastic" },
	{ id = "galaxy", name = "Galaxy skin", weight = 700, shaft = { 30, 20, 60 }, head = { 140, 90, 255 }, material = "Neon" },
	{ id = "diamond", name = "Diamond skin", weight = 299, shaft = { 200, 230, 255 }, head = { 160, 220, 255 }, material = "Glass" },
	{ id = "needle", name = "NEEDLE REVEAL", weight = 1, reveal = true },
}
Config.WheelDuplicateSearches = 200

-- Achievements stay hidden until you earn them. All ten open the Golden Loft above the hub.
Config.Achievements = {
	{ id = "first_straw", name = "First Straw", text = "Harvest your first straw.", stat = "searches", goal = 1 },
	{ id = "full_load", name = "Full Load", text = "Fill your tool to the brim.", stat = "loads_filled", goal = 1 },
	{ id = "merchant", name = "Merchant's Friend", text = "Sell 100,000 straws to the merchant.", stat = "straws_sold", goal = 100000 },
	{ id = "collector", name = "Collector", text = "Own every tool, up to the Needle Detector.", stat = "tool", goal = 10 },
	{ id = "engineer", name = "Engineer", text = "Have 10 machines working on your plot.", stat = "machines", goal = 10 },
	{ id = "power_plant", name = "Power Plant", text = "Generate 500 power on your plot.", stat = "power", goal = 500 },
	{ id = "sky_high", name = "Sky High", text = "Stand on top of your haystack, 75 studs up.", stat = "best_height", goal = 75 },
	{ id = "perfectionist", name = "Perfectionist", text = "Max out all three perks on one tool.", stat = "perks_maxed", goal = 1 },
	{ id = "lucky", name = "Lucky Duck", text = "Make 25 lucky finds in the hay.", stat = "lucky_finds", goal = 25 },
	{ id = "needle", name = "Needle Finder", text = "Find the needle.", stat = "needles", goal = 1 },
}
Config.BadgeIds = {} -- optional: { first_straw = 123456 } awards a Roblox badge too

-- The Golden Loft: a secret golden haystack above the hub where straw pays 20x.
Config.Loft = { straws = 250000, coinMultiplier = 20, needleEarliest = 0.5 }

return Config
