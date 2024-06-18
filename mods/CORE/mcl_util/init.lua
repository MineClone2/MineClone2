mcl_util = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
dofile(modpath.."/roman_numerals.lua")

-- Updates all values in t using values from to*.
function table.update(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from to*.
function table.update_nil(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

---Works the same as `pairs`, but order returned by keys
---
---Taken from https://www.lua.org/pil/19.3.html
---@generic T: table, K, V, C
---@param t T
---@param f? fun(a: C, b: C):boolean
---@return fun():K, V
function table.pairs_by_keys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)

	local i = 0        -- iterator variable
	local function iter() -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

local LOGGING_ON = minetest.settings:get_bool("mcl_logging_default", false)
local LOG_MODULE = "[MCL2]"
function mcl_util.mcl_log(message, module, bypass_default_logger)
	local selected_module = LOG_MODULE
	if module then
		selected_module = module
	end
	if (bypass_default_logger or LOGGING_ON) and message then
		minetest.log(selected_module .. " " .. message)
	end
end

local player_timers = {}

-- This is a dtime timer than can be used in on_step functions so it works every x seconds
-- self - Object you want to store timer data on. E.g. mob or a minecart, or player_name
-- dtime - The time since last run of on_step, should be passed in to function
-- timer_name - This is the name of the timer and also the key to store the data. No spaces + lowercase.
-- threshold - The time before it returns successful. 0.2 if you want to run it 5 times a second.
function mcl_util.check_dtime_timer(self, dtime, timer_name, threshold)
	if not self or not threshold or not dtime then return end
	if not timer_name or timer_name == "" then return end

	if type(self) == "string" then
		local player_name = self
		if not player_timers[player_name] then
			player_timers[player_name] = {}
		end
		self = player_timers[player_name]
	end

	if not self._timers then
		self._timers = {}
	end

	if not self._timers[timer_name] then
		self._timers[timer_name] = 0
	else
		self._timers[timer_name] = self._timers[timer_name] + dtime
		--minetest.log("dtime: " .. tostring(self._timers[timer_name]))
	end

	if self._timers[timer_name] > threshold then
		--minetest.log("Over threshold")
		self._timers[timer_name] = 0
		return true
		--else
		--minetest.log("Not over threshold")
	end
	return false
end

-- While we should always favour the new minetest vector functions such as vector.new or vector.offset which validate on
-- creation. There may be cases where state gets corrupted and we may have to check the vector is valid if created the
-- old way. This allows us to do this as a tactical solution until old style vectors are completely removed.
function mcl_util.validate_vector (vect)
	if vect then
		if tonumber(vect.x) and tonumber(vect.y) and tonumber(vect.z) then
			return true
		end
	end
	return false
end

-- Minetest 5.3.0 or less can only measure the light level. This came in at 5.4
-- This function has been known to fail in multiple places so the error handling is added increase safety and improve
-- debugging. See:
-- https://git.minetest.land/VoxeLibre/VoxeLibre/issues/1392
function mcl_util.get_natural_light (pos, time)
	local status, retVal = pcall(minetest.get_natural_light, pos, time)
	if status then
		return retVal
	else
		minetest.log("warning", "Failed to get natural light at pos: " .. dump(pos) .. ", time: " .. dump(time))
		if (pos) then
			local node = minetest.get_node(pos)
			minetest.log("warning", "Node at pos: " .. dump(node.name))
		end
	end
	return 0
end

function mcl_util.file_exists(name)
	if type(name) ~= "string" then return end
	local f = io.open(name)
	if not f then
		return false
	end
	f:close()
	return true
end

-- Based on minetest.rotate_and_place

--[[
Attempt to predict the desired orientation of the pillar-like node
defined by `itemstack`, and place it accordingly in one of 3 possible
orientations (X, Y or Z).

Stacks are handled normally if the `infinitestacks`
field is false or omitted (else, the itemstack is not changed).
* `invert_wall`: if `true`, place wall-orientation on the ground and ground-
  orientation on wall

This function is a simplified version of minetest.rotate_and_place.
The Minetest function is seen as inappropriate because this includes mirror
images of possible orientations, causing problems with pillar shadings.
]]
function mcl_util.rotate_axis_and_place(itemstack, placer, pointed_thing, infinitestacks, invert_wall)
	local unode = minetest.get_node_or_nil(pointed_thing.under)
	if not unode then
		return
	end
	local undef = minetest.registered_nodes[unode.name]
	if undef and undef.on_rightclick and not invert_wall then
		undef.on_rightclick(pointed_thing.under, unode, placer,
			itemstack, pointed_thing)
		return
	end
	local fdir = minetest.dir_to_facedir(placer:get_look_dir())
	local wield_name = itemstack:get_name()

	local above = pointed_thing.above
	local under = pointed_thing.under
	local is_x = (above.x ~= under.x)
	local is_y = (above.y ~= under.y)
	local is_z = (above.z ~= under.z)

	local anode = minetest.get_node_or_nil(above)
	if not anode then
		return
	end
	local pos = pointed_thing.above
	local node = anode

	if undef and undef.buildable_to then
		pos = pointed_thing.under
		node = unode
	end

	if minetest.is_protected(pos, placer:get_player_name()) then
		minetest.record_protection_violation(pos, placer:get_player_name())
		return
	end

	local ndef = minetest.registered_nodes[node.name]
	if not ndef or not ndef.buildable_to then
		return
	end

	local p2
	if is_y then
		p2 = 0
	elseif is_x then
		p2 = 12
	elseif is_z then
		p2 = 6
	end
	minetest.set_node(pos, {name = wield_name, param2 = p2})

	if not infinitestacks then
		itemstack:take_item()
		return itemstack
	end
end

-- Wrapper of above function for use as `on_place` callback (Recommended).
-- Similar to minetest.rotate_node.
function mcl_util.rotate_axis(itemstack, placer, pointed_thing)
	mcl_util.rotate_axis_and_place(itemstack, placer, pointed_thing,
		minetest.is_creative_enabled(placer:get_player_name()),
		placer:get_player_control().sneak)
	return itemstack
end

-- Returns position of the neighbor of a double chest node
-- or nil if node is invalid.
-- This function assumes that the large chest is actually intact
-- * pos: Position of the node to investigate
-- * param2: param2 of that node
-- * side: Which "half" the investigated node is. "left" or "right"
function mcl_util.get_double_container_neighbor_pos(pos, param2, side)
	if side == "right" then
		if param2 == 0 then
			return {x = pos.x - 1, y = pos.y, z = pos.z}
		elseif param2 == 1 then
			return {x = pos.x, y = pos.y, z = pos.z + 1}
		elseif param2 == 2 then
			return {x = pos.x + 1, y = pos.y, z = pos.z}
		elseif param2 == 3 then
			return {x = pos.x, y = pos.y, z = pos.z - 1}
		end
	else
		if param2 == 0 then
			return {x = pos.x + 1, y = pos.y, z = pos.z}
		elseif param2 == 1 then
			return {x = pos.x, y = pos.y, z = pos.z - 1}
		elseif param2 == 2 then
			return {x = pos.x - 1, y = pos.y, z = pos.z}
		elseif param2 == 3 then
			return {x = pos.x, y = pos.y, z = pos.z + 1}
		end
	end
end

--- Selects item stack to transfer from
---@param src_inventory InvRef Source innentory to pull from
---@param src_list string Name of source inventory list to pull from
---@param dst_inventory InvRef Destination inventory to push to
---@param dst_list string Name of destination inventory list to push to
---@param condition? fun(stack: ItemStack) Condition which items are allowed to be transfered.
---@param count? integer Number of items to try to transfer at once
---@return integer Item stack number to be transfered
function mcl_util.select_stack(src_inventory, src_list, dst_inventory, dst_list, condition, count)
	local src_size = src_inventory:get_size(src_list)
	local stack
	for i = 1, src_size do
		stack = src_inventory:get_stack(src_list, i)

		-- Allow for partial stack movement
		if count and stack:get_count() >= count then
			local new_stack = ItemStack(stack)
			new_stack:set_count(count)
			stack = new_stack
		end

		if not stack:is_empty() and dst_inventory:room_for_item(dst_list, stack) and ((condition == nil or condition(stack))) then
			return i
		end
	end
	return nil
end

-- Moves a single item from one inventory to another.
--- source_inventory: Inventory to take the item from
--- source_list: List name of the source inventory from which to take the item
--- source_stack_id: The inventory position ID of the source inventory to take the item from (-1 for first occupied slot)
--- destination_inventory: Put item into this inventory
--- destination_list: List name of the destination inventory to which to put the item into

-- Returns true on success and false on failure
-- Possible failures: No item in source slot, destination inventory full
function mcl_util.move_item(source_inventory, source_list, source_stack_id, destination_inventory, destination_list)
	-- Can't move items we don't have
	if source_inventory:is_empty(source_list) then return false end

	-- Can't move from an empty stack
	local stack = source_inventory:get_stack(source_list, source_stack_id)
	if stack:is_empty() then return false end

	local new_stack = ItemStack(stack)
	new_stack:set_count(1)
	if not destination_inventory:room_for_item(destination_list, new_stack) then
		return false
	end
	stack:take_item()
	source_inventory:set_stack(source_list, source_stack_id, stack)
	destination_inventory:add_item(destination_list, new_stack)
	return true
end

--- Try pushing item from hopper inventory to destination inventory
---@param pos Vector
---@param dst_pos Vector
function mcl_util.hopper_push(pos, dst_pos)
	local hop_inv = minetest.get_meta(pos):get_inventory()
	local hop_list = 'main'

	-- Get node pos' for item transfer
	local dst = minetest.get_node(dst_pos)
	if not minetest.registered_nodes[dst.name] then return end
	local dst_type = minetest.get_item_group(dst.name, "container")
	if dst_type ~= 2 then return end
	local dst_def = minetest.registered_nodes[dst.name]

	local dst_list = 'main'
	local dst_inv, stack_id

	-- Find a inventory stack in the destination
	if dst_def._mcl_hoppers_on_try_push then
		dst_inv, dst_list, stack_id = dst_def._mcl_hoppers_on_try_push(dst_pos, pos, hop_inv, hop_list)
	else
		local dst_meta = minetest.get_meta(dst_pos)
		dst_inv = dst_meta:get_inventory()
		stack_id = mcl_util.select_stack(hop_inv, hop_list, dst_inv, dst_list, nil, 1)
	end
	if not stack_id then return false end

	-- Move the item
	local ok = mcl_util.move_item(hop_inv, hop_list, stack_id, dst_inv, dst_list)
	if dst_def._mcl_hoppers_on_after_push then
		dst_def._mcl_hoppers_on_after_push(dst_pos)
	end

	return ok
end

-- Try pulling from source inventory to hopper inventory
---@param pos Vector
---@param src_pos Vector
function mcl_util.hopper_pull(pos, src_pos)
	local hop_inv = minetest.get_meta(pos):get_inventory()
	local hop_list = 'main'

	-- Get node pos' for item transfer
	local src = minetest.get_node(src_pos)
	if not minetest.registered_nodes[src.name] then return end
	local src_type = minetest.get_item_group(src.name, "container")
	if src_type ~= 2 then return end
	local src_def = minetest.registered_nodes[src.name]

	local src_list = 'main'
	local src_inv, stack_id

	if src_def._mcl_hoppers_on_try_pull then
		src_inv, src_list, stack_id = src_def._mcl_hoppers_on_try_pull(src_pos, pos, hop_inv, hop_list)
	else
		local src_meta = minetest.get_meta(src_pos)
		src_inv = src_meta:get_inventory()
		stack_id = mcl_util.select_stack(src_inv, src_list, hop_inv, hop_list, nil, 1)
	end

	if stack_id ~= nil then
		local ok = mcl_util.move_item(src_inv, src_list, stack_id, hop_inv, hop_list)
		if src_def._mcl_hoppers_on_after_pull then
			src_def._mcl_hoppers_on_after_pull(src_pos)
		end
	end
end

local function drop_item_stack(pos, stack)
	if not stack or stack:is_empty() then return end
	local drop_offset = vector.new(math.random() - 0.5, 0, math.random() - 0.5)
	minetest.add_item(vector.add(pos, drop_offset), stack)
end

function mcl_util.drop_items_from_meta_container(listname)
	return function(pos, oldnode, oldmetadata)
		if oldmetadata and oldmetadata.inventory then
			-- process in after_dig_node callback
			local main = oldmetadata.inventory.main
			if not main then return end
			for _, stack in pairs(main) do
				drop_item_stack(pos, stack)
			end
		else
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			for i = 1, inv:get_size("main") do
				drop_item_stack(pos, inv:get_stack("main", i))
			end
			meta:from_table()
		end
	end
end

-- Returns true if item (itemstring or ItemStack) can be used as a furnace fuel.
-- Returns false otherwise
function mcl_util.is_fuel(item)
	return minetest.get_craft_result({method = "fuel", width = 1, items = {item}}).time ~= 0
end

-- Returns a on_place function for plants
-- * condition: function(pos, node, itemstack)
--    * A function which is called by the on_place function to check if the node can be placed
--    * Must return true, if placement is allowed, false otherwise.
--    * If it returns a string, placement is allowed, but will place this itemstring as a node instead
--    * pos, node: Position and node table of plant node
--    * itemstack: Itemstack to place
function mcl_util.generate_on_place_plant_function(condition)
	return function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			-- no interaction possible with entities
			return itemstack
		end

		-- Call on_rightclick if the pointed node defines it
		local node = minetest.get_node(pointed_thing.under)
		if placer and not placer:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
			end
		end

		local place_pos
		local def_under = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
		local def_above = minetest.registered_nodes[minetest.get_node(pointed_thing.above).name]
		if not def_under or not def_above then
			return itemstack
		end
		if def_under.buildable_to and def_under.name ~= itemstack:get_name() then
			place_pos = pointed_thing.under
		elseif def_above.buildable_to and def_above.name ~= itemstack:get_name() then
			place_pos = pointed_thing.above
			pointed_thing.under = pointed_thing.above
		else
			return itemstack
		end

		-- Check placement rules
		local result, param2 = condition(place_pos, node, itemstack)
		if result == true then
			local idef = itemstack:get_definition()
			local new_itemstack, success = minetest.item_place_node(itemstack, placer, pointed_thing, param2)

			if success then
				if idef.sounds and idef.sounds.place then
					minetest.sound_play(idef.sounds.place, {pos = pointed_thing.above, gain = 1}, true)
				end
			end
			itemstack = new_itemstack
		end

		return itemstack
	end
end

-- adjust the y level of an object to the center of its collisionbox
-- used to get the origin position of entity explosions
function mcl_util.get_object_center(obj)
	local collisionbox = obj:get_properties().collisionbox
	local pos = obj:get_pos()
	local ymin = collisionbox[2]
	local ymax = collisionbox[5]
	pos.y = pos.y + (ymax - ymin) / 2.0
	return pos
end

function mcl_util.get_color(colorstr)
	local mc_color = mcl_colors[colorstr:upper()]
	if mc_color then
		colorstr = mc_color
	elseif #colorstr ~= 7 or colorstr:sub(1, 1) ~= "#" then
		return
	end
	local hex = tonumber(colorstr:sub(2, 7), 16)
	if hex then
		return colorstr, hex
	end
end

function mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	-- Call on_rightclick if the pointed node defines it
	if pointed_thing and pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		if player and not player:get_player_control().sneak then
			local nodedef = minetest.registered_nodes[node.name]
			local on_rightclick = nodedef and nodedef.on_rightclick
			if on_rightclick then
				return on_rightclick(pos, node, player, itemstack, pointed_thing) or itemstack
			end
		end
	end
end

function mcl_util.calculate_durability(itemstack)
	local unbreaking_level = mcl_enchanting.get_enchantment(itemstack, "unbreaking")
	local armor_uses = minetest.get_item_group(itemstack:get_name(), "mcl_armor_uses")

	local uses

	if armor_uses > 0 then
		uses = armor_uses
		if unbreaking_level > 0 then
			uses = uses / (0.6 + 0.4 / (unbreaking_level + 1))
		end
	else
		local def = itemstack:get_definition()
		if def then
			local fixed_uses = def._mcl_uses
			if fixed_uses then
				uses = fixed_uses
				if unbreaking_level > 0 then
					uses = uses * (unbreaking_level + 1)
				end
			end
		end

		local _, groupcap = next(itemstack:get_tool_capabilities().groupcaps)
		uses = uses or (groupcap or {}).uses
	end

	return uses or 0
end

function mcl_util.use_item_durability(itemstack, n)
	local uses = mcl_util.calculate_durability(itemstack)
	itemstack:add_wear(65535 / uses * n)
	tt.reload_itemstack_description(itemstack) -- update tooltip
end

function mcl_util.deal_damage(target, damage, mcl_reason)
	local luaentity = target:get_luaentity()

	if luaentity then
		if luaentity.deal_damage then
			luaentity:deal_damage(damage, mcl_reason or {type = "generic"})
			return
		elseif luaentity.is_mob then
			-- local puncher = mcl_reason and mcl_reason.direct or target
			-- target:punch(puncher, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = damage}}, vector.direction(puncher:get_pos(), target:get_pos()), damage)
			if luaentity.health > 0 then
				luaentity.health = luaentity.health - damage
			end
			return
		end
	elseif not target:is_player() then return end

	local is_immortal = target:get_armor_groups().immortal or 0
	if is_immortal>0 then
		return
	end

	local hp = target:get_hp()

	if hp > 0 then
		target:set_hp(hp - damage, {_mcl_reason = mcl_reason})
	end
end

function mcl_util.get_hp(obj)
	local luaentity = obj:get_luaentity()

	if luaentity and luaentity.is_mob then
		return luaentity.health
	else
		return obj:get_hp()
	end
end

function mcl_util.get_inventory(object, create)
	if object:is_player() then
		return object:get_inventory()
	else
		local luaentity = object:get_luaentity()
		local inventory = luaentity.inventory

		if create and not inventory and luaentity.create_inventory then
			inventory = luaentity:create_inventory()
		end

		return inventory
	end
end

function mcl_util.get_wielded_item(object)
	if object:is_player() then
		return object:get_wielded_item()
	else
		-- ToDo: implement getting wielditems from mobs as soon as mobs have wielditems
		return ItemStack()
	end
end

function mcl_util.get_object_name(object)
	if object:is_player() then
		return object:get_player_name()
	else
		local luaentity = object:get_luaentity()

		if not luaentity then
			return tostring(object)
		end

		return luaentity.nametag and luaentity.nametag ~= "" and luaentity.nametag or luaentity.description or luaentity.name
	end
end

function mcl_util.replace_mob(obj, mob)
	if not obj then return end
	local rot = obj:get_yaw()
	local pos = obj:get_pos()
	obj:remove()
	obj = minetest.add_entity(pos, mob)
	if not obj then return end
	obj:set_yaw(rot)
	return obj
end

function mcl_util.get_pointed_thing(player, liquid)
	local pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local look_dir = vector.multiply(player:get_look_dir(), 5)
	local pos2 = vector.add(pos, look_dir)
	local ray = minetest.raycast(pos, pos2, false, liquid)

	if ray then
		for pointed_thing in ray do
			return pointed_thing
		end
	end
end

-- This following part is 2 wrapper functions + helpers for
-- object:set_bones
-- and player:set_properties preventing them from being resent on
-- every globalstep when they have not changed.

local function roundN(n, d)
	if type(n) ~= "number" then return n end
	local m = 10 ^ d
	return math.floor(n * m + 0.5) / m
end

local function close_enough(a, b)
	local rt = true
	if type(a) == "table" and type(b) == "table" then
		for k, v in pairs(a) do
			if roundN(v, 2) ~= roundN(b[k], 2) then
				rt = false
				break
			end
		end
	else
		rt = roundN(a, 2) == roundN(b, 2)
	end
	return rt
end

local function props_changed(props, oldprops)
	local changed = false
	local p = {}
	for k, v in pairs(props) do
		if not close_enough(v, oldprops[k]) then
			p[k] = v
			changed = true
		end
	end
	return changed, p
end

--tests for roundN
local test_round1 = 15
local test_round2 = 15.00199999999
local test_round3 = 15.00111111
local test_round4 = 15.00999999

assert(roundN(test_round1, 2) == roundN(test_round1, 2))
assert(roundN(test_round1, 2) == roundN(test_round2, 2))
assert(roundN(test_round1, 2) == roundN(test_round3, 2))
assert(roundN(test_round1, 2) ~= roundN(test_round4, 2))

-- tests for close_enough
local test_cb = {-0.35, 0, -0.35, 0.35, 0.8, 0.35} --collisionboxes
local test_cb_close = {-0.351213, 0, -0.35, 0.35, 0.8, 0.351212}
local test_cb_diff = {-0.35, 0, -1.35, 0.35, 0.8, 0.35}

local test_eh = 1.65 --eye height
local test_eh_close = 1.65123123
local test_eh_diff = 1.35

local test_nt = {r = 225, b = 225, a = 225, g = 225} --nametag
local test_nt_diff = {r = 225, b = 225, a = 0, g = 225}

assert(close_enough(test_cb, test_cb_close))
assert(not close_enough(test_cb, test_cb_diff))
assert(close_enough(test_eh, test_eh_close))
assert(not close_enough(test_eh, test_eh_diff))
assert(not close_enough(test_nt, test_nt_diff)) --no floats involved here

--tests for properties_changed
local test_properties_set1 = {collisionbox = {-0.35, 0, -0.35, 0.35, 0.8, 0.35}, eye_height = 0.65,
	nametag_color = {r = 225, b = 225, a = 225, g = 225}}
local test_properties_set2 = {collisionbox = {-0.35, 0, -0.35, 0.35, 0.8, 0.35}, eye_height = 1.35,
	nametag_color = {r = 225, b = 225, a = 225, g = 225}}

local test_p1, _ = props_changed(test_properties_set1, test_properties_set1)
local test_p2, _ = props_changed(test_properties_set1, test_properties_set2)

assert(not test_p1)
assert(test_p2)

function mcl_util.set_properties(obj, props)
	local changed, p = props_changed(props, obj:get_properties())
	if changed then
		obj:set_properties(p)
	end
end

function mcl_util.set_bone_position(obj, bone, pos, rot)
	local current_pos, current_rot = obj:get_bone_position(bone)
	local pos_equal = not pos or vector.equals(vector.round(current_pos), vector.round(pos))
	local rot_equal = not rot or vector.equals(vector.round(current_rot), vector.round(rot))
	if not pos_equal or not rot_equal then
		obj:set_bone_position(bone, pos or current_pos, rot or current_rot)
	end
end

---Return a function to use in `on_place`.
---
---Allow to bypass the `buildable_to` node field in a `on_place` callback.
---
---You have to make sure that the nodes you return true for have `buildable_to = true`.
---@param func fun(node_name: string): boolean Return `true` if node must not replace the buildable_to node which have `node_name`
---@return fun(itemstack: ItemStack, placer: ObjectRef, pointed_thing: pointed_thing, param2: integer): ItemStack?
function mcl_util.bypass_buildable_to(func)
	--------------------------
	-- MINETEST CODE: UTILS --
	--------------------------

	local function copy_pointed_thing(pointed_thing)
		return {
			type  = pointed_thing.type,
			above = pointed_thing.above and vector.copy(pointed_thing.above),
			under = pointed_thing.under and vector.copy(pointed_thing.under),
			ref   = pointed_thing.ref,
		}
	end

	local function user_name(user)
		return user and user:get_player_name() or ""
	end

	-- Returns a logging function. For empty names, does not log.
	local function make_log(name)
		return name ~= "" and minetest.log or function() end
	end

	local function check_attached_node(p, n, group_rating)
		local def = core.registered_nodes[n.name]
		local d = vector.zero()
		if group_rating == 3 then
			-- always attach to floor
			d.y = -1
		elseif group_rating == 4 then
			-- always attach to ceiling
			d.y = 1
		elseif group_rating == 2 then
			-- attach to facedir or 4dir direction
			if (def.paramtype2 == "facedir" or
				def.paramtype2 == "colorfacedir") then
				-- Attach to whatever facedir is "mounted to".
				-- For facedir, this is where tile no. 5 point at.

				-- The fallback vector here is in case 'facedir to dir' is nil due
				-- to voxelmanip placing a wallmounted node without resetting a
				-- pre-existing param2 value that is out-of-range for facedir.
				-- The fallback vector corresponds to param2 = 0.
				d = core.facedir_to_dir(n.param2) or vector.new(0, 0, 1)
			elseif (def.paramtype2 == "4dir" or
				def.paramtype2 == "color4dir") then
				-- Similar to facedir handling
				d = core.fourdir_to_dir(n.param2) or vector.new(0, 0, 1)
			end
		elseif def.paramtype2 == "wallmounted" or
			def.paramtype2 == "colorwallmounted" then
			-- Attach to whatever this node is "mounted to".
			-- This where tile no. 2 points at.

			-- The fallback vector here is used for the same reason as
			-- for facedir nodes.
			d = core.wallmounted_to_dir(n.param2) or vector.new(0, 1, 0)
		else
			d.y = -1
		end
		local p2 = vector.add(p, d)
		local nn = core.get_node(p2).name
		local def2 = core.registered_nodes[nn]
		if def2 and not def2.walkable then
			return false
		end
		return true
	end

	return function(itemstack, placer, pointed_thing, param2)
		-------------------
		-- MINETEST CODE --
		-------------------
		local def = itemstack:get_definition()
		if def.type ~= "node" or pointed_thing.type ~= "node" then
			return itemstack
		end

		local under = pointed_thing.under
		local oldnode_under = minetest.get_node_or_nil(under)
		local above = pointed_thing.above
		local oldnode_above = minetest.get_node_or_nil(above)
		local playername = user_name(placer)
		local log = make_log(playername)

		if not oldnode_under or not oldnode_above then
			log("info", playername .. " tried to place"
				.. " node in unloaded position " .. minetest.pos_to_string(above))
			return itemstack
		end

		local olddef_under = minetest.registered_nodes[oldnode_under.name]
		olddef_under = olddef_under or minetest.nodedef_default
		local olddef_above = minetest.registered_nodes[oldnode_above.name]
		olddef_above = olddef_above or minetest.nodedef_default

		if not olddef_above.buildable_to and not olddef_under.buildable_to then
			log("info", playername .. " tried to place"
				.. " node in invalid position " .. minetest.pos_to_string(above)
				.. ", replacing " .. oldnode_above.name)
			return itemstack
		end

		---------------------
		-- CUSTOMIZED CODE --
		---------------------

		-- Place above pointed node
		local place_to = vector.copy(above)

		-- If node under is buildable_to, check for callback result and place into it instead
		if olddef_under.buildable_to and not func(oldnode_under.name) then
			log("info", "node under is buildable to")
			place_to = vector.copy(under)
		end

		-------------------
		-- MINETEST CODE --
		-------------------

		if minetest.is_protected(place_to, playername) then
			log("action", playername
				.. " tried to place " .. def.name
				.. " at protected position "
				.. minetest.pos_to_string(place_to))
			minetest.record_protection_violation(place_to, playername)
			return itemstack
		end

		local oldnode = minetest.get_node(place_to)
		local newnode = {name = def.name, param1 = 0, param2 = param2 or 0}

		-- Calculate direction for wall mounted stuff like torches and signs
		if def.place_param2 ~= nil then
			newnode.param2 = def.place_param2
		elseif (def.paramtype2 == "wallmounted" or
			def.paramtype2 == "colorwallmounted") and not param2 then
			local dir = vector.subtract(under, above)
			newnode.param2 = minetest.dir_to_wallmounted(dir)
			-- Calculate the direction for furnaces and chests and stuff
		elseif (def.paramtype2 == "facedir" or
			def.paramtype2 == "colorfacedir" or
			def.paramtype2 == "4dir" or
			def.paramtype2 == "color4dir") and not param2 then
			local placer_pos = placer and placer:get_pos()
			if placer_pos then
				local dir = vector.subtract(above, placer_pos)
				newnode.param2 = minetest.dir_to_facedir(dir)
				log("info", "facedir: " .. newnode.param2)
			end
		end

		local metatable = itemstack:get_meta():to_table().fields

		-- Transfer color information
		if metatable.palette_index and not def.place_param2 then
			local color_divisor = nil
			if def.paramtype2 == "color" then
				color_divisor = 1
			elseif def.paramtype2 == "colorwallmounted" then
				color_divisor = 8
			elseif def.paramtype2 == "colorfacedir" then
				color_divisor = 32
			elseif def.paramtype2 == "color4dir" then
				color_divisor = 4
			elseif def.paramtype2 == "colordegrotate" then
				color_divisor = 32
			end
			if color_divisor then
				local color = math.floor(metatable.palette_index / color_divisor)
				local other = newnode.param2 % color_divisor
				newnode.param2 = color * color_divisor + other
			end
		end

		-- Check if the node is attached and if it can be placed there
		local an = minetest.get_item_group(def.name, "attached_node")
		if an ~= 0 and
			not check_attached_node(place_to, newnode, an) then
			log("action", "attached node " .. def.name ..
				" cannot be placed at " .. minetest.pos_to_string(place_to))
			return itemstack
		end

		log("action", playername .. " places node "
			.. def.name .. " at " .. minetest.pos_to_string(place_to))

		-- Add node and update
		minetest.add_node(place_to, newnode)

		-- Play sound if it was done by a player
		if playername ~= "" and def.sounds and def.sounds.place then
			minetest.sound_play(def.sounds.place, {
				pos = place_to,
				exclude_player = playername,
			}, true)
		end

		local take_item = true

		-- Run callback
		if def.after_place_node then
			-- Deepcopy place_to and pointed_thing because callback can modify it
			local place_to_copy = vector.copy(place_to)
			local pointed_thing_copy = copy_pointed_thing(pointed_thing)
			if def.after_place_node(place_to_copy, placer, itemstack,
				pointed_thing_copy) then
				take_item = false
			end
		end

		-- Run script hook
		for _, callback in ipairs(minetest.registered_on_placenodes) do
			-- Deepcopy pos, node and pointed_thing because callback can modify them
			local place_to_copy = vector.copy(place_to)
			local newnode_copy = {name = newnode.name, param1 = newnode.param1, param2 = newnode.param2}
			local oldnode_copy = {name = oldnode.name, param1 = oldnode.param1, param2 = oldnode.param2}
			local pointed_thing_copy = copy_pointed_thing(pointed_thing)
			if callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy) then
				take_item = false
			end
		end

		if take_item then
			itemstack:take_item()
		end
		return itemstack
	end
end

--[[Check for a protection violation in a given area.
--
-- Applies is_protected() to a 3D lattice of points in the defined volume. The points are spaced
-- evenly throughout the volume and have a spacing similar to, but no larger than, "interval".
--
-- @param pos1          A position table of the area volume's first edge.
-- @param pos2          A position table of the area volume's second edge.
-- @param player        The player performing the action.
-- @param interval	    Optional. Max spacing between checked points at the volume.
--      Default: Same as minetest.is_area_protected.
--
-- @return	true on protection violation detection. false otherwise.
--
-- @notes   *All corners and edges of the defined volume are checked.
]]
function mcl_util.check_area_protection(pos1, pos2, player, interval)
	local name = player and player:get_player_name() or ""

	local protected_pos = minetest.is_area_protected(pos1, pos2, name, interval)
	if protected_pos then
		minetest.record_protection_violation(protected_pos, name)
		return true
	end

	return false
end

--[[Check for a protection violation on a single position.
--
-- @param position      A position table to check for protection violation.
-- @param player        The player performing the action.
--
-- @return	true on protection violation detection. false otherwise.
]]
function mcl_util.check_position_protection(position, player)
	local name = player and player:get_player_name() or ""

	if minetest.is_protected(position, name) then
		minetest.record_protection_violation(position, name)
		return true
	end

	return false
end

local palette_indexes = {grass_palette_index = 0, foliage_palette_index = 0, water_palette_index = 0}
function mcl_util.get_palette_indexes_from_pos(pos)
	local biome_data = minetest.get_biome_data(pos)
	local biome = biome_data.biome
	local biome_name = minetest.get_biome_name(biome)
	local reg_biome = minetest.registered_biomes[biome_name]
	if reg_biome and reg_biome._mcl_grass_palette_index and reg_biome._mcl_foliage_palette_index and reg_biome._mcl_water_palette_index then
		local gpi = reg_biome._mcl_grass_palette_index
		local fpi = reg_biome._mcl_foliage_palette_index
		local wpi = reg_biome._mcl_water_palette_index
		local palette_indexes = {grass_palette_index = gpi, foliage_palette_index = fpi, water_palette_index = wpi}
		return palette_indexes
	else
		return palette_indexes
	end
end

function mcl_util.get_colorwallmounted_rotation(pos)
	local colorwallmounted_node = minetest.get_node(pos)
	for i = 0, 32, 1 do
		local colorwallmounted_rotation = colorwallmounted_node.param2 - (i * 8)
		if colorwallmounted_rotation < 6 then
			return colorwallmounted_rotation
		end
	end
end

---Move items from one inventory list to another, drop items that do not fit in provided pos and direction.
---@param src_inv mt.InvRef
---@param src_listname string
---@param out_inv mt.InvRef
---@param out_listname string
---@param pos mt.Vector Position to throw items at
---@param dir? mt.Vector Direction to throw items in
---@param insta_collect? boolean Enable instant collection, let players collect dropped items instantly. Default `false`
function mcl_util.move_list(src_inv, src_listname, out_inv, out_listname, pos, dir, insta_collect)
	local src_list = src_inv:get_list(src_listname)

	if not src_list then return end
	for i, stack in ipairs(src_list) do
		if out_inv:room_for_item(out_listname, stack) then
			out_inv:add_item(out_listname, stack)
		else
			local p = vector.copy(pos)
			p.x = p.x + (math.random(1, 3) * 0.2)
			p.z = p.z + (math.random(1, 3) * 0.2)

			local obj = minetest.add_item(p, stack)
			if obj then
				if dir then
					local v = vector.copy(dir)
					v.x = v.x * 4
					v.y = v.y * 4 + 2
					v.z = v.z * 4
					obj:set_velocity(v)
					mcl_util.mcl_log("item velocity calculated "..vector.to_string(v), "[mcl_util]")
				end
				if not insta_collect then
					obj:get_luaentity()._insta_collect = false
				end
			end
		end

		stack:clear()
		src_inv:set_stack(src_listname, i, stack)
	end
end

---Move items from a player's inventory list to its main inventory list, drop items that do not fit in front of him.
---@param player mt.PlayerObjectRef
---@param src_listname string
function mcl_util.move_player_list(player, src_listname)
	mcl_util.move_list(player:get_inventory(), src_listname, player:get_inventory(), "main",
		vector.offset(player:get_pos(), 0, 1.2, 0),
		player:get_look_dir(), false)
end

function mcl_util.is_it_christmas()
	local date = os.date("*t")
	if date.month == 12 and date.day >= 24 or date.month == 1 and date.day <= 7 then
		return true
	else
		return false
	end
end
