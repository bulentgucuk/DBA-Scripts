CREATE FUNCTION dbo.udf_Convert_Int_Time (@time_in INT)
RETURNS VARCHAR(8)
AS
BEGIN
DECLARE @time_out VARCHAR(8)
SELECT @time_out =
CASE LEN(@time_in)
WHEN 6 THEN LEFT(CAST(@time_in AS VARCHAR(6)),2) + ':' + SUBSTRING(CAST(@time_in AS VARCHAR(6)), 3,2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2)
WHEN 5 THEN '0' + LEFT(CAST(@time_in AS VARCHAR(6)),1) + ':' + SUBSTRING(CAST(@time_in AS VARCHAR(6)), 2,2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2)
WHEN 4 THEN '00' + ':' + LEFT(CAST(@time_in AS VARCHAR(6)),2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2)
ELSE '00:00:00' --midnight
END --AS converted_time
RETURN @time_out
END
GO


/********
SELECT SJ.[name], SJH.[run_date],
   dbo.udf_convert_int_time(SJH.[run_time]) AS run_time
FROM msdb.dbo.[sysjobhistory] SJH 
   INNER JOIN [msdb].dbo.[sysjobs] SJ ON SJH.[job_id] = SJ.[job_id] 
WHERE SJH.[step_id] = 0 
ORDER BY SJ.[name]
GO

********/