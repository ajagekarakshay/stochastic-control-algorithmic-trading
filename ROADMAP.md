# Book roadmap

The authoritative, detailed chapter skeleton is part of the Typst manuscript
in `chapters/00-book-skeleton.typ`. It records each chapter's purpose,
subtopics, writing status, and links to material that already exists.

The book follows one recurring loop:

> observe market state -> estimate dynamics and costs -> choose an action ->
> observe fills and market response -> update beliefs and policy.

## Part I - Understanding the execution problem

1. **The Execution Problem** - Parent and child orders, inventory, trading
   rate, price risk, impact, opportunity cost, alpha decay, objectives,
   constraints, benchmarks, and feedback policies.
2. **How Markets Absorb Orders** - Limit-order books, spread, depth, queues,
   order flow, adverse selection, hidden liquidity, resilience, fragmentation,
   auctions, and market clocks.
3. **What Does an Execution Cost?** - Arrival shortfall, VWAP, TWAP, close and
   interval benchmarks, spread cost, timing risk, impact, markouts, partial
   fills, opportunity cost, counterfactuals, and TCA.

## Part II - Learning from execution data

4. **Statistical Modeling as a Research Process** - Research questions,
   estimands, data-generating stories, prediction versus causality and control,
   data contracts, label noise, features, validation, bias and variance,
   residuals, uncertainty, distribution shift, and decision-aware evaluation.
5. **Execution Data: From Market Events to Research Tables** - Orders, fills,
   quotes, trades, depth, event alignment, timestamps, parent-order
   reconstruction, missingness, censoring, corrections, rolls, and
   leakage-safe joins.
6. **The Empirical Shape of Market Impact** - Temporary, permanent, and
   transient impact, size, participation, duration, concavity, square-root
   behavior, impact paths, decay, liquidity dependence, and regimes.
7. **Estimating Market Impact** - Parametric and nonparametric models,
   nonlinear estimation, heteroskedasticity, hierarchical shrinkage,
   endogeneity, confounding, selection, uncertainty, diagnostics, and policy
   sensitivity.
8. **Modeling the State of Liquidity** - Volume, spread, volatility, depth,
   imbalance, point processes, latent state, regimes, probabilistic forecasts,
   calibration, scenarios, and drift.

## Part III - From estimated models to execution policies

9. **Classical Optimal Liquidation** - Inventory dynamics, Bertsimas-Lo,
   Almgren-Chriss, temporary impact, price risk, the execution frontier,
   urgency, calibration, and limiting cases.
10. **Volume Time, VWAP, and Participation Strategies** - Volume time, TWAP,
    VWAP, POV, uncertain volume, participation constraints, completion,
    catch-up behavior, and alpha decay.
11. **Transient Impact and Market Resilience** - Propagator models, decay
    kernels, path dependence, resilience, kernel estimation, child-order
    spacing, manipulation, and optimal schedules.
12. **Adaptive Execution** - Feedback, belief updates, Bayesian learning,
    model-predictive control, robustness, dual control, stability, hysteresis,
    guardrails, and the value of adaptation.
13. **Passive Execution and Queue Control** - Posting versus crossing, queue
    position, fills, cancellations, adverse selection, markouts, hazard models,
    non-fill risk, and impulse control.
14. **Routing, Dark Liquidity, and Auctions** - Venues, fees, rebates, latency,
    toxicity, dark pools, leakage, bandits, routing constraints, auctions, and
    joint schedule and venue control.
15. **Futures Execution** - Exposure-aware size, contract liquidity, rolls,
    basis risk, calendar spreads, continuous-series distortions, sessions,
    expiry effects, roll-aware impact, and contract choice.

## Part IV - Determining whether a policy works

16. **Experiments and Policy Evaluation** - Randomization, A/B tests,
    switchbacks, stratification, interference, completion bias, overlap,
    counterfactual policy values, doubly robust methods, uncertainty, and
    rollout.
17. **Reinforcement Learning for Execution** - MDPs and POMDPs, state and
    reward design, simulators, offline RL, off-policy evaluation, distribution
    shift, conservative improvement, and safety.

## Part V - Other trading problems through the control lens

18. **Market Making and Inventory Control** - Reservation prices, quote skew,
    Avellaneda-Stoikov, inventory risk, order arrivals, fills, adverse
    selection, queues, and multi-asset inventory.
19. **Multi-Asset and Portfolio Execution** - Basket risk, covariance, factors,
    factor liquidity, cross-impact, coupled schedules, hedging, rebalances,
    transitions, and manipulation-free models.
20. **Portfolio Choice with Trading Frictions** - Signals, turnover,
    transaction costs, decay, no-trade regions, dynamic rebalancing, robust
    portfolios, and execution-aware construction.
21. **Optimal Stopping and Statistical Arbitrage** - Continuation value,
    stopping times, free boundaries, mean reversion, regimes, sequential
    testing, transaction costs, delayed execution, and signal decay.
22. **Options Hedging under Frictions** - Delta and gamma risk, discrete
    hedging, stochastic volatility, transaction costs, impact-aware
    rebalancing, no-trade regions, jumps, and joint hedge-execution decisions.
23. **Strategic Traders and Stochastic Games** - Signaling, strategic
    liquidation, predatory trading, equilibrium impact, best responses,
    stochastic and mean-field games, and mechanism design.

## Part VI - Conducting execution research

24. **From Research Question to Production Model** - Baselines, exploratory
    analysis, validation, reproducibility, versioning, leakage controls, stress
    tests, policy translation, model-engine interfaces, monitoring,
    governance, rollback, and communication.
25. **Worked Research Studies** - Equity impact, time-of-day effects,
    transient decay, adaptive POV, passive fills, futures rolls,
    Almgren-Chriss, propagator models, and learned-policy evaluation.

## Appendices

A. Probability and conditional expectation
B. Martingales, stopping times, and change of measure
C. Brownian motion, Itô calculus, and jump processes
D. Dynamic programming, HJB equations, and verification
E. Convex optimization, KKT conditions, and numerical control
F. Statistical inference, regularization, and causal estimation
G. Time-series and event-data methods
H. Notation, units, and dimensional analysis

## Writing order

The main book is developed one chapter at a time. Part I comes first:
Chapter 1, then Chapter 2, then Chapter 3. Each chapter is discussed against
the skeleton before its working draft is rewritten.
