# Designing your own portal in Studio

The game builds every portal (the five in Sky Meadow, the one on your farm and the way back
from each world) from one design. If you make your own, the game uses yours everywhere and
colours each copy for its world.

## 1. Start from the current portal

1. Open `NeedleInTheHaystack.rbxlx` in Studio.
2. In the Explorer, find **ServerStorage > Designs** (an empty folder).
3. Right-click **Designs > Insert from File...** and pick `Portal.rbxmx`.
   A model named **Portal** appears: the same moon gate the game builds now.
4. Move it somewhere you can see it while you work (the Designs folder isn't shown in the game,
   so drag a copy into Workspace to look at it, and drag it back when you're done).

## 2. Change anything you like

Move, resize, recolour, delete or add parts, or bring in meshes and models from the Toolbox.
A few names matter:

| Part name | What the game does with it |
|---|---|
| **Base** | Marks the ground under the middle of the portal. Keep its **Front** face pointing the way players walk in from. The game hides it. Don't delete it. |
| **Opening** | Where players walk in. It takes the portal's colour, glows, and wears the flowing light. It never blocks anyone. Don't delete it. |
| **Glow...** (any name starting with Glow, like GlowGem) | Takes each portal's colour: gold for your farm, orange for Lava, and so on. |
| **Sign** | Gets the portal's name written on its Front face. |

Everything else keeps exactly the colour and material you give it. Scripts inside the design
are removed (it's only looks).

## 3. Try it

Keep the model named **Portal** inside **ServerStorage > Designs** and press Play. Every portal
is now yours. If the game can't find **Base** or **Opening**, it warns in the Output window
and builds the built-in portal instead.

## 4. Keep it when you take a new place file from Claude

A new place file from Claude replaces your Studio copy, Designs folder included. So when you're
happy with your portal:

1. Right-click your **Portal** model > **Save to Roblox**, and finish the steps.
2. Copy its asset ID (Toolbox > My Models, right-click it > Copy Asset ID).
3. Send the ID to Claude. It goes in `Config.PortalModel`, and from then on every place file
   loads your portal from Roblox.

You can also right-click the model > **Save to File...** to keep a backup.
