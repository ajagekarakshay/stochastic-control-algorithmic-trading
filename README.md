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

## Build

Install [Typst](https://typst.app/open-source/), then run:

```bash
typst compile main.typ build/book.pdf
```

For live rebuilding:

```bash
typst watch main.typ build/book.pdf
```

The source is split by chapter under `chapters/`. References are maintained in
BibLaTeX format in `references.bib`.

## Execution interview Q&A

The separate Typst project under `interview-qa/` converts the daily execution
interview drills into navigable study chapters. Every chapter presents all
questions first and detailed answers afterward. Each question links to its
answer, and each answer links back to its question.

Build the cumulative Q&A book and the current standalone chapter with:

```bash
make qa
make qa-chapter-01
```

Generated PDFs remain under `build/` and are not committed.

## Current status

The repository contains the full book architecture and first working drafts of
the five-chapter execution-and-impact track. These are meant to be deepened
progressively with derivations, empirical examples, exercises, and paper
reproductions.
