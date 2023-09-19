local S = minetest.get_translator("mcl_mangrove")
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local propagule_allowed_nodes = {
	"mcl_core:dirt",
	"mcl_core:coarse_dirt",
	"mcl_core:dirt_with_grass",
	"mcl_core:podzol",
	"mcl_core:mycelium",
	"mcl_lush_caves:rooted_dirt",
	"mcl_lush_caves:moss",
	"mcl_farming:soil",
	"mcl_farming:soil_wet",
	"mcl_core:clay",
	"mcl_mud:mud",
}
local propagule_water_nodes = {"mcl_mud:mud","mcl_core:dirt","mcl_core:coarse_dirt","mcl_core:clay"}
 --"mcl_lush_caves:moss","mcl_lush_caves:rooted_dirt

mcl_core.register_tree_trunk("mangrove_tree", S("Mangrove Wood"), S("Mangrove Bark"),
	S("The trunk of a Mangrove tree."),
	"mcl_mangrove_log_top.png", "mcl_mangrove_log.png", "mcl_mangrove:mangrove_stripped")

mcl_core.register_wooden_planks("mangrove_wood", S("Mangrove Wood Planks"), {"mcl_mangrove_planks.png"})

mcl_core.register_leaves("mangroveleaves", S("Mangrove Leaves"), S("Mangrove leaves are grown from mangrove trees."),
	{"mcl_mangrove_leaves.png"}, "#48B518", "color", "mcl_core_palette_foliage.png", "mcl_mangrove:propagule", true, {20, 16, 12, 10}, 1)

mcl_core.register_stripped_trunk("mangrove_stripped", S("Stripped Mangrove Log"), S("Stripped Mangrove Wood"),
	S("The stripped wood of a Mangrove tree"), S("The stripped bark of a Mangrove tree"),
	"mcl_stripped_mangrove_log_top.png", "mcl_stripped_mangrove_log_side.png")

minetest.register_alias("mcl_mangrove:mangrove_stripped_trunk", "mcl_mangrove:mangrove_stripped")

minetest.register_node("mcl_mangrove:mangrove_roots", {
	description = S("Mangrove Roots"),
	_doc_items_longdesc = S("Mangrove roots are decorative blocks that form as part of mangrove trees."),
	_doc_items_hidden = false,
	waving = 0,
	place_param2 = 1, -- Prevent leafdecay for placed nodes
	tiles = {
		"mcl_mangrove_roots_top.png",
		"mcl_mangrove_roots_side.png",
		"mcl_mangrove_roots_side.png",
	},
	paramtype = "light",
	drawtype = "allfaces_optional",
	groups = {
		handy = 1, hoey = 1, shearsy = 1, axey = 1, swordy = 1, dig_by_piston = 0,
		flammable = 10, fire_encouragement = 30, fire_flammability = 60,
		deco_block = 1, compostability = 30
	},
	drop = "mcl_mangrove:mangrove_roots",
	_mcl_shears_drop = true,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	_mcl_blast_resistance = 0.7,
	_mcl_hardness = 0.7,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = { "mcl_mangrove:mangrove_roots 1", "mcl_mangrove:mangrove_roots 2", "mcl_mangrove:mangrove_roots 3", "mcl_mangrove:mangrove_roots 4" },
})

minetest.register_node("mcl_mangrove:propagule", {
	description = S("Mangrove Propagule"),
	_tt_help = S("Needs soil and light to grow"),
	_doc_items_longdesc = S("When placed on soil (such as dirt) and exposed to light, an propagule will grow into an mangrove after some time."),
	_doc_items_hidden = false,
	drawtype = "plantlike",
	waving = 1,
	visual_scale = 1.0,
	tiles = {"mcl_mangrove_propagule_item.png"},
	inventory_image = "mcl_mangrove_propagule_item.png",
	wield_image = "mcl_mangrove_propagule_item.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-5/16, -0.5, -5/16, 5/16, 0.5, 5/16}
	},
	groups = {
		plant = 1, sapling = 1, non_mycelium_plant = 1, attached_node = 1,
		deco_block = 1, dig_immediate = 3, dig_by_water = 0, dig_by_piston = 1,
		destroy_by_lava_flow = 1, compostability = 30
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("stage", 0)
	end,
	node_placement_prediction = "",
	_mcl_blast_resistance = 0,
	_mcl_hardness = 0,
	on_place = mcl_util.generate_on_place_plant_function(function(place_pos, place_node,stack)
		local under = vector.offset(place_pos,0,-1,0)
		local snn = minetest.get_node_or_nil(under).name
		if not snn then return false end
		if table.indexof(propagule_allowed_nodes,snn) ~= -1 then
			local n = minetest.get_node(place_pos)
			if minetest.get_item_group(n.name,"water") > 0 and table.indexof(propagule_water_nodes,snn) ~= -1 then
					minetest.set_node(under,{name="mcl_mangrove:propagule_"..snn:split(":")[2]})
					stack:take_item()
					return stack
			end
			return true
		end
	end)
})

minetest.register_node("mcl_mangrove:hanging_propagule_1", {
	description = S("Hanging Propagule"),
	_tt_help = S("Grows on Mangrove leaves"),
	_doc_items_longdesc = "",
	_doc_items_usagehelp = "",
	groups = {
			plant = 1, not_in_creative_inventory=1, non_mycelium_plant = 1,
			deco_block = 1, dig_immediate = 3, dig_by_water = 0, dig_by_piston = 1,
			destroy_by_lava_flow = 1, compostability = 30
		},
	paramtype = "light",
	paramtype2 = "",
	on_rotate = false,
	walkable = false,
	drop = "mcl_mangrove:propagule",
	use_texture_alpha = "clip",
	drawtype = 'mesh',
	mesh = 'propagule_hanging.obj',
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- Base
		},
	},
	tiles = {"mcl_mangrove_propagule_hanging.png"},
	inventory_image = "mcl_mangrove_propagule.png",
	wield_image = "mcl_mangrove_propagule.png",
})
local propagule_rooted_nodes = {}
for _,root in pairs(propagule_water_nodes) do
	local r = root:split(":")[2]
	local def = minetest.registered_nodes[root]
	local tx = def.tiles
	local n = "mcl_mangrove:propagule_"..r
	table.insert(propagule_rooted_nodes,n)
	minetest.register_node(n, {
		drawtype = "plantlike_rooted",
		paramtype = "light",
		place_param2 = 1,
		tiles = tx,
		special_tiles = { { name = "mcl_mangrove_propagule_item.png" } },
		inventory_image = "mcl_mangrove_propagule_item.png",
		wield_image = "mcl_mangrove_propagule.png",
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
				{ -0.5, 0.5, -0.5, 0.5, 1.0, 0.5 },
			}
		},
		groups = {
			plant = 1, sapling = 1, non_mycelium_plant = 1, attached_node = 1,not_in_creative_inventory=1,
			deco_block = 1, dig_immediate = 3, dig_by_piston = 1,
			destroy_by_lava_flow = 1, compostability = 30
		},
		sounds = mcl_sounds.node_sound_leaves_defaults(),
		drop = "mcl_mangrove:propagule",
		node_placement_prediction = "",
		node_dig_prediction = "",
		after_dig_node = function(pos)
			minetest.set_node(pos, {name=root})
		end,
		_mcl_hardness = 0,
		_mcl_blast_resistance = 0,
		_mcl_silk_touch_drop = true,
	})

end


mcl_flowerpots.register_potted_flower("mcl_mangrove:propagule", {
	name = "propagule",
	desc = S("Mangrove Propagule"),
	image = "mcl_mangrove_propagule.png",
})

local water_tex = "mcl_core_water_source_animation.png^[verticalframe:16:0^[multiply:#3F76E4"

local wlroots = {
	description = S("water logged mangrove roots"),
	_doc_items_entry_name = S("water logged mangrove roots"),
	_doc_items_longdesc =
		S("Mangrove roots are decorative blocks that form as part of mangrove trees.").."\n\n"..
		S("Mangrove roots, despite being a full block, can be waterlogged and do not flow water out").."\n\n"..
		S("These cannot be crafted yet only occure when get in contact of water."),
	_doc_items_hidden = false,
	tiles = {
		{name="mcl_core_water_source_animation.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0}}
	},
	special_tiles = {
		-- New-style water source material (mostly unused)
		{
			name="mcl_core_water_source_animation.png",
			animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0},
			backface_culling = false,
		}
	},
	overlay_tiles = {
		"mcl_mangrove_roots_top.png",
		"mcl_mangrove_roots_side.png",
		"mcl_mangrove_roots_side.png",
	},
	sounds = mcl_sounds.node_sound_water_defaults(),
	drawtype = "allfaces_optional",
	use_texture_alpha = "blend",
	is_ground_content = false,
	paramtype = "light",
	walkable = true,
	pointable = true,
	diggable = true,
	buildable_to = false,
	liquids_pointable = true,
	drop = "mcl_mangrove:mangrove_roots",
	groups = {
		handy = 1, hoey = 1, water=3, liquid=3, puts_out_fire=1, dig_by_piston = 1, deco_block = 1, waterlogged = 1, not_in_creative_inventory=1 },
	_mcl_blast_resistance = 100,
	_mcl_hardness = -1, -- Hardness intentionally set to infinite instead of 100 (Minecraft value) to avoid problems in creative mode
	on_construct = function(pos)
		local dim = mcl_worlds.pos_to_dimension(pos)
		if dim == "nether" then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16}, true)
			minetest.set_node(pos, {name="mcl_mangrove:mangrove_roots"})
		end
	end,
	after_dig_node = function(pos)
		local node = minetest.get_node(pos)
		local dim = mcl_worlds.pos_to_dimension(pos)
		if minetest.get_item_group(node.name, "water") == 0 and dim ~= "nether" then
			minetest.set_node(pos, {name="mcl_core:water_source"})
		else
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16}, true)
		end
	end,
}
local rwlroots = table.copy(wlroots)
-- FIXME luacheck complains that this is a repeated definition of water_tex.
-- Maybe the tiles definition below should be replaced with the animated tile
-- definition as per above?
water_tex = "mcl_core_water_source_animation.png^[verticalframe:16:0^[multiply:#0084FF"
rwlroots.tiles = {
	"("..water_tex..")^mcl_mangrove_roots_top.png",
	"("..water_tex..")^mcl_mangrove_roots_side.png",
	"("..water_tex..")^mcl_mangrove_roots_side.png",
}
rwlroots.after_dig_node = function(pos)
	local node = minetest.get_node(pos)
	local dim = mcl_worlds.pos_to_dimension(pos)
	if minetest.get_item_group(node.name, "water") == 0 and dim ~= "nether" then
		minetest.set_node(pos, {name="mclx_core:river_water_source"})
	else
		minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16}, true)
	end
end

minetest.register_node("mcl_mangrove:water_logged_roots", wlroots)
minetest.register_node("mcl_mangrove:river_water_logged_roots",rwlroots)

minetest.register_node("mcl_mangrove:mangrove_mud_roots", {
	description = S("Muddy Mangrove Roots"),
	_tt_help = S("Crafted with Mud and Mangrove roots"),
	_doc_items_longdesc = S("Muddy Mangrove Roots is a block from mangrove swamp.It drowns player a bit inside it."),
	tiles = {
		"mcl_mud.png^mcl_mangrove_roots_top.png",
		"mcl_mud.png^mcl_mangrove_roots_side.png",
		"mcl_mud.png^mcl_mangrove_roots_side.png",
	},
	is_ground_content = true,
	groups = {handy = 1, shovely = 1, axey = 1, building_block = 1},
	sounds = mcl_sounds.node_sound_sand_defaults(),
	_mcl_blast_resistance = 0.7,
	_mcl_hardness = 0.7,
})

mcl_doors:register_door("mcl_mangrove:mangrove_door", {
	description = S("Mangrove Door"),
	_doc_items_longdesc = S("Wooden doors are 2-block high barriers which can be opened or closed by hand and by a redstone signal."),
	_doc_items_usagehelp = S("To open or close a wooden door, rightclick it or supply its lower half with a redstone signal."),
	inventory_image = "mcl_mangrove_doors.png",
	groups = {handy=1,axey=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	tiles_bottom = "mcl_mangrove_door_bottom.png",
	tiles_top = "mcl_mangrove_door_top.png",
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_doors:register_trapdoor("mcl_mangrove:mangrove_trapdoor", {
	description = S("Mangrove Trapdoor"),
	_doc_items_longdesc = S("Wooden trapdoors are horizontal barriers which can be opened and closed by hand or a redstone signal. They occupy the upper or lower part of a block, depending on how they have been placed. When open, they can be climbed like a ladder."),
	_doc_items_usagehelp = S("To open or close the trapdoor, rightclick it or send a redstone signal to it."),
	tile_front = "mcl_mangrove_trapdoor.png",
	tile_side = "mcl_mangrove_trapdoor_side.png",
	wield_image = "mcl_mangrove_trapdoor.png",
	groups = {handy=1,axey=1, mesecon_effector_on=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	sounds = mcl_sounds.node_sound_wood_defaults(),
})

mcl_fences.register_fence_and_fence_gate(
	"mangrove_wood_fence",
	S("Mangrove Wood Fence"),
	S("Mangrove Wood Fence Gate"),
	"mcl_mangrove_fence.png",
	{handy=1,axey=1, flammable=2,fence_wood=1, fire_encouragement=5, fire_flammability=20},
	minetest.registered_nodes["mcl_core:wood"]._mcl_hardness,
	minetest.registered_nodes["mcl_core:wood"]._mcl_blast_resistance,
	{"group:fence_wood"},
	mcl_sounds.node_sound_wood_defaults(), "mcl_mangrove_mangrove_wood_fence_gate_open", "mcl_mangrove_mangrove_wood_fence_gate_close", 1, 1,
	"mcl_mangrove_fence_gate.png")

mcl_stairs.register_stair("mangrove_wood", "mcl_mangrove:mangrove_wood",
	{handy=1,axey=1, flammable=3,wood_stairs=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
	{"mcl_mangrove_planks.png"},
	S("Mangrove Wood Stairs"),
	mcl_sounds.node_sound_wood_defaults(), nil, nil,
	"woodlike")

mcl_stairs.register_slab("mangrove_wood", "mcl_mangrove:mangrove_wood",
	{handy=1,axey=1, flammable=3,wood_slab=1, material_wood=1, fire_encouragement=5, fire_flammability=20},
	{"mcl_mangrove_planks.png"},
	S("Mangrove Wood Slab"),
	mcl_sounds.node_sound_wood_defaults(), nil, nil,
	S("Double Mangrove Wood Slab"))

minetest.register_craft({
	output = "mcl_mangrove:mangrove_tree_bark 3",
	recipe = {
		{ "mcl_mangrove:mangrove_tree", "mcl_mangrove:mangrove_tree" },
		{ "mcl_mangrove:mangrove_tree", "mcl_mangrove:mangrove_tree" },
	}
})

minetest.register_craft({
	output = "mcl_mangrove:mangrove_mud_roots",
	recipe = {
		{"mcl_mangrove:mangrove_roots", "mcl_mud:mud",},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_mangrove:mangrove_door",
	burntime = 15,
})

minetest.register_craft({
	output = "mcl_mangrove:mangrove_door 3",
	recipe = {
		{"mcl_mangrove:mangrove_wood", "mcl_mangrove:mangrove_wood"},
		{"mcl_mangrove:mangrove_wood", "mcl_mangrove:mangrove_wood"},
		{"mcl_mangrove:mangrove_wood", "mcl_mangrove:mangrove_wood"},
	}
})

minetest.register_craft({
	output = "mcl_mangrove:mangrove_trapdoor 2",
	recipe = {
		{"mcl_mangrove:mangrove_wood","mcl_mangrove:mangrove_wood","mcl_mangrove:mangrove_wood"},
		{"mcl_mangrove:mangrove_wood","mcl_mangrove:mangrove_wood","mcl_mangrove:mangrove_wood"},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_mangrove:mangrove_trapdoor",
	burntime = 15,
})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood_fence_gate",
		recipe = {
			{"mcl_core:stick", "mcl_mangrove:mangrove_wood", "mcl_core:stick"},
			{"mcl_core:stick", "mcl_mangrove:mangrove_wood", "mcl_core:stick"},
		}
	})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood_fence 3",
		recipe = {
			{"mcl_mangrove:mangrove_wood", "mcl_core:stick", "mcl_mangrove:mangrove_wood"},
			{"mcl_mangrove:mangrove_wood", "mcl_core:stick", "mcl_mangrove:mangrove_wood"},
		}
	})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood 4",
		recipe = {
			{"mcl_mangrove:mangrove_tree"},
		}
	})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood 4",
		recipe = {
			{"mcl_mangrove:mangrove_tree_bark"},
		}
	})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood 4",
		recipe = {
			{"mcl_mangrove:mangrove_stripped"},
		}
	})

minetest.register_craft({
		output = "mcl_mangrove:mangrove_wood 4",
		recipe = {
			{"mcl_mangrove:mangrove_stripped_bark"},
		}
	})

minetest.register_craft({
	type = "fuel",
	recipe = "group:fence_wood",
	burntime = 15,
})

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_mangrove:mangrove_roots",
	burntime = 15,
})

local adjacents = {
	vector.new(1,0,0),
	vector.new(-1,0,0),
	vector.new(0,0,1),
	vector.new(0,0,-1),
}

minetest.register_abm({
	label = "Waterlog mangrove roots",
	nodenames = {"mcl_mangrove:mangrove_roots"},
	neighbors = {"group:water"},
	interval = 5,
	chance = 5,
	action = function(pos,value)
		for _,v in pairs(adjacents) do
			local n = minetest.get_node(vector.add(pos,v)).name
			if minetest.get_item_group(n,"water") > 0 then
				if n:find("river") then
					minetest.swap_node(pos,{name="mcl_mangrove:river_water_logged_roots"})
					return
				else
					minetest.swap_node(pos,{name="mcl_mangrove:water_logged_roots"})
					return
				end
			end
		end
	end
})

local abm_nodes = table.copy(propagule_rooted_nodes)
table.insert(abm_nodes,"mcl_mangrove:propagule")
minetest.register_abm({
	label = "Mangrove_tree_growth",
	nodenames = abm_nodes,
	interval = 30,
	chance = 5,
	action = function(pos,node)
		local pr = PseudoRandom(pos.x+pos.y+pos.z)
		local r = pr:next(1,5)
		local path = modpath .."/schematics/mcl_mangrove_tree_"..tostring(r)..".mts"
		local w = 5
		local h = 10
		local fp = true
		pos.y = pos.y - 1
		if table.indexof(propagule_rooted_nodes,node.name) ~= -1 then
			local nn = minetest.find_nodes_in_area(vector.offset(pos,0,-1,0),vector.offset(pos,0,h,0),{"group:water","air"})
			if #nn >= h then
				minetest.place_schematic(pos, path, "random", function()
				mcl_core.update_sapling_foliage_colors(pos)
				local nnv = minetest.find_nodes_in_area(vector.offset(pos,-5,-1,-5),vector.offset(pos,5,h/2,5),{"mcl_core:vine"})
				minetest.bulk_set_node(nnv,{"air"})
				end, true, "place_center_x, place_center_z")
			end
			return
		end
		if r > 3 then h = 18 end
		if mcl_core.check_growth_width(pos,w,h) then
			minetest.place_schematic(pos, path, "random", nil, true, "place_center_x, place_center_z")
			mcl_core.update_sapling_foliage_colors(pos)
		end
	end,
})
