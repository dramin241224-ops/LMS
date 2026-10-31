param(
    [Parameter(Mandatory=$true)]
    [string]$PdfPath,
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Chuẩn hóa đường dẫn
$PdfPath = [System.IO.Path]::GetFullPath($PdfPath)
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path $PdfPath)) {
    Write-Error "File PDF khong ton tai: $PdfPath"
    exit 1
}

# Đảm bảo thư mục cha của OutputPath tồn tại
$parentDir = Split-Path $OutputPath
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

Write-Host "Dang thuc hien convert PDF sang TXT (giu font tieng Viet UTF-8)..."
Write-Host "Nguon: $PdfPath"
Write-Host "Dich: $OutputPath"

try {
    # Su dung Word COM Object de doc PDF va xuat ra TXT (dam bao xu ly dung tieng Viet va format)
    $word = New-Object -ComObject Word.Application -ErrorAction Stop
    $word.Visible = $false
    $word.DisplayAlerts = 0 # wdAlertsNone
    
    # Mo PDF qua Word
    $doc = $word.Documents.Open($PdfPath, $false, $true) # ReadOnly=True
    
    # SaveAs encoded text: wdFormatEncodedText = 7
    # Encoding: UTF-8 = 65001
    $wdFormatEncodedText = 7
    $msoEncodingUTF8 = 65001
    
    # Goi phuong thuc SaveAs voi cac doi so thich hop
    $doc.SaveAs($OutputPath, $wdFormatEncodedText, $null, $null, $null, $null, $null, $null, $null, $null, $null, $msoEncodingUTF8)
    
    $doc.Close([ref]$false) # wdDoNotSaveChanges
    $word.Quit()
    
    # Giai phong COM Object de tranh treo tien trinh WINWORD.EXE
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Host "=== DA HOAN THANH CONVERT PDF SANG TXT ==="
    exit 0
} catch {
    Write-Warning "Khong the su dung Word COM de convert PDF: $_"
    Write-Warning "Goi y: Hay su dung browser_subagent de mo file PDF va copy/paste text sang file .txt"
    exit 1
}
