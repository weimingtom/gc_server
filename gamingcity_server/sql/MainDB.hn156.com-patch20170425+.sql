SET FOREIGN_KEY_CHECKS=0;

USE `account`;

ALTER TABLE `t_online_account` ADD COLUMN `in_game`  int(11) NOT NULL DEFAULT 0 COMMENT '1在玩游戏，0在大厅' AFTER `game_id`;


USE `game`;



ALTER TABLE `t_notice` MODIFY COLUMN `name`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '标题' AFTER `send_range`;
ALTER TABLE `t_notice` MODIFY COLUMN `content`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '内容' AFTER `name`;

ALTER TABLE `t_notice_private` MODIFY COLUMN `content`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '内容' AFTER `name`;

ALTER TABLE `t_player` ADD COLUMN `slotma_addition`  int(11) NOT NULL DEFAULT 0 COMMENT '老虎机中奖权重' AFTER `header_icon`;

-- ----------------------------
-- Procedure structure for `get_player_data`
-- ----------------------------
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
	SELECT level, money, bank, login_award_day, login_award_receive_day, online_award_time, online_award_num, relief_payment_count, header_icon, slotma_addition FROM t_player WHERE guid=guid_;
	
END
;;
DELIMITER ;


USE `config`;

ALTER TABLE `t_game_server_cfg` MODIFY COLUMN `second_game_type`  int(11) NOT NULL DEFAULT 0 COMMENT '二级菜单：斗地主（1新手场2初级场3高级场4富豪场）,扎金花（1乞丐场2平民场3中端场4富豪场5贵宾场）,百人牛牛（1高倍场,2低倍场）' AFTER `first_game_type`;


REPLACE INTO `t_game_server_cfg` VALUES ('90', 'slotma', '0', '1', '116.31.99.145', '7090', '0', '1', '12', '1', '2000', '[{\"cell_money\": 10, \"tax\": 1, \"tax_show\": 0, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', 'slotma_room_config = {\r\n random_count = 5,\r\n max_times = 100\r\n}return slotma_room_config');
REPLACE INTO `t_game_server_cfg` VALUES ('91', 'slotma', '0', '1', '116.31.99.145', '7091', '0', '1', '12', '3', '2000', '[{\"cell_money\": 100, \"tax\": 1, \"tax_show\": 0, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 10000}]', 'slotma_room_config = {\r\n random_count = 4,\r\n max_times = 200\r\n}return slotma_room_config');
REPLACE INTO `t_game_server_cfg` VALUES ('92', 'slotma', '0', '1', '116.31.99.145', '7092', '0', '1', '12', '4', '2000', '[{\"cell_money\": 1000, \"tax\": 1, \"tax_show\": 0, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 100000}]', 'slotma_room_config = {\r\n random_count = 3,\r\n max_times = 500\r\n}return slotma_room_config');

INSERT INTO `t_globle_int_cfg` VALUES ('cash_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('game_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('login_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('ali_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('wx_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('agent_recharge_switch', '0');

ALTER TABLE `t_db_server_cfg` ADD COLUMN `php_interface_addr`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'PHP接口地址' AFTER `recharge_db_database`;

ALTER TABLE `t_db_server_cfg` MODIFY COLUMN `cash_money_addr`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '提现地址' AFTER `php_interface_addr`;

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
	DECLARE php_interface_addr_ varchar(256) DEFAULT '';	
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
	cash_money_addr, php_interface_addr
	INTO port_,
	login_db_host_,login_db_user_,login_db_password_,login_db_database_,
	game_db_host_,game_db_user_,game_db_password_,game_db_database_,
	log_db_host_,log_db_user_,log_db_password_,log_db_database_,
	recharge_db_host_,recharge_db_user_,recharge_db_password_,recharge_db_database_,
	cash_money_addr_,php_interface_addr_
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

		# 通用配置
		SELECT `value` INTO ip_temp FROM t_globle_string_cfg WHERE `key` = 'php_sign_key';
		SET result_ = CONCAT(result_, 'php_sign_key: "', ip_temp, '"\n');
		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'bank_transfer_tax';
		SET result_ = CONCAT(result_, 'bank_transfer_tax: ', port_temp, '\n');

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
		SET result_ = CONCAT(result_, 'php_interface_addr: "', php_interface_addr_, '"\n');

		# 设置服务器开启
		UPDATE t_db_server_cfg SET is_start = 1 WHERE id = db_id_;
	END IF;
	
	SELECT ret_, result_;
END
;;
DELIMITER ;


USE `recharge`;

-- ----------------------------
-- Table structure for t_re_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_re_recharge`;
CREATE TABLE `t_re_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 成功',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '增加类型',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '对应id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='补充表';

SET FOREIGN_KEY_CHECKS=1;