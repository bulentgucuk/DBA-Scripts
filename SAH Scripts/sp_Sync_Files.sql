USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_Sync_Files]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_Sync_Files]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE proc [dbo].[sp_Sync_Files]

/*************************************************************************************
** proc name:			sp_Sync_Files
**
** Description:			Copy new files from source to destination
**						
** Output Parameters:	
**
** Dependent On:		
**
** Run Script:          exec master..sp_Sync_Files
**                       @source_path   = ''
**                      ,@destn_path    = ''
**                      ,@print_restore = 0
**
** History:
**      Name            Date            Pr Number       Description
**      ----------      -----------     ---------       ---------------
**      M. Horton       Implement       n/a				Creation of inital script
**      B. Jones        11/09/2010      n/a             added checks for source and Destination, added output of files copied
**
*************************************************************************************/


 @source_path   varchar(255) = ''
,@destn_path    varchar(255) = ''
,@print_restore bit          = 0

as

set nocount on

Declare @cmd varchar(8000)

if left(reverse(@source_path), 1) != '\'
 begin
	set @source_path = @source_path + '\'
 end
if left(reverse(@destn_path), 1) != '\'
 begin
	set @destn_path = @destn_path + '\'
 end

set        @cmd = 'powershell.exe  -command "&{'
set @cmd = @cmd + 'clear-host;'
set @cmd = @cmd + '$src = '''+@source_path+''';'
set @cmd = @cmd + '$des = '''+@destn_path+''';'
set @cmd = @cmd + 'if(!(test-Path $src)){write-host Invalid Source; exit; };'
set @cmd = @cmd + 'if(!(test-Path $des)){write-host Invalid Destination; exit; };'
set @cmd = @cmd + 'if ($Err){write-host $Err -Foregroundcolor Red}'
set @cmd = @cmd + '$SrcEntries = Get-ChildItem $src;'
set @cmd = @cmd + '$SrcFiles = $SrcEntries | Where-Object{!$_.PSIsContainer};'
set @cmd = @cmd + 'foreach($entry in $SrcFiles){'
set @cmd = @cmd + '$SrcFileName = $src + $entry.Name;'
set @cmd = @cmd + '$DesFileName = $des + $entry.Name;'
set @cmd = @cmd + '$message = ''Copied File: '' + $SrcFileName + '' to: '' + $des;'
set @cmd = @cmd + 'if(!(test-Path $DesFileName)){copy-Item -path $SrcFileName -dest $DesFileName -force; write-host $message; };'
set @cmd = @cmd + ' };'
set @cmd = @cmd + ' }"'

if @print_restore = 1
 begin
	print @cmd
 end
else
 begin	
	exec master.dbo.xp_cmdshell @cmd
 end




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
