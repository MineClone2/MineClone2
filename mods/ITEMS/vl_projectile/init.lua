local mod = {}
vl_projectile = mod

local GRAVITY = tonumber(minetest.settings:get("movement_gravity"))

function mod.update_projectile(self, dtime)
	local entity_name = self.name
	local entity_def = minetest.registered_entities[entity_name] or {}
	local entity_vl_projectile = entity_def._vl_projectile or {}

	-- Update entity timer
	self.timer = (self.timer or 0) + dtime

	-- Run behaviors
	local behaviors = entity_vl_projectile.behaviors or {}
	for i=1,#behaviors do
		local behavior = behaviors[i]
		if behavior(self, dtime, entity_def, entity_vl_projectile) then
			return
		end
	end
end

local function no_op()
end

local enable_pvp = minetest.settings:get_bool("enable_pvp")
local function check_hitpoint(hitpoint)
	if hitpoint.type ~= "object" then return false end

	-- find the closest object that is in the way of the arrow
	if hitpoint.ref:is_player() and enable_pvp then
		return true
	end

	if not hitpoint.ref:is_player() and hitpoint.ref:get_luaentity() then
		if (hitpoint.ref:get_luaentity().is_mob or hitpoint.ref:get_luaentity()._hittable_by_projectile) then
			return true
		end
	end

	return false
end

function mod.collides_with_solids(self, dtime, entity_def, projectile_def)
	local pos = self.object:get_pos()

	-- Don't try to do anything on first update
	if not self._last_pos then
		self._last_pos = pos
		return
	end

	-- Check if the object can collide with this node
	local node = minetest.get_node(pos)
	local node_def = minetest.registered_nodes[node.name]
	local collides_with = projectile_def.collides_with

	if entity_def.physical then
		-- Projectile has stopped in one axis, so it probably hit something.
		-- This detection is a bit clunky, but sadly, MT does not offer a direct collision detection for us. :-(
		local vel = self.object:get_velocity()
		if not( (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) ) then
			self._last_pos = pos
			return
		end
	else
		if node_def and not node_def.walkable and (not collides_with or not mcl_util.match_node_to_filter(node.name, collides_with)) then
			self._last_pos = pos
			return
		end
	end

	-- Call entity collied hook
	local hook = projectile_def.on_collide_with_solid or no_op
	hook(self, pos, node, node_def)

	-- Call node collided hook
	local hook = (node_def._vl_projectile or {}).on_collide or no_op
	hook(self, pos, node, node_def)

	-- Play sounds
	local sounds = projectile_def.sounds or {}
	local sound = sounds.on_solid_collision or sounds.on_collision
	if sound then
		local arg2 = table.copy(sound[2])
		arg2.pos = pos
		minetest.sound_play(sound[1], arg2, sound[3])
	end

	-- Normally objects should be removed on collision with solids
	if not projectile_def.survive_collision then
		self.object:remove()
	end

	-- Done with behaviors
	return true
end

local function handle_entity_collision(self, entity_def, projectile_def, entity)
	local pos = self.object:get_pos()
	local dir = vector.normalize(self.object:get_velocity())
	local self_vl_projectile = self._vl_projectile

	if entity:is_player() and projectile_def.hits_players and self_vl_projectile.owner ~= hit:get_player_name() then
		entity:punch(self.object, 1.0, projectile_def.tool or { full_punch_interval = 1.0, damage_groups = dmg }, dir )
	elseif (entity.is_mob == true or entity._hittable_by_projectile) and (self_vl_projectile.owner ~= entity) then
		entity:punch(self.object, 1.0, projectile_def.tool or { full_punch_interval = 1.0, damage_groups = dmg }, dir )
	end

	-- Call entity collied hook
	(projectile_def.on_collide_with_entity or no_op)(self, pos, entity)

	-- Call entity reverse hook
	local other_entity_def = minetest.registered_entities[entity.name] or {}
	local other_entity_vl_projectile = other_entity_def._vl_projectile or {}
	local hook = (other_entity_vl_projectile or {}).on_collide or no_op
	hook(entity, self)

	-- Play sounds
	local sounds = (projectile_def.sounds or {})
	local sound = sounds.on_entity_collide or sounds.on_collision
	if on_collide_sound then
		local arg2 = table.copy(sound[2])
		arg2.pos = pos
		minetest.sound_play(sound[1], arg2, sound[3])
	end

	-- Normally objects should be removed on collision with entities
	if not projectile_def.survive_collision then
		self.object:remove()
	end

	return true
end

function mod.collides_with_entities(self, dtime, entity_def, projectile_def)
	local pos = self.object:get_pos()
	local dmg = projectile_def.damage_groups or 0

	local hit = nil
	local owner = self._vl_projectile.owner

	local objects = minetest.get_objects_inside_radius(pos, 1.5)
	for i = 1,#objects do
		local object = objects[i]
		local entity = object:get_luaentity()

		if entity and entity.name ~= self.object:get_luaentity().name then
			if object:is_player() and owner ~= object:get_player_name() then
				return handle_entity_collision(self, entity_def, projectile_def, object)
			elseif (entity.is_mob == true or entity._hittable_by_projectile) and (owner ~= object) then
				return handle_entity_collision(self, entity_def, projectile_def, object)
			end
		end
	end
end

function mod.raycast_collides_with_entities(self, dtime, entity_def, projectile_def)
	local closest_object
	local closest_distance

	local pos = self.object:get_pos()
	local arrow_dir = self.object:get_velocity()

	--create a raycast from the arrow based on the velocity of the arrow to deal with lag
	local raycast = minetest.raycast(pos, vector.add(pos, vector.multiply(arrow_dir, 0.1)), true, false)
	for hitpoint in raycast do
		if check_hitpoint(hitpoint) then
			local hitpoint_ref = hitpoint.ref
			local dist = vector.distance(hitpoint_ref:get_pos(), pos)
			if not closest_distance or dist < closest_distance then
				closest_object = hitpoint_ref
				closest_distance = dist
			end
		end

	end

	if closest_object then
		return handle_entity_collision(self, entity_def, projectile_def, closest_object)
	end
end

function mod.create(entity_id, options)
	local obj = minetest.add_entity(options.pos, entity_id, options.staticdata)

	-- Set initial velocoty and acceleration
	obj:set_velocity(vector.multiply(options.dir or vector.zero(), options.velocity or 0))
	obj:set_acceleration(vector.add(
		vector.multiply(options.dir or vector.zero(), -math.abs(options.drag)),
		vector.new(0,-GRAVITY,0)
	))

	-- Update projectile parameters
	local luaentity = obj:get_luaentity()
	luaentity._vl_projectile = {
		owner = options.owner,
		extra = options.extra,
	}

	-- Make the update function easy to get to
	luaentity.update_projectile = mod.update_projectile

	-- And provide the caller with the created object
	return obj
end

function mod.register(name, def)
	assert(def._vl_projectile)

	if not def.on_step then
		def.on_step = mod.update_projectile
	end

	def._thrower = nil
	def._shooter = nil
	def._last_pos = nil

	minetest.register_entity(name, def)
end

