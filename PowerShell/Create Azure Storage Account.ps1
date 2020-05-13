Get-AzStorageAccount
 
    
#Create Storage Account
New-AzStorageAccount -ResourceGroupName “SL-PowerShellStorage” -AccountName “slstoreps1” -Location “eastus” -SkuName “Standard_LRS” 
    
 
<#
SKU Options
• Standard_LRS. Locally-redundant storage.
• Standard_ZRS. Zone-redundant storage.
• Standard_GRS. Geo-redundant storage.
• Standard_RAGRS. Read access geo-redundant storage.
• Premium_LRS. Premium locally-redundant storage.
 
Optional Key Parameters
-Kind
 
The kind parameter will allow you to specify the type of Storage Account.
• Storage - General purpose Storage account that supports storage of Blobs, Tables, Queues, Files and Disks.
• StorageV2 - General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues,
 