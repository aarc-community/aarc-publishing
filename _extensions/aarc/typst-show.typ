// Passes the front matter of a guideline to the article function of
// typst-template.typ. Each field of the cover is optional, and a field the
// front matter does not state is left off the cover.
#show: doc => article(
$if(title)$
  title: [$title$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    (name: [$it.name.literal$]$if(it.orcid)$, orcid: "$it.orcid$"$endif$),
$endif$
$endfor$
  ),
$endif$
$if(publication-date)$
  publication-date: [$publication-date$],
$endif$
$if(document-code)$
  document-code: [$document-code$],
$endif$
$if(doi)$
  doi: [$doi$],
$endif$
$if(community)$
  community: [$community$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(status)$
  status: [$status$],
$endif$
$if(copyright-notice)$
  copyright: [$copyright-notice$],
$endif$
$if(licence-notice)$
  licence: [$licence-notice$],
$endif$
$if(funding-notice)$
  funding: [$funding-notice$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$keywords$",$endfor$),
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-indent)$
  toc_indent: $toc-indent$,
$endif$
  toc_depth: $toc-depth$,
  doc,
)
