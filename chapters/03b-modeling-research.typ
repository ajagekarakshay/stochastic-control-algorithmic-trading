#import "../style.typ": intuition, interview, research, definition

= Statistical Modeling as a Research Process <ch-modeling-research>

Suppose an execution-research team notices a familiar pattern: some parent
orders cost much more than others, even after accounting for their notional
size. The natural reaction is to open the historical order table, choose a set
of features, fit a model, and ask whether the test $R^2$ looks respectable.

That is often the wrong place to begin.

Before a model can tell us anything useful, we have to decide what phenomenon
we are trying to understand, which observations belong to that phenomenon, what
information would actually have been available when a decision was made, and
what kind of conclusion we want the model to support. A model that is good at
predicting realized slippage may be unsuitable for estimating the causal effect
of participation rate. A model that predicts average cost well may still be
unsafe inside an optimizer if its fitted cost curve has the wrong local shape.
A model that performs beautifully on a random train-test split may fail the
first time the volatility regime changes.

The purpose of this chapter is therefore not to catalog machine-learning
algorithms. It is to develop a way of thinking about modeling problems. The
central habit is to treat modeling as a sequence of questions about how the data
were generated, what information they contain, and what decision the final model
must support.

A useful research loop is

$
  "market phenomenon"
  arrow.r
  "research question"
  arrow.r
  "data-generating story"
  arrow.r
  "measurement"
  arrow.r
  "model"
  arrow.r
  "diagnosis"
  arrow.r
  "next experiment".
$

The fitting routine sits inside this loop. It is not the loop itself.

#intuition[
  The difference between a modeler and someone who merely fits models is not
  familiarity with more algorithms. It is the ability to look at a phenomenon,
  imagine how the observed data could have arisen, identify the important
  sources of variation and selection, and design an experiment that separates
  competing explanations.
]

== Begin with the phenomenon you want to understand

Consider the statement

> Large execution programs tend to have higher transaction costs.

It sounds like a modeling problem, but it is still too vague. What exactly is
an "execution program"? What do we mean by "cost"? Do we care about the orders
that entered one particular algorithm, all client orders that could have entered
it, or all orders in some market? Are we trying to forecast cost before trading,
explain why historical orders were expensive, estimate what would have happened
under a different trading speed, or choose a future schedule?

Each version produces a different statistical problem.

For example, suppose we want a pre-trade model that helps an optimizer compare
candidate participation rates. A precise version of the question might be:

> Among parent orders accepted by the execution engine, what is the
> distribution of side-adjusted arrival shortfall, conditional on information
> available at order arrival and on a proposed execution schedule?

Several decisions are hidden inside that sentence.

The *population* is the set of parent orders accepted by the execution engine.
The *observation unit* is the parent order, not the individual fill. The
*response* is arrival shortfall rather than VWAP slippage or a five-minute
markout. The *information set* is limited to variables known at arrival. The
*action* is the proposed schedule or some lower-dimensional description of it,
such as intended participation. The *use* is control: the output will influence
what the trading algorithm chooses to do.

Once the problem is written this way, many otherwise tempting modeling choices
become obviously wrong. End-of-day realized volume cannot be used as a pre-trade
feature. Hundreds of fills from the same parent order cannot be scattered
independently across training and test sets. Realized participation cannot be
interpreted automatically as the effect of choosing that participation because
realized participation itself may have changed in response to the market path.

This is why problem formulation is not administrative work before the "real"
modeling begins. It determines what the model is allowed to mean.

#definition("target, estimand, and estimator")[(
  The *target* is the numerical outcome a model is asked to predict. The
  *estimand* is the population quantity we would like to learn, such as a
  conditional mean, a causal contrast, or a policy value. The *estimator* is the
  rule applied to finite data to estimate that quantity. A regression, boosted
  tree, or neural network is part of an estimator; it is not the estimand.
)]

== Write down a story for how the data came to exist

Before choosing a model family, it helps to describe a plausible data-generating
process. This does not mean claiming that the market literally follows a neat
structural equation. The purpose is to make dependencies explicit enough that
we can reason about them.

For an execution-cost problem, a schematic representation is

$
  Y = f (X, A, Z, U) + epsilon,
$

where $Y$ is the observed cost, $X$ contains measured market and order state,
$A$ denotes an execution action or policy choice, $Z$ contains latent or poorly
measured state, $U$ represents broader regime effects, and $epsilon$ collects
remaining idiosyncratic variation.

The measured state $X$ might include requested quantity, spread, volatility,
depth, expected market volume, time of day, and short-horizon order-flow
signals. The action $A$ might include intended participation, aggressiveness, or
venue allocation. The latent state $Z$ might include trader urgency, private
information behind the order, or an unrecorded implementation detail. The
regime variable $U$ might describe a macro-event day, an index rebalance, a
futures roll, or a change in venue rules.

Now consider a few consequences of this picture.

A trader who believes the price is about to move adversely may choose to trade
faster. That same latent urgency can also be associated with subsequent price
movement. Historical data may therefore show that fast orders have high
slippage even if increasing speed, holding everything else fixed, would have
reduced exposure to that adverse move. A regression of cost on realized speed
cannot by itself distinguish these stories.

Similarly, an adaptive algorithm may accelerate after observing deteriorating
liquidity or an unfavorable price move. Realized participation is then partly a
response to the outcome path. Treating it as though it were an exogenous input
reverses the timing of the problem.

The value of the data-generating story is that it turns a surprising fitted
relationship into a research question. If the coefficient on participation has
the "wrong" sign, the first reaction should not be to try a more powerful model.
We should ask whether urgency, adaptation, selection, measurement error, or a
regime variable can produce that sign.

#research[
  A useful modeling habit is to explain, in words, how one row of the training
  table came to exist. What decisions were made before the row was recorded?
  Which variables were consequences of those decisions? Which quantities were
  observed only afterward? This exercise often reveals more than another round
  of hyperparameter tuning.
]

== Prediction, explanation, causal estimation, and control are different jobs

The same dataset can support several kinds of analysis, but the standards for a
good answer are not the same.

=== Prediction asks what can be known about an outcome

A predictive model asks for the distribution of an outcome given information
available at some time:

$
  P (Y | X).
$

If our goal is to predict tomorrow's parent-order cost, a variable is useful if
it improves stable out-of-sample prediction and is available at prediction
time. It does not need to have a causal interpretation. A proxy can be extremely
useful for prediction even if intervening on the proxy would do nothing.

This is why predictive modeling can tolerate relationships that would be
unacceptable in a causal analysis. The requirement is not "this coefficient is
the effect of spread." The requirement is "this information improves the
forecast in the population and regime where the model will be used."

=== Explanation asks how the fitted conditional relationship behaves

An explanatory analysis studies associations inside a specified statistical
model. We might ask how predicted cost changes with relative size after
conditioning on spread and volatility, whether the size relationship is
approximately concave, or whether the volatility effect differs by liquidity
bucket.

These statements can be economically informative without being causal. If a
linear model says that higher spread is associated with higher cost after
conditioning on the included features, it does not follow that forcing the
spread to decrease by one basis point would reduce cost by the fitted
coefficient. The market states that produce narrow spreads may differ from those
that produce wide spreads in many unmeasured ways.

=== Causal estimation asks what an intervention would change

A causal question compares potential outcomes under different actions. If $a$
and $a'$ are two participation policies, the object of interest may be

$
  E lr([Y (a') - Y (a)]).
$

Now treatment assignment matters. We need to reason about why one policy was
chosen instead of the other, which confounders were measured, whether both
policies were used in comparable states, and whether one order's treatment can
affect another order's outcome.

Predictive accuracy is not evidence that these conditions hold.

=== Control asks which action should be chosen

A control model is used inside a decision rule. Here the question is not only
whether predicted costs are close to realized costs on average. The shape of
the fitted response with respect to the action matters directly.

Suppose an optimizer chooses participation $a$ by minimizing a fitted cost curve
$hat(C) (a,x)$. Two models can have nearly identical test RMSE and nevertheless
produce very different schedules if one has an unstable local derivative with
respect to $a$. A model can therefore be good at prediction and bad at control.

This distinction is especially important in execution research because models
are often built for one purpose and then reused for another. A post-trade TCA
regression may be perfectly reasonable for explaining historical cost patterns
and still be inappropriate as the structural cost curve inside an optimizer.

== The observation unit is part of the model

A dataframe row looks like an observation because software presents it that
way. Statistical independence does not follow from the row boundary.

Imagine a single parent order that generates 150 child orders and 600 fills.
Those fills share the same parent objective, the same benchmark, the same market
path, and an adaptive execution policy. If fill rows from the same parent appear
in both training and validation sets, the model is being evaluated partly on an
episode it has already seen.

If the research question concerns parent-order implementation shortfall, the
parent is usually the natural experimental unit. Features can still be built
from lower-level events, but splitting and uncertainty calculations should
respect the dependence created by the common parent.

For a different problem, the unit may genuinely be shorter. A model of
one-second queue depletion might use event-time intervals, while a fill
probability model might use resting-order episodes. The point is not that one
unit is universally correct. The unit must match the phenomenon and the way the
model will be used.

A useful test is to ask what would count as a genuinely new realization of the
problem. Another fill from the same parent order is not a new parent-order
execution problem. Another parent order in the same symbol on the same event day
may still share important shocks. A parent order several weeks later may be more
independent, but perhaps not if the same client and strategy repeatedly generate
orders with the same latent urgency.

This reasoning determines more than the train-test split. It also affects
weights, clustered standard errors, resampling, and the effective sample size.

== Time determines what the model is allowed to know

Most financial leakage problems are timing mistakes disguised as feature
engineering.

For each feature, there are at least three relevant times:

1. when the underlying market event occurred;
2. when the value became available to the trading system;
3. when the final corrected value became available to researchers.

These times need not be equal.

Suppose a pre-trade model uses an estimate of daily volume. A historical table
may contain the final realized daily volume because it is convenient and clean.
But the production system at 10:00 a.m. knew only a forecast and the volume
observed so far. Replacing the live forecast with final daily volume during
research can create a model that looks remarkably accurate and is impossible to
reproduce in real time.

The same issue appears with corrected market data, late corporate-action files,
reconstructed reference data, revised symbol mappings, and features that use a
future rolling window. A backtest often has a cleaner view of history than the
trading system ever had.

A robust research table should therefore carry a *data contract*. For every
important variable, we should know its source, event timestamp, availability
timestamp, revision policy, missing-value meaning, and population filters. This
contract is not merely a data-engineering convenience. It defines the
information set with respect to which a forecast or policy is valid.

== The label is a measurement, not an oracle

Supervised learning notation encourages us to write observations as

$
  (X_i, Y_i),
$

as if $Y_i$ were the truth and all uncertainty lived in the mapping from $X$ to
$Y$. In market data, the label is often noisy, constructed, or benchmark
dependent.

Arrival shortfall contains both execution effects and market movement that
would have occurred without the order. A five-minute markout is sensitive to the
chosen horizon. Realized volatility depends on the estimator and sampling
frequency. A "temporary impact" label may mix mechanical price pressure with
information carried by the order.

It is often useful to think schematically of

$
  Y_"observed" = Y_"phenomenon" + eta_"measurement".
$

This decomposition is not necessarily an estimable structural model. It is a
reminder that improving the prediction of $Y_"observed"$ is not always the same
thing as learning the phenomenon we actually care about.

Suppose a parent-order cost model reaches an out-of-sample $R^2$ of only 0.35.
That number is not interpretable in isolation. If the label contains a large
amount of unpredictable market movement, 0.35 may represent substantial
predictable structure. If a supposedly stable quantity can be measured almost
without noise, 0.35 may be disappointing.

The useful question is therefore not "Is the $R^2$ high?" but "What variation
remains, and is that variation predictable, measurable, and relevant to the
decision?"

== Features should represent mechanisms

A large feature table can create the illusion that more columns mean more
information. A better starting point is to list the mechanisms that plausibly
change the outcome and then decide how to measure each one.

For execution cost, the first mechanism map might contain order scale, trading
speed, liquidity, volatility, short-horizon market state, time-of-day effects,
and instrument-specific structure.

Order scale is not simply shares. Ten thousand shares is enormous in one
instrument and trivial in another. Relative measures such as

$
  q = Q / "ADV"
$

or quantity relative to displayed depth attempt to measure how large the order
is compared with available liquidity.

Trading speed can be represented by intended participation, target duration, or
an urgency parameter. Liquidity can be represented by spread, depth, turnover,
queue state, or some combination of them. Volatility measures the price risk of
waiting. Imbalance or recent signed flow may summarize short-lived pressure.
Time of day can capture systematic changes in volume, spread, participant mix,
and auction proximity.

The important step is to connect each feature to a story. If we include depth,
we should be able to say what role we expect depth to play and over what horizon.
If we normalize cost by volatility, we are making a claim that some part of the
cross-sectional scale of cost is proportional to volatility. If we divide size
by ADV, we are hypothesizing that response depends more on relative than
absolute size.

Normalization is therefore not harmless preprocessing. It is a modeling
assumption about invariance.

A useful normalization should make the relationship more stable across the
population. If a supposedly universal cost curve in $Q/"ADV"$ still shifts
systematically between liquid and illiquid instruments, the normalization has
not removed all of the relevant heterogeneity.

== Design validation before choosing the winning model

A validation design answers a concrete question: *What kind of future novelty do
we expect the model to face?*

A random row split answers a narrow version of that question. It asks whether
the model works on new rows drawn from roughly the same historical mixture as
the training data. That can be useful, but it is often weaker than what a
trading model needs.

A model deployed next month must survive time. A model used on new instruments
must survive cross-sectional novelty. A model used after an algorithm change
must survive a changed action-selection mechanism. A model used in stress
conditions must survive a regime that may have been rare in the training set.

For a time-dependent execution model, a more realistic sequence is often

$
  "older training period"
  arrow.r
  "later tuning period"
  arrow.r
  "untouched future test period".
$

Rolling or expanding windows then reveal whether performance is stable or
whether one lucky test period is carrying the conclusion.

The split must also respect the observation unit. If parent orders are the
research unit, all child events belonging to a parent should travel together.
If several samples share the same future return window, an embargo may be needed
between training and validation. If symbol identity is powerful, a grouped
holdout can show how much of the apparent performance comes from memorizing
persistent symbol effects.

There is no single universally correct split. There is only a split that is
well or poorly aligned with the deployment question.

== Build a model ladder instead of jumping to the most flexible method

Suppose the final production candidate may be a boosted tree or a neural
network. It is still useful to begin with deliberately simple models.

A typical regression ladder might be

$
  "mean"
  arrow.r
  "one mechanism"
  arrow.r
  "multivariate linear"
  arrow.r
  "regularized linear"
  arrow.r
  "smooth nonlinear"
  arrow.r
  "selected interactions"
  arrow.r
  "flexible ML".
$

Each step is an experiment.

The unconditional mean tells us the error level before using any information.
A size-only model asks how much variation can be captured by scale alone.
Adding intended participation asks whether execution speed contains incremental
information. Adding spread and volatility asks whether market state explains
cost beyond order characteristics. A spline or generalized additive model asks
whether the main effects are smooth but nonlinear. A boosted tree then asks
whether thresholds and interactions that were difficult to specify manually
provide further out-of-sample value.

Imagine the following forward-test results:

#table(
  columns: (1.65fr, 0.65fr, 2.2fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Model*], [*$R^2$*], [*Interpretation*],
  [Mean baseline], [0.00], [No conditional information used],
  [Relative size], [0.16], [Order scale contains meaningful signal],
  [Size + intended participation], [0.25], [Trading speed adds information],
  [Add spread + volatility], [0.38], [Market state matters substantially],
  [Smooth additive model], [0.44], [Nonlinear main effects matter],
  [Boosted trees], [0.46], [Higher-order interactions add only a modest gain],
)

The final value, 0.46, is useful. The sequence is more useful. It tells us that
a small set of economically meaningful variables already captures much of the
predictable variation, that nonlinearity matters, and that very high-order
interactions add relatively little. We have learned something about the
phenomenon, not merely ranked algorithms.

This is the main reason to keep simple models in the workflow. They make the
source of improvement visible.

== Linear models are useful even when reality is not linear

Linear regression is often introduced as though its main purpose were to assume
that the world is linear. In research, it is better viewed as a microscope. Its
simplicity makes conditioning, collinearity, incremental information, and
misspecification easier to see.

Write

$
  Y = beta_0 + beta^T X + epsilon.
$

The fitted coefficient $hat(beta)_j$ describes how the fitted conditional mean
changes with $X_j$ while the other *included* variables are held fixed. The word
"included" matters. If spread and depth are correlated, adding depth can change
the spread coefficient even when the underlying predictive surface changes very
little.

This is not a paradox. The coefficient answers a different conditioning
question after the model specification changes.

For squared-error regression,

$
  R^2 = 1 - "SSE" / "SST".
$

On an out-of-sample set, $R^2$ measures improvement in squared prediction error
relative to predicting the reference mean. It does not say that the features
"explain" that percentage of the economic phenomenon in a causal sense.

A more informative research quantity is often the incremental gain

$
  Delta R^2 = R^2 (X,Z) - R^2 (X),
$

computed on data that were not used to fit either model. If adding volatility
to a size-and-spread model produces a stable increase in forward-test $R^2$,
volatility contains incremental predictive information beyond those variables.

With correlated predictors, however, there is generally no unique way to assign
all explained variation to individual features. Spread, depth, and volatility
can contain overlapping information about liquidity conditions. Statements such
as "spread explains twelve percent of execution cost" require a specific
variance-decomposition convention and should not be inferred casually from one
regression.

Coefficient stability is itself diagnostic. If the fitted spread coefficient
changes sign across samples while the model's predictions remain stable, then
the predictive surface may be much better identified than the individual
parameterization. That is a warning against overinterpreting coefficients, but
not necessarily against using the predictor.

== Bias, variance, and noise become useful when tied to symptoms

The classical bias-variance decomposition is often taught as a formula and then
forgotten. Its practical value is diagnostic.

For squared-error prediction at a fixed state $x$, one writes schematically

$
  E lr([(Y - hat(f) (x))^2])
  =
  "irreducible noise"
  + "bias"^2
  + "variance".
$

The decomposition asks three different questions.

*Noise* is outcome variation that cannot be predicted from the available
information. In execution data, part of the future market path may simply be
unpredictable from the state we record.

*Bias* is systematic error induced by the representation or model class. A
linear cost model can have high bias if the true size relationship is strongly
concave. A model can also have bias because an important state variable is
missing entirely.

*Variance* is sensitivity of the fitted model to the particular training
sample. A highly flexible model with many weak predictors may fit one historical
window extremely well and produce a noticeably different surface after a small
change in the sample.

These concepts are most useful when connected to observable symptoms.

If training and validation error are both poor and residuals show smooth
curvature with size, the problem looks like bias. More data alone will not make
a straight line become curved. A more appropriate transformation, spline, or
mechanism may help.

If training error is excellent but future error is much worse, and fitted
relationships change substantially across resamples, variance is a plausible
problem. More relevant data, stronger regularization, partial pooling, or a
simpler representation may help.

If training and validation error have converged, additional flexibility adds no
stable gain, and residuals are centered with little remaining structure, then
noise or missing information may dominate. The next improvement may require a
better label, richer state, or a different prediction horizon rather than a
more powerful algorithm.

== Learning curves tell us what "more data" is likely to buy

When a model performs poorly, "collect more data" is tempting advice. Learning
curves make that advice testable.

Fit the same modeling procedure on progressively larger training samples and
track both training and validation performance. If validation error continues
to improve as the sample grows while the train-validation gap narrows, the
procedure is still benefiting from additional information. If both curves have
flattened at an unsatisfactory level, more rows drawn from the same distribution
may have limited value.

In markets, sample size should not be confused with row count. Ten years of
history are not automatically ten times as useful as one year. Old observations
may come from different tick sizes, venue rules, market participants, execution
logic, or volatility regimes. Likewise, one million child fills generated by a
small number of parent orders do not provide one million independent examples.

The effective value of more data depends on relevance, diversity, and
independence.

This also changes how targeted data collection should work. If model error is
concentrated in large, illiquid orders, adding hundreds of thousands of small,
liquid orders may reduce global error while doing almost nothing where the model
is weakest. The useful question is not simply "Do we need more data?" but "In
which region of the state-action space would an additional observation reduce
decision-relevant uncertainty?"

== Residuals are where the next research question usually comes from

A single test metric compresses the entire error distribution into one number.
That is useful for comparison and poor for diagnosis.

Let

$
  e_i = y_i - hat(y)_i.
$

The first question is whether residuals are centered in the regions that matter.
Instead of looking only at a global histogram, examine residuals against
relative size, intended participation, spread, depth, volatility, recent price
movement, time of day, side, liquidity bucket, product, client class, and market
regime.

Suppose the average residual is close to zero, but the model underpredicts cost
systematically for large orders in high-volatility periods. That pattern is much
more informative than the global RMSE. It suggests a missing interaction or a
functional form that does not allow the size effect to steepen with volatility.

Suppose instead that errors become large only near futures roll dates. Then the
problem may not be generic model capacity at all. Liquidity may be migrating
between contracts, the denominator used in relative size may be wrong, or the
training set may have little support in that regime.

Suppose mean residuals are well centered but the error variance grows sharply
with order size. The conditional mean may be adequate while the uncertainty
model is wrong. A weighted loss, a variance model, or a quantile model may be
more relevant than changing the mean specification.

Residual analysis turns model failure into hypotheses. The most productive
question is usually not "Which model should I try next?" It is "What market or
measurement mechanism could produce this residual pattern?"

#intuition[
  A model that fails in a structured way is often more scientifically useful
  than a slightly better model whose errors have not been investigated. The
  structure tells us what the current representation does not understand.
]

== Increase complexity in response to a specific failure

There is no virtue in using a simple model when the phenomenon is complicated.
There is also no virtue in using a complicated model before we know what
problem it is solving.

If residuals are smoothly curved with size, a transformation or spline is a
direct response. If the effect of participation changes with volatility, an
interaction is a direct response. If several features have smooth nonlinear
relationships, a generalized additive model can represent them while leaving
the shape visible.

Tree ensembles become compelling when the data support many thresholds and
interactions that would be cumbersome to specify manually. Neural networks
become compelling when the representation itself must be learned from rich
inputs such as order-book sequences, event streams, or very large feature
spaces.

The escalation in model capacity should therefore have a reason. We should be
able to say what pattern the current model cannot represent and how the next
model class is capable of representing it.

This principle also keeps research interpretable. If a boosted tree beats a
linear model by ten percentage points of out-of-sample $R^2$, that is evidence
that the linear specification is missing substantial predictive structure. It
is not yet evidence that "nonlinear machine learning is better." The next task
is to find out whether the gain comes from smooth nonlinearity, a few important
interactions, regime partitioning, symbol identity, or leakage.

== Correlated features should be studied as groups and representations

Feature importance becomes slippery when many variables measure overlapping
parts of the same market state.

Spread, displayed depth, turnover, and short-horizon price impact can all carry
information about liquidity. Removing one of them may have little effect because
another substitutes for it. That does not imply the liquidity mechanism is
irrelevant.

It is often more informative to compare coherent groups. Fit a model with order
scale and speed. Add a liquidity group. Add a volatility group. Add short-term
flow state. Compare incremental out-of-sample performance and residual changes.
Then study alternative representations inside a group: raw spread versus spread
in basis points, raw size versus log size, quantity versus $Q/"ADV"$.

Regularization is useful when many correlated variables encode similar
information. Ridge regression can stabilize a prediction surface by shrinking
coefficients together. Lasso can produce sparse representations, although the
selected member of a highly correlated group may change from sample to sample.
For interpretation, stability across resamples is often more informative than a
single feature-ranking chart.

== Interpolation and extrapolation are different kinds of prediction

A model is usually most trustworthy where the training data provide comparable
examples.

Suppose almost every historical parent order is below 3% of ADV, but an
optimizer asks the cost model to evaluate a 20% ADV schedule. The model may
return a number, but that does not mean the data identified the number. The
prediction is being driven largely by the model's extrapolation assumptions.

This distinction is easy to miss with flexible software because a prediction
function is defined everywhere. Statistical support is not.

Support should therefore be examined in the joint state-action space. Are there
historical orders with similar size, participation, volatility, and liquidity?
Is the proposed action common in that regime or almost unseen? Does the model
have local data, or is it combining separate marginal experiences that rarely
occurred together?

The issue is especially important when a model is optimized. An optimizer does
not passively accept the historical action distribution. It searches the action
space for regions that look attractive. If the fitted cost surface is
artificially cheap in a sparse region, the optimizer can actively steer the
policy toward precisely the part of the model we know least about.

For this reason, a control model should be audited over its full feasible action
domain, not only at historical actions. Conservative extrapolation, explicit
constraints, uncertainty penalties, or abstention can be preferable to an
unqualified point estimate.

== Uncertainty is part of the modeling result

A point forecast such as

$
  hat(mu) (x) = E lr([Y | X=x])
$

hides two distinct questions. How variable is the outcome even if we knew the
conditional distribution perfectly? And how uncertain are we about the fitted
conditional distribution because the data are finite or sparse?

The first is outcome uncertainty. The second is estimation uncertainty.

For trading decisions, both can matter. A schedule may have a low predicted
mean cost but a wide conditional tail. Another schedule may have a similar mean
but be supported by much more historical data. A decision-maker may reasonably
prefer the second even when the point estimates are almost identical.

Depending on the application, useful outputs include conditional quantiles,

$
  Q_tau (Y | X=x),
$

exceedance probabilities,

$
  P (Y > c | X=x),
$

and confidence or stability measures for the fitted response surface.

Uncertainty models should themselves be validated. If nominal 90% prediction
intervals contain only 60% of outcomes during volatile periods, the failure is
not cosmetic. The model is understating uncertainty exactly where risk matters
most.

== Distribution shift should change the modeling conversation

A historical model assumes that past relationships remain useful in the future.
In markets, this assumption deserves continuous scrutiny.

At time $t$, write the relevant conditional distribution as

$
  P_t (Y | X).
$

Both the distribution of states $P_t (X)$ and the conditional relationship
$P_t (Y | X)$ can move. Spread and volatility distributions change. Venue rules
change. Tick sizes change. Client order mix changes. A new version of an
execution algorithm changes which actions are chosen in which states. Futures
liquidity may migrate earlier around the roll than it did in the historical
sample.

A model can therefore fail even if nothing is "wrong" with the original fit.
The world supplying its inputs has changed.

Monitoring should look beyond a single aggregate error metric. Compare
calibration, residual bias, and fitted relationships through time. Does the size
curve move? Does the participation effect weaken in volatile regimes? Does the
model remain well calibrated for large orders even while global RMSE stays
stable?

When a relationship changes, the response depends on the cause. More frequent
retraining can help with gradual drift. Regime features can help when the regime
is observable. Hierarchical or partially pooled models can help when products
share structure but not identical parameters. Shorter training windows can help
when old data have become misleading, but they also increase estimation
variance.

There is no substitute for understanding why the distribution moved.

== The model should be evaluated through the decision it drives

For execution research, the final test is often downstream.

Suppose model $m$ supplies a cost estimate $hat(C)_m (a,x)$ and the optimizer
chooses

$
  a_m^* (x) = arg min_a hat(C)_m (a,x).
$

Prediction metrics measure error at historical state-action pairs. The trading
system cares about the consequence of the selected action. Conceptually, the
quantity of interest is closer to

$
  C (a_m^* (x), x) - C (a_"reference"^* (x), x),
$

where the second action is a trusted reference or benchmark policy.

This changes what model error matters.

An error in a region where all candidate schedules have nearly identical cost
may have little policy consequence. A much smaller error near the point where
the optimizer switches from 10% to 25% participation can change the action
materially. Local slope and curvature can therefore matter more than global
RMSE.

A useful policy-level evaluation passes candidate models through the actual
optimizer over a grid of order sizes, volatility states, spreads, alpha-decay
assumptions, and liquidity regimes. We then inspect the schedules as well as the
predictions. Are they monotone where economics says they should be? Do small
changes in state create implausibly large jumps? Does the optimizer move into
poorly supported regions? Does a model improvement on average create worse tail
behavior?

This is the point where statistical modeling and control meet. The model is not
finished when it predicts history well. It is finished only when its failure
modes are understood in the context of the decisions it will influence.

== A complete investigation: building a pre-trade execution-cost model

It is useful to see the ideas above as one continuous research process rather
than as separate diagnostics.

Suppose we are asked to build a parent-order cost model for a futures execution
algorithm. The model will be used before trading to compare candidate execution
speeds.

=== First, define the economic quantity

Choose side-adjusted arrival shortfall in basis points as the primary response.
State how explicit fees are treated and what happens to incomplete orders. If
unfinished orders are excluded, recognize immediately that the sample is
selected: difficult orders may disappear from the training set. If they are
included using a terminal mark, document that convention because it changes the
meaning of the response.

Before fitting anything, plot the response distribution across time, side,
relative size, liquidity, and product. Look for changes in units, benchmark
construction, outliers, and periods where the data-generating process plainly
changed.

=== Next, construct the mechanism map

A first pre-trade hypothesis might be

$
  C = f (
    "relative size",
    "intended participation",
    "spread",
    "volatility",
    "depth",
    "time of day",
    "product state",
    "roll state"
  ) + epsilon.
$

For each candidate variable, mark whether it is known at arrival. Realized
market volume, realized duration, and realized participation can be valuable for
post-trade diagnosis while still being illegal as pre-trade features.

This distinction keeps the explanatory dataset and the production feature set
from being confused.

=== Then design the validation scheme

Split chronologically by parent order. Keep every child message and fill from a
parent on the same side of the split. Use at least one untouched future period.
If there are many instruments, add a grouped analysis by product or liquidity
bucket so that good performance cannot be attributed entirely to memorized
instrument effects.

If roll periods are especially important, make sure the validation design
contains enough roll observations to say something meaningful about them.

=== Fit the baseline ladder

Begin with the mean. Add relative size. Add intended participation. Add spread
and volatility. Add smooth nonlinear terms. Add a small number of economically
motivated interactions. Only then compare a high-capacity model.

Record the same out-of-sample metrics at each step. More importantly, record
what question each step answers.

Suppose size alone gives $R^2=0.15$, adding participation raises it to $0.24$,
and adding spread and volatility raises it to $0.38$. Time of day adds only
$0.01$ after those variables are included.

That result suggests a useful hypothesis: much of the raw time-of-day pattern in
cost may be a composition effect caused by intraday changes in spread,
volatility, and liquidity. The clock itself may have limited incremental
predictive value after market state is measured.

If time of day still added a large stable gain, the next question would be what
mechanism the clock is proxying for: participant mix, auction proximity,
benchmark demand, information arrival, or something else.

=== Diagnose the remaining errors

Now suppose the model underpredicts large orders near futures rolls. Do not add
capacity everywhere.

Slice residuals by days to roll, front-contract volume share, next-contract
volume share, relative depth, spread, and product. Check whether the relative
size denominator is based on the wrong liquidity pool. Check whether historical
orders in that region are sparse. Check whether the front and next contracts
should be represented jointly.

If a simple roll-state variable removes most of the bias, the original failure
was not that the model lacked enough parameters. It lacked the right state.

=== Test stability, not just average accuracy

Refit across time windows. Compare the fitted size and participation
relationships. If the parameters or partial effects move materially, ask
whether the difference is sampling noise, a measurable regime effect, or genuine
structural change.

A production model may then need partial pooling across products, an explicit
regime variable, or scheduled recalibration.

=== Finally, test the optimizer

Feed each candidate cost model into the scheduling optimizer. Evaluate the
resulting schedules over realistic combinations of size, volatility, spread,
alpha decay, and time remaining.

A model that improves $R^2$ from 0.44 to 0.45 but creates sharp, implausible
changes in optimal participation may be a worse control model. A slightly less
accurate model with smooth and economically sensible marginal costs may produce
a better trading policy.

At this point the research conclusion is richer than "Model B wins." We have a
view of which mechanisms explain cost, where the model is supported, how stable
the relationships are, and what model errors do to execution decisions.

== Synthetic experiments are one of the fastest ways to build intuition

Real market data are difficult because the true data-generating process is
unknown. Synthetic data let us build worlds where the answer is known and then
observe the fingerprints of specific failures.

Start with

$
  Y = 3 X_1 + epsilon.
$

Fit a linear model. Then add an irrelevant predictor. Then add a predictor that
is highly correlated with $X_1$. Prediction may remain stable while individual
coefficients become unstable. That exercise makes multicollinearity concrete.

Next simulate

$
  Y = 3 X_1 + 2 X_1^2 + epsilon.
$

Fit a straight line and predict, before looking, what the residual plot should
look like. Add the quadratic term or a spline and see whether the structure
disappears.

Then simulate an interaction,

$
  Y = 2 X_1 + X_2 + 4 X_1 X_2 + epsilon.
$

Fit an additive model. Examine where it fails. Add the interaction and observe
what changes in residuals and validation error.

Once these basic cases are familiar, introduce one pathology at a time:
measurement error, heavy-tailed noise, heteroskedasticity, omitted variables,
selection, serial dependence, regime shifts, label leakage, grouped
observations, and action-dependent sampling.

The important part is to make a prediction before fitting. Write down what you
expect to happen to coefficients, train error, validation error, residuals, and
uncertainty. Then compare the fitted result with that expectation. Modeling
intuition develops from the mismatch between what you thought would happen and
what actually happened.

== Keep a research log that records reasoning, not just scores

A sequence of experiments is useful only if understanding accumulates with it.
For every meaningful change, record the question being tested, the hypothesis,
the single important change, the expected result, the actual result, and what
the result implies for the next experiment.

For example:

> *Question.* Why does the baseline cost model underpredict large orders in high
> volatility?
>
> *Hypothesis.* The size effect steepens with volatility.
>
> *Experiment.* Add a size-by-volatility interaction while leaving the data and
> validation split unchanged.
>
> *Prediction.* High-volatility residual bias should shrink more than
> low-volatility bias, with only modest change elsewhere.
>
> *Result.* The bias shrinks near the center of the sample but remains large for
> the largest orders.
>
> *Interpretation.* The interaction helps, but lack of support or another
> liquidity variable is probably still important.

This kind of log prevents the common situation where dozens of models have been
fit but nobody can say what was learned from model 17 that was not already known
from model 6.

A worse score can still be an informative result. If a feature believed to
measure liquidity adds nothing once spread and depth are present, we have learned
that it carries little incremental information in the current representation.
If a strong random-split result disappears under a forward split, we have
learned that the relationship was unstable or that the original validation was
too easy.

== A practical sequence for an unfamiliar modeling problem

When faced with a new phenomenon, the workflow is less mysterious than it first
appears.

Begin by writing the research question in ordinary language without naming an
algorithm. Define the population, response, observation unit, information set,
and eventual use. Then describe how the observations could have been generated,
including the actions and latent variables that might create selection or
confounding.

Build the simplest research table that respects timing. Establish a validation
scheme that resembles deployment. Fit a baseline that is almost embarrassingly
simple. Add mechanisms one at a time or in coherent groups. Examine not only the
score but how the residual structure changes.

When the model fails, decide whether the failure looks like missing structure,
estimation variance, measurement noise, lack of support, or distribution shift.
Increase complexity only when a specific failure motivates it. When the model is
intended for a decision, evaluate the decision directly.

The goal is not to follow these steps mechanically. With experience, many of
them happen almost simultaneously. The important skill is being able to explain
why the next experiment is the most informative one.

== What mature modeling intuition looks like

Modeling intuition is not a collection of memorized rules. It is a library of
failure patterns and plausible explanations.

If training error is tiny and future error is poor, variance, leakage, and
regime mismatch should come to mind quickly.

If coefficients swing across samples while predictions remain stable,
correlated representations and weak parameter identification are plausible.

If a strong raw time-of-day pattern disappears after controlling for spread and
volatility, composition should be considered before declaring a structural
clock effect.

If residuals are concentrated in a sparse state-action region, lack of support
should be investigated before adding global model capacity.

If a flexible model barely improves on a smooth additive model, the phenomenon
may be largely low-dimensional and nonlinear rather than dominated by complex
interactions.

If prediction improves while the optimizer becomes unstable, attention should
shift from global prediction error to local slopes, curvature, extrapolation,
and decision-aware validation.

These reactions become fast only after repeated practice. The researcher forms
a hypothesis, predicts what the data should look like if it is true, runs a
controlled experiment, and updates the mental model. Over time, that loop is
what turns statistical techniques into modeling judgment.

== Interview checks

#interview[
  *You inherit a dataset and are asked to predict execution cost. What do you do
  before choosing a model?* Define the economic response, population,
  observation unit, information available at prediction time, intended use,
  plausible data-generating process, and deployment-aligned validation scheme.
  Then establish simple baselines before increasing model capacity.
]

#interview[
  *Training and validation error are both high. Should you collect more data?*
  Not automatically. First inspect residual structure and learning curves. If
  the current model is systematically misspecified, more of the same data may
  only estimate the wrong relationship more precisely. If the learning curve is
  still improving and the model is variance-limited, additional relevant data
  can help. If residuals are largely structureless, better measurements or a
  different target may matter more.
]

#interview[
  *A feature increases in-sample $R^2$ but not forward-test $R^2$. What have you
  learned?* The feature may be weak, unstable, regime-specific, correlated with
  existing variables, or exploiting noise. Check feature timing, temporal
  stability, overlap, and whether repeated feature searching has overfit the
  validation process.
]

#interview[
  *A boosted tree substantially beats a linear model. What does that prove?*
  It proves that the flexible model captures predictive structure missed by the
  linear specification on the chosen validation design. It does not reveal the
  source of the gain. The next step is to determine whether the improvement
  comes from nonlinear main effects, interactions, regime partitions, entity
  effects, or leakage.
]

#interview[
  *Why can a model with lower RMSE be worse for an execution optimizer?* Because
  optimization depends on the shape of the fitted cost surface in the region of
  candidate actions. Small local errors in slope or curvature can change the
  selected schedule even when average prediction error is lower.
]

== Exercises

1. Take a parent-order slippage dataset and write the modeling problem in one
   paragraph without naming any algorithm. Specify the response, population,
   observation unit, information set, validation target, and deployment use.
2. Draw a data-generating diagram containing latent urgency, intended
   participation, realized participation, volatility, market movement, and
   arrival shortfall. Explain why realized participation is difficult to
   interpret causally.
3. Build a model ladder for execution cost beginning with the unconditional
   mean. For each rung, write what a material out-of-sample improvement would
   teach you about the phenomenon.
4. Simulate two highly correlated predictors that measure one latent factor.
   Compare coefficient stability with prediction stability across resamples.
5. Simulate a concave size effect, fit a linear model, and sketch the residual
   pattern you expect before calculating it. Then add a spline and compare.
6. Create a regime shift in which one feature's relationship with the target
   changes halfway through the sample. Compare a random split with a
   chronological split and explain why they answer different questions.
7. Suppose adding 500,000 small liquid orders barely changes error on large
   illiquid orders. Design a data-collection strategy that targets the region
   relevant to the optimizer.
8. Construct two cost models with similar RMSE but different curvature in
   participation. Pass both through a simple schedule optimizer and compare the
   resulting policies.
9. Take one feature normalization, such as $Q/"ADV"$, and state the invariance
   assumption it implicitly makes. Design a diagnostic that tests whether that
   assumption is approximately valid across liquidity buckets.
10. For a production model of your choice, create a research log containing
    five sequential experiments. Each experiment should have a hypothesis and a
    predicted diagnostic outcome before the model is fit.

== Where the book goes next

A careful modeling process is still only as trustworthy as the observations
supplied to it. The next chapter moves below the research dataframe and asks how
parent orders, child messages, fills, quotes, trades, reference data, and
multiple clocks should be reconstructed into a dataset without destroying the
timing and economic meaning on which the statistical analysis depends.
