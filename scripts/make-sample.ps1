$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force (Join-Path $root 'samples') | Out-Null
Add-Type -AssemblyName System.Speech
$speaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $speaker.SelectVoice('Microsoft Haruka Desktop')
    $format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(16000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
    $speaker.SetOutputToWaveFile((Join-Path $root 'samples/japanese-smoke.wav'), $format)
    $speaker.Speak('今日はテレビの字幕をテストします。日本語の音声を文字に変換します。明日の東京は晴れるでしょう。')
} finally { $speaker.Dispose() }
Write-Host 'Created samples/japanese-smoke.wav (synthetic speech, not a broadcast accuracy benchmark).'
