local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

local copper_mod = minetest.get_modpath("mcl_copper")
local cobble = "mcl_deepslate:deepslate_cobbled"
local stick = "mcl_core:stick"

local function spawn_silverfish(pos, oldnode, oldmetadata, digger)
	if not minetest.is_creative_enabled("") then
		minetest.add_entity(pos, "mobs_mc:silverfish")
	end
end

minetest.register_node("mcl_deepslate:deepslate", {
	description = S("Deepslate"),
	_doc_items_longdesc = S("Deepslate is a stone type found deep underground in the Overworld that functions similar to regular stone but is harder than the stone."),
	_doc_items_hidden = false,
	tiles = { "mcl_deepslate_top.png", "mcl_deepslate_top.png", "mcl_deepslate.png" },
	paramtype2 = "facedir",
	is_ground_content = true,
	on_place = mcl_util.rotate_axis,
	groups = { pickaxey = 1, stone = 1, building_block = 1, material_stone = 1 },
	drop = cobble,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_3way,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
	_mcl_silk_touch_drop = true,
})

minetest.register_node("mcl_deepslate:infested_deepslate", {
	description = S("Infested Deepslate"),
	_doc_items_longdesc = S("An infested block is a block from which a silverfish will pop out when it is broken. It looks identical to its normal counterpart."),
	_tt_help = S("Hides a silverfish"),
	tiles = { "mcl_deepslate_top.png", "mcl_deepslate_top.png", "mcl_deepslate.png" },
	is_ground_content = true,
	groups = { dig_immediate = 3, spawns_silverfish = 1, deco_block = 1 },
	drop = "",
	sounds = mcl_sounds.node_sound_stone_defaults(),
	after_dig_node = spawn_silverfish,
	_mcl_hardness = 0,
	_mcl_blast_resistance = 0.5,
})

minetest.register_node("mcl_deepslate:tuff", {
	description = S("Tuff"),
	_doc_items_longdesc = S("Tuff is an ornamental rock formed from volcanic ash, occurring in underground blobs below Y=16."),
	_doc_items_hidden = false,
	tiles = { "mcl_deepslate_tuff.png" },
	groups = { pickaxey = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_silk_touch_drop = true,
})

local function register_deepslate_ore(desc, drop, cooked, pick, xp)
	local item = desc:lower()
	local item_string
	if item == "lapis lazuli" then
		item_string = "lapis"
	else
		item_string = item
	end
	local nodename = "mcl_deepslate:deepslate_with_"..item_string
	minetest.register_node(nodename, {
		description = S("Deepslate "..desc.." Ore"),
		_doc_items_longdesc = S("Deepslate "..item.." ore is a variant of "..item.." ore that can generate in deepslate and tuff blobs."),
		_doc_items_hidden = false,
		tiles = { "mcl_deepslate_"..item_string.."_ore.png" },
		is_ground_content = true,
		stack_max = 64,
		groups = { pickaxey = pick, building_block = 1, material_stone = 1, xp = xp },
		drop = drop,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 3,
		_mcl_hardness = 4.5,
		_mcl_silk_touch_drop = true,
		_mcl_fortune_drop = mcl_core.fortune_drop_ore,
	})

	minetest.register_craft({
		type = "cooking",
		output = cooked,
		recipe = nodename,
		cooktime = 10,
	})
end

local lapis_drops = {
	max_items = 1, items = {
		{ items = { "mcl_core:lapis 8" }, rarity = 5 },
		{ items = { "mcl_core:lapis 7" }, rarity = 5 },
		{ items = { "mcl_core:lapis 6" }, rarity = 5 },
		{ items = { "mcl_core:lapis 5" }, rarity = 5 },
		{ items = { "mcl_core:lapis 4" } }
	}
}

local deepslate_ores = {
	{ "Coal", "mcl_core:coal_lump", "mcl_core:coal_lump", 1, 1 },
	{ "Iron", "mcl_raw_ores:raw_iron", "mcl_core:iron_ingot", 3, 0 },
	{ "Gold", "mcl_raw_ores:raw_gold", "mcl_core:gold_ingot", 4, 0 },
	{ "Emerald", "mcl_core:emerald", "mcl_core:emerald", 4, 6 },
	{ "Diamond", "mcl_core:diamond", "mcl_core:diamond", 4, 4 },
	{ "Lapis Lazuli", lapis_drops, "mcl_core:lapis", 3, 6 },
}

for _, p in pairs(deepslate_ores) do
	register_deepslate_ore(p[1], p[2], p[3], p[4], p[5])
end

if copper_mod then
	register_deepslate_ore("Copper", "mcl_copper:raw_copper", "mcl_copper:copper_ingot", 4, 4)
end

local redstone_timer = 68.28

local function redstone_ore_activate(pos, node, puncher, pointed_thing)
	minetest.swap_node(pos, { name = "mcl_deepslate:deepslate_with_redstone_lit" })
	local t = minetest.get_node_timer(pos)
	t:start(redstone_timer)
	if puncher and pointed_thing then
		return minetest.node_punch(pos, node, puncher, pointed_thing)
	end
end

local function redstone_ore_reactivate(pos, node, puncher, pointed_thing)
	local t = minetest.get_node_timer(pos)
	t:start(redstone_timer)
	if puncher and pointed_thing then
		return minetest.node_punch(pos, node, puncher, pointed_thing)
	end
end

minetest.register_node("mcl_deepslate:deepslate_with_redstone", {
	description = S("Deepslate Redstone Ore"),
	_doc_items_longdesc = S("Deepslate redstone ore is a variant of redstone ore that can generate in deepslate and tuff blobs."),
	tiles = { "mcl_deepslate_redstone_ore.png" },
	is_ground_content = true,
	groups = { pickaxey = 4, building_block = 1, material_stone = 1, xp = 7 },
	drop = {
		items = {
			max_items = 1,
			{ items = { "mesecons:redstone 4" }, rarity = 2 },
			{ items = { "mesecons:redstone 5" } },
		}
	},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_punch = redstone_ore_activate,
	on_walk_over = redstone_ore_activate,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 4.5,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = {
		discrete_uniform_distribution = true,
		items = { "mesecons:redstone" },
		min_count = 4,
		max_count = 5,
	}
})

minetest.register_node("mcl_deepslate:deepslate_with_redstone_lit", {
	description = S("Lit Deepslate Redstone Ore"),
	_doc_items_create_entry = false,
	tiles = { "mcl_deepslate_redstone_ore.png" },
	paramtype = "light",
	light_source = 9,
	is_ground_content = true,
	groups = { pickaxey = 4, not_in_creative_inventory = 1, material_stone = 1, xp = 7 },
	drop = {
		items = {
			max_items = 1,
			{ items = { "mesecons:redstone 4" }, rarity = 2 },
			{ items = { "mesecons:redstone 5" } },
		}
	},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_punch = redstone_ore_reactivate,
	on_walk_over = redstone_ore_reactivate, -- Uses walkover mod
	on_timer = function(pos, _)
		minetest.swap_node(pos, { name = "mcl_deepslate:deepslate_with_redstone" })
	end,
	_mcl_blast_resistance = 3,
	_mcl_hardness = 4.5,
	_mcl_silk_touch_drop = { "mcl_deepslate:deepslate_with_redstone" },
	_mcl_fortune_drop = {
		discrete_uniform_distribution = true,
		items = { "mesecons:redstone" },
		min_count = 4,
		max_count = 5,
	},
})

local function register_deepslate_variant(item, desc, longdesc)
	local texture = desc:lower():gsub("% ", "_")
	local def = {
		description = S(desc),
		_doc_items_longdesc = S(longdesc),
		_doc_items_hidden = false,
		tiles = { "mcl_"..texture..".png" },
		groups = { pickaxey = 1, building_block = 1, material_stone = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3.5,
		_mcl_silk_touch_drop = true,
	}
	if item == "cobbled" then
		def.groups.cobble = 1
	end
	minetest.register_node("mcl_deepslate:deepslate_"..item, table.copy(def))

	if item == "bricks" or item == "tiles" then
		def.description = S("Cracked "..desc)
		def._doc_items_longdesc = S("Cracked "..desc:lower().." are a cracked variant.")
		def.tiles = { "mcl_cracked_"..texture..".png" }
		minetest.register_node("mcl_deepslate:deepslate_"..item.."_cracked", def)
	end
	if item ~= "chiseled" then
		mcl_stairs.register_stair_and_slab_simple("deepslate_"..item, "mcl_deepslate:deepslate_"..item, S(desc.." Stairs"), S(desc.." Slab"), S("Double "..desc.." Slab"))
		mcl_walls.register_wall(
			"mcl_deepslate:deepslate"..item.."wall",
			S(desc.." Wall"),
			"mcl_deepslate:deepslate_"..item)
	end
end

local deepslate_variants = {
	{ "cobbled", "Cobbled Deepslate", "Cobbled deepslate is a stone variant that functions similar to cobblestone or blackstone." },
	{ "polished", "Polished Deepslate", "Polished deepslate is the stone-like polished version of deepslate." },
	{ "bricks", "Deepslate Bricks", "Deepslate bricks are the brick version of deepslate." },
	{ "tiles", "Deepslate Tiles", "Deepslate tiles are a decorative variant of deepslate." },
	{ "chiseled", "Chiseled Deepslate", "Chiseled deepslate is the chiseled version of deepslate." },
}

for _, dv in pairs(deepslate_variants) do
	register_deepslate_variant(dv[1], dv[2], dv[3])
end

for i = 1, 3 do
	local s = "mcl_deepslate:deepslate_"..deepslate_variants[i][1]
	minetest.register_craft({
		output = "mcl_deepslate:deepslate_"..deepslate_variants[i+1][1].." 4",
		recipe = { { s, s }, { s, s } }
	})
	mcl_stonecutter.register_recipe(
		"mcl_deepslate:deepslate_"..deepslate_variants[i][1],
		"mcl_deepslate:deepslate_"..deepslate_variants[i+1][1]
	)
end

for _, p in pairs({ "bricks", "tiles" }) do
	minetest.register_craft({
		type = "cooking",
		output = "mcl_deepslate:deepslate_"..p.."_cracked",
		recipe = "mcl_deepslate:deepslate_"..p,
		cooktime = 10,
	})
end

minetest.register_craft({
	type = "cooking",
	output = "mesecons:redstone",
	recipe = "mcl_deepslate:deepslate_with_redstone",
	cooktime = 10,
})

minetest.register_craft({
	type = "cooking",
	output = "mcl_deepslate:deepslate",
	recipe = cobble,
	cooktime = 10,
})

minetest.register_craft({
	output = "mcl_deepslate:deepslate_chiseled",
	recipe = {
		{ "mcl_stairs:slab_deepslate_cobbled" },
		{ "mcl_stairs:slab_deepslate_cobbled" },
	},
})

mcl_stonecutter.register_recipe("mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate_chiseled")
