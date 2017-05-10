SET FOREIGN_KEY_CHECKS=0;

USE `account`;
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

SET FOREIGN_KEY_CHECKS=1;