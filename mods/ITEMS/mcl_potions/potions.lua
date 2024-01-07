local S = minetest.get_translator(minetest.get_current_modname())

local function potion_image(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return "mcl_potions_potion_overlay.png^[colorize:"..colorstring..":"..tostring(opacity).."^mcl_potions_potion_bottle.png"
end

local how_to_drink = S("Use the “Place” key to drink it.")
local potion_intro = S("Drinking a potion gives you a particular effect or set of effects.")

local function time_string(dur)
	if not dur then
		return nil
	end
	return math.floor(dur/60)..string.format(":%02d",math.floor(dur % 60))
end
local function perc_string(num)

	local rem = math.floor((num-1.0)*100 + 0.1) % 5
	local out = math.floor((num-1.0)*100 + 0.1) - rem

	if (num - 1.0) < 0 then
		return out.."%"
	else
		return "+"..out.."%"
	end
end


-- ██████╗░███████╗░██████╗░██╗░██████╗████████╗███████╗██████╗░
-- ██╔══██╗██╔════╝██╔════╝░██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
-- ██████╔╝█████╗░░██║░░██╗░██║╚█████╗░░░░██║░░░█████╗░░██████╔╝
-- ██╔══██╗██╔══╝░░██║░░╚██╗██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗
-- ██║░░██║███████╗╚██████╔╝██║██████╔╝░░░██║░░░███████╗██║░░██║
-- ╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝
--
-- ██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
-- ██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
-- ██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
-- ██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
-- ██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
-- ╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░


function return_on_use(def, effect, dur)
	return function (itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			if user and not user:get_player_control().sneak then
				-- Use pointed node's on_rightclick function first, if present
				local node = minetest.get_node(pointed_thing.under)
				if user and not user:get_player_control().sneak then
					if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
						return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
					end
				end
			end
		elseif pointed_thing.type == "object" then
			return itemstack
		end

		--def.on_use(user, effect, dur) -- Will do effect immediately but not reduce item count until eating delay ends which makes it exploitable by deliberately not finishing delay

		-- Wrapper for handling mcl_hunger delayed eating
		local name = user:get_player_name()
		mcl_hunger.eat_internal[name]._custom_itemstack = itemstack -- Used as comparison to make sure the custom wrapper executes only when the same item is eaten
		mcl_hunger.eat_internal[name]._custom_var = {
			user = user,
			effect = effect,
			dur = dur,
		}
		mcl_hunger.eat_internal[name]._custom_func = def.on_use
		mcl_hunger.eat_internal[name]._custom_wrapper = function(name)

			mcl_hunger.eat_internal[name]._custom_func(
				mcl_hunger.eat_internal[name]._custom_var.user,
				mcl_hunger.eat_internal[name]._custom_var.effect,
				mcl_hunger.eat_internal[name]._custom_var.dur
			)
		end

		local old_name, old_count = itemstack:get_name(), itemstack:get_count()
		itemstack = minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
		if old_name ~= itemstack:get_name() or old_count ~= itemstack:get_count() then
			mcl_potions._use_potion(itemstack, user, def.color)
		end
		return itemstack
	end
end

local function generate_on_use(effects, color, on_use, custom_effect)
	return function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			if user and not user:get_player_control().sneak then
				local node = minetest.get_node(pointed_thing.under)
				if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
					return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
				end
			end
		elseif pointed_thing.type == "object" then
			return itemstack
		end

		local potency = itemstack:get_meta():get_int("mcl_potions:potion_potent")
		local plus = itemstack:get_meta():get_int("mcl_potions:potion_plus")
		local ef_level
		local dur
		for name, details in pairs(effects) do
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
			mcl_potions.give_effect_by_level(name, user, ef_level, dur)
		end

		if on_use then on_use(user, potency+1) end
		if custom_effect then custom_effect(user, potency+1) end

		itemstack = minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
		if itemstack then mcl_potions._use_potion(user, color) end

		return itemstack
	end
end

-- API - registers a potion
-- required parameters in def:
-- name - string - potion name in code
-- optional parameters in def:
-- desc_prefix - translated string - part of visible potion name, comes before the word "Potion"
-- desc_suffix - translated string - part of visible potion name, comes after the word "Potion"
-- _tt - translated string - custom tooltip text
-- _dynamic_tt - function(level) - returns custom tooltip text dependent on potion level
-- _longdesc - translated string - text for in-game documentation
-- stack_max - int - max stack size - defaults to 1
-- image - string - name of a custom texture of the potion icon
-- color - string - colorstring for potion icon when image is not defined - defaults to #0000FF
-- groups - table - item groups definition for the regular potion, not splash or lingering -
--   - must contain _mcl_potion=1 for tooltip to include dynamic_tt and effects
--   - defaults to {brewitem=1, food=3, can_eat_when_full=1, _mcl_potion=1}
-- _effect_list - table - all the effects dealt by the potion in the format of tables
-- -- the name of each sub-table should be a name of a registered effect, and fields can be the following:
-- -- -- uses_level - bool - whether the level of the potion affects the level of the effect -
-- -- --   - defaults to the uses_factor field of the effect definition
-- -- -- level - int - used as the effect level if uses_level is false and for lvl1 potions - defaults to 1
-- -- -- level_scaling - int - used as the number of effect levels added per potion level - defaults to 1 -
-- -- --   - this has no effect if uses_level is false
-- -- -- dur - float - duration of the effect in seconds - defaults to mcl_potions.DURATION
-- -- -- dur_variable - bool - whether variants of the potion should have the length of this effect changed -
-- -- --   - defaults to true
-- -- --   - if at least one effect has this set to true, the potion has a "plus" variant
-- uses_level - bool - whether the potion should come at different levels -
--   - defaults to true if uses_level is true for at least one effect, else false
-- drinkable - bool - defaults to true
-- has_splash - bool - defaults to true
-- has_lingering - bool - defaults to true
-- has_arrow - bool - defaults to false
-- has_potent - bool - whether there is a potent (e.g. II) variant - defaults to the value of uses_level
-- default_potent_level - int - potion level used for the default potent variant - defaults to 2
-- default_extend_level - int - extention level (amount of +) used for the default extended variant - defaults to 1
-- custom_on_use - function(user, level) - called when the potion is drunk, returns true on success
-- custom_effect - function(object, level) - called when the potion effects are applied, returns true on success
-- custom_splash_effect - function(pos, level) - called when the splash potion explodes, returns true on success
-- custom_linger_effect - function(pos, radius, level) - called on the lingering potion step, returns true on success
function mcl_potions.register_potion(def)
	local modname = minetest.get_current_modname()
	local name = def.name
	if name == nil then
		error("Unable to register potion: name is nil")
	end
	if type(name) ~= "string" then
		error("Unable to register potion: name is not a string")
	end
	local pdef = {}
	if def.desc_prefix and def.desc_suffix then
		pdef.description = S("@1 Potion @2", def.desc_prefix, def.desc_suffix)
	elseif def.desc_prefix then
		pdef.description = S("@1 Potion", def.desc_prefix)
	elseif def.desc_suffix then
		pdef.description = S("Potion @1", def.desc_suffix)
	else
		pdef.description = S("Strange Potion")
	end
	pdef._tt_help = def._tt
	pdef._dynamic_tt = def._dynamic_tt
	local potion_longdesc = def._longdesc
	if def._effect_list then
		potion_longdesc = potion_intro .. "\n" .. def._longdesc
	end
	pdef._doc_items_longdesc = potion_longdesc
	if def.drinkable ~= false then pdef._doc_items_usagehelp = how_to_drink end
	pdef.stack_max = def.stack_max or 1
	local color = def.color or "#0000FF"
	pdef.inventory_image = def.image or potion_image(color)
	pdef.wield_image = pdef.inventory_image
	pdef.groups = def.groups or {brewitem=1, food=3, can_eat_when_full=1, _mcl_potion=1}

	pdef._effect_list = {}
	local effect
	local uses_level = false
	local has_plus = false
	if def._effect_list then
		for name, details in pairs(def._effect_list) do
			no_effects = false
			effect = mcl_potions.registered_effects[name]
			if effect then
				local ulvl
				if details.uses_level ~= nil then ulvl = details.uses_level
				else ulvl = effect.uses_factor end
				if ulvl then uses_level = true end
				local durvar = true
				if details.dur_variable ~= nil then durvar = details.dur_variable end
				if durvar then has_plus = true end
				pdef._effect_list[name] = {
					uses_level = ulvl,
					level = details.level or 1,
					level_scaling = details.level_scaling or 1,
					dur = details.dur or mcl_potions.DURATION,
					dur_variable = durvar,
				}
			else
				error("Unable to register potion: effect not registered")
			end
		end
	end
	if def.uses_level ~= nil then uses_level = def.uses_level end
	pdef.uses_level = uses_level
	if def.has_potent ~= nil then pdef.has_potent = def.has_potent
	else pdef.has_potent = uses_level end
	pdef._default_potent_level = def.default_potent_level or 2
	pdef._default_extend_level = def.default_extend_level or 1
	pdef.has_plus = has_plus
	local on_use
	if def.drinkable ~= false then
		on_use = generate_on_use(pdef._effect_list, color, def.custom_on_use, def.custom_effect)
	end
	pdef.on_place = on_use
	pdef.on_secondary_use = on_use

	minetest.register_craftitem(modname..":"..name, pdef)

	if def.has_splash or def.has_splash == nil then
		local splash_desc = S("Splash @1", pdef.description)
		local sdef = {}
		sdef._tt = def._tt
		sdef._dynamic_tt = def._dynamic_tt
		sdef._longdesc = def._longdesc
		sdef.stack_max = pdef.stack_max
		sdef._effect_list = pdef._effect_list
		sdef.uses_level = uses_level
		sdef.has_potent = pdef.has_potent
		sdef.has_plus = has_plus
		sdef._default_potent_level = pdef._default_potent_level
		sdef._default_extend_level = pdef._default_extend_level
		sdef.custom_effect = def.custom_effect
		sdef.on_splash = def.custom_splash_effect
		if not def._effect_list then sdef.instant = true end
		mcl_potions.register_splash(name, splash_desc, color, sdef)
	end

	if def.has_lingering or def.has_lingering == nil then
		local ling_desc = S("Lingering @1", pdef.description)
		local ldef = {}
		ldef._tt = def._tt
		ldef._longdesc = def._longdesc
		ldef.stack_max = pdef.stack_max
		ldef._effect_list = pdef._effect_list
		ldef.uses_level = uses_level
		ldef.has_potent = pdef.has_potent
		ldef.has_plus = has_plus
		ldef._default_potent_level = pdef._default_potent_level
		ldef._default_extend_level = pdef._default_extend_level
		ldef.custom_effect = def.custom_effect
		ldef.on_splash = def.custom_splash_effect
		ldef.while_lingering = def.custom_linger_effect
		if not def._effect_list then ldef.instant = true end
		mcl_potions.register_lingering(name, ling_desc, color, ldef)
	end

	if def.has_arrow then
		local arr_desc
		if def.desc_prefix and def.desc_suffix then
			arr_desc = S("@1 Arrow @2", def.desc_prefix, def.desc_suffix)
		elseif def.desc_prefix then
			arr_desc = S("@1 Arrow", def.desc_prefix)
		elseif def.desc_suffix then
			arr_desc = S("Arrow @1", def.desc_suffix)
		else
			arr_desc = S("Strange Tipped Arrow")
		end
		local adef = {}
		adef._tt = def._tt
		adef._longdesc = def._longdesc
		adef._effect_list = pdef._effect_list
		adef.uses_level = uses_level
		adef.has_potent = pdef.has_potent
		adef.has_plus = has_plus
		adef._default_potent_level = pdef._default_potent_level
		adef._default_extend_level = pdef._default_extend_level
		adef.custom_effect = def.custom_effect
		if not def._effect_list then adef.instant = true end
		mcl_potions.register_arrow(name, arr_desc, color, adef)
	end
end

mcl_potions.register_potion({
	name = "trolling",
	desc_prefix = S("Mighty"),
	desc_suffix = S("of Trolling"),
	_tt = "trololo",
	_dynamic_tt = function(level)
		return "trolololoooololo"
	end,
	_longdesc = "Trolololololo",
	stack_max = 2,
	color = "#00AA00",
	_effect_list = {
		night_vision = {},
		strength = {},
		swiftness = {
			uses_level = false,
			level = 2,
		},
		poison = {
			dur = 10,
		},
	},
	default_potent_level = 5,
	default_extend_level = 3,
	custom_splash_effect = mcl_potions._extinguish_nearby_fire,
	has_arrow = true,
})


local function register_potion(def)

	local dur = mcl_potions.DURATION

	if def.is_inv then
		dur = dur * mcl_potions.INV_FACTOR
	end
	if def.name == "poison" or def.name == "regeneration" or def.name == "withering" then
		dur = 45
	end

	local on_use = nil

	if def.on_use then
		on_use = return_on_use(def, def.effect, dur)
	end

	local function get_tt(tt, effect, dur)
		local _tt
		if effect and def.is_dur then
			_tt = perc_string(effect).." | "..time_string(dur)
			if def.name == "poison" or def.name == "regeneration" or def.name == "withering" then
				_tt = S("1 HP/@1s | @2", effect, time_string(dur))
			end
		elseif def.name == "healing" or def.name == "harming" then
				_tt = S("@1 HP", effect)
		else
			_tt = tt or time_string(dur) or S("No effect")
		end
		return _tt
	end

	local function get_splash_fun(effect, sp_dur)
		if def.is_dur then
			return function(player, redx) def.on_use(player, effect, sp_dur*redx) end
		elseif def.effect then
			return function(player, redx) def.on_use(player, effect*redx, sp_dur) end
		end
		-- covers case of no effect (water, awkward, mundane)
		return function() end
	end

	local function get_lingering_fun(effect, ling_dur)
		if def.is_dur then
			return function(player) def.on_use(player, effect, ling_dur) end
		elseif def.effect then
			return function(player) def.on_use(player, effect*0.5, ling_dur) end
		end
		-- covers case of no effect (water, awkward, mundane)
		return function() end
	end

	local function get_arrow_fun(effect, dur)
		if def.is_dur then
			return function(player) def.on_use(player, effect, dur) end
		elseif def.effect then
			return function(player) def.on_use(player, effect, dur) end
		end
		-- covers case of no effect (water, awkward, mundane)
		return function() end
	end

	local desc
	if not def.no_potion then
		if def.description_potion then
			desc = def.description_potion
		else
			desc = S("@1 Potion", def.description)
		end
	else
		desc = def.description
	end
	local potion_longdesc = def._longdesc
	if not def.no_effect then
		potion_longdesc = potion_intro .. "\n" .. def._longdesc
	end
	local potion_usagehelp
	local basic_potion_tt
	if def.name ~= "dragon_breath" then
		potion_usagehelp = how_to_drink
		basic_potion_tt = get_tt(def._tt, def.effect, dur)
	end

	minetest.register_craftitem("mcl_potions:"..def.name, {
		description = desc,
		_tt_help = basic_potion_tt,
		_doc_items_longdesc = potion_longdesc,
		_doc_items_usagehelp = potion_usagehelp,
		stack_max = def.stack_max or 1,
		inventory_image = def.image or potion_image(def.color),
		wield_image = def.image or potion_image(def.color),
		groups = def.groups or {brewitem=1, food=3, can_eat_when_full=1, bottle=1},
		on_place = on_use,
		on_secondary_use = on_use,
	})

	-- Register Splash and Lingering
	local splash_dur = dur * mcl_potions.SPLASH_FACTOR
	local ling_dur = dur * mcl_potions.LINGERING_FACTOR

	local splash_def = {
		tt = get_tt(def._tt, def.effect, splash_dur),
		longdesc = def._longdesc,
		potion_fun = get_splash_fun(def.effect, splash_dur),
		no_effect = def.no_effect,
		instant = def.instant,
	}

	local ling_def
	if def.name == "healing" or def.name == "harming" then
		ling_def = {
			tt = get_tt(def._tt, def.effect*mcl_potions.LINGERING_FACTOR, ling_dur),
			longdesc = def._longdesc,
			potion_fun = get_lingering_fun(def.effect*mcl_potions.LINGERING_FACTOR, ling_dur),
			no_effect = def.no_effect,
			instant = def.instant,
		}
	else
		ling_def = {
			tt = get_tt(def._tt, def.effect, ling_dur),
			longdesc = def._longdesc,
			potion_fun = get_lingering_fun(def.effect, ling_dur),
			no_effect = def.no_effect,
			instant = def.instant,
		}
	end

	local arrow_def = {
		tt = get_tt(def._tt, def.effect, dur/8.),
		longdesc = def._longdesc,
		potion_fun = get_arrow_fun(def.effect, dur/8.),
		no_effect = def.no_effect,
		instant = def.instant,
	}

	if def.color and not def.no_throwable then
		local desc
		if def.description_splash then
			desc = def.description_splash
		else
			desc = S("Splash @1 Potion", def.description)
		end
		mcl_potions.register_splash(def.name, desc, def.color, splash_def)
		if def.description_lingering then
			desc = def.description_lingering
		else
			desc = S("Lingering @1 Potion", def.description)
		end
		mcl_potions.register_lingering(def.name, desc, def.color, ling_def)
		if not def.no_arrow then
			mcl_potions.register_arrow(def.name, S("Arrow of @1", def.description), def.color, arrow_def)
		end
	end

	if def.is_II then

		local desc_mod = S(" II")

		local effect_II
		if def.name == "healing" or def.name == "harming" then
			effect_II = def.effect*mcl_potions.II_FACTOR
		elseif def.name == "poison" or def.name == "regeneration" then
			effect_II = 1.2
		elseif def.name == "withering" then
			effect_II = 2
		else
			effect_II = def.effect^mcl_potions.II_FACTOR
		end

		local dur_2 = dur / mcl_potions.II_FACTOR
		if def.name == "poison" then dur_2 = dur_2 - 1 end

		if def.name == "slowness" then
			dur_2 = 20
			effect_II = 0.40
			desc_mod = S(" IV")
		end

		on_use = return_on_use(def, effect_II, dur_2)

		minetest.register_craftitem("mcl_potions:"..def.name.."_2", {
			description = S("@1 Potion@2", def.description, desc_mod),
			_tt_help = get_tt(def._tt_2, effect_II, dur_2),
			_doc_items_longdesc = potion_longdesc,
			_doc_items_usagehelp = potion_usagehelp,
			stack_max = def.stack_max or 1,
			inventory_image = def.image or potion_image(def.color),
			wield_image = def.image or potion_image(def.color),
			groups = def.groups or {brewitem=1, food=3, can_eat_when_full=1, bottle=1},
			on_place = on_use,
			on_secondary_use = on_use,
		})

		-- Register Splash and Lingering
		local splash_dur_2 = dur_2 * mcl_potions.SPLASH_FACTOR
		local ling_dur_2 = dur_2 * mcl_potions.LINGERING_FACTOR

		local splash_def_2
		if def.name == "healing" then
			splash_def_2 = {
				tt = get_tt(def._tt_2, 7, splash_dur_2),
				longdesc = def._longdesc,
				potion_fun = get_splash_fun(7, splash_dur_2),
				no_effect = def.no_effect,
				instant = def.instant,
			}
		else
			splash_def_2 = {
				tt = get_tt(def._tt_2, effect_II, splash_dur_2),
				longdesc = def._longdesc,
				potion_fun = get_splash_fun(effect_II, splash_dur_2),
				no_effect = def.no_effect,
				instant = def.instant,
			}
		end


		local ling_def_2
		if def.name == "healing" or def.name == "harming" then
			ling_def_2 = {
				tt = get_tt(def._tt_2, effect_II*mcl_potions.LINGERING_FACTOR, ling_dur_2),
				longdesc = def._longdesc,
				potion_fun = get_lingering_fun(effect_II*mcl_potions.LINGERING_FACTOR, ling_dur_2),
				no_effect = def.no_effect,
				instant = def.instant,
			}
		else
			ling_def_2 = {
				tt = get_tt(def._tt_2, effect_II, ling_dur_2),
				longdesc = def._longdesc,
				potion_fun = get_lingering_fun(effect_II, ling_dur_2),
				no_effect = def.no_effect,
				instant = def.instant,
			}
		end

		local arrow_def_2 = {
			tt = get_tt(def._tt_2, effect_II, dur_2/8.),
			longdesc = def._longdesc,
			potion_fun = get_arrow_fun(effect_II, dur_2/8.),
			no_effect = def.no_effect,
			instant = def.instant,
		}

		if def.color and not def.no_throwable then
			mcl_potions.register_splash(def.name.."_2", S("Splash @1@2 Potion", def.description, desc_mod), def.color, splash_def_2)
			mcl_potions.register_lingering(def.name.."_2", S("Lingering @1@2 Potion", def.description, desc_mod), def.color, ling_def_2)
			if not def.no_arrow then
				mcl_potions.register_arrow(def.name.."_2", S("Arrow of @1@2", def.description, desc_mod), def.color, arrow_def_2)
			end
		end

	end

	if def.is_plus then

		local dur_pl = dur * mcl_potions.PLUS_FACTOR
		if def.name == "poison" or def.name == "regeneration" or def.name == "withering" then
			dur_pl = 90
		end

		on_use = return_on_use(def, def.effect, dur_pl)

		minetest.register_craftitem("mcl_potions:"..def.name.."_plus", {
			description = S("@1 + Potion", def.description),
			_tt_help = get_tt(def._tt_plus, def.effect, dur_pl),
			_doc_items_longdesc = potion_longdesc,
			_doc_items_usagehelp = potion_usagehelp,
			stack_max = 1,
			inventory_image = def.image or potion_image(def.color),
			wield_image = def.image or potion_image(def.color),
			groups = def.groups or {brewitem=1, food=3, can_eat_when_full=1, bottle=1},
			on_place = on_use,
			on_secondary_use = on_use,
		})

		-- Register Splash
		local splash_dur_pl = dur_pl * mcl_potions.SPLASH_FACTOR
		local ling_dur_pl = dur_pl * mcl_potions.LINGERING_FACTOR

		local splash_def_pl = {
			tt = get_tt(def._tt_plus, def.effect, splash_dur_pl),
			longdesc = def._longdesc,
			potion_fun = get_splash_fun(def.effect, splash_dur_pl),
			no_effect = def.no_effect,
			instant = def.instant,
		}
		local ling_def_pl = {
			tt = get_tt(def._tt_plus, def.effect, ling_dur_pl),
			longdesc = def._longdesc,
			potion_fun = get_lingering_fun(def.effect, ling_dur_pl),
			no_effect = def.no_effect,
			instant = def.instant,
		}
		local arrow_def_pl = {
			tt = get_tt(def._tt_pl, def.effect, dur_pl/8.),
			longdesc = def._longdesc,
			potion_fun = get_arrow_fun(def.effect, dur_pl/8.),
			no_effect = def.no_effect,
			instant = def.instant,
		}
		if def.color and not def.no_throwable then
			mcl_potions.register_splash(def.name.."_plus", S("Splash @1 + Potion", def.description), def.color, splash_def_pl)
			mcl_potions.register_lingering(def.name.."_plus", S("Lingering @1 + Potion", def.description), def.color, ling_def_pl)
			if not def.no_arrow then
				mcl_potions.register_arrow(def.name.."_plus", S("Arrow of @1 +", def.description), def.color, arrow_def_pl)
			end
		end

	end

end


-- ██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
-- ██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
-- ██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
-- ██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
-- ██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
-- ╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
--
-- ██████╗░███████╗███████╗██╗███╗░░██╗██╗████████╗██╗░█████╗░███╗░░██╗░██████╗
-- ██╔══██╗██╔════╝██╔════╝██║████╗░██║██║╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
-- ██║░░██║█████╗░░█████╗░░██║██╔██╗██║██║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
-- ██║░░██║██╔══╝░░██╔══╝░░██║██║╚████║██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
-- ██████╔╝███████╗██║░░░░░██║██║░╚███║██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
-- ╚═════╝░╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░


local awkward_def = {
	name = "awkward",
	description_potion = S("Awkward Potion"),
	description_splash = S("Awkward Splash Potion"),
	description_lingering = S("Awkward Lingering Potion"),
	no_arrow = true,
	no_effect = true,
	_tt = S("No effect"),
	_longdesc = S("Has an awkward taste and is used for brewing potions."),
	color = "#0000FF",
	groups = {brewitem=1, food=3, can_eat_when_full=1, bottle=1},
	on_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
}

local mundane_def = {
	name = "mundane",
	description_potion = S("Mundane Potion"),
	description_splash = S("Mundane Splash Potion"),
	description_lingering = S("Mundane Lingering Potion"),
	no_arrow = true,
	no_effect = true,
	_tt = S("No effect"),
	_longdesc = S("Has a terrible taste and is not useful for brewing potions."),
	color = "#0000FF",
	on_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
}

local thick_def = {
	name = "thick",
	description_potion = S("Thick Potion"),
	description_splash = S("Thick Splash Potion"),
	description_lingering = S("Thick Lingering Potion"),
	no_arrow = true,
	no_effect = true,
	_tt = S("No effect"),
	_longdesc = S("Has a bitter taste and is not useful for brewing potions."),
	color = "#0000FF",
	on_use = minetest.item_eat(0, "mcl_potions:glass_bottle"),
}

local dragon_breath_def = {
	name = "dragon_breath",
	description = S("Dragon's Breath"),
	no_arrow = true,
	no_potion = true,
	no_throwable = true,
	no_effect = true,
	_longdesc = S("This item is used in brewing and can be combined with splash potions to create lingering potions."),
	image = "mcl_potions_dragon_breath.png",
	groups = { brewitem = 1, bottle = 1 },
	on_use = nil,
	stack_max = 64,
}

local healing_def = {
	name = "healing",
	description = S("Healing"),
	_tt = S("+4 HP"),
	_tt_2 = S("+8 HP"),
	_longdesc = S("Instantly heals."),
	color = "#F82423",
	effect = 4,
	instant = true,
	on_use = mcl_potions.healing_func,
	is_II = true,
}


local harming_def = {
	name = "harming",
	description = S("Harming"),
	_tt = S("-6 HP"),
	_tt_II = S("-12 HP"),
	_longdesc = S("Instantly deals damage."),
	color = "#430A09",
	effect = -6,
	instant = true,
	on_use = mcl_potions.healing_func,
	is_II = true,
	is_inv = true,
}

local night_vision_def = {
	name = "night_vision",
	description = S("Night Vision"),
	_tt = nil,
	_longdesc = S("Increases the perceived brightness of light under a dark sky."),
	color = "#1F1FA1",
	effect = nil,
	is_dur = true,
	on_use = mcl_potions.night_vision_func,
	is_plus = true,
}

local swiftness_def = {
	name = "swiftness",
	description = S("Swiftness"),
	_tt = nil,
	_longdesc = S("Increases walking speed."),
	color = "#7CAFC6",
	effect = 1.2,
	is_dur = true,
	on_use = mcl_potions.swiftness_func,
	is_II = true,
	is_plus = true,
}

local slowness_def = {
	name = "slowness",
	description = S("Slowness"),
	_tt = nil,
	_longdesc = S("Decreases walking speed."),
	color = "#5A6C81",
	effect = 0.85,
	is_dur = true,
	on_use = mcl_potions.slowness_func,
	is_II = true,
	is_plus = true,
	is_inv = true,
}

local leaping_def = {
	name = "leaping",
	description = S("Leaping"),
	_tt = nil,
	_longdesc = S("Increases jump strength."),
	color = "#22FF4C",
	effect = 1.15,
	is_dur = true,
	on_use = mcl_potions.leaping_func,
	is_II = true,
	is_plus = true,
}

local withering_def = {
	name = "withering",
	description = S("Withering"),
	_tt = nil,
	_longdesc = S("Applies the withering effect which deals damage at a regular interval and can kill."),
	color = "#000000",
	effect = 4,
	is_dur = true,
	on_use = mcl_potions.withering_func,
	is_II = true,
	is_plus = true,
	is_inv = true,
}

local poison_def = {
	name = "poison",
	description = S("Poison"),
	_tt = nil,
	_longdesc = S("Applies the poison effect which deals damage at a regular interval."),
	color = "#4E9331",
	effect = 2.5,
	is_dur = true,
	on_use = mcl_potions.poison_func,
	is_II = true,
	is_plus = true,
	is_inv = true,
}

local regeneration_def = {
	name = "regeneration",
	description = S("Regeneration"),
	_tt = nil,
	_longdesc = S("Regenerates health over time."),
	color = "#CD5CAB",
	effect = 2.5,
	is_dur = true,
	on_use = mcl_potions.regeneration_func,
	is_II = true,
	is_plus = true,
}

local invisibility_def = {
	name = "invisibility",
	description = S("Invisibility"),
	_tt = nil,
	_longdesc = S("Grants invisibility."),
	color = "#7F8392",
	is_dur = true,
	on_use = mcl_potions.invisiblility_func,
	is_plus = true,
}

local water_breathing_def = {
	name = "water_breathing",
	description = S("Water Breathing"),
	_tt = nil,
	_longdesc = S("Grants limitless breath underwater."),
	color = "#2E5299",
	is_dur = true,
	on_use = mcl_potions.water_breathing_func,
	is_plus = true,
}

local fire_resistance_def = {
	name = "fire_resistance",
	description = S("Fire Resistance"),
	_tt = nil,
	_longdesc = S("Grants immunity to damage from heat sources like fire."),
	color = "#E49A3A",
	is_dur = true,
	on_use = mcl_potions.fire_resistance_func,
	is_plus = true,
}



local defs = { awkward_def, mundane_def, thick_def, dragon_breath_def,
	healing_def, harming_def, night_vision_def, swiftness_def,
	slowness_def, leaping_def, withering_def, poison_def, regeneration_def,
	invisibility_def, water_breathing_def, fire_resistance_def}

-- for _, def in ipairs(defs) do
-- 	register_potion(def)
-- end




-- minetest.register_craftitem("mcl_potions:weakness", {
-- 	description = S("Weakness"),
-- 	_tt_help = TODO,
-- 	_doc_items_longdesc = brewhelp,
-- 	wield_image = potion_image("#484D48"),
-- 	inventory_image = potion_image("#484D48"),
-- 	groups = { brewitem=1, food=3, can_eat_when_full=1 },
-- 	stack_max = 1,
--
-- 	on_place = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, -4, mcl_potions.DURATION*mcl_potions.INV_FACTOR)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#484D48")
-- 		return itemstack
-- 	end,
--
-- 	on_secondary_use = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, -4, mcl_potions.DURATION*mcl_potions.INV_FACTOR)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#484D48")
-- 		return itemstack
-- 	end
-- })
--
-- minetest.register_craftitem("mcl_potions:weakness_plus", {
-- 	description = S("Weakness +"),
-- 	_tt_help = TODO,
-- 	_doc_items_longdesc = brewhelp,
-- 	wield_image = potion_image("#484D48"),
-- 	inventory_image = potion_image("#484D48"),
-- 	groups = { brewitem=1, food=3, can_eat_when_full=1 },
-- 	stack_max = 1,
--
-- 	on_place = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, -4, mcl_potions.DURATION_2*mcl_potions.INV_FACTOR)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#484D48")
-- 		return itemstack
-- 	end,
--
-- 	on_secondary_use = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, -4, mcl_potions.DURATION_2*mcl_potions.INV_FACTOR)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#484D48")
-- 		return itemstack
-- 	end
-- })
--
-- minetest.register_craftitem("mcl_potions:strength", {
-- 	description = S("Strength"),
-- 	_tt_help = TODO,
-- 	_doc_items_longdesc = brewhelp,
-- 	wield_image = potion_image("#932423"),
-- 	inventory_image = potion_image("#932423"),
-- 	groups = { brewitem=1, food=3, can_eat_when_full=1 },
-- 	stack_max = 1,
--
-- 	on_place = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 3, mcl_potions.DURATION)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end,
--
-- 	on_secondary_use = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 3, mcl_potions.DURATION)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end
-- })
--
-- minetest.register_craftitem("mcl_potions:strength_2", {
-- 	description = S("Strength II"),
-- 	_tt_help = TODO,
-- 	_doc_items_longdesc = brewhelp,
-- 	wield_image = potion_image("#932423"),
-- 	inventory_image = potion_image("#932423"),
-- 	groups = { brewitem=1, food=3, can_eat_when_full=1 },
-- 	stack_max = 1,
--
-- 	on_place = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 6, mcl_potions.DURATION_2)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end,
--
-- 	on_secondary_use = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 6, mcl_potions.DURATION_2)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end
-- })
--
-- minetest.register_craftitem("mcl_potions:strength_plus", {
-- 	description = S("Strength +"),
-- 	_tt_help = TODO,
-- 	_doc_items_longdesc = brewhelp,
-- 	wield_image = potion_image("#932423"),
-- 	inventory_image = potion_image("#932423"),
-- 	groups = { brewitem=1, food=3, can_eat_when_full=1 },
-- 	stack_max = 1,
--
-- 	on_place = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 3, mcl_potions.DURATION_PLUS)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end,
--
-- 	on_secondary_use = function(itemstack, user, pointed_thing)
-- 		mcl_potions.weakness_func(user, 3, mcl_potions.DURATION_PLUS)
-- 		minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, user, pointed_thing)
-- 		mcl_potions._use_potion(itemstack, user, "#932423")
-- 		return itemstack
-- 	end
-- })
