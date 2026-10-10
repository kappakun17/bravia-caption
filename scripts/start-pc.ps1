[CmdletBinding()]
param([string]$NodePath = 'node')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $root '.runtime/nemo-speech-0.2.0-windows-x86_64-cpu/bin/nemo-speech.exe'
if (-not (Test-Path $exe)) { throw 'Run scripts/setup.ps1 first.' }
if (-not (Get-Command $NodePath -ErrorAction SilentlyContinue)) { throw 'Node.js 22 or newer required. Pass -NodePath with its executable path.' }
$env:NEMO_SPEECH_MODEL_DIR = Join-Path $root '.models'
New-Item -ItemType Directory -Force (Join-Path $root 'results') | Out-Null
$asrProcess = $null
$pageProcess = $null
try {
    # Use quoted executable/model paths through ArgumentList when paths contain spaces.
    $asrProcess = Start-Process -FilePath $exe -ArgumentList 'serve --asr-model nemotron-3.5 --device cpu --host 127.0.0.1 --port 8080' -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'results/asr-server.out.log') -RedirectStandardError (Join-Path $root 'results/asr-server.err.log')
    $ready = $false
    for ($i=0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        if ($asrProcess.HasExited) { throw 'ASR server exited. Check results/asr-server.err.log; port 8080 may be occupied.' }
        try { $health = Invoke-RestMethod 'http://127.0.0.1:8080/health' -TimeoutSec 1; if ($health.status -eq 'ok') { $ready = $true; break } } catch {}
    }
    if (-not $ready) { throw 'ASR server did not become ready.' }
    $pageProcess = Start-Process -FilePath $NodePath -ArgumentList 'pc/server.mjs' -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'results/caption-page.out.log') -RedirectStandardError (Join-Path $root 'results/caption-page.err.log')
    Start-Sleep -Milliseconds 500
    if ($pageProcess.HasExited) { throw 'Caption server exited; port 8090 may be occupied.' }
    Write-Host 'Open http://127.0.0.1:8090 in Chrome or Edge. Press Enter here to stop both servers.'
    Read-Host | Out-Null
} finally {
    foreach ($ownedProcess in @($pageProcess, $asrProcess)) { if ($ownedProcess -and -not $ownedProcess.HasExited) { Stop-Process -Id $ownedProcess.Id } }
}
