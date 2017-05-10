
local prize_pool = {
    bonus_score = 0
}

-- 累加到奖池
function prize_pool.add(score)
    prize_pool.bonus_score = prize_pool.bonus_score + score
end

-- 进行派奖
function prize_pool.award()
end

return prize_pool
