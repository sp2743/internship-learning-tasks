WITH cte AS (
    SELECT *,
           LEAD(CheckInCheckOutTime) OVER (PARTITION BY EmpID ORDER BY CheckInCheckOutTime) AS NextTime,
           LEAD(Attendance) OVER (PARTITION BY EmpID ORDER BY CheckInCheckOutTime) AS NextStatus
    FROM EmployeeAttendance
),
-- Filter only IN rows and pair with next OUT
work_cte AS (
    SELECT
        EmpID,
        Name,
        CheckInCheckOutTime AS CheckInTime,
        NextTime AS CheckOutTime,
        DATEDIFF(MINUTE, CheckInCheckOutTime, NextTime) AS DurationMinutes
    FROM cte
    WHERE UPPER(Attendance) = 'IN' AND UPPER(NextStatus) = 'OUT'
),
-- Aggregation for each employee
agg_cte AS (
    SELECT
        EmpID,
        Name,
        MIN(CheckInTime) AS FirstCheckInTime,
        MAX(CheckOutTime) AS LastCheckOutTime,
        COUNT(*) AS PairedSessions,
        SUM(DurationMinutes) AS TotalWorkMinutes
    FROM work_cte
    GROUP BY EmpID, Name
),
-- Count OUTs from original table
out_count_cte AS (
    SELECT EmpID, COUNT(*) AS TotalOutCount
    FROM EmployeeAttendance
    WHERE UPPER(Attendance) = 'OUT'
    GROUP BY EmpID
)
-- Final result with join
SELECT 
    a.EmpID,
    a.Name,
    a.FirstCheckInTime,
    a.LastCheckOutTime,
    ISNULL(o.TotalOutCount, 0) AS TotalOutCount,
    RIGHT('0' + CAST(a.TotalWorkMinutes / 60 AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST(a.TotalWorkMinutes % 60 AS VARCHAR), 2) AS TotalWorkHours_HHMM
FROM agg_cte a
LEFT JOIN out_count_cte o ON a.EmpID = o.EmpID
ORDER BY a.EmpID;


-- let write a stored procedure for above whole process
GO
CREATE PROCEDURE dbo.sp_GetEmployeeAttendanceSummary
AS
BEGIN
    SET NOCOUNT ON;
    -- Step 1: Pair IN and OUT records
    WITH cte AS (
        SELECT *,
               LEAD(CheckInCheckOutTime) OVER (PARTITION BY EmpID ORDER BY CheckInCheckOutTime) AS NextTime,
               LEAD(Attendance) OVER (PARTITION BY EmpID ORDER BY CheckInCheckOutTime) AS NextStatus
        FROM EmployeeAttendance
    ),
    -- Step 2: Filter valid IN–OUT sessions
    work_cte AS (
        SELECT
            EmpID,
            Name,
            CheckInCheckOutTime AS CheckInTime,
            NextTime AS CheckOutTime,
            DATEDIFF(MINUTE, CheckInCheckOutTime, NextTime) AS DurationMinutes
        FROM cte
        WHERE UPPER(Attendance) = 'IN'
          AND UPPER(NextStatus) = 'OUT'
          AND NextTime IS NOT NULL
          AND DATEDIFF(MINUTE, CheckInCheckOutTime, NextTime) > 0
    ),
    -- Step 3: Aggregate work durations
    agg_cte AS (
        SELECT
            EmpID,
            Name,
            MIN(CheckInTime) AS FirstCheckInTime,
            MAX(CheckOutTime) AS LastCheckOutTime,
            COUNT(*) AS PairedSessions,
            SUM(DurationMinutes) AS TotalWorkMinutes
        FROM work_cte
        GROUP BY EmpID, Name
    ),

    -- Step 4: Count total OUTs per employee
    out_count_cte AS (
        SELECT EmpID, COUNT(*) AS TotalOutCount
        FROM EmployeeAttendance
        WHERE UPPER(Attendance) = 'OUT'
        GROUP BY EmpID
    )

    -- Step 5: Final Output
    SELECT 
        a.EmpID,
        a.Name,
        a.FirstCheckInTime,
        a.LastCheckOutTime,
        ISNULL(o.TotalOutCount, 0) AS TotalOutCount,
        FORMAT(DATEADD(MINUTE, a.TotalWorkMinutes, 0), 'HH:mm') AS TotalWorkHours_HHMM
    FROM agg_cte a
    LEFT JOIN out_count_cte o ON a.EmpID = o.EmpID
    ORDER BY a.EmpID;
END;
GO
