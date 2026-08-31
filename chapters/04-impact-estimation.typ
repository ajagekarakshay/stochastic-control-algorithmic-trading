#import "../style.typ": intuition, interview, research, takeaway, definition

= Market-Impact Models and Estimation <ch-impact>

Market-impact estimation sits between measurement and control. The model must
compress executions with different sizes, speeds, products, and states into a
conditional cost surface. The optimizer will then differentiate or compare that
surface outside the exact observations used to fit it. Shape, uncertainty, and
identification matter as much as average predictive fit.

== What is the estimand?

Before choosing a functional form, specify:

- response: arrival shortfall, VWAP slippage, contemporaneous-mid cost, or
  post-trade markout;
- horizon: execution interval and any reversion window;
- unit: dollars, basis points, ticks, spread units, or volatility units;
- population: parent orders, metaorders, child orders, or public trades;
- conditioning state: only information available at the intended prediction
  time; and
- interpretation: reduced-form prediction, policy response, or structural
  impact.

These choices define different targets. There is no benchmark-free scalar
called “true impact.”

== Scaling variables

Let

$
  x = Q/V,
  quad rho = Q/(V_T T),
$

where $Q$ is order size, $V$ a daily-volume scale, and $V_T$ the relevant
market-volume rate. Then $x$ is daily size fraction and $rho$ is participation.
If volume rate is constant, duration satisfies

$
  T = Q/(rho V_T).
$

Size, participation, and duration are therefore mechanically related. Including
all three in a regression can create unstable interpretation; in real data the
identity is noisy because volume varies and policies adapt, but the dependence
does not disappear.

Costs are often normalized by volatility and liquidity. A stylized model is

$
  E[C | X] = sigma [ beta_0 + beta_1 x^delta rho^gamma ] + beta_s s + beta^T z,
$

where $0 < delta < 1$ represents concavity in size and $z$ contains pre-trade
state. A square-root specification uses $delta=1/2$ @toth2011. This is an
empirical scaling law over a population and range—not a universal theorem.

#intuition[
  Concavity says doubling size less than doubles per-share impact, not that total
  dollar cost is concave. If per-share cost scales as $Q^delta$, total cost scales
  as $Q^(1+delta)$ and is convex for $delta>0$.
]

== Shape and units

Suppose per-share temporary impact is $h(v)=eta |v|^gamma "sign"(v)$. For a
constant-rate program, total temporary cost is

$
  integral_0^T v_t h(v_t) dif t
  = eta Q^(1+gamma) T^(-gamma).
$

Thus faster completion raises cost when $gamma>0$. If $0<gamma<1$, per-share
impact is concave in rate while total instantaneous cost $v h(v)$ remains convex.
This distinction is important for optimization.

Empirical power laws are convenient because logs turn multiplicative structure
into addition:

$
  log C = alpha + delta log x + gamma log rho + theta^T z + epsilon.
$

But log regression changes the error model, excludes or transforms nonpositive
costs, and estimates $E[log C|X]$, not directly $log E[C|X]$. Retransformation
requires care under heteroskedasticity. Direct nonlinear least squares or a
distributional likelihood may better match the deployment target.

== Temporary, permanent, and decay models

=== Reduced-form schedule cost

A practical model predicts total cost from parent-order and market features:

$
  C_i = f(Q_i/"ADV"_i, rho_i, sigma_i, s_i, t_i, z_i; theta) + epsilon_i.
$

It is easy to serve and optimize, but it collapses the execution path. Changing
the child-order pattern while holding summary features fixed may invalidate it.

=== Permanent-plus-temporary model

Let unaffected midprice follow $dif S_t=sigma dif W_t$ and observed execution price be

$
  P_t = S_t + integral_0^t g(v_s) dif s + h(v_t).
$

Here $g$ shifts later reference prices while $h$ affects the current execution.
This decomposition powers classical optimal execution, but observed post-trade
prices do not uniquely reveal it without assumptions about the unaffected path.

=== Transient or propagator model

Let signed trading rate be $v_t$. A continuous-time propagator is

$
  P_t = S_t + integral_0^t G(t-s) f(v_s) dif s.
$

The expected impact cost is the quadratic-like path functional

$
  C[v] = integral_0^T v_t integral_0^t G(t-s) f(v_s) dif s dif t.
$

This captures overlap and decay. Kernel and instantaneous-response shapes must
obey restrictions to avoid price-manipulation strategies @gatheral2010. A model
that fits observed paths but permits profitable round trips is unsuitable for
control.

== Data construction

A parent-order impact table should distinguish fields known at arrival from
realized outcomes:

#table(
  columns: (1.05fr, 1.25fr, 1.45fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Stage*], [*Examples*], [*Use*],
  [Pre-trade], [requested size, forecast ADV/volume curve, spread, volatility, depth, alpha], [features and stratification],
  [Policy], [intended urgency, POV bounds, benchmark, algo version], [treatment and policy context],
  [Within-order], [realized participation, fills, pauses, market path], [diagnostics or sequential model],
  [Post-trade], [shortfall, markouts, completion, reversion], [labels and decomposition],
)

Use pre-trade denominators for a deployable pre-trade estimator. If a
post-trade TCA model uses realized volume, label it as retrospective and do not
silently pass the same formula to a live optimizer.

Filter rules also define the estimand. Excluding high-volatility days, incomplete
orders, rolls, or difficult symbols can make residuals look better by removing
the decisions for which the model is most needed. Prefer explicit regime flags,
censoring models, and separate support diagnostics.

== Constrained nonlinear estimation

Let $y_i$ be measured cost and $f(x_i;theta)$ a nonlinear impact curve. Estimate

$
  hat(theta) = arg min_(theta in Theta) sum_i w_i rho_"loss"(y_i-f(x_i;theta)),
$

where $Theta$ enforces economically motivated bounds such as positive scale and
$0<delta<1$. The loss may be squared, Huber, or a likelihood-based deviance.
Trust-region reflective algorithms are useful for bound-constrained nonlinear
least squares, but an optimizer's convergence flag is not evidence that the
model is identified.

Check:

1. multiple starting points and boundary solutions;
2. parameter-profile or bootstrap uncertainty;
3. Jacobian conditioning and correlated parameters;
4. stability across time, symbols, size ranges, and sides;
5. monotonicity and curvature over the deployment domain; and
6. extrapolated marginal costs used by the controller.

If residual variance grows with order size, unweighted least squares prioritizes
large absolute errors. That may be economically appropriate—or it may cause the
model to ignore typical orders. Choose weights to match the target estimand,
then report performance both weighted and unweighted.

#research[
  Shape constraints can encode sensible extrapolation, but they can also conceal
  misspecification. If many estimates hit a concavity bound, investigate missing
  interactions, regimes, denominator error, and action endogeneity before
  interpreting the bound as an empirical discovery.
]

== Endogeneity of execution speed

Consider

$
  C_i = beta rho_i^gamma + theta^T X_i + epsilon_i.
$

Urgency $U_i$ may raise $rho_i$ and correlate with future adverse movement in
$epsilon_i$. Liquidity shocks during the order can raise both realized
participation difficulty and cost. Adaptive algorithms may speed up after price
moves, reversing the apparent causal direction. Therefore
$E[epsilon_i|rho_i,X_i] != 0$ is plausible.

Strategies include:

- randomized parameter perturbations within safe bounds;
- intent-to-treat analysis using assigned rather than realized speed;
- instruments that shift speed without directly shifting cost;
- fixed effects or rich pre-trade controls when conditional exchangeability is
  credible;
- sequential causal methods for time-varying treatment and confounding; and
- structural models jointly describing policy and outcomes.

None is automatic. A valid instrument is an economic argument, not just a
variable correlated with participation.

== Hierarchical pooling

Symbol-specific models are noisy for illiquid products; a universal model can
miss persistent heterogeneity. A hierarchical specification partially pools:

$
  beta_j ~ cal(N)(mu_beta, tau_beta^2),
  quad C_(i,j) = beta_j f(X_(i,j);theta) + epsilon_(i,j).
$

Liquid symbols with abundant data learn their own coefficients; sparse symbols
shrink toward the cross-sectional mean or a cluster mean. Features describing
tick size, spread, sector, market cap, and liquidity can explain part of the
hierarchy.

Clustering volume profiles or impact residual shapes can help, but clusters must
be fitted on training history and monitored for membership instability. A soft
hierarchy often expresses uncertainty better than assigning a sparse symbol to
one hard cluster.

== Machine learning: where it helps

Flexible ML models can capture interactions among spread, volatility, imbalance,
time, and liquidity. Useful patterns include:

- a structural baseline plus an ML residual correction;
- generalized additive models for interpretable nonlinear effects;
- boosted trees for tabular interactions;
- quantile or distributional models for tail-aware control;
- multitask or hierarchical models across products; and
- sequence/state-space models for within-order adaptation.

A hybrid model

$
  hat(C)(x) = C_"struct"(x;hat(theta)) + f_"ML"(x)
$

preserves scaling intuition while allowing empirical corrections. Constrain or
audit the combined surface for monotonicity, smooth marginal costs, support, and
policy stability. A jagged prediction surface can create unstable bang-bang
schedules even if its average test error is low.

#takeaway[
  Model selection should include a *policy loss*: solve the downstream control
  problem using each candidate, then evaluate the resulting actions under a
  common simulator, randomized experiment, or credible off-policy method. The
  best predictor is not always the best decision model.
]

== Validation as a surface, not a score

Report at least:

- mean error, MAE/RMSE, and tail or quantile calibration;
- residual maps over size × participation and volatility × spread;
- chronological and regime holdouts;
- symbol/client/product-group stability;
- uncertainty of both predictions and parameters;
- monotonicity/concavity violations and extrapolation distance; and
- induced schedule changes and sensitivity.

A useful local sensitivity is

$
  S_j(x) = partial hat(C)(x)/partial x_j.
$

Compare $S_j$ with empirical local effects and with the optimizer's response.
If small coefficient changes produce large policy changes, the control problem
needs regularization, uncertainty-aware optimization, or tighter constraints.

== Interview checks

#interview[
  *Why can a concave per-share impact curve still produce a convex execution
  problem?* Multiply per-share impact by traded quantity or rate and show the
  resulting exponent.
]

#interview[
  *Your test RMSE improves, but optimal schedules become erratic. Why?* Discuss
  derivative noise, extrapolation, weak overlap, unconstrained interactions, and
  policy-sensitive rather than prediction-average validation.
]

#interview[
  *How would you test whether lower close-period slippage is a time effect or a
  liquidity-composition effect?* Propose pre-trade controls, within-symbol/date
  comparisons, interactions, overlap checks, and a policy or natural-experiment
  design.
]

== Exercises

1. Derive total temporary cost for $h(v)=eta v^gamma$ under constant rate and
   determine when it is convex in $Q$ and in $v$.
2. Fit mentally a power law with $delta$ near its upper bound. List four reasons
   besides “impact is linear” that could generate the boundary estimate.
3. Design a hierarchical model for futures contracts around rolls. Specify which
   parameters pool by product, front/next contract, and days-to-roll.
4. Compare a structural-plus-residual model with an unconstrained boosted tree.
   Define a validation suite focused on the schedule each model induces.
