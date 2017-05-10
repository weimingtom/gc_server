local rule = require "game/maajan/base/rule"
local pr = require "game/maajan/base/print_r"
local mj_util 	= {}
local switch_table = {}

switch_table["1"] = 1
switch_table["2"] = 2
switch_table["3"] = 3
switch_table["4"] = 4
switch_table["5"] = 5
switch_table["6"] = 6
switch_table["7"] = 7
switch_table["8"] = 8
switch_table["9"] = 9

switch_table["A"] = 10
switch_table["B"] = 11
switch_table["C"] = 12
switch_table["D"] = 13
switch_table["E"] = 14
switch_table["F"] = 15
switch_table["G"] = 16

switch_table["."] = 20
switch_table["&"] = 21
switch_table["!"] = 22
switch_table["@"] = 23
switch_table["#"] = 24
switch_table["$"] = 25
switch_table["%"] = 26
switch_table["="] = 27

function mj_util.arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end
function mj_util.tableCloneSimple(ori_tab)
    if (type(ori_tab) ~= "table") then
        return ori_tab;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = mj_util.tableCloneSimple(v);
        elseif (vtyp == "thread") then
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end
function mj_util.printTable(tb)
    pr(tb)
end
function mj_util.arraySortMJ(pai,anPaiIndex)
	anPaiIndex = anPaiIndex or 1
	local tmp = {}
	for i=anPaiIndex,#pai do
		tmp[#tmp + 1] = pai[i]
	end
	table.sort(tmp)
	for i=anPaiIndex,#pai do
		pai[i] = tmp[i-anPaiIndex + 1]
	end
end
function mj_util.printPai(pai)
	local str = ""
	for i,k in ipairs(pai) do
		for k1,v1 in pairs(switch_table) do
			if v1 == pai[i] then
				str = str .. k1 .. " "
			end
		end	
	end
	print(str)
end
function mj_util.getPaiStr(pai)
	local str = ""
	for i,k in ipairs(pai) do
		for k1,v1 in pairs(switch_table) do
			if v1 == pai[i] then
				str = str .. k1 .. " "
			end
		end	
	end
	return str
end

function mj_util.getActionTableWithInPai(pai, inPai)
	local action = {peng = false, anGang = false, baGang = false, hu = false, chi = false, fan = 0, pai_val = inPai}
	function action:hasAction()
		return self.peng or self.anGang or self.baGang or self.hu or self.chi
	end
	
	local pai_count = 0
	for k,v in ipairs(pai.shou_pai) do
		if v == inPai then
			pai_count = pai_count + 1
		end
	end
	if pai_count >= 2 then
		action.peng = true
	end
	if pai_count >= 3 then
		action.anGang = true
	end

	for k,v in ipairs(pai.ming_pai) do
		if #v == 3 and v[1] == v[2] and v[1] == inPai then
			action.baGang = true
		end
	end
	local info = rule.is_hu(pai,inPai)
	if #info > 0 then
		action.hu = true
		action.hu_info = info
		action.split_list = mj_util.tableCloneSimple(g_split_list)
        action.jiang_tile = g_jiang_tile
	end

	if rule.is_chi(pai,inPai) then
		action.chi = true
	end

	return action
end

function mj_util.panHu(pai, inPai)
	return rule.is_hu(pai,inPai)
end

function mj_util.panGangWithOutInPai(pai)
	local anGangList = {}
	local baGangList = {}

	local array = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
	for k,v in ipairs(pai.shou_pai) do
		if array[v] then
			array[v] = array[v] + 1
		end
	end

	for k,v in ipairs(array) do
		if v == 4 then
			anGangList[#anGangList + 1] = k
		end
	end

	for k,v in ipairs(pai.ming_pai) do
		if #v == 3 and v[1] == v[2] and array[v[1]] > 0 then
			baGangList[#baGangList + 1] = v[1]
		end
	end

	return anGangList,baGangList
end

function mj_util.panTing(pai)
	for i=1,16 do
		local info = rule.is_hu(pai,i)
		if #info > 0 then
			return true
		end
	end
	return false
end
function mj_util.panTing_14(pai)
	for k,v in pairs(pai.shou_pai) do
		local pai_tmp =  mj_util.tableCloneSimple(pai)
		pai_tmp.shou_pai[k] = pai_tmp.shou_pai[#pai_tmp.shou_pai]
		pai_tmp.shou_pai[#pai_tmp.shou_pai] = nil
		for i=1,16 do
			local info = rule.is_hu(pai,i)
			if #info > 0 then
				return true
			end
		end
	end
	return false
end
function mj_util.get_fan_table_res(base_fan_table)
	return rule.get_fan_table_res(base_fan_table)
end

return mj_util