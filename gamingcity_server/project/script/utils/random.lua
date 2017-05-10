
local random = {}

function random.integer(min, max)
    return math.random(min, max)
end

function random.float(precision)
    precision = precision or 10000
    return random.integer(0, precision) / precision
end

function random.boost_integer(min, max)
	return boost_get_random(min,max)
end

function random.boost_01()
	return boost_get_random01()
end

math.randomseed(tostring(os.time()):reverse():sub(1, 6))

return random
