USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IdentityValueReport]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[IdentityValueReport]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Script for SelectTopNRows command from SSMS  ******/




CREATE Proc [dbo].[IdentityValueReport]
as
With Identity_CTE([MonitorID],[DatabaseName],[TableName],[ColumnName],[DataType],[CurrentValue],[PercentageUsed],[CreateDate],[IsIdentity])
      AS
      (SELECT top  100 Percent  [MonitorID],[DatabaseName],[TableName],[ColumnName],[DataType],[CurrentValue],[PercentageUsed],[CreateDate],[IsIdentity]
  FROM [master].[dbo].[MonitorIdentity]
  Where 
	TableName + ColumnName <> '[dbo].[cs_SearchBarrel][WordHash]'
	AND TableName + ColumnName <> '[dbo].[Log][MerchantId]'
	AND TableName + ColumnName <> '[dbo].[PaidMediaLog][MerchantId]'
	AND TableName + ColumnName <> '[dbo].[FBCustomer][FacebookID]'
	AND TableName + ColumnName <> '[dbo].[FBCustomerFavorites][FBUserId]'
	AND TableName + ColumnName <> '[dbo].[BlogPartnerLog][BlogPartnerTrackerId]'
	AND TableName + ColumnName <> '[dbo].[BlogPartnerReportClickData][BlogPartnerTrackerId]'
	AND TableName + ColumnName <> '[dbo].[Purchases][CustomerID]'
	AND TableName + ColumnName <> '[dbo].[OutClickCounts][OutClickID]'
	AND TableName <> '[dbo].[cs_weblog_PostByYearMonth_tbl02]'
	AND TableName <> '[dbo].[FBFriend]'
	AND TableName <> '[dbo].[FBCustApp]'
	AND TableName <> '[dbo].[FBCustomer_old]'
	AND [CurrentValue] <> 0
  Order by PercentageUsed Desc, TableName + ColumnName   
  )
  
  ,CTE(StartValue, CurrentValue, Database_Table_Column, StartPercentUsed, CurrentPercentUsed, PercentGrowth, DataType,IsIdentity)
  AS
  (
Select 
	min(a.CurrentValue) as StartValue, 
	max(b.CurrentValue) as CurrentValue, 
	'[' + a.[DatabaseName] + '].' + a.TableName + '.' + a.ColumnName as Database_Table_Column, 
	min(a.PercentageUsed) as StartPercentUsed, 
	max(b.PercentageUsed) as CurrentPercentUsed, 
	((max(b.CurrentValue) - min(a.CurrentValue)) / min(a.CurrentValue)) * 100 as PercentGrowth,
	a.DataType,
	a.IsIdentity
From 
	Identity_CTE a 
	Join Identity_CTE b on a.MonitorID = b.MonitorID 
Group By 
	'[' + a.[DatabaseName] + '].' + a.TableName + '.' + a.ColumnName ,
	a.DataType,
	a.IsIdentity
	)
	Select top 100 Percent 
	Cast(Database_Table_Column as varchar(75)) as Database_Table_Column, 
	Cast(StartValue as decimal (20)) as StartValue, 
	Cast(CurrentValue as decimal (20)) as CurrentValue,
	Cast(StartPercentUsed as decimal (5,2)) as [Start%Full], 
	Cast(CurrentPercentUsed as decimal (5,2)) as [Current%Full], 
	Cast(PercentGrowth as decimal (15,2)) as [Growth%], 
	Cast(DataType as varchar(12))as DataType ,
	[Identity] = CASE IsIdentity   
		When 1 then 'yes' 
		Else 'no'
		END
		
	From CTE 
	Where StartValue <> CurrentValue AND PercentGrowth >.5
	Order by CurrentPercentUsed desc,PercentGrowth desc



GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
