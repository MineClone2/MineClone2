local S = minetest.get_translator(minetest.get_current_modname())
local doc_mod = minetest.get_modpath("doc")


local barks = {
	{ "", S("Oak Bark Stairs"), S("Oak Bark Slab"), S("Double Oak Bark Slab") },
	{ "jungle", S("Jungle Bark Stairs"), S("Jungle Bark Slab"), S("Double Jungle Bark Slab") },
	{ "acacia", S("Acacia Bark Stairs"), S("Acacia Bark Slab"), S("Double Acacia Bark Slab") },
	{ "spruce", S("Spruce Bark Stairs"), S("Spruce Bark Slab"), S("Double Spruce Bark Slab") },
	{ "birch", S("Birch Bark Stairs"), S("Birch Bark Slab"), S("Double Birch Bark Slab") },
	{ "dark", S("Dark Oak Bark Stairs"), S("Dark Oak Bark Slab"), S("Double Dark Oak Bark Slab") },
}

for b=1, #barks do
	local bark = barks[b]
	local sub = bark[1].."tree_bark"
	local id = "mcl_core:tree"
	if bark[1] ~= "" then
		id = "mcl_core:"..bark[1].."tree"
	end
	mcl_stairs.register_stair(sub, id,
			{handy=1,axey=1, flammable=3, bark_stairs=1, material_wood=1, fire_encouragement=5, fire_flammability=5},
			{minetest.registered_nodes[id].tiles[3]},
			bark[2],
			mcl_sounds.node_sound_wood_defaults(), nil, nil,
			"woodlike")
	mcl_stairs.register_slab(sub, id,
			{handy=1,axey=1, flammable=3, bark_slab=1, material_wood=1, fire_encouragement=5, fire_flammability=5},
			{minetest.registered_nodes[id].tiles[3]},
			bark[3],
			mcl_sounds.node_sound_wood_defaults(), nil, nil,
			bark[4])
end

mcl_stairs.register_slab("lapisblock", "mcl_core:lapisblock",
		{pickaxey=3},
		{"mcl_core_lapis_block.png", "mcl_core_lapis_block.png", "mcl_stairs_lapis_block_slab.png"},
		S("Lapis Lazuli Slab"),
		nil, nil, nil,
		S("Double Lapis Lazuli Slab"))
mcl_stairs.register_stair("lapisblock", "mcl_core:lapisblock",
		{pickaxey=3},
		{"mcl_stairs_lapis_block_slab.png", "mcl_core_lapis_block.png", "mcl_core_lapis_block.png", "mcl_core_lapis_block.png", "mcl_core_lapis_block.png", "mcl_stairs_lapis_block_slab.png"},
		S("Lapis Lazuli Stairs"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_slab("goldblock", "mcl_core:goldblock",
		{pickaxey=4},
		{"default_gold_block.png", "default_gold_block.png", "mcl_stairs_gold_block_slab.png"},
		S("Slab of Gold"),
		nil, nil, nil,
		S("Double Slab of Gold"))
mcl_stairs.register_stair("goldblock", "mcl_core:goldblock",
		{pickaxey=4},
		{"mcl_stairs_gold_block_slab.png", "default_gold_block.png", "default_gold_block.png", "default_gold_block.png", "default_gold_block.png", "mcl_stairs_gold_block_slab.png"},
		S("Stairs of Gold"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_slab("ironblock", "mcl_core:ironblock",
		{pickaxey=2},
		{"default_steel_block.png", "default_steel_block.png", "mcl_stairs_iron_block_slab.png"},
		S("Slab of Iron"),
		nil, nil, nil,
		S("Double Slab of Iron"))
mcl_stairs.register_stair("ironblock", "mcl_core:ironblock",
		{pickaxey=2},
		{"mcl_stairs_iron_block_slab.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "mcl_stairs_iron_block_slab.png"},
		S("Stairs of Iron"),
		nil, nil, nil,
		"woodlike")

mcl_stairs.register_stair("stonebrickcracked", "mcl_core:stonebrickcracked",
		{pickaxey=1},
		{"mcl_core_stonebrick_cracked.png"},
		S("Cracked Stone Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		"woodlike")

mcl_stairs.register_slab("stonebrickcracked", "mcl_core:stonebrickcracked",
		{pickaxey=1},
		{"mcl_core_stonebrick_cracked.png"},
		S("Cracked Stone Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), nil, nil,
		S("Double Cracked Stone Brick Slab"))

local block = {}
block.dyes = {
	{"white",      S("White Concrete Stairs"),      S("White Concrete Slab"), S("Double White Concrete Slab"), "white"},
	{"grey",       S("Grey Concrete Stairs"),       S("Grey Concrete Slab"), S("Double Grey Concrete Slab"), "dark_grey"},
	{"silver",     S("Light Grey Concrete Stairs"), S("Light Grey Concrete Slab"), S("Double Light Grey Concrete Slab"), "grey"},
	{"black",      S("Black Concrete Stairs"),      S("Black Concrete Slab"), S("Double Black Concrete Slab"), "black"},
	{"red",        S("Red Concrete Stairs"),        S("Red Concrete Slab"), S("Double Red Concrete Slab"), "red"},
	{"yellow",     S("Yellow Concrete Stairs"),     S("Yellow Concrete Slab"), S("Double Yellow Concrete Slab"), "yellow"},
	{"green",      S("Green Concrete Stairs"),      S("Green Concrete Slab"), S("Double Green Concrete Slab"), "dark_green"},
	{"cyan",       S("Cyan Concrete Stairs"),       S("Cyan Concrete Slab"), S("Double Cyan Concrete Slab"), "cyan"},
	{"blue",       S("Blue Concrete Stairs"),       S("Blue Concrete Slab"), S("Double Blue Concrete Slab"), "blue"},
	{"magenta",    S("Magenta Concrete Stairs"),    S("Magenta Concrete Slab"), S("Double Magenta Concrete Slab"), "magenta"},
	{"orange",     S("Orange Concrete Stairs"),     S("Orange Concrete Slab"), S("Double Orange Concrete Slab"), "orange"},
	{"purple",     S("Purple Concrete Stairs"),     S("Purple Concrete Slab"), S("Double Purple Concrete Slab"), "violet"},
	{"brown",      S("Brown Concrete Stairs"),      S("Brown Concrete Slab"), S("Double Brown Concrete Slab"), "brown"},
	{"pink",       S("Pink Concrete Stairs"),       S("Pink Concrete Slab"), S("Double Pink Concrete Slab"), "pink"},
	{"lime",       S("Lime Concrete Stairs"),       S("Lime Concrete Slab"), S("Double Lime Concrete Slab"), "green"},
	{"light_blue", S("Light Blue Concrete Stairs"), S("Light Blue Concrete Slab"), S("Double Light Blue Concrete Slab"), "lightblue"},
}
local canonical_color = "yellow"

for i=1, #block.dyes do
	local c = block.dyes[i][1]
	local is_canonical = c == canonical_color
	mcl_stairs.register_stair_and_slab_simple("concrete_"..c, "mcl_colorblocks:concrete_"..c,
		block.dyes[i][2],
		block.dyes[i][3],
		block.dyes[i][4])

	if doc_mod then
		if not is_canonical then
			doc.add_entry_alias("nodes", "mcl_stairs:slab_concrete_"..canonical_color, "nodes", "mcl_stairs:slab_concrete_"..c)
			doc.add_entry_alias("nodes", "mcl_stairs:slab_concrete_"..canonical_color.."_double", "nodes", "mcl_stairs:slab_concrete_"..c.."_double")
			doc.add_entry_alias("nodes", "mcl_stairs:stair_concrete_"..canonical_color, "nodes", "mcl_stairs:stair_concrete_"..c)
			minetest.override_item("mcl_stairs:slab_concrete_"..c, { _doc_items_create_entry = false })
			minetest.override_item("mcl_stairs:slab_concrete_"..c.."_double", { _doc_items_create_entry = false })
			minetest.override_item("mcl_stairs:stair_concrete_"..c, { _doc_items_create_entry = false })
		else
			minetest.override_item("mcl_stairs:slab_concrete_"..c, { _doc_items_entry_name = S("Concrete Slab") })
			minetest.override_item("mcl_stairs:slab_concrete_"..c.."_double", { _doc_items_entry_name = S("Double Concrete Slab") })
			minetest.override_item("mcl_stairs:stair_concrete_"..c, { _doc_items_entry_name = S("Concrete Stairs") })
		end
	end
end

-- Fuel
minetest.register_craft({
	type = "fuel",
	recipe = "group:bark_stairs",
	-- Same as wood stairs
	burntime = 15,
})
minetest.register_craft({
	type = "fuel",
	recipe = "group:bark_slab",
	-- Same as wood slab
	burntime = 8,
})
