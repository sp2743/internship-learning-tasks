/*
==========================================
Project: Open Elective Subject Allocation System
Author: Shaswat Patel
Description:
    This SQL script contains logic for allocating Open Elective Subjects to students
    based on their preferences and GPA. Additionally, it handles subject change
    requests while preserving subject history.

Phase 1: Subject Allocation
---------------------------
- Each student can select 5 subject preferences.
- Students are allotted subjects based on their GPA (highest first).
- If a student's higher preference is full, the next one is considered.
- Final allotments are stored in the "Allotments" table.
- Students who do not get any subjects are stored in "UnallotedStudents".
*/


Create Database College
GO

-- Students
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA FLOAT
);

-- Subjects
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    RemainingSeats INT
);

-- Student Preference
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT CHECK (Preference BETWEEN 1 AND 5),
    PRIMARY KEY (StudentId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

-- allotment
CREATE TABLE Allotments (
    StudentId INT PRIMARY KEY,
    SubjectId VARCHAR(10),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

-- unalloted student
CREATE TABLE UnallotedStudents (
    StudentId INT PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- Insert sample data
INSERT INTO StudentDetails (StudentId, StudentName, GPA) VALUES
(1, 'Alice', 9.5), (2, 'Bob', 8.7), (3, 'Charlie', 9.8), (4, 'David', 7.9),
(5, 'Eva', 9.1), (6, 'Frank', 8.5), (7, 'Grace', 8.0), (8, 'Hank', 7.5),
(9, 'Ivy', 8.9), (10, 'Jake', 9.0), (11, 'Kara', 7.8), (12, 'Liam', 9.3),
(13, 'Mia', 9.6), (14, 'Noah', 7.7), (15, 'Olivia', 8.2), (16, 'Paul', 8.3),
(17, 'Quinn', 7.6), (18, 'Rose', 9.4), (19, 'Sam', 7.4), (20, 'Tina', 8.8);

INSERT INTO SubjectDetails (SubjectId, SubjectName, RemainingSeats) VALUES
('S1', 'Mathematics', 5),
('S2', 'Physics', 7),
('S3', 'Chemistry', 6);


INSERT INTO StudentPreference VALUES
(1, 'S1', 1), (1, 'S2', 2), (1, 'S3', 3), (1, 'S1', 4), (1, 'S2', 5),
(2, 'S2', 1), (2, 'S3', 2), (2, 'S1', 3), (2, 'S2', 4), (2, 'S3', 5),
(3, 'S3', 1), (3, 'S1', 2), (3, 'S2', 3), (3, 'S3', 4), (3, 'S1', 5),
(4, 'S1', 1), (4, 'S3', 2), (4, 'S2', 3), (4, 'S2', 4), (4, 'S1', 5),
(5, 'S2', 1), (5, 'S1', 2), (5, 'S3', 3), (5, 'S3', 4), (5, 'S1', 5),
(6, 'S1', 1), (6, 'S3', 2), (6, 'S2', 3), (6, 'S1', 4), (6, 'S3', 5),
(7, 'S2', 1), (7, 'S1', 2), (7, 'S3', 3), (7, 'S3', 4), (7, 'S2', 5),
(8, 'S3', 1), (8, 'S1', 2), (8, 'S2', 3), (8, 'S2', 4), (8, 'S1', 5),
(9, 'S1', 1), (9, 'S2', 2), (9, 'S3', 3), (9, 'S3', 4), (9, 'S1', 5),
(10, 'S3', 1), (10, 'S1', 2), (10, 'S2', 3), (10, 'S2', 4), (10, 'S3', 5),
(11, 'S2', 1), (11, 'S1', 2), (11, 'S3', 3), (11, 'S1', 4), (11, 'S2', 5),
(12, 'S1', 1), (12, 'S3', 2), (12, 'S2', 3), (12, 'S2', 4), (12, 'S1', 5),
(13, 'S2', 1), (13, 'S3', 2), (13, 'S1', 3), (13, 'S1', 4), (13, 'S2', 5),
(14, 'S3', 1), (14, 'S1', 2), (14, 'S2', 3), (14, 'S3', 4), (14, 'S2', 5),
(15, 'S1', 1), (15, 'S2', 2), (15, 'S3', 3), (15, 'S3', 4), (15, 'S2', 5),
(16, 'S2', 1), (16, 'S3', 2), (16, 'S1', 3), (16, 'S1', 4), (16, 'S3', 5),
(17, 'S3', 1), (17, 'S2', 2), (17, 'S1', 3), (17, 'S3', 4), (17, 'S2', 5),
(18, 'S1', 1), (18, 'S3', 2), (18, 'S2', 3), (18, 'S1', 4), (18, 'S3', 5),
(19, 'S2', 1), (19, 'S1', 2), (19, 'S3', 3), (19, 'S2', 4), (19, 'S1', 5),
(20, 'S3', 1), (20, 'S1', 2), (20, 'S2', 3), (20, 'S3', 4), (20, 'S2', 5);

SELECT * FROM StudentDetails;

SELECT sp.SubjectId, sp.StudentId
FROM StudentPreference sp
INNER JOIN StudentDetails s ON sp.StudentId = s.StudentId
INNER JOIN SubjectDetails sd ON sp.SubjectId = sd.SubjectId
LEFT JOIN Allotments a ON a.StudentId = sp.StudentId
WHERE sp.Preference = 1
AND a.StudentId IS NULL         -- Student not yet allotted
AND sd.RemainingSeats > 0
AND NOT EXISTS (                -- Avoid duplicate entries
              SELECT 1 FROM Allotments x
              WHERE x.StudentId = sp.StudentId
               )
ORDER BY s.GPA DESC;


-- Creating a stored procedure to allocate the seat to the student based on the preference and remaining seat.
GO 
CREATE PROCEDURE AllocateSubjectToStudents 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @pref INT =1;

    WHILE @pref<=5
    BEGIN
        INSERT INTO Allotments (SubjectId,StudentId)
        SELECT sp.SubjectId, sp.StudentId
        FROM StudentPreference sp
        INNER JOIN StudentDetails s ON sp.StudentId = s.StudentId
        INNER JOIN SubjectDetails sd ON sp.SubjectId = sd.SubjectId
        LEFT JOIN Allotments a ON a.StudentId = sp.StudentId
        WHERE sp.Preference = @pref
          AND a.StudentId IS NULL         -- Student not yet allotted
          AND sd.RemainingSeats > 0
          AND NOT EXISTS (                -- Avoid duplicate entries
              SELECT 1 FROM Allotments x
              WHERE x.StudentId = sp.StudentId
          )
        ORDER BY s.GPA DESC;

        UPDATE sd
        SET sd.RemainingSeats = sd.RemainingSeats - x.AllocCount
        FROM SubjectDetails sd
        INNER JOIN (
            SELECT SubjectId, COUNT(*) AS AllocCount
            FROM Allotments
            WHERE StudentId IN (
                SELECT sp.StudentId
                FROM StudentPreference sp
                WHERE sp.Preference = @pref
            )
            GROUP BY SubjectId
        ) x ON sd.SubjectId = x.SubjectId;

        SET @pref = @pref + 1;
    END

    INSERT INTO UnallotedStudents (StudentId)
    SELECT s.StudentId
    FROM StudentDetails s
    LEFT JOIN Allotments a ON s.StudentId = a.StudentId
    WHERE a.StudentId IS NULL;

END;

EXEC AllocateSubjectToStudents;

-- show the result in allotments table and unallotedStudents table
SELECT * FROM Allotments;
SELECT * FROM UnallotedStudents;


