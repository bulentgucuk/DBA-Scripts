      Declare @EndDateRange datetime
      Declare @StartDateRange datetime
      Declare @BCPOutCmd varchar(max)
      Declare @DeleteCmd varchar(max)
      Declare @BCPInCmd varchar(max)
      Declare @DropFileCmd varchar(max)
      Declare @NQCount int
      Declare @RDSCount int
      DECLARE @myDate DATETIME
      DECLARE @myDestTable Varchar(256)
      DECLARE @mySourceTable Varchar(256)
      DECLARE @mySourceDB varchar(128)
      DECLARE @myDestDB varchar(128)
      DECLARE @dateColummName varchar(64)
      DECLARE @mySourceSchema sysname
      DECLARE @myDestinationSchema sysname
      DECLARE @OutputLocation varchar(512)
      DECLARE @myDestinationSQLServer sysname
      DECLARE @mySourceSQLserver sysname
      DECLARE @BcpFormat nvarchar(32)
      DECLARE @Debug bit

      --Source Info
      SET @OutputLocation = '\\SPDBXX7100SQL\BCP\'
      SET @mySourceSQLserver = 'SPDBXX0028\ODS02'
      SET @mySourceDB = 'ODS' -- not used yet
      SET @mySourceSchema = 'Evaluated'
      SET @mySourceTable = 'Adjustments'
      --Destination Info
      SET @myDestinationSQLServer = 'SPDBXX5100SQL\RPT01'
      SET @myDestDB = 'RDS' -- not used yet
      SET @myDestinationSchema = 'Evaluated'
      SET @myDestTable = 'Adjustments'
      SET @myDate = GETDATE()
      SET @dateColummName = 'CreatedDate' -- not used yet
      SET @StartDateRange = '01/01/2010 00:00:00'
      SET @EndDateRange = '06/01/2010 00:00:00'
      SET @BcpFormat = ' -c -CACP '  -- other default option '-n ' 
      SET @Debug = 1  --1 to show commands but does not run.  setting to zero will run commands
--Print @myDate   

Begin
--Begin try 
--BCP query out the data to a DAT file
SET @BCPOutCmd = char(10)+''+CHAR(10)
-- Select a set of data with a data range
SET @BCPOutCmd = @BCPOutCmd+ 'EXEC XP_CMDSHELL ''bcp "Select * from '+@mySourceDB+'.'+@mySourceSchema+'.'+@mySourceTable+' with (nolock) where ['+@dateColummName+'] >= '''''+CONVERT(VARCHAR(19), @StartDateRange, 120)+''''' and ['+@dateColummName+'] < '''''+CONVERT(VARCHAR(19), @EndDateRange, 120)+'''''" queryout '+@OutputLocation+@myDestTable+'_'+@mySourceDB+'1.dat '+@BcpFormat+' -R -E -T -S '+@mySourceSQLserver+''''
--  Select a set of data with a data range and an extra target column
--SET @BCPOutCmd = @BCPOutCmd+ 'EXEC XP_CMDSHELL ''bcp "Select *, getdate()RDSDT from '+@mySourceDB+'.'+@mySourceSchema+'.'+@myDestTable+' where ['+@dateColummName+'] >= '''''+CONVERT(VARCHAR(19), @StartDateRange, 120)+''''' and ['+@dateColummName+'] <= '''''+CONVERT(VARCHAR(19), @EndDateRange, 120)+'''''" queryout '+@OutputLocation+@myDestTable+'_'+@mySourceDB+'1.dat -n -E -T -S '+@mySourceSQLserver+''''
--  Select a whole table with an extra target column
--SET @BCPOutCmd = @BCPOutCmd+ 'EXEC XP_CMDSHELL ''bcp "Select *, getdate()RDSDT from '+@mySourceDB+'.'+@mySourceSchema+'.'+@myDestTable+'" queryout '+@OutputLocation+@myDestTable+'_'+@mySourceDB+'1.dat -n -E -T -S '+@mySourceSQLserver+''''
--  Select an entire table.
--SET @BCPOutCmd = @BCPOutCmd+ 'EXEC XP_CMDSHELL ''bcp ['+@mySourceDB+'].['+@mySourceSchema+'].['+@myDestTable+'] out '+@OutputLocation+'\'+@myDestTable+'_'+@mySourceDB+'1.dat -a 8192 -n -R -E -T -S '+@mySourceSQLserver+''''

--Delete destination data that will be replaced
SET @DeleteCmd = ''
--SET @DeleteCmd = @DeleteCmd + 'EXEC XP_CMDSHELL ''sqlcmd -S '+@myDestinationSQLServer+' -Q "Delete from ['+@myDestDB+'].['+@mySourceSchema+'].['+@myDestTable+'] "'''
SET @DeleteCmd = @DeleteCmd + 'EXEC XP_CMDSHELL ''sqlcmd -S '+@myDestinationSQLServer+' -Q "Delete from ['+@myDestDB+'].['+@mySourceSchema+'].['+@myDestTable+'] with (rowlock) where ['+@dateColummName+'] >= '''''+CONVERT(VARCHAR(19), @StartDateRange, 120)+''''' and ['+@dateColummName+'] < '''''+CONVERT(VARCHAR(19), @EndDateRange, 120)+'''''"'''
--SET @DeleteCmd = 'EXEC XP_CMDSHELL ''sqlcmd -S '+@myDestinationSQLServer+' -d '+@myDestDB+' -Q "Truncate Table ['+@mySourceSchema+'].['+@myDestTable+']" '''

--BCP IN data to destination
SET @BCPInCmd = '' 
SET @BCPInCmd = @BCPInCmd+ 'EXEC XP_CMDSHELL ''bcp ['+@myDestDB+'].['+@myDestinationSchema+'].['+@myDestTable+'] in '+@OutputLocation+@myDestTable+'_'+@mySourceDB+'1.dat -a 8192 '+@BcpFormat+' -b 50000 -R -E -T -S '+@myDestinationSQLServer+''''

--Delete output DAT file
SET @DropFileCmd = ''
SET @DropFileCmd = @DropFileCmd + 'EXEC XP_CMDSHELL ''del '+@OutputLocation+@myDestTable+'_'+@mySourceDB+'1.dat'''
END

If @Debug = 1
BEGIN
	--BCP out the file of data
	Print @BCPOutCmd

	--Delete records within the criteria specified
	Print @DeleteCmd

	--import data from BCP file
	Print @BCPInCmd

	--Drop BCP file when complete
	Print @DropFileCmd

END

If @Debug = 0
BEGIN
	--BCP out the file of data
	Print @BCPOutCmd
	EXEC (@BCPOutCmd)
	WAITFOR DELAY '00:00:01'
	--Delete records within the criteria specified
	Print @DeleteCmd
	EXEC (@DeleteCmd)
	WAITFOR DELAY '00:00:01'
	--import data from BCP file
	Print @BCPInCmd
	EXEC (@BCPInCmd)
	WAITFOR DELAY '00:00:01'
	--Drop BCP file when complete
	Print @DropFileCmd
	EXEC (@DropFileCmd)
END


--sp_rename 'Evaluated.ValidationRuleResults','ValidationRuleResults_History'
--sp_rename 'Evlauated.ValidationRuleResults_01','ValidationRuleResults'

