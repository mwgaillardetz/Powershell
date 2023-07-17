# Transcibe process
Start-Transcript -path "C:\logs\plex-itunes-sync.log" -Force

# Plex server details
$plexServerUrl = "http://localhost:32400"
$plexToken = "YOUR-TOKEN"

# iTunes XML library file path
$iTunesLibraryPath = "C:\YOUR\ITUNES\XML\FILE"

# Retrieve iTunes playlist information from the XML library
$iTunesPlaylists = [xml](Get-Content -Path $iTunesLibraryPath)
$playlistTracks = $iTunesPlaylists.plist.dict.array.dict | Where-Object { $_.key -eq "Playlists" }

# Loop through iTunes playlists and sync with Plex
foreach ($playlist in $playlistTracks) {
    $playlistName = $playlist.string[0]
    $tracks = $playlist.array.dict | Where-Object { $_.key -eq "Track ID" } | ForEach-Object { $_.integer.Value }

    # Create a new Plex playlist
    $plexPlaylistPayload = @{
        "type" = "audio"
        "title" = $playlistName
    } | ConvertTo-Json

    $plexPlaylistResponse = Invoke-RestMethod -Uri "$plexServerUrl/playlists?X-Plex-Token=$plexToken" -Method Post -Body $plexPlaylistPayload

    # Add tracks to the Plex playlist
    foreach ($trackId in $tracks) {
        $plexTrackUri = "$plexServerUrl/library/metadata/$trackId?X-Plex-Token=$plexToken"
        Invoke-RestMethod -Uri "$plexPlaylistResponse.playlist.add.item?uri=$plexTrackUri" -Method Put
    }

    Write-Host "Playlist '$playlistName' synced with Plex."
}

# Stop Transcribe
Stop-Transcript
