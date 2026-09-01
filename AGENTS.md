# Book-writing guidance

## Purpose

This repository is a book, not a collection of disconnected notes. Every
chapter should connect a market phenomenon, a statistical model, and a control
decision.

## Exposition order

For each important concept, use this order whenever possible:

1. economic or microstructure intuition;
2. precise probabilistic assumptions and notation;
3. derivation;
4. empirical identification and diagnostics;
5. control implication;
6. interview checks and exercises.

Do not present an estimator as if its output were a structural market-impact
parameter without discussing selection, confounding, censoring, and regime
dependence. Distinguish prediction, causal estimation, and control.

## Mathematical standard

- State filtrations, conditioning information, units, and timing conventions.
- Separate observed variables, latent state, actions, disturbances, and costs.
- Mark whether a result is a theorem, modeling assumption, approximation, or
  empirical regularity.
- Test limiting cases and dimensions after major derivations.
- Use consistent notation from `notation.typ`.

## Empirical standard

- Respect event time and prevent look-ahead leakage.
- Use order-level or parent-order splits when observations share an execution.
- Report uncertainty and out-of-sample stability, not only fit metrics.
- Diagnose residuals by size, participation, spread, volatility, liquidity,
  side, time of day, symbol, and regime.
- Explain what model error does to the resulting policy.

## Repository workflow

- Keep each chapter in `chapters/` and include it from `main.typ`.
- Add every cited source to `references.bib`.
- Keep generated PDFs under `build/`; do not commit them.
- Build the full book before committing changes.

## Interview Q&A companion

- Treat `interview-qa/` as a second, cumulative Typst book.
- Chapters 01-05 are the fixed baseline adapted from the five historical
  Execution Interview Drills. Do not overwrite, renumber, or regenerate them.
- Determine each new chapter number from the largest existing numbered source;
  the first newly generated daily chapter is Chapter 06.
- Present all questions first and all detailed answers afterward.
- Give every question a link to its answer and every answer a link back.
- Add one `interview-qa/chapters/NN-*.typ` source, one matching standalone
  `interview-qa/chapter-NN.typ`, and include it from `interview-qa/main.typ`.
- Compile the cumulative PDF and the new standalone PDF, visually inspect both,
  and verify internal PDF link annotations before committing.
