local define = {}

--输入事件
define.FSM_event = {
    UPDATE          = 0,	--time update
	TRUSTEE			= 1,	--托管
	CHI				= 2,	--吃
	PENG  			= 3,	--碰  
	GANG  			= 4,	--杠
	HU	  			= 5,	--胡
	PASS  			= 6,	--过
	CHU_PAI			= 7,	--出牌
	JIA_BEI			= 8,	--加倍
}

define.GANG_TYPE = {
	AN_GANG = 1,
	MING_GANG = 2,
	BA_GANG = 3
}

--状态机  状态
define.FSM_state = {
    PER_BEGIN       		= 0,	--预开始
    XI_PAI		    		= 1,    --洗牌 
	BU_HUA_BIG				= 2,	--补花
	WAIT_MO_PAI  			= 4,	--等待 摸牌
	WAIT_CHU_PAI  			= 5,	--等待 出牌
	WAIT_PENG_GANG_HU_CHI	= 6,	--等待 碰 杠 胡, 用户出牌的时候
	WAIT_BA_GANG_HU  		= 7,	--等待 胡, 用户巴杠的时候，抢胡

	GAME_BALANCE			= 15,	--结算
	GAME_CLOSE				= 16,	--关闭游戏
	GAME_ERR				= 17,	--发生错误

	GAME_IDLE_HEAD			= 0x1000, --用于客户端播放动画延迟				
}
define.FAN_UNIQUE_MAP	 = {
	--大四喜----圈风刻,门风刻,大三风,小三风,碰碰胡
	DA_SI_XI 			= {QUAN_FENG_KE,MEN_FENG_KE,DA_SAN_FENG,XIAO_SAN_FENG,PENG_PENG_HU},
	--大三元----双箭刻,箭刻
	DA_SAN_YUAN			= {SHUANG_JIAN_KE,JIAN_KE},	
	--九莲宝灯----清一色		
	JIU_LIAN_BAO_DENG	= {QING_YI_SE},	
	--18罗汉----三杠，双明杠，明杠，单钓将
	LUO_HAN_18			= {SAN_GANG,SHUANG_MING_GANG,MING_GANG,DAN_DIAO_JIANG},	
	--连7对----清一色、单钓，门前清，自摸。
	LIAN_QI_DUI			= {QING_YI_SE,DAN_DIAO_JIANG,MEN_QING,ZI_MO},	
	--大七星--全带幺，单钓将，门前清，自摸，字一色
	DA_QI_XIN			= {QUAN_DAI_YAO,DAN_DIAO_JIANG,MING_GANG,ZI_MO,ZI_YI_SE},	
	--天胡--单钓将，不求人，自摸。
	TIAN_HU				= {DAN_DIAO_JIANG,BU_QIU_REN,ZI_MO},
	--小四喜 不计大三风，小三风，圈风刻，门风刻。
	XIAO_SI_XI			= {DA_SAN_FENG,XIAO_SAN_FENG,QUAN_FENG_KE,MEN_FENG_KE},
	--小三元	不计双箭刻，箭刻
	XIAO_SAN_YUAN		= {SHUANG_JIAN_KE,JIAN_KE},
	--字一色 不计碰碰和。
	ZI_YI_SE			= {PENG_PENG_HU},
	--四暗刻	不计三暗刻，双暗刻，门前清，碰碰和，自摸
	SI_AN_KE 			= {SAN_AN_KE,SHUANG_AN_KE,MING_GANG,PENG_PENG_HU,ZI_MO},
	--一色双龙会 不计平和，清一色，一般高
	SHUANG_LONG_HUI		= {PING_HU,QING_YI_SE,YI_BAN_GAO},
	--一色四同顺 不计一色三节高、一色三同顺，四归一，一般高
	YI_SE_SI_TONG_SHUN	= {YI_SE_SAN_JIE_GAO,YI_SE_SAN_TONG_SHUN,SI_GUI_YI,YI_BAN_GAO},
	--一色四节高 不计一色三同顺，一色三节高，碰碰和，一般高
	YI_SE_SI_JIE_GAO	= {YI_SE_SAN_TONG_SHUN,YI_SE_SAN_JIE_GAO,PENG_PENG_HU,YI_BAN_GAO},
	--三元七对子 不计门前清，单钓将，自摸。
	SAN_YUAN_QI_DUI		= {MEN_QING,DAN_DIAO_JIANG,ZI_MO},
	--四喜七对子 不计 门前清，单调将，自摸。
	SI_XI_QI_DUI		= {MEN_QING,DAN_DIAO_JIANG,ZI_MO},
	--一色四步高 不计三步高，连六，老少副
	YI_SE_SI_BU_GAO		= {YI_SE_SAN_BU_GAO,LIAN_LIU,LAO_SHAO_FU},
	--三杠  不计双明刚，明杠
	SAN_GANG			= {SHUANG_MING_GANG,MING_GANG},
	--混幺九 不计碰碰和。全带幺。
	HUN_YAO_JIU			= {PENG_PENG_HU,QUAN_DAI_YAO},
	--七对 不计不求人，门前清，单钓将，自摸。
	NORMAL_QI_DUI		= {BU_QIU_REN,MEN_QING,DAN_DIAO_JIANG,ZI_MO},
	--一色三节高 不计一色三同顺，一般高。
	YI_SE_SAN_JIE_GAO	= {YI_SE_SAN_TONG_SHUN,YI_BAN_GAO},
	--一色三同顺 不计一色三节高，一般高。
	YI_SE_SAN_TONG_SHUN	= {YI_SE_SAN_JIE_GAO,YI_BAN_GAO},
	--四字刻 	不计碰碰胡。
	SI_ZI_KE			= {PENG_PENG_HU},
	--大三风 	不计小三风
	DA_SAN_FENG			= {XIAO_SAN_FENG},
	--清龙 不计连六，老少副。
	QING_LONG			= {LIAN_LIU,LAO_SHAO_FU},
	--三暗刻 不计双暗刻
	SAN_AN_KE			= {SHUANG_AN_KE},
	--妙手回春 不计自摸
	MIAO_SHOU_HUI_CHUN	= {ZI_MO},
	--杠上开花 	不计自摸。
	GANG_SHANG_HUA		= {ZI_MO},
	--抢杠胡 不计胡绝张
	QIANG_GANG_HU		= {HU_JUE_ZHANG},
	--全求人 不计单钓
	QUAN_QIU_REN		= {DAN_DIAO_JIANG},
	--双暗杠 	不计双暗刻，暗杠。
	SHUANG_AN_GANG		= {SHUANG_AN_KE,AN_GANG},
	--双箭刻 	不计双暗刻，暗杠
	SHUANG_JIAN_KE		= {SHUANG_AN_KE,AN_GANG},
} 
define.CARD_HU_TYPE_INFO = {
	WEI_HU					= {name = "WEI_HU",fan = 0},				--未胡
------------------------------叠加-------------------------------------------------
	TIAN_HU					= {name = "TIAN_HU",fan = 88},				--天胡
	DI_HU					= {name = "DI_HU",fan = 88},				--地胡
	REN_HU					= {name = "REN_HU",fan = 64},				--人胡
	TIAN_TING				= {name = "TIAN_TING",fan = 32},			--天听
	QING_YI_SE				= {name = "QING_YI_SE",fan = 16},			--清一色
	QUAN_HUA				= {name = "QUAN_HUA",fan = 16},				--全花
	ZI_YI_SE				= {name = "ZI_YI_SE",fan = 64},				--字一色
	MIAO_SHOU_HUI_CHUN		= {name = "MIAO_SHOU_HUI_CHUN",fan = 8},	--妙手回春
	HAI_DI_LAO_YUE			= {name = "HAI_DI_LAO_YUE",fan = 8},		--海底捞月
	GANG_SHANG_HUA			= {name = "GANG_SHANG_HUA",fan = 8},		--杠上开花
	QUAN_QIU_REN			= {name = "QUAN_QIU_REN",fan = 8},			--全求人
	SHUANG_AN_GANG			= {name = "SHUANG_AN_GANG",fan = 6},		--双暗杠
	SHUANG_JIAN_KE			= {name = "SHUANG_JIAN_KE",fan = 6},		--双箭刻
	HUN_YI_SE				= {name = "HUN_YI_SE",fan = 6},				--混一色
	BU_QIU_REN				= {name = "BU_QIU_REN",fan = 4},			--不求人
	SHUANG_MING_GANG		= {name = "SHUANG_MING_GANG",fan = 4},		--双明杠
	HU_JUE_ZHANG			= {name = "HU_JUE_ZHANG",fan = 4},			--胡绝张
	JIAN_KE					= {name = "JIAN_KE",fan = 2},				--箭刻
	MEN_QING				= {name = "MEN_QING",fan = 2},				--门前清
	ZI_AN_GANG				= {name = "ZI_AN_GANG",fan = 2},			--自暗杠
	DUAN_YAO				= {name = "DUAN_YAO",fan = 2},				--断幺
	SI_GUI_YI				= {name = "SI_GUI_YI",fan = 2},				--四归一
	PING_HU					= {name = "PING_HU",fan = 2},				--平胡
	SHUANG_AN_KE			= {name = "SHUANG_AN_KE",fan = 2},			--双暗刻
	SAN_AN_KE				= {name = "SAN_AN_KE",fan = 16},			--三暗刻
	SI_AN_KE				= {name = "SI_AN_KE",fan = 64},				--四暗刻
	BAO_TING				= {name = "BAO_TING",fan = 2},				--报听
	MEN_FENG_KE				= {name = "MEN_FENG_KE",fan = 2},			--门风刻
	QUAN_FENG_KE			= {name = "QUAN_FENG_KE",fan = 2},			--圈风刻
	ZI_MO					= {name = "ZI_MO",fan = 1},					--自摸
	DAN_DIAO_JIANG			= {name = "DAN_DIAO_JIANG",fan = 1},		--单钓将
	YI_BAN_GAO	 			= {name = "YI_BAN_GAO",fan = 1},			--一般高
	LAO_SHAO_FU	 			= {name = "LAO_SHAO_FU",fan = 1},			--老少副
	LIAN_LIU	 			= {name = "LIAN_LIU",fan = 1},				--连六
	YAO_JIU_KE	 			= {name = "YAO_JIU_KE",fan = 1},			--幺九刻
	MING_GANG	 			= {name = "MING_GANG",fan = 1},				--明杠
	DA_SAN_FENG				= {name = "DA_SAN_FENG",fan = 24},			--大三风
	XIAO_SAN_FENG			= {name = "XIAO_SAN_FENG",fan = 24},		--小三风
	PENG_PENG_HU			= {name = "PENG_PENG_HU",fan = 6},			--碰碰胡
	SAN_GANG				= {name = "SAN_GANG",fan = 32},				--三杠
	QUAN_DAI_YAO			= {name = "QUAN_DAI_YAO",fan = 4},			--全带幺
	QIANG_GANG_HU			= {name = "QIANG_GANG_HU",fan = 8},			--抢杠胡
	HUA_PAI					= {name = "HUA_PAI",fan = 1},				--花牌
-----------------------------------------------------------------------------------
	DA_QI_XIN			= {name = "DA_QI_XIN",fan = 88},			--大七星
	LIAN_QI_DUI 		= {name = "LIAN_QI_DUI",fan = 88},			--连七对
	SAN_YUAN_QI_DUI		= {name = "SAN_YUAN_QI_DUI",fan = 48},		--三元七对子
	SI_XI_QI_DUI		= {name = "SI_XI_QI_DUI",fan = 48},			--四喜七对子
	NORMAL_QI_DUI 		= {name = "NORMAL_QI_DUI",fan = 24},		--普通七对
---------------------
	DA_YU_WU 			= {name = "DA_YU_WU",fan = 88},				--大于五
	XIAO_YU_WU 			= {name = "XIAO_YU_WU",fan = 88},			--小于五
	DA_SI_XI			= {name = "DA_SI_XI",fan = 88},				--大四喜
	XIAO_SI_XI			= {name = "XIAO_SI_XI",fan = 64},			--小四喜
	DA_SAN_YUAN			= {name = "DA_SAN_YUAN",fan = 88},			--大三元
	XIAO_SAN_YUAN		= {name = "XIAO_SAN_YUAN",fan = 64},		--小三元
	JIU_LIAN_BAO_DENG	= {name = "JIU_LIAN_BAO_DENG",fan = 88},	--九莲宝灯
	LUO_HAN_18			= {name = "LUO_HAN_18",fan = 88},			--18罗汉
	SHUANG_LONG_HUI		= {name = "SHUANG_LONG_HUI",fan = 64},		--一色双龙会
	YI_SE_SI_TONG_SHUN	= {name = "YI_SE_SI_TONG_SHUN",fan = 48},	--一色四同顺
	YI_SE_SI_JIE_GAO	= {name = "YI_SE_SI_JIE_GAO",fan = 48},		--一色四节高
	YI_SE_SI_BU_GAO		= {name = "YI_SE_SI_BU_GAO",fan = 32},		--一色四步高
	HUN_YAO_JIU			= {name = "HUN_YAO_JIU",fan = 32},			--混幺九
	YI_SE_SAN_JIE_GAO	= {name = "YI_SE_SAN_JIE_GAO",fan = 24},	--一色三节高
	YI_SE_SAN_TONG_SHUN	= {name = "YI_SE_SAN_TONG_SHUN",fan = 24},	--一色三同顺
	SI_ZI_KE			= {name = "SI_ZI_KE",fan = 24},				--四字刻
	QING_LONG			= {name = "QING_LONG",fan = 16},			--清龙
	YI_SE_SAN_BU_GAO	= {name = "YI_SE_SAN_BU_GAO",fan = 16},		--一色三步高
}

define.ACTION_TIME_OUT			= 15 	-- 10秒

return define