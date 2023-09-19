local S = minetest.get_translator("mcl_copper")

minetest.register_node("mcl_copper:stone_with_copper", {
	description = S("Copper Ore"),
	_doc_items_longdesc = S("Some copper contained in stone, it is pretty common and can be found below sea level."),
	tiles = {"default_stone.png^mcl_copper_ore.png"},
	is_ground_content = true,
	groups = {pickaxey = 3, building_block = 1, material_stone = 1, blast_furnace_smeltable=1},
	drop = "mcl_copper:raw_copper",
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 3,
	_mcl_hardness = 3,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = mcl_core.fortune_drop_ore,
})

minetest.register_node("mcl_copper:block_raw", {
	description = S("Block of Raw Copper"),
	_doc_items_longdesc = S("A block used for compact raw copper storage."),
	tiles = {"mcl_copper_block_raw.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, blast_furnace_smeltable = 1 },
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 5,
})

minetest.register_node("mcl_copper:block", {
	description = S("Block of Copper"),
	_doc_items_longdesc = S("A block of copper is mostly a decorative block."),
	tiles = {"mcl_copper_block.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_oxidized_variant = "mcl_copper:block_exposed",
	_mcl_waxed_variant = "mcl_copper:waxed_block",
})

minetest.register_node("mcl_copper:waxed_block", {
	description = S("Waxed Block of Copper"),
	_doc_items_longdesc = S("A block of copper is mostly a decorative block."),
	tiles = {"mcl_copper_block.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block",
})

minetest.register_node("mcl_copper:block_exposed", {
	description = S("Exposed Copper"),
	_doc_items_longdesc = S("Exposed copper is a decorative block."),
	tiles = {"mcl_copper_exposed.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_oxidized_variant = "mcl_copper:block_weathered",
	_mcl_waxed_variant = "mcl_copper:waxed_block_exposed",
	_mcl_stripped_variant = "mcl_copper:block",
})

minetest.register_node("mcl_copper:waxed_block_exposed", {
	description = S("Waxed Exposed Copper"),
	_doc_items_longdesc = S("Exposed copper is a decorative block."),
	tiles = {"mcl_copper_exposed.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_exposed",
})

minetest.register_node("mcl_copper:block_weathered", {
	description = S("Weathered Copper"),
	_doc_items_longdesc = S("Weathered copper is a decorative block."),
	tiles = {"mcl_copper_weathered.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_oxidized_variant = "mcl_copper:block_oxidized",
	_mcl_waxed_variant = "mcl_copper:waxed_block_weathered",
	_mcl_stripped_variant = "mcl_copper:block_exposed",
})

minetest.register_node("mcl_copper:waxed_block_weathered", {
	description = S("Waxed Weathered Copper"),
	_doc_items_longdesc = S("Weathered copper is a decorative block."),
	tiles = {"mcl_copper_weathered.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_weathered",
})

minetest.register_node("mcl_copper:block_oxidized", {
	description = S("Oxidized Copper"),
	_doc_items_longdesc = S("Oxidized copper is a decorative block."),
	tiles = {"mcl_copper_oxidized.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_waxed_variant = "mcl_copper:waxed_block_oxidized",
	_mcl_stripped_variant = "mcl_copper:block_weathered",
})

minetest.register_node("mcl_copper:waxed_block_oxidized", {
	description = S("Waxed Oxidized Copper"),
	_doc_items_longdesc = S("Oxidized copper is a decorative block."),
	tiles = {"mcl_copper_oxidized.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_oxidized",
})

minetest.register_node("mcl_copper:block_cut", {
	description = S("Cut Copper"),
	_doc_items_longdesc = S("Cut copper is a decorative block."),
	tiles = {"mcl_copper_block_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_oxidized_variant = "mcl_copper:block_exposed_cut",
	_mcl_waxed_variant = "mcl_copper:waxed_block_cut",
})

minetest.register_node("mcl_copper:waxed_block_cut", {
	description = S("Waxed Cut Copper"),
	_doc_items_longdesc = S("Cut copper is a decorative block."),
	tiles = {"mcl_copper_block_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_cut",
})

minetest.register_node("mcl_copper:block_exposed_cut", {
	description = S("Exposed Cut Copper"),
	_doc_items_longdesc = S("Exposed cut copper is a decorative block."),
	tiles = {"mcl_copper_exposed_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_waxed_variant = "mcl_copper:waxed_block_exposed_cut",
	_mcl_oxidized_variant = "mcl_copper:block_weathered_cut",
	_mcl_stripped_variant = "mcl_copper:block_cut",
})

minetest.register_node("mcl_copper:waxed_block_exposed_cut", {
	description = S("Waxed Exposed Cut Copper"),
	_doc_items_longdesc = S("Exposed cut copper is a decorative block."),
	tiles = {"mcl_copper_exposed_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_exposed_cut",
})

minetest.register_node("mcl_copper:block_weathered_cut", {
	description = S("Weathered Cut Copper"),
	_doc_items_longdesc = S("Weathered cut copper is a decorative block."),
	tiles = {"mcl_copper_weathered_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, oxidizable = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_exposed_cut",
	_mcl_oxidized_variant = "mcl_copper:block_oxidized_cut",
	_mcl_waxed_variant = "mcl_copper:waxed_block_weathered_cut",
})

minetest.register_node("mcl_copper:waxed_block_weathered_cut", {
	description = S("Waxed Weathered Cut Copper"),
	_doc_items_longdesc = S("Weathered cut copper is a decorative block."),
	tiles = {"mcl_copper_weathered_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_weathered_cut",
})

minetest.register_node("mcl_copper:block_oxidized_cut", {
	description = S("Oxidized Cut Copper"),
	_doc_items_longdesc = S("Oxidized cut copper is a decorative block."),
	tiles = {"mcl_copper_oxidized_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_weathered_cut",
	_mcl_waxed_variant = "mcl_copper:waxed_block_oxidized_cut",
})

minetest.register_node("mcl_copper:waxed_block_oxidized_cut", {
	description = S("Waxed Oxidized Cut Copper"),
	_doc_items_longdesc = S("Oxidized cut copper is a decorative block."),
	tiles = {"mcl_copper_oxidized_cut.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, waxed = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_stripped_variant = "mcl_copper:block_oxidized_cut",
})

mcl_stairs.register_slab("copper_cut", "mcl_copper:block_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png"},
	S("Slab of Cut Copper"),
	nil, nil, nil,
	S("Double Slab of Cut Copper"))

mcl_stairs.register_slab("waxed_copper_cut", "mcl_copper:waxed_block_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png"},
	S("Waxed Slab of Cut Copper"),
	nil, nil, nil,
	S("Waxed Double Slab of Cut Copper"))

mcl_stairs.register_slab("copper_exposed_cut", "mcl_copper:block_exposed_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png"},
	S("Slab of Exposed Cut Copper"),
	nil, nil, nil,
	S("Double Slab of Exposed Cut Copper"))

mcl_stairs.register_slab("waxed_copper_exposed_cut", "mcl_copper:waxed_block_exposed_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png"},
	S("Waxed Slab of Exposed Cut Copper"),
	nil, nil, nil,
	S("Waxed Double Slab of Exposed Cut Copper"))

mcl_stairs.register_slab("copper_weathered_cut", "mcl_copper:block_weathered_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png"},
	S("Slab of Weathered Cut Copper"),
	nil, nil, nil,
	S("Double Slab of Weathered Cut Copper"))

mcl_stairs.register_slab("waxed_copper_weathered_cut", "mcl_copper:waxed_block_weathered_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png"},
	S("Waxed Slab of Weathered Cut Copper"),
	nil, nil, nil,
	S("Waxed Double Slab of Weathered Cut Copper"))

mcl_stairs.register_slab("copper_oxidized_cut", "mcl_copper:block_oxidized_cut",
	{pickaxey = 2},
	{"mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png"},
	S("Slab of Oxidized Cut Copper"),
	nil, nil, nil,
	S("Double Slab of Oxidized Cut Copper"))

mcl_stairs.register_slab("waxed_copper_oxidized_cut", "mcl_copper:waxed_block_oxidized_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png"},
	S("Waxed Slab of Oxidized Cut Copper"),
	nil, nil, nil,
	S("Waxed Double Slab of Oxidized Cut Copper"))

mcl_stairs.register_stair("copper_cut", "mcl_copper:block_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png"},
	S("Stairs of Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("waxed_copper_cut", "mcl_copper:waxed_block_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png", "mcl_copper_block_cut.png"},
	S("Waxed Stairs of Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("copper_exposed_cut", "mcl_copper:block_exposed_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png"},
	S("Stairs of Exposed Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("waxed_copper_exposed_cut", "mcl_copper:waxed_block_exposed_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png", "mcl_copper_exposed_cut.png"},
	S("Waxed Stairs of Exposed Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("copper_weathered_cut", "mcl_copper:block_weathered_cut",
	{pickaxey = 2, oxidizable = 1},
	{"mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png"},
	S("Stairs of Weathered Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("waxed_copper_weathered_cut", "mcl_copper:waxed_block_weathered_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png", "mcl_copper_weathered_cut.png"},
	S("Waxed Stairs of Weathered Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("copper_oxidized_cut", "mcl_copper:block_oxidized_cut",
	{pickaxey = 2},
	{"mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png"},
	S("Stairs of Oxidized Cut Copper"),
	nil, nil, nil,
	"woodlike")

mcl_stairs.register_stair("waxed_copper_oxidized_cut", "mcl_copper:waxed_block_oxidized_cut",
	{pickaxey = 2, waxed = 1},
	{"mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png", "mcl_copper_oxidized_cut.png"},
	S("Waxed Stairs of Oxidized Cut Copper"),
	nil, nil, nil,
	"woodlike")
