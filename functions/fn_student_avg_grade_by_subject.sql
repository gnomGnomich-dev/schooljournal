-- функция на получение ср. балла ученика по предмету
CREATE FUNCTION fn_student_avg_grade_by_subject(@student_id INT, @subject_id INT)
RETURNS DECIMAL(3,2)
AS
BEGIN
	DECLARE @avg_grade DECIMAL(3,2);

	SELECT @avg_grade = AVG(CAST(gv.name AS DECIMAL(3,2)))
	FROM grades g
	INNER JOIN grade_values gv ON g.value_id = gv.id
	WHERE g.student_id = @student_id
		AND g.subject_id = @subject_id
		AND g.deleted_at IS NULL;

	RETURN ISNULL(@avg_grade, 0);
END;