#let navy = rgb("183153")
#let blue = rgb("2463a5")
#let pale-blue = rgb("eef5fb")
#let pale-gold = rgb("fff7df")
#let pale-green = rgb("edf8f1")
#let pale-red = rgb("fff0ef")
#let gray = rgb("5e6875")

#let callout(title, fill, stroke, body) = block(
  width: 100%,
  inset: 10pt,
  radius: 3pt,
  fill: fill,
  stroke: (left: 2.2pt + stroke),
  breakable: false,
)[
  #text(weight: "bold", fill: stroke)[#title]
  #v(3pt)
  #body
]

#let intuition(body) = callout("Intuition", pale-blue, blue, body)
#let interview(body) = callout("Interview check", pale-gold, rgb("a56b00"), body)
#let research(body) = callout("Research warning", pale-red, rgb("b13a35"), body)
#let takeaway(body) = callout("Control implication", pale-green, rgb("267447"), body)
#let definition(name, body) = callout("Definition: " + name, rgb("f4f5f7"), gray, body)

#let chapter-nav(index-target, previous-target: none, next-target: none) = block(
  width: 100%,
  breakable: false,
)[
  #v(12pt)
  #line(length: 100%, stroke: 0.5pt + rgb("c8cdd3"))
  #v(5pt)
  #grid(
    columns: (1fr, auto, 1fr),
    align(left)[
      #if previous-target != none {
        link(previous-target)[#sym.arrow.l Previous chapter]
      }
    ],
    align(center)[#link(index-target)[Chapter index]],
    align(right)[
      #if next-target != none {
        link(next-target)[Next chapter #sym.arrow.r]
      }
    ],
  )
]

#let book(title: none, subtitle: none, author: none, index-target: none, body) = {
  set document(title: title, author: author)
  set page(
    paper: "us-letter",
    margin: (inside: 0.9in, outside: 0.75in, top: 0.8in, bottom: 0.8in),
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
    text(20pt, weight: "bold", fill: navy)[#it]
    v(6pt)
  }
  show heading.where(level: 2): it => {
    v(8pt)
    text(13.5pt, weight: "bold", fill: navy)[#it]
    v(2pt)
  }
  show heading.where(level: 3): it => {
    v(5pt)
    text(11pt, weight: "bold", fill: gray)[#it]
  }

  align(center)[
    #v(1.1in)
    #text(26pt, weight: "bold", fill: navy)[#title]
    #v(12pt)
    #text(14pt, fill: gray)[#subtitle]
    #v(0.6in)
    #line(length: 50%, stroke: 1pt + blue)
    #v(0.6in)
    #text(13pt)[#author]
    #v(1fr)
    #text(9pt, fill: gray)[Working manuscript · #datetime.today().display("[month repr:long] [day], [year]")]
  ]
  pagebreak()
  set page(header: context {
    if counter(page).get().first() > 1 {
      grid(
        columns: (1fr, auto, 1fr),
        [],
        align(center, text(8pt, fill: gray)[#title]),
        align(right)[
          #if index-target != none {
            text(8pt)[#link(index-target)[Index]]
          }
        ],
      )
      line(length: 100%, stroke: 0.4pt + rgb("c8cdd3"))
    }
  })
  body
}
