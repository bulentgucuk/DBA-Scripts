SET NOCOUNT ON
DECLARE @cmdline VARCHAR(500),
        @ReturnCode INT,
        @ErrorMessage varchar(500)
 
--Command to execute
SELECT @cmdline ='Net use \\DPBack0050\RepToBP15d\DQDBXX0050_QA01 Kv5apmENxb /USER:web.prod\IUSR_SQL_SERVICE /PERSISTENT:YES';
 
--Create temp table to hold result
CREATE TABLE #CmdShellLog (CmdShellMessage VARCHAR(500) NULL)
 
--dump result into temp table
INSERT #CmdShellLog
EXEC @ReturnCode = master.dbo.xp_cmdshell @cmdline

-- If we have an error populate variable
IF @ReturnCode <> 0
	BEGIN
		SELECT @ErrorMessage = CmdShellMessage  
		FROM #CmdShellLog
		WHERE CmdShellMessage IS NOT NULL
	 
		--Display error message and return code
		SELECT @ErrorMessage as ErrorMessage  ,@ReturnCode as ReturnCode
	    
		RAISERROR(@ErrorMessage,16,1)
	 
	END
ELSE
	BEGIN
		-- statement to run
		PRINT 'IF XP_CMDSHELL IS SUCCESS YOU SHOULD SEE THIS'
	
	END

-- drop temp table
DROP TABLE #CmdShellLog