# Needle in the Haystack

An original Roblox simulator, in first person. Your farm has its own 70-metre pile of
5,000,000 straws and one needle. Harvest clump by clump, sell to the merchant, build stairs,
escalators and elevators to climb higher, power machines with generators, and uncover ten
secret achievements to open the Golden Loft.

## Play it in Roblox Studio (about 15 minutes the first time)

1. **Get Roblox Studio.** Go to create.roblox.com, sign in with your Roblox account and tap
   *Start Creating*. It downloads Roblox Studio, which is free. Install it and sign in.
2. **Get the game file.** Download `NeedleInTheHaystack.rbxlx` from this project (on GitHub:
   open the file, then *Download raw file*).
3. **Open it.** Double-click the file, or in Studio choose *File*, then *Open from File*.
   The world is empty until you press Play: the farm is built when the game starts.
4. **Play-test.** Press *Play* (or F5). You start on your farm. Look at a clump of the pile
   and click to harvest. Walk to the merchant in the middle (press E there to sell). Q opens the
   shop, B builds, M frees the mouse for menus. Press *Stop* (Shift+F5) to finish.
5. **If something breaks**, open *View*, then *Output*. Red lines are errors: take a
   screenshot and send it to me, and I'll fix it.

Progress isn't saved while testing an unpublished game; that is normal.

## Publish it to Roblox

1. In Studio: *File*, then *Publish to Roblox*. Choose *New experience*, give it a name and a
   short description, and tap *Create*.
2. *Home*, then *Game Settings*: under *Places* set *Max Players* to **4** (one per plot). Under *Security* switch on *Enable Studio Access to API
   Services* and *Save*. Now saving works when you test in Studio too.
3. Your game starts private. To let everyone play, open create.roblox.com, *Creations*, your
   game, and set it to *Public* when you're happy with it.

## Earn Robux (optional, after publishing)

Robux items are built in but switched off. To turn one on:

1. On create.roblox.com open your game, then *Monetization*.
2. *Passes*: create **Auto Sell**, **Double Machines** and **VIP**, and set their prices.
   *Developer Products*: create **2x Speed (1 hour)**, **2x Coins (1 hour)**, **Lucky Charm
   (1 hour)**, **Straw Blast**, **Merchant's Whistle x10** and **Wheel Spin**, and set their
   prices.
3. Copy each item's ID (a long number) and send me the IDs. They aren't secret. I'll put
   them into the game and rebuild the file. Open the new file and publish again.

Robux you earn can be exchanged for real money through Roblox's Developer Exchange (DevEx)
once you meet its rules (check Roblox's DevEx page for the current age, balance and account
requirements).

## For developers

See `CLAUDE.md`. In short: edit `src/`, run `python3 dev/test_rules.py` and
`python3 dev/build.py`, and open the rebuilt `NeedleInTheHaystack.rbxlx`. The project also
works with Rojo (`default.project.json`).
