-- The factory line and the processing chain's numbers (Config.luau merges this file in, so
-- read and tune these as Config.<Name>; lists here are added to the end of Config's lists).
local Config = {}

-- More pieces for the Build tab: belt corners and splitters, and the processing machines.
Config.Pieces = {
	{ id = "corner", name = "Belt Corner", price = 300, size = { 6, 1, 6 }, text = "Turns hay on a belt to the side. Press R until the arrows point the way you want." },
	{ id = "splitter", name = "Belt Splitter", price = 2500, size = { 6, 1, 6 }, text = "Sends hay left, then right, then left: feed two lines from one." },
	{ id = "wrapper", name = "Bale Wrapper", price = 150000, max = 3, size = { 8, 6, 10 }, text = "Bales in at the back, wrapped bales out: worth more, and orders ask for them." },
	{ id = "press", name = "Pellet Press", price = 400000, max = 3, size = { 8, 7, 10 }, text = "Bundles in at the back, sacks of hay pellets out: worth more again." },
}

-- Feeders take hay from your heap by themselves and put it on your belts as bundles, using
-- power like machines. amount = straws a go, every = seconds between goes, draw = power,
-- throw = how far a thrower flings its bundle forward (studs).
Config.Feeders = {
	{ id = "arm", name = "Hay Arm", amount = 8, every = 4, draw = 6, price = 50000, max = 8, size = { 4, 7, 4 } },
	{ id = "thrower", name = "Hay Thrower", amount = 30, every = 4, draw = 30, price = 900000, max = 6, size = { 5, 4, 6 }, throw = 22 },
}
Config.FeederReach = 30 -- a feeder only takes hay if your heap is this close (studs from its base)

-- Hay Burner (in the generator list): power while it has hay to burn, fed by belt or by hand.
Config.BurnerSecondsPerStraw = 0.25 -- 1,000 straws keep a burner going for about 4 minutes

-- Belt motors: every belt you own runs at the speed of your level (bought in Logistics).
Config.BeltSpeeds = {
	{ speed = 10, price = 0 },
	{ speed = 14, price = 20000 },
	{ speed = 19, price = 120000 },
	{ speed = 25, price = 700000 },
}

-- Processing: what each product is worth, as a multiple of the straws in it, and how tightly
-- trucks pack it (bales already pack 3x).
Config.Processing = {
	wrapped = { value = 1.4, name = "wrapped bale" },
	pellet = { value = 1.7, straws = 500, name = "pellet sack" },
}

-- Delivery orders: a truck driver asks for straws of one kind (loose bundles, bales, wrapped
-- bales, pellet sacks). Everything of that kind reaching your basket counts by its straws; the
-- reward is a bonus on top of the sale (about 0.2-0.5 coins a straw). Each full round of orders
-- asks for and pays OrderGrowth times more, so the bonus per straw stays the same.
Config.Orders = {
	{ kind = "bundle", straws = 2000, reward = 400 },
	{ kind = "bale", straws = 10000, reward = 3000 },
	{ kind = "bundle", straws = 20000, reward = 4000 },
	{ kind = "bale", straws = 40000, reward = 12000 },
	{ kind = "wrapped", straws = 40000, reward = 16000 },
	{ kind = "pellet", straws = 20000, reward = 10000 },
	{ kind = "wrapped", straws = 100000, reward = 40000 },
	{ kind = "pellet", straws = 100000, reward = 50000 },
}
Config.OrderGrowth = 1.5

return Config
