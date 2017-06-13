-- if fk is not trusted then contraint does not help sql server during the execution
-- since there may be records missing in parent so sql server has to check everytime since the contratint is not trusted.

CREATE PROCEDURE dbo.usp_Find_Non_Integrity_FK_Vals 
   (@ParentSchemaName SYSNAME = 'dbo',
   @ParentTableName SYSNAME,
   @ChildSchemaName SYSNAME = 'dbo',
   @ChildTableName SYSNAME)
AS 
BEGIN 
   DECLARE @tsql VARCHAR(300)
   DECLARE @FKconstrName VARCHAR(50)

   SET NOCOUNT ON 

   -- get the foreign key constraint name from parent and child table names
   SELECT @FKconstrName = a.CONSTRAINT_NAME
   FROM 
       INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS a,
       INFORMATION_SCHEMA.KEY_COLUMN_USAGE b1,
       INFORMATION_SCHEMA.KEY_COLUMN_USAGE b2
   WHERE a.UNIQUE_CONSTRAINT_NAME = b1.CONSTRAINT_NAME AND 
       a.UNIQUE_CONSTRAINT_CATALOG = b1.CONSTRAINT_CATALOG AND 
       a.UNIQUE_CONSTRAINT_SCHEMA = b1.CONSTRAINT_SCHEMA AND 
       a.CONSTRAINT_NAME = b2.CONSTRAINT_NAME AND
       a.CONSTRAINT_CATALOG = b2.CONSTRAINT_CATALOG AND 
       a.CONSTRAINT_SCHEMA = b2.CONSTRAINT_SCHEMA AND
       b1.TABLE_NAME = @ParentTableName AND
       b2.TABLE_NAME = @ChildTableName AND
       b1.CONSTRAINT_SCHEMA = @ParentSchemaName AND
       b2.CONSTRAINT_SCHEMA = @ChildSchemaName
   
   -- construct a DBCC CHECKCONSTRAINTS TSQL 
   SET @tsql = 'DBCC CHECKCONSTRAINTS (' + '''' + @FKconstrName + '''' + ')'

   CREATE TABLE ##tmp (TName SYSNAME,
                       constName SYSNAME, 
                       whrClause VARCHAR(1000))

   -- EXEC TSQL Dynamically and get all integrity FK problems
   INSERT ##tmp EXEC (@tsql)

   -- output the results
   SELECT SUBSTRING (whrClause,1,
       CHARINDEX ('=',whrClause,1) - 1) AS FKcol,
       REPLACE (SUBSTRING (whrClause, 
       CHARINDEX ('=',whrClause,1) +1,
       LEN (whrClause) - CHARINDEX ('=',whrClause,1) - 1 ),'''','') AS FKval
   FROM ##tmp

   -- drop temporary table
   DROP TABLE ##tmp

END 
GO  