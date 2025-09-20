/*
use schoolJournal
go
*/

-- здесь представлены триггеры на обновление таблиц (изменение поля updated_at)
CREATE OR ALTER TRIGGER trg_users_update_at
ON users
AFTER UPDATE
AS
BEGIN
	UPDATE u
	SET updated_at = SYSDATETIME()
	FROM users u
	INNER JOIN inserted i on u.id = i.id;
END;

CREATE TRIGGER trg_schools_updated_at
ON schools
AFTER UPDATE
AS
BEGIN
	UPDATE u
	SET updated_at = SYSDATETIME()
	FROM users u
	INNER JOIN inserted i on u.id = i.id;
END;

CREATE TRIGGER trg_classes_updated_at
ON classes
AFTER UPDATE
AS
BEGIN
	UPDATE u
	SET updated_at = SYSDATETIME()
	FROM users u
	INNER JOIN inserted i on u.id = i.id;
END;