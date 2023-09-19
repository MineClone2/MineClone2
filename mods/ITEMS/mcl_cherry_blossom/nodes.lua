local S = minetest.get_translator(minetest.get_current_modname())

-- Logs
mcl_core.register_tree_trunk("cherrytree", S("Cherry Log"), S("Cherry Bark"),
	S("The trunk of a cherry blossom tree."),
	"mcl_cherry_blossom_log_top.png", "mcl_cherry_blossom_log.png", "mcl_cherry_blossom:stripped_cherrytree")

-- Stripped
mcl_core.register_stripped_trunk("stripped_cherrytree", S("Stripped Cherry Log"), S("Stripped Cherry Wood"),
	S("The stripped trunk of a cherry blossom tree."), S("The stripped wood of a cherry blossom tree."),
	"mcl_cherry_blossom_log_top_stripped.png", "mcl_cherry_blossom_log_stripped.png")

--Planks
mcl_core.register_wooden_planks("cherrywood", S("Cherry Wood Planks"), {"mcl_cherry_blossom_planks.png"})

-- Leaves
mcl_core.register_leaves("cherryleaves", S("Cherry Leaves"), 
	S("Cherry blossom leaves are grown from cherry blossom trees."), {"mcl_cherry_blossom_leaves.png"},
	nil, "none", nil, "mcl_cherry_blossom:cherrysapling", false, {20, 16, 12, 10})

-- Sapling
mcl_core.register_sapling("cherrysapling", S("Cherry Sapling"),
	S("Cherry blossom sapling can be planted to grow cherry trees."), nil,
	"mcl_cherry_blossom_sapling.png", {-4/16, -0.5, -4/16, 4/16, 0.25, 4/16})

-- Door and Trapdoor
mcl_doors:register_door("mcl_cherry_blossom:cherry_door", {
	description = S("Cherry Door"),
	inventory_image = "mcl_cherry_blossom_door_inv.png",
	groups = {handy=1,axey=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	tiles_bottom = "mcl_cherry_blossom_door_bottom.png",
	tiles_top = "mcl_cherry_blossom_door_top.png",
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_doors:register_trapdoor("mcl_cherry_blossom:cherry_trapdoor", {
	description = S("Cherry Trapdoor"),
	tile_front = "mcl_cherry_blossom_trapdoor.png",
	tile_side = "mcl_cherry_blossom_trapdoor_side.png",
	wield_image = "mcl_cherry_blossom_trapdoor.png",
	groups = {handy=1,axey=1, mesecon_effector_on=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

-- Stairs and Slabs
mcl_stairs.register_stair("cherrywood", "mcl_cherry_blossom:cherrywood",
		{handy=1,axey=1, flammable=3,wood_stairs=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
		{"mcl_cherry_blossom_planks.png"},
		S("Cherry Stairs"),
		mcl_sounds.node_sound_wood_defaults(), nil, nil,
		"woodlike")
mcl_stairs.register_slab("cherrywood", "mcl_cherry_blossom:cherrywood",
		{handy=1,axey=1, flammable=3,wood_slab=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
		{"mcl_cherry_blossom_planks.png"},
		S("Cherry Slab"),
		mcl_sounds.node_sound_wood_defaults(), nil, nil,
		S("Double Cherry Slab"))

-- Signs
mcl_signs.register_sign_custom("mcl_cherry_blossom", "_cherrywood",
		"mcl_cherry_blossom_sign.png", nil,
		"mcl_cherry_blossom_sign_inv.png", "mcl_cherry_blossom_sign_inv.png", S("Cherry Sign"))

-- Fences & Gates
mcl_fences.register_fence_and_fence_gate(
	"cherry_fence",
	S("Cherry Fence"),
	S("Cherry Gate"),
	"mcl_cherry_blossom_planks.png",
	{handy=1, axey=1, flammable=2, fence_wood=1, fire_encouragement=5, fire_flammability=20},
	minetest.registered_nodes["mcl_core:wood"]._mcl_hardness,
	minetest.registered_nodes["mcl_core:wood"]._mcl_blast_resistance,
	{"group:fence_wood"},
	mcl_sounds.node_sound_wood_defaults())

-- Redstone
mesecon.register_pressure_plate(
	"mcl_cherry_blossom:pressure_plate_cherrywood",
	S("Cherry Pressure Plate"),
	{"mcl_cherry_blossom_planks.png"},
	{"mcl_cherry_blossom_planks.png"},
	"mcl_cherry_blossom_planks.png",
	nil,
	{{"mcl_cherry_blossom:cherrywood", "mcl_cherry_blossom:cherrywood"}},
	mcl_sounds.node_sound_wood_defaults(),
	{axey=1, material_wood=1},
	nil)

mesecon.register_button(
	"cherrywood",
	S("Cherry Button"),
	"mcl_cherry_blossom_planks.png",
	"mcl_cherry_blossom:cherrywood",
	mcl_sounds.node_sound_wood_defaults(),
	{material_wood=1,handy=1,axey=1},
	1.5,
	true,
	nil,
	"mesecons_button_push_wood")
