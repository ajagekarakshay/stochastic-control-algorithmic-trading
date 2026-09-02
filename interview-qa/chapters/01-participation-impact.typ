#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-one = [
= Participation, Impact, and Causal Interpretation <qa-ch01>

This chapter adapts the first *Execution Interview Drill* from the Prep project into a stand-alone study chapter. The original case and its interview sequence are preserved; wording has been lightly edited so the material reads coherently outside the chat. The questions appear first. Detailed answers and discussion begin in the second half, with links in both directions.

#takeaway[
The case is designed to test whether you can separate a trading outcome from a causal conclusion. A strong execution researcher must reason simultaneously about market impact, exposure to price risk, endogenous controls, liquidity regimes, and what the data can actually identify.
]

== Case

A parent order buys *1,000,000 shares*, approximately *10% of ADV*. Two executions are observed:

#table(
  columns: (1.3fr, 1fr, 1fr),
  inset: 6pt,
  stroke: 0.4pt + rgb("c8cdd3"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*Metric*], [*Execution A*], [*Execution B*],
  [Participation rate], [10% POV], [25% POV],
  [Arrival-price slippage], [8 bps], [15 bps],
  [Completion time], [150 minutes], [70 minutes],
)

The tempting conclusion is that trading faster caused an additional 7 bps of market impact. The interview is about why that conclusion may be directionally plausible yet statistically unjustified from these observations alone.

#pagebreak()
== Questions

=== Q1. What can you conclude from the two executions? <c01-q01>

Interpret the difference between the 10% and 25% POV outcomes. What is observed, what is plausible, and what has *not* been identified?

#answer-link(<c01-a01>)

=== Q2. What is the real trade-off between the schedules? <c01-q02>

Why is it incomplete to compare 8 bps with 15 bps and declare the slower schedule superior?

#answer-link(<c01-a02>)

=== Q3. Why is participation rate endogenous? <c01-q03>

Suppose the algorithm or trader chooses a higher participation rate when volatility rises, liquidity deteriorates, alpha is stronger, or a deadline approaches. What goes wrong in a naive regression of slippage on realized POV?

#answer-link(<c01-a03>)

=== Q4. How would a volatility or liquidity shock change the interpretation? <c01-q04>

Imagine that Execution B encountered a spread widening, a fall in displayed depth, or an adverse price move. Explain how these shocks affect both the measured cost and the chosen control.

#answer-link(<c01-a04>)

=== Q5. How would you separate temporary from permanent impact? <c01-q05>

What price paths, horizons, and benchmarks would you examine? What can post-trade reversion tell you, and what can it not tell you by itself?

#answer-link(<c01-a05>)

=== Q6. What is the right counterfactual? <c01-q06>

For a buy order completed in 70 minutes, what would the stock price have done over those 70 minutes had the order not traded? Why is arrival price not a complete answer to that question?

#answer-link(<c01-a06>)

=== Q7. Why is market impact usually modeled as concave in size or participation? <c01-q07>

Give an economic intuition for a square-root-like response. What limiting cases and empirical diagnostics would you check before trusting the model?

#answer-link(<c01-a07>)

=== Q8. Design a credible empirical study. <c01-q08>

You have a large historical order dataset. How would you estimate the causal effect of trading faster, or at least build a decision-useful impact model, without confusing selection with impact?

#answer-link(<c01-a08>)

=== Q9. How does model error change the optimal policy? <c01-q09>

Suppose your impact model is insufficiently sensitive to trading speed in illiquid futures, or underestimates cost near roll periods. What happens to an optimizer that balances alpha decay against impact?

#answer-link(<c01-a09>)

=== Q10. Give the 90-second interview answer. <c01-q10>

Synthesize the case as if the interviewer asks: "Does the result prove that 25% POV is too aggressive, and what would you do next?"

#answer-link(<c01-a10>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Observation is not identification <c01-a01>

#back-link(<c01-q01>)

The data show an *association*: in these two executions, the faster schedule finished 80 minutes earlier and had 7 bps more arrival-price slippage. This is consistent with the economic mechanism that consuming liquidity more aggressively increases spread crossing, walks deeper into the book, and gives latent liquidity less time to replenish.

It does not identify a causal effect of 7 bps. The executions may differ in volatility, spread, depth, order-book imbalance, market trend, information content, time of day, venue conditions, urgency, or the trader's private signal. The participation choice may itself respond to those variables. With only two outcomes, there is neither a controlled comparison nor enough structure to distinguish impact from the counterfactual price move.

#candidate[
"I observe that the 25% POV execution cost 7 bps more and completed 80 minutes sooner. That is directionally consistent with greater impact from aggressive trading, but I would not call the 7 bps a causal estimate. I first need to control for the market state, order urgency, expected alpha, and the fact that POV was chosen in response to those conditions."
]

#warning[
Avoid saying "25% POV caused 15 bps." The 15 bps is a realized implementation shortfall containing spread, impact, drift, timing, and noise. Even the difference between the two executions mixes these components.
]

=== A2. Expected impact versus timing risk <c01-a02>

#back-link(<c01-q02>)

A slower schedule usually reduces instantaneous pressure on available liquidity, but it leaves more inventory exposed to uncertain price moves. A faster schedule usually increases expected impact but reduces the time during which the unexecuted order can move against the trader.

A stylized objective is

$
min_u quad E[C_"impact"(u)] + lambda "Var"(C_"timing"(u)) - E["captured alpha"(u)],
$

where $u$ is the execution policy and $lambda$ represents risk or urgency. The comparison is therefore not 8 bps versus 15 bps in isolation. It is the distribution of total cost under each policy, conditional on the order's information, benchmark, deadline, and market state.

For a risk-neutral, uninformed order with a flexible deadline, the slower policy may be attractive. For a strong short-lived buy signal, delaying can lose more alpha than it saves in impact. For a hard close benchmark, failure to complete can dominate both terms.

#interviewer[
*"If the slower schedule had lower realized slippage, why not always trade at 10%?"*

Because that conclusion conditions on one realized price path and ignores completion risk, timing variance, and alpha decay. The optimal speed is state- and objective-dependent.
]

=== A3. POV is a treatment chosen by the system <c01-a03>

#back-link(<c01-q03>)

Let $Y$ be slippage, $P$ participation, $X$ observed market conditions, and $U$ latent urgency or information. A naive model

$
Y = alpha + beta P + epsilon
$

attributes all conditional co-movement between $P$ and $Y$ to impact. But in practice

$
P = pi(X, U, "deadline", "remaining inventory"),
$

and $U$ can also affect the subsequent price move. Then $P$ is correlated with the error term, so $beta$ combines the causal effect of aggressive trading with selection into aggressive trading.

There is a second complication: *realized* POV has market volume in its denominator. An algorithm targeting a fixed rate may realize a different POV when volume surprises. Market volume can be jointly related to volatility, news, spreads, and price moves. The feature is partly an outcome of the market path, not merely a clean pre-trade control.

Useful responses include randomized parameter perturbations when operationally safe, encouragement designs, natural experiments, instruments tied to exogenous constraints, matched comparisons on rich pre-trade state, and structural models that explicitly represent the policy. None is automatically valid; each relies on a defensible identification assumption.

=== A4. Shocks create confounding and policy feedback <c01-a04>

#back-link(<c01-q04>)

A spread widening directly raises the cost of liquidity-taking. Falling depth increases the price distance traversed by a marketable child order. Higher volatility increases the variance of the counterfactual price path. An adverse move during a buy order raises arrival slippage whether or not the order caused that move.

At the same time, the execution policy may react: it can accelerate to avoid further adverse movement, slow down when liquidity vanishes, switch order types, or seek alternative venues. Consequently, the market state affects cost both directly and indirectly through the control. Regressing final slippage on an order-level average of realized volatility or spread may introduce post-treatment variables and obscure the event sequence.

A better representation is sequential. At decision time $t$, define a pre-action state $S_t$, action $A_t$, next-state disturbance $W_{t+1}$, fill $F_{t+1}$, and cost increment $C_{t+1}$. Features used to explain $A_t$ must be measured before the action. Evaluation should respect this filtration and avoid leaking future path information into the predictor.

=== A5. Temporary and persistent responses <c01-a05>

#back-link(<c01-q05>)

Temporary impact is the component associated with immediate liquidity consumption that decays as the book replenishes and other traders supply liquidity. Persistent or permanent impact is the non-reverting component, although empirically it is difficult to distinguish information revelation from a mechanical permanent effect.

For buy orders, examine signed price response around child trades and parent-order start, during execution, at completion, and over several post-trade horizons. Useful objects include:

- midquote response rather than transaction-price response, to reduce bid-ask bounce;
- response conditional on signed volume, participation, spread, depth, volatility, and market return;
- decay from the peak or completion-time displacement;
- matched non-trading periods or market/factor-adjusted counterfactual returns; and
- event-time and clock-time views, because replenishment may operate on both clocks.

Reversion after completion supports a transient component, but it is not definitive. Signals may decay, market-wide prices may reverse, traders may systematically stop when expected reversal is high, or execution completion itself may be endogenous. The post-trade window must also be long enough to observe decay without becoming dominated by unrelated information.

=== A6. The missing no-trade price path <c01-a06>

#back-link(<c01-q06>)

The relevant counterfactual is the price path under the same market conditions and information set, but without this order's trading pressure. It is unobserved. Arrival price is a useful benchmark because it is known before execution, yet it does not predict where the price would have gone in the absence of the order.

A practical model decomposes signed implementation shortfall schematically as

$
C_"IS" = C_"spread" + C_"mechanical impact" + C_"market drift" + C_"idiosyncratic drift" + C_"timing/noise".
$

The terms are not directly observed and the decomposition depends on assumptions. Market- and factor-adjusted returns can remove common movement. Matched controls can approximate similar no-trade paths. Short-horizon response models can estimate a baseline conditional on order-book state. A structural propagator can model how signed flow shifts prices. Each method trades stronger assumptions for a sharper decomposition.

=== A7. Concavity and saturation of marginal impact <c01-a07>

#back-link(<c01-q07>)

A common empirical specification is

$
I(Q) = Y sigma (Q / V)^delta, quad 0 < delta < 1,
$

where $Q$ is signed size, $V$ is a liquidity scale such as ADV, $sigma$ is volatility, and $Y$ is a calibration factor. The square-root form uses $delta approx 1/2$.

Concavity says doubling the order does not usually double percentage impact. One intuition is that larger orders are spread across more time and market volume rather than executed as one block. Liquidity supply and strategic response also change with the execution horizon. Another intuition comes from latent liquidity: progressively deeper interest can be revealed as price moves, producing a nonlinear response.

This is an empirical regularity, not a universal law. Check:

- $I(0)=0$ and sign symmetry as first-pass limiting cases;
- monotonicity in $Q/V$ and sensible units after volatility scaling;
- stability of $delta$ across liquidity buckets, regimes, and horizons;
- residual patterns by size, POV, spread, volatility, time of day, and symbol;
- whether the model confuses order size with execution duration; and
- out-of-sample calibration of both mean cost and tail risk.

#warning[
A cross-sectional square-root fit does not prove a structural square-root law. Heterogeneous policies and horizons can manufacture apparent concavity even when local mechanical response differs.
]

=== A8. From historical orders to credible evidence <c01-a08>

#back-link(<c01-q08>)

A defensible study would proceed in layers.

*1. Define the estimand.* Decide whether the target is predictive slippage, the causal effect of changing a control, or a structural response used inside an optimizer. These are different questions.

*2. Build the sample in event time.* Preserve parent-child relationships, reconstruct the information available before each action, and separate arrival, execution, and post-trade windows. Exclude or explicitly model auctions, halts, roll periods, and other special regimes.

*3. Prevent leakage.* Split train and test data by parent order and preferably by time. Child orders from one parent must not appear in both sets. Do not use realized full-order quantities as if known at arrival unless the production policy truly knows them.

*4. Model selection into speed.* Estimate or describe the historical policy using pre-action state. Use overlap diagnostics: if 25% POV appears only in urgent or illiquid states, the data do not support a clean comparison with 10% POV there.

*5. Seek exogenous variation.* The strongest evidence may come from randomized safe parameter bands, operational thresholds, broker routing changes, venue outages, or other changes that shift speed without directly shifting the potential outcome. Validate exclusion and no-anticipation assumptions.

*6. Report uncertainty and heterogeneity.* Use order-level clustered uncertainty, time-based holdouts, regime slices, calibration plots, and sensitivity analysis. Measure the effect of model error on the downstream schedule, not only $R^2$.

For a purely predictive cost model, flexible ML may improve accuracy through nonlinear interactions. For policy choice, prediction under the historical policy is insufficient: the model must behave credibly under actions the optimizer may propose.

=== A9. Policy error can amplify model error <c01-a09>

#back-link(<c01-q09>)

Suppose the optimizer minimizes predicted impact plus an alpha-decay or timing penalty. If predicted impact is too flat in participation for illiquid contracts, accelerating appears artificially cheap. The optimizer can then choose an aggressive schedule exactly where the model is least reliable. Underestimation near futures roll periods creates the same failure: unusually thin or fragmented liquidity is treated as ordinary, and the policy consumes more liquidity than intended.

This is an example of optimizer's curse. Optimization searches for regions with the most favorable predicted trade-off; prediction errors in those regions are selected rather than averaged away.

Mitigations include monotonicity and shape constraints, regime-specific adjustments, conservative uncertainty penalties, action bounds, overlap constraints, stress tests, and policy-level backtests. A useful acceptance test asks: if cost sensitivity is perturbed within its confidence region, how much does the optimal schedule change? Large policy movement from small parameter uncertainty is a control-risk warning.

#candidate[
"I would not judge the impact model only by average prediction error. I would test the induced schedule. If the model is too insensitive to speed, the optimizer will systematically overtrade; near rolls I would add a regime feature or conservative multiplier and constrain the policy until the regime has enough support."
]

=== A10. A concise synthesis <c01-a10>

#back-link(<c01-q10>)

#candidate[
"No. The two executions show that the 25% POV order finished 80 minutes faster and realized 7 bps more slippage, which is consistent with higher impact, but it does not prove that 25% POV caused the difference or is globally too aggressive. Arrival slippage also contains market drift and timing noise, and POV is endogenous because traders accelerate when urgency, alpha, volatility, or liquidity conditions change.

I would first align the orders on information available at arrival and during each decision: size relative to volume and depth, spread, volatility, imbalance, time of day, trend, urgency, benchmark, and deadline. I would examine the midprice path during and after execution for transient response, adjust for market and factor returns, and check whether comparable 10% and 25% observations have overlap. Ideally I would use randomized safe perturbations or another source of exogenous variation.

The trading decision is then a trade-off: faster trading raises expected impact but reduces timing risk and alpha decay. I would estimate that trade-off with uncertainty, test it out of sample by regime, and validate the schedule produced by the model before changing production policy."
]

The structure of this answer is reusable: *state the observation, refuse the unsupported causal leap, name the confounders, define the control trade-off, propose an identification strategy, and close with a policy validation plan.*

== Closing Drill

Answer each prompt aloud in no more than 30 seconds:

1. Why is realized POV not a clean treatment variable?
2. When can a faster execution have higher expected impact but lower expected total cost?
3. What observation would support transient impact?
4. Why does post-trade reversion not prove mechanical decay?
5. What is the difference between predicting slippage and estimating the effect of changing execution speed?
6. How can a small estimation error create a large policy error?

Then give the 90-second synthesis in A10 without looking at the text.
]
