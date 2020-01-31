<#
VERSION 18.4 works to import to the existing empty database
SqlPackage import bacpac file into database using 
ADPassword with MFA
#>
Clear-Host;
set-location 'C:\Program Files\Microsoft SQL Server\150\DAC\bin\';
.\SqlPackage.exe /a:Import /sf:"C:\Temp\SSBRPTest_20200115_1530_UTC.bacpac" /tcs:"Data Source=ssb-dev-databases.database.windows.net;Initial Catalog=SSBRPTest_import;" /ua:True /tid:"ssbinfo.com";
