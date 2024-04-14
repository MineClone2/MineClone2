local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

vl_scheduler = {}
local mod = vl_scheduler

dofile(modpath.."/queue.lua")
dofile(modpath.."/fifo.lua")
dofile(modpath.."/test.lua")

local run_queues = {}
for i = 1,4 do
	run_queues[i] = mod.fifo:new()
end
local tasks = 0
local time = 0
local priority_queue = mod.queue:new()
local functions = {}
local function_id_from_name = {}

local unpack = unpack
local minetest_get_us_time = minetest.get_us_time
local queue_add_task = mod.queue.add_task
local queue_get = mod.queue.get
local queue_tick = mod.queue.tick
local fifo_insert = mod.fifo.insert
local fifo_get = mod.fifo.get

function mod.add_task(time, name, priority, args)
	if priority then
		if priority > 4 then priority = 4 end
		if priority < 1 then priority = 1 end
	end

	local fid = function_id_from_name[name]
	if not fid then
		print("Trying to add task with unknown function "..name)
		return
	end
	local dtime = math.floor(time * 20) + 1
	local task = {
		time = dtime, -- Used by scheduler to track how long until this task is dispatched
		dtime = dtime, -- Original time amount
		fid = fid,
		priority = priority,
		args = args,
	}
	queue_add_task(priority_queue, task)
end

function mod.register_function(name, func)
	local fid = #functions + 1
	functions[fid] = {
		func = func,
		name = name,
		fid = fid,
	}
	function_id_from_name[name] = fid
	print("Registering "..name.." as #"..tostring(fid))
end

mod.register_function("vl_scheduler:test",function(task)
	print("game time="..tostring(minetest.get_gametime()))

	-- Reschedule task
	task.time = 0.25 * 20
	return task
end)
mod.add_task(0, "vl_scheduler:test")

minetest.register_globalstep(function(dtime)
	local start_time = minetest_get_us_time()
	local end_time = start_time + 50000
	time = time + dtime

	-- Add tasks to the run queues
	local iter = queue_tick(priority_queue)
	while iter do
		local task = iter
		iter = iter.next

		local priority = task.priority or 3

		fifo_insert(run_queues[priority], task)
		tasks = tasks + 1
	end
	local task_time = minetest_get_us_time()
	--print("Took "..tostring(task_time-start_time).." us to update task list")

	-- Run tasks until we run out of timeslice
	if tasks > 0 then
		local i = 1
		while i < 4 and minetest_get_us_time() < end_time do
			local task = fifo_get(run_queues[i])
			if task then
				tasks = tasks - 1
				local func = functions[task.fid]
				if func then
					--print("Running task "..dump(task)..",func="..dump(func))
					local ok,ret = pcall(func.func, task, unpack(task.args or {}))
					if not ok then
						minetest.log("error","Error while running task "..func.name..": "..tostring(ret))
					end

					-- If the task was returned, reschedule it
					if ret == task then
						task.next = nil
						queue_add_task(priority_queue, task)
					end
					local next_task_time = minetest_get_us_time()
					print(func.name.." took "..(next_task_time-task_time).." us")
					task_time = next_task_time
				end
			else
				i = i + 1
			end
		end
	end
	print("Total scheduler time: "..tostring(minetest_get_us_time() - start_time).." microseconds")
	--print("priority_queue="..dump(priority_queue))
end)

