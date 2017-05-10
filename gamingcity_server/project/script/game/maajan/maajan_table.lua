local pb = require "protobuf"
require "game/lobby/base_table"
local def 		= require "game/maajan/base/define"
local mj_util 	= require "game/maajan/base/mang_jiang_util"
require "game/lobby/base_player"
local base_player = base_player
local FSM_E     = def.FSM_event
local FSM_S     = def.FSM_state
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local LOG_MONEY_OPT_TYPE_MAAJAN = pb.enum_id("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_MAAJAN") or 100

maajan_table = base_table:new()

function send2client_pb_mj(player,op_name,msg)
    send2client_pb(player,op_name,msg)
    if msg then
        print("send2client_pb : " .. op_name)
    end
end
-- 初始化
function maajan_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.cards = {
	1,2,3,4,5,6,7,8,9, 10,11,12,13,14,15,16,
	1,2,3,4,5,6,7,8,9, 10,11,12,13,14,15,16,
	1,2,3,4,5,6,7,8,9, 10,11,12,13,14,15,16, 
	1,2,3,4,5,6,7,8,9, 10,11,12,13,14,15,16, 20,21,22,23,24,25,26,27};

    self.quan_feng = 13
	-- test 
    --[[
	if table_id == 1 then
		for i = 1, 2 do
			self.player_list_[i] = {chair_id = i}
		end
		self:start(2,true)
	end
    
	
    local player = base_player:new()
	player:init(10000, "android", "android")
	player.session_id = 10000 + table_id
    player.is_android = true
    player.chair_id = 1
    player.room_id = 1
    player.table_id = table_id
    player.pb_base_info = {money = 9999999,}
    self.player_list_[1] = player
    self:ready(player)
    ]]
	-- test --
end
function maajan_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	local maajan_config = funtemp()
	self.mj_min_scale = maajan_config.mj_min_scale
end
function maajan_table:start(player_count,is_test)
	local bRet = base_table.start(self,player_count)	
	for k,v in pairs(self.player_list_) do
		if v then
			v.hu                    = false
            v.deposit               = false
            v.miao_shou_hui_chun    = false
            v.hai_di_lao_yue        = false
            v.zi_mo                 = false
            v.last_act_is_gang      = false
            v.has_done_chu_pai      = false
            v.quan_qiu_ren          = false
            v.dan_diao_jiang        = false
            v.tian_ting             = false
            v.baoting               = false
            v.finish_task           = false
            v.can_jiabei_this_chupai_round = true
            v.hua_count             = 0
            v.mo_pai_count          = 0
			v.jiabei				= 0
			v.pai                   =
            {
                shou_pai = {},
                ming_pai = {},
                hua_pai = {},
                desk_tiles = {}
            }

            if is_test then
                v.deposit   = true
            end
		end
	end
    self.timer = {}
    self.task = {
        tile = 0,
        type = 0
    }
	self.gongPai = {}
	self.cur_state_FSM             = FSM_S.PER_BEGIN
	self.chu_pai_player_index      = 1 --出牌人的索引   
	self.last_chu_pai              = -1 --上次的出牌
	self.player_action_table       = {}
	self.last_action_change_time_stamp = os.time() --上次状态 更新的 时间戳
	self.zhuang = math.random(1,2)
	self.record                = {}
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
    self.quan_feng = self.quan_feng + 1 
    if self.quan_feng > 13 then self.quan_feng = 10 end
    self.table_game_id = self:get_now_game_id()
    self:next_game()
    self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
        quan_feng = self.quan_feng,
        task = self.task,
        mj_min_scale = self.mj_min_scale,
        action_table = {},
        players = {
            {},
            {}
        },
    }
end

function maajan_table:notify_offline(player)
    if self.do_logic_update then
        player.deposit = true
        self:broadcast2client("SC_Maajan_Act_Trustee",{chair_id = player.chair_id,is_trustee = player.deposit})
    else
        self.room_:player_exit_room(player)
    end
end
-- 检查是否可取消准备
function maajan_table:check_cancel_ready(player, is_offline)
	if self.do_logic_update then
		return false
	end
	return true
end
function maajan_table:isPlay( ... )
	if self.do_logic_update then
		return true
	end
	return false
end

function maajan_table:reconnect(player)
    self:clear_deposit_and_time_out(player)
end

function maajan_table:tick()
	-- test --
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
		print("player count", tmp_player_count)
        self.old_player_count = tmp_player_count
	end
    -- test --

	if self.do_logic_update then
		self:safe_event({type = FSM_E.UPDATE})
        local dead_list = {}
        for k,v in pairs(self.timer) do
            if os.time() > v.dead_line then
                v.execute()
                dead_list[#dead_list + 1] = k
            end
        end
        for k,v in pairs(dead_list) do
            self.timer[v] = nil
        end
    else
        self.Maintain_time = self.Maintain_time or get_second_time()
        if get_second_time() - self.Maintain_time > 5 then
            self.Maintain_time = get_second_time()
            for _,v in ipairs(self.player_list_) do
                if v then
                    --维护时将准备阶段正在匹配的玩家踢出
                    local iRet = base_table:onNotifyReadyPlayerMaintain(v)--检查游戏是否维护
                end
            end
        end
	end
end
function maajan_table:clear_deposit_and_time_out(player)
    if player.deposit then
        player.deposit = false
        self:broadcast2client("SC_Maajan_Act_Trustee",{chair_id = player.chair_id,is_trustee = player.deposit})
    end
    player.time_out_count = 0
end
function maajan_table:increase_time_out_and_deposit(player)
    player.time_out_count = player.time_out_count or 0
    if player.time_out_count >= 2 then
        player.deposit = true
        player.time_out_count = 0
    end
end
--胡
function maajan_table:on_cs_act_win(player, msg)
    self:clear_deposit_and_time_out(player)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.HU})
end
--加倍
function maajan_table:on_cs_act_double(player, msg)
    local msg_t = msg or {tile = player.pai.shou_pai[#player.pai.shou_pai]}
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.JIA_BEI,tile = msg_t.tile})
end
--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and msg.tile >= 0 then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.CHU_PAI,tile = msg.tile})
    end
end
--碰
function maajan_table:on_cs_act_peng(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.PENG})
end
--杠
function maajan_table:on_cs_act_gang(player, msg)
    if msg and msg.tile and msg.tile >= 0 then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = msg.tile})
    end
end
--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.PASS})
end
--吃
function maajan_table:on_cs_act_chi(player, msg)
    if msg and msg.tiles and #msg.tiles == 3 then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI,tiles = msg.tiles})
    end
end
--托管
function maajan_table:on_cs_act_trustee(player, msg)
    self:clear_deposit_and_time_out(player)
end
--报听
function maajan_table:on_cs_act_baoting(player, msg)
    if not player.baoting then
        self:clear_deposit_and_time_out(player)
        player.baoting = true
        self:broadcast2client("SC_Maajan_Act_BaoTing",{chair_id = player.chair_id,is_ting = player.baoting})
    end
end

function maajan_table:safe_event(...)
    -- test --
    self:FSM_event(...)
   --[[
    local ok = xpcall(maajan_table.FSM_event,function() print(debug.traceback()) end,self,...)
    if not ok then
        print("safe_event error") 
        self:update_state(FSM_S.GAME_ERR)
    end
    ]]
end

function maajan_table:broad_cast_desk_state()
    if self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM == FSM_S.XI_PAI 
    or self.cur_state_FSM == FSM_S.WAIT_MO_PAI or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
        return
    end
    self:broadcast2client("SC_Maajan_Desk_State",{state = self.cur_state_FSM})
end

function maajan_table:broad_cast_player_hu(player,is_ba_gang_hu)
    assert(player.hu)
    player.is_ba_gang_hu = is_ba_gang_hu
    local msg = {chair_id = player.chair_id, tile = player.hu_pai,ba_gang_hu = 0}
    if is_ba_gang_hu then
        msg.ba_gang_hu = 1
    end
    self:broadcast2client("SC_Maajan_Act_Win",msg)
end
function maajan_table:player_jiabei(player)
    player.jiabei = player.jiabei + 1
    self:broadcast2client("SC_Maajan_Act_Double",{chair_id = player.chair_id,jiabei_val = player.jiabei})
end

function maajan_table:player_is_activity(player)
	return not player.is_android
end

function maajan_table:update_state(new_state)
    self.cur_state_FSM = new_state
    self.last_action_change_time_stamp = os.time()
    self:broad_cast_desk_state()
    if self.cur_state_FSM == FSM_S.WAIT_CHU_PAI then 
        local player = self.player_list_[self.chu_pai_player_index]
        player.can_jiabei_this_chupai_round = true
        self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    end
end

function maajan_table:update_state_delay(new_state,delay_seconds)
	self:update_state(new_state)
	
	--[[
    self.cur_state_FSM = new_state + FSM_S.GAME_IDLE_HEAD

    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute = function()
        update_state(self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD)
    end
    self.timer[#self.timer + 1] = act
	]]
end

function maajan_table:is_action_time_out()
    -- test --
    return false
    --[[
    local time_out = (os.time() - self.last_action_change_time_stamp) >= def.ACTION_TIME_OUT 
    return time_out
    ]]
end

function maajan_table:increase_chu_pai_player_index()
	self.chu_pai_player_index = self.chu_pai_player_index + 1
	if self.chu_pai_player_index > 2 then self.chu_pai_player_index = 1 end
end

function maajan_table:adjust_shou_pai(player, adjust_type, targetPais, targetPaisEx)
    local adjust_count = 0
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai
   
    local msg = {chair_id=player.chair_id, tiles=targetPais}
    if "anGang" == adjust_type then 
        for k,v in ipairs(targetPais) do
            for k1,v1 in ipairs(shou_pai) do
                if v == v1 then
                    shou_pai[k1],shou_pai[#shou_pai] = shou_pai[#shou_pai],shou_pai[k1]
                    shou_pai[#shou_pai] = nil
                    break
                end
            end
        end

        if targetPaisEx then
            targetPais[5] = def.GANG_TYPE.AN_GANG --暗杠,自己
        else
            targetPais[5] = def.GANG_TYPE.MING_GANG --暗杠,其他人
        end
        ming_pai[#ming_pai+1] = targetPais
        self:broadcast2client("SC_Maajan_Act_Gang",{chair_id = player.chair_id,tile = targetPais[1],type = targetPais[5]})
        player.last_act_is_gang = true
    end
    if "baGang" == adjust_type then 
        for k,v in ipairs(shou_pai) do
            if v == targetPais[1] then
                shou_pai[k],shou_pai[#shou_pai] = shou_pai[#shou_pai],shou_pai[k]
                shou_pai[#shou_pai] = nil
                break
            end
        end

        targetPais[5] = def.GANG_TYPE.BA_GANG --巴杠
        for k,v in ipairs(ming_pai) do
            if v[1] == targetPais[1] then
                ming_pai[k] = targetPais
                break
            end
        end
        self:broadcast2client("SC_Maajan_Act_Gang",{chair_id = player.chair_id,tile = targetPais[1],type = targetPais[5]})
        player.last_act_is_gang = true        
    end
    if "peng" == adjust_type then 
        local do_count = 0
        for k,v in ipairs(targetPais) do
            for k1,v1 in ipairs(shou_pai) do
                if v == v1 then
                    shou_pai[k1],shou_pai[#shou_pai] = shou_pai[#shou_pai],shou_pai[k1]
                    shou_pai[#shou_pai] = nil
                    do_count = do_count + 1
                    break
                end
            end
            if do_count == 2 then
               break
            end
        end

        ming_pai[#ming_pai+1] = targetPais
        
        self:broadcast2client("SC_Maajan_Act_Peng",{chair_id = player.chair_id,tile = targetPais[1]})
    end
    if "chi" == adjust_type then 
        local do_count = 0
        for k,v in ipairs(targetPais) do
            for k1,v1 in ipairs(shou_pai) do
                if v == v1 and targetPaisEx ~= v1 then
                    shou_pai[k1],shou_pai[#shou_pai] = shou_pai[#shou_pai],shou_pai[k1]
                    shou_pai[#shou_pai] = nil
                    do_count = do_count + 1
                    break
                end
            end
            if do_count == 2 then
               break
            end
        end

        ming_pai[#ming_pai+1] = targetPais
        self:broadcast2client("SC_Maajan_Act_Chi",{chair_id = player.chair_id,tile = targetPaisEx,tiles = targetPais})
    end
	table.sort(shou_pai)
end

function maajan_table:get_shou_pai_pos(player,pai_val)
    local chu_pai_pos = -1
    for k,v in ipairs(player.pai.shou_pai) do
        if pai_val == v then
            chu_pai_pos = k
            break
        end
    end
    return chu_pai_pos 
end

--掉线，离开，自动胡牌
function maajan_table:auto_act_if_deposit(player,type)
    local delay_seconds = 2
    if player.deposit then
        if "hu_mo_pai" == type or "hu_ba_gang" == type or "hu_chu_pai" == type then
			local hu_info = 0
            if "hu_mo_pai" == type then hu_info = mj_util.panHu(player.pai) end
			if "hu_ba_gang" == type or "hu_chu_pai" == type then 
				hu_info = mj_util.panHu(player.pai,self.last_chu_pai) 
			end
            if #hu_info > 0 then
                local act = {}
                act.dead_line = os.time() + delay_seconds
                act.execute = function()
                    self:safe_event({chair_id = player.chair_id,type = FSM_E.HU})  
                end
                self.timer[#self.timer + 1] = act
            end
        elseif "gang_mo_pai" == type then
            -- test --
			local act = {}
            act.dead_line = os.time() + delay_seconds
            act.execute = function()
                self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = player.pai.shou_pai[#(player.pai.shou_pai)]})  
            end
            self.timer[#self.timer + 1] = act
            -- test --
        elseif "gang_chu_pai" == type then
            -- test --
			local act = {}
            act.dead_line = os.time() + delay_seconds
            act.execute = function()
                self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = self.last_chu_pai})  
            end
            self.timer[#self.timer + 1] = act
            -- test --
		elseif "peng_chu_pai" == type then
            -- test --
			local act = {}
            act.dead_line = os.time() + delay_seconds
            act.execute = function()
                self:safe_event({chair_id = player.chair_id,type = FSM_E.PENG})  
            end
            self.timer[#self.timer + 1] = act
            -- test --
        elseif "chi_chu_pai" == type then
            -- test --
			local act = {}
            act.dead_line = os.time() + delay_seconds
            act.execute = function()
                self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai,self.last_chu_pai+1,self.last_chu_pai+2}})
                self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai-1,self.last_chu_pai,self.last_chu_pai+1}})
                self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai-2,self.last_chu_pai-1,self.last_chu_pai}})  
            end
            self.timer[#self.timer + 1] = act
            -- test --
        end
    end
end
--执行 出牌
function maajan_table:do_chu_pai(chu_pai_val)
    if not chu_pai_val then return end
    local player = self.player_list_[self.chu_pai_player_index]
    local chu_pai_pos = self:get_shou_pai_pos(player,chu_pai_val)
    if player.baoting and chu_pai_pos ~= #player.pai.shou_pai then 
        --log_info(string.format("player %d do_chu_pai err baoting",player.guid))
        --return 
    end
    print(string.format("---------chu pai index: %d ------",self.chu_pai_player_index))
    print(string.format("---------chu pai val:   %s ------",mj_util.getPaiStr({chu_pai_val})))
    if chu_pai_pos ~= -1 then
        player.pai.shou_pai[chu_pai_pos] = player.pai.shou_pai[#player.pai.shou_pai]
        player.pai.shou_pai[#player.pai.shou_pai] = nil
        self.last_chu_pai = chu_pai_val --上次的出牌
        table.insert(player.pai.desk_tiles,self.last_chu_pai)
        self:broadcast2client("SC_Maajan_Act_Discard",{chair_id = player.chair_id, tile = self.last_chu_pai})
		table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = self.last_chu_pai}})
        self.player_action_table = {}
        for k,v in pairs(self.player_list_) do
            if v and k ~= self.chu_pai_player_index and (not v.hu) then --排除自己
                local act = mj_util.getActionTableWithInPai(v.pai, self.last_chu_pai)
                act.baGang = false -- 别人出的牌  不能巴杠
                act.chair_id = v.chair_id
				v.split_list = act.split_list
				v.jiang_tile = act.jiang_tile
                v.hu_info = act.hu_info
                if act.hu then
                    if v.mo_pai_count == 0 then
                        v.ren_hu = true
                    end
                    if #self.gongPai == 0 then
                        v.hai_di_lao_yue = true
                    end
                    if #v.pai.shou_pai <= 2 then
                        v.quan_qiu_ren = true
                        for k1,v1 in pairs(v.pai.ming_pai) do
                            if #v1 > 4 and v1[5] == def.GANG_TYPE.AN_GANG then
                                v.quan_qiu_ren = false
                            end
                        end
                        if not v.quan_qiu_ren then
                            v.dan_diao_jiang = true
                        end
                    end
                    if not self:hu_fan_match(v) then
                        act.hu = false
                        v.ren_hu = false
                        v.hai_di_lao_yue = false
                        v.quan_qiu_ren = false
                        v.dan_diao_jiang = false
                    end
                end
                if act:hasAction() then
                    self.player_action_table = act
                    if act.hu then
						self:auto_act_if_deposit(v,"hu_chu_pai")
                    elseif act.anGang then
						self:auto_act_if_deposit(v,"gang_chu_pai")
					elseif act.peng then
						self:auto_act_if_deposit(v,"peng_chu_pai")
                    elseif act.chi then
						self:auto_act_if_deposit(v,"chi_chu_pai")
                    end
                end
            end
        end
        
        if self.player_action_table.chair_id == nil then
            self:increase_chu_pai_player_index()
            self:update_state_delay(FSM_S.WAIT_MO_PAI,1)
        else
            self:update_state_delay(FSM_S.WAIT_PENG_GANG_HU_CHI,1)
        end

        player.last_act_is_gang = false
        player.has_done_chu_pai = true -- 出过牌了，判断地胡用
    else
        log_info(string.format("player %d chu_pai error",player.chair_id)) 
    end
end

function maajan_table:judge_action_peng_gang_hu_chi_bei_after_event(param)
    local act = self.player_action_table
    local act_player = self.player_list_[act.chair_id]

    local desk_tile_delete = function ()
        local len = #(self.player_list_[self.chu_pai_player_index].pai.desk_tiles)
        if len ~= 0 then
            self.player_list_[self.chu_pai_player_index].pai.desk_tiles[len] = nil 
        end
    end
    if act.peng and act.do_peng then
        desk_tile_delete()
        self:adjust_shou_pai(act_player,"peng",{self.last_chu_pai,self.last_chu_pai,self.last_chu_pai}) 
        self:increase_chu_pai_player_index()
        self:update_state(FSM_S.WAIT_CHU_PAI)
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Peng",msg = {tile = self.last_chu_pai}}) 
    elseif act.anGang and act.do_gang then
        desk_tile_delete()
        self:adjust_shou_pai(act_player,"anGang",{self.last_chu_pai,self.last_chu_pai,self.last_chu_pai,self.last_chu_pai}) 
        self:increase_chu_pai_player_index()
        self:update_state(FSM_S.WAIT_MO_PAI) 
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "MingGang",msg = {tile = self.last_chu_pai}})
    elseif act.hu and act.do_hu then
        desk_tile_delete()
        act_player.hu = true
        act_player.hu_time = os.time()
        act_player.hu_pai = self.last_chu_pai
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Hu",msg = {tile = self.last_chu_pai}})
        self:broad_cast_player_hu(act_player,false)
        self:update_state_delay(FSM_S.GAME_BALANCE,1)
    elseif act.chi and act.do_chi then
        local shou_pai_array = {}
        for k,v in ipairs(act_player.pai.shou_pai) do
            shou_pai_array[v] = shou_pai_array[v] or 0
            shou_pai_array[v] = shou_pai_array[v] + 1
        end
        local b_is_valid_param = true
        table.sort(param)
        for k,v in ipairs(param) do
            if v ~= self.last_chu_pai then
                 local cc = shou_pai_array[v] or 0
                 if cc <= 0 then b_is_valid_param = false break end
            end
        end
        if (param[1] + 1 ~= param[2]) or (param[1] + 2 ~= param[3]) then
            b_is_valid_param = false
        end
       
        if b_is_valid_param then
            desk_tile_delete()
            self:adjust_shou_pai(act_player,"chi",param,self.last_chu_pai) 
            self:increase_chu_pai_player_index()
            self:update_state(FSM_S.WAIT_CHU_PAI) 
            table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Chi",msg = {tile = self.last_chu_pai,tiles = param}})
        end
    elseif act.hu and act.do_jiabei then
        act_player.ren_hu = false
        act_player.hai_di_lao_yue = false
        act_player.quan_qiu_ren = false
        act_player.dan_diao_jiang = false
        self:player_jiabei(act_player)
        self:increase_chu_pai_player_index()
        self:update_state(FSM_S.WAIT_MO_PAI)
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "JiaBei",msg = {tile = self.last_chu_pai}}) 
    elseif act.do_pass then
        act_player.ren_hu = false
        act_player.hai_di_lao_yue = false
        act_player.quan_qiu_ren = false
        act_player.dan_diao_jiang = false
        self:increase_chu_pai_player_index()
        self:update_state(FSM_S.WAIT_MO_PAI) 
    end
end

function maajan_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {}
    msg.state = self.cur_state_FSM
    msg.zhuang = self.zhuang
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = def.ACTION_TIME_OUT
    msg.decision_time_limit = def.ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
    msg.pb_task_data = {
        task_type = self.task.type,
	    task_tile = self.task.tile,
	    task_scale = 2
    }
    msg.pb_players = {}
    for k,v in pairs(self.player_list_) do
        if v then
            local tplayer = {}
            tplayer.chair_id = v.chair_id
            tplayer.desk_pai = v.pai.desk_tiles
            tplayer.pb_ming_pai = {}
            for k1,v1 in pairs(v.pai.ming_pai) do
                tplayer.pb_ming_pai[#tplayer.pb_ming_pai + 1] = {tiles = v1}
            end
            tplayer.hua_pai = v.pai.hua_pai
            tplayer.shou_pai = {}
            for k1,v1 in ipairs(v.pai.shou_pai) do
                if v.chair_id == player.chair_id then
                    tplayer.shou_pai[k1] = v1
                else
                    tplayer.shou_pai[k1] = 255
                end
            end
            tplayer.is_ting = v.baoting
            table.insert(msg.pb_players,tplayer)
        end
    end
    if is_reconnect then
        msg.pb_rec_data = {}
        msg.pb_rec_data.act_left_time = self.last_action_change_time_stamp + def.ACTION_TIME_OUT - os.time()   
        if msg.pb_rec_data.act_left_time < 0 then msg.pb_rec_data.act_left_time = 0 end   
        msg.pb_rec_data.chu_pai_player_index = self.chu_pai_player_index
        msg.pb_rec_data.last_chu_pai = self.last_chu_pai
    end
    send2client_pb_mj(player,"SC_Maajan_Desk_Enter",msg)
    if is_reconnect then
        send2client_pb_mj(player,"SC_Maajan_Tile_Letf",{tile_left = #self.gongPai})
        for k,v in pairs(self.player_list_) do
            if v and v.baoting then
                send2client_pb_mj(player,"SC_Maajan_Act_BaoTing",{chair_id = v.chair_id,is_ting = v.baoting})
            end
        end
    end
end
function maajan_table:ReconnectionPlayMsg(player)
	log_info("player Reconnection : ".. player.chair_id)
	base_table.ReconnectionPlayMsg(self,player)
    self:send_data_to_enter_player(player,true)
end

--获取当前出牌玩家手上花牌的位置
function maajan_table:get_hua_pai_from_cur_player()
	local player = self.player_list_[self.chu_pai_player_index]
	for k,v in pairs(player.pai.shou_pai) do
		if v >= 20 then
			return k,v
		end
	end
end
function maajan_table:player_finish_task(player)
    local done = false
    local tile = self.task.tile
    if self.task.type == FSM_E.CHI then
        for k,v in pairs(player.pai.ming_pai) do
            if #v == 3 and v[1] ~= v[2] and v[1] ~= v[3] and (tile == v[1] or tile == v[2] or tile == v[3]) then
                done = true break
            end
        end
    elseif self.task.type == FSM_E.PENG then
        for k,v in pairs(player.pai.ming_pai) do
            if #v == 3 and v[1] == v[2] and v[1] == v[3] and tile == v[1] then
                done = true break
            end
        end
    elseif self.task.type == FSM_E.HU then
        if player.hu_pai == tile then
            done = true
        end
    end
    return done
end
function maajan_table:hu_fan_match(player)
    self:calculate_hu(player)
    if player.fan >= self.mj_min_scale then
        return true
    end
    return false
end
function maajan_table:calculate_hu(player)
    local v = player
    local hu_info = mj_util.tableCloneSimple(player.hu_info)
    local card_type = def.CARD_HU_TYPE_INFO
    if #(v.pai.hua_pai) == 8 then --全花
        table.insert(hu_info,card_type.QUAN_HUA)
    else
        for i=1,#(v.pai.hua_pai) do
            table.insert(hu_info,card_type.HUA_PAI)
        end
    end
    if v.tian_hu then--天胡
        table.insert(hu_info,card_type.TIAN_HU)
    elseif v.di_hu then--地胡
        table.insert(hu_info,card_type.DI_HU)
    elseif v.ren_hu then--人胡
        table.insert(hu_info,card_type.REN_HU)
    end
    if v.tian_ting then--天听
        table.insert(hu_info,card_type.TIAN_TING)
    end
    if v.baoting then--报听
        table.insert(hu_info,card_type.BAO_TING)
    end
    if v.qiang_gang_hu then
        table.insert(hu_info,card_type.QIANG_GANG_HU)
    end
    if v.miao_shou_hui_chun then
        table.insert(hu_info,card_type.MIAO_SHOU_HUI_CHUN)
    end
    if v.hai_di_lao_yue then
        table.insert(hu_info,card_type.HAI_DI_LAO_YUE)
    end
    if v.gang_shang_hua then
        table.insert(hu_info,card_type.GANG_SHANG_HUA)
    end
    if v.quan_qiu_ren then
        table.insert(hu_info,card_type.QUAN_QIU_REN)
    elseif v.dan_diao_jiang then
        table.insert(hu_info,card_type.DAN_DIAO_JIANG)
    end
    -- 一般高 --
    local shun_zi_count = {}
    for k1,v1 in pairs(v.pai.ming_pai) do
        if v1[1] ~= v1[2] then
            shun_zi_count[v1[1]] = shun_zi_count[v1[1]] or 0
            shun_zi_count[v1[1]] = shun_zi_count[v1[1]] + 1
        end
    end
    for k1,v1 in pairs(shun_zi_count) do
        if v1 >= 2 then
            table.insert(hu_info,card_type.YI_BAN_GAO)
        end
    end
    -- 一般高 --
    -- 四归一 --
    local si_gui_count = {}
    for k1,v1 in pairs(v.pai.ming_pai) do
        for k2,v2 in pairs(v1) do
            if k2 < 4 then
                si_gui_count[v2] = si_gui_count[v2] or 0 
                si_gui_count[v2] = si_gui_count[v2] + 1
            end
        end
    end
    for k1,v1 in pairs(v.pai.shou_pai) do
        si_gui_count[v1] = si_gui_count[v1] or 0 
        si_gui_count[v1] = si_gui_count[v1] + 1
    end

    for k1,v1 in pairs(si_gui_count) do
        if v1 >= 4 then
            table.insert(hu_info,card_type.SI_GUI_YI)
		end
    end
    -- 四归一 --
    -- 断幺 --
    local duan_yao = true
    for k1,v1 in pairs(v.pai.ming_pai) do
        for k2,v2 in pairs(v1) do
            if k2 < 5 and (v2 == 1 or v2 == 9 or (v2 >= 14 and v2 <= 16)) then
                duan_yao = false
            end
        end
    end
    for k1,v1 in pairs(v.pai.shou_pai) do
        if (v1 == 1 or v1 == 9 or (v1 >= 14 and v1 <= 16)) then
            duan_yao = false
        end
    end
    if duan_yao then
        table.insert(hu_info,card_type.DUAN_YAO)
    end
    -- 断幺 --
    -- 暗杠 --
    local four_an_gang_count = 0
    for k1,v1 in pairs(v.pai.ming_pai) do
        if #v1 > 4 and v1[5] == def.GANG_TYPE.AN_GANG then
            four_an_gang_count = four_an_gang_count + 1
        end
    end
    if four_an_gang_count > 0 then
        for i=1,four_an_gang_count do
            table.insert(hu_info,card_type.ZI_AN_GANG)
        end
    end
    -- 双暗杠 --
    if four_an_gang_count >=2 then 
        table.insert(hu_info,card_type.SHUANG_AN_GANG)
    end
    -- 双暗杠 --
    -- 双明杠 --
    local four_count = 0
    for k1,v1 in pairs(v.pai.ming_pai) do
        if #v1 >= 4 then four_count = four_count + 1 end
    end
    if four_count >=2 then 
        table.insert(hu_info,card_type.SHUANG_MING_GANG)
    end
    -- 双明杠 --
    -- 胡绝张 --
    local jue_count = 0
    for k1,v1 in pairs(self.gongPai) do
        if v1 == v.hu_pai then
            jue_count = 1
            break
        end
    end
    if jue_count == 0 then
        table.insert(hu_info,card_type.HU_JUE_ZHANG)
    end                    
    -- 胡绝张 --
    -- 不求人 --
    if v.zi_mo then
        v.bu_qiu_ren = true
        for k1,v1 in pairs(v.pai.ming_pai) do
            if #v1 < 4 or (#v1 >= 4 and v1[5] ~= def.GANG_TYPE.AN_GANG) then
                v.bu_qiu_ren = false
            end
        end
        if v.bu_qiu_ren then
            table.insert(hu_info,card_type.BU_QIU_REN)
        end
    end
    -- 不求人 --
    if v.zi_mo then
        table.insert(hu_info,card_type.ZI_MO)
    end

    local men_feng_ke = false
    local quan_feng_ke = false
    for k,val in ipairs(v.split_list) do
        if #val == 3 and val[1] == val[2] then
            if val[1] == self.quan_feng then
                quan_feng_ke = true
            end
            if v.chair_id == self.zhuang and val[1] == 10 then
                men_feng_ke = true
            elseif v.chair_id ~= self.zhuang and val[1] == 12 then
                men_feng_ke = true
            end
        end
    end
    if men_feng_ke then--门风刻
        table.insert(hu_info,card_type.MEN_FENG_KE)
    elseif quan_feng_ke then--圈风刻
        table.insert(hu_info,card_type.QUAN_FENG_KE)
    end
   
    local res = mj_util.get_fan_table_res(hu_info)
    v.fan = res.fan
    v.describe = res.describe
    if self:player_finish_task(v) then
        v.fan = v.fan * 2
        v.finish_task = true
    end
    for i=1,v.jiabei do
        v.fan = v.fan * 2
    end
end
function maajan_table:FSM_event(event_table)
    if self.cur_state_FSM ~= FSM_S.GAME_CLOSE then
        for k,v in pairs(FSM_E) do
            if event_table.type == v then
            --print("cur event is " .. k)
            end
        end

        if self.last_act ~= self.cur_state_FSM then
            for k,v in pairs(FSM_S) do
                if self.cur_state_FSM == v then
                    print("cur state is " .. k)
                    for k1,v1 in pairs(self.player_list_) do
                        if v1 and v1.pai then 
                            mj_util.printPai(v1.pai.shou_pai) -- test --
							local str = ""
							for k,v in pairs(v1.pai.ming_pai) do
								str = str .. " #" .. mj_util.getPaiStr(v)
							end
							if #str > 0 then print(str)	end
                       end
                    end
                end
            end
            self.last_act = self.cur_state_FSM
        end
    end
    
    if self.cur_state_FSM == FSM_S.PER_BEGIN then
        if event_table.type == FSM_E.UPDATE then
            self:update_state_delay(FSM_S.XI_PAI,1)
        else 
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type)
        end
    elseif self.cur_state_FSM == FSM_S.XI_PAI then
        if event_table.type == FSM_E.UPDATE then
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			local k = #self.cards
			for i=1,2 do
				for j=1,13 do
					local r = math.random(k)
					self.player_list_[i].pai.shou_pai[j] = self.cards[r]
					if r ~= k then
						self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
					end
					k = k-1
				end
			end

			local r = math.random(k)
			self.player_list_[self.zhuang].pai.shou_pai[#(self.player_list_[self.zhuang].pai.shou_pai) + 1] = self.cards[r]
			if r ~= k then
				self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
			end
			k = k-1

            for i=1,k do
				self.gongPai[i] = self.cards[i]
			end

            while true do
                r = math.random(k)
                local tile = self.gongPai[r]
                if tile <= 9 then
                    local act = {FSM_E.CHI,FSM_E.PENG,FSM_E.HU}
                    self.task.tile = tile
                    self.task.type = act[math.random(#act)]
                    break
                elseif self.gongPai[r] <= 16 then
                    local act = {FSM_E.PENG,FSM_E.HU}
                    self.task.tile = tile
                    self.task.type = act[math.random(#act)]
                    break
                end
            end
            
            -- test --
            self.zhuang = 1
            self.player_list_[1].pai.shou_pai = {1,2,3,4,5,6,7,8,9,10,10,10, 12,13}
			--self.player_list_[1].pai.ming_pai = {{11,11,11,}}
            self.player_list_[2].pai.shou_pai = {1,2,3,4,5,6,7,8,9,10,10, 11,13}
            self.gongPai = {12,12,12,10,10,}
            -- test --
            for k,v in pairs(self.player_list_) do
                if v then self:send_data_to_enter_player(v) end 
            end
        
			self.chu_pai_player_index = self.zhuang
			self:update_state_delay(FSM_S.BU_HUA_BIG,5)

            for k,v in pairs(self.player_list_) do
                if v then self.game_log.players[k].start_pai = mj_util.tableCloneSimple(v.shou_pai)  end   
            end
            self.game_log.start_gong_pai = mj_util.tableCloneSimple(self.gongPai)
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.BU_HUA_BIG then
        local bu_hu_count = 0
        local bu_hua_table_01 = {{tiles = {}},{tiles = {}}}
        local bu_hua_table_02 = {{tiles = {}},{tiles = {}}}
        for k,v in pairs(self.player_list_) do
            while true do
                if v then
                    for k1,v1 in pairs(v.pai.shou_pai) do
                        if v1 >= 20 then
                            local mo_pai = self.gongPai[#self.gongPai]
                            self.gongPai[#self.gongPai] = nil
                            local player_pai = v.pai.shou_pai
                            player_pai[k1] = mo_pai

                            if k == 1 then
                                table.insert(bu_hua_table_01[k].tiles,v1)
                                table.insert(bu_hua_table_01[k].tiles,mo_pai)
                                table.insert(bu_hua_table_02[k].tiles,v1)
                                table.insert(bu_hua_table_02[k].tiles,255)
                            else
                                table.insert(bu_hua_table_01[k].tiles,v1)
                                table.insert(bu_hua_table_01[k].tiles,255)
                                table.insert(bu_hua_table_02[k].tiles,v1)
                                table.insert(bu_hua_table_02[k].tiles,mo_pai)
                            end
                            
                            table.insert(v.pai.hua_pai,v1)
                            print(string.format( "bu hua %s %s",mj_util.getPaiStr({v1}),mj_util.getPaiStr({mo_pai})))
                            bu_hu_count = bu_hu_count + 1
                        end
                    end 
                    local bu_hu_finish = true
                    for k1,v1 in pairs(v.pai.shou_pai) do
                        if v1 >= 20 then
                            bu_hu_finish = false break
                        end
                    end
                    if bu_hu_finish then break end
                end
            end
        end
        if bu_hu_count > 0 then
            send2client_pb_mj(self.player_list_[1],"SC_Maajan_Bu_Hua",{pb_bu_hu = bu_hua_table_01})
            send2client_pb_mj(self.player_list_[2],"SC_Maajan_Bu_Hua",{pb_bu_hu = bu_hua_table_02})

            self.game_log.players[1].bu_hua = mj_util.tableCloneSimple(bu_hua_table_01) 
            self.game_log.players[2].bu_hua = mj_util.tableCloneSimple(bu_hua_table_02)   
        end
        for k,v in ipairs(self.player_list_) do
            if v then 
                if k == self.zhuang then
                    v.tian_ting = mj_util.panTing_14(v.pai)
                else
                    v.tian_ting = mj_util.panTing(v.pai)
                end
            end
        end
        self:update_state_delay(FSM_S.WAIT_CHU_PAI,bu_hu_count)    
        -- test --
        --self:update_state_delay(FSM_S.GAME_CLOSE,bu_hu_count)
        -- test --
    elseif self.cur_state_FSM == FSM_S.WAIT_MO_PAI then
        if event_table.type == FSM_E.UPDATE then
            local mo_pai_table = {}
            local mo_pai_table_dis = {}
            local shou_pai = self.player_list_[self.chu_pai_player_index].pai.shou_pai
            repeat
                local len = #self.gongPai print("-------left pai " .. len .. " tile")
                if len > 0 then
                    self.player_list_[self.chu_pai_player_index].mo_pai_count = self.player_list_[self.chu_pai_player_index].mo_pai_count + 1
                    local mo_pai = self.gongPai[len]
                    self.gongPai[len] = nil
                    table.sort(shou_pai)
                    shou_pai[#(shou_pai) + 1] = mo_pai
                    table.insert(mo_pai_table,mo_pai)
                    table.insert(mo_pai_table_dis,255)
                    print(string.format("---------mo pai:  %s ------",mj_util.getPaiStr({mo_pai})))
                    local pos,tile = self:get_hua_pai_from_cur_player()
                    if pos then
                        -- 继续
                        shou_pai[pos] = nil
                        table.insert(mo_pai_table,tile)
                        table.insert(mo_pai_table_dis,tile)
                        table.insert(self.player_list_[self.chu_pai_player_index].pai.hua_pai,tile)
                        print(string.format( "bu hua %s",mj_util.getPaiStr({tile})))
                    else
                        self:update_state(FSM_S.WAIT_CHU_PAI)
                        break
                    end
                else
                    self:update_state(FSM_S.GAME_BALANCE)
                    break
                end    
            until (false)
            self:auto_act_if_deposit(self.player_list_[self.chu_pai_player_index],"hu_mo_pai")
            self:auto_act_if_deposit(self.player_list_[self.chu_pai_player_index],"gang_mo_pai")
            self:broadcast2client("SC_Maajan_Tile_Letf",{tile_left = #self.gongPai})
            for k,v in pairs(self.player_list_) do
                if v and v.chair_id == self.chu_pai_player_index and #mo_pai_table > 0 then
                    send2client_pb_mj(v,"SC_Maajan_Draw",{tiles = mo_pai_table})
					table.insert(self.game_log.action_table,{chair = k,act = "Draw",msg = {tiles = mo_pai_table}})
                elseif v  and #mo_pai_table_dis > 0 then
                    send2client_pb_mj(v,"SC_Maajan_Draw",{tiles = mo_pai_table_dis})
                end
            end            
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end  
    elseif self.cur_state_FSM == FSM_S.WAIT_CHU_PAI then
        assert(self.player_list_[self.chu_pai_player_index].hu == false)
        if event_table.type == FSM_E.UPDATE then
            if self:is_action_time_out() then
                local last_index = #(self.player_list_[self.chu_pai_player_index].pai.shou_pai)
                self:do_chu_pai(self.player_list_[self.chu_pai_player_index].pai.shou_pai[last_index])
                self:increase_time_out_and_deposit(self.player_list_[self.chu_pai_player_index])
            end
        elseif event_table.type == FSM_E.CHU_PAI then
            self:do_chu_pai(event_table.tile)
        elseif event_table.type == FSM_E.GANG then --自杠 巴杠
            local cur_chu_pai_player = self.player_list_[self.chu_pai_player_index]
            if cur_chu_pai_player.chair_id == event_table.chair_id then
                self.player_list_[self.chu_pai_player_index].last_act_is_gang = false
                local anGangList,baGangList = mj_util.panGangWithOutInPai(cur_chu_pai_player.pai)
                for _,gp in ipairs(anGangList) do
                    if event_table.tile == gp then
                        self:update_state(FSM_S.WAIT_MO_PAI)
                        self:adjust_shou_pai(cur_chu_pai_player,"anGang",{gp,gp,gp,gp},true)
                        break
                    end
                end
                
                for _,gp in ipairs(baGangList) do
                    if event_table.tile == gp then
                        self.last_chu_pai = gp
                        self:adjust_shou_pai(cur_chu_pai_player,"baGang",{gp,gp,gp,gp})

                        local hu_player = {}
                        self.player_action_table = {}
                        for k,v in pairs(self.player_list_) do
                            if v and k ~= self.chu_pai_player_index then --排除自己
                                local act = mj_util.getActionTableWithInPai(v.pai, self.last_chu_pai)
                                act.baGang = false -- 别人出的牌  不能巴杠
                                act.peng = false
                                act.anGang = false
                                act.chi = false
                                act.chair_id = v.chair_id
                                if act.hu then
                                    hu_player = v
                                    hu_player.split_list = act.split_list
				                    hu_player.jiang_tile = act.jiang_tile
                                    hu_player.hu_info = act.hu_info
                                    if self:hu_fan_match(hu_player) then
                                        self.player_action_table = act
                                    end
                                end
                            end
                        end
                            
                        if self.player_action_table.chair_id == nil then
                            self:update_state(FSM_S.WAIT_MO_PAI)
                        else
                            self:update_state(FSM_S.WAIT_BA_GANG_HU)
                            self:auto_act_if_deposit(hu_player,"hu_ba_gang")
                        end 
                    end
                end
            end
        elseif event_table.type == FSM_E.HU then --自摸胡
            local player = self.player_list_[self.chu_pai_player_index]
            if (player.chair_id == event_table.chair_id) then
                player.hu_info = mj_util.panHu(player.pai)
                if #player.hu_info > 0 then
                    player.split_list = mj_util.tableCloneSimple(g_split_list)
                    player.jiang_tile = g_jiang_tile

                    player.gang_shang_hua = player.last_act_is_gang
                    if #self.gongPai == 0 then
                        player.miao_shou_hui_chun = true
                    else
                        player.zi_mo = true
                    end
                    if player.mo_pai_count == 0 and self.chu_pai_player_index == self.zhuang then
                        player.tian_hu = true -- 天胡
                    elseif player.mo_pai_count == 1 and not player.has_done_chu_pai then
                        player.di_hu = true -- 地胡
                    end
                    if self:hu_fan_match(player) then
                        player.hu = true
                        player.hu_time = os.time()
                        player.hu_pai = self.last_chu_pai
                        self:broad_cast_player_hu(player,false)
                        self:update_state_delay(FSM_S.GAME_BALANCE,1)
                    else
                        player.gang_shang_hua = false
                        player.miao_shou_hui_chun = false
                        player.zi_mo = false
                        player.tian_hu = false -- 天胡
                        player.di_hu = false -- 地胡
                        player.hu_info = nil
                        player.split_list = nil
                        player.jiang_tile = nil
                    end
                end
            end  
        elseif event_table.type == FSM_E.JIA_BEI then
            local player = self.player_list_[self.chu_pai_player_index]
            if (player.can_jiabei_this_chupai_round and player.chair_id == event_table.chair_id) then
                local hu_info = mj_util.panHu(player.pai)
                if #hu_info > 0 then
                    player.can_jiabei_this_chupai_round = false
                    self:player_jiabei(player)
                    for k,v in ipairs(player.pai.shou_pai) do
                        if v == event_table.tile then
                            --self:do_chu_pai(event_table.tile)
                            break
                        end
                    end
                end
            end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.WAIT_PENG_GANG_HU_CHI then
        if event_table.type == FSM_E.UPDATE then
            if self:is_action_time_out() then
                self:increase_time_out_and_deposit(self.player_list_[self.player_action_table.chair_id])
                self.player_action_table.do_pass = true
                self:judge_action_peng_gang_hu_chi_bei_after_event()
            end
        elseif event_table.type == FSM_E.PASS then
            if self.player_action_table.chair_id == event_table.chair_id then
                self.player_action_table.do_pass = true
                self:judge_action_peng_gang_hu_chi_bei_after_event()
            end
        elseif event_table.type == FSM_E.PENG then
            local act = self.player_action_table
            if act.peng and (act.chair_id == event_table.chair_id) then
                act.do_peng = true
                self:judge_action_peng_gang_hu_chi_bei_after_event()
            end
        elseif event_table.type == FSM_E.GANG then
            local act = self.player_action_table
            if act.anGang and (act.chair_id == event_table.chair_id) then
               act.do_gang = true
               self:judge_action_peng_gang_hu_chi_bei_after_event()   
            end
        elseif event_table.type == FSM_E.HU then
            local act = self.player_action_table
            if act.hu and (act.chair_id == event_table.chair_id) then
               act.do_hu = true
               self:judge_action_peng_gang_hu_chi_bei_after_event()   
            end
        elseif event_table.type == FSM_E.CHI then
            local act = self.player_action_table
            if act.chi and (act.chair_id == event_table.chair_id) and #event_table.tiles == 3
            and (event_table.tiles[1] == self.last_chu_pai or event_table.tiles[2] == self.last_chu_pai or event_table.tiles[3] == self.last_chu_pai)
            and (event_table.tiles[1] < 10 and event_table.tiles[2] < 10 and event_table.tiles[3] < 10)
            then
               act.do_chi = true
               self:judge_action_peng_gang_hu_chi_bei_after_event(event_table.tiles)   
            end
        elseif event_table.type == FSM_E.JIA_BEI then
            local act = self.player_action_table
            if act.hu and (act.chair_id == event_table.chair_id) then
               act.do_jiabei = true
               self:judge_action_peng_gang_hu_chi_bei_after_event()   
            end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.WAIT_BA_GANG_HU then
        if event_table.type ~= FSM_E.UPDATE then
            if self.player_action_table.chair_id ~= event_table.chair_id then
                log_info(string.format("WAIT_BA_GANG_HU error , player %d",act.uid))
                return
            end
        end
        if event_table.type == FSM_E.UPDATE then
            if self:is_action_time_out() then
                self:increase_time_out_and_deposit(self.player_list_[self.player_action_table.chair_id])
                self:update_state(FSM_S.WAIT_MO_PAI)
            end
        elseif event_table.type == FSM_E.PASS then
            if self.player_action_table.chair_id == event_table.chair_id then
               self.player_action_table.do_pass = true
            end
            if self.player_action_table.do_pass then
                self:update_state(FSM_S.WAIT_MO_PAI)
            end 
        elseif event_table.type == FSM_E.HU then
            local act = self.player_action_table
            if act.hu and (act.chair_id == event_table.chair_id) then
                act.do_hu = true
            end

            if self.player_action_table.do_hu then -- 选择了胡
                local player = self.player_list_[self.chu_pai_player_index]
                for k,v in pairs(player.pai.ming_pai) do--取消巴杠
                    if v[1] == self.last_chu_pai then
                        v[4] = nil v[5] = nil
                        break
                    end
                end

                local player_hu = self.player_list_[event_table.chair_id]
                player_hu.hu = true
                player_hu.hu_time = os.time()
                player_hu.hu_pai = self.last_chu_pai
                player_hu.qiang_gang_hu = true
                player_hu.split_list = mj_util.tableCloneSimple(act.split_list)
                player_hu.jiang_tile = act.jiang_tile
                
                self:broad_cast_player_hu(player_hu,true)
                self:update_state_delay(FSM_S.GAME_BALANCE,1)
            end 
        elseif event_table.type == FSM_E.JIA_BEI then
            if self.player_action_table.hu and (self.player_action_table.chair_id == event_table.chair_id) then
                self.player_action_table.do_jiabei = true
                local player = self.player_list_[event_table.chair_id]
                self:player_jiabei(player)
                self:update_state(FSM_S.WAIT_MO_PAI)
            end
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
	elseif self.cur_state_FSM == FSM_S.GAME_BALANCE then
        if event_table.type == FSM_E.UPDATE then
            local hu_player = nil
            local lost_player = nil
            local room_cell_score = self.cell_score_
            for k,v in pairs(self.player_list_) do
                if v then 
                    v.describe = v.describe or ""
                    local log_p = self.game_log.players[v.chair_id]
                    log_p.hu = v.hu
                    log_p.pai = v.pai
                    if v.hu then
                        hu_player = v
                        v.win_money = v.fan * room_cell_score
                        print("player hu",v.fan,v.win_money,v.describe)
                        log_p.fan = v.fan
                        log_p.describe = v.describe
                        log_p.win_money = v.win_money
                        log_p.finish_task = v.finish_task
                    else
                        lost_player = v
                        v.ting = mj_util.panTing(v.pai)
                        print(string.format("GAME_BALANCE %d ting %s",v.chair_id,tostring(v.ting)))
                    end
                end
            end
            local win_money = 0
            local win_taxes = 0
            if hu_player then
                win_money = hu_player.win_money
                for k,v in pairs(self.player_list_) do
                    if v.pb_base_info and v.pb_base_info.money < win_money then
                        win_money = v.pb_base_info.money
                    end
                end

                if lost_player.cost_money then
                    win_taxes = math.ceil(win_money * self.room_:get_room_tax())
					--lost_player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = win_money}}, LOG_MONEY_OPT_TYPE_MAAJAN)
					--hu_player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = win_money - win_taxes}}, LOG_MONEY_OPT_TYPE_MAAJAN)
				end 
            else
                --流局
            end
            local msg = {}
            msg.pb_players = {}
            for k,v in pairs(self.player_list_) do
                if v then
                    local tplayer = {}
                    tplayer.chair_id = v.chair_id
                    tplayer.finish_task = v.finish_task
                    tplayer.is_hu = v.hu
                    if v.hu then
                        tplayer.win_money = win_money
                        tplayer.taxes = win_taxes
                    else
                        tplayer.win_money = -win_money
                        tplayer.taxes = 0
                    end
                    tplayer.hu_fan = v.fan
                    tplayer.jiabei = v.jiabei
                    tplayer.describe = v.describe
                    tplayer.desk_pai = v.pai.desk_tiles
                    tplayer.hua_pai = v.pai.hua_pai
                    tplayer.shou_pai = v.pai.shou_pai
                    tplayer.pb_ming_pai = {}
                    for k1,v1 in pairs(v.pai.ming_pai) do
                        tplayer.pb_ming_pai[#tplayer.pb_ming_pai + 1] = {tiles = v1}
                    end
                    table.insert(msg.pb_players,tplayer)
                end
            end
            self:broadcast2client("SC_Maajan_Game_Finish",msg)

            self.game_log.end_game_time = os.time()
            local s_log = lua_to_json(self.game_log)
	        log_info(s_log)
	        self:Save_Game_Log(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)

            self:update_state(FSM_S.GAME_CLOSE)
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_CLOSE then
        if event_table.type == FSM_E.UPDATE then
			self.do_logic_update = false
            self:clear_ready()

            local room_limit = self.room_:get_room_limit()
            for i,v in ipairs(self.player_list_) do
                if v then
                    if v.deposit then
                        v:forced_exit()
                    else
                        v:check_forced_exit(room_limit)
                        if v.is_android then
                            self:ready(v)
                        end
                    end
                end
            end

            for i,v in pairs (self.player_list_) do
                if game_switch == 1 then--游戏将进入维护阶段
                    if  v and v.is_player == true then 
                        send2client_pb(v, "SC_GameMaintain", {
                        result = GAME_SERVER_RESULT_MAINTAIN,
                        })
                        v:forced_exit()
                    end
                end
            end
			
			-- test --
			-- self:start(2,true)
			-- test --
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_ERR then
         if event_table.type == FSM_E.UPDATE then  
            for k,v in pairs(self.player_list_) do
                if v then 
                    v.hu = false
                    v.ting = false
                end
            end  
            self:update_state(FSM_S.GAME_CLOSE)
        else
            log_info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
    end
    return true
end





