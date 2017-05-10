
local game_type = require("game_type")
local game_helper = require("game_helper")

-- 测试小玛丽
local function test_bonus_mode()
    local rolling_icons = game_helper.generate_random_rolling_icons()
    local rotate_icon = game_helper.generate_random_rotate_icon()
    local multiple = game_helper.calc_bonus_lottery(rolling_icons, rotate_icon)

    print(string.format("rolling icons: %d, %d, %d, %d", rolling_icons[1], rolling_icons[2], rolling_icons[3], rolling_icons[4]))
    print(string.format("rotate icon: %d", rotate_icon))
    print(string.format("lottery multiple: %d", multiple))
end

for i = 1, 10 do
    test_bonus_mode()
    print()
end
