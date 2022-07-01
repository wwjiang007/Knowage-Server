-- 2021/07/26
ALTER TABLE SBI_ALERT_ACTION DROP COLUMN TEMPLATE CASCADE;
ALTER TABLE SBI_ALERT_LISTENER DROP COLUMN TEMPLATE CASCADE;

-- 2022/02/08
CREATE TABLE SBI_ORGANIZATION_THEME (
	UUID 				 VARCHAR(36) NOT NULL,
	ORGANIZATION_ID 	 INTEGER NOT NULL,
	THEME_NAME 			 VARCHAR(255) NOT NULL,
	CONFIG 				 CLOB NULL,
	ACTIVE 				 SMALLINT DEFAULT 0,
	USER_IN              VARCHAR2(100) NOT NULL,
	USER_UP              VARCHAR2(100),
	USER_DE              VARCHAR2(100),
	TIME_IN              TIMESTAMP NOT NULL,
	TIME_UP              TIMESTAMP DEFAULT NULL,
	TIME_DE              TIMESTAMP DEFAULT NULL,
	SBI_VERSION_IN       VARCHAR2(10),
	SBI_VERSION_UP       VARCHAR2(10),
	SBI_VERSION_DE       VARCHAR2(10),
	ORGANIZATION         VARCHAR2(20),
	PRIMARY KEY (UUID, ORGANIZATION),
	CONSTRAINT FK_ORGANIZATION_1 FOREIGN KEY (ORGANIZATION_ID) REFERENCES SBI_ORGANIZATIONS(ID)
);

ALTER TABLE SBI_WIDGET_GALLERY ADD LABEL VARCHAR2(200);
UPDATE SBI_WIDGET_GALLERY SET LABEL = NAME;
ALTER TABLE SBI_WIDGET_GALLERY MODIFY LABEL NOT NULL;

-- 2022/03/10 : Data preparation
ALTER TABLE SBI_DATA_SOURCE ADD USE_FOR_DATAPREP SMALLINT DEFAULT 0;

-- 2022/04/20 : Fix length of TRIGGER_GROUP, TRIGGER_NAME, JOB_GROUP and JOB_NAME: we saw a lot of different sizes 
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

-- 2022/03/10 : Update to Quartz 2.3
CREATE OR REPLACE PROCEDURE CLEAR_INDEXES(MY_TABLE_NAME VARCHAR) IS
BEGIN
	FOR IND IN 
	(
		SELECT *
		FROM ALL_INDEXES
		WHERE
			OWNER = sys_context( 'userenv', 'current_schema' )
			AND TABLE_NAME = MY_TABLE_NAME
			AND UNIQUENESS = 'NONUNIQUE'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX ' || IND.INDEX_NAME;
	   
	END LOOP;
END;


CALL CLEAR_INDEXES('QRTZ_BLOB_TRIGGERS');
CALL CLEAR_INDEXES('QRTZ_CALENDARS');
CALL CLEAR_INDEXES('QRTZ_CRON_TRIGGERS');
CALL CLEAR_INDEXES('QRTZ_FIRED_TRIGGERS');
CALL CLEAR_INDEXES('QRTZ_JOB_DETAILS');
CALL CLEAR_INDEXES('QRTZ_LOCKS');
CALL CLEAR_INDEXES('QRTZ_PAUSED_TRIGGER_GRPS');
CALL CLEAR_INDEXES('QRTZ_SCHEDULER_STATE');
CALL CLEAR_INDEXES('QRTZ_SIMPLE_TRIGGERS');
CALL CLEAR_INDEXES('QRTZ_SIMPROP_TRIGGERS');
CALL CLEAR_INDEXES('QRTZ_TRIGGERS');

DROP PROCEDURE CLEAR_INDEXES;

CREATE OR REPLACE PROCEDURE DROP_FK_WITH_UNKNOW_NAME(MY_TABLE_NAME VARCHAR ) IS

	CURSOR CUR IS SELECT CONSTRAINT_NAME FROM ALL_CONSTRAINTS WHERE OWNER = sys_context( 'userenv', 'current_schema' ) AND TABLE_NAME = MY_TABLE_NAME AND CONSTRAINT_TYPE IN ('R') ;

	BEGIN

		FOR cur_row IN CUR
		LOOP
			
			EXECUTE IMMEDIATE 'ALTER TABLE ' || MY_TABLE_NAME || ' DROP CONSTRAINT ' || cur_row.CONSTRAINT_NAME ;
		
		END LOOP;
		
	END
;

DROP TABLE QRTZ_JOB_LISTENERS;
DROP TABLE QRTZ_TRIGGER_LISTENERS;

ALTER TABLE QRTZ_JOB_DETAILS    DROP COLUMN IS_VOLATILE;
ALTER TABLE QRTZ_TRIGGERS       DROP COLUMN IS_VOLATILE;
ALTER TABLE QRTZ_FIRED_TRIGGERS DROP COLUMN IS_VOLATILE;

ALTER TABLE QRTZ_JOB_DETAILS ADD IS_NONCONCURRENT VARCHAR2(1) ;
ALTER TABLE QRTZ_JOB_DETAILS ADD IS_UPDATE_DATA VARCHAR2(1) ;
UPDATE QRTZ_JOB_DETAILS SET IS_NONCONCURRENT = IS_STATEFUL;
UPDATE QRTZ_JOB_DETAILS SET IS_UPDATE_DATA = IS_STATEFUL;
ALTER TABLE QRTZ_JOB_DETAILS DROP COLUMN IS_STATEFUL;
ALTER TABLE QRTZ_FIRED_TRIGGERS ADD IS_NONCONCURRENT VARCHAR2(1) ;
UPDATE QRTZ_FIRED_TRIGGERS SET IS_NONCONCURRENT = IS_STATEFUL;
ALTER TABLE QRTZ_FIRED_TRIGGERS DROP COLUMN IS_STATEFUL;

ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_CALENDARS           ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_FIRED_TRIGGERS      ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_JOB_DETAILS         ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_LOCKS               ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_PAUSED_TRIGGER_GRPS ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_SCHEDULER_STATE     ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;
ALTER TABLE QRTZ_TRIGGERS            ADD SCHED_NAME VARCHAR(120) DEFAULT 'DefaultQuartzScheduler' NOT NULL;

ALTER TABLE QRTZ_FIRED_TRIGGERS ADD SCHED_TIME NUMBER(13) NOT NULL;

CALL DROP_FK_WITH_UNKNOW_NAME('QRTZ_TRIGGERS') ;

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
ALTER TABLE QRTZ_TRIGGERS            ADD FOREIGN KEY                           (SCHED_NAME, JOB_NAME, JOB_GROUP)          REFERENCES QRTZ_JOB_DETAILS(SCHED_NAME, JOB_NAME, JOB_GROUP);
ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_BLOB_TRIGGERS       ADD FOREIGN KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_CRON_TRIGGERS       ADD FOREIGN KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD PRIMARY KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);
ALTER TABLE QRTZ_SIMPLE_TRIGGERS     ADD FOREIGN KEY                           (SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP) REFERENCES QRTZ_TRIGGERS(SCHED_NAME, TRIGGER_NAME, TRIGGER_GROUP);

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

CREATE TABLE QRTZ_SIMPROP_TRIGGERS(          
	SCHED_NAME VARCHAR2(120) NOT NULL,
	TRIGGER_NAME VARCHAR2(120) NOT NULL,
	TRIGGER_GROUP VARCHAR2(120) NOT NULL,
	STR_PROP_1 VARCHAR2(512) NULL,
	STR_PROP_2 VARCHAR2(512) NULL,
	STR_PROP_3 VARCHAR2(512) NULL,
	INT_PROP_1 NUMBER(10) NULL,
	INT_PROP_2 NUMBER(10) NULL,
	LONG_PROP_1 NUMBER(13) NULL,
	LONG_PROP_2 NUMBER(13) NULL,
	DEC_PROP_1 NUMERIC(13,4) NULL,
	DEC_PROP_2 NUMERIC(13,4) NULL,
	BOOL_PROP_1 VARCHAR2(1) NULL,
	BOOL_PROP_2 VARCHAR2(1) NULL,
	CONSTRAINT QRTZ_SIMPROP_TRIG_PK PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
	CONSTRAINT QRTZ_SIMPROP_TRIG_TO_TRIG_FK FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP) 
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

DROP PROCEDURE DROP_FK_WITH_UNKNOW_NAME;
