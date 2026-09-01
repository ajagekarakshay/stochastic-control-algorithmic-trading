#let navy = rgb("183153")
#let blue = rgb("2463a5")
#let pale-blue = rgb("eef5fb")
#let pale-gold = rgb("fff7df")
#let pale-green = rgb("edf8f1")
#let pale-red = rgb("fff0ef")
#let gray = rgb("5e6875")

#let panel(title, fill, stroke, body, breakable: true) = block(
  width: 100%,
  inset: 10pt,
  radius: 3pt,
  fill: fill,
  stroke: (left: 2.2pt + stroke),
  breakable: breakable,
)[
  #text(weight: "bold", fill: stroke)[#title]
  #v(3pt)
  #body
]

#let interviewer(body) = panel("Interviewer follow-up", pale-gold, rgb("a56b00"), body)
#let candidate(body) = panel("Strong spoken answer", pale-blue, blue, body)
#let warning(body) = panel("Research warning", pale-red, rgb("b13a35"), body)
#let takeaway(body) = panel("What the interviewer is testing", pale-green, rgb("267447"), body)

#let answer-link(target) = link(target)[Detailed answer #sym.arrow.r]
#let back-link(target) = link(target)[#sym.arrow.l Back to question]

#let qa-book(title: none, subtitle: none, author: none, body) = {
  set document(title: title, author: author)
  set page(
    paper: "us-letter",
    margin: (inside: 0.88in, outside: 0.72in, top: 0.78in, bottom: 0.78in),
    numbering: "1",
    number-align: center,
  )
  set text(font: "New Computer Modern", size: 10.5pt, fill: rgb("20252b"))
  set par(justify: true, leading: 0.68em)
  set heading(numbering: "1.1")
  set list(indent: 1.1em, body-indent: 0.55em, spacing: 0.35em)
  set enum(indent: 1.1em, body-indent: 0.55em, spacing: 0.35em)
  show math.equation: set text(size: 10.5pt)
  show link: set text(fill: blue)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(10pt)
    text(20pt, weight: "bold", fill: navy, hyphenate: false)[#it]
    v(6pt)
  }
  show heading.where(level: 2): it => {
    v(8pt)
    text(13.5pt, weight: "bold", fill: navy, hyphenate: false)[#it]
    v(2pt)
  }
  show heading.where(level: 3): it => {
    v(5pt)
    text(11pt, weight: "bold", fill: gray, hyphenate: false)[#it]
  }

  align(center)[
    #v(1.05in)
    #block(width: 100%)[
      #text(24pt, weight: "bold", fill: navy, hyphenate: false)[#title]
    ]
    #v(12pt)
    #text(14pt, fill: gray)[#subtitle]
    #v(0.58in)
    #line(length: 50%, stroke: 1pt + blue)
    #v(0.58in)
    #text(13pt)[#author]
    #v(1fr)
    #text(9pt, fill: gray)[Execution interview companion #sym.dot.c #datetime.today().display("[month repr:long] [day], [year]")]
  ]
  pagebreak()
  set page(header: context {
    if counter(page).get().first() > 1 {
      align(center, text(8pt, fill: gray)[#title])
      line(length: 100%, stroke: 0.4pt + rgb("c8cdd3"))
    }
  })
  body
}
