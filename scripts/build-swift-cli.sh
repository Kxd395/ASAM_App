#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../tools/pdf_export"
xcrun swiftc -O -framework Cocoa -framework PDFKit PDFExport.swift -o pdf_export
echo "Built tools/pdf_export/pdf_export"
