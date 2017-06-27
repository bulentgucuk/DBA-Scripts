USE msdb;
GO
DECLARE @weekDay TABLE
	(
		mask INT
		, maskValue VARCHAR(32)
	);

INSERT INTO @weekDay
		SELECT 1
				, 'Sunday'
		UNION ALL
		SELECT 2
				, 'Monday'
		UNION ALL
		SELECT 4
				, 'Tuesday'
		UNION ALL
		SELECT 8
				, 'Wednesday'
		UNION ALL
		SELECT 16
				, 'Thursday'
		UNION ALL
		SELECT 32
				, 'Friday'
		UNION ALL
		SELECT 64
				, 'Saturday';

WITH	myCTE
			AS ( SELECT sched.name AS 'scheduleName'
							, sched.enabled AS SchedEnabled
							, sched.schedule_id
							, jobsched.job_id
							, CASE	WHEN sched.freq_type = 1 THEN 'Once'
									WHEN sched.freq_type = 4
											AND sched.freq_interval = 1
									THEN 'Daily'
									WHEN sched.freq_type = 4
									THEN 'Every '
											+ CAST(sched.freq_interval AS VARCHAR(5))
											+ ' days'
									WHEN sched.freq_type = 8
									THEN REPLACE(REPLACE(REPLACE(( SELECT maskValue
																FROM @weekDay AS x
																WHERE sched.freq_interval
																& x.mask <> 0
																ORDER BY mask
																FOR
																XML RAW
																),
																'"/><row maskValue="',
																', '),
															'<row maskValue="',
															''), '"/>', '')
											+ CASE	WHEN sched.freq_recurrence_factor <> 0
															AND sched.freq_recurrence_factor = 1
													THEN '; weekly'
													WHEN sched.freq_recurrence_factor <> 0
													THEN '; every '
															+ CAST(sched.freq_recurrence_factor AS VARCHAR(10))
															+ ' weeks'
												END
									WHEN sched.freq_type = 16
									THEN 'On day '
											+ CAST(sched.freq_interval AS VARCHAR(10))
											+ ' of every '
											+ CAST(sched.freq_recurrence_factor AS VARCHAR(10))
											+ ' months'
									WHEN sched.freq_type = 32
									THEN CASE	WHEN sched.freq_relative_interval = 1
												THEN 'First'
												WHEN sched.freq_relative_interval = 2
												THEN 'Second'
												WHEN sched.freq_relative_interval = 4
												THEN 'Third'
												WHEN sched.freq_relative_interval = 8
												THEN 'Fourth'
												WHEN sched.freq_relative_interval = 16
												THEN 'Last'
											END
											+ CASE	WHEN sched.freq_interval = 1
													THEN ' Sunday'
													WHEN sched.freq_interval = 2
													THEN ' Monday'
													WHEN sched.freq_interval = 3
													THEN ' Tuesday'
													WHEN sched.freq_interval = 4
													THEN ' Wednesday'
													WHEN sched.freq_interval = 5
													THEN ' Thursday'
													WHEN sched.freq_interval = 6
													THEN ' Friday'
													WHEN sched.freq_interval = 7
													THEN ' Saturday'
													WHEN sched.freq_interval = 8
													THEN ' Day'
													WHEN sched.freq_interval = 9
													THEN ' Weekday'
													WHEN sched.freq_interval = 10
													THEN ' Weekend'
												END
											+ CASE	WHEN sched.freq_recurrence_factor <> 0
															AND sched.freq_recurrence_factor = 1
													THEN '; monthly'
													WHEN sched.freq_recurrence_factor <> 0
													THEN '; every '
															+ CAST(sched.freq_recurrence_factor AS VARCHAR(10))
															+ ' months'
												END
									WHEN sched.freq_type = 64 THEN 'StartUp'
									WHEN sched.freq_type = 128 THEN 'Idle'
								END AS Frequency
							, ISNULL('Every '
										+ CAST(sched.freq_subday_interval AS VARCHAR(10))
										+ CASE	WHEN sched.freq_subday_type = 2
												THEN ' seconds'
												WHEN sched.freq_subday_type = 4
												THEN ' minutes'
												WHEN sched.freq_subday_type = 8
												THEN ' hours'
											END, 'Once') AS SubFrequency
							, REPLICATE('0', 6 - LEN(sched.active_start_time))
							+ CAST(sched.active_start_time AS VARCHAR(6)) AS start_time
							, REPLICATE('0', 6 - LEN(sched.active_end_time))
							+ CAST(sched.active_end_time AS VARCHAR(6)) AS end_time
							, REPLICATE('0', 6 - LEN(jobsched.next_run_time))
							+ CAST(jobsched.next_run_time AS VARCHAR(6)) AS next_run_time
							, CAST(jobsched.next_run_date AS CHAR(8)) AS next_run_date
						FROM msdb.dbo.sysschedules AS sched
							INNER JOIN msdb.dbo.sysjobschedules AS jobsched
								ON sched.schedule_id = jobsched.schedule_id
						WHERE sched.enabled = 1
				)
	SELECT j.name AS JobName
			, j.enabled
			, j.category_id
			, sp.name AS JobOwner
			, c.name
			, c.category_class
			, js.step_id
			, js.step_name
			, js.subsystem
			, js.command
			, js.database_name
			, js.database_user_name
			, ct.next_run_date
			, ct.next_run_time
			, ct.start_time
			, ct.end_time
			, ct.Frequency
			, ct.SubFrequency
			, ct.scheduleName AS ScheduleName
			, ct.SchedEnabled--, ss.
		FROM dbo.sysjobs j
			INNER JOIN dbo.sysjobsteps js
				ON j.job_id = js.job_id
			INNER JOIN dbo.syscategories c
				ON j.category_id = c.category_id
			INNER JOIN sys.server_principals sp
				ON j.owner_sid = sp.sid
			INNER JOIN myCTE ct
				ON ct.job_id = j.job_id;