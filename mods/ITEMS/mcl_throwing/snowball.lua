local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local how_to_throw = S("Use the punch key to throw.")

-- Snowball
minetest.register_craftitem("mcl_throwing:snowball", {
	description = S("Snowball"),
	_tt_help = S("Throwable"),
	_doc_items_longdesc = S("Snowballs can be thrown or launched from a dispenser for fun. Hitting something with a snowball does nothing."),
	_doc_items_usagehelp = how_to_throw,
	inventory_image = "mcl_throwing_snowball.png",
	stack_max = 16,
	groups = { weapon_ranged = 1 },
	on_use = mcl_throwing.get_player_throw_function("mcl_throwing:snowball_entity"),
	_on_dispense = mcl_throwing.dispense_function,
})
mcl_throwing.register_throwable_object("mcl_throwing:snowball", "mcl_throwing:snowball_entity", 22)

-- The snowball entity
local function snowball_particles(pos, vel)
	local vel = vector.normalize(vector.multiply(vel, -1))
	minetest.add_particlespawner({
		amount = 20,
		time = 0.001,
		minpos = pos,
		maxpos = pos,
		minvel = vector.add({x=-2, y=3, z=-2}, vel),
		maxvel = vector.add({x=2, y=5, z=2}, vel),
		minacc = {x=0, y=-9.81, z=0},
		maxacc = {x=0, y=-9.81, z=0},
		minexptime = 1,
		maxexptime = 3,
		minsize = 0.7,
		maxsize = 0.7,
		collisiondetection = true,
		collision_removal = true,
		object_collision = false,
		texture = "weather_pack_snow_snowflake"..math.random(1,2)..".png",
	})
end
vl_projectile.register("mcl_throwing:snowball_entity", {
	physical = false,
	timer=0,
	textures = {"mcl_throwing_snowball.png"},
	visual_size = {x=0.5, y=0.5},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = mcl_throwing.get_staticdata,
	on_activate = mcl_throwing.on_activate,
	_vl_projectile = {
		behaviors = {
			vl_projectile.collides_with_solids,
			vl_projectile.collides_with_entities,
		},
		on_collide_with_solid = function(self, pos, node)
			if mod_target and node.name == "mcl_target:target_off" then
				mcl_target.hit(vector.round(pos), 0.4) --4 redstone ticks
			end

			snowball_particles(self._last_pos or pos, self.object:get_velocity())
		end,
		on_collide_with_entity = function(self, pos, entity)
			snowball_particles(self._last_pos or pos, self.object:get_velocity())
		end,
		sounds = {
			on_solid_collision = {"mcl_throwing_snowball_impact_hard", { max_hear_distance=16, gain=0.7 }, true},
			on_entity_collision = {"mcl_throwing_snowball_impact_soft", { max_hear_distance=16, gain=0.7 }, true}
		},
		damage_groups = { snowball_vulnerable = 3 },
	},
})

