USE [SahSelect];
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products_AdminSearch]') AND type in (N'P', N'PC'))
	BEGIN
		EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[Products_AdminSearch] AS'
	END
GO

ALTER PROCEDURE [dbo].[Products_AdminSearch]
	@merchantId INT = NULL,
	@brand VARCHAR(50) = NULL,
	@sku VARCHAR(50) = NULL,
	@searchText VARCHAR(50) = NULL,
	@startDateBeginning DATETIME = NULL,
	@startDateEnd DATETIME = NULL,
	@Debug BIT = 0
AS
BEGIN
SET NOCOUNT ON;
	-- Main dynamic Query parameters
	DECLARE
		  @SqlQuery NVARCHAR(4000)
		, @ParameterDefinition NVARCHAR(2000);

	SET @SqlQuery = '
	SELECT TOP 10001
		  p.Id
		, p.ProductSourcesId
		, p.MerchantId
		, p.MerchantProductId
		, p.BrandName
		, p.Title
		, p.[Description]
		, p.StartDate
		, p.EndDate
		, p.ImageURL
		, p.[URL]
		, p.Price
		, p.DiscountPrice
		, p.ShippingPrice
		, p.CreateDate
		, p.LastUpdatedBy
		, p.LastUpdateDate
		, m.MerchantName
		, ps.[Name] AS ''ProductSourceName''
	FROM dbo.Products AS p WITH (NOLOCK)
		INNER JOIN dbo.Merchants AS m WITH (NOLOCK) ON m.MerchantId = p.MerchantId
		INNER JOIN dbo.ProductSources AS ps WITH (NOLOCK) ON ps.Id = p.ProductSourcesId
	WHERE 1=1';

	-- Start building the dynamic where clause
	-- Check @merchantid
	IF @merchantId IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery + CHAR(13) + 'AND p.MerchantId = @merchantId';
		END

	-- Check @brand
	IF @brand IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery +  CHAR(13) + 'AND p.BrandName LIKE ''' + '%' + @brand + '%' + '''';
		END

	-- Chekc @sku
	IF @sku IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery +  CHAR(13) + 'AND p.MerchantProductId LIKE ''' + '%' + @sku + '%' + '''';
		END

	-- Check @searchText
	IF @searchText IS NOT NULL
		BEGIN
			SET @SqlQuery =  @SqlQuery +  CHAR(13) + 'AND (p.Title LIKE ''' + '%' + @searchText + '%' + '''' + ' OR p.[Description] LIKE ''' + '%' + @searchText + '%' + ''')';
		END

	-- Check @startDateBeginning
	IF @startDateBeginning IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery + CHAR(13) + 'AND CAST(p.StartDate AS DATE) >= @startDateBeginning';
		END

	-- Check @startDateEnd
	IF @startDateEnd IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery + CHAR(13) + 'AND CAST(p.StartDate AS DATE) <= @startDateEnd';
		END

	-- Check @startDateBeginning and @startDateEnd
	IF @startDateBeginning IS NOT NULL OR @startDateEnd IS NOT NULL
		BEGIN
			SET @SqlQuery = @SqlQuery + CHAR(13) + 'AND (p.EndDate > GETDATE() OR p.EndDate IS NULL)';
		END

	-- Add the order by clause
	Set @SqlQuery = @SqlQuery + CHAR(13) + 'ORDER BY p.ProductSourcesId ASC;';

	-- Set @ParameterDefinition
	SET	@ParameterDefinition = ' @merchantId INT,
		@brand VARCHAR(50),
		@sku VARCHAR(50),
		@searchText VARCHAR(50),
		@startDateBeginning DATETIME,
		@startDateEnd DATETIME';

	-- Print the query for visual inspection
	IF @Debug = 1
		BEGIN
			PRINT @SqlQuery;
		END
	-- Execute @SqlQuery using sp_executesql stored procedure
	EXEC sp_executesql
		  @stmt = @SqlQuery
		, @params = @ParameterDefinition
		, @merchantId = @merchantId 
		, @brand = @brand
		, @sku = @sku
		, @searchText = @searchText
		, @startDateBeginning = @startDateBeginning
		, @startDateEnd = @startDateEnd;

END
