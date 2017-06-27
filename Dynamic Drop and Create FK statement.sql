SET NOCOUNT ON
SET XACT_ABORT ON
DECLARE	@DropCommand VARCHAR(500),
		@CreateCommand VARCHAR(500),
		@ConstraintName sysname,
		@ColumnName sysname

CREATE TABLE #TablesToMove (
	TableName sysname
	)

INSERT INTO #TablesToMove (TableName)
-- Insert into this table the names of the tables you need to affect.
--SELECT	OBJECT_SCHEMA_NAME(object_id) + '.' + name
SELECT	name
FROM	sys.tables
WHERE	is_ms_shipped = 0


CREATE TABLE #Instructions (
	ExecOrder INT IDENTITY,
	Command VARCHAR(500)
)

-- drop the foreign keys and log the recreation code.
DECLARE curForeignKeys CURSOR LOCAL FAST_FORWARD FOR
SELECT
'ALTER TABLE ' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) + ' WITH CHECK ADD CONSTRAINT ' + fk.name + ' FOREIGN KEY (' + ParentColumns.name + ') REFERENCES ' + OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) + ' (' + ReferencedColumns.name + ')' + CASE delete_referential_action WHEN 1 THEN ' ON DELETE CASCADE' ELSE '' END AS CreationCommand,
'ALTER TABLE ' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) + ' DROP CONSTRAINT ' + fk.name AS DropCommand
 FROM sys.foreign_keys fk INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
  INNER JOIN sys.columns ParentColumns ON fkc.parent_object_id = ParentColumns.OBJECT_ID AND fkc.parent_column_id = ParentColumns.column_id
  INNER JOIN sys.columns ReferencedColumns ON fk.referenced_object_id = ReferencedColumns.object_id AND fkc.referenced_column_id = ReferencedColumns.column_id
 WHERE OBJECT_NAME(fk.referenced_object_id) IN (SELECT TableName FROM #TablesToMove)
ORDER BY fk.referenced_object_id, fk.parent_object_id

OPEN curForeignKeys

FETCH NEXT FROM curForeignKeys INTO @CreateCommand, @DropCommand

WHILE @@FETCH_STATUS = 0
 BEGIN
  PRINT @DropCommand
  --EXECUTE (@DropCommand)
  INSERT INTO #Instructions (Command)
  VALUES (@CreateCommand)
  FETCH NEXT FROM curForeignKeys INTO @CreateCommand, @DropCommand
 END

CLOSE curForeignKeys
DEALLOCATE curForeignKeys

-- do whatever needs to be done here.

DECLARE curRecreate CURSOR LOCAL FAST_FORWARD FOR
 SELECT Command FROM #Instructions ORDER BY ExecOrder DESC

OPEN curRecreate
FETCH next FROM curRecreate INTO @CreateCommand

WHILE @@FETCH_STATUS=0
 BEGIN
  PRINT @CreateCommand
  --EXECUTE (@CreateCommand)
  FETCH next FROM curRecreate INTO @CreateCommand
 END

CLOSE curRecreate
DEALLOCATE curRecreate

DROP TABLE #TablesToMove
DROP TABLE #Instructions

SELECT * FROM #Instructions