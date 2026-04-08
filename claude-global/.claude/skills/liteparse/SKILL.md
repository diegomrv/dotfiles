---
name: liteparse
description: Parse documents (PDF, DOCX, PPTX, XLSX, images) locally with LiteParse. Use when the user asks to extract text from files, parse documents, convert documents for processing, or needs to read content from PDFs/Office docs/images. Also triggers on "parse this file", "extract text", "read this PDF", or any document processing task.
---

# LiteParse

Local document parsing via the `lit` CLI. No cloud, no API keys. Outputs LLM-optimized text with spatial positioning.

## Prerequisites

- `lit` CLI installed (`brew install run-llama/liteparse/llamaindex-liteparse`)
- For Office docs (DOCX, PPTX, XLSX): LibreOffice (`brew install --cask libreoffice`)
- For images: ImageMagick (`brew install imagemagick`)

## Supported Formats

| Category | Formats |
|----------|---------|
| PDF | `.pdf` |
| Word | `.doc`, `.docx`, `.docm`, `.odt`, `.rtf` |
| PowerPoint | `.ppt`, `.pptx`, `.pptm`, `.odp` |
| Spreadsheets | `.xls`, `.xlsx`, `.xlsm`, `.ods`, `.csv`, `.tsv` |
| Images | `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.webp`, `.svg` |

Office docs and images are auto-converted to PDF before parsing (requires LibreOffice/ImageMagick).

## Core Commands

### Parse a single file

```bash
# Plain text (default) -- best for feeding to LLMs
lit parse document.pdf

# JSON with bounding boxes
lit parse document.pdf --format json -o output.json

# Specific pages
lit parse document.pdf --target-pages "1-5,10,15-20"

# No OCR (faster for digital/text-based PDFs)
lit parse document.pdf --no-ocr

# Higher DPI for better quality
lit parse document.pdf --dpi 300
```

### Batch parse a directory

```bash
lit batch-parse ./input-directory ./output-directory

# Filter by extension, recursive
lit batch-parse ./input ./output --extension .pdf --recursive
```

### Generate page screenshots

Useful when LLMs need to see visual layout (charts, forms, complex tables).

```bash
lit screenshot document.pdf -o ./screenshots
lit screenshot document.pdf --pages "1,3,5" --dpi 300 --format png -o ./screenshots
```

## Key Options

| Option | Description |
|--------|-------------|
| `--format json` | Structured JSON with bounding boxes |
| `--format text` | Plain text (default) |
| `-o <file>` | Save output to file |
| `--no-ocr` | Skip OCR (faster for digital PDFs) |
| `--ocr-language <code>` | OCR language (ISO code, default: en) |
| `--ocr-server-url <url>` | External OCR server (EasyOCR, PaddleOCR) |
| `--dpi <n>` | Render DPI (default: 150, use 300 for quality) |
| `--max-pages <n>` | Limit pages parsed |
| `--target-pages <pages>` | Specific pages (e.g. "1-5,10") |
| `--no-precise-bbox` | Faster, skip precise bounding boxes |
| `--skip-diagonal-text` | Ignore rotated text |
| `--preserve-small-text` | Keep very small text |

## Config File

For repeated use, create `liteparse.config.json`:

```json
{
  "ocrLanguage": "en",
  "ocrEnabled": true,
  "maxPages": 1000,
  "dpi": 150,
  "outputFormat": "json"
}
```

Use: `lit parse document.pdf --config liteparse.config.json`

## Tips

- **Digital PDFs** (most documents): use `--no-ocr` for speed
- **Scanned documents**: leave OCR on (default Tesseract.js, or use `--ocr-server-url` for better accuracy)
- **For LLM consumption**: plain text output (default) preserves layout via ASCII formatting that LLMs understand natively
- **For structured extraction**: JSON output includes bounding boxes per text element
- **Screenshots**: good fallback when text extraction misses visual elements (charts, diagrams)
