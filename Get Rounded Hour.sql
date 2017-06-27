
-- get the hour rounded to the top of the hour
select DateAdd(hh, DateDiff(hh, 0, GetDate()), 0)

-- get the previous hour rounded to the top of the hour
select dateadd(hour,-1 ,(DateAdd(hh, DateDiff(hh, 0, GetDate()), 0)))
