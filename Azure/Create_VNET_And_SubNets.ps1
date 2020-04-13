#Resource Group and Location

$rg = "SL-Network"

$location = "EastUS"


#VNET Name and Address Space

$VNETName = "SL-VNET-PShell"

$VNETAddressSpace = "10.0.0.0/22"


#Subnet Configurations

$websubnet = New-AzVirtualNetworkSubnetConfig -Name "SL-Web" -AddressPrefix "10.0.0.0/24"

$appsubnet = New-AzVirtualNetworkSubnetConfig -Name "SL-App" -AddressPrefix "10.0.1.0/24"

$dbsubnet = New-AzVirtualNetworkSubnetConfig -Name "SL-Data" -AddressPrefix "10.0.2.0/24"


#Create Resource Group

New-AzResourceGroup -Name $rg -Location $location



#Create VNET and Subnets

$virtualNetwork = New-AzVirtualNetwork -Name $VNETName -ResourceGroupName $rg `

    -Location $location -AddressPrefix $VNETAddressSpace -Subnet $websubnet,$appsubnet


#Add Additional Subnet

$subnetConfig = Add-AzVirtualNetworkSubnetConfig `

  -Name "LastSubnet" `

  -AddressPrefix "10.0.4.0/24" `

  -VirtualNetwork $virtualNetwork


#Write the changes to the VNET

$virtualNetwork | Set-AzVirtualNetwork