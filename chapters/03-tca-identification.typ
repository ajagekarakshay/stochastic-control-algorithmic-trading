#import "../style.typ": intuition, interview, research, takeaway, definition

= Transaction Costs and Statistical Identification <ch-tca>

Transaction-cost analysis is where market data becomes evidence. It is also
where seemingly minor definitions can reverse conclusions. A benchmark chooses
a counterfactual; a sampling rule chooses a population; a standard error chooses
which dependence is acknowledged. Before fitting a sophisticated model, we must
make these choices explicit.

== The parent order is the unit of intent

Let a parent buy order have requested quantity $Q$, fills $(q_i,p_i,t_i)$,
completed quantity $Q_f=sum_i q_i$, and average execution price

$
  overline(P) = (sum_i q_i p_i)/Q_f.
$

Child fills from the same parent are not independent research observations. They
share urgency, benchmark, signal, market path, and adaptive policy. Treating
each fill as independent inflates sample size and understates uncertainty.

Use a side variable $epsilon=+1$ for buys and $-1$ for sells. A side-adjusted
cost relative to benchmark $B$ is

$
  C_B = 10^4 epsilon (overline(P)-B)/B " bps".
$

Positive values then represent cost on both sides. State whether fees, rebates,
commissions, taxes, and financing are included.

== Benchmarks answer different questions

#table(
  columns: (0.8fr, 1.35fr, 1.8fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Benchmark*], [*Question*], [*Main vulnerability*],
  [Decision price], [Cost from investment decision onward], [Decision timestamp and pre-routing delay],
  [Arrival price], [Quality after algo receives the order], [Pre-existing short-horizon alpha and arrival noise],
  [Interval VWAP], [Performance versus market volume schedule], [Endogenous interval, realized-volume leakage, benchmark gaming],
  [Close], [Performance for close-valued portfolios], [Large exogenous price move before the close],
  [Reversion price], [How much execution-period move persists], [Arbitrary horizon and new information after completion],
)

Arrival-price shortfall is natural for measuring the execution algorithm because
it starts the clock when the algo gains control. It is not a pure impact measure:
the no-trade price could have moved during the execution for informational or
random reasons.

#intuition[
  A benchmark is not a neutral ruler. It specifies the world against which the
  execution is judged. Arrival asks, “What happened after control was handed to
  the algo?” VWAP asks, “Did the schedule beat the market's realized volume-
  weighted path?” These are different objectives, not competing estimates of one
  true cost.
]

== Implementation-shortfall decomposition

Suppose $Q_f <= Q$ shares fill and mark unfilled inventory at price $P_T$. Total
arrival shortfall in dollars for a buy is

$
  "IS" = sum_i q_i(p_i-P_0) + (Q-Q_f)(P_T-P_0) + "explicit costs".
$

It can be decomposed algebraically in many ways. One useful research
decomposition separates:

- spread and explicit-cost component;
- market movement during the schedule;
- price paid relative to contemporaneous mid;
- post-trade reversion or persistent markout; and
- opportunity cost of unfilled quantity.

The decomposition is descriptive unless an unaffected price path is identified.
For example, contemporaneous-mid cost captures local aggression but the mid may
already contain the program's earlier impact.

== The missing counterfactual

For order $i$, define potential cost $Y_i(a)$ under execution policy $a$. The
causal effect of changing from policy $a$ to $a'$ is

$
  tau = E[Y_i(a')-Y_i(a)].
$

Only one potential outcome is observed. A historical comparison estimates
$E[Y|A=a']-E[Y|A=a]$, which equals $tau$ only under assumptions such as
exchangeability after conditioning on pre-treatment state $X$:

$
  (Y(a),Y(a')) perp A | X,
$

together with overlap and consistent treatment definition.

Execution challenges each assumption:

- urgency and alpha affect both chosen strategy and subsequent price;
- policy parameters vary continuously and adapt within the order;
- an algorithm can change which fills and even which completion times exist;
- one order's action may affect another order's outcome; and
- market regimes with one policy may have little overlap with another.

#research[
  Realized participation, duration, completion, and fill count are usually
  outcomes of the policy as well as descriptors of the order. Conditioning on
  them can block part of the effect or introduce collider bias. Prefer intended
  parameters and pre-trade forecasts when defining treatment and controls.
]

== Randomized and quasi-experimental comparisons

Randomized A/B tests are the cleanest design when operationally safe. Randomize
at the parent-order level, preserve allocation logs, and check:

1. treatment assignment occurred before any treatment-dependent action;
2. sample-ratio mismatch and logging failures;
3. pre-treatment balance by side, size, liquidity, urgency, symbol, and time;
4. adherence and crossovers;
5. interference between simultaneous orders; and
6. heterogeneous effects and tail risk, not merely mean cost.

If randomization is unavailable, options include matching, regression
adjustment, inverse-propensity weighting, doubly robust estimation, instruments,
and natural experiments. Each replaces randomization with assumptions. A method
name does not make those assumptions credible.

For binary treatment with propensity $e(X)=P(A=1|X)$, the inverse-weighted
average-treatment estimator is

$
  hat(tau) = 1/n sum_i [A_i Y_i/e(X_i) - (1-A_i)Y_i/(1-e(X_i))].
$

Extreme weights reveal lack of overlap. Trimming changes the target population
and must be reported.

== Dependence and uncertainty

Order costs are heavy-tailed, heteroskedastic, and dependent across common
symbols, days, clients, or market events. The standard error of an IID sample
mean, $s/sqrt(n)$, is too small if observations share shocks.

Choose a resampling or variance strategy aligned with the variation of interest:

- cluster by parent order when modeling child-level events;
- cluster or block by date for common market shocks;
- consider symbol and date multiway clustering for cross-sectional panels;
- use a block bootstrap for serially dependent time series; and
- report robust location and tail summaries alongside the mean.

If orders carry different notionals, distinguish the equal-order estimand from
the dollar- or share-weighted estimand. A weighted mean answers a different
business question and can be dominated by a few large orders.

== A leakage-safe data contract

For every column, record:

#table(
  columns: (0.95fr, 1.1fr, 1.55fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Field*], [*Timestamp*], [*Question*],
  [feature time], [when value became knowable], [Could the live policy have used it?],
  [decision time], [when action was selected], [Does the feature precede treatment?],
  [event time], [exchange or normalized market time], [Are feeds synchronized?],
  [label horizon], [when outcome is complete], [Do train/test labels overlap?],
  [revision time], [when corrected data arrived], [Is research using a later revision?],
)

Parent orders should be assigned wholly to train, validation, or test. Temporal
splits better represent deployment than random row splits. Purge overlapping
label windows when neighboring samples share future returns, and fit all
normalizers, encoders, clusters, and feature selectors inside the training fold.

== Modeling cost distributions

The conditional mean is often insufficient. A schedule may reduce average cost
while worsening the right tail. Useful targets include

$
  E[C|X], quad "median"(C|X), quad Q_tau(C|X), quad P(C>c|X).
$

Quantile regression, distributional models, or conformal prediction can
describe conditional uncertainty. Evaluation should include:

- calibration of intervals or quantiles;
- error by size, participation, spread, volatility, liquidity, side, and time;
- stability across symbols, dates, and regime shifts;
- economic loss under the downstream optimizer; and
- sensitivity to benchmark and markout horizon.

A low mean-squared error can coexist with systematically underestimated large-
order cost—the exact region most important for control.

== From TCA to model diagnosis

Residual analysis should ask structured economic questions. Let
$e_i=C_i-hat(C)_i$. Plot or tabulate conditional residual means and quantiles
against:

- order size as a fraction of forecast ADV or depth;
- intended and realized participation;
- spread, volatility, volume, and order-flow imbalance;
- duration and time of day;
- sector, product, symbol liquidity, and futures roll proximity;
- client objective and benchmark; and
- market regime.

Patterns imply different failures. Residual curvature versus participation
suggests functional-form error. Bias near rolls suggests a missing regime or
contract-liquidity variable. Intraday structure after controlling for liquidity
could indicate participant mix, benchmark incentives, or selection.

#takeaway[
  TCA should close the control loop. The question is not merely whether average
  residual is zero, but whether errors are concentrated where the optimizer
  changes speed. Evaluate model error weighted by policy sensitivity.
]

== Interview checks

#interview[
  *Algorithm B has 2 bps lower average arrival shortfall than A. What do you ask
  before declaring B better?* Cover assignment, order mix, benchmark, completion,
  weighting, uncertainty, overlap, tails, and interference.
]

#interview[
  *Why should parent orders—not child fills—usually define the train/test split?*
  Explain shared latent intent, market path, policy adaptation, and label
  leakage.
]

#interview[
  *Your model underestimates cost near futures rolls. What are plausible causes?*
  Discuss migration between contracts, changing depth/volume denominators,
  spread and volatility, sample support, contract identity, and participant mix.
]

== Exercises

1. Derive the relation between equal-order and notional-weighted average cost.
   Construct a two-order example in which they rank two algorithms oppositely.
2. Design an A/B test for two POV controllers. Specify the randomization unit,
   primary metric, guardrails, stratification variables, and interference check.
3. Build a causal graph containing urgency, alpha, intended participation,
   realized participation, market movement, and shortfall. Explain why realized
   duration can be a bad control.
4. Given repeated orders across 100 symbols and 40 dates, propose two uncertainty
   estimates and state what dependence each preserves.
