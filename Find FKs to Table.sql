-- Enable, Disable, Drop and Recreate FKs based on Primary Key table 
-- Written 2007-11-18 
-- Edgewood Solutions / MSSQLTips.com 
-- Works for SQL Server 2005 

SET NOCOUNT ON 

DECLARE @operation VARCHAR(10) 
DECLARE @tableName sysname 
DECLARE @schemaName sysname 

SET @operation = 'drop' --ENABLE, DISABLE, DROP 
SET @tableName = 'ReportRole' 
SET @schemaName = 'REPORTS' 

DECLARE @cmd NVARCHAR(1000)

DECLARE  
   @FK_NAME sysname, 
   @FK_OBJECTID INT, 
   @FK_DISABLED INT, 
   @FK_NOT_FOR_REPLICATION INT, 
   @DELETE_RULE    smallint,    
   @UPDATE_RULE    smallint,    
   @FKTABLE_NAME sysname, 
   @FKTABLE_OWNER sysname, 
   @PKTABLE_NAME sysname, 
   @PKTABLE_OWNER sysname, 
   @FKCOLUMN_NAME sysname, 
   @PKCOLUMN_NAME sysname, 
   @CONSTRAINT_COLID INT 


DECLARE cursor_fkeys CURSOR FOR  
   SELECT  Fk.name, 
           Fk.OBJECT_ID,  
           Fk.is_disabled,  
           Fk.is_not_for_replication,  
           Fk.delete_referential_action,  
           Fk.update_referential_action,  
           OBJECT_NAME(Fk.parent_object_id) AS Fk_table_name,  
           schema_name(Fk.schema_id) AS Fk_table_schema,  
           TbR.name AS Pk_table_name,  
           schema_name(TbR.schema_id) Pk_table_schema 
   FROM    sys.foreign_keys Fk LEFT OUTER JOIN  
           sys.tables TbR ON TbR.OBJECT_ID = Fk.referenced_object_id --inner join  
   WHERE   TbR.name = @tableName 
           AND schema_name(TbR.schema_id) = @schemaName 

OPEN cursor_fkeys 

FETCH NEXT FROM   cursor_fkeys  
   INTO @FK_NAME,@FK_OBJECTID, 
       @FK_DISABLED, 
       @FK_NOT_FOR_REPLICATION, 
       @DELETE_RULE,    
       @UPDATE_RULE,    
       @FKTABLE_NAME, 
       @FKTABLE_OWNER, 
       @PKTABLE_NAME, 
       @PKTABLE_OWNER 

WHILE @@FETCH_STATUS = 0  
BEGIN  

   -- create statement for enabling FK 
   IF @operation = 'ENABLE'  
   BEGIN 
       SET @cmd = 'ALTER TABLE [' + @FKTABLE_OWNER + '].[' + @FKTABLE_NAME  
           + ']  CHECK CONSTRAINT [' + @FK_NAME + ']' 

      PRINT @cmd 
   END 

   -- create statement for disabling FK 
   IF @operation = 'DISABLE' 
   BEGIN    
       SET @cmd = 'ALTER TABLE [' + @FKTABLE_OWNER + '].[' + @FKTABLE_NAME  
           + ']  NOCHECK CONSTRAINT [' + @FK_NAME + ']' 

      PRINT @cmd 
   END 

   -- create statement for dropping FK and also for recreating FK 
   IF @operation = 'DROP' 
   BEGIN 

       -- drop statement 
       SET @cmd = 'ALTER TABLE [' + @FKTABLE_OWNER + '].[' + @FKTABLE_NAME  
       + ']  DROP CONSTRAINT [' + @FK_NAME + ']'    

      PRINT @cmd 

       -- create process 
       DECLARE @FKCOLUMNS VARCHAR(1000), @PKCOLUMNS VARCHAR(1000), @COUNTER INT 

       -- create cursor to get FK columns 
       DECLARE cursor_fkeyCols CURSOR FOR  
       SELECT  COL_NAME(Fk.parent_object_id, Fk_Cl.parent_column_id) AS Fk_col_name,  
               COL_NAME(Fk.referenced_object_id, Fk_Cl.referenced_column_id) AS Pk_col_name 
       FROM    sys.foreign_keys Fk LEFT OUTER JOIN  
               sys.tables TbR ON TbR.OBJECT_ID = Fk.referenced_object_id INNER JOIN  
               sys.foreign_key_columns Fk_Cl ON Fk_Cl.constraint_object_id = Fk.OBJECT_ID  
       WHERE   TbR.name = @tableName 
               AND schema_name(TbR.schema_id) = @schemaName 
               AND Fk_Cl.constraint_object_id = @FK_OBJECTID -- added 6/12/2008 
       ORDER BY Fk_Cl.constraint_column_id 

       OPEN cursor_fkeyCols 

       FETCH NEXT FROM    cursor_fkeyCols INTO @FKCOLUMN_NAME,@PKCOLUMN_NAME 

       SET @COUNTER = 1 
       SET @FKCOLUMNS = '' 
       SET @PKCOLUMNS = '' 
        
       WHILE @@FETCH_STATUS = 0  
       BEGIN  

           IF @COUNTER > 1  
           BEGIN 
               SET @FKCOLUMNS = @FKCOLUMNS + ',' 
               SET @PKCOLUMNS = @PKCOLUMNS + ',' 
           END 

           SET @FKCOLUMNS = @FKCOLUMNS + '[' + @FKCOLUMN_NAME + ']' 
           SET @PKCOLUMNS = @PKCOLUMNS + '[' + @PKCOLUMN_NAME + ']' 

           SET @COUNTER = @COUNTER + 1 
            
           FETCH NEXT FROM    cursor_fkeyCols INTO @FKCOLUMN_NAME,@PKCOLUMN_NAME 
       END 

       CLOSE cursor_fkeyCols  
       DEALLOCATE cursor_fkeyCols  

       -- generate create FK statement 
       SET @cmd = 'ALTER TABLE [' + @FKTABLE_OWNER + '].[' + @FKTABLE_NAME + ']  WITH ' +  
           CASE @FK_DISABLED  
               WHEN 0 THEN ' CHECK ' 
               WHEN 1 THEN ' NOCHECK ' 
           END +  ' ADD CONSTRAINT [' + @FK_NAME  
           + '] FOREIGN KEY (' + @FKCOLUMNS  
           + ') REFERENCES [' + @PKTABLE_OWNER + '].[' + @PKTABLE_NAME + '] ('  
           + @PKCOLUMNS + ') ON UPDATE ' +  
           CASE @UPDATE_RULE  
               WHEN 0 THEN ' NO ACTION ' 
               WHEN 1 THEN ' CASCADE '  
               WHEN 2 THEN ' SET_NULL '  
               END + ' ON DELETE ' +  
           CASE @DELETE_RULE 
               WHEN 0 THEN ' NO ACTION '  
               WHEN 1 THEN ' CASCADE '  
               WHEN 2 THEN ' SET_NULL '  
               END + '' + 
           CASE @FK_NOT_FOR_REPLICATION 
               WHEN 0 THEN '' 
               WHEN 1 THEN ' NOT FOR REPLICATION ' 
           END 

      PRINT @cmd 

   END 

   FETCH NEXT FROM    cursor_fkeys  
      INTO @FK_NAME,@FK_OBJECTID, 
           @FK_DISABLED, 
           @FK_NOT_FOR_REPLICATION, 
           @DELETE_RULE,    
           @UPDATE_RULE,    
           @FKTABLE_NAME, 
           @FKTABLE_OWNER, 
           @PKTABLE_NAME, 
           @PKTABLE_OWNER 
END 

CLOSE cursor_fkeys  
DEALLOCATE cursor_fkeys  