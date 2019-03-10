Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$appName="dvm"
$targetDir="bin"
$targetPath="$targetDir/$appName.exe"

function Build
{
  dub build --verror -b release
}

function Version
{
  Invoke-Expression "$targetPath --version"
}

function Arch
{
  if ($env:PLATFORM -eq 'x86') { '32' } else { '64' }
}

function ReleaseName
{
  "$appName-$(Version)-win$(Arch)"
}

Build
mv "$targetPath" "$targetDir/$(ReleaseName).exe"
