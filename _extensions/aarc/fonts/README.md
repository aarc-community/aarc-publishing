# Fonts

The AARC template names fonts that are not free to redistribute. Each is set in
a substitute with the same metrics, so lines break where they break in Word.

| Template font   | Substitute      | Files                  | Licence                                    |
| --------------- | --------------- | ---------------------- | ------------------------------------------ |
| Arial           | Liberation Sans | `LiberationSans-*.ttf` | SIL OFL 1.1, in `LICENSE-LiberationSans`   |
| Source Code Pro | Source Code Pro | `SourceCodePro-*.otf`  | SIL OFL 1.1, in `LICENSE-SourceCodePro.md` |

The files are kept in the repository, rather than taken from the system, so a
build on a CI runner sets the same glyphs as a build on a laptop.
`design/tokens.json` names the font that each part of a guideline is set in.

The SIL Open Font License permits the fonts to be copied and redistributed with
this software, on these conditions:

- Each licence file stays beside the fonts it covers, with the copyright notice
  at its top.
- The fonts are not sold by themselves.
- The files are not changed. A changed font must not use the Reserved Font
  Names, which are Liberation, Arimo, Tinos and Cousine for Liberation Sans, and
  Source for Source Code Pro.

The licence does not apply to a document set in the fonts, so a PDF built here,
with the fonts embedded in it, is not bound by it.
