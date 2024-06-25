# VoxeLibre
A game inspired by Minecraft for Minetest. Forked from MineClone by davedevils.
Developed by many people, see CREDITS.md for a complete list.

### Gameplay
You start in a randomly-generated world made entirely of cubes. You can explore
the world and dig and build almost every block in the world to create new
structures. You can choose to play in a “survival mode” in which you have to
fight monsters and hunger for survival and slowly progress through the
various other aspects of the game, such as mining, farming, building machines, and so on
Or you can play in “creative mode” in which you can build almost anything instantly.

#### Gameplay summary

* Sandbox-style gameplay, no goals
* Survive: Fight against hostile monsters and hunger
* Mine for ores and other treasures
* Magic: Gain experience and enchant your tools
* Use the collected blocks to create great buildings, your imagination is the limit
* Collect flowers (and other dye sources) and colorize your world
* Find some seeds and start farming
* Find or craft one of hundreds of items
* Build a railway system and have fun with minecarts
* Build complex machines with redstone circuits
* In creative mode you can build almost anything for free and without limits

## How to play (quick start)
### Getting started
* **Punch a tree** trunk until it breaks and collect wood
* Place the **wood into the 2×2 grid** (your “crafting grid” in your inventory menu) and craft 4 wood planks
* Place the 4 wood planks in a 2×2 shape in the crafting grid to **make a crafting table**
* **Rightclick the crafting table** for a 3×3 crafting grid to craft more complex things
* Use the **crafting guide** (book icon) to learn all the possible crafting recipes
* **Craft a wooden pickaxe** so you can dig stone
* Different tools break different kinds of blocks. Try them out!
* Continue playing as you wish. Have fun!

### Farming
* Find seeds
* Craft a hoe
* Rightclick dirt or a similar block with a hoe to create farmland
* Place seeds on farmland and watch them grow
* Collect plants when fully grown
* If near water, farmland becomes wet and speeds up growth

### Furnace
* Craft a furnace
* The furnace allows you to obtain more items
* Upper slot must contain a smeltable item (example: iron ore)
* Lower slot must contain a fuel item (example: coal)
* See tooltips in crafting guide to learn about fuels and smeltable items

### Additional help
More help about the gameplay, blocks items and much more can be found from inside
the game. You can access the help from your inventory menu.

### Special items
The following items are interesting for Creative Mode and for adventure
map builders. They can not be obtained in-game or in the creative inventory.

* Barrier: `mcl_core:barrier`

Use the `/giveme` chat command to obtain them. See the in-game help for
an explanation.

## Installation
To run the game with the best performance and support, we recommend the latest
stable version of [Minetest](http://minetest.net), be we always make an effort
to support one version behind the latest stable version. In some cases, older
versions might still be good enough but you would be missing out on important
Minetest features that enable important features for our game.

There is no support for running VoxeLibre in development versions of Minetest.

To install VoxeLibre (if you haven't already), move this directory into the
“games” directory of your Minetest data directory. Consult the help of
Minetest to learn more.

## Useful links
The VoxeLibre repository is hosted at Mesehub. To contribute or report issues, head there.

* Mesehub: <https://git.minetest.land/VoxeLibre/VoxeLibre>
* Discord: <https://discord.gg/xE4z8EEpDC>
* YouTube: <https://www.youtube.com/channel/UClI_YcsXMF3KNeJtoBfnk9A>
* ContentDB: <https://content.minetest.net/packages/wuzzy/mineclone2/>
* OpenCollective: <https://opencollective.com/voxelibre>
* Mastodon: <https://fosstodon.org/@VoxeLibre>
* Lemmy: <https://lemm.ee/c/voxelibre>
* Matrix space: <https://app.element.io/#/room/#voxelibre:matrix.org>
* Minetest forums: <https://forum.minetest.net/viewtopic.php?f=50&t=16407>
* Reddit: <https://www.reddit.com/r/VoxeLibre/>
* IRC (barely used): <https://web.libera.chat/#mineclone2>

## Target
- Create a stable, peformant, moddable, free/libre game inspired by Minecraft
using the Minetest engine, usable in both singleplayer and multiplayer.
- Currently, a lot of features are already implemented.
Polishing existing features is always welcome.

## Completion status
This game is currently in **beta** stage.
It is playable, but not yet feature-complete.
Backwards-compability is not entirely guaranteed, updating your world might cause small bugs.
If you want to use the development version of VoxeLibre in production, the master branch is usually relatively stable.

The following main features are available:

* Tools, weapons
* Armor
* Crafting system: 2×2 grid, crafting table (3×3 grid), furnace, including a crafting guide
* Chests, large chests, ender chests, shulker boxes
* Furnaces, hoppers
* Hunger
* Most monsters and animals
* All ores from Minecraft
* Most blocks in the overworld
* Water and lava
* Weather
* 28 biomes + 5 Nether Biomes
* The Nether, a fiery underworld in another dimension
* Redstone circuits (partially)
* Minecarts (partial)
* Status effects (partial)
* Experience
* Enchanting
* Brewing, potions, tipped arrow (partial)
* Boats
* Fire
* Buidling blocks: Stairs, slabs, doors, trapdoors, fences, fence gates, walls
* Clock
* Compass
* Sponge
* Slime block
* Small plants and saplings
* Dyes
* Banners
* Deco blocks: Glass, stained glass, glass panes, iron bars, hardened clay (and colors), heads and more
* Item frames
* Jukeboxes
* Beds
* Inventory menu
* Creative inventory
* Farming
* Writable books
* Commands
* Villages
* The End
* And more!

The following features are incomplete:

* Some monsters and animals
* Redstone-related things
* Some special minecarts (hopper and chest minecarts work)
* A couple of non-trivial blocks and items

Bonus features (not found in Minecraft):

* Built-in crafting guide which shows you crafting and smelting recipes
* In-game help system containing extensive help about gameplay basics, blocks, items and more
* Temporary crafting recipes. They only exist to make some otherwise unaccessible items available when you're not in creative mode. These recipes will be removed as development goes on an more features become available
* Saplings in chests in [mapgen v6](https://wiki.minetest.net/Map_generator#v6)
* Fully moddable (thanks to Minetest's powerful Lua API)
* New blocks and items:
    * Lookup tool, shows you the help for whatever it touches
    * More slabs and stairs
    * Nether Brick Fence Gate
    * Red Nether Brick Fence
    * Red Nether Brick Fence Gate
* Structure replacements - these small variants of Minecraft structures serve as replacements until we can get large structures working:
    * Woodland Cabin (Mansions)
    * Nether Outpost (Fortress)

Technical differences from Minecraft:

* Height limit of ca. 31000 blocks (much higher than in Minecraft)
* Horizontal world size is ca. 62000×62000 blocks (much smaller than in Minecraft, but it is still very large)
* Still very incomplete and buggy
* Blocks, items, enemies and other features are missing
* A few items have slightly different names to make them easier to distinguish
* Different music for jukebox
* Different textures (Pixel Perfection)
* Different sounds (various sources)
* Different engine (Minetest)
* Different easter eggs

… and finally, VoxeLibre is free software (“free” as in “freedom”)!

## Other readme files

* `LICENSE.txt`: The GPLv3 license text
* `CONTRIBUTING.md`: Information for those who want to contribute
* `API.md`: For Minetest modders who want to mod this game
* `LEGAL.md`: Legal information
* `CREDITS.md`: List of everyone who contributed
