SET FOREIGN_KEY_CHECKS=0;

USE `game`;

-- ----------------------------
-- Procedure structure for `change_player_bank_money`
-- ----------------------------
DROP PROCEDURE IF EXISTS `change_player_bank_money`;
DELIMITER ;;
CREATE PROCEDURE `change_player_bank_money`(IN `guid_` int,IN `money_` bigint(20))
    COMMENT '银行转账，参数guid_：转账guid，money_：金钱'
label_pro:BEGIN
	DECLARE oldbank bigint(20);
	select bank into oldbank from t_player where guid = guid_;
	if oldbank is not null then
		if money_ < 0 then
			if oldbank + money_ < 0 then
				select 2 as ret;
				leave label_pro;
			end if;
		end if;
		update t_player set bank = bank + money_ where guid = guid_;
		IF ROW_COUNT() = 0 THEN
			select 5 as ret;
		else
			select 0 as ret, oldbank , (oldbank + money_) as newbank;
		END IF;
	else
		select 4 as ret;
		leave label_pro;
	end if;
END
;;
DELIMITER ;

SET FOREIGN_KEY_CHECKS=0;

USE `account`;

-- ----------------------------
-- Procedure structure for `check_is_Agent`
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_is_agent`;
DELIMITER ;;
CREATE PROCEDURE `check_is_agent`(IN `guid_1` int,IN `guid_2` int)
    COMMENT '查询guid1，guid2 是否为代理商却是否支持转账功能'
label_pro:BEGIN
	DECLARE guidAflg int;
	DECLARE guidBflg int;
	select enable_transfer into guidAflg from t_account where guid = guid_1;
	select enable_transfer into guidBflg from t_account where guid = guid_2;
	if guidAflg is null then
		set guidAflg = 9;
	end if;
	if guidBflg is null then
		set guidBflg = 9;
	end if;
	
	select guidAflg * 10 + guidBflg as retCode;
END
;;
DELIMITER ;