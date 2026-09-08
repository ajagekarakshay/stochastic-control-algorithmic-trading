#import "../style.typ": intuition, interview, research, takeaway, definition

= Experiments and Policy Evaluation <ch-policy-evaluation>

An execution policy can look better for reasons that have little to do with its
decisions. It may receive smaller orders, more liquid symbols, less urgent flow,
or quieter market days. Traders may choose it precisely when they expect it to
work well. A new version may be launched during a favorable regime. If we compare
raw average costs, all of these differences are credited to the algorithm.

Policy evaluation asks a counterfactual question: what would have happened to
the *same relevant population of orders* under the alternative policy? That
question is more demanding than validating a cost forecast. A predictive model
can estimate outcomes under behavior similar to the historical data. A policy
comparison must estimate outcomes under actions that were not taken.

This chapter begins with randomized execution experiments because randomization
makes the missing counterfactual most credible. It then develops observational
methods for situations in which assignment was not randomized. The methods are
not interchangeable repairs. Each relies on a different source of identifying
variation and fails in a different way.

== Define the policy and the estimand before looking at results

Let $A_i in {0, 1}$ indicate whether parent order $i$ is assigned to a new policy
or a baseline. Let $Y_i (1)$ and $Y_i (0)$ be its potential costs under the two
assignments. Using the side-adjusted convention of Chapter 3, lower $Y$ is
better. The sample average treatment effect is

$
  tau_"SATE"
  = (1 / n) sum_(i=1)^n (Y_i (1) - Y_i (0)).
$

We observe

$
  Y_i = A_i Y_i (1) + (1 - A_i) Y_i (0),
$

never both potential outcomes. A negative $tau_"SATE"$ means the new policy
reduces cost for the experimental sample.

Several choices are hidden inside this notation:

- Is $Y_i$ arrival shortfall, VWAP slippage, total implementation shortfall, or
  a risk-adjusted objective?
- Does the unit include all accepted orders or only completed orders?
- Is the treatment an algorithm family, a parameter setting, a model version,
  or an entire routing stack?
- Is the target the experimental sample, future eligible orders, or a specific
  client/product segment?
- Is assignment itself the treatment, or is actual compliance with the assigned
  behavior the treatment?

Write a policy contract that fixes eligibility, assignment, parameter ranges,
benchmark, outcome horizon, exclusions, and analysis before launching. A policy
name is not a treatment definition. If the “new algorithm” changes its impact
model, routing, urgency, and venue set midway through the experiment, the
observed treatment is a mixture of versions.

#definition([Intent-to-treat effect], [
  The intent-to-treat effect compares outcomes by randomized assignment,
  regardless of whether each order followed the assigned behavior exactly. It
  answers the operational question: what is the effect of deploying the policy
  assignment rule as it actually functions?
])

== The experimental unit must match the decision

Randomizing child orders within one parent program is rarely equivalent to
randomizing parent orders. Children share inventory, benchmark, market impact,
and feedback. The action taken for one child changes the state seen by the next.
Treating them as independent experimental units understates uncertainty and
creates contamination between policies.

The parent order is often the natural unit. Other possibilities include a
client-day, symbol-day, venue-time block, or entire session. The choice balances
three concerns:

1. *Interference.* Can treatment on one unit affect another unit's outcome?
2. *Operational consistency.* Can the system keep assignment stable over the
   relevant trajectory?
3. *Statistical efficiency.* How many effectively independent units remain?

If several parent orders trade the same symbol simultaneously, their impacts
interact. If a routing policy changes displayed liquidity or information
leakage, it may affect other orders. Randomization does not eliminate
interference; it only randomizes exposure to a design whose interference must be
defined or controlled.

#intuition[
  Ten thousand child fills from twenty parent orders do not create ten thousand
  independent policy comparisons. The policy acted on twenty connected
  trajectories.
]

== A simple randomized experiment

Suppose eligible parent orders are independently assigned with probability
$p$ to the new policy. Under correct randomization and stable treatment
definitions, an unbiased difference-in-means estimator is

$
  hat(tau)
  = (1 / n_1) sum_(i:A_i=1) Y_i
  - (1 / n_0) sum_(i:A_i=0) Y_i,
$

where $n_1 = sum_i A_i$ and $n_0 = n - n_1$. Randomization balances measured and
unmeasured pre-treatment covariates in expectation. A balance table is still
useful: it detects implementation errors and unlucky finite-sample imbalance,
but it should not become a sequence of hypothesis tests used to decide whether
randomization “worked.”

The outcome should include operational failures. If the new policy leaves
inventory unfilled, dropping that order rewards failure. Use total
implementation shortfall with a stated terminal mark, or define completion and
cost as co-primary outcomes. Safety metrics such as rejects, cancel rates,
limit-price breaches, and emergency completions belong in the analysis even if
they were not part of the optimization objective.

=== Stratified randomization

Execution costs vary strongly with variables known before assignment. Divide
orders into strata such as size bucket, liquidity group, side, benchmark, or
client mandate, then randomize within each stratum. Let stratum $g$ contain
$n_g$ orders and estimated contrast $hat(tau)_g$. The overall estimate is

$
  hat(tau)_"strat"
  = sum_(g=1)^G (n_g / n) hat(tau)_g.
$

Stratification improves precision when the variables predict outcomes and
protects against severe imbalance in small but important segments. Keep the
number of strata manageable; empty treatment cells make the contrast undefined.
Regression adjustment using pre-treatment covariates can further improve
precision, but the analysis should respect the randomization design.

=== Paired and matched designs

Exact pairing of two simultaneous orders is usually impossible, yet useful
blocking can be constructed from orders with similar pre-trade size, symbol
liquidity, benchmark, urgency, and market state. Randomize within the block and
analyze block differences. Never match on realized cost, realized participation,
or other post-assignment variables.

== Switchback designs and carryover

Sometimes randomizing individual orders is operationally difficult or causes
cross-policy interference. A switchback experiment assigns a policy to time
blocks, alternates according to a randomized schedule, and compares outcomes
across blocks. This is useful for venue routing or system-wide logic, but market
conditions also change across time.

Let $A_b$ be the assignment for block $b$ and $Y_b$ an aggregate outcome. If
treatment effects persist for $L$ blocks, the potential outcome may depend on
recent assignments:

$
  Y_b (A_b, A_(b-1), ..., A_(b-L)).
$

Ignoring carryover biases the comparison. Impact decay, queue position,
information leakage, and shared venue state can all outlast the block in which
the action occurred. Designs may use washout periods, longer blocks, or an
explicit exposure mapping. The optimal block length trades carryover against the
loss of independent switches; formal switchback designs make this tradeoff
explicit @bojinov2020.

Time-block assignment should be balanced over intraday seasonality, weekdays,
events, and rolls. Alternating A/B/A/B deterministically is vulnerable to any
periodic pattern aligned with the alternation. Randomize the sequence within
valid operational constraints.

== Precision, clustering, and minimum detectable effects

An experiment can be unbiased yet too noisy to answer the business question.
For independent equal-sized groups with outcome variance $sigma_Y^2$, the
approximate standard error of the difference in means is

$
  "SE"(hat(tau))
  approx sqrt(2 sigma_Y^2 / n_"arm").
$

Heavy tails and clustering make this formula optimistic. Estimate design inputs
from historical data using the intended unit and outcome definition. If orders
are clustered by day, symbol-day, or client, simulate the proposed assignment at
that level or use a cluster-aware variance estimate.

Power should be expressed in economic units. A one-basis-point improvement may
be economically large for substantial notional; a statistically detectable
0.05-basis-point change may not justify operational complexity. Specify the
minimum economically meaningful effect, baseline variance, expected eligibility
rate, allocation ratio, clustering, and experiment duration.

Repeatedly checking the result and stopping when significance appears inflates
false positives. Use a fixed horizon, a preplanned group-sequential design, or
always-valid inference. Safety monitoring may stop an experiment immediately,
but safety rules should be distinct from opportunistic performance peeking.

== Outcome construction and benchmark risk

The experiment inherits every measurement choice from TCA. Arrival shortfall
captures the total price change after release but includes market movement and
alpha. VWAP slippage is benchmark-relative and can reward tracking even when the
benchmark moves adversely. Close slippage depends on the relation between order
horizon and close. Report a primary outcome tied to the policy's mandate, with
secondary decompositions that explain the mechanism.

If the policy can change completion time, comparing only the average price of
filled shares creates truncation. Let requested quantity be $Q_i$, filled
quantity $Q_i^f$, and residual $Q_i^u = Q_i - Q_i^f$. A complete economic
outcome can be written

$
  Y_i^"total"
  = (Q_i^f / Q_i) Y_i^"fills"
  + (Q_i^u / Q_i) Y_i^"residual",
$

where the residual is valued at a predeclared terminal price and includes any
explicit non-completion penalty. Changing the terminal mark after seeing the
results changes the estimand.

Outcomes also have horizons. A passive policy may improve fill-price spread
capture while worsening five-minute markouts. An aggressive policy may incur
higher immediate cost but reduce adverse movement before completion. Present the
trajectory of outcomes without cherry-picking the horizon at which one version
looks best.

== Noncompliance and treatment versions

An order assigned to 10% POV may realize 7% because volume arrives differently,
a cap binds, or a trader intervenes. The intent-to-treat estimate remains a
valid effect of assignment. A per-protocol comparison using realized
participation reintroduces selection.

If assignment $Z_i$ changes actual treatment $A_i$, an instrumental-variables
estimand may be possible under additional assumptions. In the simplest binary
case, the Wald ratio is

$
  hat(tau)_"LATE"
  = (bar(Y)_(Z=1) - bar(Y)_(Z=0))
    / (bar(A)_(Z=1) - bar(A)_(Z=0)).
$

It estimates a local effect for units whose treatment changes with assignment,
not a universal effect. Exclusion, monotonicity, and a nonzero first stage are
substantive claims. In many execution experiments, reporting intent-to-treat
alongside compliance and mechanism metrics is clearer than forcing a
per-protocol causal number.

== Observational policy comparisons

When traders or upstream systems choose the policy, raw comparisons are
confounded. Let $X_i$ contain pre-treatment variables influencing both policy
selection and outcome, and define the propensity score

$
  e(x) = P(A_i = 1 | X_i = x).
$

Under consistency, conditional exchangeability

$
  (Y_i (0), Y_i (1)) perp A_i | X_i,
$

and overlap $0 < e(X_i) < 1$, the average treatment effect is identified.
Propensity scores balance the distribution of measured covariates under these
assumptions @rosenbaum1983. They do not balance latent urgency or undocumented
trader choice.

=== Common support comes before adjustment

Plot assignment probabilities and important covariates by policy. If the new
algorithm handles only liquid equities and the baseline handles the illiquid
tail, no model observes the missing comparison. Trimming to common support
changes the population but can make the estimate defensible. Extrapolating a
flexible outcome model across empty support disguises assumption as data.

A useful overlap diagnostic is effective sample size for nonnegative weights
$w_i$:

$
  n_"eff" = (sum_i w_i)^2 / sum_i w_i^2.
$

A nominal sample of 100,000 orders can have a tiny effective sample if a few
rare observations receive enormous inverse-probability weights.

=== Outcome regression

Fit

$
  m_a (x) = E lr([Y_i | A_i = a, X_i = x])
$

and average predicted contrasts:

$
  hat(tau)_"OR"
  = (1 / n) sum_(i=1)^n
    (hat(m)_1 (X_i) - hat(m)_0 (X_i)).
$

This estimator relies on correct outcome extrapolation over the target
population. Validate each treatment surface within observed support; a low
pooled RMSE can conceal poor counterfactual regions.

=== Inverse-propensity weighting

With estimated propensity $hat(e)_i = hat(e)(X_i)$, an inverse-probability
estimator is

$
  hat(tau)_"IPW"
  = (1 / n) sum_(i=1)^n
    (A_i Y_i / hat(e)_i
    - (1 - A_i) Y_i / (1 - hat(e)_i)).
$

Stabilized or normalized weights can reduce finite-sample variance. Truncating
extreme weights trades variance for bias and must be reported. After weighting,
check covariate balance; predictive accuracy of the propensity model is not the
goal.

=== Doubly robust estimation

Combining outcome and propensity models gives

$
  hat(tau)_"DR"
  = (1 / n) sum_(i=1)^n lr(
      hat(m)_1 (X_i) - hat(m)_0 (X_i)
      + A_i (Y_i - hat(m)_1 (X_i)) / hat(e)_i
      - (1 - A_i) (Y_i - hat(m)_0 (X_i)) / (1 - hat(e)_i)
    ).
$

Under regularity conditions, this estimator is consistent if either the outcome
model or propensity model is correctly specified, though not if both fail.
Cross-fitting allows flexible nuisance models while reducing overfit bias.
Doubly robust does not mean “robust to unmeasured confounding,” and it does not
repair lack of overlap @dudik2011.

#research[
  A sophisticated causal estimator applied to an implausible assignment story
  is still an implausible study. Write down who or what selected the algorithm,
  what information they used, and which of that information appears in the data.
]

== Time-varying policies and feedback

An adaptive algorithm takes a sequence of actions $A_0, ..., A_T$. Market state
$L_t$ affects $A_t$, while earlier actions affect later $L_t$. Conditioning on
$L_t$ in an ordinary regression can block part of the treatment effect or create
bias because it is both a confounder for later actions and a consequence of
earlier actions.

Under sequential exchangeability, the probability of the observed action
history is

$
  product_(t=0)^T
  P(A_t | bar(A)_(t-1), bar(L)_t),
$

where bars denote history. Marginal structural models and sequential
importance-weighting methods reweight trajectories using these probabilities.
The assumptions are demanding: every influential time-varying input to the
policy must be logged with correct timing, and target actions need support under
the behavior policy.

For a deterministic target policy $pi$, trajectory importance weights can become
zero or enormous. In execution, small action differences compound through
inventory and state, making purely offline evaluation fragile. Use randomized
exploration within safe bounds, a validated action-conditional simulator, or a
staged live experiment whenever possible. Chapter 17 treats this problem in the
language of reinforcement learning.

== Heterogeneous effects without storytelling

The average effect can hide where a policy helps or harms. Define a conditional
effect

$
  tau(x) = E lr([Y_i (1) - Y_i (0) | X_i = x]).
$

Relevant dimensions include size, liquidity, spread, volatility, urgency,
benchmark, product, and time of day. Subgroup analysis is useful when it follows
predeclared economic hypotheses or is confirmed in new data. Searching hundreds
of slices and reporting the best one manufactures discoveries.

Use shrinkage, honest sample splitting, or causal forests to explore
heterogeneity, then validate candidate segments prospectively. Report sample
size, overlap, uncertainty, and absolute outcomes for each segment. A policy can
show a large relative improvement only because the baseline behaves badly in a
small unstable group.

Heterogeneity can lead to a targeting rule. If $hat(tau)(x) < 0$ predicts benefit
from the new policy, assigning only those orders is a *new policy* that must be
evaluated on data not used to discover the rule.

== Statistical significance, economic significance, and risk

A confidence interval describes uncertainty under the assumed design and
estimator. It does not measure model risk, data errors, or the cost of a rare
failure. Report the treatment contrast in basis points and dollars, but also
include:

- completion and deadline breaches;
- tail cost and expected shortfall;
- dispersion across days, products, and clients;
- action rates, participation, passivity, and routing changes;
- operational rejects and fallback use; and
- capacity and market-footprint effects.

For order weights $w_i$ representing the target population, an economically
weighted effect is

$
  tau_w
  = E lr([w_i (Y_i (1) - Y_i (0))]) / E lr([w_i]).
$

Order-weighted, share-weighted, and dollar-weighted effects answer different
questions. Declare the primary one. A model that saves many tiny orders but
harms the largest orders can look favorable under equal-order averaging.

Multiple primary outcomes or segments require multiplicity control or a clear
hierarchy. Do not hide a failed arrival-cost result behind a favorable secondary
markout selected after the fact.

== From shadow mode to staged rollout

Evaluation begins before the policy sends live orders.

1. *Replay and unit tests.* Confirm feature timing, action constraints, and
   deterministic behavior on recorded cases.
2. *Shadow mode.* Generate decisions without acting; compare action
   distributions, latency, missing features, and support with the baseline.
3. *Limited randomized pilot.* Use small eligible flow and conservative action
   bounds.
4. *Stratified expansion.* Increase exposure only after safety and outcome
   criteria pass in important segments.
5. *Production monitoring.* Continue randomized holdouts or periodic controls
   where feasible because the market and policy population change.

Predeclare promotion, pause, and rollback criteria. A staged rollout is not an
experiment if assignment is quietly overridden whenever an outcome looks bad
and those interventions are omitted. Log eligibility, assignment, actual
actions, overrides, model versions, and fallback reasons.

Guardrail metrics should have faster feedback than the primary economic label.
For example, rejects, excessive participation, stale features, and missed
completion can trigger an immediate rollback before enough orders accumulate to
estimate shortfall precisely. The fallback should be exercised before launch,
not invented during an incident.

#takeaway[
  The credible unit of progress is not “the new model predicts better.” It is
  “the new policy improves a predeclared economic outcome for an identified
  population, within uncertainty and safety limits.”
]

== A practical analysis report

A concise policy-evaluation report should let a skeptical reader reconstruct the
claim. Include:

- policy versions, eligibility, assignment mechanism, and experiment dates;
- a diagram or description of the unit, interference, and compliance;
- primary and secondary estimands with sign conventions and weights;
- sample flow from eligibility through final analysis;
- pre-treatment balance and common-support diagnostics;
- effect estimates, confidence intervals, and cluster definition;
- results by predeclared size, liquidity, and regime slices;
- completion, tail, operational, and mechanism outcomes;
- deviations from the analysis plan and sensitivity analyses; and
- the deployment decision, monitoring plan, and rollback thresholds.

The report should distinguish an absence of evidence from evidence of no
economically meaningful effect. If the interval is wide, the conclusion may be
that the experiment was inconclusive, not that the policies are equivalent.

== Interview checks

#interview[
  *A new algorithm has lower average shortfall in production. Why is that not
  enough?* Discuss selection into algorithms, order mix, regimes, completion,
  benchmark choice, interference, and the missing counterfactual.
]

#interview[
  *What should be randomized: child orders or parent orders?* Connect the unit to
  inventory, feedback, shared impact, operational consistency, and the level at
  which uncertainty is estimated.
]

#interview[
  *What does doubly robust mean?* State the outcome and propensity components,
  the either-model consistency property under assumptions, and what it does not
  solve: unmeasured confounding or absent support.
]

#interview[
  *Why can filtering to completed orders reverse a policy comparison?* Explain
  policy-dependent completion, opportunity cost, informative censoring, and the
  need for a total order outcome.
]

== Exercises

1. Design a parent-order randomized experiment comparing 10% and 20% intended
   POV. Specify eligibility, stratification, outcome, compliance metrics,
   clustering, and safety rules.
2. Construct an example in which child-level standard errors are one tenth of
   parent-level standard errors even though the point estimate is unchanged.
3. Derive the inverse-propensity estimator for a binary policy and explain what
   happens as $hat(e)(X_i) -> 0$ for treated observations.
4. Draw a causal graph for trader-selected algorithms using urgency, alpha,
   size, liquidity, policy, completion, and cost. Decide which variables belong
   in adjustment and which are post-treatment.
5. Propose a switchback design for venue-routing logic. Choose block and washout
   lengths and explain the carryover mechanisms they address.
6. Create a policy result that is statistically significant but economically
   unattractive after tail losses and implementation complexity are included.
7. Define a heterogeneous targeting rule from an experiment, then describe the
   separate data needed to evaluate that rule without selection bias.

== Where the book goes next

Policy evaluation closes the loop between an estimated model and observed
trading outcomes. The remaining chapters extend the control framework to learned
sequential policies and other trading problems. Chapter 24 later returns to the
organizational loop: how a research question, dataset, model, experiment, and
production service remain traceable as each evolves.
