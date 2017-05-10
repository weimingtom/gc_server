#pragma once
typedef struct CS_stTimeSync
{

    CS_stTimeSync()
    {
        Clear();
    }
    ~CS_stTimeSync()
    {
        Clear();
    }
    CS_stTimeSync& operator=(CS_stTimeSync& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->client_tick = other.client_tick;            //玩家时间
        return *this;
    }
    void Clear()
    {
        chair_id    = 0;			//椅子ID
        client_tick = 0;            //玩家时间
    }
    int	chair_id;				//椅子ID
    int	client_tick;            //玩家时间
};

typedef struct CS_stChangeCannon
{

    CS_stChangeCannon()
    {
        Clear();
    }
    ~CS_stChangeCannon()
    {
        Clear();
    }
    void Clear()
    {
        chair_id = 0;				//椅子ID
        add = 0;            //玩家时间
    }
    CS_stChangeCannon& operator=(CS_stChangeCannon& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->add = other.add;            
        return *this;
    }
    int	chair_id;				//椅子ID
    int	add;                    //0减下一档 非0增加
};


typedef struct CS_stFire
{
    CS_stFire()
    {
        Clear();
    }
    ~CS_stFire()
    {
        Clear();
    }
    void Clear()
    {
        chair_id = 0;				//椅子ID
        direction = 0;
        fire_time = 0;
        client_id = 0;
    }
    CS_stFire& operator=(CS_stFire& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->direction = other.direction;
        this->fire_time = other.fire_time;
        this->client_id = other.client_id;
        return *this;
    }
    int	    chair_id;		//椅子ID
    float   direction;		//方向
    int     fire_time;		//开火时间
    int     client_id;		//子弹ID？
};


typedef struct CS_stLockFish
{
    CS_stLockFish()
    {
        Clear();
    }
    ~CS_stLockFish()
    {
        Clear();
    }
    void Clear()
    {
        chair_id = 0;				//椅子ID
        lock = 0;
    }
    CS_stLockFish& operator= (CS_stLockFish& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->lock = other.lock;
        return *this;
    }
    int	    chair_id;		//椅子ID
    int     lock;		    //0表示解锁
};

typedef struct CS_stNetcast
{
    CS_stNetcast()
    {
        Clear();
    }
    ~CS_stNetcast()
    {
        Clear();
    }
    void Clear()
    {
        bullet_id = 0;		  //子弹ID
        data = 0;             //无使用 可优
        fish_id = 0;          //鱼ID
    }
    CS_stNetcast& operator= (CS_stNetcast& other)
    {
        this->bullet_id = other.bullet_id;			//椅子ID
        this->data = other.data;
        this->fish_id = other.fish_id;
        return *this;
    }
    int	bullet_id;		  //子弹ID
    int	data;             //无使用 可优
    int	fish_id;          //鱼ID
};


typedef struct CS_stChangeCannonSet
{
    CS_stChangeCannonSet()
    {
        Clear();
    }
    ~CS_stChangeCannonSet()
    {
        Clear();
    }
    void Clear()
    {
        chair_id = 0;		  
        add = 0;               
    }
    CS_stChangeCannonSet& operator= (CS_stChangeCannonSet& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->add = other.add;
        return *this;
    }
    int	    chair_id;		//椅子ID
    int     add;		    //增加值 0 减 
};

typedef struct CS_stTreasureEnd
{
    CS_stTreasureEnd()
    {
        Clear();
    }
    ~CS_stTreasureEnd()
    {
        Clear();
    }
    void Clear()
    {
        chair_id = 0;
        score = 0;
    }
    CS_stTreasureEnd& operator= (CS_stTreasureEnd& other)
    {
        this->chair_id = other.chair_id;			//椅子ID
        this->score = other.score;
        return *this;
    }
    int	    chair_id;		//椅子ID
    int     score;		    //值 
};


typedef struct SC_stSendFish
{
    SC_stSendFish()
    {
        Clear();
    }
    ~SC_stSendFish()
    {
        Clear();
    }
    void Clear()
    {
       fish_id = 0;		    
       type_id = 0;         
       path_id = 0;         
       create_tick = 0;     
       offest_x = 0;        
       offest_y = 0;        
       dir = 0;             
       delay = 0;           
       server_tick = 0;     
       fish_speed = 0;     
       fis_type = 0;       
       troop = 0;          
       refersh_id = 0;     
    }
    SC_stSendFish& operator= (SC_stSendFish& other)
    {
        this->fish_id = other.fish_id;
        this->type_id = other.type_id;
        this->path_id = other.path_id;
        this->create_tick = other.create_tick;
        this->offest_x = other.offest_x;
        this->offest_y = other.offest_y;
        this->dir = other.dir;
        this->delay = other.delay;
        this->server_tick = other.server_tick;
        this->fish_speed = other.fish_speed;
        this->fis_type = other.fis_type;
        this->troop = other.troop;
        this->refersh_id = other.refersh_id;
        return *this;
    }
    int	    fish_id;		 //鱼ID
    int	    type_id;         //类型？
    int	    path_id;         //路径ID
    int	    create_tick;     //创建时间
    float	offest_x;        //X坐标
    float	offest_y;        //Y坐标
    float	dir;             //方向
    float	delay;           //延时
    int	    server_tick;     //系统时间
    float	fish_speed;      //鱼速度
    int	    fis_type;        //鱼类型？
    int	    troop;           //是否鱼群
    int	    refersh_id;      //获取刷新ID？
};


typedef struct stLuaMsgType
{
    stLuaMsgType()
    {
        Clear();
    }
    ~stLuaMsgType()
    {
        Clear();
    }
    void Clear()
    {
        wValue = 0;
        bRet = false;
        cbByte = 0;
        lValue = 0;
        strValue = "";
    }
    stLuaMsgType& operator= (stLuaMsgType& other)
    {
        this->wValue = other.wValue;
        this->bRet = other.bRet;
        this->cbByte = other.cbByte;
        this->strValue = other.strValue;
        this->lValue = other.lValue;
        return *this;
    }
    WORD	    wValue;		 
    bool	    bRet   ;  
    BYTE        cbByte;
    LONGLONG    lValue;
    std::string strValue;
};

typedef struct stLuaMsg
{
    stLuaMsg()
    {
        Clear();
    }
    ~stLuaMsg()
    {
        Clear();
    }
    void Clear()
    {
        m_TableID = 0;
        m_pMsg = NULL;
        m_iMsgID = NULL;
        m_iGuID = 0;
    }
    int     m_iGuID;         //发起玩家ID
    int	    m_TableID;		 //桌子ID
    int     m_iMsgID;        //消息ID
    void*	m_pMsg;          //消息包指针
};
