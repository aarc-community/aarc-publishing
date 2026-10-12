--[[
Letter the appendices.

A guideline marks its first appendix with the class `appendix` on the heading:

    # Federation Policies {.appendix #sec-federation-policies}

This filter places a call to aarc-appendix() in front of that heading. From
there on, typst-template.typ letters the top-level headings A, B, C, sets each
as "Appendix A -- Federation Policies", and numbers the figures, the tables and
the subsections beneath it A.1, A.2. Only the first heading needs the class.

Markdown has no notion of an appendix, and the PDF is the only output, so the
marker is a raw typst call and not a Div.
]]

local placed = false

function Header(header)
  if placed or not header.classes:includes('appendix') then
    return nil
  end
  placed = true
  return {
    pandoc.RawBlock('typst', '#aarc-appendix()'),
    header,
  }
end
