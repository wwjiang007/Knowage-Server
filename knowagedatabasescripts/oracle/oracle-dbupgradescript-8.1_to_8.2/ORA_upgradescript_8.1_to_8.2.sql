DELETE FROM SBI_CONFIG WHERE LABEL = 'internal.security.encript.password';

-- 2023-04-04 KNOWAGE_TM-568
CREATE TABLE SBI_VIEW_HIERARCHY (
  ID             CHAR(36)     NOT NULL,
  PARENT_ID      CHAR(36),
  NAME           VARCHAR(200) NOT NULL,
  DESCR          CLOB,
  PROGR          INTEGER      NOT NULL,
  USER_IN        VARCHAR(100) NOT NULL,
  USER_UP        VARCHAR(100),
  USER_DE        VARCHAR(100),
  TIME_IN        TIMESTAMP    NOT NULL,
  TIME_UP        TIMESTAMP        NULL,
  TIME_DE        TIMESTAMP        NULL,
  SBI_VERSION_IN VARCHAR(10),
  SBI_VERSION_UP VARCHAR(10),
  SBI_VERSION_DE VARCHAR(10),
  META_VERSION   VARCHAR(100),
  ORGANIZATION   VARCHAR(20)  NOT NULL,
  PRIMARY KEY (ORGANIZATION,ID)
);

CREATE TABLE SBI_VIEW (
  ID                CHAR(36)     NOT NULL,
  LABEL             VARCHAR(200) NOT NULL,
  NAME              VARCHAR(200) NOT NULL,
  DESCR             CLOB,
  DRIVERS           CLOB         NOT NULL,
  SETTINGS          CLOB         NOT NULL,
  BIOBJ_ID          INTEGER,
  VIEW_HIERARCHY_ID CHAR(36)     NOT NULL,
  USER_IN           VARCHAR(100) NOT NULL,
  USER_UP           VARCHAR(100),
  USER_DE           VARCHAR(100),
  TIME_IN           TIMESTAMP    NOT NULL,
  TIME_UP           TIMESTAMP        NULL,
  TIME_DE           TIMESTAMP        NULL,
  SBI_VERSION_IN    VARCHAR(10),
  SBI_VERSION_UP    VARCHAR(10),
  SBI_VERSION_DE    VARCHAR(10),
  META_VERSION      VARCHAR(100),
  ORGANIZATION      VARCHAR(20)  NOT NULL,
  PRIMARY KEY (ORGANIZATION,ID)
);

CREATE TABLE SBI_VIEW_FOR_DOC (
  ID                CHAR(36)     NOT NULL,
  BIOBJ_ID          INTEGER      NOT NULL,
  VIEW_HIERARCHY_ID CHAR(36)     NOT NULL,
  USER_IN           VARCHAR(100) NOT NULL,
  USER_UP           VARCHAR(100),
  USER_DE           VARCHAR(100),
  TIME_IN           TIMESTAMP    NOT NULL,
  TIME_UP           TIMESTAMP        NULL,
  TIME_DE           TIMESTAMP        NULL,
  SBI_VERSION_IN    VARCHAR(10),
  SBI_VERSION_UP    VARCHAR(10),
  SBI_VERSION_DE    VARCHAR(10),
  META_VERSION      VARCHAR(100),
  ORGANIZATION      VARCHAR(20)  NOT NULL,
  PRIMARY KEY (ORGANIZATION,ID)
);

ALTER TABLE SBI_VIEW_HIERARCHY ADD CONSTRAINT FK_SBI_VIEW_HIERARCHY_1 FOREIGN KEY (ORGANIZATION, PARENT_ID) REFERENCES SBI_VIEW_HIERARCHY (ORGANIZATION, ID);

ALTER TABLE SBI_VIEW ADD CONSTRAINT FK_SBI_VIEW_1 FOREIGN KEY (ORGANIZATION, VIEW_HIERARCHY_ID) REFERENCES SBI_VIEW_HIERARCHY (ORGANIZATION, ID);
ALTER TABLE SBI_VIEW ADD CONSTRAINT FK_SBI_VIEW_2 FOREIGN KEY (BIOBJ_ID)                        REFERENCES SBI_OBJECTS        (BIOBJ_ID);

ALTER TABLE SBI_VIEW_FOR_DOC ADD CONSTRAINT FK_SBI_VIEW_FOR_DOC_1 FOREIGN KEY (ORGANIZATION, VIEW_HIERARCHY_ID) REFERENCES SBI_VIEW_HIERARCHY (ORGANIZATION, ID);
ALTER TABLE SBI_VIEW_FOR_DOC ADD CONSTRAINT FK_SBI_VIEW_FOR_DOC_2 FOREIGN KEY (BIOBJ_ID)                        REFERENCES SBI_OBJECTS        (BIOBJ_ID);
