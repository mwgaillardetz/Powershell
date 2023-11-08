# Almost complete - need to refine condition report process. 
# Script checks Blizzard's site every 10 minutes and reports to your discord server when your realm is online and ready to rumble. 

# Define the URL of the World of Warcraft server status page
$url = "https://worldofwarcraft.blizzard.com/en-us/game/status/us"

# Define the Discord webhook URL
$discordWebhook = "your-discord-webhook"

# Define the realm name you want to monitor
$realmToMonitor = "Gurubashi"

# Function to send a message to Discord
function Send-DiscordMessage($content) {
    $payload = @{
        content = $content
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $discordWebhook -Method Post -Body $payload -ContentType "application/json"
}

# Function to check if the realm is online
function Check-RealmStatus($htmlContent) {
    if ($htmlContent -match "Gurubashi" -and $htmlContent -match "normal") {
        return $true
    }
    return $false
}

# Main loop
while ($true) {
    try {
        $webResponse = Invoke-WebRequest -Uri $url
        $htmlContent = $webResponse.Content

        if (Check-RealmStatus $htmlContent) {
            $message = "The realm $realmToMonitor is online now!"
            Send-DiscordMessage $message
        }
        else {
            $message = "The realm $realmToMonitor is currently offline."
            Send-DiscordMessage $message
        }

        # Sleep for 10 minutes
        Start-Sleep -Seconds 600
    }
    catch {
        $errorMessage = "An error occurred: $_"
        Send-DiscordMessage $errorMessage

        # Sleep for 10 minutes even in case of an error
        Start-Sleep -Seconds 600
    }
}
