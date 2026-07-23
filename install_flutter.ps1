# Flutter SDK Kurulum Scripti
# Bu scripti yönetici olarak çalıştırın veya PowerShell'de çalıştırın

Write-Host "=== Flutter SDK Kurulum Scripti ===" -ForegroundColor Cyan
Write-Host ""

$flutterDir = "$env:USERPROFILE\flutter"
$downloadPath = "$env:USERPROFILE\Downloads\flutter_sdk.zip"

# 1. İndirme kontrolü
if (Test-Path $downloadPath) {
    $size = (Get-Item $downloadPath).Length
    $sizeMB = [math]::Round($size / 1MB, 1)
    Write-Host "Mevcut indirme: $downloadPath ($sizeMB MB)" -ForegroundColor Yellow
    
    if ($size -gt 1000MB) {
        Write-Host "İndirme tamamlandı gibi görünüyor. Devam ediliyor..." -ForegroundColor Green
    } else {
        Write-Host "İndirme devam ediyor veya eksik kalmış... Tekrar indiriliyor." -ForegroundColor Yellow
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    }
}

if (!(Test-Path $downloadPath)) {
    Write-Host "Flutter SDK indiriliyor..." -ForegroundColor Yellow
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.4-stable.zip"
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
        Write-Host "İndirme tamamlandı!" -ForegroundColor Green
    } catch {
        Write-Host "İndirme başarısız: $_" -ForegroundColor Red
        Write-Host "Lütfen manual olarak indirin: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        exit 1
    }
}

# 2. Mevcut Flutter kontrolü
if (Test-Path "$flutterDir\bin\flutter.bat") {
    Write-Host "Flutter zaten kurulu: $flutterDir" -ForegroundColor Green
} else {
    # 3. Çıkartma
    Write-Host "Flutter SDK çıkartılıyor..." -ForegroundColor Yellow
    
    if (!(Test-Path $flutterDir)) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE" -Force | Out-Null
    }
    
    try {
        Expand-Archive -Path $downloadPath -DestinationPath "$env:USERPROFILE" -Force
        Write-Host "Çıkartma tamamlandı!" -ForegroundColor Green
    } catch {
        Write-Host "Çıkartma başarısız: $_" -ForegroundColor Red
        Write-Host "Bozuk veya eksik dosya olabilir. İndirilen zip siliniyor..." -ForegroundColor Yellow
        Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# 4. PATH güncelleme
$flutterBin = "$flutterDir\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($currentPath -notlike "*$flutterBin*") {
    Write-Host "PATH'e Flutter ekleniyor..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable(
        "PATH",
        "$currentPath;$flutterBin",
        "User"
    )
    $env:PATH = "$env:PATH;$flutterBin"
    Write-Host "PATH güncellendi!" -ForegroundColor Green
} else {
    Write-Host "Flutter zaten PATH'te mevcut." -ForegroundColor Green
}

# 5. Flutter doctor
Write-Host ""
Write-Host "Flutter doctor çalıştırılıyor..." -ForegroundColor Cyan
& "$flutterBin\flutter.bat" doctor

# 6. Proje kurulumu
$projectPath = "c:\Users\erk_septar\Eczane Bul"
Write-Host ""
Write-Host "Proje bağımlılıkları yükleniyor..." -ForegroundColor Cyan
Set-Location $projectPath
& "$flutterBin\flutter.bat" pub get

Write-Host ""
Write-Host "=== Kurulum Tamamlandı! ===" -ForegroundColor Green
Write-Host "Uygulamayı çalıştırmak için:" -ForegroundColor Cyan
Write-Host "  cd 'c:\Users\erk_septar\Eczane Bul'" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""
Write-Host "Emülatör listesi için: flutter devices" -ForegroundColor Cyan
