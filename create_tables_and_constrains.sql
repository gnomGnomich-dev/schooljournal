CREATE DATABASE schoolJournal;

USE schoolJournal
GO

CREATE TABLE auth_tokens (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,       -- токен доступа
    refresh_token VARCHAR(255) UNIQUE NULL,   -- опционально, для refresh
    ip_address VARCHAR(45) NULL,
    user_agent NVARCHAR(500) NULL,
    issued_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    expires_at DATETIME2 NOT NULL,            -- срок жизни токена
    is_revoked CHAR(1) DEFAULT '0',           -- отозван ли токен
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Индексы для быстрого поиска
CREATE INDEX IX_auth_tokens_token ON auth_tokens(token);
CREATE INDEX IX_auth_tokens_user_id ON auth_tokens(user_id);
CREATE INDEX IX_auth_tokens_expires_at ON auth_tokens(expires_at);
CREATE INDEX IX_auth_tokens_is_revoked ON auth_tokens(is_revoked);

CREATE TABLE users (
	id INT PRIMARY KEY IDENTITY(1, 1),
	email VARCHAR(255) UNIQUE NOT NULL,
	password_hash VARCHAR(255) NULL,
	role_id INT NOT NULL,
	phone VARCHAR(20) UNIQUE NOT NULL,
	is_active CHAR(1) DEFAULT '1',
	avatar_url TEXT,
	created_at DATETIME DEFAULT SYSDATETIME(),
	updated_at DATETIME NULL,
	deleted_at DATETIME NULL
);

CREATE TABLE schools (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20),
    director_name VARCHAR(255),
    created_at DATETIME DEFAULT SYSDATETIME(),
	deleted_at DATETIME
);

CREATE TABLE roles (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(20)
);

CREATE TABLE classes (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(10) NOT NULL,          
    school_id INTEGER, 
    curator_id INTEGER,                
    created_at DATETIME DEFAULT SYSDATETIME(),
	deleted_at DATETIME
);

CREATE TABLE students (
    id INT PRIMARY KEY IDENTITY(1, 1),
    user_id INTEGER UNIQUE,
    class_id INTEGER,
    birth_date DATE,
    gender_id INT,
    enrollment_date DATE,
    parent_id INTEGER,
    update_at DATETIME,
    deleted_at DATETIME
);

CREATE TABLE parents (
    id INT PRIMARY KEY IDENTITY(1, 1),
    fullname VARCHAR(255),
    user_id INTEGER UNIQUE,
    birth_date DATE,
    gender_id INT,
    passport INT,
    phone INT
);

CREATE TABLE genders (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(10)
);

CREATE TABLE teachers (
    id INT PRIMARY KEY IDENTITY(1, 1),
    user_id INTEGER UNIQUE,
    gender_id INTEGER,
    subject_id INT,
    education VARCHAR(255),
    experience_years INTEGER,
    hire_date DATE,
    update_at DATETIME,
    deleted_at DATETIME
);

CREATE TABLE subjects (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(255) NOT NULL UNIQUE,   
    short_name VARCHAR(50),         
    description VARCHAR(255)
);

CREATE TABLE class_subjects (
    id INT PRIMARY KEY IDENTITY(1, 1),
    class_id INTEGER,
    subject_id INTEGER,
    teacher_id INTEGER ,
    hours_per_week TINYINT,              
    UNIQUE(class_id, subject_id)        
);

CREATE TABLE grades (
    id INT PRIMARY KEY IDENTITY(1, 1),
    student_id INTEGER, 
    subject_id INTEGER, 
    teacher_id INTEGER, 
    value_id INTEGER NOT NULL,
    date DATETIME NOT NULL DEFAULT SYSDATETIME(),
    comment VARCHAR(255),
    created_at DATETIME DEFAULT SYSDATETIME(),
    deleted_at DATETIME
);

CREATE TABLE grade_values (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(3),
    comment VARCHAR(50)
);

CREATE TABLE schedule (
    id INT PRIMARY KEY IDENTITY(1, 1),
    class_id INTEGER,
    subject_id INTEGER,
    teacher_id INTEGER,
    day_id INTEGER NOT NULL, 
    lesson_number INTEGER NOT NULL,       
    start_time TIME,                      
    end_time TIME,                       
    room VARCHAR(50),                    
    homework VARCHAR(MAX),      
    semester_id INTEGER 
);

CREATE TABLE weekdays (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(50)
);

CREATE TABLE semesters (
    id INT PRIMARY KEY IDENTITY(1, 1),
    name VARCHAR(50) NOT NULL,           
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    school_id INTEGER NOT NULL,
    year DATE NOT NULL 
);

CREATE TABLE settings (
    id INT PRIMARY KEY IDENTITY(1, 1),
    value VARCHAR(255),
    description VARCHAR(255),
    updated_at DATETIME DEFAULT SYSDATETIME()
);

-- Связи между таблицами --
-- 1. classes → schools
ALTER TABLE classes
ADD CONSTRAINT FK_classes_schools
FOREIGN KEY (school_id) REFERENCES schools(id);

-- 2. classes → teachers (curator_id)
ALTER TABLE classes
ADD CONSTRAINT FK_classes_teachers_curator
FOREIGN KEY (curator_id) REFERENCES teachers(id);

-- 3. students → users
ALTER TABLE students
ADD CONSTRAINT FK_students_users
FOREIGN KEY (user_id) REFERENCES users(id);

-- 4. students → classes
ALTER TABLE students
ADD CONSTRAINT FK_students_classes
FOREIGN KEY (class_id) REFERENCES classes(id);

-- 5. students → genders
ALTER TABLE students
ADD CONSTRAINT FK_students_genders
FOREIGN KEY (gender_id) REFERENCES genders(id);

-- 6. students → users (parent_id)
ALTER TABLE students
ADD CONSTRAINT FK_students_parents
FOREIGN KEY (parent_id) REFERENCES users(id);

-- 7. teachers → users
ALTER TABLE teachers
ADD CONSTRAINT FK_teachers_users
FOREIGN KEY (user_id) REFERENCES users(id);

-- 8. teachers → subjects
ALTER TABLE teachers
ADD CONSTRAINT FK_teachers_subjects
FOREIGN KEY (subject_id) REFERENCES subjects(id);

-- 9. class_subjects → classes
ALTER TABLE class_subjects
ADD CONSTRAINT FK_class_subjects_classes
FOREIGN KEY (class_id) REFERENCES classes(id);

-- 10. class_subjects → subjects
ALTER TABLE class_subjects
ADD CONSTRAINT FK_class_subjects_subjects
FOREIGN KEY (subject_id) REFERENCES subjects(id);

-- 11. class_subjects → teachers
ALTER TABLE class_subjects
ADD CONSTRAINT FK_class_subjects_teachers
FOREIGN KEY (teacher_id) REFERENCES teachers(id);

-- 12. grades → students
ALTER TABLE grades
ADD CONSTRAINT FK_grades_students
FOREIGN KEY (student_id) REFERENCES students(id);

-- 13. grades → subjects
ALTER TABLE grades
ADD CONSTRAINT FK_grades_subjects
FOREIGN KEY (subject_id) REFERENCES subjects(id);

-- 14. grades → teachers
ALTER TABLE grades
ADD CONSTRAINT FK_grades_teachers
FOREIGN KEY (teacher_id) REFERENCES teachers(id);

-- 15. grades → grade_values
ALTER TABLE grades
ADD CONSTRAINT FK_grades_grade_values
FOREIGN KEY (value_id) REFERENCES grade_values(id);

-- 16. schedule → classes
ALTER TABLE schedule
ADD CONSTRAINT FK_schedule_classes
FOREIGN KEY (class_id) REFERENCES classes(id);

-- 17. schedule → subjects
ALTER TABLE schedule
ADD CONSTRAINT FK_schedule_subjects
FOREIGN KEY (subject_id) REFERENCES subjects(id);

-- 18. schedule → teachers
ALTER TABLE schedule
ADD CONSTRAINT FK_schedule_teachers
FOREIGN KEY (teacher_id) REFERENCES teachers(id);

-- 19. schedule → semesters
ALTER TABLE schedule
ADD CONSTRAINT FK_schedule_semesters
FOREIGN KEY (semester_id) REFERENCES semesters(id);

-- 20. semesters → schools
ALTER TABLE semesters
ADD CONSTRAINT FK_semesters_schools
FOREIGN KEY (school_id) REFERENCES schools(id);

--21. schedule -> weekdays
ALTER TABLE schedule
ADD CONSTRAINT FK_schedule_weekdays
FOREIGN KEY (day_id) REFERENCES weekdays(id);

--22. students -> parents
ALTER TABLE students
ADD CONSTRAINT FK_students_parents
FOREIGN KEY (parent_id) REFERENCES parents(id);

--22. parents -> users
ALTER TABLE parents
ADD CONSTRAINT FK_parents_users
FOREIGN KEY (user_id) REFERENCES users(id);

--23. parents -> genders
ALTER TABLE parents
ADD CONSTRAINT FK_parents_genders
FOREIGN KEY (gender_id) REFERENCES genders(id);

--24. teachers -> genders
ALTER TABLE teachers
ADD CONSTRAINT FK_teachers_genders
FOREIGN KEY (gender_id) REFERENCES genders(id);

--25. users -> roles
ALTER TABLE users
ADD CONSTRAINT FK_users_roles
FOREIGN KEY (role_id) REFERENCES roles(id);

INSERT INTO genders (name) VALUES 
(
    'мужской',
    'женский'
);

INSERT INTO classes (name) VALUES
(
    '1а',
    '9в'
);