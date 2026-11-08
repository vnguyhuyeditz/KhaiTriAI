# Khai Tri AI - cai dat tu dong (chay mot lan).
# Lam: flutter create, chep am thanh thong bao, sua AndroidManifest + gradle, flutter pub get.
$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Text($p)  { [System.IO.File]::ReadAllText($p, $utf8) }
function Write-Text($p, $t) { [System.IO.File]::WriteAllText($p, $t, $utf8) }

Write-Host '== 1/5 Tao khung Android + iOS (flutter create) ==' -ForegroundColor Cyan
flutter create --project-name khai_tri_ai --org com.khaitri --platforms android,ios .
if ($LASTEXITCODE -ne 0) { throw 'flutter create loi. Kiem tra lai flutter doctor.' }

# flutter create tu sinh file test mau goi MyApp (khong ton tai), xoa di.
if (Test-Path 'test\widget_test.dart') { Remove-Item 'test\widget_test.dart' -Force }

Write-Host '== 2/5 Chep am thanh thong bao ==' -ForegroundColor Cyan
$raw = 'android\app\src\main\res\raw'
New-Item -ItemType Directory -Force -Path $raw | Out-Null
Copy-Item 'android_extra\res\raw\notification_sound.mp3' "$raw\notification_sound.mp3" -Force

# Icon ung dung (logo Khai Tri AI) thay icon Flutter mac dinh.
foreach ($d in 'mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi') {
  $src = "android_extra\res\mipmap-$d\ic_launcher.png"
  $dst = "android\app\src\main\res\mipmap-$d"
  if ((Test-Path $src) -and (Test-Path $dst)) { Copy-Item $src "$dst\ic_launcher.png" -Force }
}

Write-Host '== 3/5 Sua AndroidManifest.xml ==' -ForegroundColor Cyan
$mf = 'android\app\src\main\AndroidManifest.xml'
$m = Read-Text $mf
if ($m -notmatch 'POST_NOTIFICATIONS') {
  $perms = @'
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

'@
  $m = $m -replace '(\s*)<application', ("`r`n" + $perms + '    <application')
}
if ($m -notmatch 'ScheduledNotificationReceiver') {
  $recv = @'
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'@
  $m = $m -replace '</application>', ($recv + "`r`n    </application>")
}
Write-Text $mf $m

Write-Host '== 4/5 Bat desugaring trong gradle ==' -ForegroundColor Cyan
$kts = 'android\app\build.gradle.kts'
$grv = 'android\app\build.gradle'
if (Test-Path $kts) {
  $g = Read-Text $kts
  if ($g -notmatch 'isCoreLibraryDesugaringEnabled') {
    if ($g -match 'compileOptions\s*\{') {
      $g = $g -replace '(compileOptions\s*\{)', "`$1`r`n        isCoreLibraryDesugaringEnabled = true"
    } else {
      $g = $g -replace '(android\s*\{)', "`$1`r`n    compileOptions {`r`n        isCoreLibraryDesugaringEnabled = true`r`n    }"
    }
    $g += "`r`ndependencies {`r`n    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.1.4`")`r`n}`r`n"
    Write-Text $kts $g
  }
  # Mo hinh AI 500MB+ trong APK: khong nen nen (nen se rat cham va ton RAM khi build).
  $g = Read-Text $kts
  if ($g -notmatch 'noCompress') {
    $g = $g -replace '(android\s*\{)', "`$1`r`n    androidResources {`r`n        noCompress += listOf(`"litertlm`")`r`n    }"
  }
  $g = $g -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 26'
  Write-Text $kts $g
} elseif (Test-Path $grv) {
  $g = Read-Text $grv
  if ($g -notmatch 'coreLibraryDesugaringEnabled') {
    if ($g -match 'compileOptions\s*\{') {
      $g = $g -replace '(compileOptions\s*\{)', "`$1`r`n        coreLibraryDesugaringEnabled true"
    } else {
      $g = $g -replace '(android\s*\{)', "`$1`r`n    compileOptions {`r`n        coreLibraryDesugaringEnabled true`r`n    }"
    }
    $g += "`r`ndependencies {`r`n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'`r`n}`r`n"
    Write-Text $grv $g
  }
  $g = Read-Text $grv
  if ($g -notmatch 'noCompress') {
    $g = $g -replace '(android\s*\{)', "`$1`r`n    aaptOptions {`r`n        noCompress 'litertlm'`r`n    }"
  }
  $g = $g -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 26'
  Write-Text $grv $g
} else {
  Write-Warning 'Khong thay build.gradle(.kts) cua app. Hay lam buoc 3 trong README bang tay.'
}

Write-Host '== 5/5 Cai goi + flutter pub get ==' -ForegroundColor Cyan
# Goi doc tai lieu (cai ban moi nhat tuong thich voi Flutter cua ban).
flutter pub add file_picker image_picker google_mlkit_text_recognition syncfusion_flutter_pdf printing archive xml path_provider flutter_edge_ai flutter_edge_ai_litertlm
flutter pub get

Write-Host ''
Write-Host 'XONG. Cam dien thoai roi chay:  flutter devices   sau do   flutter run -d <ma may>' -ForegroundColor Green
