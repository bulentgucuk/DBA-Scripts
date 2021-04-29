/*
https://www.mssqltips.com/sqlservertip/2053/trick-to-optimize-top-clause-in-sql-server/
*/
USE tempdb;
GO
SET NOCOUNT ON
CREATE TABLE tab7 (c1 INT PRIMARY KEY CLUSTERED, c2 INT, c3 CHAR(2000))
GO

BEGIN TRAN
GO

DECLARE @i INT
SET @i=1
WHILE @i<=50000
BEGIN
   INSERT INTO tab7 VALUES (@i,RAND()*200000,'a')
   SET @i=@i+1
END 
COMMIT TRAN
GO

/***********************************************************************************/
/* Let's update the statistics with a full scan to make the optimizer work easier. */
/***********************************************************************************/
UPDATE STATISTICS tab7 WITH fullscan
GO

/***********************************************************************************/
/*						TEST 1									 */
/* Let's set statistics time on and execute the following query. */
/***********************************************************************************/

SET STATISTICS time ON
GO
--Source code provided by: www.sqlworkshops.com
SELECT num_of_reads, num_of_bytes_read,
num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1) 
GO

SELECT TOP 100 c1, c2,c3
FROM tab7
WHERE c1<30000
ORDER BY c2
GO

SELECT num_of_reads, num_of_bytes_read,
num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1)
GO

/*
The number of reads and writes on tempdb before and after the execution of our query are the same. This means that our query was able to complete the sort in memory without spilling to tempdb.
*/

/***********************************************************************************/
/*						TEST 2									 */

/* Now, lets execute the following query. Please note the new value in the TOP clause which was changed from 100 to 101. */
/***********************************************************************************/

SELECT num_of_reads, num_of_bytes_read,num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1) 
GO

SELECT TOP 101 c1, c2, c3
FROM tab7
WHERE c1<30000
ORDER BY c2
GO

SELECT num_of_reads, num_of_bytes_read,num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1)
GO

/*
The query runs much slower (726 ms).

The sort operation spilled over to tempdb, which we can see by the read/write values before and after execution of our query have increased.
*/

/***********************************************************************************/
/*				WAYS TO FIX THE PROBLEM					*/
/* If you are running SQL 2008 or later 64bit, the work around to make the sort happen in memory is to change the query, */
/* so the optimizer can allocate more memory allowing the sort operation to take place in memory as shown below. */
/***********************************************************************************/

SELECT TOP 101 c1, c2, CONVERT(VARCHAR(4500),c3)
FROM tab7
WHERE c1<30000
ORDER BY c2

/* If If you are running SQL 2005 or later TOP (@variable) does the trick.	*/

SELECT num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1)
GO

DECLARE @i INT
SET @i=101
SELECT TOP(@i) c1, c2, CONVERT(VARCHAR(5000),c3)
FROM tab7
WHERE c1<30000
ORDER BY c2
GO

SELECT num_of_reads, num_of_bytes_read,num_of_writes, num_of_bytes_written
FROM sys.dm_io_virtual_file_stats(DB_ID('tempdb'), 1)
GO	
