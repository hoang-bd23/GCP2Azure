###############################################################################
# destroy-paid.ps1 — Destroy ONLY paid resources to save costs
#
# Keeps: VPC, subnets, firewall, router, folders, projects, IAM, org policies
# Removes: VMs, NAT, Load Balancers, Azure resources (optional)
#
# Usage:
#   .\scripts\destroy-paid.ps1                 # Destroy GCP paid resources
#   .\scripts\destroy-paid.ps1 -IncludeAzure   # Also destroy Azure resources
###############################################################################
param(
    [switch]$IncludeAzure
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $PSScriptRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Selective Destroy — Paid Resources Only" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Destroy Prod VM + LB
Write-Host "--- Destroying env-prod ---" -ForegroundColor Yellow
Push-Location "$ROOT\environments\prod"
try {
    terraform init "-backend-config=backend.hcl" -input=false -no-color
    terraform destroy -auto-approve -no-color
    Write-Host "    [OK] env-prod destroyed" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed: $_" -ForegroundColor Red
}
Pop-Location

# Step 2: Destroy Dev VM + LB
Write-Host "--- Destroying env-dev ---" -ForegroundColor Yellow
Push-Location "$ROOT\environments\dev"
try {
    terraform init "-backend-config=backend.hcl" -input=false -no-color
    terraform destroy -auto-approve -no-color
    Write-Host "    [OK] env-dev destroyed" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed: $_" -ForegroundColor Red
}
Pop-Location

# Step 3: Selective destroy in foundation/03-network-hub (NAT + LB only, keep VPC/Firewall/Router)
Write-Host "--- Destroying NAT in 03-network-hub ---" -ForegroundColor Yellow
Push-Location "$ROOT\foundation\03-network-hub"
try {
    terraform init "-backend-config=backend.hcl" -input=false -no-color
    terraform destroy "-target=module.nat" -auto-approve -no-color
    Write-Host "    [OK] NAT destroyed" -ForegroundColor Green
} catch {
    Write-Host "    [WARN] NAT destroy failed: $_" -ForegroundColor DarkYellow
}
Pop-Location

# Step 4: Azure (optional)
if ($IncludeAzure) {
    Write-Host "--- Destroying Azure hybrid VPN ---" -ForegroundColor Yellow
    Push-Location "$ROOT\azure"
    try {
        terraform init "-backend-config=backend.hcl" -input=false -no-color
        terraform destroy -auto-approve -no-color
        Write-Host "    [OK] Azure resources destroyed" -ForegroundColor Green
    } catch {
        Write-Host "    [ERROR] Azure destroy failed: $_" -ForegroundColor Red
    }
    Pop-Location

    Write-Host "--- Destroying GCP HA VPN Gateway ---" -ForegroundColor Yellow
    Push-Location "$ROOT\foundation\03-network-hub"
    try {
        terraform destroy "-target=module.vpn" -auto-approve -no-color
        Write-Host "    [OK] GCP HA VPN Gateway destroyed" -ForegroundColor Green
    } catch {
        Write-Host "    [ERROR] GCP VPN destroy failed: $_" -ForegroundColor Red
    }
    Pop-Location
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Selective destroy complete!" -ForegroundColor Green
Write-Host " VPC, Subnets, Firewall, Router, IAM — all preserved." -ForegroundColor Green
Write-Host " To redeploy: .\scripts\deploy.ps1 -StartFrom 3" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
