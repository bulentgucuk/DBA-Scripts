------------------------------------------------------------------------
-- Script:			sys2.indexes_per_table
-- Version:			1
-- Release Date:	2010-08-09
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_per_table		
-- Notes:			Display a list of all table along with information 
--					regarding presence of clustered and nonclustered 
--					indexes
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_per_table', 'V') IS NOT NULL)
	DROP VIEW sys2.indexes_per_table
GO

CREATE VIEW sys2.indexes_per_table
as
with cte as
(
	select 
		table_name = o.name,	
		o.[object_id],
		i.index_id,
		i.type,
		i.type_desc
	from 
		sys.indexes i
	inner join
		sys.objects o on i.[object_id] = o.[object_id]
	where
		o.type in ('U')
	and
		o.is_ms_shipped = 0 and i.is_disabled = 0  and i.is_hypothetical = 0 
	and
		i.type <= 2
), cte2 as
(
select
	*
from
	cte c
pivot
	(count(type) for type_desc in ([HEAP], [CLUSTERED], [NONCLUSTERED])) pv
)
select
	c2.table_name,
	[rows] = max(p.rows),
	is_heap = sum([HEAP]),
	is_clustered = sum([CLUSTERED]),
	num_of_nonclustered = sum([NONCLUSTERED])
from
	cte2 c2
inner join
	sys.partitions p on c2.[object_id] = p.[object_id] and c2.index_id = p.index_id
group by
	table_name
