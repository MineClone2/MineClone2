local S = minetest.get_translator(minetest.get_current_modname())
local doc_mod = minetest.get_modpath("doc")

local block = {}

block.dyes = {
	{"white",      S("White Terracotta"),      S("White Glazed Terracotta"),	S("White Glazed Terracotta Pillar"),	S("White Concrete Powder"),		S("White Concrete"),		"white"},
	{"grey",       S("Grey Terracotta"),       S("Grey Glazed Terracotta"),		S("Grey Glazed Terracotta Pillar"),		S("Grey Concrete Powder"),		S("Grey Concrete"),		"dark_grey"},
	{"silver",     S("Light Grey Terracotta"), S("Light Grey Glazed Terracotta"),	S("Light Grey Glazed Terracotta Pillar"),	S("Light Grey Concrete Powder"),	S("Light Grey Concrete"),	"grey"},
	{"black",      S("Black Terracotta"),      S("Black Glazed Terracotta"),	S("Black Glazed Terracotta Pillar"),	S("Black Concrete Powder"),		S("Black Concrete"),		"black"},
	{"red",        S("Red Terracotta"),        S("Red Glazed Terracotta"),		S("Red Glazed Terracotta Pillar"),		S("Red Concrete Powder"),		S("Red Concrete"),		"red"},
	{"yellow",     S("Yellow Terracotta"),     S("Yellow Glazed Terracotta"),	S("Yellow Glazed Terracotta Pillar"),	S("Yellow Concrete Powder"),		S("Yellow Concrete"),		"yellow"},
	{"green",      S("Green Terracotta"),      S("Green Glazed Terracotta"),	S("Green Glazed Terracotta Pillar"),	S("Green Concrete Powder"),		S("Green Concrete"),		"dark_green"},
	{"cyan",       S("Cyan Terracotta"),       S("Cyan Glazed Terracotta"),		S("Cyan Glazed Terracotta Pillar"),		S("Cyan Concrete Powder"),		S("Cyan Concrete"),		"cyan"},
	{"blue",       S("Blue Terracotta"),       S("Blue Glazed Terracotta"),		S("Blue Glazed Terracotta Pillar"),		S("Blue Concrete Powder"),		S("Blue Concrete"),		"blue"},
	{"magenta",    S("Magenta Terracotta"),    S("Magenta Glazed Terracotta"),	S("Magenta Glazed Terracotta Pillar"),	S("Magenta Concrete Powder"),		S("Magenta Concrete"),		"magenta"},
	{"orange",     S("Orange Terracotta"),     S("Orange Glazed Terracotta"),	S("Orange Glazed Terracotta Pillar"),	S("Orange Concrete Powder"),		S("Orange Concrete"),		"orange"},
	{"purple",     S("Purple Terracotta"),     S("Purple Glazed Terracotta"),	S("Purple Glazed Terracotta Pillar"),	S("Purple Concrete Powder"),		S("Purple Concrete"),		"violet"},
	{"brown",      S("Brown Terracotta"),      S("Brown Glazed Terracotta"),	S("Brown Glazed Terracotta Pillar"),	S("Brown Concrete Powder"),		S("Brown Concrete"),		"brown"},
	{"pink",       S("Pink Terracotta"),       S("Pink Glazed Terracotta"),		S("Pink Glazed Terracotta Pillar"),		S("Pink Concrete Powder"),		S("Pink Concrete"),		"pink"},
	{"lime",       S("Lime Terracotta"),       S("Lime Glazed Terracotta"),		S("Lime Glazed Terracotta Pillar"),		S("Lime Concrete Powder"),		S("Lime Concrete"),		"green"},
	{"light_blue", S("Light Blue Terracotta"), S("Light Blue Glazed Terracotta"),	S("Light Blue Glazed Terracotta Pillar"),	S("Light Blue Concrete Powder"),	S("Light Blue Concrete"),	"lightblue"},
}
local canonical_color = "yellow"

local hc_desc = S("Terracotta is a basic building material. It comes in many different colors.")
local gt_desc = S("Glazed terracotta is a decorative block with a complex pattern. It can be rotated by placing it in different directions.")
local gtp_desc = S("Glazed terracotta pillar is a decorative block with a complex pattern. It can be used with Glazed terracotta to make uneven patterns.")
local cp_desc = S("Concrete powder is used for creating concrete, but it can also be used as decoration itself. It comes in different colors. Concrete powder turns into concrete of the same color when it comes in contact with water.")
local c_desc = S("Concrete is a decorative block which comes in many different colors. It is notable for having a very strong and clean color.")
local cp_tt = S("Turns into concrete on water contact")

minetest.register_node("mcl_colorblocks:hardened_clay", {
	description = S("Terracotta"),
	_doc_items_longdesc = S("Terracotta is a basic building material which comes in many different colors. This particular block is uncolored."),
	tiles = {"hardened_clay.png"},
	stack_max = 64,
	groups = {pickaxey=1, hardened_clay=1,building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 4.2,
	_mcl_hardness = 1.25,
})

minetest.register_craft({
	type = "cooking",
	output = "mcl_colorblocks:hardened_clay",
	recipe = "mcl_core:clay",
	cooktime = 10,
})

local on_rotate
if minetest.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

for _, row in ipairs(block.dyes) do
	local name = row[1]
	local is_canonical = name == canonical_color
	local sdesc_hc = row[2]
	local sdesc_gt = row[3]
	local sdesc_gtp = row[4]
	local sdesc_cp = row[5]
	local sdesc_c = row[6]
	local ldesc_hc, ldesc_gt, ldesc_cp, ldesc_c, ldesc_gtp
	local create_entry
	local ename_hc, ename_gt, ename_cp, ename_c, ename_gtp
	local ltt_cp = cp_tt
	if is_canonical then
		ldesc_hc = hc_desc
		ldesc_gt = gt_desc
		ldesc_gtp = gtp_desc
		ldesc_cp = cp_desc
		ldesc_c = c_desc
		ename_hc = S("Colored Terracotta")
		ename_gt = S("Glazed Terracotta")
		ename_gtp = S("Glazed Terracotta Pillar")
		ename_cp = S("Concrete Powder")
		ename_c = S("Concrete")
	else
		create_entry = false
	end
	local craft_color_group = row[7]
	-- Node Definition
	minetest.register_node("mcl_colorblocks:hardened_clay_"..name, {
		description = sdesc_hc,
		_doc_items_longdesc = ldesc_hc,
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = ename_hc,
		tiles = {"hardened_clay_stained_"..name..".png"},
		groups = {pickaxey=1, hardened_clay=1,building_block=1, material_stone=1},
		stack_max = 64,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 4.2,
		_mcl_hardness = 1.25,
	})

	minetest.register_node("mcl_colorblocks:concrete_powder_"..name, {
		description = sdesc_cp,
		_tt_help = ltt_cp,
		_doc_items_longdesc = ldesc_cp,
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = ename_cp,
		tiles = {"mcl_colorblocks_concrete_powder_"..name..".png"},
		groups = {handy=1,shovely=1, concrete_powder=1,building_block=1,falling_node=1, material_sand=1, float=1},
		stack_max = 64,
		is_ground_content = false,
		sounds = mcl_sounds.node_sound_sand_defaults(),
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			-- Call on_rightclick if the pointed node defines it
			local unode = minetest.get_node(pointed_thing.under)
			if placer and not placer:get_player_control().sneak then
				if minetest.registered_nodes[unode.name] and minetest.registered_nodes[unode.name].on_rightclick then
					return minetest.registered_nodes[unode.name].on_rightclick(pointed_thing.under, unode, placer, itemstack) or itemstack
				end
			end

			-- If placed in water, immediately harden this node
			local n = minetest.get_node(pointed_thing.above)
			local oldname = itemstack:get_name()
			if minetest.get_item_group(n.name, "water") ~= 0 then
				itemstack:set_name(itemstack:get_definition()._mcl_colorblocks_harden_to)
			end
			itemstack = minetest.item_place_node(itemstack, placer, pointed_thing)
			itemstack:set_name(oldname)
			return itemstack
		end,

		-- Specify the node to which this node will convert after getting in contact with water
		_mcl_colorblocks_harden_to = "mcl_colorblocks:concrete_"..name,
		_mcl_blast_resistance = 0.5,
		_mcl_hardness = 0.5,
	})

	minetest.register_node("mcl_colorblocks:concrete_"..name, {
		description = sdesc_c,
		_doc_items_longdesc = ldesc_c,
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = ename_c,
		tiles = {"mcl_colorblocks_concrete_"..name..".png"},
		groups = {handy=1,pickaxey=1, concrete=1,building_block=1, material_stone=1},
		stack_max = 64,
		is_ground_content = false,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 1.8,
		_mcl_hardness = 1.8,
	})

	local tex = "mcl_colorblocks_glazed_terracotta_"..name..".png"
	local texes = { tex, tex, tex.."^[transformR180", tex, tex.."^[transformR270", tex.."^[transformR90" }
	minetest.register_node("mcl_colorblocks:glazed_terracotta_"..name, {
		description = sdesc_gt,
		_doc_items_longdesc = ldesc_gt,
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = ename_gt,
		tiles = texes,
		groups = {handy=1,pickaxey=1, glazed_terracotta=1,building_block=1, material_stone=1},
		paramtype2 = "facedir",
		stack_max = 64,
		is_ground_content = false,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 1.4,
		_mcl_hardness = 1.4,
		on_rotate = on_rotate,
	})
	minetest.register_node("mcl_colorblocks:glazed_terracotta_pillar_"..name, {
		description = sdesc_gtp,
		_doc_items_longdesc = ldesc_gtp,
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = ename_gtp,
		tiles = {"mcl_colorblocks_glazed_terracotta_pillar_top_"..name..".png", "mcl_colorblocks_glazed_terracotta_pillar_top_"..name..".png", "mcl_colorblocks_glazed_terracotta_pillar_side_"..name..".png"},
		groups = {handy=1,pickaxey=1, glazed_terracotta=1,building_block=1, material_stone=1},
		paramtype2 = "facedir",
		stack_max = 64,
		is_ground_content = false,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 4.2,
		_mcl_hardness = 1.4,
		on_place = mcl_util.rotate_axis,
		on_rotate = on_rotate,
	})

	if not is_canonical and doc_mod then
		doc.add_entry_alias("nodes", "mcl_colorblocks:hardened_clay_"..canonical_color, "nodes", "mcl_colorblocks:hardened_clay_"..name)
		doc.add_entry_alias("nodes", "mcl_colorblocks:glazed_terracotta_"..canonical_color, "nodes", "mcl_colorblocks:glazed_terracotta_"..name)
		doc.add_entry_alias("nodes", "mcl_colorblocks:concrete_"..canonical_color, "nodes", "mcl_colorblocks:concrete_"..name)
		doc.add_entry_alias("nodes", "mcl_colorblocks:concrete_powder_"..canonical_color, "nodes", "mcl_colorblocks:concrete_powder_"..name)
	end

	-- Crafting recipes
	if craft_color_group then
		minetest.register_craft({
			output = "mcl_colorblocks:hardened_clay_"..name.." 8",
			recipe = {
					{"mcl_colorblocks:hardened_clay", "mcl_colorblocks:hardened_clay", "mcl_colorblocks:hardened_clay"},
					{"mcl_colorblocks:hardened_clay", "mcl_dye:"..craft_color_group, "mcl_colorblocks:hardened_clay"},
					{"mcl_colorblocks:hardened_clay", "mcl_colorblocks:hardened_clay", "mcl_colorblocks:hardened_clay"},
			},
		})
		minetest.register_craft({
			type = "shapeless",
			output = "mcl_colorblocks:concrete_powder_"..name.." 8",
			recipe = {
				"mcl_core:sand", "mcl_core:gravel", "mcl_core:sand",
				"mcl_core:gravel", "mcl_dye:"..craft_color_group, "mcl_core:gravel",
				"mcl_core:sand", "mcl_core:gravel", "mcl_core:sand",
			}
		})

		minetest.register_craft({
			type = "cooking",
			output = "mcl_colorblocks:glazed_terracotta_"..name,
			recipe = "mcl_colorblocks:hardened_clay_"..name,
			cooktime = 10,
		})

		minetest.register_craft({
			output = "mcl_colorblocks:glazed_terracotta_pillar_"..name.." 2",
			recipe = {
				{"mcl_colorblocks:glazed_terracotta_"..name},
				{"mcl_colorblocks:glazed_terracotta_"..name},
			}
		})

		mcl_stonecutter.register_recipe("mcl_colorblocks:glazed_terracotta_"..name, "mcl_colorblocks:glazed_terracotta_pillar_"..name)
	end
end

-- When water touches concrete powder, it turns into concrete of the same color
minetest.register_abm({
	label = "Concrete powder hardening",
	interval = 1,
	chance = 1,
	nodenames = {"group:concrete_powder"},
	neighbors = {"group:water"},
	action = function(pos, node)
		local harden_to = minetest.registered_nodes[node.name]._mcl_colorblocks_harden_to
               -- It should be impossible for harden_to to be nil, but a Minetest bug might call
               -- the ABM on the new concrete node, which isn't part of this ABM!
        if harden_to then
            node.name = harden_to
			--Fix "float" group not lowering concrete into the water by 1.
			local water_pos = { x = pos.x, y = pos.y-1, z = pos.z }
			local water_node = minetest.get_node(water_pos)
			if minetest.get_item_group(water_node.name, "water") == 0 then
				minetest.set_node(pos, node)
			else
				minetest.set_node(water_pos,node)
				minetest.set_node(pos, {name = "air"})
				minetest.check_for_falling(pos) -- Update C. Powder that stacked above so they fall down after setting air.
			end
        end
	end,
})
