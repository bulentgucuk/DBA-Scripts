    -- Different ways to get date and time
    SELECT SYSDATETIME() AS [SYSDATETIME], SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET],
           SYSUTCDATETIME() AS [SYSUTCDATETIME], CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP],
           GETDATE() AS [GETDATE], GETUTCDATE() AS [GETUTCDATE];

    -- SQL Server 2008 and 2008 R2 only
    SELECT SYSUTCDATETIME() AS [UTCTime];
    SELECT SYSDATETIMEOFFSET() AS [SysDateTimeOffset]; 
    SELECT SYSDATETIME() AS [SysDateTime] 


    -- These work in SQL Server 2005
    SELECT CURRENT_TIMESTAMP AS [CurrentTime];
    SELECT GETDATE() AS [LocalDate];
    SELECT GETUTCDATE() AS [UTCDate];  
    
    -- Getting difference between local time and UTC time
    -- This works in SQL Server 2005
    DECLARE @OffsetValue int;
    SET @OffsetValue = (SELECT DATEDIFF(hh, GETUTCDATE(), GETDATE()));
    SELECT @OffSetValue AS [TimeOffset];