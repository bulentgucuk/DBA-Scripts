-- This resturn datetime starting at the midnight
DECLARE @Today DATETIME
SET		@Today = GETDATE() --'2008-04-11 01:26:54.000'
SELECT CAST(FLOOR(CAST(@TODAY AS FLOAT)) AS DATETIME) 
