$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path "$ENV:CIRRUS_WORKING_DIR"
Set-Location "$ENV:CIRRUS_WORKING_DIR"


function download($uri, $file) {
    Write-Host "Downloading $uri"
    For($i = 0;;) {
        Try {
            Invoke-WebRequest -UseBasicParsing -ErrorAction Stop -OutFile "$file" `
                -Uri "$uri"
            Break
        } Catch {
            if (++$i -gt 6) {
                throw $_.Exception
            }
            Write-Host "Download failed - retrying:" $_.Exception.Response.StatusCode
            Start-Sleep -Seconds 10
        }
    }
}

# Download the machine image from the previous build job
download "${ENV:MACHINE_IMAGE_BASE_URL}${ENV:MACHINE_IMAGE}" "${ENV:MACHINE_IMAGE}"

# Download and install podman
$uri = "https://github.com/containers/podman/releases/download/v${ENV:PODMAN_INSTALL_VERSION}/podman-installer-windows-amd64.exe"
$installer = "podman-setup.exe"
download "$uri" "$installer"

Write-Host "Installing podman..."
$ret = Start-Process -Wait `
                        -PassThru "$installer" `
                        -ArgumentList "/install /quiet `
                            MachineProvider=hyperv `
                            WSLCheckbox=0 `
                            HyperVCheckbox=0 `
                            /log podman-setup.log"
if ($ret.ExitCode -ne 0) {
    Write-Host "Install failed, dumping log"
    Get-Content podman-setup.log
    throw "Exit code is $($ret.ExitCode)"
}
Write-Host "Installation completed successfully!`n"

Write-Host "Podman version"
podman.exe --version

Write-Host "Saving selection of CI env. vars."
# Env. vars will not pass through win-sess-launch.ps1
Get-ChildItem -Path "Env:\*" -include @("PATH", "PROVIDER", "MACHINE_IMAGE", "TEST_*", "CI_*") `
  | Export-CLIXML "$ENV:TEMP\envars.xml"

Write-Host "Installing ginkgo"
Set-Location ".\verify"
New-Item ..\bin -ItemType Directory
go build -o ..\bin\ginkgo.exe ./vendor/github.com/onsi/ginkgo/v2/ginkgo
