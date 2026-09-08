#import "style.typ": book, chapter-nav

#show: book.with(
  title: "Stochastic Modeling and Optimal Control for Algorithmic Trading",
  subtitle: "From market microstructure and statistical inference to adaptive trading policies",
  author: "Akshay Ajagekar",
  index-target: <book-chapter-index>,
)

#include "chapters/00-preface.typ"

#outline(title: [Contents], depth: 2)
#pagebreak()

#heading(level: 1, numbering: none, outlined: false)[Chapter Index] <book-chapter-index>

#include "chapters/00-book-skeleton.typ"

#pagebreak()

#include "chapters/01-control-lens.typ"
#chapter-nav(<book-chapter-index>, next-target: <ch-microstructure>)

#include "chapters/02-microstructure.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-control-lens>, next-target: <ch-tca>)

#include "chapters/03-tca-identification.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-microstructure>, next-target: <ch-modeling-research>)

#include "chapters/03b-modeling-research.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-tca>, next-target: <ch-execution-data>)

#include "chapters/04-execution-data.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-modeling-research>, next-target: <ch-impact-empirical>)

#include "chapters/05-impact-empirical.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-execution-data>, next-target: <ch-impact-estimation>)

#include "chapters/06-impact-estimation.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-impact-empirical>, next-target: <ch-liquidity-state>)

#include "chapters/07-liquidity-forecasting.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-impact-estimation>, next-target: <ch-policy-evaluation>)

#counter(heading).update(15)
#include "chapters/15-policy-evaluation.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-liquidity-state>, next-target: <ch-production-research>)

#counter(heading).update(23)
#include "chapters/23-production-research.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-policy-evaluation>)

#pagebreak()
#set text(size: 9pt)
#bibliography("references.bib", title: [References], style: "ieee")
