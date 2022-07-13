$BitlockerStatus = Get-BitLockerVolume -MountPoint $env:SystemDrive
$status = $BitlockerStatus.VolumeStatus
$algorithm = $BitlockerStatus.EncryptionMethod
$BitlockerCheck = 'C:\Windows\BTL256.txt'							# verification we used to filter if powershell script needs to be pushed
$Command = "C:\Windows\system32\deviceenroller.exe"
$Parms1 = "/o /%i /c /z"
$Prms1 = $Parms1.Split(" ")
$Parms2 = "/o /%i /c /b"
$Prms2 = $Parms2.Split(" ")
$Parms3 = "/o /%i /c /y"
$Prms3 = $Parms3.Split(" ")

##### Check if WinRE is disabled, if not then enable, this is needed for Bitlocker to be activated #####

if((reagentc /info | Where-Object{$_ -like "*Windows RE status:         Disabled*"}))
{
	reagentc /enable	
}


##### Check if drive is encrypted #####
if ($status -eq 'FullyEncrypted')
{
	
##### Check encryption method equals <YourEncryptionMethod> #####
if ($algorithm -eq 'XtsAes256')
	{
##### Create file for filter #####
	if(-not(Test-path $BitlockerCheck -PathType leaf))
		{
		New-Item -ItemType File -Path $BitlockerCheck -Force
		}
	}

Else
	{
##### Sync with intune to get AES256 policy, we want the policy before new encryption starts #####
		& "$Command" $Prms1
		& "$Command" $Prms2
		& "$Command" $Prms3
		Start-Sleep -Seconds 60
		
##### Decrypt if encryption method is not XtsAes256 #####
		Disable-BitLocker -MountPoint $env:SystemDrive

##### Check if decrypt is finish #####
While ( (Get-BitLockerVolume -MountPoint $env:SystemDrive).EncryptionPercentage -gt 0 ) 
		{
		Start-Sleep -Seconds 60
		}

##### Sync with intune to start encryption (just an extra, because "intune" #####
		Start-Sleep -Seconds 60
		& "$Command" $Prms1
		& "$Command" $Prms2
		& "$Command" $Prms3
	}
}

##### Check if drive is not encrypted then sync with intune (sync again to start encryption) #####
if ($status -eq 'FullyDecrypted')
{
##### Sync with intune #####
& "$Command" $Prms1
& "$Command" $Prms2
& "$Command" $Prms3

}
