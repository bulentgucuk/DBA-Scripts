/*Healthy SQL - GetSQLServerEngineProperties

Copyright © 2015 by Robert Pearl

This work is subject to copyright. All rights are reserved by the Publisher, whether the whole or part of the material is concerned, specifically the rights of translation, reprinting, reuse of illustrations, recitation, broadcasting, reproduction on microfilms or in any other physical way, and transmission or information storage and retrieval, electronic adaptation, computer software, or by similar or dissimilar methodology now known or hereafter developed. Exempted from this legal reservation are brief excerpts in connection with reviews or scholarly analysis or material supplied specifically for the purpose of being entered and executed on a computer system, for exclusive use by the purchaser of the work. Duplication of this publication or parts thereof is permitted only under the provisions of the Copyright Law of the Publisher’s location, in its current version, and permission for use must always be obtained from Springer. Permissions for use may be obtained through RightsLink at the Copyright Clearance Center. Violations are liable to prosecution under the respective Copyright Law. */


SET NOCOUNT ON

DECLARE @ver NVARCHAR(128)

DECLARE @majorVersion NVARCHAR(4)

SET @ver = CAST(SERVERPROPERTY('productversion') AS NVARCHAR)

SET @ver = SUBSTRING(@ver,1,CHARINDEX('.',@ver)+1)

SET @majorVersion = CAST(@ver AS nvarchar)

SELECT SERVERPROPERTY('ServerName') AS [ServerName],SERVERPROPERTY('InstanceName') AS [Instance],

SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS],

SERVERPROPERTY('ProductVersion') AS [ProductVersion],

CASE @MajorVersion

WHEN '8.0' THEN 'SQL Server 2000'

WHEN '9.0' THEN 'SQL Server 2005'

WHEN '10.0' THEN 'SQL Server 2008'

WHEN '10.5' THEN 'SQL Server 2008 R2'

WHEN '11.0' THEN 'SQL Server 2012'

WHEN '12.0' THEN 'SQL Server 2014'

END AS 'SQL',

SERVERPROPERTY('ProductLevel') AS [ProductLevel],

SERVERPROPERTY('Edition') AS [Edition],

SERVERPROPERTY ('BuildClrVersion') AS NET,

CASE SERVERPROPERTY('IsClustered')

WHEN 0 THEN 'NO'

WHEN 1 THEN 'YES'

END

AS [IsClustered],

CASE WHEN CHARINDEX('Hypervisor',@@VERSION)>0

OR CHARINDEX('VM',@@VERSION)>0 THEN 'VM'

ELSE 'PHYSICAL'

END

AS [VM_PHYSICAL],

CASE SERVERPROPERTY('IsIntegratedSecurityOnly')

WHEN 1 THEN 'WINDOWS AUTHENTICATION ONLY'

WHEN 0 THEN 'SQL & WINDOWS AUTHENTICATION'

END AS 'SECURITY MODE' 