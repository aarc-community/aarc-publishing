--[[
Write a table as a list of rows.

A grid table is the only markdown table that holds lists or several paragraphs
in a cell, and prettier does not know it: it reflows a grid table as a
paragraph, and the table is lost without a warning. A list table holds the same
content as nested lists, which prettier formats correctly:

    ::: {.list-table #tbl-registration tbl-colwidths="[16,42,42]"}
    Client registration methods

    - - Aspect
      - Automatic registration
    - - Mechanism
      - - RP uses its federation entity id as the client ID
        - OP validates trust on the fly
    :::

Each item of the list is a row, and each item of a row is a cell, which holds
any blocks. The first row is the header; `header-rows="0"` gives a table with
no header, and a larger number a deeper one. The blocks before the list are the
caption, and an identifier starting tbl- makes the table one that @tbl-name
refers to, as for any other table. `tbl-colwidths` sets the relative width of
each column, as Quarto's option of the same name does for a pipe table. A row
shorter than the widest is filled with empty cells.

The filter runs at the pre-quarto stage, so the table it writes is captioned
and numbered by Quarto like one written in markdown.
]]

local function widths(spec, columns)
  local out = {}
  if spec then
    local values = {}
    for number in spec:gmatch('[%d%.]+') do
      table.insert(values, tonumber(number))
    end
    local total = 0
    for _, value in ipairs(values) do
      total = total + value
    end
    if #values == columns and total > 0 then
      for i, value in ipairs(values) do
        out[i] = value / total
      end
      return out
    end
    io.stderr:write(('list-table: tbl-colwidths names %d columns, the table has %d\n')
      :format(#values, columns))
  end
  for i = 1, columns do
    out[i] = 0 -- let the writer decide
  end
  return out
end

local function row_of(cells, columns)
  local out = {}
  for i = 1, columns do
    out[i] = pandoc.Cell(cells[i] or {})
  end
  return pandoc.Row(out)
end

function Div(div)
  if not div.classes:includes('list-table') then
    return nil
  end

  local caption, list = {}, nil
  for _, block in ipairs(div.content) do
    if list == nil and block.t == 'BulletList' then
      list = block
    elseif list == nil then
      table.insert(caption, block)
    else
      io.stderr:write('list-table: blocks after the list in '
        .. (div.identifier ~= '' and div.identifier or 'a list table')
        .. ' are dropped\n')
    end
  end
  if list == nil then
    io.stderr:write('list-table: a list table holds no list\n')
    return nil
  end

  -- Each item of the list is a row. An item that is itself a list gives the
  -- cells; anything else is a row of one cell.
  local rows, columns = {}, 0
  for _, item in ipairs(list.content) do
    local cells = {}
    if #item == 1 and item[1].t == 'BulletList' then
      for _, cell in ipairs(item[1].content) do
        table.insert(cells, cell)
      end
    else
      cells = { item }
    end
    columns = math.max(columns, #cells)
    table.insert(rows, cells)
  end

  local header_rows = tonumber(div.attributes['header-rows'] or '1')
  local head, body = {}, {}
  for i, cells in ipairs(rows) do
    table.insert(i <= header_rows and head or body, row_of(cells, columns))
  end

  local specs = {}
  for i, width in ipairs(widths(div.attributes['tbl-colwidths'], columns)) do
    specs[i] = { pandoc.AlignDefault, width }
  end

  local attributes = {}
  for key, value in pairs(div.attributes) do
    if key ~= 'header-rows' and key ~= 'tbl-colwidths' then
      attributes[key] = value
    end
  end
  local classes = div.classes:filter(function(class)
    return class ~= 'list-table'
  end)

  return pandoc.Table(
    { long = caption, short = {} },
    specs,
    pandoc.TableHead(head),
    { { attr = pandoc.Attr(), body = body, head = {}, row_head_columns = 0 } },
    pandoc.TableFoot(),
    pandoc.Attr(div.identifier, classes, attributes)
  )
end
