#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-four = [
= Passive versus Aggressive Execution

This chapter adapts Day 4 of the *Execution Interview Drill*: passive versus aggressive execution, queue position, adverse selection, and the hidden cost of apparently free liquidity. The drill tests whether you can value a limit order as a contingent execution rather than simply comparing maker and taker fees.

#takeaway[
A passive order earns the spread only when it fills, and fill probability is highest precisely when the market may be moving through it. The correct comparison is between conditional future cost distributions, including non-fill and adverse selection, not between a zero-spread fill and an immediate spread-crossing fee.
]

== Case

You must buy 100,000 shares over the next 20 minutes. The stock has a 4-cent spread, moderate displayed depth, and rising buy imbalance. You can join the best bid, improve the bid, or cross the offer. A colleague argues that posting is obviously cheaper because it avoids paying the spread and may earn a rebate.

#pagebreak()
== Questions

=== Q1. What is missing from the fee-and-spread comparison? <c04-q01>

List the economic costs of a passive order and the benefits of an aggressive order.

#answer-link(<c04-a01>)

=== Q2. How does queue position create option value? <c04-q02>

Explain why shares ahead, cancellation behavior, and depletion rate matter more than displayed size alone.

#answer-link(<c04-a02>)

=== Q3. What is adverse selection for a limit order? <c04-q03>

Why can a buy limit fill just before the price falls, and how would you measure the loss?

#answer-link(<c04-a03>)

=== Q4. How should fill probability be modeled? <c04-q04>

What state variables, censoring issues, and competing events belong in the model?

#answer-link(<c04-a04>)

=== Q5. How do you value post versus cross? <c04-q05>

Write a simple expected-cost comparison that includes spread, rebate or fee, fill probability, adverse selection, non-fill cost, and timing risk.

#answer-link(<c04-a05>)

=== Q6. When should you cancel or reprice? <c04-q06>

Discuss the trade-off between stale-quote risk, lost queue priority, message costs, and deadline pressure.

#answer-link(<c04-a06>)

=== Q7. How would you estimate passive-order performance causally? <c04-q07>

Why is comparing posted and crossed child orders confounded, and what experiments or quasi-experiments could help?

#answer-link(<c04-a07>)

=== Q8. How does passive execution enter a control problem? <c04-q08>

Specify the state, action set, fill transition, and terminal cost. Why is this not just a static classifier?

#answer-link(<c04-a08>)

=== Q9. Give the 90-second interview answer. <c04-q09>

Respond to: "Posting is free liquidity, so why would you ever cross a four-cent spread?"

#answer-link(<c04-a09>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Passive liquidity has contingent costs <c04-a01>

#back-link(<c04-q01>)

Posting can avoid crossing the spread and may earn a rebate, but the order may not fill. While waiting, the market can rise, causing a buy order to chase at a worse price. A fill can be adversely selected: sellers hit the bid because new information makes the old bid too high. Posting also reveals interest, consumes time, and can leave a large residual near the deadline.

Crossing pays the spread, fees, and possibly market impact, but it gives immediate inventory reduction, eliminates near-term non-fill risk for the executed quantity, and captures short-lived alpha. The correct action depends on urgency, queue state, toxicity, expected price move, remaining inventory, and future liquidity opportunities.

#candidate[
"Posting is not free; it exchanges an explicit spread cost for a contingent fill. I would value the probability and timing of a fill, the markout conditional on filling, and the cost of the residual if it does not fill. Crossing can be optimal when alpha, imbalance, queue length, or the deadline makes waiting more expensive than the spread."
]

=== A2. Queue position is a claim on future sell flow <c04-a02>

#back-link(<c04-q02>)

An order at the best bid fills only after eligible volume ahead is executed or canceled, subject to venue priority rules and hidden interest. Displayed size is a noisy snapshot; the relevant quantity is effective queue ahead and its stochastic depletion. A deep book can still offer a fast fill if cancellations are high, while a small displayed queue can refill repeatedly ahead of you.

Estimate queue position from acknowledgments and market-data events, then model executions, cancellations, additions, price moves, and your own cancellation as competing events. The value of queue priority grows when expected sell flow is high and adverse-selection risk is low. Canceling and reposting sacrifices that claim, so a one-tick price improvement must be worth both the tick and the lost priority.

=== A3. Fills are informative events <c04-a03>

#back-link(<c04-q03>)

A passive buy fills when sell market orders or marketable limits reach it. Some sellers are liquidity-motivated, but others act because they expect lower prices. Therefore, the conditional return after a fill can be worse than the unconditional return while the order rests. This is adverse selection.

Measure signed markouts at several horizons from the fill-time midquote, adjusted for market and factor returns. Separate bid-ask bounce by using midquotes. Slice by imbalance, spread, volatility, queue age, news, fill mechanism, venue, and whether the quote moved immediately after the fill. The relevant horizon depends on the control decision: milliseconds for routing, seconds for child-order tactics, and longer for parent-order execution.

#warning[
A positive realized spread at the instant of fill does not establish profitability. The quote can move against the order immediately afterward, and a non-filled order's opportunity cost is absent from a fill-only sample.
]

=== A4. Fill modeling is a time-to-event problem <c04-a04>

#back-link(<c04-q04>)

Useful pre-action features include effective queue ahead, recent executions and cancellations at the level, order-flow imbalance, spread, depth, microprice, volatility, venue, queue age, distance from touch, and remaining time. A hazard model estimates the instantaneous probability of fill conditional on survival; flexible survival models can capture nonlinear interactions.

There are competing risks: full or partial fill, cancellation by the policy, price moving away, price moving through the order, venue events, and expiry. Policy cancellation creates informative censoring because the algorithm cancels in risky states. Treating canceled orders as ordinary no-fills biases estimates. Model the historical cancellation policy or use randomized resting-time bands to obtain support.

Calibration is more important than classification accuracy. A model that correctly ranks orders but predicts 80% fill probability when the true probability is 50% can create severe residual and deadline risk.

=== A5. Compare expected continuation values <c04-a05>

#back-link(<c04-q05>)

Let $p_f$ be the probability of a passive fill within the decision horizon. A schematic passive cost for a buy is

$
E[C_"post"] = p_f(-s/2 - r + a) + (1-p_f) C_"nonfill" + C_"signal",
$

where $s$ is spread, $r$ rebate, $a$ conditional adverse-selection markout, and $C_"nonfill"$ is the continuation cost if unfilled. Crossing has

$
E[C_"cross"] = s/2 + f + I(q),
$

with fee $f$ and impact $I(q)$. These expressions are intentionally simplified: fill time, partial fills, changing state, and inventory risk make the true comparison dynamic.

Post when its expected continuation value is lower, not merely when $-s/2-r$ looks attractive. As the deadline approaches, $C_"nonfill"$ rises because the residual must be crossed more aggressively or may fail to complete.

#interviewer[
*"If the passive fill probability is 90%, is posting automatically correct?"*

No. The 90% may occur in highly toxic states; conditional markout and the cost of the remaining 10% can dominate the saved spread.
]

=== A6. Cancellation trades information against priority <c04-a06>

#back-link(<c04-q06>)

Cancel when the expected value of retaining queue priority falls below the value of avoiding stale-quote exposure or moving to a better action. Adverse imbalance, microprice movement, volatility jumps, venue toxicity, and stronger alpha can justify canceling a passive buy and crossing or repricing. Improved conditions can justify keeping a mature queue position even if a myopic model would repost.

Excessive cancellation loses priority, increases message traffic and throttling risk, and can make the policy react to noise. Use hysteresis or minimum-rest logic where appropriate, but do not let a rigid resting rule trap the order during a genuine information shock. Deadline pressure changes the threshold continuously: tolerance for non-fill should shrink as remaining time falls.

=== A7. Historical post-versus-cross choices are selected <c04-a07>

#back-link(<c04-q07>)

Algorithms cross when urgency, alpha, adverse imbalance, or deadline risk is high and post when conditions are favorable. A raw comparison will therefore make passive orders look cheaper even if posting would perform badly in states where the algorithm crossed. Fill-only analysis adds survivorship bias.

Randomize post-versus-cross within a narrow safe region, or randomize a small aggressiveness parameter that encourages one action while preserving risk controls. Queue-position discontinuities, tick-size changes, fee changes, or venue rule changes can provide quasi-experimental variation, but exclusion restrictions must be defended. Evaluate intent-to-treat as well as treatment-on-the-treated because not every posted order fills.

Interference matters: one child order changes the book and the opportunities seen by later children. Randomization and standard errors should usually be organized at the parent-order or larger cluster level.

=== A8. The action changes both inventory and future opportunities <c04-a08>

#back-link(<c04-q08>)

A minimal state contains remaining inventory, time, spread, depth, imbalance, volatility, alpha, queue position, outstanding orders, and recent fills. Actions include cross quantity, post price and quantity, cancel, reprice, or wait. A passive action produces a stochastic fill transition; an aggressive action produces more certain inventory reduction with immediate cost. The terminal penalty prices residual inventory or non-completion.

This is not a static "will it fill?" classifier because the best action depends on the value of the state after fill or non-fill. A 60% fill probability can justify posting early but crossing late. A control policy needs calibrated transitions and costs under alternative actions, not only predictions under the historical action distribution.

=== A9. A concise synthesis <c04-a09>

#back-link(<c04-q09>)

#candidate[
"A passive order avoids the explicit four-cent spread only conditional on filling. Its hidden costs are waiting, non-fill, lost alpha, terminal residual, and adverse selection: a buy limit often fills when sellers know the bid is stale. Crossing pays a visible cost but immediately reduces inventory and timing risk.

I would compare expected continuation values using calibrated fill probability, time to fill, queue ahead, conditional markout, and the cost of chasing if unfilled. I would model cancellations and price moves as competing risks and evaluate all submitted orders, not only fills. Historical post-versus-cross comparisons are confounded because the algorithm crosses in urgent or toxic states, so I would use randomized safe action bands where possible.

The policy should be dynamic. Posting can be right with time, good queue position, and low toxicity; crossing becomes right when alpha, adverse imbalance, remaining inventory, or the deadline makes the non-fill option more expensive than the spread."
]

== Closing Drill

1. What is the economic value of queue priority?
2. Why is a fill-only markout sample biased?
3. Name the competing risks in a passive-order survival model.
4. How can a high fill probability coexist with poor passive performance?
5. Why should the cancel threshold change near the deadline?
6. What does an intent-to-treat estimate measure in a post-versus-cross experiment?
]
