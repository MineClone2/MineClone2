local math, vector, minetest, mcl_mobs = math, vector, minetest, mcl_mobs
local mob_class = mcl_mobs.mob_class

local HORNY_TIME = 30
local HORNY_AGAIN_TIME = 30 -- was 300 or 15*20
local CHILD_GROW_TIME = 60

local LOGGING_ON = minetest.settings:get_bool("mcl_logging_mobs_villager",false)

local LOG_MODULE = "[mcl_mobs]"
local function mcl_log (message)
	if LOGGING_ON and message then
		minetest.log(LOG_MODULE .. " " .. message)
	end
end

-- No-op in MCL2 (capturing mobs is not possible).
-- Provided for compability with Mobs Redo
function mcl_mobs:capture_mob(self, clicker, chance_hand, chance_net, chance_lasso, force_take, replacewith)
	return false
end


-- No-op in MCL2 (protecting mobs is not possible).
function mcl_mobs:protect(self, clicker)
	return false
end


-- feeding, taming and breeding (thanks blert2112)
function mob_class:feed_tame(clicker, feed_count, breed, tame, notake)
	if not self.follow then
		return false
	end
	if clicker:get_wielded_item():get_definition()._mcl_not_consumable then
		return false
	end
	-- can eat/tame with item in hand
	if self.nofollow or self:follow_holding(clicker) then
		local consume_food = false

		-- tame if not still a baby

		if tame and not self.child then
			if not self.owner or self.owner == "" then
				self.tamed = true
				self.owner = clicker:get_player_name()
				consume_food = true
			end
		end

		-- increase health

		if self.health < self.hp_max and not consume_food then
			consume_food = true
			self.health = math.min(self.health + 4, self.hp_max)

			if self.htimer < 1 then
				self.htimer = 5
			end
			self.object:set_hp(self.health)
		end

		-- make children grow quicker

		if not consume_food and self.child == true then
			consume_food = true
			-- deduct 10% of the time to adulthood
			self.hornytimer = self.hornytimer + ((CHILD_GROW_TIME - self.hornytimer) * 0.1)
		end

		--  breed animals

		if breed and not consume_food and self.hornytimer == 0 and not self.horny then
			self.food = (self.food or 0) + 1
			consume_food = true
			if self.food >= feed_count then
				self.food = 0
				self.horny = true
				self.persistent = true
				self._luck = mcl_luck.get_luck(clicker:get_player_name())
			end
		end

		self:update_tag()
		-- play a sound if the animal used the item and take the item if not in creative
		if consume_food then
			-- don't consume food if clicker is in creative
			if not minetest.is_creative_enabled(clicker:get_player_name()) and not notake then
				local item = clicker:get_wielded_item()
				item:take_item()
				clicker:set_wielded_item(item)
			end
			-- always play the eat sound if food is used, even in creative
			self:mob_sound("eat", nil, true)

		else
			-- make sound when the mob doesn't want food
			self:mob_sound("random", true)
		end
		return true
	end
	return false
end

-- Spawn a child
function mcl_mobs.spawn_child(pos, mob_type)
	local child = minetest.add_entity(pos, mob_type)
	if not child then
		return
	end

	local ent = child:get_luaentity()
	mcl_mobs.effect(pos, 15, "mcl_particles_smoke.png", 1, 2, 2, 15, 5)

	ent.child = true

	local textures
	-- using specific child texture (if found)
	if ent.child_texture then
		textures = ent.child_texture[1]
	end

	-- and resize to half height
	child:set_properties({
		textures = textures,
		visual_size = {
			x = ent.base_size.x * .5,
			y = ent.base_size.y * .5,
		},
		collisionbox = {
			ent.base_colbox[1] * .5,
			ent.base_colbox[2] * .5,
			ent.base_colbox[3] * .5,
			ent.base_colbox[4] * .5,
			ent.base_colbox[5] * .5,
			ent.base_colbox[6] * .5,
		},
		selectionbox = {
			ent.base_selbox[1] * .5,
			ent.base_selbox[2] * .5,
			ent.base_selbox[3] * .5,
			ent.base_selbox[4] * .5,
			ent.base_selbox[5] * .5,
			ent.base_selbox[6] * .5,
		},
	})

	ent.animation = ent._child_animations
	ent._current_animation = nil
	ent:set_animation("stand")

	return child
end

-- find two animals of same type and breed if nearby and horny
function mob_class:check_breeding()

	--mcl_log("In breed function")
	-- child takes a long time before growing into adult
	if self.child == true then

		-- When a child, hornytimer is used to count age until adulthood
		self.hornytimer = self.hornytimer + 1

		if self.hornytimer >= CHILD_GROW_TIME then

			self.child = false
			self.hornytimer = 0

			self.object:set_properties({
				textures = self.base_texture,
				mesh = self.base_mesh,
				visual_size = self.base_size,
				collisionbox = self.base_colbox,
				selectionbox = self.base_selbox,
			})

			-- custom function when child grows up
			if self.on_grown then
				self.on_grown(self)
			else
				-- jump when fully grown so as not to fall into ground
				self.object:set_velocity({
					x = 0,
					y = self.jump_height,
					z = 0
				})
			end

			self.animation = nil
			local anim = self._current_animation
			self._current_animation = nil -- Mobs Redo does nothing otherwise
			self:set_animation(anim)
		end

		return
	else
		-- horny animal can mate for HORNY_TIME seconds,
		-- afterwards horny animal cannot mate again for HORNY_AGAIN_TIME seconds
		if self.horny == true then
			self.hornytimer = self.hornytimer + 1

			if self.hornytimer >= HORNY_TIME + HORNY_AGAIN_TIME then
				self.hornytimer = 0
				self.horny = false
			end
		end
	end

	-- find another same animal who is also horny and mate if nearby
	if self.horny == true
	and self.hornytimer <= HORNY_TIME then

		mcl_log("In breed function. All good. Do the magic.")

		local pos = self.object:get_pos()

		mcl_mobs.effect({x = pos.x, y = pos.y + 1, z = pos.z}, 8, "heart.png", 3, 4, 1, 0.1)

		local objs = minetest.get_objects_inside_radius(pos, 3)
		local num = 0
		local ent = nil

		for n = 1, #objs do

			ent = objs[n]:get_luaentity()

			-- check for same animal with different colour
			local canmate = false

			if ent then

				if ent.name == self.name then
					canmate = true
				else
					local entname = string.split(ent.name,":")
					local selfname = string.split(self.name,":")

					if entname[1] == selfname[1] then
						entname = string.split(entname[2],"_")
						selfname = string.split(selfname[2],"_")

						if entname[1] == selfname[1] then
							canmate = true
						end
					end
				end
			end

			if canmate then mcl_log("In breed function. Can mate.") end

			if ent
			and canmate == true
			and ent.horny == true
			and ent.hornytimer <= HORNY_TIME then
				num = num + 1
			end

			-- found your mate? then have a baby
			if num > 1 then

				self.hornytimer = HORNY_TIME + 1
				ent.hornytimer = HORNY_TIME + 1

				-- spawn baby


				minetest.after(5, function(parent1, parent2, pos)
					if not parent1.object:get_luaentity() then
						return
					end
					if not parent2.object:get_luaentity() then
						return
					end

					mcl_experience.throw_xp(pos, math.random(1, 7) + (parent1._luck or 0) + (parent2._luck or 0))

					-- custom breed function
					if parent1.on_breed then
						-- when false, skip going any further
						if parent1.on_breed(parent1, parent2) == false then
							return
						end
					end

					local child = mcl_mobs.spawn_child(pos, parent1.name)

					local ent_c = child:get_luaentity()


					-- Use texture of one of the parents
					local p = math.random(1, 2)
					if p == 1 then
						ent_c.base_texture = parent1.base_texture
					else
						ent_c.base_texture = parent2.base_texture
					end
					child:set_properties({
						textures = ent_c.base_texture
					})

					-- tamed and owned by parents' owner
					ent_c.tamed = true
					ent_c.owner = parent1.owner
				end, self, ent, pos)

				num = 0

				break
			end
		end
	end
end

function mob_class:toggle_sit(clicker,p)
	if not self.tamed or self.child  or self.owner ~= clicker:get_player_name() then
		return
	end
	local pos = self.object:get_pos()
	local particle
	if not self.order or self.order == "" or self.order == "sit" then
		particle = "mobs_mc_wolf_icon_roam.png"
		self.order = "roam"
		self.state = "stand"
		self.walk_chance = default_walk_chance
		self.jump = true
		self:set_animation("stand")
		-- TODO: Add sitting model
	else
		particle = "mobs_mc_wolf_icon_sit.png"
		self.order = "sit"
		self.state = "stand"
		self.walk_chance = 0
		self.jump = false
		if self.animation.sit_start then
			self:set_animation("sit")
		else
			self:set_animation("stand")
		end
	end
	local pp = vector.new(0,1.4,0)
	if p then pp = vector.offset(pp,0,p,0) end
	-- Display icon to show current order (sit or roam)
	minetest.add_particle({
		pos = vector.add(pos, pp),
		velocity = {x=0,y=0.2,z=0},
		expirationtime = 1,
		size = 4,
		texture = particle,
		playername = self.owner,
		glow = minetest.LIGHT_MAX,
	})
end
