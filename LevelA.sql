/*
=========================================================
           SQL Queries Documentation - Northwind DB
=========================================================

Platform Used
---------------------------------------------------------
- Database System: Microsoft SQL Server (also works with MySQL/PostgreSQL/SQLite)
- Query Editor: SSMS
- Data Source: Northwind Sample Database (https://github.com/Microsoft/sql-server-samples)

Database: Northwind
---------------------------------------------------------
- Type: Relational Database
- Purpose: Sample trading company database used for learning SQL

Tables Used
---------------------------------------------------------
1. Customers           -- Customer contact details
2. Orders              -- Orders placed by customers
3. [Order Details]     -- Line items in each order (product, quantity, price)
4. Products            -- Product info with supplier and category
5. Suppliers           -- Information on product suppliers
6. Employees           -- Sales employees handling orders
7. Shippers            -- Shipping company data
8. Categories          -- Categories to which products belong
9. Region              -- Region info
10. Territories        -- Geographic territories
11. EmployeeTerritories -- Mapping of employees to territories

Query Features Used
---------------------------------------------------------
- Aggregate Functions: MAX, SUM, COUNT, AVG
- GROUP BY, HAVING, ORDER BY
- Joins: INNER JOIN, LEFT JOIN
- Subqueries and CTEs
- Window Functions: ROW_NUMBER()
- Filtering: WHERE, DISTINCT
- Top-N Logic: TOP, LIMIT (for other DBs)
- NULL Handling

*/

-- List of all customer
SELECT * 
FROM Customers;

--  List of all customers where company name ends in 'N'
SELECT * 
FROM Customers
WHERE CompanyName LIKE '%N';

-- List of all customers who live in Berlin or London
SELECT * 
FROM Customers
WHERE City IN ('Berlin', 'London');

-- List of all customers who live in UK or USA
SELECT * 
FROM Customers
WHERE Country IN ('UK', 'USA');

-- List of all products sorted by product name
SELECT * 
FROM Products
ORDER BY ProductName;

-- List of all products where product name starts with an 'A'
SELECT * 
FROM Products
WHERE ProductName LIKE 'A%';

-- List of customers who ever placed an order
SELECT DISTINCT c.CustomerID, c.CompanyName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID;

-- List of customers who live in London and have bought Chai
SELECT DISTINCT c.CustomerID, c.CompanyName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.City = 'London' AND p.ProductName = 'Chai';

-- List of customers who never placed an order
SELECT * 
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID FROM Orders
);

--  List of customers who ordered Tofu
SELECT DISTINCT c.CustomerID, c.CompanyName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'Tofu';

-- Details of first order of the system
SELECT TOP 1*
FROM Orders
ORDER BY OrderDate;

-- Find the details of the most expensive order date
SELECT TOP 1 o.OrderID, o.OrderDate, SUM(od.UnitPrice * od.Quantity) AS TotalAmount
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, o.OrderDate
ORDER BY TotalAmount DESC;

-- For each order get the OrderID and average quantity of items in that order
SELECT OrderID, AVG(Quantity) AS avg_quantity
FROM [Order Details]
GROUP BY OrderID;

-- For each order get the OrderID, minimum quantity, and maximum quantity for that order
SELECT OrderID, MIN(Quantity) AS MinQuantity, MAX(Quantity) AS MaxQuantity
FROM [Order Details]
GROUP BY OrderID;

-- Get a list of all managers and total number of employees who report to them
SELECT ReportsTo AS ManagerID, COUNT(*) AS NumEmployees
FROM Employees
WHERE ReportsTo IS NOT NULL
GROUP BY ReportsTo;

-- Get the OrderID and the total quantity for each order that has a total quantity of greater than 300
SELECT OrderID,SUM(Quantity) as total_quantity
FROM [Order Details]
GROUP BY OrderID
HAVING SUM(Quantity)>300;

-- List of all orders placed on or after 1996/12/31
SELECT * 
FROM Orders
WHERE OrderDate >= '1996-12-31';

--  List of all orders shipped to Canada
SELECT * 
FROM Orders
WHERE ShipCountry = 'Canada';

-- List of all orders with order total > 200
SELECT o.OrderID, SUM(od.UnitPrice * od.Quantity) AS OrderTotal
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY o.OrderID
HAVING SUM(od.UnitPrice * od.Quantity) > 200;

-- List of countries and sales made in each country
SELECT ShipCountry, SUM(od.UnitPrice * od.Quantity) AS TotalSales
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY ShipCountry;

-- List of Customer ContactName and number of orders they placed
SELECT c.ContactName, COUNT(o.OrderID) AS NumberOfOrders
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.ContactName;

-- List of customer contact names who have placed more than 3 orders
SELECT c.ContactName, COUNT(o.OrderID) AS NumberOfOrders
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.ContactName
HAVING COUNT(o.OrderID)>3;

-- List of discontinued products which were ordered between 1/1/1997 and 1/1/1998
SELECT DISTINCT p.ProductName
FROM Products p
JOIN [Order Details] od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
WHERE p.Discontinued = 1
  AND o.OrderDate BETWEEN '1997-01-01' AND '1998-01-01';

-- List of employee FirstName, LastName, Supervisor FirstName, LastName
SELECT e.FirstName AS EmployeeFirstName,
       e.LastName AS EmployeeLastName,
       s.FirstName AS SupervisorFirstName,
       s.LastName AS SupervisorLastName
FROM Employees e
LEFT JOIN Employees s ON e.ReportsTo = s.EmployeeID;

-- List of Employees ID and total sale conducted by employee
SELECT e.EmployeeID, SUM(od.UnitPrice * od.Quantity) AS TotalSales
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID;

-- List of employees whose FirstName contains character 'a'
SELECT * 
FROM Employees
WHERE FirstName LIKE '%a%';

-- List of managers who have more than four people reporting to them
SELECT ReportsTo AS ManagerID, COUNT(*) AS NumReports
FROM Employees
WHERE ReportsTo IS NOT NULL
GROUP BY ReportsTo
HAVING COUNT(*) > 4;

-- List of Orders and Product Names
SELECT o.OrderID, p.ProductName
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID;

-- List of orders placed by the best customer 
-- Assuming a Customer who have made a highest sale
WITH best_customer AS (
    SELECT TOP 1 o.CustomerID
    FROM Orders o
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
    ORDER BY SUM(od.UnitPrice * od.Quantity) DESC
)
SELECT DISTINCT p.ProductName
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN best_customer bc ON o.CustomerID = bc.CustomerID;


WITH CustomerSales AS (
    SELECT o.CustomerID, SUM(od.UnitPrice * od.Quantity) AS TotalSpent
    FROM Orders o
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
)
SELECT o.OrderID, o.CustomerID
FROM Orders o
JOIN CustomerSales cs ON o.CustomerID = cs.CustomerID
WHERE cs.TotalSpent = (
    SELECT MAX(TotalSpent) FROM CustomerSales
);

-- List of orders placed by customers who do not have a Fax number
SELECT o.*
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Fax IS NULL;

-- Show the order id and the total amount for each order
SELECT OrderID,SUM(UnitPrice*Quantity) as total_amount
FROM [Order Details]
GROUP BY OrderID;

-- List the customer and their most recent order date
WITH RankedOrders AS (
    SELECT c.CustomerID, c.ContactName, o.OrderDate,
           ROW_NUMBER() OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate DESC) AS rnk
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
)
SELECT CustomerID, ContactName, OrderDate
FROM RankedOrders
WHERE rnk = 1;
-- another way
SELECT c.ContactName, MAX(o.OrderDate) AS MostRecentOrder
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.ContactName;

-- List products that have never been ordered
SELECT p.ProductName
FROM Products p
LEFT JOIN [Order Details] od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL;

-- List the top 5 products with highest total sales amount
SELECT TOP 5 p.ProductName, SUM(od.UnitPrice * od.Quantity) AS TotalSales
FROM Products p
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales DESC;

-- Show the total number of orders placed in each year
SELECT YEAR(OrderDate) AS OrderYear, COUNT(*) AS TotalOrders
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;

-- Show the total sales amount by each employee
SELECT e.EmployeeID, e.FirstName, e.LastName, SUM(od.UnitPrice * od.Quantity) AS TotalSales
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;

-- List the product with the highest unit price
SELECT TOP 1 ProductName, UnitPrice
FROM Products
ORDER BY UnitPrice DESC;

-- List employees who have taken orders from Germany
SELECT DISTINCT e.EmployeeID, e.FirstName, e.LastName
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.Country = 'Germany';

-- List customers who ordered more than 5 different products
SELECT o.CustomerID
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT od.ProductID) > 5;

-- List the products along with the supplier name
SELECT p.ProductName, s.CompanyName AS SupplierName
FROM Products p
JOIN Suppliers s ON p.SupplierID = s.SupplierID;

-- Show the total number of products supplied by each supplier
SELECT s.CompanyName, COUNT(p.ProductID) AS TotalProducts
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.CompanyName;