-- 2021/07/26
ALTER TABLE SBI_ALERT_ACTION DROP COLUMN TEMPLATE CASCADE;
ALTER TABLE SBI_ALERT_LISTENER DROP COLUMN TEMPLATE CASCADE;

-- 2022/02/08
CREATE TABLE SBI_ORGANIZATION_THEME (
	UUID VARCHAR(36) NOT NULL,
	ORGANIZATION_ID INTEGER NOT NULL,
	THEME_NAME VARCHAR(255) NOT NULL,
	CONFIG TEXT NULL,
	ACTIVE SMALLINT DEFAULT '1',
	USER_IN VARCHAR(100) NOT NULL,
	USER_UP VARCHAR(100),
	USER_DE VARCHAR(100),
	TIME_IN TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	TIME_UP TIMESTAMP NULL DEFAULT NULL,
	TIME_DE TIMESTAMP NULL DEFAULT NULL,
	SBI_VERSION_IN VARCHAR(10),
	SBI_VERSION_UP VARCHAR(10),
	SBI_VERSION_DE VARCHAR(10),
	META_VERSION VARCHAR(100),
	ORGANIZATION VARCHAR(20),
	PRIMARY KEY (UUID, ORGANIZATION),
	CONSTRAINT FK_ORGANIZATION_1 FOREIGN KEY (ORGANIZATION_ID) REFERENCES SBI_ORGANIZATIONS(ID)
);

ALTER TABLE SBI_WIDGET_GALLERY ADD LABEL VARCHAR(200);
UPDATE SBI_WIDGET_GALLERY SET LABEL = NAME;
ALTER TABLE SBI_WIDGET_GALLERY MODIFY COLUMN LABEL varchar(200) NOT NULL;

-- 2022/03/10 : Data preparation
ALTER TABLE SBI_DATA_SOURCE ADD USE_FOR_DATAPREP BOOLEAN DEFAULT FALSE;

-- 2022/04/20 : Fix length of TRIGGER_GROUP, TRIGGER_NAME, JOB_GROUP and JOB_NAME: we saw a lot of different sizes 
SET foreign_key_checks = 0

ALTER TABLE QRTZ_BLOB_TRIGGERS       MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_BLOB_TRIGGERS       MODIFY TRIGGER_NAME VARCHAR(120);
ALTER TABLE QRTZ_CRON_TRIGGERS       MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_CRON_TRIGGERS       MODIFY TRIGGER_NAME VARCHAR(120);
ALTER TABLE QRTZ_FIRED_TRIGGERS      MODIFY JOB_GROUP VARCHAR(120);
ALTER TABLE QRTZ_FIRED_TRIGGERS      MODIFY JOB_NAME VARCHAR(120);
ALTER TABLE QRTZ_FIRED_TRIGGERS      MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_FIRED_TRIGGERS      MODIFY TRIGGER_NAME VARCHAR(120);
ALTER TABLE QRTZ_JOB_DETAILS         MODIFY JOB_GROUP VARCHAR(120);
ALTER TABLE QRTZ_JOB_DETAILS         MODIFY JOB_NAME VARCHAR(120);
ALTER TABLE QRTZ_PAUSED_TRIGGER_GRPS MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     MODIFY TRIGGER_NAME VARCHAR(120);
ALTER TABLE QRTZ_TRIGGERS            MODIFY JOB_GROUP VARCHAR(120);
ALTER TABLE QRTZ_TRIGGERS            MODIFY JOB_NAME VARCHAR(120);
ALTER TABLE QRTZ_TRIGGERS            MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE QRTZ_TRIGGERS            MODIFY TRIGGER_NAME VARCHAR(120);
ALTER TABLE SBI_TRIGGER_PAUSED       MODIFY JOB_GROUP VARCHAR(120);
ALTER TABLE SBI_TRIGGER_PAUSED       MODIFY JOB_NAME VARCHAR(120);
ALTER TABLE SBI_TRIGGER_PAUSED       MODIFY TRIGGER_GROUP VARCHAR(120);
ALTER TABLE SBI_TRIGGER_PAUSED       MODIFY TRIGGER_NAME VARCHAR(120);

SET foreign_key_checks = 1

-- 2022/03/10 : Update to Quartz 2.3
DROP PROCEDURE IF EXISTS DROP_FK_WITH_UNKNOW_NAME;

DELIMITER //

CREATE PROCEDURE DROP_FK_WITH_UNKNOW_NAME(IN MY_TABLE_NAME VARCHAR(100) )
BEGIN
	DECLARE DONE BOOLEAN DEFAULT FALSE;
	DECLARE _CONSTRAINT_NAME VARCHAR(100) ;
	DECLARE CUR CURSOR FOR SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME LIKE MY_TABLE_NAME ;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE := TRUE;

	OPEN CUR ;

	DELETE_LOOP: LOOP

		FETCH CUR INTO _CONSTRAINT_NAME ;
	
		IF DONE THEN
			LEAVE DELETE_LOOP;
		END IF;
		
		SET @RUNSTRING = CONCAT('ALTER TABLE ', MY_TABLE_NAME,' DROP FOREIGN KEY ', _CONSTRAINT_NAME) ;

		PREPARE STMT1 FROM @RUNSTRING ;
		EXECUTE STMT1 ;
		DEALLOCATE PREPARE STMT1 ;

	END LOOP DELETE_LOOP ;

	CLOSE CUR ;

END //

DELIMITER ;

DROP TABLE QRTZ_JOB_LISTENERS;
DROP TABLE QRTZ_TRIGGER_LISTENERS;

ALTER TABLE QRTZ_JOB_DETAILS    DROP COLUMN IS_VOLATILE;
ALTER TABLE QRTZ_TRIGGERS       DROP COLUMN IS_VOLATILE;
ALTER TABLE QRTZ_FIRED_TRIGGERS DROP COLUMN IS_VOLATILE;

ALTER TABLE QRTZ_JOB_DETAILS ADD COLUMN IS_NONCONCURRENT BOOL;
ALTER TABLE QRTZ_JOB_DETAILS ADD COLUMN IS_UPDATE_DATA BOOL;
UPDATE QRTZ_JOB_DETAILS SET IS_NONCONCURRENT = IS_STATEFUL;
UPDATE QRTZ_JOB_DETAILS SET IS_UPDATE_DATA = IS_STATEFUL;
ALTER TABLE QRTZ_JOB_DETAILS DROP COLUMN IS_STATEFUL;
ALTER TABLE QRTZ_FIRED_TRIGGERS ADD COLUMN IS_NONCONCURRENT BOOL;
UPDATE QRTZ_FIRED_TRIGGERS SET IS_NONCONCURRENT = IS_STATEFUL;
ALTER TABLE QRTZ_FIRED_TRIGGERS DROP COLUMN IS_STATEFUL;

ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_CALENDARS           ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_FIRED_TRIGGERS      ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_JOB_DETAILS         ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_LOCKS               ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_PAUSED_TRIGGER_GRPS ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_SCHEDULER_STATE     ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';
ALTER TABLE QRTZ_TRIGGERS            ADD COLUMN SCHED_NAME VARCHAR(120) NOT NULL DEFAULT 'DefaultQuartzScheduler';

ALTER TABLE QRTZ_FIRED_TRIGGERS ADD COLUMN SCHED_TIME BIGINT(13) NOT NULL;

CALL DROP_FK_WITH_UNKNOW_NAME('QRTZ_TRIGGERS');

ALTER TABLE QRTZ_BLOB_TRIGGERS DROP PRIMARY KEY;
CALL DROP_FK_WITH_UNKNOW_NAME('QRTZ_BLOB_TRIGGERS');

ALTER TABLE QRTZ_SIMPLE_TRIGGERS DROP PRIMARY KEY;
CALL DROP_FK_WITH_UNKNOW_NAME('QRTZ_SIMPLE_TRIGGERS');

ALTER TABLE QRTZ_CRON_TRIGGERS DROP PRIMARY KEY;
CALL DROP_FK_WITH_UNKNOW_NAME('QRTZ_CRON_TRIGGERS');

ALTER TABLE QRTZ_JOB_DETAILS DROP PRIMARY KEY;

ALTER TABLE QRTZ_JOB_DETAILS ADD PRIMARY KEY (SCHED_NAME, JOB_NAME, JOB_GROUP);

ALTER TABLE QRTZ_TRIGGERS DROP PRIMARY KEY;

ALTER TABLE QRTZ_TRIGGERS            ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_TRIGGERS            ADD FOREIGN KEY QRTZ_TRIGGERS_FKEY        (SCHED_NAME, JOB_NAME, JOB_GROUP)          REFERENCES QRTZ_JOB_DETAILS(SCHED_NAME, JOB_NAME, JOB_GROUP);
ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD FOREIGN KEY QRTZ_BLOB_TRIGGERS_FKEY   (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD FOREIGN KEY QRTZ_CRON_TRIGGERS_FKEY   (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD FOREIGN KEY QRTZ_SIMPLE_TRIGGERS_FKEY (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);

ALTER TABLE QRTZ_FIRED_TRIGGERS      DROP PRIMARY KEY;
ALTER TABLE QRTZ_FIRED_TRIGGERS      ADD PRIMARY KEY   (SCHED_NAME, ENTRY_ID);
ALTER TABLE QRTZ_CALENDARS           DROP PRIMARY KEY;
ALTER TABLE QRTZ_CALENDARS           ADD PRIMARY KEY   (SCHED_NAME, CALENDAR_NAME);
ALTER TABLE QRTZ_LOCKS               DROP PRIMARY KEY;
ALTER TABLE QRTZ_LOCKS               ADD PRIMARY KEY   (SCHED_NAME, LOCK_NAME);
ALTER TABLE QRTZ_PAUSED_TRIGGER_GRPS DROP PRIMARY KEY;
ALTER TABLE QRTZ_PAUSED_TRIGGER_GRPS ADD PRIMARY KEY   (SCHED_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_SCHEDULER_STATE     DROP PRIMARY KEY;
ALTER TABLE QRTZ_SCHEDULER_STATE     ADD PRIMARY KEY   (SCHED_NAME, INSTANCE_NAME);

CREATE TABLE QRTZ_SIMPROP_TRIGGERS (
	SCHED_NAME VARCHAR(120) NOT NULL,
	TRIGGER_NAME VARCHAR(120) NOT NULL,
	TRIGGER_GROUP VARCHAR(120) NOT NULL,
	STR_PROP_1 VARCHAR(512) NULL,
	STR_PROP_2 VARCHAR(512) NULL,
	STR_PROP_3 VARCHAR(512) NULL,
	INT_PROP_1 INT NULL,
	INT_PROP_2 INT NULL,
	LONG_PROP_1 BIGINT NULL,
	LONG_PROP_2 BIGINT NULL,
	DEC_PROP_1 NUMERIC(13,4) NULL,
	DEC_PROP_2 NUMERIC(13,4) NULL,
	BOOL_PROP_1 BOOL NULL,
	BOOL_PROP_2 BOOL NULL,
	PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
	FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
	REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE INDEX IDX_QRTZ_J_REQ_RECOVERY        ON QRTZ_JOB_DETAILS(SCHED_NAME,REQUESTS_RECOVERY);
CREATE INDEX IDX_QRTZ_J_GRP                 ON QRTZ_JOB_DETAILS(SCHED_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_T_J                   ON QRTZ_TRIGGERS(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_T_JG                  ON QRTZ_TRIGGERS(SCHED_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_T_C                   ON QRTZ_TRIGGERS(SCHED_NAME,CALENDAR_NAME);
CREATE INDEX IDX_QRTZ_T_G                   ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_GROUP);
CREATE INDEX IDX_QRTZ_T_STATE               ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_N_STATE             ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_N_G_STATE           ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_NEXT_FIRE_TIME      ON QRTZ_TRIGGERS(SCHED_NAME,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_ST              ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_MISFIRE         ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_ST_MISFIRE      ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_NFT_ST_MISFIRE_GRP  ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_FT_TRIG_INST_NAME     ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,INSTANCE_NAME);
CREATE INDEX IDX_QRTZ_FT_INST_JOB_REQ_RCVRY ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY);
CREATE INDEX IDX_QRTZ_FT_J_G                ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_FT_JG                 ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_FT_T_G                ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP);
CREATE INDEX IDX_QRTZ_FT_TG                 ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,TRIGGER_GROUP);

DROP PROCEDURE IF EXISTS DROP_FK_WITH_UNKNOW_NAME;

-- 2022/06/17 : Add events table
CREATE TABLE SBI_ES (
  `ORGANIZATION` VARCHAR(20)  NOT NULL,
  `TIMESTAMP`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PROG`         BIGINT(20)   NOT NULL,
  `TYPE`         VARCHAR(100) NOT NULL,
  `ID`           CHAR(100)    NOT NULL,
  `EVENT_ID`     CHAR(36)     NOT NULL,
  `EVENT`        VARCHAR(100) NOT NULL,
  `DATA`         TEXT         NOT NULL,
  PRIMARY KEY (`PROG`),
  UNIQUE KEY `XAK1SBI_ES` (`EVENT_ID`),
  KEY `IDX_SBI_ES_1` (`ORGANIZATION`,`TIMESTAMP`,`ID`)
);
