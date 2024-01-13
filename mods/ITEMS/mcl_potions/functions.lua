local S = minetest.get_translator(minetest.get_current_modname())

local EF = {}
mcl_potions.registered_effects = {}
local registered_effects = mcl_potions.registered_effects -- shorthand ref

local EFFECT_TYPES = 0
minetest.register_on_mods_loaded(function()
	for _,_ in pairs(EF) do
		EFFECT_TYPES = EFFECT_TYPES + 1
	end
end)

-- ██████╗░███████╗░██████╗░██╗░██████╗████████╗███████╗██████╗
-- ██╔══██╗██╔════╝██╔════╝░██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
-- ██████╔╝█████╗░░██║░░██╗░██║╚█████╗░░░░██║░░░█████╗░░██████╔╝
-- ██╔══██╗██╔══╝░░██║░░╚██╗██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗
-- ██║░░██║███████╗╚██████╔╝██║██████╔╝░░░██║░░░███████╗██║░░██║
-- ╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝
--
-- ███████╗███████╗███████╗███████╗░█████╗░████████╗░██████╗
-- ██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝
-- █████╗░░█████╗░░█████╗░░█████╗░░██║░░╚═╝░░░██║░░░╚█████╗░
-- ██╔══╝░░██╔══╝░░██╔══╝░░██╔══╝░░██║░░██╗░░░██║░░░░╚═══██╗
-- ███████╗██║░░░░░██║░░░░░███████╗╚█████╔╝░░░██║░░░██████╔╝
-- ╚══════╝╚═╝░░░░░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░╚═════╝░

local function generate_linear_lvl_to_fac(l1, l2)
	local a = l2 - l1
	local b = 2*l1 - l2
	return function(level)
		return (a*level + b)
	end
end

local function generate_linear_fac_to_lvl(l1, l2)
	local a = 1/(l2 - l1)
	local b = -(2*l1 - l2) * a
	return function(factor)
		return math.round(a*factor + b)
	end
end

local function generate_rational_lvl_to_fac(l1, l2)
	local a = (l1 - l2) * 2
	local b = 2*l2 - l1
	return function(level)
		if level == 0 then return 0 end
		return (a/level + b)
	end
end

local function generate_rational_fac_to_lvl(l1, l2)
	local a = (l1 - l2) * 2
	local b = 2*l2 - l1
	return function(factor)
		if factor == 0 then return math.huge end
		return math.round(a/(factor - b))
	end
end

local function generate_modifier_func(name, dmg_flag, mod_func)
	if dmg_flag ~= "" then return function(object, damage, reason)
		if EF[name][object] and not reason.flags.bypasses_magic and reason.flags[dmg_flag] then
			return mod_func and mod_func(damage, EF[name][object]) or 0
		end
	end
	else return function(object, damage, reason)
		if EF[name][object] and not reason.flags.bypasses_magic then
			return mod_func and mod_func(damage, EF[name][object]) or 0
		end
	end end
end

-- API - registers an effect
-- required parameters in def:
-- name - string - effect name in code
-- description - translated string - actual effect name in game
-- optional parameters in def:
-- get_tt - function(factor) - returns tooltip description text for use with potions
-- icon - string - file name of the effect icon in HUD - defaults to one based on name
-- res_condition - function(object) - returning true if target is to be resistant to the effect
-- on_start - function(object, factor) - called when dealing the effect
-- on_load - function(object, factor) - called on_joinplayer and on_activate
-- on_step - function(dtime, object, factor, duration) - running every step for all objects with this effect
-- on_hit_timer - function(object, factor, duration) - if defined runs a hit_timer depending on timer_uses_factor value
-- on_end - function(object) - called when the effect wears off
-- particle_color - string - colorstring for particles - defaults to #3000EE
-- uses_factor - bool - whether factor affects the effect
-- lvl1_factor - integer - factor for lvl1 effect - defaults to 1 if uses_factor
-- lvl2_factor - integer - factor for lvl2 effect - defaults to 2 if uses_factor
-- timer_uses_factor - bool - whether hit_timer uses factor (uses_factor must be true) or a constant value (hit_timer_step must be defined)
-- hit_timer_step - float - interval between hit_timer hits
-- damage_modifier - string - damage flag of which damage is changed as defined by modifier_func, pass empty string for all damage
-- modifier_func - function(damage, effect_vals) - see damage_modifier, if not defined damage_modifier defaults to 100% resistance
-- modifier_priority - integer - priority passed when registering damage_modifier - defaults to -50
function mcl_potions.register_effect(def)
	local modname = minetest.get_current_modname()
	local name = def.name
	if name == nil then
		error("Unable to register effect: name is nil")
	end
	if type(name) ~= "string" then
		error("Unable to register effect: name is not a string")
	end
	if name == "list" then
		error("Unable to register effect: list is a reserved word")
	end
	if name == "heal" then
		error("Unable to register effect: heal is a reserved word")
	end
	if registered_effects[name] then
		error("Effect named "..name.." already registered!")
	end
	if not def.description or type(def.description) ~= "string" then
		error("Unable to register effect: description is not a string")
	end
	local pdef = {}
	pdef.description = def.description
	if not def.icon then
		pdef.icon = modname.."_effect_"..name..".png"
	else
		pdef.icon = def.icon
	end
	pdef.get_tt = def.get_tt
	pdef.res_condition = def.res_condition
	pdef.on_start = def.on_start
	pdef.on_load = def.on_load
	pdef.on_step = def.on_step
	pdef.on_hit_timer = def.on_hit_timer
	pdef.on_end = def.on_end
	if not def.particle_color then
		pdef.particle_color = "#3000EE"
	else
		pdef.particle_color = def.particle_color
	end
	if def.uses_factor then
		pdef.uses_factor = true
		local l1 = def.lvl1_factor or 1
		local l2 = def.lvl2_factor or 2*l1
		if l1 < l2 then
			pdef.level_to_factor = generate_linear_lvl_to_fac(l1, l2)
			pdef.factor_to_level = generate_linear_fac_to_lvl(l1, l2)
			pdef.inv_factor = false
		elseif l1 > l2 then
			pdef.level_to_factor = generate_rational_lvl_to_fac(l1, l2)
			pdef.factor_to_level = generate_rational_fac_to_lvl(l1, l2)
			pdef.inv_factor = true
		else
			error("Can't extrapolate levels from lvl1 and lvl2 bearing the same factor")
		end
	else
		pdef.uses_factor = false
	end
	if def.on_hit_timer then
		if def.timer_uses_factor then
			if not def.uses_factor then error("Uses factor but does not use factor?") end
			pdef.timer_uses_factor = true
		else
			if not def.hit_timer_step then error("If hit_timer does not use factor, hit_timer_step must be defined") end
			pdef.timer_uses_factor = false
			pdef.hit_timer_step = def.hit_timer_step
		end
	end
	if def.damage_modifier then
		mcl_damage.register_modifier(
			generate_modifier_func(name, def.damage_modifier, def.modifier_func),
			def.modifier_priority or -50
		)
	end
	registered_effects[name] = pdef
	EF[name] = {}
end

mcl_potions.register_effect({
	name = "invisibility",
	description = S("Invisiblity"),
	get_tt = function(factor)
		return S("body is invisible")
	end,
	on_start = function(object, factor)
		mcl_potions.make_invisible(object, true)
	end,
	on_load = function(object, factor)
		mcl_potions.make_invisible(object, true)
	end,
	on_end = function(object)
		mcl_potions.make_invisible(object, false)
	end,
	particle_color = "#7F8392",
	uses_factor = false,
})

mcl_potions.register_effect({
	name = "poison",
	description = S("Poison"),
	get_tt = function(factor)
		return S("-1 HP / @1 s", factor)
	end,
	res_condition = function(object)
		local entity = object:get_luaentity()
		return (entity and (entity.harmed_by_heal or string.find(entity.name, "spider")))
	end,
	on_hit_timer = function(object, factor, duration)
		if mcl_util.get_hp(object) - 1 > 0 then
			mcl_util.deal_damage(object, 1, {type = "magic"})
		end
	end,
	particle_color = "#4E9331",
	uses_factor = true,
	lvl1_factor = 1.25,
	lvl2_factor = 0.6,
	timer_uses_factor = true,
})

mcl_potions.register_effect({
	name = "regeneration",
	description = S("Regeneration"),
	get_tt = function(factor)
		return S("+1 HP / @1 s", factor)
	end,
	res_condition = function(object)
		local entity = object:get_luaentity()
		return (entity and entity.harmed_by_heal)
	end,
	on_hit_timer = function(object, factor, duration)
		local entity = object:get_luaentity()
		if object:is_player() then
			object:set_hp(math.min(object:get_properties().hp_max or 20, object:get_hp() + 1), { type = "set_hp", other = "regeneration" })
		elseif entity and entity.is_mob then
			entity.health = math.min(entity.hp_max, entity.health + 1)
		end
	end,
	particle_color = "#CD5CAB",
	uses_factor = true,
	lvl1_factor = 2.5,
	lvl2_factor = 1.25,
	timer_uses_factor = true,
})

mcl_potions.register_effect({
	name = "strength",
	description = S("Strength"),
	res_condition = function(object)
		return (not object:is_player())
	end,
	particle_color = "#932423",
})

mcl_potions.register_effect({
	name = "weakness",
	description = S("Weakness"),
	res_condition = function(object)
		return (not object:is_player())
	end,
	particle_color = "#484D48",
})

mcl_potions.register_effect({
	name = "water_breathing",
	description = S("Water Breathing"),
	get_tt = function(factor)
		return S("limitless breathing under water")
	end,
	on_step = function(dtime, object, factor, duration)
		if not object:is_player() then return end
		if object:get_breath() then
			hb.hide_hudbar(object, "breath")
			if object:get_breath() < 10 then object:set_breath(10) end
		end
	end,
	particle_color = "#2E5299",
	uses_factor = false,
})

mcl_potions.register_effect({
	name = "leaping",
	description = S("Leaping"),
	get_tt = function(factor)
		if factor > 0 then return S("+@1% jumping power", math.floor(factor*100)) end
		return S("-@1% jumping power", math.floor(-factor*100))
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	on_start = function(object, factor)
		playerphysics.add_physics_factor(object, "jump", "mcl_potions:leaping", 1+factor)
	end,
	on_end = function(object)
		playerphysics.remove_physics_factor(object, "jump", "mcl_potions:leaping")
	end,
	particle_color = "#22FF4C",
	uses_factor = true,
	lvl1_factor = 0.5,
	lvl2_factor = 1,
})

mcl_potions.register_effect({
	name = "swiftness",
	description = S("Swiftness"),
	get_tt = function(factor)
		return S("+@1% running speed", math.floor(factor*100))
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	on_start = function(object, factor)
		playerphysics.add_physics_factor(object, "speed", "mcl_potions:swiftness", 1+factor)
	end,
	on_end = function(object)
		playerphysics.remove_physics_factor(object, "speed", "mcl_potions:swiftness")
	end,
	particle_color = "#7CAFC6",
	uses_factor = true,
	lvl1_factor = 0.2,
	lvl2_factor = 0.4,
})

mcl_potions.register_effect({
	name = "slowness",
	description = S("Slowness"),
	get_tt = function(factor)
		return S("-@1% running speed", math.floor(factor*100))
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	on_start = function(object, factor)
		playerphysics.add_physics_factor(object, "speed", "mcl_potions:slowness", 1-factor)
	end,
	on_end = function(object)
		playerphysics.remove_physics_factor(object, "speed", "mcl_potions:slowness")
	end,
	particle_color = "#5A6C81",
	uses_factor = true,
	lvl1_factor = 0.15,
	lvl2_factor = 0.3,
})

mcl_potions.register_effect({
	name = "night_vision",
	description = S("Night Vision"),
	get_tt = function(factor)
		return S("improved vision during the night")
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	on_start = function(object, factor)
		object:get_meta():set_int("night_vision", 1)
	mcl_weather.skycolor.update_sky_color({object})
	end,
	on_step = function(dtime, object, factor, duration)
		mcl_weather.skycolor.update_sky_color({object})
	end,
	on_end = function(object)
		local meta = object:get_meta()
		meta:set_int("night_vision", 0)
		mcl_weather.skycolor.update_sky_color({object})
	end,
	particle_color = "#1F1FA1",
	uses_factor = false,
})

mcl_potions.register_effect({
	name = "fire_resistance",
	description = S("Fire Resistance"),
	get_tt = function(factor)
		return S("resistance to fire damage")
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	particle_color = "#E49A3A",
	uses_factor = false,
	damage_modifier = "is_fire",
})

mcl_potions.register_effect({
	name = "resistance",
	description = S("Resistance"),
	get_tt = function(factor)
		return S("resist @1% of incoming damage", math.floor(factor*100))
	end,
	res_condition = function(object)
		return (not object:is_player())
	end,
	particle_color = "#2552A5",
	uses_factor = true,
	lvl1_factor = 0.2,
	lvl2_factor = 0.4,
	damage_modifier = "",
	modifier_func = function(damage, effect_vals)
		return damage - (effect_vals.factor)*damage
	end,
})

mcl_potions.register_effect({
	name = "bad_omen",
	description = S("Bad Omen"),
	particle_color = "#0b6138",
})

mcl_potions.register_effect({
	name = "withering",
	description = S("Withering"),
	get_tt = function(factor)
		return S("-1 HP / @1 s, can kill", factor)
	end,
	res_condition = function(object)
		local entity = object:get_luaentity()
		return (entity and string.find(entity.name, "wither"))
	end,
	on_hit_timer = function(object, factor, duration)
		if object:is_player() or object:get_luaentity() then
			mcl_util.deal_damage(object, 1, {type = "magic"})
		end
	end,
	particle_color = "#000000",
	uses_factor = true,
	lvl1_factor = 2,
	lvl2_factor = 1,
	timer_uses_factor = true,
})


-- ██╗░░░██╗██████╗░██████╗░░█████╗░████████╗███████╗
-- ██║░░░██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
-- ██║░░░██║██████╔╝██║░░██║███████║░░░██║░░░█████╗░░
-- ██║░░░██║██╔═══╝░██║░░██║██╔══██║░░░██║░░░██╔══╝░░
-- ╚██████╔╝██║░░░░░██████╦╝██║░░██║░░░██║░░░███████╗
-- ░╚═════╝░╚═╝░░░░░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝
--
-- ██╗░░██╗██╗░░░██╗██████╗░
-- ██║░░██║██║░░░██║██╔══██╗
-- ███████║██║░░░██║██║░░██║
-- ██╔══██║██║░░░██║██║░░██║
-- ██║░░██║╚██████╔╝██████╦╝
-- ╚═╝░░╚═╝░╚═════╝░╚═════╝░

local icon_ids = {}

local function potions_set_hudbar(player)
	if EF.withering[player] and EF.regeneration[player] then
		hb.change_hudbar(player, "health", nil, nil, "mcl_potions_icon_regen_wither.png", nil, "hudbars_bar_health.png")
	elseif EF.withering[player] then
		hb.change_hudbar(player, "health", nil, nil, "mcl_potions_icon_wither.png", nil, "hudbars_bar_health.png")
	elseif EF.poison[player] and EF.regeneration[player] then
		hb.change_hudbar(player, "health", nil, nil, "hbhunger_icon_regen_poison.png", nil, "hudbars_bar_health.png")
	elseif EF.poison[player] then
		hb.change_hudbar(player, "health", nil, nil, "hbhunger_icon_health_poison.png", nil, "hudbars_bar_health.png")
	elseif EF.regeneration[player] then
		hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_regenerate.png", nil, "hudbars_bar_health.png")
	else
		hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
	end

end

local function potions_init_icons(player)
	local name = player:get_player_name()
	icon_ids[name] = {}
	for e=1, EFFECT_TYPES do
		local x = -52 * e - 2
		local id = {}
		id.img = player:hud_add({
			hud_elem_type = "image",
			text = "blank.png",
			position = { x = 1, y = 0 },
			offset = { x = x, y = 3 },
			scale = { x = 0.375, y = 0.375 },
			alignment = { x = 1, y = 1 },
			z_index = 100,
		})
		id.label = player:hud_add({
			hud_elem_type = "text",
			text = "",
			position = { x = 1, y = 0 },
			offset = { x = x+22, y = 50 },
			scale = { x = 50, y = 15 },
			alignment = { x = 0, y = 1 },
			z_index = 100,
			style = 1,
			number = 0xFFFFFF,
		})
		id.timestamp = player:hud_add({
			hud_elem_type = "text",
			text = "",
			position = { x = 1, y = 0 },
			offset = { x = x+22, y = 65 },
			scale = { x = 50, y = 15 },
			alignment = { x = 0, y = 1 },
			z_index = 100,
			style = 1,
			number = 0xFFFFFF,
		})
		table.insert(icon_ids[name], id)
	end
end

local function potions_set_icons(player)
	local name = player:get_player_name()
	if not icon_ids[name] then
		return
	end
	local active_effects = {}
	for effect_name, effect in pairs(EF) do
		if effect[player] then
			active_effects[effect_name] = effect[player]
		end
	end

	local i = 1
	for effect_name, def in pairs(registered_effects) do
		local icon = icon_ids[name][i].img
		local label = icon_ids[name][i].label
		local timestamp = icon_ids[name][i].timestamp
		local vals = active_effects[effect_name]
		if vals then
			player:hud_change(icon, "text", def.icon .. "^[resize:128x128")
			if def.uses_factor then
				local level = def.factor_to_level(vals.factor)
				if level == math.huge then level = "∞"
				else level = mcl_util.to_roman(level) end
				player:hud_change(label, "text", level)
			else
				player:hud_change(label, "text", "")
			end
			local dur = math.round(vals.dur-vals.timer)
			player:hud_change(timestamp, "text", math.floor(dur/60)..string.format(":%02d",math.floor(dur % 60)))
			EF[effect_name][player].hud_index = i
			i = i + 1
		end
	end
	while i < EFFECT_TYPES do
		player:hud_change(icon_ids[name][i].img, "text", "blank.png")
		player:hud_change(icon_ids[name][i].label, "text", "")
		player:hud_change(icon_ids[name][i].timestamp, "text", "")
		i = i + 1
	end
end

local function potions_set_hud(player)
	potions_set_hudbar(player)
	potions_set_icons(player)
end


-- ███╗░░░███╗░█████╗░██╗███╗░░██╗  ███████╗███████╗███████╗███████╗░█████╗░████████╗
-- ████╗░████║██╔══██╗██║████╗░██║  ██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝
-- ██╔████╔██║███████║██║██╔██╗██║  █████╗░░█████╗░░█████╗░░█████╗░░██║░░╚═╝░░░██║░░░
-- ██║╚██╔╝██║██╔══██║██║██║╚████║  ██╔══╝░░██╔══╝░░██╔══╝░░██╔══╝░░██║░░██╗░░░██║░░░
-- ██║░╚═╝░██║██║░░██║██║██║░╚███║  ███████╗██║░░░░░██║░░░░░███████╗╚█████╔╝░░░██║░░░
-- ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝  ╚══════╝╚═╝░░░░░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░
--
-- ░█████╗░██╗░░██╗███████╗░█████╗░██╗░░██╗███████╗██████╗░
-- ██╔══██╗██║░░██║██╔════╝██╔══██╗██║░██╔╝██╔════╝██╔══██╗
-- ██║░░╚═╝███████║█████╗░░██║░░╚═╝█████═╝░█████╗░░██████╔╝
-- ██║░░██╗██╔══██║██╔══╝░░██║░░██╗██╔═██╗░██╔══╝░░██╔══██╗
-- ╚█████╔╝██║░░██║███████╗╚█████╔╝██║░╚██╗███████╗██║░░██║
-- ░╚════╝░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝

minetest.register_globalstep(function(dtime)
	for name, effect in pairs(registered_effects) do
		for object, vals in pairs(EF[name]) do
			EF[name][object].timer = vals.timer + dtime

			if object:get_pos() then mcl_potions._add_spawner(object, effect.particle_color) end
			if effect.on_step then effect.on_step(dtime, object, vals.factor, vals.dur) end
			if effect.on_hit_timer then
				EF[name][object].hit_timer = (vals.hit_timer or 0) + dtime
				if EF[name][object].hit_timer >= vals.step then
					effect.on_hit_timer(object, vals.factor, vals.dur)
					if EF[name][object] then EF[name][object].hit_timer = 0 end
				end
			end

			if not EF[name][object] or EF[name][object].timer >= vals.dur then
				if effect.on_end then effect.on_end(object) end
				EF[name][object] = nil
				if object:is_player() then
					meta = object:get_meta()
					meta:set_string("mcl_potions:"..name, minetest.serialize(EF[name][object]))
					potions_set_hud(object)
				end
			elseif object:is_player() then
				local dur = math.round(vals.dur-vals.timer)
				object:hud_change(icon_ids[object:get_player_name()][vals.hud_index].timestamp,
					"text", math.floor(dur/60)..string.format(":%02d",math.floor(dur % 60)))
			end
		end
	end
end)


-- ███████╗███████╗███████╗███████╗░█████╗░████████╗
-- ██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝
-- █████╗░░█████╗░░█████╗░░█████╗░░██║░░╚═╝░░░██║░░░
-- ██╔══╝░░██╔══╝░░██╔══╝░░██╔══╝░░██║░░██╗░░░██║░░░
-- ███████╗██║░░░░░██║░░░░░███████╗╚█████╔╝░░░██║░░░
-- ╚══════╝╚═╝░░░░░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░
--
-- ██╗░░░░░░█████╗░░█████╗░██████╗░░░░░██╗░██████╗░█████╗░██╗░░░██╗███████╗
-- ██║░░░░░██╔══██╗██╔══██╗██╔══██╗░░░██╔╝██╔════╝██╔══██╗██║░░░██║██╔════╝
-- ██║░░░░░██║░░██║███████║██║░░██║░░██╔╝░╚█████╗░███████║╚██╗░██╔╝█████╗░░
-- ██║░░░░░██║░░██║██╔══██║██║░░██║░██╔╝░░░╚═══██╗██╔══██║░╚████╔╝░██╔══╝░░
-- ███████╗╚█████╔╝██║░░██║██████╔╝██╔╝░░░██████╔╝██║░░██║░░╚██╔╝░░███████╗
-- ╚══════╝░╚════╝░╚═╝░░╚═╝╚═════╝░╚═╝░░░░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝

function mcl_potions._clear_cached_player_data(player)
	for name, effect in pairs(EF) do
		effect[player] = nil
	end

	local meta = player:get_meta()
	meta:set_int("night_vision", 0)
end

function mcl_potions._reset_player_effects(player, set_hud)
	if not player:is_player() then
		return
	end

	for name, effect in pairs(registered_effects) do
		if effect.on_end then effect.on_end(player) end
	end

	mcl_potions._clear_cached_player_data(player)

	if set_hud ~= false then
		potions_set_hud(player)
	end
end

function mcl_potions._save_player_effects(player)
	if not player:is_player() then
		return
	end
	local meta = player:get_meta()

	for name, effect in pairs(registered_effects) do
		meta:set_string("mcl_potions:_EF_"..name, minetest.serialize(EF[name][player]))
	end
end

function mcl_potions._load_player_effects(player)
	if not player:is_player() then
		return
	end
	local meta = player:get_meta()

	-- handle legacy meta strings
	local legacy_invisible = minetest.deserialize(meta:get_string("_is_invisible"))
	local legacy_poisoned = minetest.deserialize(meta:get_string("_is_poisoned"))
	local legacy_regenerating = minetest.deserialize(meta:get_string("_is_regenerating"))
	local legacy_strong = minetest.deserialize(meta:get_string("_is_strong"))
	local legacy_weak = minetest.deserialize(meta:get_string("_is_weak"))
	local legacy_water_breathing = minetest.deserialize(meta:get_string("_is_water_breathing"))
	local legacy_leaping = minetest.deserialize(meta:get_string("_is_leaping"))
	local legacy_swift = minetest.deserialize(meta:get_string("_is_swift"))
	local legacy_night_vision = minetest.deserialize(meta:get_string("_is_cat"))
	local legacy_fireproof = minetest.deserialize(meta:get_string("_is_fire_proof"))
	local legacy_bad_omen = minetest.deserialize(meta:get_string("_has_bad_omen"))
	local legacy_withering = minetest.deserialize(meta:get_string("_is_withering"))
	if legacy_invisible then
		EF.invisibility[player] = legacy_invisible
		meta:set_string("_is_invisible", "")
	end
	if legacy_poisoned then
		EF.poison[player] = legacy_poisoned
		meta:set_string("_is_poisoned", "")
	end
	if legacy_regenerating then
		EF.regeneration[player] = legacy_regenerating
		meta:set_string("_is_regenerating", "")
	end
	if legacy_strong then
		EF.strength[player] = legacy_strong
		meta:set_string("_is_strong", "")
	end
	if legacy_weak then
		EF.weakness[player] = legacy_weak
		meta:set_string("_is_weak", "")
	end
	if legacy_water_breathing then
		EF.water_breathing[player] = legacy_water_breating
		meta:set_string("_is_water_breating", "")
	end
	if legacy_leaping then
		EF.leaping[player] = legacy_leaping
		meta:set_string("_is_leaping", "")
	end
	if legacy_swift then
		EF.swiftness[player] = legacy_swift
		meta:set_string("_is_swift", "")
	end
	if legacy_night_vision then
		EF.night_vision[player] = legacy_night_vision
		meta:set_string("_is_cat", "")
	end
	if legacy_fireproof then
		EF.fire_resistance[player] = legacy_fireproof
		meta:set_string("_is_fire_proof", "")
	end
	if legacy_bad_omen then
		EF.bad_omen[player] = legacy_bad_omen
		meta:set_string("_has_bad_omen", "")
	end
	if legacy_withering then
		EF.withering[player] = legacy_withering
		meta:set_string("_is_withering", "")
	end

	-- new API effects + on_load for loaded legacy effects
	for name, effect in pairs(registered_effects) do
		local loaded = minetest.deserialize(meta:get_string("mcl_potions:_EF_"..name))
		if loaded then EF[name][player] = loaded end
		if EF[name][player] and effect.on_load then
			effect.on_load(player, EF[name][player].factor)
		end
	end
end

-- Returns true if player has given effect
function mcl_potions.player_has_effect(player, effect_name)
	if not EF[effect_name] then
		return false
	end
	return EF[effect_name][player] ~= nil
end

function mcl_potions.player_get_effect(player, effect_name)
	if not EF[effect_name] or not EF[effect_name][player] then
		return false
	end
	return EF[effect_name][player]
end

function mcl_potions.player_clear_effect(player,effect)
	EF[effect][player] = nil
	potions_set_hud(player)
end

minetest.register_on_leaveplayer( function(player)
	mcl_potions._save_player_effects(player)
	mcl_potions._clear_cached_player_data(player) -- clear the buffer to prevent looking for a player not there
	icon_ids[player:get_player_name()] = nil
end)

minetest.register_on_dieplayer( function(player)
	mcl_potions._reset_player_effects(player)
	potions_set_hud(player)
end)

minetest.register_on_joinplayer( function(player)
	mcl_potions._reset_player_effects(player, false) -- make sure there are no weird holdover effects
	mcl_potions._load_player_effects(player)
	potions_init_icons(player)
	potions_set_hud(player)
end)

minetest.register_on_shutdown(function()
	-- save player effects on server shutdown
	for _,player in pairs(minetest.get_connected_players()) do
		mcl_potions._save_player_effects(player)
	end
end)

-- ░██████╗██╗░░░██╗██████╗░██████╗░░█████╗░██████╗░████████╗██╗███╗░░██╗░██████╗░
-- ██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║████╗░██║██╔════╝░
-- ╚█████╗░██║░░░██║██████╔╝██████╔╝██║░░██║██████╔╝░░░██║░░░██║██╔██╗██║██║░░██╗░
-- ░╚═══██╗██║░░░██║██╔═══╝░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░██║██║╚████║██║░░╚██╗
-- ██████╔╝╚██████╔╝██║░░░░░██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║██║░╚███║╚██████╔╝
-- ╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝╚═╝░░╚══╝░╚═════╝░
--
-- ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
-- ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
-- █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
-- ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
-- ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
-- ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

function mcl_potions.is_obj_hit(self, pos)

	local entity
	for _,object in pairs(minetest.get_objects_inside_radius(pos, 1.1)) do

		entity = object:get_luaentity()

		if entity and entity.name ~= self.object:get_luaentity().name then

			if entity.is_mob then
				return true
			end

		elseif object:is_player() and self._thrower ~= object:get_player_name() then
			return true
		end

	end
	return false
end


function mcl_potions.make_invisible(obj_ref, hide)
	if obj_ref:is_player() then
		if hide then
			mcl_player.player_set_visibility(obj_ref, false)
			obj_ref:set_nametag_attributes({ color = { a = 0 } })
		else
			mcl_player.player_set_visibility(obj_ref, true)
			obj_ref:set_nametag_attributes({ color = { r = 255, g = 255, b = 255, a = 255 } })
		end
	else -- TODO make below section (and preferably other effects on mobs) rely on metadata
		if hide then
			local luaentity = obj_ref:get_luaentity()
			EF.invisibility[obj_ref].old_size = luaentity.visual_size
			obj_ref:set_properties({ visual_size = { x = 0, y = 0 } })
		else
			obj_ref:set_properties({ visual_size = EF.invisibility[obj_ref].old_size })
		end
	end
end


function mcl_potions._use_potion(obj, color)
	local d = 0.1
	local pos = obj:get_pos()
	minetest.sound_play("mcl_potions_drinking", {pos = pos, max_hear_distance = 6, gain = 1})
	minetest.add_particlespawner({
		amount = 25,
		time = 1,
		minpos = {x=pos.x-d, y=pos.y+1, z=pos.z-d},
		maxpos = {x=pos.x+d, y=pos.y+2, z=pos.z+d},
		minvel = {x=-0.1, y=0, z=-0.1},
		maxvel = {x=0.1, y=0.1, z=0.1},
		minacc = {x=-0.1, y=0, z=-0.1},
		maxacc = {x=0.1, y=.1, z=0.1},
		minexptime = 1,
		maxexptime = 5,
		minsize = 0.5,
		maxsize = 1,
		collisiondetection = true,
		vertical = false,
		texture = "mcl_particles_effect.png^[colorize:"..color..":127",
	})
end


function mcl_potions._add_spawner(obj, color)
	local d = 0.2
	local pos = obj:get_pos()
	minetest.add_particlespawner({
		amount = 1,
		time = 1,
		minpos = {x=pos.x-d, y=pos.y+1, z=pos.z-d},
		maxpos = {x=pos.x+d, y=pos.y+2, z=pos.z+d},
		minvel = {x=-0.1, y=0, z=-0.1},
		maxvel = {x=0.1, y=0.1, z=0.1},
		minacc = {x=-0.1, y=0, z=-0.1},
		maxacc = {x=0.1, y=.1, z=0.1},
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		texture = "mcl_particles_effect.png^[colorize:"..color..":127",
	})
end



-- ██████╗░░█████╗░░██████╗███████╗  ██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
-- ██╔══██╗██╔══██╗██╔════╝██╔════╝  ██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
-- ██████╦╝███████║╚█████╗░█████╗░░  ██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
-- ██╔══██╗██╔══██║░╚═══██╗██╔══╝░░  ██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
-- ██████╦╝██║░░██║██████╔╝███████╗  ██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
-- ╚═════╝░╚═╝░░╚═╝╚═════╝░╚══════╝  ╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
--
-- ███████╗███████╗███████╗███████╗░█████╗░████████╗
-- ██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝
-- █████╗░░█████╗░░█████╗░░█████╗░░██║░░╚═╝░░░██║░░░
-- ██╔══╝░░██╔══╝░░██╔══╝░░██╔══╝░░██║░░██╗░░░██║░░░
-- ███████╗██║░░░░░██║░░░░░███████╗╚█████╔╝░░░██║░░░
-- ╚══════╝╚═╝░░░░░╚═╝░░░░░╚══════╝░╚════╝░░░░╚═╝░░░
--
-- ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
-- ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
-- █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
-- ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
-- ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
-- ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

local function target_valid(object, name)
	if not object or object:get_hp() <= 0 then return false end

	local entity = object:get_luaentity()
	if entity and entity.is_boss then return false end

	if not (registered_effects[name].res_condition
		and registered_effects[name].res_condition(object)) then return true end
end

function mcl_potions.give_effect(name, object, factor, duration)
	local edef = registered_effects[name]
	if not edef or not target_valid(object, name) then return false end
	if not EF[name][object] then
		local vals = {dur = duration, timer = 0,}
		if edef.uses_factor then vals.factor = factor end
		if edef.on_hit_timer then
			if edef.timer_uses_factor then vals.step = factor
			else vals.step = edef.hit_timer_step end
		end
		EF[name][object] = vals
		if edef.on_start then edef.on_start(object, factor) end
	else
		local present = EF[name][object]
		if not edef.uses_factor or (edef.uses_factor and
			(not edef.inv_factor and factor >= present.factor
			or edef.inv_factor and factor <= present.factor)) then
				present.dur = math.max(duration, present.dur - present.timer)
				present.timer = 0
				if edef.uses_factor then
					present.factor = factor
					if edef.timer_uses_factor then present.step = factor end
					if edef.on_start then edef.on_start(object, factor) end
				end
		else
			return false
		end
	end

	if object:is_player() then potions_set_hud(object) end

	return true
end

function mcl_potions.give_effect_by_level(name, object, level, duration)
	if level == 0 then return false end
	if not registered_effects[name].uses_factor then
		return mcl_potions.give_effect(name, object, 0, duration)
	end
	local factor = registered_effects[name].level_to_factor(level)
	return mcl_potions.give_effect(name, object, factor, duration)
end

function mcl_potions.healing_func(object, hp)
	if not object or object:get_hp() <= 0 then return false end
	local ent = object:get_luaentity()

	if ent and ent.harmed_by_heal then hp = -hp end

	if hp > 0 then
		-- at least 1 HP
		if hp < 1 then
			hp = 1
		end

		if ent and ent.is_mob then
			ent.health = math.min(ent.health + hp, ent.hp_max)
		elseif object:is_player() then
			object:set_hp(math.min(object:get_hp() + hp, object:get_properties().hp_max), { type = "set_hp", other = "healing" })
		end

	elseif hp < 0 then
		if hp > -1 then
			hp = -1
		end

		mcl_util.deal_damage(object, -hp, {type = "magic"})
	end
end

function mcl_potions.strength_func(object, factor, duration)
	return mcl_potions.give_effect("strength", object, factor, duration)
end
function mcl_potions.leaping_func(object, factor, duration)
	return mcl_potions.give_effect("leaping", object, factor, duration)
end
function mcl_potions.weakness_func(object, factor, duration)
	return mcl_potions.give_effect("weakness", object, factor, duration)
end
function mcl_potions.swiftness_func(object, factor, duration)
	return mcl_potions.give_effect("swiftness", object, factor, duration)
end
function mcl_potions.slowness_func(object, factor, duration)
	return mcl_potions.give_effect("slowness", object, factor, duration)
end

function mcl_potions.withering_func(object, factor, duration)
	return mcl_potions.give_effect("withering", object, factor, duration)
end


function mcl_potions.poison_func(object, factor, duration)
	return mcl_potions.give_effect("poison", object, factor, duration)
end


function mcl_potions.regeneration_func(object, factor, duration)
	return mcl_potions.give_effect("regeneration", object, factor, duration)
end


function mcl_potions.invisiblility_func(object, null, duration)
	return mcl_potions.give_effect("invisibility", object, null, duration)
end

function mcl_potions.water_breathing_func(object, null, duration)
	return mcl_potions.give_effect("water_breathing", object, null, duration)
end


function mcl_potions.fire_resistance_func(object, null, duration)
	return mcl_potions.give_effect("fire_resistance", object, null, duration)
end


function mcl_potions.night_vision_func(object, null, duration)
	return mcl_potions.give_effect("night_vision", object, null, duration)
end

function mcl_potions._extinguish_nearby_fire(pos, radius)
	local epos = {x=pos.x, y=pos.y+0.5, z=pos.z}
	local dnode = minetest.get_node({x=pos.x,y=pos.y-0.5,z=pos.z})
	if minetest.get_item_group(dnode.name, "fire") ~= 0 or minetest.get_item_group(dnode.name, "lit_campfire") ~= 0 then
		epos.y = pos.y - 0.5
	end
	local exting = false
	-- No radius: Splash, extinguish epos and 4 nodes around
	if not radius then
		local dirs = {
			{x=0,y=0,z=0},
			{x=0,y=0,z=-1},
			{x=0,y=0,z=1},
			{x=-1,y=0,z=0},
			{x=1,y=0,z=0},
		}
		for d=1, #dirs do
			local tpos = vector.add(epos, dirs[d])
			local node = minetest.get_node(tpos)
			if minetest.get_item_group(node.name, "fire") ~= 0 then
				minetest.sound_play("fire_extinguish_flame", {pos = tpos, gain = 0.25, max_hear_distance = 16}, true)
				minetest.remove_node(tpos)
				exting = true
			elseif minetest.get_item_group(node.name, "lit_campfire") ~= 0 then
				minetest.sound_play("fire_extinguish_flame", {pos = tpos, gain = 0.25, max_hear_distance = 16}, true)
				local def = minetest.registered_nodes[node.name]
				minetest.set_node(tpos, {name = def._mcl_campfires_smothered_form, param2 = node.param2})
				exting = true
			end
		end
	-- Has radius: lingering, extinguish all nodes in area
	else
		local nodes = minetest.find_nodes_in_area(
			{x=epos.x-radius,y=epos.y,z=epos.z-radius},
			{x=epos.x+radius,y=epos.y,z=epos.z+radius},
			{"group:fire", "group:lit_campfire"})
		for n=1, #nodes do
			local node = minetest.get_node(nodes[n])
			minetest.sound_play("fire_extinguish_flame", {pos = nodes[n], gain = 0.25, max_hear_distance = 16}, true)
			if minetest.get_item_group(node.name, "fire") ~= 0 then
				minetest.remove_node(nodes[n])
			elseif minetest.get_item_group(node.name, "lit_campfire") ~= 0 then
				local def = minetest.registered_nodes[node.name]
				minetest.set_node(nodes[n], {name = def._mcl_campfires_smothered_form, param2 = node.param2})
			end
			exting = true
		end
	end
	return exting
end

function mcl_potions.bad_omen_func(object, factor, duration)
	mcl_potions.give_effect("bad_omen", object, factor, duration)
end
