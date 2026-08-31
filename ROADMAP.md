# Book roadmap

The book is organized around a loop:

> observe market state → estimate dynamics and costs → choose an action →
> observe fills and market response → update beliefs and policy.

## Part I — Execution and market impact (first priority)

1. **Trading as inference and control**  
   State, action, disturbance, objective, filtration, Bellman recursion, and the
   prediction-versus-control distinction.

2. **Market microstructure as the controlled system**  
   Limit-order books, spread, depth, queueing, order flow, adverse selection,
   resilience, fragmentation, auctions, and clocks.

3. **Transaction costs and statistical identification**  
   Arrival shortfall, VWAP, reversion, opportunity cost, decomposition,
   counterfactuals, dependence, A/B tests, causal pitfalls, and uncertainty.

4. **Market-impact models and estimation**  
   Temporary/permanent and transient impact, concavity, square-root and
   propagator laws, nonlinear constrained regression, hierarchical shrinkage,
   endogeneity, metaorder reconstruction, diagnostics, and ML extensions.

5. **Optimal liquidation and participation control**  
   Bertsimas–Lo and Almgren–Chriss, the efficient frontier, alpha decay,
   volume time, POV schedules, constraints, sensitivity, and receding-horizon
   control.

## Part II — Adaptive execution and order placement

6. **Stochastic liquidity, volume, spread, and volatility**  
   State-space and point-process models; volume-curve estimation; forecast
   uncertainty; regime changes; scenario generation.

7. **Transient impact and market resilience**  
   Propagator states, no-dynamic-arbitrage conditions, optimal schedules under
   decay, price manipulation, and empirical kernel estimation.

8. **Limit-order placement and queue control**  
   Fill probabilities, queue position, cancellation, adverse selection,
   survival models, marked point processes, and impulse control.

9. **Smart order routing and venue choice**  
   Fragmented liquidity, fees and rebates, latency, fill quality, dark pools,
   crossing, auctions, bandits, and constrained routing.

10. **Bayesian, robust, and model-predictive execution**  
    Online learning, uncertainty sets, distributional robustness, dual control,
    and rolling re-optimization.

11. **Machine learning for execution decisions**  
    Supervised prediction, calibration, ranking, representation learning,
    uncertainty quantification, drift monitoring, and policy-aware losses.

12. **Reinforcement learning and offline policy evaluation**  
    MDPs/POMDPs, simulators, offline RL, off-policy evaluation, safe policy
    improvement, and why naive backtests fail.

## Part III — Other trading problems through the same lens

13. **Market making and inventory control**  
    Reservation prices, Avellaneda–Stoikov, order-flow calibration, queue risk,
    inventory penalties, and multi-asset extensions.

14. **Optimal stopping and statistical arbitrage**  
    Entry/exit, free-boundary problems, pairs and spread models, regime
    uncertainty, and costs.

15. **Portfolio choice with trading frictions**  
    Dynamic mean–variance ideas, stochastic control with transaction costs,
    no-trade regions, and signal decay.

16. **Multi-asset and portfolio execution**  
    Cross-impact, covariance, factor liquidity, coupled schedules, basket risk,
    and manipulation-free models.

17. **Options hedging and execution under frictions**  
    Discrete hedging, inventory and gamma risk, impact-aware rebalancing, and
    stochastic volatility.

18. **Auctions, liquidation, and special trading mechanisms**  
    Opening/closing auctions, benchmarks, imbalances, fire sales, and strategic
    interaction.

19. **Strategic agents and stochastic games**  
    Signaling, predatory trading, mean-field games, equilibrium impact, and
    mechanism design.

## Part IV — Research practice and foundations

20. **From research question to production model**  
    Data contracts, reproducible experiments, leakage controls, simulation,
    validation, monitoring, governance, and model–engine interfaces.

21. **Case studies and paper reproductions**  
    Almgren–Chriss, propagator impact, volume uncertainty, fill modeling,
    market making, and offline RL.

22. **Interview research drills**  
    Open-ended investigations, model criticism, experimental design, numerical
    problems, and concise communication.

### Appendices

A. Probability, conditional expectation, martingales, and stopping times  
B. Brownian motion, Itô calculus, jump processes, and point processes  
C. Dynamic programming, HJB, verification, and maximum principles  
D. Convex optimization, KKT systems, numerical methods, and MPC  
E. Statistical inference, regularization, causal inference, and ML  
F. Time-series data engineering, event studies, and reproducible computation  
G. Notation and dimensional-analysis reference

## Progressive writing order

The recommended order is 1 → 2 → 3 → 4 → 5 → 7 → 6 → 8 → 10 → 11 → 12.
This puts the highest-value execution interview material first while preserving
the dependency chain from mechanism to measurement to estimation to control.

