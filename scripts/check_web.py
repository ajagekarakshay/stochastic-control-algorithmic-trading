#!/usr/bin/env python3
"""Check the rendered book's pages, internal links, assets, and Q&A backlinks."""
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "web/_book"
REPO_PREFIX = "/stochastic-control-algorithmic-trading/"


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids = Counter()
        self.links = []
        self.math = 0
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids[attrs["id"]] += 1
        for key in ("href", "src", "poster"):
            if attrs.get(key):
                self.links.append((tag, attrs[key]))
        if "math" in attrs.get("class", "").split():
            self.math += 1


def main():
    pages = {p.resolve(): Page(p) for p in SITE.rglob("*.html")}
    errors = []
    assert len(pages) >= 40, f"Expected the complete book, found {len(pages)} pages"
    for path, page in pages.items():
        for identifier, count in page.ids.items():
            if count > 1:
                errors.append(f"{path.relative_to(SITE)}: duplicate id {identifier}")
        for tag, href in page.links:
            url = urlsplit(href)
            if url.scheme or url.netloc or href.startswith(("javascript:", "data:")):
                continue
            relative = unquote(url.path)
            if relative.startswith(REPO_PREFIX):
                target = SITE / relative[len(REPO_PREFIX):]
            elif relative.startswith("/"):
                target = SITE / relative.lstrip("/")
            elif relative:
                target = path.parent / relative
            else:
                target = path
            if target.is_dir():
                target /= "index.html"
            target = target.resolve()
            if not target.is_relative_to(SITE.resolve()):
                errors.append(f"{path.relative_to(SITE)}: link escapes site: {href}")
            elif not target.exists():
                errors.append(f"{path.relative_to(SITE)}: missing {href}")
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f"{path.relative_to(SITE)}: missing anchor {href}")
    question_count = 0
    for chapter in range(1, 8):
        candidates = list(SITE.glob(f"interview-qa/{chapter:02d}-*.html"))
        assert len(candidates) == 1, chapter
        page = pages[candidates[0].resolve()]
        assert any(href.endswith(f"execution-interview-qa-chapter-{chapter:02d}.pdf") for _, href in page.links), f"Q&A {chapter}: missing PDF download link"
        assert 'qa-chapter-navigation' in candidates[0].read_text(), f"Q&A {chapter}: missing chapter/index chain"
        questions = {i for i in page.ids if re.fullmatch(fr"c{chapter:02d}-q\d+", i)}
        assert questions, f"Missing questions in Q&A {chapter}"
        for question in questions:
            answer = question.replace("-q", "-a")
            question_count += 1
            if answer not in page.ids:
                errors.append(f"Q&A {chapter}: missing answer {answer}")
            if not any(href == f"#{answer}" for _, href in page.links):
                errors.append(f"Q&A {chapter}: missing question → answer link {question}")
            if not any(href == f"#{question}" for _, href in page.links):
                errors.append(f"Q&A {chapter}: missing answer → question link {answer}")
    for chapter in range(1, 26):
        candidates = list(SITE.glob(f"chapters/{chapter:02d}-*.html"))
        assert len(candidates) == 1, chapter
        source = candidates[0].read_text()
        title = re.search(r'<h1 class="title">(.*?)</h1>', source, re.S)[1]
        assert f'<span class="chapter-number">{chapter}</span>' in title, f"Chapter {chapter}: wrong numbering"
        assert 'class="book-status"' in source, f"Chapter {chapter}: missing draft/planned status"
    pdfs = list((SITE / "assets/pdf").glob("*.pdf"))
    assert len(pdfs) == 8, "Missing main or standalone Q&A PDF downloads"
    cname = ROOT / "web/CNAME"
    if cname.exists():
        assert (SITE / "CNAME").read_text() == cname.read_text(), "Custom domain was not copied"
    if errors:
        print("\n".join(errors[:80]), file=sys.stderr)
        raise SystemExit(f"{len(errors)} rendered-book errors")
    print(f"Verified {len(pages)} pages, {sum(p.math for p in pages.values())} math expressions, "
          f"{question_count} question/answer pairs, and {len(pdfs)} PDF downloads; no broken internal links.")


if __name__ == "__main__":
    main()
