// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

/*
This is a Typst template file for a NOAA Fisheries Stock Assessment Report (SAR).
It is based on the official NOAA SAR template, but has been adapted for use with Typst.
*/

// Function to set up the document's style.
#let article(
  // Document metadata
  title: none,
  subtitle: none,
  authors: none,
  affiliations: none,
  date: none,
  publication-date: none,
  
  // Custom NMFS SAR variables
  nmfs-region: none,
  common-name: none,
  genus-species: none,
  stock-name: none,
  sar-year: none,

  // Layout and page settings
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  
  // Language and typography
  lang: "en",
  region: "US",
  font: "STIX Two Text",
  fontsize: 11pt,
  title-size: 1.75em,
  subtitle-size: 1.25em,
  line-spacing: 0.8,
  linenumbering: false,

  // Heading styles
  heading-family: "Roboto",
  heading-weight: "semibold",
  heading-style: "normal",
  heading-color: rgb("#00559B"),
  heading-line-height: 0.65em,
  sectionnumbering: none,
  
  // Table of contents
  toc: false,
  toc_title: "Table of Contents",
  toc_depth: 3,
  toc_indent: 1.5em,

  // The document's body content.
  body
) = {
  // Set the document's basic properties.
  set document(
    title: title
  )

  // Construct the running title for the header
  let runningtitle = "Marine Mammal Stock Assessment Report - " + nmfs-region + " " + sar-year + linebreak() + common-name + " (" + emph[#genus-species] + ")" + if stock-name != none {" - " + stock-name} else {""}

  // Set the page properties, including header, footer, and background
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
    footer: context [
      #set text(size: 8pt, font: "Roboto", fill: rgb("#5EB6D9"))
      #h(1fr)
      Page #counter(page).display("1 of 1", both: true)
    ],
    header: align(right + horizon)[
      #set text(size: 11pt, font: "Roboto", fill: rgb("#5EB6D9"))
      #set par(leading: 0.6em)
      #runningtitle
    ],
    background: context { 
      if(counter(page).get().at(0) == 1) {
        align(left + top)[
          #image("assets/22Fisheries SEA_T1 CornerTall.png", width: 20%)
        ]
      }
    } 
  )

  // Set the text properties.
  set text(
    font: font,
    size: fontsize,
    lang: lang,
    fill: rgb("#323C46")
  )

  // Set base paragraph properties.
  set par(
    justify: true,
    leading: line-spacing * 1em,
  )

  // Set heading properties.
  if sectionnumbering != none {
    set heading(numbering: sectionnumbering)
  }

  // Set list properties.
  set list(
    indent: 2em,
    body-indent: 2em,
  )

  // Set enum properties.
  set enum(
    indent: 2em,
    body-indent: 2em,
  )

  // Title page layout
  if title != none {
    align(left)[#block(inset: (left: 2em, right: 2em, top: 2em, bottom: 1em))[
      #set par(leading: heading-line-height)
      #set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
      #text(size: title-size)[#title]
      #if subtitle != none {
        parbreak()
        text(size: subtitle-size)[#subtitle]
      }
    ]]
    v(1em)
    line(length: 100%, stroke: 0.5pt + gray)
    v(1em)
  }
  
  // Authors and Affiliations
  if authors != none {
    box(inset: (left: 2em, right: 2em), {
      set text(font: "Roboto")
      authors.map(author => {
        text(11pt, weight: "semibold", author.name)
        h(1pt)
        if "affiliation" in author {
          let matching_affils = if affiliations != none and "affiliation" in author {
            let affiliations_list = if type(affiliations) == dictionary { (affiliations,) } else { affiliations }
            affiliations_list.filter(affil => author.affiliation.contains(affil.id))
          } else { () }
          if matching_affils.len() > 0 {
            super(matching_affils.map(affil => affil.id).join(","))
          }
        }
      }).join(", ", last: " and ")
    })
    parbreak()
  }

  if affiliations != none {
    box(inset: (left: 2em, right: 2em, bottom: 10pt), {
      set text(font: "Roboto", size: 9pt);
      let affiliations_list = if type(affiliations) == dictionary { (affiliations,) } else { affiliations }
      affiliations_list.map(affil => {
        super(affil.id)
        h(1pt)
        // Build an array of location parts and join them.
        let location_parts = ()
        if "city" in affil {
          location_parts.push(affil.city)
        }
        if "region" in affil {
          location_parts.push(affil.region)
        }
        if "country" in affil {
          location_parts.push(affil.country)
        }
        let location = location_parts.join(", ")
        
        affil.name + linebreak() + h(3pt) + affil.department + (if location != "" {linebreak() + h(3pt) + location} else {""})
      }).join("\n")
    })
  }

  // Corresponding author
  if authors != none {
    let corresponding_authors_list = authors.filter(author => "attributes" in author and "corresponding" in author.attributes and author.attributes.corresponding)
    if corresponding_authors_list.len() > 0 {
      let corresponding_author = corresponding_authors_list.first()
      v(1em)
      box(inset: (left: 2em, right: 2em), {
        set text(font: "Roboto", style: "italic", size: 9pt)
        "Corresponding author: "
        corresponding_author.name
        if "email" in corresponding_author {
          " (" + corresponding_author.email + ")"
        }
      })
    }
  }

  v(1em)
  line(length: 100%, stroke: 0.5pt + gray)
  v(1em)

  // Reproducibility and date statement
  let pub_date_str = if publication-date != none {
    let parts = publication-date.split("-")
    datetime(
      year: int(parts.at(0)),
      month: int(parts.at(1)),
      day: int(parts.at(2))
    ).display("[month repr:long] [day], [year]")
  } else {
    "not specified"
  }

  place(bottom)[
    #box(inset: (left: 2em, right: 2em))[
      #set text(font: "Roboto", size: 9pt)
      This document was produced from a reproducible workflow.
      This version was rendered on #date.
      This marine mammal stock assessment report was published on #pub_date_str.
    ]
  ]
  
  // Table of Contents
  if toc {
    pagebreak()
    outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent,
    )
  }

  // Add a page break after the title page content.
  pagebreak()

  // The main content of the document.
  body
}
// ==============================================================================
// TYPST RENDERER
// ==============================================================================
// This file is the entry point for the Quarto extension. It calls the main
// `article` function defined in `typst-template.typ` and passes it all the
// necessary metadata from the Quarto YAML front matter.
//

#show: doc => article(
  // --- DOCUMENT METADATA FROM QUARTO YAML ---
  // The variables below are automatically populated by Quarto's Pandoc
  // processing and are passed to our custom `article` function.
  // Each `` block ensures the variable is only
  // passed if it exists in the .qmd YAML.
  
  // Title and Subtitle
      title: [Stock Assessment Report for a Cetacean or Pinniped Marine Mammal (#emph[Genus species];) in Alaska or the North Pacific Ocean. This title is especially long for demonstration purposes],
      
  // Author information
      authors: (
                ( 
            name: [Josh M. London],
            affiliation: (
                              "1"            ),
                          attributes: (
                corresponding: true,
                
              ),
                                                  email: [josh.london\@noaa.gov],
                      ),          ( 
            name: [Brian S. Fadely],
            affiliation: (
                              "1"            ),
                                                  email: [brian.fadely\@noaa.gov],
                      )    ),
    
  // Affiliation details
      affiliations: (
            (
        id: "1",
        name: "Alaska Fisheries Science Center",
                department: "National Marine Fisheries Service, NOAA",
                        city: "Seattle",
                        region: "Washington",
                        country: "USA",
              )
          ),
  
  // --- CUSTOM NMFS SAR TEMPLATE VARIABLES ---
  // These variables were added to the top-level YAML in `template.qmd`.
      nmfs-region: "NMFS Region",
        common-name: "Common Name",
        genus-species: "Genus species",
        stock-name: "All Stocks",
        sar-year: "2050",
  
  // Document Date, Language, and Region
      date: "August 06, 2025",
        publication-date: "2025-09-15",
        
  // Layout and Fonts
              linenumbering: true,
    
  // Headings
                              
  // Section Numbering and TOC
          toc_title: [Table of contents],
      toc_depth: 3,
  
  // Columns
  cols: 1,
  
  // Pass the main document body
  doc,
)

// ==============================================================================
// CUSTOM SHOW RULES
// ==============================================================================
// These rules are applied to specific elements after the main article function
// has been processed. They provide fine-grained control over the appearance of
// math equations, headings, figures, etc.

#show math.equation: set text(font: "STIX Two Math")

// This `show` rule styles all headings.
#show heading: it => block(width: 100%)[
  #set text(weight: "regular", 
            font: "Roboto",
            fill: rgb("#00559B"))
  #(it.body)
]

// This `show` rule adds vertical spacing around figures and disables line numbering.
#show figure: it => {
  set par.line(numbering: none)
  block(width: 100%, inset: (top: 1em, bottom: 1em), it)
}

// This `show` rule styles figure captions.
#show figure.caption: c => context {
  set par(justify: true);
  align(left)[
    #text(fill: luma(130), weight: "bold", size: 10pt)[
      #c.supplement #c.counter.display(c.numbering)
    ]
    #text(fill: luma(130), size: 10pt)[
      #c.separator #c.body
    ]
  ]
}

// This `show` rule specifically styles top-level (level 1) headings.
#show heading.where(
  level: 1
): it => [
  #set align(left)
  #set text(font:"Roboto", 
            weight: "semibold",
            fill: rgb("#00559B"))
  #pad(top: 1.5em, it.body)
]

// This `show` rule specifically styles level 2 headings.
#show heading.where(
  level: 2
): it => [
  #set align(left)
  #set text(font:"Roboto", 
            weight: "semibold",
            fill: rgb("#00559B"))
  #pad(top: 1.2em, it.body)
]

// This `show` rule styles horizontal lines.
#show line: it => {
  v(1.5em, weak: true)
  line(length: 100%)
  v(1.5em, weak: true)
}

// Set internal table properties
#set table(
  stroke: none,
)

// Conditionally apply line numbering.
#set par.line(numbering: n => text(fill: gray, size: 8pt, str(n) + " "))



= Introduction
<introduction>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sagittis posuere ligula sit amet lacinia. Duis dignissim pellentesque magna, rhoncus congue sapien finibus mollis. Ut eu sem laoreet, vehicula ipsum in, convallis erat. Vestibulum magna sem, blandit pulvinar augue sit amet, auctor malesuada sapien. Nullam faucibus leo eget eros hendrerit, non laoreet ipsum lacinia. Curabitur cursus diam elit, non tempus ante volutpat a. Quisque hendrerit blandit purus non fringilla. Integer sit amet elit viverra ante dapibus semper. Vestibulum viverra rutrum enim, at luctus enim posuere eu. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

#figure([
#{set text(font: ("Roboto", "system-ui", "Segoe UI", "Helvetica", "Arial", "sans-serif", "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji") , size: 8.25pt); table(
  columns: (20%, auto, auto, auto, 20%),
  align: (left,right,right,right,right,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 9pt , fill: rgb("#104e8b")); Stock], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 9pt , fill: rgb("#104e8b")); 2023 Abundance], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 9pt , fill: rgb("#104e8b")); 95% Confidence Range], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 9pt , fill: rgb("#104e8b")); CV], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 9pt , fill: rgb("#104e8b")); Prob. of Decline \
    (2015-2023)],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Alpha], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 6,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 5,000--6,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.04], table.cell(align: horizon + right, fill: rgb("#f7f6f7"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 60.0%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Beta], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 150], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 90--190], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.18], table.cell(align: horizon + right, fill: rgb("#f1e9f1"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 65.0%],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Gamma], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 36,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 32,000--40,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.06], table.cell(align: horizon + right, fill: rgb("#bbdfb5"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 42.0%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Delta], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 8,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 6,000--10,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.15], table.cell(align: horizon + right, fill: rgb("#57a05d"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#ffffff")); 27.5%],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Epsilon], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 19,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 16,000--24,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.11], table.cell(align: horizon + right, fill: rgb("#1b7837"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#ffffff")); 20.0%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Zeta], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 38,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 34,000--42,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.05], table.cell(align: horizon + right, fill: rgb("#762a83"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#ffffff")); 99.5%],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Eta], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 32,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 28,000--38,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.07], table.cell(align: horizon + right, fill: rgb("#add8a7"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 40.0%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Theta], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 6,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 4,000--7,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.14], table.cell(align: horizon + right, fill: rgb("#add8a7"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 40.0%],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Iota], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 11,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 10,000--13,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.07], table.cell(align: horizon + right, fill: rgb("#f4f0f4"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 62.5%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Kappa], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 12,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 10,000--13,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.07], table.cell(align: horizon + right, fill: rgb("#d4bbdb"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 77.5%],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Lambda], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 21,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 17,000--25,000], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.09], table.cell(align: horizon + right, fill: rgb("#f1e9f1"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 65.0%],
  table.cell(align: horizon + left, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); Omega], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#000000")); 23,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 20,000--29,000], table.cell(align: horizon + right, fill: rgb(128, 128, 128, 5%), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#7f7f7f")); 0.10], table.cell(align: horizon + right, fill: rgb("#b494c6"), stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[#set text(fill: rgb("#ffffff")); 85.0%],
)}
], caption: figure.caption(
position: top, 
[
Abundance estimates of a some seal species across different stocks
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-abundance-estimates>


= More Information
<more-information>
#strong[Bold Statement] Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sagittis posuere ligula sit amet lacinia. Duis dignissim pellentesque magna, rhoncus congue sapien finibus mollis. Ut eu sem laoreet, vehicula ipsum in, convallis erat. Vestibulum magna sem, blandit pulvinar augue sit amet, auctor malesuada sapien. Nullam faucibus leo eget eros hendrerit, non laoreet ipsum lacinia. Curabitur cursus diam elit, non tempus ante volutpat a. Quisque hendrerit blandit purus non fringilla. Integer sit amet elit viverra ante dapibus semper. Vestibulum viverra rutrum enim, at luctus enim posuere eu. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sagittis posuere ligula sit amet lacinia. Duis dignissim pellentesque magna, rhoncus congue sapien finibus mollis. Ut eu sem laoreet, vehicula ipsum in, convallis erat. Vestibulum magna sem, blandit pulvinar augue sit amet, auctor malesuada sapien. Nullam faucibus leo eget eros hendrerit, non laoreet ipsum lacinia. Curabitur cursus diam elit, non tempus ante volutpat a. Quisque hendrerit blandit purus non fringilla. Integer sit amet elit viverra ante dapibus semper. Vestibulum viverra rutrum enim, at luctus enim posuere eu. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

== Subheading
<subheading>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sagittis posuere ligula sit amet lacinia. Duis dignissim pellentesque magna, rhoncus congue sapien finibus mollis. Ut eu sem laoreet, vehicula ipsum in, convallis erat. Vestibulum magna sem, blandit pulvinar augue sit amet, auctor malesuada sapien. Nullam faucibus leo eget eros hendrerit, non laoreet ipsum lacinia. Curabitur cursus diam elit, non tempus ante volutpat a. Quisque hendrerit blandit purus non fringilla. Integer sit amet elit viverra ante dapibus semper. Vestibulum viverra rutrum enim, at luctus enim posuere eu. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Nunc ac dignissim magna. Vestibulum vitae egestas elit. Proin feugiat leo quis ante condimentum, eu ornare mauris feugiat. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris cursus laoreet ex, dignissim bibendum est posuere iaculis. Suspendisse et maximus elit. In fringilla gravida ornare. Aenean id lectus pulvinar, sagittis felis nec, rutrum risus. Nam vel neque eu arcu blandit fringilla et in quam. Aliquam luctus est sit amet vestibulum eleifend. Phasellus elementum sagittis molestie. Proin tempor lorem arcu, at condimentum purus volutpat eu. Fusce et pellentesque ligula. Pellentesque id tellus at erat luctus fringilla. Suspendisse potenti.

Etiam maximus accumsan gravida. Maecenas at nunc dignissim, euismod enim ac, bibendum ipsum. Maecenas vehicula velit in nisl aliquet ultricies. Nam eget massa interdum, maximus arcu vel, pretium erat. Maecenas sit amet tempor purus, vitae aliquet nunc. Vivamus cursus urna velit, eleifend dictum magna laoreet ut. Duis eu erat mollis, blandit magna id, tincidunt ipsum. Integer massa nibh, commodo eu ex vel, venenatis efficitur ligula. Integer convallis lacus elit, maximus eleifend lacus ornare ac. Vestibulum scelerisque viverra urna id lacinia. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Aenean eget enim at diam bibendum tincidunt eu non purus. Nullam id magna ultrices, sodales metus viverra, tempus turpis.
