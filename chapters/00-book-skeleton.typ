#let index-navy = rgb("183153")
#let index-blue = rgb("2463a5")
#let index-gray = rgb("5e6875")
#let index-border = rgb("d9e0e7")
#let index-fill = rgb("f8fafc")
#let index-status-fill = rgb("fff7df")
#let index-status-text = rgb("8a5a00")

#let roadmap-part(title, purpose) = [
  #v(10pt)
  #heading(level: 2, numbering: none, outlined: false)[#title]
  #text(size: 9.5pt, fill: index-gray)[#purpose]
  #v(6pt)
]

#let roadmap-entry(
  number,
  title,
  purpose,
  subtopics,
  target: none,
  status: [Planned],
) = [
  #block(
    width: 100%,
    inset: 9pt,
    radius: 3pt,
    fill: index-fill,
    stroke: 0.5pt + index-border,
    breakable: false,
  )[
    #let displayed-title = if target == none {
      title
    } else {
      link(target)[#title]
    }
    #grid(
      columns: (26pt, 1fr, auto),
      column-gutter: 7pt,
      align: (center + horizon, left + horizon, right + horizon),
      box(
        width: 22pt,
        height: 22pt,
        radius: 11pt,
        fill: index-blue,
        align(center + horizon, text(size: 8.5pt, weight: "bold", fill: white)[#number]),
      ),
      text(size: 11pt, weight: "bold", fill: index-navy)[#displayed-title],
      box(
        inset: (x: 6pt, y: 2pt),
        radius: 8pt,
        fill: index-status-fill,
      )[
        #text(size: 7.5pt, weight: "bold", fill: index-status-text)[#status]
      ],
    )
    #v(4pt)
    #text(size: 9.2pt)[#purpose]
    #v(3pt)
    #text(size: 8.6pt, fill: index-gray)[
      *Subtopics.* #subtopics
    ]
  ]
  #v(6pt)
]

This is the working architecture of the book. It is intentionally more
detailed than a conventional table of contents: it records the question each
chapter should answer and the subjects that belong there before prose is
written. A linked title opens material already in the manuscript. Entries
marked *Source draft* point to an early combined chapter that will later be
split and rewritten to match the approved structure.

#roadmap-part(
  [Part I - Understanding the execution problem],
  [The reader first learns what an execution algorithm is trying to accomplish, how a market absorbs orders, and what it means to say that an execution was expensive.],
)

#roadmap-entry(
  1,
  [The Execution Problem],
  [Frames execution as a decision problem in which inventory must be traded while prices, liquidity, and information continue to change.],
  [Parent and child orders; inventory and trading rate; price risk; market impact; opportunity cost; alpha decay; static schedules and feedback policies; objectives, constraints, and benchmarks; prediction, estimation, and control.],
  target: <ch-control-lens>,
  status: [Working draft],
)

#roadmap-entry(
  2,
  [How Markets Absorb Orders],
  [Builds an economic picture of the trading venue before reducing liquidity to a handful of model inputs.],
  [The bid, ask, spread, and depth; market and limit orders; price-time priority; queue position; order flow; adverse selection; hidden liquidity; cancellations; replenishment and resilience; fragmentation; dark pools; auctions; clock time, event time, and volume time.],
  target: <ch-microstructure>,
  status: [Working draft],
)

#roadmap-entry(
  3,
  [What Does an Execution Cost?],
  [Defines the outcomes that execution research tries to explain and shows why the benchmark determines the economic question.],
  [Arrival-price implementation shortfall; VWAP, TWAP, close, and interval benchmarks; spread cost; timing risk; impact; opportunity cost; markouts; partial fills and unfinished orders; realized versus expected cost; cost decomposition; counterfactual interpretation; transaction-cost analysis.],
  target: <ch-tca>,
  status: [Working draft],
)

#roadmap-part(
  [Part II - Learning from execution data],
  [This part develops the research judgment needed to turn market observations into defensible measurements, models, and forecasts.],
)

#roadmap-entry(
  4,
  [Statistical Modeling as a Research Process],
  [Explains how to move from an observed market phenomenon to a model that can support an explanation, forecast, or decision.],
  [Research-question formation; the phenomenon, population, observational unit, target, and estimand; data-generating stories; prediction, explanation, causal estimation, and control; information available at decision time; data contracts; noisy labels; feature mechanisms and invariances; validation design; model ladders; bias, variance, and irreducible noise; learning curves; residual analysis; uncertainty; extrapolation; distribution shift; decision-aware evaluation; research logs and synthetic experiments.],
  target: <ch-modeling-research>,
  status: [Working draft],
)

#roadmap-entry(
  5,
  [Execution Data: From Market Events to Research Tables],
  [Shows how orders, fills, quotes, and trades become a trustworthy research dataset without losing their timing or economic meaning.],
  [Order, fill, quote, trade, and depth records; parent-order reconstruction; event alignment and quote matching; timestamps and clock synchronization; sampling frequency; stale observations; missingness; cancellations and incomplete orders; censoring; corporate actions; futures rolls and symbol changes; live versus corrected reference data; leakage-safe joins; reproducible research tables.],
)

#roadmap-entry(
  6,
  [The Empirical Shape of Market Impact],
  [Describes the regularities seen in execution data before imposing a particular functional form or causal interpretation.],
  [Temporary, permanent, and transient impact; signed volume; order size, participation, and duration; concavity and square-root behavior; impact trajectories during an order; post-trade decay; spread, volatility, depth, and liquidity dependence; time-of-day effects; market regimes; cross-sectional variation; differences among equities, futures, options, and less-liquid products.],
  target: <ch-impact>,
  status: [Source draft],
)

#roadmap-entry(
  7,
  [Estimating Market Impact],
  [Develops statistical methods for estimating impact while being explicit about selection, endogeneity, uncertainty, and model use.],
  [Parametric and nonparametric specifications; log-log models; nonlinear and constrained regression; heteroskedasticity and heavy tails; hierarchical shrinkage; interactions and segmentation; metaorder reconstruction; endogenous participation and duration; latent urgency; confounding and selection; measurement error; causal designs; uncertainty intervals; stability; residual diagnostics; policy sensitivity.],
  target: <ch-impact>,
  status: [Source draft],
)

#roadmap-entry(
  8,
  [Modeling the State of Liquidity],
  [Treats volume, spread, volatility, depth, and order flow as uncertain state variables that must be forecast jointly with their uncertainty.],
  [Intraday and remaining-day volume; spread and depth dynamics; realized and forecast volatility; imbalance and order flow; trade and order-arrival processes; state-space and latent-liquidity models; regime switching; trees, boosting, neural networks, and Gaussian processes; probabilistic forecasts; calibration; scenario generation; drift monitoring; forecast value for control.],
)

#roadmap-part(
  [Part III - From estimated models to execution policies],
  [The emphasis now moves from describing costs and market state to choosing actions and understanding why an optimal policy behaves as it does.],
)

#roadmap-entry(
  9,
  [Classical Optimal Liquidation],
  [Derives the basic cost-risk trade-off and uses it to explain the shape of an optimal liquidation schedule.],
  [Discrete and continuous inventory dynamics; temporary impact; price risk; Bertsimas-Lo; Almgren-Chriss; expected cost and variance; the execution frontier; risk aversion and urgency; boundary conditions; closed-form trajectories; calibration; units and limiting cases; when the classical assumptions fail.],
  target: <ch-optimal-execution>,
  status: [Source draft],
)

#roadmap-entry(
  10,
  [Volume Time, VWAP, and Participation Strategies],
  [Connects optimal liquidation to the schedules and constraints used by practical execution algorithms.],
  [Calendar time and volume time; TWAP and VWAP schedules; constant and time-varying POV; uncertain future volume; participation caps and floors; completion constraints; catch-up logic near deadlines; benchmark-aware control; realized versus intended participation; interaction among impact, volume forecasts, and alpha decay.],
  target: <ch-optimal-execution>,
  status: [Source draft],
)

#roadmap-entry(
  11,
  [Transient Impact and Market Resilience],
  [Introduces impact with memory and studies how liquidity recovery changes the value of waiting and the shape of a schedule.],
  [Propagator states; exponential and power-law kernels; resilience; path-dependent execution cost; child-order spacing; post-trade decay; kernel estimation; mechanical decay versus informational reversion; price manipulation; no-dynamic-arbitrage restrictions; optimal schedules under transient impact.],
)

#roadmap-entry(
  12,
  [Adaptive Execution],
  [Explains how a policy should respond when forecasts, market conditions, or beliefs change during an order.],
  [Feedback policies; state and belief updates; receding-horizon control; model-predictive control; Bayesian learning; uncertain parameters; robust and distributionally robust optimization; dual control; changing volume, volatility, spread, and alpha; stability; excessive switching; hysteresis; guardrails; emergency completion; value of adaptation.],
)

#roadmap-entry(
  13,
  [Passive Execution and Queue Control],
  [Values a resting order as a contingent execution whose apparent spread saving must be balanced against non-fill and adverse-selection risk.],
  [Posting versus crossing; queue priority and position; fill probability; queue depletion; cancellation and reposting; conditional markouts; adverse selection after fills; survival and hazard models; marked point processes; non-fill and deadline risk; impulse control; aggressiveness selection.],
)

#roadmap-entry(
  14,
  [Routing, Dark Liquidity, and Auctions],
  [Extends the action from trading speed to venue, order type, and trading mechanism.],
  [Fragmented liquidity; fees and rebates; latency; fill quality; venue-specific toxicity; dark pools and conditional liquidity; information leakage; price protection; contextual bandits; constrained routing; opening and closing auctions; imbalance information; crossing opportunities; joint control of schedule, aggressiveness, and venue.],
)

#roadmap-entry(
  15,
  [Futures Execution],
  [Treats contract choice, roll dynamics, and economic exposure as part of the execution decision rather than as data-cleaning details.],
  [Contract multipliers, tick sizes, and risk-equivalent quantity; margin versus exposure; contract liquidity measures; front and deferred contracts; liquidity migration; roll timing; basis and calendar spreads; outright versus spread execution; continuous-series distortions; session boundaries; expiry effects; roll-aware impact models; two-expiry control; underestimation near rolls.],
)

#roadmap-part(
  [Part IV - Determining whether a policy works],
  [A policy must be evaluated as a policy. These chapters separate genuine improvement from changes in order mix, market conditions, or the algorithm's own selection behavior.],
)

#roadmap-entry(
  16,
  [Experiments and Policy Evaluation],
  [Develops credible ways to decide whether a new execution policy improves outcomes and for which orders it improves them.],
  [Randomized execution experiments; A/B tests and switchbacks; stratification; interference; selection into algorithms; completion bias and censoring; common support; counterfactual policy values; inverse-propensity weighting; doubly robust estimation; heterogeneous effects; uncertainty for policy differences; economic versus statistical significance; staged rollout and monitoring.],
)

#roadmap-entry(
  17,
  [Reinforcement Learning for Execution],
  [Examines when execution should be treated as a learned sequential policy and why offline data make that problem difficult.],
  [MDPs and partially observed MDPs; state, action, transition, and reward design; inventory and deadline constraints; simulator construction; simulator bias; behavior policies; offline reinforcement learning; off-policy evaluation; distribution shift; conservative policy improvement; safe exploration; policy guardrails; comparison with model-predictive control.],
)

#roadmap-part(
  [Part V - Other trading problems through the control lens],
  [The same language of state, belief, action, cost, and feedback is applied to other central problems in algorithmic trading.],
)

#roadmap-entry(
  18,
  [Market Making and Inventory Control],
  [Studies bid and ask decisions when the trader earns spread but accumulates inventory and adverse-selection risk.],
  [Reservation prices; Avellaneda-Stoikov; inventory penalties; quote skew; order-arrival calibration; fill probabilities; adverse selection; queue-aware quoting; volatility and regime changes; latency; multi-asset inventory; practical limits of stylized models.],
)

#roadmap-entry(
  19,
  [Multi-Asset and Portfolio Execution],
  [Coordinates the liquidation of related positions when risk, liquidity, and impact are coupled across instruments.],
  [Basket execution; covariance and factor risk; factor liquidity; cross-impact; coupled schedules; hedging during execution; index rebalances; portfolio transitions; manipulation-free cross-impact; parameter estimation; robustness to unstable correlations and liquidity.],
)

#roadmap-entry(
  20,
  [Portfolio Choice with Trading Frictions],
  [Connects forecasts and desired positions to the costly, gradual process of moving an actual portfolio.],
  [Signals and expected returns; turnover; transaction costs; signal decay; dynamic mean-variance control; no-trade regions; impulse and singular control; model-predictive rebalancing; robust portfolios; execution-aware portfolio construction; the boundary between portfolio and execution decisions.],
)

#roadmap-entry(
  21,
  [Optimal Stopping and Statistical Arbitrage],
  [Develops entry, exit, and abandonment decisions when waiting changes both information and opportunity.],
  [Stopping times; continuation value; Snell envelopes and dynamic programming; free-boundary intuition; mean-reverting spreads; pairs and relative-value models; regime uncertainty; sequential testing; transaction costs; delayed execution; signal decay; when a statistically attractive trade is not economically worth taking.],
)

#roadmap-entry(
  22,
  [Options Hedging under Frictions],
  [Studies hedging when rebalancing is discrete, costly, and itself moves the market.],
  [Delta and gamma exposure; discrete hedging error; stochastic volatility; transaction costs; impact-aware rebalancing; inventory constraints; no-trade regions; volatility and jump risk; joint hedge and execution decisions; liquidity differences across strikes and maturities.],
)

#roadmap-entry(
  23,
  [Strategic Traders and Stochastic Games],
  [Explains when market response depends on the beliefs and actions of other strategic participants, not only on exogenous noise.],
  [Signaling through order flow; strategic liquidation; predatory trading; information leakage; equilibrium impact; best responses; stochastic differential games; mean-field games; competition among execution algorithms; mechanism design; limits of single-agent control models.],
)

#roadmap-part(
  [Part VI - Conducting execution research],
  [The final part brings the statistical, economic, and control ideas together in complete research workflows.],
)

#roadmap-entry(
  24,
  [From Research Question to Production Model],
  [Follows a model from its first research question through deployment, monitoring, and communication with traders and engineers.],
  [Problem statements and decision context; simple benchmarks; exploratory analysis; preregistered validation; reproducible experiments; feature and model versioning; leakage controls; stress and sensitivity tests; translating estimates into policy behavior; model-engine interfaces; monitoring and drift; retraining; governance; rollback; communicating uncertainty.],
)

#roadmap-entry(
  25,
  [Worked Research Studies],
  [Presents complete investigations so the reader can see how the book's principles interact when the data and conclusions are imperfect.],
  [Estimating an equity impact curve; diagnosing time-of-day effects; estimating transient-impact decay; designing and evaluating adaptive POV; modeling passive fills and adverse selection; futures execution around a roll; reproducing Almgren-Chriss and a propagator model; comparing a learned policy with a controlled baseline.],
)

#v(6pt)
#text(size: 9pt, fill: index-gray)[
  *Appendices.* Probability and conditional expectation; martingales and
  stopping times; Brownian motion, Itô calculus, and jump processes; dynamic
  programming, HJB equations, and verification; convex optimization, KKT
  conditions, and numerical control; statistical inference, regularization,
  and causal estimation; time-series and event-data methods; notation, units,
  and dimensional analysis.
]
