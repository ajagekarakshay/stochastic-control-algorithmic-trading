# Stochastic Modeling and Optimal Control for Algorithmic Trading

A rigorous, intuition-first book on treating algorithmic trading as a problem of
inference and sequential decision-making under uncertainty.

The opening track is deliberately optimized for execution-services and
market-impact interviews:

1. trading as a stochastic control problem;
2. market microstructure and the state of liquidity;
3. transaction-cost measurement and statistical identification;
4. market-impact models and estimation; and
5. optimal liquidation, arrival price, and POV control.

The remaining roadmap extends the same lens to order placement, routing,
market making, multi-asset execution, robust control, and reinforcement
learning. See [`ROADMAP.md`](ROADMAP.md).

The book begins with a detailed 25-chapter skeleton that records each chapter's
purpose and planned subtopics. Existing material is linked from that index, and
every content page includes an Index link for returning to it.

## Build

The online edition uses [Quarto](https://quarto.org/) with the editorial textbook
theme. Its complete source is under [`web/`](web/): the existing chapters,
all 25 chapter plans, the detailed chapter index, the roadmap, the appendices,
the interview Q&A companion, and the retained source draft.

Install Quarto **1.11.9**, then run:

```bash
make web
make check-web
make web-preview
```

The rendered website is written to `web/_book/`. Quarto provides search,
responsive navigation, mathematical typesetting, citations, and previous/next
links. The site includes the existing main-book PDF and standalone Q&A PDFs as
downloads. No cumulative Q&A PDF is generated.

The original Typst sources remain intact as the reference for this migration
and for the existing PDF edition. The online sources are native Quarto Markdown
(`.qmd`); normal website builds do not require Typst or a conversion step.
Shared references remain in `references.bib`.

To audit that the migration preserves every manuscript word, formula, citation,
list, and table, run:

```bash
make check-port
```

This compares the `.qmd` content with the preserved Typst sources using Quarto's
bundled Pandoc reader. The audit permits presentation and link changes, and
normalizes whitespace, while comparing every translated formula. Migration
provenance and counts are recorded in `web/migration-manifest.json`.
`python3 scripts/port_typst.py` reproduces the migration and **overwrites the
ported `.qmd` files**; do not run it after making intentional edits to the online
edition. When new writing intentionally diverges from the archived Typst
edition, retire that document's migration comparison as part of the reviewed
content change instead of regenerating the online book.

## GitHub Pages

[Read the online book](https://ajagekarakshay.github.io/stochastic-control-algorithmic-trading/).

The workflow in [`.github/workflows/book.yml`](.github/workflows/book.yml)
checks content preservation, renders the book, checks every internal link and
Q&A backlink, and deploys to GitHub Pages after a push to `main`. Pull requests
run the same checks without publishing. In repository **Settings → Pages**,
the build source is **GitHub Actions**.

No custom domain is configured. When one is chosen, update `book.site-url` in
`web/_quarto.yml`, add `web/CNAME` with that domain, and configure the domain in
GitHub Pages and at the DNS provider. Relative chapter and asset links work
under the current repository URL and a future custom domain.

## PDF edition

Install [Typst](https://typst.app/open-source/), then run:

```bash
typst compile main.typ output/pdf/stochastic-control-algorithmic-trading.pdf
```

For live rebuilding:

```bash
typst watch main.typ output/pdf/stochastic-control-algorithmic-trading.pdf
```

The source is split by chapter under `chapters/`. References are maintained in
BibLaTeX format in `references.bib`.

## Execution interview Q&A

The separate Typst project under `interview-qa/` converts the daily execution
interview drills into navigable study chapters. Every chapter presents all
questions first and detailed answers afterward. Each question links to its
answer, and each answer links back to its question.

The first five chapters preserve the five completed historical drills:

1. participation, impact, and causal interpretation;
2. time of day, liquidity, and confounding;
3. transient impact, resilience, and schedule shape;
4. passive versus aggressive execution and queue risk; and
5. adaptive versus static POV and policy evaluation.

Build all standalone Q&A chapters with:

```bash
make qa-chapters
```

To build one chapter, use a target such as `make qa-chapter-03`.

Generated PDFs are stored under the root-level `output/pdf/` directory and are
committed with their Typst sources. Running `make all` refreshes the main book
and every standalone Q&A chapter PDF. The cumulative Q&A source remains useful
for organization, but no cumulative Q&A PDF is generated or committed. New
daily material must continue from the largest chapter number already in the
repository.

The cumulative Q&A PDF uses the same two-way navigation: its chapter index
links into every chapter, each page links back to the index, and each chapter
links to its neighbors. Standalone chapter PDFs intentionally omit
cross-document navigation while preserving question-answer links.

## Current status

The repository contains the approved 25-chapter architecture and ten working
main-book drafts (Chapters 1–8, 16, and 24), seven Q&A chapters, and one retained
source draft. The online port preserves their content. Unwritten chapters show
only the purpose and subtopics from the approved skeleton. Chapters are reviewed
and rewritten one at a time rather than generated in bulk.
