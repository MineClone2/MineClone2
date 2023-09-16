local S = minetest.get_translator(minetest.get_current_modname())

-- Node box
local p = {-2/16, -0.5, -2/16, 2/16, 0.5, 2/16}
local x1 = {-0.5, 4/16, -1/16, -2/16, 7/16, 1/16}   --oben(quer) -x
local x12 = {-0.5, -2/16, -1/16, -2/16, 1/16, 1/16} --unten(quer) -x
local x2 = {2/16, 4/16, -1/16, 0.5, 7/16, 1/16}   --oben(quer) x
local x22 = {2/16, -2/16, -1/16, 0.5, 1/16, 1/16} --unten(quer) x
local z1 = {-1/16, 4/16, -0.5, 1/16, 7/16, -2/16}   --oben(quer) -z
local z12 = {-1/16, -2/16, -0.5, 1/16, 1/16, -2/16} --unten(quer) -z
local z2 = {-1/16, 4/16, 2/16, 1/16, 7/16, 0.5}   --oben(quer) z
local z22 = {-1/16, -2/16, 2/16, 1/16, 1/16, 0.5} --unten(quer) z

-- Collision box
local cp = {-2/16, -0.5, -2/16, 2/16, 1.01, 2/16}
local cx1 = {-0.5, -0.5, -2/16, -2/16, 1.01, 2/16} --unten(quer) -x
local cx2 = {2/16, -0.5, -2/16, 0.5, 1.01, 2/16} --unten(quer) x
local cz1 = {-2/16, -0.5, -0.5, 2/16, 1.01, -2/16} --unten(quer) -z
local cz2 = {-2/16, -0.5, 2/16, 2/16, 1.01, 0.5} --unten(quer) z

mcl_fences = {}

function mcl_fences.register_fence(id, fence_name, texture, groups, hardness, blast_resistance, connects_to, sounds)
	local cgroups = table.copy(groups)
	if cgroups == nil then cgroups = {} end
	cgroups.fence = 1
	cgroups.deco_block = 1
	if connects_to == nil then
		connects_to = {}
	else
		connects_to = table.copy(connects_to)
	end
	local fence_id = minetest.get_current_modname()..":"..id
	table.insert(connects_to, "group:solid")
	table.insert(connects_to, "group:fence_gate")
	table.insert(connects_to, fence_id)
	minetest.register_node(fence_id, {
		description = fence_name,
		_doc_items_longdesc = S("Fences are structures which block the way. Fences will connect to each other and solid blocks. They cannot be jumped over with a simple jump."),
		tiles = {texture},
		inventory_image = "mcl_fences_fence_mask.png^" .. texture .. "^mcl_fences_fence_mask.png^[makealpha:255,126,126",
		wield_image = "mcl_fences_fence_mask.png^" .. texture .. "^mcl_fences_fence_mask.png^[makealpha:255,126,126",
		paramtype = "light",
		is_ground_content = false,
		groups = cgroups,
		stack_max = 64,
		sunlight_propagates = true,
		drawtype = "nodebox",
		connect_sides = { "front", "back", "left", "right" },
		connects_to = connects_to,
		node_box = {
			type = "connected",
			fixed = {p},
			connect_front = {z1,z12},
			connect_back = {z2,z22,},
			connect_left = {x1,x12},
			connect_right = {x2,x22},
		},
		collision_box = {
			type = "connected",
			fixed = {cp},
			connect_front = {cz1},
			connect_back = {cz2,},
			connect_left = {cx1},
			connect_right = {cx2},
		},
		sounds = sounds,
		_mcl_blast_resistance = blast_resistance,
		_mcl_hardness = hardness,
	})

	return fence_id
end

function mcl_fences.register_fence_gate(id, fence_gate_name, texture, groups, hardness, blast_resistance, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close)
	local meta2
	local state2 = 0

	local function update_gate(pos, node)
		minetest.set_node(pos, node)
	end

	local gate_id = minetest.get_current_modname()..":"..id.."_gate"
	local open_gate_id = gate_id .. "_open"
	if not sound_open then
		sound_open = "doors_fencegate_open"
	end
	if not sound_close then
		sound_close = "doors_fencegate_close"
	end
	if not sound_gain_open then
		sound_gain_open = 0.3
	end
	if not sound_gain_close then
		sound_gain_close = 0.3
	end
	local function punch_gate(pos, node)
		meta2 = minetest.get_meta(pos)
		state2 = meta2:get_int("state")
		local tmp_node2
		if state2 == 1 then
			state2 = 0
			minetest.sound_play(sound_close, {gain = sound_gain_close, max_hear_distance = 10, pos = pos}, true)
			tmp_node2 = {name=gate_id, param1=node.param1, param2=node.param2}
		else
			state2 = 1
			minetest.sound_play(sound_open, {gain = sound_gain_open, max_hear_distance = 10, pos = pos}, true)
			tmp_node2 = {name=open_gate_id, param1=node.param1, param2=node.param2}
		end
		update_gate(pos, tmp_node2)
		meta2:set_int("state", state2)
	end

	local on_rotate
	if minetest.get_modpath("screwdriver") then
		on_rotate = screwdriver.rotate_simple
	end

	local cgroups = table.copy(groups)
	if cgroups == nil then cgroups = {} end
	cgroups.fence_gate = 1
	cgroups.deco_block = 1

	cgroups.mesecon_ignore_opaque_dig = 1
	cgroups.mesecon_effector_on = 1
	cgroups.fence_gate = 1
	minetest.register_node(open_gate_id, {
		tiles = {texture},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sunlight_propagates = true,
		walkable = false,
		groups = cgroups,
		drop = gate_id,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -3/16, -1/16, -6/16, 0.5, 1/16},   --links abschluss
				{6/16, -3/16, -1/16, 0.5, 0.5, 1/16},   --rechts abschluss
				{-0.5, 4/16, 1/16, -6/16, 7/16, 6/16},   --oben-links(quer) x
				{-0.5, -2/16, 1/16, -6/16, 1/16, 6/16}, --unten-links(quer) x
				{6/16, 4/16, 1/16, 0.5, 7/16, 0.5},   --oben-rechts(quer) x
				{6/16, -2/16, 1/16, 0.5, 1/16, 0.5}, --unten-rechts(quer) x
				{-0.5, -2/16, 6/16, -6/16, 7/16, 0.5},  --mitte links
				{6/16, 1/16, 0.5, 0.5, 4/16, 6/16},  --mitte rechts
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {
					{-0.5, -3/16, -1/16, 0.5, 0.5, 1/16},   --gate
				}
		},
		on_rightclick = function(pos, node, clicker)
			punch_gate(pos, node)
		end,
		mesecons = {effector = {
			action_off = (function(pos, node)
				punch_gate(pos, node)
			end),
		}},
		on_rotate = on_rotate,
		sounds = sounds,
		_mcl_blast_resistance = blast_resistance,
		_mcl_hardness = hardness,
	})

	local cgroups_closed = table.copy(cgroups)
	cgroups_closed.mesecon_effector_on = nil
	cgroups_closed.mesecon_effector_off = nil
	minetest.register_node(gate_id, {
		description = fence_gate_name,
		_tt_help = S("Openable by players and redstone power"),
		_doc_items_longdesc = S("Fence gates can be opened or closed and can't be jumped over. Fences will connect nicely to fence gates."),
		_doc_items_usagehelp = S("Right-click the fence gate to open or close it."),
		tiles = {texture},
		inventory_image = "mcl_fences_fence_gate_mask.png^" .. texture .. "^mcl_fences_fence_gate_mask.png^[makealpha:255,126,126",
		wield_image = "mcl_fences_fence_gate_mask.png^" .. texture .. "^mcl_fences_fence_gate_mask.png^[makealpha:255,126,126",
		paramtype = "light",
		is_ground_content = false,
		stack_max = 64,
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = true,
		groups = cgroups_closed,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -3/16, -1/16, -6/16, 0.5, 1/16},   --links abschluss
				{6/16, -3/16, -1/16, 0.5, 0.5, 1/16},   --rechts abschluss
				{-2/16, -2/16, -1/16, 0, 7/16, 1/16},  --mitte links
				{0, -2/16, -1/16, 2/16, 7/16, 1/16},  --mitte rechts
				{-0.5, 4/16, -1/16, -2/16, 7/16, 1/16},   --oben(quer) -z
				{-0.5, -2/16, -1/16, -2/16, 1/16, 1/16}, --unten(quer) -z
				{2/16, 4/16, -1/16, 0.5, 7/16, 1/16},   --oben(quer) z
				{2/16, -2/16, -1/16, 0.5, 1/16, 1/16}, --unten(quer) z
			}
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -3/16, -2/16, 0.5, 1, 2/16},   --gate
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -3/16, -1/16, 0.5, 0.5, 1/16},   --gate
			}
		},
		on_construct = function(pos)
			meta2 = minetest.get_meta(pos)
			meta2:set_int("state", 0)
			state2 = 0
		end,
		mesecons = {effector = {
			action_on = (function(pos, node)
				punch_gate(pos, node)
			end),
		}},
		on_rotate = on_rotate,
		on_rightclick = function(pos, node, clicker)
			punch_gate(pos, node)
		end,
		sounds = sounds,
		_mcl_blast_resistance = blast_resistance,
		_mcl_hardness = hardness,
	})

	if minetest.get_modpath("doc") then
		doc.add_entry_alias("nodes", gate_id, "nodes", open_gate_id)
	end

	return gate_id, open_gate_id
end

function mcl_fences.register_fence_and_fence_gate(id, fence_name, fence_gate_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close, texture_fence_gate)
	if texture_fence_gate == nil then
		texture_fence_gate = texture_fence
	end
	local fence_id = mcl_fences.register_fence(id, fence_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds)
	local gate_id, open_gate_id = mcl_fences.register_fence_gate(id, fence_gate_name, texture_fence_gate, groups, hardness, blast_resistance, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close)
	return fence_id, gate_id, open_gate_id
end

local wood_groups = {handy=1,axey=1, flammable=2,fence_wood=1, fire_encouragement=5, fire_flammability=20}
local wood_connect = {"group:fence_wood"}
local wood_sounds = mcl_sounds.node_sound_wood_defaults()

local woods = {
	{"", S("Oak Fence"), S("Oak Fence Gate"), "mcl_fences_fence_oak.png", "mcl_fences_fence_gate_oak.png", "mcl_core:wood"},
	{"spruce", S("Spruce Fence"), S("Spruce Fence Gate"), "mcl_fences_fence_spruce.png", "mcl_fences_fence_gate_spruce.png", "mcl_core:sprucewood"},
	{"birch", S("Birch Fence"), S("Birch Fence Gate"), "mcl_fences_fence_birch.png", "mcl_fences_fence_gate_birch.png", "mcl_core:birchwood"},
	{"jungle", S("Jungle Fence"), S("Jungle Fence Gate"), "mcl_fences_fence_jungle.png", "mcl_fences_fence_gate_jungle.png", "mcl_core:junglewood"},
	{"dark_oak", S("Dark Oak Fence"), S("Dark Oak Fence Gate"), "mcl_fences_fence_big_oak.png", "mcl_fences_fence_gate_big_oak.png", "mcl_core:darkwood"},
	{"acacia", S("Acacia Fence"), S("Acacia Fence Gate"), "mcl_fences_fence_acacia.png", "mcl_fences_fence_gate_acacia.png", "mcl_core:acaciawood"},
}

for w=1, #woods do
	local wood = woods[w]
	local id, id_gate
	if wood[1] == "" then
		id = "fence"
		id_gate = "fence_gate"
	else
		id = wood[1].."_fence"
		id_gate = wood[1].."_fence_gate"
	end
	mcl_fences.register_fence_and_fence_gate(
		id,
		wood[2],
		wood[3],
		wood[4],
		wood_groups,
		minetest.registered_nodes["mcl_core:wood"]._mcl_hardness,
		minetest.registered_nodes["mcl_core:wood"]._mcl_blast_resistance,
		wood_connect,
		wood_sounds)

	minetest.register_craft({
		output = "mcl_fences:"..id.." 3",
		recipe = {
			{wood[6], "mcl_core:stick", wood[6]},
			{wood[6], "mcl_core:stick", wood[6]},
		}
	})
	minetest.register_craft({
		output = "mcl_fences:"..id_gate,
		recipe = {
			{"mcl_core:stick", wood[6], "mcl_core:stick"},
			{"mcl_core:stick", wood[6], "mcl_core:stick"},
		}
	})
end


-- Nether Brick Fence (without fence gate!)
mcl_fences.register_fence(
	"nether_brick_fence",
	S("Nether Brick Fence"),
	"mcl_fences_fence_nether_brick.png",
	{pickaxey=1, deco_block=1, fence_nether_brick=1},
	minetest.registered_nodes["mcl_nether:nether_brick"]._mcl_hardness,
	minetest.registered_nodes["mcl_nether:nether_brick"]._mcl_blast_resistance,
	{"group:fence_nether_brick"},
	mcl_sounds.node_sound_stone_defaults())

minetest.register_craft({
	output = "mcl_fences:nether_brick_fence 6",
	recipe = {
		{"mcl_nether:nether_brick", "mcl_nether:netherbrick", "mcl_nether:nether_brick"},
		{"mcl_nether:nether_brick", "mcl_nether:netherbrick", "mcl_nether:nether_brick"},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:fence_wood",
	burntime = 15,
})
