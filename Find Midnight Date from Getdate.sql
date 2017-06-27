-- Note: Methods 2 and 5 will work from version 2008 onwards and Method 4 depends on the language of the session.
declare @date datetime
set @date= GETDATE()
select
dateadd(day,datediff(day,0,@date),0),           --Method 1
cast(@date as date),                            --Method 2
cast(convert(char(8),@date,112) as datetime),   --Method 3
cast(cast(@date as varchar(11)) as datetime),   --Method 4
@date-cast(cast(@date as time) as datetime),    --Method 5
@date-convert(char(10),@date,108)				--Method 6


select CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)