"""Extract text from a PDF to stdout, one labeled block per page.

Usage:
    py scripts/extract_pdf.py "path/to/file.pdf"

Requires: pypdf  (py -m pip install pypdf)
"""

import sys
from pathlib import Path

from pypdf import PdfReader


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: py scripts/extract_pdf.py <file.pdf>", file=sys.stderr)
        return 2

    pdf_path = Path(sys.argv[1])
    if not pdf_path.is_file():
        print(f"not a file: {pdf_path}", file=sys.stderr)
        return 1

    reader = PdfReader(str(pdf_path))
    print(f"PAGES {len(reader.pages)}")
    for index, page in enumerate(reader.pages, start=1):
        text = (page.extract_text() or "").strip()
        print(f"\n===== PAGE {index} =====\n{text}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
