CREATE OR ALTER TRIGGER tr_users_generate_password
ON users
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE u
    SET password_hash = CONVERT(VARCHAR(128),
                HASHBYTES('SHA2_512',
                    LEFT(NEWID(), 8) + LEFT(NEWID(), 4)
                ), 2)
    FROM users u
    INNER JOIN inserted i ON u.id = i.id
    WHERE i.password_hash IS NULL OR i.password_hash = '';

END;