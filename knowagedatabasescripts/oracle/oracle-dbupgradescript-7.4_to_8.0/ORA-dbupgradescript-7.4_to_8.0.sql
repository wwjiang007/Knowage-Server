-- 06/04/2021
UPDATE SBI_CONFIG SC SET VALUE_CHECK = 'it-IT,en-US,fr-FR,es-ES,pt-BR,en-GB,zh-Hans-CN,de-DE' WHERE LABEL = 'SPAGOBI.LANGUAGE_SUPPORTED.LANGUAGES';
UPDATE SBI_CONFIG SC SET VALUE_CHECK = 'en-US' WHERE LABEL = 'SPAGOBI.LANGUAGE_SUPPORTED.LANGUAGE.default';

UPDATE SBI_DOMAINS SET VALUE_CD = 'it-IT', DOMAIN_NM='Language tag code', VALUE_NM = 'Italian (IT)', VALUE_DS=VALUE_NM WHERE DOMAIN_CD = 'LANG' AND VALUE_NM = 'Italian' AND DOMAIN_NM = 'Language ISO code';
UPDATE SBI_DOMAINS SET VALUE_CD = 'en-US', DOMAIN_NM='Language tag code', VALUE_NM = 'English (US)', VALUE_DS=VALUE_NM WHERE DOMAIN_CD = 'LANG' AND VALUE_NM = 'English' AND DOMAIN_NM = 'Language ISO code';
UPDATE SBI_DOMAINS SET VALUE_CD = 'es-ES', DOMAIN_NM='Language tag code', VALUE_NM = 'Spanish (ES)', VALUE_DS=VALUE_NM WHERE DOMAIN_CD = 'LANG' AND VALUE_NM = 'Spanish' AND DOMAIN_NM = 'Language ISO code';
UPDATE SBI_DOMAINS SET VALUE_CD = 'fr-FR', DOMAIN_NM='Language tag code', VALUE_NM = 'French (FR)', VALUE_DS=VALUE_NM WHERE DOMAIN_CD = 'LANG' AND VALUE_NM = 'French' AND DOMAIN_NM = 'Language ISO code';
UPDATE SBI_DOMAINS SET VALUE_CD = 'pt-BR', DOMAIN_NM='Language tag code', VALUE_NM = 'Portoguese (BR)', VALUE_DS=VALUE_NM WHERE DOMAIN_CD = 'LANG' AND VALUE_NM = 'Portoguese' AND DOMAIN_NM = 'Language ISO code';

ALTER TABLE SBI_MENU ADD (CUST_ICON_CLOB CLOB);
UPDATE SBI_MENU SET CUST_ICON_CLOB = CUST_ICON;
ALTER TABLE SBI_MENU DROP COLUMN CUST_ICON;
ALTER TABLE SBI_MENU RENAME COLUMN CUST_ICON_CLOB TO CUST_ICON;

CREATE TABLE SBI_WIDGET_GALLERY (
  UUID CHAR(36) NOT NULL, -- primary key
  NAME VARCHAR(200) NOT NULL,
  DESCRIPTION VARCHAR(500) NULL,
  TYPE VARCHAR(45) NULL, -- HTML/CUSTOM CHART/PYTHON/R
  PREVIEW_IMAGE BLOB NULL, -- binary of preview file
  TEMPLATE BLOB NULL, -- text with template as a JSON
  AUTHOR VARCHAR(100) NULL,
  USAGE_COUNTER INT NULL, -- counter to see how many times the widgets was used
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
		OUTPUT_TYPE         VARCHAR2(100),
 CONSTRAINT  XAK1SBI_WIDGET_GALLERY UNIQUE (NAME, ORGANIZATION),
  PRIMARY KEY (UUID, ORGANIZATION)
);

CREATE TABLE SBI_WIDGET_GALLERY_TAGS (
  WIDGET_ID CHAR(36) NOT NULL, -- widget id reference
  TAG VARCHAR(50) NOT NULL, -- tag name
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
  PRIMARY KEY  (WIDGET_ID, TAG, ORGANIZATION),
  CONSTRAINT FK_SBI_WIDGET_GALLERY_TAGS_1 FOREIGN KEY (WIDGET_ID, ORGANIZATION) REFERENCES SBI_WIDGET_GALLERY (UUID, ORGANIZATION) ON DELETE CASCADE
);

-- 21/06/2021
-- CATALOG FUNCTION REFACTORING - SUPPORT FOR UUIDS

-- DROP OLD FOREIGN KEYS
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE DROP CONSTRAINT FK_FUNCTION_INPUT_VARIABLES_1;
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN DROP CONSTRAINT FK_FUNCTION_INPUT_COLUMNS_1;
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN DROP CONSTRAINT FK_FUNCTION_OUTPUT_COLUMNS_1;
ALTER TABLE SBI_OBJ_FUNCTION DROP CONSTRAINT FK_SBI_OBJ_FUNCTION_1;

-- DROP OLD PRIMARY KEYS
ALTER TABLE SBI_CATALOG_FUNCTION DROP PRIMARY KEY;
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN DROP PRIMARY KEY;
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE DROP PRIMARY KEY;
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN DROP PRIMARY KEY;
ALTER TABLE SBI_OBJ_FUNCTION DROP CONSTRAINT XAK1SBI_OBJ_FUNCTION;

-- ADD NEW UUID COLUMN
ALTER TABLE SBI_CATALOG_FUNCTION ADD FUNCTION_UUID VARCHAR(36) ;
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN ADD FUNCTION_UUID VARCHAR(36) ;
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE ADD FUNCTION_UUID VARCHAR(36) ;
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN ADD FUNCTION_UUID VARCHAR(36) ;
ALTER TABLE SBI_OBJ_FUNCTION ADD FUNCTION_UUID VARCHAR(36) ;

-- CONVERT ID TO UUID
CREATE OR REPLACE PROCEDURE GENERATE_KNOWAGE_UUIDS IS
		function_id  SBI_CATALOG_FUNCTION.FUNCTION_ID%TYPE ;
		organization SBI_CATALOG_FUNCTION.ORGANIZATION%TYPE ;
		uuid         VARCHAR2(36);
		CURSOR cur IS SELECT FUNCTION_ID, ORGANIZATION FROM SBI_CATALOG_FUNCTION;
	BEGIN
		
		FOR  curr_row IN cur
		LOOP

			SELECT LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '([A-F0-9]{8})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{12})', '\1-\2-\3-\4-\5')) AS UUID INTO uuid FROM DUAL;

			UPDATE SBI_CATALOG_FUNCTION        SET FUNCTION_UUID = uuid WHERE FUNCTION_ID = curr_row.function_id AND ORGANIZATION = curr_row.organization ;
			UPDATE SBI_FUNCTION_INPUT_VARIABLE SET FUNCTION_UUID = uuid WHERE FUNCTION_ID = curr_row.function_id AND ORGANIZATION = curr_row.organization ;
			UPDATE SBI_FUNCTION_INPUT_COLUMN   SET FUNCTION_UUID = uuid WHERE FUNCTION_ID = curr_row.function_id AND ORGANIZATION = curr_row.organization ;
			UPDATE SBI_FUNCTION_OUTPUT_COLUMN  SET FUNCTION_UUID = uuid WHERE FUNCTION_ID = curr_row.function_id AND ORGANIZATION = curr_row.organization ;
			UPDATE SBI_OBJ_FUNCTION            SET FUNCTION_UUID = uuid WHERE FUNCTION_ID = curr_row.function_id AND ORGANIZATION = curr_row.organization ;
		END LOOP;

	END 
;

CALL GENERATE_KNOWAGE_UUIDS();

DROP PROCEDURE GENERATE_KNOWAGE_UUIDS;

-- CREATE NEW PRIMARY KEYS
ALTER TABLE SBI_CATALOG_FUNCTION        ADD CONSTRAINT PK_SBI_CATALOG_FUNCTION        PRIMARY KEY(FUNCTION_UUID, ORGANIZATION);
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN   ADD CONSTRAINT PK_SBI_FUNCTION_INPUT_COLUMN   PRIMARY KEY(FUNCTION_UUID, ORGANIZATION, COL_NAME);
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE ADD CONSTRAINT PK_SBI_FUNCTION_INPUT_VARIABLE PRIMARY KEY(FUNCTION_UUID, ORGANIZATION, VAR_NAME);
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN  ADD CONSTRAINT PK_SBI_FUNCTION_OUTPUT_COLUMN  PRIMARY KEY(FUNCTION_UUID, ORGANIZATION, COL_NAME);

ALTER TABLE SBI_OBJ_FUNCTION            ADD CONSTRAINT XAK1SBI_OBJ_FUNCTION           UNIQUE(BIOBJ_ID, FUNCTION_UUID, ORGANIZATION);
ALTER TABLE SBI_CATALOG_FUNCTION        ADD CONSTRAINT UNIQUE_FUNC_ID_ORG             UNIQUE (FUNCTION_UUID,ORGANIZATION),

-- CREATE NEW FOREIGN KEYS
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE     ADD CONSTRAINT FK_FUNCTION_INPUT_VARIABLES_1   FOREIGN KEY (FUNCTION_UUID, ORGANIZATION) REFERENCES SBI_CATALOG_FUNCTION(FUNCTION_UUID, ORGANIZATION) ;
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN       ADD CONSTRAINT FK_FUNCTION_INPUT_COLUMNS_1     FOREIGN KEY (FUNCTION_UUID, ORGANIZATION) REFERENCES SBI_CATALOG_FUNCTION(FUNCTION_UUID, ORGANIZATION) ;
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN      ADD CONSTRAINT FK_FUNCTION_OUTPUT_COLUMNS_1    FOREIGN KEY (FUNCTION_UUID, ORGANIZATION) REFERENCES SBI_CATALOG_FUNCTION(FUNCTION_UUID, ORGANIZATION) ;
ALTER TABLE SBI_OBJ_FUNCTION                ADD CONSTRAINT FK_SBI_OBJ_FUNCTION_1           FOREIGN KEY (BIOBJ_ID)                    REFERENCES SBI_OBJECTS         (BIOBJ_ID);
ALTER TABLE SBI_OBJ_FUNCTION                ADD CONSTRAINT FK_SBI_OBJ_FUNCTION_2           FOREIGN KEY (FUNCTION_UUID,ORGANIZATION)  REFERENCES SBI_CATALOG_FUNCTION(FUNCTION_UUID,ORGANIZATION);

-- DROP OLD ID COLUMNS
ALTER TABLE SBI_CATALOG_FUNCTION        DROP COLUMN FUNCTION_ID;
ALTER TABLE SBI_FUNCTION_INPUT_COLUMN   DROP COLUMN FUNCTION_ID;
ALTER TABLE SBI_FUNCTION_INPUT_VARIABLE DROP COLUMN FUNCTION_ID;
ALTER TABLE SBI_FUNCTION_OUTPUT_COLUMN  DROP COLUMN FUNCTION_ID;
ALTER TABLE SBI_OBJ_FUNCTION            DROP COLUMN FUNCTION_ID;

-- 2021/08/27
-- UPDATED SBI_EXT_USER_ROLES ORGANIZATION FIELD WHERE NULL
UPDATE SBI_EXT_USER_ROLES SET ORGANIZATION = (SELECT ORGANIZATION FROM SBI_USER WHERE ID = SBI_EXT_USER_ROLES.ID), TIME_UP = CURRENT_TIMESTAMP 
WHERE SBI_EXT_USER_ROLES.ORGANIZATION IS NULL;