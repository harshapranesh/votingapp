param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("blue","green")]
    [string]$env
)

$composeFile = "deploy/compose/docker-compose.$env.yml"

Write-Host ""
Write-Host "=== Deploying $env environment ==="
Write-Host "Using compose file: $composeFile"
Write-Host ""

# Pull latest images
docker compose -f $composeFile pull
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pull failed." -ForegroundColor Red
    exit 1
}

# Start or update containers
docker compose -f $composeFile up -d --remove-orphans
# ---- Smoke test (smart) ----
function Invoke-SmartSmokeTest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string[]]$MustContainAny,

        [int]$Retries = 10,
        [int]$SleepSeconds = 2
    )

    for ($i = 1; $i -le $Retries; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
            if ($resp.StatusCode -ne 200) {
                throw "HTTP $($resp.StatusCode)"
            }

            $body = $resp.Content
            $matched = $false
            foreach ($needle in $MustContainAny) {
                if ($body -match [regex]::Escape($needle)) {
                    $matched = $true
                    break
                }
            }

            if (-not $matched) {
                throw "Page loaded but content did not match expected keywords: $($MustContainAny -join ', ')"
            }

            Write-Host "Smoke test OK: $Url" -ForegroundColor Green
            return
        }
        catch {
            Write-Host "Smoke test retry $i/$Retries failed for ${Url} - $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds $SleepSeconds
        }
    }

    throw "Smoke test FAILED for ${Url} after $Retries retries"
}

# Decide ports based on env (blue vs green)
$votePort   = if ($env -eq "blue") { 8080 } else { 9080 }
$resultPort = if ($env -eq "blue") { 8081 } else { 9081 }

Write-Host ""
Write-Host "Running smart smoke tests for $env..." -ForegroundColor Cyan

# Vote page should contain something like Cats/Dogs or Vote
Invoke-SmartSmokeTest -Url "http://localhost:$votePort/" `
    -MustContainAny @("Cats", "Dogs", "Vote", "Voting")

# Result page should contain something like Results/Cats/Dogs
Invoke-SmartSmokeTest -Url "http://localhost:$resultPort/" `
    -MustContainAny @("Result", "Results", "Cats", "Dogs")

Write-Host "All smoke tests passed." -ForegroundColor Green
Write-Host ""
# ---- end smoke test ----
try {
    Invoke-SmartSmokeTest -Url "http://localhost:$votePort/" `
        -MustContainAny @("Cats","Dogs","Vote","Voting")

    Invoke-SmartSmokeTest -Url "http://localhost:$resultPort/" `
        -MustContainAny @("Result","Results","Cats","Dogs")

    Write-Host "All smoke tests passed." -ForegroundColor Green
}
catch {
    Write-Host "Smoke tests failed. Rolling back..." -ForegroundColor Red

    docker compose -f $composeFile down
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Up failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== $env deployment completed successfully ===" -ForegroundColor Green
Write-Host ""