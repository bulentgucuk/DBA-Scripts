/*Healthy SQL - Chapter 10 - Surviving the Audit
(c) 2015 Robert Pearl - All T-SQL scripts in Chapter 10 - Section: Reading the Transaction Log */


--Look inside current transaction log
Select * from fn_dblog(null,null)
GO

/*DECODE_TLOG script - create DB/Table */
Create Database DECODE_TLOG_DB 
Go 
Use DECODE_TLOG_DB 
GO 
CREATE TABLE DECODE_TLOG(COL1 VARCHAR(100)); 
GO 
INSERT INTO DECODE_TLOG VALUES ('Hello World'); 
GO 
UPDATE DECODE_TLOG SET COL1 = 'Find Me'; 
GO 

/*Select for Begin transaction */
Use DECODE_TLOG_DB 
Go 
select [Current LSN], [Operation], [Transaction ID], [Parent Transaction ID], 
[Begin Time], [Transaction Name], [Transaction SID] 
from fn_dblog(null, null) 
where [Operation] = 'LOP_BEGIN_XACT' 
order by [Begin Time] Desc 
GO

select [Current LSN], [Operation], 
[AllocUnitName], [Page ID], [Slot ID], 
[Lock Information], 
[Num Elements], [RowLog Contents 0], [RowLog Contents 1], [RowLog Contents 2],
SUSER_SNAME([Transaction SID]) as [LoginUserName] 
from fn_dblog(null, null) 
where [Transaction ID]='0000:000022eb' --<-- Replace with transaction ID according to book
GO

/*DECODE_TLOG1.SQL */
SELECT [MainLogRec].[Transaction ID], 
cast(substring([RowLog Contents 0],3,Len([RowLog Contents 0])) as varchar(max))BEFORE_UPDATE, 
cast(substring([RowLog Contents 1],3,Len([RowLog Contents 1])) as varchar(max))AFTER_UPDATE, 
[Operation], 
GetLoginName.[Transaction Name], 
[AllocUnitName], 
GetLoginName.LoginUserName, GetLoginName.[Begin Time], 
[Lock Information],[Page ID], [Slot ID], 
[Num Elements], [RowLog Contents 0], [RowLog Contents 1] 
from 
( 
Select  [transaction id],cast(substring([RowLog Contents 0],3,Len([RowLog Contents 0])) as 
varchar(max))BEFORE_UPDATE, 
cast(substring([RowLog Contents 1],3,Len([RowLog Contents 1])) as varchar(max))AFTER_UPDATE, 
[Operation], 
[AllocUnitName], [Lock Information],[Page ID], [Slot ID], 
[Num Elements], [RowLog Contents 0], [RowLog Contents 1] FROM ::fn_dblog(NULL, NULL) AS l 
WHERE CHARINDEX('Hello World', l.[RowLog Contents 0]) > 0 -- Find "Hello World" 
AND Operation='LOP_MODIFY_ROW' 
--AND [transaction id]='0000:000022e8' --uncomment to set tran_id 
) As MainLogRec 
inner join 
( 
Select SUSER_SNAME([Transaction SID]) as [LoginUserName], [Transaction ID], [Transaction 
Name], [Begin Time] 
FROM ::fn_dblog(NULL, NULL) 
WHERE /*[transaction id]='0000:000022e8'*/ ----uncomment to set tran_id 
Operation='LOP_BEGIN_XACT' 
) As GetLoginName 
On [MainLogRec].[transaction id]=GetLoginName.[transaction_id]
