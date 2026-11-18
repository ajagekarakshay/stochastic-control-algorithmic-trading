#!/usr/bin/env python3
"""Reproduce or check the one-time Typst → Quarto migration.

Pandoc's Typst reader evaluates the manuscript and translates its math. This
script changes presentation and link destinations, never manuscript wording.
The preserved .typ files remain the reference for the migration audit.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"
CHAPTERS = [
    (1, "01-control-lens", "01-execution-problem"),
    (2, "02-microstructure", "02-how-markets-absorb-orders"),
    (3, "03-tca-identification", "03-execution-cost"),
    (4, "03b-modeling-research", "04-statistical-modeling"),
    (5, "04-execution-data", "05-execution-data"),
    (6, "05-impact-empirical", "06-empirical-market-impact"),
    (7, "06-impact-estimation", "07-estimating-market-impact"),
    (8, "07-liquidity-forecasting", "08-liquidity-state"),
    (16, "15-policy-evaluation", "16-policy-evaluation"),
    (24, "23-production-research", "24-production-research"),
]


def pandoc(args, content=None):
    executable = os.environ.get("PANDOC") or shutil.which("pandoc")
    command = [executable] if executable else [os.environ.get("QUARTO", "quarto"), "pandoc"]
    result = subprocess.run(command + args, input=content, text=True,
                            capture_output=True, cwd=ROOT)
    if result.returncode or result.stderr.strip():
        raise RuntimeError(f"Pandoc conversion failed or warned:\n{result.stderr}")
    # Some reader errors are printed to stdout with exit status zero.
    return result.stdout


def read_ast(text, source_format="typst"):
    return json.loads(pandoc(["-f", source_format, "-t", "json"], text))


def markdown(ast):
    return pandoc(["-f", "json", "-t", "markdown-smart-simple_tables-multiline_tables"
                   "+pipe_tables+fenced_divs", "--wrap=none", "--columns=160"], json.dumps(ast))


def node(kind, content):
    return {"t": kind, "c": content}


def attr(identifier="", classes=None):
    return [identifier, classes or [], []]


def words(text):
    result = []
    for index, word in enumerate(text.split()):
        if index:
            result.append({"t": "Space"})
        result.append(node("Str", word))
    return result


def inline_text(value):
    if isinstance(value, list):
        return "".join(inline_text(v) for v in value)
    if not isinstance(value, dict) or "t" not in value:
        return ""
    kind, content = value["t"], value.get("c")
    if kind == "Str":
        return content
    if kind in ("Space", "SoftBreak", "LineBreak"):
        return " "
    if kind in ("Span", "Link", "Image"):
        return inline_text(content[1])
    if kind == "Math":
        return content[1]
    if kind == "Header":
        return inline_text(content[2])
    return inline_text(content)


def walk(value):
    if isinstance(value, dict) and "t" in value:
        yield value
        yield from walk(value.get("c"))
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def prepared_source(source):
    text = source.read_text()
    text = re.sub(r'^#import[^\n]*\n', '', text, flags=re.M)
    if source.parent.name == "chapters" and source.parent.parent.name == "interview-qa":
        text = re.sub(r'^#let chapter-[a-z]+ = \[\s*', '', text, count=1, flags=re.M)
        assert text.rstrip().endswith("]"), source
        text = text.rstrip()[:-1]
        text = text.replace("#takeaway[", "#qa-takeaway[")
    # Pandoc 3.10 misreads a symbol call with semicolon-separated arguments,
    # and its bar(...) fallback loses the closing delimiter. These adapters
    # have been checked against Typst-rendered originals: tau (...) has the
    # same rendering as tau(...), and bar(P) renders as |P| (not an overbar).
    # Do not silently "correct" the author's notation during a format port.
    def adapt_math(match):
        body = match[1].replace("tau(", "tau (")
        body = re.sub(r'\bbar\(', 'abs(', body)
        return "$" + body + "$"
    text = re.sub(r'(?<!\\)\$(.*?)(?<!\\)\$', adapt_math, text, flags=re.S)
    return (ROOT / "scripts/typst-web-compat.typ").read_text() + "\n" + text


def group_panels(blocks):
    result, panel, kind = [], None, None
    for block in blocks:
        text = inline_text(block.get("c", [])) if block["t"] in ("Para", "Plain") else ""
        if text.startswith("PORTPANELSTART"):
            assert panel is None
            kind, panel = text.removeprefix("PORTPANELSTART"), []
        elif text == "PORTPANELEND":
            assert panel is not None
            result.append(node("Div", [attr(classes=["book-callout", f"book-{kind}"]), panel]))
            panel, kind = None, None
        elif panel is not None:
            panel.append(block)
        else:
            result.append(block)
    assert panel is None
    return result


def remove_empty_labels(blocks):
    """Pandoc emits a separate empty span after a Typst heading label."""
    result = []
    for block in blocks:
        if (block["t"] == "Para" and len(block["c"]) == 1
                and block["c"][0]["t"] == "Span" and not block["c"][0]["c"][1]
                and result and result[-1]["t"] == "Header"):
            result[-1]["c"][1][0] = block["c"][0]["c"][0][0]
        else:
            result.append(block)
    return result


def source_ast(source):
    ast = read_ast(prepared_source(source))
    ast["blocks"] = remove_empty_labels(group_panels(ast["blocks"]))
    for item in walk(ast["blocks"]):
        if item["t"] == "Math":
            assert not re.search(r'math\.|text\(body:|base:|\|\(', item["c"][1]), (
                f"{source}: unsupported Typst math conversion: {item['c'][1]}"
            )
    return ast


def signatures(ast):
    """Compare every prose character, formula, citation, list, and table cell.

    Normalize whitespace and typography that Markdown's smart punctuation
    renderer restores. Ignore presentation wrappers and anchor destinations.
    Math strings are compared separately without whitespace normalization.
    """
    prose, math, cites = [], [], []
    structures = Counter()

    def visit(value):
        if isinstance(value, list):
            for child in value:
                visit(child)
        elif isinstance(value, dict):
            kind, content = value["t"], value.get("c")
            if kind == "Str":
                prose.append(content)
            elif kind in ("Space", "SoftBreak", "LineBreak"):
                prose.append(" ")
            elif kind == "Math":
                math.append(content)
                prose.append(f" FORMULA{len(math)} ")
            elif kind == "Cite":
                cites.extend(c["citationId"] for c in content[0])
                prose.append(" CITATION ")
            elif kind == "Code":
                prose.append(content[1])
            elif kind == "CodeBlock":
                prose.append(content[1])
            elif kind == "Header":
                structures["Header"] += 1
                visit(content[2])
                prose.append(" ")
            elif kind in ("Span", "Link", "Image"):
                visit(content[1])
            elif kind == "Div":
                visit(content[1])
            elif kind == "Table":
                structures["Table"] += 1
                visit(content)
            elif kind in ("BulletList", "OrderedList"):
                structures[kind] += 1
                visit(content[1] if kind == "OrderedList" else content)
            elif kind == "Quoted":
                double = content[0]["t"] == "DoubleQuote"
                prose.append('"' if double else "'")
                visit(content[1])
                prose.append('"' if double else "'")
            elif kind == "RawBlock" and content == ["tex", "\\newpage"]:
                pass
            else:
                visit(content)
                if kind in ("Para", "Plain"):
                    prose.append(" ")
    visit(ast["blocks"])
    text = re.sub(r"\s+", " ", "".join(prose)).strip()
    return {"prose": text, "math": math, "citations": cites, "structure": dict(structures)}


def assert_equivalent(expected, actual, name):
    for field in expected:
        if expected[field] != actual[field]:
            if field == "prose":
                import difflib
                diff = "\n".join(difflib.unified_diff(expected[field].split(), actual[field].split(), n=5))
                raise AssertionError(f"{name}: prose changed\n{diff[:5000]}")
            raise AssertionError(f"{name}: {field} changed\n{expected[field]}\n{actual[field]}")


def extract_roadmap():
    text = (ROOT / "chapters/00-book-skeleton.typ").read_text()
    parts, entries, current = [], [], None
    calls = re.finditer(r'#roadmap-(part|entry)\(\s*(.*?)\n\)', text, re.S)
    for match in calls:
        body = match[2]
        # These prose-only arguments contain no nested markup brackets.
        fields = re.findall(r'\[([^\[\]]*)\]', body, re.S)
        fields = [re.sub(r'\s+', ' ', f).strip() for f in fields]
        if match[1] == "part":
            current = {"title": fields[0], "purpose": fields[1], "chapters": []}
            parts.append(current)
        else:
            number = int(re.match(r'\s*(\d+)', body)[1])
            target = re.search(r'target: <([^>]+)>', body)
            status = re.search(r'status: \[([^]]+)\]', body)
            entry = {"number": number, "title": fields[0], "purpose": fields[1],
                     "subtopics": fields[2], "status": status[1] if status else "Planned",
                     "target": target[1] if target else None}
            assert current is not None
            current["chapters"].append(entry)
            entries.append(entry)
    assert [e["number"] for e in entries] == list(range(1, 26))
    return parts, entries


def frontmatter(source=None, number=None, status=None, extra=None):
    lines = ["---"]
    if source:
        lines.append("source-typst: " + json.dumps(str(source.relative_to(ROOT))))
    if number:
        lines.append(f"chapter-number: {number}")
    if status:
        lines.append("draft-status: " + json.dumps(status))
    if extra:
        lines.extend(extra)
    return "\n".join(lines + ["---", "", ""])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check migration parity; do not write sources")
    args = parser.parse_args()
    os.chdir(ROOT)
    parts, entries = extract_roadmap()
    by_number = {e["number"]: e for e in entries}
    documents = []
    documents.append((ROOT / "chapters/00-preface.typ", Path("index.qmd"), None, None))
    for number, old, new in CHAPTERS:
        documents.append((ROOT / f"chapters/{old}.typ", Path(f"chapters/{new}.qmd"), number, "First draft"))
        by_number[number]["file"] = f"chapters/{new}.qmd"
    documents.append((ROOT / "chapters/05-optimal-execution.typ", Path("source-drafts/optimal-execution.qmd"), None, "Source draft"))
    for source in sorted((ROOT / "interview-qa/chapters").glob("*.typ")):
        documents.append((source, Path("interview-qa") / (source.stem + ".qmd"), None, None))
    for entry in entries:
        if "file" not in entry:
            slug = re.sub(r'[^a-z0-9]+', '-', entry["title"].lower()).strip('-')
            entry["file"] = f"chapters/{entry['number']:02d}-{slug}.qmd"

    asts = {str(dest): source_ast(source) for source, dest, _, _ in documents}
    labels = {"book-chapter-index": "chapter-index.qmd", "qa-chapter-index": "interview-qa/index.qmd"}
    for dest, ast in asts.items():
        for item in walk(ast["blocks"]):
            if item["t"] == "Header" and item["c"][1][0]:
                labels[item["c"][1][0]] = dest
    # Include the original detailed index, preserving its exact displayed text.
    skeleton = read_ast((ROOT / "chapters/00-book-skeleton.typ").read_text())
    asts["chapter-index.qmd"] = skeleton
    generated = {}
    report = []

    def relink(ast, dest):
        ast = copy.deepcopy(ast)
        for item in walk(ast["blocks"]):
            if item["t"] == "Link" and item["c"][2][0].startswith("#"):
                identifier = item["c"][2][0][1:]
                if identifier in labels:
                    target = labels[identifier]
                    if target != str(dest):
                        relative = os.path.relpath(target, dest.parent).replace(os.sep, "/")
                        item["c"][2][0] = relative + "#" + identifier
        return ast

    qa_paths = [dest for _, dest, _, _ in documents if dest.parent == Path("interview-qa")]
    for source, dest, number, status in documents:
        ast = asts[str(dest)]
        expected = signatures(ast)
        web_ast = relink(ast, dest)
        if number is None:
            for block in web_ast["blocks"]:
                if block["t"] == "Header" and block["c"][0] == 1:
                    block["c"][1][1].append("unnumbered")
        output = markdown(web_ast)
        # Pagebreaks have no meaning in the reflowable online edition.
        output = re.sub(r'```\{=tex\}\n\\newpage\n```\n*', '', output)
        assert_equivalent(expected, signatures(read_ast(output, "markdown")), str(dest))
        if not args.check:
            extra = ["number-sections: false"] if number is None else []
            if dest in qa_paths:
                index = qa_paths.index(dest)
                extra.append('qa-index: "index.qmd#qa-chapter-index"')
                if index > 0:
                    extra.append('qa-previous: ' + json.dumps(qa_paths[index-1].name))
                if index+1 < len(qa_paths):
                    extra.append('qa-next: ' + json.dumps(qa_paths[index+1].name))
                extra.extend(["other-links:", "  - text: Download this chapter (PDF)",
                              f"    href: ../assets/pdf/execution-interview-qa-chapter-{dest.name[:2]}.pdf"])
            generated[str(dest)] = frontmatter(source, number, status,
                                                extra) + output
        else:
            existing = (WEB / dest).read_text()
            assert_equivalent(expected, signatures(read_ast(existing, "markdown")), str(dest))
        report.append({"source": str(source.relative_to(ROOT)), "destination": str(dest),
                       "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                       "prose_sha256": hashlib.sha256(expected["prose"].encode()).hexdigest(),
                       "math_sha256": hashlib.sha256(json.dumps(expected["math"]).encode()).hexdigest(),
                       "formulas": len(expected["math"]), "structure": expected["structure"]})

    # Style each roadmap entry as a heading + badge instead of a layout table.
    roadmap = relink(skeleton, Path("chapter-index.qmd"))
    transformed = []
    for block in roadmap["blocks"]:
        if block["t"] == "Table":
            cells = block["c"][4][0][3][0][1]
            number = inline_text(cells[0][-1]).strip()
            title_blocks = cells[1][-1]
            status_blocks = cells[2][-1]
            title_inlines = title_blocks[0]["c"]
            if title_inlines[0]["t"] == "Strong":
                title_inlines = title_inlines[0]["c"]
            heading = node("Header", [3, attr(f"plan-{number}", ["unnumbered"]), words(number) + [{"t": "Space"}] + title_inlines])
            badge = node("Div", [attr(classes=["roadmap-status"]), status_blocks])
            transformed.extend([heading, badge])
        else:
            transformed.append(block)
    roadmap["blocks"] = transformed
    # Structural presentation changes are permitted; every displayed word is preserved.
    expected_roadmap = signatures(skeleton)
    actual_roadmap = signatures(roadmap)
    assert expected_roadmap["prose"] == actual_roadmap["prose"]
    roadmap_body = markdown(roadmap)
    generated["chapter-index.qmd"] = frontmatter(extra=["number-sections: false"]) + "# Chapter Index {#book-chapter-index .unnumbered}\n\n" + roadmap_body
    roadmap_markdown = (ROOT / "ROADMAP.md").read_text()
    roadmap_markdown = re.sub(r'(?m)^(# .+)$', r'\1 {.unnumbered}', roadmap_markdown, count=1)
    generated["roadmap.qmd"] = "---\nnumber-sections: false\n---\n\n" + roadmap_markdown
    # Planned pages contain only existing purpose/subtopic text and a status.
    for entry in entries:
        if entry["number"] in {n for n, _, _ in CHAPTERS}:
            continue
        body = f"# {entry['title']} {{#plan-ch{entry['number']:02d}}}\n\n"
        body += f"::: {{.planned-chapter}}\n{entry['status']}\n:::\n\n"
        body += entry["purpose"] + "\n\n**Subtopics.** " + entry["subtopics"] + "\n"
        generated[entry["file"]] = frontmatter(ROOT / "chapters/00-book-skeleton.typ", entry["number"], entry["status"]) + body
    qa_source = (ROOT / "interview-qa/main.typ").read_text()
    qa_listing = re.search(r'(?m)^1\. #link.*?(?=\n\n#pagebreak)', qa_source, re.S)[0]
    qa_index = read_ast(qa_listing)
    # Keep the exact titles and links from the companion's existing index.
    qa_index = relink(qa_index, Path("interview-qa/index.qmd"))
    generated["interview-qa/index.qmd"] = "---\nnumber-sections: false\n---\n\n# Execution and Market Impact Interview Q&A {#qa-chapter-index .unnumbered}\n\nQuestions first, then rigorous answers and discussion\n\n" + markdown(qa_index)
    generated["references.qmd"] = "# References {.unnumbered}\n\n::: {#refs}\n:::\n"
    if args.check:
        for name in ("chapter-index.qmd", "roadmap.qmd", "interview-qa/index.qmd"):
            if (WEB / name).read_text() != generated[name]:
                raise AssertionError(f"{name}: roadmap or index changed during migration")
        for entry in entries:
            if entry["number"] not in {n for n, _, _ in CHAPTERS}:
                if (WEB / entry["file"]).read_text() != generated[entry["file"]]:
                    raise AssertionError(f"Planned chapter {entry['number']} differs from the approved skeleton")
    else:
        for name, content in generated.items():
            path = WEB / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        (WEB / "migration-manifest.json").write_text(json.dumps({"documents": report, "parts": parts}, indent=2) + "\n")
    print(f"{'Verified' if args.check else 'Ported'} {len(documents)} source documents, "
          f"{sum(r['formulas'] for r in report)} formulas, all 25 chapter plans, and both roadmap/index pages.")


if __name__ == "__main__":
    main()
