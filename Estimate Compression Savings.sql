EXEC sp_estimate_data_compression_savings 'dbo', 'VisitorPageHits', NULL, NULL, 'PAGE' ;
GO


EXEC sp_estimate_data_compression_savings 'dbo', 'VisitorPageHits', NULL, NULL, 'ROW' ;
GO

/****

[dbo].[VisitorSessions]



***/