local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local C = minetest.colorize

local longdesc = S(
	"Ender chests grant you access to a single personal interdimensional inventory with 27 slots. This " ..
	"inventory is the same no matter from which ender chest you access it from. If you put one item into one " ..
	"ender chest, you will find it in all other ender chests. Each player will only see their own items, but " ..
	"not the items of other players."
)

minetest.register_node("mcl_chests:ender_chest", {
	description = S("Ender Chest"),
	_tt_help = S("27 interdimensional inventory slots") ..
		"\n" .. S("Put items inside, retrieve them from any ender chest"),
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = S("Rightclick the ender chest to access your personal interdimensional inventory."),
	drawtype = "mesh",
	mesh = "mcl_chests_chest.b3d",
	tiles = mcl_chests.tiles.chest_ender_small,
	use_texture_alpha = "opaque",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_construct = function(pos)
		local node = minetest.get_node(pos)
		node.name = "mcl_chests:ender_chest_small"
		minetest.set_node(pos, node)
	end,
})

local formspec_ender_chest = table.concat({
	"formspec_version[4]",
	"size[11.75,10.425]",

	"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Ender Chest"))) .. "]",
	mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
	"list[current_player;enderchest;0.375,0.75;9,3;]",
	"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
	mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
	"list[current_player;main;0.375,5.1;9,3;9]",

	mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
	"list[current_player;main;0.375,9.05;9,1;]",

	"listring[current_player;enderchest]",
	"listring[current_player;main]",
})

minetest.register_node("mcl_chests:ender_chest_small", {
	description = S("Ender Chest"),
	_tt_help = S("27 interdimensional inventory slots") ..
		"\n" .. S("Put items inside, retrieve them from any ender chest"),
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = S("Rightclick the ender chest to access your personal interdimensional inventory."),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.4375, -0.5, -0.4375, 0.4375, 0.375, 0.4375 },
	},
	_chest_entity_textures = mcl_chests.tiles.ender_chest_texture,
	_chest_entity_sound = "mcl_chests_enderchest",
	_chest_entity_mesh = "mcl_chests_chest",
	_chest_entity_animation_type = "chest",
	tiles = { "blank.png^[resize:16x16" },
	use_texture_alpha = "clip",
	-- Note: The “container” group is missing here because the ender chest does not
	-- have an inventory on its own
	groups = { pickaxey = 1, deco_block = 1, material_stone = 1, chest_entity = 1, not_in_creative_inventory = 1 },
	is_ground_content = false,
	paramtype = "light",
	light_source = 7,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_stone_defaults(),
	drop = "mcl_core:obsidian 8",
	on_construct = function(pos)
		mcl_chests.create_entity(pos, "mcl_chests:ender_chest_small", mcl_chests.tiles.ender_chest_texture,
			minetest.get_node(pos).param2, false, "mcl_chests_enderchest", "mcl_chests_chest", "chest")
	end,
	on_rightclick = function(pos, node, clicker)
		if minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name].groups.opaque == 1 then
			-- won't open if there is no space from the top
			return false
		end
		minetest.show_formspec(clicker:get_player_name(), "mcl_chests:ender_chest_" .. clicker:get_player_name(),
			formspec_ender_chest)
		mcl_chests.player_chest_open(clicker, pos, "mcl_chests:ender_chest_small",
			mcl_chests.tiles.ender_chest_texture, node.param2, false, "mcl_chests_enderchest",
			"mcl_chests_chest")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.quit then
			mcl_chests.player_chest_close(sender)
		end
	end,
	_mcl_blast_resistance = 3000,
	_mcl_hardness = 22.5,
	_mcl_silk_touch_drop = { "mcl_chests:ender_chest" },
	on_rotate = simple_rotate,
})

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	inv:set_size("enderchest", 9 * 3)
end)

minetest.register_allow_player_inventory_action(function(player, action, inv, info)
	if inv:get_location().type == "player" and (
			action == "move" and (info.from_list == "enderchest" or info.to_list == "enderchest")
			or action == "put" and info.listname == "enderchest"
			or action == "take" and info.listname == "enderchest") then
		local def = player:get_wielded_item():get_definition()
		local range = (def and def.range or player:get_inventory():get_stack("hand", 1):get_definition().range) + 1
		if not minetest.find_node_near(player:get_pos(), range, "mcl_chests:ender_chest_small", true) then
			return 0
		end
	end
end)

minetest.register_craft({
	output = "mcl_chests:ender_chest",
	recipe = {
		{ "mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian" },
		{ "mcl_core:obsidian", "mcl_end:ender_eye", "mcl_core:obsidian" },
		{ "mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian" },
	},
})

minetest.register_lbm({
	label = "Upgrade old ender chest formspec",
	name = "mcl_chests:replace_old_ender_form",
	nodenames = { "mcl_chests:ender_chest_small" },
	run_at_every_load = false,
	action = function(pos, node)
		minetest.get_meta(pos):set_string("formspec", "")
	end,
})
