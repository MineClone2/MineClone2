mcl_damage.register_modifier(function(obj, damage, reason)
	if reason.type == "player" then
		local hitter = reason.direct
		if mcl_sprint.is_sprinting(hitter) then
			obj:add_velocity(hitter:get_velocity())
		elseif (hitter:get_velocity() or hitter:get_player_velocity()).y < 0 then
			local pos = mcl_util.get_object_center(obj)
			minetest.add_particlespawner({
				amount = 15,
				time = 0.1,
				minpos = {x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
				maxpos = {x=pos.x+0.5, y=pos.y+0.5, z=pos.z+0.5},
				minvel = {x=-0.1, y=-0.1, z=-0.1},
				maxvel = {x=0.1, y=0.1, z=0.1},
				minacc = {x=0, y=0, z=0},
				maxacc = {x=0, y=0, z=0},
				minexptime = 1,
				maxexptime = 2,
				minsize = 1.5,
				maxsize = 1.5,
				collisiondetection = false,
				vertical = false,
				texture = "mcl_particles_crit.png^[colorize:#bc7a57:127",
			})
			minetest.sound_play("mcl_criticals_hit", {object = obj})
			local crit_mod
			local CRIT_MIN = 1.5
			local CRIT_DIFF = 1
			if hitter:is_player() then
				local luck = mcl_luck.get_luck(hitter:get_player_name())
				if luck ~= 0 then
					local a, d
					if luck > 0 then
						d = -0.5
						a = d - math.abs(luck)
					elseif luck < 0 then
						a = -0.5
						d = a - math.abs(luck)
					else
						minetest.log("warning", "[mcl_criticals] luck is not a number") -- this technically can't happen, but want to catch such cases
					end
					if a then
						local x = math.random()
						crit_mod = CRIT_DIFF * (a * x) / (d - luck * x) + CRIT_MIN
					end
				end
			end
			if not crit_mod then
				crit_mod = math.random(CRIT_MIN, CRIT_MIN + CRIT_DIFF)
			end
			return damage * crit_mod
		end
	end
end, -100)
