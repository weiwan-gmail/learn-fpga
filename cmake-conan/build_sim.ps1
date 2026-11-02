# cmake-conan Windows helper (PC2023 copy-paste ready).
# Conan 2 + local recipes/verilator (withlimon PE on Windows).
# Always drive verilator_bin.exe. Never extensionless Perl `verilator`.
#
# cd cmake-conan
# .\build_sim.ps1
# .\build_sim.ps1 -Generator "Visual Studio 17 2022"
#
# PC2023: Conan 2.34 + withlimon Verilator; worker workspace D:\CursorWorker
# GNU make is not required for this Verilator/cmake sim path.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    [string]$Config = "Release",
    [string]$Generator = "",
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-MzPe([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $fs = [IO.File]::OpenRead($Path)
    try {
        return ($fs.ReadByte() -eq 0x4D -and $fs.ReadByte() -eq 0x5A)
    } finally { $fs.Close() }
}

function Find-VerilatorBin {
    $cands = New-Object System.Collections.Generic.List[string]
    $cands.Add("D:\verilator\bin\verilator_bin.exe")
    $cands.Add("C:\msys64\mingw64\bin\verilator_bin.exe")
    if ($env:VERILATOR_ROOT) {
        $cands.Add((Join-Path $env:VERILATOR_ROOT "bin\verilator_bin.exe"))
        $cands.Add((Join-Path $env:VERILATOR_ROOT "..\bin\verilator_bin.exe"))
        $cands.Add((Join-Path $env:VERILATOR_ROOT "..\..\bin\verilator_bin.exe"))
    }
    foreach ($c in $cands) {
        if ($c -and (Test-MzPe $c)) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }
    $cmd = Get-Command verilator_bin.exe -ErrorAction SilentlyContinue
    if ($cmd -and (Test-MzPe $cmd.Source)) { return $cmd.Source }
    return $null
}

function Find-MsysMake {
    $cands = @(
        "C:\msys64\usr\bin\make.exe",
        "C:\msys64\usr\bin\gmake.exe",
        "C:\msys64\mingw64\bin\mingw32-make.exe",
        "C:\msys64\ucrt64\bin\mingw32-make.exe",
        "D:\msys64\usr\bin\make.exe"
    )
    if ($env:MSYS2_ROOT) {
        $cands += @(
            (Join-Path $env:MSYS2_ROOT "usr\bin\make.exe"),
            (Join-Path $env:MSYS2_ROOT "mingw64\bin\mingw32-make.exe")
        )
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath $c)) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }
    foreach ($n in @("make.exe", "gmake.exe", "mingw32-make.exe")) {
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Find-RiscvGcc {
    foreach ($n in @("riscv64-unknown-elf-gcc.exe", "riscv-none-elf-gcc.exe", "riscv-none-embed-gcc.exe")) {
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    $cands = @(
        "C:\msys64\mingw64\bin\riscv64-unknown-elf-gcc.exe",
        "C:\msys64\mingw64\bin\riscv-none-elf-gcc.exe",
        "C:\msys64\ucrt64\bin\riscv64-unknown-elf-gcc.exe",
        "C:\msys64\ucrt64\bin\riscv-none-elf-gcc.exe"
    )
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
    }
    $xpackRoots = @(
        (Join-Path $env:USERPROFILE "AppData\Roaming\xPacks"),
        (Join-Path $env:LOCALAPPDATA "xPacks")
    )
    foreach ($r in $xpackRoots) {
        if (-not (Test-Path -LiteralPath $r)) { continue }
        $hit = Get-ChildItem -Path $r -Recurse -Filter "riscv-none-elf-gcc.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

Write-Host "cmake-conan/build_sim.ps1 config=$Config buildDir=$BuildDir"
Write-Host "withlimon: https://github.com/withlimon/verilator-windows"
Write-Host "Conan 2 expected (PC2023: 2.34)"

$conan = Get-Command conan -ErrorAction SilentlyContinue
if (-not $conan) {
    throw "conan not on PATH. Install Conan 2 (PC2023: 2.34) or use cmake-system/ instead."
}
Write-Host "conan = $($conan.Source)"

& conan export (Join-Path $Here "recipes\verilator")
if ($LASTEXITCODE -ne 0) { throw "conan export recipes/verilator failed" }

$pe = Find-VerilatorBin
if ($pe) {
    Write-Host "VERILATOR_BIN (PE) = $pe"
    $binDir = Split-Path -Parent $pe
    $rootGuess = Split-Path -Parent $binDir
    if (-not $env:VERILATOR_ROOT) {
        if (Test-Path (Join-Path $rootGuess "include\verilated.h")) {
            $env:VERILATOR_ROOT = $rootGuess
        } elseif (Test-Path (Join-Path $rootGuess "share\verilator\include\verilated.h")) {
            $env:VERILATOR_ROOT = Join-Path $rootGuess "share\verilator"
        }
    }
    $env:PATH = "$binDir;$env:PATH"
    Write-Host "VERILATOR_ROOT = $($env:VERILATOR_ROOT)"
} else {
    Write-Host "verilator_bin.exe not preinstalled; recipe will fetch/package withlimon on Windows."
}

$make = Find-MsysMake
if ($make) {
    Write-Host "MSYS2 make (optional, not required for cmake sim) = $make"
    $env:PATH = "$(Split-Path -Parent $make);$env:PATH"
} else {
    Write-Host "GNU make not on PATH; cmake sim does not need it on Windows."
}

$rvgcc = Find-RiscvGcc
if ($rvgcc) {
    Write-Host "RISC-V GCC = $rvgcc"
    $env:PATH = "$(Split-Path -Parent $rvgcc);$env:PATH"
} else {
    Write-Host "RISC-V GCC not found; cmake will use cmake/firmware.helloC.hex fallback."
}

$buildPath = if ([System.IO.Path]::IsPathRooted($BuildDir)) { $BuildDir } else { Join-Path $Here $BuildDir }

$cmakeArgs = @(
    "-S", $Here,
    "-B", $buildPath,
    "-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=$Here\conan_provider.cmake",
    "-DCONAN_INSTALL_ARGS=--build=missing;--no-remote"
)
if ($Generator) { $cmakeArgs += @("-G", $Generator) }
if ($Generator -notmatch "Visual Studio") {
    $cmakeArgs += "-DCMAKE_BUILD_TYPE=$Config"
}
if ($Profile) {
    $cmakeArgs += "-DCONAN_HOST_PROFILE=$Profile"
    $cmakeArgs += "-DCONAN_BUILD_PROFILE=$Profile"
}

Write-Host "cmake $($cmakeArgs -join ' ')"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

$buildArgs = @("--build", $buildPath, "--config", $Config, "--target", "sim")
& cmake @buildArgs
if ($LASTEXITCODE -ne 0) { throw "cmake --build --target sim failed" }

Push-Location $buildPath
try {
    & ctest -C $Config --output-on-failure
    if ($LASTEXITCODE -ne 0) { throw "ctest failed" }
} finally {
    Pop-Location
}

Write-Host "cmake-conan PASS (sim + ctest)"
