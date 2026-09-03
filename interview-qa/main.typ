#import "style.typ": qa-book, chapter-nav
#import "chapters/01-participation-impact.typ": chapter-one
#import "chapters/02-time-of-day-liquidity.typ": chapter-two
#import "chapters/03-transient-impact-resilience.typ": chapter-three
#import "chapters/04-passive-aggressive-queues.typ": chapter-four
#import "chapters/05-adaptive-policy-evaluation.typ": chapter-five
#import "chapters/06-almgren-chriss-control.typ": chapter-six
#import "chapters/07-futures-roll-liquidity.typ": chapter-seven
#import "chapters/08-adaptive-feedback-control.typ": chapter-eight

#show: qa-book.with(
  title: "Execution and Market Impact Interview Q&A",
  subtitle: "Questions first, then rigorous answers and discussion",
  author: "Akshay Ajagekar",
  index-target: <qa-chapter-index>,
)

#outline(title: [Contents], depth: 2)
#pagebreak()

#heading(level: 1, numbering: none, outlined: false)[Chapter Index] <qa-chapter-index>

1. #link(<qa-ch01>)[Participation, Impact, and Causal Interpretation]
2. #link(<qa-ch02>)[Time of Day, Liquidity, and Confounding]
3. #link(<qa-ch03>)[Transient Impact, Resilience, and Schedule Shape]
4. #link(<qa-ch04>)[Passive versus Aggressive Execution]
5. #link(<qa-ch05>)[Adaptive versus Static POV]
6. #link(<qa-ch06>)[Almgren-Chriss: Risk, Impact, and the Execution Frontier]
7. #link(<qa-ch07>)[Futures Execution: Contract Choice, Rolls, and Liquidity Migration]
8. #link(<qa-ch08>)[Adaptive Execution: Belief States, Feedback, and Receding-Horizon Control]

#pagebreak()

#chapter-one
#chapter-nav(<qa-chapter-index>, next-target: <qa-ch02>)

#chapter-two
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch01>, next-target: <qa-ch03>)

#chapter-three
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch02>, next-target: <qa-ch04>)

#chapter-four
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch03>, next-target: <qa-ch05>)

#chapter-five
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch04>, next-target: <qa-ch06>)

#chapter-six
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch05>, next-target: <qa-ch07>)

#chapter-seven
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch06>, next-target: <qa-ch08>)

#chapter-eight
#chapter-nav(<qa-chapter-index>, previous-target: <qa-ch07>)
