SET FOREIGN_KEY_CHECKS=0;

USE `account`;

ALTER TABLE `t_account` ADD COLUMN `inviter_guid`  int(11) NULL DEFAULT 0 COMMENT '邀请人的id' AFTER `cash_count`;

ALTER TABLE `t_account` ADD COLUMN `invite_code`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '邀请码' AFTER `inviter_guid`;

CREATE INDEX `index_invite_code` ON `t_account`(`invite_code`) USING BTREE ;

CREATE TABLE `t_channel_invite` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键' ,
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
`channel_lock`  tinyint(3) NULL DEFAULT 0 COMMENT '1开启 0关闭' ,
`big_lock`  tinyint(3) NULL DEFAULT 1 COMMENT '1开启 0关闭' ,
`tax_rate`  int(11) UNSIGNED NOT NULL DEFAULT 1 COMMENT '税率 百分比' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
ROW_FORMAT=Dynamic
;

DROP PROCEDURE IF EXISTS `create_guest_account`;
DELIMITER ;;
CREATE PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建游客账号'
BEGIN
	DECLARE guest_id_ BIGINT;

	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE is_first INT DEFAULT 1;
	DECLARE channel_lock_ INT DEFAULT 0;

	SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	IF guid_ = 0 THEN
		SET guid_ = get_guest_id();

		SET account_ = CONCAT("guest_", guid_);
		SET password_ = MD5(account_);
		SET nickname_ = CONCAT("guest_", guid_);

		SELECT channel_lock INTO channel_lock_ FROM t_channel_invite WHERE channel_id=channel_id_ AND big_lock=1;
		IF channel_lock_ != 1 THEN
			SET is_first = 2;
		END IF;

		INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code) VALUES (account_,password_,1,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,HEX(guid_));
		SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
	ELSE
		SET is_first = 2;
		IF disabled_ = 1 THEN
			SET ret = 15;
		ELSE
			UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
		END IF;
	END IF;
		
	SELECT is_first,ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer;
END;
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `sms_login`;
DELIMITER ;;
CREATE PROCEDURE `sms_login`(IN `account_` varchar(64))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
	DECLARE inviter_guid_ INT DEFAULT 0;

	SELECT guid, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code INTO guid_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_ FROM t_account WHERE account = account_;
	IF guid_ = 0 THEN
		SET ret = 3;
	END IF;
	
	IF disabled_ = 1 THEN
		SET ret = 15;
	END IF;
	
	IF ret = 0 THEN
		UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
	END IF;
	
	SELECT ret, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code;
END;
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `verify_account`;
DELIMITER ;;
CREATE PROCEDURE `verify_account`(IN `account_` varchar(64),IN `password_` varchar(32))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
  DECLARE ret INT DEFAULT 0;
  DECLARE guid_ INT DEFAULT 0;
  DECLARE no_bank_password INT DEFAULT 0;
  DECLARE vip_ INT DEFAULT 0;
  DECLARE login_time_ INT;
  DECLARE logout_time_ INT;
  DECLARE is_guest_ INT DEFAULT 0;
  DECLARE nickname_ VARCHAR(32) DEFAULT '0';
  DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
  DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
  DECLARE change_alipay_num_ INT DEFAULT 0;
  DECLARE disabled_ INT DEFAULT 0;
  DECLARE risk_ INT DEFAULT 0;
  DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
  DECLARE enable_transfer_ INT DEFAULT 0;
  DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
  DECLARE inviter_guid_ INT DEFAULT 0;
  
  SELECT guid, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code INTO guid_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_ FROM t_account WHERE account = account_ AND password = password_;
  IF guid_ = 0 THEN
    SET ret = 27;
    SELECT 3 INTO ret FROM t_account WHERE account = account_ LIMIT 1;
  END IF;

  IF disabled_ = 1 THEN
    SET ret = 15;
  END IF;
  
  IF ret = 0 THEN
    UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
  END IF;
  
  SELECT ret, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code;
END;
;;
DELIMITER ;

USE `game`;

CREATE TABLE `t_channel_invite_tax` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id' ,
`guid`  int(11) NOT NULL COMMENT 'guid' ,
`val`  int(11) NOT NULL DEFAULT 0 COMMENT '获得的收益' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
ROW_FORMAT=Dynamic
;

DROP PROCEDURE IF EXISTS `get_player_data`;
DELIMITER ;;
CREATE PROCEDURE `get_player_data`(IN `guid_` int,IN `account_` varchar(64),IN `nick_` varchar(64),IN `money_` int)
BEGIN
	DECLARE guid_tmp INTEGER DEFAULT 0; 
	DECLARE t_error INTEGER DEFAULT 0; 
	DECLARE done INT DEFAULT 0; 
	DECLARE suc INT DEFAULT 1; 
	DECLARE tmp_val INTEGER DEFAULT 0; 
	DECLARE tmp_total INTEGER DEFAULT 0;
	DECLARE updateNum INT DEFAULT 1;
	DECLARE deleteNum INT DEFAULT 0;
	DECLARE selectNum INT DEFAULT 0;

	DECLARE mycur CURSOR FOR SELECT `val` FROM t_channel_invite_tax WHERE guid=guid_;#定义光标 
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET t_error=1;  
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
					

	SELECT guid INTO guid_tmp FROM t_player WHERE guid=guid_;
	IF guid_tmp = 0 THEN
		REPLACE INTO t_player SET guid=guid_,account=account_,nickname=nick_,money=money_;
	ELSE
			#START TRANSACTION; #打开光标  
			#OPEN mycur; #开始循环 
			#REPEAT 
			#		FETCH mycur INTO tmp_val;
			#		 IF NOT done THEN
			#				SET selectNum = selectNum+1;
			#				SET tmp_total = tmp_total + tmp_val;
			#				IF t_error = 1 THEN 
			#					SET suc = 0;
			#				END IF;  
			#		 END IF; 
			#UNTIL done END REPEAT;
			#CLOSE mycur;


			#IF tmp_total > 0 THEN
			#	UPDATE t_player SET money=money+(tmp_total) WHERE guid=guid_;
			#	SET updateNum = row_count();
			#END IF;

			#DELETE FROM t_channel_invite_tax WHERE guid=guid_;
			#SET deleteNum = row_count();

			
			#IF suc = 0 OR updateNum < 1 OR deleteNum != selectNum THEN
			#		ROLLBACK;
			#ELSE
			#		COMMIT; 
			#END IF;
			SET suc = 1;
	END IF;
	SELECT level, money, bank, login_award_day, login_award_receive_day, online_award_time, online_award_num, relief_payment_count, header_icon FROM t_player WHERE guid=guid_;
	
END;
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `get_player_invite_reward`;
DELIMITER ;;
CREATE PROCEDURE `get_player_invite_reward`(IN `guid_` int)
BEGIN
	DECLARE t_error INTEGER DEFAULT 0; 
	DECLARE done INT DEFAULT 0; 
	DECLARE suc INT DEFAULT 1; 
	DECLARE tmp_val INTEGER DEFAULT 0; 
	DECLARE tmp_total INTEGER DEFAULT 0;
	DECLARE deleteNum INT DEFAULT 0;
	DECLARE selectNum INT DEFAULT 0;

	DECLARE mycur CURSOR FOR SELECT `val` FROM t_channel_invite_tax WHERE guid=guid_;#定义光标 
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET t_error=1;  
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
					
	START TRANSACTION; #打开光标  
	OPEN mycur; #开始循环 
	REPEAT 
		FETCH mycur INTO tmp_val;
	  IF NOT done THEN
					SET selectNum = selectNum+1;
					SET tmp_total = tmp_total + tmp_val;
					IF t_error = 1 THEN 
						SET suc = 0;
					END IF;  
			 END IF; 
	UNTIL done END REPEAT;
	CLOSE mycur;


	DELETE FROM t_channel_invite_tax WHERE guid=guid_;
	SET deleteNum = row_count();

	IF suc = 0 OR deleteNum != selectNum THEN
		ROLLBACK;
	ELSE
		COMMIT; 
	END IF;

	SELECT tmp_total as total_reward;
	
END;
;;
DELIMITER ;

USE `config`;

DROP TABLE IF EXISTS `t_game_server_cfg`;
CREATE TABLE `t_game_server_cfg` (
  `game_id` int(11) NOT NULL COMMENT '游戏ID',
  `game_name` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏名字',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该游戏配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `using_login_validatebox` int(11) NOT NULL COMMENT '是否开启登陆验证框',
  `default_lobby` int(11) NOT NULL COMMENT '是否拥有默认大厅',
  `first_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '一级菜单：5斗地主，6扎金花，8百人牛牛',
  `second_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '二级菜单：斗地主（1新手场2初级场3高级场4富豪场）,扎金花（1乞丐场2平民场3中端场4富豪场5贵宾场）,百人牛牛（1默认）',
  `player_limit` int(11) NOT NULL COMMENT '人数限制',
  `room_list` text COMMENT '房间列表配置',
  `room_lua_cfg` text COMMENT '房间lua配置',
  PRIMARY KEY (`game_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci ;

INSERT INTO `t_game_server_cfg` VALUES ('1', 'lobby', '0', '0', '127.0.0.1', '7720', '1', '1', '1', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 0}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('2', 'demo', '0', '0', '127.0.0.1', '7721', '1', '1', '2', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('3', 'fishing', '0', '0', '127.0.0.1', '7722', '1', '1', '3', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 100}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('10', 'shuihu_zhuan', '0', '0', '127.0.0.1', '7723', '1', '1', '4', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 300, \"tax_open\": 1, \"money_limit\": 100}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('20', 'land', '0', '1', '127.0.0.1', '7724', '1', '1', '5', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 200}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('21', 'land', '0', '1', '127.0.0.1', '7725', '1', '1', '5', '2', '2000', '[{\"cell_money\": 30, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 600}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('22', 'land', '0', '1', '127.0.0.1', '7726', '1', '1', '5', '3', '2000', '[{\"cell_money\": 50, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('23', 'land', '0', '1', '127.0.0.1', '7727', '1', '1', '5', '4', '2000', '[{\"cell_money\": 100, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 20000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('30', 'zhajinhua', '0', '1', '127.0.0.1', '7728', '1', '1', '6', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('31', 'zhajinhua', '0', '1', '127.0.0.1', '7729', '1', '1', '6', '2', '2000', '[{\"cell_money\": 100, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 6000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('32', 'zhajinhua', '0', '1', '127.0.0.1', '7730', '1', '1', '6', '3', '2000', '[{\"cell_money\": 500, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 30000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('33', 'zhajinhua', '0', '1', '127.0.0.1', '7731', '1', '1', '6', '4', '2000', '[{\"cell_money\": 1000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 60000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('34', 'zhajinhua', '0', '1', '127.0.0.1', '7732', '1', '1', '6', '5', '2000', '[{\"cell_money\": 2000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 120000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('40', 'showhand', '0', '0', '127.0.0.1', '7733', '1', '1', '7', '1', '2000', '[{\"cell_money\": 1, \"max_call\": 1000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('50', 'ox', '0', '1', '127.0.0.1', '7734', '1', '1', '8', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', 'many_ox_room_config = {\r\n Ox_FreeTime = 3, \r\n Ox_BetTime = 18,\r\n Ox_EndTime = 15,\r\n Ox_MustWinCoeff = 5,\r\n Ox_FloatingCoeff = 3,\r\n Ox_bankerMoneyLimit = 1000000,\r\n Ox_SystemBankerSwitch = 1,\r\n Ox_BankerCount = 5,\r\n Ox_RobotBankerInitUid = 100000,\r\n Ox_RobotBankerInitMoney = 10000000,\r\n Ox_BetRobotSwitch = 1,\r\n Ox_BetRobotInitUid = 200000,\r\n Ox_BetRobotInitMoney = 35000,\r\n Ox_BetRobotNumControl = 5,\r\n Ox_BetRobotTimeControl = 10,\r\n Ox_RobotBetMoneyControl = 10000,\r\n Ox_basic_chip = {10,100,500,1000,5000}\r\n} return many_ox_room_config\r\n');
INSERT INTO `t_game_server_cfg` VALUES ('60', 'furit', '0', '0', '127.0.0.1', '7735', '1', '1', '9', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('70', 'benz_bmw', '0', '0', '127.0.0.1', '7736', '1', '1', '10', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('80', 'texas', '0', '0', '127.0.0.1', '7737', '1', '1', '11', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('90', 'slotma', '0', '0', '127.0.0.1', '7738', '1', '1', '12', '1', '2000', '[{\"cell_money\": 100, \"lines\": [{\"line\": [{\"y\": 1, \"x\": 0}, {\"y\": 1, \"x\": 1}, {\"y\": 1, \"x\": 2}, {\"y\": 1, \"x\": 3}, {\"y\": 1, \"x\": 4}], \"id\": 1}, {\"line\": [{\"y\": 0, \"x\": 0}, {\"y\": 0, \"x\": 1}, {\"y\": 0, \"x\": 2}, {\"y\": 0, \"x\": 3}, {\"y\": 0, \"x\": 4}], \"id\": 2}, {\"line\": [{\"y\": 2, \"x\": 0}, {\"y\": 2, \"x\": 1}, {\"y\": 2, \"x\": 2}, {\"y\": 2, \"x\": 3}, {\"y\": 2, \"x\": 4}], \"id\": 3}, {\"line\": [{\"y\": 0, \"x\": 0}, {\"y\": 1, \"x\": 1}, {\"y\": 2, \"x\": 2}, {\"y\": 1, \"x\": 3}, {\"y\": 0, \"x\": 4}], \"id\": 4}, {\"line\": [{\"y\": 2, \"x\": 0}, {\"y\": 1, \"x\": 1}, {\"y\": 0, \"x\": 2}, {\"y\": 1, \"x\": 3}, {\"y\": 2, \"x\": 4}], \"id\": 5}, {\"line\": [{\"y\": 0, \"x\": 0}, {\"y\": 0, \"x\": 1}, {\"y\": 1, \"x\": 2}, {\"y\": 2, \"x\": 3}, {\"y\": 2, \"x\": 4}], \"id\": 6}, {\"line\": [{\"y\": 2, \"x\": 0}, {\"y\": 2, \"x\": 1}, {\"y\": 1, \"x\": 2}, {\"y\": 0, \"x\": 3}, {\"y\": 0, \"x\": 4}], \"id\": 7}, {\"line\": [{\"y\": 1, \"x\": 0}, {\"y\": 2, \"x\": 1}, {\"y\": 2, \"x\": 2}, {\"y\": 2, \"x\": 3}, {\"y\": 1, \"x\": 4}], \"id\": 8}, {\"line\": [{\"y\": 1, \"x\": 0}, {\"y\": 0, \"x\": 1}, {\"y\": 0, \"x\": 2}, {\"y\": 0, \"x\": 3}, {\"y\": 1, \"x\": 4}], \"id\": 8}], \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"items\": [{\"winingtype\": [{\"number\": 3, \"times\": 2}, {\"number\": 4, \"times\": 5}, {\"number\": 5, \"times\": 20}], \"id\": 1, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 3}, {\"number\": 4, \"times\": 10}, {\"number\": 5, \"times\": 40}], \"id\": 2, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 5}, {\"number\": 4, \"times\": 15}, {\"number\": 5, \"times\": 60}], \"id\": 3, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 7}, {\"number\": 4, \"times\": 20}, {\"number\": 5, \"times\": 100}], \"id\": 4, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 10}, {\"number\": 4, \"times\": 30}, {\"number\": 5, \"times\": 160}], \"id\": 5, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 15}, {\"number\": 4, \"times\": 40}, {\"number\": 5, \"times\": 200}], \"id\": 6, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 20}, {\"number\": 4, \"times\": 80}, {\"number\": 5, \"times\": 400}], \"id\": 7, \"number\": 5}, {\"winingtype\": [{\"number\": 3, \"times\": 50}, {\"number\": 4, \"times\": 200}, {\"number\": 5, \"times\": 1000}], \"id\": 8, \"number\": 5}], \"tax_open\": 1, \"money_limit\": 1000, \"linelen\": 5}]', '');

DROP TABLE IF EXISTS `t_gate_server_cfg`;
CREATE TABLE `t_gate_server_cfg` (
  `gate_id` int(11) NOT NULL COMMENT '网关服务器ID',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该网关配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `timeout_limit` int(11) NOT NULL DEFAULT '0' COMMENT '超时（秒）',
  `sms_time_limit` int(11) NOT NULL DEFAULT '0' COMMENT '发短信间隔',
  `sms_url` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '短信url',
  `sms_sign_key` varchar(256) NOT NULL DEFAULT '' COMMENT '短信接口签名',
  PRIMARY KEY (`gate_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci ;

-- ----------------------------
-- Records of t_gate_server_cfg
-- ----------------------------
INSERT INTO `t_gate_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7788', '30', '90', 'http://14.29.123.144:80/api/account/sms','c12345678');

DROP TABLE IF EXISTS `t_login_server_cfg`;
CREATE TABLE `t_login_server_cfg` (
  `login_id` int(11) NOT NULL COMMENT '登陆服务器ID',
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该登陆服务器配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  PRIMARY KEY (`login_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- Records of t_login_server_cfg
-- ----------------------------
INSERT INTO `t_login_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7710');

DROP TABLE IF EXISTS `t_db_server_cfg`;
CREATE TABLE `t_db_server_cfg` (
  `id` int(11) NOT NULL,
  `is_start` int(11) NOT NULL DEFAULT '0' COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该登陆服务器配置',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `login_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB地址',
  `login_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB账号',
  `login_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB密码',
  `login_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '登陆DB数据库',
  `game_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB地址',
  `game_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB账号',
  `game_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB密码',
  `game_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '游戏DB数据库',
  `log_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB地址',
  `log_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB账号',
  `log_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB密码',
  `log_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '日志DB数据库',
  `recharge_db_host` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值提现DB地址',
  `recharge_db_user` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值提现DB账号',
  `recharge_db_password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值提现DB密码',
  `recharge_db_database` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '充值提现DB数据库',
  `cash_money_addr` varchar(255) DEFAULT NULL COMMENT 'PHP地址',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

INSERT INTO `t_db_server_cfg` VALUES ('1', '1', '1', '127.0.0.1', '7700', 'tcp://127.0.0.1:3306', 'root', '123456', 'account', 'tcp://127.0.0.1:3306', 'root', '123456', 'game', 'tcp://127.0.0.1:3306', 'root', '123456', 'log', 'tcp://127.0.0.1:3306', 'root', '123456', 'recharge', 'http://119.23.142.36:8080/api/index/cash');


DROP TABLE IF EXISTS `t_redis_cfg`;
CREATE TABLE `t_redis_cfg` (
  `id` bigint(20) NOT NULL COMMENT 'id',
  `is_sentinel` int(11) NOT NULL DEFAULT '0' COMMENT '1是哨兵，0不是',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `dbnum` int(11) NOT NULL COMMENT '数据库号',
  `password` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT 'redis密码',
  `master_name` varchar(256) COLLATE utf8_general_ci DEFAULT '' COMMENT '主redis名字',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_redis_cfg
-- ----------------------------
INSERT INTO `t_redis_cfg` VALUES ('1', '0', '127.0.0.1', '6379', '0', 'foobared', '');


-- ----------------------------
-- Procedure structure for `get_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_db_config`;
DELIMITER ;;
CREATE PROCEDURE `get_db_config`(IN `db_id_` int)
    COMMENT '得到db配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE port_  INT DEFAULT 0;
	DECLARE login_db_host_ varchar(256) DEFAULT '';
	DECLARE login_db_user_ varchar(256) DEFAULT '';
	DECLARE login_db_password_ varchar(256) DEFAULT '';
	DECLARE login_db_database_ varchar(256) DEFAULT '';
	DECLARE game_db_host_ varchar(256) DEFAULT '';
	DECLARE game_db_user_ varchar(256) DEFAULT '';
	DECLARE game_db_password_ varchar(256) DEFAULT '';
	DECLARE game_db_database_ varchar(256) DEFAULT '';
	DECLARE log_db_host_ varchar(256) DEFAULT '';
	DECLARE log_db_user_ varchar(256) DEFAULT '';
	DECLARE log_db_password_ varchar(256) DEFAULT '';
	DECLARE log_db_database_ varchar(256) DEFAULT '';
	DECLARE recharge_db_host_ varchar(256) DEFAULT '';
	DECLARE recharge_db_user_ varchar(256) DEFAULT '';
	DECLARE recharge_db_password_ varchar(256) DEFAULT '';
	DECLARE recharge_db_database_ varchar(256) DEFAULT '';
	DECLARE cash_money_addr_ varchar(256) DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';	
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';
	
	DECLARE cur1 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
	OPEN cur2;
	
	# 查询自己的配置
	SELECT 	port,
	login_db_host,login_db_user,login_db_password,login_db_database,
	game_db_host,game_db_user,game_db_password,game_db_database,
	log_db_host,log_db_user,log_db_password,log_db_database,
	recharge_db_host,recharge_db_user,recharge_db_password,recharge_db_database,
	cash_money_addr  
	INTO port_,
	login_db_host_,login_db_user_,login_db_password_,login_db_database_,
	game_db_host_,game_db_user_,game_db_password_,game_db_database_,
	log_db_host_,log_db_user_,log_db_password_,log_db_database_,
	recharge_db_host_,recharge_db_user_,recharge_db_password_,recharge_db_database_,
	cash_money_addr_
	FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('port: ', port_,
		'\n login_db { ',
		'\nhost: "', login_db_host_,	'"\nuser: "', login_db_user_,	'"\npassword: "', login_db_password_,	'"\ndatabase: "', login_db_database_, '"\n}\n',	
		'game_db { ',
		'\nhost: "', game_db_host_,	'"\nuser: "', game_db_user_,	'"\npassword: "', game_db_password_,	'"\ndatabase: "', game_db_database_, '"\n}\n',
		'log_db { ',	
		'\nhost: "', log_db_host_,	'"\nuser: "', log_db_user_,	'"\npassword: "', log_db_password_,	'"\ndatabase: "', log_db_database_, '"\n}\n',
		'recharge_db { ',	
		'\nhost: "', recharge_db_host_,	'"\nuser: "', recharge_db_user_,	'"\npassword: "', recharge_db_password_,	'"\ndatabase: "', recharge_db_database_, '"\n}\n');

		# 查询redis配置
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
		END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET result_ = CONCAT(result_, 'cash_money_addr: "', cash_money_addr_, '"\n');

		# 设置服务器开启
		UPDATE t_db_server_cfg SET is_start = 1 WHERE id = db_id_;
	END IF;
	
	SELECT ret_, result_;
END
;;
DELIMITER ;
-- ----------------------------
-- Procedure structure for `get_game_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_game_config`;
DELIMITER ;;
CREATE PROCEDURE `get_game_config`(IN `game_id_` int)
    COMMENT '得到login配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE using_login_validatebox_ int(11) DEFAULT '0';
	DECLARE default_lobby_ int(11) DEFAULT '0';
	DECLARE first_game_type_ int(11) DEFAULT '0';
	DECLARE second_game_type_ int(11) DEFAULT '0';
	DECLARE player_limit_ int(11) DEFAULT '0';
	DECLARE room_list_ varchar(256) DEFAULT '';
	DECLARE room_lua_cfg_ TEXT DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';

	DECLARE cur1 CURSOR FOR SELECT ip, port FROM t_login_server_cfg;
	DECLARE cur2 CURSOR FOR SELECT ip, port FROM t_db_server_cfg;
	DECLARE cur3 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur4 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;
	OPEN cur3;
	OPEN cur4;

	# 查询自己的IP端口
	SELECT ip, port, using_login_validatebox, default_lobby, first_game_type, second_game_type, player_limit, room_list, room_lua_cfg INTO ip_, port_, using_login_validatebox_, default_lobby_, first_game_type_, second_game_type_, player_limit_, room_list_, room_lua_cfg_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('game_id: ', game_id_, '\nport: ', port_, '\nusing_login_validatebox: ', using_login_validatebox_, '\ndefault_lobby: ', default_lobby_, '\nfirst_game_type: ', first_game_type_,  '\nsecond_game_type: ', second_game_type_,  '\nplayer_limit: ', player_limit_, '\n');

		# 查询连接login的IP端口
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询连接db的IP端口
		REPEAT
			FETCH cur2 INTO ip_temp, port_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询redis配置
		REPEAT
			FETCH cur3 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur4 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_game_server_cfg SET is_start = 1 WHERE game_id = game_id_;
	END IF;
	SELECT ret_, result_, room_list_, room_lua_cfg_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_login_config`;
DELIMITER ;;
CREATE PROCEDURE `get_login_config`(IN `login_id_` int)
    COMMENT '得到login配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;
	DECLARE dbnum_temp INT DEFAULT 0;
	DECLARE password_temp varchar(256) DEFAULT '';
	DECLARE master_name_temp varchar(256) DEFAULT '';

	DECLARE cur1 CURSOR FOR SELECT ip, port FROM t_db_server_cfg;
	DECLARE cur2 CURSOR FOR SELECT ip, port, dbnum, password FROM t_redis_cfg WHERE is_sentinel = 0 LIMIT 1;
	DECLARE cur3 CURSOR FOR SELECT ip, port, dbnum, password, master_name FROM t_redis_cfg WHERE is_sentinel = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;
	OPEN cur3;

	# 查询自己的IP端口
	SELECT ip, port INTO ip_, port_ FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;	
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('login_id: ', login_id_, '\nport: ', port_, '\n');

		# 查询连接db的IP端口
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询redis配置
		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp, password_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_redis {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\n}\n');
		END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		REPEAT
			FETCH cur3 INTO ip_temp, port_temp, dbnum_temp, password_temp, master_name_temp;
			IF NOT done THEN
				SET result_ = CONCAT(result_, 'def_sentinel {\nip: "', ip_temp, '"\nport: ', port_temp, '\ndbnum: ', dbnum_temp, '\npassword: "', password_temp, '"\nmaster_name: "', master_name_temp, '"\n}\n');
			END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_login_server_cfg SET is_start = 1 WHERE login_id = login_id_;
	END IF;
	SELECT ret_, result_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_gate_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_gate_config`;
DELIMITER ;;
CREATE PROCEDURE `get_gate_config`(IN `gate_id_` int)
    COMMENT '得到gate配置'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE port_ INT DEFAULT 0;
	DECLARE timeout_limit_ int(11) DEFAULT '0';
	DECLARE sms_time_limit_ int(11) DEFAULT '0';
	DECLARE sms_url_ varchar(256) DEFAULT '';
	DECLARE sms_sign_key_ varchar(256) DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	DECLARE cur1 CURSOR FOR SELECT ip, port FROM t_login_server_cfg;
	DECLARE cur2 CURSOR FOR SELECT ip, port FROM t_game_server_cfg WHERE is_open = 1;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;
	OPEN cur2;

	# 查询自己的IP端口
	SELECT ip, port, timeout_limit, sms_time_limit, sms_url,sms_sign_key INTO ip_, port_, timeout_limit_, sms_time_limit_, sms_url_,sms_sign_key_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	IF port_ != 0 THEN
		SET ret_ = 1;
		SET result_ = CONCAT('gate_id: ', gate_id_, '\nport: ', port_, '\ntimeout_limit: ', timeout_limit_, '\nsms_time_limit: ', sms_time_limit_,  '\nsms_url: "', sms_url_,  '"\nsms_sign_key: "', sms_sign_key_, '"\n');

		# 查询连接login的IP端口
		REPEAT
		FETCH cur1 INTO ip_temp, port_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
  
		SET done = 0;
  
		# 查询连接game的IP端口
		REPEAT
		FETCH cur2 INTO ip_temp, port_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'game_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_gate_server_cfg SET is_start = 1 WHERE gate_id = gate_id_;
	END IF;
	SELECT ret_, result_;
END
;;
DELIMITER ;

SET FOREIGN_KEY_CHECKS=1;