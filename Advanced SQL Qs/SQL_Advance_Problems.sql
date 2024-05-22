/* 
 
----------Q.1----------

Create a function in your own database that takes two 
   parameters: 
1) A year parameter  
2) A month parameter 
   The function then calculates and returns the total sale  
   for the requested year and month. If there was no sale 
   for the requested period, returns 0. 
 
   Hints: a) Use the TotalDue column of the  
             Sales.SalesOrderHeader table in an 
             AdventureWorks database for 
             calculating the total sale. 
          b) The year and month parameters should use  
             the INT data type. 
          c) Make sure the function returns 0 if there 
             was no sale in the database for the requested 
             period. */

CREATE DATABASE Tot_sales;
USE Tot_sales;

CREATE FUNCTION dbo.TOT_SALES(@YEAR INT, @MONTH INT)
RETURNS FLOAT
AS 
BEGIN
	DECLARE @tot_sales FLOAT;
	(
	SELECT @tot_sales = SUM(soh.TotalDue)  
  	FROM [AdventureWorks2008R2].Sales.SalesOrderHeader AS soh
  	-- I included AdventureWorks to connect it to my database and retrieve information from AdventureWorks.
  	GROUP BY YEAR(soh.OrderDate), MONTH(soh.orderdate)
  	HAVING CAST(YEAR( soh.OrderDate) AS INT) = @YEAR AND CAST(MONTH(soh.OrderDate) AS INT)= @MONTH
  	)
    IF (@tot_sales IS NULL)
    BEGIN
    	SET @tot_sales = 0
    END
  	RETURN @tot_sales 
END;
SELECT dbo.TOT_SALES(2005,08) [Total Sales];
SELECT dbo.TOT_SALES(2012,08) [Total Sales];

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/* 

----------Q.2----------

Create a table in your own database using the following statement. 

CREATE TABLE DateRange 
(DateID INT IDENTITY,  
 DateValue DATE, 
 Month INT, 
 DayOfWeek INT); 
 
Write a stored procedure that accepts two parameters: 
1)  A starting date  
2)  The number of the consecutive dates beginning with the starting 
date 
The stored procedure then populates all columns of the 
DateRange table according to the two provided parameters */

USE Tot_sales;

DROP TABLE IF EXISTS DateRange;
--If we need new data only in the table, we need to drop table and create new one to avoid filling new data in same table.
--Otherwise we can run same execution again which will fill the data in existing table data

CREATE TABLE DateRange
(
DateID INT IDENTITY,
DateValue DATE, 
MONTH INT, 
DayOfWeek INT
)

DROP PROCEDURE dbo.fnDateRange;
--We can either drop the procedure to reset the procedure or use ALTER command to alter the procedure.

--We run procedure code
CREATE PROCEDURE fnDateRange(@Start_Date DATE, @Consec_Dates INT OUTPUT)
AS
BEGIN
     DECLARE @Counter INT = 0; 
     WHILE (@Counter < @Consec_Dates)
	 BEGIN
	    INSERT INTO DateRange
		VALUES
		(
		--@Counter + 1,
		DATEADD(DAY, @Counter, @Start_Date),
		MONTH(DATEADD(DAY, @Counter,@Start_Date)), 
        DAY(DATEADD(DAY, @Counter,@Start_Date))
		);
        SET @Counter += 1
	END
END
--We run execution code
EXEC fnDateRange @Start_Date = '2017-07-25', @Consec_Dates = 10
--We run selection code
SELECT * FROM DateRange;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/* 

----------Q.3----------

With three tables as defined below
 
Write a trigger to update the CustomerStatus column of Customer  
based on the total of OrderAmountBeforeTax for all orders  
placed by the customer. If the total exceeds 5,000, put Preferred 
in the CustomerStatus column. */ 

USE Tot_sales;

DROP TABLE dbo.Customer;
DROP TABLE dbo.SaleOrder;
DROP TABLE dbo.SaleOrderDetail;
-- dropping tables if empty dataset is desired.
DROP TRIGGER dbo.update_status;
--dropping and creating trigger to reset trigger

CREATE TABLE dbo.Customer
(
CustomerID VARCHAR(20) PRIMARY KEY,
CustomerLName VARCHAR(30),
CustomerFName VARCHAR(30),
CustomerStatus VARCHAR(10)
); 
 
CREATE TABLE dbo.SaleOrder
(
OrderID INT IDENTITY PRIMARY KEY,
CustomerID VARCHAR(20) REFERENCES Customer(CustomerID),
OrderDate DATE,
OrderAmountBeforeTax INT
);
 
CREATE TABLE dbo.SaleOrderDetail 
(
OrderID INT REFERENCES SaleOrder(OrderID), 
ProductID INT,
Quantity INT,
UnitPrice INT,
PRIMARY KEY (OrderID, ProductID)
);

-- Running the trigger creation code
CREATE TRIGGER dbo.update_status
ON dbo.SaleOrder
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @NewID INT;
	DECLARE @status_customer VARCHAR(10);
	DECLARE @AmountBTax FLOAT;
	SELECT @NewID = ins.CustomerID
	FROM INSERTED ins
	FULL JOIN DELETED del
		ON ins.customerid = del.customerid;

	SET @AmountBTax = ( SELECT SUM(OrderAmountBeforeTax) FROM dbo.SaleOrder WHERE CustomerID = @NewID);

	IF @AmountBTax > 5000
		SET @status_customer = 'Preffered'
	ELSE
		SET @status_customer = 'Normal'
UPDATE Customer set CustomerStatus = @status_customer
WHERE CustomerID = @NewID;
END;

--Inserting some value in customer table
INSERT into dbo.Customer VALUES ('1','Pranav','P','Normal');

--Inserting some values in SaleOrder table to see if trigger works after condition is checked
INSERT into dbo.SaleOrder VALUES ('1','1998-10-18',600);

SELECT * FROM dbo.Customer;

SELECT * FROM dbo.SaleOrder;

UPDATE dbo.SaleOrder SET OrderAmountBeforeTax = 1000
	WHERE orderid = 1 AND CustomerID = '1' AND OrderDate = '1998-10-18';

DELETE FROM dbo.SaleOrder WHERE orderid = 1 AND CustomerID = '1' AND OrderDate = '1998-10-18';

--Part 1

CREATE DATABASE PranavCP;

USE PranavCP;

Drop table if exists TargetCustomers;
Drop table if exists MailingLists;
 
CREATE TABLE TargetCustomers
(
	TargetId INT PRIMARY KEY IDENTITY NOT NULL,
	First_Name NVARCHAR(50)  NULL,
	Last_Name NVARCHAR(50)  NULL,
	Address NVARCHAR(50)  NULL,
	City NVARCHAR(50)  NULL,
	State NVARCHAR(50) NULL,
	ZipCode NVARCHAR(50) NULL
);


CREATE TABLE MailingLists
(
	MailingListId INT PRIMARY KEY IDENTITY NOT NULL,
	MailingList NVARCHAR(50)  NULL
);


CREATE TABLE TargetMailingLists
(
	TargetId INT NOT NULL,
	MailingListId INT NOT NULL,
	PRIMARY KEY (TargetId, MailingListId),
	FOREIGN KEY (TargetId) REFERENCES TargetCustomers(TargetId),
	FOREIGN KEY (MailingListId) REFERENCES MailingLists(MailingListId)
);

--Part 2

USE AdventureWorks2008R2;

/* Using the content of AdventureWorks, write a query to retrieve 
   all unique customers with all salespeople they have dealt with. 
   If a customer has never worked with a salesperson, make the 
   'Salesperson ID' column blank instead of displaying NULL. 
   Sort the returned data by CustomerID in the descending order. 
   The result should have the following format. 
 
   Hint: Use the SalesOrderHeadrer table. */


SELECT CustomerID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE customerID = 30118

SELECT
	soh2.CustomerID,
	STUFF
		(
			(
			SELECT DISTINCT ', ' + RTRIM(isnull(CAST(soh.SalesPersonID AS CHAR), ''))
			FROM Sales.SalesOrderHeader soh
			WHERE soh.CustomerID = soh2.CustomerID
			FOR XML PATH('')
			), 1, 2, ''
		) AS SalesPersonID 
From Sales.SalesOrderHeader soh2
GROUP BY soh2.CustomerID 
ORDER BY CustomerID DESC

SELECT DISTINCT c.CustomerID,
COALESCE( STUFF((SELECT  DISTINCT ', '+RTRIM(CAST(SalesPersonID AS char))  
       FROM Sales.SalesOrderHeader 
       WHERE CustomerID = c.customerid
       FOR XML PATH('')) , 1, 2, '') , '')  AS SalesPersons
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader oh 
	ON c.customerID = oh.CustomerID
ORDER BY c.CustomerID DESC;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/* 

----------Q.4----------

Using the content of AdventureWorks, write a query to retrieve the top five  
products for each year. Use OrderQty of SalesOrderDetail to calculate the total quantity sold. 
The top five products have the five highest sold quantities.  Also calculate the top five products'  
sold quantity for a year as a percentage of the total quantity sold for the year. */

WITH TEMP1 AS
	(
	SELECT 
		YEAR(soh.OrderDate) YEAR,
		SUM(sod.OrderQty) AS ttq,
		sod.ProductID, 
    		RANK() OVER (PARTITION BY YEAR(soh.OrderDate) ORDER BY SUM(sod.OrderQty) DESC) AS RANK
    	FROM Sales.SalesOrderDetail sod
   	JOIN Sales.SalesOrderHeader soh
    		ON sod.SalesOrderID=soh.SalesOrderID
   	GROUP BY YEAR(soh.OrderDate), sod.ProductID
    	)
SELECT
	TEMP1.YEAR,
	((CAST(SUM(ttq) AS FLOAT) / CAST(ttq1 AS FLOAT) ) * 100) AS [Percentage_of_Total_Sale],
	STUFF
		(
			(
			SELECT TOP 5  ', ' + RTRIM(CAST(ProductID AS CHAR))
			FROM Sales.SalesOrderDetail sod 
       			JOIN Sales.SalesOrderHeader soh
       				ON Sod.SalesOrderID=soh.SalesOrderID
       			WHERE YEAR(soh.OrderDate) = TEMP1.YEAR
       			GROUP BY ProductID
       			ORDER BY  SUM(OrderQty) DESC
       			FOR XML PATH('')
       			) , 1, 1, ''
       		) AS Top5Products
FROM TEMP1 
JOIN
(SELECT
	YEAR(soh.OrderDate) YEAR,
	SUM(sod.OrderQty) AS ttq1
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID=soh.SalesOrderID
    GROUP BY YEAR(soh.OrderDate)
) TEMP2
	ON TEMP1.YEAR = TEMP2.YEAR 
WHERE TEMP1.RANK <=5
GROUP BY TEMP1.YEAR, TEMP2.ttq1 
ORDER BY YEAR;

WITH Temp1 AS
   	(SELECT 
	YEAR(OrderDate) YEAR,
	ProductID, sum(OrderQty) ttl,
	RANK() OVER (PARTITION BY YEAR(OrderDate) ORDER BY sum(OrderQty) DESC) AS TopProduct
	FROM Sales.SalesOrderHeader sh
	JOIN Sales.SalesOrderDetail sd
		ON sh.SalesOrderID = sd.SalesOrderID
	GROUP BY YEAR(OrderDate), ProductID
	),
Temp2 AS
   	(SELECT YEAR(OrderDate) YEAR, sum(OrderQty) ttl
    	FROM Sales.SalesOrderHeader sh
	JOIN Sales.SalesOrderDetail sd
		ON sh.SalesOrderID = sd.SalesOrderID
    	GROUP BY YEAR(OrderDate)
	)
SELECT t1.YEAR, CAST(sum(t1.ttl) AS decimal) / t2.ttl * 100 [% of Total Sale],
STUFF((SELECT  ', '+RTRIM(CAST(ProductID AS char))  
       FROM temp1 
       WHERE Year = t1.YEAR AND TopProduct <=5
       FOR XML PATH('')) , 1, 2, '') AS Top5Products
FROM temp1 t1
JOIN temp2 t2
ON t1.YEAR = t2.YEAR
WHERE t1.TopProduct <= 5
GROUP BY t1.YEAR, t2.ttl;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/* 

----------Q.5----------

Year	Week Day	Monday	Tuesday	Wednesday Thursday Friday Saturday Sunday
2006	Total Sales						  8164751  6749180	
2007	Total Sales	6639424	5590523		  6379290	  9967385  10042829
2008	Total Sales				  5814991

*/

USE AdventureWorks2008R2;

SELECT datepart(yy, OrderDate) YEAR,
       datepart(dw, OrderDate) AS WeekDay,
       CAST(sum(TotalDue) AS int) AS TotalSales
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) BETWEEN 2006 AND 2008
GROUP BY datepart(dw, OrderDate),  datepart(yy, OrderDate)
HAVING sum(TotalDue) > 5500000

SELECT YEAR,'Total Sales', ISNULL([1], ' ') AS 'Monday' ,
			   ISNULL([2], ' ') AS 'Tuesday',
			   ISNULL([3], ' ') AS 'Wednesday',
			   ISNULL([4], ' ') AS 'Thursday',
			   ISNULL([5], ' ') AS 'Friday',
			   ISNULL([6], ' ') AS 'Saturday',
			   ISNULL([7], ' ') AS 'Sunday'
FROM
	(SELECT datepart(yy, OrderDate) YEAR,
	        datepart(dw, OrderDate) AS WeekDay,
	        CAST(sum(TotalDue) AS int) AS TotalSales
	FROM Sales.SalesOrderHeader
	WHERE YEAR(OrderDate) BETWEEN 2006 AND 2008
	GROUP BY datepart(dw, OrderDate),  datepart(yy, OrderDate)
	HAVING sum(TotalDue) > 5500000
	) AS SourceTable
PIVOT
(
	SUM(TotalSales)
	FOR WeekDay
	IN ([1], [2], [3], [4], [5], [6], [7])

) AS PivotTable
	
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/*

----------Q.6----------

Using AdventureWorks2008R2, write a query to retrieve 
the order years and their order info.

Return the year, a year's total sales, the top 3 
order values of a year, and the total of the top 3 
order values as a percentage of a year's total sales.

The top 3 order values are the 3 highest order values. 
Use TotalDue in SalesOrderHeader as the order value. 
Please keep in mind it's the order value and several orders 
may have the same value. 

Return only the top 2 years. The top 2 years have the 2 highest
total sales. If there is a tie, the tie needs to be retrieved.

Sort the returned data by year. Return the data in
the format specified below.
*/

/*
Year	TotalSales	Top 3 Order Values			Percentage
2006	34463848	170512.67, 166537.08, 165028.75		1.45
2007	47171490	187487.83, 182018.63, 145454.37		1.09
*/

USE AdventureWorks2008R2;

WITH TEMP AS
(
SELECT 
	YEAR(soh.OrderDate) YEAR,
	ProductID,
	SOH.TotalDue AS 'TTQ',
	DENSE_RANK() OVER (Partition BY YEAR(soh.OrderDate) ORDER BY SOH.TotalDue DESC) AS 'Rank'
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH
	ON SOD.SalesOrderID=SOH.SalesOrderID
GROUP BY YEAR(soh.OrderDate), SOD.ProductID, SOH.TotalDue
)
SELECT 
	TEMP.YEAR,
	TTQ1 AS [TotSales],
	(( CAST(SUM(TTQ) AS FLOAT)  / CAST(TTQ1 AS FLOAT) ) * 100 ) AS 'Percentage',
	STUFF(
		(
		SELECT TOP 3  ', '+RTRIM(CAST(SOH.TotalDue AS char))  
		FROM Sales.SalesOrderDetail SOD 
		JOIN Sales.SalesOrderHeader SOH
			ON SOD.SalesOrderID=SOH.SalesOrderID
		WHERE YEAR(soh.OrderDate) = TEMP.YEAR
		GROUP BY SOH.TotalDue
		ORDER BY  SOH.TotalDue  DESC
		FOR XML PATH('')
		) , 1, 1, ''
	     ) AS 'Top3Order Values'
FROM TEMP 
JOIN 
(SELECT YEAR(soh.OrderDate) YEAR, SUM(SOH.TotalDue) AS 'TTQ1'
 FROM Sales.SalesOrderHeader SOH
GROUP BY YEAR(soh.OrderDate)) B
ON TEMP.YEAR =B.YEAR 
WHERE TEMP.Rank <=3
GROUP BY TEMP.YEAR,B.TTQ1 
ORDER BY TEMP.YEAR;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/*

----------Q.7----------

Leetcode Problem 362

*/

SELECT '[0-5>' AS bin, SUM duration/60 < 5) AS 'total'
FROM Sessions
UNION
SELECT '[5-103' AS bin, SUM duration/60 > 5 AND duration/60 < 10) AS 'total'
FROM Sessions
UNION
SELECT ' [10-15>' AS bin, SUM duration/60 > 10 AND duration/60 < 15) AS 'total'
FROM Sessions
UNION
SELECT '15 or more' AS bin, SUM duration/60 > 15) AS 'total'
FROM Sessions;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/*

----------Q.8----------

Leetcode Problem 454

*/

SELECT product_id,
SUM(CASE WHEN store = 'storel' THEN price END AS store1,
SUM(CASE WHEN store = 'store2' THEN price END AS store2,
SUM CASE WHEN store = 'store3' THEN price END AS store3
FROM Products
GROUP BY product_id

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/*

----------Q.9----------

Leetcode Problem 460

*/

SELECT 	view.product_id,
	view.store,
	view.price
FROM(	SELECT product_id, 'storel' AS store, storel AS price FROM Products
	UNION ALL
	SELECT product_id, 'store2' AS store, store AS price FROM Products
	UNION ALL
	SELECT product_id, 'store3' AS store, store3 AS price FROM Products
	) AS view
WHERE view.price IS NOT NULL;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

/*

----------Q.9----------

Leetcode Problem

*/


