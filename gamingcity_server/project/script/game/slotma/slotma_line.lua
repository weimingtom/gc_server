-- 老虎机一条线

local pb = require "protobuf"

slotma_line = {}

-- 创建
function slotma_line:new()
    local o = {}  
    setmetatable(o, {__index = self})	
    return o 
end

-- 初始化
function slotma_line:init(line , linelen)
    self.linelen_ = math.ceil(linelen)
    self.lineID_ = math.ceil(line.id)
    self.linepos_ = {}
	for i,v in ipairs(line.point) do
		self.linepos_[i] = {}
		self.linepos_[i].x = math.ceil(v.x)
		self.linepos_[i].y = math.ceil(v.y)
	end
end

--获取元素在list里面的索引
function slotma_line:get_itemIndex(linepos_index)
     return (self.linepos_[linepos_index].y-1)*self.linelen_ + self.linepos_[linepos_index].x
end

--查找连续的最大个数
function slotma_line:getResult(list)

--[[查找连续相同的元素，不一定从最左或者最右边开始
    local result = {}
    local tempResult = {}
    local preItemId = 0
    for _,v in ipairs(self.linepos_) do
        local itemIndex = (v.y-1)*self.linelen_ + v.x

        if list[itemIndex] then
            local itemId = list[itemIndex]
            --第一个元素
            if preItemId == 0 then
                tempResult[itemId] = 1
                result[itemId] = 1
            else
                if itemId == preItemId then
                    tempResult[itemId] = tempResult[itemId] + 1
                    --更新元素最大个数
                    if result[itemId] == nil or result[itemId] < tempResult[itemId] then
                        result[itemId] = tempResult[itemId]
                    end  
                else 
                    --之前的元素清空
                    tempResult[preItemId] = 0 
                    tempResult[itemId] = 1
                    result[itemId] = 1      

                end
            end

            preItemId = itemId
        end
    end
    return result
--]]


    --从最左或者最右查找连续相同的元素
    local result = {}

    local leftItemId =  list[self:get_itemIndex(1)]
    local rightItemId = list[self:get_itemIndex(#self.linepos_)]

    local left_count = 1
    local right_count = 1

    --从左至右检查
    for i=2,#self.linepos_ do
        local itemIndex = self:get_itemIndex(i)

        if list[itemIndex] == leftItemId then
            left_count = left_count + 1
        else
            break
        end
    end


    --从右至左检查
    for i=#self.linepos_-1,1,-1 do
        local itemIndex = self:get_itemIndex(i)

        if list[itemIndex] == rightItemId then
            right_count = right_count + 1
        else
            break
        end
    end

    if leftItemId ~= rightItemId then
        result[leftItemId] = left_count
        result[rightItemId] = right_count
    else
        if left_count > right_count then
            result[leftItemId] = left_count
        else
            result[leftItemId] = right_count
        end
    end

    return result
end