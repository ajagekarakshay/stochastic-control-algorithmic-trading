#import "../style.typ": intuition, interview, research, takeaway, definition

= Market Microstructure as the Controlled System <ch-microstructure>

An execution model controls neither an abstract Brownian motion nor a daily
return. It submits orders into a trading mechanism. The mechanism determines
priority, fills, spread capture, information leakage, and how quickly liquidity
recovers. Microstructure supplies the causal stories behind the state variables
and cost functions of Chapter 1.

== The limit-order book

At time $t$, let the best bid and ask be $b_t$ and $a_t$. Define

$
  m_t = (a_t+b_t)/2, quad s_t = a_t-b_t.
$

A limit order supplies liquidity at a specified price; a marketable order
demands liquidity and trades against resting orders. Price-time priority usually
means better prices execute first and, at the same price, earlier orders execute
first. Amendments may lose queue priority.

The displayed book is a schedule of marginal liquidity, not a promise that all
depth remains available. A market order of size $q$ walks the ask until its
quantity is filled. If $A_t(p)$ is cumulative displayed ask depth through price
$p$, the mechanical book cost relative to the mid is

$
  C_t(q) = integral_0^q (P_t^"ask"(x)-m_t) dif x,
$

where $P_t^"ask"(x)$ is the marginal ask price at cumulative quantity $x$.
This is an *instantaneous* snapshot cost. It is not the same as the realized
impact of an algorithm spread through time.

#intuition[
  Depth is a stock; volume is a flow. A book can look thin but replenish rapidly,
  or look deep and vanish when touched. Execution capacity depends on both the
  visible stock and the dynamics of replenishment.
]

== Spread is compensation, state, and cost

The bid–ask spread compensates liquidity suppliers for several components:

- order-processing and venue costs;
- inventory risk while holding an unwanted position;
- adverse selection against better-informed or faster traders; and
- option value granted to a resting order while the market moves.

For an aggressive buy at the ask, the immediate mid-relative cost begins near
$s_t/2$, before fees and impact. A passive buy may appear to earn $s_t/2$, but
the fill is selected: it is more likely when sell pressure arrives or the fair
price is moving down. Spread capture must therefore be evaluated after a
suitable markout horizon and with non-fills included.

#definition("effective and realized spread")[
  For a trade at price $P_t$ with sign $epsilon_t in {-1,+1}$, the effective
  spread is $2 epsilon_t(P_t-m_t)$. A realized-spread measure replaces the
  contemporaneous mid with a future mid $m_(t+tau)$:
  $2 epsilon_t(P_t-m_(t+tau))$. Their difference is a markout or adverse-
  selection component, conditional on the chosen horizon $tau$.
]

== Order flow and price formation

Trade signs are persistent: large investors split orders, and correlated agents
may act on related information. Yet returns are much less predictable than raw
sign persistence suggests. Liquidity must adapt. The market may provide less
depth, widen spreads, or adjust prices more strongly when order flow is
surprising; predictable flow can have smaller marginal response.

A simple signed-flow model is

$
  Delta m_(t+1) = beta epsilon_t f(q_t) + gamma^T z_t + xi_(t+1),
$

where $z_t$ captures prior flow and liquidity. Interpreting $beta$ as “the
impact of a trade” is dangerous unless trade initiation and market state are
handled. The trade may convey information, remove a stale quote, mechanically
deplete depth, or be caused by the same news that moves price.

The propagator representation makes path dependence explicit:

$
  m_t = m_0 + sum_(j < t) G(t-j) f(q_j) epsilon_j + M_t,
$

where $G(l)$ is a decay kernel and $M_t$ is exogenous price innovation. A slowly
decaying $G$ means past flow remains part of the state. The model connects
persistent flow, transient impact, and market resilience @bouchaud2004.

#takeaway[
  If impact decays, remaining inventory is not a sufficient control state.
  The algorithm also needs a summary of its outstanding impact. Trading now
  changes both inventory and the cost of future trades.
]

== Three meanings of “market impact”

The phrase is used for distinct objects:

1. *Mechanical response:* the price change caused by consuming or inducing a
   change in available liquidity, holding information fixed.
2. *Informational response:* prices move because the order reveals information
   or shares a cause with future returns.
3. *Reduced-form conditional cost:* the empirical slippage of executions with
   given characteristics under an observed policy.

All three matter economically. Only the first is a clean intervention effect,
and even it depends on the intervention definition and horizon. A production
cost model often estimates the third. It can be useful without supporting a
structural claim, provided policy changes do not move too far outside the data.

== Temporary, permanent, and transient response

A traditional execution model separates temporary impact, paid by the current
child order, from permanent impact, which shifts all subsequent prices. Real
markets more often show a response that builds during a metaorder and partially
decays afterward. This motivates a transient state

$
  d r_t = -rho r_t dif t + kappa v_t dif t,
  quad P_t = m_t^0 + r_t + h(v_t),
$

where $rho$ is resilience and $m_t^0$ is an unaffected price. The solution

$
  r_t = r_0 e^(-rho t) + kappa integral_0^t e^(-rho(t-s)) v_s dif s
$

shows why two schedules with the same total quantity can have different costs:
their child orders overlap differently through the decay kernel.

The “unaffected price” is a modeling counterfactual, not an observable tape
field. Estimating it is an identification problem.

== Liquidity state and resilience

Useful liquidity measurements operate at several horizons:

#table(
  columns: (1fr, 1.25fr, 1.55fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Object*], [*Examples*], [*Control relevance*],
  [Price], [spread, mid, microprice], [aggression and benchmark cost],
  [Book stock], [depth, slope, imbalance], [near-term capacity and fill risk],
  [Order-flow dynamics], [trades, adds, cancels, signed imbalance], [adverse selection and depletion],
  [Resilience], [refill time, spread recovery, impact decay], [spacing and pause decisions],
  [Market activity], [volume rate, trade count, event intensity], [participation and clock speed],
)

The microprice is one compressed top-of-book signal. If best-bid size is $Q^b$
and best-ask size is $Q^a$, a common convention is

$
  p^"micro" = (a Q^b + b Q^a)/(Q^a+Q^b).
$

When bid depth dominates, the microprice lies closer to the ask. This is an
empirical predictor, not a no-arbitrage fair value; queue cancellations, hidden
liquidity, and deeper levels can reverse its meaning.

== Clock choice

Calendar time is not the only clock. Trading intensity varies sharply through
the day, so a minute near the close may contain far more events and volume than
a minute at lunch.

- *Calendar time* is required for deadlines, alpha half-life, and latency.
- *Event time* advances with trades or book events and is useful for local
  microstructure dynamics.
- *Volume time* advances by market volume and often makes participation policies
  and intraday variance more homogeneous.

If cumulative expected volume is

$
  tau(t) = integral_0^t E[d V_s]/E[V_T],
$

then a uniform schedule in $tau$ is a VWAP-style schedule in calendar time.
Volume time helps remove seasonality but does not eliminate stochastic volume or
selection: realized volume is not known at the start.

#research[
  Never use completed-day volume to normalize a feature used intraday unless it
  is explicitly a forecast or the task is retrospective measurement. Realized
  ADV-like denominators can leak future activity and make backtests too stable.
]

== Intraday seasonality and the close

Spreads, depth, volatility, volume, and participant composition vary by time of
day. Lower observed slippage near the close need not mean that time alone causes
lower impact. Possible mechanisms include:

- greater volume and faster replenishment;
- different order mix and benchmark incentives;
- more predictable one-sided flows around the auction;
- selection of which orders remain or begin late;
- shorter markout horizons or benchmark construction; and
- conditioning on realized rather than forecast volume.

A time-of-day coefficient is a useful reduced-form adjustment, but research
should test which state variable it proxies. Otherwise a regime change in the
close can break the coefficient without warning.

== Fragmentation, dark liquidity, and auctions

In a fragmented market, the action includes venue. Displayed prices may be
similar while fill probability, queue length, fee/rebate, latency, odd-lot
treatment, adverse selection, and hidden liquidity differ. A router faces a
joint allocation and timing problem with censored feedback: for unchosen venues,
the counterfactual fill is not observed.

Dark venues can reduce displayed information leakage and sometimes provide
price improvement, but execution is uncertain and fills may be adversely
selected. Closing auctions concentrate liquidity and eliminate continuous-book
timing within the match, yet imbalance risk and benchmark incentives create a
different control problem. An optimal policy must value optionality: waiting for
uncertain passive or dark fills consumes time that could have been used to
complete elsewhere.

== From mechanism to model feature

A disciplined feature story has four links:

1. mechanism: why the variable should affect price, fill, or cost;
2. timing: when it becomes observable relative to the decision;
3. horizon: how long its information should persist;
4. action: which control choice should change.

For example, book imbalance may predict the next mid move over tens of events.
It could justify a brief change in aggression, but it is unlikely to determine a
two-hour schedule without an aggregation and persistence model.

== Interview checks

#interview[
  *A passive fill earns half the spread. Why can its expected markout still be
  negative?* Explain selection into fills, adverse flow, queue position, and why
  non-fills must be valued.
]

#interview[
  *Why might a thin displayed book have low realized impact?* Discuss hidden
  liquidity, fast replenishment, cancellation behavior, child-order spacing,
  and the difference between snapshot depth and flow capacity.
]

#interview[
  *Observed slippage is lower near the close. What would you investigate before
  adding a time-of-day multiplier?* Separate liquidity mechanisms, order
  selection, benchmark effects, denominator leakage, and post-trade horizon.
]

== Exercises

1. Derive $p^"micro"-m$ in terms of spread and normalized top-level imbalance.
   Check its sign when bid depth exceeds ask depth.
2. Simulate the resilience state for two schedules with equal quantity: one
   block and ten equally spaced child orders. Compare the area under $v_t r_t$.
3. Propose a leakage-safe estimate of the intraday volume curve for a symbol with
   sparse history. Explain how hierarchical pooling or clustering would help.
4. Define a state and action space for a two-venue router with one lit and one
   dark venue. Identify the censored outcomes.
