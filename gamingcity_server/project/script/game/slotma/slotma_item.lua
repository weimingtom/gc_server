-- 老虎机一个水果种类

--local pb = require "protobuf"

slotma_item = {}

-- 创建
function slotma_item:new()
    local o = {}  
    setmetatable(o, {__index = self})	
    return o 
end

-- 初始化
function slotma_item:init(itemConfig)
    self.itemID_ = math.ceil(itemConfig.id)
    self.maxNum_ = math.ceil(itemConfig.maxNum)
    self.type = {}
	for i,v in ipairs(itemConfig.winingtype) do
		self.type[i] = {}
		self.type[i].number = math.ceil(v.number)
		self.type[i].times = math.ceil(v.times)
	end
end

function slotma_item:getTimes( numb )
    -- body
    for _,v in ipairs(self.type) do
        if v.number == numb then
            return v.times
        end
    end
    return 0
end