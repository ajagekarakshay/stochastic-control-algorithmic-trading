#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-two = [
= Time of Day, Liquidity, and Confounding

This chapter adapts Day 2 of the *Execution Interview Drill*. Its central puzzle is deliberately close to a real market-impact research problem: apparently lower slippage near the close, despite the intuition that concentrating an order late should be expensive. The drill tests whether you can distinguish volume from liquidity, diagnose selection effects, and convert a surprising empirical result into a defensible model change.

#takeaway[
An intraday pattern is not an explanation. Time of day is a label for a changing joint distribution of volume, spread, depth, volatility, order flow, information, auctions, and trader selection. The research task is to discover which mechanisms move cost and which remain when the trading policy is held comparable.
]

== Case

You estimate arrival-price slippage for comparable buy orders and find that orders executed late in the day have lower average slippage than orders spread through the session. The result survives a simple control for order size and average participation rate. This appears to contradict the intuition that a longer horizon allows more liquidity replenishment and reduces impact.

#pagebreak()
== Questions

=== Q1. Why is the finding counterintuitive but not impossible? <c02-q01>

Give at least four mechanisms that could make late-day executions cheaper even when the same fraction of daily volume is traded.

#answer-link(<c02-a01>)

=== Q2. Why is volume not the same as liquidity? <c02-q02>

What would you measure in addition to the intraday volume curve before calling the close more liquid?

#answer-link(<c02-a02>)

=== Q3. How should time-of-day cost be decomposed? <c02-q03>

Separate spread, mechanical impact, market drift, idiosyncratic drift, timing risk, and benchmark effects.

#answer-link(<c02-a03>)

=== Q4. Where can selection and confounding enter? <c02-q04>

Why might orders traded late differ systematically from orders started early, even after controlling for size and realized POV?

#answer-link(<c02-a04>)

=== Q5. How would you specify the first diagnostic model? <c02-q05>

Propose a regression or flexible predictive model, the required features, interactions, splitting scheme, and residual diagnostics.

#answer-link(<c02-a05>)

=== Q6. How would you seek causal evidence? <c02-q06>

Discuss randomized timing bands, natural experiments, difference-in-differences, and the assumptions each requires.

#answer-link(<c02-a06>)

=== Q7. How do auctions and benchmarks change the result? <c02-q07>

Explain why arrival-price, VWAP, close, and decision-price slippage can tell different stories for the same execution.

#answer-link(<c02-a07>)

=== Q8. What belongs in a production adjustment factor? <c02-q08>

Suppose a time-of-day multiplier improves calibration. How do you keep it from hiding model misspecification or being exploited by an optimizer?

#answer-link(<c02-a08>)

=== Q9. Give the 90-second interview answer. <c02-q09>

Explain the surprising late-day result, the investigation you would run, and the production decision you would make.

#answer-link(<c02-a09>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. A clock-time pattern can have several mechanisms <c02-a01>

#back-link(<c02-q01>)

The naive story is that compressing an order into less time raises participation and consumes liquidity faster than it replenishes. That can be true while the conditional late-day cost is still lower. Near the close, market volume and the number of active counterparties often rise; displayed and latent liquidity may replenish faster; spreads may tighten; uncertainty about the day's information can fall; and natural closing flows can offset the order.

The result may also be statistical rather than structural. Traders may reserve easier, benchmark-insensitive, or low-urgency orders for late execution. Difficult orders may have been started early precisely because they were expected to be costly. Orders with strong adverse alpha may finish early and disappear from the late sample. A close-auction allocation can provide substantial liquidity with different price formation from continuous trading.

#candidate[
"The finding conflicts with a one-variable duration story, not with market microstructure. Late in the day, volume, counterparty arrival, spread, depth, and auction liquidity all change. I would also expect strong selection: the orders that survive to the close may be systematically different from those launched in the morning. I would test mechanisms before turning clock time itself into an explanation."
]

=== A2. Volume measures trading; liquidity measures the cost of trading <c02-a02>

#back-link(<c02-q02>)

Volume is the quantity that transacted. Liquidity is the market's ability to absorb an incremental order with limited price concession and to recover after it. A high-volume interval can be highly liquid because many suppliers compete, or toxic because information and one-sided flow cause everyone to trade while quotes retreat.

Measure quoted and effective spread, depth at several price levels, replenishment after depletion, cancel-to-add behavior, order-flow imbalance, volatility, price impact per signed unit, fill probability, queue turnover, hidden-liquidity indications, venue fragmentation, and auction imbalance. Resilience matters: two books with identical displayed depth can have very different costs if one refills in milliseconds and the other remains depleted.

#interviewer[
*"If volume doubles near the close, should impact per share halve?"*

No. That assumes stable composition and proportional liquidity supply. Volume can rise because informed or urgent demand rises, and the marginal liquidity curve can change independently of total prints.
]

=== A3. Decompose the measured benchmark cost <c02-a03>

#back-link(<c02-q03>)

For a buy order, signed implementation shortfall relative to arrival can be viewed schematically as

$
C_"arrival" = C_"spread" + C_"temporary" + C_"persistent" + C_"market drift" + C_"idiosyncratic drift" + C_"timing/noise".
$

Clock time can affect every term. Spreads and depth follow intraday seasonality. Volatility changes timing variance. The market's conditional return may differ around macro releases or the close. The closing auction changes the execution mechanism. A benchmark can also create apparent seasonality: VWAP cost depends on the market volume distribution, while arrival cost penalizes any adverse movement after the order begins.

Estimate components at the finest defensible event level. Use pre-action spread and depth for expected liquidity cost, market- and factor-adjusted returns for common drift, and post-trade response for evidence about transient displacement. Do not claim the decomposition is observed; it is a model whose assumptions require validation.

=== A4. The late sample is selected by the trading policy <c02-a04>

#back-link(<c02-q04>)

Start time, horizon, urgency, order type, and benchmark are decisions. They depend on client instructions, predicted liquidity, alpha, volatility, overnight news, remaining inventory, and earlier fills. Realized POV and duration are outcomes of both the algorithm and the realized market path. Conditioning only on size and average POV leaves many backdoor paths open.

Completion creates another selection problem. If the dataset contains only completed orders, difficult late-day orders that failed to finish may be missing or recorded differently. Orders that complete early no longer contribute observations to late intervals. Compare parent-order populations at decision time, track censored and canceled orders, and model survival to each interval rather than treating the late sample as an exchangeable subset.

#warning[
Controlling for realized full-day volume, realized duration, or variables measured after the timing decision can introduce post-treatment bias. Features must be aligned to the information set at the decision being evaluated.
]

=== A5. A diagnostic model is a map, not a causal answer <c02-a05>

#back-link(<c02-q05>)

A useful starting specification is a partially pooled model for signed cost per share:

$
C_i = f(Q_i/V_i, P_i, s_i, sigma_i, D_i, "OFI"_i, t_i, h_i, b_i, r_i) + alpha_"symbol" + alpha_"day" + epsilon_i,
$

where $t$ is start time, $h$ horizon, $b$ benchmark, and $r$ regime. Include interactions between time and spread, volatility, participation, and depth; time alone should not be forced to absorb them. A generalized additive model can reveal smooth intraday shapes, while trees or boosting can detect interactions. Shape constraints can preserve monotonic relationships required by the downstream optimizer.

Split by parent order and forward in calendar time. Diagnose residual mean, dispersion, and tails by time bucket, symbol, size, side, liquidity, volatility, and roll or auction regime. Compare calibration, not only $R^2$. Then ask whether adding clock time improves out-of-sample prediction after state variables are included. If the time term vanishes, it was a proxy; if it remains, search for missing state or accept it as a stable reduced-form correction with uncertainty.

=== A6. Stronger designs require stronger operational support <c02-a06>

#back-link(<c02-q06>)

The cleanest design is a safe randomized perturbation: for orders within a narrow eligibility region, randomly vary start time or schedule intensity inside client-approved bounds. Randomization balances observed and latent confounders in expectation. Guardrails, interference monitoring, and sufficient overlap remain essential.

A natural experiment might use an exchange rule change, auction-design change, venue outage, or externally imposed cutoff that shifts timing or liquidity. Difference-in-differences compares the treated change with a credible unaffected control group. Its key assumption is parallel counterfactual trends, not merely similar pre-period averages. An instrumental variable must shift timing but affect cost only through timing; operational thresholds may fail this exclusion restriction if they also change urgency or routing.

When causal identification is unavailable, be explicit: build a predictive conditional cost model, restrict policy changes to supported regions, and validate prospectively. Honest reduced-form evidence is stronger than a structural label attached to an endogenous regression.

=== A7. Cost depends on the question encoded by the benchmark <c02-a07>

#back-link(<c02-q07>)

Arrival price asks how execution performed relative to the price when the order reached the algorithm. Decision price includes delay before arrival and is closer to the portfolio manager's implementation shortfall. VWAP asks whether execution beat the market's volume-weighted average during a specified interval. The close asks about performance versus a terminal valuation point.

A late schedule may look good versus VWAP because it trades when market volume is high, yet look poor versus arrival if price moved adversely while waiting. A close-auction fill can look excellent versus the close by construction while still having substantial opportunity cost versus the investment decision. Benchmarks are not neutral labels; they assign different portions of price movement to the execution process.

Report several benchmarks with a clear decomposition rather than selecting the flattering one. For causal research, avoid using a benchmark whose construction is itself altered by the order or the policy unless that endogeneity is modeled.

=== A8. A production correction needs governance <c02-a08>

#back-link(<c02-q08>)

A time-of-day multiplier is reasonable when it fixes stable out-of-sample calibration after the main state variables are included. Estimate it with shrinkage so sparse buckets do not overreact; require continuity across adjacent times; interact it only where data support the interaction; and track uncertainty and drift.

Test the multiplier inside the control loop. An optimizer may exploit a low predicted late-day cost by deferring inventory, creating completion risk or moving far beyond the historical support from which the correction was estimated. Apply inventory and deadline constraints, uncertainty penalties, overlap checks, and counterfactual stress tests. Monitor whether the apparent edge survives after the policy changes, because deployment alters the data-generating process.

=== A9. A concise synthesis <c02-a09>

#back-link(<c02-q09>)

#candidate[
"Lower late-day slippage is surprising only if I hold the market state and order population fixed. I would not interpret time of day as the cause. Volume rises near the close, but I would distinguish that from liquidity using spreads, depth, replenishment, order-flow imbalance, volatility, and auction participation. I would also test selection: early and late orders can differ in urgency, alpha, benchmark, and completion status.

I would decompose arrival cost into spread, market and idiosyncratic drift, transient response, and timing noise; fit an out-of-sample model with time interactions; and inspect whether the time effect remains after pre-action liquidity variables are included. For causal evidence, I would prefer randomized safe timing bands or a defensible natural experiment. If a stable residual pattern remains, I would use a shrunk time-of-day adjustment, but validate the schedule it induces and constrain the optimizer from deferring into unsupported late-day states."
]

== Closing Drill

Answer aloud in 30 seconds each:

1. Give one example of high volume but poor liquidity.
2. Why can controlling for realized POV create bias?
3. What would make a difference-in-differences design credible?
4. How can the same execution beat VWAP but lose versus arrival?
5. When is a time-of-day multiplier a reasonable reduced-form model?
6. What policy failure occurs if the optimizer overtrusts cheap predicted late-day liquidity?
]
