# 👨‍💼 Employee Attendance Summary (SQL Project)
To meet the company's requirements, need to calculate the total work hours of employees in a day based on their check-in and check-out times.

## 🔍 About
A SQL Server project developed during my internship at Celebal Technologies. It calculates:
- First Check-In
- Last Check-Out
- Total OUT counts
- Total Work Hours (HH:MM)

## 🗃️ Database Schema

### Table: `EmployeeAttendance`
| Column               | Type         | Description                       |
|----------------------|--------------|-----------------------------------|
| `EmpID`              | INT          | Employee ID                       |
| `Name`               | VARCHAR(50)  | Employee name                     |
| `CheckInCheckOutTime`| DATETIME     | Time of check-in or check-out     |
| `Attendance`         | VARCHAR(10)  | 'IN' or 'OUT'                     |

## 🧱 Technologies
- SQL Server
- Stored Procedure
- CTEs, Window Functions

## 📁 Files Included
- `database_setup.sql`: Create table and insert sample data
- `stored_procedure.sql`: Logic to summarize attendance
- `sample_query_output.png`: Screenshot of final result in SSMS

## 🛠️ How to Run

1. Run `database_setup.sql` to create the table and insert data.
2. Run `stored_procedure.sql` to create the stored procedure.
3. Execute:

```sql
EXEC dbo.sp_GetEmployeeAttendanceSummary;
