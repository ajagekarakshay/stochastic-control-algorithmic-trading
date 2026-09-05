# Book-writing guidance

## Purpose

This repository is a book, not a collection of disconnected notes. Every
chapter should connect a market phenomenon, a statistical model, and a control
decision.

The authoritative 25-chapter architecture is maintained in
`chapters/00-book-skeleton.typ`. Discuss and agree on a chapter's purpose and
subtopics before replacing its skeleton with prose. Develop the main book one
chapter at a time; do not generate several planned chapters in a single pass.

## Writing voice

- Write for a mathematically mature human reader, not for another AI or as an
  instruction manual for one.
- Prefer connected explanatory prose to compressed lists of declarations.
- Be descriptive without becoming pedantic. Introduce formalism when it makes
  an economic or statistical idea more precise.
- Begin important sections with the market or research problem that motivates
  them. Return to what the result changes for modeling or trading.
- Avoid formulaic transitions, repeated summary boxes, canned “key takeaway”
  language, and claims of importance that have not been demonstrated.
- Treat existing main-book chapters as working drafts until they have been
  reviewed against the approved skeleton.

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
- Keep the detailed chapter index in `chapters/00-book-skeleton.typ` aligned
  with `ROADMAP.md`. Link entries only to material that exists.
- Give every main-book chapter a stable heading label, add it to the clickable
  chapter index in `main.typ`, and maintain the Previous / Index / Next chain.
- Add every cited source to `references.bib`.
- Keep generated PDFs under the root-level `output/pdf/` directory.
- Build the main book and all standalone Q&A chapters, and commit every
  generated PDF together with its source. Do not generate or commit a
  cumulative Q&A PDF.

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
- Give the chapter heading a stable `<qa-chNN>` label. Update the clickable
  chapter index and the Previous / Index / Next chain in
  `interview-qa/main.typ`; the former last chapter must point forward to the
  new chapter, and the new last chapter must point back.
- Run `make all` so the main book and every standalone Q&A chapter are
  regenerated under `output/pdf/`. Visually inspect the main book and the new
  standalone PDF, verify internal PDF link annotations, and commit all changed
  PDFs together with the Typst sources. Do not place a cumulative Q&A PDF in
  `output/pdf/`.
