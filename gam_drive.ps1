param (
    # [Parameter(Mandatory=$true)]
    [string] $gsuite_email,
    [string] $path_to_backup
)


function CheckGSuiteEmail {
	if(-not($gsuite_email)) { 
		try {
			Throw "Please enter a G Suite email address for -gsuite_email" 
		}
		catch {
			Write-Host
			Write-Host "Exception Message: $($_.Exception.Message)"
			Write-Host
			exit 10
		}
	}
}


function CheckPathToBackup {
	if(-not($path_to_backup)) {
		try {
			Throw "Please enter a path to backup for -path_to_backup WITHOUT THE TRAILING SLASH" 
		}
		catch {
			Write-Host
			Write-Host "Exception Message: $($_.Exception.Message)"
			Write-Host
			exit 20
		}
	}
}


function CreateDriveFolder {
	param (
		[string] $dir_name,
		[string] $par_name
	)
    gam `
		user "$gsuite_email" `
		add drivefile `
		drivefilename "$dir_name" `
		mimetype gfolder `
		parentname "$par_name"
}


function BackupFilesToDrive {
	param (
		[string] $backup_path,
		[string] $par_name
	)
	Set-Location $backup_path
    Get-ChildItem -File | `
		% {`
			gam `
				user "$gsuite_email" `
				add drivefile `
				localfile "$_" `
				parentname "$par_name"
		}
}


function Recurse1 {
	$directories1 = (Get-ChildItem -Directory).FullName
	foreach ($directory1 in $directories1) {
		$dir_name = (Get-Item $directory1).Name
		$par_name = (Get-Item $directory1).Parent.Name
		$backup_path = (Get-Item $directory1).FullName
		
		CreateDriveFolder -dir_name $dir_name -par_name $drive_folder
		BackupFilesToDrive -backup_path $backup_path -par_name $dir_name
		
		Recurse2
	}
}


function Recurse2 {
	$directories2 = (Get-ChildItem -Directory -Recurse).FullName
	foreach ($directory2 in $directories2) {
		$dir_name = (Get-Item $directory2).Name
		$par_name = (Get-Item $directory2).Parent.Name
		$backup_path = (Get-Item $directory2).FullName
		
		CreateDriveFolder -dir_name $dir_name -par_name $par_name
		BackupFilesToDrive -backup_path $backup_path -par_name $dir_name
	}
}


CheckGSuiteEmail
CheckPathToBackup

$backup_path = (Get-Item $path_to_backup).FullName
$bk_dir = (Get-Item $path_to_backup).Name
$drive_folder = "$(get-date -Format yyyy-MMdd_hhmmss)_backup_$bk_dir"

CreateDriveFolder -dir_name $drive_folder -par_name "/ of $gsuite_email Drive Account"
BackupFilesToDrive -backup_path $backup_path -par_name $drive_folder
Recurse1
