return function(Builder, LL)

-- Print

local ipairs, pairs, print, tostring, type
    = ipairs, pairs, print, tostring, type

local s, t, u = require"string", require"table", require"util"
local S_tostring = Builder.set.tostring


local _ENV = u.noglobals() ----------------------------------------------------



local s_char, s_sub, t_concat
    = s.char, s.sub, t.concat

local   expose,   map
    = u.expose, u.map

local escape_index = {
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\v"] = "\\v",
    ["\127"] = "\\ESC"
}

local function flatten(kind, list)
    if list[2].pkind == kind then
        return list[1], flatten(kind, list[2])
    else
        return list[1], list[2]
    end
end

for i = 0, 8 do escape_index[s_char(i)] = "\\"..i end
for i = 14, 31 do escape_index[s_char(i)] = "\\"..i end

local
function escape( str )
    return str:gsub("%c", escape_index)
end

local
function set_repr (set)
    local s = ''
    for cs in (S_tostring(set) .. ','):gmatch '(%d+),' do
        s = s .. s_char(tonumber(cs))
    end
    return s
end


local printers = {}

local
function LL_pprint (pt, offset, prefix)
    -- [[DBG]] print("PRINT -", pt)
    -- [[DBG]] print("PRINT +", pt.pkind)
    -- [[DBG]] expose(pt)
    -- [[DBG]] expose(LL.proxycache[pt])
    return printers[pt.pkind](pt, offset, prefix)
end

function LL.pprint (pt0)
    local pt = LL.P(pt0)
    print"\nPrint pattern"
    LL_pprint(pt, "", "")
    print"--- /pprint\n"
    return pt0
end

printers.string = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( \""..escape(pt.as_is).."\" )"})
end
printers.char = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( \""..escape(to_char(pt.aux)).."\" )"})
end
printers["true"] = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( true )"})
end
printers["false"] = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( false )"})
end
printers.eos = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"~EOS~"})
end
printers.one = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( one )"})
end
printers.any = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( "..pt.aux.." )"})
end
printers.set = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"S( "..'"'..escape(set_repr(pt.aux))..'"'.." )"})
end
printers["function"] = function (pt, offset, prefix)
    print(t_concat{offset,prefix,"P( "..pt.aux.." )"})
end
printers.ref = function (pt, offset, prefix)
    print(t_concat{offset,prefix,
        "V( ",
            (type(pt.aux) == "string" and "\""..pt.aux.."\"")
                          or tostring(pt.aux)
        , " )"
    })
end
printers.range = function (pt, offset, prefix)
    print(t_concat{offset,prefix,
        "R( ",
            escape(t_concat(map(
                pt.as_is,
                function(e) return '"'..e..'"' end)
            , ", "))
        ," )"
    })
end

printers.behind = function (pt, offset, prefix)
    LL_pprint(pt.pattern, offset, "B ")
end
printers["at least"] = function (pt, offset, prefix)
    LL_pprint(pt.pattern, offset, pt.aux.." ^ ")
end
printers["at most"] = function (pt, offset, prefix)
    LL_pprint(pt.pattern, offset, pt.aux.." ^ ")
end
printers.unm = function (pt, offset, prefix)
    LL_pprint(pt.pattern, offset, "- ")
end
printers.lookahead = function (pt, offset, prefix)
    LL_pprint(pt.pattern, offset, "# ")
end
printers.choice = function (pt, offset, prefix)
    print(offset..prefix.."+")
    -- dprint"Printer for choice"
    local ch, i = {}, 1
    while pt.pkind == "choice" do
        ch[i], pt, i = pt[1], pt[2], i + 1
    end
    ch[i] = pt

    map(ch, LL_pprint, offset.." :", "")
end
printers.sequence = function (pt, offset, prefix)
    -- print("Seq printer", s, u)
    -- u.expose(pt)
    print(offset..prefix.."*")
    local acc, p2 = {}
    offset = offset .. " |"
    while true do
        if pt.pkind ~= "sequence" then -- last element
            if pt.pkind == "char" then
                acc[#acc + 1] = pt.aux
                print(offset..'P( "'..s.char(u.unpack(acc))..'" )')
            else
                if #acc ~= 0 then
                    print(offset..'P( "'..s.char(u.unpack(acc))..'" )')
                end
                LL_pprint(pt, offset, "")
            end
            break
        elseif pt[1].pkind == "char" then
            acc[#acc + 1] = pt[1].aux
        elseif #acc ~= 0 then
            print(offset..'P( "'..s.char(u.unpack(acc))..'" )')
            acc = {}
            LL_pprint(pt[1], offset, "")
        else
            LL_pprint(pt[1], offset, "")
        end
        pt = pt[2]
    end
end
printers.grammar = function (pt, offset, prefix)
    print(offset..prefix.."Grammar")
    -- dprint"Printer for Grammar"
    for k, pt in pairs(pt.aux) do
        local prefix = ( type(k)~="string"
        and tostring(k)
        or "\""..k.."\"" )
        LL_pprint(pt, offset.."  ", prefix .. " = ")
    end
end

-------------------------------------------------------------------------------
--- Captures patterns
--

-- for _, cap in pairs{"C", "Cs", "Ct"} do
-- for _, cap in pairs{"Carg", "Cb", "Cp"} do
-- function LL_Cc (...)
-- for _, cap in pairs{"Cf", "Cmt"} do
-- function LL_Cg (pt, tag)
-- local valid_slash_type = newset{"string", "number", "table", "function"}


for _, cap in pairs{"C", "Cs", "Ct"} do
    printers[cap] = function (pt, offset, prefix)
        print(offset..prefix..cap)
        LL_pprint(pt.pattern, offset.."  ", "")
    end
end

for _, cap in pairs{"Cg", "Clb", "Cf", "Cmt", "div_number", "/zero", "div_function", "div_table"} do
    printers[cap] = function (pt, offset, prefix)
        print(offset..prefix..cap.." "..tostring(pt.aux or ""))
        LL_pprint(pt.pattern, offset.."  ", "")
    end
end

printers["div_string"] = function (pt, offset, prefix)
    print(offset..prefix..'/string "'..tostring(pt.aux or "")..'"')
    LL_pprint(pt.pattern, offset.."  ", "")
end

for _, cap in pairs{"Carg", "Cp"} do
    printers[cap] = function (pt, offset, prefix)
        print(offset..prefix..cap.."( "..tostring(pt.aux).." )")
    end
end

printers["Cb"] = function (pt, offset, prefix)
    print(offset..prefix.."Cb( \""..pt.aux.."\" )")
end

printers["Cc"] = function (pt, offset, prefix)
    print(offset..prefix.."Cc(" ..t_concat(map(pt.aux, tostring),", ").." )")
end


-------------------------------------------------------------------------------
--- Capture objects
--

local cprinters = {}

local padding = "   "
local function padnum(n)
    n = tostring(n)
    n = n .."."..((" "):rep(4 - #n))
    return n
end

local function _cprint(caps, ci, indent, sbj, n)
    local openclose, kind = caps.openclose, caps.kind
    indent = indent or 0
    while kind[ci] and openclose[ci] >= 0 do
        if caps.openclose[ci] > 0 then
            print(t_concat({
                            padnum(n),
                            padding:rep(indent),
                            caps.kind[ci],
                            ": start = ", tostring(caps.bounds[ci]),
                            " finish = ", tostring(caps.openclose[ci]),
                            caps.aux[ci] and " aux = " or "",
                            caps.aux[ci] and (
                                type(caps.aux[ci]) == "string"
                                    and '"'..tostring(caps.aux[ci])..'"'
                                or tostring(caps.aux[ci])
                            ) or "",
                            " \t", s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)
                        }))
            if type(caps.aux[ci]) == "table" then expose(caps.aux[ci]) end
        else
            local kind = caps.kind[ci]
            local start = caps.bounds[ci]
            print(t_concat({
                            padnum(n),
                            padding:rep(indent), kind,
                            ": start = ", start,
                            caps.aux[ci] and " aux = " or "",
                            caps.aux[ci] and (
                                type(caps.aux[ci]) == "string"
                                    and '"'..tostring(caps.aux[ci])..'"'
                                or tostring(caps.aux[ci])
                            ) or ""
                        }))
            ci, n = _cprint(caps, ci + 1, indent + 1, sbj, n + 1)
            print(t_concat({
                            padnum(n),
                            padding:rep(indent),
                            "/", kind,
                            " finish = ", tostring(caps.bounds[ci]),
                            " \t", s_sub(sbj, start, (caps.bounds[ci] or 1) - 1)
                        }))
        end
        n = n + 1
        ci = ci + 1
    end

    return ci, n
end

function LL.cprint (caps, ci, sbj)
    ci = ci or 1
    print"\nCapture Printer:\n================"
    -- print(capture)
    -- [[DBG]] expose(caps)
    _cprint(caps, ci, 0, sbj, 1)
    print"================\n/Cprinter\n"
end




return { pprint = LL.pprint,cprint = LL.cprint }

end -- module wrapper ---------------------------------------------------------


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The LuLPeg library
--
--                                             \
--                                              '.,__
--                                           \  /
--                                            '/,__
--                                            /
--                                           /
--                                          /
--                       has been          / released
--                  ~ ~ ~ ~ ~ ~ ~ ~       ~ ~ ~ ~ ~ ~ ~ ~
--                under  the  Romantic   WTF Public License.
--               ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~`,´ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
--               I hereby grant you an irrevocable license to
--                ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
--                  do what the gentle caress you want to
--                       ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
--                           with   this   lovely
--                              ~ ~ ~ ~ ~ ~ ~ ~
--                               / thing...
--                              /  ~ ~ ~ ~
--                             /    Love,
--                        #   /      '.'
--                        #######      ·
--                        #####
--                        ###
--                        #
--
--            -- Pierre-Yves
--
--
--            P.S.: Even though I poured my heart into this work,
--                  I _cannot_ provide any warranty regarding
--                  its fitness for _any_ purpose. You
--                  acknowledge that I will not be held liable
--                  for any damage its use could incur.
