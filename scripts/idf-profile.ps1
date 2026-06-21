param(
    [ValidateSet("menuconfig", "build", "flash", "monitor", "flash-monitor", "clean")]
    [string]$Action = "menuconfig",

    [string]$Profile = "watch",

    [string]$Defaults = "",

    [string]$Target = "esp32s3",

    [string]$Port = "COM3",

    [string]$IdfPath = "D:\Espressif\frameworks\.espressif\v5.5.4\esp-idf",

    [string]$PythonEnvPath = "D:\Espressif\python_env\idf5.5_py3.12_env\Scripts"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$IdfExport = Join-Path $IdfPath "export.ps1"

if (-not (Test-Path -LiteralPath $IdfExport)) {
    throw "ESP-IDF export script not found: $IdfExport"
}

if (-not (Test-Path -LiteralPath (Join-Path $PythonEnvPath "python.exe"))) {
    throw "ESP-IDF Python not found: $PythonEnvPath\python.exe"
}

$DefaultFiles = @(
    "sdkconfig.defaults",
    "sdkconfig.defaults.$Target"
)

if ([string]::IsNullOrWhiteSpace($Defaults)) {
    $ProfileDefaults = "sdkconfig.defaults.$Profile"
    if (Test-Path -LiteralPath (Join-Path $ProjectRoot $ProfileDefaults)) {
        $DefaultFiles += $ProfileDefaults
    }
} else {
    $DefaultFiles += $Defaults
}

foreach ($file in $DefaultFiles) {
    $path = Join-Path $ProjectRoot $file
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Defaults file not found: $path"
    }
}

$BuildDir = Join-Path $ProjectRoot "build-$Profile"
$SdkConfig = Join-Path $ProjectRoot "sdkconfig.$Profile"
$SdkConfigDefaults = ($DefaultFiles -join ";")

Set-Location $ProjectRoot
. $IdfExport
$env:Path = "$PythonEnvPath;$env:Path"

$CommonArgs = @(
    "-B", $BuildDir,
    "-D", "SDKCONFIG=$SdkConfig",
    "-D", "SDKCONFIG_DEFAULTS=$SdkConfigDefaults",
    "-D", "IDF_TARGET=$Target"
)

Write-Host "Profile: $Profile"
Write-Host "Target: $Target"
Write-Host "SDKCONFIG: $SdkConfig"
Write-Host "Defaults: $SdkConfigDefaults"
Write-Host "Build dir: $BuildDir"

switch ($Action) {
    "menuconfig" {
        idf.py @CommonArgs menuconfig
    }
    "build" {
        idf.py @CommonArgs build
    }
    "flash" {
        idf.py @CommonArgs -p $Port flash
    }
    "monitor" {
        idf.py @CommonArgs -p $Port monitor
    }
    "flash-monitor" {
        idf.py @CommonArgs -p $Port flash monitor
    }
    "clean" {
        idf.py @CommonArgs fullclean
    }
}
