#import "../style.typ": intuition, interview, research, takeaway, definition

= Statistical Modeling as a Research Process <ch-modeling-research>

A model is useful when it sharpens a question about the world. The fitted
algorithm is only one step in that process. In practice, much of the difficult
work happens earlier: deciding what the phenomenon actually is, what one
observation should represent, which measurements carry information about the
phenomenon, what information would have been available at decision time, and
what sort of error would matter if the model were wrong.

This distinction is easy to miss because modern software makes fitting models
cheap. A few lines of code can produce a regression, a boosted tree, or a neural
network. The result may even have an impressive test score. None of that tells
us whether the target was well defined, whether the sample represents the
deployment population, whether the validation exercise mimics the future, or
whether the model has learned a stable relationship rather than an accidental
regularity.

The useful mental shift is therefore

$
  "phenomenon"
  arrow.r
  "data-generating story"
  arrow.r
  "measurement"
  arrow.r
  "estimand or target"
  arrow.r
  "validation"
  arrow.r
  "model"
  arrow.r
  "diagnosis"
  arrow.r
  "next experiment".
$

The fitting routine belongs in the middle, not at the beginning.

#intuition[
  A good modeler does not ask, “Which algorithm should I try on this table?”
  The first question is, “What process could have produced this table, and
  which parts of that process am I trying to learn?” Once that question is
  precise, model choice becomes much easier.
]

== Start with the phenomenon, not the columns

Suppose we observe that some execution programs are much more expensive than
others. The raw phenomenon is “execution cost varies.” That statement is too
vague to model.

We first have to decide what we mean by cost. Arrival shortfall and VWAP
slippage are not interchangeable labels for the same quantity. They compare the
execution with different counterfactuals. We also have to decide whether an
observation is a fill, a child order, a parent order, a symbol-day, or a short
market interval. A model of fill-level price concession answers a different
question from a model of parent-order implementation shortfall.

A useful problem statement therefore has at least five parts:

1. *Response.* What numerical quantity represents the phenomenon?
2. *Population.* What collection of cases do we care about?
3. *Unit of observation.* What is one statistically meaningful example?
4. *Information set.* What can be known when the prediction or decision is made?
5. *Use.* Is the output for description, prediction, causal comparison, or
   control?

For a pre-trade execution-cost model, a concrete statement could be:

> For parent orders accepted by the execution engine, estimate the conditional
> distribution of arrival shortfall using only information known at arrival, so
> that an optimizer can compare candidate participation schedules.

That sentence already rules out many modeling mistakes. Realized market volume
cannot quietly appear as a pre-trade feature. Child fills cannot be treated as
independent orders. A model that predicts only the unconditional average is not
enough if the optimizer needs state-dependent marginal costs.

#definition[
  The *estimand* is the population quantity we want to learn. The *estimator* is
  the rule we apply to data to estimate it. A machine-learning model is often
  part of the estimator; it is not the estimand itself.
]

== Build a data-generating story before fitting anything

Before writing a formula, sketch a plausible story for how the outcome arises.
The story need not be literally true. Its purpose is to force important
variables and dependencies into the open.

A generic representation is

$
  Y = f(X, Z, A, U) + epsilon,
$

where

- $Y$ is the outcome we observe;
- $X$ contains measured state variables available to the model;
- $Z$ contains latent or poorly measured state;
- $A$ is an action or policy choice that may itself depend on the state;
- $U$ represents broader regime or population effects; and
- $epsilon$ collects idiosyncratic variation not explained by the model.

For execution cost, $X$ might include requested size, spread, volatility,
forecast volume, depth, imbalance, and time of day. $Z$ might include latent
trader urgency or unrecorded information about the order. $A$ might be intended
participation or an algo choice. $U$ might represent a volatile macro day, a
futures roll regime, or a change in market structure.

This picture immediately generates research questions.

If urgency affects both chosen speed and subsequent price movement, then the
coefficient on realized speed is not automatically a causal effect of speed.
If volatility is measured with a noisy historical estimator, attenuation and
regime mismatch may obscure its role. If the algo adapts participation after
observing adverse price movement, realized participation is partly an outcome
of the path rather than a clean pre-treatment variable.

The point is not to draw a perfect causal graph before every regression. The
point is to develop the habit of asking what had to happen in the world for the
recorded row to exist.

#research[
  When a surprising coefficient appears, do not begin with an optimizer or a
  different model family. First revisit the data-generating story. A surprising
  sign can come from a real economic effect, but it can also come from selection,
  an omitted state variable, measurement error, conditioning on a post-treatment
  quantity, or a changing population.
]

== Separate prediction, explanation, causal estimation, and control

Many modeling arguments become confused because the purpose of the model is
never stated.

=== Prediction

Prediction asks

$
  "How accurately can we estimate " Y " from information available in " X "?"
$

A variable can be valuable for prediction even when it has no causal
interpretation. A highly correlated proxy may be perfectly useful if it is
stable, available in production, and does not leak the future.

=== Explanation

Explanation asks how variation in the response is associated with measured
features under a particular statistical model. We may examine coefficients,
partial relationships, variance decompositions, residual structure, and
interactions. The conclusions are conditional on the model and sample.

Explanation is stronger than merely obtaining predictions, but weaker than
causal inference. Saying that spread has incremental explanatory power for
slippage is not the same as saying that mechanically reducing spread would
produce the coefficient-implied reduction in slippage.

=== Causal estimation

Causal analysis asks what would happen under an intervention:

$
  E[Y(a') - Y(a)].
$

This requires assumptions about treatment assignment, confounding, overlap,
interference, and timing that predictive accuracy does not provide.

=== Control

Control asks which action should be taken. A model can have modest prediction
error and still be poor for control if its local gradients are wrong in the
region where the optimizer makes decisions. Conversely, a model can have a
slightly worse global score but produce much more stable actions because it
respects shape and support.

These goals can share the same dataset while requiring different validation and
interpretation. Never let a single metric silently move the analysis from one
goal to another.

== Decide what one observation means

A row in a dataframe is not automatically an independent statistical
observation.

Suppose a parent order creates hundreds of child fills. Those fills share the
same parent intent, the same market path, the same benchmark, and an adaptive
policy. Randomly splitting fills across training and test sets allows
information from the same economic episode to appear on both sides.

The right unit of observation follows the question. If the target is parent
order shortfall, the parent order is usually the natural unit. If the target is
one-second quote response, the unit may be an event-time interval, but serial
dependence must then be handled explicitly.

Ask four questions:

- What event makes a new observation genuinely new?
- Which rows share a latent cause?
- Which rows share future label information?
- At what level would the model be deployed or the intervention be assigned?

The answers determine splitting, weighting, standard errors, and often the
definition of the target itself.

== Construct a data contract

Every modeling table should come with a timing and provenance contract. For
each variable, record when the underlying event occurred, when the value became
knowable, and whether it was later revised.

#table(
  columns: (1.05fr, 1.35fr, 1.6fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Question*], [*Why it matters*], [*Typical failure*],
  [When was the feature knowable?], [Defines the live information set], [Using end-of-day volume in a pre-trade model],
  [When is the label complete?], [Defines embargo and overlap], [Adjacent samples share the same future return window],
  [Was the value revised later?], [Research may see cleaner history than production], [Using corrected reference data unavailable live],
  [What generated missingness?], [Missingness can be informative or selective], [Dropping difficult orders because fields are absent],
  [What filtering created this table?], [Filters define the population], [Removing incomplete or volatile orders and then claiming generality],
)

This discipline prevents a common form of research optimism: constructing a
beautiful historical dataset that could never have existed at the time of
decision.

== Treat the label as a measurement, not as truth

Supervised learning usually writes

$
  (X_i, Y_i)
$

as though $Y_i$ were ground truth. In many financial problems the label is
itself an estimator or noisy proxy.

Arrival slippage contains market movement unrelated to the order. Realized
volatility depends on sampling frequency and microstructure noise. A label such
as “temporary impact” may depend on an arbitrary markout horizon. A trader's
urgency label may be an imperfect classification extracted from metadata.

A useful decomposition is

$
  Y_"observed" = Y_"phenomenon" + eta_"measurement".
$

More rows do not necessarily eliminate measurement error. If the noise is
irreducible at the individual-observation level, the attainable prediction
accuracy may be bounded even with enormous data.

This matters when interpreting a plateau in $R^2$. A low $R^2$ does not by
itself imply a poor model. It may indicate that the response is intrinsically
noisy at the chosen horizon. The right question is whether the remaining error
contains stable, actionable structure.

== Design features from mechanisms

Feature engineering should begin with mechanisms, not with a search over every
available column.

For execution cost, a first mechanism list might be:

- *scale:* order size relative to available liquidity;
- *speed:* intended participation or urgency;
- *liquidity:* spread, depth, turnover, tick regime;
- *risk:* volatility and jump intensity;
- *state:* order-flow imbalance and recent market movement;
- *clock:* time of day and proximity to open, close, or roll;
- *identity:* product, venue, client objective, or algo version.

For each mechanism, ask what observable quantity is a defensible proxy. Then
ask how noisy that proxy is and whether it is known at the right time.

This approach is more useful than adding features because they happen to be
present. It also makes missing-variable reasoning easier. If residuals are
systematically high around futures rolls, the relevant question becomes, “What
part of the liquidity-migration mechanism is absent from the feature set?” rather
than, “Which additional technical indicator should I generate?”

=== Raw variables, normalized variables, and invariances

Many domains contain obvious changes of scale. A $100000$ order has different
meaning in a highly liquid stock and a thin contract. Ratios such as

$
  x = Q/"ADV"
$

encode a hypothesis that market response depends more on relative size than
absolute size.

Normalization is therefore part of the model. Dividing cost by volatility,
spread, depth, or notional asserts a form of invariance. Test that assertion
rather than treating normalization as harmless preprocessing.

A good normalized feature should make relationships more stable across the
population. If the fitted size curve still shifts strongly by liquidity bucket,
the normalization has not removed the relevant heterogeneity.

== Establish the validation design before model selection

The validation scheme determines what “generalization” means.

A random row split estimates performance on new rows drawn from approximately
the same mixture as the historical sample. That may be reasonable for some
static problems. It is often weak evidence for a trading model that will be
deployed in the future.

Common validation questions include:

- Can the model generalize to a later period?
- Can it generalize to unseen symbols?
- Can it generalize to a new client or algo version?
- Can it survive a volatility regime outside the center of the training sample?
- Can it interpolate within the historical domain but avoid unstable
  extrapolation?

These questions suggest different holdouts.

For a time-dependent problem, a useful sequence is

$
  "train past"
  arrow.r
  "tune on later period"
  arrow.r
  "evaluate on untouched future".
$

Rolling or expanding-window validation reveals whether performance is stable.
Group holdouts reveal whether apparent accuracy comes from memorizing entity
effects. Purging or embargoing may be needed when neighboring examples share
future outcomes.

#takeaway[
  Validation is not an administrative step after modeling. It is an explicit
  statement of the future you expect the model to face.
]

== Start with a model ladder

A strong modeling workflow usually begins with models that are intentionally
too simple.

For a continuous response, a useful ladder is:

$
  "mean"
  arrow.r
  "one-feature model"
  arrow.r
  "linear model"
  arrow.r
  "regularized linear model"
  arrow.r
  "splines or GAM"
  arrow.r
  "interaction model"
  arrow.r
  "flexible ML".
$

The purpose is not nostalgia for simple models. Each rung answers a different
question.

The unconditional mean tells us how much error exists before using any
features. A one-feature model shows whether a dominant mechanism carries signal.
A multivariate linear model tells us how much can be captured by additive first-
order structure. A spline model tests whether smooth nonlinearity matters. A
tree ensemble tests whether richer interactions and partitions provide
incremental value.

Suppose an out-of-sample sequence looks like this:

#table(
  columns: (1.6fr, 0.7fr, 2.1fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Model*], [*$R^2$*], [*What we learn*],
  [Mean baseline], [0.00], [Reference uncertainty],
  [Relative size only], [0.17], [Scale explains meaningful variation],
  [Size + participation], [0.27], [Trading speed adds information],
  [Add spread + volatility], [0.39], [Market state matters substantially],
  [Smooth additive model], [0.44], [Nonlinear marginal effects matter],
  [Boosted trees], [0.46], [Remaining high-order interactions add relatively little],
)

The final number, $0.46$, is useful. The path to it is more informative. It
suggests that much of the predictable structure is already captured by a small
set of economic mechanisms and smooth nonlinearities. That is knowledge about
the phenomenon, not merely a ranking of algorithms.

== Use linear models as microscopes

Linear regression is valuable even when the final production model is not
linear. It provides a controlled environment for examining incremental
information, correlation, noise, instability, and specification error.

Write

$
  Y = beta_0 + beta^T X + epsilon.
$

The fitted coefficient $hat(beta)_j$ describes how the fitted conditional mean
changes with $X_j$ while the other included variables are held fixed. The phrase
“included variables” is doing a great deal of work. The coefficient can change
when a correlated feature is added because the conditioning question changed.

=== Interpreting $R^2$

For squared-error regression,

$
  R^2 = 1 - "SSE"/"SST".
$

It measures improvement over predicting the sample mean under that loss. An
$R^2$ of $0.40$ says that the fitted predictions remove 40% of the squared
variation relative to the mean baseline in the evaluated sample.

It does *not* say that the features causally generate 40% of the phenomenon.

More useful for research is often the incremental change

$
  Delta R^2 = R^2(X, Z) - R^2(X),
$

evaluated out of sample. If adding volatility to a model with size and spread
raises out-of-sample $R^2$ materially, volatility contains incremental
predictive information beyond those variables.

With correlated predictors, the total explained variation cannot generally be
assigned uniquely to individual features. Spread, depth, and volatility can
carry overlapping information. “Spread explains 12% of cost” is therefore
usually too strong unless a particular variance-decomposition convention has
been specified.

=== Coefficient stability is evidence

Fit the same regression across time windows, liquidity buckets, symbols, and
regimes. If a coefficient changes sign repeatedly while predictions remain
stable, the model may be using correlated variables interchangeably. The
predictive surface can be identified more strongly than the individual
coefficients.

That distinction is crucial. Stable predictions do not guarantee stable
interpretation.

== Bias, variance, and irreducible noise as practical diagnoses

The classical decomposition is easiest to use when treated as a diagnostic
framework rather than an equation to memorize.

For a learned predictor $hat(f)$ evaluated at $x$,

$
  E[(Y-hat(f)(x))^2]
  =
  "noise"
  + "bias"^2
  + "variance".
$

The terms are conceptual:

- *Noise* is outcome variation that cannot be predicted from the available
  information.
- *Bias* is systematic error caused by restrictions or misspecification in the
  modeling procedure.
- *Variance* is sensitivity of the fitted model to the particular training
  sample.

The practical question is: which term appears to be limiting us?

=== Signs of high bias

- Training error is poor and validation error is also poor.
- Residuals show systematic curvature or regime-dependent mean error.
- A simple model repeatedly misses the same regions of feature space.
- Adding genuinely informative mechanisms produces large gains.
- A more flexible but still well-validated model improves both train and test
  performance.

Possible responses are to improve measurements, add missing mechanisms, change
the functional form, allow interactions, or model separate regimes.

=== Signs of high variance

- Training performance is excellent but validation performance is much worse.
- Coefficients or feature importances move dramatically across resamples.
- Small changes in the training window produce large prediction changes.
- Removing weak features or increasing regularization improves validation.
- Performance improves noticeably as the training sample grows.

Possible responses are more data, stronger regularization, fewer degrees of
freedom, partial pooling, more stable features, or a simpler model family.

=== Signs that noise is dominant

- Train and validation errors have largely converged.
- Additional flexibility stops producing robust gains.
- Repeated measurements of similar states still show wide outcome dispersion.
- Model errors appear conditionally centered and largely structureless.
- Independent estimates of the label itself are noisy.

In that situation, collecting more of the *same* data may tighten aggregate
estimates but will not make individual outcomes highly predictable. Improvement
may require better measurements, a different prediction horizon, a more
predictable target, or richer state information.

== Learning curves answer “more data or a better model?”

Plot training and validation performance as a function of training-set size.

If validation performance continues improving while the training-validation gap
shrinks slowly, more data may be valuable. If both curves plateau at a poor
level, simply multiplying the sample size is less promising.

The exact shape depends on the model and problem, but the question is powerful:
is the model unable to learn the available structure, or have we already learned
most of what the current representation contains?

For financial data, “more data” also needs qualification. Ten years of history
is not automatically ten times as informative as one year. Old observations may
come from different tick sizes, market participants, routing rules, volatility
regimes, and execution logic. Effective sample size depends on relevance and
dependence, not only row count.

#intuition[
  More observations reduce estimation uncertainty only to the extent that they
  are informative about the deployment distribution. A million stale or highly
  dependent rows can be less useful than a much smaller sample from the current
  regime.
]

== Residuals are the researcher's map

A scalar test score says how much error remains. Residuals tell us where it
remains.

Let

$
  e_i = y_i - hat(y)_i.
$

The first diagnostic is not merely a histogram of $e_i$. Condition residuals on
variables that represent mechanisms:

- size and participation;
- spread, depth, volatility, and volume;
- recent return and order-flow imbalance;
- time of day;
- symbol or liquidity bucket;
- side;
- client or strategy;
- futures roll proximity;
- market regime.

Then ask whether

$
  E[e | X_j]
$

is approximately zero across the deployment range.

Different residual patterns suggest different next experiments.

#table(
  columns: (1.45fr, 1.7fr, 1.8fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Residual pattern*], [*Possible explanation*], [*Next investigation*],
  [Curvature versus size], [Wrong functional form or scaling], [Splines, log scale, alternative denominator],
  [Bias only in high volatility], [Missing interaction or regime], [Size × volatility, regime-specific calibration],
  [Bias near futures roll], [Liquidity migration not represented], [Days-to-roll, contract depth, front/next activity],
  [Error variance rises with size], [Heteroskedastic response], [Weighted loss, variance model, quantile analysis],
  [Mean error centered but right tail poor], [Conditional distribution misspecified], [Quantile or distributional model],
  [Good random split, poor future split], [Temporal shift or leakage], [Drift analysis, retraining window, feature timing],
  [One symbol dominates errors], [Entity heterogeneity or data issue], [Hierarchical effect, data audit, support check],
)

A residual plot is therefore not cosmetic. It is a mechanism-discovery tool.

== Escalate complexity only in response to evidence

When a linear model fails, the next question should be *how* it fails.

If residuals are smoothly curved against one variable, use a transformation or
spline before reaching for an opaque model. If the effect of size changes with
volatility, add an interaction. If several effects vary smoothly, a generalized
additive model may capture most of the structure while preserving
interpretability.

Flexible tree models become compelling when the data support many thresholds
and interactions that are difficult to specify manually. Neural networks become
compelling when the representation itself must be learned from rich inputs such
as sequences, order-book states, images, or text, or when scale makes learned
representations advantageous.

The hierarchy is not “simple models are good and complex models are bad.” The
principle is:

> Increase model capacity because diagnostics reveal structure the current
> model cannot represent.

This makes each increase in complexity an empirical response rather than a
default preference.

== Think about features in groups, not one at a time

Real predictors are correlated. Removing one feature can make another appear
more important because the two carry overlapping information.

A useful feature analysis operates at several levels:

- *mechanism group:* liquidity, volatility, order scale, flow state;
- *individual variable:* spread, depth, ADV, realized volatility;
- *representation:* raw value, log value, percentile, normalized ratio;
- *interaction:* size × liquidity, participation × volatility.

Compare models by removing or adding coherent groups. Evaluate the change out
of sample.

If deleting an entire mechanism group barely changes performance, either the
group adds little information or its information is already duplicated
elsewhere. If deleting one of twenty correlated variables has no effect, that
does not imply the underlying mechanism is irrelevant.

Regularization is especially useful when many variables describe overlapping
aspects of the same state. Ridge stabilizes the prediction surface by shrinking
correlated coefficients. Lasso can produce sparse representations, although
which member of a correlated group survives can be unstable. Stability across
resamples is often more informative than one selected feature list.

== Know when to add data, remove features, or change the target

A common modeling question is whether poor performance calls for more data or a
different model. There is no universal rule, but diagnostics narrow the choice.

#table(
  columns: (1.5fr, 1.8fr, 1.7fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Evidence*], [*Likely bottleneck*], [*Reasonable response*],
  [Large train-test gap that shrinks with sample size], [Estimation variance], [Collect relevant data; regularize],
  [Train and test both weak; structured residuals], [Bias or missing state], [Add mechanisms or change functional form],
  [Train and test both weak; residuals mostly structureless], [Label noise or missing information], [Improve measurement or redefine target],
  [Performance worsens after many weak features], [Variance / spurious correlations], [Remove, group, or regularize features],
  [Old data hurt recent validation], [Distribution shift], [Shorter or weighted history; regime features],
  [Rare region has large error], [Lack of support], [Targeted data collection or explicit abstention],
  [Average score good, important tail poor], [Objective mismatch], [Tail-aware loss or distributional target],
)

The phrase *targeted data collection* matters. If errors are concentrated in
large illiquid orders, collecting millions of additional small liquid orders is
unlikely to solve the problem. Data should be added where uncertainty or
decision sensitivity is high.

== Distinguish interpolation from extrapolation

Machine-learning models are most trustworthy where the training data provide
support. A prediction for a 20% ADV order is not simply a noisier version of a
prediction for a 1% ADV order if the training sample contains almost no orders
above 3% ADV. It may be an extrapolation driven mostly by model assumptions.

Support diagnostics should therefore accompany prediction:

- distance to the training distribution;
- local sample size or density;
- range of each important variable;
- presence of comparable combinations of features;
- regime and entity representation.

This is especially important for control because an optimizer actively searches
for actions. If the fitted cost model looks artificially cheap in a sparse
region, the optimizer may deliberately steer into that region.

A model used for optimization should be audited over the *action domain*, not
only over historically observed actions.

== Uncertainty is part of the output

A point prediction hides two different uncertainties:

1. uncertainty about the conditional outcome itself; and
2. uncertainty about the estimated model.

The first is aleatoric or outcome uncertainty. The second is epistemic or
estimation uncertainty.

For a trading decision, both can matter. Two schedules may have nearly identical
predicted mean cost, but one estimate may rely on abundant historical support
while the other requires extrapolation.

Useful outputs can therefore include

$
  E[Y|X],
  quad Q_tau(Y|X),
  quad P(Y>c|X),
$

along with confidence or stability measures for the fitted relationship.

Calibration should be checked empirically. If a model claims that 90% prediction
intervals contain the outcome only 60% of the time in high-volatility periods,
the uncertainty model is not merely imperfect—it is systematically misleading
where risk is high.

== Distribution shift is a modeling problem, not just a monitoring problem

Suppose the conditional relationship at time $t$ is

$
  P_t(Y | X).
$

A model trained on historical data assumes, explicitly or implicitly, that this
relationship will remain useful in the future. In markets, both $P(X)$ and
$P(Y|X)$ can change.

Examples include:

- spread and volatility distributions shifting;
- new venue rules;
- tick-size changes;
- new execution logic changing the action-selection mechanism;
- futures liquidity migrating earlier or later around rolls;
- clients changing the mix of urgency and benchmarks.

A useful stability analysis compares not only average score by date but also
the fitted relationships themselves. Does the size slope change? Does the
volatility adjustment retain its sign? Does calibration deteriorate before
RMSE does?

Regime variables can help when regimes are measurable. Retraining can help when
recent data are relevant. Partial pooling can help when relationships differ but
share structure. None of these eliminates the need to understand why the
distribution moved.

== Evaluate the model through the decision it will drive

For a model that feeds an optimizer, predictive metrics are necessary but not
sufficient.

Suppose two cost models have similar RMSE. Model A is smooth and slightly
conservative at high participation. Model B has lower average error but a
locally jagged prediction surface. An optimizer that differentiates the cost
curve may produce stable schedules under A and erratic jumps under B.

The downstream loss should therefore appear in model evaluation.

If the action selected from model $m$ is

$
  a_m^*(x) = arg min_a hat(C)_m(a,x),
$

we care about the realized or simulated decision loss

$
  L_m = C(a_m^*(x),x) - C(a_"reference"^*(x),x),
$

not only the prediction error averaged over historical actions.

This closes the loop between modeling and control. The regions where the model
needs the most accuracy are the regions where prediction error changes the
decision.

#takeaway[
  A model is not finished when its residuals look acceptable. It is finished
  only when we understand where it is reliable, where it is uncertain, how its
  errors change decisions, and what evidence would cause us to retrain, revise,
  or reject it.
]

== A worked modeling investigation: execution cost

Consider a new project: understand what drives parent-order arrival shortfall
and build a pre-trade cost model.

=== Step 1: define the target

Choose side-adjusted arrival shortfall in basis points at the parent-order level.
State how incomplete orders and explicit fees are handled.

Do not begin by fitting a model. First inspect the response distribution by
side, size, symbol liquidity, and date. Look for obvious data errors, censoring,
heavy tails, and changes in measurement conventions.

=== Step 2: write the mechanism map

A first hypothesis might be:

$
  C = f("relative size", "speed", "spread", "volatility", "depth",
        "flow state", "time", "regime") + epsilon.
$

Mark which variables are known at arrival and which are realized later. If the
model is pre-trade, realized duration and realized market volume belong in
diagnostics, not silently in the feature set.

=== Step 3: design the split

Use chronological holdouts, preserving each parent order as one unit. If the
same symbols occur throughout history, add a symbol-group or liquidity-bucket
analysis to distinguish temporal generalization from cross-sectional
memorization.

=== Step 4: fit the baseline ladder

Fit:

1. unconditional mean;
2. relative size only;
3. size + intended participation;
4. add spread and volatility;
5. add time-of-day effects;
6. add smooth nonlinear terms;
7. add economically motivated interactions;
8. only then compare a flexible ML model.

Record train and validation performance at every step.

=== Step 5: interpret incremental gains

Suppose size alone gives $R^2=0.15$. Adding participation raises it to $0.24$.
Adding spread and volatility raises it to $0.38$. Time of day adds only $0.01$
after those variables.

That is an interesting result. Raw slippage may vary strongly by time of day,
yet little incremental information remains after controlling for liquidity and
volatility. The apparent clock effect may therefore be largely a composition
effect.

The opposite result would motivate a different investigation. If time of day
still adds substantial out-of-sample information after rich liquidity controls,
there may be participant-mix, auction, information-arrival, or benchmark effects
not represented by the current state variables.

=== Step 6: interrogate residuals

Suppose the model systematically underpredicts large orders near futures rolls.
Do not immediately add model capacity everywhere.

Slice the error by days-to-roll, contract, relative depth, front-versus-next
volume share, and spread. Ask whether the problem is missing state, denominator
error, or lack of support.

If a simple regime flag removes most of the bias, a universal high-capacity
model may have been solving the wrong problem.

=== Step 7: test stability

Refit across time windows and products. Compare the size and participation
relationships. If they shift materially, ask whether the model should be
hierarchical, regime-dependent, or periodically recalibrated.

=== Step 8: test the decision

Pass candidate models into the schedule optimizer. Compare the schedules they
produce over a grid of size, spread, volatility, and alpha assumptions.

A model that improves average $R^2$ by one point but creates implausible
marginal-cost gradients may be worse for the trading system.

This workflow turns model fitting into a sequence of questions about market
behavior.

== Build intuition by constructing worlds where you know the answer

One of the fastest ways to develop modeling intuition is to create synthetic
data-generating processes and then deliberately break them.

Start with

$
  Y = 3 X_1 + epsilon.
$

Fit a linear model. Then add an irrelevant predictor. Then add a predictor
highly correlated with $X_1$. Watch prediction stability and coefficient
stability diverge.

Next create

$
  Y = 3 X_1 + 2 X_1^2 + epsilon.
$

Fit a straight line and examine residual curvature. Add a quadratic term or
spline and watch the pattern disappear.

Then create an interaction:

$
  Y = 2 X_1 + X_2 + 4 X_1 X_2 + epsilon.
$

Ask whether marginal plots reveal it. Fit an additive model, inspect structured
residuals, then add the interaction.

Continue by introducing one pathology at a time:

- heteroskedastic noise;
- heavy-tailed errors;
- measurement error in $X$;
- measurement error in $Y$;
- omitted confounders;
- correlated irrelevant variables;
- missing-not-at-random observations;
- duplicated or grouped observations;
- regime shifts;
- serial dependence;
- label leakage;
- selection based on the action.

Because you know the true process, you can connect each failure mechanism with
its empirical fingerprint. After enough repetition, seeing that fingerprint in
real data begins to trigger the right questions automatically.

#research[
  Before fitting each synthetic experiment, write down what you expect to
  happen to coefficients, train error, validation error, residuals, and
  uncertainty. The prediction is what builds intuition. Merely observing the
  output after fitting builds much less.
]

== Keep a research log

A modeling project becomes much more informative when each experiment has an
explicit reason.

For every meaningful fit, record:

- *Question:* what uncertainty are we trying to resolve?
- *Hypothesis:* what do we expect and why?
- *Change:* what single modeling or data change are we making?
- *Prediction:* what should happen if the hypothesis is correct?
- *Result:* what happened on the predetermined validation set?
- *Diagnosis:* what does that imply about the phenomenon or model?
- *Next experiment:* what is now the most valuable uncertainty to resolve?

This prevents the common pattern of accumulating dozens of models without
accumulating understanding.

A good experiment can be valuable even when the score becomes worse. If a
feature thought to represent liquidity contributes nothing once spread and
depth are included, that result refines the mechanism map. If an apparently
strong signal disappears under a forward split, the experiment discovered
instability.

== A compact decision framework

When a model disappoints, ask the questions in order.

=== 1. Is the target meaningful?

Would success on this metric actually answer the research or trading question?
Is the label contaminated by unrelated noise or an inappropriate benchmark?

=== 2. Is the sample representative?

What population generated the data? What filters or selection rules are hidden
in it? Are the difficult cases missing?

=== 3. Is the information set legitimate?

Could every feature have been known at prediction time? Are preprocessors and
feature selectors fitted only on training data?

=== 4. Does the validation mimic deployment?

Are we testing the kind of novelty the model will actually encounter: future
time, new symbols, new regimes, or new clients?

=== 5. Does a simple baseline work?

If not, is there evidence that the available features contain signal at all?

=== 6. Where does the residual structure live?

Slice errors according to mechanisms. Look for curvature, interactions,
heteroskedasticity, regime bias, and lack of support.

=== 7. Is the bottleneck bias, variance, or noise?

Use train-validation gaps, learning curves, resampling stability, and residual
patterns.

=== 8. What is the smallest experiment that distinguishes competing explanations?

Do not change six things at once. If the hypothesis is that volatility modifies
the size effect, test that interaction directly.

=== 9. Does the improvement survive out of sample?

An in-sample story is a hypothesis generator. A stable out-of-sample result is
evidence.

=== 10. Does it improve the downstream decision?

For trading models, evaluate schedules, risk, tail behavior, and policy
stability—not just average prediction error.

== What mature modeling intuition looks like

The end goal is not to memorize a table of rules. It is to compress experience
into fast, testable hypotheses.

When train error is tiny and future error is poor, you should instinctively
think about variance, leakage, and distribution shift.

When coefficients swing while predictions remain stable, think about correlated
features and weak parameter identification.

When a strong raw time-of-day pattern vanishes after controlling for spread and
volatility, think about composition rather than immediately declaring a causal
clock effect.

When errors are concentrated in a sparse region, think about support before
adding global model capacity.

When additional data help only in already well-sampled regions, think about
targeted data collection.

When a flexible model barely beats a smooth additive model, think that the
phenomenon may be mostly low-dimensional and nonlinear rather than governed by
complicated interactions.

When prediction improves but the optimizer becomes unstable, think about local
shape, derivatives, and decision-aware validation.

These reactions are not innate. They are learned by repeatedly making a
prediction about what should happen, fitting the model, examining the failure,
and updating the mental picture of the data-generating process.

== Interview checks

#interview[
  *You inherit a dataset and are asked to predict execution cost. What do you do
  before choosing a model?* Define the response, population, observation unit,
  timing contract, intended use, plausible data-generating process, and
  validation scheme. Then establish simple baselines.
]

#interview[
  *Training and validation error are both high. Should you collect more data?*
  Not automatically. First determine whether residuals contain structured error
  suggesting misspecification or missing state. If both curves have plateaued
  and residuals are largely structureless, more of the same data may provide
  little individual-level predictive improvement.
]

#interview[
  *A feature increases in-sample $R^2$ but not forward out-of-sample $R^2$.
  What does that suggest?* It may be weak, unstable, regime-specific, or
  exploiting noise. Check temporal stability, feature construction, overlap,
  multiple-testing effects, and whether the relationship exists in the
  deployment period.
]

#interview[
  *A boosted tree beats a linear model substantially. What have you learned?*
  Only that the flexible model captures predictive structure the linear
  specification misses. Determine whether the gain comes from smooth
  nonlinearity, thresholds, interactions, entity effects, or leakage before
  drawing a substantive conclusion.
]

#interview[
  *A coefficient is statistically significant but removing the feature barely
  changes out-of-sample performance. Is the feature important?* It can be
  associated with the response while adding little incremental predictive
  information, especially when correlated variables already carry the same
  signal. “Important” must be defined relative to explanation, prediction, or
  causal interpretation.
]

== Exercises

1. Take a parent-order slippage dataset and write the modeling problem in one
   paragraph without naming any algorithm. Specify response, population,
   observation unit, information set, validation target, and deployment use.
2. Draw a data-generating diagram for cost containing latent urgency, intended
   participation, realized participation, volatility, market movement, and
   shortfall. Identify which relationships make realized participation difficult
   to interpret causally.
3. Construct a model ladder for slippage beginning with the unconditional mean.
   For every rung, write one sentence describing what a material out-of-sample
   improvement would teach you.
4. Simulate two highly correlated predictors with only one true latent factor.
   Show how coefficient estimates can be unstable while predictions remain
   stable.
5. Simulate a nonlinear size effect and fit a linear model. Predict the shape of
   the residual plot before computing it. Add a spline and explain what changes.
6. Create a regime shift in which the sign of one relationship changes halfway
   through the sample. Compare a random split with a chronological split and
   explain why they answer different questions.
7. Suppose adding 500,000 small liquid orders barely changes error on large
   illiquid orders. Design a data-collection strategy that is more likely to
   help the region relevant to the optimizer.
8. Compare two models with almost identical RMSE but different smoothness in
   participation. Describe an experiment that evaluates which model is safer for
   schedule optimization.
