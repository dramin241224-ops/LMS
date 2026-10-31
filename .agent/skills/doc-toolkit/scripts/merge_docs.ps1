param(
    [Parameter(Mandatory=$true)]
    [string]$InputFiles, # Danh sách các file nguồn, ngăn cách bởi dấu phẩy
    [Parameter(Mandatory=$true)]
    [string]$OutputMd,    # File Markdown kết quả
    [Parameter(Mandatory=$false)]
    [string]$OutputDoc,   # File Word kết quả (nếu muốn)
    [Parameter(Mandatory=$false)]
    [string]$TemplatePath # Đường dẫn đến file template .doc (nếu có)
)

$OutputMd = [System.IO.Path]::GetFullPath($OutputMd)
if ($OutputDoc) {
    $OutputDoc = [System.IO.Path]::GetFullPath($OutputDoc)
}

# Đảm bảo thư mục cha của OutputMd tồn tại
$parentDir = Split-Path $OutputMd
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# Phân tách danh sách file đầu vào
$files = $InputFiles -split ","
$mergedContent = New-Object System.Text.StringBuilder

Write-Host "Bat dau tong hop cac tai lieu..."

foreach ($file in $files) {
    $trimmedPath = $file.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedPath)) { continue }
    
    $fullPath = [System.IO.Path]::GetFullPath($trimmedPath)
    if (-not (Test-Path $fullPath)) {
        Write-Warning "File nguon khong ton tai, bo qua: $fullPath"
        continue
    }
    
    Write-Host "Dang doc file: $trimmedPath"
    
    # Đọc file bằng UTF-8
    $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    
    # Thêm comment phân tách nguồn tài liệu (giúp dễ debug)
    $filename = Split-Path $fullPath -Leaf
    $mergedContent.AppendLine("<!-- START SOURCE FILE: $filename -->") | Out-Null
    $mergedContent.AppendLine($content) | Out-Null
    $mergedContent.AppendLine("<!-- END SOURCE FILE: $filename -->") | Out-Null
    
    # Thêm page-break phân trang giữa các tài liệu để tạo cấu trúc Word đẹp mắt
    $mergedContent.AppendLine("`n<div class=""page-break""></div>`n") | Out-Null
}

# Lưu file Markdown tổng hợp
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputMd, $mergedContent.ToString(), $Utf8NoBom)
Write-Host "Da tao file Markdown tong hop tai: $OutputMd"

# Nếu yêu cầu xuất cả file Word (.doc)
if ($OutputDoc) {
    Write-Host "Dang thuc hien tu dong chuyen doi sang file Word (.doc)..."
    
    # Tìm file md_to_doc.ps1 nằm cùng thư mục scripts
    $scriptDir = Split-Path $PSCommandPath
    $converterScript = Join-Path $scriptDir "md_to_doc.ps1"
    
    if (Test-Path $converterScript) {
        $params = @{
            InputMd = $OutputMd
            OutputDoc = $OutputDoc
        }
        if ($TemplatePath) {
            $params["TemplatePath"] = $TemplatePath
        }
        
        # Gọi md_to_doc.ps1 để chuyển đổi
        & $converterScript @params
    } else {
        Write-Error "Khong tim thay script md_to_doc.ps1 tai: $converterScript"
    }
}

Write-Host "=== TONG HOP TAI LIEU HOAN TAT ==="
exit 0
