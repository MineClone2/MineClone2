local string = string
local table = table
local math = math

local sm = string.match

mcl_chests = {}

-- Christmas chest setup
local it_is_christmas = mcl_util.is_it_christmas()

local tiles = { -- extensions will be added later
	chest_normal_small = { "mcl_chests_normal" },
	chest_normal_double = { "mcl_chests_normal_double" },
	chest_trapped_small = { "mcl_chests_trapped" },
	chest_trapped_double = { "mcl_chests_trapped_double" },
	chest_ender_small = { "mcl_chests_ender" },
	ender_chest_texture = { "mcl_chests_ender" },
}

local tiles_postfix = ".png"
local tiles_postfix_double = ".png"
if it_is_christmas then
	tiles_postfix = "_present.png^mcl_chests_noise.png"
	tiles_postfix_double = "_present.png^mcl_chests_noise_double.png"
end

-- Append the postfixes for each entry
for k,v in pairs(tiles) do
	if not sm(k, "double") then
		tiles[k] = {v[1] .. tiles_postfix}
	else
		tiles[k] = {v[1] .. tiles_postfix_double}
	end
end

mcl_chests.tiles = tiles

local modpath = minetest.get_modpath("mcl_chests")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/chests.lua")
dofile(modpath .. "/ender.lua")
dofile(modpath .. "/shulkers.lua")



-- Disable chest when it has been closed
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:find("mcl_chests:") == 1 then
		if fields.quit then
			mcl_chests.player_chest_close(player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	mcl_chests.player_chest_close(player)
end)



local function select_and_spawn_entity(pos, node)
	local node_name = node.name
	local node_def = minetest.registered_nodes[node_name]
	local double_chest = minetest.get_item_group(node_name, "double_chest") > 0
	mcl_chests.find_or_create_entity(pos, node_name, node_def._chest_entity_textures, node.param2, double_chest,
		node_def._chest_entity_sound, node_def._chest_entity_mesh, node_def._chest_entity_animation_type)
end

minetest.register_lbm({
	label = "Spawn Chest entities",
	name = "mcl_chests:spawn_chest_entities",
	nodenames = { "group:chest_entity" },
	run_at_every_load = true,
	action = select_and_spawn_entity,
})

minetest.register_lbm({
	label = "Replace old chest nodes",
	name = "mcl_chests:replace_old",
	nodenames = {
		"mcl_chests:chest",
		"mcl_chests:trapped_chest",
		"mcl_chests:trapped_chest_on",
		"mcl_chests:ender_chest",
		"group:old_shulker_box_node"
	},
	run_at_every_load = true,
	action = function(pos, node)
		local node_name = node.name
		node.name = node_name .. "_small"
		minetest.swap_node(pos, node)
		select_and_spawn_entity(pos, node)
		if node_name == "mcl_chests:trapped_chest_on" then
			minetest.log("action", "[mcl_chests] Disabled active trapped chest on load: " .. minetest.pos_to_string(pos))
			mcl_chests.chest_update_after_close(pos)
		elseif node_name == "mcl_chests:ender_chest" then
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", formspec_ender_chest)
		end
	end
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

minetest.register_lbm({
	label = "Upgrade old ender chest formspec",
	name = "mcl_chests:replace_old_ender_form",
	nodenames = { "mcl_chests:ender_chest_small" },
	run_at_every_load = false,
	action = function(pos, node)
		minetest.get_meta(pos):set_string("formspec", "")
	end,
})
