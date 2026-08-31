#import "../style.typ": intuition, interview, research, takeaway, definition

= Trading as Inference and Control <ch-control-lens>

A parent order is not merely a quantity to split. It is a sequence of decisions
made with partial information while the system changes. Prices move, liquidity
appears and disappears, a signal decays, fills reveal information, and the
trader's own actions may change the market. This is the natural language of
stochastic control.

This chapter develops a reusable representation before choosing a particular
price model or optimizer. The representation is more important than any one
closed-form solution: it tells us which forecasts are relevant, which costs are
missing, and when a backtest is answering the wrong question.

== The canonical execution problem

Suppose a buy order of $Q > 0$ shares arrives at time $0$ and must be completed
by $T$. Let $X_t$ be remaining inventory, so

$
  X_0 = Q, quad X_T = 0, quad d X_t = -v_t dif t,
$

where the trading rate $v_t >= 0$ has units shares per unit time. We use signed
quantities when both sides are needed, but fixing the side initially prevents
sign conventions from hiding the economics.

At time $t$, the algorithm does not observe “the market” as a scalar. A useful
state vector might be

$
  Z_t = (X_t, t, m_t, s_t, D_t, V_t, sigma_t, a_t, q_t, r_t).
$

Here $m_t$ is midprice; $s_t$ is spread; $D_t$ summarizes depth; $V_t$ is
forecast market volume; $sigma_t$ is volatility; $a_t$ is an alpha or drift
state; $q_t$ is queue position; and $r_t$ is a market-resilience or transient-
impact state. Not every model needs every component. Choosing the smallest state
that preserves the decision-relevant future is a central modeling task.

#definition("admissible policy")[
  A policy $pi = {pi_t}$ maps the information available at time $t$ into an
  action: $u_t = pi_t(cal(F)_t)$. It is admissible if it respects information
  timing, trading constraints, and integrability conditions. A backtest that
  uses a feature unavailable at decision time evaluates a non-admissible policy.
]

The action $u_t$ can be a market-order rate, a vector of venue allocations,
limit prices and sizes, cancellation decisions, or a mixture. The disturbance
includes future price innovations, other agents' order flow, fills, volume, and
latency.

== State, observation, and belief

The true economic state is rarely observed. Displayed depth omits hidden and
latent liquidity. The origin and remaining size of a metaorder are unobserved.
The current volatility regime is estimated with error. It is therefore useful
to separate

$
  Z_(t+1) = F(Z_t, u_t, epsilon_(t+1)),
  quad
  Y_t = H(Z_t, eta_t),
$

where $Z_t$ is latent state, $Y_t$ is observed data, and $epsilon, eta$ are state
and observation noise. If the observation is not sufficient for control, the
state becomes a *belief* $b_t(z) = P(Z_t = z | cal(F)_t)$. This converts a
partially observed problem into a fully observed problem on distributions.

#intuition[
  “State” does not mean every column in the feature store. It means the smallest
  summary of history needed to evaluate the consequences of the next action.
  A feature can improve prediction and still be irrelevant to the optimal
  action; another can have weak standalone predictive power yet matter because
  it changes risk or constraints.
]

== Costs: benchmark, cash, and risk

Let $P_t$ be the execution price for a child order. For a buy program, arrival-
price implementation shortfall per share is

$
  "IS" = 1/Q integral_0^T v_t (P_t - m_0) dif t
       + X_T (P_T - m_0)/Q.
$

The second term is an opportunity or terminal penalty if the order is not
complete. In a model with mandatory completion it is zero, but removing it from
the objective without enforcing $X_T=0$ creates the absurd optimal policy of not
trading.

Write the execution price schematically as

$
  P_t = m_t + s_t/2 + h(v_t, L_t),
$

for a buy, where $h$ is instantaneous impact or liquidity cost and $L_t$ denotes
market conditions. The midprice may itself evolve as

$
  d m_t = mu_t dif t + sigma_t dif W_t + g(v_t) dif t + d J_t.
$

The term $g(v_t)$ represents persistent impact and $J_t$ jumps. This separation
already exposes two distinct consequences of speed: trading faster can increase
the paid liquidity cost $h$, while trading slower leaves inventory exposed to
$mu$, $sigma$, and signal decay.

A generic objective is

$
  min_pi E^pi [ integral_0^T c(Z_t, u_t) dif t + Phi(Z_T) ]
  + lambda cal(R)^pi,
$

where $cal(R)$ is a risk functional. Common choices include variance, expected
shortfall, exponential utility, a running inventory penalty
$integral X_t^2 sigma_t^2 dif t$, or hard risk limits. These are not equivalent.
Variance produces convenient linear-quadratic models; tail risk and hard
constraints may produce qualitatively different policies.

== Bellman's principle

In discrete time, let the next state have transition law
$p(z' | z,u)$. The value function is the minimum expected remaining cost:

$
  V_k(z) = min_(u in cal(U)(z)) {
    c_k(z,u) + E[V_(k+1)(Z_(k+1)) | Z_k=z, u_k=u]
  }.
$

The terminal condition is $V_N(z)=Phi(z)$. Bellman's principle says that after
any realized transition, the remaining actions must be optimal for the new
state. The equation contains three inputs that empirical work must supply:

- a transition model for prices, liquidity, volume, fills, and impact state;
- a cost model for spread, fees, impact, risk, and non-completion; and
- a feasible action set representing urgency, participation, venue, and order-
  type constraints.

The continuous-time limit leads to a Hamilton–Jacobi–Bellman equation. For a
diffusion $dif Z_t=b(Z_t,u_t) dif t + Sigma(Z_t,u_t) dif W_t$,

$
  0 = partial_t V + min_u {
    c(z,u) + nabla V^T b(z,u)
    + 1/2 "tr"(Sigma Sigma^T nabla^2 V)
  }.
$

The HJB is not the starting point; it is a compressed statement of the state,
dynamics, objective, and information assumptions already chosen.

#takeaway[
  A better forecast matters only through the Bellman comparison between
  actions. If all feasible actions have nearly the same conditional cost, large
  predictive gains can have little economic value. Conversely, a modestly
  predictive feature can be valuable near a switching boundary.
]

== Prediction, causal response, and control

Three questions are often conflated:

#table(
  columns: (1.05fr, 1.4fr, 1.55fr),
  inset: 5pt,
  stroke: 0.5pt + rgb("d9dde2"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Question*], [*Target*], [*Example*],
  [Prediction], [$E[Y | X=x]$ under the observed policy], [Expected slippage of orders similar to this one],
  [Causal response], [$E[Y(u)-Y(u')]$ under an intervention], [Incremental cost of raising participation from 10% to 20%],
  [Control], [$arg min_pi E[C^pi]$], [Adaptive schedule using impact, alpha, and liquidity state],
)

Historical executions were selected by traders and algorithms. Urgent orders
receive high participation; urgent orders may also arrive during adverse price
moves. A regression of slippage on participation therefore mixes the response
to speed with the reason speed was chosen. High out-of-sample predictive
accuracy does not remove this endogeneity.

#research[
  Before interpreting a feature as an impact driver, draw the data-generating
  graph: latent urgency and alpha influence both the action and future prices;
  liquidity influences action, fills, and cost; early realized price moves can
  cause the policy to adapt. Conditioning on post-decision variables can create
  rather than remove bias.
]

For control, a purely predictive model can still be useful if deployed only
within the support of the historical policy and validated on the decisions it
changes. Structural or causal interpretation requires stronger design:
randomization, valid instruments, natural experiments, explicit behavior-policy
models, or credible assumptions about confounders.

== A dimensional check

Dimensional analysis catches many modeling mistakes. If $v$ is shares/minute,
$X$ shares, $sigma$ dollars/share/sqrt(minute), and the temporary-impact
coefficient $eta$ satisfies $h(v)=eta v$, then $eta$ has units
dollars·minute/share². The cost rate $v h(v)=eta v^2$ has units dollars/minute,
and its integral has units dollars.

Normalizing quantity by ADV, time by a trading day, and cost by volatility can
improve cross-sectional stability, but normalization does not make the data
dimensionless by magic. State the reference horizon and whether volatility is
daily, intraday, or annualized.

== A research workflow derived from the control problem

1. Define decision time, benchmark, horizon, side, and unit of analysis.
2. Specify the action the model will change.
3. List state variables observable before that action.
4. State the counterfactual required: prediction under the current policy or
   response under an alternative action.
5. Build leakage-safe training and evaluation sets.
6. Estimate conditional cost and transition distributions with uncertainty.
7. solve the control problem and test sensitivity to estimation error.
8. Evaluate the complete policy, including fills, constraints, and opportunity
   cost—not just the model's loss.

== Interview checks

#interview[
  *Why is “minimize expected slippage” incomplete?* State at least four missing
  choices. A good answer identifies the benchmark, completion constraint,
  information set, risk criterion, action space, and whether the expectation is
  predictive or interventional.
]

#interview[
  *A feature improves slippage $R^2$ but leaves the schedule unchanged. Is it
  valuable?* Not necessarily. Explain this using action-value differences and
  discuss where the feature could still matter: constraints, tails, calibration,
  or regimes near a policy boundary.
]

#interview[
  *Why might realized participation be endogenous?* Give one pre-trade and one
  within-order mechanism, then propose an empirical design that reduces each
  bias.
]

== Exercises

1. Formulate a ten-bucket buy program with state
   $(X_k, m_k, a_k, V_k)$, action $v_k$, hard maximum participation, and a
   terminal non-completion penalty. Write the Bellman recursion.
2. Add a latent liquidity regime with noisy spread/depth observations. Define
   the belief-state update and explain why the last observation alone is not
   Markov.
3. Compare variance penalization with a 95% expected-shortfall objective. Give a
   scenario in which their optimal schedules differ.
4. Draw a causal graph for slippage, realized participation, volatility,
   urgency, and short-horizon alpha. Identify one variable that is a confounder
   and one that may be post-treatment.
