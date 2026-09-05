#import "../style.typ": intuition, interview, research, takeaway, definition

= The Execution Problem <ch-control-lens>

At ten o'clock, a portfolio manager sends an instruction to buy 400,000 shares
before 11:30. The stock is trading near \$50. Based on the morning volume
forecast, roughly four million shares should trade during the ninety-minute
window, so a uniform schedule would represent about ten percent of market
volume.

The instruction sounds precise: buy a known quantity by a known deadline. It
does not say how to trade.

The algorithm could cross the spread and complete the order immediately. That
would remove the risk of a price rise, but it might consume several levels of
the order book and reveal urgency. It could participate steadily, accepting
price risk in exchange for smaller child orders. It could wait for more
favorable liquidity, post passively, route to a dark venue, or accelerate
because the portfolio manager's signal predicts that the price will rise.
Every choice changes both the cost paid now and the set of choices left later.

This is the execution problem. A parent order is not simply a quantity to be
divided into pieces. It is a sequence of decisions made while prices,
liquidity, forecasts, and the trader's own inventory evolve. The purpose of
this chapter is to describe that decision problem carefully enough that the
mathematics introduced later has something definite to represent.

== From a trading instruction to a sequence of decisions

A *parent order* is the economic instruction received by the execution system:
buy or sell a quantity, subject to a horizon, benchmark, and constraints. The
orders actually submitted to venues are *child orders*. A child order has a
size, price, order type, destination, and lifetime. It may fill immediately,
fill partially, rest in a queue, or be cancelled without filling.

The distinction matters because the parent order carries the objective, while
child orders are actions taken in pursuit of that objective. A hundred fills
from one parent order are not a hundred independent trading problems. They
belong to one evolving episode, share the same benchmark, and are connected by
the policy that generated them.

Before an execution problem can be modeled, the instruction must answer several
questions.

#table(
  columns: (1.05fr, 1.45fr, 1.7fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Part of the instruction*], [*Typical examples*], [*Why it changes the policy*],
  [Quantity and side], [Buy 400,000 shares], [Sets inventory, scale, and the direction of price exposure],
  [Trading window], [Now through 11:30], [Determines how much time is available to wait or recover],
  [Benchmark], [Arrival price or interval VWAP], [Defines what “good execution” means],
  [Urgency or alpha], [Expected price rise with a thirty-minute half-life], [Makes delay economically costly even before risk is considered],
  [Constraints], [Maximum POV, price limit, venue restrictions], [Removes otherwise attractive actions from the feasible set],
  [Risk preference], [Limit shortfall variance or tail loss], [Determines how much uncertainty the trader will accept to reduce expected impact],
)

Two orders with the same side and quantity can therefore require very
different policies. A benchmark-sensitive index order, a short-lived alpha
trade, and a portfolio rebalance may look identical in an order database while
representing different control problems.

== Inventory is the state that cannot be ignored

Divide the trading window into decision times $k=0,1,...,N$. Let $Q>0$ denote
the total quantity of a buy order and let $X_k$ be the quantity still unfilled
immediately before decision $k$. If $x_k$ shares execute during the next
interval, then

$
  X_(k+1) = X_k - x_k,
  quad X_0 = Q.
$

Mandatory completion requires $X_N=0$, or equivalently

$
  sum_(k=0)^(N-1) x_k = Q.
$

This accounting identity is simple, but it gives execution its intertemporal
structure. Trading more now reduces future inventory. Trading less now
preserves flexibility, but it also leaves more quantity exposed to later price
moves and a shorter remaining horizon.

The symbol $x_k$ above means *executed* quantity, not necessarily submitted
quantity. With a marketable order, the distinction may be small over a coarse
interval. With a passive order, the algorithm chooses a submitted size and
price, while the resulting fill is random. Inventory then evolves as

$
  X_(k+1) = X_k - F_(k+1) (u_k),
$

where $u_k$ is the order-placement decision and $F_(k+1)$ is the fill produced
by subsequent market events. This is one reason passive execution cannot be
modeled by assigning a fixed negative spread cost to limit orders: the fill
itself is part of the uncertainty.

In continuous time, a market-order-rate model writes

$
  dif X_t = -v_t dif t,
  quad X_0=Q,
$

where $v_t$ is measured in shares per unit time. The discrete and continuous
representations describe the same inventory logic. Which one is more useful
depends on the decisions being modeled. Bucketed schedules are naturally
discrete. Fine-grained order placement and diffusion models are often written
in continuous time.

== The market state is more than the price

Inventory and time remaining are always relevant, but they are rarely a
sufficient description of the execution environment. At decision time $k$, a
useful state might contain

$
  Z_k = (
    X_k,
    tau_k,
    m_k,
    s_k,
    D_k,
    hat(V)_k,
    hat(sigma)_k,
    a_k,
    I_k
  ).
$

Here $tau_k$ is time remaining, $m_k$ is the midprice, $s_k$ is the quoted
spread, and $D_k$ summarizes displayed depth or queue conditions.
$hat(V)_k$ is a forecast of market volume, $hat(sigma)_k$ is a
volatility estimate, $a_k$ represents short-horizon alpha or urgency, and $I_k$
is a state variable carrying the lingering effect of recent trading.

This list is illustrative, not compulsory. A state should not contain every
available field merely because storage is cheap. It should contain enough
information to compare the consequences of the available actions. If recent
order flow changes the distribution of future fills, then some summary of that
flow belongs in the state. If a variable improves a forecast but leaves every
action comparison unchanged, it may not be useful to the controller.

#definition("decision state")[
  A decision state is a summary of the information needed to evaluate future
  costs and feasible actions from the current time onward. Calling a collection
  of variables a state is a modeling claim: once the state and current action
  are known, older history should not contain material additional information
  about the modeled future.
]

The action is also richer than a trading rate. A practical action can be
written schematically as

$
  u_k = (
    "submitted size",
    "aggressiveness",
    "limit price",
    "venue allocation",
    "cancellation rule"
  ).
$

Later chapters separate these choices because they operate on different time
scales. For now, it is useful to remember that “trade ten percent POV” describes
only one component of an execution policy.

Everything the algorithm does not choose enters as uncertainty: future price
innovations, market volume, spread and depth, other traders' orders,
cancellations, venue latency, and whether passive orders fill. Some of these
quantities are forecastable; none is known exactly.

== What the algorithm is allowed to know

Let $cal(F)_k$ represent the information available immediately before action
$u_k$ is chosen. It contains the history of observable market data, the
algorithm's earlier actions, and fills received by that time. A valid policy
has the form

$
  u_k = pi_k (cal(F)_k).
$

It cannot use the closing volume, the next quote, or a corrected market-data
record that became available after the decision. This may sound obvious, but
many attractive historical strategies fail precisely because the research
table quietly contains future information.

#definition("admissible policy")[
  A policy is admissible if each action uses only information available at
  that time and respects the trading problem's operational and mathematical
  constraints. A backtest that uses future information evaluates a policy that
  could not have been run.
]

The filtration notation is not mathematical decoration. It forces every
feature to carry a timestamp and every forecast to be judged against what was
knowable when the action was taken.

== Measuring cost against the instruction

Let $P_k$ be the average price paid for the $x_k$ shares bought in interval
$k$, and let $m_0$ be the midprice when the parent order arrived. If the order
is completed, its dollar implementation shortfall is

$
  C_"IS" = sum_(k=0)^(N-1) x_k (P_k - m_0).
$

Dividing by $Q m_0$ expresses the same cost as a return; multiplying by
$10^4$ expresses it in basis points. The benchmark and normalization must be
stated because “ten basis points of cost” is otherwise incomplete.

For a marketable buy order, it is useful to write the execution price as

$
  P_k = m_k + s_k/2 + h_k (x_k; L_k),
$

where $L_k$ denotes the liquidity state and $h_k$ is the additional price
concession caused by size, speed, or book consumption. Substituting this into
implementation shortfall separates three ideas:

- the half-spread and fees paid to demand immediacy;
- the liquidity or impact cost associated with the chosen action; and
- the movement of the midprice while inventory remains unexecuted.

The separation is conceptually helpful, but it is not automatically a causal
decomposition. The market state affects both the action and the observed cost,
and the trader's own action can affect the later market state. Chapter 3
returns to what can actually be identified from transaction-cost data.

If incomplete orders are permitted, the accounting must say how remaining
inventory is valued. One convention marks the unfilled quantity at the end of
the horizon:

$
  C_"reported"
  =
  sum_(k=0)^(N-1) x_k (P_k - m_0)
  + X_N (m_N - m_0).
$

That expression measures the price movement on what was not bought, but it
does not by itself make completion desirable. A control objective therefore
needs either the hard condition $X_N=0$ or a terminal penalty $Phi (X_N)$ that
represents the economic cost of leaving the instruction unfinished. Without
one of them, “do not trade” can become an apparently optimal solution.

== The basic tension: immediacy versus exposure

The cleanest way to see the execution trade-off is to study a deliberately
simple model. Suppose the spread is constant, there is no alpha or price risk,
and temporary impact per share is linear in the trading rate:

$
  h (v_t) = eta v_t,
  quad eta > 0.
$

The impact portion of dollar cost is then

$
  C_"impact" = integral_0^T eta v_t^2 dif t.
$

Completion requires $integral_0^T v_t dif t=Q$. By the
Cauchy-Schwarz inequality,

$
  integral_0^T v_t^2 dif t
  >=
  1/T (integral_0^T v_t dif t)^2
  =
  Q^2/T.
$

Equality holds when $v_t=Q/T$. In this narrow model, a uniform schedule is
optimal. The result is not a universal defense of TWAP. It says something more
specific: if the only schedule-dependent cost is a time-homogeneous convex
penalty on speed, spreading the order evenly avoids expensive bursts.

For the running order, uniform trading means roughly 44,444 shares every ten
minutes. If the forecast volume is also uniform, that corresponds to ten
percent participation. Doubling the allowed horizon would halve the model's
impact cost, since $eta Q^2/T$ is inversely proportional to $T$.

Real execution immediately breaks the assumptions behind this conclusion.
Volume is not uniform. Spread and depth change. The alpha may decay. Price risk
accumulates while inventory remains. Impact can persist and recover. Once these
effects enter, the best schedule need not be flat.

#intuition[
  Trading fast pays for immediacy. Trading slowly rents exposure to the future.
  The execution problem is the choice of which cost to bear, when to bear it,
  and how that choice should change when the market evolves.
]

== Price risk and alpha make waiting costly

Suppose the unaffected midprice follows

$
  dif m_t = mu_t dif t + sigma_t dif W_t.
$

For a completed buy order, integration by parts gives

$
  integral_0^T v_t (m_t - m_0) dif t
  =
  integral_0^T X_t dif m_t.
$

This identity gives a useful interpretation of timing cost. Until a share is
bought, it remains exposed to future price movement. Conditional on current
information, the expected contribution is approximately

$
  E lr([integral_0^T X_t mu_t dif t]),
$

and the variance of the diffusion contribution is governed by

$
  E lr([integral_0^T X_t^2 sigma_t^2 dif t]).
$

For a buy order, positive expected drift makes delay expensive and encourages
front-loading. Negative short-term drift can justify patience. Even when the
expected drift is zero, a risk-averse trader may execute earlier because a
large remaining inventory amplifies exposure to price uncertainty.

This is where alpha decay enters. An alpha signal is not merely another feature
in an impact regression. It changes the economic cost of waiting. A strong but
short-lived signal can rationally produce a more aggressive schedule than a
larger signal expected to persist for several hours.

A common local objective combines these considerations:

$
  J (pi)
  =
  E^pi lr([
    integral_0^T (
      v_t (s_t/2 + h (v_t, L_t))
      + X_t mu_t
      + lambda/2 sigma_t^2 X_t^2
    ) dif t
    + Phi (X_T)
  ]).
$

The first term pays for liquidity, the second represents expected delay cost,
the third penalizes inventory risk, and the terminal term handles unfinished
quantity. This objective is a model, not a definition of best execution.
Different clients, benchmarks, and mandates imply different terms.

Classical optimal-execution models make versions of this trade-off precise
@bertsimas1998 @almgren2001. Their value is not that one closed-form trajectory
fits every order. They provide a disciplined reference point: changing an
assumption should change the policy for an intelligible reason.

== Benchmarks change the problem

Arrival-price shortfall rewards avoiding adverse price movement after the
order arrives. A VWAP benchmark asks whether the execution tracked the prices
available over an interval. A close benchmark may reward trading near the
auction even when doing so increases arrival shortfall.

Consider the same 400,000-share buy order under two instructions.

- If the benchmark is arrival price and the signal predicts a near-term price
  rise, early execution is valuable.
- If the benchmark is the 10:00-11:30 VWAP and benchmark risk dominates, a
  volume-shaped schedule may be preferable even if it has greater expected
  arrival shortfall.

Neither policy is intrinsically better. They optimize different definitions of
performance. An execution model that omits the benchmark can therefore be
mathematically consistent and economically wrong.

== Constraints are part of the model

Execution policies operate inside a feasible set. Typical constraints include

- a maximum participation rate relative to observed or forecast market volume;
- minimum or maximum child-order sizes;
- limit prices and price-protection bands;
- restrictions on venues, dark liquidity, auctions, or order types;
- throttles on messages, cancellations, and venue exposure;
- no-buy-after or no-sell-after instructions;
- risk limits and mandatory completion rules.

If market volume in interval $k$ is $M_k$, a realized participation constraint
might be written

$
  0 <= x_k <= rho_"max" M_k.
$

At decision time, however, $M_k$ is not yet known. The algorithm may instead
control submitted rate using a forecast, react to observed prints, or impose a
chance constraint on exceeding the cap. The apparently simple phrase
“maximum twenty percent POV” therefore hides a forecasting and feedback
problem.

Hard and soft constraints should not be mixed casually. A price limit is
usually an action restriction. A preference to remain below a participation
level may be a penalty that can be violated near a deadline. The distinction
determines whether the optimizer may trade through the condition when
completion becomes urgent.

== A schedule is not yet a policy

An *open-loop schedule* is fixed when the parent order begins. It might specify
ten percent of quantity in each of ten buckets. A *feedback policy* specifies
what to do as a function of information observed during the order:

$
  u_k = pi_k (X_k, tau_k, "market observations", "current forecasts").
$

The difference becomes clear when the morning changes.

Suppose the spread widens, displayed ask depth falls, and the price starts
rising. A static schedule keeps following its original path. A feedback policy
must decide whether these observations indicate temporary illiquidity, a
deteriorating opportunity, or both. It may slow down to avoid consuming a thin
book, or accelerate because the cost of waiting now dominates the additional
impact.

The correct response cannot be inferred from “liquidity worsened” alone. It
depends on side, inventory, time remaining, benchmark, alpha, and the expected
duration of the liquidity shock. For a sell order, a fragile bid can be a
reason to accelerate before depth disappears; if the book is replenishing and
the deadline is distant, patience may be more valuable.

Feedback can reduce regret when forecasts are wrong, but it introduces new
problems. The policy can react to noise, switch too often, create unstable
trading rates, or move into regions poorly represented in historical data.
Adaptive execution therefore requires both a state model and rules governing
how strongly the algorithm may react.

== The true state is only partially observed

Displayed depth is not total available liquidity. A queue can contain hidden
intent, cancellations, and orders that will appear only after the price moves.
The current volatility regime and the remaining size of other traders'
metaorders are not directly visible. Even the algorithm's own impact state is
inferred rather than observed.

It is useful to distinguish the latent state $Z_k$ from observations $Y_k$:

$
  Z_(k+1) = F (Z_k, u_k, epsilon_(k+1)),
  quad
  Y_k = H (Z_k, eta_k).
$

The first equation describes how the market and inventory evolve under the
action. The second describes what the algorithm gets to see. If $Y_k$ is not a
sufficient state, the controller can maintain a belief

$
  b_k (z) = P (Z_k = z | cal(F)_k).
$

A belief is simply an explicit representation of uncertainty about the current
state. For example, recent cancellations, trades, and quote replenishment may
shift the probability that liquidity is fragile even when the displayed depth
returns to its earlier value.

This distinction prevents a common conceptual mistake: treating a noisy
estimate as though it were the underlying state. A volatility forecast, volume
curve, or fill probability should carry uncertainty into the decision when
that uncertainty is large enough to change the action.

== Bellman's principle in execution language

Let $V_k (z)$ denote the minimum expected cost from time $k$ onward when the
current state is $z$. If $cal(U)_k (z)$ is the set of feasible actions, then

$
  V_k (z)
  =
  min_(u in cal(U)_k (z)) (
    c_k (z, u)
    + E lr([V_(k+1) (Z_(k+1)) | Z_k = z, u_k = u])
  ).
$

The expectation averages over the possible next states after taking action $u$
from state $z$. The terminal value is $V_N (z)=Phi (z)$. In words, the algorithm
compares the cost paid by acting now with the expected future cost of the state
that action leaves behind. A large aggressive child order may be expensive
immediately but reduce future inventory. A passive order may have a favorable
price if it fills but leave the parent order exposed if it does not.

The recursion also reveals what empirical research must supply:

1. a model of immediate cost, including spread, fees, impact, and fill quality;
2. a transition model for price, volume, liquidity, fills, and any lingering
   impact state;
3. a feasible action set reflecting the actual trading system; and
4. a terminal value for inventory, benchmark risk, and unfinished quantity.

The continuous-time version leads to a Hamilton-Jacobi-Bellman equation. For a
controlled diffusion

$
  dif Z_t = b (Z_t, u_t) dif t + Sigma (Z_t, u_t) dif W_t,
$

the value function formally satisfies

$
  0
  =
  partial_t V
  +
  min_u {
    c (z, u)
    + nabla V^T b (z, u)
    + 1/2 "tr" (Sigma Sigma^T nabla^2 V)
  }.
$

The HJB is not where the modeling begins. It is the compressed result of choices
already made about state, observations, actions, dynamics, costs, and
constraints. An elegant solution to the wrong HJB is still the wrong trading
policy.

== Prediction, causal response, and control

Execution research often moves among three questions without noticing that the
target has changed.

#table(
  columns: (1.05fr, 1.5fr, 1.65fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Question*], [*Quantity of interest*], [*Execution example*],
  [Prediction], [$E lr([Y | X=x])$ under the observed data-generating policy], [What slippage should we expect for an order with these characteristics?],
  [Causal response], [$E lr([Y (u)-Y (u')])$ under an intervention], [How would cost change if participation rose from ten to twenty percent?],
  [Control], [$arg min_pi E lr([C^pi])$ subject to constraints], [Which sequence of actions should the algorithm take as the order and market evolve?],
)

These questions can use some of the same data, but they do not require the same
assumptions. Historical participation was chosen for a reason. Urgent orders
may be traded faster, and they may also arrive when prices are moving
adversely. During an order, an adaptive algorithm may increase participation
after observing a price move. Realized participation is therefore partly a
decision and partly an outcome of the path.

A regression can predict slippage accurately while giving a misleading answer
to “what happens if we trade faster?” Control is especially demanding because
the optimizer needs action-dependent consequences, not just associations under
the old policy.

#research[
  Before an estimated relationship is used in an optimizer, ask what generated
  the historical action. Latent urgency, alpha, liquidity, and early price
  movement can affect both participation and final cost. Predictive accuracy
  alone does not make the participation coefficient causal.
]

This does not make predictive models useless for control. A predictive model
can be valuable when actions remain close to historical support and the complete
policy is validated directly. Stronger claims about intervention require
randomization, natural experiments, valid instruments, or credible assumptions
about confounding. Chapters 4, 7, and 16 develop these distinctions in detail.

== Why model quality must be judged through the policy

Suppose a new liquidity feature improves the impact model's average test error.
That is encouraging, but it does not yet show that execution improved.

The feature may change predictions equally for every feasible action, leaving
the ranking of actions unchanged. It may improve common, inexpensive orders
while remaining wrong for the large orders where the optimizer relies on it.
It may produce unstable local slopes, causing extreme participation
recommendations even though its global fit is good.

For control, three aspects of model error deserve particular attention:

- *Action sensitivity.* Are predicted cost differences between nearby actions
  stable and economically plausible?
- *Support.* Does the proposed policy choose actions that are represented in
  the data used to estimate their consequences?
- *Decision regret.* How much is lost when the policy uses the estimated model
  rather than the unknown true one?

#takeaway[
  A model enters an execution algorithm through comparisons between actions.
  The important errors are therefore the ones that change those comparisons,
  especially near constraints and switching boundaries.
]

This is also why uncertainty should sometimes make a policy less aggressive.
If the model is extrapolating into a thinly observed liquidity regime, a robust
policy may prefer a slightly more expensive action whose consequences are
better understood.

== Units and normalization

Dimensional analysis is an inexpensive defense against confused models.
Suppose $v$ is measured in shares per minute and the per-share temporary impact
is $h (v)=eta v$ dollars per share. Then $eta$ has units
dollars times minutes per share squared. The cost rate

$
  v h (v) = eta v^2
$

has units dollars per minute, and its integral has units dollars.

Normalizations such as $Q/"ADV"$, cost divided by volatility, or time expressed
as a fraction of the trading day can make relationships more stable across
instruments. They also introduce assumptions. Dividing by daily volatility is
not innocuous if the relevant risk is concentrated in a ninety-minute window.
Using ADV without specifying the lookback, session, and treatment of roll days
does not fully define the variable.

Every model should state the units of quantity, time, volatility, cost, and
impact coefficients. If a parameter cannot be interpreted dimensionally, it is
difficult to know whether it can be transferred across horizons or products.

== A practical formulation template

When a new trading problem appears, the fastest route to a useful model is
usually to make the following choices explicit.

1. *Instruction.* What economic task created the order? State the side,
   quantity, horizon, benchmark, and client objective.
2. *Inventory.* What remains to be done, and what happens if it is unfinished?
3. *Information.* What is observed at each decision time, and what is only
   estimated or latent?
4. *Action.* Which decision will the model actually change: speed,
   aggressiveness, price, venue, cancellation, or contract?
5. *Dynamics.* How do inventory, price, liquidity, fills, and impact state
   change after an action?
6. *Cost and risk.* Which immediate and future consequences matter, in what
   units, and against which benchmark?
7. *Constraints.* Which conditions are inviolable, and which may be traded off
   against completion or risk?
8. *Evidence.* Which quantities can be predicted from historical data, which
   require causal interpretation, and how will the resulting policy be
   evaluated?

Once these are specified, choosing a regression, stochastic process, optimizer,
or reinforcement-learning method becomes a narrower technical decision. When
they are not specified, sophistication later in the pipeline usually hides
rather than solves the ambiguity.

== Interview checks

#interview[
  *Why is “minimize expected slippage” not yet a complete objective?* Explain
  what must be said about the benchmark, information set, completion,
  constraints, risk, action space, and the meaning of the expectation.
]

#interview[
  *When would a buy algorithm accelerate after liquidity deteriorates, and when
  would it slow down?* Relate the answer to remaining inventory, time, alpha,
  expected replenishment, and the cost of crossing a thin book.
]

#interview[
  *A feature improves out-of-sample slippage prediction but leaves the chosen
  schedule unchanged. Is it useful?* Discuss action rankings, policy boundaries,
  calibration, tail behavior, and other decisions the feature might affect.
]

#interview[
  *Why is realized participation endogenous?* Give one mechanism present when
  the parent order arrives and another created by adaptation during the order.
]

== Exercises

1. Formulate the running 400,000-share order in nine ten-minute buckets. Define
   inventory, action, observed state, completion, a maximum twenty-percent POV
   rule, and an arrival-price objective.
2. Starting from $min integral_0^T eta_t v_t^2 dif t$, derive the optimal
   schedule when $eta_t$ varies deterministically through the day. Explain why
   the algorithm should trade more when liquidity is cheaper.
3. Add a positive alpha state with exponential decay. Without solving the full
   control problem, explain which terms favor front-loading and how the answer
   changes as the signal half-life increases.
4. Model passive fills as random. Write an inventory transition in which the
   action specifies posted size and the disturbance specifies the fill. What
   must the terminal cost contain?
5. Draw a causal graph involving urgency, realized participation, volatility,
   early price movement, and final slippage. Identify a pre-trade confounder and
   a variable that may be affected by the trading policy.
6. Compare two policies with identical expected shortfall but different tail
   losses and completion rates. Describe three client objectives under which
   their ranking would differ.

== Where the book goes next

This chapter has treated spread, depth, queues, and liquidity state as inputs.
The next chapter opens that black box. It asks how orders interact inside a
limit-order market, what displayed liquidity does and does not reveal, and why
the same submitted quantity can have very different consequences in different
states of the book.
