with partitionedtables AS (
    SELECT DISTINCT 
        t.object_id,
        t.name AS table_name
    FROM sys.tables AS t
    JOIN sys.indexes AS si on t.object_id=si.object_id 
    JOIN sys.partition_schemes AS sc on si.data_space_id=sc.data_space_id
)
SELECT 
    pt.table_name,
    si.index_id,
    si.name AS index_name,
    ISNULL(pf.name, 'NonAligned') AS partition_function,
    ISNULL(sc.name, fg.name) AS partition_scheme_or_filegroup,
    ic.partition_ordinal, /* 0= not a partitioning column*/
    ic.key_ordinal,
    ic.is_included_column,
    c.name AS column_name,
    t.name AS data_type_name,
    c.is_identity,
    ic.is_descending_key,
    si.filter_definition
FROM partitionedtables AS pt
JOIN sys.indexes AS si on pt.object_id=si.object_id
JOIN sys.index_columns AS ic on si.object_id=ic.object_id
    and si.index_id=ic.index_id
JOIN sys.columns AS c on ic.object_id=c.object_id
    and ic.column_id=c.column_id
JOIN sys.types AS t on c.system_type_id=t.system_type_id
LEFT JOIN sys.partition_schemes AS sc on si.data_space_id=sc.data_space_id
LEFT JOIN sys.partition_functions AS pf on sc.function_id=pf.function_id
LEFT JOIN sys.filegroups as fg on si.data_space_id=fg.data_space_id
ORDER BY 1,2,3,4,5,6 DESC,7,8
GO