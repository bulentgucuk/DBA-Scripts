/***
Run in Metadata to create new tenant, server and datasource

***/

--Below is external parameters to be passed to the proc
DECLARE @StatusName VARCHAR(50) --(Approved,Pending Approval,Denied)
	, @EnvType NVARCHAR(32) --(Prod,Test,Dev)
	, @DBType NVARCHAR(128) --(SSB CI DW - Core,SSB CI CRM - Outbound (Integration),SSB CI CRM - Inbound (Reporting),SSB CI Client DW (Azure))
	, @TenantName NVARCHAR(128) -- name of the tenant
	, @NickName NVARCHAR(128) -- short name for the tenant
	, @ServerName NVARCHAR(128) -- Server name
	, @FQDN NVARCHAR(128) --Fully Qualified Domain Name of the Server
	, @DBName VARCHAR(100) --Database name
	, @Ownership VARCHAR(50) -- Who owns the db source ('SSB', 'Client')
	, @ConnectionType VARCHAR(50) --Connection for the source database('sqlServer')

SELECT
	  @TenantName = 'Los Angeles Dodgers'  -- Pay attention tenant could be a leage and have a team as the dbname
	, @NickName = 'Los Angeles Dodgers'
	, @ServerName = 'VM-DB-DEV-01'
	, @FQDN = 'VM-DB-DEV-01.ssbinfo.com'
	, @DBName = 'LosAngelesDodgers'
	, @DBType = 'SSB CI DW - Core'
	, @EnvType = 'Dev'
	, @Ownership = 'SSB'
	, @ConnectionType = 'sqlServer'
	, @StatusName = 'Pending Approval'

--Above is external parameters to be passed to the proc

-- Internal variables
DECLARE @StatusId UNIQUEIDENTIFIER
	, @EnvTypeId UNIQUEIDENTIFIER
	, @DBTypeId UNIQUEIDENTIFIER
	, @TenantId UNIQUEIDENTIFIER
	, @ServerId UNIQUEIDENTIFIER
	, @TenantDataSourceID UNIQUEIDENTIFIER


--Get the envtypeid
SELECT	@EnvTypeId = EnvTypeId
FROM	dbo.EnvType
WHERE	EnvType = @EnvType;

--Get the DBtypeid
SELECT	@DBTypeId = DBTypeId
FROM	dbo.DbType
WHERE	DBtype = @DBType;

--Get the StatusId
SELECT	@StatusId = StatusId
FROM	dbo.TenantDataSource_Status
WHERE	StatusName = @StatusName;

--Check tenant record
SELECT	@TenantId = TenantId
FROM	dbo.Tenant
WHERE	TenantName = LTRIM(RTRIM(@TenantName));

--If tenant does not exist insert a new record for the tenant
IF @TenantId IS NULL
	BEGIN
		SET @TenantId = NEWID();
		INSERT INTO dbo.Tenant ([TenantID], [TenantName], [TenantUrl], [TenantType], [TenantSubType], [ShortName], [Nickname], [Mascot], [Active], [OrchardName], [OrchardType], [IsDiscoveryClient], [DiscoveryClientName])
		SELECT
			  @TenantId
			, LTRIM(RTRIM(@TenantName)) AS TenantName
			, '/' + REPLACE(LOWER(LTRIM(RTRIM(@TenantName))), ' ', '') AS TenantUrl
			, NULL AS TenanType
			, NULL AS TenantSubType
			, LTRIM(RTRIM(@TenantName)) AS ShortName
			, LTRIM(RTRIM(@NickName)) AS NickName
			, NULL AS Mascot
			, 1 AS Active
			, LTRIM(RTRIM(@TenantName)) AS OrchardName
			, 'CI' AS OrchardType
			, 1 AS IsDiscoveryClient
			, NULL AS DiscoveryClientName
	END


--Get the ServerId
SELECT	 @ServerId = ServerId
FROM	dbo.Server
WHERE	FQDN = @FQDN;

--If null then insert a new record for the server
IF @ServerId IS NULL
	BEGIN
		SET @ServerId = NEWID();
		SELECT @EnvTypeId = EnvTypeId
		FROM	dbo.EnvType
		
		INSERT INTO dbo.Server ([ServerID], [ServerName], [FQDN], [Port], [EnvTypeID], [Ownership], [ConnectionType], [IsActive], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate])
		SELECT
			  @ServerId AS ServerId
			, @ServerName AS ServerName
			, @FQDN AS FQDN
			, NULL AS Port
			, @EnvTypeId
			, @Ownership AS Ownership
			, @ConnectionType AS ConnectionType
			, 1 AS IsActive
			, SUSER_NAME() AS CreatedBy
			, GETDATE() AS CreatedDate
			, NULL AS UpdatedBy
			, NULL AS UpdatedDate;
	END

--Check the TenantDataSource
SELECT	@TenantDataSourceID = TenantDataSourceID
FROM	dbo.TenantDataSource
WHERE	TenantId = @TenantId
AND		ServerId = @ServerId
AND		DBName = @DBName
AND		DBTypeId = @DBTypeId
AND		EnvTypeId = @EnvTypeId

IF @TenantDataSourceID IS NULL
	BEGIN
		SET @TenantDataSourceID = NEWID();

		INSERT INTO dbo.TenantDataSource ([TenantDataSourceID], [FriendlyName], [TenantID], [ServerID], [DBName], [DBTypeID], [EnvTypeID], [Username], [EncryptedPassword], [IsActive], [CreatedBy], [CreatedDate], [StatusId])
		SELECT
			  @TenantDataSourceID AS TenantDataSourceID
			, @TenantName + ' - ' + @FQDN + ' - ' + @DBName AS FriendlyName
			, @TenantId AS TenantId
			, @ServerId AS ServerId
			, @DBName AS DBName
			, @DBTypeId AS DBTypeId
			, @EnvTypeId AS EnvTypeId
			, NULL AS UserName
			, NULL AS EncryptedPassword
			, 1 AS IsActive
			, SUSER_NAME() AS CreatedBy
			, GETDATE() AS CreatedDate
			, @StatusId AS StatusId;
	END


SELECT *
FROM dbo.Tenant
WHERE TenantId = @TenantId;

SELECT *
FROM	dbo.Server
WHERE	ServerId = @ServerId;

SELECT	*
FROM	dbo.TenantDataSource
WHERE	TenantId = @TenantId
AND		ServerId = @ServerId
AND		DBName = @DBName
AND		DBTypeId = @DBTypeId
AND		EnvTypeId = @EnvTypeId;
