// Migration-only adapters. The original manuscripts and styles are untouched.
// Markers let Pandoc retain the boundaries of the book's semantic panels.
#let web-panel(kind, title, body) = [
  #block[PORTPANELSTART#kind]
  #parbreak()
  #block[#strong(title) #body]
  #parbreak()
  #block[PORTPANELEND]
  #parbreak()
]
#let intuition(body) = web-panel("intuition", "Intuition", body)
#let interview(body) = web-panel("interview", "Interview check", body)
#let research(body) = web-panel("research", "Research warning", body)
#let takeaway(body) = web-panel("takeaway", "Control implication", body)
#let definition(name, body) = web-panel("definition", [Definition: #name], body)
#let interviewer(body) = web-panel("interviewer", "Interviewer follow-up", body)
#let candidate(body) = web-panel("candidate", "Strong spoken answer", body)
#let warning(body) = web-panel("warning", "Research warning", body)
#let qa-takeaway(body) = web-panel("takeaway", "What the interviewer is testing", body)
#let answer-link(target) = link(target)[Detailed answer #sym.arrow.r]
#let back-link(target) = link(target)[#sym.arrow.l Back to question]
