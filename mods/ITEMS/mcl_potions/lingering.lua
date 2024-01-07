local S = minetest.get_translator(minetest.get_current_modname())

local mod_target = minetest.get_modpath("mcl_target")

local function lingering_image(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return "mcl_potions_splash_overlay.png^[colorize:"..colorstring..":"..tostring(opacity).."^mcl_potions_lingering_bottle.png"
end

local lingering_effect_at = {}

local function add_lingering_effect(pos, color, def, is_water, potency, plus)
	lingering_effect_at[pos] = {color = color, timer = 30, def = def, is_water = is_water, potency = potency, plus = plus}
end

local function linger_particles(pos, d, texture, color)
	minetest.add_particlespawner({
		amount = 10 * d^2,
		time = 1,
		minpos = {x=pos.x-d, y=pos.y+0.5, z=pos.z-d},
		maxpos = {x=pos.x+d, y=pos.y+1, z=pos.z+d},
		minvel = {x=-0.5, y=0, z=-0.5},
		maxvel = {x=0.5, y=0.5, z=0.5},
		minacc = {x=-0.2, y=0, z=-0.2},
		maxacc = {x=0.2, y=.05, z=0.2},
		minexptime = 1,
		maxexptime = 2,
		minsize = 2,
		maxsize = 4,
		collisiondetection = true,
		vertical = false,
		texture = texture.."^[colorize:"..color..":127",
	})
end

local lingering_timer = 0
minetest.register_globalstep(function(dtime)

	lingering_timer = lingering_timer + dtime
	if lingering_timer >= 1 then

		for pos, vals in pairs(lingering_effect_at) do

			vals.timer = vals.timer - lingering_timer
			local d = 4 * (vals.timer / 30.0)
			local texture
			if vals.is_water then
				texture = "mcl_particles_droplet_bottle.png"
			elseif vals.def.instant then
				texture = "mcl_particles_instant_effect.png"
			else
				texture = "mcl_particles_effect.png"
			end
			linger_particles(pos, d, texture, vals.color)

-- 			-- Extinguish fire if water bottle
-- 			if vals.is_water then
-- 				if mcl_potions._extinguish_nearby_fire(pos, d) then
-- 					vals.timer = vals.timer - 3.25
-- 				end
-- 			end

			if vals.def.while_lingering and vals.def.while_lingering(pos, d, vals.potency+1) then
				vals.timer = vals.timer - 3.25
			end

			-- Affect players and mobs
			for _, obj in pairs(minetest.get_objects_inside_radius(pos, d)) do

				local entity = obj:get_luaentity()
				if obj:is_player() or entity and entity.is_mob then
					local applied = false
					if vals.def._effect_list then
						local ef_level
						local dur
						for name, details in pairs(vals.def._effect_list) do
							if details.uses_level then
								ef_level = details.level + details.level_scaling * (vals.potency)
							else
								ef_level = details.level
							end
							if details.dur_variable then
								dur = details.dur * math.pow(mcl_potions.PLUS_FACTOR, vals.plus)
								if vals.potency>0 and details.uses_level then
									dur = dur / math.pow(mcl_potions.POTENT_FACTOR, vals.potency)
								end
							else
								dur = details.dur
							end
							dur = dur * mcl_potions.SPLASH_FACTOR
							if mcl_potions.give_effect_by_level(name, obj, ef_level, dur) then
								applied = true
							end
						end
					end

					if vals.def.custom_effect and vals.def.custom_effect(obj, vals.potency+1) then
						applied = true
					end

					if applied then vals.timer = vals.timer - 3.25 end
				end
			end

			if vals.timer <= 0 then
				lingering_effect_at[pos] = nil
			end

		end
		lingering_timer = 0
	end
end)



function mcl_potions.register_lingering(name, descr, color, def)
	local id = "mcl_potions:"..name.."_lingering"
	local longdesc = def._longdesc
	if not def.no_effect then
		longdesc = S("A throwable potion that will shatter on impact, where it creates a magic cloud that lingers around for a while. Any player or mob inside the cloud will receive the potion's effect or set of effects, possibly repeatedly.")
		if def.longdesc then
			longdesc = longdesc .. "\n" .. def._longdesc
		end
	end
	minetest.register_craftitem(id, {
		description = descr,
		_tt_help = def._tt,
		_dynamic_tt = def._dynamic_tt,
		_doc_items_longdesc = longdesc,
		_doc_items_usagehelp = S("Use the “Punch” key to throw it."),
		stack_max = def.stack_max,
		_effect_list = def._effect_list,
		uses_level = def.uses_level,
		has_potent = def.has_potent,
		has_plus = def.has_plus,
		_default_potent_level = def._default_potent_level,
		_default_extend_level = def._default_extend_level,
		inventory_image = lingering_image(color),
		groups = {brewitem=1, bottle=1, _mcl_potion=1},
		on_use = function(item, placer, pointed_thing)
			local velocity = 10
			local dir = placer:get_look_dir();
			local pos = placer:getpos();
			minetest.sound_play("mcl_throwing_throw", {pos = pos, gain = 0.4, max_hear_distance = 16}, true)
			local obj = minetest.add_entity({x=pos.x+dir.x,y=pos.y+2+dir.y,z=pos.z+dir.z}, id.."_flying")
			obj:set_velocity({x=dir.x*velocity,y=dir.y*velocity,z=dir.z*velocity})
			obj:set_acceleration({x=dir.x*-3, y=-9.8, z=dir.z*-3})
			local ent = obj:get_luaentity()
			ent._thrower = placer:get_player_name()
			ent._potency = item:get_meta():get_int("mcl_potions:potion_potent")
			ent._plus = item:get_meta():get_int("mcl_potions:potion_plus")
			ent._effect_list = def._effect_list
			if not minetest.is_creative_enabled(placer:get_player_name()) then
				item:take_item()
			end
			return item
		end,
		stack_max = 1,
		_on_dispense = function(stack, dispenserpos, droppos, dropnode, dropdir)
			local s_pos = vector.add(dispenserpos, vector.multiply(dropdir, 0.51))
			local pos = {x=s_pos.x+dropdir.x,y=s_pos.y+dropdir.y,z=s_pos.z+dropdir.z}
			minetest.sound_play("mcl_throwing_throw", {pos = pos, gain = 0.4, max_hear_distance = 16}, true)
			local obj = minetest.add_entity(pos, id.."_flying")
			local velocity = 22
			obj:set_velocity({x=dropdir.x*velocity,y=dropdir.y*velocity,z=dropdir.z*velocity})
			obj:set_acceleration({x=dropdir.x*-3, y=-9.8, z=dropdir.z*-3})
			local ent = obj:get_luaentity()
			ent._potency = item:get_meta():get_int("mcl_potions:potion_potent")
			ent._plus = item:get_meta():get_int("mcl_potions:potion_plus")
			ent._effect_list = def._effect_list
		end
	})

	local w = 0.7

	minetest.register_entity(id.."_flying",{
		textures = {lingering_image(color)},
		hp_max = 1,
		visual_size = {x=w/2,y=w/2},
		collisionbox = {-0.1,-0.1,-0.1,0.1,0.1,0.1},
		pointable = false,
		on_step = function(self, dtime)
			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			local n = node.name
			local g = minetest.get_item_group(n, "liquid")
			local d = 4
			if mod_target and n == "mcl_target:target_off" then
				mcl_target.hit(vector.round(pos), 0.4) --4 redstone ticks
			end
			if n ~= "air" and n ~= "mcl_portals:portal" and n ~= "mcl_portals:portal_end" and g == 0 or mcl_potions.is_obj_hit(self, pos) then
				minetest.sound_play("mcl_potions_breaking_glass", {pos = pos, max_hear_distance = 16, gain = 1})
				local potency = self._potency or 0
				local plus = self._plus or 0
				add_lingering_effect(pos, color, def, name == "water", potency, plus)
				local texture
				if name == "water" then
					texture = "mcl_particles_droplet_bottle.png"
				else
					if def.instant then
						texture = "mcl_particles_instant_effect.png"
					else
						texture = "mcl_particles_effect.png"
					end
				end
				linger_particles(pos, d, texture, color)
				if def.on_splash then def.on_splash(pos, potency+1) end
				self.object:remove()
			end
		end,
	})
end
