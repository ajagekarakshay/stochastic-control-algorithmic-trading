#import "../style.typ": answer-link, back-link, candidate, interviewer, takeaway, warning

#let chapter-seven = [
= Futures Execution: Contract Choice, Rolls, and Liquidity Migration <qa-ch07>

Chapter 6 derived an optimal schedule after assuming that quantity, volatility, and temporary impact live in one stable instrument. Futures make every one of those inputs more delicate. Exposure can migrate from one expiry to the next, the cheapest contract can change during the order, and a continuous historical series can hide the contract-level market in which execution actually occurred.

#takeaway[
Futures execution is a joint decision about *when to trade, how fast to trade, and which contract or spread to trade*. Contract choice is part of the control. A model that treats the front month, next month, and roll window as one homogeneous instrument can be well calibrated on average yet fail exactly when liquidity is moving and the execution decision is most sensitive.
]

== Case

A client wants to buy index-futures exposure over 90 minutes during the week in which liquidity is migrating from the front contract $F_1$ to the next contract $F_2$. At arrival:

#table(
  columns: (1.35fr, 1fr, 1fr),
  inset: 6pt,
  stroke: 0.4pt + rgb("c8cdd3"),
  fill: (x, y) => if y == 0 { rgb("eef5fb") },
  [*State*], [*$F_1$*], [*$F_2$*],
  [Recent daily volume], [180,000 contracts], [110,000 contracts],
  [Top-level depth], [900 contracts], [1,300 contracts],
  [Quoted spread], [1 tick], [1 tick],
  [Open interest], [larger], [growing rapidly],
)

The order is large enough that a fixed 20% participation target could interact with displayed liquidity. The client cares about obtaining the exposure, not owning a particular expiry, but the portfolio currently holds some $F_1$. A colleague proposes fitting the ordinary equity-style cost model to a back-adjusted continuous futures series and always routing to whichever expiry printed more volume yesterday.

Your task is to explain why that proposal is incomplete and how to turn contract liquidity, roll risk, and basis dynamics into a defensible execution policy.

#pagebreak()
== Questions

=== Q1. What is the economically correct quantity? <c07-q01>

Should the order be measured in contracts, notional dollars, delta-adjusted exposure, or a risk unit such as DV01? Explain why equal contract counts can represent different risk across products or expiries.

#answer-link(<c07-a01>)

=== Q2. Which contract is actually more liquid? <c07-q02>

$F_1$ has more recent volume, while $F_2$ has greater displayed depth and accelerating activity. Distinguish volume, open interest, spread, depth, trade intensity, and resilience. Which measurements should drive the next child order?

#answer-link(<c07-a02>)

=== Q3. What changes during the roll? <c07-q03>

Describe liquidity migration, participant heterogeneity, calendar-spread activity, and how a fixed “front-month” rule can become discontinuous. Why should days-to-expiry alone be insufficient?

#answer-link(<c07-a03>)

=== Q4. Why can a continuous futures series corrupt TCA? <c07-q04>

Explain back adjustment, artificial jumps at contract switches, and the difference between a research return series and an executable price. Which contract-level fields must be retained?

#answer-link(<c07-a04>)

=== Q5. How should size and participation be normalized? <c07-q05>

Compare $Q/"ADV"$, fraction of displayed depth, realized POV, forecast POV, and risk-normalized size. What leakage or mechanical endogeneity enters if you normalize with realized roll-day volume?

#answer-link(<c07-a05>)

=== Q6. Outright or calendar spread? <c07-q06>

If the portfolio owns $F_1$ but ultimately wants $F_2$ exposure, compare separate outright legs with executing the listed $F_1$–$F_2$ calendar spread. Discuss legging risk, basis risk, queueing, fees, and cross-impact.

#answer-link(<c07-a06>)

=== Q7. Does margin determine execution urgency? <c07-q07>

Futures require only a fraction of notional as margin. Why does low initial cash usage not imply low economic exposure or low timing risk? What risk quantity belongs in the inventory penalty?

#answer-link(<c07-a07>)

=== Q8. How do sessions and scheduled events enter the policy? <c07-q08>

Futures trade nearly around the clock but liquidity is not stationary. Explain local session opens, cash-market overlap, maintenance breaks, settlement, price limits, and macro announcements as state or regime variables.

#answer-link(<c07-a08>)

=== Q9. How would you estimate a roll-aware impact model? <c07-q09>

Propose a hierarchical specification across products, expiries, and days-to-roll. Separate predictive calibration from a causal claim about raising participation.

#answer-link(<c07-a09>)

=== Q10. Why is contract choice endogenous? <c07-q10>

Algorithms route toward the contract expected to be cheaper. What bias appears if you compare realized costs in $F_1$ and $F_2$ without modeling that choice? What experimental or quasi-experimental variation could help?

#answer-link(<c07-a10>)

=== Q11. Formulate the control problem across two expiries. <c07-q11>

Define a state, actions, inventory transition, and objective when the controller can trade $F_1$, $F_2$, or the calendar spread. What constraints prevent a cost-only optimizer from creating unwanted basis exposure?

#answer-link(<c07-a11>)

=== Q12. Diagnose a model that underestimates costs near rolls. <c07-q12>

Give a prioritized investigation covering denominators, contract mapping, state omission, selection, tails, and policy feedback. How do you decide between a correction factor, a new regime, and a trading constraint?

#answer-link(<c07-a12>)

=== Q13. Give the 90-second interview answer. <c07-q13>

Respond to: “What is different about market-impact modeling and optimal execution for futures, especially near the roll?”

#answer-link(<c07-a13>)

#pagebreak()
== Detailed Answers and Discussion

=== A1. Quantity should preserve the exposure the client wants <c07-a01>

#back-link(<c07-q01>)

Contracts are the operational order unit, but they are not generally the right comparison unit. One equity-index contract, one energy contract, and one rates contract have different multipliers, prices, tick values, and risk. Even within a product, price and conversion factors can change the notional or risk represented by a contract.

For a simple equity-index future, dollar notional is approximately

$
  N = n times M times F,
$

where $n$ is contracts, $M$ is the contract multiplier, and $F$ is futures price. For a rates future, a duration-like quantity such as DV01 may be more meaningful. For options on futures, delta and higher-order risks matter. The execution state should track both contracts remaining and the economic exposure still required.

Impact can be reported in ticks or basis points, but cross-product comparisons need a consistent denominator. A one-tick cost becomes dollars through tick value; dividing by notional produces basis points; dividing by a risk measure produces cost per unit of risk. The choice should match the portfolio objective.

#candidate[
“I submit contracts, but I control exposure. I would convert contract counts to the client's relevant risk unit—often notional for equity-index futures and DV01 for rates—while retaining tick value and multiplier for executable cost. Otherwise equal contract counts can look comparable while representing very different inventory risk.”
]

=== A2. Liquidity is the conditional cost of the next action <c07-a02>

#back-link(<c07-q02>)

Volume records completed trading; open interest records outstanding positions; spread measures the immediate price concession at the touch; depth measures displayed capacity; trade intensity measures how quickly opportunities arrive; and resilience measures replenishment after consumption. None alone identifies the marginal cost of the next child order.

$F_1$ may have higher trailing volume because the roll only recently began, while $F_2$ may now offer more depth and faster replenishment. Open interest can remain high even when executable liquidity is migrating. A one-tick spread in both contracts also hides different tick values, queue lengths, depth slopes, and adverse-selection risk.

For the next action, use contemporaneous pre-action spread, depth across levels, queue and trade intensity, signed order flow, refill behavior, volatility, and the cross-contract basis. Forecast near-term volume in each expiry rather than mechanically routing from yesterday's totals. Contract selection should compare expected continuation values, including what an unfilled child does to future flexibility.

#interviewer[
*“If $F_1$ has twice the open interest, isn't it obviously safer?”*

No. Open interest measures positions outstanding, not the price or speed at which I can trade now. It can remain concentrated in an expiring contract while marginal trading liquidity has already moved.
]

=== A3. The roll is a state transition, not a calendar dummy <c07-a03>

#back-link(<c07-q03>)

As expiration approaches, hedgers, asset managers, market makers, and index-linked accounts transfer positions. Outright volume and depth migrate, while much of the transfer may occur through listed calendar spreads. The active contract can change over hours rather than at one universal date, and different products follow different conventions.

A hard rule such as “front contract until five days before expiry, then next contract” creates a discontinuous instrument mapping even when liquidity migrates smoothly. It can also switch too late in one cycle and too early in another. Days-to-expiry is useful, but a robust state includes volume share by expiry, depth share, open-interest change, spread-market activity, basis volatility, settlement rules, delivery risk, and product-specific roll conventions.

The control implication is to allow gradual allocation across expiries subject to exposure constraints. The policy can move toward $F_2$ as its marginal all-in cost falls, rather than pretending contract identity is fixed until a deterministic switch.

#warning[
Do not learn the roll regime from the final day's volume share and feed it into an earlier decision. The active-contract label itself must be constructed from information available at that time.
]

=== A4. A continuous series is useful for returns but not an executable tape <c07-a04>

#back-link(<c07-q04>)

A continuous series splices different expiries. Back adjustment removes or redistributes price gaps at switches so historical returns are easier to analyze. The adjusted level may never have been tradable. If a benchmark or arrival price comes from the adjusted series while fills come from raw contract prices, the measured shortfall can contain the adjustment rather than execution cost.

Contract switches can also create artificial jumps or erase real basis changes. A model may interpret the switch as volatility, reversion, or impact. Retain the raw symbol and expiry, raw quote and fill prices, multiplier, tick size and value, exact roll mapping, adjustment factor, benchmark contract, and timestamps. Build returns for forecasting from a documented continuous construction, but compute executable TCA on the actual contract or spread traded.

#candidate[
“I would use a continuous series for some signal and volatility research, but never assume its adjusted price was executable. TCA must reconcile each fill with the raw contract-level quote and a benchmark defined in the same instrument. The roll mapping and adjustment factor remain audit fields, not hidden preprocessing.”
]

=== A5. Denominators are forecasts or outcomes depending on timing <c07-a05>

#back-link(<c07-q05>)

$Q/"ADV"$ is a broad daily-size measure, but trailing ADV can lag a rapid roll migration. Fraction of displayed depth describes immediate footprint but ignores hidden liquidity and replenishment. POV connects the order rate to market volume, yet *realized* POV contains future market activity in its denominator.

For expiry $j$ over bucket $t$, define intended participation using a pre-action forecast:

$
  rho_(j,t) = frac(q_(j,t), hat(V)_(j,t)).
$

If realized $V_(j,t)$ replaces $hat(V)_(j,t)$, a volume surprise changes measured POV after the action. On roll days, unusually high volume can make an aggressive order appear gentle, while both the volume shock and cost may be driven by the same event. That creates mechanical endogeneity and can leak future information into a live optimizer.

Use several scales: forecast share of volume for scheduling, depth fraction for child-order risk, and notional or DV01 for cross-contract exposure. Diagnose results across all of them rather than treating one denominator as universal.

=== A6. The calendar spread packages basis transfer <c07-a06>

#back-link(<c07-q06>)

Rolling a long $F_1$ position into $F_2$ requires selling $F_1$ and buying $F_2$. Separate outright legs expose the portfolio to price movement between executions and can temporarily change total market exposure. The listed calendar spread executes the relative-price trade as one instrument, reducing legging risk and often concentrating roll liquidity.

The spread is not automatically cheaper. Its book has its own queue, tick, depth, fees, implied-liquidity rules, and adverse selection. Executing outright legs may be better when one leg has abundant natural flow, when the portfolio wants to alter net exposure at the same time, or when spread liquidity is poor. Cross-impact matters because trading one expiry can move the basis and the quotes of the other.

Compare complete costs:

$
  C_"spread" quad "versus" quad C_(F_1)+C_(F_2)+C_"legging risk"+C_"cross-impact".
$

The counterfactual must preserve the same final exposure and timing constraint. Comparing only quoted spreads ignores fill probability and the inventory path between legs.

#interviewer[
*“Can I estimate each outright leg independently and add the costs?”*

Only as a first approximation. The legs share information, basis dynamics, and liquidity. Executing one changes the state faced by the other, so covariance and cross-impact can be economically material.
]

=== A7. Margin is financing mechanics; risk follows economic exposure <c07-a07>

#back-link(<c07-q07>)

Initial margin is collateral against potential losses, not the amount economically invested. A futures position is marked to market on its full price exposure. A small cash deposit can support a large notional, so measuring timing risk from margin would understate the price sensitivity that execution leaves outstanding.

For an equity-index future, an inventory-risk term can use remaining notional times return volatility. For rates, remaining DV01 times yield volatility may align better with P&L. In vector form, with remaining risk exposure $x_t$ and conditional covariance $Sigma_t$,

$
  "risk rate" = x_t^T Sigma_t x_t.
$

Margin still matters as a constraint: execution and temporary positions across legs can change cash requirements, intraday variation margin, and available capacity. But it should not replace the underlying exposure in the risk objective.

#warning[
Low margin-to-notional is leverage, not low risk. Confusing the two makes a slow schedule appear much safer than it is.
]

=== A8. Nearly continuous trading still has sharp regimes <c07-a08>

#back-link(<c07-q08>)

Liquidity, participant mix, and price discovery change around regional opens, the underlying cash-market session, exchange maintenance, settlement windows, and scheduled announcements. A minute at 03:00 and a minute during the cash open are not exchangeable merely because both are available for trading.

Scheduled macro releases can jump volatility and widen or empty books. Price limits and circuit rules truncate the action set and make completion risk nonlinear. Settlement and expiry procedures can change the relevant benchmark and create delivery or final-settlement exposure. The policy state should therefore include session, time to known event, limit proximity, settlement regime, and market-data freshness.

Some effects are predictable seasonality; others are conditional regimes. Forecast volume and volatility by event-aligned time, not only clock time. Use pre-event guardrails and re-estimate after the release rather than letting a smooth daily curve average across the discontinuity.

=== A9. Pool information without erasing contract identity <c07-a09>

#back-link(<c07-q09>)

A reduced-form parent-order model could be

$
  C_i = beta_(p_i,r_i) f(x_i, rho_i)
      + theta^T z_i + u_"date" + epsilon_i,
$

where $p_i$ is product, $r_i$ is a roll-state bucket, $x_i$ is risk-normalized size, $rho_i$ is intended participation, and $z_i$ contains pre-trade spread, depth, volatility, basis state, session, and contract maturity. Hierarchical priors or mixed effects allow sparse products and expiries to borrow strength while retaining roll-specific deviations.

Use continuous roll features where possible—volume share, depth share, open-interest change, days to expiry—and interactions with participation. Split by parent order and forward in time; keep a whole roll cycle or contract family together when leakage is plausible. Report calibration and tails by product, expiry, roll state, side, and session.

This model predicts cost under the logged routing policy. Interpreting the coefficient on $rho$ as the causal effect of raising participation requires conditional exchangeability or exogenous variation. An optimizer needs the action response and cross-contract transition, not only a good average prediction.

#candidate[
“I would partially pool across products but keep contract and roll state explicit. The key validation is not a single $R^2$; it is whether marginal cost and tail calibration remain sensible in each expiry as liquidity migrates, and whether the induced allocation is stable under parameter uncertainty.”
]

=== A10. The cheaper-looking contract was selected to look cheaper <c07-a10>

#back-link(<c07-q10>)

The router observes spread, depth, queue, volatility, basis, and urgency before choosing $F_1$ or $F_2$. Consequently,

$
  "contract choice" <- "market state" -> "execution cost".
$

A raw comparison assigns favorable selected states to the chosen contract. Even rich regression can fail if latent queue information, client restrictions, or private urgency affects both choice and outcome. The unchosen contract's fill and impact are censored counterfactuals.

Within safe, economically equivalent regions, small randomized routing shares can create overlap. Deterministic routing thresholds may support regression discontinuity if no other rule changes there and the running variable cannot be manipulated. Exchange changes, roll-rule changes, or staggered product migrations can offer quasi-experiments, but their exclusion and parallel-trend assumptions need economic defense.

Estimate intent-to-route effects as well as realized-fill effects. A route assignment that produces no fill still changes the remaining inventory and subsequent actions.

=== A11. Contract allocation belongs inside the Bellman state <c07-a11>

#back-link(<c07-q11>)

Let $x_t=(x_(1,t),x_(2,t))$ be current exposure by expiry and let $e_t$ be the client's remaining target exposure. A state can include

$
  S_t=(x_t,e_t,t,L_(1,t),L_(2,t),B_t,sigma_t,a_t,m_t),
$

where $L_j$ summarizes contract liquidity, $B_t=F_(2,t)-F_(1,t)$ is the basis or calendar spread, $a_t$ is alpha, and $m_t$ is margin capacity. Actions choose outright quantities $u_(1,t),u_(2,t)$ and a spread quantity $u_(s,t)$.

Transitions update each expiry position, total exposure, basis exposure, transient impact, and margin. The objective contains explicit cost, own impact and cross-impact, timing risk of unacquired exposure, basis risk from unmatched legs, and a terminal penalty for missing the required exposure or holding the wrong expiry.

Constraints include maximum POV and depth fraction by contract, total exposure bounds, basis-exposure limits, delivery or expiry restrictions, margin, and terminal contract eligibility. Without them, a cost-only optimizer may buy the apparently cheap expiry while creating a large unwanted basis position or delivery obligation.

#takeaway[
The action is not “pick the liquid contract” once. It is a sequence of allocations whose value depends on remaining exposure, evolving liquidity in both books, and the future cost of unwinding basis.
]

=== A12. Diagnose the failure in the order the data are constructed <c07-a12>

#back-link(<c07-q12>)

First verify plumbing: raw contract identity, expiry, multiplier, tick value, side, timestamps, benchmark contract, continuous-series adjustment, parent-child mapping, and explicit fees. A stale or mixed contract map can manufacture a roll effect.

Second audit denominators. Trailing ADV may belong mostly to $F_1$ while the order traded $F_2$; realized roll-day volume may leak the outcome; daily notional may hide a changing risk unit. Recompute cost against pre-trade forecast volume, depth, and risk exposure.

Third inspect omitted state and selection: spread, depth slope, replenishment, volume share, calendar-spread activity, basis volatility, days to expiry, session, announcement risk, urgency, and why the router chose that contract. Then examine residual distributions—not only means—by product, roll day, participation, and contract rank.

Finally evaluate policy feedback. If underestimated roll cost makes the optimizer raise POV, deployment amplifies the error. Re-solve schedules under parameter uncertainty and stress low depth, volume migration reversal, and failed spread fills.

Use a shrunk correction factor when a stable residual level remains within supported states. Introduce an explicit regime when relationships and variance change structurally. Apply hard constraints or a conservative fallback when data support is weak, tail loss is unacceptable, or the model cannot identify the action response safely.

#interviewer[
*“The roll dummy fixes mean residuals. Are we done?”*

No. It may hide a denominator error, selection, or a changing slope with POV. I would test marginal-cost calibration, tails, stability across roll cycles, and the schedule produced after the correction.
]

=== A13. A concise synthesis <c07-a13>

#back-link(<c07-q13>)

#candidate[
“Futures add contract choice to timing and speed. I trade contracts operationally, but the client's objective is an economic exposure such as notional or DV01. Near a roll, volume, depth, open interest, and calendar-spread activity migrate across expiries at different speeds, so a fixed front-month label or trailing ADV can misstate the liquidity available to the next child order.

For measurement, I would keep raw contract-level quotes, fills, multipliers, tick values, and benchmarks. A back-adjusted continuous series is useful for some return models but its price is not executable and can contaminate TCA around switches. I would normalize size using pre-trade forecast volume, depth, and the relevant risk unit, and I would model roll state continuously through volume share, depth share, basis volatility, and days to expiry.

For estimation, I would use a hierarchical model across products and expiries with forward roll-cycle validation. Historical contract choice and POV are endogenous because the router selects them from market state, so predictive fit is not a causal action response. I would seek bounded randomized routing or credible threshold variation and check overlap.

For control, the state contains inventory by expiry, remaining target exposure, both liquidity states, basis, volatility, alpha, time, and constraints. Actions can use either outright or the calendar spread. The objective prices own impact, cross-impact, timing risk, legging and basis risk, margin, and terminal contract eligibility. Near weak support I would constrain the policy and use a conservative fallback rather than let an optimizer exploit a cheap but unreliable roll coefficient.”
]

The reusable structure is: *define exposure before quantity, keep executable contract data separate from continuous research data, model liquidity migration rather than a fixed roll date, identify the routing counterfactual, and optimize contract allocation with basis and terminal constraints.*

== Closing Oral Drill

Answer each aloud in no more than 20 seconds, then give A13 from memory:

1. Why is contract count often the wrong cross-product size measure?
2. Why can open interest remain high after marginal liquidity starts moving?
3. What makes a back-adjusted price unsuitable as an execution benchmark?
4. Why is realized roll-day POV endogenous?
5. When can a listed calendar spread dominate separate outright legs?
6. Why does low margin not imply low timing risk?
7. Name three state variables that describe a roll better than days to expiry alone.
8. Why is a raw $F_1$ versus $F_2$ cost comparison confounded?
9. What must a two-expiry controller penalize besides outright impact?
10. When should a roll correction become a hard policy constraint?
]
