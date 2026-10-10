[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$version = '0.2.0'
$name = "nemo-speech-$version-windows-x86_64-cpu"
$exe = Join-Path $root ".runtime/$name/bin/nemo-speech.exe"
if (-not (Test-Path -LiteralPath $exe)) {
    $downloads = Join-Path $root '.downloads'
    New-Item -ItemType Directory -Force $downloads | Out-Null
    $zip = Join-Path $downloads "$name.zip"
    $url = "https://github.com/NVIDIA/NeMo-Speech.cpp/releases/download/v$version/$name.zip"
    Invoke-WebRequest $url -OutFile $zip
    Invoke-WebRequest "$url.sha256" -OutFile "$zip.sha256"
    $expected = ((Get-Content "$zip.sha256" -Raw).Trim() -split '\s+')[0]
    if ($expected -notmatch '^[a-fA-F0-9]{64}$' -or (Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected) {
        throw 'Runtime SHA-256 verification failed.'
    }
    Expand-Archive $zip -DestinationPath (Join-Path $root '.runtime') -Force
}
& $exe --json doctor
if ($LASTEXITCODE -ne 0) { throw 'Runtime health check failed.' }
$env:NEMO_SPEECH_MODEL_DIR = Join-Path $root '.models'
& $exe pull nemotron-3.5
if ($LASTEXITCODE -ne 0) { throw 'Model download or verification failed.' }
