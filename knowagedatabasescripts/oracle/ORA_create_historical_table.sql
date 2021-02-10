DROP TABLE SBI_USER_HISTORY;
CREATE TABLE SBI_USER_HISTORY (
	EVENT_ID			INTEGER NOT NULL,
	USER_ID				VARCHAR2(100) NOT NULL,
	PASSWORD			VARCHAR2(150),
	FULL_NAME			VARCHAR2(255),
	ID					INTEGER NOT NULL,
	DT_PWD_BEGIN		TIMESTAMP(6),
	DT_PWD_END			TIMESTAMP(6),
	FLG_PWD_BLOCKED		SMALLINT,
	DT_LAST_ACCESS		TIMESTAMP(6),
	IS_SUPERADMIN		SMALLINT DEFAULT 0,
	USER_IN				VARCHAR2(100) DEFAULT NULL,
	USER_UP				VARCHAR2(100) DEFAULT NULL,
	USER_DE				VARCHAR2(100) DEFAULT NULL,
	TIME_IN				TIMESTAMP DEFAULT NULL,
	TIME_UP				TIMESTAMP DEFAULT NULL,
	TIME_DE				TIMESTAMP DEFAULT NULL,
	SBI_VERSION_IN		VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_UP		VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_DE		VARCHAR2(10) DEFAULT NULL,
	META_VERSION		VARCHAR2(100),
	ORGANIZATION		VARCHAR2(20),
	TIME_START          TIMESTAMP DEFAULT NULL,
	TIME_END            TIMESTAMP DEFAULT NULL,
	PRIMARY KEY(EVENT_ID)
);

DROP TABLE SBI_EXT_USER_ROLES_HISTORY;
CREATE TABLE SBI_EXT_USER_ROLES_HISTORY (
	EVENT_ID			INTEGER NOT NULL,
	ID 					INTEGER NOT NULL,
	EXT_ROLE_ID			INTEGER NOT NULL,
	USER_IN				VARCHAR2(100) DEFAULT NULL,
	USER_UP				VARCHAR2(100) DEFAULT NULL,
	USER_DE				VARCHAR2(100) DEFAULT NULL,
	TIME_IN				TIMESTAMP DEFAULT NULL,
	TIME_UP				TIMESTAMP DEFAULT NULL,
	TIME_DE				TIMESTAMP DEFAULT NULL,
	SBI_VERSION_IN		VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_UP		VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_DE		VARCHAR2(10) DEFAULT NULL,
	META_VERSION		VARCHAR2(100),
	ORGANIZATION		VARCHAR2(20),
	TIME_START			TIMESTAMP DEFAULT NULL,
	TIME_END			TIMESTAMP DEFAULT NULL,
	PRIMARY KEY (EVENT_ID)
);

DROP TABLE SBI_USER_ATTRIBUTES_HISTORY;
CREATE TABLE SBI_USER_ATTRIBUTES_HISTORY (
	EVENT_ID			INTEGER NOT NULL,
	ID 					INTEGER NOT NULL,
	ATTRIBUTE_ID 		INTEGER NOT NULL,
	ATTRIBUTE_VALUE		VARCHAR2(500),
	USER_IN              VARCHAR2(100) DEFAULT NULL,
	USER_UP              VARCHAR2(100) DEFAULT NULL,
	USER_DE              VARCHAR2(100) DEFAULT NULL,
	TIME_IN              TIMESTAMP DEFAULT NULL,
	TIME_UP              TIMESTAMP DEFAULT NULL,
	TIME_DE              TIMESTAMP DEFAULT NULL,
	SBI_VERSION_IN       VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_UP       VARCHAR2(10) DEFAULT NULL,
	SBI_VERSION_DE       VARCHAR2(10) DEFAULT NULL,
	META_VERSION         VARCHAR2(100),
	ORGANIZATION         VARCHAR2(20),     
	TIME_START          TIMESTAMP DEFAULT NULL,
	TIME_END            TIMESTAMP DEFAULT NULL,
 	PRIMARY KEY (EVENT_ID)
);
