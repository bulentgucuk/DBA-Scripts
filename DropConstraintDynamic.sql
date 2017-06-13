-- Drop Constraint Dynamic
declare	@ConstraintToBeDropped varchar (100),
		@Sql varchar (1000)
-- get the constraint name
select	@ConstraintToBeDropped = Constraint_Name 
from	information_schema.key_column_usage
where	table_name = 'VisitorPageHits'
and		column_name = 'pageid'

-- assign value to dynamic sql statement
select	@Sql = 'alter table dbo.visitorpagehits drop constraint ' + @ConstraintToBeDropped

-- execute and drop the constraint
print	@sql
exec	(@sql)