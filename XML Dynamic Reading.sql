SET NOCOUNT ON
DECLARE	@RowId INT,
		@SessisionId VARCHAR (50),
		@ApplicationId INT,
		@x xml

SELECT	@RowId = MAX(RowId)
FROM	dbo.PendingAppsFromUATEMP (NOLOCK)
WHERE	SessionId IS NULL

WHILE	@RowId >=   0
	BEGIN
		SELECT  @x = (select top 1 A.Content from dbo.APPLICATIONS AS A (NOLOCK)
					inner join dbo.PendingAppsFromUATEMP AS PUA (NOLOCK)
						ON A.APPLICATIONID = PUA.APPLICATIONID
					WHERE	PUA.RowId = @RowId)
		SELECT	@ApplicationId = ApplicationId
		FROM	dbo.PendingAppsFromUATEMP (NOLOCK)
		WHERE	RowId = @Rowid

		--SELECT @X RAW_XML

		-- Initialize XML handle
		DECLARE @hdoc INT    
		EXEC sp_xml_preparedocument @hdoc OUTPUT, @x
 
		--SQL 2005 CODE
		SELECT	@SessisionId = 
		  x.header.value('@VisitorSessionID[1]', 'varchar(50)')-- AS PARSED_XML
		--,  x.header.value('Typex[1]', 'varchar(20)') AS Typex2
		 FROM @x.nodes('//QuoteRequest') AS x(header)
		-- Update table data
--		UPDATE	dbo.PendingAppsFromUATEMP
--		SET		SessionId = @SessisionId
--		WHERE	ApplicationId = @ApplicationId

--		SELECT	aPPLICATIONID, @SessisionId
--		FROM	dbo.PendingAppsFromUATEMP
--		WHERE	ApplicationId = @ApplicationId

		--Remove xml document from memory
		EXEC sp_xml_removedocument @hdoc
		--Decrease the Rowid
		SELECT	@RowId = @Rowid - 1
	END

	



SELECT	PUA.ApplicationId
		, A.ApplicationId
		, PUA.SessionId
		, A.Content
FROM	dbo.PendingAppsFromUATEMP AS PUA (NOLOCK) -- 2885
	INNER JOIN dbo.Applications AS A (nolock)
		on A.ApplicationId = PUA.ApplicationId
WHERE	SESSIONID IS  NULL ---28609372


-- COMMON RECORDS 144
SELECT	PUA.APPLICATIONID,
		VA.APPLICATIONID,
		PUA.SessionId,
		VA.VisitorSessionID
FROM	dbo.PendingAppsFromUATEMP AS PUA (NOLOCK)
	INNER JOIN	dbo.VisitorApplications AS VA (NOLOCK)
		ON PUA.APPLICATIONID = VA.APPLICATIONID
		AND PUA.SessionId = VA.VisitorSessionID

-- NOT IN VISITORAPPLICATIONS 2741
SELECT	PUA.APPLICATIONID,
		VA.APPLICATIONID,
		PUA.SessionId,
		VA.VisitorSessionID
FROM	dbo.PendingAppsFromUATEMP AS PUA (NOLOCK)
	LEFT OUTER JOIN	dbo.VisitorApplications AS VA (NOLOCK)
		ON PUA.APPLICATIONID = VA.APPLICATIONID
		AND PUA.SessionId = VA.VisitorSessionID
WHERE	VA.APPLICATIONID IS NULL
AND		VA.VisitorSessionID IS NULL

INSERT INTO dbo.VisitorApplications (VisitorSessionId, ApplicationId, SuppressPartnerReporting)
SELECT	PUA.SessionId,
		PUA.APPLICATIONID,
		0 AS SuppressPartnerReporting
FROM	dbo.PendingAppsFromUATEMP AS PUA (NOLOCK)
	LEFT OUTER JOIN	dbo.VisitorApplications AS VA (NOLOCK)
		ON PUA.APPLICATIONID = VA.APPLICATIONID
		AND PUA.SessionId = VA.VisitorSessionID
WHERE	VA.APPLICATIONID IS NULL
AND		VA.VisitorSessionID IS NULL



SELECT	PUA.APPLICATIONID
		,BL.APPLICATIONID
		,PUA.DATE
		,BL.DATE
FROM	dbo.PendingAppsFromUATEMP AS PUA(NOLOCK)
	INNER JOIN dbo.BillableLeadsTSA AS BL (NOLOCK) --DBO.VW_IBS_BILLABLELEADS AS BL (NOLOCK)--
		ON BL.APPLICATIONID = PUA.APPLICATIONID

UPDATE	DBO.BillableLeadsTSA
SET		DATE = PUA.DATE
FROM	DBO.BillableLeadsTSA AS BL (NOLOCK)
	INNER JOIN dbo.PendingAppsFromUATEMP AS PUA(NOLOCK)
		ON BL.APPLICATIONID = PUA.APPLICATIONID


SELECT BL.DATE BLDATE,
		PUA.DATE PUADATE
FROM	DBO.BillableLeadsTSA AS BL (NOLOCK)
	INNER JOIN dbo.PendingAppsFromUATEMP AS PUA(NOLOCK)
		ON BL.APPLICATIONID = PUA.APPLICATIONID



