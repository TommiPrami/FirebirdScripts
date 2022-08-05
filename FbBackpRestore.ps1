Write-Host ""
Write-Host "BACKUP AND RESTORE DATABASES"
Write-Host ""

# Initialize "Global" variables
$G_FIREBIRD_PATH = "C:\Program Files (x86)\Firebird\Firebird_2_5\bin"
$G_GBAK = "$G_FIREBIRD_PATH\gbak.exe"
$G_FB_SERVER = "127.0.0.1"
$G_USER_NAME = "SYSDBA"
$G_PASSWORD = "masterkey"
$G_DB_BUFFERS = 9999
$G_DB_PAGE_SIZE = 16384

function GetBackupFileName
{
  param(
    [Parameter(Mandatory=$true)] [string] $ADatabaseFile
  )

  $LBackUpFileName = $(Split-Path -Path $ADatabaseFile) + $("\") + $(Split-Path -Leaf $ADatabaseFile)

  $LBackUpFileName = [Regex]::Replace($LBackUpFileName, 
    [regex]::Escape(".fdb"), ".fbk",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

  return $LBackUpFileName
}

function NormalizeDeleteBackupFileParameter
{
  param(
    [Parameter(Mandatory=$true)] [System.Boolean] $ADeleteBackupFile
  ) 
  
  if (!($ADeleteBackupFile))
  {
    $ADeleteBackupFile = $false
  }  

  return $ADeleteBackupFile
}

function FBBackup
{
  param(
    [Parameter(Mandatory=$true)] [string] $ADatabaseFile,
    [Parameter(Mandatory=$true)] [string] $ABackupFileName
  ) 
  
  # Commadline thingy
  $LBackupCommandline = " -v -t -user $G_USER_NAME -password ""$G_PASSWORD"" ${G_FB_SERVER}:""$ADatabaseFile"" ""$ABackupFileName"

  Write-Host "Running backup: GBak.exe $LBackupCommandline"
  Start-Process -FilePath "$G_GBAK" -ArgumentList "$LBackupCommandline" -Wait

  if (-Not (Test-Path $ABackupFileName))
  {
    Write-Host "  - FAIL: Backupfile [$ABackupFileName] does not exist"
    Exit 1
  }
}

function FBRestore
{
  param(
    [Parameter(Mandatory=$true)] [string] $ABackupFile,
    [Parameter(Mandatory=$true)] [string] $ADatabaseFile,
    [Parameter(Mandatory=$false)] [System.Boolean] $ADeleteBackupFile
  ) 

  $ADeleteBackupFile = $(NormalizeDeleteBackupFileParameter $ADeleteBackupFile)
  
  # Commadline thingy
  # gbak -r o -v -user SYSDBA -password masterkey c:\backups\warehouse.fbk dbserver:/db/warehouse.fdb
  $LRestoreCommandline = " -bu ""$G_DB_BUFFERS"" -p ""$G_DB_PAGE_SIZE"" -r o -v -user $G_USER_NAME -password ""$G_PASSWORD"" ""$ABackupFile"" ${G_FB_SERVER}:""$ADatabaseFile""" 

  Write-Host "Running restore: GBak.exe $LRestoreCommandline"
  Start-Process -FilePath "$G_GBAK" -ArgumentList "$LRestoreCommandline" -Wait

  if ($ADeleteBackupFile) 
  {
    Remove-Item -Path "$ABackupFile" -Force

    if (Test-Path $ABackupFile)
    {
      Write-Host "  - FAIL: Backupfile [$ABackupFile] should not does not exist"
      Exit 1
    }    
  }

  if (-Not (Test-Path $ADatabaseFile))
  {
    Write-Host "  - FAIL: Database file [$ADatabaseFile] does not exist"
    Exit 1
  }
}

function FBBackupAndRestore
{
  param(
    [Parameter(Mandatory=$true)] [string] $ADatabaseFile,
    [Parameter(Mandatory=$false)] [System.Boolean] $ADeleteBackupFile
  ) 

  $ADeleteBackupFile = $(NormalizeDeleteBackupFileParameter $ADeleteBackupFile)

  $LBackupFileName = GetBackupFileName $ADatabaseFile

  FBBackup $ADatabaseFile $LBackupFileName
  FBRestore $LBackupFileName $ADatabaseFile $ADeleteBackupFile
}

FBBackupAndRestore "C:\Data\Test\DEMO.FDB" $true
