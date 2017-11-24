USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ShinkDatabaseInIncrements]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_ShinkDatabaseInIncrements]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



Create proc [dbo].[sp_ShinkDatabaseInIncrements] (@DBFileName sysname, @TargetFreeMB int , @ShrinkIncrementMB int)
as
begin
	--declare @DBFileName sysname
	--declare @TargetFreeMB int
	--declare @ShrinkIncrementMB int

	
	


	-- Show Size, Space Used, Unused Space, and Name of all database files
	select
		[FileSizeMB]	=
			convert(numeric(10,2),round(a.size/128.,2)),
		[UsedSpaceMB]	=
			convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) ,
		[UnusedSpaceMB]	=
			convert(numeric(10,2),round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2)) ,
		[DBFileName]	= a.name
	from
		sysfiles a with (nolock) 
	Where a.name = 'AgentUsage_Data'

	declare @sql varchar(8000)
	declare @SizeMB int
	declare @UsedMB int

	-- Get current file size in MB
	select @SizeMB = size/128. from sysfiles where name = @DBFileName

	-- Get current space used in MB
	select @UsedMB = fileproperty( @DBFileName,'SpaceUsed')/128.

	select [StartFileSize] = @SizeMB, [StartUsedSpace] = @UsedMB, [DBFileName] = @DBFileName

	-- Loop until file at desired size
	while  @SizeMB > @UsedMB+@TargetFreeMB+@ShrinkIncrementMB
		begin

		set @sql =
		'dbcc shrinkfile ( '+@DBFileName+', '+
		convert(varchar(20),@SizeMB-@ShrinkIncrementMB)+' ) '

		print 'Start ' + @sql
		print 'at '+convert(varchar(30),getdate(),121)

		exec ( @sql )

		print 'Done ' + @sql
		print 'at '+convert(varchar(30),getdate(),121)

		-- Get current file size in MB
		select @SizeMB = size/128. from sysfiles where name = @DBFileName
		
		-- Get current space used in MB
		select @UsedMB = fileproperty( @DBFileName,'SpaceUsed')/128.

		select [FileSize] = @SizeMB, [UsedSpace] = @UsedMB, [DBFileName] = @DBFileName
		waitfor delay '00:00:00'
		end

	select [EndFileSize] = @SizeMB, [EndUsedSpace] = @UsedMB, [DBFileName] = @DBFileName

	-- Show Size, Space Used, Unused Space, and Name of all database files
	select
		[FileSizeMB]	=
			convert(numeric(10,2),round(a.size/128.,2)),
		[UsedSpaceMB]	=
			convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) ,
		[UnusedSpaceMB]	=
			convert(numeric(10,2),round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2)) ,
		[DBFileName]	= a.name
	from
		
		sysfiles a with (nolock) 
	Where a.name = 'AgentUsage_Data'
end

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
