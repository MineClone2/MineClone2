local random = math.random

mcl_death_drop = {}

mcl_death_drop.registered_dropped_lists = {}

function mcl_death_drop.register_dropped_list(inv, listname, drop)
	table.insert(mcl_death_drop.registered_dropped_player_lists, {inv=inv, listname=listname, drop=drop})
end

mcl_death_drop.register_dropped_list("PLAYER", "main", true)
mcl_death_drop.register_dropped_list("PLAYER", "craft", true)
mcl_death_drop.register_dropped_list("PLAYER", "armor", true)
mcl_death_drop.register_dropped_list(function(player) return minetest.get_inventory({type="detached", name=player:get_player_name().."_armor"}) end , "armor", false)

minetest.register_on_dieplayer(function(player)
	local keep = minetest.settings:get_bool("mcl_keepInventory", false)
	if keep == false then
		-- Drop inventory, crafting grid and armor
		local inv = player:get_inventory()
		local pos = player:get_pos()
		local name, player_armor_inv, armor_armor_inv, pos = armor:get_valid_player(player, "[on_dieplayer]")
		-- No item drop if in deep void
		local void, void_deadly = mcl_worlds.is_in_void(pos)

		for l=1,#mcl_death_drop.registered_dropped_lists do
			local inv = mcl_death_drop.registered_dropped_lists[l].inv
			local listname = mcl_death_drop.registered_dropped_lists[l].listname
			local drop = mcl_death_drop.registered_dropped_lists[l].drop
			if inv ~= nil then
				for i, stack in ipairs(inv:get_list(listname)) do
					local x = random(0, 9)/3
					local z = random(0, 9)/3
					pos.x = pos.x + x
					pos.z = pos.z + z
					if not void_deadly and drop and not mcl_enchanting.has_enchantment(stack, "curse_of_vanishing") then
						local def = minetest.registered_items[stack:get_name()]
						if def and def.on_drop then
							stack = def.on_drop(stack, player, pos)
						end
						minetest.add_item(pos, stack)
					end
					pos.x = pos.x - x
					pos.z = pos.z - z
				end
				inv:set_list(listname, {})
			end
		end
		armor:set_player_armor(player)
		armor:update_inventory(player)
	end
end)
