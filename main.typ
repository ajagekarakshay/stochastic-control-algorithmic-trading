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
#chapter-nav(<book-chapter-index>, previous-target: <ch-tca>, next-target: <ch-impact>)

#include "chapters/04-impact-estimation.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-modeling-research>, next-target: <ch-optimal-execution>)

#include "chapters/05-optimal-execution.typ"
#chapter-nav(<book-chapter-index>, previous-target: <ch-impact>)

#pagebreak()
#bibliography("references.bib", title: [References], style: "ieee")
