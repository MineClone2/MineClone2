local S = minetest.get_translator(minetest.get_current_modname())

local mod_target = minetest.get_modpath("mcl_target")

local math = math

-- Time in seconds after which a stuck arrow is deleted
local ARROW_TIMEOUT = 60
-- Time after which stuck arrow is rechecked for being stuck
local STUCK_RECHECK_TIME = 5

--local GRAVITY = 9.81

local YAW_OFFSET = -math.pi/2

local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function arrow_image(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return {"mcl_bows_arrow.png^(mcl_bows_arrow_overlay.png^[colorize:"..colorstring..":"..tostring(opacity)..")"}
end

local how_to_shoot = minetest.registered_items["mcl_bows:arrow"]._doc_items_usagehelp

local mod_awards = minetest.get_modpath("awards") and minetest.get_modpath("mcl_achievements")
local mod_button = minetest.get_modpath("mesecons_button")
local enable_pvp = minetest.settings:get_bool("enable_pvp")

local arrow_longdesc = minetest.registered_items["mcl_bows:arrow"]._doc_items_longdesc or ""
local arrow_tt = minetest.registered_items["mcl_bows:arrow"]._tt_help or ""

function mcl_potions.register_arrow(name, desc, color, def)

	local longdesc = def._longdesc or ""
	local tt = def._tt or ""
	minetest.register_craftitem("mcl_potions:"..name.."_arrow", {
		description = desc,
		_tt_help = arrow_tt .. "\n" .. tt,
		_dynamic_tt = def._dynamic_tt,
		_doc_items_longdesc = arrow_longdesc .. "\n" ..
			S("This particular arrow is tipped and will give an effect when it hits a player or mob.") .. "\n" ..
			longdesc,
		_doc_items_usagehelp = how_to_shoot,
		_effect_list = def._effect_list,
		uses_level = def.uses_level,
		has_potent = def.has_potent,
		has_plus = def.has_plus,
		_default_potent_level = def._default_potent_level,
		_default_extend_level = def._default_extend_level,
		inventory_image = "mcl_bows_arrow_inv.png^(mcl_potions_arrow_inv.png^[colorize:"..color..":100)",
		groups = { ammo=1, ammo_bow=1, brewitem=1, _mcl_potion=1},
		_on_dispense = function(itemstack, dispenserpos, droppos, dropnode, dropdir)
			-- Shoot arrow
			local shootpos = vector.add(dispenserpos, vector.multiply(dropdir, 0.51))
			local yaw = math.atan2(dropdir.z, dropdir.x) + YAW_OFFSET
			mcl_bows.shoot_arrow(itemstack:get_name(), shootpos, dropdir, yaw, nil, 19, 3)
		end,
	})


	-- This is a fake node, used as model for the arrow entity.
	-- It's not supposed to be usable as item or real node.
	-- TODO: Use a proper mesh for the arrow entity
	minetest.register_node("mcl_potions:"..name.."_arrow_box", {
		drawtype = "nodebox",
		is_ground_content = false,
		node_box = {
			type = "fixed",
			fixed = {
				-- Shaft
				{-6.5/17, -1.5/17, -1.5/17, -4.5/17, 1.5/17, 1.5/17},
				{-4.5/17, -0.5/17, -0.5/17, 5.5/17, 0.5/17, 0.5/17},
				{5.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
				-- Tip
				{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
				{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
				-- Fletching
				{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
				{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
				{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
				{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},

				{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
				{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
				{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
				{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17},
			}
		},
		tiles = arrow_image(color, 100),
		use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		groups = {not_in_creative_inventory=1, dig_immediate=3},
		drop = "",
		node_placement_prediction = "",
		on_construct = function(pos)
			minetest.log("error", "[mcl_potions] Trying to construct mcl_potions:"..name.."arrow_box at "..minetest.pos_to_string(pos))
			minetest.remove_node(pos)
		end,
	})


	local ARROW_ENTITY={
		physical = true,
		visual = "mesh",
		mesh = "mcl_bows_arrow.obj",
		visual_size = {x=-1, y=1},
		textures = arrow_image(color, 100),
		collisionbox = {-0.19, -0.125, -0.19, 0.19, 0.125, 0.19},
		collide_with_objects = false,

		_lastpos={},
		_startpos=nil,
		_damage=1,	-- Damage on impact
		_stuck=false,   -- Whether arrow is stuck
		_stucktimer=nil,-- Amount of time (in seconds) the arrow has been stuck so far
		_stuckrechecktimer=nil,-- An additional timer for periodically re-checking the stuck status of an arrow
		_stuckin=nil,	--Position of node in which arow is stuck.
		_shooter=nil,	-- ObjectRef of player or mob who shot it

		_viscosity=0,   -- Viscosity of node the arrow is currently in
		_deflection_cooloff=0, -- Cooloff timer after an arrow deflection, to prevent many deflections in quick succession
	}

	-- Destroy arrow entity self at pos and drops it as an item
	local function spawn_item(self, pos)
		if not minetest.is_creative_enabled("") then
			local item = minetest.add_item(pos, "mcl_potions:"..name.."_arrow")
			item:set_velocity({x=0, y=0, z=0})
			item:set_yaw(self.object:get_yaw())
		end
		self.object:remove()
	end

	function ARROW_ENTITY.on_step(self, dtime)
		local pos = self.object:get_pos()
		local dpos = table.copy(pos) -- digital pos
		dpos = vector.round(dpos)
		local node = minetest.get_node(dpos)

		if self._stuck then
			self._stucktimer = self._stucktimer + dtime
			self._stuckrechecktimer = self._stuckrechecktimer + dtime
			if self._stucktimer > ARROW_TIMEOUT then
				self.object:remove()
				return
			end
			-- Drop arrow as item when it is no longer stuck
			-- FIXME: Arrows are a bit slow to react and continue to float in mid air for a few seconds.
			if self._stuckrechecktimer > STUCK_RECHECK_TIME then
				local stuckin_def
				if self._stuckin then
					stuckin_def = minetest.registered_nodes[minetest.get_node(self._stuckin).name]
				end
				-- TODO: In MC, arrow just falls down without turning into an item
				if stuckin_def and stuckin_def.walkable == false then
					spawn_item(self, pos)
					return
				end
				self._stuckrechecktimer = 0
			end
			-- Pickup arrow if player is nearby (not in Creative Mode)
			local objects = minetest.get_objects_inside_radius(pos, 1)
			for _,obj in ipairs(objects) do
				if obj:is_player() then
					if not minetest.is_creative_enabled(obj:get_player_name()) then
						if obj:get_inventory():room_for_item("main", "mcl_potions:"..name.."_arrow") then
							obj:get_inventory():add_item("main", "mcl_potions:"..name.."_arrow")
							minetest.sound_play("item_drop_pickup", {
								pos = pos,
								max_hear_distance = 16,
								gain = 1.0,
							}, true)
						end
					end
					self.object:remove()
					return
				end
			end

		-- Check for object "collision". Done every tick (hopefully this is not too stressing)
		else

			if self._damage == 10 or self._damage == 9 then
				minetest.add_particlespawner({
					amount = 1,
					time = .001,
					minpos = pos,
					maxpos = pos,
					minvel = vector.new(-0.1,-0.1,-0.1),
					maxvel = vector.new(0.1,0.1,0.1),
					minexptime = 0.5,
					maxexptime = 0.5,
					minsize = 2,
					maxsize = 2,
					collisiondetection = false,
					vertical = false,
					texture = "mobs_mc_arrow_particle.png",
					glow = 1,
				})
			end
			-- We just check for any hurtable objects nearby.
			-- The radius of 3 is fairly liberal, but anything lower than than will cause
			-- arrow to hilariously go through mobs often.
			-- TODO: Implement an ACTUAL collision detection (engine support needed).
			local objs = minetest.get_objects_inside_radius(pos, 1.5)
			local closest_object
			local closest_distance

			if self._deflection_cooloff > 0 then
				self._deflection_cooloff = self._deflection_cooloff - dtime
			end

			-- Iterate through all objects and remember the closest attackable object
			local arrow_dir = self.object:get_velocity()
			--create a raycast from the arrow based on the velocity of the arrow to deal with lag
			local raycast = minetest.raycast(pos, vector.add(pos, vector.multiply(arrow_dir, 0.1)), true, false)
			for hitpoint in raycast do
				if hitpoint.type == "object" then
					-- find the closest object that is in the way of the arrow
					local ok = false
					if hitpoint.ref:is_player() and enable_pvp then
						ok = true
					elseif not hitpoint.ref:is_player() and hitpoint.ref:get_luaentity() then
						if (hitpoint.ref:get_luaentity().is_mob or hitpoint.ref:get_luaentity()._hittable_by_projectile) then
							ok = true
						end
					end
					if ok then
						local dist = vector.distance(hitpoint.ref:get_pos(), pos)
						if not closest_object or not closest_distance then
							closest_object = hitpoint.ref
							closest_distance = dist
						elseif dist < closest_distance then
							closest_object = hitpoint.ref
							closest_distance = dist
						end
					end
				end
			end


			-- If an attackable object was found, we will damage the closest one only
			if closest_object then
				local obj = closest_object
				local is_player = obj:is_player()
				local lua = obj:get_luaentity()
				if obj ~= self._shooter and (is_player or (lua and lua.is_mob)) then

					if obj:get_hp() > 0 then
						-- Check if there is no solid node between arrow and object
						local ray = minetest.raycast(self.object:get_pos(), obj:get_pos(), true)
						for pointed_thing in ray do
							if pointed_thing.type == "object" and pointed_thing.ref == closest_object then
								-- Target reached! We can proceed now.
								break
							elseif pointed_thing.type == "node" then
								local nn = minetest.get_node(minetest.get_pointed_thing_position(pointed_thing)).name
								local nodedef = minetest.registered_nodes[nn]
								if (not nodedef) or nodedef.walkable then
									-- There's a node in the way. Delete arrow without damage
									self.object:remove()
									return
								end
							end
						end

						local potency = self._potency or 0
						local plus = self._plus or 0

						-- Punch target object but avoid hurting enderman.
						if lua then
							if lua.name ~= "mobs_mc:enderman" then
								obj:punch(self.object, 1.0, {
									full_punch_interval=1.0,
									damage_groups={fleshy=self._damage},
								}, nil)
								if def._effect_list then
									local ef_level
									local dur
									for name, details in pairs(def._effect_list) do
										if details.uses_level then
											ef_level = details.level + details.level_scaling * (potency)
										else
											ef_level = details.level
										end
										if details.dur_variable then
											dur = details.dur * math.pow(mcl_potions.PLUS_FACTOR, plus)
											if potency>0 and details.uses_level then
												dur = dur / math.pow(mcl_potions.POTENT_FACTOR, potency)
											end
										else
											dur = details.dur
										end
										mcl_potions.give_effect_by_level(name, obj, ef_level, dur)
									end
								end
								if def.custom_effect then def.custom_effect(obj, potency+1) end
							end
						else
							obj:punch(self.object, 1.0, {
								full_punch_interval=1.0,
								damage_groups={fleshy=self._damage},
							}, nil)
							if def._effect_list then
								local ef_level
								local dur
								for name, details in pairs(def._effect_list) do
									if details.uses_level then
										ef_level = details.level + details.level_scaling * (potency)
									else
										ef_level = details.level
									end
									if details.dur_variable then
										dur = details.dur * math.pow(mcl_potions.PLUS_FACTOR, plus)
										if potency>0 and details.uses_level then
											dur = dur / math.pow(mcl_potions.POTENT_FACTOR, potency)
										end
									else
										dur = details.dur
									end
									dur = dur * mcl_potions.SPLASH_FACTOR
									if rad > 0 then
										mcl_potions.give_effect_by_level(name, obj, ef_level, redux_map[rad]*dur)
									else
										mcl_potions.give_effect_by_level(name, obj, ef_level, dur)
									end
								end
							end
							if def.custom_effect then def.custom_effect(obj, potency+1) end
						end

						if is_player then
							if self._shooter and self._shooter:is_player() then
								-- “Ding” sound for hitting another player
								minetest.sound_play({name="mcl_bows_hit_player", gain=0.1}, {to_player=self._shooter:get_player_name()}, true)
							end
						end

						if lua then
							local entity_name = lua.name
							-- Achievement for hitting skeleton, wither skeleton or stray (TODO) with an arrow at least 50 meters away
							-- NOTE: Range has been reduced because mobs unload much earlier than that ... >_>
							-- TODO: This achievement should be given for the kill, not just a hit
							if self._shooter and self._shooter:is_player() and vector.distance(pos, self._startpos) >= 20 then
								if mod_awards and (entity_name == "mobs_mc:skeleton" or entity_name == "mobs_mc:stray" or entity_name == "mobs_mc:witherskeleton") then
									awards.unlock(self._shooter:get_player_name(), "mcl:snipeSkeleton")
								end
							end
						end
					end
					self.object:remove()
					return
				end
			end
		end

		-- Check for node collision
		if self._lastpos.x~=nil and not self._stuck then
			local nodedef = minetest.registered_nodes[node.name]
			local vel = self.object:get_velocity()
			-- Arrow has stopped in one axis, so it probably hit something.
			-- This detection is a bit clunky, but sadly, MT does not offer a direct collision detection for us. :-(
			if (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) then
				-- Check for the node to which the arrow is pointing
				local dir
				if math.abs(vel.y) < 0.00001 then
					if self._lastpos.y < pos.y then
						dir = {x=0, y=1, z=0}
					else
						dir = {x=0, y=-1, z=0}
					end
				else
					dir = minetest.facedir_to_dir(minetest.dir_to_facedir(minetest.yaw_to_dir(self.object:get_yaw()-YAW_OFFSET)))
				end
				self._stuckin = vector.add(dpos, dir)
				local snode = minetest.get_node(self._stuckin)
				local sdef = minetest.registered_nodes[snode.name]

				-- If node is non-walkable, unknown or ignore, don't make arrow stuck.
				-- This causes a deflection in the engine.
				if not sdef or sdef.walkable == false or snode.name == "ignore" then
					self._stuckin = nil
					if self._deflection_cooloff <= 0 then
						-- Lose 1/3 of velocity on deflection
						local newvel = vector.multiply(vel, 0.6667)

						self.object:set_velocity(newvel)
						-- Reset deflection cooloff timer to prevent many deflections happening in quick succession
						self._deflection_cooloff = 1.0
					end
				else

					-- Node was walkable, make arrow stuck
					self._stuck = true
					self._stucktimer = 0
					self._stuckrechecktimer = 0

					self.object:set_velocity({x=0, y=0, z=0})
					self.object:set_acceleration({x=0, y=0, z=0})

					-- Activate target
					if mod_target and snode.name == "mcl_target:target_off" then
						mcl_target.hit(self._stuckin, 1) --10 redstone ticks
					end

					-- Push the button! Push, push, push the button!
					if mod_button and minetest.get_item_group(node.name, "button") > 0 and minetest.get_item_group(node.name, "button_push_by_arrow") == 1 then
						local bdir = minetest.wallmounted_to_dir(node.param2)
						-- Check the button orientation
						if vector.equals(vector.add(dpos, bdir), self._stuckin) then
							mesecon.push_button(dpos, node)
						end
					end
				end
			elseif (nodedef and nodedef.liquidtype ~= "none") then
				-- Slow down arrow in liquids
				local v = nodedef.liquid_viscosity
				if not v then
					v = 0
				end
				--local old_v = self._viscosity
				self._viscosity = v
				local vpenalty = math.max(0.1, 0.98 - 0.1 * v)
				if math.abs(vel.x) > 0.001 then
					vel.x = vel.x * vpenalty
				end
				if math.abs(vel.z) > 0.001 then
					vel.z = vel.z * vpenalty
				end
				self.object:set_velocity(vel)
			end
		end

		-- Update yaw
		if not self._stuck then
			local vel = self.object:get_velocity()
			local yaw = minetest.dir_to_yaw(vel)+YAW_OFFSET
			local pitch = dir_to_pitch(vel)
			self.object:set_rotation({ x = 0, y = yaw, z = pitch })
		end

		-- Update internal variable
		self._lastpos={x=pos.x, y=pos.y, z=pos.z}
	end

	-- Force recheck of stuck arrows when punched.
	-- Otherwise, punching has no effect.
	function ARROW_ENTITY.on_punch(self)
		if self._stuck then
			self._stuckrechecktimer = STUCK_RECHECK_TIME
		end
	end

	function ARROW_ENTITY.get_staticdata(self)
		local out = {
			lastpos = self._lastpos,
			startpos = self._startpos,
			damage = self._damage,
			stuck = self._stuck,
			stuckin = self._stuckin,
		}
		if self._stuck then
			-- If _stucktimer is missing for some reason, assume the maximum
			if not self._stucktimer then
				self._stucktimer = ARROW_TIMEOUT
			end
			out.stuckstarttime = minetest.get_gametime() - self._stucktimer
		end
		if self._shooter and self._shooter:is_player() then
			out.shootername = self._shooter:get_player_name()
		end
		return minetest.serialize(out)
	end

	function ARROW_ENTITY.on_activate(self, staticdata, dtime_s)
		local data = minetest.deserialize(staticdata)
		if data then
			self._stuck = data.stuck
			if data.stuck then
				if data.stuckstarttime then
					-- First, check if the stuck arrow is aleady past its life timer.
					-- If yes, delete it.
					self._stucktimer = minetest.get_gametime() - data.stuckstarttime
					if self._stucktimer > ARROW_TIMEOUT then
						self.object:remove()
						return
					end
				end

				-- Perform a stuck recheck on the next step.
				self._stuckrechecktimer = STUCK_RECHECK_TIME

				self._stuckin = data.stuckin
			end

			-- Get the remaining arrow state
			self._lastpos = data.lastpos
			self._startpos = data.startpos
			self._damage = data.damage
			if data.shootername then
				local shooter = minetest.get_player_by_name(data.shootername)
				if shooter and shooter:is_player() then
					self._shooter = shooter
				end
			end
		end
		self.object:set_armor_groups({ immortal = 1 })
	end

	minetest.register_entity("mcl_potions:"..name.."_arrow_entity", ARROW_ENTITY)

	if minetest.get_modpath("mcl_bows") then
		minetest.register_craft({
			output = "mcl_potions:"..name.."_arrow 8",
			recipe = {
				{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"},
				{"mcl_bows:arrow","mcl_potions:"..name.."_lingering","mcl_bows:arrow"},
				{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"}
			}
		})

	end

	if minetest.get_modpath("doc_identifier") then
		doc.sub.identifier.register_object("mcl_bows:arrow_entity", "craftitems", "mcl_bows:arrow")
	end
end
