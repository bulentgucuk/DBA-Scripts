USE MYDATABASE -- CHANGE THE NAME OF THE DB
SET NOCOUNT ON
 
-- STORE FK DROP STATEMENT TO TABLE
SET NOCOUNT ON;
DECLARE @schema_name sysname;
DECLARE @table_name sysname;
DECLARE @constraint_name sysname;
DECLARE @constraint_object_id int;
DECLARE @referenced_object_name sysname;
DECLARE @is_disabled bit;
DECLARE @is_not_for_replication bit;
DECLARE @is_not_trusted bit;
DECLARE @delete_referential_action tinyint;
DECLARE @update_referential_action tinyint;
DECLARE @tsql nvarchar(4000);
DECLARE @tsql2 nvarchar(4000);
DECLARE @fkCol sysname;
DECLARE @pkCol sysname;
DECLARE @col1 bit;
DECLARE @action char(6);

SET @action = 'DROP';

--SET @action = 'CREATE';

-- STORE FK DROP statements to log table
IF EXISTS (
			SELECT	1
			FROM	SYS.Tables
			WHERE	Name = 'FKDrop'
			)
	BEGIN
		TRUNCATE TABLE dbo.FKDrop
		DROP TABLE dbo.FKDrop
	END

CREATE TABLE dbo.FKDrop (
	FKid INT IDENTITY (1,1),
	[Str] VARCHAR(1024) NOT NULL
	)

DECLARE FKcursor CURSOR FOR
    select OBJECT_SCHEMA_NAME(parent_object_id)
         , OBJECT_NAME(parent_object_id), name, OBJECT_NAME(referenced_object_id)
         , object_id
         , is_disabled, is_not_for_replication, is_not_trusted
         , delete_referential_action, update_referential_action
    from sys.foreign_keys
    order by 1,2;

OPEN FKcursor;

FETCH NEXT FROM FKcursor INTO @schema_name, @table_name, @constraint_name
    , @referenced_object_name, @constraint_object_id
    , @is_disabled, @is_not_for_replication, @is_not_trusted
    , @delete_referential_action, @update_referential_action;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @action <> 'CREATE'
        SET @tsql = 'ALTER TABLE '
                  + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)
                  + ' DROP CONSTRAINT ' + QUOTENAME(@constraint_name) + ';';
    ELSE
        BEGIN
        SET @tsql = 'ALTER TABLE '
                  + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)
                  + CASE @is_not_trusted
                        WHEN 0 THEN ' WITH CHECK '
                        ELSE ' WITH NOCHECK '
                    END
                  + ' ADD CONSTRAINT ' + QUOTENAME(@constraint_name)
                  + ' FOREIGN KEY ('
        SET @tsql2 = '';

        DECLARE ColumnCursor CURSOR FOR
            select COL_NAME(fk.parent_object_id, fkc.parent_column_id)
                 , COL_NAME(fk.referenced_object_id, fkc.referenced_column_id)
            from sys.foreign_keys fk
            inner join sys.foreign_key_columns fkc
            on fk.object_id = fkc.constraint_object_id
            where fkc.constraint_object_id = @constraint_object_id
            order by fkc.constraint_column_id;

        OPEN ColumnCursor;
        SET @col1 = 1;

        FETCH NEXT FROM ColumnCursor INTO @fkCol, @pkCol;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF (@col1 = 1)
                SET @col1 = 0
            ELSE
            BEGIN
                SET @tsql = @tsql + ',';
                SET @tsql2 = @tsql2 + ',';
            END;
            SET @tsql = @tsql + QUOTENAME(@fkCol);
            SET @tsql2 = @tsql2 + QUOTENAME(@pkCol);

            FETCH NEXT FROM ColumnCursor INTO @fkCol, @pkCol;
        END;
        CLOSE ColumnCursor;
        DEALLOCATE ColumnCursor;

        SET @tsql = @tsql + ' ) REFERENCES ' + QUOTENAME(@referenced_object_name)
                  + ' (' + @tsql2 + ')';
        SET @tsql = @tsql
                  + ' ON UPDATE ' + CASE @update_referential_action
                                        WHEN 0 THEN 'NO ACTION '
                                        WHEN 1 THEN 'CASCADE '
                                        WHEN 2 THEN 'SET NULL '
                                        ELSE 'SET DEFAULT '
                                    END
                  + ' ON DELETE ' + CASE @delete_referential_action
                                        WHEN 0 THEN 'NO ACTION '
                                        WHEN 1 THEN 'CASCADE '
                                        WHEN 2 THEN 'SET NULL '
                                        ELSE 'SET DEFAULT '
                                    END
                  + CASE @is_not_for_replication
                        WHEN 1 THEN ' NOT FOR REPLICATION '
                        ELSE ''
                    END
                  + ';';

        END;
		--PRINT @tsql;
		INSERT INTO dbo.FKDrop ([Str])
		SELECT	@tsql
    IF @action = 'CREATE'
        BEGIN
        SET @tsql = 'ALTER TABLE '
                  + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name)
                  + CASE @is_disabled
                        WHEN 0 THEN ' CHECK '
                        ELSE ' NOCHECK '
                    END
                  + 'CONSTRAINT ' + QUOTENAME(@constraint_name)
                  + ';';
        --PRINT @tsql;
        END;
    FETCH NEXT FROM FKcursor INTO @schema_name, @table_name, @constraint_name
        , @referenced_object_name, @constraint_object_id
        , @is_disabled, @is_not_for_replication, @is_not_trusted
        , @delete_referential_action, @update_referential_action;
END;

CLOSE FKcursor;

DEALLOCATE FKcursor;