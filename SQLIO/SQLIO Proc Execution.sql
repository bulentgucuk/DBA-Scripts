/****
EXECUTE [dbo].[USP_Import_SQLIO_TestPass] 
@ServerName NVARCHAR(50) - the name of the server you're using for testing. This is mostly useful for servers with locally attached storage as opposed to SAN storage.
@DriveQty INT - the number of drives in the array you're testing.
@DriveRPM INT - you might be testing 10k and 15k variations of the same setup. I suggest lumping drives into categories - don't try to differentiate between drives that report 10,080 RPM or other odd numbers - just stick with 5400, 10000, 150000, etc. For SSD, I prefer to use a number for the generation of SSD, like 1 or 2.
@DriveRaidLevel NVARCHAR(10) - raid 5, raid 0, raid 10, raid DP, etc. (Yes, there are vendor-specific RAID implementations that use letters instead of numbers.)
@TestDate DATETIME - the date you're running the tests. I include this as a parameter because sometimes I've run the same tests on a quarterly basis and I want to track whether things are changing over time.
@SANmodel NVARCHAR(50) - the type of SAN, such as an IBM DS4800 or EMC CX300.
@SANfirmware NVARCHAR(50) - the version of firmware, which can impact SAN performance.
@PartitionOffset INT - Windows systems can use DISKPART to offset their partitions.
@Filesystem NVARCHAR(50) - usually NTFS. Can be used to track testing different filesystems.
@FSClusterSizeBytes INT - the file system cluster size.

***/

EXECUTE [dbo].[USP_Import_SQLIO_TestPass] 
   @ServerName =  'SQLCLR04-P'
  ,@DriveQty = 8
  ,@DriveRPM = 15000
  ,@DriveRaidLevel = 'RAID 5'
  ,@TestDate = '2011/10/04'
  ,@SANmodel = 'SUN 6580'
  ,@SANfirmware = 'XX.XX'
  ,@PartitionOffset = 1024
  ,@Filesystem = 'NTFS'
  ,@FSClusterSizeBytes = '64000'
  
  
