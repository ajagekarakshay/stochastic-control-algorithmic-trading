#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-six = [
= Almgren–Chriss: Risk, Impact, and the Execution Frontier

The first five chapters established why execution cost is state-dependent, why benchmarks are not causal estimates, and why an adaptive policy must be evaluated as a policy. This chapter now builds the classical bridge from those ingredients to a control rule. Almgren–Chriss is deliberately simple, but it gives an unusually clear answer to the core interview question: *what economic force should make an execution accelerate or slow down?*

#takeaway[
Almgren–Chriss is not a formula for the universally correct schedule. It is a reference control model in which marginal temporary-impact cost is exchanged for marginal inventory risk. Its value is the disciplined decomposition: state the objective, derive the schedule, test limiting cases, estimate the inputs without leakage, and then ask what changes when the assumptions fail.
]

== Case

You must buy $Q=1,000,000$ shares over $T=60$ minutes. Ignore alpha initially. Let $X_t$ be shares remaining and $v_t=-dot(X)_t >= 0$ the buy rate. Assume linear temporary impact and constant volatility. Up to path-independent terms, use

$
  J[X] = integral_0^T [eta dot(X)_t^2 + lambda sigma^2 X_t^2] dif t,
  quad X_0=Q, quad X_T=0.
$

The desk asks whether it should trade uniformly, front-load, or wait for later liquidity. Your task is not merely to quote the hyperbolic-sine solution. You must explain what it assumes, how it would be calibrated, what the inputs mean, and when optimizing it would give a misleading answer.

#pagebreak()
== Questions

=== Q1. What is the control problem actually minimizing? <c06-q01>

Interpret every term in $J[X]$. Why is $eta dot(X)_t^2$ an expected-cost rate, while $lambda sigma^2 X_t^2$ is a risk charge? State the units and the boundary conditions.

#answer-link(<c06-a01>)

=== Q2. Why does inventory risk scale with $X_t^2$? <c06-q02>

Derive the variance contribution of one short interval. What assumptions make the running variance additive, and what would change under autocorrelated returns, stochastic volatility, or a tail-risk objective?

#answer-link(<c06-a02>)

=== Q3. Why is the risk-neutral schedule TWAP-like? <c06-q03>

Set $lambda=0$. Explain the result using both the Euler–Lagrange equation and convexity. Which changes to the model would make a risk-neutral optimum nonuniform?

#answer-link(<c06-a03>)

=== Q4. Derive and interpret the urgency parameter. <c06-q04>

Show that the first-order condition is

$
  eta dot.double(X)_t = lambda sigma^2 X_t,
$

and define $kappa=sqrt(lambda sigma^2/eta)$. How does the schedule change when volatility, risk aversion, impact cost, or horizon changes?

#answer-link(<c06-a04>)

=== Q5. What does $kappa T$ tell you that $kappa$ alone does not? <c06-q05>

For

$
  X_t = Q frac(sinh(kappa(T-t)), sinh(kappa T)),
$

compare $kappa T << 1$, $kappa T approx 1$, and $kappa T >> 1$. Give the fraction completed halfway through when $kappa T=1$.

#answer-link(<c06-a05>)

=== Q6. Why does linear permanent impact not change the basic schedule? <c06-q06>

Explain why a linear permanent-impact term is path-independent for fixed total quantity. What model changes would make persistent impact affect schedule shape, and what economic-consistency checks would then become necessary?

#answer-link(<c06-a06>)

=== Q7. How does alpha enter the execution decision? <c06-q07>

For a buy order, add an expected drift $alpha_t$ and interpret

$
  integral_0^T alpha_t X_t dif t.
$

What does positive, negative, or rapidly decaying alpha do? Why is a dimensionless signal score not yet a valid $alpha_t$?

#answer-link(<c06-a07>)

=== Q8. How do volume forecasts and participation constraints change the solution? <c06-q08>

Translate rate into POV using $v_t=rho_t hat(V)_t$. Explain why a U-shaped volume curve, a maximum POV, and terminal completion can overturn the unconstrained closed form.

#answer-link(<c06-a08>)

=== Q9. How would you estimate $eta$, $sigma$, and $lambda$? <c06-q09>

Separate an empirical parameter, a forecast, and a preference. Discuss selection into trading speed, benchmark choice, heteroskedasticity, regime dependence, and why a good historical fit does not identify a structural impact coefficient.

#answer-link(<c06-a09>)

=== Q10. Distinguish prediction, causal estimation, and control. <c06-q10>

A model predicts realized slippage accurately from realized POV, spread, and volatility. Can you minimize that prediction over POV and call the result optimal? State the three different targets precisely.

#answer-link(<c06-a10>)

=== Q11. What diagnostics matter after the optimizer is attached? <c06-q11>

Suppose cost residuals are small on average but the model underestimates high-POV orders and futures roll periods. What happens to the schedule? Propose model-level and policy-level diagnostics.

#answer-link(<c06-a11>)

=== Q12. When should the static schedule become adaptive? <c06-q12>

Describe a receding-horizon controller. What state is updated, what is re-solved, and which safeguards keep adaptation from becoming unstable or from chasing noise?

#answer-link(<c06-a12>)

=== Q13. Give the 90-second interview answer. <c06-q13>

Respond to: “Explain Almgren–Chriss, tell me what makes the schedule front-loaded, and tell me why you would not deploy the closed form directly.”

#answer-link(<c06-a13>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Expected liquidity cost plus a price-risk charge <c06-a01>

#back-link(<c06-q01>)

$X_t$ is the remaining inventory and $v_t=-dot(X)_t$ is the execution rate. With linear per-share temporary impact $h(v)=eta v$, a child traded at rate $v$ pays approximately $eta v$ per share beyond the unaffected price. Multiplying by shares per unit time gives the expected dollar-cost rate $eta v^2=eta dot(X)^2$.

If $sigma$ is price volatility per square-root time, the instantaneous variance rate of the mark-to-market exposure is $sigma^2 X_t^2$. The multiplier $lambda$ converts that variance into the same objective units as expected cost. It is a risk preference or mandate parameter, not something ordinary price data uniquely estimate.

For dollars, with $X$ in shares, time in minutes, and $sigma$ in dollars per share per square-root minute, $sigma^2X^2$ has dollars squared per minute. Then $lambda$ has reciprocal-dollar units if $J$ is in dollars. Meanwhile $eta$ must make $eta v^2$ dollars per minute. Explicit units matter because mixing annualized volatility with a minute horizon can change urgency by orders of magnitude.

The boundary conditions $X_0=Q$ and $X_T=0$ encode the order and mandatory completion. If $X_T=0$ is relaxed, the objective needs a terminal residual or opportunity-cost penalty; otherwise “do not trade” can appear artificially cheap.

#candidate[
“The model minimizes expected temporary-impact cost plus a charge for carrying unexecuted inventory. Trading faster raises the first term quadratically in rate, while trading slower keeps $X_t$ large and raises exposure to price uncertainty. The completion boundary prevents the model from avoiding cost by leaving the order unfinished.”
]

=== A2. Squared inventory comes from variance, not from a universal law <c06-a02>

#back-link(<c06-q02>)

Over a short interval $Delta t$, suppose the unaffected price innovation is $Delta S=sigma sqrt(Delta t) xi$, where $E[xi]=0$ and $"Var"(xi)=1$. Holding $X_t$ shares exposes execution shortfall to approximately $X_t Delta S$, so

$
  "Var"(X_t Delta S | cal(F)_t) = X_t^2 sigma^2 Delta t.
$

Independent increments make these conditional variance contributions additive, yielding $integral_0^T sigma^2X_t^2 dif t$. Twice the inventory creates twice the dollar exposure and therefore four times the variance.

This is a modeling consequence, not a timeless fact about risk. Predictable or autocorrelated returns introduce covariance across intervals. Stochastic volatility makes the state and penalty time-varying. Jumps and heavy tails can make variance a poor description of what the client fears. Expected shortfall, exponential utility, a benchmark-underperformance probability, or a hard inventory limit can produce different schedules even with the same expected impact.

#interviewer[
*“If I double $sigma$, do I merely double the risk penalty?”*

No. The running variance term increases fourfold because it contains $sigma^2$. In the closed-form schedule, however, $kappa$ doubles. Objective sensitivity and schedule sensitivity are related but not identical.
]

=== A3. Convex rate cost rewards smoothing <c06-a03>

#back-link(<c06-q03>)

With $lambda=0$, minimize $integral_0^T eta v_t^2 dif t$ subject to $integral_0^T v_t dif t=Q$. The Euler equation gives $dot.double(X)=0$, so $X_t=Q(1-t/T)$ and $v_t=Q/T$. Equivalently, Jensen's inequality says a convex function of rate has the smallest time average when the rate is constant for a fixed total quantity.

The result is TWAP-like only because $eta$ and the opportunity set are constant and impact has no transient state. A time-varying liquidity coefficient $eta_t$, volume caps, a U-shaped volume forecast, spread variation, alpha, passive-fill opportunities, resilience, or a nonlinear state transition can make a risk-neutral schedule nonuniform. Even then, the same marginal principle survives: allocate the next share where its expected incremental total cost is smallest, subject to feasibility.

#warning[
Do not say “risk-neutral always means TWAP.” It means TWAP in the constant-coefficient convex-rate model. The conclusion is conditional on the assumed market state being homogeneous through time.
]

=== A4. $kappa$ is the local exchange rate between urgency and liquidity cost <c06-a04>

#back-link(<c06-q04>)

For the Lagrangian $L=eta dot(X)^2+lambda sigma^2X^2$, the Euler–Lagrange equation gives

$
  frac(d, dif t)(2eta dot(X)) - 2lambda sigma^2X = 0,
$

hence $eta dot.double(X)=lambda sigma^2X$. Define

$
  kappa=sqrt(frac(lambda sigma^2, eta)).
$

Larger $lambda$ or $sigma$ raises urgency and front-loads the schedule. Larger $eta$ makes aggressive liquidity consumption expensive and flattens it. A shorter horizon forces a higher average rate even if the shape parameter is unchanged.

Comparative statics should be stated carefully. Doubling volatility doubles $kappa$; quadrupling risk aversion doubles it; quadrupling temporary-impact cost halves it. But the economically relevant shape depends on $kappa T$, while absolute rates must also satisfy the fixed quantity and horizon.

#candidate[
“$kappa$ has units of inverse time and acts like an execution-decay rate. It rises when the cost of holding inventory is large relative to the curvature of trading cost. I would interpret $1/kappa$ as a characteristic liquidation timescale, then compare it with the actual horizon.”
]

=== A5. $kappa T$ measures urgency relative to the available horizon <c06-a05>

#back-link(<c06-q05>)

The solution is

$
  X_t=Q frac(sinh(kappa(T-t)),sinh(kappa T)),
  quad
  v_t=Q kappa frac(cosh(kappa(T-t)),sinh(kappa T)).
$

When $kappa T << 1$, $sinh(x) approx x$ and the inventory path is nearly linear. When $kappa T approx 1$, risk meaningfully front-loads the program while leaving activity throughout the horizon. When $kappa T >> 1$, the characteristic liquidation time is much shorter than the allowed horizon, so most inventory is traded early.

At $t=T/2$ and $kappa T=1$,

$
  frac(X_(T/2),Q)=frac(sinh(0.5),sinh(1)) approx 0.443.
$

Thus approximately $55.7%$ is completed by halfway, compared with $50%$ under TWAP. This numerical check is useful in interviews because it prevents vague claims that $kappa T=1$ implies an extremely aggressive schedule.

The horizon also affects feasibility. If a maximum POV binds, a theoretically large $kappa$ cannot create arbitrary early trading; the controller trades at the constraint until it can rejoin the interior path.

=== A6. Linear permanent impact is a fixed-quantity charge <c06-a06>

#back-link(<c06-q06>)

Suppose permanent displacement is proportional to cumulative executed quantity. The expected cost accumulated while moving from zero to total quantity $Q$ is proportional to

$
  integral_0^Q gamma y dif y = gamma Q^2/2,
$

which does not depend on how $Q$ is distributed through time. It changes total expected cost but not the minimizing schedule in the basic model.

Persistent impact can affect shape if it is nonlinear, time-varying, asymmetric, state-dependent, cross-asset, or decays rather than remaining truly permanent. Those changes make action history part of the control state. They also require no-manipulation checks: an impact specification should not allow an expected-profit zero-net round trip solely because of its kernel or nonlinear response.

#interviewer[
*“Our permanent-impact coefficient changes the optimal path. Is that automatically wrong?”*

Not automatically. It means the term is not the classical linear, path-independent object, or other constraints and states interact with it. I would inspect the exact dynamics and test round trips before interpreting it.
]

=== A7. Alpha gives waiting a directional opportunity cost <c06-a07>

#back-link(<c06-q07>)

For a buy, $alpha_t>0$ means the unaffected price is expected to rise. Every share left in $X_t$ remains exposed to that adverse expected move, producing the running expected cost $alpha_t X_t$. Positive alpha accelerates; negative alpha can reward patience; zero alpha leaves only impact and risk. A rapidly decaying positive signal places more value on early execution because waiting forfeits the forecast before it can be captured.

The forced Euler equation becomes, under the chapter's convention,

$
  eta dot.double(X)_t = lambda sigma^2X_t + alpha_t/2.
$

An ML score or “alpha in volatility units” is not yet a drift. It needs a sign convention, horizon, decay path, calibration from score to expected return, and an out-of-sample uncertainty estimate. Feeding an overconfident score directly into the optimizer can dominate the impact term and create extreme front-loading.

#warning[
Alpha observed in historical executions may also explain why the trader chose a high POV. If omitted from impact estimation, it confounds the cost response; if then added again to control, the same directional movement can be counted inconsistently.
]

=== A8. Real execution is constrained in volume time <c06-a08>

#back-link(<c06-q08>)

Let $hat(V)_t$ be the market-volume rate forecast available at decision time and write $v_t=rho_t hat(V)_t$. Constant POV is uniform in forecast volume time, not calendar time. With a U-shaped forecast, the same participation naturally schedules more shares near the open and close.

A cap $0<=rho_t<=rho_max$ creates a state-dependent rate constraint. Terminal completion requires enough forecast capacity in the remaining buckets. If the unconstrained solution waits too long, the feasible policy may need to trade earlier simply to preserve a completion corridor. If early risk pressure is high, the controller may sit at maximum POV before returning to an interior solution.

Use forecast, not realized future, volume. Full-day realized volume makes a retrospective schedule look feasible with information that the live controller did not have. Receding-horizon updates may use volume observed so far and refresh the remaining forecast, but they cannot use the eventual day total.

Policy implications should be tested under volume forecast error. An apparently optimal back-loaded schedule can become an expensive terminal catch-up if close volume disappoints.

=== A9. $eta$ and $sigma$ are estimated; $lambda$ is chosen <c06-a09>

#back-link(<c06-q09>)

$sigma$ is a horizon-aligned conditional volatility forecast. Estimate it with only information available at the decision time and validate calibration by time of day, product, and regime. A single daily historical volatility rescaled mechanically can miss intraday seasonality, jumps, and futures-roll behavior.

$eta$ summarizes marginal temporary-cost curvature in this model. It can be estimated from child- or parent-order data, but historical speed is endogenous: urgent, informed, or illiquid orders often trade faster. Arrival shortfall also contains market drift and noise. Use pre-action liquidity features, parent-order clustering, time-based holdouts, shape diagnostics, and, where safe, randomized variation in assigned aggressiveness. Be explicit whether the result is predictive reduced form or a causal response usable under intervention.

$lambda$ represents the client's exchange rate between expected cost and risk. It can be elicited from a mandate, calibrated to a desired frontier point, inferred approximately from consistent historical choices, or chosen to satisfy risk limits. Calling it an objectively estimated market parameter hides a business preference inside the statistics.

Diagnostics should include coefficient stability, uncertainty, residuals across size × POV and spread × volatility, and the schedule induced by confidence-region perturbations. Estimation is incomplete until its control consequences are examined.

=== A10. A forecast under the old policy is not an intervention surface <c06-a10>

#back-link(<c06-q10>)

Prediction asks for a conditional outcome under the logged data-generating process, for example

$
  E[C | S=s, A=a].
$

Causal estimation asks how cost changes if the action is intervened upon,

$
  E[C(a)-C(a') | S=s].
$

Control asks for a policy that minimizes cumulative expected cost while accounting for transitions and constraints,

$
  pi^* = arg min_pi E^pi[sum_t c(S_t,A_t)+Phi(S_T)].
$

Realized POV, spread averages, duration, and completion can all be affected by earlier actions and market shocks. A highly accurate predictor may learn that high POV occurs on hard orders rather than learn the marginal effect of raising POV. Minimizing it can extrapolate into state-action combinations absent from the training data and exploit model error.

#candidate[
“I can use the prediction model to forecast costs under the historical policy. To optimize POV, I need credible action comparisons and future-state transitions. I would check overlap, use intended pre-action controls, seek randomized or quasi-exogenous variation, and constrain the policy to supported action regions before treating the surface as causal.”
]

=== A11. The optimizer selects the model's weakest regions <c06-a11>

#back-link(<c06-q11>)

If the model underestimates marginal cost at high POV, the optimizer sees aggressive execution as artificially cheap and chooses more of it. Underestimation near futures rolls can concentrate trading precisely when liquidity migrates and the model has weak support. Average residual error can remain small because the failure occupies a narrow region; optimization makes that region economically dominant.

Model-level diagnostics include chronological holdouts, parent-order splits, calibration and tail residuals by action and regime, derivative or marginal-cost plots, overlap maps, uncertainty intervals, and checks of monotonicity and convex total cost. For futures, slice by days to roll, front-versus-next contract, depth migration, spread, and denominator stability.

Policy-level diagnostics include induced inventory paths, binding-constraint frequency, turnover in target rates, sensitivity to parameter perturbations, terminal residuals under forecast shocks, tail shortfall, and comparisons in a common simulator or randomized trial. Stress alpha sign errors, volatility jumps, stale data, venue outages, and low-volume close scenarios.

#takeaway[
Predictive errors average over the historical action distribution. A controller reweights them toward actions it finds attractive. Validate model derivatives and policy outcomes, not only prediction levels.
]

=== A12. Receding horizon turns a plan into feedback control <c06-a12>

#back-link(<c06-q12>)

A model-predictive execution controller repeats four steps: observe the latest inventory, fills, price, liquidity, volume, volatility, alpha, and transient-impact state; update forecasts over the remaining horizon; solve the constrained remaining-order problem; and execute only the next action before rolling forward.

This adapts to volume forecast errors and changing market state. It also makes actions endogenous to earlier outcomes, so evaluation must compare complete policies rather than regress slippage on realized rates.

Safeguards include maximum participation and child size, terminal-feasibility corridors, rate-of-change limits, hysteresis around switching boundaries, minimum time between large updates, uncertainty buffers, stale-data detection, a static fallback schedule, and kill switches. Without them, a noisy spread or alpha estimate can make the target oscillate, sacrifice queue position, and generate cost not represented in the optimization.

#interviewer[
*“Why not re-optimize after every market-data tick?”*

More frequent decisions do not guarantee better control. If state estimates are noisy and actions have switching, messaging, and queue costs, unconstrained high-frequency re-optimization can chase noise and omit the cost of changing the plan.
]

=== A13. A concise synthesis <c06-a13>

#back-link(<c06-q13>)

#candidate[
“Almgren–Chriss is a benchmark optimal-execution model. Remaining inventory $X_t$ falls as I trade, temporary impact makes high rates costly, and price uncertainty makes carrying inventory risky. With linear per-share temporary impact and a quadratic variance penalty, the objective is $integral[eta dot(X)^2+lambda sigma^2X^2]dif t$. The solution is a hyperbolic-sine inventory path with urgency $kappa=sqrt(lambda sigma^2/eta)$. Higher volatility or risk aversion front-loads; higher impact cost flattens; and as risk aversion goes to zero the schedule approaches TWAP.

I would not deploy the closed form directly because constant volatility and liquidity, mandatory marketable fills, Brownian returns, and a known structural impact coefficient are strong assumptions. In data, speed is endogenous, volume and liquidity vary intraday, alpha may decay, fills are uncertain, and constraints bind. I would estimate horizon-aligned volatility and a leakage-safe conditional cost surface, distinguish predictive fit from causal action response, and stress the induced schedule rather than only the regression.

In production I would solve a constrained receding-horizon version using forecast volume, current inventory, liquidity, alpha, and possibly transient impact. I would add action bounds, terminal-feasibility checks, uncertainty buffers, and a fallback policy, then validate the complete controller with supported off-policy evidence and a staged randomized test.”
]

The reusable structure is: *state the impact–risk trade-off, derive the dimensionless urgency, test limiting cases, identify which inputs are empirical versus preferential, diagnose causal support, and close with a guarded feedback-control implementation.*

== Closing Oral Drill

Answer each aloud in no more than 20 seconds, then give A13 from memory:

1. Why does linear temporary impact create a quadratic rate cost?
2. Where does $X_t^2$ come from, and when might it be inappropriate?
3. Why is the risk-neutral basic solution constant rate?
4. What are the units and economic meaning of $kappa$?
5. What changes when $kappa T$ moves from near zero to well above one?
6. Why is classical linear permanent impact path-independent?
7. How does positive buy alpha change the opportunity cost of waiting?
8. Which of $eta$, $sigma$, and $lambda$ is primarily a preference parameter?
9. Why can minimizing a high-$R^2$ slippage model over POV fail?
10. Name two policy diagnostics that ordinary prediction metrics miss.
11. Why must a volume-constrained optimizer use forecast rather than realized volume?
12. What safeguard would you add first to an adaptive MPC execution policy?
]
