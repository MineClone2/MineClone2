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

function table.find(t, item)
	for k,v in pairs(t) do
		if v == item then return k end
	end
	return nil
end

function table.intersect(a, b)
	local values_map = {}

	for _,v in pairs(a) do values_map[v] = 1 end
	for _,v in pairs(b) do values_map[v] = (values_map[v] or 0) + 1 end

	-- Get all the values that are in both tables
	local result = {}
	for v,count in pairs(values_map) do
		if count == 2 then table.insert(result, v) end
	end
	return result
end

