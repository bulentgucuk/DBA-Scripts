USE msdb;

DECLARE @operator NVARCHAR(128);
DECLARE @emailAddress NVARCHAR(128);
DECLARE @pagerAddress NVARCHAR(128);

SELECT
    @operator = ParmValue
FROM
    DBAdmin.dbo.DBAdmin_InstallParms
WHERE ParmName = 'JobPageOperator'

SELECT
    @emailAddress =
        CASE @operator
            WHEN 'QA Group' THEN N'QA_DBA@insurancequotes.com'
            WHEN 'DBA Group' THEN N'DBAAlerts@insurancequotes.com'
        ELSE N'DBAAlerts@insurancequotes.com'
        END

SELECT @pagerAddress = @emailAddress;

IF NOT EXISTS (SELECT * FROM [msdb].[dbo].[sysoperators] WHERE name = @operator)
BEGIN
    EXEC [msdb].[dbo].[sp_add_operator]
        @name = @operator,
        @email_address = @emailAddress,
        @pager_address = @pagerAddress,
        @weekday_pager_start_time = 000000,
        @weekday_pager_end_time = 235959,
        @saturday_pager_start_time = 000000,
        @saturday_pager_end_time = 235959,
        @sunday_pager_start_time = 000000,
        @sunday_pager_end_time = 235959,
        @pager_days = 127
END

SELECT DISTINCT
    @@SERVERNAME,
    a.job_id,
    a.name AS job_name,
    a.enabled,
    a.description,
    b.name AS email_operator,
    b.email_address AS email_operator_address,
    c.name AS pager_operator,
    c.email_address AS pager_operator_address
FROM
    [msdb].[dbo].[sysjobs] a
        LEFT OUTER JOIN [msdb].[dbo].[sysoperators] b
            ON (a.notify_email_operator_id = b.id)
        LEFT OUTER JOIN [msdb].[dbo].[sysoperators] c
            ON (a.notify_page_operator_id = c.id)
WHERE
    ISNULL(b.name, @operator) = @operator AND
    ISNULL(c.name, @operator) = @operator;
