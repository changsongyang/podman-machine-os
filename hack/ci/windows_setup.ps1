$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'



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

# Download and install podman
$uri = "https://github.com/containers/podman/releases/download/${ENV:PODMAN_INSTALL_VERSION}/podman-installer-windows-amd64.msi"
$installer = "podman-installer.msi"
download "$uri" "$installer"

Write-Host "Installing podman..."
$ret = Start-Process -Wait `
    -PassThru 'msiexec' `
    -ArgumentList "/package $installer /quiet /l*v podman-setup.log MACHINE_PROVIDER=${ENV:PROVIDER}"

if ($ret.ExitCode -ne 0) {
    Write-Host "Install failed, dumping log"
    Get-Content podman-setup.log
    throw "Exit code is $($ret.ExitCode)"
}
Write-Host "Installation completed successfully!`n"

Write-Host "Installing ginkgo"
Set-Location ".\verify"
New-Item ..\bin -ItemType Directory
go build -o ..\bin\ginkgo.exe ./vendor/github.com/onsi/ginkgo/v2/ginkgo
