/*
	use schoolJournal
	go
*/

-- функция на получение списка студентов в классе
CREATE FUNCTION fn_students_in_class(@class_id INT)
RETURNS TABLE
AS
RETURN (
	SELECT
		s.fullname,
		u.email AS student_email,
		u.phone AS  student_phone,
		p.fullname AS parent_name,
		p.phone AS parent_phone
	FROM students s
	INNER JOIN users u ON s.user_id = u.id
	LEFT JOIN parents p ON s.parent_id = p.id
	WHERE s.class_id = @class_id
		AND u.deleted_at IS NULL
);