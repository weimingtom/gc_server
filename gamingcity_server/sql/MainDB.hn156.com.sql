SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS `account`;
CREATE DATABASE `account` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `account`;

-- ----------------------------
-- Table structure for `t_account`
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account` (
  `guid` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '账号',
  `password` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '密码',
  `is_guest` int(11) NOT NULL DEFAULT '0' COMMENT '是否是游客 1是游客',
  `nickname` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `enable_transfer` int(11) NOT NULL DEFAULT '0' COMMENT '1能够转账，0不能给其他玩家转账',
  `bank_password` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '银行密码',
  `vip` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `alipay_name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '加了星号的支付宝姓名',
  `alipay_name_y` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付宝姓名',
  `alipay_account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '加了星号的支付宝账号',
  `alipay_account_y` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付宝账号',
  `bang_alipay_time` timestamp NULL DEFAULT NULL COMMENT '支付宝绑时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `login_time` timestamp NULL DEFAULT NULL COMMENT '登陆时间',
  `logout_time` timestamp NULL DEFAULT NULL COMMENT '退出时间',
  `online_time` int(11) DEFAULT '0' COMMENT '累计在线时间',
  `login_count` int(11) DEFAULT '1' COMMENT '登录次数',
  `phone` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '手机名字：ios，android',
  `phone_type` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '手机具体型号',
  `version` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '版本号',
  `channel_id` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '渠道号',
  `package_name` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '安装包名字',
  `imei` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '设备唯一码',
  `ip` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '客户端ip',
  `last_login_phone` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录手机名字：ios，android',
  `last_login_phone_type` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录手机具体型号',
  `last_login_version` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录版本号',
  `last_login_channel_id` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录渠道号',
  `last_login_package_name` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录安装包名字',
  `last_login_imei` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录设备唯一码',
  `last_login_ip` varchar(256) COLLATE utf8_general_ci DEFAULT NULL COMMENT '最后登录IP',
  `change_alipay_num` int(11) DEFAULT '6' COMMENT '允许修改支付宝账号次数',
  `disabled` tinyint(4) DEFAULT '0' COMMENT '0启用  1禁用',
  `risk` tinyint(4) DEFAULT '0' COMMENT '危险等级0-9  9最危险',
  `recharge_count` bigint(20) DEFAULT '0' COMMENT '总充值金额',
  `cash_count` bigint(20) DEFAULT '0' COMMENT '总提现金额',
  `inviter_guid` int(11) DEFAULT '0' COMMENT '邀请人的id',
  `invite_code` varchar(32) DEFAULT '0' COMMENT '邀请码',
  PRIMARY KEY (`guid`),
  UNIQUE KEY `index_nickname` (`nickname`) USING BTREE,
  UNIQUE KEY `index_account` (`account`) USING BTREE,
  UNIQUE KEY `index_imei` (`imei`) USING BTREE,
  KEY `index_is_guest` (`is_guest`),
  KEY `index_password` (`password`),
  KEY `index_invite_code` (`invite_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='账号表';

-- ----------------------------
-- Table structure for `t_channel_invite`
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  `channel_lock` tinyint(3) DEFAULT '0' COMMENT '1开启 0关闭',
  `big_lock` tinyint(3) DEFAULT '1' COMMENT '1开启 0关闭',
  `tax_rate` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '税率 百分比',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of t_channel_invite
-- ----------------------------
INSERT INTO `t_channel_invite` VALUES ('1', 'new_baobo', '1', '1', '50');

-- ----------------------------
-- Table structure for `t_guest_id`
-- ----------------------------
DROP TABLE IF EXISTS `t_guest_id`;
CREATE TABLE `t_guest_id` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_key` int(11) NOT NULL DEFAULT '0' COMMENT '用于更新',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_id_key` (`id_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- Table structure for `t_online_account`
-- ----------------------------
DROP TABLE IF EXISTS `t_online_account`;
CREATE TABLE `t_online_account` (
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `first_game_type` int(11) DEFAULT NULL COMMENT '5斗地主 6炸金花 8百人牛牛',
  `second_game_type` int(11) DEFAULT NULL COMMENT '1新手场 2初级场 3 高级场 4富豪场',
  `game_id` int(11) DEFAULT NULL COMMENT '游戏ID',
  `in_game` int(11) NOT NULL DEFAULT '0' COMMENT '1在玩游戏，0在大厅',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='在线账号表';

-- ----------------------------
-- Procedure structure for `create_test_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_test_account`;
DELIMITER ;;
CREATE PROCEDURE `create_test_account`()
BEGIN
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE i INT DEFAULT 0;
	WHILE i < 3000 DO
		SET i = i + 1;
		SET account_ = CONCAT("test_",i);
		INSERT INTO t_account (account,password,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,MD5("123456"),account_,NOW(),"windows", "windows-test", "1.1", "test", "package-test", account_, "127.0.0.1");
	END WHILE;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `FreezeAccount`
-- ----------------------------
DROP PROCEDURE IF EXISTS `FreezeAccount`;
DELIMITER ;;
CREATE PROCEDURE `FreezeAccount`(IN `guid_` int(11),
								 IN `status_` tinyint(4))
    COMMENT '封号，参数guid_：账号id，status_：设置的状态'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_t int(11);
	DECLARE status_t tinyint(4);
	
	update account.t_account set disabled = status_ where guid = guid_;
	
	select guid , disabled into guid_t , status_t from account.t_account where guid = guid_;
	
	if guid_t is null then
		set guid_t = -1;
	end if;
	if status_t is null then
		set status_t = -1;
	end if;
	
	if guid_t != guid_ or status_t != status_ then
		set ret = 1;
	else
		set ret = 0;
	end if;
	select ret as retCode , concat(guid_t,'|',status_t) as  retData;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `create_account`
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_account`;
DELIMITER ;;
CREATE PROCEDURE `create_account`(IN `account_` VARCHAR(64), IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建账号'
BEGIN
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	SET password_ = MD5(account_);
	SET nickname_ = CONCAT("guest_", get_guest_id());

	INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,password_,0,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_);
	SELECT account_ AS account, password_ AS password, LAST_INSERT_ID() AS guid, nickname_ AS nickname;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `create_guest_account`
-- ----------------------------
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
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `sms_login`
-- ----------------------------
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
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `verify_account`
-- ----------------------------
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
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for `get_guest_id`
-- ----------------------------
DROP FUNCTION IF EXISTS `get_guest_id`;
DELIMITER ;;
CREATE FUNCTION `get_guest_id`() RETURNS bigint(20)
BEGIN
	REPLACE INTO t_guest_id SET id_key = 0;
	RETURN LAST_INSERT_ID();
END
;;
DELIMITER ;

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

DROP DATABASE IF EXISTS `game`;
CREATE DATABASE `game` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `game`;

-- ----------------------------
-- Table structure for `t_bag`
-- ----------------------------
DROP TABLE IF EXISTS `t_bag`;
CREATE TABLE `t_bag` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `pb_items` blob COMMENT '所有物品',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='背包表';

-- ----------------------------
-- Table structure for `t_channel_invite_tax`
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite_tax`;
CREATE TABLE `t_channel_invite_tax` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `guid` int(11) NOT NULL COMMENT 'guid',
  `val` int(11) NOT NULL DEFAULT '0' COMMENT '获得的收益',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `t_bank_statement`
-- ----------------------------
DROP TABLE IF EXISTS `t_bank_statement`;
CREATE TABLE `t_bank_statement` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '银行流水ID',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `time` timestamp NULL DEFAULT NULL COMMENT '记录时间',
  `opt` int(11) NOT NULL DEFAULT '0' COMMENT '操作类型',
  `target` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '目标',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '改变的钱',
  `bank_balance` int(11) NOT NULL DEFAULT '0' COMMENT '当前剩余的钱',
  PRIMARY KEY (`id`),
  KEY `index_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='银行流水表';

-- ----------------------------
-- Table structure for `t_daily_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_daily_earnings_rank`;
CREATE TABLE `t_daily_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='日盈利榜表';

-- ----------------------------
-- Table structure for `t_earnings`
-- ----------------------------
DROP TABLE IF EXISTS `t_earnings`;
CREATE TABLE `t_earnings` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `daily_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '日盈利',
  `weekly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '周盈利',
  `monthly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '月盈利',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='盈利榜表';

-- ----------------------------
-- Table structure for `t_fortune_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_fortune_rank`;
CREATE TABLE `t_fortune_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='总财富榜表';

-- ----------------------------
-- Table structure for `t_mail`
-- ----------------------------
DROP TABLE IF EXISTS `t_mail`;
CREATE TABLE `t_mail` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '邮件ID',
  `expiration_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '过期时间',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `send_guid` int(11) NOT NULL DEFAULT '0' COMMENT '发件人的全局唯一标识符',
  `send_name` varchar(32) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '发件人的名字',
  `title` varchar(32) COLLATE utf8_general_ci NOT NULL COMMENT '标题',
  `content` varchar(128) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '内容',
  `pb_attachment` blob COMMENT '附件',
  PRIMARY KEY (`id`),
  KEY `index_expiration_time_guid` (`expiration_time`,`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='邮件表';

-- ----------------------------
-- Table structure for `t_monthly_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_monthly_earnings_rank`;
CREATE TABLE `t_monthly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='月盈利榜表';

-- ----------------------------
-- Table structure for `t_notice`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice`;
CREATE TABLE `t_notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number` int(11) DEFAULT '0' COMMENT '轮播次数',
  `interval_time` int(11) DEFAULT '0' COMMENT '轮播时间间隔（秒）',
  `type` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '通知类型 1：消息通知 2：公告通知 3跑马灯',
  `send_range` tinyint(1) DEFAULT '0' COMMENT '发送范围 0：全部',
  `name` varchar(1024) COLLATE utf8_general_ci DEFAULT NULL COMMENT '标题',
  `content` text DEFAULT NULL COMMENT '内容',
  `author` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '发送时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='通知表';

-- ----------------------------
-- Table structure for `t_notice_private`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_private`;
CREATE TABLE `t_notice_private` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) DEFAULT NULL COMMENT '用户ID,与account.t_account',
  `account` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '用户账号',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '用户昵称',
  `type` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '通知类型 1：消息通知',
  `name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '标题',
  `content` text DEFAULT NULL COMMENT '内容',
  `author` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `is_read` tinyint(1) DEFAULT '0' COMMENT '是否阅读 1:已读 0:未读',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`),
  KEY `index_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='私信通知表';

-- ----------------------------
-- Table structure for `t_notice_read`
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_read`;
CREATE TABLE `t_notice_read` (
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `n_id` int(11) NOT NULL COMMENT '通知ID',
  `is_read` tinyint(1) DEFAULT '1' COMMENT '是否阅读 1：已读， 0：未读',
  `read_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '阅读时间',
  PRIMARY KEY (`guid`,`n_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='通知阅读明细表';

-- ----------------------------
-- Table structure for `t_ox_player_info`
-- ----------------------------
DROP TABLE IF EXISTS `t_ox_player_info`;
CREATE TABLE `t_ox_player_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `guid` int(11) NOT NULL COMMENT '用户ID',
  `is_android` int(11) NOT NULL COMMENT '是否机器人',
  `table_id` int(11) NOT NULL COMMENT '桌子ID',
  `banker_id` int(11) NOT NULL COMMENT '庄家ID',
  `nickname` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '昵称',
  `money` bigint(20) NOT NULL COMMENT '金币数',
  `win_money` bigint(20) NOT NULL COMMENT '该局输赢',
  `bet_money` int(11) NOT NULL COMMENT '玩家下注金币',
  `tax` int(11) NOT NULL COMMENT '玩家台费',
  `curtime` int(11) NOT NULL COMMENT '当前时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='百人牛牛收益表';

-- ----------------------------
-- Table structure for `t_many_ox_server_config`
-- ----------------------------
DROP TABLE IF EXISTS `t_many_ox_server_config`;
CREATE TABLE `t_many_ox_server_config` (
  `id` int(11) NOT NULL,
  `FreeTime` int(11) NOT NULL COMMENT '空闲时间',
  `BetTime` int(11) NOT NULL COMMENT '下注时间',
  `EndTime` int(11) NOT NULL COMMENT '结束时间',
  `MustWinCoeff` int(11) NOT NULL COMMENT '系统必赢系数',
  `BankerMoneyLimit` int(11) NOT NULL COMMENT '上庄条件限制',
  `SystemBankerSwitch` int(11) NOT NULL COMMENT '系统当庄开关',
  `BankerCount` int(11) NOT NULL COMMENT '连庄次数',
  `RobotBankerInitUid` int(11) NOT NULL COMMENT '系统庄家初始UID',
  `RobotBankerInitMoney` bigint(20) NOT NULL COMMENT '系统庄家初始金币',
  `BetRobotSwitch` int(11) NOT NULL COMMENT '下注机器人开关',
  `BetRobotInitUid` int(11) NOT NULL COMMENT '下注机器人初始UID',
  `BetRobotInitMoney` bigint(20) NOT NULL COMMENT '下注机器人初始金币',
  `BetRobotNumControl` int(11) NOT NULL COMMENT '下注机器人个数限制',
  `BetRobotTimesControl` int(11) NOT NULL COMMENT '机器人下注次数限制',
  `RobotBetMoneyControl` int(11) NOT NULL COMMENT '机器人下注金币限制',
  `BasicChip` varchar(64) COLLATE utf8_general_ci NOT NULL COMMENT '筹码信息',
  `ExtendA` int(11) NOT NULL COMMENT '预留字段A',
  `ExtendB` int(11) NOT NULL COMMENT '预留字段B',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='百人牛牛基础配置表';
INSERT INTO t_many_ox_server_config VALUES(1,3,18,15,30,1000000,1,5,100000,10000000,1,200000,35000,5,10,10000,'10,100,500,1000,5000',0,0); 


-- ----------------------------
-- Table structure for `t_player`
-- ----------------------------
DROP TABLE IF EXISTS `t_player`;
CREATE TABLE `t_player` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `is_android` int(11) NOT NULL DEFAULT '0' COMMENT '是机器人',
  `account` varchar(64) COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '账号',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `level` int(11) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `money` bigint(20) NOT NULL DEFAULT '0' COMMENT '有多少钱',
  `bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '银行存款',
  `login_award_day` int(11) NOT NULL DEFAULT '0' COMMENT '登录奖励，该领取那一天',
  `login_award_receive_day` int(11) NOT NULL DEFAULT '0' COMMENT '登录奖励，最近领取在那一天',
  `online_award_time` int(11) NOT NULL DEFAULT '0' COMMENT '在线奖励，今天已经在线时间',
  `online_award_num` int(11) NOT NULL DEFAULT '0' COMMENT '在线奖励，该领取哪个奖励',
  `relief_payment_count` int(11) NOT NULL DEFAULT '0' COMMENT '救济金，今天领取次数',
  `header_icon` int(11) NOT NULL DEFAULT '0' COMMENT '头像',
  `slotma_addition` int(11) NOT NULL DEFAULT '0' COMMENT '老虎机中奖权重',
  PRIMARY KEY (`guid`),
  UNIQUE KEY `index_account` (`account`),
  KEY `index_is_android` (`is_android`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='玩家表';

-- ----------------------------
-- Table structure for `t_rank_update_time`
-- ----------------------------
DROP TABLE IF EXISTS `t_rank_update_time`;
CREATE TABLE `t_rank_update_time` (
  `rank_type` int(11) NOT NULL COMMENT '排行榜类型',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '上次更新时间',
  PRIMARY KEY (`rank_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='排行榜更新时间表';

-- ----------------------------
-- Table structure for `t_weekly_earnings_rank`
-- ----------------------------
DROP TABLE IF EXISTS `t_weekly_earnings_rank`;
CREATE TABLE `t_weekly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) COLLATE utf8_general_ci DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='周盈利榜表';

-- ----------------------------
-- Procedure structure for `bank_transfer`
-- ----------------------------
DROP PROCEDURE IF EXISTS `bank_transfer`;
DELIMITER ;;
CREATE PROCEDURE `bank_transfer`(IN `guid_` int,IN `time_` int,IN `target_` varchar(64),IN `money_` int,IN `bank_balance_` int)
    COMMENT '银行转账，参数guid_：转账guid，time_：时间，target_：收款guid，money_：转多少钱，bank_balance_：剩下多少'
BEGIN
	DECLARE target_guid_ INT DEFAULT 0;
	DECLARE target_bank_ INT DEFAULT 0;

	UPDATE t_player SET bank = bank + money_ WHERE account = target_;
	IF ROW_COUNT() = 0 THEN
		SELECT 1 as ret, 0 as id;
	ELSE
		SELECT guid, bank INTO target_guid_, target_bank_ FROM t_player WHERE account = target_;
		#INSERT INTO t_bank_statement (guid,bank_balance,time,opt,target,money) VALUES(target_guid_,target_bank_,FROM_UNIXTIME(time_),3,(SELECT account FROM t_player WHERE guid = guid_),money_);
		#INSERT INTO t_bank_statement (guid,time,opt,target,money,bank_balance) VALUES(guid_,FROM_UNIXTIME(time_),2,target_,money_,bank_balance_);
		SELECT 0 as ret, LAST_INSERT_ID() as id;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `del_msg`
-- ----------------------------
DROP PROCEDURE IF EXISTS `del_msg`;
DELIMITER ;;
CREATE PROCEDURE `del_msg`(IN `ID_` int,
 IN `TYPE_` int)
    COMMENT 'ID_ 消息ID,TYPE_ 消息类型'
BEGIN
  DECLARE guid_ INT DEFAULT 0;
    IF TYPE_ = 1 THEN -- 消息
        select guid into guid_ from t_notice_private where id = ID_;
        delete from t_notice_private where id = ID_;
        IF ROW_COUNT() > 0 then
            select 0 as ret, guid_ as guid ;
        ELSE
            select 1 as ret, 1 as guid ;
        END IF;
    ELSEIF TYPE_ = 2 or TYPE_ = 3 THEN -- 公告及跑马灯
        delete from t_notice where id = ID_;
        IF ROW_COUNT() > 0 then
            delete from t_notice_read where n_id = ID_;
            select 0 as ret, 1 as guid;
        ELSE
            select 1 as ret, 1 as guid;
        END IF;
    END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_daily_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_daily_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_daily_earnings_rank`()
    COMMENT '得到日盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 2;
	IF last_time_ = 0 OR TO_DAYS(NOW()) != TO_DAYS(last_time_) THEN
		TRUNCATE TABLE t_daily_earnings_rank;
		INSERT INTO t_daily_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.daily_earnings FROM t_earnings, t_player WHERE t_earnings.daily_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.daily_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 2, update_time = NOW();
		UPDATE t_earnings SET daily_earnings = 0;
	END IF;
	SELECT * FROM t_daily_earnings_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_fortune_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_fortune_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_fortune_rank`()
    COMMENT '总财富榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 1;
	IF last_time_ = 0 OR TO_DAYS(NOW()) != TO_DAYS(last_time_) THEN
		TRUNCATE TABLE t_fortune_rank;
		INSERT INTO t_fortune_rank (guid, nickname, money) SELECT guid, nickname, money+bank FROM t_player WHERE money+bank > 0 ORDER BY money+bank DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 1, update_time = NOW();
	END IF;
	SELECT * FROM t_fortune_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `get_monthly_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_monthly_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_monthly_earnings_rank`()
    COMMENT '得到月盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 4;
	IF last_time_ = 0 OR EXTRACT(YEAR_MONTH FROM NOW()) != EXTRACT(YEAR_MONTH FROM last_time_) THEN
		TRUNCATE TABLE t_monthly_earnings_rank;
		INSERT INTO t_monthly_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.monthly_earnings FROM t_earnings, t_player WHERE t_earnings.monthly_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.monthly_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 4, update_time = NOW();
		UPDATE t_earnings SET monthly_earnings = 0;
	END IF;
	SELECT * FROM t_monthly_earnings_rank;
END
;;
DELIMITER ;

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

-- ----------------------------
-- Procedure structure for `get_player_invite_reward`
-- ----------------------------
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
	
END
;;
DELIMITER ;


-- ----------------------------
-- Procedure structure for `get_weekly_earnings_rank`
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_weekly_earnings_rank`;
DELIMITER ;;
CREATE PROCEDURE `get_weekly_earnings_rank`()
    COMMENT '得到周盈利榜'
BEGIN
	DECLARE last_time_ TIMESTAMP DEFAULT 0;
	SELECT update_time INTO last_time_ FROM t_rank_update_time WHERE rank_type = 3;
	IF last_time_ = 0 OR YEARWEEK(NOW()) != YEARWEEK(last_time_) THEN
		TRUNCATE TABLE t_weekly_earnings_rank;
		INSERT INTO t_weekly_earnings_rank (guid, nickname, money) SELECT t_earnings.guid, t_player.nickname, t_earnings.weekly_earnings FROM t_earnings, t_player WHERE t_earnings.weekly_earnings > 0 AND t_earnings.guid = t_player.guid ORDER BY t_earnings.weekly_earnings DESC LIMIT 50;
		REPLACE INTO t_rank_update_time SET rank_type = 3, update_time = NOW();
		UPDATE t_earnings SET weekly_earnings = 0;
	END IF;
	SELECT * FROM t_weekly_earnings_rank;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `save_bank_statement`
-- ----------------------------
DROP PROCEDURE IF EXISTS `save_bank_statement`;
DELIMITER ;;
CREATE PROCEDURE `save_bank_statement`(IN `guid_` int,IN `time_` int,IN `opt_` int,IN `target_` varchar(64),IN `money_` int,IN `bank_balance_` int)
    COMMENT '保存银行流水，参数guid_：操作guid，time_：时间，opt_：操作类型，target_：目标guid，money_：操作多少钱，bank_balance_：剩下多少'
BEGIN
	INSERT INTO t_bank_statement (guid,time,opt,target,money,bank_balance) VALUES(guid_,FROM_UNIXTIME(time_),opt_,target_,money_,bank_balance_);
	SELECT LAST_INSERT_ID() as id;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for `send_mail`
-- ----------------------------
DROP PROCEDURE IF EXISTS `send_mail`;
DELIMITER ;;
CREATE PROCEDURE `send_mail`(IN `expiration_time_` int,IN `guid_` int,IN `send_guid_` int,IN `send_name_` varchar(32),IN `title_` varchar(32),IN `content_` varchar(128),IN `attachment_` blob)
    COMMENT '发送邮件，参数expiration_time_：过期时间，guid_：收件guid，send_guid_：发件guid，send_name_：发件名字，title_：标题，content_：内容， attachment_：附件'
BEGIN
	IF NOT EXISTS(SELECT 1 FROM t_player WHERE guid = guid_) THEN
		SELECT 1 as ret, 0 as id;
	ELSE
		INSERT INTO t_mail (expiration_time, guid, send_guid, send_name, title, content, attachment) VALUES (FROM_UNIXTIME(expiration_time_), guid_, send_guid_, send_name_, title_, content_, attachment_);
		SELECT 0 as ret, LAST_INSERT_ID() as id;
	END IF;
END
;;
DELIMITER ;


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

DROP DATABASE IF EXISTS `config`;
CREATE DATABASE `config` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
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
  `first_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '一级菜单：5斗地主，6扎金花，8百人牛牛 ，12老虎机',
  `second_game_type` int(11) NOT NULL DEFAULT '0' COMMENT '二级菜单：斗地主（1新手场2初级场3高级场4富豪场）,扎金花（1乞丐场2平民场3中端场4富豪场5贵宾场）,百人牛牛（1高倍场,2低倍场）,老虎机(1练习场,3发财场,4爆机场)',
  `player_limit` int(11) NOT NULL COMMENT '人数限制',
  `room_list` text COMMENT '房间列表配置',
  `room_lua_cfg` text COMMENT '房间lua配置',
  PRIMARY KEY (`game_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci ;

INSERT INTO `t_game_server_cfg` VALUES ('1', 'lobby', '0', '0', '127.0.0.1', '7001', '1', '1', '1', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 0}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('2', 'demo', '0', '0', '127.0.0.1', '7702', '1', '1', '2', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('3', 'fishing', '0', '0', '127.0.0.1', '7703', '1', '1', '3', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 100}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('10', 'shuihu_zhuan', '0', '0', '127.0.0.1', '7010', '1', '1', '4', '1', '2000', '[{\"cell_money\": 0, \"tax\": 5, \"tax_show\": 1, \"table_count\": 300, \"tax_open\": 1, \"money_limit\": 100}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('20', 'land', '0', '1', '127.0.0.1', '7020', '1', '1', '5', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 200, \"GameLimitCdTime\" : 6}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('21', 'land', '0', '1', '127.0.0.1', '7021', '1', '1', '5', '2', '2000', '[{\"cell_money\": 30, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 600, \"GameLimitCdTime\" : 5}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('22', 'land', '0', '1', '127.0.0.1', '7022', '1', '1', '5', '3', '2000', '[{\"cell_money\": 50, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000, \"GameLimitCdTime\" : 4}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('23', 'land', '0', '1', '127.0.0.1', '7023', '1', '1', '5', '4', '2000', '[{\"cell_money\": 100, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 20000, \"GameLimitCdTime\" : 0}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('30', 'zhajinhua', '0', '1', '127.0.0.1', '7030', '1', '1', '6', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('31', 'zhajinhua', '0', '1', '127.0.0.1', '7031', '1', '1', '6', '2', '2000', '[{\"cell_money\": 100, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 6000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('32', 'zhajinhua', '0', '1', '127.0.0.1', '7032', '1', '1', '6', '3', '2000', '[{\"cell_money\": 500, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 30000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('33', 'zhajinhua', '0', '1', '127.0.0.1', '7033', '1', '1', '6', '4', '2000', '[{\"cell_money\": 1000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 60000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('34', 'zhajinhua', '0', '1', '127.0.0.1', '7034', '1', '1', '6', '5', '2000', '[{\"cell_money\": 2000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 120000}]', 'y = {[1] = {[10] = 10, [20] = 20, [50] =50, [80] = 80, [100] = 100}, [2] = {[100] = 100, [200] = 200, [500] =500, [800] = 800, [1000] = 1000}, [3] = {[500] = 500, [1000] = 1000, [2500] = 2500, [4000] = 4000, [5000] = 5000}, [4] = {[1000] = 1000, [2000] = 2000, [5000] = 5000, [8000] = 8000, [10000] = 10000}, [5] = {[2000] = 2000, [5000] = 5000, [10000] = 10000, [15000] = 15000, [20000] = 20000}} return y');
INSERT INTO `t_game_server_cfg` VALUES ('40', 'showhand', '0', '0', '127.0.0.1', '7040', '1', '1', '7', '1', '2000', '[{\"cell_money\": 1, \"max_call\": 1000, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('50', 'ox', '0', '1', '127.0.0.1', '7050', '1', '1', '8', '1', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', 'many_ox_room_config = {\r\n Ox_FreeTime = 3, \r\n Ox_BetTime = 18,\r\n Ox_EndTime = 15,\r\n Ox_MustWinCoeff = 5,\r\n Ox_FloatingCoeff = 3,\r\n Ox_bankerMoneyLimit = 1000000,\r\n Ox_SystemBankerSwitch = 1,\r\n Ox_BankerCount = 5,\r\n Ox_RobotBankerInitUid = 500000,\r\n Ox_RobotBankerInitMoney = 10000000,\r\n Ox_BetRobotSwitch = 1,\r\n Ox_BetRobotInitUid = 600000,\r\n Ox_BetRobotInitMoney = 35000,\r\n Ox_BetRobotNumControl = 5,\r\n Ox_BetRobotTimeControl = 10,\r\n Ox_RobotBetMoneyControl = 10000,\r\n Ox_PLAYER_MIN_LIMIT = 1000,\r\n Ox_basic_chip = {100,1000,5000,10000,50000}\r\n} return many_ox_room_config\r\n');
INSERT INTO `t_game_server_cfg` VALUES ('51', 'ox', '0', '1', '127.0.0.1', '7051', '1', '1', '8', '2', '2000', '[{\"cell_money\": 10, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', 'many_ox_room_config = {\r\n Ox_FreeTime = 3, \r\n Ox_BetTime = 18,\r\n Ox_EndTime = 15,\r\n Ox_MustWinCoeff = 5,\r\n Ox_FloatingCoeff = 3,\r\n Ox_bankerMoneyLimit = 300000,\r\n Ox_SystemBankerSwitch = 1,\r\n Ox_BankerCount = 5,\r\n Ox_RobotBankerInitUid = 700000,\r\n Ox_RobotBankerInitMoney = 10000000,\r\n Ox_BetRobotSwitch = 1,\r\n Ox_BetRobotInitUid = 800000,\r\n Ox_BetRobotInitMoney = 15000,\r\n Ox_BetRobotNumControl = 5,\r\n Ox_BetRobotTimeControl = 10,\r\n Ox_RobotBetMoneyControl = 10000,\r\n Ox_PLAYER_MIN_LIMIT = 1000,\r\n Ox_basic_chip = {100,500,1000,2000,5000}\r\n} return many_ox_room_config\r\n');
INSERT INTO `t_game_server_cfg` VALUES ('60', 'furit', '0', '0', '127.0.0.1', '7060', '1', '1', '9', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('70', 'benz_bmw', '0', '0', '127.0.0.1', '7070', '1', '1', '10', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('80', 'texas', '0', '0', '127.0.0.1', '7080', '1', '1', '11', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', '');
INSERT INTO `t_game_server_cfg` VALUES ('90', 'slotma', '0', '1', '127.0.0.1', '7090', '1', '1', '12', '1', '2000', '[{\"cell_money\": 10, \"tax\": 1, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 1000}]', 'slotma_room_config = {\r\n random_count = 5,\r\n max_times = 100\r\n}return slotma_room_config');
INSERT INTO `t_game_server_cfg` VALUES ('91', 'slotma', '0', '1', '127.0.0.1', '7091', '1', '1', '12', '2', '2000', '[{\"cell_money\": 50, \"tax\": 1, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 2000}]', 'slotma_room_config = {\r\n random_count = 4,\r\n max_times = 200\r\n}return slotma_room_config');
INSERT INTO `t_game_server_cfg` VALUES ('92', 'slotma', '0', '1', '127.0.0.1', '7092', '1', '1', '12', '3', '2000', '[{\"cell_money\": 100, \"tax\": 1, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 10000}]', 'slotma_room_config = {\r\n random_count = 4,\r\n max_times = 200\r\n}return slotma_room_config');
INSERT INTO `t_game_server_cfg` VALUES ('93', 'slotma', '0', '1', '127.0.0.1', '7093', '1', '1', '12', '4', '2000', '[{\"cell_money\": 1000, \"tax\": 1, \"tax_show\": 1, \"table_count\": 1, \"tax_open\": 1, \"money_limit\": 100000}]', 'slotma_room_config = {\r\n random_count = 3,\r\n max_times = 500\r\n}return slotma_room_config');
INSERT INTO `t_game_server_cfg` VALUES ('100', 'mj', '0', '0', '127.0.0.1', '7100', '1', '1', '13', '1', '2000', '[{\"cell_money\": 1, \"tax\": 5, \"tax_show\": 1, \"table_count\": 100, \"tax_open\": 1, \"money_limit\": 2000}]', 'mj_room_config = {\r\n mj_min_scale = 0,--番数\r\n} return mj_room_config');
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
  `php_interface_addr` varchar(255) DEFAULT NULL COMMENT 'PHP接口地址',
  `cash_money_addr` varchar(255) DEFAULT NULL COMMENT '提现地址',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;

INSERT INTO `t_db_server_cfg` VALUES ('1', '0', '1', '127.0.0.1', '7700', 'tcp://127.0.0.1:3306', 'root', '123456', 'account', 'tcp://127.0.0.1:3306', 'root', '123456', 'game', 'tcp://127.0.0.1:3306', 'root', '123456', 'log', 'tcp://127.0.0.1:3306', 'root', '123456', 'recharge', 'http://14.29.123.185/api/notice/notice_server', 'http://14.29.123.185/api/index/cash');


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
INSERT INTO `t_globle_int_cfg` VALUES ('cash_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('game_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('login_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('ali_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('wx_recharge_switch', '0');
INSERT INTO `t_globle_int_cfg` VALUES ('agent_recharge_switch', '0');

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


DROP DATABASE IF EXISTS `recharge`;
CREATE DATABASE `recharge` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `recharge`;


SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for t_cash
-- ----------------------------
DROP TABLE IF EXISTS `t_cash`;
CREATE TABLE `t_cash` (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `bag_id` varchar(255) NOT NULL DEFAULT '' COMMENT '渠道号',
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP',
  `phone_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android',
  `phone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `coins` bigint(20) NOT NULL DEFAULT '0' COMMENT '提款金币',
  `pay_money` bigint(20) NOT NULL COMMENT '实际获得金额',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功',
  `status_c` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家 6服务器接收成功处理中',
  `reason` varchar(500) COLLATE utf8_general_ci DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由',
  `return_c` varchar(500) COLLATE utf8_general_ci DEFAULT NULL COMMENT 'C++返回扣币是否成功数据',
  `return` varchar(500) COLLATE utf8_general_ci DEFAULT NULL COMMENT '打款端返回是否打款成功数据',
  `check_name` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '审核人',
  `check_time` timestamp NULL DEFAULT NULL COMMENT '审核时间',
  `before_money` bigint(20) DEFAULT NULL COMMENT '提现前金钱',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '提现前银行金钱',
  `after_money` bigint(20) DEFAULT NULL COMMENT '提现后金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '提现后银行金钱',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`order_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='提现表'
/*!50100 PARTITION BY RANGE (UNIX_TIMESTAMP(created_at))
(PARTITION t_cash_p201701l VALUES LESS THAN (1485878400) ENGINE = InnoDB,
 PARTITION t_cash_p201702 VALUES LESS THAN (1488297600) ENGINE = InnoDB,
 PARTITION t_cash_p201703 VALUES LESS THAN (1490976000) ENGINE = InnoDB,
 PARTITION t_cash_p201704 VALUES LESS THAN (1493568000) ENGINE = InnoDB,
 PARTITION t_cash_p201705 VALUES LESS THAN (1496246400) ENGINE = InnoDB,
 PARTITION t_cash_p201706 VALUES LESS THAN (1498838400) ENGINE = InnoDB,
 PARTITION t_cash_p201707 VALUES LESS THAN (1501516800) ENGINE = InnoDB,
 PARTITION t_cash_p201708 VALUES LESS THAN (1504195200) ENGINE = InnoDB,
 PARTITION t_cash_p201709 VALUES LESS THAN (1506787200) ENGINE = InnoDB,
 PARTITION t_cash_p201710 VALUES LESS THAN (1509465600) ENGINE = InnoDB,
 PARTITION t_cash_p201711 VALUES LESS THAN (1512057600) ENGINE = InnoDB,
 PARTITION t_cash_p201712 VALUES LESS THAN (1514736000) ENGINE = InnoDB,
 PARTITION t_cash_p201801 VALUES LESS THAN (1517414400) ENGINE = InnoDB,
 PARTITION t_cash_p201802 VALUES LESS THAN (1519833600) ENGINE = InnoDB,
 PARTITION t_cash_p201803 VALUES LESS THAN (1522512000) ENGINE = InnoDB,
 PARTITION t_cash_p201804 VALUES LESS THAN (1525104000) ENGINE = InnoDB,
 PARTITION t_cash_p201805 VALUES LESS THAN (1527782400) ENGINE = InnoDB,
 PARTITION t_cash_p201806 VALUES LESS THAN (1530374400) ENGINE = InnoDB,
 PARTITION t_cash_p201807 VALUES LESS THAN (1533052800) ENGINE = InnoDB,
 PARTITION t_cash_p201808 VALUES LESS THAN (1535731200) ENGINE = InnoDB,
 PARTITION t_cash_p201809 VALUES LESS THAN (1538323200) ENGINE = InnoDB,
 PARTITION t_cash_p201810 VALUES LESS THAN (1541001600) ENGINE = InnoDB,
 PARTITION t_cash_p201811 VALUES LESS THAN (1543593600) ENGINE = InnoDB,
 PARTITION t_cash_p201812 VALUES LESS THAN (1546272000) ENGINE = InnoDB,
 PARTITION t_cash_p201901 VALUES LESS THAN (1548950400) ENGINE = InnoDB,
 PARTITION t_cash_p201902 VALUES LESS THAN (1551369600) ENGINE = InnoDB,
 PARTITION t_cash_p201903 VALUES LESS THAN (1554048000) ENGINE = InnoDB,
 PARTITION t_cash_p201904 VALUES LESS THAN (1556640000) ENGINE = InnoDB,
 PARTITION t_cash_p201905 VALUES LESS THAN (1559318400) ENGINE = InnoDB,
 PARTITION t_cash_p201906 VALUES LESS THAN (1561910400) ENGINE = InnoDB,
 PARTITION t_cash_p201907 VALUES LESS THAN (1564588800) ENGINE = InnoDB,
 PARTITION t_cash_p201908 VALUES LESS THAN (1567267200) ENGINE = InnoDB,
 PARTITION t_cash_p201909 VALUES LESS THAN (1569859200) ENGINE = InnoDB,
 PARTITION t_cash_p201910 VALUES LESS THAN (1572537600) ENGINE = InnoDB,
 PARTITION t_cash_p201911 VALUES LESS THAN (1575129600) ENGINE = InnoDB,
 PARTITION t_cash_p201912 VALUES LESS THAN (1577808000) ENGINE = InnoDB,
 PARTITION t_cash_p201912g VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

-- ----------------------------
-- Records of t_cash
-- ----------------------------

-- ----------------------------
-- Table structure for t_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge`;
CREATE TABLE `t_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值日志表';

-- ----------------------------
-- Records of t_recharge
-- ----------------------------

-- ----------------------------
-- Table structure for t_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_order`;
CREATE TABLE `t_recharge_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_order_no` varchar(50) COLLATE utf8_general_ci NOT NULL COMMENT '支付流水订单号',
  `guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `bag_id` varchar(255) DEFAULT NULL COMMENT '该guid隶属的渠道包ID',
  `account_ip` varchar(16) COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT 'IP地址',
  `area` varchar(50) COLLATE utf8_general_ci DEFAULT NULL COMMENT '根据IP获得地区',
  `device` varchar(50) COLLATE utf8_general_ci DEFAULT NULL COMMENT '设备号',
  `platform_id` int(11) NOT NULL DEFAULT '0' COMMENT '充值平台号',
  `seller_id` varchar(16) COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT '商家id',
  `trade_no` varchar(200) COLLATE utf8_general_ci DEFAULT NULL COMMENT '交易订单号',
  `channel_id` int(11) DEFAULT NULL COMMENT '渠道ID',
  `recharge_type` tinyint(2) NOT NULL DEFAULT '2' COMMENT '充值类型',
  `point_card_id` varchar(255) COLLATE utf8_general_ci DEFAULT NULL COMMENT '点卡ID',
  `payment_amt` double(11,2) DEFAULT '0.00' COMMENT '支付金额',
  `actual_amt` double(11,2) DEFAULT '0.00' COMMENT '实付进金额',
  `currency` varchar(10) COLLATE utf8_general_ci NOT NULL DEFAULT 'RMB' COMMENT '支持货币',
  `exchange_gold` int(50) NOT NULL DEFAULT '0' COMMENT '实际游戏币',
  `channel` varchar(20) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付渠道编码:alipay aliwap tenpay weixi applepay',
  `callback` varchar(500) COLLATE utf8_general_ci NOT NULL COMMENT '回调服务端口地址',
  `order_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '订单状态：1 生成订单 2 支付订单 3 订单失败 4 订单补发',
  `pay_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '支付返回状态: 0默认 1充值成功 2充值失败 ',
  `pay_succ_time` timestamp NULL DEFAULT NULL COMMENT '支付成功的时间',
  `pay_returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支付回调数据',
  `server_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '服务端返回状态:0默认 1充值成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家 6服务器接收成功处理中',
  `server_returns` varchar(5000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '服务端回调数据',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '充值前银行金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '充值后银行金钱',
  `sign` varchar(100) COLLATE utf8_general_ci DEFAULT NULL COMMENT '签名',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值订单'
/*!50100 PARTITION BY RANGE (UNIX_TIMESTAMP(created_at))
(PARTITION t_recharge_order_p201701l VALUES LESS THAN (1485878400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201702 VALUES LESS THAN (1488297600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201703 VALUES LESS THAN (1490976000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201704 VALUES LESS THAN (1493568000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201705 VALUES LESS THAN (1496246400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201706 VALUES LESS THAN (1498838400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201707 VALUES LESS THAN (1501516800) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201708 VALUES LESS THAN (1504195200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201709 VALUES LESS THAN (1506787200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201710 VALUES LESS THAN (1509465600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201711 VALUES LESS THAN (1512057600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201712 VALUES LESS THAN (1514736000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201801 VALUES LESS THAN (1517414400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201802 VALUES LESS THAN (1519833600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201803 VALUES LESS THAN (1522512000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201804 VALUES LESS THAN (1525104000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201805 VALUES LESS THAN (1527782400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201806 VALUES LESS THAN (1530374400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201807 VALUES LESS THAN (1533052800) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201808 VALUES LESS THAN (1535731200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201809 VALUES LESS THAN (1538323200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201810 VALUES LESS THAN (1541001600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201811 VALUES LESS THAN (1543593600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201812 VALUES LESS THAN (1546272000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201901 VALUES LESS THAN (1548950400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201902 VALUES LESS THAN (1551369600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201903 VALUES LESS THAN (1554048000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201904 VALUES LESS THAN (1556640000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201905 VALUES LESS THAN (1559318400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201906 VALUES LESS THAN (1561910400) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201907 VALUES LESS THAN (1564588800) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201908 VALUES LESS THAN (1567267200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201909 VALUES LESS THAN (1569859200) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201910 VALUES LESS THAN (1572537600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201911 VALUES LESS THAN (1575129600) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201912 VALUES LESS THAN (1577808000) ENGINE = InnoDB,
 PARTITION t_recharge_order_p201912g VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

-- ----------------------------
-- Records of t_recharge_order
-- ----------------------------

-- ----------------------------
-- Table structure for t_recharge_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_platform`;
CREATE TABLE `t_recharge_platform` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '充值平台唯一ID',
  `name` varchar(100) COLLATE utf8_general_ci DEFAULT NULL COMMENT '接入充值平台名称',
  `developer` varchar(64) COLLATE utf8_general_ci DEFAULT NULL COMMENT '开发者',
  `client_type` varchar(20) COLLATE utf8_general_ci DEFAULT 'all' COMMENT '客户端类型：all 全部, iOS 苹果, android 安卓等 ',
  `is_online` tinyint(4) DEFAULT '0' COMMENT '是否上线：0下线 1上线',
  `desc` varchar(1000) COLLATE utf8_general_ci DEFAULT NULL COMMENT '描述',
  `object_name` varchar(50) COLLATE utf8_general_ci DEFAULT NULL COMMENT '对象名',
  `pay_select` varchar(255) COLLATE utf8_general_ci DEFAULT NULL COMMENT '支持的支付方式',
  `created_at` timestamp NULL DEFAULT NULL COMMENT '开发时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE utf8_general_ci COMMENT='充值平台表';


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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='补充表';

-- ----------------------------
-- Records of t_recharge_platform
-- ----------------------------
INSERT INTO `t_recharge_platform` VALUES ('1', '苹果支付平台', '', 'iOS', '1', '', 'Apple', 'ios', '2017-02-06 21:13:32', '2017-02-06 21:13:37');
INSERT INTO `t_recharge_platform` VALUES ('2', '自支付平台', '', 'all', '1', '', 'SsPay', 'alipay', '2017-02-06 21:18:04', '2017-02-06 21:18:07');

CREATE TABLE t_recharge_channel (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '(权重分配:如果该支付渠道,已经‘上线使用’,并且未超单天额度,并且金额区间囊括此次充值金额，就可以进入权重分配)',
  name varchar(255) NOT NULL COMMENT '分配的渠道名字',
  p_id int(11) NOT NULL COMMENT '平台iD(与t_recharge_platform的id对应)',
  pay_select varchar(255) NOT NULL COMMENT '支持的支付方式',
  percentage smallint(6) NOT NULL DEFAULT '0' COMMENT '百分比(越大权重越高)',
  min_money double(11,0) DEFAULT NULL COMMENT '单次最小金额(单位元)',
  max_money double(11,0) DEFAULT NULL COMMENT '单次最多金额(单位元)',
  day_limit double(11,0) DEFAULT NULL COMMENT '该支付方式每天的限额(单位元)',
  day_sum double(11,0) DEFAULT NULL COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  test_statu tinyint(1) DEFAULT '0' COMMENT '0:尚未测试, 1:正在测试, 2:完成测试',
  is_online tinyint(1) DEFAULT '0' COMMENT '上线开关，1:开，0关',
  object_name varchar(255) DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unq_name (name),
  UNIQUE KEY unq_way (p_id,pay_select)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='渠道商与充值平台中间表';


CREATE TABLE t_recharge_test_guids (
  guid int(11) NOT NULL COMMENT '(该表是充值测试白名单)',
  account varchar(64) DEFAULT NULL COMMENT '玩家账号',
  r_channel_id int(11) NOT NULL COMMENT '充值渠道ID，表t_recharge_channel中的id',
  PRIMARY KEY (guid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值白名单表';

