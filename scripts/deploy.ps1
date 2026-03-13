###############################################################################
# deploy.ps1 — Deploy GCP Landing Zone layers in order
#
# Usage:
#   .\scripts\deploy.ps1                       # Deploy all GCP layers (00-06)
#   .\scripts\deploy.ps1 -IncludeAzure         # Also deploy Azure hybrid VPN
#   .\scripts\deploy.ps1 -StartFrom 3          # Start from layer 03
###############################################################################
param(
    [switch]$IncludeAzure,
    [int]$StartFrom = 0
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $PSScriptRoot

$layers = @(
    @{ Path = "$ROOT\foundation\00-bootstrap";      Name = "00-bootstrap";      NeedsBackend = $false },
    @{ Path = "$ROOT\foundation\01-org";             Name = "01-org";             NeedsBackend = $true },
    @{ Path = "$ROOT\foundation\02-security";        Name = "02-security";        NeedsBackend = $true },
    @{ Path = "$ROOT\foundation\03-network-hub";     Name = "03-network-hub";     NeedsBackend = $true },
    @{ Path = "$ROOT\foundation\04-observability";   Name = "04-observability";   NeedsBackend = $true },
    @{ Path = "$ROOT\environments\dev";              Name = "env-dev";            NeedsBackend = $true },
    @{ Path = "$ROOT\environments\prod";             Name = "env-prod";           NeedsBackend = $true }
)

if ($IncludeAzure) {
    $layers += @{ Path = "$ROOT\azure"; Name = "azure-hybrid-vpn"; NeedsBackend = $true }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " GCP Landing Zone — Deployment Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

for ($i = $StartFrom; $i -lt $layers.Count; $i++) {
    $layer = $layers[$i]
    $name = $layer.Name
    $path = $layer.Path

    Write-Host "`n>>> Deploying [$name] <<<" -ForegroundColor Yellow
    Write-Host "    Path: $path" -ForegroundColor DarkGray

    if (-not (Test-Path "$path\main.tf")) {
        Write-Host "    [SKIP] main.tf not found — skipping" -ForegroundColor DarkYellow
        continue
    }

    Push-Location $path
    try {
        # Init
        if ($layer.NeedsBackend -and (Test-Path "backend.hcl")) {
            Write-Host "    terraform init (with backend.hcl)..." -ForegroundColor DarkGray
            terraform init "-backend-config=backend.hcl" -input=false -no-color
        } else {
            Write-Host "    terraform init..." -ForegroundColor DarkGray
            terraform init -input=false -no-color
        }
        if ($LASTEXITCODE -ne 0) { throw "terraform init failed for $name" }

        # Plan
        Write-Host "    terraform plan..." -ForegroundColor DarkGray
        terraform plan -out=tfplan -input=false -no-color
        if ($LASTEXITCODE -ne 0) { throw "terraform plan failed for $name" }

        # Apply
        Write-Host "    terraform apply..." -ForegroundColor DarkGray
        terraform apply -input=false -no-color tfplan
        if ($LASTEXITCODE -ne 0) { throw "terraform apply failed for $name" }

        Remove-Item -Force tfplan -ErrorAction SilentlyContinue
        Write-Host "    [OK] $name deployed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "    [ERROR] $name failed: $_" -ForegroundColor Red
        Write-Host "    Fix the issue and re-run with: .\scripts\deploy.ps1 -StartFrom $i" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Deployment complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
