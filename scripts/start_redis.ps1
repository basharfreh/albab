# Starts the local Redis-compatible server for backend dev.
# Native Windows Redis has no MSI-installable build that survives this machine's
# Smart App Control policy (the installer's helper DLL gets blocked), so the
# server binary was extracted directly from the MSI instead of installed as a
# service. Run this once per dev session before `manage.py runserver`.
$exe = "C:\dev\redis\Redis\redis-server.exe"
$conf = "C:\dev\redis\Redis\redis.windows.conf"
if (Get-Process redis-server -ErrorAction SilentlyContinue) {
    Write-Host "redis-server already running."
} else {
    Start-Process -FilePath $exe -ArgumentList "`"$conf`"" -WindowStyle Hidden
    Start-Sleep -Seconds 1
    Write-Host "redis-server started."
}
