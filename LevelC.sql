CREATE TABLE Projects (
    Task_ID INT PRIMARY KEY,
    Start_Date DATE NOT NULL,
    End_Date DATE NOT NULL
);

INSERT INTO Projects (Task_ID, Start_Date, End_Date)
VALUES
  (1, '2015-10-01', '2015-10-02'),
  (2, '2015-10-02', '2015-10-03'),
  (3, '2015-10-03', '2015-10-04'),
  (4, '2015-10-13', '2015-10-14'),
  (5, '2015-10-14', '2015-10-15'),
  (6, '2015-10-28', '2015-10-29'),
  (7, '2015-10-30', '2015-10-31');

/*
Write a query to output the start and end dates of projects listed by number of days to complete
project in ascending order.
approach: use recursive cte to form a chain. 
          use window function (row_num) for without recursive. 
*/

WITH ProjectList AS (
	SELECT 
		ROW_NUMBER() OVER (ORDER BY Start_Date) AS RowNum,
		Start_Date,
		End_Date
	FROM Projects
)
SELECT 
	MIN(Start_Date) AS Project_Start,
	MAX(End_Date) AS Project_End
FROM ProjectList
GROUP BY 
	DATEDIFF(DAY, RowNum, Start_Date)
ORDER BY 
	DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)),
	MIN(Start_Date);


--------------------------------------------------------------------------------------------------
/*
Write a query to output the names of those students whose best friends got offered a higher salary than them.
Names must be ordered by the salary amount offered to the best friend.It is gurantee that no two students got same salary offers.
*/

CREATE TABLE Students (
    ID INT PRIMARY KEY,
    Name VARCHAR(50)
);

-- Friends table
CREATE TABLE Friends (
    ID INT,
    Friend_ID INT
);

-- Packages table
CREATE TABLE Packages (
    ID INT PRIMARY KEY,
    Salary DECIMAL(10, 2)
);

-- Insert into Students
INSERT INTO Students (ID, Name) VALUES
(1, 'Ashley'),
(2, 'Samantha'),
(3, 'Julia'),
(4, 'Scarlet');

-- Insert into Friends
INSERT INTO Friends (ID, Friend_ID) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);

-- Insert into Packages
INSERT INTO Packages (ID, Salary) VALUES
(1, 15.20),
(2, 10.06),
(3, 11.55),
(4, 12.12);


SELECT Name
FROM Students s
JOIN Friends f on s.ID=f.ID
JOIN Packages p on f.ID=p.ID
JOIN packages p1 on f.Friend_ID=p1.ID
WHERE p.salary<p1.salary;


----------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/symmetric-pairs/problem

SELECT DISTINCT
    LEAST(f1.x, f1.y) AS x,
    GREATEST(f1.x, f1.y) AS y
FROM Functions f1
JOIN Functions f2
    ON f1.x = f2.y AND f1.y = f2.x
WHERE f1.x <> f1.y

UNION

-- Self-pairs (x == y), check if they occur more than once
SELECT X, Y
FROM Functions
WHERE X = Y
GROUP BY X, Y
HAVING COUNT(*) > 1

ORDER BY X, Y;

-----------------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/interviews/problem

SELECT 
    c.contest_id, 
    c.hacker_id, 
    c.name,
    COALESCE(SUM(s.total_submissions), 0) AS total_submissions, 
    COALESCE(SUM(s.total_accepted_submissions), 0) AS total_accepted_submissions, 
    COALESCE(SUM(v.total_views), 0) AS total_views, 
    COALESCE(SUM(v.total_unique_views), 0) AS total_unique_views
FROM Contests c
JOIN Colleges cl ON c.contest_id = cl.contest_id
JOIN Challenges ch ON cl.college_id = ch.college_id
LEFT JOIN (SELECT challenge_id, 
                  SUM(total_submissions) AS total_submissions, 
                  SUM(total_accepted_submissions) AS total_accepted_submissions
           FROM Submission_Stats
           GROUP BY challenge_id) s ON ch.challenge_id = s.challenge_id
LEFT JOIN (SELECT challenge_id, 
                  SUM(total_views) AS total_views, 
                  SUM(total_unique_views) AS total_unique_views
           FROM View_Stats
           GROUP BY challenge_id) v ON ch.challenge_id = v.challenge_id
GROUP BY c.contest_id, c.hacker_id, c.name
HAVING 
    total_submissions > 0 OR 
    total_accepted_submissions > 0 OR 
    total_views > 0 OR 
    total_unique_views > 0
ORDER BY c.contest_id;

-----------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/contest-leaderboard/problem


SELECT h.hacker_id,h.name,SUM(s.score) as total_score
FROM Hackers h
JOIN (SELECT hacker_id,challenge_id,MAX(score) as score
     FROM Submissions
     GROUP by hacker_id,challenge_id) s on h.hacker_id=s.hacker_id
GROUP BY h.hacker_id,h.name
HAVING total_score>0
ORDER BY total_score desc,h.hacker_id;

----------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/weather-observation-station-18/problem

SELECT ROUND(abs(MAX(LONG_W)-MIN(LONG_W))+abs(MAX(LAT_N)-MIN(LAT_N)),4)
FROM STATION

----------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/print-prime-numbers/problem

DECLARE @N INT = 1000;

WITH Numbers AS (
    SELECT 2 AS num
    UNION ALL
    SELECT num + 1 FROM Numbers WHERE num + 1 <= @N
),
Divisors AS (
    SELECT n.num AS candidate, d.num AS divisor
    FROM Numbers n
    JOIN Numbers d ON d.num < n.num AND n.num % d.num = 0
),
PrimeNumbers AS (
    SELECT num FROM Numbers
    WHERE num NOT IN (SELECT candidate FROM Divisors)
)
SELECT STRING_AGG(CAST(num AS VARCHAR), '&') AS PrimeList
FROM PrimeNumbers
OPTION (MAXRECURSION 0);

----------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/occupations/problem

WITH RankedOccupations AS (
    SELECT 
        Name,
        Occupation,
        ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM OCCUPATIONS
)
SELECT 
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
FROM RankedOccupations
GROUP BY rn
ORDER BY rn;

------------------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/binary-search-tree-1/problem

SELECT N,
       CASE 
           WHEN P IS NULL THEN 'Root'  
           WHEN N NOT IN (SELECT DISTINCT P FROM BST WHERE P IS NOT NULL) THEN 'Leaf'
           ELSE 'Inner'
       END AS NodeType
FROM BST
ORDER BY N;

----------------------------------------------------------------------------
-- https://www.hackerrank.com/challenges/the-company/problem

SELECT c.company_code, 
       c.founder, 
       (SELECT COUNT(DISTINCT lm.lead_manager_code) FROM Lead_Manager lm WHERE lm.company_code = c.company_code) AS total_lead_managers, 
       (SELECT COUNT(DISTINCT sm.senior_manager_code) FROM Senior_Manager sm WHERE sm.company_code = c.company_code) AS total_senior_managers, 
       (SELECT COUNT(DISTINCT m.manager_code) FROM Manager m WHERE m.company_code = c.company_code) AS total_managers, 
       (SELECT COUNT(DISTINCT e.employee_code) FROM Employee e WHERE e.company_code = c.company_code) AS total_employees
FROM Company c
ORDER BY c.company_code;

------------------------------------------------------------------------------
-- refer query 2 for tables

SELECT Name
FROM Students s
JOIN Friends f on s.ID=f.ID
JOIN Packages p on f.ID=p.ID
JOIN packages p1 on f.Friend_ID=p1.ID
WHERE p.salary<p1.salary;

------------------------------------------------------------------------
-- task 20 Copy new data of one table to another (you do not have indicator for new data and old data)

INSERT INTO TargetTable
SELECT * FROM SourceTable
EXCEPT
SELECT * FROM TargetTable;
