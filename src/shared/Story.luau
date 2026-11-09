-- The story: "The Silver Needle of Hollow Creek". Every beat plays once, in order, when its
-- trigger is reached (server/Story checks; client/Dialogue shows it). Edit the words freely.
--   who: a key of Story.cast. text: what they say. A line may offer `choices`: { reply, answer }
--   (the player's reply, then what the speaker says back; every choice carries on the story).
--   trigger kinds: start, stat (key), clumps (whole clumps cleared from this heap), tool, truck
--   (key), placed (key), machines, needles, world (key = a Config.Worlds id).
--   found: an item the player turns up in the hay (shown before the talk). reward: coins.
local Story = {}

Story.cast = {
	mabel = { name = "Grandma Mabel", colour = { 96, 128, 74 } },
	patch = { name = "Patch", colour = { 206, 152, 46 } },
	pip = { name = "Pip", colour = { 59, 52, 66 } },
	tobias = { name = "Tobias", colour = { 76, 106, 130 } },
	clem = { name = "Clem Burdock", colour = { 176, 84, 60 } },
	luna = { name = "Luna", colour = { 122, 110, 170 } },
}

Story.beats = {
	{ id = "arrival", title = "The storm", trigger = { kind = "start" }, reward = 0, lines = {
		{ who = "mabel", text = "There you are, love! Thank goodness. Did you see what last night's storm did?" },
		{ who = "mabel", text = "The wind blew every loose bit of hay in the valley onto our stack. It's taller than the barn now." },
		{ who = "mabel", text = "And somewhere in there is my silver needle. My gran's needle. I've stitched every quilt in Hollow Creek with it.",
			choices = { { "I'll find it, Gran.", "That's my brave one. Start at the bottom and work your way in." }, { "In THAT? It's enormous!", "It is. But so is your stubbornness. You get that from me." } } },
		{ who = "mabel", text = "Take my old garden trowel. Aim at the hay and click to lift some off." },
	} },
	{ id = "patch", title = "A talking scarecrow", trigger = { kind = "stat", key = "searches", n = 1 }, reward = 25, lines = {
		{ who = "patch", text = "Oi! Mind where you're digging, that's my boot under there!" },
		{ who = "patch", text = "Patch is the name. Scarecrow, lookout, and the only one who saw where that needle went." },
		{ who = "patch", text = "Mabel was up top last night, sewing my arm back on, when the wind took the needle right out of her hand.",
			choices = { { "Scarecrows can talk?", "Only to people who listen. Most folk are too busy shouting at crows." }, { "Which way did it go?", "Into the hay. Deep in, I'd say. Further than you'd like." } } },
		{ who = "patch", text = "Fill your trowel, then take the hay to Tobias at the stall. He'll pay you for it." },
	} },
	{ id = "tobias", title = "The trader", trigger = { kind = "stat", key = "dumps", n = 1 }, reward = 50, lines = {
		{ who = "tobias", text = "Ah, fresh hay! Lovely. I'll take it off your hands and sell it on, a bit at a time." },
		{ who = "tobias", text = "Coins land in your pocket as I sell. Spend them in the shop: a better fork lifts more with every swing." },
		{ who = "tobias", text = "Mind you, I'm only one man. If the basket piles up, a van would help. Just saying." },
	} },
	{ id = "button", title = "A red button", trigger = { kind = "clumps", n = 1 }, found = "A red button", reward = 100, lines = {
		{ who = "patch", text = "My button! My lovely red button! I've been winking for a week without it." },
		{ who = "patch", text = "See? The hay gives things back if you keep at it. Every clump you clear, something might turn up." },
	} },
	{ id = "pitchfork", title = "Grandpa's pitchfork", trigger = { kind = "tool", n = 2 }, reward = 150, lines = {
		{ who = "mabel", text = "Oh, a pitchfork. Your grandpa had one just like that. He called it Gerald." },
		{ who = "mabel", text = "Three prongs lift more than one trowel ever could. You'll be through the outside in no time." },
	} },
	{ id = "note", title = "The torn note", trigger = { kind = "clumps", n = 3 }, found = "A torn note", reward = 200, lines = {
		{ who = "mabel", text = "That's my handwriting! 'Mend Patch... by moonlight... top of the stack.'" },
		{ who = "mabel", text = "So I really was right up at the top when it slipped. It fell in from above, not from the side." },
		{ who = "patch", text = "Which means it's high up and deep in. You'll want stairs eventually. Lots of stairs." },
	} },
	{ id = "clem", title = "The neighbour", trigger = { kind = "stat", key = "straws_sold", n = 3000 }, reward = 250, lines = {
		{ who = "clem", text = "Morning! Clem Burdock, from over the hill. The storm took my lucky horseshoe and dropped it in MY haystack." },
		{ who = "clem", text = "Tell you what: I bet I find my horseshoe before you find that needle.",
			choices = { { "You're on.", "Ha! Loser bakes the winner a pie. Mabel's recipe, mind." }, { "That's not fair, a horseshoe is bigger!", "Exactly why I suggested it. Ha!" } } },
	} },
	{ id = "thimble", title = "A silver thimble", trigger = { kind = "clumps", n = 6 }, found = "A silver thimble", reward = 300, lines = {
		{ who = "pip", text = "CAW! CAW CAW!" },
		{ who = "patch", text = "That's Pip. He says the thimble is his and you should put it back. Finders keepers, he says." },
		{ who = "patch", text = "Pip collects anything shiny. If he'd found the needle first, we'd never see it again." },
	} },
	{ id = "van", title = "A van of your own", trigger = { kind = "truck", key = "van", n = 1 }, reward = 400, lines = {
		{ who = "tobias", text = "A van! Now we're talking. It'll come by and take the hay to market while I serve customers." },
		{ who = "tobias", text = "The more trucks you have, the faster your hay turns into coins. I'm not complaining. Much." },
	} },
	{ id = "thread", title = "The red thread", trigger = { kind = "clumps", n = 10 }, found = "A long red thread", reward = 500, lines = {
		{ who = "mabel", text = "Red thread! I had the needle threaded with red when it flew off. It must have trailed behind it." },
		{ who = "mabel", text = "Look how it runs: up, and in. Follow the thread and you'll follow the needle." },
		{ who = "patch", text = "Told you. Up and in. Nobody listens to the scarecrow." },
	} },
	{ id = "stairs", title = "Up the stack", trigger = { kind = "placed", key = "stairs", n = 1 }, reward = 400, lines = {
		{ who = "mabel", text = "Stairs! Clever thing. Be careful up there, the top's wobbly after a storm." },
		{ who = "patch", text = "Bring me back a view. I've been stuck on this pole for eleven years." },
	} },
	{ id = "harmonica", title = "Grandpa's harmonica", trigger = { kind = "clumps", n = 20 }, found = "An old harmonica", reward = 800, lines = {
		{ who = "mabel", text = "Oh my. That's your grandpa's harmonica. He used to play it on top of this very haystack on summer nights." },
		{ who = "mabel", text = "He said the stack was the best seat in the valley. I think he'd be proud of you, digging away like this." },
	} },
	{ id = "machines", title = "A helping hand", trigger = { kind = "machines", n = 1 }, reward = 1000, lines = {
		{ who = "clem", text = "Is that a machine digging your hay for you? That's cheating!" },
		{ who = "clem", text = "...How much did it cost? Asking for a friend. The friend is me." },
	} },
	{ id = "nest", title = "Pip's nest", trigger = { kind = "clumps", n = 40 }, found = "Pip's secret nest", reward = 2500, lines = {
		{ who = "pip", text = "CAW!! CAAAW!" },
		{ who = "patch", text = "A spoon, two keys, a bottle cap and a lot of coins. No needle. Pip says he's never seen it, and for once I believe him." },
		{ who = "patch", text = "He's also very upset you found his nest. Keep the coins. Call it rent." },
	} },
	{ id = "thicker", title = "The thread goes on", trigger = { kind = "clumps", n = 80 }, found = "More red thread", reward = 5000, lines = {
		{ who = "mabel", text = "More of my thread, and it's pointing further up. We're on the right track." },
		{ who = "patch", text = "Close. Ish. Close-ish. Keep going." },
	} },
	{ id = "spectacles", title = "Lost spectacles", trigger = { kind = "clumps", n = 150 }, found = "A pair of spectacles", reward = 10000, lines = {
		{ who = "mabel", text = "My reading glasses! I lost these in 1987. I've been squinting at quilts for forty years!" },
		{ who = "mabel", text = "Oh, everything's so sharp. Is that what the hay looks like? It's lovely." },
	} },
	{ id = "horseshoe", title = "Clem's horseshoe", trigger = { kind = "clumps", n = 300 }, reward = 20000, lines = {
		{ who = "clem", text = "Guess who found his horseshoe? Me! I win the bet!" },
		{ who = "clem", text = "Don't worry, I'll still help. Here, take some coins for your trouble. And I'm keeping the pie." },
	} },
	{ id = "sky", title = "Haystacks in the sky", trigger = { kind = "clumps", n = 600 }, reward = 40000, lines = {
		{ who = "patch", text = "Ever looked up at night? There's a haystack on the moon, you know. And in stranger places." },
		{ who = "patch", text = "Every one of them hides a needle. The arches in Sky Meadow lead to them, if you save up." },
	} },
	{ id = "warm", title = "Getting warm", trigger = { kind = "clumps", n = 1200 }, found = "A loop of red thread", reward = 80000, lines = {
		{ who = "mabel", text = "The thread loops round on itself here. It must have tangled as it fell. It can't be far now." },
		{ who = "mabel", text = "Mind you, 'not far' in this stack could still be a long way. Keep your chin up." },
	} },
	{ id = "halfway", title = "Halfway", trigger = { kind = "clumps", n = 2500 }, reward = 150000, lines = {
		{ who = "mabel", text = "Half the stack gone! I've baked you an apple pie. Clem had a slice. Several slices." },
		{ who = "clem", text = "It's a very good pie." },
	} },
	{ id = "found", title = "The silver needle", trigger = { kind = "needles", n = 1 }, reward = 0, lines = {
		{ who = "mabel", text = "You found it! My gran's needle, still threaded with red. Oh, come here, you." },
		{ who = "mabel", text = "I'll stitch the Great Quilt for the harvest fair, and your name's going right in the middle." },
		{ who = "patch", text = "Lovely. Wonderful. One small thing: the storm's back, and it's blowing a fresh stack in." },
		{ who = "mabel", text = "And I've just remembered I had TWO needles in my pocket that night. Shall we go again?" },
	} },
	{ id = "moon", title = "The Moon", trigger = { kind = "world", key = "moon", n = 1 }, reward = 0, lines = {
		{ who = "luna", text = "Oh! A visitor from below. I'm Luna. I keep the moon tidy, and the hay up here is moon-dust soft." },
		{ who = "luna", text = "My needle's hidden in it somewhere. Hay here sells for three times as much down below. Happy hunting." },
	} },
	{ id = "lava", title = "Ember Lands", trigger = { kind = "world", key = "lava", n = 1 }, reward = 0, lines = {
		{ who = "patch", text = "Hot, hot, hot! Don't stand too close to the lava, and don't let your hay catch fire." },
		{ who = "patch", text = "Somebody lost a needle here too. Must have been a very warm sewing circle." },
	} },
	{ id = "atlantis", title = "Bubble City", trigger = { kind = "world", key = "atlantis", n = 1 }, reward = 0, lines = {
		{ who = "luna", text = "A city in a bubble, under the sea! The hay here is a bit soggy, but it pays twelve times as much." },
	} },
	{ id = "field", title = "Haystack Stadium", trigger = { kind = "world", key = "field", n = 1 }, reward = 0, lines = {
		{ who = "clem", text = "A whole stadium of hay! I'll be in the stands, cheering. Loudly. Embarrassingly loudly." },
	} },
}

return Story
