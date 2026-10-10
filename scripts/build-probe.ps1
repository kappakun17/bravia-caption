[CmdletBinding()]
param([string]$SdkPath = "$env:LOCALAPPDATA/Android/Sdk")
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$probe=Join-Path $root 'android-probe'
$build=Join-Path $probe 'build'
$tools=Join-Path $SdkPath 'build-tools/36.0.0'
$jar=Join-Path $SdkPath 'platforms/android-37.0/android.jar'
if(-not (Test-Path $jar)){throw 'Install Android SDK platform android-37.0 and build-tools 36.0.0, or adapt these paths.'}
New-Item -ItemType Directory -Force $build,(Join-Path $build 'classes'),(Join-Path $build 'dex') | Out-Null
$sources=@(Get-ChildItem (Join-Path $probe 'src') -Recurse -Filter '*.java' | ForEach-Object FullName)
& javac -encoding UTF-8 -source 8 -target 8 -classpath $jar -d (Join-Path $build 'classes') @sources
if($LASTEXITCODE -ne 0){throw 'javac failed'}
Push-Location (Join-Path $build 'classes')
try{ & jar cf (Join-Path $build 'classes.jar') . }finally{Pop-Location}
if($LASTEXITCODE -ne 0){throw 'jar failed'}
& (Join-Path $tools 'd8.bat') --lib $jar --min-api 29 --output (Join-Path $build 'dex') (Join-Path $build 'classes.jar')
if($LASTEXITCODE -ne 0){throw 'd8 failed'}
& (Join-Path $tools 'aapt.exe') package -f -M (Join-Path $probe 'AndroidManifest.xml') -I $jar -F (Join-Path $build 'unsigned.apk')
if($LASTEXITCODE -ne 0){throw 'aapt package failed'}
Push-Location (Join-Path $build 'dex')
try{ & (Join-Path $tools 'aapt.exe') add (Join-Path $build 'unsigned.apk') classes.dex }finally{Pop-Location}
if($LASTEXITCODE -ne 0){throw 'aapt dex failed'}
& (Join-Path $tools 'zipalign.exe') -f 4 (Join-Path $build 'unsigned.apk') (Join-Path $build 'aligned.apk')
if($LASTEXITCODE -ne 0){throw 'zipalign failed'}
$key=Join-Path $build 'debug.jks'
if(-not (Test-Path $key)){& keytool -genkeypair -keystore $key -storepass android -keypass android -alias debug -dname 'CN=Caption Probe Debug' -keyalg RSA -validity 3650; if($LASTEXITCODE -ne 0){throw 'keytool failed'}}
& (Join-Path $tools 'apksigner.bat') sign --ks $key --ks-pass pass:android --key-pass pass:android --v3-signing-enabled false --v4-signing-enabled false --out (Join-Path $build 'bravia-caption-probe.apk') (Join-Path $build 'aligned.apk')
if($LASTEXITCODE -ne 0){throw 'APK sign failed'}
& (Join-Path $tools 'apksigner.bat') verify (Join-Path $build 'bravia-caption-probe.apk')
if($LASTEXITCODE -ne 0){throw 'APK verify failed'}
Write-Host "APK: $build/bravia-caption-probe.apk"
