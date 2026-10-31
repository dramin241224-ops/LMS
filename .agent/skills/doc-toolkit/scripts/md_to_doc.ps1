param(
    [Parameter(Mandatory=$true)]
    [string]$InputMd,
    [Parameter(Mandatory=$true)]
    [string]$OutputDoc,
    [Parameter(Mandatory=$false)]
    [string]$TemplatePath
)

# Thiết lập encoding mặc định cho Output là UTF-8
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Chuẩn hóa đường dẫn
$InputMd = [System.IO.Path]::GetFullPath($InputMd)
$OutputDoc = [System.IO.Path]::GetFullPath($OutputDoc)

if (-not (Test-Path $InputMd)) {
    Write-Error "File Markdown dau vao khong ton tai: $InputMd"
    exit 1
}

# Đảm bảo thư mục cha của OutputDoc tồn tại
$parentDir = Split-Path $OutputDoc
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# 1. Đọc nội dung Markdown (đọc dạng UTF-8)
$mdContent = [System.IO.File]::ReadAllText($InputMd, [System.Text.Encoding]::UTF8)

# 2. Định nghĩa hàm parse inline và block Markdown sang HTML
function Convert-InlineMarkdown {
    param ([string]$text)
    
    # Fix HTML escape cơ bản
    $text = $text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
    # Restore lại các tags HTML mà ta tự sinh hoặc có sẵn trong markdown được cho phép
    $text = $text -replace '&lt;br\s*/?&gt;', '<br/>'
    $text = $text -replace '&lt;div\s+class=&quot;page-break&quot;&gt;&lt;/div&gt;', '<div class="page-break"></div>'
    
    # Bold: **text** hoặc __text__
    $text = $text -replace '\*\*(.*?)\*\*', '<strong>$1</strong>'
    $text = $text -replace '__(.*?)__', '<strong>$1</strong>'
    
    # Italic: *text* hoặc _text_
    $text = $text -replace '\*(.*?)\*', '<em>$1</em>'
    $text = $text -replace '_(.*?)_', '<em>$1</em>'
    
    # Inline code: `code`
    $text = $text -replace '`(.*?)`', '<code style="background-color:#f2f2f2;padding:2px 4px;font-family:Consolas;">$1</code>'
    
    # Links: [text](url)
    $text = $text -replace '\[(.*?)\]\((.*?)\)', '<a href="$2">$1</a>'
    
    return $text
}

function Convert-TableToHtml {
    param ($rows)
    
    if ($rows.Count -lt 1) { return "" }
    
    # Phân tích xem có phải là usecase-table hay data-table
    $tableClass = "data-table"
    
    # Kiểm tra xem có cột nào chứa nhãn usecase không để tự động đổi class
    foreach ($row in $rows) {
        $trimmedRow = $row.Trim()
        if ($trimmedRow.StartsWith("|")) { $trimmedRow = $trimmedRow.Substring(1) }
        if ($trimmedRow.EndsWith("|")) { $trimmedRow = $trimmedRow.Substring(0, $trimmedRow.Length - 1) }
        $cells = $trimmedRow -split "\|"
        if ($cells.Count -gt 0) {
            $firstCell = $cells[0].Trim()
            if ($firstCell -match "^(Description|Actor|Trigger|Pre-condition|Post-condition|Precondition|Postcondition|Tác nhân|Điều kiện|Kết quả|Mô tả)$" -or $firstCell -match "^(Pre-conditions|Post-conditions)$") {
                $tableClass = "usecase-table"
                break
            }
        }
    }
    
    $html = New-Object System.Text.StringBuilder
    $html.AppendLine("<table class='$tableClass'>") | Out-Null
    
    $headerProcessed = $false
    
    foreach ($row in $rows) {
        $trimmedRow = $row.Trim()
        # Loại bỏ pipe ở đầu và cuối
        if ($trimmedRow.StartsWith("|")) { $trimmedRow = $trimmedRow.Substring(1) }
        if ($trimmedRow.EndsWith("|")) { $trimmedRow = $trimmedRow.Substring(0, $trimmedRow.Length - 1) }
        
        $cells = $trimmedRow -split "\|"
        for ($j = 0; $j -lt $cells.Length; $j++) {
            $cells[$j] = $cells[$j].Trim()
        }
        
        # Kiểm tra separator
        $isSeparator = $true
        foreach ($cell in $cells) {
            if ($cell -notmatch "^[\s\-\:\n\r\t]*$") {
                $isSeparator = $false
                break
            }
        }
        if ($isSeparator) { continue }
        
        if (-not $headerProcessed) {
            # Dòng đầu tiên là Header
            $html.AppendLine("<thead><tr>") | Out-Null
            foreach ($cell in $cells) {
                # Không escape HTML cho nội dung header
                $headerText = $cell.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
                $headerText = $headerText -replace '\*\*(.*?)\*\*', '<strong>$1</strong>'
                $html.AppendLine("<th>$headerText</th>") | Out-Null
            }
            $html.AppendLine("</tr></thead><tbody>") | Out-Null
            $headerProcessed = $true
        } else {
            $html.AppendLine("<tr>") | Out-Null
            
            # Nếu là usecase-table, cell đầu tiên là label
            $isFirstCell = $true
            foreach ($cell in $cells) {
                $cellText = Convert-InlineMarkdown $cell
                if ($tableClass -eq "usecase-table" -and $isFirstCell) {
                    $html.AppendLine("<td class='label'>$cellText</td>") | Out-Null
                    $isFirstCell = $false
                } else {
                    $html.AppendLine("<td>$cellText</td>") | Out-Null
                }
            }
            $html.AppendLine("</tr>") | Out-Null
        }
    }
    
    if ($headerProcessed) {
        $html.AppendLine("</tbody>") | Out-Null
    }
    $html.AppendLine("</table>") | Out-Null
    
    return $html.ToString()
}

function Convert-MarkdownToHtml {
    param (
        [string]$MarkdownContent
    )
    
    $lines = $MarkdownContent -replace "`r`n", "`n" -split "`n"
    $htmlOutput = New-Object System.Text.StringBuilder
    
    $inList = $false
    $listType = "" # "ul" hoặc "ol"
    $inTable = $false
    $tableRows = @()
    $inBlockquote = $false
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i].TrimEnd()
        
        # 1. Xử lý Table
        if ($line -match "^\s*\|") {
            if ($inList) {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            if ($inBlockquote) {
                $htmlOutput.AppendLine("</blockquote>") | Out-Null
                $inBlockquote = $false
            }
            
            $inTable = $true
            $tableRows += $line
            continue
        } else {
            if ($inTable) {
                $htmlOutput.AppendLine((Convert-TableToHtml $tableRows)) | Out-Null
                $inTable = $false
                $tableRows = @()
            }
        }
        
        # Bỏ qua dòng trống
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($inList) {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            if ($inBlockquote) {
                $htmlOutput.AppendLine("</blockquote>") | Out-Null
                $inBlockquote = $false
            }
            continue
        }
        
        # 2. Xử lý Blockquote
        if ($line -match "^\s*>\s*(.*)") {
            if ($inList) {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            $blockquoteContent = $Matches[1]
            if (-not $inBlockquote) {
                $htmlOutput.AppendLine("<blockquote>") | Out-Null
                $inBlockquote = $true
            }
            $htmlOutput.AppendLine("<p>$(Convert-InlineMarkdown $blockquoteContent)</p>") | Out-Null
            continue
        } else {
            if ($inBlockquote) {
                $htmlOutput.AppendLine("</blockquote>") | Out-Null
                $inBlockquote = $false
            }
        }
        
        # 3. Xử lý Headings
        if ($line -match "^\s*(#{1,6})\s+(.+)$") {
            if ($inList) {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            $level = $Matches[1].Length
            $headingText = Convert-InlineMarkdown $Matches[2]
            $htmlOutput.AppendLine("<h$level>$headingText</h$level>") | Out-Null
            continue
        }
        
        # 4. Xử lý Unordered Lists
        if ($line -match "^\s*[\*\-\+]\s+(.+)$") {
            $listContent = Convert-InlineMarkdown $Matches[1]
            if ($inList -and $listType -ne "ul") {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            if (-not $inList) {
                $htmlOutput.AppendLine("<ul>") | Out-Null
                $inList = $true
                $listType = "ul"
            }
            $htmlOutput.AppendLine("<li>$listContent</li>") | Out-Null
            continue
        }
        
        # 5. Xử lý Ordered Lists
        if ($line -match "^\s*\d+\.\s+(.+)$") {
            $listContent = Convert-InlineMarkdown $Matches[1]
            if ($inList -and $listType -ne "ol") {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            if (-not $inList) {
                $htmlOutput.AppendLine("<ol>") | Out-Null
                $inList = $true
                $listType = "ol"
            }
            $htmlOutput.AppendLine("<li>$listContent</li>") | Out-Null
            continue
        }
        
        # 6. HTML thuần hoặc các page break
        $trimmedLine = $line.Trim()
        if ($trimmedLine.StartsWith("<div") -or $trimmedLine.StartsWith("</div") -or $trimmedLine.StartsWith("<table") -or $trimmedLine.StartsWith("<tr") -or $trimmedLine.StartsWith("<td") -or $trimmedLine.StartsWith("<p") -or $trimmedLine.StartsWith("<span") -or $trimmedLine.StartsWith("</span")) {
            if ($inList) {
                $htmlOutput.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            $htmlOutput.AppendLine($line) | Out-Null
            continue
        }
        
        # 7. Dòng văn bản bình thường (Paragraph)
        if ($inList) {
            $htmlOutput.AppendLine("</$listType>") | Out-Null
            $inList = $false
        }
        $pContent = Convert-InlineMarkdown $line
        $htmlOutput.AppendLine("<p>$pContent</p>") | Out-Null
    }
    
    # Dọn dẹp thẻ cuối file
    if ($inTable) {
        $htmlOutput.AppendLine((Convert-TableToHtml $tableRows)) | Out-Null
    }
    if ($inList) {
        $htmlOutput.AppendLine("</$listType>") | Out-Null
    }
    if ($inBlockquote) {
        $htmlOutput.AppendLine("</blockquote>") | Out-Null
    }
    
    return $htmlOutput.ToString()
}

# 3. Convert MD content sang HTML body
Write-Host "Converting Markdown to HTML..."
$bodyHtml = Convert-MarkdownToHtml $mdContent

# 4. Thiết lập Head/Style (Sử dụng template CSS chuẩn FPT)
$headHtml = @"
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>FPT.VN URD</title>
<style>
    body { font-family: 'Times New Roman', Times, serif; line-height: 1.5; color: #000000; font-size: 12pt; }
    .header-table { width: 100%; border: 1px solid #000; border-collapse: collapse; margin-bottom: 20px; }
    .header-table td { border: 1px solid #000; padding: 10px; font-weight: bold; }
    h1 { font-family: 'Arial', sans-serif; color: #1f4e78; font-size: 18pt; font-weight: bold; text-transform: uppercase; margin-top: 24px; margin-bottom: 12px; }
    h2 { font-family: 'Arial', sans-serif; color: #2e75b6; font-size: 14pt; font-weight: bold; margin-top: 20px; margin-bottom: 10px; border-bottom: 1px solid #2e75b6; padding-bottom: 3px; }
    h3 { font-family: 'Arial', sans-serif; color: #5b9bd5; font-size: 12pt; font-weight: bold; margin-top: 16px; margin-bottom: 8px; }
    h4 { font-family: 'Arial', sans-serif; color: #000; font-size: 12pt; font-weight: bold; margin-top: 12px; margin-bottom: 6px; }
    table.data-table { border-collapse: collapse; width: 100%; margin-top: 10px; margin-bottom: 15px; }
    table.data-table th, table.data-table td { border: 1px solid #000000; padding: 8px; text-align: left; vertical-align: top; }
    table.data-table th { background-color: #d9e1f2; font-weight: bold; color: #1f4e78; }
    table.usecase-table { border-collapse: collapse; width: 100%; margin-top: 8px; margin-bottom: 12px; }
    table.usecase-table td { border: 1px solid #000000; padding: 8px; vertical-align: top; }
    table.usecase-table td.label { background-color: #f2f2f2; font-weight: bold; width: 150px; }
    ul, ol { margin-top: 5px; margin-bottom: 10px; padding-left: 20px; }
    li { margin-bottom: 4px; }
    p { margin-top: 0; margin-bottom: 8px; }
    blockquote { margin-left: 20px; border-left: 3px solid #ccc; padding-left: 10px; color: #555; }
    .page-break { page-break-before: always; }
</style>
</head>
"@

# Nếu có template, thử extract head & style từ template
if ($TemplatePath -and (Test-Path $TemplatePath)) {
    Write-Host "Extracting styles from template: $TemplatePath"
    try {
        $tempContent = [System.IO.File]::ReadAllText($TemplatePath, [System.Text.Encoding]::UTF8)
        if ($tempContent -match "<head>([\s\S]*?)<\/head>") {
            $headHtml = "<head>" + $Matches[1] + "</head>"
            Write-Host "Successfully extracted <head> from template."
        }
    } catch {
        Write-Warning "Could not extract head from template: $_. Using default FPT style."
    }
}

# 5. Lắp ghép HTML-Word Document
$finalHtml = @"
<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
$headHtml
<body>
$bodyHtml
</body>
</html>
"@

# 6. Ghi ra file với UTF-8 encoding (đảm bảo hiển thị đúng tiếng Việt)
Write-Host "Writing output to: $OutputDoc"
[System.IO.File]::WriteAllText($OutputDoc, $finalHtml, $Utf8NoBom)

Write-Host "=== DA HOAN THANH CONVERT MD SANG DOC ==="
exit 0
