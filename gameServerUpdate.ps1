# Custom logging function with timestamp
function Log-Message($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    [Console]::WriteLine("$timestamp $message")
}

# Ensure the script's working directory is where the script is located
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location -Path $scriptPath

# Customizable Variables
$intervalSeconds = 3600 # Check interval in seconds
$steamAppID = "376030" # Steam AppID for ARK: Survival Evolved Dedicated Server
$steamCmdPath = "C:\Users\user\Documents\steamcmd\steamcmd.exe" # Full path to steamcmd.exe
$outputFilePath = ".\steamcmd_output.txt" # Temporary file to store steamcmd output
$lastUpdateTimeFile = ".\lastUpdateTime.txt" # File to store the last "timeupdated" value
$exeName = "ShooterGameServer" # The name of the EXE file you want to kill (without '.exe')
$batchFilePath = ".\gameExecuteUpdate.bat" # Path to the batch file for updates
$exePath = "C:\Users\user\Documents\steamcmd\steamapps\common\ARK Survival Evolved Dedicated Server\ShooterGame\Binaries\Win64\ShooterGameServer.exe" # Full path to the EXE file to start with arguments
$restartFlagPath = ".\lastRestartDate.txt" # File to track the last restart date

function IsServerRunning {
    $serverProcess = Get-Process $exeName -ErrorAction SilentlyContinue
    return $serverProcess -ne $null
}

function KillProcess {
    try {
        Get-Process $exeName -ErrorAction Stop | Stop-Process -Force
        Log-Message "Process $exeName stopped."
    } catch {
        Log-Message "Failed to stop process $exeName. It may not have been running."
    }
}

function RunBatchFile {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFilePath`"" -Wait -NoNewWindow
    Log-Message "Batch file for updates has been executed."
}

function StartServer {
    $arguments = "TheIsland?SessionName=GameServerExample?ServerPassword=Passwort?Port=7777?QueryPort=27015?MaxPlayers=10?ServerAdminPassword=boingo"
    Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow
    Log-Message "ARK server started with specified arguments."
}

function RestartServerIfNeeded {
    $currentTime = Get-Date
    $currentHour = $currentTime.Hour
    $lastRestartDate = if (Test-Path $restartFlagPath) { Get-Content $restartFlagPath } else { "1970-01-01" }

    if ($currentHour -ge 2 -and $currentHour -lt 3 -and $lastRestartDate -ne $currentTime.ToString("yyyy-MM-dd")) {
        # The actual restart operations are commented out to prevent accidental restarts during testing
        # KillProcess
        # StartServer
        $currentTime.ToString("yyyy-MM-dd") | Out-File $restartFlagPath
        Log-Message "Server was intended to restart on $($currentTime.ToString('yyyy-MM-dd')), but auto-restart is disabled."
    }
}

function CheckForUpdate {
    $success = $false
    $updateFound = $false
    $attemptCount = 0
    $maxAttempts = 10

    while (-not $success -and $attemptCount -lt $maxAttempts) {
        $attemptCount++
        Log-Message "Attempt $attemptCount of $maxAttempts"

        Start-Process -FilePath $steamCmdPath -ArgumentList "+login anonymous +app_info_update 1 +app_info_print $steamAppID +quit" -NoNewWindow -RedirectStandardOutput $outputFilePath -Wait
        Start-Sleep -Seconds 2

        if (Test-Path $outputFilePath) {
            $steamCmdOutput = Get-Content $outputFilePath -Raw
            Remove-Item $outputFilePath -Force

            if ($steamCmdOutput -match '"timeupdated"\s+"(\d+)"') {
                $currentTimeUpdated = $matches[1]
                $lastUpdateTime = if (Test-Path $lastUpdateTimeFile) { Get-Content $lastUpdateTimeFile } else { "0" }

                if ([int64]$currentTimeUpdated -gt [int64]$lastUpdateTime) {
                    $currentTimeUpdated | Out-File $lastUpdateTimeFile
                                        Log-Message "New update found for AppID $steamAppID. 'timeupdated' value is newer than the last check."
                    $updateFound = $true
                    $success = $true
                } else {
                    Log-Message "Checked successfully but no new update found. 'timeupdated' value has not changed."
                    $success = $true
                }
            } else {
                Log-Message "Did not find 'timeupdated' in the output, trying again..."
            }
        } else {
            Log-Message "Output file not found, trying again..."
        }

        Start-Sleep -Seconds 2
    }

    if (-not $success) {
        Log-Message "Failed to check for update after $maxAttempts attempts, will try again in the next interval."
    } elseif ($updateFound) {
        KillProcess
        RunBatchFile
        # Wait a moment for any update processes to finalize
        Start-Sleep -Seconds 10
        if (-not IsServerRunning) {
            Log-Message "Server is not running after updates. Attempting to start the server..."
            StartServer
        } else {
            Log-Message "Server update process completed, and the server is already running."
        }
    }
}

# Initial check and update attempt
CheckForUpdate

# Schedule subsequent checks at the defined interval and include server restart check
while ($true) {
    Start-Sleep -Seconds $intervalSeconds
    CheckForUpdate
    RestartServerIfNeeded # This function checks if the server needs to be restarted and will restart it if necessary.
}
