#import "style.typ": book

#show: book.with(
  title: "Stochastic Modeling and Optimal Control for Algorithmic Trading",
  subtitle: "From market microstructure and statistical inference to adaptive trading policies",
  author: "Akshay Ajagekar",
)

#include "chapters/00-preface.typ"

#outline(title: [Contents], depth: 2)
#pagebreak()

#include "chapters/01-control-lens.typ"
#include "chapters/02-microstructure.typ"
#include "chapters/03-tca-identification.typ"
#include "chapters/04-impact-estimation.typ"
#include "chapters/05-optimal-execution.typ"

#pagebreak()
#bibliography("references.bib", title: [References], style: "ieee")
