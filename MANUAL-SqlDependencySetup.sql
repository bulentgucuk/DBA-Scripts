-- Prepare for SqlDependency
-- Run the section for the specified environmnet

-- Navigate to C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727, and run:
-- aspnet_regsql.exe -S "(local)" -d "UniversalApplicationLocal" -ed

-------------------------------------------------------------------------------------------------------
-- Local
-- Note: Local database was changed to use SQL Authentication, user IUSR_SQL_UA_LOCAL
-- rather than windows integrated authentication.  Create the user and add to local UA db.
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationLocal SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationLocal SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_LOCAL AUTHORIZATION IUSR_SQL_UA_LOCAL
-- Make IUSR_SQL_UA_LOCAL the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_QA_LOCAL;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_LOCAL
GRANT CREATE QUEUE to     IUSR_SQL_UA_LOCAL
GRANT CREATE SERVICE to   IUSR_SQL_UA_LOCAL
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_LOCAL
GRANT VIEW DEFINITION to  IUSR_SQL_UA_LOCAL

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_LOCAL
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_LOCAL
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_LOCAL
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_LOCAL'
GRANT SELECT TO IUSR_SQL_UA_LOCAL
*/

-------------------------------------------------------------------------------------------------------
-- A1
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationAcceptance1 SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationAcceptance1 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_LOCAL AUTHORIZATION IUSR_SQL_UA_A1
-- Make IUSR_SQL_UA_A1 the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_A1;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_A1
GRANT CREATE QUEUE to     IUSR_SQL_UA_A1
GRANT CREATE SERVICE to   IUSR_SQL_UA_A1
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_A1
GRANT VIEW DEFINITION to  IUSR_SQL_UA_A1

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_A1
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_A1
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_A1
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_A1'
GRANT SELECT TO IUSR_SQL_UA_A1
*/

-------------------------------------------------------------------------------------------------------
-- A2
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationAcceptance2 SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationAcceptance2 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_A2 AUTHORIZATION IUSR_SQL_UA_A2
-- Make IUSR_SQL_UA_A2 the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_A2;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_A2
GRANT CREATE QUEUE to     IUSR_SQL_UA_A2
GRANT CREATE SERVICE to   IUSR_SQL_UA_A2
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_A2
GRANT VIEW DEFINITION to  IUSR_SQL_UA_A2

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_A2
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_A2
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_A2
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_A2'
GRANT SELECT TO IUSR_SQL_UA_A2
*/

-------------------------------------------------------------------------------------------------------
-- A3
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationAcceptance3 SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationAcceptance3 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_A3 AUTHORIZATION IUSR_SQL_UA_A3
-- Make IUSR_SQL_UA_A3 the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_A3;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_A3
GRANT CREATE QUEUE to     IUSR_SQL_UA_A3
GRANT CREATE SERVICE to   IUSR_SQL_UA_A3
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_A3
GRANT VIEW DEFINITION to  IUSR_SQL_UA_A3

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_A3
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_A3
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_A3
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_A3'
GRANT SELECT TO IUSR_SQL_UA_A3
*/

-------------------------------------------------------------------------------------------------------
-- A4
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationAcceptance4 SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationAcceptance4 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_A4 AUTHORIZATION IUSR_SQL_UA_A4
-- Make IUSR_SQL_UA_A4 the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_A4;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_A4
GRANT CREATE QUEUE to     IUSR_SQL_UA_A4
GRANT CREATE SERVICE to   IUSR_SQL_UA_A4
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_A4
GRANT VIEW DEFINITION to  IUSR_SQL_UA_A4

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_A4
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_A4
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_A4
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_A4'
GRANT SELECT TO IUSR_SQL_UA_A4
*/

-------------------------------------------------------------------------------------------------------
-- A5
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationAcceptance5 SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationAcceptance5 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_A5 AUTHORIZATION IUSR_SQL_UA_A5
-- Make IUSR_SQL_UA_A3 the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_A5;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_A5
GRANT CREATE QUEUE to     IUSR_SQL_UA_A5
GRANT CREATE SERVICE to   IUSR_SQL_UA_A5
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_A5
GRANT VIEW DEFINITION to  IUSR_SQL_UA_A5

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_A5
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_A5
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_A5
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_A5'
GRANT SELECT TO IUSR_SQL_UA_A5
*/

-------------------------------------------------------------------------------------------------------
-- QA
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationQA SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationQA SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_QA AUTHORIZATION IUSR_SQL_UA_QA
-- Make IUSR_SQL_UA_QA the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_QA;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_QA
GRANT CREATE QUEUE to     IUSR_SQL_UA_QA
GRANT CREATE SERVICE to   IUSR_SQL_UA_QA
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_QA
GRANT VIEW DEFINITION to  IUSR_SQL_UA_QA

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_QA
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_QA
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_QA
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_QA'
GRANT SELECT TO IUSR_SQL_UA_QA
*/

-------------------------------------------------------------------------------------------------------
-- DEMO
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationDemo SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationDemo SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_RW_DEMO AUTHORIZATION IUSR_SQL_UA_RW_DEMO
-- Make IUSR_SQL_UA_RW_DEMO the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_RW_DEMO;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_RW_DEMO
GRANT CREATE QUEUE to     IUSR_SQL_UA_RW_DEMO
GRANT CREATE SERVICE to   IUSR_SQL_UA_RW_DEMO
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_RW_DEMO
GRANT VIEW DEFINITION to  IUSR_SQL_UA_RW_DEMO

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_RW_DEMO
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_RW_DEMO
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_RW_DEMO
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_RW_DEMO'
GRANT SELECT TO IUSR_SQL_UA_RW_DEMO
*/

-------------------------------------------------------------------------------------------------------
-- Production
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplication SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplication SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_RW_PROD AUTHORIZATION IUSR_SQL_UA_RW_PROD
-- Make IUSR_SQL_UA the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_RW_PROD;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_RW_PROD
GRANT CREATE QUEUE to     IUSR_SQL_UA_RW_PROD
GRANT CREATE SERVICE to   IUSR_SQL_UA_RW_PROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_RW_PROD
GRANT VIEW DEFINITION to  IUSR_SQL_UA_RW_PROD

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_RW_PROD
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_RW_PROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_RW_PROD
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_RW_PROD'
GRANT SELECT TO IUSR_SQL_UA_RW_PROD
*/

-------------------------------------------------------------------------------------------------------
-- CURRENTPRODUCTION
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationCurrentProduction SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationCurrentProduction SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_RW_CURPROD AUTHORIZATION IUSR_SQL_UA_RW_CURPROD
-- Make IUSR_SQL_UA_TEST the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_RW_CURPROD;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_RW_CURPROD
GRANT CREATE QUEUE to     IUSR_SQL_UA_RW_CURPROD
GRANT CREATE SERVICE to   IUSR_SQL_UA_RW_CURPROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_RW_CURPROD
GRANT VIEW DEFINITION to  IUSR_SQL_UA_RW_CURPROD

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_RW_CURPROD
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_RW_CURPROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_RW_CURPROD
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_RW_CURPROD'
GRANT SELECT TO IUSR_SQL_UA_RW_CURPROD
*/

-------------------------------------------------------------------------------------------------------
-- PROPOSEDPRODUCTION
-------------------------------------------------------------------------------------------------------
/*
ALTER DATABASE UniversalApplicationProposedProduction SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
--ALTER DATABASE UniversalApplicationProposedProduction SET NEW_BROKER WITH ROLLBACK IMMEDIATE
EXEC sp_addrole 'sql_dependency_subscriber'

-- CREATE SCHEMA IUSR_SQL_UA_RW_PROPROD AUTHORIZATION IUSR_SQL_UA_RW_PROPROD
-- Make IUSR_SQL_UA_RW_PROPROD the owner of the sql_dependency_subscriber schema
-- ALTER AUTHORIZATION ON SCHEMA::sql_dependency_subscriber TO IUSR_SQL_UA_RW_PROPROD;

GRANT CREATE PROCEDURE to IUSR_SQL_UA_RW_PROPROD
GRANT CREATE QUEUE to     IUSR_SQL_UA_RW_PROPROD
GRANT CREATE SERVICE to   IUSR_SQL_UA_RW_PROPROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
					   to IUSR_SQL_UA_RW_PROPROD
GRANT VIEW DEFINITION to  IUSR_SQL_UA_RW_PROPROD

GRANT SUBSCRIBE QUERY NOTIFICATIONS TO			 IUSR_SQL_UA_RW_PROPROD
GRANT RECEIVE ON QueryNotificationErrorsQueue TO IUSR_SQL_UA_RW_PROPROD
GRANT REFERENCES on CONTRACT::[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification] 
											  TO IUSR_SQL_UA_RW_PROPROD
EXEC sp_addrolemember 'sql_dependency_subscriber', 'IUSR_SQL_UA_RW_PROPROD'
GRANT SELECT TO IUSR_SQL_UA_RW_PROPROD
*/