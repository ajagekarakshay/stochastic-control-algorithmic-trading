#import "../style.typ": intuition

#heading(level: 1, numbering: none)[Preface] <preface>

Algorithmic trading is often taught as a collection of models: one model for
impact, another for volume, a dynamic program for liquidation, a classifier for
fills, and perhaps a reinforcement-learning agent at the end. This book takes a
different view. These are components of one feedback system.

The trader observes an incomplete and noisy state of the market, estimates how
prices and liquidity may evolve, chooses actions that change both inventory and
future trading conditions, and learns from fills and market response. Statistics
describes what can be inferred; stochastic modeling describes how uncertainty
evolves; control theory describes how beliefs should become decisions.

#intuition[
  The unifying question is not “Which algorithm should I use?” It is: *What is
  the state, what can I observe, what can I influence, what does my action reveal
  or disturb, and which cost matters for the decision?*
]

The opening five chapters form a self-contained execution-and-impact track.
They emphasize the questions that arise in execution research and market-impact
interviews: why costs increase with urgency, what an impact coefficient actually
identifies, why realized slippage is endogenous, when a smooth schedule is
optimal, and how alpha decay, liquidity forecasts, and constraints change the
answer.

The intended rhythm is intuition → assumptions → derivation → empirical test →
control implication. “Laws” of market impact are treated as conditional
empirical regularities rather than universal constants. Machine-learning models
are judged not only by predictive accuracy but by calibration, stability, and
the decisions they induce.

== How to use the book

- For an execution interview, read Chapters 1–5 in order and solve every
  interview check without looking back.
- For research practice, reproduce the empirical diagnostics and ask what
  selection mechanism generated the sample.
- For theory, re-derive results after changing one assumption at a time.
- For production modeling, trace the units and information set of every feature
  before considering model class.

This is a working manuscript. The first priority is conceptual and mathematical
depth in execution and market impact; later parts expand the same framework to
order placement, routing, market making, portfolio execution, and learning.
