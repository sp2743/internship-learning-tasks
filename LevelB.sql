/* Feature Used---
-- Stored Procedure: Inserting order details with validations
-- Optional Parameters Handling: NULL value defaults (UnitPrice, Discount)
-- Inventory Validation: Stock check before insert
-- Trigger Management: Prevent conflicting triggers (INSTEAD OF vs AFTER)
-- Error Handling: TRY...CATCH blocks
-- Transactions: BEGIN TRANSACTION, ROLLBACK for test cases
-- Conditional Logic: IF...ELSE branching
-- Return Codes: To indicate success, failure, or edge cases
-- Warnings: For stock dropping below reorder level
*/

USE [Northwind]
GO
/****** Object:  StoredProcedure [dbo].[InsertOrderDetails]    Script Date: 29-05-2025 10:47:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[InsertOrderDetails]
(
	@OrderID int,
	@ProductID int,
	@UnitPrice money=null,
	@Quantity smallint,
	@Discount real=null
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @stock smallint;
	DECLARE @ReorderLevel smallint;

	BEGIN TRY
		SELECT @stock=UnitsInStock,@ReorderLevel=ReorderLevel
		FROM Products
		WHERE ProductID=@ProductID;

		IF @stock IS NULL
		BEGIN
			PRINT 'Product not found. cannot proceed'
			RETURN 2;
		END

		IF @Quantity>@stock
		BEGIN
			PRINT 'Not enough stock available.Order aborted.';
			RETURN 4;
		END

		IF @UnitPrice IS NULL
		BEGIN
			SELECT @UnitPrice=UnitPrice
			FROM Products
			WHERE ProductID=@ProductID;
			
			IF @UnitPrice IS NULL
			BEGIN
				PRINT 'Product not found.Cannot fetch UnitPrice'
				RETURN 2;
			END
		END

		IF @Discount IS NULL
		BEGIN
			SET @Discount=0;
		END
		INSERT dbo.[Order Details] (OrderID,ProductID,UnitPrice,Quantity,Discount)
		VALUES (@OrderID,@ProductID,@UnitPrice,@Quantity,@Discount);

		IF @@ROWCOUNT=0
		BEGIN
			PRINT 'Failed to insert order';
			RETURN 1;
		END

		UPDATE Products
		SET UnitsInStock=UnitsInStock-@Quantity
		WHERE ProductID=@ProductID;

		-- check whether the stock is below reorder level or not. If it is then give a warning 
		IF @stock-@Quantity<@ReorderLevel
		BEGIN
			PRINT 'Warning Stock has dropped below reorder level!'
		END

		PRINT 'Order inserted and inventory updated successfully.';
		RETURN 0;
	END TRY
	BEGIN CATCH 
		PRINT 'An unexpected error occured!';
		RETURN 3;
	END CATCH
END
GO

EXEC InsertOrderDetails 10616, 11, 20.0, 5, 0.1;
-- OrderID+ProductID is a primary key. If you try to insert with same key,
-- it will show failed to place an order because the combination is already present in order details table.

EXEC InsertOrderDetails 10616, 5, NULL, 5, NULL;
-- Above details get saved in order details table as below. UnitPrice value is used from product table as it is null here
-- OrderID|ProductID|UnitPrice|Quantity|Discount
-- 10616  |5	    |21.35    |5       |0


BEGIN TRANSACTION;
-- table before update
SELECT * FROM [Order Details] WHERE OrderID = 10621;
SELECT * FROM Products WHERE ProductID=11;

EXEC InsertOrderDetails 10621, 11, NULL, 5, NULL;

-- table after update, View the result temporialy
SELECT * FROM [Order Details] WHERE OrderID = 10621;
SELECT * FROM Products WHERE ProductID=11;



-- Now undo the insert
ROLLBACK;



------------------------------------------------------------------------------------------------
GO
CREATE PROCEDURE UpdateOrderDetails
(
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT = NULL,
    @Discount REAL = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQuantity SMALLINT;
    DECLARE @NewQuantity SMALLINT;

    BEGIN TRY
        -- Get the current order details
        SELECT 
            @OldQuantity = Quantity
        FROM [Order Details]
        WHERE OrderID = @OrderID AND ProductID = @ProductID;

        IF @OldQuantity IS NULL
        BEGIN
            PRINT 'Order not found.';
            RETURN 1;
        END

        -- Update order details using ISNULL to preserve existing values if parameters are NULL
        UPDATE [Order Details]
        SET 
            UnitPrice = ISNULL(@UnitPrice, UnitPrice),
            Quantity = ISNULL(@Quantity, Quantity),
            Discount = ISNULL(@Discount, Discount)
        WHERE OrderID = @OrderID AND ProductID = @ProductID;

        -- Update UnitsInStock ONLY IF quantity changed
        IF @Quantity IS NOT NULL
        BEGIN
            SET @NewQuantity = @Quantity;
            -- Adjust inventory: add back old quantity, subtract new one
            UPDATE Products
            SET UnitsInStock = UnitsInStock + @OldQuantity - @NewQuantity
            WHERE ProductID = @ProductID;
        END

        PRINT 'Order updated successfully.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred while updating order.';
        RETURN 2;
    END CATCH
END
GO

-- Begin a transaction so changes can be rolled back for testing
BEGIN TRANSACTION;

-- View data before update
SELECT * FROM [Order Details] WHERE OrderID = 10248 AND ProductID = 1;
SELECT * FROM Products WHERE ProductID = 1;

-- Execute the update: changing quantity to 8, leaving other fields unchanged (NULL)
EXEC UpdateOrderDetails 
    @OrderID = 10248, 
    @ProductID = 1, 
    @UnitPrice = NULL,     
    @Quantity = 8,         
    @Discount = NULL;      

-- View data after update
SELECT * FROM [Order Details] WHERE OrderID = 10248 AND ProductID = 1;
SELECT * FROM Products WHERE ProductID = 1;

ROLLBACK;

-------------------------------------------------------------------------------------
GO
CREATE PROCEDURE GetOrderDetails
(
    @OrderID INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM [Order Details] WHERE OrderID = @OrderID
    )
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    -- If records exist, show the order details
    SELECT * FROM [Order Details] WHERE OrderID = @OrderID;
    RETURN 0;
END
GO


EXEC GetOrderDetails 10621;

EXEC GetOrderDetails 99999;

-------------------------------------------------------------------------------
GO
CREATE PROCEDURE DeleteOrderDetails
(
    @OrderID INT,
    @ProductID INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if both OrderID and ProductID exist as a pair
    IF NOT EXISTS (
        SELECT 1 FROM [Order Details]
        WHERE OrderID = @OrderID AND ProductID = @ProductID
    )
    BEGIN
        PRINT 'Invalid OrderID or ProductID for deletion.';
        RETURN -1;
    END

    -- Perform deletion
    DELETE FROM [Order Details]
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    PRINT 'Record deleted successfully.';
    RETURN 0;
END
GO


BEGIN TRANSACTION;
EXEC DeleteOrderDetails 10621, 19
ROLLBACK;

EXEC DeleteOrderDetails 10621, 999;

-----------------------------------------------------------------------

-- FUNCTION
GO
Create function fn_formatdate(@Inputdate DATETIME)
RETURNS varchar(10)
AS
BEGIN
     RETURN CONVERT(varchar(10),@Inputdate,101);
END
GO

SELECT dbo.fn_formatdate('2006-11-21 23:34:05.920') as FormatDate;
-- output 11/21/2006

GO
Create function fn_formatdate_YYYYMMDD(@Inputdate DATETIME)
RETURNS varchar(10)
AS
BEGIN
     RETURN CONVERT(varchar(10),@Inputdate,112);
END
GO

SELECT dbo.fn_formatdate_YYYYMMDD('2006-11-21 23:34:05.920') as FormatDate;
-- output 20061121

-------------------------------------------------------------------------------------
GO
Create View vWCustomerOrders
as 
SELECT CompanyName,o.OrderID,OrderDate,od.ProductID,ProductName,Quantity,od.UnitPrice,(Quantity*od.UnitPrice) as total_amount
FROM Customers c
JOIN Orders o on c.CustomerID=o.CustomerID
JOIN [Order Details] od on o.OrderID=od.OrderID
JOIN Products p on od.ProductID=p.ProductID;
GO 

SELECT * FROM vWCustomerOrders;

GO
CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT 
    c.CompanyName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS TotalPrice
FROM 
    Customers c
JOIN 
    Orders o ON c.CustomerID = o.CustomerID
JOIN 
    [Order Details] od ON o.OrderID = od.OrderID
JOIN 
    Products p ON od.ProductID = p.ProductID
WHERE 
    CAST(o.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
GO

SELECT * FROM dbo.vwCustomerOrders_Yesterday


GO
CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName AS SupplierName,
    c.CategoryName
FROM 
    Products p
JOIN 
    Suppliers s ON p.SupplierID = s.SupplierID
JOIN 
    Categories c ON p.CategoryID = c.CategoryID
WHERE 
    p.Discontinued = 0;
GO

SELECT * FROM dbo.MyProducts;

-----------------------------------------------------------------------

-- TRIGGER 
-- Create an INSTEAD OF DELETE trigger on the Orders table that:
-- First deletes related records from the Order Details table.
-- Then deletes the order from the Orders table
GO
CREATE TRIGGER trgInsteadOfDeleteOrders
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Delete related Order Details first
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    -- Now delete from Orders
    DELETE FROM Orders
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    PRINT 'Order and related Order Details deleted successfully.';
END;
GO

SELECT * FROM [Order Details] WHERE OrderID = 10616;
SELECT * FROM Orders WHERE OrderID = 10616

DELETE FROM Orders WHERE OrderID = 10616;

SELECT * FROM [Order Details] WHERE OrderID = 10616;
SELECT * FROM Orders WHERE OrderID = 10616;


-- Create a trigger on Order Details that:
-- Checks Products.UnitsInStock before inserting.
-- If stock is sufficient, insert the order and subtract quantity from stock.
-- If not, cancel the insert and notify the user.
GO
CREATE TRIGGER trgCheckStockBeforeInsert
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT, @Quantity SMALLINT, @OrderID INT;

    SELECT @ProductID = ProductID,
           @Quantity = Quantity,
           @OrderID = OrderID
    FROM INSERTED;

    DECLARE @CurrentStock SMALLINT;

    SELECT @CurrentStock = UnitsInStock
    FROM Products
    WHERE ProductID = @ProductID;

    IF @CurrentStock IS NULL
    BEGIN
        PRINT 'Product does not exist.';
        RETURN;
    END

    IF @CurrentStock < @Quantity
    BEGIN
        PRINT 'Insufficient stock. Order cannot be processed.';
        RETURN;
    END

    -- Sufficient stock exists; proceed with insert
    INSERT INTO [Order Details](OrderID, ProductID, UnitPrice, Quantity, Discount)
    SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
    FROM INSERTED;

    -- Update stock in Products table
    UPDATE Products
    SET UnitsInStock = UnitsInStock - @Quantity
    WHERE ProductID = @ProductID;

    PRINT 'Order inserted successfully and stock updated.';
END;
GO



