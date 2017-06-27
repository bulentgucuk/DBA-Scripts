--TRUNCATE TABLE on stand-alone and child tables, or DELETE if it's a parent table:

-- disable referential integrity
EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
GO

EXEC sp_MSForEachTable '
 IF OBJECTPROPERTY(object_id(''?''), ''TableHasForeignRef'') = 1
  DELETE FROM ?
 else 
  TRUNCATE TABLE ?
'
GO

-- enable referential integrity again
EXEC sp_MSForEachTable 'ALTER TABLE ? CHECK CONSTRAINT ALL'
GO

