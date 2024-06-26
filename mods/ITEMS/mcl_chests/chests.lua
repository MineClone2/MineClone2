local S = minetest.get_translator(minetest.get_current_modname())
local get_double_container_neighbor_pos = mcl_util.get_double_container_neighbor_pos

local chestusage = S("To access its inventory, rightclick it. When broken, the items will drop out.")

mcl_chests.register_chest("chest", {
	desc = S("Chest"),
	longdesc = S(
		"Chests are containers which provide 27 inventory slots. Chests can be turned into large chests with " ..
		"double the capacity by placing two chests next to each other."
	),
	usagehelp = chestusage,
	tt_help = S("27 inventory slots") .. "\n" .. S("Can be combined to a large chest"),
	tiles = {
		small = mcl_chests.tiles.chest_normal_small,
		double = mcl_chests.tiles.chest_normal_double,
		inv = { "default_chest_top.png", "mcl_chests_chest_bottom.png",
			"mcl_chests_chest_right.png", "mcl_chests_chest_left.png",
			"mcl_chests_chest_back.png", "default_chest_front.png" },
	},
	groups = {
		handy = 1,
		axey = 1,
		material_wood = 1,
		flammable = -1,
	},
	sounds = { mcl_sounds.node_sound_wood_defaults() },
	hardness = 2.5,
	hidden = false,
})

local traptiles = {
	small = mcl_chests.tiles.chest_trapped_small,
	double = mcl_chests.tiles.chest_trapped_double,
}

mcl_chests.register_chest("trapped_chest", {
	desc = S("Trapped Chest"),
	title = {
		small = S("Chest"),
		double = S("Large Chest")
	},
	longdesc = S(
		"A trapped chest is a container which provides 27 inventory slots. When it is opened, it sends a redstone " ..
		"signal to its adjacent blocks as long it stays open. Trapped chests can be turned into large trapped " ..
		"chests with double the capacity by placing two trapped chests next to each other."
	),
	usagehelp = chestusage,
	tt_help = S("27 inventory slots") ..
		"\n" .. S("Can be combined to a large chest") .. "\n" .. S("Emits a redstone signal when opened"),
	tiles = traptiles,
	groups = {
		handy = 1,
		axey = 1,
		material_wood = 1,
		flammable = -1,
		mesecon = 2,
	},
	sounds = { mcl_sounds.node_sound_wood_defaults() },
	hardness = 2.5,
	hidden = false,
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = mesecon.rules.pplate,
		},
	},
	on_rightclick = function(pos, node, clicker)
		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_on_small", param2 = node.param2 })
		mcl_chests.find_or_create_entity(pos, "mcl_chests:trapped_chest_on_small", { "mcl_chests_trapped.png" },
			node.param2, false, "default_chest", "mcl_chests_chest", "chest")
			:reinitialize("mcl_chests:trapped_chest_on_small")
		mesecon.receptor_on(pos, mesecon.rules.pplate)
	end,
	on_rightclick_left = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_int("players", 1)

		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_on_left", param2 = node.param2 })
		mcl_chests.find_or_create_entity(pos, "mcl_chests:trapped_chest_on_left",
			mcl_chests.tiles.chest_trapped_double, node.param2, true, "default_chest", "mcl_chests_chest",
			"chest"):reinitialize("mcl_chests:trapped_chest_on_left")
		mesecon.receptor_on(pos, mesecon.rules.pplate)

		local pos_other = get_double_container_neighbor_pos(pos, node.param2, "left")
		minetest.swap_node(pos_other, { name = "mcl_chests:trapped_chest_on_right", param2 = node.param2 })
		mesecon.receptor_on(pos_other, mesecon.rules.pplate)
	end,
	on_rightclick_right = function(pos, node, clicker)
		local pos_other = get_double_container_neighbor_pos(pos, node.param2, "right")

		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_on_right", param2 = node.param2 })
		mesecon.receptor_on(pos, mesecon.rules.pplate)

		minetest.swap_node(pos_other, { name = "mcl_chests:trapped_chest_on_left", param2 = node.param2 })
		mcl_chests.find_or_create_entity(pos_other, "mcl_chests:trapped_chest_on_left",
			mcl_chests.tiles.chest_trapped_double, node.param2, true, "default_chest", "mcl_chests_chest",
			"chest"):reinitialize("mcl_chests:trapped_chest_on_left")
		mesecon.receptor_on(pos_other, mesecon.rules.pplate)
	end
})

mcl_chests.register_chest("trapped_chest_on", {
	desc = nil,
	title = {
		small = S("Chest"),
		double = S("Large Chest")
	},
	longdesc = nil,
	usagehelp = nil,
	tt_help = nil,
	tiles = traptiles,
	groups = {
		handy = 1,
		axey = 1,
		material_wood = 1,
		flammable = -1,
		mesecon = 2,
	},
	sounds = { mcl_sounds.node_sound_wood_defaults() },
	hardness = 2.5,
	hidden = true,
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = mesecon.rules.pplate,
		},
	},
	on_rightclick = nil,
	on_rightclick_left = nil,
	on_rightclick_right = nil,
	drop = "trapped_chest",
	canonical_basename = "trapped_chest"
})

minetest.register_craft({
	output = "mcl_chests:chest",
	recipe = {
		{ "group:wood", "group:wood", "group:wood" },
		{ "group:wood", "",           "group:wood" },
		{ "group:wood", "group:wood", "group:wood" },
	},
})

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_chests:chest",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_chests:trapped_chest",
	burntime = 15,
})

-- Disable active/open trapped chests when loaded because nobody could have them open at loading time.
-- Fixes redstone weirdness.
minetest.register_lbm({
	label = "Disable active trapped chests",
	name = "mcl_chests:reset_trapped_chests",
	nodenames = {
		"mcl_chests:trapped_chest_on_small",
		"mcl_chests:trapped_chest_on_left",
		"mcl_chests:trapped_chest_on_right"
	},
	run_at_every_load = true,
	action = function(pos, node)
		minetest.log("action", "[mcl_chests] Disabled active trapped chest on load: " .. minetest.pos_to_string(pos))
		mcl_chests.chest_update_after_close(pos)
	end,
})
