local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)

mcl_structures = {}

local rotations = {
	"0",
	"90",
	"180",
	"270"
}

local function ecb_place(blockpos, action, calls_remaining, param)
	if calls_remaining >= 1 then return end
	minetest.place_schematic(param.pos, param.schematic, param.rotation, param.replacements, param.force_placement, param.flags)
	if param.after_placement_callback and param.p1 and param.p2 then
		param.after_placement_callback(param.p1, param.p2, param.size, param.rotation, param.pr, param.callback_param)
	end
end

function mcl_structures.place_schematic(pos, schematic, rotation, replacements, force_placement, flags, after_placement_callback, pr, callback_param)
	local s = loadstring(minetest.serialize_schematic(schematic, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}) .. " return schematic")()
	if s and s.size then
		local x, z = s.size.x, s.size.z
		if rotation then
			if rotation == "random" and pr then
				rotation = rotations[pr:next(1,#rotations)]
			end
			if rotation == "random" then
				x = math.max(x, z)
				z = x
			elseif rotation == "90" or rotation == "270" then
				x, z = z, x
			end
		end
		local p1 = {x=pos.x    , y=pos.y           , z=pos.z    }
		local p2 = {x=pos.x+x-1, y=pos.y+s.size.y-1, z=pos.z+z-1}
		minetest.log("verbose", "[mcl_structures] size=" ..minetest.pos_to_string(s.size) .. ", rotation=" .. tostring(rotation) .. ", emerge from "..minetest.pos_to_string(p1) .. " to " .. minetest.pos_to_string(p2))
		local param = {pos=vector.new(pos), schematic=s, rotation=rotation, replacements=replacements, force_placement=force_placement, flags=flags, p1=p1, p2=p2, after_placement_callback = after_placement_callback, size=vector.new(s.size), pr=pr, callback_param=callback_param}
		minetest.emerge_area(p1, p2, ecb_place, param)
	end
end

function mcl_structures.get_struct(file)
	local localfile = modpath.."/schematics/"..file
	local file, errorload = io.open(localfile, "rb")
	if errorload then
		minetest.log("error", "[mcl_structures] Could not open this struct: "..localfile)
		return nil
	end

	local allnode = file:read("*a")
	file:close()

	return allnode
end

-- Call on_construct on pos.
-- Useful to init chests from formspec.
local function init_node_construct(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	if def and def.on_construct then
		def.on_construct(pos)
		return true
	end
	return false
end
mcl_structures.init_node_construct = init_node_construct

-- The call of Struct
function mcl_structures.call_struct(pos, struct_style, rotation, pr)
	minetest.log("action","[mcl_structures] call_struct " .. struct_style.." at "..minetest.pos_to_string(pos))
	if not rotation then
		rotation = "random"
	end
	if struct_style == "igloo" then
		return mcl_structures.generate_igloo(pos, rotation, pr)
	elseif struct_style == "fossil" then
		return mcl_structures.generate_fossil(pos, rotation, pr)
	elseif struct_style == "end_exit_portal" then
		return mcl_structures.generate_end_exit_portal(pos, rotation)
	elseif struct_style == "end_exit_portal_open" then
		return mcl_structures.generate_end_exit_portal_open(pos, rotation)
	elseif struct_style == "end_gateway_portal" then
		return mcl_structures.generate_end_gateway_portal(pos, rotation)
	elseif struct_style == "end_portal_shrine" then
		return mcl_structures.generate_end_portal_shrine(pos, rotation, pr)
	end
end

function mcl_structures.generate_igloo(pos, rotation, pr)
	-- Place igloo
	local success, rotation = mcl_structures.generate_igloo_top(pos, pr)
	-- Place igloo basement with 50% chance
	local r = pr:next(1,2)
	if r == 1 then
		-- Select basement depth
		local dim = mcl_worlds.pos_to_dimension(pos)
		--local buffer = pos.y - (mcl_vars.mg_lava_overworld_max + 10)
		local buffer
		if dim == "nether" then
			buffer = pos.y - (mcl_vars.mg_lava_nether_max + 10)
		elseif dim == "end" then
			buffer = pos.y - (mcl_vars.mg_end_min + 1)
		elseif dim == "overworld" then
			buffer = pos.y - (mcl_vars.mg_lava_overworld_max + 10)
		else
			return success
		end
		if buffer <= 19 then
			return success
		end
		local depth = pr:next(19, buffer)
		local bpos = {x=pos.x, y=pos.y-depth, z=pos.z}
		-- trapdoor position
		local tpos
		local dir, tdir
		if rotation == "0" then
			dir = {x=-1, y=0, z=0}
			tdir = {x=1, y=0, z=0}
			tpos = {x=pos.x+7, y=pos.y-1, z=pos.z+3}
		elseif rotation == "90" then
			dir = {x=0, y=0, z=-1}
			tdir = {x=0, y=0, z=-1}
			tpos = {x=pos.x+3, y=pos.y-1, z=pos.z+1}
		elseif rotation == "180" then
			dir = {x=1, y=0, z=0}
			tdir = {x=-1, y=0, z=0}
			tpos = {x=pos.x+1, y=pos.y-1, z=pos.z+3}
		elseif rotation == "270" then
			dir = {x=0, y=0, z=1}
			tdir = {x=0, y=0, z=1}
			tpos = {x=pos.x+3, y=pos.y-1, z=pos.z+7}
		else
			return success
		end
		local function set_brick(pos)
			local c = pr:next(1, 3) -- cracked chance
			local m = pr:next(1, 10) -- chance for monster egg
			local brick
			if m == 1 then
				if c == 1 then
					brick = "mcl_monster_eggs:monster_egg_stonebrickcracked"
				else
					brick = "mcl_monster_eggs:monster_egg_stonebrick"
				end
			else
				if c == 1 then
					brick = "mcl_core:stonebrickcracked"
				else
					brick = "mcl_core:stonebrick"
				end
			end
			minetest.set_node(pos, {name=brick})
		end
		local ladder_param2 = minetest.dir_to_wallmounted(tdir)
		local real_depth = 0
		-- Check how deep we can actuall dig
		for y=1, depth-5 do
			real_depth = real_depth + 1
			local node = minetest.get_node({x=tpos.x,y=tpos.y-y,z=tpos.z})
			local def = minetest.registered_nodes[node.name]
			if not (def and def.walkable and def.liquidtype == "none" and def.is_ground_content) then
				bpos.y = tpos.y-y+1
				break
			end
		end
		if real_depth <= 6 then
			return success
		end
		-- Generate ladder to basement
		for y=1, real_depth-1 do
			set_brick({x=tpos.x-1,y=tpos.y-y,z=tpos.z  })
			set_brick({x=tpos.x+1,y=tpos.y-y,z=tpos.z  })
			set_brick({x=tpos.x  ,y=tpos.y-y,z=tpos.z-1})
			set_brick({x=tpos.x  ,y=tpos.y-y,z=tpos.z+1})
			minetest.set_node({x=tpos.x,y=tpos.y-y,z=tpos.z}, {name="mcl_core:ladder", param2=ladder_param2})
		end
		-- Place basement
		mcl_structures.generate_igloo_basement(bpos, rotation, pr)
		-- Place hidden trapdoor
		minetest.after(5, function(tpos, dir)
			minetest.set_node(tpos, {name="mcl_doors:trapdoor", param2=20+minetest.dir_to_facedir(dir)}) -- TODO: more reliable param2
		end, tpos, dir)
	end
	return success
end

function mcl_structures.generate_igloo_top(pos, pr)
	-- FIXME: This spawns bookshelf instead of furnace. Fix this!
	-- Furnace does ot work atm because apparently meta is not set. :-(
	local newpos = {x=pos.x,y=pos.y-1,z=pos.z}
	local path = modpath.."/schematics/mcl_structures_igloo_top.mts"
	local rotation = tostring(pr:next(0,3)*90)
	return mcl_structures.place_schematic(newpos, path, rotation, nil, true), rotation
end

local function igloo_placement_callback(p1, p2, size, orientation, pr)
	local chest_offset
	if orientation == "0" then
		chest_offset = {x=5, y=1, z=5}
	elseif orientation == "90" then
		chest_offset = {x=5, y=1, z=3}
	elseif orientation == "180" then
		chest_offset = {x=3, y=1, z=1}
	elseif orientation == "270" then
		chest_offset = {x=1, y=1, z=5}
	else
		return
	end
	--local size = {x=9,y=5,z=7}
	local lootitems = mcl_loot.get_multi_loot({
	{
		stacks_min = 1,
		stacks_max = 1,
		items = {
			{ itemstring = "mcl_core:apple_gold", weight = 1 },
		}
	},
	{
		stacks_min = 2,
		stacks_max = 8,
		items = {
			{ itemstring = "mcl_core:coal_lump", weight = 15, amount_min = 1, amount_max = 4 },
			{ itemstring = "mcl_core:apple", weight = 15, amount_min = 1, amount_max = 3 },
			{ itemstring = "mcl_farming:wheat_item", weight = 10, amount_min = 2, amount_max = 3 },
			{ itemstring = "mcl_core:gold_nugget", weight = 10, amount_min = 1, amount_max = 3 },
			{ itemstring = "mcl_mobitems:rotten_flesh", weight = 10 },
			{ itemstring = "mcl_tools:axe_stone", weight = 2 },
			{ itemstring = "mcl_core:emerald", weight = 1 },
		}
	}}, pr)

	local chest_pos = vector.add(p1, chest_offset)
	init_node_construct(chest_pos)
	local meta = minetest.get_meta(chest_pos)
	local inv = meta:get_inventory()
	mcl_loot.fill_inventory(inv, "main", lootitems, pr)
end

function mcl_structures.generate_igloo_basement(pos, orientation, pr)
	-- TODO: Add brewing stand
	-- TODO: Add monster eggs
	-- TODO: Spawn villager and zombie villager
	local path = modpath.."/schematics/mcl_structures_igloo_basement.mts"
	mcl_structures.place_schematic(pos, path, orientation, nil, true, nil, igloo_placement_callback, pr)
end

local function spawn_witch(p1,p2)
	local c = minetest.find_node_near(p1,15,{"mcl_cauldrons:cauldron"})
	if c then
		local nn = minetest.find_nodes_in_area_under_air(vector.new(p1.x,c.y-1,p1.z),vector.new(p2.x,c.y-1,p2.z),{"mcl_core:sprucewood"})
		local witch = minetest.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:witch"):get_luaentity()
		local cat = minetest.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:cat"):get_luaentity()
		witch._home = c
		witch.can_despawn = false
		cat.object:set_properties({textures = {"mobs_mc_cat_black.png"}})
		cat.owner = "!witch!" --so it's not claimable by player
		cat._home = c
		cat.can_despawn = false
		return
	end
end

function mcl_structures.generate_fossil(pos, rotation, pr)
	-- Generates one out of 8 possible fossil pieces
	local newpos = {x=pos.x,y=pos.y-1,z=pos.z}
	local fossils = {
		"mcl_structures_fossil_skull_1.mts", -- 4×5×5
		"mcl_structures_fossil_skull_2.mts", -- 5×5×5
		"mcl_structures_fossil_skull_3.mts", -- 5×5×7
		"mcl_structures_fossil_skull_4.mts", -- 7×5×5
		"mcl_structures_fossil_spine_1.mts", -- 3×3×13
		"mcl_structures_fossil_spine_2.mts", -- 5×4×13
		"mcl_structures_fossil_spine_3.mts", -- 7×4×13
		"mcl_structures_fossil_spine_4.mts", -- 8×5×13
	}
	local r = pr:next(1, #fossils)
	local path = modpath.."/schematics/"..fossils[r]
	return mcl_structures.place_schematic(newpos, path, rotation or "random", nil, true)
end

function mcl_structures.generate_end_exit_portal(pos, rot)
	local path = modpath.."/schematics/mcl_structures_end_exit_portal.mts"
	return mcl_structures.place_schematic(pos, path, rot or "0", {["mcl_portals:portal_end"] = "air"}, true)
end

function mcl_structures.generate_end_exit_portal_open(pos, rot)
	local path = modpath.."/schematics/mcl_structures_end_exit_portal.mts"
	return mcl_structures.place_schematic(pos, path, rot or "0", nil, true)
end

function mcl_structures.generate_end_gateway_portal(pos, rot)
	local path = modpath.."/schematics/mcl_structures_end_gateway_portal.mts"
	return mcl_structures.place_schematic(pos, path, rot or "0", nil, true)
end

local function shrine_placement_callback(p1, p2, size, rotation, pr)
	-- Find and setup spawner with silverfish
	local spawners = minetest.find_nodes_in_area(p1, p2, "mcl_mobspawners:spawner")
	for s=1, #spawners do
		--local meta = minetest.get_meta(spawners[s])
		mcl_mobspawners.setup_spawner(spawners[s], "mobs_mc:silverfish")
	end

	-- Shuffle stone brick types
	local bricks = minetest.find_nodes_in_area(p1, p2, "mcl_core:stonebrick")
	for b=1, #bricks do
		local r_bricktype = pr:next(1, 100)
		local r_infested = pr:next(1, 100)
		local bricktype
		if r_infested <= 5 then
			if r_bricktype <= 30 then -- 30%
				bricktype = "mcl_monster_eggs:monster_egg_stonebrickmossy"
			elseif r_bricktype <= 50 then -- 20%
				bricktype = "mcl_monster_eggs:monster_egg_stonebrickcracked"
			else -- 50%
				bricktype = "mcl_monster_eggs:monster_egg_stonebrick"
			end
		else
			if r_bricktype <= 30 then -- 30%
				bricktype = "mcl_core:stonebrickmossy"
			elseif r_bricktype <= 50 then -- 20%
				bricktype = "mcl_core:stonebrickcracked"
			end
			-- 50% stonebrick (no change necessary)
		end
		if bricktype then
			minetest.set_node(bricks[b], { name = bricktype })
		end
	end

	-- Also replace stairs
	local stairs = minetest.find_nodes_in_area(p1, p2, {"mcl_stairs:stair_stonebrick", "mcl_stairs:stair_stonebrick_outer", "mcl_stairs:stair_stonebrick_inner"})
	for s=1, #stairs do
		local stair = minetest.get_node(stairs[s])
		local r_type = pr:next(1, 100)
		if r_type <= 30 then -- 30% mossy
			if stair.name == "mcl_stairs:stair_stonebrick" then
				stair.name = "mcl_stairs:stair_stonebrickmossy"
			elseif stair.name == "mcl_stairs:stair_stonebrick_outer" then
				stair.name = "mcl_stairs:stair_stonebrickmossy_outer"
			elseif stair.name == "mcl_stairs:stair_stonebrick_inner" then
				stair.name = "mcl_stairs:stair_stonebrickmossy_inner"
			end
			minetest.set_node(stairs[s], stair)
		elseif r_type <= 50 then -- 20% cracky
			if stair.name == "mcl_stairs:stair_stonebrick" then
				stair.name = "mcl_stairs:stair_stonebrickcracked"
			elseif stair.name == "mcl_stairs:stair_stonebrick_outer" then
				stair.name = "mcl_stairs:stair_stonebrickcracked_outer"
			elseif stair.name == "mcl_stairs:stair_stonebrick_inner" then
				stair.name = "mcl_stairs:stair_stonebrickcracked_inner"
			end
			minetest.set_node(stairs[s], stair)
		end
		-- 50% no change
	end

	-- Randomly add ender eyes into end portal frames, but never fill the entire frame
	local frames = minetest.find_nodes_in_area(p1, p2, "mcl_portals:end_portal_frame")
	local eyes = 0
	for f=1, #frames do
		local r_eye = pr:next(1, 10)
		if r_eye == 1 then
			eyes = eyes + 1
			if eyes < #frames then
				local frame_node = minetest.get_node(frames[f])
				frame_node.name = "mcl_portals:end_portal_frame_eye"
				minetest.set_node(frames[f], frame_node)
			end
		end
	end
end

function mcl_structures.generate_end_portal_shrine(pos, rotation, pr)
	local offset = {x=6, y=4, z=6}
	--local size = {x=13, y=8, z=13}
	local newpos = { x = pos.x - offset.x, y = pos.y, z = pos.z - offset.z }

	local path = modpath.."/schematics/mcl_structures_end_portal_room_simple.mts"
	mcl_structures.place_schematic(newpos, path, rotation or "0", nil, true, nil, shrine_placement_callback, pr)
end

local structure_data = {}

--[[ Returns a table of structure of the specified type.
Currently the only valid parameter is "stronghold".
Format of return value:
{
	{ pos = <position>, generated=<true/false> }, -- first structure
	{ pos = <position>, generated=<true/false> }, -- second structure
	-- and so on
}

TODO: Implement this function for all other structure types as well.
]]
function mcl_structures.get_structure_data(structure_type)
	if structure_data[structure_type] then
		return table.copy(structure_data[structure_type])
	else
		return {}
	end
end

-- Register a structures table for the given type. The table format is the same as for
-- mcl_structures.get_structure_data.
function mcl_structures.register_structure_data(structure_type, structures)
	structure_data[structure_type] = structures
end

local function dir_to_rotation(dir)
	local ax, az = math.abs(dir.x), math.abs(dir.z)
	if ax > az then
		if dir.x < 0 then
			return "270"
		end
		return "90"
	end
	if dir.z < 0 then
		return "180"
	end
	return "0"
end

dofile(modpath.."/api.lua")
dofile(modpath.."/desert_temple.lua")
dofile(modpath.."/jungle_temple.lua")
dofile(modpath.."/ocean_ruins.lua")

local function hut_placement_callback(pos,def,pr)
	local hl = def.sidelen / 2
	local p1 = vector.offset(pos,-hl,-hl,-hl)
	local p2 = vector.offset(pos,hl,hl,hl)
	if not p1 or not p2 then return end
	local legs = minetest.find_nodes_in_area(p1, p2, "mcl_core:tree")
	local tree = {}
	for i = 1, #legs do
		while minetest.get_item_group(mcl_vars.get_node({x=legs[i].x, y=legs[i].y-1, z=legs[i].z}, true, 333333).name, "water") ~= 0 do
			legs[i].y = legs[i].y - 1
			table.insert(tree,legs[i])
		end
	end
	minetest.bulk_set_node(tree, {name = "mcl_core:tree", param2 = 2})
	spawn_witch(p1,p2)
end

mcl_structures.register_structure("witch_hut",{
	place_on = {"group:sand","group:grass_block","mcl_core:water_source","group:dirt"},
	noise_params = {
		offset = 0,
		scale = 0.0012,
		spread = {x = 250, y = 250, z = 250},
		seed = 233,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	flags = "place_center_x, place_center_z, liquid_surface, force_placement",
	sidelen = 5,
	chunk_probability = 64,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	--y_offset = function(pr) return pr:next(-4,1) end,
	y_offset = 0,
	biomes = { "Swampland", "Swampland_ocean", "Swampland_shore" },
	filenames = { modpath.."/schematics/mcl_structures_witch_hut.mts" },
	after_place = hut_placement_callback,
})
mcl_structures.register_structure("desert_well",{
	place_on = {"group:sand"},
	noise_params = {
		offset = 0,
		scale = 0.00012,
		spread = {x = 250, y = 250, z = 250},
		seed = 233,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	flags = "place_center_x, place_center_z",
	not_near = { "desert_temple_new" },
	solid_ground = true,
	sidelen = 4,
	chunk_probability = 64,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	y_offset = -2,
	biomes = { "Desert" },
	filenames = { modpath.."/schematics/mcl_structures_desert_well.mts" },
})

mcl_structures.register_structure("boulder",{
	flags = "place_center_x, place_center_z",
	sidelen = 4,
	filenames = {
		modpath.."/schematics/mcl_structures_boulder_small.mts",
		modpath.."/schematics/mcl_structures_boulder_small.mts",
		modpath.."/schematics/mcl_structures_boulder_small.mts",
		modpath.."/schematics/mcl_structures_boulder.mts",
	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct
mcl_structures.register_structure("ice_spike_small",{
	sidelen = 3,
	filenames = {
		modpath.."/schematics/mcl_structures_ice_spike_small.mts"
	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct
mcl_structures.register_structure("ice_spike_large",{
	sidelen = 6,
	filenames = {
		modpath.."/schematics/mcl_structures_ice_spike_large.mts"
	},
},true) --is spawned as a normal decoration. this is just for /spawnstruct

-- Debug command
minetest.register_chatcommand("spawnstruct", {
	params = "igloo | end_exit_portal | end_exit_portal_open | end_gateway_portal | end_portal_shrine | nether_portal | dungeon",
	description = S("Generate a pre-defined structure near your position."),
	privs = {debug = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		local pos = player:get_pos()
		if not pos then return end
		pos = vector.round(pos)
		local dir = minetest.yaw_to_dir(player:get_look_horizontal())
		local rot = dir_to_rotation(dir)
		local pr = PseudoRandom(pos.x+pos.y+pos.z)
		local errord = false
		local message = S("Structure placed.")
		if param == "igloo" then
			mcl_structures.generate_igloo(pos, rot, pr)
		elseif param == "fossil" then
			mcl_structures.generate_fossil(pos, rot, pr)
		elseif param == "end_exit_portal" then
			mcl_structures.generate_end_exit_portal(pos, rot, pr)
		elseif param == "end_exit_portal_open" then
			mcl_structures.generate_end_exit_portal_open(pos, rot, pr)
		elseif param == "end_gateway_portal" then
			mcl_structures.generate_end_gateway_portal(pos, rot, pr)
		elseif param == "end_portal_shrine" then
			mcl_structures.generate_end_portal_shrine(pos, rot, pr)
		elseif param == "dungeon" and mcl_dungeons and mcl_dungeons.spawn_dungeon then
			mcl_dungeons.spawn_dungeon(pos, rot, pr)
		elseif param == "nether_portal" and mcl_portals and mcl_portals.spawn_nether_portal then
			mcl_portals.spawn_nether_portal(pos, rot, pr, name)
		elseif param == "" then
			message = S("Error: No structure type given. Please use “/spawnstruct <type>”.")
			errord = true
		else
			for n,d in pairs(mcl_structures.registered_structures) do
				if n == param then
					mcl_structures.place_structure(pos,d,pr)
					return true,message
				end
			end
			message = S("Error: Unknown structure type. Please use “/spawnstruct <type>”.")
			errord = true
		end
		minetest.chat_send_player(name, message)
		if errord then
			minetest.chat_send_player(name, S("Use /help spawnstruct to see a list of avaiable types."))
		end
	end
})
minetest.register_on_mods_loaded(function()
	local p = ""
	for n,_ in pairs(mcl_structures.registered_structures) do
		p = p .. " | "..n
	end
	minetest.registered_chatcommands["spawnstruct"].params = minetest.registered_chatcommands["spawnstruct"].params .. p
end)
