mcl_luck = {}

-- table indexed by player name
-- each entry for each player contains list of modifiers applied to the player
-- modifiers are listed by their name (defined when applying them)
-- all modifiers are dynamic (they are removed when the player leaves game and on server shutdown)
local applied_luck = {}

function mcl_luck.apply_luck_modifier(player_name, modifier_name, amount)
	applied_luck[player_name][modifier_name] = amount
end

function mcl_luck.remove_luck_modifier(player_name, modifier_name)
	applied_luck[player_name][modifier_name] = nil
end

function mcl_luck.get_luck(player_name)
	local luck = 0
	for _, amount in pairs(applied_luck[player_name]) do
		luck = luck + amount
	end
	return luck
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	applied_luck[player_name] = {}
end)

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	applied_luck[player_name] = nil
end)
