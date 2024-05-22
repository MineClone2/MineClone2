local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local mod_target = minetest.get_modpath("mcl_target")
local how_to_throw = S("Use the punch key to throw.")

-- Egg
minetest.register_craftitem("mcl_throwing:egg", {
	description = S("Egg"),
	_tt_help = S("Throwable").."\n"..S("Chance to hatch chicks when broken"),
	_doc_items_longdesc = S("Eggs can be thrown or launched from a dispenser and breaks on impact. There is a small chance that 1 or even 4 chicks will pop out of the egg."),
	_doc_items_usagehelp = how_to_throw,
	inventory_image = "mcl_throwing_egg.png",
	stack_max = 16,
	on_use = mcl_throwing.get_player_throw_function("mcl_throwing:egg_entity"),
	_on_dispense = mcl_throwing.dispense_function,
	groups = { craftitem = 1 },
})
mcl_throwing.register_throwable_object("mcl_throwing:egg", "mcl_throwing:egg_entity", 22)

minetest.register_entity("mcl_throwing:egg_entity",{
	physical = false,
	timer=0,
	textures = {"mcl_throwing_egg.png"},
	visual_size = {x=0.45, y=0.45},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = mcl_throwing.get_staticdata,
	on_activate = mcl_throwing.on_activate,

	on_step = vl_projectile.update_projectile,
	_lastpos={},
	_thrower = nil,
	_vl_projectile = {
		behaviors = {
			vl_projectile.collides_with_solids,
		},
		on_collide_with_solid = function(self, pos, node)
			if mod_target and node.name == "mcl_target:target_off" then
				mcl_target.hit(vector.round(pos), 0.4) --4 redstone ticks
			end

			-- 1/8 chance to spawn a chick
			-- FIXME: Chicks have a quite good chance to spawn in walls
			if math.random(1,8) ~= 1 then return end

			mcl_mobs.spawn_child(self._lastpos, "mobs_mc:chicken")

			-- BONUS ROUND: 1/32 chance to spawn 3 additional chicks
			if math.random(1,32) ~= 1 then return end

			local offsets = {
				{ x=0.7, y=0, z=0 },
				{ x=-0.7, y=0, z=-0.7 },
				{ x=-0.7, y=0, z=0.7 },
			}
			for o=1, 3 do
				local pos = vector.add(self._lastpos, offsets[o])
				mcl_mobs.spawn_child(pos, "mobs_mc:chicken")
			end
		end,
		sounds = {
			on_collision = {"mcl_throwing_egg_impact", {max_hear_distance=10, gain=0.5}, true}
		},
	},
})

