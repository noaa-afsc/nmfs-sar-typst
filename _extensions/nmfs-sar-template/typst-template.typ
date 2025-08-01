
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
  affiliations: none,
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
  title-size: 1.75em,
  subtitle-size: 1.25em,
  heading-family: "Roboto",
  heading-weight: "semibold",
  heading-style: "normal",
  heading-color: rgb("#00559B"),
  heading-line-height: 0.65em,
  sectionnumbering: none,
  linenumbering: true,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  nmfs-region: none,
  sar-year: none,
  common-name: "Common Name",
  genus-species: "Genus species",
  stock-name: none,
  doc,
) = {

  let runningtitle = "Marine Mammal Stock Assessment Report - " + nmfs-region + " " + sar-year + linebreak() + common-name + " (" + emph[genus-species] + ")" + stock-name

  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
    footer: context [
      #set text(
        size: 8pt,
        font: "Roboto",
        fill: rgb("#5EB6D9")
      )
      #date
      #h(1fr)
      Page #counter(page).display(
        "1 of 1",
        both: true,
    )
  ],
    header: align(right + horizon)[
      #set text(
        size: 11pt,
        font: "Roboto",
        fill: rgb("#5EB6D9"))
      #runningtitle],
    // Marine Mammal Stock Assessment Report - #nmfs-region#sar-year \
    // #common-name (#emph[#genus-species])#stock-name],
    // Define the background for the first page
    background: context { if(counter(page).get().at(0)== 1) {
      align(left + top)[
      #image("/assets/22Fisheries SEA_T1 CornerTall.png", width: 20%)
    ]}} 
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

// Styled gray line numbers.
  if linenumbering {
    set par.line(numbering: n => text(gray)[#n])
  } else {
    set par.line(numbering: none)
  }

// Authors and Affiliations
  if authors.len() == 2 {
    box(inset: (left: 2em, right: 2em), {
      set text(font: "Roboto")
      authors.map(author => {
        text(11pt, weight: "semibold", author.name)
        h(1pt)
        if "affiliation" in author {
          super(author.affiliation)
        }
      }).join(", ", last: " and ")
    })
    parbreak()
  }

  if authors.len() > 2 {
    box(inset: (left: 2em, right: 2em), {
      set text(font: "Roboto")
      authors.map(author => {
        text(11pt, weight: "semibold", author.name)
        h(1pt)
        if "affiliation" in author {
          super(author.affiliation)
        }
      }).join(", ", last: ", and ")
    })
    parbreak()
  }


  if affiliations.len() > 0 {
    box(inset: (left: 2em, right: 2em, bottom: 10pt), {
      set text(font: "Roboto", size: 9pt)
      affiliations.map(affil => {
        super(affil.id)
        h(1pt)
        affil.name + linebreak() + h(3pt) + affil.department
      }).join("\n")
    })
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
  inset: 2pt,
  stroke: none
)