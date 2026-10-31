---
name: doc-toolkit
description: >
  Bộ công cụ xử lý tài liệu chuyên dụng cho dự án FPT: convert PDF sang text,
  chuyển đổi Markdown sang Word (.doc/.docx), fix encoding UTF-8 tiếng Việt (mojibake),
  và tổng hợp nhiều tài liệu thành một file URD/SRS hoàn chỉnh.
  
  Kích hoạt skill này khi user đề cập đến bất kỳ thao tác nào sau:
  - "convert PDF", "đọc PDF", "trích xuất PDF", "PDF sang text/md/doc"
  - "chuyển md sang doc/docx/word", "tạo file word từ markdown"
  - "fix encoding", "fix UTF-8", "lỗi tiếng Việt", "ký tự bị lỗi", "mojibake"
  - "tổng hợp tài liệu", "gộp file", "merge tài liệu", "tổng hợp thành 1 file"
  - "tạo URD", "tạo SRS", "export ra doc", "lưu thành word"
  - "chuyển đổi giáo án", "convert doc sang md", "căn chỉnh bảng gv hs", "thẳng hàng gv hs"
  Không cần user nói đúng tên skill — chỉ cần có ý định xử lý tài liệu là dùng.
---

# Doc Toolkit — Bộ Công Cụ Xử Lý Tài Liệu

Skill này cung cấp các công cụ tái sử dụng để xử lý tài liệu, giúp tránh phải viết lại script
mỗi lần sử dụng. Tất cả script nằm trong thư mục `scripts/`.

## Tổng quan công cụ

| Tool | Script | Mô tả |
|------|--------|-------|
| PDF → TXT | `scripts/pdf_to_txt.ps1` | Đọc PDF qua browser, lưu text |
| MD → DOC | `scripts/md_to_doc.ps1` | Convert Markdown sang HTML-Word |
| Fix UTF-8 | `scripts/fix_utf8.ps1` | Fix mojibake CP1252 → UTF-8 |
| Tổng hợp tài liệu | `scripts/merge_docs.ps1` | Gộp nhiều file thành 1 |
| DOC → MD | *(Quy trình & logic bên dưới)* | Convert .doc sang .md, tự động căn chỉnh hàng bảng GV - HS |

---

## 1. PDF → TXT: Trích xuất nội dung PDF

**Khi nào dùng**: User muốn đọc nội dung file PDF và lưu thành `.txt` để xử lý tiếp.

**Cách dùng**:

Vì Windows thường không có `pdftotext`, cách tốt nhất là dùng browser để đọc PDF:

```
Dùng browser_subagent để:
1. Mở file PDF: file:///đường-dẫn/đến/file.pdf
2. Đọc toàn bộ nội dung trang
3. Trả về text đầy đủ
4. Lưu vào file .txt tương ứng
```

**Script PowerShell** (nếu có thư viện iTextSharp hoặc dùng COM Word):

```powershell
# Dùng script: scripts/pdf_to_txt.ps1
# Tham số: -PdfPath <đường dẫn PDF> -OutputPath <đường dẫn TXT>
powershell -ExecutionPolicy Bypass -File .agent/skills/doc-toolkit/scripts/pdf_to_txt.ps1 `
  -PdfPath "result_docs/file.pdf" `
  -OutputPath "result_docs/file.txt"
```

**Lưu ý quan trọng**:
- PDF dạng scan hình ảnh cần OCR (dùng browser để đọc visual content)
- PDF dạng text thuần thường đọc được qua browser
- Đặt tên file output theo pattern: `pdf<số>_<tên_ngắn>.txt`

---

## 2. MD → DOC: Chuyển Markdown sang Word

**Khi nào dùng**: User muốn export tài liệu Markdown thành file Word (`.doc` hoặc `.docx`).

**Hai phương pháp**:

### Phương pháp A: HTML-Word (khuyến nghị — không cần cài thêm)

Tạo file `.doc` thực chất là HTML với Word namespace. Microsoft Word đọc được hoàn hảo.

```powershell
# Dùng script: scripts/md_to_doc.ps1
powershell -ExecutionPolicy Bypass -File .agent/skills/doc-toolkit/scripts/md_to_doc.ps1 `
  -InputMd "result_docs/document.md" `
  -OutputDoc "result_docs/document.doc" `
  -TemplatePath ".agent/skills/ba-senior/templates/fpt_urd_template.doc"
```

**Cấu trúc HTML-Word chuẩn FPT**:
- Font body: Times New Roman 12pt
- Font heading: Arial (h1=#1f4e78, h2=#2e75b6, h3=#5b9bd5)
- Table styles: `header-table`, `data-table`, `usecase-table`
- Encoding: UTF-8 bắt buộc

### Phương pháp B: Dùng pandoc (nếu đã cài)

```powershell
pandoc -f markdown -t docx -o output.docx input.md --reference-doc=template.docx
```

**Quy tắc encoding bắt buộc** (tránh lỗi tiếng Việt):
```powershell
# ĐÚNG: Dùng WriteAllText với UTF-8 encoding
[System.IO.File]::WriteAllText($outputPath, $content, [System.Text.Encoding]::UTF8)

# SAI: Dùng Out-File thông thường (gây mojibake)
# $content | Out-File $outputPath  ← KHÔNG dùng cái này
```

---

## 3. Fix UTF-8: Sửa lỗi encoding tiếng Việt

**Khi nào dùng**: File `.doc`/`.html`/`.txt` có ký tự tiếng Việt bị lỗi kiểu:
- `MÃ£ hiá»‡u` thay vì `Mã hiệu`
- `â€"` thay vì `–`
- `chuáº©n` thay vì `chuẩn`

**Nguyên nhân**: File được ghi bằng UTF-8 nhưng đọc/lưu lại theo CP1252 (Windows-1252), gây double-encode.

**Script sửa lỗi**:

```powershell
# Dùng script: scripts/fix_utf8.ps1
powershell -ExecutionPolicy Bypass -File .agent/skills/doc-toolkit/scripts/fix_utf8.ps1 `
  -FilePath "đường-dẫn/file-bị-lỗi.doc"
# Script sẽ overwrite trực tiếp file gốc sau khi fix
```

**Logic fix (inline)**:
```powershell
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$bytes    = [System.IO.File]::ReadAllBytes($filePath)
$utf8Str  = [System.Text.Encoding]::UTF8.GetString($bytes)
$cp1252   = [System.Text.Encoding]::GetEncoding(1252)
$fixed    = [System.Text.Encoding]::UTF8.GetString($cp1252.GetBytes($utf8Str))

# Loại bỏ BOM nếu có
$idx = $fixed.IndexOf("<html")
if ($idx -gt 0) { $fixed = $fixed.Substring($idx) }

[System.IO.File]::WriteAllText($filePath, $fixed, [System.Text.Encoding]::UTF8)
```

---

## 4. Tổng hợp tài liệu: Gộp nhiều file thành 1 URD

**Khi nào dùng**: User có nhiều file (PDF text, MD, DOC) và muốn gộp thành 1 tài liệu hoàn chỉnh.

**Quy trình chuẩn**:

```
Bước 1: Đọc từng file nguồn theo thứ tự ưu tiên
  - File MD: đọc trực tiếp bằng view_file
  - File TXT (từ PDF): đọc trực tiếp bằng view_file  
  - File DOC: đọc bằng view_file (HTML-based)

Bước 2: Phân tích và map cấu trúc
  - Xác định section nào thuộc về module/chức năng nào
  - Tránh trùng lặp nội dung
  - Giữ nguyên toàn bộ nội dung — KHÔNG rút gọn

Bước 3: Gộp theo cấu trúc URD FPT chuẩn
  - REVISION HISTORY
  - I. GIỚI THIỆU (Mục đích, Phạm vi, Thuật ngữ)
  - II. TỔNG QUAN HỆ THỐNG (Business Flow, Danh sách chức năng, Permission Matrix)
  - III. ĐẶC TẢ CHI TIẾT CÁC CHỨC NĂNG (Use Case Specs từng module)
  - IV. YÊU CẦU PHI CHỨC NĂNG (Performance, UX, Security)
  - V. PHỤ LỤC

Bước 4: Export ra MD trước, sau đó convert sang DOC
```

**Lệnh tổng hợp nhanh**:
```powershell
# Dùng script: scripts/merge_docs.ps1
powershell -ExecutionPolicy Bypass -File .agent/skills/doc-toolkit/scripts/merge_docs.ps1 `
  -InputFiles "file1.txt,file2.txt,file3.md" `
  -OutputMd "result_docs/output.md" `
  -OutputDoc "result_docs/output.doc"
```

---

## 5. DOC → MD: Chuyển đổi và Căn chỉnh Giáo án thẳng hàng

**Khi nào dùng**: Chuyển đổi file giáo án `.doc` (chứa các bảng tiến trình dạy học gồm cột hoạt động của GV và HS) sang định dạng Markdown `.md`, yêu cầu ngắt dòng đề mục tự động và phân tách các hoạt động thành từng hàng đối ứng thẳng tắp.

### Quy trình kỹ thuật chuẩn:

1. **Export sang HTML Filtered:** Sử dụng Word COM để xuất file `.doc` sang HTML để dễ dàng phân tích cấu trúc bảng biểu.
2. **Giải mã mã hóa tiếng Việt:** Giải mã NCRs & Windows-1252 về Unicode UTF-8 sạch sẽ.
3. **Ngắt dòng đề mục thông minh:** Chèn ngắt dòng `<br>` tự động trước các đề mục (`1.`, `2.`, `2.1.`, `-`, `+`, `*`) bên trong ô bảng Markdown bằng Regex có Negative Lookbehind để tránh phá hỏng định dạng chỉ số và số hình vẽ.
4. **Phân tách và căn chỉnh bảng biểu:**
   * Trích xuất toàn bộ dòng GV và HS của bảng.
   * Định nghĩa danh sách các tiêu đề hoạt động lớn của giáo viên (`GV_Sections`) và số lượng hàng phản hồi tương ứng của học sinh cho mỗi hoạt động (`HS_RowCounts`).
   * Phân bổ tuần tự các câu trả lời của HS tương ứng với hoạt động của GV.
   * Tạo bảng Markdown mới có nhiều hàng nhỏ thẳng hàng tuyệt đối.

---

## Checklist trước khi giao file cho user

- [ ] File `.doc` mở được bằng Microsoft Word không bị lỗi format
- [ ] Tiếng Việt hiển thị đúng, không có ký tự lạ kiểu `Ã`, `â€`
- [ ] File có `<meta charset="utf-8">` trong `<head>`
- [ ] Sử dụng đúng template FPT (font, màu heading, table styles)
- [ ] Nội dung đầy đủ, không bị cắt bớt so với source
- [ ] Các cột trong bảng đối xứng thẳng hàng tuyệt đối, không bị lệch hoặc dồn đống

---

## Scripts reference

Xem chi tiết từng script trong thư mục `scripts/`:
- `pdf_to_txt.ps1` — Trích xuất PDF sang TXT
- `md_to_doc.ps1` — Convert MD sang HTML-Word
- `fix_utf8.ps1` — Sửa lỗi encoding UTF-8
- `merge_docs.ps1` — Tổng hợp nhiều file thành 1

---

## Tips & Gotchas

### Tránh lỗi encoding khi tạo file bằng PowerShell here-string

```powershell
# VẤN ĐỀ: PowerShell here-string @"..."@ có thể gây lỗi encoding với tiếng Việt
# GIẢI PHÁP: Luôn dùng WriteAllText với UTF-8 encoding rõ ràng
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
```

### Xử lý lỗi OneDrive File Locking (RPC Server unavailable 0x800706BE)

*   **Vấn đề:** Khi tự động hóa MS Word qua COM Object trong thư mục được đồng bộ OneDrive (như Desktop, Documents), OneDrive sync client sẽ cố gắng khóa và đồng bộ file ngay khi được tạo, gây tranh chấp tài nguyên khiến Word COM bị sập đột ngột với lỗi RPC `0x800706BE`.
*   **Giải pháp:** Copy file nguồn ra một thư mục tạm thời nằm ngoài OneDrive (ví dụ: `C:\Users\hoang\.gemini\antigravity-ide\temp\`), thực hiện toàn bộ quá trình mở, sửa đổi, lưu bằng Word COM tại đó. Sau khi hoàn thành và thoát Word, sao chép file kết quả đè ngược lại workspace.

### Xử lý lỗi mã hóa tiếng Việt dạng NCRs & Windows-1252 trong HTML xuất từ Word

*   **Vấn đề:** Word lưu các ký tự tiếng Việt đặc biệt bằng thực thể NCR (như `&#7846;`...) và các ký tự Latin-1 (như À, Ô, Ê...) bằng mã hóa byte thô `windows-1252`. Nếu đọc trực tiếp bằng UTF-8, các ký tự Latin-1 này sẽ bị hỏng thành ký tự rác (mojibake) vĩnh viễn.
*   **Giải pháp:** Đọc file HTML nguồn bằng encoding `windows-1252` trước, sau đó dùng `[System.Net.WebUtility]::HtmlDecode($content)` để chuyển đổi toàn bộ sang Unicode tiếng Việt UTF-8 chuẩn sạch đẹp.

### Chuyển đổi HTML sang .doc nhị phân an toàn không gây hỏng cấu trúc file

*   **Vấn đề:** Mở file HTML trực tiếp bằng Word rồi `SaveAs` sang `.doc` nhị phân cũ (wdFormatDocument = 0) dễ làm hỏng cấu trúc file (corrupted doc), gây sập Word ở lần mở tiếp theo.
*   **Giải pháp:** Tạo một tài liệu Word trống mới tinh (`$word.Documents.Add()`), sau đó sử dụng phương thức `InsertFile` để import nội dung HTML:
    ```powershell
    $doc = $word.Documents.Add()
    $doc.Range().InsertFile($htmlPath)
    $doc.SaveAs($docPath, 0)
    ```
    Phương pháp này import và convert định dạng an toàn 100% không làm hỏng file.

### Tránh trùng tên biến tự động `$matches` trong PowerShell

*   **Vấn đề:** `$matches` là biến hệ thống được PowerShell tự động cập nhật kết quả so khớp mỗi khi sử dụng toán tử `-match`. Việc tự ý đặt tên biến trùng với `$matches` (như `$matches = [regex]::Matches(...)`) sẽ khiến biến này bị PowerShell ghi đè thành Hashtable rỗng hoặc rác sau lượt so khớp `-match` đầu tiên bên trong vòng lặp, làm sập logic duyệt của script một cách thầm lặng.
*   **Giải pháp:** Luôn sử dụng tên biến khác biệt (như `$tableMatches` hoặc `$allMatches`) để tránh xung đột với biến tự động của hệ thống.

### Ký tự xuống dòng Unix trong PowerShell split

*   **Vấn đề:** Khi sử dụng toán tử `-split` để tách dòng theo ngắt dòng Unix (`\n`), nếu viết chuỗi `"\n"` (dấu backslash n) trong nháy kép, PowerShell sẽ hiểu đó là hai ký tự thô `\` và `n` chứ không phải ký tự xuống dòng thực sự, dẫn đến tách chuỗi thất bại.
*   **Giải pháp:** Luôn viết ký tự ngắt dòng bằng dấu backtick là `` "`n" `` hoặc dùng `[char]10` (Line Feed) để split chuẩn xác.

### So khớp tên hoạt động giáo án ổn định bất chấp định dạng

*   **Vấn đề:** Các tiêu đề hoạt động trong giáo án thường bị lệch so khớp do có thêm các ký tự bôi đậm `**`, ký tự hoa thị `*`, dấu hai chấm `:`, dấu phẩy `,` nằm xen giữa.
*   **Giải pháp:** Trước khi so khớp `.Contains()`, hãy loại bỏ toàn bộ ký tự không phải là chữ cái và chữ số ASCII khỏi cả hai chuỗi so sánh:
    ```powershell
    $cleanNextSec = (Remove-Diacritics $nextSecName) -replace '[^a-zA-Z0-9]', ''
    $cleanGvLine = (Remove-Diacritics $gvLine) -replace '[^a-zA-Z0-9]', ''
    ```
    Phương pháp này triệt tiêu hoàn toàn ảnh hưởng của định dạng, bảo đảm độ chính xác so khớp 100%.

### Nhận diện Header/Separator bảng Markdown theo vị trí dòng thực tế

*   **Vấn đề:** Việc sử dụng Regex để phán đoán dòng nào là Header bảng Markdown (như tìm kiếm chữ "GV" và "HS") rất dễ bị nhận diện sai khi dòng dữ liệu lớn trong bảng chứa các chữ viết tắt này (ví dụ: "cho HS quan sát...", "GV hướng dẫn..."), làm mất mát hoặc hỏng toàn bộ dữ liệu bảng.
*   **Giải pháp:** Một bảng Markdown chuẩn luôn có dòng đầu tiên là Header và dòng thứ hai là Separator (chứa `| --- |`). Do đó, hãy lọc các dòng bắt đầu bằng `|`, sau đó gán trực tiếp dòng thứ nhất làm Header, dòng thứ hai làm Separator nếu khớp `---`, và toàn bộ các dòng sau đó là dòng dữ liệu.

### PDF scan vs PDF text

- **PDF text thuần**: Dùng browser_subagent đọc nội dung DOM
- **PDF scan (hình ảnh)**: Phải dùng OCR — có thể dùng browser để đọc text được render bởi PDF viewer

### Thứ tự ưu tiên khi tổng hợp

Nếu có thông tin trùng lặp giữa các file, ưu tiên theo thứ tự:
1. File mới nhất (timestamp cao hơn)
2. File có version cao hơn (v1.1 > v1.0)
3. File có nhiều chi tiết hơn
