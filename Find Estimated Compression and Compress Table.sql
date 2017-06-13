EXEC sp_estimate_data_compression_savings 'dbo', 'ClickRateCMSShared', NULL, NULL, 'PAGE' ;
GO

EXEC sp_estimate_data_compression_savings 'dbo', 'ClickRateCMSShared', NULL, NULL, 'ROW' ;
GO


/******

EXEC sp_spaceused 'dbo.ClickRate_Dashboard'
go
--Warning: Option sort_in_tempdb is not applicable to table ClickRate_Dashboard because it does not have a clustered index. This option will be applied only to the table's nonclustered indexes, if it has any.
ALTER TABLE dbo.ClickRate_Dashboard REBUILD PARTITION = ALL
WITH 
(DATA_COMPRESSION = PAGE,
SORT_IN_TEMPDB = ON
)
GO

EXEC sp_spaceused 'dbo.ClickRateCMSShared'
go


name				rows		reserved		data		index_size	unused
ClickRateCMSShared	26274      	3920 KB			3848 KB		48 KB		24 KB
ClickRateCMSShared	26274      	2384 KB			2352 KB		24 KB		8 KB

*****/