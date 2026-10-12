// The AARC guideline design, for the PDF.
//
// This file replaces the typst-template partial that Quarto supplies, so it
// defines the article function that typst-show.typ calls, with the parameters
// Quarto passes. The colours, fonts, sizes and page geometry are in
// design/tokens.json and the images in design/assets/, and the layout is
// written here. Both were taken from the Word file of AARC-G100, the design the
// AARC guidelines have had, and are now maintained here rather than in Word.
//
// Paths start with a slash, which typst resolves against the project root that
// Quarto compiles from. The extension is always installed at _extensions/aarc/
// in that root, so the design files are found from any guideline at any depth.

#let tokens = json("/_extensions/aarc/design/tokens.json")
#let assets = "/_extensions/aarc/design/assets/"

#let brand = rgb(tokens.title.colour)
#let link-colour = rgb(tokens.link.colour)
#let body-font = tokens.font.family
#let code-font = tokens.code.family
#let rule = tokens.table.rule_pt * 1pt + rgb(tokens.table.rule)

#let heading-token(level) = tokens.heading.at(str(calc.min(level, 4)))

// The appendices begin at this label, which the appendix filter places in
// front of the first heading marked {.appendix}. Everything after it is
// lettered rather than numbered.
#let appendix-label = <aarc-appendix>

#let in-appendix(loc) = {
  let starts = query(appendix-label)
  if starts.len() == 0 { return false }
  let start = starts.first().location().position()
  let here = loc.position()
  here.page > start.page or (here.page == start.page and here.y >= start.y)
}

// The number of a heading, a figure or a table, in the form of the template:
// 2, 2.1 and 2.1.3 in the body, A, A.1 and A.1.3 in the appendices.
#let section-number(loc, ..parts) = {
  numbering(if in-appendix(loc) { "A.1" } else { "1.1" }, ..parts)
}

// Called by the appendix filter. Restarts the count of the top-level headings,
// so the first appendix is A.
#let aarc-appendix() = [
  #metadata("appendix") #appendix-label
  #counter(heading).update(0)
]

// An author as the cover names them: the name, and the ORCID iD icon linked to
// the record of the author when the front matter gives an iD. The icon is kept
// on the line of the name it belongs to.
#let author-entry(author) = {
  let orcid = author.at("orcid", default: none)
  if orcid == none { return author.name }
  let badge = tokens.orcid_badge
  box[#author.name#h(0.25em)#link("https://orcid.org/" + orcid, box(
    baseline: 15%,
    image(assets + badge.file, height: badge.height_pt * 1pt, alt: "ORCID iD " + orcid),
  ))]
}

// The cover of the template: the title, then the document information as a
// list of a label and a value aligned on a tab stop, then the abstract. The
// cover carries no page number.
#let cover(
  title: none,
  authors: (),
  publication-date: none,
  document-code: none,
  doi: none,
  community: none,
  abstract: none,
) = {
  set page(footer: none)
  set par(justify: false)
  v(tokens.title.before_pt * 1pt - 1em)
  block(below: tokens.title.after_pt * 1pt)[
    #set par(leading: 0.45em)
    #text(
      size: tokens.title.size_pt * 1pt,
      weight: if tokens.title.bold { "bold" } else { "regular" },
      fill: brand,
    )[#title]
  ]

  set text(size: tokens.cover.size_pt * 1pt, fill: brand)
  let field(label, value, style: it => it) = if value != none {
    (label, style(value))
  } else { () }
  let rows(..fields) = grid(
    columns: (tokens.cover.label_width_in * 1in, 1fr),
    row-gutter: 0.55em,
    ..fields.pos().flatten()
  )
  // The groups are separated by an empty line, as on the Word cover.
  rows(
    ..field([Publication Date], publication-date),
    ..field([Authors:], if authors.len() > 0 { authors.map(author-entry).join(", ") }),
  )
  v(1.2em)
  rows(
    ..field([Document Code:], document-code),
    ..field([DOI:], doi, style: emph),
  )
  if community != none {
    v(1.2em)
    rows(..field([Community:], community))
  }

  if abstract != none {
    v(4.5em)
    block(below: 0.6em, strong[Abstract])
    set par(justify: true, leading: 0.5em)
    if tokens.cover.abstract_italic { emph(abstract) } else { abstract }
  }
  pagebreak()
}

// The second page of the template opens with the copyright, the licence and
// the funding statement, each with its badge, ahead of the table of contents.
#let notices(copyright: none, licence: none, funding: none) = {
  set text(size: tokens.cover.size_pt * 1pt, fill: brand)
  set par(justify: false, leading: 0.5em)
  let badge(token) = image(assets + token.file, width: token.width_in * 1in)
  if copyright != none or licence != none {
    grid(
      columns: (1fr, auto),
      column-gutter: 1em,
      align: (left + bottom, right + bottom),
      [#copyright \ #licence], badge(tokens.licence_badge),
    )
  }
  if funding != none {
    v(1.5em)
    grid(
      columns: (auto, 1fr),
      column-gutter: 0.5em,
      align: (left + horizon, left + horizon),
      badge(tokens.funding_badge), funding,
    )
  }
  v(4em)
}

// A callout, redefined over the one Quarto writes. The template has no
// callout, so it takes the shading of the code blocks and a rule in the colour
// of the title. The kind of a callout carries no meaning beyond setting the
// passage apart, so the colours the call sites pass are ignored.
#let callout(
  body: [],
  title: "Callout",
  background_color: none,
  icon: none,
  icon_color: none,
  body_background_color: none,
) = {
  block(
    breakable: true,
    width: 100%,
    fill: rgb(tokens.code.fill),
    stroke: (left: 2.5pt + brand),
    inset: (x: 10pt, y: 8pt),
    {
      block(below: 0.6em, text(weight: "bold", fill: brand)[#title])
      body
    },
  )
}

#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "GB",
  font: none,
  fontsize: none,
  title-size: none,
  subtitle-size: none,
  heading-family: none,
  heading-weight: none,
  heading-style: none,
  heading-color: none,
  heading-line-height: none,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: "1.1.1",
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: true,
  toc_title: none,
  toc_depth: 3,
  toc_indent: 1.5em,
  publication-date: none,
  document-code: none,
  doi: none,
  community: none,
  status: none,
  copyright: none,
  licence: none,
  funding: none,
  doc,
) = {
  let author-names = if authors == none { () } else { authors.map(a => a.name) }

  set document(
    title: title,
    author: author-names.map(name => if type(name) == str { name } else {
      // The names arrive as content. The PDF metadata wants plain strings.
      let flat(it) = if it.has("text") { it.text } else if it.has("children") {
        it.children.map(flat).join()
      } else if it == [ ] { " " } else { "" }
      flat(name)
    }),
    keywords: keywords,
  )

  set text(
    font: body-font,
    size: tokens.font.size_pt * 1pt,
    lang: lang,
    region: region,
  )
  // Word sets a line at 1.15 times the height of the font. Typst measures the
  // gap from the baseline to the cap height of the next line instead, which for
  // Arial comes to this leading.
  set par(justify: true, leading: 0.62em, spacing: 1.25em)
  set list(marker: ([•], [◦], [▪]), indent: 0.6em, spacing: 0.75em)
  set enum(indent: 0.6em, spacing: 0.75em)
  // External links and citations take the link colour of the template. A link
  // to a place in the document, such as an entry of the table of contents, is
  // left as it is.
  show link: it => {
    if type(it.dest) == location { return it }
    set text(fill: link-colour)
    if tokens.link.underline { underline(it) } else { it }
  }

  // Code is set on a shaded block that runs the width of the text.
  show raw: set text(font: code-font, size: tokens.code.size_pt * 1pt)
  show raw.where(block: true): set par(justify: false, leading: 0.5em)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: rgb(tokens.code.fill),
    inset: (x: 8pt, y: 8pt),
    breakable: true,
    it,
  )

  // The logo stands at the top right of every page, the cover included, and
  // the page number at the foot, except on the cover.
  let margin = tokens.page.margin_in
  set page(
    width: tokens.page.width_in * 1in,
    height: tokens.page.height_in * 1in,
    margin: (
      top: margin.top * 1in,
      bottom: margin.bottom * 1in,
      left: margin.left * 1in,
      right: margin.right * 1in,
    ),
    header: none,
    background: {
      place(
        top + right,
        dx: -margin.right * 1in,
        dy: tokens.logo.offset_y_in * 1in + 0.12in,
        image(assets + tokens.logo.file, width: tokens.logo.width_in * 1in),
      )
      // A draft carries a word across every page, behind the text.
      if status != none {
        place(
          center + horizon,
          rotate(-52deg, text(
            font: body-font,
            size: 96pt,
            weight: "bold",
            fill: brand.transparentize(88%),
          )[#status]),
        )
      }
    },
    footer-descent: (margin.bottom - tokens.page.footer_in) * 1in - 1em,
    footer: context {
      set text(size: tokens.font.size_pt * 1pt)
      let align-to = (left: left, center: center, right: right, both: right)
      align(
        align-to.at(tokens.footer.page_number_align, default: right),
        counter(page).display("1"),
      )
    },
  )

  // Headings are numbered 1, 1.1 and 1.1.1 in the body, and the appendices are
  // lettered: Appendix A, A.1. The template sets them in the body font, not
  // bold, and greys the lower levels.
  set heading(numbering: (..parts) => context section-number(here(), ..parts))
  show heading: it => context {
    let token = heading-token(it.level)
    set text(
      size: token.size_pt * 1pt,
      fill: rgb(token.colour),
      weight: if token.bold { "bold" } else { "regular" },
    )
    set par(justify: false, leading: 0.4em)
    let number = if it.numbering != none {
      let shown = counter(heading).display(it.numbering)
      if it.level == 1 and in-appendix(it.location()) {
        [Appendix #shown -- ]
      } else {
        [#shown #h(0.4em)]
      }
    }
    block(
      above: token.before_pt * 1pt + 0.6em,
      below: token.after_pt * 1pt + 0.4em,
      sticky: true,
    )[#number#it.body]
  }

  // Quarto writes every reference to a section with the supplement Section. A
  // reference to an appendix reads Appendix A instead.
  show ref: it => {
    let target = it.element
    if target == none or target.func() != heading or target.level != 1 { return it }
    context {
      let place = target.location()
      if not in-appendix(place) { return it }
      link(place, [Appendix #numbering("A", counter(heading).at(place).first())])
    }
  }

  // Figures and tables are numbered within the top-level section, as Figure
  // 2.1 and Table 8.1 are in the template, and the count restarts at each one.
  show heading.where(level: 1): it => {
    counter(figure.where(kind: "quarto-float-fig")).update(0)
    counter(figure.where(kind: "quarto-float-tbl")).update(0)
    counter(figure.where(kind: "quarto-float-lst")).update(0)
    it
  }
  set figure(numbering: n => context {
    let chapter = counter(heading).get().first()
    if chapter == 0 { numbering("1", n) } else {
      section-number(here(), chapter, n)
    }
  })

  // A caption is set beneath its figure or table, in italic and smaller than
  // the body, at the start edge as in the template. A figure centres its body,
  // and the cells of a table take the alignment of the figure, so the alignment
  // of a table is set back to the start edge.
  // A table longer than a page breaks across it. A figure does not, so that an
  // image is never parted from its caption.
  show figure: set block(above: 1.4em, below: 1.4em)
  show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)
  show figure.where(kind: "quarto-float-tbl"): set align(left)
  show figure.where(kind: "quarto-float-tbl"): set figure.caption(position: bottom)
  show figure.caption: set text(
    size: tokens.caption.size_pt * 1pt,
    style: if tokens.caption.italic { "italic" } else { "normal" },
  )
  show figure.caption: set par(justify: false)
  show figure.caption: it => align(left, it)

  // Tables are ruled on every edge in black, as in the template, with the
  // header row in bold. A narrow column stretches the words of a justified
  // cell, so a cell is set ragged right.
  set table(stroke: rule, inset: tokens.table.inset_pt * 1pt)
  // A table breaks between its rows, never inside one, so a row is read whole.
  set table.cell(breakable: false)
  show table: set text(size: tokens.table.body_size_pt * 1pt)
  show table.cell: set par(justify: false, leading: 0.5em)
  show table.cell.where(y: 0): set text(weight: "bold")

  cover(
    title: title,
    authors: if authors == none { () } else { authors },
    publication-date: publication-date,
    document-code: document-code,
    doi: doi,
    community: community,
    abstract: abstract,
  )

  notices(copyright: copyright, licence: licence, funding: funding)

  if toc {
    // The table of contents of the template has no title. The numbering of a
    // heading is worked out where it is shown, and the outline stands before
    // the appendices, so the number of an appendix entry is written here from
    // the count at the heading. Its top-level entries carry the word Appendix,
    // as the headings do.
    show outline.entry.where(level: 1): set text(weight: "bold")
    show outline.entry.where(level: 1): set block(above: 1em)
    show outline.entry: it => context {
      let target = it.element.location()
      if it.element.func() != heading or not in-appendix(target) { return it }
      let shown = numbering("A.1", ..counter(heading).at(target))
      let prefix = if it.level == 1 [Appendix #shown --] else [#shown]
      link(target, it.indented(prefix, it.inner()))
    }
    outline(title: none, depth: toc_depth, indent: toc_indent)
  }
  pagebreak()

  doc
}
