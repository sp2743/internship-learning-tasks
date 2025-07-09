Create Database Employee;

CREATE TABLE EmployeeAttendance (
    EmpID INT,
    Name VARCHAR(50),
    CheckInCheckOutTime DATETIME,
    Attendance VARCHAR(10)
);

INSERT INTO EmployeeAttendance (EmpID, Name, CheckInCheckOutTime, Attendance)
VALUES 
(1, 'Him', '2024-01-03 10:08:00', 'IN'),
(2, 'Raj', '2024-01-03 10:10:00', 'IN'),
(3, 'Anu', '2024-01-03 10:12:00', 'IN'),
(1, 'Him', '2024-01-03 11:11:00', 'OUT'),
(2, 'Raj', '2024-01-03 12:12:00', 'OUT'),
(3, 'Anu', '2024-01-03 12:35:00', 'OUT'),
(1, 'Him', '2024-01-03 12:08:00', 'IN'),
(2, 'Raj', '2024-01-03 12:25:00', 'IN'),
(3, 'Anu', '2024-01-03 12:40:00', 'IN'),
(1, 'Him', '2024-01-03 14:12:00', 'OUT'),
(2, 'Raj', '2024-01-03 15:12:00', 'OUT'),
(3, 'Anu', '2024-01-03 18:35:00', 'OUT'),
(1, 'Him', '2024-01-03 15:08:00', 'IN'),
(1, 'Him', '2024-01-03 18:08:00', 'OUT');
