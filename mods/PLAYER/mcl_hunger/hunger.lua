--local S = minetest.get_translator(minetest.get_current_modname())

-- wrapper for minetest.item_eat (this way we make sure other mods can't break this one)
function minetest.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if not user or user:is_player() == false then
		return itemstack
	end

	-- Call on_rightclick if the pointed node defines it
	if pointed_thing.type == "node" then
		local node = minetest.get_node(pointed_thing.under)
		if user and not user:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
			end
		end
	end
	-- Also don't eat when pointing object (it could be an animal)
	if pointed_thing.type == "object" then
		return itemstack
	end

	local old_itemstack = itemstack

	local name = user:get_player_name()

	local creative = minetest.is_creative_enabled(name)

	-- Special foodstuffs like the cake may disable the eating delay
	local no_eat_delay = creative or (minetest.get_item_group(itemstack:get_name(), "no_eat_delay") == 1)

	-- Allow eating only after a delay of 2 seconds. This prevents eating as an excessive speed.
	-- FIXME: time() is not a precise timer, so the actual delay may be +- 1 second, depending on which fraction
	-- of the second the player made the first eat.
	-- FIXME: In singleplayer, there's a cheat to circumvent this, simply by pausing the game between eats.
	-- This is because os.time() obviously does not care about the pause. A fix needs a different timer mechanism.
	if no_eat_delay or (mcl_hunger.last_eat[name] < 0) or (os.difftime(os.time(), mcl_hunger.last_eat[name]) >= 2) then
		local can_eat_when_full = creative or (mcl_hunger.active == false)
		or minetest.get_item_group(itemstack:get_name(), "can_eat_when_full") == 1
		-- Don't allow eating when player has full hunger bar (some exceptional items apply)
		if not no_eat_delay and not mcl_hunger.eat_internal[name].is_eating and not mcl_hunger.eat_internal[name].do_item_eat and (can_eat_when_full or (mcl_hunger.get_hunger(user) < 20)) then
			local itemname = itemstack:get_name()
			table.update(mcl_hunger.eat_internal[name], {
				is_eating = true,
				is_eating_no_padding = true,
				itemname = itemname,
				item_definition = minetest.registered_items[itemname],
				hp_change = hp_change,
				replace_with_item = replace_with_item,
				itemstack = itemstack,
				user = user,
				pointed_thing = pointed_thing
			})
		elseif (mcl_hunger.eat_internal[name].do_item_eat or no_eat_delay) and (can_eat_when_full or (mcl_hunger.get_hunger(user) < 20)) then
			if mcl_hunger.eat_internal[name]._custom_itemstack and
				mcl_hunger.eat_internal[name]._custom_wrapper and
				mcl_hunger.eat_internal[name]._custom_itemstack == itemstack then

				mcl_hunger.eat_internal[name]._custom_wrapper(name)
			end
			itemstack = mcl_hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
			for _, callback in pairs(minetest.registered_on_item_eats) do
				local result = callback(hp_change, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
				if result then
					return result
				end
			end
			mcl_hunger.last_eat[name] = os.time()
			user:get_inventory():set_stack("main", user:get_wield_index(), itemstack)
		end
	end

	return itemstack
end

function mcl_hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local item = itemstack:get_name()
	local def = mcl_hunger.registered_foods[item]
	if not def then
		def = {}
		if type(hp_change) ~= "number" then
			hp_change = 1
			minetest.log("error", "Wrong on_use() definition for item '" .. item .. "'")
		end
		def.saturation = hp_change
		def.replace = replace_with_item
	end
	local func = mcl_hunger.item_eat(def.saturation, def.replace, def.poisontime,
		def.poison, def.exhaust, def.poisonchance, def.sound)
	return func(itemstack, user, pointed_thing)
end

-- Reset HUD bars after food poisoning

function mcl_hunger.reset_bars_poison_hunger(player)
	hb.change_hudbar(player, "hunger", nil, nil, "hbhunger_icon.png", nil, "hbhunger_bar.png")
	if mcl_hunger.debug then
		hb.change_hudbar(player, "exhaustion", nil, nil, nil, nil, "mcl_hunger_bar_exhaustion.png")
	end
end

-- Poison player TODO remove this function
local function poisonp(tick, time, time_left, damage, exhaustion, name)
	if not mcl_hunger.active then
		return
	end
	local player = minetest.get_player_by_name(name)
	-- First check if player is still there
	if not player then
		return
	end
	-- Abort if food poisonings have been stopped
	if mcl_hunger.poison_hunger[name] == 0 then
		return
	end
	time_left = time_left + tick
	if time_left < time then
		minetest.after(tick, poisonp, tick, time, time_left, damage, exhaustion, name)
	else
		if exhaustion > 0 then
			mcl_hunger.poison_hunger [name] = mcl_hunger.poison_hunger[name] - 1
		end
		if mcl_hunger.poison_hunger[name] <= 0 then
			mcl_hunger.reset_bars_poison_hunger(player)
		end
	end

	-- Deal damage and exhaust player
	-- TODO: Introduce fatal poison at higher difficulties
	if player:get_hp()-damage > 0 then
		mcl_util.deal_damage(player, damage, {type = "hunger"})
	end

	mcl_hunger.exhaust(name, exhaustion)

end

local poisonrandomizer = PseudoRandom(os.time())

function mcl_hunger.item_eat(hunger_change, replace_with_item, poisontime, poison, exhaust, poisonchance, sound)
	return function(itemstack, user, pointed_thing)
		local itemname = itemstack:get_name()
		local creative = minetest.is_creative_enabled(user:get_player_name())
		if itemstack:peek_item() and user then
			if not creative then
				itemstack:take_item()
			end
			local name = user:get_player_name()
			--local hp = user:get_hp()

			local pos = user:get_pos()
			local def = minetest.registered_items[itemname]
	
			mcl_hunger.eat_effects(user, itemname, pos, hunger_change, def)

			if mcl_hunger.active and hunger_change then
				-- Add saturation (must be defined in item table)
				local _mcl_saturation = minetest.registered_items[itemname]._mcl_saturation
				local saturation
				if not _mcl_saturation then
					saturation = 0
				else
					saturation = minetest.registered_items[itemname]._mcl_saturation
				end
				mcl_hunger.saturate(name, saturation, false)

				-- Add food points
				local h = mcl_hunger.get_hunger(user)
				if h < 20 and hunger_change then
					h = h + hunger_change
					if h > 20 then h = 20 end
					mcl_hunger.set_hunger(user, h, false)
				end

				hb.change_hudbar(user, "hunger", h)
				mcl_hunger.update_saturation_hud(user, mcl_hunger.get_saturation(user), h)
			end
			-- Poison
			if mcl_hunger.active and poisontime then
				local do_poison = false
				if poisonchance then
					if poisonrandomizer:next(0,100) < poisonchance then
						do_poison = true
					end
				else
					do_poison = true
				end
				if do_poison then
					local level = mcl_potions.player_get_effect_level(user, "food_poisoning")
					mcl_potions.give_effect_by_level("food_poisoning", user, level+exhaust, poisontime)
				end
			end

			if not creative then
				itemstack:add_item(replace_with_item)
			end
		end
		return itemstack
	end
end

function mcl_hunger.eat_effects(user, itemname, pos, hunger_change, item_def, pitch)
	if user and itemname and pos and hunger_change and item_def then
		local name = user:get_player_name()
		if mcl_hunger.eat_internal[name] and mcl_hunger.eat_internal[name].do_item_eat then
			pitch = 0.95
		end
		local def = item_def
		-- player height
		pos.y = pos.y + 1.5
		local foodtype = minetest.get_item_group(itemname, "food")
		if foodtype == 3 then
			-- Item is a drink, only play drinking sound (no particle)
			minetest.sound_play("survival_thirst_drink", {
				max_hear_distance = 12,
				gain = 1.0,
				pitch = pitch or 1 + math.random(-10, 10)*0.005,
				object = user,
			}, true)
		else
			-- Assume the item is a food
			-- Add eat particle effect and sound
			--local def = minetest.registered_items[itemname]
			local texture = def.inventory_image
			if not texture or texture == "" then
				texture = def.wield_image
			end
			-- Special item definition field: _food_particles
			-- If false, force item to not spawn any food partiles when eaten
			if def._food_particles ~= false and texture and texture ~= "" then
				local v = user:get_velocity() or user:get_player_velocity()
				for i = 0, math.min(math.max(8, hunger_change*2), 25) do
					minetest.add_particle({
						pos = { x = pos.x, y = pos.y, z = pos.z },
						velocity = vector.add(v, { x = math.random(-1, 1), y = math.random(1, 2), z = math.random(-1, 1) }),
						acceleration = { x = 0, y = math.random(-9, -5), z = 0 },
						expirationtime = 1,
						size = math.random(1, 2),
						collisiondetection = true,
						vertical = false,
						texture = "[combine:3x3:" .. -i .. "," .. -i .. "=" .. texture,
					})
				end
			end
			minetest.sound_play("mcl_hunger_bite", {
				max_hear_distance = 12,
				gain = 1.0,
				pitch = pitch or 1 + math.random(-10, 10)*0.005,
				object = user,
			}, true)
		end
	else
		return false
	end
end

if mcl_hunger.active then
	-- player-action based hunger changes
	minetest.register_on_dignode(function(pos, oldnode, player)
		-- is_fake_player comes from the pipeworks, we are not interested in those
		if not player or not player:is_player() or player.is_fake_player == true then
			return
		end
		local name = player:get_player_name()
		-- dig event
		mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_DIG)
	end)
end
