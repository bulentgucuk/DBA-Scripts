if exists (select * from sysobjects
			where name ='dbaSpaceUsedAnalyzer'
			and objectproperty(object_id('dbaSpaceUsedAnalyzer'),'isprocedure')=1)
	begin
		print 'Dropping: dbaSpaceUsedAnalyzer'
		drop proc dbo.dbaSpaceUsedAnalyzer;
	end
print 'Creating: dbo.dbaSpaceUsedAnalyzer' 
go
CREATE PROCEDURE dbo.dbaSpaceUsedAnalyzer 
@type				varchar(256)='summary',		------------------------------------{Options 'summary' or 'Details'}
@sort_order		varchar(256)='1 ASC'		----------------------------------------{Options 'ASC' or 'DESC'}
-- ==========================================================================================
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- ==========================================================================================
-- 	Script Title :
-- 	=====================================================================================
-- 	Description  :		 Apply the procedure to the local database 
--	
--	Sample:		exec dbo.dbaSpaceUsedAnalyzer 'summary','6 desc'				-- order by max spaceused by indexes 
--				exec dbo.dbaSpaceUsedAnalyzer 'summary','5 desc'				-- order by max spaceused by the Physical data 
--				exec dbo.dbaSpaceUsedAnalyzer 'details','6 desc,8 desc'		-- order by max space used by non clustred indexes 
--				exec dbo.dbaSpaceUsedAnalyzer 'summary','4 desc'				-- order by max number of rows
-- 	=====================================================================================
-- 	Coder  										: 	Shaunt Khaldtiance
-- 	Creation Date								:	10/04/2008
--  Last 	Modification Date	(by whom)	:
-- ==========================================================================================
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- ==========================================================================================
AS
declare	@command varchar(1000),
			@schemaname varchar(256),
			@FullName varchar(256),
			@Name varchar(256),
			@schema varchar(256)
if (@type='summary')
	begin 
		if object_id(N'tempdb..[#TableSizes]') is not null   drop table #TableSizes ;
		if object_id(N'tempdb..[#TableSizesBuffer]') is not null   drop table #TableSizesBuffer ;
		create table #TableSizes
		(
			[Schema]				nvarchar(128),   
			[Table Name]			nvarchar(128),   
			[Number of Rows]	char(11),    
			[Reserved Space]	varchar(18), 
			[Data Space]			varchar(18),    
			[Index Size]			varchar(18),    
			[Unused Space]		varchar(18),   
		) ;
			
			select *  into  #TableSizesBuffer from #TableSizes where 1=2
			declare curSchemaTable cursor
														  for select '['+sys.schemas.name + '].[' + sys.objects.name+']',sys.objects.name,sys.schemas.name
														  from    sys.objects
																	, sys.schemas
														  where   object_id > 100
															 --     and sys.schemas.name = @schemaname
																  and type_desc = 'USER_TABLE'
																  and sys.objects.schema_id = sys.schemas.schema_id ; 
			open curSchemaTable ;
			fetch curSchemaTable into @FullName,@Name,@schema ;
			while ( @@FETCH_STATUS = 0 )
				begin     
							truncate table #TableSizesBuffer
							print @FullName
							insert into #TableSizesBuffer ([Table Name],[Number of Rows],[Reserved Space],[Data Space],[Index Size],[Unused Space] )
							exec sp_spaceused @objname = @FullName ;      
							update  #TableSizesBuffer set [Schema]=@schema where [Table Name]=@Name
							
							insert into #TableSizes select * from #TableSizesBuffer
		 
							fetch curSchemaTable into @FullName,@Name,@schema ;
				end 
				close curSchemaTable ;      
				deallocate curSchemaTable ;
			
				select @command='select	[Table Name],
							[Schema], 
							[Number of Rows],
							convert(decimal(15,2),convert(float,replace([Reserved Space],''KB'',''''))/1024.0) ''Reserved Space (MB)'',
							convert(decimal(15,2),convert(float,replace([Data Space],''KB'',''''))/1024.0)		''Data Space (MB)'',
							convert(decimal(15,2),convert(float,replace([Index Size],''KB'',''''))/1024.0	)	''Index Size (MB)'',
							convert(decimal(15,2),convert(float,replace([Unused Space],''KB'',''''))/1024.0) ''Unused Space(MB)''
				from    [#TableSizes] order by '+@sort_order
				exec (@command)
				drop table #TableSizes ;
				drop table #TableSizesBuffer ;
	end
else
	if (@type='details')
		begin 									
			select @command='SELECT 	Tab.Name ''Table Name'',
													Sch.Name ''Schema Name'',
													Inx.name ''Index Name'',			
													Inx.index_id ''Index ID'',
													InxUSG.page_count ''No. Pages'',
													InxUSG.index_type_desc,
													InxUSG.alloc_unit_type_desc,
													convert(float,InxUSG.page_count*8.00/1024.00) ''Used Space (MB)''
										FROM		sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL , NULL)  InxUSG
										join		sys.indexes Inx on InxUSG.object_id=Inx.object_id and InxUSG.index_id=Inx.index_id
										join		sys.tables	Tab on Tab.object_id=InxUSG.object_id 
										join		sys.schemas Sch on Sch.schema_id=Tab.schema_id
										order by '+@sort_order
			exec (@command)
		end
else 
	begin 
		print 'error in syntax:'+char(13)+space(10)+'exec dbo.dbaSpaceUsedAnalyzer {summary|details},{n1 [Desc|Asc][,n [Desc|Asc],...]}'
	end 
-- ==========================================================================================
-- 	End  of the Script  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- ==========================================================================================

go


















































