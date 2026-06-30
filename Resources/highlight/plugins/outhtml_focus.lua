
Description="Focuses the lines defined as comma separated list or range in the plug-in parameter (HTML)."

Categories = {"format", "html" }

function syntaxUpdate(desc)

  if HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML then
      return
  end

  if #HL_PLUGIN_PARAM == 0 then return end

  -- explode (separator, string)
  function explode(d,p)
    local t, ll
    t={}
    ll=0
    if(#p == 1) then
      t[tonumber(p)] = 1
      return t
    end
    while true do
      l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        t[tonumber(string.sub(p,ll,l-1))] = 1
        ll=l+1 -- save just after where we found it for searching next time.
      else
        t[tonumber(string.sub(p,ll))] = 1
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
    return t
  end

  function range(p)
    local t, ll
    t={}
    ll=0
    l=string.find(p,'-',ll,true)
    if l~=nil then
      for i=tonumber(string.sub(p,ll,l-1)), tonumber(string.sub(p,l+1)), 1 do
        t[i] = 1
      end
    end
    return t
  end

  if (string.find(HL_PLUGIN_PARAM,'-')) == nil then
    linesToMark=explode(',', HL_PLUGIN_PARAM)
  else
    linesToMark=range(HL_PLUGIN_PARAM)
  end

  currentLineNumber=0
  currentColumn=0
  markStarts=true
  linesNoIdent = {}

  function DecorateLineBegin(lineNumber)
    currentLineNumber = lineNumber
    currentColumn=0

    if (linesToMark[currentLineNumber]) then
      return '<span class="hl mark">'
    else
      return '<span class="hl no_mark">'
    end
  end

  function DecorateLineEnd()
      return '</span>'
  end

end

function themeUpdate(desc)
  if HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML then
    return
  end
  -- looked up the trick here https://torchlight.dev/docs/annotations/focusing
  Injections[#Injections+1]=".hl.no_mark { transition: filter 0.3s, opacity 0.3s; opacity: 0.6; filter: blur(.095rem); }"
  Injections[#Injections+1]="pre.hl:hover .hl.no_mark { opacity: 1; filter: blur(0px); }"

end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
