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

-- 2022/07/07 moving categories from SBI_DOMAINS into SBI_CATEGORY
CREATE TABLE SBI_CATEGORY (
	   ID 					INTEGER,
	   CODE                 VARCHAR(100),
       NAME   				VARCHAR(100),
	   CATEGORY_TYPE		VARCHAR(100),
       USER_IN              VARCHAR(100) NOT NULL,
       USER_UP              VARCHAR(100),
       USER_DE              VARCHAR(100),
       TIME_IN              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       TIME_UP              TIMESTAMP NULL DEFAULT NULL,
       TIME_DE              TIMESTAMP NULL DEFAULT NULL,
       SBI_VERSION_IN       VARCHAR(10),
       SBI_VERSION_UP       VARCHAR(10),
       SBI_VERSION_DE       VARCHAR(10),
       META_VERSION         VARCHAR(100),
	   ORGANIZATION         VARCHAR(20),
	   UNIQUE U_SBI_CATEGORY_CODE (CODE, CATEGORY_TYPE, ORGANIZATION),
	   UNIQUE U_SBI_CATEGORY_NAME (NAME, CATEGORY_TYPE, ORGANIZATION),
       PRIMARY KEY (ID)
)ENGINE=InnoDB;

INSERT INTO SBI_CATEGORY (ID, CODE, NAME, CATEGORY_TYPE, USER_IN, USER_UP, TIME_IN, TIME_UP, SBI_VERSION_IN, SBI_VERSION_UP, ORGANIZATION)
SELECT 
    (@ROW := @ROW + 1) AS ID,
    d.VALUE_CD AS CODE,
    d.VALUE_NM AS NAME,
	d.DOMAIN_CD AS CATEGORY_TYPE,
	d.USER_IN AS USER_IN,
	d.USER_UP AS USER_UP,
	d.TIME_IN AS TIME_IN,
	d.TIME_UP AS TIME_UP,
	d.SBI_VERSION_IN AS SBI_VERSION_IN,
	d.SBI_VERSION_UP AS SBI_VERSION_UP,
    o.NAME AS ORGANIZATION
FROM
    SBI_DOMAINS d 
	cross join SBI_ORGANIZATIONS o
	cross join (SELECT @ROW := 0) r
WHERE
    domain_cd IN (
		'CATEGORY_TYPE', 
		'BM_CATEGORY',
        'GEO_CATEGORY',
        'KPI_KPI_CATEGORY',
        'KPI_TARGET_CATEGORY',
        'KPI_MEASURE_CATEGORY');

COMMIT;

ALTER TABLE SBI_DATA_SET DROP FOREIGN KEY FK_DATA_SET_CATEGORY;

UPDATE 
	SBI_DATA_SET ds
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = ds.CATEGORY_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = ds.ORGANIZATION
SET 
	ds.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_DATA_SET ADD CONSTRAINT FK_DATA_SET_CATEGORY FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY(ID);

ALTER TABLE SBI_META_MODELS DROP FOREIGN KEY FK_META_MODELS_CATEGORY;

UPDATE 
	SBI_META_MODELS mm
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = mm.CATEGORY_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = mm.ORGANIZATION
SET 
	mm.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_META_MODELS ADD CONSTRAINT FK_META_MODELS_CATEGORY FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY (ID);

-- FK for GEO layers was missing

UPDATE 
	SBI_GEO_LAYERS gl
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = gl.GEO_CATEGORY
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = gl.ORGANIZATION
SET 
	gl.GEO_CATEGORY = c.ID;
COMMIT;

ALTER TABLE SBI_GEO_LAYERS ADD CONSTRAINT FK_SBI_GEO_LAYERS_CATEGORY FOREIGN KEY (GEO_CATEGORY) REFERENCES SBI_CATEGORY(ID);

ALTER TABLE SBI_KPI_KPI DROP FOREIGN KEY FK_01_SBI_KPI_KPI;

UPDATE 
	SBI_KPI_KPI kk
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = kk.CATEGORY_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = kk.ORGANIZATION
SET 
	kk.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_KPI_KPI ADD CONSTRAINT FK_01_SBI_KPI_KPI FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY(ID);

ALTER TABLE SBI_KPI_TARGET DROP FOREIGN KEY FK_03_SBI_KPI_TARGET;

UPDATE 
	SBI_KPI_TARGET kt
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = kt.CATEGORY_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = kt.ORGANIZATION
SET 
	kt.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_KPI_TARGET ADD CONSTRAINT FK_03_SBI_KPI_TARGET FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY (ID);

ALTER TABLE SBI_KPI_RULE_OUTPUT DROP FOREIGN KEY FK_04_SBI_KPI_RULE_OUTPUT;

UPDATE 
	SBI_KPI_RULE_OUTPUT kro
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = kro.CATEGORY_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = kro.ORGANIZATION
SET 
	kro.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_KPI_RULE_OUTPUT ADD CONSTRAINT FK_04_SBI_KPI_RULE_OUTPUT FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY (ID);

ALTER TABLE SBI_EXT_ROLES_CATEGORY DROP FOREIGN KEY FK_SB_EXT_ROLES_META_MODEL_CATEGORY_1;

ALTER TABLE SBI_EXT_ROLES_CATEGORY DROP FOREIGN KEY FK_SB_EXT_ROLES_META_MODEL_CATEGORY_2;

ALTER TABLE SBI_EXT_ROLES_CATEGORY DROP PRIMARY KEY;

UPDATE 
	SBI_EXT_ROLES_CATEGORY erc
INNER JOIN 
	SBI_DOMAINS d on d.VALUE_ID = erc.CATEGORY_ID
INNER JOIN
	SBI_EXT_ROLES er on er.EXT_ROLE_ID = erc.EXT_ROLE_ID
INNER JOIN 
	SBI_CATEGORY c ON c.CODE = d.VALUE_CD and c.CATEGORY_TYPE = d.DOMAIN_CD and c.ORGANIZATION = er.ORGANIZATION
SET 
	erc.CATEGORY_ID = c.ID;
COMMIT;

ALTER TABLE SBI_EXT_ROLES_CATEGORY ADD PRIMARY KEY(EXT_ROLE_ID,CATEGORY_ID);

ALTER TABLE SBI_EXT_ROLES_CATEGORY ADD CONSTRAINT FK_SB_EXT_ROLES_META_MODEL_CATEGORY_1 FOREIGN KEY (EXT_ROLE_ID) REFERENCES SBI_EXT_ROLES (EXT_ROLE_ID);

ALTER TABLE SBI_EXT_ROLES_CATEGORY ADD CONSTRAINT FK_SB_EXT_ROLES_META_MODEL_CATEGORY_2 FOREIGN KEY (CATEGORY_ID) REFERENCES SBI_CATEGORY(ID);


insert into hibernate_sequences(next_val,sequence_name) values ((select max(ID)+1 from SBI_CATEGORY) ,'SBI_CATEGORY');
COMMIT;

DELETE 
FROM 
	SBI_DOMAINS 
WHERE
    domain_cd IN (
		'CATEGORY_TYPE', 
		'BM_CATEGORY',
        'GEO_CATEGORY',
        'KPI_KPI_CATEGORY',
        'KPI_TARGET_CATEGORY',
        'KPI_MEASURE_CATEGORY');

COMMIT;

UPDATE SBI_CATEGORY SET CATEGORY_TYPE = 'DATASET_CATEGORY' WHERE CATEGORY_TYPE = 'CATEGORY_TYPE';
COMMIT;

-- 17/10/2022 Dossier
ALTER TABLE SBI_DOSSIER_ACTIVITY ADD PPT_V2 longblob NULL; 