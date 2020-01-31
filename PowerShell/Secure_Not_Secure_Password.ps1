Clear-Host;
$secpasswd = ConvertTo-SecureString "IsThatYourBestPassWord?" -AsPlainText -Force;
$mycreds = New-Object System.Management.Automation.PSCredential ("ssb_bgucuk", $secpasswd);

$NotSecurePassword = [System.Net.NetworkCredential]::new("", $secpasswd).Password


$NotSecurePassword

$mycreds