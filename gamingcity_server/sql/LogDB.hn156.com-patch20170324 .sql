SET FOREIGN_KEY_CHECKS=0;

USE `log`;

CREATE TABLE `t_log_channel_invite_tax` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '获奖励者的guid' ,
`guid_contribute`  int(11) NOT NULL COMMENT '贡献者的id' ,
`val`  int(11) NOT NULL COMMENT '具体的值' ,
`time`  date NOT NULL COMMENT '时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
ROW_FORMAT=Dynamic
;

ALTER TABLE `t_log_money_tj` MODIFY COLUMN `type`  int(11) NOT NULL COMMENT '1 loss 2 win' AFTER `guid`;

SET FOREIGN_KEY_CHECKS=1;