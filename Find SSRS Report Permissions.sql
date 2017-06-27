-- Find SSRS Report Permissions
USE ReportServer
GO
SELECT	Catalog.Name AS ReportName,
		Users.UserName,
		Roles.RoleName

FROM	[dbo].[Catalog]
	INNER JOIN dbo.PolicyUserRole
		ON	[Catalog].PolicyID = PolicyUserRole.PolicyID
	INNER JOIN dbo.Users
		ON	PolicyUserRole.UserID = Users.UserID
	INNER JOIN dbo.Roles
		ON	PolicyUserRole.RoleID = Roles.RoleID

