-------------------   1  Create Table

USE [DBAMaint]
GO

/****** Object:  Table [dbo].[IdentityStatus]    Script Date: 6/2/2017 3:42:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IdentityStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[IdentityStatus](
	[Date] [datetime] NULL,
	[database_name] [varchar](128) NULL,
	[table_name] [varchar](128) NULL,
	[column_name] [varchar](128) NULL,
	[data_type] [varchar](128) NULL,
	[last_value] [bigint] NULL,
	[percentLeft] [numeric](18, 2) NULL,
	[id_status] [varchar](30) NOT NULL
) ON [PRIMARY]
END
GO


---------------  2 Collect the Identity Value information from all the tables in all databases Job Step 1

/* Define how close we are to the value limit
   before we start throwing up the red flag.
   The higher the value, the closer to the limit. */
Declare @threshold decimal(3,2) = .85;
Declare @Date datetime = getdate();
Set @Date = convert(date, getdate())

/* Create a temp table */
DROP TABLE IF EXISTS #identityStatus;
Create Table #identityStatus
(
	  database_name     varchar(128)
    , table_name        varchar(128)
    , column_name       varchar(128)
    , data_type         varchar(128)
    , last_value        bigint
    , max_value         bigint
);

/* Use an undocumented command to run a SQL statement
   in each database on a server */
Execute sp_msforeachdb '
    Use [?];
    Insert Into #identityStatus
    Select ''?'' As [database_name]
        , Object_Name(id.object_id, DB_ID(''?'')) As [table_name]
        , id.name As [column_name]
        , t.name As [data_type]
        , Cast(id.last_value As bigint) As [last_value]
        , Case 
            When t.name = ''tinyint''   Then 255 
            When t.name = ''smallint''  Then 32767 
            When t.name = ''int''       Then 2147483647 
            When t.name = ''bigint''    Then 9223372036854775807
          End As [max_value]
    From sys.identity_columns As id
    Join sys.types As t
        On id.system_type_id = t.system_type_id
    Where id.last_value Is Not Null';

/* Retrieve our results and format it all prettily */


--insert into DBAMaint.dbo.IdentityStatus
select
	@Date as Date
	, database_name
    , table_name
    , column_name
    , data_type
    , last_value
    , Case 
        When last_value < 0 Then 100
        Else (1 - Cast(last_value As float(4)) / max_value) * 100 
      End As [percentLeft]
    , Case 
        When Cast(last_value As float(4)) / max_value >= @threshold
            Then 'warning: approaching max limit'
        Else 'okay'
        End As [id_status]
From #identityStatus
Order By percentLeft;

/* Clean up after ourselves */
Drop Table #identityStatus;


---------------  3 Send Alert Email if more than 90% is used Job Step 2

USE DBAMaint;
GO
DECLARE @retVal int;

SELECT	@retVal = COUNT(*) 
FROM	dbo.IdentityStatus
WHERE	Date = convert(date, getdate())
AND		percentLeft < 10.00

IF (@retVal > 0)
BEGIN

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>Identity Status</H1>' +
    N'<table border="1">' +
    N'<tr><th>Database_name</th><th>Table_name</th><th>Column_name</th>' +
    N'<th>Data_type</th><th>Last_value</th><th>percentLeft</th>' +
    N'<th>id_status</th></tr>' +
    CAST ( ( SELECT td = database_name,       '',
                    td = table_name, '',
                    td = column_name, '',
                    td = data_type, '',
                    td = last_value, '',
                    td = percentLeft, '',
                                  td = id_status, ''
              FROM DBAMaint.dbo.IdentityStatus
              WHERE Date = convert(date, getdate()) 
			  AND percentLeft < 10.00
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;

EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'SQL14PROD01',
	@recipients = 'bgucuk@shopathome.com',
	@subject = 'Warning - Identity Columns Approaching Max Limit',
	@body = @tableHTML,
	@body_format = 'HTML' ;

END
