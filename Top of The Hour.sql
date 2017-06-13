

select DATEADD(HH, DATEDIFF(HH, 0, GETDATE()), 0)  -- current hour top of the hour

select DATEADD(HH, (DATEDIFF(HH, 0, GETDATE()))-2, 0)  -- 2 hours ago top of the hour