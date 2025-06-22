/*
===================================================================
 PROBLEM STATEMENT OVERVIEW
===================================================================
A college tracks student Open Elective Subject preferences.
Students can change their subjects, and the system should:
1. Preserve historical data of previously allotted subjects.
2. Ensure only one subject is active (Is_valid = 1) at any time.

Tables:
   - SubjectAllotments: Stores history of subject allotments.
   - SubjectRequest: Stores new subject requests.

LOGIC IMPLEMENTED BY THE STORED PROCEDURE (ProcessSubjectChange):
-------------------------------------------------------------------
For each student request in SubjectRequest:
If student has no entry in SubjectAllotments:
   Insert new subject with Is_valid = 1
If student has an active subject (Is_valid = 1) different from request:
   Mark current subject as Is_valid = 0
   Insert new subject with Is_valid = 1
If requested subject is same as current active subject:
   Do nothing (subject is already active)
===================================================================
*/
------------------------------------------------------------
-- TABLE: SubjectAllotments 
------------------------------------------------------------
CREATE TABLE SubjectAllotments (
    StudentID VARCHAR(20),
    SubjectID VARCHAR(20),
    Is_valid BIT
);

------------------------------------------------------------
-- TABLE: SubjectRequest (Pending Change Requests)
------------------------------------------------------------
CREATE TABLE SubjectRequest (
    StudentID VARCHAR(20),
    SubjectID VARCHAR(20)
);

INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_valid) VALUES
('159103036', 'P01491', 1),
('159103036', 'P01492', 0),
('159103036', 'P01493', 0);

GO
CREATE OR ALTER PROCEDURE sp_ProcessSubjectChangeRequest
AS
BEGIN
    SET NOCOUNT ON;

    -- Loop through each request in SubjectRequest table
    DECLARE @StudentID VARCHAR(20), @RequestedSubjectID VARCHAR(20), @CurrentSubjectID VARCHAR(20);

    DECLARE request_cursor CURSOR FOR
    SELECT StudentID, SubjectID FROM SubjectRequest;

    OPEN request_cursor;
    FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get current active subject for the student
        SELECT @CurrentSubjectID = SubjectID
        FROM SubjectAllotments
        WHERE StudentID = @StudentID AND Is_valid = 1;

        IF @CurrentSubjectID IS NULL
        BEGIN
            -- No current subject, insert the new one
            INSERT INTO SubjectAllotments(StudentID, SubjectID, Is_valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END
        ELSE IF @CurrentSubjectID != @RequestedSubjectID
        BEGIN
            -- Update old subject to Is_valid = 0
            UPDATE SubjectAllotments
            SET Is_valid = 0
            WHERE StudentID = @StudentID AND Is_valid = 1;

            -- Insert the requested subject as the new active one
            INSERT INTO SubjectAllotments(StudentID, SubjectID, Is_valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END
        -- If already same subject as requested, do nothing

        FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;
    END

    CLOSE request_cursor;
    DEALLOCATE request_cursor;
END;

-- test case-1 Requesting a new subject (different from current active)
INSERT INTO SubjectRequest (StudentID, SubjectID) VALUES
('159103036', 'P01496');


EXEC sp_ProcessSubjectChangeRequest;

SELECT * FROM SubjectAllotments ORDER BY StudentID, Is_valid DESC;

SELECT StudentID, COUNT(*) AS ActiveSubjects
FROM SubjectAllotments
WHERE Is_valid = 1
GROUP BY StudentID;


-- test case-2 New student with no subject yet
INSERT INTO SubjectRequest (StudentID, SubjectID) VALUES
('159103099', 'P01500');

-- testcase-3 Exissting one is same as previous one
INSERT INTO SubjectRequest (StudentID, SubjectID) VALUES
('159103099', 'P01500');