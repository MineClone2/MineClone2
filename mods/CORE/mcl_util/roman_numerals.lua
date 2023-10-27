local converter = {
	{1000, "M"},
	{900, "CM"},
	{500, "D"},
	{400, "CD"},
	{100, "C"},
	{90, "XC"},
	{50, "L"},
	{40, "XL"},
	{10, "X"},
	{9, "IX"},
	{5, "V"},
	{4, "IV"},
	{1, "I"}
}

mcl_util.to_roman = function(number)
	local r = ""
	local a = number
	local i = 1
	while a > 0 do
		if a >= converter[i][1] then
			a = a - converter[i][1]
			r = r.. converter[i][2]
		else
			i = i + 1
		end
	end
	return r
end
