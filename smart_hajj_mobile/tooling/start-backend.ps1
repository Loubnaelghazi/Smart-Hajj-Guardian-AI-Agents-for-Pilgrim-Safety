param(
    [string]$Distribution = 'Debian',
    [string]$ProjectPath = '/home/Lubna/projects/ia/smart_hajj_guardian_tier1/smart_hajj_guardian'
)
$ErrorActionPreference = 'Stop'
# Run Compose in the distribution which owns the Linux bind-mount source.
# Do not run `down -v`: MongoDB data must be preserved.
wsl -d $Distribution --cd $ProjectPath -- docker compose up -d --no-deps --force-recreate backend
if ($LASTEXITCODE -ne 0) { throw 'Backend recreation failed.' }
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    try {
        $health = Invoke-RestMethod 'http://localhost:8000/health' -TimeoutSec 3
        if ($health.status -eq 'ok' -and $health.mongodb -eq $true) {
            Write-Output 'FastAPI and MongoDB are ready.'
            return
        }
    } catch { }
    Start-Sleep -Seconds 1
}
throw 'Backend did not become healthy. Check docker logs smart-hajj-backend.'
