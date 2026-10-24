<#
.SYNOPSIS
  Retries terraform apply in a loop rotating across OCI fault domains on capacity shortages.

.DESCRIPTION
  Runs 'terraform apply -auto-approve' from the terraform folder.
  If 'Out of host capacity' is encountered, waits 90 seconds and rotates
  -var fault_domain through FAULT-DOMAIN-1, FAULT-DOMAIN-2, and FAULT-DOMAIN-3,
  up to 40 attempts. Stops immediately on any other error. Prints outputs on success.
#>

[CmdletBinding()]
param()

$terraformDir = Join-Path $PSScriptRoot "..\terraform"
if (-not (Test-Path $terraformDir)) {
    Write-Error "Terraform directory not found at $terraformDir"
    exit 1
}

Push-Location $terraformDir
try {
    $faultDomains = @("FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3")
    $maxAttempts = 40

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $currentFd = $faultDomains[($attempt - 1) % $faultDomains.Count]
        Write-Host "=== [Attempt $attempt / $maxAttempts] Applying with fault_domain=$currentFd ===" -ForegroundColor Cyan

        $output = & terraform apply -auto-approve -var="fault_domain=$currentFd" 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Host "`n[SUCCESS] Terraform apply completed successfully on attempt $attempt ($currentFd)!" -ForegroundColor Green
            Write-Host "`nTerraform Outputs:" -ForegroundColor Cyan
            & terraform output
            exit 0
        }

        if ($output -like "*Out of host capacity*") {
            Write-Warning "Out of host capacity on $currentFd (attempt $attempt of $maxAttempts)."
            if ($attempt -lt $maxAttempts) {
                Write-Host "Waiting 90 seconds before rotating to the next fault domain..." -ForegroundColor Yellow
                Start-Sleep -Seconds 90
            }
        } else {
            Write-Error "Terraform apply failed with a non-capacity error:"
            Write-Host $output
            exit $exitCode
        }
    }

    Write-Error "Exhausted all $maxAttempts attempts without securing host capacity."
    exit 1
}
finally {
    Pop-Location
}
