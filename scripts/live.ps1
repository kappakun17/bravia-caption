$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$env:NEMO_SPEECH_MODEL_DIR = Join-Path $root '.models'
$exe = Join-Path $root '.runtime/nemo-speech-0.2.0-windows-x86_64-cpu/bin/nemo-speech.exe'
Write-Host 'Default microphone transcription starts now. Stop with Ctrl+C.'
& $exe transcribe --live --model nemotron-3.5 --language ja-JP --device cpu
if ($LASTEXITCODE -ne 0) { throw 'Live transcription failed.' }
