use msdb
go

select j.name, js.step_id,js.step_name, js.output_file_name
, CONCAT ('EXEC dbo.sp_update_jobstep @job_name = N', '''', j.name, '''', ',', ' @step_id = ' , js.step_id, ',', '@output_file_name = ', '''', '$(ESCAPE_SQUOTE(SQLLOGDIR))\$(ESCAPE_SQUOTE(JOBNAME))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(DATE))_$(ESCAPE_SQUOTE(TIME)).txt', '''', ';'  )
from	dbo.sysjobsteps as js
inner join dbo.sysjobs as j on j.job_id = js.job_id
where js.output_file_name is not null
order by j.name

