#import "font.typ": *
#import "../contents/info.typ": *

#let report_title(title: "", authors: (), body) = {
  // Set the document's basic properties.
  set document(author: authors, title: title)

  // Set run-in subheadings, starting at level 3.
  show heading: it => {
    if it.level > 2 {
      parbreak()
      text(11pt, style: "italic", weight: "regular", it.body + ".")
    } else {
      it
    }
  }


  // Title row.
  align(center)[
    #block(text(font: songti, weight: 700, 1.75em, title))
  ]

  // Author information.
  set text(font: songti, weight: 400, 1.25em)
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center, strong(author))),
    ),
  )
}

#show: report_title.with(
  title: ReportTitle,
  authors: Authors,
)