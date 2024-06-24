local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local C = minetest.colorize
local get_double_container_neighbor_pos = mcl_util.get_double_container_neighbor_pos
local trapped_chest_mesecons_rules = mesecon.rules.pplate

mcl_chests.register_chest("stone_chest", {
	desc = S("Stone Chest"),
	large_desc = S("Large Stone Chest"),
	longdesc = S(
		"Stone Chests are containers which provide 27 inventory slots. Stone Chests can be turned into" ..
		"large stone chests with double the capacity by placing two stone chests next to each other."
	),
	usagehelp = S("To access its inventory, rightclick it. When broken, the items will drop out."),
	tt_help = S("27 inventory slots") .. "\n" .. S("Can be combined to a large stone chest"),
	tiles = {
		small = { mcl_chests.tiles.chest_normal_small[1] .. "^[hsl:-15:-80:-20" },
		double = { mcl_chests.tiles.chest_normal_double[1] .. "^[hsl:-15:-80:-20" },
		inv = { "default_chest_top.png^[hsl:-15:-80:-20",
			"mcl_chests_chest_bottom.png^[hsl:-15:-80:-20",
			"mcl_chests_chest_right.png^[hsl:-15:-80:-20",
			"mcl_chests_chest_left.png^[hsl:-15:-80:-20",
			"mcl_chests_chest_back.png^[hsl:-15:-80:-20",
			"default_chest_front.png^[hsl:-15:-80:-20"
		},
	},
	groups = {
		pickaxey = 1,
		stone = 1,
		material_stone = 1,
	},
	sounds = {
		mcl_sounds.node_sound_stone_defaults(),
		"mcl_chests_enderchest"
	},
	hardness = 4.0,
	hidden = false,
	-- It bites!
	on_rightclick = function(pos, node, clicker)
		mcl_util.deal_damage(clicker, 2)
	end,
})

minetest.register_craft({
	output = "mcl_chests:stone_chest",
	recipe = {
		{ "mcl_core:stone", "mcl_core:stone", "mcl_core:stone" },
		{ "mcl_core:stone", "",               "mcl_core:stone" },
		{ "mcl_core:stone", "mcl_core:stone", "mcl_core:stone" },
	},
})
