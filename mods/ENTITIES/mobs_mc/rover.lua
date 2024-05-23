--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

-- ENDERMAN BEHAVIOUR (OLD):
-- In this game, endermen attack the player on sight, like other monsters do.
-- However, they have a reduced viewing range to make them less dangerous.
-- This differs from MC, in which endermen only become hostile when provoked,
-- and they are provoked by looking directly at them.

-- Rootyjr
-----------------------------
-- implemented ability to detect when seen / break eye contact and aggressive response
-- implemented teleport to avoid arrows.
-- implemented teleport to avoid rain.
-- implemented teleport to chase.
-- added enderman particles.
-- drew mcl_portal_particle1.png
-- drew mcl_portal_particle2.png
-- drew mcl_portal_particle3.png
-- drew mcl_portal_particle4.png
-- drew mcl_portal_particle5.png
-- added rain damage.
-- fixed the grass_with_dirt issue.

-- How freqeuntly to take and place blocks, in seconds
local take_frequency_min = 235
local take_frequency_max = 245
local place_frequency_min = 235
local place_frequency_max = 245

minetest.register_entity("mobs_mc:ender_eyes", {
	on_step = function(self)
		self.object:remove()
	end,
})

local S = minetest.get_translator("mobs_mc")
local enable_damage = minetest.settings:get_bool("enable_damage")

local telesound = function(pos, is_source)
	local snd
	if is_source then
		snd = "mobs_mc_enderman_teleport_src"
	else
		snd = "mobs_mc_enderman_teleport_dst"
	end
	minetest.sound_play(snd, {pos=pos, max_hear_distance=16}, true)
end

--###################
--################### ENDERMAN
--###################

local pr = PseudoRandom(os.time()*(-334))

-- Select a new animation definition.
local select_rover_animation = function(animation_type)
	-- Enderman holds a block
	if animation_type == "block" then
		return {
			walk_speed = 25,
			run_speed = 50,
			stand_speed = 25,
			stand_start = 200,
			stand_end = 200,
			walk_start = 161,
			walk_end = 200,
			run_start = 161,
			run_end = 200,
			punch_start = 121,
			punch_end = 160,
		}
	-- Enderman doesn't hold a block
	elseif animation_type == "normal" or animation_type == nil then
		return {
			walk_speed = 25,
			run_speed = 50,
			stand_speed = 25,
			stand_start = 40,
			stand_end = 80,
			walk_start = 0,
			walk_end = 40,
			run_start = 0,
			run_end = 40,
			punch_start = 81,
			punch_end = 120,
		}
	end
end

local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false
local psdefs = {{
	amount = 5,
	minpos = vector.new(-0.6,0,-0.6),
	maxpos = vector.new(0.6,3,0.6),
	minvel = vector.new(-0.25,-0.25,-0.25),
	maxvel = vector.new(0.25,0.25,0.25),
	minacc = vector.new(-0.5,-0.5,-0.5),
	maxacc = vector.new(0.5,0.5,0.5),
	minexptime = 0.2,
	maxexptime = 3,
	minsize = 0.2,
	maxsize = 1.2,
	collisiondetection = true,
	vertical = false,
	time = 0,
	texture = "mcl_portals_particle"..math.random(1, 5)..".png",
}}

mcl_mobs.register_mob("mobs_mc:rover", {
	description = S("Rover"),
	type = "monster",
	spawn_class = "passive",
	can_despawn = true,
	passive = true,
	pathfinding = 1,
	hp_min = 40,
	hp_max = 40,
	xp_min = 5,
	xp_max = 5,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 2.89, 0.3},
	visual = "mesh",
	mesh = "vl_rover.b3d",
	textures = { "vl_mobs_rover.png^vl_mobs_rover_face.png" },
	glow = 100,
	visual_size = {x=10, y=10},
	makes_footstep_sound = true,
	sounds = {
		-- TODO: Custom war cry sound
		war_cry = "mobs_sandmonster",
		death = {name="mobs_mc_enderman_death", gain=0.7},
		damage = {name="mobs_mc_enderman_hurt", gain=0.5},
		random = {name="mobs_mc_enderman_random", gain=0.5},
		distance = 16,
	},
	walk_velocity = 2,
	run_velocity = 4,
	damage = 7,
	reach = 2,
	particlespawners = psdefs,
	drops = {
		{name = "mcl_throwing:ender_pearl",
		chance = 1,
		min = 0,
		max = 1,
		looting = "common"},
	},
	animation = select_rover_animation("normal"),
	_taken_node = "",
	can_spawn = function(pos)
		return #minetest.find_nodes_in_area(vector.offset(pos,0,1,0),vector.offset(pos,0,3,0),{"air"}) > 2
	end,
	do_custom = function(self, dtime)
		-- RAIN DAMAGE / EVASIVE WARP BEHAVIOUR HERE.
		local enderpos = self.object:get_pos()
		local dim = mcl_worlds.pos_to_dimension(enderpos)
		if dim == "overworld" then
			if mcl_weather.state == "rain" or mcl_weather.state == "lightning" then
				local damage = true
				local enderpos = self.object:get_pos()
				enderpos.y = enderpos.y+2.89
				local height = {x=enderpos.x, y=enderpos.y+512,z=enderpos.z}
				local ray = minetest.raycast(enderpos, height, true)
				-- Check for blocks above enderman.
				for pointed_thing in ray do
					if pointed_thing.type == "node" then
						local nn = minetest.get_node(minetest.get_pointed_thing_position(pointed_thing)).name
						local def = minetest.registered_nodes[nn]
						if (not def) or def.walkable then
							-- There's a node in the way. Delete arrow without damage
							damage = false
							break
						end
					end
				end

				if damage == true then
					self.state = ""
					--rain hurts enderman
					self.object:punch(self.object, 1.0, {
						full_punch_interval=1.0,
						damage_groups={fleshy=self._damage},
					}, nil)
					--randomly teleport hopefully under something.
					self:teleport(nil)
				end
			end
		end

		-- AGRESSIVELY WARP/CHASE PLAYER BEHAVIOUR HERE.
		if self.state == "attack" then
			self.object:set_properties({textures={"vl_mobs_rover.png^vl_mobs_rover_face_angry.png"}})
			if self.attack then
				local target = self.attack
				local pos = target:get_pos()
				if pos ~= nil then
					if vector.distance(self.object:get_pos(), target:get_pos()) > 10 then
						self:teleport(target)
					end
				end
			end
		else --if not attacking try to tp to the dark
			self.object:set_properties({textures={"vl_mobs_rover.png^vl_mobs_rover_face.png"}})
			if dim == 'overworld' then
				local light = minetest.get_node_light(enderpos)
				if light and light > minetest.LIGHT_MAX then
					self:teleport(nil)
				end
			end
		end
		-- ARROW / DAYTIME PEOPLE AVOIDANCE BEHAVIOUR HERE.
		-- Check for arrows and people nearby.

		enderpos = self.object:get_pos()
		enderpos.y = enderpos.y + 1.5
		local objs = minetest.get_objects_inside_radius(enderpos, 2)
		for n = 1, #objs do
			local obj = objs[n]
			if obj then
				if minetest.is_player(obj) then
					-- Warp from players during day.
					--if (minetest.get_timeofday() * 24000) > 5001 and (minetest.get_timeofday() * 24000) < 19000 then
					--	self:teleport(nil)
					--end
				else
					local lua = obj:get_luaentity()
					if lua then
						if lua.name == "mcl_bows:arrow_entity" or lua.name == "mcl_throwing:snowball_entity" then
							self:teleport(nil)
						end
					end
				end
			end
		end

		-- PROVOKED BEHAVIOUR HERE.
		local enderpos = self.object:get_pos()
		if self.provoked == "broke_contact" then
			self.provoked = "false"
			--if (minetest.get_timeofday() * 24000) > 5001 and (minetest.get_timeofday() * 24000) < 19000 then
			--	self:teleport(nil)
			--	self.state = ""
			--else
				if self.attack ~= nil and enable_damage then
					self.state = 'attack'
				end
			--end
		end
		-- Check to see if people are near by enough to look at us.
		for _,obj in pairs(minetest.get_connected_players()) do

			--check if they are within radius
			local player_pos = obj:get_pos()
			if player_pos then -- prevent crashing in 1 in a million scenario

				local ender_distance = vector.distance(enderpos, player_pos)
				if ender_distance <= 64 then

					-- Check if they are looking at us.
					local look_dir_not_normalized = obj:get_look_dir()
					local look_dir = vector.normalize(look_dir_not_normalized)
					local player_eye_height = obj:get_properties().eye_height

					--skip player if they have no data - log it
					if not player_eye_height then
						minetest.log("error", "Enderman at location: ".. dump(enderpos).." has indexed a null player!")
					else

						--calculate very quickly the exact location the player is looking
						--within the distance between the two "heads" (player and enderman)
						local look_pos = vector.new(player_pos.x, player_pos.y + player_eye_height, player_pos.z)
						local look_pos_base = look_pos
						local ender_eye_pos = vector.new(enderpos.x, enderpos.y + 2.75, enderpos.z)
						local eye_distance_from_player = vector.distance(ender_eye_pos, look_pos)
						look_pos = vector.add(look_pos, vector.multiply(look_dir, eye_distance_from_player))

						--if looking in general head position, turn hostile
						if minetest.line_of_sight(ender_eye_pos, look_pos_base) and vector.distance(look_pos, ender_eye_pos) <= 0.4 then
							self.provoked = "staring"
							self.attack = minetest.get_player_by_name(obj:get_player_name())
							break
						else -- I'm not sure what this part does, but I don't want to break anything - jordan4ibanez
							if self.provoked == "staring" then
								self.provoked = "broke_contact"
							end
						end

					end
				end
			end
		end

		-- ATTACK ENDERMITE
		local enderpos = self.object:get_pos()
		if math.random(1,140) == 1 then
			local mobsnear = minetest.get_objects_inside_radius(enderpos, 64)
			for n=1, #mobsnear do
				local mob = mobsnear[n]
				if mob then
					local entity = mob:get_luaentity()
					if entity and entity.name == "mobs_mc:endermite" then
						self.attack = mob
						self.state = 'attack'
					end
				end
			end
		end

		-- TAKE AND PLACE STUFF BEHAVIOUR BELOW.
		if not mobs_griefing then
			return
		end
		-- Take and put nodes
		if not self._take_place_timer or not self._next_take_place_time then
			self._take_place_timer = 0
			self._next_take_place_time = math.random(take_frequency_min, take_frequency_max)
			return
		end
		self._take_place_timer = self._take_place_timer + dtime
		if (self._taken_node == nil or self._taken_node == "") and self._take_place_timer >= self._next_take_place_time then
			-- Take random node
			self._take_place_timer = 0
			self._next_take_place_time = math.random(place_frequency_min, place_frequency_max)
			local pos = self.object:get_pos()
			local takable_nodes = minetest.find_nodes_in_area_under_air({x=pos.x-2, y=pos.y-1, z=pos.z-2}, {x=pos.x+2, y=pos.y+1, z=pos.z+2}, "group:enderman_takable")
			if #takable_nodes >= 1 then
				local r = pr:next(1, #takable_nodes)
				local take_pos = takable_nodes[r]
				local node = minetest.get_node(take_pos)
				-- Don't destroy protected stuff.
				if not minetest.is_protected(take_pos, "") then
					minetest.remove_node(take_pos)
					local dug = minetest.get_node_or_nil(take_pos)
					if dug and dug.name == "air" then
						local node_obj = vl_held_item.create_item_entity(take_pos, node.name)
						if node_obj then
							node_obj:set_attach(self.object, "held_node")
							self._node_obj = node_obj
							self._taken_node = node.name
							node_obj:set_properties({visual_size={x=0.02, y=0.02}})
						end
						local def = minetest.registered_nodes[self._taken_node]
						self.animation = select_rover_animation("block")
						self:set_animation(self.animation.current)
						if def and def.sounds and def.sounds.dug then
							minetest.sound_play(def.sounds.dug, {pos = take_pos, max_hear_distance = 16}, true)
						end
					end
				end
			end
		elseif self._taken_node ~= nil and self._taken_node ~= "" and self._take_place_timer >= self._next_take_place_time then
			-- Place taken node
			self._take_place_timer = 0
			self._next_take_place_time = math.random(take_frequency_min, take_frequency_max)
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
			-- Place node at looking direction
			local place_pos = vector.subtract(pos, minetest.facedir_to_dir(minetest.dir_to_facedir(minetest.yaw_to_dir(yaw))))
			-- Also check to see if protected.
			if minetest.get_node(place_pos).name == "air" and not minetest.is_protected(place_pos, "") then
				-- ... but only if there's a free space
				local success = minetest.place_node(place_pos, {name = self._taken_node})
				if success then
					local def = minetest.registered_nodes[self._taken_node]
					-- Update animation accordingly (removes visible block)
					self.persistent = false
					self.animation = select_rover_animation("normal")
					self:set_animation(self.animation.current)
					if def and def.sounds and def.sounds.place then
						minetest.sound_play(def.sounds.place, {pos = place_pos, max_hear_distance = 16}, true)
					end
					self._node_obj:remove()
					self._node_obj = nil
					self._taken_node = nil
				end
			end
		end
	end,
	do_teleport = function(self, target)
		if target ~= nil then
			local target_pos = target:get_pos()
			-- Find all solid nodes below air in a 10×10×10 cuboid centered on the target
			local nodes = minetest.find_nodes_in_area_under_air(vector.subtract(target_pos, 5), vector.add(target_pos, 5), {"group:solid", "group:cracky", "group:crumbly"})
			local telepos
			if nodes ~= nil then
				if #nodes > 0 then
					-- Up to 64 attempts to teleport
					for n=1, math.min(64, #nodes) do
						local r = pr:next(1, #nodes)
						local nodepos = nodes[r]
						local node_ok = true
						-- Selected node needs to have 3 nodes of free space above
						for u=1, 3 do
							local node = minetest.get_node({x=nodepos.x, y=nodepos.y+u, z=nodepos.z})
							local ndef = minetest.registered_nodes[node.name]
							if ndef and ndef.walkable then
								node_ok = false
								break
							end
						end
						if node_ok then
							telepos = {x=nodepos.x, y=nodepos.y+1, z=nodepos.z}
						end
					end
					if telepos then
						telesound(self.object:get_pos(), false)
						self.object:set_pos(telepos)
						telesound(telepos, true)
					end
				end
			end
		else
			-- Attempt to randomly teleport enderman
			local pos = self.object:get_pos()
			-- Up to 8 top-level attempts to teleport
			for n=1, 8 do
				local node_ok = false
				-- We need to add (or subtract) different random numbers to each vector component, so it couldn't be done with a nice single vector.add() or .subtract():
				local randomCube = vector.new( pos.x + 8*(pr:next(0,16)-8), pos.y + 8*(pr:next(0,16)-8), pos.z + 8*(pr:next(0,16)-8) )
				local nodes = minetest.find_nodes_in_area_under_air(vector.subtract(randomCube, 4), vector.add(randomCube, 4), {"group:solid", "group:cracky", "group:crumbly"})
				if nodes ~= nil then
					if #nodes > 0 then
						-- Up to 8 low-level (in total up to 8*8 = 64) attempts to teleport
						for n=1, math.min(8, #nodes) do
							local r = pr:next(1, #nodes)
							local nodepos = nodes[r]
							node_ok = true
							for u=1, 3 do
								local node = minetest.get_node({x=nodepos.x, y=nodepos.y+u, z=nodepos.z})
								local ndef = minetest.registered_nodes[node.name]
								if ndef and ndef.walkable then
									node_ok = false
									break
								end
							end
							if node_ok then
								telesound(self.object:get_pos(), false)
								local telepos = {x=nodepos.x, y=nodepos.y+1, z=nodepos.z}
								self.object:set_pos(telepos)
								telesound(telepos, true)
								break
							end
						end
					end
				end
				if node_ok then
					 break
				end
			end
		end
	end,
	on_die = function(self, pos)
		-- Drop carried node on death
		if self._taken_node ~= nil and self._taken_node ~= "" then
			minetest.add_item(pos, self._taken_node)
		end
	end,
	do_punch = function(self, hitter, tflp, tool_caps, dir)
		-- damage from rain caused by itself so we don't want it to attack itself.
		if hitter ~= self.object and hitter ~= nil then
			--if (minetest.get_timeofday() * 24000) > 5001 and (minetest.get_timeofday() * 24000) < 19000 then
			--	self:teleport(nil)
			--else
			if pr:next(1, 8) == 8 then --FIXME: real mc rate
				self:teleport(hitter)
			end
			self.attack=hitter
			self.state="attack"
			--end
		end
	end,
	after_activate = function(self, staticdata, def, dtime)
		if not self._taken_node or self._taken_node == "" then
			self.animation = select_rover_animation("normal")
			self:set_animation(self.animation.current)
			return
		end
		self.animation = select_rover_animation("block")
		self:set_animation(self.animation.current)
		local node_obj = vl_held_item.create_item_entity(self.object:get_pos(), self._taken_node)
		if node_obj then
			node_obj:set_attach(self.object, "held_node")
			self._node_obj = node_obj
			node_obj:set_properties({visual_size={x=0.02, y=0.02}})
		end
	end,
	armor = { fleshy = 100, water_vulnerable = 100 },
	water_damage = 8,
	view_range = 64,
	fear_height = 4,
	attack_type = "dogfight",
})

-- compat
minetest.register_entity("mobs_mc:enderman", {
	on_activate = function(self, staticdata, dtime)
		local obj = minetest.add_entity(self.object:get_pos(), "mobs_mc:rover", staticdata)
		obj:set_properties({
			mesh = "vl_rover.b3d",
			textures = { "vl_mobs_rover.png^vl_mobs_rover_face.png" },
			visual_size = {x=10, y=10},
		})
		self.object:remove()
	end,
})

-- End spawn
mcl_mobs:spawn_specific(
"mobs_mc:rover",
"end",
"ground",
{
"End",
"EndIsland",
"EndMidlands",
"EndBarrens",
"EndBorder",
"EndSmallIslands"
},
0,
minetest.LIGHT_MAX+1,
30,
100,
12,
mcl_vars.mg_end_min,
mcl_vars.mg_end_max)
-- Overworld spawn
mcl_mobs:spawn_specific(
"mobs_mc:rover",
"overworld",
"ground",
{
"Mesa",
"FlowerForest",
"Swampland",
"Taiga",
"ExtremeHills",
"Jungle",
"Savanna",
"BirchForest",
"MegaSpruceTaiga",
"MegaTaiga",
"ExtremeHills+",
"Forest",
"Plains",
"Desert",
"ColdTaiga",
"IcePlainsSpikes",
"SunflowerPlains",
"IcePlains",
"RoofedForest",
"ExtremeHills+_snowtop",
"MesaPlateauFM_grasstop",
"JungleEdgeM",
"ExtremeHillsM",
"JungleM",
"BirchForestM",
"MesaPlateauF",
"MesaPlateauFM",
"MesaPlateauF_grasstop",
"MesaBryce",
"JungleEdge",
"SavannaM",
"FlowerForest_beach",
"Forest_beach",
"StoneBeach",
"ColdTaiga_beach_water",
"Taiga_beach",
"Savanna_beach",
"Plains_beach",
"ExtremeHills_beach",
"ColdTaiga_beach",
"Swampland_shore",
"JungleM_shore",
"Jungle_shore",
"MesaPlateauFM_sandlevel",
"MesaPlateauF_sandlevel",
"MesaBryce_sandlevel",
"Mesa_sandlevel",
"RoofedForest_ocean",
"JungleEdgeM_ocean",
"BirchForestM_ocean",
"BirchForest_ocean",
"IcePlains_deep_ocean",
"Jungle_deep_ocean",
"Savanna_ocean",
"MesaPlateauF_ocean",
"ExtremeHillsM_deep_ocean",
"Savanna_deep_ocean",
"SunflowerPlains_ocean",
"Swampland_deep_ocean",
"Swampland_ocean",
"MegaSpruceTaiga_deep_ocean",
"ExtremeHillsM_ocean",
"JungleEdgeM_deep_ocean",
"SunflowerPlains_deep_ocean",
"BirchForest_deep_ocean",
"IcePlainsSpikes_ocean",
"Mesa_ocean",
"StoneBeach_ocean",
"Plains_deep_ocean",
"JungleEdge_deep_ocean",
"SavannaM_deep_ocean",
"Desert_deep_ocean",
"Mesa_deep_ocean",
"ColdTaiga_deep_ocean",
"Plains_ocean",
"MesaPlateauFM_ocean",
"Forest_deep_ocean",
"JungleM_deep_ocean",
"FlowerForest_deep_ocean",
"MegaTaiga_ocean",
"StoneBeach_deep_ocean",
"IcePlainsSpikes_deep_ocean",
"ColdTaiga_ocean",
"SavannaM_ocean",
"MesaPlateauF_deep_ocean",
"MesaBryce_deep_ocean",
"ExtremeHills+_deep_ocean",
"ExtremeHills_ocean",
"Forest_ocean",
"MegaTaiga_deep_ocean",
"JungleEdge_ocean",
"MesaBryce_ocean",
"MegaSpruceTaiga_ocean",
"ExtremeHills+_ocean",
"Jungle_ocean",
"RoofedForest_deep_ocean",
"IcePlains_ocean",
"FlowerForest_ocean",
"ExtremeHills_deep_ocean",
"MesaPlateauFM_deep_ocean",
"Desert_ocean",
"Taiga_ocean",
"BirchForestM_deep_ocean",
"Taiga_deep_ocean",
"JungleM_ocean",
"FlowerForest_underground",
"JungleEdge_underground",
"StoneBeach_underground",
"MesaBryce_underground",
"Mesa_underground",
"RoofedForest_underground",
"Jungle_underground",
"Swampland_underground",
"BirchForest_underground",
"Plains_underground",
"MesaPlateauF_underground",
"ExtremeHills_underground",
"MegaSpruceTaiga_underground",
"BirchForestM_underground",
"SavannaM_underground",
"MesaPlateauFM_underground",
"Desert_underground",
"Savanna_underground",
"Forest_underground",
"SunflowerPlains_underground",
"ColdTaiga_underground",
"IcePlains_underground",
"IcePlainsSpikes_underground",
"MegaTaiga_underground",
"Taiga_underground",
"ExtremeHills+_underground",
"JungleM_underground",
"ExtremeHillsM_underground",
"JungleEdgeM_underground",
},
0,
7,
30,
100,
2,
mcl_vars.mg_overworld_min,
mcl_vars.mg_overworld_max)

-- Nether spawn (rare)
mcl_mobs:spawn_specific(
"mobs_mc:rover",
"nether",
"ground",
{
"Nether",
"SoulsandValley",
},
0,
11,
30,
100,
4,
mcl_vars.mg_nether_min,
mcl_vars.mg_nether_max)

-- Warped Forest spawn (common)
mcl_mobs:spawn_specific(
"mobs_mc:rover",
"nether",
"ground",
{
"WarpedForest"
},
0,
11,
30,
100,
4,
mcl_vars.mg_nether_min,
mcl_vars.mg_nether_max)

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:rover", S("Rover"), "#252525", "#151515", 0)
minetest.register_alias("mobs_mc:enderman", "mobs_mc:rover")
