#import "../style.typ": intuition, interview, research, takeaway, definition

= Short-Horizon Forecasting and Liquidity State <ch-liquidity-state>

An execution algorithm never trades into an unconditional average market. At
each decision time it faces a particular spread, queue, volume rate, volatility
regime, and pattern of order flow. Some of that state is visible. Some is noisy,
delayed, or latent. All of it can change before the next child order is filled.

The purpose of forecasting in execution is therefore narrower than “predict the
market.” It is to estimate the future quantities that distinguish the available
actions. Should the algorithm trade now or wait? Post or cross? Maintain its
participation target or reduce it? Route to one venue or another? A statistically
predictable variable has no execution value if every feasible action responds to
it in the same way.

This chapter develops forecasts for two closely related objects:

- *liquidity state*: volume, spread, depth, volatility, order arrivals, and
  fill conditions; and
- *short-horizon price pressure*: the expected price move or markout over the
  horizon affected by the next execution decision.

Calling the second object *short-term alpha* is convenient, but it should not be
confused with a portfolio signal intended to hold a position for hours or days.
Execution alpha is conditional, short lived, and valuable only after spread,
impact, fill risk, and inventory constraints are included.

== State, information, action, and horizon

At event or clock time $t$, let $cal(F)_t$ be the information available to the
algorithm. Let $O_t$ be the observed market data, $H_t$ a latent liquidity
regime, $X_t$ remaining inventory, and $A_t$ the next execution action. A useful
control state is

$
  Z_t = (X_t, O_t, hat(H)_t, tau_t),
$

where $tau_t$ is remaining time and $hat(H)_t$ represents a filtered belief,
not necessarily a single regime label. The action might specify a child-order
size, aggressiveness, price, venue, or participation target.

A forecast must be indexed by a horizon. For future variable $Y_(t+h)$, define

$
  mu_h (Z_t) = E lr([Y_(t+h) | cal(F)_t]).
$

The choice of $h$ is economic. A 100-millisecond queue decision, a five-minute
participation update, and a remaining-day VWAP schedule need different targets.
A model with excellent accuracy at one horizon can be irrelevant or even
misleading at another.

Actions complicate the definition. If our own order can materially change the
book, the required object is action conditional:

$
  mu_h (z, a)
  = E lr([Y_(t+h) | Z_t = z, "do"(A_t = a)]).
$

Historical prediction under the behavior policy estimates
$E lr([Y_(t+h) | Z_t = z, A_t = a])$. It becomes a counterfactual action model
only with a credible experiment or identification argument. For a small child
order, treating the market state as exogenous may be a useful approximation. For
a large aggressive slice, it is not.

#intuition[
  A forecast answers “what is likely to happen next under specified
  information.” A controller asks “what is likely to happen next if I choose
  this action.” The two questions become the same only when the action has no
  relevant effect or when that effect is already modeled.
]

== Start from simple conditional baselines

Market data contain strong seasonality and persistence. A sophisticated model
should first beat baselines that represent those facts:

- the unconditional mean by symbol and time bucket;
- the most recent observed value;
- an exponentially weighted mean;
- the historical intraday curve for the same weekday or event type;
- a linear autoregression with a small set of state variables; and
- the current quote or microprice for very short price horizons.

These baselines are not ceremonial. If a neural network beats a global mean but
not the current spread, it has not learned useful spread dynamics. If a volume
model beats yesterday's volume but not the historical cumulative curve updated
with today's realized volume, the comparison is too weak.

For any target, record the forecast origin, horizon, sampling clock, revision
policy, and loss. “Predict volatility” is incomplete. “At the end of each
five-minute bucket, predict the distribution of integrated midprice variance
over the next six buckets using information timestamped by the forecast origin”
is testable.

== Forecasting intraday and remaining volume

Volume forecasts enter VWAP schedules, participation controls, completion
checks, and size normalization. They have two distinct components:

1. the *shape* of volume through the session; and
2. the *scale* of total daily activity.

Partition the session into $K$ buckets. Let $V_k$ be volume in bucket $k$,
$V_"day" = sum_(j=1)^K V_j$, and

$
  R_k = V_k / V_"day",
  quad sum_(k=1)^K R_k = 1.
$

The vector $R = (R_1, ..., R_K)$ is a composition. Modeling each $R_k$
independently ignores the unit-sum constraint and usually produces incoherent
uncertainty. Several representations are possible:

- a deterministic historical curve by product and day type;
- a Dirichlet or logistic-normal distribution for the share vector;
- a smooth functional model of cumulative volume;
- a state-space model that updates today's latent scale and shape; or
- a sequence model that predicts the remaining conditional distribution.

Let cumulative volume through bucket $k$ be $C_k = sum_(j=1)^k V_j$. The
quantity needed at time $k$ is not the unconditional daily forecast, but

$
  E lr([V_"day" - C_k | cal(F)_k]).
$

Today's realized pace, scheduled events, index changes, expiry, and opening
conditions should update the remaining-volume distribution. A useful state-space
decomposition is

$
  log(V_k) = mu_k + L_d + u_(d,k),
$

where $mu_k$ is the typical intraday pattern, $L_d$ is a latent activity level
for day $d$, and $u_(d,k)$ is bucket noise. Filtering $L_d$ as volume arrives
allows early observations to revise the remainder of the curve.

Point forecasts are insufficient near a completion deadline. If future market
volume is uncertain, a nominal 10% participation schedule may fail to complete.
The controller needs quantiles or scenarios. For example, if
$M_(t,T)$ is remaining market volume through deadline $T$, then a feasibility
test for remaining inventory $X_t$ and maximum participation $a_"max"$ is

$
  P(a_"max" M_(t,T) >= X_t | cal(F)_t).
$

A low probability warns that the strategy must increase aggressiveness, extend
the horizon, or invoke an emergency completion rule. Replacing $M_(t,T)$ by its
mean hides precisely the downside state that matters.

=== Intended and realized participation

At time $t$, a controller can choose an intended rate based on forecast volume.
It cannot choose realized participation exactly because the denominator is
unknown. If $q_(t,t+h)$ is our executed quantity and $M_(t,t+h)$ is market
volume, then

$
  A_"realized" = q_(t,t+h) / M_(t,t+h).
$

Forecast errors create deviations even when the policy behaves exactly as
designed. Training a volume model on corrected end-of-day data and evaluating
the policy with real-time feeds also creates hidden look-ahead. Store the
vintage of every forecast and the precise volume definition used in production.

== Spread and depth are distributions, not constants

Let best bid and ask be $b_t$ and $a_t$, spread $s_t = a_t - b_t$, and displayed
depth at the best quotes $D_t^b$ and $D_t^a$. For a marketable buy of size $q$,
the relevant liquidity variable is not only $s_t$ but the ask-side cost of
walking the book:

$
  W_t^a (q)
  = (1 / q) sum_(ell=1)^L q_(t,ell)
    (p_(t,ell)^a - m_t),
$

where $sum_(ell=1)^L q_(t,ell) = q$ and $p_(t,ell)^a$ is the ask price at level
$ell$. This snapshot cost can disappear through cancellations before the action
arrives, or replenish while the order executes.

Useful spread and depth forecasts include:

- the probability that the spread widens or narrows before the next decision;
- expected and quantile book-walking cost for candidate sizes;
- time to depletion of the best quote;
- replenishment following a trade or cancellation burst; and
- joint transitions of spread, depth, and order flow.

A discrete transition model might estimate

$
  P(S_(t+h) = s', D_(t+h) in B_d | Z_t = z),
$

where $S_t$ is spread in ticks and $B_d$ is a depth bin. A model that predicts
these variables independently can generate impossible scenarios, such as
extreme depth at a spread state never observed for that product. Joint models or
scenario resampling preserve more of the dependence.

Depth is especially venue- and latency-dependent. Displayed size seen at the
research timestamp is not necessarily accessible size at order arrival. A
deployable feature should reproduce the production feed, processing delay, and
venue view. Otherwise the model learns phantom liquidity.

== Volatility: forecast the risk that the policy bears

Execution risk depends on price variation while inventory remains. For log
midprice $p_t = log(m_t)$, realized variance over $[t, t+h]$ on a grid
$t = u_0 < u_1 < ... < u_J = t+h$ is

$
  "RV"_(t,t+h) = sum_(j=1)^J (p_(u_j) - p_(u_(j-1)))^2.
$

This is one ex-post observation of variation over the interval. At time $t$, the
forecast target is a conditional distribution such as

$
  cal(L)("RV"_(t,t+h) | cal(F)_t).
$

Historical daily volatility, current high-frequency realized variation, option
implied volatility, spread, order-flow intensity, and scheduled events provide
different information. Their usefulness depends on the horizon and asset.

Microstructure noise contaminates very fine returns. Bid-ask bounce can make
trade-price variance rise as sampling becomes faster even when efficient-price
risk does not. Midquotes reduce bounce but can be stale. Use sampling and noise
corrections appropriate to the control horizon, and specify whether the policy
needs variance of the midprice, executable price, or benchmark.

In a cost-risk controller, forecast variance is multiplied by future inventory
exposure. A simple discrete approximation is

$
  "Risk"_t
  = lambda sum_(k=t)^(T-1)
    hat(sigma)_(k,k+1)^2 X_k^2 Delta t.
$

Underestimating volatility early, when inventory is large, matters much more
than the same proportional error near completion. This suggests evaluating the
forecast with inventory-weighted loss in addition to ordinary variance error.

== Order flow, imbalance, and short-horizon price pressure

At the best quotes, a simple queue imbalance is

$
  I_t = (D_t^b - D_t^a) / (D_t^b + D_t^a),
$

which lies in $[-1, 1]$ when total displayed depth is positive. A depth-weighted
microprice is

$
  mu_t
  = (a_t D_t^b + b_t D_t^a) / (D_t^b + D_t^a).
$

When bid depth exceeds ask depth, $mu_t$ lies above the midpoint. The formula
does not say that price must rise; it summarizes an imbalance that may predict
which queue depletes first.

Order-flow imbalance improves the description by accounting for additions,
cancellations, and market orders at the best quotes. Over interval
$(t, t+h]$, write a signed net change

$
  "OFI"_(t,t+h)
  = Delta D^b_(t,t+h) - Delta D^a_(t,t+h),
$

with event-specific sign conventions defined carefully. Empirical work finds a
strong short-horizon relation between price changes and order-flow imbalance,
with sensitivity related to depth @cont2014. That relation is predictive and
state dependent; our own order flow may also contribute to the measured
imbalance.

Define short-horizon midprice alpha for horizon $h$ as

$
  alpha_t^(h)
  = E lr([d (m_(t+h) - m_t) | cal(F)_t]),
$

where $d=1$ for a buy program and $d=-1$ for a sell. Positive
$alpha_t^(h)$ means waiting is expected to move the market against the order.
It increases the value of immediacy. Negative alpha favors patience, subject to
fill and completion risk.

The horizon profile matters more than a single score. Let

$
  bold(alpha)_t
  = (alpha_t^(h_1), ..., alpha_t^(h_J)).
$

A signal that predicts the next event but reverses within ten seconds should
change queue tactics, not a thirty-minute schedule. A persistent five-minute
signal may justify front-loading. Multi-horizon models can reveal this decay,
but adjacent horizon labels overlap strongly; splits and uncertainty estimates
must respect that dependence.

=== Price prediction is not yet execution value

Suppose an immediate buy of quantity $q$ has expected all-in cost
$C_"now" (q, Z_t)$. Waiting for horizon $h$ has expected later execution cost
$C_"later" (q, Z_t)$, adverse movement $alpha_t^(h)$, and non-completion penalty
$N_t (h)$. The net advantage of trading now can be written schematically as

$
  Delta V_t (q, h)
  = alpha_t^(h)
  + C_"later" (q, Z_t)
  + N_t (h)
  - C_"now" (q, Z_t).
$

The sign, not the raw alpha, distinguishes the actions. A one-basis-point signal
is valuable when immediacy costs 0.3 basis points and irrelevant when crossing
costs four. Expected return should therefore be calibrated in the same economic
units and evaluated jointly with impact and fill predictions.

#takeaway[
  Short-term alpha does not create a new objective separate from execution. It
  changes the opportunity cost of waiting inside the existing objective.
]

== Fill probability and adverse selection must be modeled together

A passive order offers a possible spread saving but creates a random fill time.
Let $F_(t,h)=1$ if an order posted at time $t$ fills by $t+h$. A fill model
estimates

$
  p_"fill" (h | z, a)
  = P(F_(t,h) = 1 | Z_t = z, A_t = a).
$

Queue position, displayed depth ahead, cancellation intensity, trade intensity,
price distance, venue, and latency are natural inputs. Survival analysis or
point-process models can represent time to fill and censor orders canceled by
the strategy.

Fill probability alone overvalues toxic fills. Let the side-adjusted markout
after a fill at time $tau_f$ be

$
  M_h = d (m_(tau_f+h) - P_"fill").
$

The relevant forecast is conditional on filling:

$
  E lr([M_h | F_(t,h_f) = 1, Z_t = z, A_t = a]).
$

Fills are not random subsets of posting opportunities. They often occur when
the market is moving through the quote, so the conditional markout can be
adverse even when the unconditional price forecast is neutral. A passive-action
value model must combine spread capture, fees or rebates, fill probability,
conditional markout, opportunity cost, and terminal urgency.

Cancellation by the algorithm is informative censoring: the order may be pulled
because the state became dangerous. Treating every canceled order as a non-fill
without modeling the policy mixes market fill risk with the strategy's decision
rule. Randomized or logged policy variation is particularly valuable here.

== Event intensities and point-process models

At very short horizons, market evolution is naturally described by event
arrivals. Let $N_t^r$ count events of type $r$, such as buy market orders, ask
cancellations, or bid limit additions. A conditional intensity is

$
  lambda_t^r
  = lim_(Delta t -> 0)
    P(N_(t+Delta t)^r - N_t^r = 1 | cal(F)_t) / Delta t.
$

Poisson regression permits state-dependent but conditionally independent
increments. Hawkes processes add excitation from recent events:

$
  lambda_t^r
  = mu^r + sum_s integral_0^t phi_(r,s)(t-u) dif N_u^s.
$

The kernels $phi_(r,s)$ describe how an event of type $s$ changes the near-term
rate of type $r$. They can represent clustered trades, cancellations, and
replenishment. Stability requires the excitation not to amplify indefinitely.
In execution applications, intensities are useful only if simulation or action
valuation preserves the correct joint response of prices and queues.

Event models have a practical advantage: their clock speeds up when the market
is active. But event time discards calendar waiting. A queue may see no events
for several seconds, which matters to a deadline-aware policy. Retain both event
count and elapsed time in the state.

== Latent liquidity and state-space models

Displayed observations are noisy manifestations of a slower market condition.
Let latent state $H_t$ represent normal, thin, or stressed liquidity. A linear
Gaussian state-space model is

$
  H_(t+1) = F H_t + G u_t + w_t,
$

$
  O_t = C H_t + v_t,
$

where $u_t$ contains known inputs, $w_t$ is process noise, and $v_t$ is
measurement noise. The Kalman filter maintains a conditional mean and covariance
of $H_t$. This separation is conceptually valuable even when Gaussian linearity
is too restrictive: it distinguishes actual state evolution from noisy
observation.

A hidden Markov model instead uses a discrete regime $H_t in {1, ..., R}$ with
transition probabilities

$
  P(H_(t+1) = r' | H_t = r) = p_(r,r').
$

The controller should usually retain the filtered probability of each regime,
not replace it with a hard label. If the posterior is 55% normal and 45%
stressed, acting as if “normal” were certain discards decision-relevant
uncertainty.

Regimes should earn their place by improving forecasts or decisions out of
sample. A state discovered by an unsupervised model is not automatically an
economic regime. Examine its duration, transitions, feature distributions,
cost consequences, and stability across retraining windows.

== Choosing a model family

The model should match the target's structure before it matches fashion.

=== Linear and generalized models

Linear, logistic, count, and survival regressions provide transparent signs,
interactions, and uncertainty. Splines and generalized additive models capture
smooth intraday and nonlinear effects without abandoning interpretability. They
are strong baselines for volume curves, spread transitions, volatility, and
fill hazards.

=== Trees and boosting

Tree ensembles work well on heterogeneous tabular state. They capture thresholds
such as “imbalance matters primarily when depth is thin.” Their stepwise surfaces
can produce unstable action boundaries. Monotonicity constraints, probability
calibration, and perturbation tests help. Feature importance is not a causal
explanation and can be distorted by correlated market variables.

=== Gaussian processes

A Gaussian process places a distribution over functions,

$
  f ~ "GP"(m( dot ), k( dot , dot )).
$

The kernel encodes similarity across states and produces uncertainty that can
expand away from observations. Gaussian processes are attractive for smooth,
moderate-dimensional response surfaces and hierarchical product effects, but
naive computation scales poorly with sample size. Sparse approximations and
careful kernels are needed for large event data.

=== Sequence models

Recurrent networks, temporal convolutions, and attention models can consume
book-event histories directly. Limit-order-book research shows that deep models
can extract predictive structure across short horizons @zhang2019deeplob
@kolm2023. Their advantage depends heavily on event representation, horizon,
normalization, and realistic chronological testing. A model can learn symbol,
price-level, or feed artifacts that vanish after a market change.

For execution, use a sequence model when the sequence carries incremental value
over well-designed state summaries. Compare it with imbalance, microprice,
recent returns, intensity, and spread baselines. The additional latency and
operational complexity are part of the model cost.

== Joint and probabilistic forecasting

Liquidity variables move together. High volatility may coincide with wider
spreads, faster events, lower accessible depth, and higher volume. Separate
point forecasts lose this dependence. Let the future vector be

$
  Y_(t+h)
  = (M_(t,t+h), S_(t+h), D_(t+h), "RV"_(t,t+h), R_(t,t+h)).
$

Possible approaches include a joint likelihood, copula, multivariate
state-space model, multi-output neural network, or conditional scenario
resampling. The goal is not a universally accurate simulator. It is a coherent
distribution over the quantities used by the next decision.

A probabilistic forecast should be assessed with a proper scoring rule. For a
density forecast $p$ and realization $y$, log score is

$
  L_"log" (p, y) = -log(p(y)).
$

For quantile $hat(q)_alpha$, pinball loss is

$
  L_alpha (y, hat(q)_alpha)
  = (alpha - bold(1)_{y < hat(q)_alpha})
    (y - hat(q)_alpha).
$

Also check empirical coverage, sharpness, and calibration conditional on market
state. A forecast can be calibrated overall while understating tail risk in the
very regimes that drive execution losses.

== Validation without temporal leakage

Execution features have complicated timestamps. A quote can be timestamped by
the exchange, feed handler, research store, and strategy clock. A feature is
available only if the production system could have assembled it before the
action. “As-of joining” to the nearest quote can accidentally select a future
observation. End-of-day corrections and revised reference data are equally
dangerous.

Use chronological, preferably purged, validation. If labels span horizon $h$,
training observations whose label windows overlap a test origin leak future
returns into training. Overlapping labels also reduce effective sample size.
Keep parent orders, days, or contiguous blocks together where dependence
requires it.

Validation should answer five questions:

1. Does the model beat a strong horizon-specific baseline?
2. Are probabilities, quantiles, and intervals calibrated by important slice?
3. Does performance survive future periods, products, and stressed regimes?
4. Is the model stable under realistic latency and missing-data conditions?
5. Does the forecast improve a feasible execution decision after costs?

For short-term alpha, report directional accuracy only as a diagnostic. Economic
value depends on magnitude and action threshold. If action $a$ is chosen when
$hat(alpha)_t > c_t$, calibration around $c_t$ matters more than ranking many
observations far from the boundary.

#research[
  A high-frequency model can appear to have millions of test examples while
  relying on a few highly overlapping trading days. Report performance by day
  and regime, cluster uncertainty appropriately, and reserve genuinely future
  periods.
]

== Forecast value is a control comparison

Let policy $pi_f$ use forecast $f$, and let $pi_0$ use a simple baseline. Under
state trajectories $omega$, define realized execution loss

$
  J(pi; omega)
  = "cost"(pi; omega)
  + lambda "risk"(pi; omega)
  + "penalty"(pi; omega).
$

The forecast value is

$
  Delta J
  = E lr([J(pi_0; omega) - J(pi_f; omega)]).
$

Positive $Delta J$ means the forecast-informed policy improves the chosen
objective. Estimating it requires common scenarios in a simulator, a randomized
live experiment, or a credible off-policy design. Comparing forecast errors
alone cannot establish it.

The comparison should include turnover in actions. A noisy signal that makes the
algorithm repeatedly speed up and slow down may increase fees, information
leakage, and operational risk. Smoothing, hysteresis, minimum action duration,
and confidence thresholds can preserve most predictive value while reducing
unstable responses.

One useful diagnostic is *decision disagreement*. For candidate models $f_1$
and $f_2$, calculate

$
  P(pi_(f_1) (Z_t) != pi_(f_2) (Z_t)).
$

If two forecasts differ statistically but almost never change the action, the
more complex model has little control value. If they disagree only in sparse
states, those states deserve focused support and safety analysis.

== Monitoring forecast decay

Markets change because tick sizes, venues, participants, fee schedules, event
rates, and the execution policy itself change. Monitor three layers:

- *input drift*: distributions, missingness, staleness, and timestamp delays;
- *forecast behavior*: mean, dispersion, calibration, and action thresholds;
- *realized value*: cost, fills, risk, completion, and policy outcomes.

Population drift does not always imply model failure, and stable inputs do not
guarantee stable conditional relationships. When labels arrive with delay,
leading indicators such as feature validity, output range, and policy action mix
provide early warning. Retraining should follow a tested rule, not merely a
calendar. A refreshed model can be worse if the recent window is small or
unrepresentative.

Every production forecast needs an abstention or fallback rule. When book data
are stale, a contract is outside support, or uncertainty is unusually high, the
system should return to a simpler schedule or conservative state estimate. A
forecast that is accurate only when the pipeline is healthy is incomplete as a
trading component.

== Interview checks

#interview[
  *What is the difference between realized volatility and a volatility forecast
  in an execution model?* State the forecast origin and horizon, explain that
  realized variance is an ex-post observation, and connect forecast errors to
  inventory-weighted risk.
]

#interview[
  *Order-book imbalance predicts the next price move. How do you decide whether
  it should change an execution?* Compare the signal horizon with decision and
  latency horizons, calibrate magnitude, subtract action costs, condition on
  fills, and test the resulting policy.
]

#interview[
  *Why is a high fill-probability model insufficient for passive execution?*
  Explain fill-conditioned adverse selection, censoring by cancellation, queue
  position, and opportunity cost.
]

#interview[
  *A complex volume model lowers RMSE but increases completion failures. How is
  that possible?* Discuss tail calibration, remaining-volume uncertainty,
  asymmetric policy loss, and the difference between average forecast error and
  feasibility.
]

== Exercises

1. For a ten-bucket session, construct two volume-share distributions with the
   same mean curve but different covariance. Explain how they lead to different
   completion risk for a capped POV strategy.
2. Derive the location of the microprice relative to the midpoint as a function
   of imbalance $I_t$. Check the cases $I_t=-1$, $0$, and $1$.
3. Design labels for a multi-horizon alpha model at one second, ten seconds, one
   minute, and five minutes. Specify how you would prevent leakage from
   overlapping labels.
4. Write the expected value of a passive buy using fill probability, spread
   capture, fee or rebate, conditional markout, and non-fill cost. Identify which
   terms are action conditional.
5. Propose a state-space volume model and describe how an unexpectedly active
   first hour updates the remaining-day distribution.
6. Compare a boosted tree and a sequence model for predicting spread widening.
   Design statistical, latency, stability, and policy-value tests.
7. Construct a case where an alpha forecast improves RMSE but worsens execution
   cost because its errors occur near the action threshold.

== Where the book goes next

Chapters 7 and 8 provide estimated cost and state models. The next part of the
book turns those objects into policies. Later, Chapter 16 returns to the harder
question: once a new policy is proposed, how can we tell whether its apparent
improvement is caused by the policy rather than by the orders and markets on
which it happened to run?
