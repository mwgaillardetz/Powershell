# Variables
$oldSharePath = "D:\path-share-to-mirror"
$newSharePath = "D:\new-share-path"
$oldShareName = "old_share_name"
$newShareName = "new_share_name"

# Get existing share permissions
$existingShare = Get-SmbShare -Name $oldShareName -ErrorAction Stop
$existingPermissions = Get-SmbShareAccess -Name $oldShareName -ErrorAction Stop

# Create the new folder if it doesn't exist
if (-Not (Test-Path -Path $newSharePath)) {
    New-Item -ItemType Directory -Path $newSharePath | Out-Null
    Write-Host "Created folder: $newSharePath"
} else {
    Write-Host "Folder already exists: $newSharePath"
}

# Create the new share
try {
    New-SmbShare -Name $newShareName -Path $newSharePath -ErrorAction Stop
    Write-Host "Created share: $newShareName"
} catch {
    Write-Error "Failed to create share. Ensure the share name is unique and the user has permissions."
    return
}

# Apply the same share permissions
foreach ($permission in $existingPermissions) {
    Grant-SmbShareAccess -Name $newShareName -AccountName $permission.AccountName -AccessRight $permission.AccessRight -Force -ErrorAction Stop
    Write-Host "Granted $($permission.AccessRight) to $($permission.AccountName) on $newShareName"
}

# Remove default "Everyone" permissions if required
Revoke-SmbShareAccess -Name $newShareName -AccountName "Everyone" -ErrorAction SilentlyContinue
Write-Host "Revised permissions on the new share: $newShareName"
