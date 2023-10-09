local S = minetest.get_translator(minetest.get_current_modname())

-- ░█████╗░██╗░░██╗░█████╗░████████╗  ░█████╗░░█████╗░███╗░░░███╗███╗░░░███╗░█████╗░███╗░░██╗██████╗░░██████╗
-- ██╔══██╗██║░░██║██╔══██╗╚══██╔══╝  ██╔══██╗██╔══██╗████╗░████║████╗░████║██╔══██╗████╗░██║██╔══██╗██╔════╝
-- ██║░░╚═╝███████║███████║░░░██║░░░  ██║░░╚═╝██║░░██║██╔████╔██║██╔████╔██║███████║██╔██╗██║██║░░██║╚█████╗░
-- ██║░░██╗██╔══██║██╔══██║░░░██║░░░  ██║░░██╗██║░░██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚████║██║░░██║░╚═══██╗
-- ╚█████╔╝██║░░██║██║░░██║░░░██║░░░  ╚█████╔╝╚█████╔╝██║░╚═╝░██║██║░╚═╝░██║██║░░██║██║░╚███║██████╔╝██████╔╝
-- ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═════╝░


minetest.register_chatcommand("effect",{
	params = S("<effect> <duration> [<level>] [<factor>]"),
	description = S("Add a status effect to yourself. Arguments: <effect>: name of status effect, e.g. poison. <duration>: duration in seconds. <level>: effect power determinant, bigger level results in more powerful effect for effects that depend on the level, defaults to 1, pass F to use low-level factor instead. <factor>: effect strength modifier, can mean different things depending on the effect."),
	privs = {server = true},
	func = function(name, params)

		local P = {}
		local i = 0
		for str in string.gmatch(params, "([^ ]+)") do
			i = i + 1
			P[i] = str
		end

		if not P[1] then
			return false, S("Missing effect parameter!")
		elseif P[1] == "list" then
			local regs = mcl_potions.get_registered_effects()
			local effects = "heal"
			for name, _ in pairs(regs) do
				effects = effects .. ", " .. name
			end
			return true, effects
		elseif not tonumber(P[2])then
			return false, S("Missing or invalid duration parameter!")
		elseif P[3] and not tonumber(P[3]) and P[3] ~= "F" then
			return false, S("Invalid level parameter!")
		elseif P[3] and P[3] == "F" and not P[4] then
			return false, S("Missing or invalid factor parameter when level is F!")
		end

		-- Default level = 1
		if not P[3] then
			P[3] = 1
		end

		if mcl_potions.is_effect_registered(P[1]) then
			if P[3] == "F" then
				local given = mcl_potions.give_effect(P[1], minetest.get_player_by_name(name), tonumber(P[4]), tonumber(P[2]))
				if given then
					return true, S("@1 effect given to player @2 for @3 seconds with factor of @4.", P[1], name, P[2], P[4])
				else
					return false, S("Giving effect @1 to player @2 failed.", P[1], name)
				end
			else
				local given = mcl_potions.give_effect_by_level(P[1], minetest.get_player_by_name(name), tonumber(P[3]), tonumber(P[2]))
				if given then
					return true, S("@1 effect on level @2 given to player @3 for @4 seconds.", P[1], P[3], name, P[2])
				else
					return false, S("Giving effect @1 to player @2 failed.", P[1], name)
				end
			end
		else
			return false, S("@1 is not an available status effect.", P[1])
		end

	 end,
})

