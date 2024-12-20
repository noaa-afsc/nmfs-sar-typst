
// This is an example typst template (based on the default template that ships
// with Quarto). It defines a typst function named 'article' which provides
// various customization options. This function is called from the 
// 'typst-show.typ' file (which maps Pandoc metadata function arguments)
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-show.typ' entirely. You can find 
// documentation on creating typst templates and some examples here: 
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates


#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "STIX Two Text",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "Open Sans",
  heading-weight: "semibold",
  heading-style: "normal",
  heading-color: rgb("#00559B"),
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
    header: align(right + horizon)[
      #set text(
        font: "Open Sans",
        fill: rgb("#5EB6D9"))
      ALASKA MARINE MAMMAL STOCK ASSESSMENT REPORT],
    // Define the background for the first page
    background: context { if(counter(page).get().at(0)== 1) {
      align(left + top)[
      #image("_extensions/nmfs-sar-template/assets/22Fisheries SEA_T1 CornerTall.png", width: 20%)
    ]}
} 
  )
   set text(lang: lang,
           region: region,
           font: font,
           size: fontsize,
           fill: rgb("#323C46"))
  set heading(numbering: sectionnumbering)
  if title != none {
    align(left)[#block(inset: (left: 2em, right: 2em, top: 2em, bottom: 1em))[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

if authors != none {
  block(inset: (left: 2em, right: 2em))[
  #set text(size: 11pt)
  #table(
  columns: (1fr, 1fr),
  row-gutter: 0.1em,
  ..for (name, affiliation) in authors {
    (name, affiliation)
  }
)
  ]
}

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
