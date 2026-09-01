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

The first five chapters preserve the five completed historical drills:

1. participation, impact, and causal interpretation;
2. time of day, liquidity, and confounding;
3. transient impact, resilience, and schedule shape;
4. passive versus aggressive execution and queue risk; and
5. adaptive versus static POV and policy evaluation.

Build the cumulative Q&A book and all standalone chapters with:

```bash
make qa
make qa-chapters
```

To build one chapter, use a target such as `make qa-chapter-03`.

Generated PDFs remain under `build/` and are not committed. New daily material
must begin at Chapter 6 and continue from the largest chapter number already in
the repository.

## Current status

The repository contains the full book architecture and first working drafts of
the five-chapter execution-and-impact track. These are meant to be deepened
progressively with derivations, empirical examples, exercises, and paper
reproductions.
