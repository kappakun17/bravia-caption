[CmdletBinding()]
param([Parameter(Mandatory)][string]$AudioPath)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$audio = (Resolve-Path -LiteralPath $AudioPath).Path
$exe = Join-Path $root '.runtime/nemo-speech-0.2.0-windows-x86_64-cpu/bin/nemo-speech.exe'
if (-not (Test-Path $exe)) { throw 'Run scripts/setup.ps1 first.' }
$env:NEMO_SPEECH_MODEL_DIR = Join-Path $root '.models'
$run = Join-Path $root ('results/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force $run | Out-Null
$timer = [Diagnostics.Stopwatch]::StartNew()
$ErrorActionPreference = 'Continue'
& $exe transcribe $audio --model nemotron-3.5 --language ja-JP --device cpu --format json --output (Join-Path $run 'transcript.json') 2> (Join-Path $run 'runtime.log')
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$timer.Stop()
@{exit_code=$code; elapsed_seconds=$timer.Elapsed.TotalSeconds; timing_scope='process startup + model load + recognition'; device='cpu'; language='ja-JP'; runtime='0.2.0'} | ConvertTo-Json | Set-Content (Join-Path $run 'measurement.json') -Encoding UTF8
if ($code -ne 0) { throw "Recognition failed. See $run/runtime.log" }
Get-Content (Join-Path $run 'transcript.json') -Raw -Encoding UTF8
Write-Host "Results: $run"
