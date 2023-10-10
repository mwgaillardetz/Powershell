# Define the source and destination paths
$sourcePath = " "
$destinationPath = " "

# Function to copy directories recursively
function Copy-DirectoriesRecursively($source, $destination) {
    # Get all directories in the source path
    $directories = Get-ChildItem -Path $source -Directory

    # Loop through each directory and copy it to the destination
    foreach ($directory in $directories) {
        $destinationDir = Join-Path -Path $destination -ChildPath $directory.Name
        New-Item -Path $destinationDir -ItemType Directory -Force
        Copy-DirectoriesRecursively $directory.FullName $destinationDir
    }
}

# Start the recursive copying process
Copy-DirectoriesRecursively $sourcePath $destinationPath
