#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-three = [
= Transient Impact, Resilience, and Schedule Shape <qa-ch03>

This chapter adapts Day 3 of the *Execution Interview Drill*. The drill moves from static cost curves to path dependence: if a child order depletes liquidity and the market later replenishes, then the cost of the next child order depends on both its size and the recent trading path. The central interview skill is distinguishing mechanical decay from information, selection, and changing market state.

#takeaway[
Temporary impact is not merely "impact that goes away." It is a latent state created by past actions and decaying through market resilience. Once cost is path-dependent, two schedules with the same total size, duration, and average POV can have different expected costs.
]

== Case

An algorithm must buy 300,000 shares over 30 minutes. Compare two schedules with the same total quantity:

- *Smooth:* trade 10,000 shares every minute.
- *Bursty:* trade 50,000 shares in each of six short bursts, separated by several minutes of inactivity.

The bursty schedule sometimes costs less in historical data, apparently because prices partially revert during pauses. Does this demonstrate transient market impact and justify deliberate waiting?

#pagebreak()
== Questions

=== Q1. Why can equal-size schedules have different costs? <c03-q01>

Explain the roles of depletion, replenishment, nonlinear instantaneous impact, and the timing of natural market volume.

#answer-link(<c03-a01>)

=== Q2. What exactly is market resilience? <c03-q02>

Define resilience operationally and distinguish book refill, spread recovery, and price-response decay.

#answer-link(<c03-a02>)

=== Q3. How would you write a propagator model? <c03-q03>

State the model, interpret its kernel, and explain how permanent and transient impact appear as limiting cases.

#answer-link(<c03-a03>)

=== Q4. Does post-trade price reversion prove transient impact? <c03-q04>

List alternative explanations for apparent decay after a buy program pauses or completes.

#answer-link(<c03-a04>)

=== Q5. How would you estimate the decay kernel? <c03-q05>

Discuss event time versus clock time, signed-flow autocorrelation, overlapping responses, and regularization.

#answer-link(<c03-a05>)

=== Q6. When are bursts better or worse than smooth trading? <c03-q06>

Reason about concavity, spread crossing, signaling, queue dynamics, volatility, and alpha decay.

#answer-link(<c03-a06>)

=== Q7. Can transient impact models admit manipulation? <c03-q07>

What pathological round trips or oscillating schedules should a valid cost model rule out?

#answer-link(<c03-a07>)

=== Q8. How does a transient state enter stochastic control? <c03-q08>

Specify a minimal state, its transition, and the qualitative form of the optimal policy.

#answer-link(<c03-a08>)

=== Q9. Give the 90-second interview answer. <c03-q09>

Does the bursty result justify pausing, and what evidence would you require before deployment?

#answer-link(<c03-a09>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Impact depends on the action history <c03-a01>

#back-link(<c03-q01>)

A child order can consume displayed depth, widen the effective spread, move the midquote, reveal urgency, and trigger strategic responses from other traders. If the next child arrives before liquidity replenishes, it trades against a depleted state. A pause may allow new limit orders and hidden interest to arrive and the quote to recover.

But batching also increases the instantaneous trading rate. With a convex short-run cost in rate, bursts are expensive. With concave child-order response or fixed costs per interval, batching can appear cheaper. Market volume is uneven, so the same clock-time spacing can produce different participation. The answer depends on the shape of immediate impact, the speed of decay, and what else happens during the pauses.

#candidate[
"The schedules have the same total quantity but not the same state path. Each trade changes the liquidity state seen by later trades. Bursts raise instantaneous pressure but pauses may let spread, depth, and midprice recover. I would compare the marginal cost of a larger burst with the value of allowing the transient state to decay, while also accounting for timing risk and alpha decay during the wait."
]

=== A2. Resilience is multidimensional recovery <c03-a02>

#back-link(<c03-q02>)

Resilience is the speed and extent with which market conditions recover after a liquidity shock. It is not a single observable. Book resilience can mean replacement of depth at the depleted levels. Spread resilience is the return of the quoted spread after it widens. Price resilience is decay of signed midprice displacement. Flow resilience concerns the arrival of offsetting liquidity or the dissipation of order-flow imbalance.

Operational measures include refill half-life, probability and time to restore a depth threshold, spread-normalization time, and the decay of market- and factor-adjusted midprice response. Condition these measures on shock size, side, volatility, time of day, venue, and whether the initial trade was information-laden. A fast book refill with no price reversion is different from a price reversal caused by the market moving for unrelated reasons.

=== A3. The propagator stores the memory of past flow <c03-a03>

#back-link(<c03-q03>)

A discrete propagator model writes the midprice as

$
p_t = p_0 + sum_(s < t) G(t-s) f(v_s) + M_t,
$

where $v_s$ is signed executed volume, $f$ maps volume to immediate impact, $G(t-s)$ is the decay kernel, and $M_t$ is the unaffected price component. If $G(k)$ falls toward zero, the mechanical displacement is transient. If it approaches a positive constant, the model contains a persistent component. An exponential kernel $G(k)=exp(-rho k)$ yields a Markovian impact state with decay rate $rho$.

The kernel is not automatically causal. Signed trading correlates over time, and informed flow predicts future returns. A fitted slow kernel may compensate for omitted alpha or order-flow autocorrelation. The interpretation depends on the joint model for unaffected returns and the policy producing $v_s$.

=== A4. Reversion has competing explanations <c03-a04>

#back-link(<c03-q04>)

Price reversal after a buy pause is consistent with transient mechanical pressure, but also with bid-ask bounce, temporary market-wide reversal, decay of the trader's signal, systematic stopping after adverse conditions improve, or dealers unwinding inventory. Completion time is endogenous: an algorithm may stop when liquidity recovers or when expected returns change.

Use midquotes rather than trade prices, subtract market and factor returns, align on pre-specified pauses rather than only endogenous completions, and compare with matched periods having similar order-flow imbalance but no parent order. Randomized micro-pauses within safe bounds are especially informative. Examine spread and depth recovery alongside price decay; a coherent microstructure response is stronger evidence than a single post-trade return curve.

#warning[
Do not define temporary impact as the observed peak minus a later price. That arithmetic labels every unrelated reversal as liquidity recovery and embeds a chosen horizon into the estimate.
]

=== A5. Kernel estimation is an inverse problem <c03-a05>

#back-link(<c03-q05>)

Regress future midprice changes on lagged signed flow across multiple lags, but account for the strong autocorrelation of trade signs. Naive impulse responses mix the effect of the current trade with predictable future same-sign flow. Jointly model flow and return, use order-level clustering, and prevent child orders from the same parent leaking across train and test sets.

Clock time is natural for replenishment by elapsed seconds; event time is natural when recovery scales with trading activity. Estimate or compare both. Flexible kernels need smoothness, positivity, or monotonic-decay regularization because adjacent lags are collinear. Validate by reconstructing price paths and by predicting the marginal cost of held-out schedule shapes, not only one-step returns.

Useful diagnostics include kernel stability by spread, volatility, time of day, symbol, shock size, and parent-order participation. If the decay rate changes sharply by regime, a single universal kernel is a poor control state.

=== A6. Waiting is valuable only relative to its opportunity cost <c03-a06>

#back-link(<c03-q06>)

Bursts can help when impact decays quickly, refill is strong, fixed spread-crossing decisions can be consolidated, and the market supplies predictable liquidity windows. They can hurt when instantaneous cost is convex, displayed depth is thin, bursts reveal the parent order, volatility is high, or the alpha signal decays while the algorithm waits.

Smooth trading reduces signaling and rate peaks and may maintain queue presence, but persistent participation can prevent the book from recovering. A practical schedule can be adaptive: trade when liquidity is favorable, slow when the transient state is high, and accelerate as deadline or adverse-alpha risk rises. The comparison must use equal completion constraints and include failed or partially completed schedules.

#interviewer[
*"If the price reverted during every pause, would you always wait longer?"*

No. Longer waiting increases inventory exposure and may allow alpha to decay. Reversion can also become smaller at longer pauses, and the deadline eventually makes acceleration unavoidable.
]

=== A7. Economic consistency rules out profitable round trips <c03-a07>

#back-link(<c03-q07>)

A transient-impact model can be pathological if a trader can buy, wait for modeled decay, sell, and earn positive expected profit with zero net position. More complicated price-manipulation strategies alternate signs or front-load one side to exploit an incorrectly specified kernel.

A valid model should make every zero-net-quantity round trip have nonnegative expected execution cost absent alpha. Conditions depend on the chosen impact function and kernel, but positive, suitably regular decay and compatible instantaneous cost are common requirements. Test the calibrated model numerically with oscillating, round-trip, and highly bursty schedules. If an optimizer discovers a strange buy-sell pattern, treat it as a model failure before treating it as a strategy.

=== A8. Add an impact state to inventory and market state <c03-a08>

#back-link(<c03-q08>)

For an exponential kernel, define transient pressure $z_t$:

$
z_(t+1) = exp(-rho Delta t) z_t + eta u_t,
$

where $u_t$ is signed trading rate. A minimal control state is $(q_t,z_t,S_t,t)$: remaining inventory, accumulated transient pressure, observable liquidity state, and time. The cost includes execution against the current pressure, additional instantaneous impact, inventory risk, and terminal penalty.

Qualitatively, the policy trades less when $z_t$ is high and the book is fragile, waits when recovery is fast and timing risk is low, and accelerates when inventory, alpha decay, or the deadline dominates. Estimation uncertainty in $rho$ matters directly: overestimating resilience causes repeated bursts into liquidity that has not actually recovered.

=== A9. A concise synthesis <c03-a09>

#back-link(<c03-q09>)

#candidate[
"The bursty schedule is evidence consistent with transient impact, but it is not proof. Its pauses may let spread, depth, and the midprice recover, yet the result can also reflect when the algorithm chose to pause, natural volume windows, factor reversals, or completion selection.

I would estimate signed midprice response and book recovery after pre-specified shocks, adjust for market returns and predictable order flow, and compare randomized safe micro-pauses where possible. A propagator model would represent past signed flow through a decay kernel, but I would validate the kernel out of sample on schedule-level cost and test that it cannot generate profitable round trips.

In control, I would add transient pressure as a state. Pausing is attractive only when expected recovery exceeds the timing-risk and alpha-decay cost. Before deployment I would stress the policy across uncertain decay rates, thin-liquidity regimes, and deadlines, because overestimating resilience can make the optimizer dangerously bursty."
]

== Closing Drill

1. Distinguish price resilience from depth resilience.
2. Why does signed-flow autocorrelation bias a naive response curve?
3. What does $G(k)$ approaching a positive constant mean?
4. Give two non-impact explanations for post-trade reversion.
5. When does a pause reduce expected total cost?
6. What round-trip test would expose a pathological propagator model?
]
