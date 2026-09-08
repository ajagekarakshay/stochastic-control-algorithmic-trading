#import "../style.typ": intuition, interview, research, takeaway, definition

= Estimating Market Impact <ch-impact-estimation>

Chapter 6 described the shapes that appear in execution data: costs usually rise
with size and speed, the rise is often concave when expressed per share, and the
observed response may decay after the order finishes. This chapter asks a harder
question. Which part of that pattern can be estimated well enough to support a
forecast or change a trading decision?

The difficulty is not a shortage of regression methods. It is that execution is
an observational process with feedback. Traders choose urgency because they know
something about the order. Algorithms change speed as prices and liquidity move.
Large orders are not placed in randomly selected markets. Realized participation
is partly an outcome of market volume, not merely a control chosen in advance.
Consequently, a fitted relationship between cost and trading speed need not be
the cost response that would follow if we deliberately changed speed.

We will keep three possible uses separate throughout the chapter:

- a *descriptive model* summarizes where costs occurred in historical data;
- a *predictive model* forecasts cost for a new order drawn from a similar
  environment; and
- a *policy model* predicts how cost changes when the execution policy changes.

One model may serve more than one use, but that must be demonstrated rather than
assumed.

#intuition[
  A weather model may predict rain from people carrying umbrellas, but handing
  out umbrellas does not cause rain. The execution analogue is urgency: urgent
  orders often trade quickly and incur high costs. A regression can use speed to
  predict those costs while badly overstating the cost caused by speeding up.
]

== Begin with the estimand

Let parent order $i$ arrive at time $t_i$ with side $d_i in { -1, 1 }$, requested
quantity $Q_i$, completion time $T_i$, average execution price $bar(P)_i$, and
arrival midprice $m_(t_i)$. A side-adjusted arrival cost in basis points is

$
  Y_i = 10^4 d_i (bar(P)_i - m_(t_i)) / m_(t_i).
$

This is a measurement. It is not yet an estimand. We might want the conditional
mean

$
  mu(x) = E lr([Y_i | X_i = x]),
$

where $X_i$ contains pre-trade order and market information. This is a valid
predictive target: what cost should we expect for an order with state $x$ under
the mixture of policies represented in the data?

If the question concerns speed, define an intended participation action $A_i$.
The causal response is expressed with potential outcomes. Let $Y_i (a)$ be the
cost that would have been observed had order $i$ been assigned participation
target $a$. A conditional policy contrast is

$
  tau(a_1, a_0; x)
  = E lr([Y_i (a_1) - Y_i (a_0) | X_i = x]).
$

Only one of $Y_i (a_1)$ and $Y_i (a_0)$ is observed for the order. Estimating their
difference therefore requires a design and assumptions about the missing
counterfactual. The regression surface $E lr([Y_i | A_i = a, X_i = x])$ equals
the causal surface $E lr([Y_i (a) | X_i = x])$ only under conditions such as
conditional exchangeability, consistency, and adequate overlap.

The target also depends on population and timing. A model for completed equity
orders is not automatically a model for all accepted orders, futures around a
roll, or orders whose urgency changes intraday. A pre-trade model may condition
only on variables in the arrival information set $cal(F)_(t_i)$. A retrospective
TCA model can use realized market volume or realized volatility, but its output
answers a different question.

#definition([Identification], [
  Identification means that the target quantity is uniquely determined by the
  distribution of observed data together with stated assumptions. More data can
  reduce sampling error around an identified quantity; it cannot repair a target
  that the observed design does not identify.
])

== Choose quantities whose units tell the right story

Let $V_i$ be a pre-trade daily-volume forecast and let $M_i$ denote forecast
market volume during the intended execution window. Define

$
  q_i = Q_i / V_i,
  quad a_i = Q_i / M_i.
$

Both $q_i$ and $a_i$ are dimensionless. The first measures daily size fraction;
the second is intended participation over the chosen window. If $nu_i$ is a
market-volume rate in shares per unit time and execution occurs at approximately
constant participation $a_i$, then the implied duration is

$
  D_i approx Q_i / (a_i nu_i).
$

Size, participation, and duration are therefore geometrically related. A model
that includes all three as if they were independent levers can have unstable
coefficients even with a large sample. In actual data the identity is blurred by
volume surprises, caps, pauses, and feedback, but the dependence remains.

A useful starting specification for expected cost is

$
  mu_i
  = beta_0
  + beta_q sigma_i q_i^delta
  + beta_a sigma_i a_i^gamma
  + beta_s s_i
  + g(z_i),
$

where $sigma_i$ is a dimensionless volatility forecast over a stated horizon,
$s_i$ is spread in basis points, and $z_i$ contains pre-trade state. Then every
term in $mu_i$ is in basis points. The powers $delta$ and $gamma$ are elasticities
only when their associated terms are interpreted carefully; they are not
unit-free evidence that one mechanism caused another.

The common square-root relation corresponds to $delta approx 1/2$ over a
particular population and support. Direct empirical work finds stable scaling in
many large samples, but the estimated coefficients and even the relevant
normalization vary with data construction, execution horizon, and market
conditions @almgren2005 @toth2011. The square root is a useful baseline, not a
law to be imposed without diagnostics.

=== Average cost, total cost, and marginal cost

Suppose predicted per-share cost in dollars is

$
  c(Q) = k Q^delta,
$

with $k > 0$ and $0 < delta < 1$. Total dollar cost and its marginal derivative
are

$
  C_"tot" (Q) = Q c(Q) = k Q^(1 + delta),
$

$
  C_"tot"'(Q) = (1 + delta) k Q^delta
  = (1 + delta) c(Q).
$

Thus concave *per-share* impact produces convex total cost. For a square-root
curve, marginal cost is $3/2$ times average cost. An optimizer usually responds
to this marginal surface, not to the reported average cost. Smoothness and
extrapolation of derivatives can therefore matter more than a small improvement
in average prediction error.

== Start with a ladder of models

Impact estimation benefits from increasing complexity slowly. Each rung should
answer a diagnostic question that the preceding rung could not answer.

1. A global mean establishes the irreducible baseline.
2. Binned averages reveal shape without assuming a formula.
3. A linear or square-root model tests a simple economic relation.
4. A nonlinear parametric model estimates elasticities and interactions.
5. A generalized additive or partially pooled model captures smooth
   heterogeneity.
6. A flexible machine-learning model searches for residual structure.

If a complex model wins, we should know where: large orders, wide spreads,
particular products, or certain regimes. If the improvement cannot be located,
it is difficult to know whether it will survive the next market state.

=== Bins are exploratory estimators, not harmless pictures

For observations in a bin $B$, the weighted mean cost is

$
  hat(mu)_B = (sum_(i in B) w_i Y_i) / (sum_(i in B) w_i).
$

Equal-count bins give similar sampling mass; fixed-width bins preserve the scale
of the explanatory variable. Both hide within-bin composition. Confidence bands
should respect clustering by parent order, day, or symbol as appropriate. A plot
of thousands of child fills can otherwise look extremely precise when the
effective number of independent parent decisions is small.

Two-dimensional bins over size and participation are especially useful. They
make weak support visible before a smooth model interpolates across empty cells.
Display counts or effective sample sizes along with means. A bright corner based
on six orders should not carry the same visual authority as the center of the
sample.

== Parametric estimation and the error model

Let $x_i$ collect the model inputs and let $f(x_i; theta)$ be a nonlinear impact
surface. A general M-estimator is

$
  hat(theta)
  = arg min_(theta in Theta)
    sum_(i=1)^n w_i ell(Y_i - f(x_i; theta)),
$

where $Theta$ may encode positive scales, bounded elasticities, or monotonicity,
and $ell$ determines how residuals are valued. Squared loss estimates a
conditional mean when the model is correctly specified. Absolute loss targets a
conditional median. Huber loss behaves quadratically near zero and linearly in
the tails, reducing the influence of extreme observations without discarding
them.

Execution residuals are rarely homoskedastic or Gaussian. Their variance often
grows with order size and volatility; tails thicken on event days; and residuals
share day, symbol, client, or parent-order shocks. These features affect both
estimation and reported uncertainty.

If

$
  "Var"(Y_i | X_i = x_i) = omega^2 (x_i),
$

then weights proportional to $1 / omega^2 (x_i)$ can improve efficiency for the
conditional mean. But this weighting changes which errors dominate the fit.
Equal-order weighting estimates performance for a typical order. Quantity
weighting emphasizes a typical share. Dollar-notional weighting emphasizes a
typical dollar. None is universally correct; the production objective should
choose the weighting, and results should also be reported under economically
important alternatives.

=== Log models and retransformation

Power laws invite the regression

$
  log(Y_i) = alpha + delta log(q_i) + gamma log(a_i)
  + theta^T z_i + epsilon_i.
$

This equation is defined only for positive $Y_i$. Realized signed shortfall can
be negative, so taking logs either removes favorable executions or requires a
new response such as absolute cost. The model estimates
$E lr([log(Y_i) | X_i])$, not $log(E lr([Y_i | X_i]))$. If
$epsilon_i | X_i = x$ is Gaussian with conditional variance $omega^2 (x)$, then

$
  E lr([Y_i | X_i = x])
  = exp(mu_"log" (x) + omega^2 (x) / 2).
$

A single global correction is wrong when log residual variance changes across
the state space. Direct nonlinear estimation on the original scale, a
distributional likelihood, or a nonparametric smearing estimate may match the
deployment target better.

#research[
  A log-log plot can look beautifully linear after unfavorable executions have
  been retained and favorable ones made undefined. Always state which
  observations enter the plot and what quantity is being logged.
]

=== Constraints help only when their meaning is defensible

Bounds such as $beta_q >= 0$ and $0 < delta < 1$ can prevent absurd
extrapolation. They do not prove that the constrained curve describes the data.
For nonlinear fits, inspect multiple starting points, boundary solutions, the
conditioning of the Jacobian, and profile loss. If $J$ is the Jacobian with
entries

$
  J_(i,j) = partial f(x_i; theta) / partial theta_j,
$

then nearly collinear columns of $J$ indicate that different parameter changes
produce almost the same fitted surface. Individual coefficients may be weakly
identified even when predictions are stable.

Bootstrap resampling should preserve the dependence structure. Resampling child
fills independently destroys within-order correlation. Depending on the target,
resample parent orders, trading days, or symbol-days; for sparse products a
hierarchical bootstrap may be appropriate.

== Partial pooling across products and regimes

Separate symbol models are noisy where data are scarce. A universal model hides
persistent heterogeneity. A hierarchical model allows both. For product $j$,
consider

$
  beta_j ~ cal(N)(mu_beta + b^T u_j, tau_beta^2),
$

$
  Y_(i,j) = beta_j f(x_(i,j); theta) + epsilon_(i,j),
$

where $u_j$ may contain tick size, typical spread, liquidity rank, asset class,
or roll status. Products with abundant observations learn distinct $beta_j$;
sparse products shrink toward a cross-sectional value informed by their
characteristics. The posterior or sampling uncertainty should widen where the
data remain weak.

Pooling is also useful for time-of-day effects. A separate coefficient for each
five-minute bucket is noisy and jagged. A smooth cyclic function or hierarchical
curve by liquidity group can represent common structure while allowing genuine
departures. Crucially, use pre-trade spread, volatility, volume, and order mix so
that the time label does not absorb every state difference associated with the
clock.

== Endogeneity: speed is chosen for a reason

Write a simplified structural relation as

$
  Y_i = beta A_i^gamma + theta^T X_i + epsilon_i.
$

Suppose latent urgency $U_i$ raises intended participation $A_i$. If urgent buy
orders also have positive short-term alpha, $U_i$ raises adverse price movement
inside $epsilon_i$. Then

$
  E lr([epsilon_i | A_i, X_i]) != 0.
$

Ordinary regression attributes part of the alpha to participation. Realized
participation adds another feedback channel: market volume and fills determine
the denominator, and algorithms change actions after observing the price path.

The appropriate remedy depends on the decision and available variation.

- *Randomized assignment* of safe participation bands gives the cleanest
  comparison within the randomized support.
- *Intent-to-treat analysis* compares assigned policies even when realized
  participation differs because of market conditions.
- *Rich pre-trade adjustment* is credible only if the remaining assignment is
  conditionally exchangeable.
- *Instrumental variables* require a variable that changes speed and affects
  cost only through speed; correlation with speed is not sufficient.
- *Sequential causal methods* are needed when time-varying market state affects
  both later actions and outcomes while itself being affected by earlier
  actions.
- *Structural joint models* make the policy and market response explicit, but
  their conclusions inherit stronger assumptions.

Metaorder reconstruction creates a related selection problem. Public trade data
do not reveal investor intent, order boundaries, or the unexecuted quantity.
Heuristics that group same-sign trades can manufacture long-memory and impact
patterns. When private parent identifiers exist, preserve them. When they do
not, treat reconstructed metaorders as latent objects and report sensitivity to
the grouping rule.

== Measurement error and denominator risk

Suppose the true daily size fraction is $q_i = Q_i / V_i$, but we observe

$
  tilde(q)_i = Q_i / tilde(V)_i,
$

where $tilde(V)_i$ is a noisy or revised volume estimate. Classical measurement
error in a regressor often attenuates a linear slope, but ratio variables and
nonlinear power laws need not exhibit simple attenuation. Errors can also be
systematic: continuous futures series obscure the exact contract, corporate
actions change historical shares, and realized volume contains information not
available before trading.

Keep separate fields for forecast, contemporaneously known, and corrected
denominators. Train the live model on values reproducible at the decision time.
A post-trade model may use corrected values for diagnosis, but it should not be
presented as a feasible pre-trade forecast.

Completion creates censoring. If only completed orders are kept, difficult
orders disappear precisely when impact and opportunity cost are high. Let
$R_i = 1$ indicate that the target cost is fully observed. Complete-case
estimation is unbiased only under restrictive missingness assumptions. At a
minimum, model and report

$
  pi_i = P(R_i = 1 | X_i, A_i),
$

inspect completion by state and policy, and include residual inventory valued at
a stated terminal benchmark. Chapter 3's implementation-shortfall identity is
often safer than pretending the missing shares had no cost.

== Flexible models without surrendering economics

Boosted trees, generalized additive models, neural networks, and Gaussian
processes can capture interactions among size, spread, volatility, depth,
imbalance, and time. Their usefulness is greatest when the structure of the
deployment problem guides them.

A practical hybrid is

$
  hat(mu)(x)
  = mu_"base" (x; hat(theta)) + f_"res" (x),
$

where $mu_"base"$ is a stable scaling model and $f_"res"$ learns residual
structure. Cross-fit the residual model so that diagnostics do not reuse fitted
noise. Audit the combined surface, not its components separately.

For control, useful constraints include:

- nondecreasing expected cost with size and aggressiveness over supported
  regions;
- smooth or regularized marginal costs;
- sensible limiting behavior near zero size and at participation caps;
- uncertainty that expands away from training support; and
- stable rankings of feasible actions under small input perturbations.

Monotone boosting or shape-constrained additive models can encode part of this
structure. A probabilistic model should forecast a distribution, not merely
attach a constant standard error to a nonlinear point estimate. Quantile loss,
heteroskedastic likelihoods, conformal intervals under suitable exchangeability,
or Bayesian predictive distributions are possible tools. Calibration must be
checked by state: an interval with 90% overall coverage can fail systematically
for large illiquid orders.

== Validation must resemble deployment

Random row splits are usually too optimistic. Neighboring executions share
market regimes, symbols, client behavior, and sometimes the same parent order.
Use chronological holdouts and keep statistically dependent units together. A
useful validation design may combine:

- a rolling or expanding training window;
- future weeks as validation and test periods;
- parent-order grouping for child-level data;
- held-out symbols or product groups to test pooling;
- explicit event, roll, and stressed-liquidity slices; and
- a final untouched period used once for model selection.

No single score describes an impact surface. Report mean bias, MAE or RMSE,
tail loss, and interval calibration, then map residuals over size-participation,
volatility-spread, time of day, side, product, and regime. For residual

$
  e_i = Y_i - hat(mu)(X_i),
$

conditional residual means

$
  hat(b)(B) = (sum_(i in B) w_i e_i) / (sum_(i in B) w_i)
$

should be economically small across important bins $B$, not merely zero after
averaging mutually offsetting regions.

Compare prediction surfaces and their derivatives. For feature $x_j$, define

$
  S_j (x) = partial hat(mu)(x) / partial x_j.
$

The controller may act on $S_j (x)$ even when evaluation reports only
$hat(mu)(x)$. Numerically perturb each input, recompute the feasible policy, and
measure changes in trading rate, completion, expected cost, and risk. If tiny
estimation changes create large action changes, regularize the policy, not just
the predictor.

#takeaway[
  The final validation object is a chain: data $arrow.r$ estimated surface
  $arrow.r$ marginal comparison $arrow.r$ action $arrow.r$ realized outcome.
  A model can pass the first link and fail the rest.
]

== A worked diagnostic: lower slippage near the close

Suppose mean arrival shortfall is lower for orders beginning late in the day.
It is tempting to add a closing-period indicator and call its coefficient a
time-of-day effect. First write several competing explanations:

- spreads or volatility are lower in the observed late-day sample;
- volume and replenishment are stronger near the close;
- order sizes, clients, benchmarks, or urgency differ;
- incomplete difficult orders are missing;
- auction participation changes the relevant benchmark;
- the algorithm changes behavior late in the session; or
- the effect is genuine after these differences are controlled.

Estimate the raw curve, then progressively condition on pre-trade state and
order composition. Inspect common support: if large illiquid morning orders have
no close-period counterparts, regression adjustment is extrapolation. Compare
within-symbol and within-day contrasts where possible. Interact clock time with
spread, volatility, and liquidity rather than forcing one universal adjustment.
Finally, test whether changing the policy's time-dependent behavior reproduces
the benefit. The coefficient is useful for prediction before it is necessarily
a causal instruction to delay trading.

== What the estimator should hand to the controller

A production handoff should specify more than fitted coefficients. For every
candidate action, the consuming policy needs:

- the predicted cost or response distribution;
- the information timestamp of every input;
- the supported state-action region;
- local marginal costs or action rankings;
- parameter and predictive uncertainty;
- behavior under caps, zero liquidity, and missing features; and
- a fallback outside supported conditions.

The model contract should also state the policy that generated its data. Once a
new optimizer changes participation, routing, or pause behavior, it changes the
distribution on which the estimator was trained. Impact estimation is therefore
not a one-time calibration. It is part of a feedback loop that Chapters 16 and
24 will make explicit.

== Interview checks

#interview[
  *Why does regressing cost on realized participation not identify the causal
  effect of speed?* Discuss latent urgency, alpha, market-volume shocks,
  within-order feedback, and the difference between intended and realized
  participation.
]

#interview[
  *A square-root model has worse RMSE than a boosted tree but produces more
  stable schedules. Which model is better?* State the deployment objective,
  compare calibration by decision-relevant slices, inspect marginal surfaces,
  and evaluate the policies induced by both models.
]

#interview[
  *Why can a coefficient be imprecise while predictions remain stable?* Explain
  correlated parameters, weak identification of a decomposition, and strong
  identification of their combined fitted surface.
]

#interview[
  *How would you estimate impact for illiquid futures near a roll?* Preserve
  exact contract identity, model liquidity migration and days-to-expiry, use
  partial pooling, retain incomplete orders, and validate the roll region
  separately instead of relying on a continuous series.
]

== Exercises

1. For $c(Q) = k Q^delta$, derive average, total, and marginal cost. Check the
   limits $delta -> 0$ and $delta -> 1$ and interpret each.
2. Construct a causal graph containing urgency, intended participation,
   realized participation, market volume, alpha, and cost. Identify variables
   that are pre-treatment controls and variables that should not enter a
   pre-trade causal adjustment.
3. Fit conceptually a log-cost model when 20% of signed costs are negative.
   Propose three response definitions and explain the estimand each creates.
4. Design a bootstrap for child fills nested within parent orders and days.
   State which source of uncertainty each resampling level captures.
5. A constrained nonlinear estimate repeatedly returns $hat(delta)=0.99$.
   List diagnostic explanations other than “impact is linear” and propose one
   test for each.
6. Specify a validation table for an impact model used by a participation
   optimizer. Include statistical, economic, derivative, support, and policy
   metrics.

== Where the book goes next

An impact estimator describes the cost side of an execution decision. The
policy also needs a forecast of the environment into which it will trade:
remaining volume, spread, depth, volatility, order flow, fill conditions, and
short-horizon price pressure. Chapter 8 develops that state forecast and asks a
practical question: which prediction would actually change the next action?
