USE msdb
GO
EXEC dbo.sp_update_job_for_non_admins
     @job_name = N'ZZZ_Test_Job' -- the job name
   , @owner_login_name = 'SSBINFO\gholder' -- new owner in SSBINFO domain
   , @enabled = 1 ; -- 1 enable / 0 disable job
GO