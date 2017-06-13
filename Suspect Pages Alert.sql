declare @count integer
declare @tableHTML  nvarchar(MAX);
declare @subj nvarchar(100)

select @count=count(1)
from msdb.dbo.suspect_pages;

set @subj = 'Suspect Pages Found in ' + @@SERVERNAME;

set @tableHTML =
    N'<H1>Suspect Pages Found in ' + @@SERVERNAME + ', details are below.</H1>' +
    N'<table border="1">' +
    N'<tr><th>Database ID</th><th>Database</th>' +
    N'<th>File ID</th><th>File</th><th>Page ID</th>' +
    N'<th>Event Desc</th><th>Error Count</th><th>Last Updated</th></tr>' +
    cast ( ( select td = sp.database_id,       '',
       td = d.name,       '',
       td = sp.file_id,       '',
       td = mf.physical_name,       '',
       td = sp.page_id,       '',
       td = case when sp.event_type = 1 then '823 or 824 error other than a bad checksum or a torn page'
            when sp.event_type = 2 then 'Bad checksum'
            when sp.event_type = 3 then 'Torn Page'
            when sp.event_type = 4 then 'Restored (The page was restored after it was marked bad)'
            when sp.event_type = 5 then 'Repaired (DBCC repaired the page)'
            when sp.event_type = 7 then 'Deallocated by DBCC'
       end,       '',
       td = sp.error_count,       '',
       td = sp.last_update_date
from msdb.dbo.suspect_pages sp
inner join sys.databases d on d.database_id=sp.database_id
inner join sys.master_files mf on mf.database_id=sp.database_id and mf.file_id=sp.file_id
              for xml path('tr'), TYPE 
    ) as nvarchar(max) ) +
    N'</table>' ;

IF @count > 0
  exec msdb.dbo.sp_send_dbmail
    @recipients=N'gucukb@insurancequotes.com',
    @body= @tableHTML, 
    @subject = @subj,
    @body_format = 'HTML',
    @profile_name ='SPDBXX5100SQL\RPT01'


GO

delete from msdb.dbo.suspect_pages
where last_update_date < getdate()-90;