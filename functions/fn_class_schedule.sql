/*
	use schoolJournal
	go
*/

-- функция получения расписания класса на неделю
CREATE FUNCTION fn_class_schedule(@class_id INT, @semestr_id INT)
RETURNS TABLE
AS
RETURN (
	SELECT
		wd.name AS day_name,
		sch.lesson_number,
		sub.name as subject_name,
		t.fullname,
		u.email AS teacher_email,
		sch.start_time,
		sch.end_time,
		sch.room
	FROM schedule sch
	INNER JOIN weekdays wd ON sch.day_id = wd.id
	INNER JOIN subjects sub ON sch.subject_id = sub.id
	INNER JOIN teachers t ON sch.teacher_id = t.id
	INNER JOIN users u ON t.user_id = u.id
	WHERE sch.class_id = @class_id
		AND sch.semester_id = @semestr_id
		AND sch.is_active = '1'
);