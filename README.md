# AARC publishing

The code that builds AARC guidelines as PDF, in the AARC guideline design. It
provides:

- the design, as a Quarto extension that sets a guideline through typst,
- the toolchain, as a devenv module that pins Quarto, typst and the tools a
  build needs,
- the commands a repository of guidelines builds and checks with.

The guidelines themselves are not here. They live in their own repository, which
imports this one. See [Using it in a repository of guidelines](#using-it).

## Contents

| Path                                  | Purpose                                                        |
| ------------------------------------- | -------------------------------------------------------------- |
| `_extensions/aarc/`                   | The Quarto extension. `format: aarc-typst` selects it          |
| `_extensions/aarc/_extension.yml`     | The format: options, filters, citation style, fonts            |
| `_extensions/aarc/typst-template.typ` | The layout of a guideline                                      |
| `_extensions/aarc/typst-show.typ`     | Passes the front matter to that layout                         |
| `_extensions/aarc/design/tokens.json` | Colours, fonts, sizes and page geometry                        |
| `_extensions/aarc/design/assets/`     | The logo, the badges of the notices page, the ORCID iD icon    |
| `_extensions/aarc/filters/`           | List tables, appendices, normative and informative citations   |
| `_extensions/aarc/fonts/`             | The fonts, metric-compatible with those of the Word design     |
| `example/aarc-gxxx-example/`          | The example guideline. The test, and the starter for new ones  |
| `scripts/check-output.py`             | Reads each PDF back and reports what a render can get wrong    |
| `nix/quarto.nix`                      | Packages the upstream Quarto release                           |
| `devenv.nix`                          | The toolchain, and the module a repository of guidelines takes |
| `.github/workflows/test.yml`          | Renders and checks the example on GitHub                       |
| `LICENSE`                             | The MIT licence of the code                                    |

## Working on the publishing code

`devenv shell` enters the toolchain: Quarto 1.10.18 with the pandoc and typst
0.15.1 it bundles, Python, `just`, `prettier` and poppler.

    just build    # render the example guideline
    just ci       # render it and fail on any warning or unresolved reference

`.github/workflows/test.yml` runs `devenv test`, which checks the toolchain, and
`just ci` on every push to `main` and every pull request, and keeps the example
PDF as the artifact `example` of the run.

The example in `example/` uses every element a guideline can contain, so
`just ci` passing is the test that a change to the extension works. The output
is `generated/example/aarc-gxxx-example/aarc-gxxx-example.pdf`.

## The design

The design is the one the AARC guidelines have had in Word. It was taken from
the Word file of AARC-G100 once, and is maintained here, not in Word:

- `design/tokens.json` holds the values: the colours, the fonts, the size and
  spacing of each heading level, the cover, the captions, the tables, the code
  blocks and the page geometry. A change of colour or size is a change to this
  file.
- `design/assets/` holds the AARC logo of the running header, the licence badge
  and the funding flag of the notices page, and the ORCID iD icon of the cover.
  A new logo replaces the file of the same name. `orcid-id.svg` is the official
  icon from orcid.org, which ORCID asks to be used unaltered.
- `typst-template.typ` holds the layout: the cover, the notices page, the header
  and the footer, the numbering of headings, figures and appendices, and the
  look of tables, code and captions. It reads its values from `tokens.json`
  rather than stating them.

Render the example after a change and look at the PDF. `just ci` catches a
change that breaks the build, but not one that looks wrong.

## Using it in a repository of guidelines {#using-it}

A repository of guidelines imports this one in its `devenv.yaml`:

    inputs:
      aarc-publishing:
        url: github:AARC-Community/aarc-publishing
        flake: false
    imports:
      - aarc-publishing

and declares the format in its `_quarto.yml`:

    format: aarc-typst

The import gives it the toolchain and these:

| Name              | What it is                                                      |
| ----------------- | --------------------------------------------------------------- |
| `aarc-install`    | Copies the extension into `_extensions/aarc/` of the project    |
| `aarc-check`      | Checks the rendered PDFs, given the sources as a glob           |
| `$AARC_STARTER`   | The example guideline, which a new guideline is copied from     |
| `$AARC_EXTENSION` | The extension itself, as this commit of the repository holds it |

Its `devenv.lock` pins the commit of this repository it uses, so the tools and
the design a guideline is built with move together, and `devenv update` takes
the newest. The extension is installed at each build rather than committed, so
there is no second copy to fall out of step.

The extension has to sit at `_extensions/aarc/` in the project root, because the
typst template reads its design files by their path from that root.

## Writing a guideline

`example/aarc-gxxx-example/aarc-gxxx-example.qmd` is the reference. In short:

**The cover comes from the front matter.** `title`, `document-code`,
`publication-date`, `author`, `doi`, `community` and `abstract`. `status: DRAFT`
prints the word across every page.

**An author can carry an ORCID iD.** An author is a name, or a name with the iD,
which the cover shows as the ORCID iD icon linked to the author's record:

    author:
      - name: "Diana Gudu (ed)"
        orcid: "0000-0002-1825-0097"
      - "Halil Adem"

Give the iD alone, without `https://orcid.org/`. `aarc-check` fails a guideline
whose iD is in another form or has a wrong check digit, because either would
link the cover to someone else's record or to none.

**The notices are shared.** The copyright, the licence and the funding statement
are set in `_extension.yml` as `copyright-notice`, `licence-notice` and
`funding-notice`. A guideline funded by another project overrides
`funding-notice` in its front matter.

**Headings carry no numbers.** A heading has an identifier,
`# Trust Model {#sec-trust-model}`, and a reference to it is `@sec-trust-model`.
Figures and tables are referenced with `@fig-` and `@tbl-` and are numbered
within their section, as Figure 2.1.

**Appendices are lettered.** The class `appendix` goes on the first appendix
heading. Every top-level heading after it is an appendix.

**Citations use labels.** Each guideline has a `references.json` in CSL JSON,
where `citation-label` is the label printed. Cite with `[@OID-Fed]`. The entries
named under `normative-references` are listed apart from the informative ones.
The list is placed with `<div id="refs"></div>`. An empty fenced div does the
same, but prettier joins its fences into one line and breaks it.

**A table is a pipe table or a list table.** A table whose cells hold one line
of text each is a pipe table. A table whose cells hold a list or several
paragraphs is a list table, in which each item of the list is a row and each
item of a row is a cell:

    ::: {.list-table #tbl-trade-offs tbl-colwidths="[20,40,40]"}

    Trade-offs of the registration methods

    - - Aspect
      - Automatic registration
    - - Pros
      - - No need for prior contact
        - Fully dynamic

    :::

The first row is the header, and `header-rows` sets another number. The
paragraph before the list is the caption. `tbl-colwidths` sets the relative
width of each column, on the div of a list table and on the caption line of a
pipe table. Grid tables are not used: prettier reflows one into a paragraph, and
the table disappears from the PDF without a warning. `aarc-check` fails a
guideline that contains one.

**Every `:::` line stands alone**, with a blank line before and after it.
Without them, prettier joins the line to the text beside it, and the div is
lost. `aarc-check` fails a guideline with a fence that does not.

**A wide table goes on a landscape page**, inside a `::: {.landscape}` div.

## Licence

The code and the documentation of this repository are under the MIT licence, in
`LICENSE`. These files are not under the MIT licence, because other parties hold
the rights to them:

| Path                                           | Holder and terms                                                   |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `_extensions/aarc/fonts/LiberationSans-*.ttf`  | Google and Red Hat, SIL OFL 1.1, as in `LICENSE-LiberationSans`    |
| `_extensions/aarc/fonts/SourceCodePro-*.otf`   | Adobe, SIL OFL 1.1, as in `LICENSE-SourceCodePro.md`               |
| `_extensions/aarc/design/assets/aarc-logo.jpg` | The AARC Community. The logo of the AARC guidelines                |
| `_extensions/aarc/design/assets/cc-by.png`     | Creative Commons. The badge of the CC BY 4.0 licence               |
| `_extensions/aarc/design/assets/eu-flag.png`   | The European Union. The emblem for a statement of EU funding       |
| `_extensions/aarc/design/assets/orcid-id.svg`  | ORCID. The iD icon, which ORCID permits for a link to an iD record |

The PDF of a guideline is under the licence that the guideline gives on its
cover, and not under the licence of this repository.
