-- Find Duplicate and Overlapping Indexes
DECLARE	@SchemaName SYSNAME,
		@TableName SYSNAME;
SELECT	@SchemaName = '',
		@TableName = '' -- CHANGE THE TABLE NAME OR PASS EMPTY STRING FOR ALL 
;WITH MyDuplicate AS (SELECT
Sch.[name] AS SchemaName,
Obj.[name] AS TableName,
Idx.[name] AS IndexName,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 1) AS Col1,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 2) AS Col2,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 3) AS Col3,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 4) AS Col4,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 5) AS Col5,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 6) AS Col6,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 7) AS Col7,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 8) AS Col8,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 9) AS Col9,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 10) AS Col10,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 11) AS Col11,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 12) AS Col12,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 13) AS Col13,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 14) AS Col14,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 15) AS Col15,
INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 16) AS Col16
FROM sys.indexes Idx
INNER JOIN sys.objects Obj ON Idx.[object_id] = Obj.[object_id]
INNER JOIN sys.schemas Sch ON Sch.[schema_id] = Obj.[schema_id]
WHERE index_id > 0
AND Sch.name LIKE CASE WHEN @SchemaName='' THEN Sch.name ELSE @SchemaName END
--AND	(Sch.name = @SchemaName OR Sch.name = Sch.name)
--AND	(Obj.object_id = object_id(@TableName) OR Obj.object_id = Obj.schema_id)
AND Obj.name LIKE CASE WHEN @TableName='' THEn Obj.name ELSE @TableName END
)
SELECT    MD1.SchemaName, MD1.TableName, MD1.IndexName,
MD2.IndexName AS OverLappingIndex,
MD1.Col1, MD1.Col2, MD1.Col3, MD1.Col4,
MD1.Col5, MD1.Col6, MD1.Col7, MD1.Col8,
MD1.Col9, MD1.Col10, MD1.Col11, MD1.Col12,
MD1.Col13, MD1.Col14, MD1.Col15, MD1.Col16
FROM MyDuplicate MD1
INNER JOIN MyDuplicate MD2 ON MD1.tablename = MD2.tablename AND MD1.SchemaName = MD2.SchemaName
AND MD1.indexname <> MD2.indexname
AND MD1.Col1 = MD2.Col1
AND (MD1.Col2 IS NULL OR MD2.Col2 IS NULL OR MD1.Col2 = MD2.Col2)
AND (MD1.Col3 IS NULL OR MD2.Col3 IS NULL OR MD1.Col3 = MD2.Col3)
AND (MD1.Col4 IS NULL OR MD2.Col4 IS NULL OR MD1.Col4 = MD2.Col4)
AND (MD1.Col5 IS NULL OR MD2.Col5 IS NULL OR MD1.Col5 = MD2.Col5)
AND (MD1.Col6 IS NULL OR MD2.Col6 IS NULL OR MD1.Col6 = MD2.Col6)
AND (MD1.Col7 IS NULL OR MD2.Col7 IS NULL OR MD1.Col7 = MD2.Col7)
AND (MD1.Col8 IS NULL OR MD2.Col8 IS NULL OR MD1.Col8 = MD2.Col8)
AND (MD1.Col9 IS NULL OR MD2.Col9 IS NULL OR MD1.Col9 = MD2.Col9)
AND (MD1.Col10 IS NULL OR MD2.Col10 IS NULL OR MD1.Col10 = MD2.Col10)
AND (MD1.Col11 IS NULL OR MD2.Col11 IS NULL OR MD1.Col11 = MD2.Col11)
AND (MD1.Col12 IS NULL OR MD2.Col12 IS NULL OR MD1.Col12 = MD2.Col12)
AND (MD1.Col13 IS NULL OR MD2.Col13 IS NULL OR MD1.Col13 = MD2.Col13)
AND (MD1.Col14 IS NULL OR MD2.Col14 IS NULL OR MD1.Col14 = MD2.Col14)
AND (MD1.Col15 IS NULL OR MD2.Col15 IS NULL OR MD1.Col15 = MD2.Col15)
AND (MD1.Col16 IS NULL OR MD2.Col16 IS NULL OR MD1.Col16 = MD2.Col16)
ORDER BY MD1.SchemaName,MD1.TableName,MD1.IndexName
