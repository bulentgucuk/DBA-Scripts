USE MASTER
GO
CREATE DATABASE DatabaseNameToBeAttached
      ON	(FILENAME = 'C:\Data\Databases\DatabaseNameToBeAttached_Data.mdf'),
			(FILENAME = 'C:\Data\Databases\DatabaseNameToBeAttached_Log.ldf')
      FOR ATTACH;




