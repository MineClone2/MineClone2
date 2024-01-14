local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local S = minetest.get_translator(modname)

mcl_hunger = {}

--[[ This variable tells you if the hunger gameplay mechanic is active.
The state of the hunger mechanic will be determined at game start.
Hunger is enabled when damage is enabled.
If the damage setting is changed within the game, this does NOT
update the hunger mechanic, so the game must be restarted for this
to take effect. ]]
mcl_hunger.active = false
if minetest.settings:get_bool("enable_damage") == true and minetest.settings:get_bool("mcl_enable_hunger") ~= false then
	mcl_hunger.active = true
end

mcl_hunger.HUD_TICK = 0.1

-- Exhaustion increase
mcl_hunger.EXHAUST_DIG = 5  -- after digging node
mcl_hunger.EXHAUST_JUMP = 50 -- jump
mcl_hunger.EXHAUST_SPRINT_JUMP = 200 -- jump while sprinting
mcl_hunger.EXHAUST_ATTACK = 100 -- hit an enemy
mcl_hunger.EXHAUST_SWIM = 10 -- player movement in water
mcl_hunger.EXHAUST_SPRINT = 100 -- sprint (per node)
mcl_hunger.EXHAUST_DAMAGE = 100 -- taking damage (protected by armor)
mcl_hunger.EXHAUST_REGEN = 6000 -- Regenerate 1 HP
mcl_hunger.EXHAUST_HUNGER = 5 -- Hunger status effect at base level.
mcl_hunger.EXHAUST_LVL = 4000 -- at what exhaustion player saturation gets lowered

mcl_hunger.EATING_DELAY = tonumber(minetest.settings:get("mcl_eating_delay")) or 1.61
mcl_hunger.EATING_WALK_SPEED = tonumber(minetest.settings:get("movement_speed_crouch")) / tonumber(minetest.settings:get("movement_speed_walk"))
mcl_hunger.EATING_TOUCHSCREEN_DELAY_PADDING = 0.75

mcl_hunger.SATURATION_INIT = 5 -- Initial saturation for new/respawning players

-- Debug Mode. If enabled, saturation and exhaustion are shown as well.
-- NOTE: Only updated when settings are loaded.
mcl_hunger.debug = false

-- Cooldown timers for each player, to force a short delay between consuming 2 food items
mcl_hunger.last_eat = {}

-- Is player eating API
function mcl_hunger.is_eating(name)
	local result
	if name then
		if type(name) ~= "string" then
			name = name:get_player_name()
		end
		result = mcl_hunger.eat_internal[name].is_eating_no_padding
	end
	return result
end

-- Variables for each player, to handle delayed eating
mcl_hunger.eat_internal = {}

-- Set per player internal variables for delayed eating
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	mcl_hunger.eat_internal[name] = {
		is_eating = false,
		is_eating_no_padding = false,
		itemname = nil,
		item_definition = nil,
		hp_change = nil,
		replace_with_item = nil,
		itemstack = nil,
		user = nil,
		pointed_thing = nil,
		pitch = nil,
		do_item_eat = false,
		_custom_itemstack = nil, -- Used as comparison to make sure _custom_wrapper only executes when the same item is eaten
		_custom_var = {}, -- Variables that can be used by _custom_var and _custom_wrapper
		_custom_func = nil, -- Can be executed by _custom_wrapper
		_custom_wrapper = nil, -- Will execute alongside minetest.do_item_eat if not empty and _custom_itemstack is equal to current player itemstack
		_custom_do_delayed = false, -- If true, then will execute only _custom_wrapper after holding RMB or LMB within a delay specified by mcl_hunger.EATING_DELAY (Use to bypass minetest.do_item_eat entirely)
	}
	playerphysics.remove_physics_factor(player, "speed", "mcl_hunger:eating_speed")
end)

-- Clear when player leaves
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()

	mcl_hunger.eat_internal[name] = nil
end)

dofile(modpath.."/api.lua")
dofile(modpath.."/hunger.lua")
dofile(modpath.."/register_foods.lua")

--[[ IF HUNGER IS ENABLED ]]
if mcl_hunger.active == true then

-- Read debug mode setting
-- The setting should only be read at the beginning, this mod is not
-- prepared to change this setting later.
mcl_hunger.debug = minetest.settings:get_bool("mcl_hunger_debug")
if mcl_hunger.debug == nil then
	mcl_hunger.debug = false
end

--[[ Data value format notes:
	Hunger values is identical to Minecraft's and ranges from 0 to 20.
	Exhaustion and saturation values are stored as integers, unlike in Minecraft.
	Exhaustion is Minecraft exhaustion times 1000 and ranges from 0 to 4000.
	Saturation is Minecraft saturation and ranges from 0 to 20.

	Food saturation is stored in the custom item definition field _mcl_saturation.
	This field uses the original Minecraft value.
]]

-- Count number of poisonings a player has at once
mcl_hunger.poison_hunger = {} -- food poisoning, increasing hunger

-- HUD
local function init_hud(player)
	hb.init_hudbar(player, "hunger", mcl_hunger.get_hunger(player))
	if mcl_hunger.debug then
		hb.init_hudbar(player, "saturation", mcl_hunger.get_saturation(player), mcl_hunger.get_hunger(player))
		hb.init_hudbar(player, "exhaustion", mcl_hunger.get_exhaustion(player))
	end
end

-- HUD updating functions for Debug Mode. No-op if not in Debug Mode
function mcl_hunger.update_saturation_hud(player, saturation, hunger)
	if mcl_hunger.debug then
		hb.change_hudbar(player, "saturation", saturation, hunger)
	end
end
function mcl_hunger.update_exhaustion_hud(player, exhaustion)
	if mcl_hunger.debug then
		if not exhaustion then
			exhaustion =  mcl_hunger.get_exhaustion(player)
		end
		hb.change_hudbar(player, "exhaustion", exhaustion)
	end
end

-- register saturation hudbar
hb.register_hudbar("hunger", 0xFFFFFF, S("Food"), { icon = "hbhunger_icon.png", bgicon = "hbhunger_bgicon.png",  bar = "hbhunger_bar.png" }, 1, 20, 20, false)
if mcl_hunger.debug then
	hb.register_hudbar("saturation", 0xFFFFFF, S("Saturation"), { icon = "mcl_hunger_icon_saturation.png", bgicon = "mcl_hunger_bgicon_saturation.png", bar = "mcl_hunger_bar_saturation.png" }, 1, mcl_hunger.SATURATION_INIT, 200, false)
	hb.register_hudbar("exhaustion", 0xFFFFFF, S("Exhaust."), { icon = "mcl_hunger_icon_exhaustion.png", bgicon = "mcl_hunger_bgicon_exhaustion.png", bar = "mcl_hunger_bar_exhaustion.png" }, 1, 0, mcl_hunger.EXHAUST_LVL, false)
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	mcl_hunger.init_player(player)
	init_hud(player)
	mcl_hunger.poison_hunger[name] = 0
	mcl_hunger.last_eat[name] = -1
end)

minetest.register_on_respawnplayer(function(player)
	-- reset hunger, related values and poison
	local name = player:get_player_name()

	mcl_hunger.stop_poison(player)
	mcl_hunger.last_eat[name] = -1

	local h, s, e = 20, mcl_hunger.SATURATION_INIT, 0
	mcl_hunger.set_hunger(player, h, false)
	mcl_hunger.set_saturation(player, s, false)
	mcl_hunger.set_exhaustion(player, e, false)
	hb.change_hudbar(player, "hunger", h)
	mcl_hunger.update_saturation_hud(player, s, h)
	mcl_hunger.update_exhaustion_hud(player, e)
end)

-- PvP combat exhaustion
minetest.register_on_punchplayer(function(victim, puncher, time_from_last_punch, tool_capabilities, dir, damage)
	if puncher:is_player() then
		mcl_hunger.exhaust(puncher:get_player_name(), mcl_hunger.EXHAUST_ATTACK)
	end
end)

-- Exhaust on taking damage
minetest.register_on_player_hpchange(function(player, hp_change)
	if hp_change < 0 then
		local name = player:get_player_name()
		mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_DAMAGE)
	end
end)

local food_tick_timers = {} -- one food_tick_timer per player, keys are the player-objects
local eat_start_timers = {}
local eat_tick_timers = {}
local eat_effects_cooldown = {}

local function clear_eat_internal_and_timers(player, player_name)
	playerphysics.remove_physics_factor(player, "speed", "mcl_hunger:eating_speed")
	mcl_hunger.eat_internal[player_name] = {
		is_eating = false,
		is_eating_no_padding = false,
		itemname = nil,
		item_definition = nil,
		hp_change = nil,
		replace_with_item = nil,
		itemstack = nil,
		user = nil,
		pointed_thing = nil,
		pitch = nil,
		do_item_eat = false,
		_custom_itemstack = nil,
		_custom_var = {},
		_custom_func = nil,
		_custom_wrapper = nil,
		_custom_do_delayed = false,
	}
	eat_start_timers[player] = 0
	eat_tick_timers[player] = 0
	eat_effects_cooldown[player] = 0
end

minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do

		local food_tick_timer = food_tick_timers[player] and food_tick_timers[player] + dtime or 0
		local player_name = player:get_player_name()
		local food_level = mcl_hunger.get_hunger(player)
		local food_saturation_level = mcl_hunger.get_saturation(player)
		local player_health = player:get_hp()
		local max_tick_timer = tonumber(minetest.settings:get("mcl_health_regen_delay")) or 0.5

		if food_tick_timer > 4 then
			food_tick_timer = 0

			-- let hunger work always
			if player_health > 0 then
				--mcl_hunger.exhaust(player_name, mcl_hunger.EXHAUST_HUNGER) -- later for hunger status effect
				mcl_hunger.update_exhaustion_hud(player)
			end

			if food_level >= 18 then -- slow regeneration
				if player_health > 0 and player_health < player:get_properties().hp_max then
					player:set_hp(player_health+1)
					mcl_hunger.exhaust(player_name, mcl_hunger.EXHAUST_REGEN)
					mcl_hunger.update_exhaustion_hud(player)
				end

			elseif food_level == 0 then -- starvation
				-- the amount of health at which a player will stop to get
				-- harmed by starvation (10 for Easy, 1 for Normal, 0 for Hard)
				local maximum_starvation = 1
				-- TODO: implement Minecraft-like difficulty modes and the update maximumStarvation here
				if player_health > maximum_starvation then
					mcl_util.deal_damage(player, 1, {type = "starve"})
				end
			end

		elseif food_tick_timer > max_tick_timer and food_level == 20 and food_saturation_level > 0 then -- fast regeneration
			if player_health > 0 and player_health < player:get_properties().hp_max then
				food_tick_timer = 0
				player:set_hp(player_health+1)
				mcl_hunger.exhaust(player_name, mcl_hunger.EXHAUST_REGEN)
				mcl_hunger.update_exhaustion_hud(player)
			end
		end

		food_tick_timers[player] = food_tick_timer -- update food_tick_timer table

		-- Eating delay code
		if mcl_hunger.eat_internal[player_name] and mcl_hunger.eat_internal[player_name].is_eating or mcl_hunger.eat_internal[player_name]._custom_do_delayed then
			mcl_hunger.eat_internal[player_name].is_eating = true
			mcl_hunger.eat_internal[player_name].is_eating_no_padding = true

			local control = player:get_player_control()
			local inv = player:get_inventory()
			local current_itemstack = player:get_wielded_item()

			if not eat_start_timers[player] then
				eat_start_timers[player] = 0
			end

			eat_start_timers[player] = eat_start_timers[player] + dtime

			if not eat_tick_timers[player] then
				eat_tick_timers[player] = 0
			end

			if not eat_effects_cooldown[player] then
				eat_effects_cooldown[player] = 0
			end

			if not mcl_hunger.eat_internal[player_name].pitch then
				mcl_hunger.eat_internal[player_name].pitch = 1 + math.random(-10, 10)*0.005
			end

			-- check if holding RMB (or LMB as workaround for touchscreen)
			if (current_itemstack == mcl_hunger.eat_internal[player_name].itemstack or current_itemstack == mcl_hunger.eat_internal[player_name]._custom_itemstack) and (control.RMB or control.LMB) then
				eat_tick_timers[player] = eat_tick_timers[player] + dtime
				eat_effects_cooldown[player] = eat_effects_cooldown[player] + dtime

				playerphysics.add_physics_factor(player, "speed", "mcl_hunger:eating_speed", mcl_hunger.EATING_WALK_SPEED)

				if eat_effects_cooldown[player] > 0.2 then
					eat_effects_cooldown[player] = 0

					if not mcl_hunger.eat_internal[player_name].user then
						mcl_hunger.eat_internal[player_name].user = player
					end
	
					if not mcl_hunger.eat_internal[player_name].itemname then
						mcl_hunger.eat_internal[player_name].itemname = current_itemstack:get_name()
					end

					if not mcl_hunger.eat_internal[player_name].hp_change then
						mcl_hunger.eat_internal[player_name].hp_change = 0
					end

					local pos = player:get_pos()
					local itemname = mcl_hunger.eat_internal[player_name].itemname
					local def = minetest.registered_items[itemname]

					mcl_hunger.eat_effects(
						mcl_hunger.eat_internal[player_name].user,
						mcl_hunger.eat_internal[player_name].itemname,
						pos,
						mcl_hunger.eat_internal[player_name].hp_change,
						def,
						mcl_hunger.eat_internal[player_name].pitch
					)
				end

				-- check if eating delay is over
				if eat_tick_timers[player] >= mcl_hunger.EATING_DELAY then

					if not mcl_hunger.eat_internal[player_name]._custom_do_delayed then
						mcl_hunger.eat_internal[player_name].do_item_eat = true

						minetest.do_item_eat(
							mcl_hunger.eat_internal[player_name].hp_change,
							mcl_hunger.eat_internal[player_name].replace_with_item,
							mcl_hunger.eat_internal[player_name].itemstack,
							mcl_hunger.eat_internal[player_name].user,
							mcl_hunger.eat_internal[player_name].pointed_thing
						)

					-- bypass minetest.do_item_eat and only execute _custom_wrapper
					elseif mcl_hunger.eat_internal[player_name]._custom_itemstack and
						mcl_hunger.eat_internal[player_name]._custom_wrapper and
						mcl_hunger.eat_internal[player_name]._custom_itemstack == current_itemstack then

						mcl_hunger.eat_internal[player_name]._custom_wrapper(player_name)

						player:get_inventory():set_stack("main", player:get_wield_index(), itemstack)
					end

					clear_eat_internal_and_timers(player, player_name)
				end

			elseif eat_start_timers[player] and eat_start_timers[player] > 0.2 then
				playerphysics.remove_physics_factor(player, "speed", "mcl_hunger:eating_speed")
				mcl_hunger.eat_internal[player_name].is_eating_no_padding = false

			elseif eat_start_timers[player] and eat_start_timers[player] > mcl_hunger.EATING_TOUCHSCREEN_DELAY_PADDING then
				clear_eat_internal_and_timers(player, player_name)
			end
		end

		if eat_start_timers[player] and eat_start_timers[player] > mcl_hunger.EATING_DELAY + mcl_hunger.EATING_TOUCHSCREEN_DELAY_PADDING then
			clear_eat_internal_and_timers(player, player_name)
		end
	end
end)

--[[ IF HUNGER IS NOT ENABLED ]]
else

minetest.register_on_joinplayer(function(player)
	mcl_hunger.init_player(player)
	mcl_hunger.last_eat[player:get_player_name()] = -1
end)

end
