local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)
-- Warped and Crimson fungus
-- by debiankaios
-- adapted for mcl2 by cora

local wood_slab_groups = {handy = 1, axey = 1, material_wood = 1, wood_slab = 1}
local wood_stair_groups = {handy = 1, axey = 1, material_wood = 1, wood_stairs = 1}

local function generate_warped_tree(pos)
	minetest.place_schematic(pos,modpath.."/schematics/warped_fungus_1.mts","random",nil,false,"place_center_x,place_center_z")
end

function generate_crimson_tree(pos)
	minetest.place_schematic(pos,modpath.."/schematics/crimson_fungus_1.mts","random",nil,false,"place_center_x,place_center_z")
end

function grow_vines(pos, moreontop ,vine, dir)
	if dir == nil then dir = 1 end
	local n
	repeat
		pos = vector.offset(pos,0,dir,0)
		n = minetest.get_node(pos)
		if n.name == "air" then
			for i=0,math.max(moreontop,1) do
				if minetest.get_node(pos).name == "air" then
					minetest.set_node(vector.offset(pos,0,i*dir,0),{name=vine})
				end
			end
			break
		end
	until n.name ~= "air" and n.name ~= vine
end

local nether_plants = {
	["mcl_crimson:crimson_nylium"] = {
		"mcl_crimson:crimson_roots",
		"mcl_crimson:crimson_fungus",
		"mcl_crimson:warped_fungus",
	},
	["mcl_crimson:warped_nylium"] = {
		"mcl_crimson:warped_roots",
		"mcl_crimson:warped_fungus",
		"mcl_crimson:twisting_vines",
		"mcl_crimson:nether_sprouts",
	},
}

local function has_nylium_neighbor(pos)
	local p = minetest.find_node_near(pos,1,{"mcl_crimson:warped_nylium","mcl_crimson:crimson_nylium"})
	if p then
		return minetest.get_node(p)
	end
end

local function spread_nether_plants(pos,node)
	local n = node.name
	local nn = minetest.find_nodes_in_area_under_air(vector.offset(pos,-5,-3,-5),vector.offset(pos,5,3,5),{n})
	table.shuffle(nn)
	nn[1] = pos
	for i=1,math.random(1,math.min(#nn,12)) do
		local p = vector.offset(nn[i],0,1,0)
		if minetest.get_node(p).name == "air" then
			minetest.set_node(p,{name=nether_plants[n][math.random(#nether_plants[n])]})
			mcl_dye.add_bone_meal_particle(vector.offset(nn[i],0,1,0))
		end
	end
end

minetest.register_node("mcl_crimson:warped_fungus", {
	description = S("Warped Fungus"),
	_tt_help = S("Warped fungus is a mushroom found in the nether's warped forest."),
	_doc_items_longdesc = S("Warped fungus is a mushroom found in the nether's warped forest."),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_warped_fungus.png" },
	inventory_image = "mcl_crimson_warped_fungus.png",
	wield_image = "mcl_crimson_warped_fungus.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = {dig_immediate=3,mushroom=1,attached_node=1,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,enderman_takable=1,deco_block=1,compostability=65},
	light_source = 1,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	node_placement_prediction = "",
	on_rightclick = function(pos, node, pointed_thing, player, itemstack)
		if pointed_thing:get_wielded_item():get_name() == "mcl_bone_meal:bone_meal" then
			local nodepos = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
			if nodepos.name == "mcl_crimson:warped_nylium" or nodepos.name == "mcl_nether:netherrack" then
				local random = math.random(1, 5)
				if random == 1 then
					minetest.remove_node(pos)
					generate_warped_tree(pos)
				end
			end
		end
	end,
	_mcl_blast_resistance = 0,
})

mcl_flowerpots.register_potted_flower("mcl_crimson:warped_fungus", {
	name = "warped_fungus",
	desc = S("Warped Fungus"),
	image = "mcl_crimson_warped_fungus.png",
})

minetest.register_node("mcl_crimson:twisting_vines", {
	description = S("Twisting Vines"),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_twisting_vines_plant.png" },
	inventory_image = "mcl_crimson_twisting_vines.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	climbable = true,
	buildable_to = true,
	groups = {dig_immediate=3, shearsy=1, vines=1, dig_by_water=1, destroy_by_lava_flow=1, dig_by_piston=1, deco_block=1, compostability=50},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -3/16, -0.5, -3/16, 3/16, 0.5, 3/16 },
	},
	node_placement_prediction = "",
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local pn = clicker:get_player_name()
		if clicker:is_player() and minetest.is_protected(vector.offset(pos,0,1,0), pn or "") then
			minetest.record_protection_violation(vector.offset(pos,0,1,0), pn)
			return itemstack
		end
		if clicker:get_wielded_item():get_name() == "mcl_crimson:twisting_vines" then
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
			grow_vines(pos, 1, "mcl_crimson:twisting_vines")
			local idef = itemstack:get_definition()
			local itemstack, success = minetest.item_place_node(itemstack, placer, pointed_thing)
			if success then
				if idef.sounds and idef.sounds.place then
				minetest.sound_play(idef.sounds.place, {pos=above, gain=1}, true)
			end
		end

		elseif clicker:get_wielded_item():get_name() == "mcl_bone_meal:bone_meal" then
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
			grow_vines(pos, math.random(1, 3),"mcl_crimson:twisting_vines")
		end
		return itemstack
	end,
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local above = pointed_thing.above
		local unode = minetest.get_node(under)
		if under.y < above.y then
			minetest.set_node(above, {name = "mcl_crimson:twisting_vines"})
			if not minetest.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		else
			if unode.name == "mcl_crimson:twisting_vines" then
				return minetest.registered_nodes[unode.name].on_rightclick(under, unode, placer, itemstack, pointed_thing)
			end
		end
		return itemstack
	end,
	on_dig = function(pos, node, digger)
		local above = vector.offset(pos,0,1,0)
		local abovenode = minetest.get_node(above)
		minetest.node_dig(pos, node, digger)
		if abovenode.name == node.name and (not mcl_core.check_vines_supported(above, abovenode)) then
			minetest.registered_nodes[node.name].on_dig(above, node, digger)
		end
	end,

	drop = {
		max_items = 1,
		items = {
			{items = {"mcl_crimson:twisting_vines"}, rarity = 3},
		},
	},
	_mcl_shears_drop = true,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = {
		items = {
			{items = {"mcl_crimson:twisting_vines"}, rarity = 3},
		},
		items = {
			{items = {"mcl_crimson:twisting_vines"}, rarity = 1.8181818181818181},
		},
		"mcl_crimson:twisting_vines",
		"mcl_crimson:twisting_vines",
	},
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_crimson:weeping_vines", {
	description = S("Weeping Vines"),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_weeping_vines.png" },
	inventory_image = "mcl_crimson_weeping_vines.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	climbable = true,
	buildable_to = true,
	groups = {dig_immediate=3, shearsy=1, vines=1, dig_by_water=1, destroy_by_lava_flow=1, dig_by_piston=1, deco_block=1, compostability=50},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -3/16, -0.5, -3/16, 3/16, 0.5, 3/16 },
	},
	node_placement_prediction = "",
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local pn = clicker:get_player_name()
		if clicker:is_player() and minetest.is_protected(vector.offset(pos,0,1,0), pn or "") then
			minetest.record_protection_violation(vector.offset(pos,0,1,0), pn)
			return itemstack
		end
		if clicker:get_wielded_item():get_name() == "mcl_crimson:weeping_vines" then
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
			grow_vines(pos, 1, "mcl_crimson:weeping_vines", -1)
			local idef = itemstack:get_definition()
			local itemstack, success = minetest.item_place_node(itemstack, placer, pointed_thing)
			if success then
				if idef.sounds and idef.sounds.place then
				minetest.sound_play(idef.sounds.place, {pos=above, gain=1}, true)
			end
		end

		elseif clicker:get_wielded_item():get_name() == "mcl_bone_meal:bone_meal" then
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
			grow_vines(pos, math.random(1, 3),"mcl_crimson:weeping_vines", -1)
		end
		return itemstack
	end,
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local above = pointed_thing.above
		local unode = minetest.get_node(under)
		if under.y > above.y then
			minetest.set_node(above, {name = "mcl_crimson:weeping_vines"})
			if not minetest.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		else
			if unode.name == "mcl_crimson:weeping_vines" then
				return minetest.registered_nodes[unode.name].on_rightclick(under, unode, placer, itemstack, pointed_thing)
			end
		end
		return itemstack
	end,
	on_dig = function(pos, node, digger)
		local below = vector.offset(pos,0,-1,0)
		local belownode = minetest.get_node(below)
		minetest.node_dig(pos, node, digger)
		if belownode.name == node.name and (not mcl_core.check_vines_supported(below, belownode)) then
			minetest.registered_nodes[node.name].on_dig(below, node, digger)
		end
	end,
	drop = {
		max_items = 1,
		items = {
			{items = {"mcl_crimson:weeping_vines"}, rarity = 3},
		},
	},
	_mcl_shears_drop = true,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = {
		items = {
			{items = {"mcl_crimson:weeping_vines"}, rarity = 3},
		},
		items = {
			{items = {"mcl_crimson:weeping_vines"}, rarity = 1.8181818181818181},
		},
		"mcl_crimson:weeping_vines",
		"mcl_crimson:weeping_vines",
	},
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_crimson:nether_sprouts", {
	description = S("Nether Sprouts"),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_nether_sprouts.png" },
	inventory_image = "mcl_crimson_nether_sprouts.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	groups = {dig_immediate=3,vines=1,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,deco_block=1,shearsy=1,compostability=50},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -4/16, -0.5, -4/16, 4/16, 0, 4/16 },
	},
	node_placement_prediction = "",
	drop = "",
	_mcl_shears_drop = true,
	_mcl_silk_touch_drop = false,
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_crimson:warped_roots", {
	description = S("Warped Roots"),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_warped_roots.png" },
	inventory_image = "mcl_crimson_warped_roots.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	groups = {dig_immediate=3,vines=1,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,deco_block=1,shearsy = 1,compostability=65},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -0.5, -6/16, 6/16, -4/16, 6/16 },
	},
	node_placement_prediction = "",
	_mcl_silk_touch_drop = false,
	_mcl_blast_resistance = 0,
})

mcl_flowerpots.register_potted_flower("mcl_crimson:warped_roots", {
	name = "warped_roots",
	desc = S("Warped Roots"),
	image = "mcl_crimson_warped_roots.png",
})


minetest.register_node("mcl_crimson:warped_wart_block", {
	description = S("Warped Wart Block"),
	tiles = {"mcl_crimson_warped_wart_block.png"},
	groups = {handy = 1, hoey = 7, swordy = 1, deco_block = 1, compostability = 85},
	_mcl_hardness = 1,
	sounds = mcl_sounds.node_sound_leaves_defaults({
			footstep={name="default_dirt_footstep", gain=0.7},
			dug={name="default_dirt_footstep", gain=1.5},
	}),
})

minetest.register_node("mcl_crimson:shroomlight", {
	description = S("Shroomlight"),
	tiles = {"mcl_crimson_shroomlight.png"},
	groups = {handy = 1, hoey = 7, swordy = 1, deco_block = 1, compostability = 65},
	light_source = minetest.LIGHT_MAX,
	_mcl_hardness = 1,
	sounds = mcl_sounds.node_sound_leaves_defaults({
			footstep={name="default_dirt_footstep", gain=0.7},
			dug={name="default_dirt_footstep", gain=1.5},
	}),
})

minetest.register_node("mcl_crimson:warped_hyphae", {
	description = S("Warped Hyphae"),
	_doc_items_longdesc = S("The stem of a warped hyphae"),
	_doc_items_hidden = false,
	tiles = {
		"mcl_crimson_warped_hyphae.png",
		"mcl_crimson_warped_hyphae.png",
		{
			name = "mcl_crimson_warped_hyphae_side.png",
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
		},
	},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, tree = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_stripped_variant = "mcl_crimson:stripped_warped_hyphae",
})

minetest.register_node("mcl_crimson:warped_nylium", {
	description = S("Warped Nylium"),
	tiles = {
		"mcl_crimson_warped_nylium.png",
		"mcl_nether_netherrack.png",
		"mcl_nether_netherrack.png^mcl_crimson_warped_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_warped_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_warped_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_warped_nylium_side.png",
	},
	is_ground_content = true,
	drop = "mcl_nether:netherrack",
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_hardness = 0.4,
	_mcl_blast_resistance = 0.4,
	_mcl_silk_touch_drop = true,
})

--Stem bark, stripped stem and bark

minetest.register_node("mcl_crimson:warped_hyphae_bark", {
	description = S("Warped Hyphae Bark"),
	_doc_items_longdesc = S("This is a decorative block surrounded by the bark of an hyphae."),
	tiles = {
	{
		name = "mcl_crimson_warped_hyphae_side.png",
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
	},
	},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, bark = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	is_ground_content = false,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_stripped_variant = "mcl_crimson:stripped_warped_hyphae_bark",
})

minetest.register_craft({
	output = "mcl_crimson:warped_hyphae_bark 3",
	recipe = {
		{ "mcl_crimson:warped_hyphae", "mcl_crimson:warped_hyphae" },
		{ "mcl_crimson:warped_hyphae", "mcl_crimson:warped_hyphae" },
	},
})

minetest.register_node("mcl_crimson:stripped_warped_hyphae", {
	description = S("Stripped Warped Hyphae"),
	_doc_items_longdesc = S("The stripped hyphae of a warped fungus"),
	_doc_items_hidden = false,
	tiles = {"mcl_crimson_warped_stem_stripped_top.png", "mcl_crimson_warped_stem_stripped_top.png", "mcl_crimson_warped_stem_stripped_side.png"},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, tree = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
})

minetest.register_node("mcl_crimson:stripped_warped_hyphae_bark", {
	description = S("Stripped Warped Hyphae Bark"),
	_doc_items_longdesc = S("The stripped hyphae bark of a warped fungus"),
	tiles = {"mcl_crimson_warped_stem_stripped_side.png"},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, bark = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	is_ground_content = false,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
})

minetest.register_craft({
	output = "mcl_crimson:stripped_warped_hyphae_bark 3",
	recipe = {
		{ "mcl_crimson:stripped_warped_hyphae", "mcl_crimson:stripped_warped_hyphae" },
		{ "mcl_crimson:stripped_warped_hyphae", "mcl_crimson:stripped_warped_hyphae" },
	},
})

minetest.register_node("mcl_crimson:warped_hyphae_wood", {
	description = S("Warped Hyphae Wood"),
	tiles = {"mcl_crimson_warped_hyphae_wood.png"},
	groups = {handy = 5,axey = 1, wood=1,building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 2,
})

mcl_stairs.register_stair("warped_hyphae_wood", "mcl_crimson:warped_hyphae_wood", wood_stair_groups, false, S("Warped Stair"))
mcl_stairs.register_slab("warped_hyphae_wood", "mcl_crimson:warped_hyphae_wood", wood_slab_groups, false, S("Warped Slab"))

minetest.register_craft({
	output = "mcl_crimson:warped_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:warped_hyphae"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:warped_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:warped_hyphae_bark"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:warped_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:stripped_warped_hyphae"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:warped_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:stripped_warped_hyphae_bark"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:warped_nylium 2",
	recipe = {
		{"mcl_crimson:warped_wart_block"},
		{"mcl_nether:netherrack"},
	},
})

minetest.register_node("mcl_crimson:crimson_fungus", {
	description = S("Crimson Fungus"),
	_tt_help = S("Crimson fungus is a mushroom found in the nether's crimson forest."),
	_doc_items_longdesc = S("Crimson fungus is a mushroom found in the nether's crimson forest."),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_crimson_fungus.png" },
	inventory_image = "mcl_crimson_crimson_fungus.png",
	wield_image = "mcl_crimson_crimson_fungus.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = {dig_immediate=3,mushroom=1,attached_node=1,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,enderman_takable=1,deco_block=1,compostability=65},
	light_source = 1,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -3/16, -0.5, -3/16, 3/16, -2/16, 3/16 },
	},
	node_placement_prediction = "",
	on_rightclick = function(pos, node, pointed_thing, player)
		if pointed_thing:get_wielded_item():get_name() == "mcl_bone_meal:bone_meal" then
			local nodepos = minetest.get_node(vector.offset(pos, 0, -1, 0))
			if nodepos.name == "mcl_crimson:crimson_nylium" or nodepos.name == "mcl_nether:netherrack" then
				local random = math.random(1, 5)
				if random == 1 then
					minetest.remove_node(pos)
					generate_crimson_tree(pos)
				end
			end
		end
	end,
	_mcl_blast_resistance = 0,
})

mcl_flowerpots.register_potted_flower("mcl_crimson:crimson_fungus", {
	name = "crimson_fungus",
	desc = S("Crimson Fungus"),
	image = "mcl_crimson_crimson_fungus.png",
})

minetest.register_node("mcl_crimson:crimson_roots", {
	description = S("Crimson Roots"),
	drawtype = "plantlike",
	tiles = { "mcl_crimson_crimson_roots.png" },
	inventory_image = "mcl_crimson_crimson_roots.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	groups = {dig_immediate=3,vines=1,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,deco_block=1,shearsy = 1,compostability=65},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -0.5, -6/16, 6/16, -4/16, 6/16 },
	},
	node_placement_prediction = "",
	_mcl_silk_touch_drop = false,
	_mcl_blast_resistance = 0,
})

mcl_flowerpots.register_potted_flower("mcl_crimson:crimson_roots", {
	name = "crimson_roots",
	desc = S("Crimson Roots"),
	image = "mcl_crimson_crimson_roots.png",
})

minetest.register_node("mcl_crimson:crimson_hyphae", {
	description = S("Crimson Hyphae"),
	_doc_items_longdesc = S("The stem of a crimson hyphae"),
	_doc_items_hidden = false,
	tiles = {
		"mcl_crimson_crimson_hyphae.png",
		"mcl_crimson_crimson_hyphae.png",
		{
			name = "mcl_crimson_crimson_hyphae_side.png",
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
		},
	},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, tree = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_stripped_variant = "mcl_crimson:stripped_crimson_hyphae",
})

--Stem bark, stripped stem and bark

minetest.register_node("mcl_crimson:crimson_hyphae_bark", {
	description = S("Crimson Hyphae Bark"),
	_doc_items_longdesc = S("This is a decorative block surrounded by the bark of an hyphae."),
	tiles = {
	{
		name = "mcl_crimson_crimson_hyphae_side.png",
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
	},
	},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, bark = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	is_ground_content = false,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_stripped_variant = "mcl_crimson:stripped_crimson_hyphae_bark",
})

minetest.register_craft({
	output = "mcl_crimson:crimson_hyphae_bark 3",
	recipe = {
		{ "mcl_crimson:crimson_hyphae", "mcl_crimson:crimson_hyphae" },
		{ "mcl_crimson:crimson_hyphae", "mcl_crimson:crimson_hyphae" },
	},
})

minetest.register_node("mcl_crimson:stripped_crimson_hyphae", {
	description = S("Stripped Crimson Hyphae"),
	_doc_items_longdesc = S("The stripped stem of a crimson hyphae"),
	_doc_items_hidden = false,
	tiles = {"mcl_crimson_crimson_stem_stripped_top.png", "mcl_crimson_crimson_stem_stripped_top.png", "mcl_crimson_crimson_stem_stripped_side.png"},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, tree = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
})

minetest.register_node("mcl_crimson:stripped_crimson_hyphae_bark", {
	description =	S("Stripped Crimson Hyphae Bark"),
	_doc_items_longdesc = S("The stripped wood of a crimson hyphae"),
	tiles = {"mcl_crimson_crimson_stem_stripped_side.png"},
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {handy = 1, axey = 1, bark = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	is_ground_content = false,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
})

minetest.register_craft({
	output = "mcl_crimson:stripped_crimson_hyphae_bark 3",
	recipe = {
		{ "mcl_crimson:stripped_crimson_hyphae", "mcl_crimson:stripped_crimson_hyphae" },
		{ "mcl_crimson:stripped_crimson_hyphae", "mcl_crimson:stripped_crimson_hyphae" },
	},
})

minetest.register_node("mcl_crimson:crimson_hyphae_wood", {
	description = S("Crimson Hyphae Wood"),
	tiles = {"mcl_crimson_crimson_hyphae_wood.png"},
	groups = {handy = 5, axey = 1, wood = 1, building_block = 1, material_wood = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 2,
})

minetest.register_node("mcl_crimson:crimson_nylium", {
	description = S("Crimson Nylium"),
	tiles = {
		"mcl_crimson_crimson_nylium.png",
		"mcl_nether_netherrack.png",
		"mcl_nether_netherrack.png^mcl_crimson_crimson_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_crimson_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_crimson_nylium_side.png",
		"mcl_nether_netherrack.png^mcl_crimson_crimson_nylium_side.png",
	},
	groups = {pickaxey = 1, building_block = 1, material_stone = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = true,
	drop = "mcl_nether:netherrack",
	_mcl_hardness = 0.4,
	_mcl_blast_resistance = 0.4,
	_mcl_silk_touch_drop = true,
})

minetest.register_craft({
	output = "mcl_crimson:crimson_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:crimson_hyphae"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:crimson_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:crimson_hyphae_bark"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:crimson_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:stripped_crimson_hyphae"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:crimson_hyphae_wood 4",
	recipe = {
		{"mcl_crimson:stripped_crimson_hyphae_bark"},
	},
})

minetest.register_craft({
	output = "mcl_crimson:crimson_nylium 2",
	recipe = {
		{"mcl_nether:nether_wart"},
		{"mcl_nether:netherrack"},
	},
})

mcl_stairs.register_stair("crimson_hyphae_wood", "mcl_crimson:crimson_hyphae_wood", wood_stair_groups, false, S("Crimson Stair"))
mcl_stairs.register_slab("crimson_hyphae_wood", "mcl_crimson:crimson_hyphae_wood", wood_slab_groups, false, S("Crimson Slab"))

mcl_dye.register_on_bone_meal_apply(function(pt,user)
	if not pt.type == "node" then return end
	local node = minetest.get_node(pt.under)
	if node.name == "mcl_nether:netherrack" then
		local n = has_nylium_neighbor(pt.under)
		if n then
			minetest.set_node(pt.under,n)
		end
	elseif node.name == "mcl_crimson:warped_nylium" or node.name == "mcl_crimson:crimson_nylium" then
		spread_nether_plants(pt.under,node)
	end
end)

minetest.register_abm({
	label = "Turn Crimson Nylium and Warped Nylium below solid block into Netherrack",
	nodenames = {"mcl_crimson:crimson_nylium","mcl_crimson:warped_nylium"},
	neighbors = {"group:solid"},
	interval = 8,
	chance = 50,
	action = function(pos, node)
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local name = minetest.get_node(above).name
		local nodedef = minetest.registered_nodes[name]
		if name ~= "ignore" and nodedef and (nodedef.groups and nodedef.groups.solid) then
			minetest.set_node(pos, {name = "mcl_nether:netherrack"})
		end
	end
})

mcl_doors:register_door("mcl_crimson:crimson_door", {
	description = S("Crimson Door"),
	_doc_items_longdesc = S("Wooden doors are 2-block high barriers which can be opened or closed by hand and by a redstone signal."),
	_doc_items_usagehelp = S("To open or close a wooden door, rightclick it or supply its lower half with a redstone signal."),
	inventory_image = "mcl_crimson_crimson_door.png",
	groups = {handy=1,axey=1, material_wood=1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	tiles_bottom = "mcl_crimson_crimson_door_bottom.png",
	tiles_top = "mcl_crimson_crimson_door_top.png",
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_doors:register_trapdoor("mcl_crimson:crimson_trapdoor", {
	description = S("Crimson Trapdoor"),
	_doc_items_longdesc = S("Wooden trapdoors are horizontal barriers which can be opened and closed by hand or a redstone signal. They occupy the upper or lower part of a block, depending on how they have been placed. When open, they can be climbed like a ladder."),
	_doc_items_usagehelp = S("To open or close the trapdoor, rightclick it or send a redstone signal to it."),
	tile_front = "mcl_crimson_crimson_trapdoor.png",
	tile_side = "mcl_crimson_crimson_trapdoor_side.png",
	wield_image = "mcl_crimson_crimson_trapdoor.png",
	groups = {handy=1,axey=1, mesecon_effector_on=1, material_wood=1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_fences.register_fence_and_fence_gate(
	"crimson_fence",
	S("Crimson Fence"),
	S("Crimson Fence Gate"),
	"mcl_crimson_crimson_fence.png",
	{handy=1,axey=1,fence_wood=1},
	minetest.registered_nodes["mcl_crimson:crimson_hyphae"]._mcl_hardness,
	minetest.registered_nodes["mcl_crimson:crimson_hyphae"]._mcl_blast_resistance,
	{"group:fence_wood"},
	mcl_sounds.node_sound_wood_defaults())


mcl_doors:register_door("mcl_crimson:warped_door", {
	description = S("Warped Door"),
	_doc_items_longdesc = S("Wooden doors are 2-block high barriers which can be opened or closed by hand and by a redstone signal."),
	_doc_items_usagehelp = S("To open or close a wooden door, rightclick it or supply its lower half with a redstone signal."),
	inventory_image = "mcl_crimson_warped_door.png",
	groups = {handy=1,axey=1, material_wood=1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	tiles_bottom = "mcl_crimson_warped_door_bottom.png",
	tiles_top = "mcl_crimson_warped_door_top.png",
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_doors:register_trapdoor("mcl_crimson:warped_trapdoor", {
	description = S("Warped Trapdoor"),
	_doc_items_longdesc = S("Wooden trapdoors are horizontal barriers which can be opened and closed by hand or a redstone signal. They occupy the upper or lower part of a block, depending on how they have been placed. When open, they can be climbed like a ladder."),
	_doc_items_usagehelp = S("To open or close the trapdoor, rightclick it or send a redstone signal to it."),
	tile_front = "mcl_crimson_warped_trapdoor.png",
	tile_side = "mcl_crimson_warped_trapdoor_side.png",
	wield_image = "mcl_crimson_warped_trapdoor.png",
	groups = {handy=1,axey=1, mesecon_effector_on=1, material_wood=1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_fences.register_fence_and_fence_gate(
	"warped_fence",
	S("Warped Fence"),
	S("Warped Fence Gate"),
	"mcl_crimson_warped_fence.png",
	{handy=1,axey=1,fence_wood=1},
	minetest.registered_nodes["mcl_crimson:warped_hyphae"]._mcl_hardness,
	minetest.registered_nodes["mcl_crimson:warped_hyphae"]._mcl_blast_resistance,
	{"group:fence_wood"},
	mcl_sounds.node_sound_wood_defaults())

-- Door, Trapdoor, and Fence/Gate Crafting
local crimson_wood = "mcl_crimson:crimson_hyphae_wood"
local warped_wood = "mcl_crimson:warped_hyphae_wood"

minetest.register_craft({
	output = "mcl_crimson:crimson_door 3",
	recipe = {
		{crimson_wood, crimson_wood},
		{crimson_wood, crimson_wood},
		{crimson_wood, crimson_wood}
	}
})

minetest.register_craft({
	output = "mcl_crimson:warped_door 3",
	recipe = {
		{warped_wood, warped_wood},
		{warped_wood, warped_wood},
		{warped_wood, warped_wood}
	}
})

minetest.register_craft({
	output = "mcl_crimson:crimson_trapdoor 2",
	recipe = {
		{crimson_wood, crimson_wood, crimson_wood},
		{crimson_wood, crimson_wood, crimson_wood},
	}
})

minetest.register_craft({
	output = "mcl_crimson:warped_trapdoor 2",
	recipe = {
		{warped_wood, warped_wood, warped_wood},
		{warped_wood, warped_wood, warped_wood},
	}
})

minetest.register_craft({
	output = "mcl_crimson:crimson_fence 3",
	recipe = {
		{crimson_wood, "mcl_core:stick", crimson_wood},
		{crimson_wood, "mcl_core:stick", crimson_wood},
	}
})

minetest.register_craft({
	output = "mcl_crimson:warped_fence 3",
	recipe = {
		{warped_wood, "mcl_core:stick", warped_wood},
		{warped_wood, "mcl_core:stick", warped_wood},
	}
})

minetest.register_craft({
	output = "mcl_crimson:crimson_fence_gate",
	recipe = {
		{"mcl_core:stick", crimson_wood, "mcl_core:stick"},
		{"mcl_core:stick", crimson_wood, "mcl_core:stick"},
	}
})

minetest.register_craft({
	output = "mcl_crimson:warped_fence_gate",
	recipe = {
		{"mcl_core:stick", warped_wood, "mcl_core:stick"},
		{"mcl_core:stick", warped_wood, "mcl_core:stick"},
	}
})

dofile(modpath.."/alias.lua")
