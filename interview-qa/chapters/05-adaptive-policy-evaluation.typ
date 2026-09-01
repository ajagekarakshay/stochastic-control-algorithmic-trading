#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-five = [
= Adaptive versus Static POV

This chapter adapts Day 5 of the *Execution Interview Drill*. The original drill used twelve questions to compare an adaptive POV policy with a static POV baseline while probing benchmarks, selection, randomized experiments, interference, completion bias, predictive versus causal modeling, and off-policy evaluation.

#takeaway[
An adaptive policy chooses different actions in different states, so its realized orders are not directly comparable with those of a static policy. A credible evaluation must define the benchmark and estimand, preserve the unit of randomization, include incomplete outcomes, and stay within the action support of the logged policy.
]

== Case

A static algorithm targets 15% POV. A new adaptive algorithm varies its target between 5% and 30% using spread, volatility, depth, order-flow imbalance, alpha, remaining inventory, and time to deadline. In a historical backtest, adaptive POV has 3 bps lower VWAP slippage, similar arrival slippage, a lower completion rate, and better results among completed orders.

#pagebreak()
== Questions

=== Q1. Has the adaptive policy won? <c05-q01>

Interpret the reported metrics without selecting a preferred conclusion.

#answer-link(<c05-a01>)

=== Q2. Which benchmark answers which question? <c05-q02>

Compare decision price, arrival price, interval VWAP, and close.

#answer-link(<c05-a02>)

=== Q3. Can the benchmark be endogenous? <c05-q03>

How can the policy affect its own VWAP comparison or the interval over which VWAP is calculated?

#answer-link(<c05-a03>)

=== Q4. What is completion bias? <c05-q04>

Why can the adaptive policy look better among completed orders while being worse for the client?

#answer-link(<c05-a04>)

=== Q5. Why is an observational comparison confounded? <c05-q05>

Explain state-dependent selection of actions and orders into the adaptive policy.

#answer-link(<c05-a05>)

=== Q6. How would you randomize an A/B test? <c05-q06>

Choose the randomization unit, eligibility criteria, guardrails, and primary outcome.

#answer-link(<c05-a06>)

=== Q7. What interference could invalidate the experiment? <c05-q07>

Discuss child orders within a parent, simultaneous firm orders, venue impact, and learning across days.

#answer-link(<c05-a07>)

=== Q8. What is the difference between a predictive and a causal cost model? <c05-q08>

Why can an accurate slippage model fail when used to choose execution speed?

#answer-link(<c05-a08>)

=== Q9. What is off-policy evaluation? <c05-q09>

Explain inverse propensity weighting, the direct method, and doubly robust estimation at an interview level.

#answer-link(<c05-a09>)

=== Q10. What are overlap and support? <c05-q10>

Why is evaluating 30% POV impossible if the historical policy almost never chose it in the relevant states?

#answer-link(<c05-a10>)

=== Q11. How should uncertainty and tail risk enter approval? <c05-q11>

Move beyond average slippage to risk, stability, and policy-level sensitivity.

#answer-link(<c05-a11>)

=== Q12. Give the 90-second research recommendation. <c05-q12>

Would you launch adaptive POV, and what study would you run next?

#answer-link(<c05-a12>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. The metrics describe a trade-off, not a winner <c05-a01>

#back-link(<c05-q01>)

Adaptive POV improves VWAP slippage by 3 bps, has similar arrival slippage, and completes fewer orders. Those facts can coexist. The policy may wait for high-volume intervals and track VWAP better while leaving difficult inventory unfinished. Similar arrival cost suggests the apparent VWAP gain may be benchmark-specific rather than a reduction in total implementation shortfall.

Do not compare completed orders alone. Define the client's objective: full completion by a deadline, risk-adjusted arrival cost, VWAP tracking, alpha capture, or some combination. Include residual inventory, cancellations, opportunity cost, and terminal catch-up. The policy wins only relative to a predeclared utility and estimand.

=== A2. Each benchmark allocates delay differently <c05-a02>

#back-link(<c05-q02>)

Decision price includes the delay from the investment decision through execution and is closest to total implementation shortfall. Arrival price begins when the algorithm receives the order and evaluates the execution process from that point. VWAP measures performance relative to market trading during a chosen interval and is natural for a VWAP mandate. The close is relevant for terminal valuation or close-benchmarked portfolios.

An adaptive policy can improve one and worsen another. Waiting for volume can improve VWAP tracking but lose against arrival during an adverse move. Accelerating on alpha can improve decision-price cost while looking poor versus a later VWAP. Report a benchmark vector and explain which objective the policy optimizes.

=== A3. A benchmark can move with the treatment <c05-a03>

#back-link(<c05-q03>)

If the policy determines completion time and VWAP is computed only over the execution interval, then changing the policy changes both execution prices and the benchmark window. The policy can appear to improve by selecting an easier interval. For large orders, the trading itself can also contribute to market prints and marginally influence VWAP.

Fix benchmark windows ex ante when possible, report full-session and mandate-specific VWAP, and quantify the order's fraction of benchmark volume. Treat policy-dependent horizons as outcomes, not harmless conditioning variables. A client-facing benchmark can remain valid even if endogenous, but it cannot be interpreted as an unaffected causal reference without modeling that dependence.

=== A4. Conditioning on completion selects easy paths <c05-a04>

#back-link(<c05-q04>)

The adaptive algorithm may complete when liquidity is favorable and fail when spread, volatility, or adverse flow makes execution costly. Restricting the sample to completed orders discards precisely the expensive outcomes. The static policy may complete more often by accepting those costs, making its completed sample harder.

Assign every randomized or eligible parent order an outcome. Charge residual inventory using a predeclared terminal rule, record non-completion as a separate risk metric, and analyze time-to-completion. Intent-to-treat preserves the original assignment even if the algorithm deviates or is overridden. Per-completed-order analysis can be a diagnostic, never the primary efficacy estimate.

#warning[
Completion is post-treatment. Matching or controlling on completion can create collider bias and reverse the apparent policy ranking.
]

=== A5. Adaptive actions target selected states <c05-a05>

#back-link(<c05-q05>)

The policy accelerates when alpha, deadline pressure, or predicted liquidity justifies it and slows when spreads or toxicity are high. Therefore, high and low POV observations have different potential outcomes even before the action. If the new algorithm was deployed only to selected clients, symbols, or regimes, policy assignment is also confounded.

A regression that controls for observed state can reduce bias only if the state is measured before action, overlap exists, and no important latent driver remains. Sequence matters: the policy changes inventory and market state, which determines later actions. Parent-level policy evaluation or longitudinal causal methods are needed when child-level treatment changes over time.

=== A6. Randomize at the level of the policy decision <c05-a06>

#back-link(<c05-q06>)

Randomize eligible parent orders to static or adaptive policy before execution. Stratify or block by side, size, liquidity bucket, time, client objective, and perhaps symbol when balance matters. Define eligibility and exclusions before observing outcomes. Preserve identical routing infrastructure and operational support where possible.

Choose one primary outcome aligned with the mandate, such as terminal-penalized arrival shortfall, and predeclare completion and tail-risk guardrails. Cluster uncertainty at the randomization unit. Use small safe traffic initially, staged exposure, real-time kill switches, and a minimum detectable effect calculation. Analyze assignment even when an operator overrides the policy, while reporting compliance separately.

=== A7. One order can change another order's outcome <c05-a07>

#back-link(<c05-q07>)

Child orders within a parent share inventory and impact, so randomizing them independently contaminates both arms. Multiple firm orders in the same symbol can compete for queue position or aggregate into market impact. A policy deployed broadly can change venue behavior, broker routing, and even the liquidity available to the control group.

Randomize at the parent order or at a symbol-time cluster when cross-order interaction is material. Avoid simultaneous opposite-arm orders in the same name when feasible. Measure firm participation and concurrent inventory. If policies learn online, freeze versions within the experiment or treat calendar time as part of the design; otherwise early and late assignments test different policies.

=== A8. Prediction under one policy is not a response surface <c05-a08>

#back-link(<c05-q08>)

A predictive model estimates $E[Y | S=s,A=a]$ in logged data. Using it for control assumes this conditional mean represents what would happen if the action were changed. That fails when latent urgency affects both action and outcome, when action support is sparse, or when the model extrapolates beyond the historical policy.

A causal model targets a potential-outcome contrast such as $E[Y(a)-Y(a') | S=s]$ under identification assumptions. A control model also needs transitions because today's action changes tomorrow's state. High predictive accuracy averaged over historical actions does not guarantee correct action ranking, stable counterfactuals, or a safe optimized policy.

#interviewer[
*"My gradient-boosted model predicts slippage with very high accuracy. Why not minimize it over POV?"*

Because it may have learned the historical policy and confounding. Optimization will query action-state combinations with little support and exploit errors that barely affect average predictive metrics.
]

=== A9. Off-policy evaluation reuses logged decisions carefully <c05-a09>

#back-link(<c05-q09>)

Suppose logged policy $mu(a|s)$ chose action $a$, while target policy $pi(a|s)$ would choose actions differently. Inverse propensity weighting reweights outcomes by $pi(a|s)/mu(a|s)$ so logged observations resemble the target policy. It is unbiased under correct propensities, sequential ignorability, and support, but weights can have enormous variance.

The direct method fits an outcome or value model and predicts target-policy performance. It can be stable but biased by misspecification. Doubly robust estimators combine the model with a propensity-weighted correction and are consistent if either nuisance component is correct under the remaining assumptions. For sequential execution, weights or value functions extend across decisions, making variance and support harder.

Use clipping, diagnostics, and sensitivity analysis, but recognize that no estimator recovers actions absent from the logs. A prospective randomized test remains the decisive step for a material policy change.

=== A10. No data support means no empirical identification <c05-a10>

#back-link(<c05-q10>)

Overlap means that, within relevant states, the logging policy assigned positive probability to the actions the target policy may take. If 30% POV was never used in thin, volatile markets, historical outcomes cannot reveal its effect there. A flexible model will still output a number, but that number is extrapolation.

Plot action distributions and effective sample size by state and regime. Constrain the target policy to supported actions, collect exploration data inside safe bounds, or fall back to a conservative baseline outside support. Treat uncertainty as state-action dependent rather than attaching one global confidence interval to the policy.

=== A11. Approval is a distributional and control decision <c05-a11>

#back-link(<c05-q11>)

Report mean, median, tail quantiles, conditional value at risk, completion probability, terminal residual, dispersion, and worst-regime performance. Check temporal stability, client and symbol heterogeneity, and operational failures. A 3 bps mean gain can be unacceptable if it creates rare large non-completions.

Propagate estimation uncertainty into policy outputs. Perturb impact sensitivity, fill probabilities, alpha decay, and liquidity transitions within plausible regions and observe schedule changes. Large policy changes from small parameter perturbations signal fragility. Require guardrails, fallback behavior, monitoring, and a rollback threshold before broad launch.

=== A12. A concise recommendation <c05-a12>

#back-link(<c05-q12>)

#candidate[
"I would not declare adaptive POV superior from the backtest. It gains 3 bps versus VWAP but not versus arrival and completes fewer orders. The completed-order advantage is likely selected because difficult paths remain unfinished. I would define a primary client objective, include a terminal charge for residual inventory, and keep benchmark windows fixed ex ante.

I would run a parent-order randomized A/B test within a safe common-support region, stratified by size and liquidity. The primary metric would be terminal-penalized arrival shortfall or the mandate-specific benchmark, with completion and tail cost as guardrails. I would cluster at the parent or symbol-time level to handle interference and analyze intent-to-treat.

Before launch I would check action support, off-policy diagnostics, regime stability, and how parameter uncertainty changes the induced schedule. If the randomized test confirms a risk-adjusted benefit without lower completion, I would stage deployment with action bounds and a static-POV fallback."
]

== Closing Drill

1. Why can VWAP improve while arrival cost does not?
2. Why is completion a post-treatment variable?
3. What should be the unit of randomization?
4. Give one example of interference between orders.
5. Why does predictive accuracy not validate policy optimization?
6. What does a large inverse-propensity weight mean?
7. What should the policy do outside historical action support?
8. Name two launch guardrails beyond mean slippage.
]
