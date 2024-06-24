--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

--###################
--################### SPIDER
--###################


-- Spider by AspireMint (fishyWET (CC-BY-SA 3.0 license for texture)
minetest.register_entity("mobs_mc:spider_eyes", {
	pointable = false,
	visual = "mesh",
	mesh = "mobs_mc_spider.b3d",
	visual_size = {x=1.01/3, y=1.01/3},
	textures = {
		"mobs_mc_spider_eyes.png",
	},
	on_step = function(self)
		if self and self.object then
			if not self.object:get_attach() then
				self.object:remove()
			end
		end
	end,
	glow = 50,
})

local spider = {
	description = S("Spider"),
	type = "monster",
	spawn_class = "hostile",
	passive = false,
	docile_by_day = true,
	attack_type = "dogfight",
	pathfinding = 1,
	damage = 2,
	reach = 2,
	hp_min = 16,
	hp_max = 16,
	xp_min = 5,
	xp_max = 5,
	armor = {fleshy = 100, arthropod = 100},
	on_spawn = function(self)
		self.object:set_properties({visual_size={x=1,y=1}})
		local spider_eyes=false
		for n = 1, #self.object:get_children() do
			local obj = self.object:get_children()[n]
			if obj:get_luaentity() and self.object:get_luaentity().name == "mobs_mc:spider_eyes" then
				spider_eyes = true
			end
		end
		if not spider_eyes then
			minetest.add_entity(self.object:get_pos(), "mobs_mc:spider_eyes"):set_attach(self.object, "body.head", vector.new(0,-0.98,2), vector.new(90,180,180))
		end
	end,
	on_die=function(self)
		if self.object:get_children() and self.object:get_children()[1] then
			self.object:get_children()[1]:set_detach()
		end
	end,
	head_swivel = "Head_Control",
	bone_eye_height = 1,
	curiosity = 10,
	head_yaw="z",
	collisionbox = {-0.7, -0.01, -0.7, 0.7, 0.89, 0.7},
	spawnbox = {-1.2, -0.01, -1.2, 1.2, 0.89, 1.2},
	visual = "mesh",
	mesh = "mobs_mc_spider.b3d",
	textures = {
		{"mobs_mc_spider.png"},
	},
	visual_size = {x=1, y=1},
	makes_footstep_sound = false,
	sounds = {
		random = "mobs_mc_spider_random",
		attack = "mobs_mc_spider_attack",
		damage = "mobs_mc_spider_hurt",
		death = "mobs_mc_spider_death",
		-- TODO: sounds: walk
		distance = 16,
	},
	walk_velocity = 1.3,
	run_velocity = 2.4,
	jump = true,
	jump_height = 4,
	view_range = 16,
	floats = 1,
	drops = {
		{name = "mcl_mobitems:string", chance = 1, min = 0, max = 2, looting = "common"},
		{name = "mcl_mobitems:spider_eye", chance = 3, min = 1, max = 1, looting = "common", looting_chance_function = function(lvl)
			return 1 - 2 / (lvl + 3)
		end},
	},
	specific_attack = { "player", "mobs_mc:iron_golem" },
	fear_height = 4,
	animation = {
		stand_speed = 10,
		walk_speed = 25,
		run_speed = 50,
		stand_start = 20,
		stand_end = 40,
		walk_start = 0,
		walk_end = 20,
		run_start = 0,
		run_end = 20,
	},
}
mcl_mobs.register_mob("mobs_mc:spider", spider)

-- Cave spider
local cave_spider = table.copy(spider)
cave_spider.description = S("Cave Spider")
cave_spider.textures = { {"mobs_mc_cave_spider.png^(mobs_mc_spider_eyes.png^[makealpha:0,0,0)"} }
cave_spider.damage = 2
cave_spider.hp_min = 1
cave_spider.hp_max = 12
cave_spider.collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.46, 0.35}
cave_spider.visual_size = {x=0.55,y=0.5}
cave_spider.on_spawn = function(self)
	self.object:set_properties({visual_size={x=0.55,y=0.5}})
	local spider_eyes=false
	for n = 1, #self.object:get_children() do
		local obj = self.object:get_children()[n]
		if obj:get_luaentity() and self.object:get_luaentity().name == "mobs_mc:spider_eyes" then
			spider_eyes = true
		end
	end
	if not spider_eyes then
		minetest.add_entity(self.object:get_pos(), "mobs_mc:spider_eyes"):set_attach(self.object, "body.head", vector.new(0,-0.98,2), vector.new(90,180,180))
	end
end
cave_spider.walk_velocity = 1.3
cave_spider.run_velocity = 3.2
cave_spider.sounds = table.copy(spider.sounds)
cave_spider.sounds.base_pitch = 1.25
cave_spider.dealt_effect = {
	name = "poison",
	level = 2,
	dur = 7,
}
mcl_mobs.register_mob("mobs_mc:cave_spider", cave_spider)


mcl_mobs:spawn_specific(
"mobs_mc:spider",
"overworld",
"ground",
{
"Mesa",
"FlowerForest",
"Swampland",
"Taiga",
"ExtremeHills",
"Jungle",
"Savanna",
"BirchForest",
"MegaSpruceTaiga",
"MegaTaiga",
"ExtremeHills+",
"Forest",
"Plains",
"Desert",
"ColdTaiga",
"IcePlainsSpikes",
"SunflowerPlains",
"IcePlains",
"RoofedForest",
"ExtremeHills+_snowtop",
"MesaPlateauFM_grasstop",
"JungleEdgeM",
"ExtremeHillsM",
"JungleM",
"BirchForestM",
"MesaPlateauF",
"MesaPlateauFM",
"MesaPlateauF_grasstop",
"MesaBryce",
"JungleEdge",
"SavannaM",
"FlowerForest_beach",
"Forest_beach",
"StoneBeach",
"ColdTaiga_beach_water",
"Taiga_beach",
"Savanna_beach",
"Plains_beach",
"ExtremeHills_beach",
"ColdTaiga_beach",
"Swampland_shore",
"JungleM_shore",
"Jungle_shore",
"MesaPlateauFM_sandlevel",
"MesaPlateauF_sandlevel",
"MesaBryce_sandlevel",
"Mesa_sandlevel",
"RoofedForest_ocean",
"JungleEdgeM_ocean",
"BirchForestM_ocean",
"BirchForest_ocean",
"IcePlains_deep_ocean",
"Jungle_deep_ocean",
"Savanna_ocean",
"MesaPlateauF_ocean",
"ExtremeHillsM_deep_ocean",
"Savanna_deep_ocean",
"SunflowerPlains_ocean",
"Swampland_deep_ocean",
"Swampland_ocean",
"MegaSpruceTaiga_deep_ocean",
"ExtremeHillsM_ocean",
"JungleEdgeM_deep_ocean",
"SunflowerPlains_deep_ocean",
"BirchForest_deep_ocean",
"IcePlainsSpikes_ocean",
"Mesa_ocean",
"StoneBeach_ocean",
"Plains_deep_ocean",
"JungleEdge_deep_ocean",
"SavannaM_deep_ocean",
"Desert_deep_ocean",
"Mesa_deep_ocean",
"ColdTaiga_deep_ocean",
"Plains_ocean",
"MesaPlateauFM_ocean",
"Forest_deep_ocean",
"JungleM_deep_ocean",
"FlowerForest_deep_ocean",
"MegaTaiga_ocean",
"StoneBeach_deep_ocean",
"IcePlainsSpikes_deep_ocean",
"ColdTaiga_ocean",
"SavannaM_ocean",
"MesaPlateauF_deep_ocean",
"MesaBryce_deep_ocean",
"ExtremeHills+_deep_ocean",
"ExtremeHills_ocean",
"Forest_ocean",
"MegaTaiga_deep_ocean",
"JungleEdge_ocean",
"MesaBryce_ocean",
"MegaSpruceTaiga_ocean",
"ExtremeHills+_ocean",
"Jungle_ocean",
"RoofedForest_deep_ocean",
"IcePlains_ocean",
"FlowerForest_ocean",
"ExtremeHills_deep_ocean",
"MesaPlateauFM_deep_ocean",
"Desert_ocean",
"Taiga_ocean",
"BirchForestM_deep_ocean",
"Taiga_deep_ocean",
"JungleM_ocean",
"FlowerForest_underground",
"JungleEdge_underground",
"StoneBeach_underground",
"MesaBryce_underground",
"Mesa_underground",
"RoofedForest_underground",
"Jungle_underground",
"Swampland_underground",
"BirchForest_underground",
"Plains_underground",
"MesaPlateauF_underground",
"ExtremeHills_underground",
"MegaSpruceTaiga_underground",
"BirchForestM_underground",
"SavannaM_underground",
"MesaPlateauFM_underground",
"Desert_underground",
"Savanna_underground",
"Forest_underground",
"SunflowerPlains_underground",
"ColdTaiga_underground",
"IcePlains_underground",
"IcePlainsSpikes_underground",
"MegaTaiga_underground",
"Taiga_underground",
"ExtremeHills+_underground",
"JungleM_underground",
"ExtremeHillsM_underground",
"JungleEdgeM_underground",
},
0,
7,
30,
1000,
2,
mcl_vars.mg_overworld_min,
mcl_vars.mg_overworld_max)

mcl_mobs:non_spawn_specific("mobs_mc:cave_spider","overworld",0,7)

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:spider", S("Spider"), "#342d26", "#a80e0e", 0)
mcl_mobs.register_egg("mobs_mc:cave_spider", S("Cave Spider"), "#0c424e", "#a80e0e", 0)
