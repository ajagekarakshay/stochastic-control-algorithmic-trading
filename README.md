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

The repository contains the approved 25-chapter architecture and six working
main-book drafts. Chapters are reviewed and rewritten one at a time, beginning
with Part I, rather than generated in bulk.
