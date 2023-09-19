-- Register all Minecraft stairs and slabs
-- Note about hardness: For some reason, the hardness of slabs and stairs don't always match nicely, so that some
-- slabs actually take slightly longer to be dug than their stair counterparts.
-- Note sure if it is a good idea to preserve this oddity.

local S = minetest.get_translator(minetest.get_current_modname())

local woods = {
	{ "wood", "default_wood.png", S("Oak Wood Stairs"), S("Oak Wood Slab"), S("Double Oak Wood Slab") },
	{ "junglewood", "default_junglewood.png", S("Jungle Wood Stairs"), S("Jungle Wood Slab"), S("Double Jungle Wood Slab") },
	{ "acaciawood", "default_acacia_wood.png", S("Acacia Wood Stairs"), S("Acacia Wood Slab"), S("Double Acacia Wood Slab") },
	{ "sprucewood", "mcl_core_planks_spruce.png", S("Spruce Wood Stairs"), S("Spruce Wood Slab"), S("Double Spruce Wood Slab") },
	{ "birchwood", "mcl_core_planks_birch.png", S("Birch Wood Stairs"), S("Birch Wood Slab"), S("Double Birch Wood Slab") },
	{ "darkwood", "mcl_core_planks_big_oak.png", S("Dark Oak Wood Stairs"), S("Dark Oak Wood Slab"), S("Double Dark Oak Wood Slab") },
}

for w=1, #woods do
	local wood = woods[w]
	mcl_stairs.register_stair(wood[1], "mcl_core:"..wood[1],
			{handy=1,axey=1, flammable=3,wood_stairs=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
			{wood[2]},
			wood[3],
			mcl_sounds.node_sound_wood_defaults(), nil, nil,
			"woodlike")
	mcl_stairs.register_slab(wood[1], "mcl_core:"..wood[1],
			{handy=1,axey=1, flammable=3,wood_slab=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
			{wood[2]},
			wood[4],
			mcl_sounds.node_sound_wood_defaults(), nil, nil,
			wood[5])
end


mcl_stairs.register_slab("stone_rough", "mcl_core:stone",
		{pickaxey=1, material_stone=1},
		{"default_stone.png"},
		S("Stone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Stone Slab"))
mcl_stairs.register_stair("stone_rough", "mcl_core:stone",
		{pickaxey=1, material_stone=1},
		{"default_stone.png"},
		S("Stone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)

mcl_stairs.register_slab("stone", "mcl_core:stone_smooth",
		{pickaxey=1, material_stone=1},
		{"mcl_stairs_stone_slab_top.png", "mcl_stairs_stone_slab_top.png", "mcl_stairs_stone_slab_side.png"},
		S("Polished Stone Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Polished Stone Slab"))

mcl_stairs.register_stair("andesite", "mcl_core:andesite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_andesite.png"},
		S("Andesite Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("andesite", "mcl_core:andesite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_andesite.png"},
		S("Andesite Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Andesite Slab"))

mcl_stairs.register_stair("granite", "mcl_core:granite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_granite.png"},
		S("Granite Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("granite", "mcl_core:granite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_granite.png"},
		S("Granite Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Granite Slab"))

mcl_stairs.register_stair("diorite", "mcl_core:diorite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_diorite.png"},
		S("Granite Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("diorite", "mcl_core:diorite",
		{pickaxey=1, material_stone=1},
		{"mcl_core_diorite.png"},
		S("Diorite Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Diorite Slab"))

mcl_stairs.register_stair("cobble", "mcl_core:cobble",
		{pickaxey=1, material_stone=1},
		{"default_cobble.png"},
		S("Cobblestone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("cobble", "mcl_core:cobble",
		{pickaxey=1, material_stone=1},
		{"default_cobble.png"},
		S("Cobblestone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Cobblestone Slab"))

mcl_stairs.register_stair("mossycobble", "mcl_core:mossycobble",
		{pickaxey=1, material_stone=1},
		{"default_mossycobble.png"},
		S("Mossy Cobblestone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("mossycobble", "mcl_core:mossycobble",
		{pickaxey=1, material_stone=1},
		{"default_mossycobble.png"},
		S("Mossy Cobblestone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Mossy Cobblestone Slab"))

mcl_stairs.register_stair("brick_block", "mcl_core:brick_block",
		{pickaxey=1, material_stone=1},
		{"default_brick.png"},
		S("Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("brick_block", "mcl_core:brick_block",
		{pickaxey=1, material_stone=1},
		{"default_brick.png"},
		S("Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Brick Slab"))

mcl_stairs.register_stair("sandstone", "mcl_core:sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png", "mcl_core_sandstone_bottom.png", "mcl_core_sandstone_normal.png"},
		S("Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	0.8, 0.8,
		nil, "mcl_core:sandstone")	--fixme: extra parameter from previous release
mcl_stairs.register_slab("sandstone", "mcl_core:sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png", "mcl_core_sandstone_bottom.png", "mcl_core_sandstone_normal.png"},
		S("Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Sandstone Slab"), "mcl_core:sandstone")	--fixme: extra parameter from previous release

mcl_stairs.register_stair("sandstonesmooth2", "mcl_core:sandstonesmooth2",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png"},
		S("Smooth Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	0.8, 0.8)
mcl_stairs.register_slab("sandstonesmooth2", "mcl_core:sandstonesmooth2",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png"},
		S("Smooth Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Smooth Sandstone Slab"))

mcl_stairs.register_stair("redsandstone", "mcl_core:redsandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png", "mcl_core_red_sandstone_bottom.png", "mcl_core_red_sandstone_normal.png"},
		S("Red Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8,
		nil, "mcl_core:redsandstone")	--fixme: extra parameter from previous release
mcl_stairs.register_slab("redsandstone", "mcl_core:redsandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png", "mcl_core_red_sandstone_bottom.png", "mcl_core_red_sandstone_normal.png"},
		S("Red Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Red Sandstone Slab"), "mcl_core:redsandstone")	--fixme: extra parameter from previous release

mcl_stairs.register_stair("redsandstonesmooth2", "mcl_core:redsandstonesmooth2",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png"},
		S("Smooth Red Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	0.8, 0.8)
mcl_stairs.register_slab("redsandstonesmooth2", "mcl_core:redsandstonesmooth2",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png"},
		S("Smooth Red Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Smooth Red Sandstone Slab"))

-- Intentionally not group:stonebrick because of mclx_stairs
mcl_stairs.register_stair("stonebrick", "mcl_core:stonebrick",
		{pickaxey=1, material_stone=1},
		{"default_stone_brick.png"},
		S("Stone Bricks Stairs"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		nil)
mcl_stairs.register_slab("stonebrick", "mcl_core:stonebrick",
		{pickaxey=1, material_stone=1},
		{"default_stone_brick.png"},
		S("Stone Bricks Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Stone Bricks Slab"))

mcl_stairs.register_stair("quartzblock", "mcl_nether:quartz_block",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_top.png", "mcl_nether_quartz_block_bottom.png", "mcl_nether_quartz_block_side.png"},
		S("Quartz Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8,
		nil, "mcl_nether:quartz_block")	--fixme: extra parameter from previous release
mcl_stairs.register_slab("quartzblock", "mcl_nether:quartz_block",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_top.png", "mcl_nether_quartz_block_bottom.png", "mcl_nether_quartz_block_side.png"},
		S("Quartz Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Quartz Slab"), "mcl_nether:quartz_block")	--fixme: extra parameter from previous release

mcl_stairs.register_stair("quartz_smooth", "mcl_nether:quartz_smooth",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_bottom.png"},
		S("Smooth Quartz Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, 0.8)
mcl_stairs.register_slab("quartz_smooth", "mcl_nether:quartz_smooth",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_bottom.png"},
		S("Smooth Quartz Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Smooth Quartz Slab"))

mcl_stairs.register_stair_and_slab("nether_brick", "mcl_nether:nether_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_nether_brick.png"},
		S("Nether Brick Stairs"),
		S("Nether Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Nether Brick Slab"), nil)
mcl_stairs.register_stair_and_slab("red_nether_brick", "mcl_nether:red_nether_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_red_nether_brick.png"},
		S("Red Nether Brick Stairs"),
		S("Red Nether Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Red Nether Brick Slab"), nil)

mcl_stairs.register_stair_and_slab("end_bricks", "mcl_end:end_bricks",
		{pickaxey=1, material_stone=1},
		{"mcl_end_end_bricks.png"},
		S("End Stone Brick Stairs"),
		S("End Stone Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double End Stone Brick Slab"), nil)

mcl_stairs.register_stair("purpur_block", "mcl_end:purpur_block",
		{pickaxey=1, material_stone=1},
		{"mcl_end_purpur_block.png"},
		S("Purpur Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	6, 1.5,
		nil)
mcl_stairs.register_slab("purpur_block", "mcl_end:purpur_block",
		{pickaxey=1, material_stone=1},
		{"mcl_end_purpur_block.png"},
		S("Purpur Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Purpur Slab"))

mcl_stairs.register_stair("prismarine", "mcl_ocean:prismarine",
		{pickaxey=1, material_stone=1},
		{{name="mcl_ocean_prismarine_anim.png", animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=45.0}}},
		S("Prismarine Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	6, 1.5,
		nil)
mcl_stairs.register_slab("prismarine", "mcl_ocean:prismarine",
		{pickaxey=1, material_stone=1},
		{{name="mcl_ocean_prismarine_anim.png", animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=45.0}}},
		S("Prismarine Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Prismarine Slab"))

mcl_stairs.register_stair("prismarine_brick", "mcl_ocean:prismarine_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_ocean_prismarine_bricks.png"},
		S("prismarine Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	6, 1.5,
		nil)
mcl_stairs.register_slab("prismarine_brick", "mcl_ocean:prismarine_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_ocean_prismarine_bricks.png"},
		S("prismarine Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double prismarine_brick Slab"))

mcl_stairs.register_stair("prismarine_dark", "mcl_ocean:prismarine_dark",
		{pickaxey=1, material_stone=1},
		{"mcl_ocean_prismarine_dark.png"},
		S("prismarine Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(),	6, 1.5,
		nil)
mcl_stairs.register_slab("prismarine_dark", "mcl_ocean:prismarine_dark",
		{pickaxey=1, material_stone=1},
		{"mcl_ocean_prismarine_dark.png"},
		S("Dark Prismarine Slab"),
		mcl_sounds.node_sound_stone_defaults(),	6, 2,
		S("Double Dark Prismarine Slab"))

mcl_stairs.register_stair_and_slab("mud_brick", "mcl_mud:mud_bricks",
		{pickaxey=1, material_stone=1},
		{"mcl_mud_bricks.png"},
		S("Mud Brick Stairs"),
		S("Mud Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), 6, 2,
		S("Double Mud Brick Slab"), nil)

mcl_stairs.register_slab("andesite_smooth", "mcl_core:andesite_smooth",
		{pickaxey=1},
		{"mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_stairs_andesite_smooth_slab.png"},
		S("Polished Andesite Slab"),
		nil, nil, nil,
		S("Double Polished Andesite Slab"))
mcl_stairs.register_stair("andesite_smooth", "mcl_core:andesite_smooth",
		{pickaxey=1},
		{"mcl_stairs_andesite_smooth_slab.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_stairs_andesite_smooth_slab.png"},
		S("Polished Andesite Stairs"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_slab("granite_smooth", "mcl_core:granite_smooth",
		{pickaxey=1},
		{"mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_stairs_granite_smooth_slab.png"},
		S("Polished Granite Slab"),
		nil, nil, nil,
		S("Double Polished Granite Slab"))
mcl_stairs.register_stair("granite_smooth", "mcl_core:granite_smooth",
		{pickaxey=1},
		{"mcl_stairs_granite_smooth_slab.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_stairs_granite_smooth_slab.png"},
		S("Polished Granite Stairs"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_slab("diorite_smooth", "mcl_core:diorite_smooth",
		{pickaxey=1},
		{"mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_stairs_diorite_smooth_slab.png"},
		S("Polished Diorite Slab"),
		nil, nil, nil,
		S("Double Polished Diorite Slab"))
mcl_stairs.register_stair("diorite_smooth", "mcl_core:diorite_smooth",
		{pickaxey=1},
		{"mcl_stairs_diorite_smooth_slab.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_stairs_diorite_smooth_slab.png"},
		S("Polished Diorite Stairs"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_stair("stonebrickmossy", "mcl_core:stonebrickmossy",
		{pickaxey=1},
		{"mcl_core_stonebrick_mossy.png"},
		S("Mossy Stone Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		nil)

mcl_stairs.register_slab("stonebrickmossy", "mcl_core:stonebrickmossy",
		{pickaxey=1},
		{"mcl_core_stonebrick_mossy.png"},
		S("Mossy Stone Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Mossy Stone Brick Slab"))

