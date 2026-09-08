#import "../style.typ": intuition, interview, research, takeaway, definition

= The Empirical Shape of Market Impact <ch-impact-empirical>

Return to the 400,000-share buy order. During its ninety-minute execution the
midprice rises, but not smoothly. It moves after some child orders, remains flat
after others, retreats during two pauses, and finishes above its arrival level.
The program paid more than the initial mid. How much of that movement was market
impact, and what shape should an impact model try to capture?

The temptation is to begin with a familiar formula, perhaps a square root of
order size. That is too early. Before estimating parameters, we need to know
which empirical object the formula is supposed to summarize. The immediate
response to one aggressive child order, the price path during a parent order,
the average execution cost, and the post-trade decay are related, but they are
not the same outcome.

This chapter maps those outcomes. It describes the recurring patterns that
appear in execution data, the variables along which the patterns change, and
the checks that prevent a stylized fact from becoming a universal law. Chapter
7 will ask how to estimate these relationships under noise, selection, and
endogeneity.

== Impact is a response indexed by time

Let a parent order begin at $t_0$, end at $t_1$, have side $epsilon in {-1,+1}$,
and requested quantity $Q$. Let $m_t$ be the midprice. A side-adjusted price
trajectory relative to arrival is

$
  I (t)
  =
  epsilon frac(m_t-m_(t_0),m_(t_0)),
  quad t >= t_0.
$

Positive values mean the market moved in the direction of the order. Three
points on this trajectory receive particular attention:

$
  I^"peak"
  =
  max_(t in [t_0,t_1]) I (t),
  quad
  I^"end"
  =
  I (t_1),
  quad
  I^"post" (tau)
  =
  I (t_1+tau).
$

Peak response, end response, and post-trade response answer different questions.
An order can move the price sharply, experience partial reversion before it
finishes, and be followed by another move after completion. Reducing the path to
one number discards the distinction.

The denominator and units should be explicit. Returns make prices comparable;
basis points make small returns readable. Dividing by daily volatility expresses
the move in risk units. Dividing by spread expresses it in local liquidity units.
Each normalization proposes a different kind of stability.

#definition("empirical impact curve")[
  An empirical impact curve is a conditional average or distribution of signed
  price response indexed by order progress or time and by pre-specified order
  and market characteristics. It is a statistic of a population, not yet a
  structural law describing the price that would prevail without the order.
]

#pagebreak()

== Child-order response and parent-order impact live on different scales

At the child level, an aggressive buy can exhaust the best ask and change the
mid immediately. The relevant horizon may be milliseconds or a few book events.
Queue state, displayed depth, and concurrent messages dominate.

At the parent level, hundreds of child orders can be interleaved with other
market activity over minutes or hours. The parent order's side may persist while
its child-level actions alternate among taking, posting, cancelling, and waiting.
Market participants can infer the flow and replenish or withdraw liquidity.

Let $v_t$ be signed parent trading rate and let a schematic response be

$
  I (t)
  =
  integral_(t_0)^t G (t-s) f (v_s) dif s
  + U (t),
$

where $G$ describes persistence, $f$ describes instantaneous response, and
$U (t)$ contains other price movement. This is not being asserted as the true
data-generating process. It makes one point visible: the observed response at
time $t$ depends on the path of earlier trading, not only on the latest child.

An event study of public trades and a study of broker metaorders therefore
should not be expected to produce identical curves. They use different units,
different information about parent intent, and different conditioning.

== The no-trade price is unobserved

The observed signed move can be written conceptually as

$
  epsilon lr((m_t-m_(t_0)))
  =
  I^"causal" (t)
  +
  R^"other" (t),
$

where $I^"causal" (t)$ is the difference the order would make to the same market
path and $R^"other" (t)$ is everything else. Only their sum is observed.

Orders are not placed randomly. A buy can be triggered by information that also
predicts a price rise. Urgency can increase when the market begins moving away.
Other investors may trade on the same signal. A raw average signed trajectory
therefore combines mechanical response, information revealed by the order,
selection into trading, and common-cause movement.

This does not make the trajectory useless. It remains the outcome a historical
policy encountered and may be predictive for a similar future policy. The
discipline is to call it a signed response unless an identification design
supports the stronger causal word “impact.”

#research[
  Side adjustment removes the sign difference between buys and sells; it does
  not remove selection. If buys occur before positive returns because of alpha,
  averaging signed paths will attribute some predictable movement to the order.
]

== Progress time reveals the shape of the execution path

Parent orders have different durations. To compare their trajectories, define
fraction of elapsed execution time

$
  u (t)
  =
  frac(t-t_0,t_1-t_0),
  quad 0 <= u (t) <= 1,
$

and fraction completed

$
  z (t)
  =
  frac(Q^"fill" (t),Q^"fill" (t_1)).
$

Clock progress and quantity progress need not agree. A front-loaded program has
$z (t)>u (t)$ through much of the interval; a back-loaded program has $z (t)<u (t)$.
Plotting impact against $u$ mixes the response with schedule shape. Plotting it
against $z$ aligns quantity but suppresses pauses and variation in trading rate.

Use both. A pause that shows flat quantity progress but falling price response
is evidence of decay on the observed path. The same episode plotted only by
fraction completed can make the recovery disappear because no new progress
points are created during the pause.

When orders are incomplete, normalizing by final filled quantity can also leak
the eventual outcome into earlier points. A live-progress feature should use
requested quantity or the then-current instruction; a retrospective chart may
use final quantity if labeled clearly.

== Size, participation, and duration form a triangle

Three variables recur in nearly every impact study:

- relative size $x=Q/V_D$, where $V_D$ is a daily liquidity scale;
- participation $rho=Q/V_T$, where $V_T$ is market volume during the execution;
  and
- duration $T=t_1-t_0$.

If market volume arrives at an approximately constant rate $nu$, then

$
  V_T approx nu T,
  quad
  Q approx rho nu T.
$

Holding any two variables constrains the third. Larger orders tend to last
longer or trade at higher participation. A regression that includes all three
as though they vary independently can assign unstable meanings to their
coefficients.

The relationship is not an exact identity in practice. Volume rate changes
through the day, algorithms pause, and realized duration responds to fills and
price movement. But the geometry remains. Every empirical plot of impact versus
size averages over a distribution of participation and duration. Every plot
versus participation averages over a distribution of order sizes and states.

#intuition[
  “Large” and “fast” are not two names for the same thing. A large order can be
  patient, and a small order can be urgent. Yet the data-generating policy ties
  size, speed, and duration together. Studying one requires showing what happened
  to the other two.
]

== The square-root law is a scaling regularity

A widely reported empirical form relates signed response to daily size fraction:

$
  E lr([I^"end" | x])
  approx
  Y sigma_D x^delta,
$

where $sigma_D$ is a daily volatility scale, $Y$ is a dimensionless coefficient,
and empirical work often finds a concave exponent near $delta=1/2$ over a useful
range @toth2011. Other studies find dependence on participation and duration as
well; direct institutional-order estimates have reported exponents and scaling
that differ from an exact universal square root @almgren2005.

The formula says that average per-share price response grows less than
proportionally with order size. It does not say:

- every order moves price by its square root prediction;
- the exponent is exactly one half in every asset or regime;
- impact is independent of execution speed;
- the curve remains valid for arbitrarily small or large orders; or
- the relationship is causal merely because it is stable.

A log-log chart can make a power law look persuasive. Always show the same data
in original units, display observation density, and report the range with actual
support. Apparent straightness over two sparse tail bins is not a scaling law.

== Concave response does not mean large orders are cheap

Suppose per-share response is

$
  c (Q)
  =
  k Q^delta,
  quad 0<delta<1.
$

Doubling $Q$ less than doubles cost per share. Total dollar cost is approximately

$
  C^"dollar" (Q)
  =
  Q c (Q)
  =
  k Q^(1+delta),
$

which is convex because $1+delta>1$. Large orders remain disproportionately
expensive in total dollars.

This distinction is crucial for control. An optimizer allocates marginal
dollars, not only average basis points. The marginal total cost is

$
  frac(d C^"dollar" (Q),d Q)
  =
  k (1+delta) Q^delta.
$

It exceeds the average cost $k Q^delta$ by the factor $1+delta$. Confusing the
per-share curve with the total-cost curve produces the wrong optimization
geometry.

Concavity can also arise from population mixing. If large orders are assigned
longer horizons, better liquidity, or different algorithms, an unconditional
size curve partly reflects those policies. A conditional curve should show how
the shape changes within participation, duration, and liquidity bands.

== Participation measures how hard the order leans on flow

Realized participation over the order is

$
  rho^"real"
  =
  frac(Q^"fill",V_(t_0,t_1)),
$

where $V_(t_0,t_1)$ is eligible market volume during the execution. Higher
participation generally means the program consumes a larger share of the flow
available to absorb it.

Participation is economically appealing but statistically awkward. The
denominator is realized after the order begins. Duration can change in response
to fills. An adaptive algorithm may accelerate after adverse price movement.
Consequently high realized participation can be both a cause and a consequence
of a difficult path.

Separate intended participation, forecast participation, and realized
participation. Intended participation describes the action requested at the
decision. Forecast participation uses volume expected at that time. Realized
participation is valuable for retrospective description. Their differences
measure implementation and forecast error rather than interchangeable versions
of one feature.

When an existing model appears insufficiently sensitive to speed for illiquid
products, inspect whether realized participation is compressed by low and noisy
market volume, whether duration selection masks the curve, and whether child-
order spacing or replenishment carries the missing mechanism.

== Duration is both exposure and a policy outcome

For fixed quantity, a longer duration usually lowers the average trading rate
and allows more replenishment. It also exposes the unfilled inventory to more
market movement. An arrival-price response measured at completion therefore
contains two effects: the liquidity response to slower trading and a longer
window in which unrelated or informational returns can accumulate.

Duration may be scheduled in advance, bounded by a client window, or generated
endogenously by a participation policy. These cases should not be pooled without
labels. A two-hour order that was instructed to be patient is different from an
order that took two hours because passive fills repeatedly failed.

Compare trajectories at fixed quantity and intended speed when possible. If the
aim is causal, safe randomized changes to participation or horizon are much more
informative than a regression on realized duration.

== Temporary, transient, and permanent describe horizons

The vocabulary of impact is useful but inconsistently applied.

- *Immediate* or *instantaneous* response occurs with the child action, including
  spread crossing and visible book consumption.
- *Temporary* cost often means a price concession paid only by the current
  execution, such as a rate-dependent execution-price term.
- *Transient* impact is a state that persists after the action but decays over
  time.
- *Permanent* impact is the component that does not decay over the horizon the
  model considers.

These definitions are horizon dependent. A response that appears permanent
after ten minutes may decay over several days. A post-trade price that remains
elevated may reflect information rather than an irreversible mechanical change.

A useful empirical report avoids forcing a binary temporary/permanent split. It
plots the response over several post-trade horizons and states exactly what
“permanent” means in the dataset.

== Post-trade decay is a curve, not one reversion number

Define end-relative decay for $tau>0$ as

$
  D (tau)
  =
  I^"post" (tau)-I^"end".
$

A negative value indicates reversion of a same-direction end impact. An often-
used normalized persistence ratio is

$
  R (tau)
  =
  frac(I^"post" (tau),I^"end"),
$

when the denominator is sufficiently far from zero. $R=1$ means no observed
decay from the end level; $R=0$ means full reversion to arrival. Ratios become
unstable for small end responses and should be accompanied by levels.

Empirical metaorder studies find nontrivial trajectories during execution and
decay after completion rather than one universal permanent fraction
@bacry2015. The measured shape depends on order duration, participation,
conditioning, and whether the sample separates information-driven orders from
liquidity-motivated ones.

Post-trade windows overlap with new information and other trades. Longer
horizons allow more decay to appear but make the no-trade counterfactual less
credible. Controls based on market or sector returns can reduce common movement,
but they do not recreate the exact price path that would have occurred without
the order.

== Pauses make resilience visible

If trading stops while the parent order remains active, quantity is fixed but
time advances. A decline in the signed response during the pause is consistent
with transient recovery. When trading resumes, the subsequent response can
reveal whether the book has replenished.

Pauses are especially informative when they arise from randomized scheduling or
external constraints. Endogenous pauses are selected: the algorithm may pause
because liquidity is poor, the price moved favorably, or alpha weakened. Compare
the observed path with states that triggered the pause before interpreting the
recovery rate.

A stylized exponential response state is

$
  dif r_t
  =
  -kappa r_t dif t
  + eta v_t dif t.
$

During a pause, $v_t=0$ and

$
  r_(t+Delta)
  =
  r_t e^(-kappa Delta).
$

The empirical half-life $log(2)/kappa$ is meaningful only if the single-rate
approximation fits the relevant horizon. Multiple decay scales, regime changes,
and continuing information response often produce systematic departures.

== Mechanical and informational components can decay differently

A mechanical story begins with depleted liquidity: aggressive trading consumes
nearby supply, prices move, and replenishment gradually restores the book. An
informational story begins with beliefs: the order is evidence about future
value, so other participants revise quotes and some price change can persist.

The latent-order-book framework offers one way to separate a transient
mechanical response from a more persistent informational component
@donier2015. Empirical data alone rarely reveals a unique decomposition. Yet the
distinction guides useful tests:

- Does the response decay during exogenous pauses?
- Does replenishment in depth accompany price recovery?
- Is persistence stronger for orders with independently measured alpha?
- Does response differ between liquidity-motivated and information-motivated
  flow?
- Does reversing or hedging the trade reverse the same state?

A model for scheduling needs the decay that follows actions under the policy,
not a philosophical verdict about permanent value. If the distinction affects
the value of waiting, it belongs in the state and should be estimated over the
decision horizon.

== Volatility normalization is useful and incomplete

Price response tends to be larger in more volatile assets and regimes. A common
normalization writes

$
  tilde(I)
  =
  frac(I,sigma_D).
$

This can collapse curves across products if daily volatility is a suitable
scale. It can fail when volatility is stale, when jumps dominate, when the order
horizon is much shorter than a day, or when the volatility estimator contains
the order's own price movement.

Use a pre-trade volatility estimate for a deployable model. For descriptive
analysis, compare pre-trade, contemporaneous, and full-day measures to see how
normalization changes the curve. If high-impact orders mechanically inflate the
denominator, dividing by realized volatility can hide part of the response.

Risk normalization also does not replace liquidity variables. Two instruments
with the same daily volatility can have different spreads, depth, volume, tick
sizes, and replenishment.

== Spread, depth, and volume describe different liquidity mechanisms

Impact usually rises when the market is less able or less willing to absorb
flow, but “liquidity” needs more than one column.

#table(
  columns: (0.9fr, 1.35fr, 1.75fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Measure*], [*Mechanism represented*], [*Reason the relation can fail*],
  [Spread], [Immediate price of crossing], [A wide book may replenish rapidly],
  [Displayed depth], [Visible capacity near the price], [Quotes can cancel or hidden size can refill],
  [Market volume], [Realized flow capacity], [Volume can be endogenous to information and volatility],
  [Turnover], [Trading relative to shares or exposure], [Cross-sectional identity remains],
  [Message intensity], [Rate of book revision], [Many messages can be cancellations rather than supply],
  [Resilience], [Recovery after depletion], [Estimated decay depends on the initiating action and regime],
)

Conditioning on spread alone can leave strong residual size or participation
effects. Conditioning on daily volume can miss an intraday drought. A compact
impact model may still use a few variables, but exploratory work should show
which mechanism each one is standing in for.

== Time of day is a mixture, not an explanation

Suppose average slippage is lower near the close. One story says close-period
trading is cheaper because market volume and replenishment are high. Another
says orders near the close have a different benchmark, urgency, or composition.
A third says the sample excludes difficult late orders that failed to complete.

To separate these stories, plot impact by start time while also conditioning on
forecast participation, spread, volatility, depth, duration, benchmark, and
auction access. Compare within symbol and date where support exists. Distinguish
continuous-session fills from the closing auction. Use only information known at
the intended decision time when the result will enter a controller.

If a time coefficient disappears after adding liquidity state, clock time was a
proxy. If it remains, investigate participant mix, benchmark demand, news
schedule, and structural venue effects. Even a stable residual time effect is a
reduced-form regularity, not a reason to hard-code back-loading without terminal
risk and forecast uncertainty.

== Regimes bend the curve

Impact relationships change during volatility shocks, news, index rebalances,
rolls, holidays, shortened sessions, outages, and liquidity transitions. A
single power law fitted to the full sample estimates an average across these
states.

Regime analysis should show three things:

1. *support:* which sizes and policies actually occur in each regime;
2. *conditional shape:* whether level, slope, curvature, or decay changes; and
3. *uncertainty:* whether sparse regimes justify a separate curve.

Hard regime labels can create unstable boundaries. Continuous state variables
and hierarchical partial pooling often describe gradual changes better. Still,
named events such as a futures roll or closing auction have mechanisms that
deserve explicit representation.

An especially important diagnostic is extrapolation. If large illiquid orders
occur mostly during stressed regimes, a model can appear accurate on average
while its high-size curve is based on little comparable data.

== Cross-sectional collapse is an empirical claim

Scaling by volatility and volume aims to make impact comparable across assets:

$
  frac(I,sigma_D)
  approx
  F lr((frac(Q,V_D),rho,T,Z)).
$

If curves from many symbols align after normalization, the result supports a
shared structure and enables pooling. If residual levels remain related to tick
size, spread, turnover, sector, contract type, or venue, the collapse is
incomplete.

Do not judge collapse only by a pooled fit score. Plot symbol or product random
effects, leave-one-group-out performance, and residual distributions across
liquidity deciles. A universal curve that predicts liquid equities well and
systematically underestimates thin futures contracts is not universal in the
region that matters.

Partial pooling offers a practical middle ground: a common shape with uncertain
group-level shifts or slopes. Chapter 7 develops that model statistically.

== Equities, futures, options, and illiquid assets differ in state

The broad idea of signed response applies across markets, but the economic unit
and liquidity state change.

For equities, shares, notional, ADV, spread, fragmented venues, and auctions are
natural descriptors. For futures, contract multiplier, tick value, expiry,
session, front-to-next liquidity migration, and basis matter. A risk-equivalent
quantity may be more comparable than contracts. For options, delta, gamma,
vega, underlying moves, implied-volatility response, and sparse strikes complicate
a price-only impact label. Empirical work has found square-root-like behavior in
option markets when quantity is measured as net vega @toth2016, but that does
not remove the need to define the risk dimension being traded.

In very illiquid assets, zero-trade intervals, discrete ticks, price limits, and
large gaps make smooth basis-point curves fragile. Completion and waiting time
may be more informative than conditional cost on the few completed orders.

The goal is not to force every product into a different model. It is to retain
the state variables that make an action economically comparable.

== Futures rolls expose weak normalizations

Around a roll, volume and depth migrate across expiries while the desired
economic exposure can stay nearly constant. Suppose $Q_1$ contracts trade in the
front and $Q_2$ in the next contract. Raw contract counts are comparable only
after accounting for multipliers and price risk.

Let dollar exposure per contract be $E_j=P_j M_j$, with price $P_j$ and
multiplier $M_j$. A simple exposure-normalized size is

$
  x_j^"risk"
  =
  frac(Q_j E_j,V_j E_j)
  =
  frac(Q_j,V_j),
$

when numerator and denominator use the same contract. The cancellation shows
why contract-specific volume matters: substituting root-level volume pooled
across expiries changes the ratio even though those contracts are not perfectly
interchangeable at the execution horizon.

Residual underestimation near rolls can signal several failures: wrong expiry
mapping, pooled denominators, disappearing top-of-book depth, basis volatility,
different participant mix, or an outright order that would have been cheaper as
a listed spread. Plot impact by days to roll, contract liquidity rank, and
front-next volume share rather than adding one generic “roll week” dummy and
stopping.

== An empirical impact study should reveal the surface

A disciplined exploratory sequence is more informative than one regression.

1. Define the unit, response path, side convention, horizon, and population.
2. Plot observation support over size, intended participation, realized
   participation, duration, and liquidity.
3. Show unconditional response trajectories in clock and quantity-progress time.
4. Plot size curves within participation, duration, and liquidity bands.
5. Plot participation curves within size and duration bands.
6. Examine post-trade decay in levels and normalized ratios.
7. Repeat by spread, volatility, time of day, symbol group, and named regime.
8. Show completion, censoring, and missingness beside cost.
9. Compare original and normalized units.
10. Record where the data interpolate and where a model would extrapolate.

Use uncertainty bands and counts. Equal-width bins can leave sparse tails;
quantile bins can hide how far the tail extends. Smooth curves are helpful, but
overlay enough raw or binned structure to make support visible.

#takeaway[
  The purpose of empirical exploration is not to select the prettiest curve. It
  is to discover which variables change the response in a way that would change
  an execution decision, and where the data are too weak to support that change.
]

== From empirical regularity to control input

A scheduler needs expected marginal cost over feasible actions. A transient
controller needs the response to timing and pauses. A passive-order controller
needs conditional fills and markouts. A router needs venue-specific outcomes and
missing counterfactuals.

An empirical finding becomes useful for control only after specifying:

- the action whose consequence it predicts;
- the pre-decision state on which it conditions;
- the horizon over which the response persists;
- the uncertainty and support around the prediction;
- the derivative or ranking used by the optimizer; and
- the policy under which the training data were generated.

For the running order, learning that average response scales with size is not
enough. The policy must know whether sending the next 20,000 shares now is more
expensive than splitting them after replenishment, given current spread, depth,
flow, remaining inventory, and deadline. The empirical surface supplies evidence
for that comparison; it does not choose the action by itself.

== Interview checks

#interview[
  *What exactly does the square-root impact law say?* State the response,
  normalization, population, and range. Explain why a concave per-share curve
  still produces convex total dollar cost and why the relation is not
  automatically causal.
]

#interview[
  *Impact appears lower for longer orders. Does patience cause lower cost?*
  Discuss size-participation-duration dependence, selection into horizons,
  replenishment, longer exposure to unrelated returns, and randomized or
  intent-based comparisons.
]

#interview[
  *How would you investigate lower slippage near the close?* Separate liquidity,
  benchmark, auction, order-composition, completion, and time-of-day mechanisms;
  use pre-trade variables and display overlap.
]

#interview[
  *Why might a futures impact model underestimate near the roll?* Discuss exact
  expiry, contract-specific volume and depth, liquidity rank, basis risk,
  participant mix, continuous-series distortion, and outright versus spread
  execution.
]

== Exercises

1. Construct two parent orders with identical size fraction but different
   participation and duration. Sketch plausible impact paths during execution
   and post-trade, and state what data would distinguish the mechanisms.
2. If per-share impact is $c (Q)=k sqrt(Q)$, derive total and marginal dollar cost.
   Compare the marginal cost with the average cost and interpret the ratio.
3. Create an example in which a log-log size plot appears linear because large
   orders occur only in high-volatility states. Show how volatility normalization
   and stratification change the picture.
4. Design clock-progress and quantity-progress trajectory plots for a program
   with a ten-minute pause. Explain what each representation preserves and hides.
5. Define intended, forecast, and realized participation for a VWAP-style order.
   Give one modeling use and one misuse of each.
6. Propose a post-trade decay study with horizons of one minute, ten minutes, one
   hour, and one day. Specify controls, overlapping-window treatment, support,
   and how information-driven orders complicate interpretation.
7. Design a cross-sectional scaling test across equities and futures. Specify
   units, volatility and volume denominators, group holdouts, residual plots, and
   a criterion for declaring that pooling has failed.
8. An impact curve fits average cost well but its numerical derivative oscillates
   with participation. Explain why this is dangerous for control and what
   Chapter 7's estimation procedure must validate.

== Where the book goes next

This chapter has described the surface that an impact model must explain: how
signed response varies with progress, size, speed, duration, liquidity, time,
product, and regime. Chapter 7 turns to estimation. It will compare functional
forms, confront heavy tails and endogeneity, quantify uncertainty, and test the
parts of the fitted surface that an optimizer actually uses.
