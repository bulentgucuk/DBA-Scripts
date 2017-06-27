--Find Column Name that exists in multiple tables
select	  c.table_name
		, c.column_name
from	information_schema.columns as c
	inner join information_schema.tables as t
		on t.table_name = c.table_name
where	c.column_name = 'applicationid'
and		t.table_type = 'base table'
order by c.table_name

