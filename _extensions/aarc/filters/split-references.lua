--[[
Split the bibliography into Normative References and Informative References.

RFC 7322 Section 4.8.6 requires a reference list to indicate whether each entry
is normative or informative, and to split it into two subsections when both
kinds are present. Pandoc's citeproc emits one bibliography into a single Div
with the identifier "refs", and this filter partitions that Div.

Quarto runs citeproc after its whole Lua filter chain, so no filter stage sees a
populated bibliography. This filter therefore runs citeproc itself, at the
pre-quarto stage, before Quarto rewrites tables into raw typst and puts the
citations they contain beyond citeproc's reach. _quarto.yml sets
`citeproc: false` on each format so that citations are resolved once, here.

    filters:
      - path: split-references.lua
        at: pre-quarto

The normative entries are named in the `normative-references` metadata list, one
citation key per item. Every other entry is informative.

The filter leaves a document with no bibliography, or with entries of only one
kind, exactly as citeproc produced it.
]]

-- The generated headings sit one level below the section holding the
-- bibliography, wherever that section is placed in the document.
-- They are unnumbered when that section is, as the References section of a
-- guideline is.
local enclosing = { level = 2, unnumbered = false }

local function headingFor(text, identifier)
  local classes = enclosing.unnumbered and { 'unnumbered' } or {}
  return pandoc.Header(enclosing.level + 1, pandoc.Str(text), pandoc.Attr(identifier, classes))
end

local function normativeKeys(meta)
  local keys = {}
  local declared = meta['normative-references']
  if declared then
    for _, key in ipairs(declared) do
      keys[pandoc.utils.stringify(key)] = true
    end
  end
  return keys
end

local function splitter(keys)
  return function(div)
    if div.identifier ~= 'refs' then
      return nil
    end

    local normative, informative = {}, {}
    for _, entry in ipairs(div.content) do
      local key = entry.identifier and entry.identifier:match('^ref%-(.+)$')
      if key and keys[key] then
        table.insert(normative, entry)
      else
        table.insert(informative, entry)
      end
    end

    if #normative == 0 or #informative == 0 then
      return nil
    end

    local function body(entries, identifier)
      return pandoc.Div(entries, pandoc.Attr(identifier, div.classes, div.attributes))
    end

    return {
      headingFor('Normative References', 'sec-normative-references'),
      body(normative, 'refs-normative'),
      headingFor('Informative References', 'sec-informative-references'),
      body(informative, 'refs-informative'),
    }
  end
end

-- Quarto writes a cross-reference as a citation, and its crossref filter runs
-- after this one. citeproc would consume @sec-x and @tbl-x as unresolvable
-- citations, so they are set aside across the citeproc call and put back.
local crossrefPrefixes = {
  sec = true, fig = true, tbl = true, eq = true, lst = true, thm = true,
  lem = true, cor = true, prp = true, cnj = true, def = true, exm = true,
  exr = true, sol = true, rem = true, nte = true, tip = true, wrn = true,
  imp = true, cau = true, vid = true,
}

local function isCrossReference(cite)
  for _, citation in ipairs(cite.citations) do
    local prefix = citation.id:match('^(%a+)%-')
    if not (prefix and crossrefPrefixes[prefix]) then
      return false
    end
  end
  return true
end

function Pandoc(doc)
  local keys = normativeKeys(doc.meta)

  local stash, n = {}, 0
  doc.blocks = doc.blocks:walk({
    Cite = function(cite)
      if not isCrossReference(cite) then
        return nil
      end
      n = n + 1
      stash[tostring(n)] = cite
      return pandoc.RawInline('quarto-crossref', tostring(n))
    end,
  })

  local resolved = pandoc.utils.citeproc(doc)

  resolved.blocks = resolved.blocks:walk({
    RawInline = function(raw)
      if raw.format == 'quarto-crossref' then
        return stash[raw.text]
      end
      return nil
    end,
    -- citeproc fills in the text of a Cite but leaves the node in place, and
    -- the typst writer renders a surviving Cite natively as @key against a
    -- typst bibliography that does not exist. Replace each with its text.
    Cite = function(cite)
      return cite.content
    end,
  })

  resolved.blocks = resolved.blocks:walk({
    Header = function(header)
      enclosing.level = header.level
      enclosing.unnumbered = header.classes:includes('unnumbered')
    end,
    Div = splitter(keys),
  })
  -- Left in place, the metadata makes the typst writer emit a native
  -- #bibliography() call over a JSON file that typst cannot read, and a
  -- #set bibliography(style:) over a CSL path that typst rejects. citeproc has
  -- already rendered the entries, so neither is needed.
  resolved.meta.bibliography = nil
  resolved.meta.csl = nil
  return resolved
end
