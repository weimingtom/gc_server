local function copy_table_(src, dest)
	dest = dest or {}
    for k, v in pairs(src or {}) do
        if type(v) ~= "table" then
            dest[k] = v
        else
            dest[k] = copy_table_(v)
        end
    end
    return dest
end
copy_table = copy_table_

function print_table(tb, sp)
	print ((sp or "") .. "{")
	for k, v in pairs(tb or {}) do
        if type(v) ~= "table" then
			if type(v) == "string" then
				print (sp or "", k .. ' = "' .. v .. '"')
			elseif type(v) == "boolean" then
				print (sp or "", k .. ' = "' .. tostring(v) .. '"')
			elseif type(v) ~= "userdata" then
				print (sp or "", k .. " = " .. v)
			end
        else
			print (sp or "", k .. " = ")
            print_table(v, (sp or "") .. "\t")
        end
    end
	print ((sp or "") .. "}")
end

function serialize_table(t)
	local mark={}
	local assign={}
	
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or k
			if type(v)=="table" then
				local dotkey= parent..(type(k)=="number" and key or "."..key)
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			else
				if type(v) == "number" then 
					table.insert(tmp, key.."="..v)
				elseif type(v) == "string" then 
					table.insert(tmp, key..'="'..v..'"')
				elseif type(v) == "boolean" then 
					table.insert(tmp, key.."="..tostring(v))
				end
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
 
	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

function parse_table(str)
	--return assert(loadstring(str))() -- lua 5.1
	return assert(load(str))()
end

local cjson = require "cjson"
function load_json_file(filename)
	local f = assert(io.open(filename , "rb"))
	local buffer = f:read "*a"
	local tb = cjson.decode(buffer)
	f:close()
	return tb
end
function load_json_buffer(buffer)
	return cjson.decode(buffer)
end
function lua_to_json(tb)
    return cjson.encode(tb)
    -- body
end