--in master
CREATE LOGIN [ssb_redgate_monitor] WITH	 PASSWORD = 'IbMA6DWT$tt*5^z5g7$NQhYy'

CREATE USER [ssb_redgate_monitor] FROM LOGIN [ssb_redgate_monitor]
WITH --PASSWORD = N'IbMA6DWT$tt*5^z5g7$NQhYy' , 
DEFAULT_SCHEMA=[dbo];

-- in sql db
CREATE USER [ssb_redgate_monitor] FROM LOGIN [ssb_redgate_monitor]
WITH --PASSWORD = N'IbMA6DWT$tt*5^z5g7$NQhYy' , 
DEFAULT_SCHEMA=[dbo];

ALTER ROLE db_owner ADD MEMBER [ssb_redgate_monitor]