SET FOREIGN_KEY_CHECKS=0;

USE `config`;

-- ----------------------------
-- Procedure structure for `update_gate_config`
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_gate_config`;
DELIMITER ;;
CREATE PROCEDURE `update_gate_config`(IN `gate_id_` int, IN `game_id_` int)
    COMMENT '更新gate配置'
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

SET FOREIGN_KEY_CHECKS=1;