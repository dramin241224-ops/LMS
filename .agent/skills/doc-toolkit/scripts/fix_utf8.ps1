param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

$FilePath = [System.IO.Path]::GetFullPath($FilePath)
if (-not (Test-Path $FilePath)) {
    Write-Error "File khong ton tai: $FilePath"
    exit 1
}

Write-Host "Dang thuc hien sua loi font UTF-8 (Mojibake/CP1252) cho: $FilePath"

try {
    # Đăng ký CodePagesEncodingProvider để .NET Core nhận dạng CP1252 (Windows-1252)
    try {
        [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
    } catch {}

    # Đọc mảng byte thô từ file
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    
    # Giải mã thô bằng UTF-8
    $utf8Str = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    # Lấy encoding CP1252
    $cp1252 = [System.Text.Encoding]::GetEncoding(1252)
    
    # Thực hiện chuyển đổi ngược: Lấy bytes của chuỗi UTF-8 theo kiểu CP1252
    # và giải mã lại chuẩn bằng UTF-8
    $fixedBytes = $cp1252.GetBytes($utf8Str)
    $fixedText = [System.Text.Encoding]::UTF8.GetString($fixedBytes)
    
    # Hậu xử lý: Loại bỏ các ký tự rác/BOM nếu phát hiện thấy file HTML-Word
    # Word đôi khi tự thêm BOM hoặc các thẻ lạ. Nếu là HTML-Word, ta đảm bảo cấu trúc sạch.
    $idx = $fixedText.IndexOf("<html")
    if ($idx -gt 0) {
        $fixedText = $fixedText.Substring($idx)
    }

    # Backup file cũ để an toàn
    $backupPath = "$FilePath.bak"
    Copy-Item $FilePath $backupPath -Force
    Write-Host "Da tao backup tại: $backupPath"

    # Ghi đè file với UTF-8 không BOM
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($FilePath, $fixedText, $Utf8NoBom)
    
    Write-Host "=== DA SUA LOI ENCODING THANH CONG ==="
    exit 0
} catch {
    Write-Error "Sua loi encoding that bai: $_"
    exit 1
}
