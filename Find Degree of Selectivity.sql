--Finds the Degree of Selectivity for a Specific Column in a Row
Declare @total_unique float
Declare @total_rows float
Declare @selectivity_ratio float

SELECT @total_unique = 0
SELECT @total_rows = 0
SELECT @selectivity_ratio = 0

--Finds the Total Number of Unique Rows in a Table
--Be sure to replace OrderID below with the name of your column
--Be sure to replace [Order Details] below with your table name
SELECT @total_unique = (SELECT COUNT(DISTINCT OrderID) FROM [Order Details])

--Calculates Total Number of Rows in Table
--Be sure to replace [Order Details] below with your table name
SELECT @total_rows = (SELECT COUNT(*) FROM [Order Details])

--Calculates Selectivity Ratio for a Specific Column
SELECT @selectivity_ratio = ROUND((SELECT @total_unique/@total_rows),2,2)
SELECT @selectivity_ratio as 'Selectivity Ratio'