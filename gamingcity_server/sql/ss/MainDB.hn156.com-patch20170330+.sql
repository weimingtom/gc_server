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


USE `config`;

-- ----------------------------
-- Table structure for `t_globle_int_cfg`
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_int_cfg`;
CREATE TABLE `t_globle_int_cfg` (
  `key` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键',
  `value` int(11) NOT NULL COMMENT '值',
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_globle_int_cfg
-- ----------------------------
INSERT INTO `t_globle_int_cfg` VALUES ('bank_transfer_tax', '5');

-- ----------------------------
-- Table structure for `t_globle_string_cfg`
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_string_cfg`;
CREATE TABLE `t_globle_string_cfg` (
  `key` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键',
  `value` varchar(256) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '值',
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_globle_string_cfg
-- ----------------------------
INSERT INTO `t_globle_string_cfg` VALUES ('php_sign_key', 'c12345678');


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

	DECLARE cur1 CURSOR FOR SELECT ip, port, login_id FROM t_login_server_cfg WHERE is_open = 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, id FROM t_db_server_cfg WHERE is_open = 1;
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

		# 通用配置
		SELECT `value` INTO port_temp FROM t_globle_int_cfg WHERE `key` = 'bank_transfer_tax';
		SET result_ = CONCAT(result_, 'bank_transfer_tax: ', port_temp, '\n');

		# 查询连接login的IP端口
		REPEAT
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
			END IF;
		UNTIL done END REPEAT;

		SET done = 0;

		# 查询连接db的IP端口
		REPEAT
			FETCH cur2 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
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

	DECLARE cur1 CURSOR FOR SELECT ip, port, id FROM t_db_server_cfg WHERE is_open = 1;
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
			FETCH cur1 INTO ip_temp, port_temp, dbnum_temp;
			IF NOT done THEN
				IF ip_temp = ip_ THEN
					SET ip_temp = '127.0.0.1';
				END IF;
				SET result_ = CONCAT(result_, 'db_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', dbnum_temp, '\n}\n');
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
	DECLARE server_id_temp INT DEFAULT 0;
	
	DECLARE cur1 CURSOR FOR SELECT ip, port, login_id FROM t_login_server_cfg WHERE is_open = 1;
	DECLARE cur2 CURSOR FOR SELECT ip, port, game_id FROM t_game_server_cfg WHERE is_open = 1;
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
		FETCH cur1 INTO ip_temp, port_temp, server_id_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'login_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', server_id_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
  
		SET done = 0;
  
		# 查询连接game的IP端口
		REPEAT
		FETCH cur2 INTO ip_temp, port_temp, server_id_temp;
		IF NOT done THEN
			IF ip_temp = ip_ THEN
				SET ip_temp = '127.0.0.1';
			END IF;
			SET result_ = CONCAT(result_, 'game_addr {\nip: "', ip_temp, '"\nport: ', port_temp, '\nserver_id: ', server_id_temp, '\n}\n');
		END IF;
		UNTIL done END REPEAT;
		
		# 设置服务器开启
		UPDATE t_gate_server_cfg SET is_start = 1 WHERE gate_id = gate_id_;
	END IF;
	SELECT ret_, result_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_game_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_game_db_config`;
DELIMITER ;;
CREATE PROCEDURE `update_game_db_config`(IN `game_id_` int, IN `db_id_` int)
    COMMENT '更新game连接db配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_game_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_game_login_config`;
DELIMITER ;;
CREATE PROCEDURE `update_game_login_config`(IN `game_id_` int, IN `login_id_` int)
    COMMENT '更新game连接login配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_gate_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_gate_config`;
DELIMITER ;;
CREATE PROCEDURE `update_gate_config`(IN `gate_id_` int, IN `game_id_` int)
    COMMENT '更新gate连接game配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_game_server_cfg WHERE game_id = game_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_gate_login_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_gate_login_config`;
DELIMITER ;;
CREATE PROCEDURE `update_gate_login_config`(IN `gate_id_` int, IN `login_id_` int)
    COMMENT '更新gate连接login配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_gate_server_cfg WHERE gate_id = gate_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `update_login_db_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_login_db_config`;
DELIMITER ;;
CREATE PROCEDURE `update_login_db_config`(IN `login_id_` int, IN `db_id_` int)
    COMMENT '更新login连接db配置'
BEGIN
	DECLARE ip_ varchar(256) DEFAULT '';
	DECLARE ip_temp varchar(256) DEFAULT '';
	DECLARE port_temp INT DEFAULT 0;

	SELECT ip INTO ip_ FROM t_login_server_cfg WHERE login_id = login_id_ AND is_open = 1;
	SELECT ip, port INTO ip_temp, port_temp FROM t_db_server_cfg WHERE id = db_id_ AND is_open = 1;
	IF ip_temp = ip_ THEN
		SET ip_temp = '127.0.0.1';
	END IF;

	SELECT ip_temp, port_temp;
END
;;
DELIMITER ;

SET FOREIGN_KEY_CHECKS=1;