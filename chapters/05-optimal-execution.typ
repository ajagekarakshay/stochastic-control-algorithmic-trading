#import "../style.typ": intuition, interview, research, takeaway, definition

= Optimal Liquidation and Participation Control <ch-optimal-execution>

We now close the loop: use an impact model and a price-risk model to choose a
schedule. Classical optimal execution is valuable not because its assumptions
are literally complete, but because it isolates the central trade-off and makes
comparative statics transparent. It is the reference model against which more
realistic controllers should be understood.

== Why an optimum exists

For a buy order, trading very fast reduces exposure to adverse price movement
and alpha decay but consumes liquidity aggressively. Trading very slowly lowers
instantaneous impact but leaves inventory at risk and may miss the deadline.
An interior optimum arises when marginal urgency benefit equals marginal
liquidity cost.

#intuition[
  Execution speed is an insurance decision. Faster trading pays a more certain
  liquidity premium to reduce an uncertain future-price and non-completion
  exposure. Risk aversion, adverse alpha, and short deadlines buy more insurance.
]

== A discrete control model

Divide the horizon into $N$ intervals. Let $x_k$ be inventory before interval
$k$, $n_k=x_k-x_(k+1)$ shares traded, and $x_0=Q$, $x_N=0$. Suppose

$
  S_(k+1) = S_k + sigma sqrt(Delta t) xi_(k+1) + gamma n_k,
$

and execution price is

$
  P_k = S_k + h(n_k/Delta t).
$

The first equation contains persistent impact and random price movement; the
second adds temporary liquidity cost. With quadratic temporary cost and a
variance penalty, the problem becomes a convex quadratic program. Position,
participation, trading-rate, and completion constraints can be added directly.

Bertsimas and Lo formulate execution as a dynamic optimization of expected cost
@bertsimas1998. Almgren and Chriss make the expected-cost/risk frontier explicit
@almgren2001. Their exact conventions differ, but both demonstrate that optimal
execution is a control problem, not simply a forecast of cost.

== Continuous Almgren–Chriss derivation

Let remaining inventory $X_t$ satisfy $dot X_t=-v_t$, with $X_0=Q$ and
$X_T=0$. Assume an unaffected arithmetic Brownian price

$
  dif S_t = sigma dif W_t
$

and linear temporary impact $h(v)=eta v$. Ignoring path-independent terms, the
mean–variance objective is

$
  J[X] = integral_0^T [eta dot X_t^2 + lambda sigma^2 X_t^2] dif t.
$

The first term is expected temporary cost because $v=-dot X$; the second is the
running variance exposure of unexecuted inventory. The Euler–Lagrange equation
is

$
  eta dot.double(X_t) = lambda sigma^2 X_t.
$

Define $kappa=sqrt(lambda sigma^2/eta)$. Applying the boundary conditions gives

$
  X_t = Q (sinh(kappa(T-t)))/(sinh(kappa T)),
$

and

$
  v_t = Q kappa (cosh(kappa(T-t)))/(sinh(kappa T)).
$

The schedule is front-loaded. As $lambda -> 0$, $kappa -> 0$ and
$X_t -> Q(1-t/T)$: the risk-neutral optimum is constant rate. As risk aversion
or volatility increases, or temporary impact falls, $kappa$ increases and the
program trades earlier.

The characteristic execution time is approximately $1/kappa$. This single
ratio exposes the economics:

$
  "urgency" ~~ kappa = sqrt(("risk pressure")/("liquidity-cost curvature")).
$

== What permanent impact does

With linear permanent impact, the price shift is proportional to cumulative
quantity traded. For fixed total quantity, its expected cost is proportional to
$Q^2/2$ and is path-independent. It changes expected total cost but not the
optimal schedule in the basic model.

This surprising result is a good diagnostic. If a proposed “permanent-impact”
term changes the fixed-quantity schedule, check whether it is actually nonlinear,
state dependent, asymmetric, or mixed with a temporary component. Nonlinear
permanent impact can also admit manipulation and requires no-arbitrage analysis.

== Efficient frontier

Every admissible schedule has expected cost $E$ and variance $V$. Varying
$lambda$ traces an efficient frontier: lower variance generally requires higher
expected impact cost. A desk's urgency setting is therefore an implicit exchange
rate between expected basis points and execution uncertainty.

Mean–variance is convenient but has limitations. Cost distributions are not
Gaussian; impact parameters are uncertain; jumps and fill risk affect tails; and
clients may care about benchmark underperformance probabilities rather than
variance. Expected shortfall, utility, or chance constraints can replace the
quadratic penalty, usually at the cost of closed forms.

== Adding alpha or adverse drift

Suppose the expected price drift relevant to a buy is $alpha_t$ dollars per
share per unit time. Integration by parts shows that expected market-movement
cost contributes

$
  integral_0^T alpha_t X_t dif t.
$

The objective becomes

$
  J[X] = integral_0^T [
    eta dot X_t^2 + lambda sigma^2 X_t^2 + alpha_t X_t
  ] dif t.
$

Positive $alpha_t$ means waiting is expected to be costly and induces earlier
trading; negative drift rewards patience. The Euler equation is now forced:

$
  eta dot.double(X_t) = lambda sigma^2 X_t + alpha_t/2.
$

If alpha decays, for example $alpha_t=alpha_0 e^(-omega t)$, only its value over
the remaining horizon matters. A fast-decaying signal favors capturing value
early; an uncertain signal should be shrunk and incorporated with estimation
risk rather than treated as known.

#research[
  Alpha supplied in “volatility units” needs a horizon. A dimensionless score is
  not a drift until it is mapped to an expected price path and calibrated out of
  sample. Overconfident alpha estimates can dominate impact and create extreme
  schedules.
]

== Nonlinear temporary impact

Let per-share temporary impact be $h(v)=eta v^gamma$ for $v>=0$. The running
dollar cost is $eta v^(1+gamma)$. With risk,

$
  J[X] = integral_0^T [eta (-dot X_t)^(1+gamma)
                       + lambda sigma^2 X_t^2] dif t.
$

The first-order condition is nonlinear. Closed form may disappear, but convexity
is preserved for $gamma>0$. Numerical dynamic programming, direct collocation,
or convex optimization can solve the discretized problem. Concave per-share
impact does not imply a nonconvex total-cost objective.

When the estimated exponent is weak or uncertain, the optimal rate can be
highly sensitive because the controller uses marginal rather than average cost:

$
  d/(dif v) [v h(v)] = eta(1+gamma)v^gamma.
$

This is why impact-surface derivatives deserve direct validation.

== Volume time and POV control

Let forecast cumulative market volume be $M(t)$, with volume rate $dot M(t)$.
A participation policy trades

$
  v_t = rho_t dot M(t).
$

Inventory follows

$
  X_t = Q - integral_0^t rho_s dot M(s) dif s.
$

A constant $rho$ is uniform in forecast volume time. If $dot M(t)$ has a
U-shape, the calendar-time schedule naturally trades more near the open and
close.

An optimal POV controller chooses $rho_t$ by balancing:

- the impact curve's marginal cost of participation;
- expected alpha loss from leaving inventory;
- price and benchmark risk;
- forecast liquidity and its uncertainty;
- minimum/maximum participation and rate limits; and
- terminal completion or residual penalty.

A generic discrete formulation over buckets is

$
  min_(q_1,...,q_N) sum_k [
    C_k(q_k; hat V_k, Z_k) + alpha_k X_k Delta t
    + lambda sigma_k^2 X_k^2 Delta t
  ] + Phi(X_(N+1))
$

subject to

$
  X_(k+1)=X_k-q_k,
  quad 0 <= q_k <= rho_max hat V_k,
  quad X_1=Q.
$

Here $hat V_k$ must be a forecast at the decision time. Using realized bucket
volume in an ex ante optimizer leaks information.

#takeaway[
  A POV is not intrinsically “fast” or “slow.” Its calendar-time speed is the
  product of participation and market volume. The same 10% POV can be gentle in
  an active market and unable to complete in a quiet one.
]

== Time-of-day liquidity and the apparent close advantage

Let temporary-cost scale vary by bucket, $eta_k$. If estimated $eta_k$ is lower
near the close because volume is high and spread is narrow, a cost-only optimizer
back-loads. But several forces oppose it:

- inventory is exposed longer to price and benchmark risk;
- alpha may decay;
- close liquidity is forecast with error;
- auction access and continuous trading differ;
- maximum participation can make late completion infeasible; and
- the historical close coefficient may reflect selected order mix.

The right response to counterintuitive lower close slippage is not to reject it
or hard-code it. Decompose the mechanism, use pre-trade state, test stability,
and let terminal feasibility and risk compete with the estimated liquidity
benefit.

== Receding-horizon control

A static schedule uses forecasts available at arrival. A model-predictive
controller repeats:

1. observe current inventory, fills, prices, volume, and liquidity;
2. update forecasts and impact/resilience state;
3. solve the remaining-horizon problem;
4. execute only the next action; and
5. roll forward.

This handles forecast error and changing conditions while retaining transparent
optimization. It also creates a statistical complication: realized actions are
endogenous to earlier shocks. Evaluation should compare complete policies, not
regress cost naively on their realized controls.

Safeguards include rate-of-change limits, minimum time between major updates,
uncertainty buffers, fallback schedules, and terminal feasibility checks. These
are part of the policy, not engineering details outside the model.

== Sensitivity and model risk

For the classical solution,

$
  kappa = sqrt(lambda) sigma / sqrt(eta).
$

Thus a 1% local increase in volatility or risk-aversion square root raises
urgency approximately proportionally, while a 1% increase in $eta$ lowers
$kappa$ by about 0.5%. This parameter sensitivity does not directly equal
schedule sensitivity when $kappa T$ is very small or very large.

Stress the policy under:

- impact coefficient and exponent uncertainty;
- volume forecast error by bucket and whole day;
- volatility and spread shocks;
- alpha sign error and faster/slower decay;
- roll, auction, and low-liquidity regimes;
- partial fills, outages, and delayed market data; and
- objective mismatch between arrival, VWAP, and close.

A robust controller may optimize worst-case or distributionally perturbed cost.
A simpler and often effective approach is shrinkage, conservative liquidity
forecasts, constraints, and receding-horizon updates.

== Interview checks

#interview[
  *Why is the risk-neutral Almgren–Chriss schedule TWAP-like?* Show that with
  quadratic rate cost and no drift or state variation, Jensen's inequality or
  the Euler equation favors a constant rate.
]

#interview[
  *What happens when volatility doubles?* In the basic model $kappa$ doubles,
  but describe the actual schedule change using $kappa T$ and distinguish this
  from doubling total cost.
]

#interview[
  *A $25$M order trades in a stock with $80$M ADV. Should it front-load?* There
  is no answer from size alone. Discuss horizon, participation capacity, spread,
  volatility, liquidity curve, alpha sign/decay, benchmark, impact curvature,
  and completion risk.
]

#interview[
  *Why can a pause reduce future cost in a transient-impact model but not in the
  basic temporary-impact model?* Identify the added resilience state and its
  decay during the pause; then state the opportunity cost of waiting.
]

== Exercises

1. Re-derive the hyperbolic-sine inventory path from the Euler–Lagrange equation
   and recover the linear schedule as $lambda -> 0$.
2. Prove with Jensen's inequality that a constant rate minimizes
   $integral_0^T v_t^(1+gamma) dif t$ for fixed $integral v_t dif t=Q$ and
   $gamma>0$.
3. Add bucket-specific $eta_k$ and volume caps to a five-period quadratic model.
   Write its matrix quadratic-program form.
4. Create three alpha scenarios—momentum, mean reversion, and zero—and sketch
   how each changes the inventory path.
5. Design an MPC update for an order that falls behind its volume schedule at
   midday. List state updates, forecast changes, constraints, and fallback
   conditions.
