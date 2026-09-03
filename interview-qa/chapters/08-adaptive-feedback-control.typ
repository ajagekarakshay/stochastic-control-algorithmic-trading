#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-eight = [
= Adaptive Execution: Belief States, Feedback, and Receding-Horizon Control <qa-ch08>

Chapter 6 turned impact and inventory risk into an optimal schedule. Chapter 7 enlarged the action space to include contract choice. Both raise the next interview question: what should the algorithm do when the market observed during execution differs from the market assumed at arrival? A production controller must infer a changing state, update a feasible plan, and avoid converting every noisy quote into a costly change of direction.

#takeaway[
Adaptation is not “trade faster whenever conditions look bad.” It is a feedback rule that maps the information available now into an action while accounting for inventory, future opportunities, estimation uncertainty, and the fact that the action itself changes later observations. The object to validate is the closed-loop policy, not merely the accuracy of one forecast or the attractiveness of one revised schedule.
]

== Case

You must buy 600,000 shares over 60 minutes. At arrival, the forecast implies a 10% volume-time schedule. After 20 minutes, only 120,000 shares are complete. Market volume is 30% below forecast, the spread has doubled, displayed ask depth is thin, and your recent child orders appear to leave residual impact. At the same time, a short-horizon signal predicts a modest price increase.

Three proposals arrive:

1. preserve the original share schedule;
2. preserve 10% realized POV and accept possible non-completion; or
3. re-solve every minute using the latest state estimate.

The third sounds sophisticated, but it can be unstable, overfit, or infeasible. Your task is to specify what the controller should know, what it should optimize, and how you would tell whether adaptation creates economic value.

#pagebreak()
== Questions

=== Q1. What makes a schedule adaptive rather than merely revised? <c08-q01>

Contrast an arrival-time schedule, an event-triggered replan, and a feedback policy. Is a rule that recomputes the same static optimizer every minute automatically a good controller?

#answer-link(<c08-a01>)

=== Q2. What is state, what is observation, and what is belief? <c08-q02>

Classify remaining inventory, displayed depth, latent liquidity, alpha, transient impact, and volume regime. Why might the latest order-book snapshot be insufficient for the next decision?

#answer-link(<c08-a02>)

=== Q3. What does the Markov assumption require? <c08-q03>

An engineer feeds the controller the current spread and inventory only. What history may still matter? How would you test whether the proposed state is decision-sufficient without claiming that a residual test proves the market is Markov?

#answer-link(<c08-a03>)

=== Q4. Bellman control or model-predictive control? <c08-q04>

Compare a dynamic-programming policy with receding-horizon optimization. What does model-predictive control gain operationally, and what can it miss if uncertainty is replaced by point forecasts?

#answer-link(<c08-a04>)

=== Q5. How should uncertainty change the action? <c08-q05>

The volume forecast is 80,000 shares for the next bucket, with a wide predictive interval. Explain why plugging 80,000 into a deterministic optimizer is not generally equivalent to optimizing over the distribution. When should uncertainty make the controller more conservative, and when can it increase urgency?

#answer-link(<c08-a05>)

=== Q6. Why are adaptive observations endogenous? <c08-q06>

The algo becomes aggressive after adverse price moves, then aggressive periods have high slippage. Why does a regression of slippage on realized aggression fail to identify the cost of intervening? Include action-dependent observations and transient impact in your answer.

#answer-link(<c08-a06>)

=== Q7. How do you prevent chattering and overreaction? <c08-q07>

If the estimated optimal POV jumps between 8% and 24% as spread and imbalance fluctuate, what costs are missing? Discuss hysteresis, action-rate penalties, commitment intervals, filtering, and trigger thresholds.

#answer-link(<c08-a07>)

=== Q8. How do feasibility and terminal risk constrain feedback? <c08-q08>

With 40 minutes left, 480,000 shares remain and expected market volume is 2.4 million shares. What minimum average participation is required? How should the controller behave as the feasible completion set shrinks?

#answer-link(<c08-a08>)

=== Q9. When does a better prediction have control value? <c08-q09>

A new liquidity model improves out-of-sample $R^2$ but barely changes the action. Another weakly predictive feature often moves the policy near a passive/aggressive boundary. Which is more valuable? Define value in terms of action values or regret.

#answer-link(<c08-a09>)

=== Q10. How would you estimate the response model needed by the controller? <c08-q10>

Distinguish forecasting next-bucket cost under the logged policy from estimating transitions under alternative actions. What role can bounded random perturbations, instruments, or threshold rules play?

#answer-link(<c08-a10>)

=== Q11. How would you evaluate a new adaptive policy offline? <c08-q11>

Explain trajectory-level off-policy evaluation, overlap, importance weights, model-based simulation, and doubly robust estimation. Why is one-step validation inadequate when actions change future states?

#answer-link(<c08-a11>)

=== Q12. What diagnostics and guardrails belong in production? <c08-q12>

Give a prioritized monitoring plan spanning data freshness, belief calibration, constraint activity, action stability, cost tails, regime drift, and fallback behavior. Which failures demand a model update, and which demand a hard control limit?

#answer-link(<c08-a12>)

=== Q13. Give the 90-second interview answer. <c08-q13>

Respond to: “How would you turn a static optimal execution schedule into a robust adaptive controller?”

#answer-link(<c08-a13>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Adaptation is a policy, not a sequence of excuses <c08-a01>

#back-link(<c08-q01>)

An arrival-time schedule maps the initial forecast into a complete action path and then ignores new information. An event-triggered plan is recomputed only after a defined event, such as a fill shortfall or volatility break. A feedback policy specifies an action for every admissible information state:

$
  u_t = pi_t(cal(F)_t).
$

Re-solving a static optimizer every minute creates feedback mechanically, but not necessarily good feedback. If its inputs are noisy point estimates, small quote changes can create large action changes. If it omits the impact left by prior trades, each solve falsely begins from a clean market. If it treats the latest forecast as truth, it ignores learning and parameter risk.

The policy must include the estimator, update cadence, optimizer, action smoothing, constraints, and fallback. Those components jointly determine realized cost. A backtest that swaps only the optimizer while holding post-decision states fixed does not evaluate the actual controller.

#candidate[
“A revised schedule is one new open-loop plan. An adaptive controller is the full mapping from information to actions through time. I would judge the estimator, transition model, constraints, and update rule as one closed-loop policy, because each action changes both inventory and the market state faced next.”
]

=== A2. The controller acts on a belief about the hidden market <c08-a02>

#back-link(<c08-q02>)

Remaining inventory and time are observed nearly exactly. Quotes, trades, fills, queue estimates, and displayed depth are observations. The true liquidity available to a large order, other traders' latent metaorders, alpha regime, and residual own-impact state are only partially observed. Even volume “regime” is inferred from noisy arrivals.

Write a latent state and observation system as

$
  Z_(t+1) = F(Z_t,u_t,epsilon_(t+1)),
  quad Y_t = H(Z_t,u_(t-1),eta_t).
$

The action enters the observation equation because a fill, price response, or depleted book depends on what the algorithm just did. The sufficient information state may therefore be the filtering distribution

$
  b_t(z) = P(Z_t=z mid Y_(0:t),u_(0:t-1)),
$

not the last snapshot. A sequence of refill rates, cancellations, and signed flow can distinguish briefly thin displayed depth from a persistent low-liquidity regime. The belief should carry uncertainty, not only a regime label.

#interviewer[
*“Why not put every feature in the state?”*

Because state is a decision-sufficient summary, not a data dump. Excess features worsen estimation and support, while missing memory causes biased transitions. I would add history only when it improves conditional transition calibration or changes economically relevant action values out of sample.
]

=== A3. Markov means sufficient for the modeled future, conditional on action <c08-a03>

#back-link(<c08-q03>)

A state $S_t$ is Markov for control if, for feasible $u_t$,

$
  P(S_(t+1) mid S_(0:t),u_(0:t))
  = P(S_(t+1) mid S_t,u_t).
$

Current spread and inventory omit recent signed flow, queue depletion, fill history, volume pace, alpha age, and residual impact. The controller may then confuse two identical snapshots with very different continuation distributions.

Diagnostics include whether lagged history improves held-out forecasts of fills, cost, volume, and price after conditioning on state and action; whether probability-integral-transform or classification residuals remain serially structured; and whether policy performance changes when compact memory features or recurrent filters are added. Split by parent order and forward in time.

Failure to find residual dependence is not proof of a Markov market. It is evidence only relative to the measured variables, sample size, model class, and action support. The practical question is whether omitted history changes the ranking of feasible actions enough to matter.

#warning[
Do not test state sufficiency after conditioning on outcomes generated later in the same bucket. Post-action depth, realized volume, and fills can leak the disturbance the controller was supposed to face.
]

=== A4. MPC trades exact global optimality for transparent replanning <c08-a04>

#back-link(<c08-q04>)

Dynamic programming solves continuation values across possible future states:

$
  V_t(s) = min_(u in cal(U)(s))
  {c_t(s,u)+E[V_(t+1)(S_(t+1)) mid s,u]}.
$

It accounts for how today's action changes future options, but a realistic continuous state and action space can make it computationally prohibitive.

Model-predictive control observes the current state, forecasts a finite horizon, solves a constrained remaining-order problem, executes the first action, and repeats. It readily handles inventory, rate, participation, venue, and terminal constraints. It is auditable and can reuse convex execution optimizers.

Naive MPC often substitutes a single expected path for a distribution. It may ignore the value of flexibility, forecast convexity, tail completion risk, and dual control—the possibility that a small action teaches the algorithm about liquidity. Scenario MPC, chance constraints, robust uncertainty sets, and terminal value approximations recover some of that structure.

#candidate[
“I would start with constrained MPC because it is operationally transparent, but I would not call a point-forecast replan fully stochastic. I would include scenarios or conservative bounds where forecast uncertainty changes feasibility or marginal cost, and I would test the terminal-value approximation.”
]

=== A5. Optimize through the distribution, not at its mean <c08-a05>

#back-link(<c08-q05>)

Suppose next-bucket capacity is $V$ and action is participation $rho$, so shares executed are approximately $q=rho V$. For a nonlinear cost or terminal penalty,

$
  E[C(rho,V)] != C(rho,E[V])
$

in general. A mean forecast discards asymmetry: an upside volume surprise creates extra capacity, while a downside surprise can make later completion impossible. Jensen effects also matter whenever impact or penalties are convex.

Uncertainty can reduce aggression when the controller is uncertain whether apparently thin liquidity is persistent, when parameter error could make impact much steeper, or when reversible waiting preserves options. It can increase urgency when delaying risks entering an infeasible completion region, when future volume has a heavy downside tail, or when positive alpha may decay before the order is acquired.

A chance constraint makes the distinction explicit:

$
  P(X_T=0 mid cal(F)_t) >= 1-delta.
$

Alternatively, penalize expected shortfall of execution cost or optimize across an ambiguity set of volume and impact models. Report how much action changes because of uncertainty rather than hiding buffers inside an unexplained urgency parameter.

=== A6. The policy selects the states in which aggression is observed <c08-a06>

#back-link(<c08-q06>)

Aggression is chosen after the algo sees adverse movement, low fills, shrinking time, or positive alpha. Those variables also predict later slippage. Thus

$
  "state shock" -> "aggression",
  quad "state shock" -> "future cost".
$

Within an order, the action also consumes depth, leaves transient impact, changes queue position, and alters subsequent observations. Realized aggression is therefore both selected by history and a cause of future state. Controlling for post-action spread or realized volume can block part of the treatment effect or induce collider bias.

A predictive regression estimates cost patterns under the behavior policy. The causal object required for optimization is a transition or action-value contrast such as

$
  E[C_(t:t+h) mid "do"(u_t=u),S_t=s]
  -E[C_(t:t+h) mid "do"(u_t=u'),S_t=s].
$

Identification needs randomized action variation or defensible assumptions and pre-action covariates. Standard errors should respect parent-order and market-level dependence.

#interviewer[
*“If I control for every order-book feature, is the aggression coefficient causal?”*

Only if those features capture all common causes, are measured before the action, and overlap remains. Latent urgency, private alpha, queue state, and policy overrides make that a demanding claim.
]

=== A7. Stability has an economic value <c08-a07>

#back-link(<c08-q07>)

Rapid switching can lose queue priority, pay repeated spreads, reveal intent, create message and cancellation costs, and interact with latency. It also makes the policy sensitive to measurement noise. A one-period optimizer omits these intertemporal adjustment costs.

Useful controls include:

- a penalty $zeta(u_t-u_(t-1))^2$ on action changes;
- hysteresis, with different thresholds for entering and leaving an aggressive mode;
- minimum commitment intervals or cooldowns;
- filtered beliefs rather than raw snapshots;
- statistically meaningful trigger thresholds; and
- hard maximum changes in participation, size, or price level.

These are not cosmetic smoothing. They change the policy and must enter backtests. Tune them against total parent-order cost and tail behavior, not visual smoothness. Too much inertia is also costly when a genuine regime shift or completion threat requires a fast response.

#takeaway[
A robust controller distinguishes a noisy observation from a persistent state change. Hysteresis prices the option to wait for confirmation; terminal feasibility limits how long that option can be held.
]

=== A8. The viability constraint becomes more important near the deadline <c08-a08>

#back-link(<c08-q08>)

With 480,000 shares remaining and 2.4 million shares of expected market volume, the minimum average participation against that forecast is

$
  rho_min = 480,000 / 2,400,000 = 20%.
$

That is a point estimate, not a guarantee. If maximum participation is 25%, only a narrow forecast shortfall can be absorbed. The controller should compute a viability or reachable set: states from which the order can still finish under action, volume, venue, and risk constraints.

As the boundary approaches, the shadow price of remaining capacity rises. The policy should increase urgency before completion becomes impossible, reserve aggressive capacity, broaden venues or order types where permitted, and surface the risk rather than silently violating constraints. A terminal penalty is useful for soft objectives; a client mandate may require a hard completion constraint or an explicit escalation rule.

The common trap is to preserve realized 10% POV after volume disappoints. That policy adapts to volume mechanically but abandons the parent-order objective.

=== A9. Information is valuable only when it changes a consequential decision <c08-a09>

#back-link(<c08-q09>)

Let $Q(s,u)$ denote expected remaining cost after action $u$ in state $s$. A feature has control value when it improves the choice among actions with materially different $Q$ values. Approximate decision regret is

$
  "Regret" = E[Q(S,hat(pi)(S))-min_u Q(S,u)].
$

An $R^2$ gain concentrated in states where every feasible action is similar can have almost no economic value. A modest signal near a passive/aggressive or slow/urgent switching boundary can prevent expensive errors. Calibration, tail discrimination, and ranking around policy boundaries may matter more than global prediction loss.

Evaluate the new model through frozen-policy simulations first, then through the actions it changes, and finally through a controlled policy experiment. Report incremental cost, completion, risk, turnover, and constraint violations. This separates a forecasting achievement from a control improvement.

#candidate[
“I care about prediction error weighted by decision consequences. The useful model is the one that reduces policy regret in supported states, not necessarily the one with the best unconditional fit.”
]

=== A10. A controller needs action-conditional transitions <c08-a10>

#back-link(<c08-q10>)

A logged-data model for

$
  E[C_(t+1) mid S_t=s,u_t=u]
$

is predictive under the historical selection mechanism. To simulate or optimize a new action, the model needs a credible response for fills, impact, resilience, volume, and price under that intervention. Unmeasured urgency and action-dependent censoring can invalidate a causal reading.

Within safe bounds, randomized perturbations around the incumbent action generate local overlap and identify marginal responses. A deterministic threshold can support regression discontinuity if market states evolve smoothly through it and no other rule changes there. Valid instruments must affect the action without directly affecting future cost except through that action—hard to defend in markets.

Combine experimental variation with structural restrictions such as inventory accounting, monotone fill capacity, convex temporary cost where defensible, and no-manipulation conditions. Extrapolate cautiously: local effects around 10% POV do not identify 40% POV in a stressed book.

#warning[
The optimizer searches for extremes. A response surface that is slightly wrong in sparse action regions can induce a large policy error even when average prediction is excellent.
]

=== A11. Evaluate the whole trajectory under the target policy <c08-a11>

#back-link(<c08-q11>)

For a trajectory $tau=(S_0,U_0,C_0,...,S_T)$ generated by behavior policy $mu$, a basic importance weight for target policy $pi$ is

$
  W(tau)=product_t frac(pi(U_t mid S_t),mu(U_t mid S_t)).
$

If the behavior policy rarely takes a target action, weights explode; if it never does, the target is unidentified from logged data. Sequential dependence compounds this variance. Per-decision weighting, weight clipping, and self-normalization trade variance for bias.

Model-based evaluation simulates transitions and costs, but is vulnerable to model error accumulated through feedback. Doubly robust estimators combine an outcome or action-value model with propensity weighting and can remain consistent if one nuisance component is correct under the relevant assumptions. None fixes absent support or market interference.

Use parent-order trajectories, preserve event timing, cross-fit nuisance models, split forward in time, and cluster uncertainty at market units that share shocks. Compare offline estimates with staged randomized deployment. One-step prediction is inadequate because a different fill now changes inventory, later actions, exposure, and terminal cost.

#interviewer[
*“Why not replay the new actions against the historical order book?”*

Because the historical book evolved after the old actions. A counterfactual child order could consume depth, alter queues, reveal information, and change other participants' responses. Literal replay assumes away the feedback being evaluated.
]

=== A12. Monitor the sensing, thinking, and acting layers separately <c08-a12>

#back-link(<c08-q12>)

Start with data-contract checks: timestamps, stale or crossed quotes, dropped venues, fill reconciliation, corporate actions, and feature availability at decision time. Next monitor belief calibration: predicted fill, volume, volatility, and cost distributions by horizon, symbol, side, liquidity, time, and regime.

Then monitor the controller:

- inventory tracking and terminal-feasibility margin;
- frequency and duration of binding constraints;
- action changes, mode switches, cancellations, and queue loss;
- realized versus predicted marginal cost and post-trade response;
- completion, implementation shortfall, and tail loss at the parent-order level;
- support distance from training data; and
- fallback activations, stale-model age, and recovery time.

A calibration drift with adequate support suggests re-estimation. A new regime with poor overlap calls for conservative behavior and new evidence. Nonsensical actions under plausible parameter stress indicate objective or structural model failure. Hard limits are appropriate for client constraints, maximum participation, exposure, price limits, stale data, and loss containment; they should not be learned from an average cost regression.

Run shadow decisions, canary cohorts, scenario stress tests, and kill-switch drills. Attribute performance to complete policy versions so a model update cannot be separated from its filters, constraints, or fallback.

=== A13. A concise synthesis <c08-a13>

#back-link(<c08-q13>)

#candidate[
“I would define a pre-action information state containing remaining inventory and time, current and forecast liquidity, alpha, volatility, fill and queue information, plus residual own impact. Because much of liquidity is latent, I would maintain a belief with uncertainty rather than treat the latest snapshot as truth.

Operationally I would use constrained receding-horizon control: forecast scenarios, solve the remaining-order problem, execute the first action, and update. The objective includes explicit execution cost, inventory and benchmark risk, completion, and action-change costs. The policy needs viability checks, rate limits, hysteresis, and a fallback schedule so noise does not create chattering or missed completion.

Statistically, I would separate prediction under the logged policy from the causal response to changing participation. I would seek bounded randomized variation and validate action-conditional transitions within support. Offline, I would evaluate whole trajectories with model-based and doubly robust methods, then confirm in a staged experiment. Production approval depends on parent-order value, tails, constraint behavior, calibration, and robustness—not just forecast $R^2$.”
]

== Closing Oral Drill

Answer each in one or two sentences.

1. Why is the latest book snapshot not necessarily a state?
2. What is the difference between replanning and feedback control?
3. When does certainty-equivalent MPC fail?
4. Why can forecast uncertainty increase urgency?
5. What causes chattering, and what is one principled remedy?
6. Why is realized aggression endogenous?
7. What does a viability set tell the controller?
8. Why can a weak predictor have high control value?
9. What breaks importance-weighted off-policy evaluation?
10. What belongs in the policy version besides model weights?

#takeaway[
The static question is “What schedule is optimal under my initial assumptions?” The adaptive question is “Given what I have observed, what do I now believe, which actions remain feasible, and how does acting change both cost and what I will observe next?” That is the step from optimization to closed-loop stochastic control.
]
]
