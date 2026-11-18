-- Presentation metadata lives outside the unchanged manuscript body.
function Pandoc(doc)
  local meta = doc.meta
  local number = meta["chapter-number"]
  local status = meta["draft-status"]
  local blocks = {}
  if number then
    blocks[#blocks + 1] = pandoc.Div({pandoc.Para({pandoc.Str("Chapter " .. pandoc.utils.stringify(number))})},
      pandoc.Attr("", {"book-eyebrow"}))
  end
  if status then
    blocks[#blocks + 1] = pandoc.Div({pandoc.Para({
      pandoc.Span({pandoc.Str(pandoc.utils.stringify(status))}, pandoc.Attr("", {"book-status"})),
    })}, pandoc.Attr("", {"book-chapter-meta"}))
  end
  for index = #blocks, 1, -1 do doc.blocks:insert(1, blocks[index]) end
  if meta["qa-index"] then
    local function nav_link(key, label, class)
      local target = meta[key]
      local contents = target and {pandoc.Link(label, pandoc.utils.stringify(target))} or {}
      return pandoc.Div({pandoc.Plain(contents)}, pandoc.Attr("", {class}))
    end
    doc.blocks:insert(pandoc.Div({
      nav_link("qa-previous", "← Previous chapter", "book-nav-previous"),
      nav_link("qa-index", "Chapter index", "book-nav-index"),
      nav_link("qa-next", "Next chapter →", "book-nav-next")
    }, pandoc.Attr("", {"qa-chapter-navigation"})))
  end
  return doc
end
