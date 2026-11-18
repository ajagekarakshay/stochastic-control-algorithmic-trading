#!/usr/bin/env python3
"""Stage the existing bibliography and committed standalone PDF downloads."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
destination = root / "web/assets/pdf"
destination.mkdir(parents=True, exist_ok=True)
sources = sorted((root / "output/pdf").glob("*.pdf"))
allowed = [p for p in sources if p.name == "stochastic-control-algorithmic-trading.pdf"
           or p.name.startswith("execution-interview-qa-chapter-")]
expected = 1 + len(list((root / "interview-qa").glob("chapter-*.typ")))
assert len(allowed) == expected, "Expected the main book and every standalone Q&A PDF"
for path in allowed:
    shutil.copyfile(path, destination / path.name)
print(f"Staged {len(allowed)} existing PDF downloads.")
