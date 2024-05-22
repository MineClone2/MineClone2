local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local math = math
local vector = vector

local mod_target = minetest.get_modpath("mcl_target")
local how_to_throw = S("Use the punch key to throw.")

-- Ender Pearl
minetest.register_craftitem("mcl_throwing:ender_pearl", {
	description = S("Ender Pearl"),
	_tt_help = S("Throwable").."\n"..minetest.colorize(mcl_colors.YELLOW, S("Teleports you on impact for cost of 5 HP")),
	_doc_items_longdesc = S("An ender pearl is an item which can be used for teleportation at the cost of health. It can be thrown and teleport the thrower to its impact location when it hits a solid block or a plant. Each teleportation hurts the user by 5 hit points."),
	_doc_items_usagehelp = how_to_throw,
	wield_image = "mcl_throwing_ender_pearl.png",
	inventory_image = "mcl_throwing_ender_pearl.png",
	stack_max = 16,
	on_use = mcl_throwing.get_player_throw_function("mcl_throwing:ender_pearl_entity"),
	groups = { transport = 1 },
})
mcl_throwing.register_throwable_object("mcl_throwing:ender_pearl", "mcl_throwing:ender_pearl_entity", 22)

-- Ender pearl entity
minetest.register_entity("mcl_throwing:ender_pearl_entity",{
	physical = false,
	timer=0,
	textures = {"mcl_throwing_ender_pearl.png"},
	visual_size = {x=0.9, y=0.9},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = mcl_throwing.get_staticdata,
	on_activate = mcl_throwing.on_activate,

	on_step = vl_projectile.update_projectile,
	_lastpos={},
	_thrower = nil,		-- Player ObjectRef of the player who threw the ender pearl
	_vl_projectile = {
		behaviors = {
			vl_projectile.collides_with_solids,
		},
		collides_with = {
			"mcl_core:vine", "mcl_core:deadbush",
			"group:flower", "group:sapling",
			"group:plant", "group:mushroom",
		},
		on_collide_with_solid = function(self, pos, node)
			if mod_target and node.name == "mcl_target:target_off" then
				mcl_target.hit(vector.round(pos), 0.4) --4 redstone ticks
			end

			if node.name == "ignore" then
				-- FIXME: This also means the player loses an ender pearl for throwing into unloaded areas
				return
			end

			-- Make sure we have a reference to the player
			local player = self._thrower and minetest.get_player_by_name(self._thrower)
			if not player then return end

			-- Teleport and hurt player

			-- First determine good teleport position
			local dir = {x=0, y=0, z=0}

			local v = self.object:get_velocity()
			if node_def and node_def.walkable then
				local vc = table.copy(v) -- vector for calculating
				-- Node is walkable, we have to find a place somewhere outside of that node
				vc = vector.normalize(vc)

				-- Zero-out the two axes with a lower absolute value than
				-- the axis with the strongest force
				local lv, ld
				lv, ld = math.abs(vc.y), "y"
				if math.abs(vc.x) > lv then
					lv, ld = math.abs(vc.x), "x"
				end
				if math.abs(vc.z) > lv then
					ld = "z" --math.abs(vc.z)
				end
				if ld ~= "x" then vc.x = 0 end
				if ld ~= "y" then vc.y = 0 end
				if ld ~= "z" then vc.z = 0 end

				-- Final tweaks to the teleporting pos, based on direction
				-- Impact from the side
				dir.x = vc.x * -1
				dir.z = vc.z * -1

				-- Special case: top or bottom of node
				if vc.y > 0 then
					-- We need more space when impact is from below
					dir.y = -2.3
				elseif vc.y < 0 then
					-- Standing on top
					dir.y = 0.5
				end
			end
			-- If node was not walkable, no modification to pos is made.

			-- Final teleportation position
			local telepos = vector.add(pos, dir)
			local telenode = minetest.get_node(telepos)

			--[[ It may be possible that telepos is walkable due to the algorithm.
			Especially when the ender pearl is faster horizontally than vertical.
			This applies final fixing, just to be sure we're not in a walkable node ]]
			if not minetest.registered_nodes[telenode.name] or minetest.registered_nodes[telenode.name].walkable then
				if v.y < 0 then
					telepos.y = telepos.y + 0.5
				else
					telepos.y = telepos.y - 2.3
				end
			end

			local oldpos = player:get_pos()
			-- Teleport and hurt player
			player:set_pos(telepos)
			player:set_hp(player:get_hp() - 5, { type = "fall", from = "mod" })

			-- 5% chance to spawn endermite at the player's origin
			local r = math.random(1,20)
			if r == 1 then
				minetest.add_entity(oldpos, "mobs_mc:endermite")
			end
		end
	},
})
