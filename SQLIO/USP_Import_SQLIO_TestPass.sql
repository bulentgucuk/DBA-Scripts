
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[USP_Import_SQLIO_TestPass]
		@ServerName         NVARCHAR(50),
		@DriveQty           INT,
		@DriveRPM           INT,
		@DriveRaidLevel     NVARCHAR(10),
		@TestDate           DATETIME,
		@SANmodel           NVARCHAR(50),
		@SANfirmware        NVARCHAR(50),
		@PartitionOffset    INT,
		@Filesystem         NVARCHAR(50),
		@FSClusterSizeBytes INT
AS

SET NOCOUNT OFF
  
  IF @TestDate IS NULL
    SET @TestDate = Getdate()

  /* Add a blank record to the end so the last test result is captured */
  INSERT INTO dbo.SQLIO_Import
    (ParameterRowID, 
     ResultText)
  VALUES
    (0,
     '');
                               
  /* Update the ParameterRowID field for easier querying */
  UPDATE dbo.sqlio_import
  SET    parameterrowid = (SELECT   TOP 1 rowid
                           FROM     dbo.sqlio_import parm
                           WHERE    parm.resulttext LIKE '%\%'
                                    AND parm.rowid <= upd.rowid
                           ORDER BY rowid DESC)
  FROM   dbo.sqlio_import upd
         
  /* Add new SQLIO_TestPass records from SQLIO_Import */
  INSERT INTO dbo.sqlio_testpass
             (servername,
              driveqty,
              driverpm,
              driveraidlevel,
              testdate,
              sanmodel,
              sanfirmware,
              partitionoffset,
              filesystem,
              fsclustersizebytes,
              sqlio_version,
              threads,
              readorwrite,
              durationseconds,
              sectorsizekb,
              iopattern,
              iosoutstanding,
              buffering,
              filesizemb,
              ios_sec,
              mbs_sec,
              latencyms_min,
              latencyms_avg,
              latencyms_max)

             
  SELECT   @ServerName,
           @DriveQty,
           @DriveRPM,
           @DriveRaidLevel,
           @TestDate,
           @SANmodel,
           @SANfirmware,
           @PartitionOffset,
           @Filesystem,
           @FSClusterSizeBytes,
           (SELECT REPLACE(resulttext,'sqlio ','')
            FROM   dbo.sqlio_import impsqlio_version
            WHERE  imp.rowid - 1 = impsqlio_version.rowid) AS sqlio_version,
           (SELECT LEFT(resulttext,(Charindex(' threads',resulttext)))
            FROM   dbo.sqlio_import impthreads
            WHERE  imp.rowid + 3 = impthreads.rowid) AS threads,
           (SELECT Upper(Substring(resulttext,(Charindex('threads ',resulttext)) + 8,
                                   1))
            FROM   dbo.sqlio_import impreadorwrite
            WHERE  imp.rowid + 3 = impreadorwrite.rowid) AS readorwrite,
           (SELECT Substring(resulttext,(Charindex(' for',resulttext)) + 4,
                             (Charindex(' secs ',resulttext)) - (Charindex(' for',resulttext)) - 4)
            FROM   dbo.sqlio_import impdurationseconds
            WHERE  imp.rowid + 3 = impdurationseconds.rowid) AS durationseconds,
           (SELECT Substring(resulttext,7,(Charindex('KB',resulttext)) - 7)
            FROM   dbo.sqlio_import impsectorsizekb
            WHERE  imp.rowid + 4 = impsectorsizekb.rowid) AS sectorsizekb,
           (SELECT Substring(resulttext,(Charindex('KB ',resulttext)) + 3,
                             (Charindex(' IOs',resulttext)) - (Charindex('KB ',resulttext)) - 3)
            FROM   dbo.sqlio_import impiopattern
            WHERE  imp.rowid + 4 = impiopattern.rowid) AS iopattern,
           (SELECT Substring(resulttext,(Charindex('with ',resulttext)) + 5,
                             (Charindex(' outstanding',resulttext)) - (Charindex('with ',resulttext)) - 5)
            FROM   dbo.sqlio_import impiosoutstanding
            WHERE  imp.rowid + 5 = impiosoutstanding.rowid) AS iosoutstanding,
           (SELECT REPLACE(CAST(resulttext AS NVARCHAR(100)),'buffering set to ',
                           '')
            FROM   dbo.sqlio_import impbuffering
            WHERE  imp.rowid + 6 = impbuffering.rowid) AS buffering,
           (SELECT Substring(resulttext,(Charindex('size: ',resulttext)) + 6,
                             (Charindex(' for ',resulttext)) - (Charindex('size: ',resulttext)) - 9)
            FROM   dbo.sqlio_import impfilesizemb
            WHERE  imp.rowid + 7 = impfilesizemb.rowid) AS filesizemb,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 10))
            FROM   dbo.sqlio_import impios_sec
            WHERE  imp.rowid + 11 = impios_sec.rowid) AS ios_sec,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 10))
            FROM   dbo.sqlio_import impmbs_sec
            WHERE  imp.rowid + 12 = impmbs_sec.rowid) AS mbs_sec,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_min
            WHERE  imp.rowid + 14 = implatencyms_min.rowid) AS latencyms_min,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_avg
            WHERE  imp.rowid + 15 = implatencyms_avg.rowid) AS latencyms_avg,
           (SELECT RIGHT(resulttext,(Len(resulttext) - 17))
            FROM   dbo.sqlio_import implatencyms_max
            WHERE  imp.rowid + 16 = implatencyms_max.rowid) AS latencyms_max
  FROM     dbo.sqlio_import imp
           INNER JOIN dbo.sqlio_import impfulltest
             ON imp.rowid + 20 = impfulltest.rowid
                AND impfulltest.resulttext = ''
  --WHERE    imp.rowid = imp.parameterrowid
           /***AND (SELECT Substring(resulttext,(Charindex('size: ',resulttext)) + 6,
                                 (Charindex(' for ',resulttext)) - (Charindex('size: ',resulttext)) - 9)
                FROM   dbo.sqlio_import impfilesizemb
                WHERE  imp.rowid + 7 = impfilesizemb.rowid) > 0   ***/
  ORDER BY imp.parameterrowid
           
/* Empty out the ETL table */

IF @@ROWCOUNT > 0
	BEGIN
		TRUNCATE TABLE dbo.sqlio_import
	END
         
SET nocount off

GO


