CREATE FUNCTION knowage_master.get_next_val_from_hibernate(sequence_name VARCHAR(200))
RETURNS INT
BEGIN
	DECLARE next_val INT ;
	SELECT hs.next_val INTO next_val FROM hibernate_sequences hs
	WHERE hs.sequence_name = sequence_name ;

	UPDATE hibernate_sequences hs SET hs.next_val = hs.next_val + 1 WHERE hs.sequence_name = sequence_name ;

	RETURN next_val ;
END

INSERT INTO sbi_user_history(EVENT_ID,USER_ID,PASSWORD,FULL_NAME,ID,DT_PWD_BEGIN,DT_PWD_END,FLG_PWD_BLOCKED,DT_LAST_ACCESS,IS_SUPERADMIN,USER_IN,USER_UP,USER_DE,TIME_IN,TIME_UP,TIME_DE,SBI_VERSION_IN,SBI_VERSION_UP,SBI_VERSION_DE,META_VERSION,ORGANIZATION,TIME_START)
SELECT knowage.get_next_val_from_hibernate("SBI_USER_HISTORY"), su.*, su.TIME_IN 
FROM sbi_user su 
WHERE su.USER_ID NOT IN ( SELECT DISTINCT USER_ID FROM sbi_user_history )

INSERT INTO sbi_ext_user_roles_history (EVENT_ID,ID,EXT_ROLE_ID,USER_IN,USER_UP,USER_DE,TIME_IN,TIME_UP,TIME_DE,SBI_VERSION_IN,SBI_VERSION_UP,SBI_VERSION_DE,META_VERSION,ORGANIZATION,TIME_START)
SELECT get_next_val_from_hibernate("SBI_EXT_USER_ROLES_HISTORY"), su.*, su.TIME_IN 
FROM sbi_ext_user_roles su 
WHERE su.ID NOT IN ( SELECT DISTINCT ID FROM sbi_user_history )

INSERT INTO SBI_USER_ATTRIBUTES_HISTORY (EVENT_ID,ID,ATTRIBUTE_ID,ATTRIBUTE_VALUE,USER_IN,USER_UP,USER_DE,TIME_IN,TIME_UP,TIME_DE,SBI_VERSION_IN,SBI_VERSION_UP,SBI_VERSION_DE,META_VERSION,ORGANIZATION,TIME_START)
SELECT get_next_val_from_hibernate("SBI_USER_ATTRIBUTES_HISTORY"), su.*, su.TIME_IN 
FROM SBI_USER_ATTRIBUTES su 
WHERE su.ID NOT IN ( SELECT DISTINCT ID FROM sbi_user_history )
