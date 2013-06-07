-- PureLPeg, a pure Lua port of LPeg, Roberto Ierusalimschy's
-- Parsing Expression  Grammars library.
-- 
-- Copyright (C) Pierre-Yves Gerardy.
-- Released under the Romantif WTF Public License (cf. the LICENSE
-- file or the end of this file, whichever is present).
-- 
-- See http://www.inf.puc-rio.br/~roberto/lpeg/ for the original.
local module_name = ...
local _ENV,       error,          loaded, packages, release, require_ 
    = _ENV or _G, error or print, {},     {},       true,    require
local t_concat = require"table".concat
local function pront(...) print("pront",...) return ... end
local function require(...)
    local lib = ...
    print("require",lib)
    -- is it a private file?
    if loaded[lib] then 
        return loaded[lib]
    elseif packages[lib] then 
        loaded[lib] = packages[lib](lib)
        print(loaded[lib])
        return loaded[lib]
    else
        -- standard require.
        local success, lib = pcall(require_, lib)
        
        if success then return lib end

        -- -- error handling.
        -- local name, line, trace
        -- local success, d = pcall(require, "debug")
        -- if success then success, d = pcall (debug.getinfo, 2) end
        -- if success then
        --     line = d.currentline or "-1"
        --     name = ( d.name ~= "" ) and name 
        --         or ( d.shortsrc ~= "" ) and d.shortsrc
        --         or "?"
        --     success, trace = pcall(d.traceback(1))
        --     if not success then trace = "" end
        -- else
        --     line, name, trace = -1, "?", ""
        -- end

        -- print(t_concat( name, ":", line, ": module '", lib, "' not found:"))
        -- print(t_concat("\tno private field ", module_name,".packages['",
        --     lib,"']\n", trace))
        -- error()
    end
end

--=============================================================================
do local _ENV = _ENV
packages['optimizer'] = function (...)
--
end
end
--=============================================================================
do local _ENV = _ENV
packages['compat'] = function (...)
local _, debug, jit

_, debug = pcall(require, "debug")
if not _ then debug = nil end

_, jit = pcall(require, "jit")
if not _ then jit = nil end

local compat = {
    lua52_len = not #setmetatable({},{__len = nop}), 
    proxies --= false local FOOO
        = newproxy
        and (function()
            local ok, result = pcall(newproxy)
            return ok and (type(result) == "userdata" )
        end)()
        and type(debug) == "table"
        and (function() 
            local prox, mt = newproxy(), {}
            local pcall_ok, db_setmt_ok = pcall(debug.setmetatable, prox, mt)
            return pcall_ok and db_setmt_ok and (getmetatable(prox) == mt)
        end)(),
    lua52 = _VERSION == "Lua 5.2",
    luajit = jit and true or false,
    jit = (jit and jit.status())
}

compat .lua51 = (_VERSION == "Lua 5.1") and not luajit
-- [[DB]] print("compat")
-- [[DB]] for k, v in pairs(compat) do print(k,v) end

return compat
end
end
--=============================================================================
do local _ENV = _ENV
packages['validator'] = function (...)
--
end
end
--=============================================================================
do local _ENV = _ENV
packages['match'] = function (...)
---------------------------------------  .   ,      ,       ,     ------------
---------------------------------------  |\ /| ,--. |-- ,-- |__   ------------
-- Match ------------------------------  | v | ,--| |   |   |  |  ------------
---------------------------------------  '   ' `--' `-- `-- '  '  ------------

local error, select, type = error, select, type

local u =require"util"


local _ENV = u.noglobals() ---------------------------------------------------


local t_unpack = u.unpack


return function(Builder, PL) -------------------------------------------------

local PL_compile, PL_cprint, PL_evaluate, PL_P, PL_pprint
    = PL.compile, PL.Cprint, PL.evaluate, PL.P, PL.pprint


function PL.match(pt, subject, index, ...)
    -- [[DP]] print("@!!! Match !!!@")
    pt = PL_P(pt)
    if index == nil then
        index = 1
    elseif type(index) ~= "number" then
        error"The index must be a number"
    elseif index == 0 then
        -- return nil 
        -- This allows to pass the test, but not suer if correct.
        error("Dunno what to do with a 0 index")
    elseif index < 0 then
        index = #subject + index + 1
        if index < 1 then index = 1 end
    end
    -- print(("-"):rep(30))
    -- print(pt.ptype)
    -- PL.pprint(pt)
    local matcher, cap_acc, state, success, cap_i, nindex
        = PL_compile(pt, {})
        , {type = "insert"}   -- capture accumulator
        , {grammars = {}, args = {n = select('#',...),...}, tags = {}}
        , 0 -- matcher state
    success, nindex, cap_i = matcher(subject, index, cap_acc, 1, state)
    -- [[DP]] print("!!! Done Matching !!!")
    if success then
        cap_acc.n = cap_i
        -- print("cap_i = ",cap_i)
        -- print("= $$$ captures $$$ =", cap_acc)
        -- PL.cprint(cap_acc)
        local cap_values, cap_i = PL_evaluate(cap_acc, subject, index)
        if cap_i == 1
        then return nindex
        else return t_unpack(cap_values, 1, cap_i - 1) end
    else 
        return nil 
    end
end

end -- /wrapper --------------------------------------------------------------
end
end
--=============================================================================
do local _ENV = _ENV
packages['constructors'] = function (...)
---------------------------------------   ,--.                 ----------------
---------------------------------------  /     ,--. ,-.  ,--.  ----------------
-- Constructors -----------------------  \     |  | |  | `--.  ----------------
---------------------------------------   `--' `--' '  ' `--'  ----------------


--[[---------------------------------------------------------------------------
Patterns have the following, optional fields:

- type: the pattern type. ~1 to 1 correspondance with the pattern constructors
    described in the LPeg documentation.
- pattern: the one subpattern held by the pattern, like most captures, or 
    `#pt`, `-pt` and `pt^n`.
- aux: any other type of data associated to the pattern. Like the string of a
    `P"string"`, the range of an `R`, or the list of subpatterns of a `+` or
    `*` pattern. In some cases, the data is pre-processed. in that case,
    the `as_is` field holds the data as passed to the constructor.
- as_is: see aux.
- meta: A table holding meta information about patterns, like their
    minimal and maximal width, the form they can take when compiled, 
    whether they are terminal or not (no V patterns), and so on.
--]]---------------------------------------------------------------------------

local ipairs, newproxy, setmetatable 
    = ipairs, newproxy, setmetatable

local d, t, u, dtst, compat
    = require"debug", require"table"
    , require"util", require"datastructures", require"compat"

local t_concat, t_sort
    = t.concat, t.sort

local copy, getuniqueid, id, map
    , nop, weakkey, weakval
    = u.copy, u.getuniqueid, u.id, u.map
    , u.nop, u.weakkey, u.weakval

local _ENV = u.noglobals()



--- The type of cache for each kind of pattern:
--

local classpt = {
    constant = {
        "Cp", "true", "false"
    },
    -- only aux
    aux = {
        "string", "any",
        "char", "range", "set", 
        "ref", "sequence", "choice",
        "Carg", "Cb"
    },
    -- only sub pattern
    subpt = {
        "unm", "lookahead", "C", "Cf", 
        "Cg", "Cs", "Ct", "/zero"
    }, 
    -- both
    both = {
        "behind", "at least", "at most", "Ctag", "Cmt",
        "/string", "/number", "/table", "/function"
    },
    none = "grammar", "Cc"
}



-------------------------------------------------------------------------------
return function(Builder, PL) --- module wrapper.
--


local split_int, S_tostring 
    = Builder.charset.split_int, Builder.set.tostring


-------------------------------------------------------------------------------
--- Base pattern constructor
--

local newpattern do 
    -- This deals with the Lua 5.1/5.2 compatibility, and restricted 
    -- environements without access to newproxy and/or debug.setmetatable.
    local setmetatable = setmetatable

    function PL.get_direct (p) return p end

    if compat.lua52_len then
        -- Lua 5.2 or LuaJIT + 5.2 compat. No need to do the proxy dance.
        function newpattern(pt)
            return setmetatable(pt,PL) 
        end    
    elseif compat.proxies then -- Lua 5.1 / LuaJIT without compat.
        local d_setmetatable, newproxy
            = d.setmetatable, newproxy

        local proxycache = weakkey{}
        local __index_PL = {__index = PL}
        PL.proxycache = proxycache
        function newpattern(cons) 
            local pt = newproxy()
            setmetatable(cons, __index_PL)
            proxycache[pt]=cons
            d_setmetatable(pt,PL) 
            return pt
        end
        function PL:__index(k)
            return proxycache[self][k]
        end
        function PL:__newindex(k, v)
            proxycache[self][k] = v
        end
        function PL.get_direct(p) return proxycache[p] end
    else
        -- Fallback if neither __len(table) nor newproxy work 
        -- (is there such a Lua version?)
        if PL.warnings then
            print("Warning: The `__len` metatethod won't work with patterns, "
                .."use `PL.L(pattern)` for lookaheads.")
        end
        function newpattern(pt)
            return setmetatable(pt,PL) 
        end    
    end
end


-------------------------------------------------------------------------------
--- The caches
--

-- Warning regarding caches: if composite patterns are memoized,
-- their comiled version must not be stored in them if the
-- hold references. Currently they are thus always stored in
-- the compiler cache, not the pattern itself.





-- -- reverse lookup
-- local ptclass = {}
-- for class, pts in pairs(classpt) do
--     for _, pt in pairs(pts) do
--         ptclass[pt] = class
--     end
-- end
local ptcache, meta
local
function resetcache()
    ptcache, meta = {}, weakkey{}

    -- Patterns with aux only.
    for _, p in ipairs (classpt.aux) do
        ptcache[p] = weakval{}
    end

    -- Patterns with only one sub-pattern.
    for _, p in ipairs(classpt.subpt) do
        ptcache[p] = weakval{}
    end

    -- Patterns with both
    for _, p in ipairs(classpt.both) do
        ptcache[p] = {}
    end

    return ptcache
end
PL.resetptcache = resetcache

resetcache()


-------------------------------------------------------------------------------
--- Individual pattern constructor
--

local constructors = {}
Builder.constructors = constructors

constructors["constant"] = {
    truept  = newpattern{ ptype = "true" },
    falsept = newpattern{ ptype = "false" },
    Cppt    = newpattern{ ptype = "Cp" }
}

-- data manglers that produce cache keys for each aux type.
-- `id()` for unspecified cases.
local getauxkey = {
    string = function(aux, as_is) return as_is end,
    table = copy,
    set = function(aux, as_is)
        return S_tostring(aux)
    end,
    range = function(aux, as_is)
        return t_concat(as_is, "|")
    end,
    sequence = function(aux, as_is) 
        return t_concat(map(getuniqueid, aux),"|") 
    end
}

getauxkey.choice = getauxkey.sequence

constructors["aux"] = function(typ, _, aux, as_is)
     -- dprint("CONS: ", typ, pt, aux, as_is)
    local cache = ptcache[typ]
    local key = (getauxkey[typ] or id)(aux, as_is)
    if not cache[key] then
        cache[key] = newpattern{
            ptype = typ,
            aux = aux,
            as_is = as_is
        }
    end
    return cache[key]
end

-- no cache for grammars
constructors["none"] = function(typ, _, aux)
     -- dprint("CONS: ", typ, pt, aux)
    return newpattern{
        ptype = typ,
        aux = aux
    }
end

constructors["subpt"] = function(typ, pt)
    -- [[DP]]print("CONS: ", typ, pt, aux) 
    local cache = ptcache[typ]
    if not cache[pt] then
        cache[pt] = newpattern{
            ptype = typ,
            pattern = pt
        }
    end
    return cache[pt]
end

constructors["both"] = function(typ, pt, aux)
     -- dprint("CONS: ", typ, pt, aux)
    local cache = ptcache[typ][aux]
    if not cache then
        ptcache[typ][aux] = weakval{}
        cache = ptcache[typ][aux]
    end
    if not cache[pt] then
        cache[pt] = newpattern{
            ptype = typ,
            pattern = pt,
            aux = aux,
            cache = cache -- needed to keep the cache as long as the pattern exists.
        }
    end
    return cache[pt]
end

end -- module wrapper

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['datastructures'] = function (...)
local getmetatable, pairs, pcall, print, setmetatable, type
    = getmetatable, pairs, pcall, print, setmetatable, type

local m, t = require"math", require"table"
local m_min, m_max, t_concat, t_insert, t_sort
    = m.min, m.max, t.concat, t.insert, t.sort
local _, m_MAX = pcall(m_max)

local u = require"util"
local   all,   expose,   extend,   load,   map,   map_all, u_max, t_unpack
    = u.all, u.expose, u.extend, u.load, u.map, u.map_all, u.max, u.unpack

local compat = require"compat"

local ffi if compat.luajit then
    ffi = require"ffi"
end

--[[DBG]] local debug = debug

local _ENV = u.noglobals() ----------------------------------------------------



local structfor = {}

--------------------------------------------------------------------------------
--- Byte sets
--

-- Byte sets are sets whose elements are comprised between 0 and 255.
-- We provide two implemetations. One based on Lua tables, and the
-- other based on a FFI bool array.

local byteset_new, isboolset, isbyteset

local byteset_mt = {}

local
function byteset_constructor (upper)
    local set = setmetatable(load(t_concat{ 
        "return{ [0]=false", 
        (", false"):rep(upper), 
        " }"
    })(),
    byteset_mt) 
    if upper < 0 then set[0] = nil end
    return set
end

if compat.jit then
    local struct, empty, boolset_constructor = {v={}}, {}

    function byteset_mt.__index(s,i)
        -- [[DBG]] print("GI", s,i)
        -- [[DBG]] print(debug.traceback())
        -- [[DBG]] if i == "v" then error("FOOO") end
        if i == nil or i > s.upper then return nil end
        return s.v[i]
    end
    function byteset_mt.__len(s)
        return s.upper
    end
    function byteset_mt.__newindex(s,i,v)
        -- [[DBG]] print("NI", i, v)
        s.v[i] = v
    end

    boolset_constructor = ffi.metatype('struct { int upper; bool v[?]; }', byteset_mt)

-- [=[
    function byteset_new (t)
        -- [[DBG]] print ("Konstructor", t)
        if type(t) == "number" then
            local tmp
            tmp, struct.v = struct.v, empty
            struct.upper = t
            local res = boolset_constructor(t+1,struct)
            struct.v = tmp
            return res
        end
        local upper = u_max(t)

        struct.upper = upper
        if upper > 255 then error"bool_set overflow" end
        local set = struct.v

        for i = 0, upper do set[i] = false end
        for i = upper + 1, 255 do set[i] = nil end
        for i = 1, #t do set[t[i]] = true end

        return boolset_constructor(upper+1, struct)
    end
--[==[]=]
    function byteset_new (t)
        -- [[DBG]] print "Konstructor"
        if type(t) == "number" then return boolset_constructor(t+1,{n=t}) end
        local upper, set

        upper = u_max(t); if upper > 255 then error"bool_set overflow" end        
        set = byteset_constructor(255)

        for _, el in pairs(t) do
            if el > 255 then error"value out of bounds" end
            set[el] = true
        end

        set[0] = set[0] or false
        struct.v = set
        return boolset_constructor(upper+1, struct)
    end
]==]
    function isboolset(s) return type(s)=="cdata" and ffi.istype(s, boolset_constructor) end
    isbyteset = isboolset
else
    function byteset_new (t)
        -- [[DBG]] print("Set", t)
        if type(t) == "number" then return byteset_constructor(t) end
        local set = byteset_constructor(u_max(t))
        for i = 1, #t do set[t[i]] = true end
        return set
    end

    function isboolset(s) return false end
    function isbyteset (s)
        return getmetatable(s) == byteset_mt 
    end
end

local
function byterange_new (low, high)
    -- [[DBG]] print("Range", low,high)
    high = ( low <= high ) and high or -1
    local set = byteset_new(high)
    for i = low, high do
        set[i] = true
    end
    return set
end

local
function byteset_union (a ,b)
    -- [[DBG]] print("\nUNION\n", #a, #b, m_max(#a,#b))
    local upper = m_max(#a, #b)
    local res = byteset_new(upper)
    for i = 0, upper do 
        res[i] = a[i] or b[i] or false
        -- [[DBG]] print(i, res[i])
    end
    -- [[DBG]] print("BS Un ==========================")
    -- [[DBG]] print"/// A ///////////////////////  " 
    -- [[DBG]] expose(a)
    -- [[DBG]] print"*** B ***********************  " 
    -- [[DBG]] expose(b)
    -- [[DBG]] print"   RES   " 
    -- [[DBG]] expose(res)
    return res
end

local
function byteset_difference (a, b)
    local res = {}
    for i = 0, 255 do
        res[i] = a[i] and not b[i]
    end
    return res
end

local
function byteset_tostring (s)
    local list = {}
    for i = 0, 255 do
        -- [[DBG]] print(s[i] == true and i)
        list[#list+1] = (s[i] == true) and i or nil
    end
    -- [[DBG]] print("BS TOS", t_concat(list,", "))
    return t_concat(list,", ")
end

local function byteset_has(set, elem)
    if elem > 255 then return false end
    return set[elem]
end



structfor.binary = {
    set ={
        new = byteset_new,
        union = byteset_union,
        difference = byteset_difference,
        tostring = byteset_tostring
    },
    Range = byterange_new,
    isboolset = isboolset,
    isbyteset = isbyteset,
    isset = isbyteset
}

--------------------------------------------------------------------------------
--- Bit sets: TODO? to try, at least.
--

-- From Mike Pall's suggestion found at 
-- http://lua-users.org/lists/lua-l/2011-08/msg00382.html

-- local bit = require("bit")
-- local band, bor = bit.band, bit.bor
-- local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

-- local function bitnew(n)
--   return ffi.new("int32_t[?]", rshift(n+31, 5))
-- end

-- -- Note: the index 'i' is zero-based!
-- local function bittest(b, i)
--   return band(rshift(b[rshift(i, 5)], i), 1) ~= 0
-- end

-- local function bitset(b, i)
--   local x = rshift(i, 5); b[x] = bor(b[x], lshift(1, i))
-- end

-- local function bitclear(b, i)
--   local x = rshift(i, 5); b[x] = band(b[x], rol(-2, i))
-- end



-------------------------------------------------------------------------------
--- General case:
--

-- Set
--

local set_mt = {}

local
function set_new (t)
    -- optimization for byte sets.
    -- [[BS]] if all(map_all(t, function(e)return type(e) == "number" end))
    -- and u_max(t) <= 255 
    -- or #t == 0 
    -- then
    --     return byteset_new(t)
    -- end
    local set = setmetatable({}, set_mt)
    for i = 1, #t do set[t[i]] = true end
    return set
end

local -- helper for the union code.
function add_elements(a, res)
    -- [[BS]] if isbyteset(a) then
    --     for i = 0, 255 do
    --         if a[i] then res[i] = true end
    --     end
    -- else 
    for k in pairs(a) do res[k] = true end
    return res
end

local
function set_union (a, b)
    -- [[BS]] if isbyteset(a) and isbyteset(b) then 
    --     return byteset_union(a,b)
    -- end
    a, b = (type(a) == "number") and set_new{a} or a
         , (type(b) == "number") and set_new{b} or b
    local res = set_new{}
    add_elements(a, res)
    add_elements(b, res)
    return res
end

local
function set_difference(a, b)
    local list = {}
    -- [[BS]] if isbyteset(a) and isbyteset(b) then 
    --     return byteset_difference(a,b)
    -- end
    a, b = (type(a) == "number") and set_new{a} or a
         , (type(b) == "number") and set_new{b} or b

    -- [[BS]] if isbyteset(a) then
    --     for i = 0, 255 do
    --         if a[i] and not b[i] then
    --             list[#list+1] = i
    --         end
    --     end
    -- elseif isbyteset(b) then
    --     for el in pairs(a) do
    --         if not byteset_has(b, el) then
    --             list[#list + 1] = i
    --         end
    --     end
    -- else
    for el in pairs(a) do
        if a[i] and not b[i] then
            list[#list+1] = i
        end            
    end
    -- [[BS]] end 
    return set_new(list)
end

local
function set_tostring (s)
    -- [[BS]] if isbyteset(s) then return byteset_tostring(s) end
    local list = {}
    for el in pairs(s) do
        t_insert(list,el)
    end
    t_sort(list)
    return t_concat(list, ",")
end

local
function isset (s)
    return (getmetatable(s) == set_mt) 
        -- [[BS]] or isbyteset(s)
end


-- Range
--

-- For now emulated using sets.

local range_mt = {}
    
local 
function range_new (start, finish)
    local list = {}
    for i = start, finish do
        list[#list + 1] = i
    end
    return set_new(list)
end

-- local 
-- function range_overlap (r1, r2)
--     return r1[1] <= r2[2] and r2[1] <= r1[2]
-- end

-- local
-- function range_merge (r1, r2)
--     if not range_overlap(r1, r2) then return nil end
--     local v1, v2 =
--         r1[1] < r2[1] and r1[1] or r2[1],
--         r1[2] > r2[2] and r1[2] or r2[2]
--     return newrange(v1,v2)
-- end

-- local
-- function range_isrange (r)
--     return getmetatable(r) == range_mt
-- end

structfor.other = {
    set = {
        new = set_new,
        union = set_union,
        tostring = set_tostring,
        difference = set_difference,
    },
    Range = range_new,
    isboolset = isboolset,
    isbyteset = isbyteset,
    isset = isset,
    isrange = function(a) return false end
}



return function(Builder, PL)
    local cs = (Builder.options or {}).charset or "binary"
    if type(cs) == "string" then
        cs = (cs == "binary") and "binary" or "other"
    else
        cs = cs.binary and "binary" or "other"
    end
    return extend(Builder, structfor[cs])
end


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['API'] = function (...)
---------------------------------------  ,--, ,--. -,-  ----------------------
---------------------------------------  |  | |__'  |   ----------------------
-- API --------------------------------  |- | |     |   ----------------------
---------------------------------------  '  ' '    -'-  ----------------------

-- What follows is the core LPeg functions, the public API to create patterns.
-- Think P(), R(), pt1 + pt2, etc.

local assert, error, ipairs, pairs, pcall, print
    , require, select, tonumber, tostring, type
    = assert, error, ipairs, pairs, pcall, print
    , require, select, tonumber, tostring, type

local s, t, u = require"string", require"table", require"util"


local _ENV = u.noglobals() ---------------------------------------------------


local s_byte, t_concat, t_insert, t_sort
    = s.byte, t.concat, t.insert, t.sort

local   copy,   expose,   fold,   load,   map,   setify, t_pack, t_unpack 
    = u.copy, u.expose, u.fold, u.load, u.map, u.setify, u.pack, u.unpack

local 
function charset_error(index, charset)
    error("Character at position ".. index + 1 
            .." is not a valid "..charset.." one.",
        2)
end


------------------------------------------------------------------------------
return function(Builder, PL) -- module wrapper -------------------------------
------------------------------------------------------------------------------


local binary_split_int, cs = Builder.binary_split_int, Builder.charset

local constructors, PL_ispattern
    = Builder.constructors, PL.ispattern

local truept, falsept, Cppt 
    = constructors.constant.truept
    , constructors.constant.falsept
    , constructors.constant.Cppt 

local    split_int,    tochar,    validate 
    = cs.split_int, cs.tochar, cs.validate

local Range, Set, S_union, S_tostring
    = Builder.Range, Builder.set.new
    , Builder.set.union, Builder.set.tostring

-- factorizers, defined at the end of the file.
local factorize_choice, factorize_lookahead, factorize_sequence, factorize_unm



local
function makechar(c)
    return constructors.aux("char", nil, c)
end

local
function PL_P (v)
    if PL_ispattern(v) then
        return v 
    elseif type(v) == "function" then
        return true and PL.Cmt("", v)
    elseif type(v) == "string" then
        local success, index = validate(v)
        if not success then 
            charset_error(index, charset)
        end
        if v == "" then return PL_P(true) end
        return true and constructors.aux("sequence", nil, map(makechar, split_int(v)))
    elseif type(v) == "table" then
        -- private copy because tables are mutable.
        local g = copy(v)
        if g[1] == nil then error("grammar has no initial rule") end
        if not PL_ispattern(g[1]) then g[1] = PL.V(g[1]) end
        return true and constructors.none("grammar", nil, g) 
    elseif type(v) == "boolean" then
        return v and truept or falsept
    elseif type(v) == "number" then
        if v == 0 then
            return truept
        elseif v > 0 then
            return true and constructors.aux("any", nil, v)
        else
            return true and - constructors.aux("any", nil, -v)
        end
    end
end
PL.P = PL_P

local
function PL_S (set)
    if set == "" then 
        return true and PL_P(false)
    else 
        local success, index = validate(set)
        if not success then 
            charset_error(index, charset)
        end
        return true and constructors.aux("set", nil, Set(split_int(set)), set)
    end
end
PL.S = PL_S

local
function PL_R (...)
    -- [[DBG]]print"PL.R(...) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    -- [[DBG]] print(...)
    if select('#', ...) == 0 then
        return PL_P(false)
    else
        local range = Range(1,0)--Set("")
        for _, r in ipairs{...} do
            local success, index = validate(r)
            if not success then 
                charset_error(index, charset)
            end
            range = S_union ( range, Range(t_unpack(split_int(r))) )
            -- [[DBG]] print("\nR() iter CURRENT", r,  "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")
            -- [[DBG]] print(t_unpack(split_int(r)))
            -- [[DBG]] expose(Range(t_unpack(split_int(r))))
            -- [[DBG]] print("\nR() iter RESULT", r, "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")
            -- [[DBG]] expose(range)
        end
        -- This is awful.
        local representation = t_concat(map(tochar, 
                {load("return "..S_tostring(range))()}))
        -- [[DBG]] print("PL_R() repr",s_byte(representation))
        -- [[DBG]] print("PL_R() tstring", S_tostring(range))
        -- [[DBG]] print("PL_R() eval", load("return "..S_tostring(range))())
        -- [[DBG]] print("PL_R() map tochar")
        -- [[DBG]] expose(map(tochar, {load("return "..S_tostring(range))()}))

        -- [[DB]] print"<<< Final Range <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        local p = constructors.aux("set", nil, range, representation)
        -- [[DB]] PL.pprint(p)
        return true and constructors.aux("set", nil, range, representation)
    end
end
PL.R = PL_R

local
function PL_V (name)
    assert(name ~= nil)
    return constructors.aux("ref", nil,  name)
end
PL.V = PL_V



do 
    local one = setify{"set", "range", "one", "char"}
    local zero = setify{"true", "false", "lookahead", "unm"}
    local forbidden = setify{
        "Carg", "Cb", "C", "Cf",
        "Cg", "Cs", "Ct", "/zero",
        "Ctag", "Cmt", "Cc", "Cp",
        "/string", "/number", "/table", "/function",
        "at least", "at most", "behind"
    }
    local function fixedlen(pt, gram, cycle)
        -- [[DP]] print("Fixed Len",pt.ptype)
        local typ = pt.ptype
        if forbidden[typ] then return false
        elseif one[typ]  then return 1
        elseif zero[typ] then return 0
        elseif typ == "string" then return #pt.as_is
        elseif typ == "any" then return pt.aux
        elseif typ == "choice" then
            return fold(map(pt.aux,fixedlen), function(a,b) return (a == b) and a end )
        elseif typ == "sequence" then
            return fold(map(pt.aux, fixedlen), function(a,b) return a and b and a + b end)
        elseif typ == "grammar" then
            if pt.aux[1].ptype == "ref" then
                return fixedlen(pt.aux[pt.aux[1].aux], pt.aux, {})
            else
                return fixedlen(pt.aux[1], pt.aux, {})
            end
        elseif typ == "ref" then
            if cycle[pt] then return false end
            cycle[pt] = true
            return fixedlen(gram[pt.aux], gram, cycle)
        else
            print(typ,"is not handled by fixedlen()")
        end
    end

    function PL.B (pt)
        pt = PL_P(pt)
        -- [[DP]] print("PL.B")
        -- [[DP]] PL.pprint(pt)
        local len = fixedlen(pt)
        assert(len, "A 'behind' pattern takes a fixed length pattern as argument.")
        if len >= 260 then error("Subpattern too long in 'behind' pattern constructor.") end
        return constructors.both("behind", pt, len)
    end
end

 
-- pt*pt
local
function PL_choice (a,b)
    a,b = PL_P(a), PL_P(b)
    -- [[DP]] print("Choice")
    -- [[DP]] print("A")

    -- [[DP]] PL.pprint(a)
    -- [[DP]] print("B")
    -- [[DP]] PL.pprint(b)
    local ch = factorize_choice(a,b)

    if #ch == 0 then 
        return true
    elseif #ch == 1 then 
        return ch[1]
    else
        return constructors.aux("choice", nil, ch)
    end
end
PL.__add = PL_choice


 -- pt+pt, 
local
function sequence (a,b)
    a,b = PL_P(a), PL_P(b)
    local seq = factorize_sequence(a,b)

    if #seq == 0 then 
        return truept
    elseif #seq == 1 then 
        return seq[1]
    end

    return constructors.aux("sequence", nil, seq)
end
PL.__mul = sequence


local
function PL_lookahead (pt)
    -- Simplifications
    if pt == truept
    or pt == falsept
    or pt.ptype == "unm"
    or pt.ptype == "lookahead" 
    then 
    -- print("Simplifying:", "LOOK")
    -- PL.pprint(pt)
    -- return pt
    end
    -- -- The general case
    -- [[DB]] print("PL_lookahead", constructors.subpt("lookahead", pt))
    return constructors.subpt("lookahead", pt)
end
PL.__len = PL_lookahead
PL.L = PL_lookahead

local
function PL_unm(pt)
    -- Simplifications
    local as_is
    pt, as_is = factorize_unm(pt)
    if as_is 
    then return pt
    else return constructors.subpt("unm", pt) end
end
PL.__unm = PL_unm

local
function PL_sub (a, b)
    a, b = PL_P(a), PL_P(b)
    return PL_unm(b) * a
end
PL.__sub = PL_sub

local
function PL_repeat (pt, n)
    local success
    success, n = pcall(tonumber, n)
    assert(success and type(n) == "number",
        "Invalid type encountered at right side of '^'.")
    return constructors.both(( n < 0 and "at most" or "at least" ), pt, n)
end
PL.__pow = PL_repeat

-------------------------------------------------------------------------------
--- Captures
--
for __, cap in pairs{"C", "Cs", "Ct"} do
    PL[cap] = function(pt, aux)
        pt = PL_P(pt)
        return constructors.subpt(cap, pt)
    end
end


PL["Cb"] = function(aux)
    return constructors.aux("Cb", nil, aux)
end


PL["Carg"] = function(aux)
    assert(type(aux)=="number", "Number expected as parameter to Carg capture.")
    assert( 0 < aux and aux <= 200, "Argument out of bounds in Carg capture.")
    return constructors.aux("Carg", nil, aux)
end


local
function PL_Cp ()
    return Cppt
end
PL.Cp = PL_Cp

local
function PL_Cc (...)
    return true and constructors.none("Cc", nil, t_pack(...))
end
PL.Cc = PL_Cc

for __, cap in pairs{"Cf", "Cmt"} do
    local msg = "Function expected in "..cap.." capture"
    PL[cap] = function(pt, aux)
    assert(type(aux) == "function", msg)
    pt = PL_P(pt)
    return constructors.both(cap, pt, aux)
    end
end


local
function PL_Cg (pt, tag)
    pt = PL_P(pt)
    if tag then 
        return constructors.both("Ctag", pt, tag)
    else
        return constructors.subpt("Cg", pt)
    end
end
PL.Cg = PL_Cg


local valid_slash_type = setify{"string", "number", "table", "function"}
local
function PL_slash (pt, aux)
    if PL_ispattern(aux) then 
        error"The right side of a '/' capture cannot be a pattern."
    elseif not valid_slash_type[type(aux)] then
        error("The right side of a '/' capture must be of type "
            .."string, number, table or function.")
    end
    local name
    if aux == 0 then 
        name = "/zero" 
    else 
        name = "/"..type(aux) 
    end
    return constructors.both(name, pt, aux)
end
PL.__div = PL_slash

local factorizer
    = Builder.factorizer(Builder, PL)

-- These are declared as locals at the top of the wrapper.
factorize_choice,  factorize_lookahead,  factorize_sequence,  factorize_unm =
factorizer.choice, factorizer.lookahead, factorizer.sequence, factorizer.unm

end -- module wrapper --------------------------------------------------------


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['purelpeg'] = function (...)
---------------------------------  ,--.                ,    ,--.            ---
---------------------------------  |__' ,  . ,--. ,--. |    |__' ,--. ,--.  ---
-- PureLPeg.lua -----------------  |    |  | |    |--' |    |    |--' `__|  ---
---------------------------------  '    `--' '    `--' `--- '    `--' .__'  ---

-- a WIP LPeg implementation in pure Lua, by Pierre-Yves Gérardy
-- released under the Romantic WTF Public License (see the end of the file).

-- Captures and locales are not yet implemented, but the rest works quite well.
-- UTF-8 is supported out of the box
--
--     PL.set_charset"UTF-8"
--     s = PL.S"ß∂ƒ©˙"
--     s:match"©" --> 3 (since © is two bytes wide).
-- 
-- More encodings can be easily added (see the charset section), by adding a 
-- few appropriate functions.

-- remove the global tables from the environment
-- they are restored at the end of the file.
-- standard libraries must be require()d.

-- [[DBG]] local debug, print_ = debug, print
-- [[DBG]] print = function(...) print_(debug.traceback(2)) print_(...) end

local tmp_globals, globalenv = {}, _ENV or _G
if not release then
for lib, tbl in pairs(globalenv) do
    if type(tbl) == "table" then
        tmp_globals[lib], globalenv[lib] = globalenv[lib], nil
    end
end
end

local getmetatable, pairs
    = getmetatable, pairs

local u = require"util"
local   map,   nop, t_unpack 
    = u.map, u.nop, u.unpack

-- The module decorators.
local API, charsets, compiler, constructors
    , datastructures, evaluator, factorizer
    , locale, match, printers, re
    = t_unpack(map(require,
    { "API", "charsets", "compiler", "constructors"
    , "datastructures", "evaluator", "factorizer"
    , "locale", "match", "printers", "re" }))

if not release then
    local success, package = pcall(require, "package")
    if type(package) == "table" 
    and type(package.loaded) == "table" 
    and package.loaded.re 
    then 
        package.loaded.re = nil
    end
end


local _ENV = u.noglobals() ----------------------------------------------------



-- The LPeg version we emulate.
local VERSION = "0.12"

-- The PureLPeg version.
local PVERSION = "0.0.0"



local 
function PLPeg(options)
    options = options and copy(options) or {}

    -- PL is the module
    -- Builder keeps the state during the module decoration.
    local Builder, PL 
        = { options = options, factorizer = factorizer }
        , { new = PLPeg
          , version = function () return VERSION end
          , pversion = function () return PVERSION end
          , setmaxstack = nop --Just a stub, for compatibility.
          }

    PL.__index = PL

    local getmetatable = getmetatable
    local
    function PL_ispattern(pt) return getmetatable(pt) == PL end
    PL.ispattern = PL_ispattern

    function PL.type(pt)
        if PL_ispattern(pt) then 
            return "pattern"
        else
            return nil
        end
    end

    -- Decorate the LPeg object.
    charsets(Builder, PL)
    datastructures(Builder, PL)
    printers(Builder, PL)
    constructors(Builder, PL)
    API(Builder, PL)
    evaluator(Builder, PL)
    ;(options.compiler or compiler)(Builder, PL)
    match(Builder, PL)
    locale(Builder, PL)
    PL.re = re(PL)

    return PL
end -- PLPeg

local PL = PLPeg()
-- restore the global libraries
for lib, tbl in pairs(tmp_globals) do
        globalenv[lib] = tmp_globals[lib] 
end


return PL

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['locale'] = function (...)
---------------------------------------  |                  |        ----------
---------------------------------------  |    ,--. ,-- ,--. |  ,--.  ----------
-- Locale -----------------------------  |    |  | |   ,--| |  |--'  ----------
---------------------------------------  +--- `--' `-- `--' `- `--'  ----------


-- We'll limit ourselves to the standard C locale for now.
-- see http://wayback.archive.org/web/20120310215042/http://www.utas.edu.au...
-- .../infosys/info/documentation/C/CStdLib.html#ctype.h

return function(Builder, PL) -- Module wrapper

local extend = require"util".extend
local R, S = PL.R, PL.S

local locale = {}
locale["cntrl"] = R"\0\31" + "\127"
locale["digit"] = R"09"
locale["lower"] = R"az"
locale["print"] = R" ~" -- 0x20 to 0xee
locale["space"] = S" \f\n\r\t\v" -- \f == form feed (for a printer), \v == vtab
locale["upper"] = R"AZ"

locale["alpha"]  = locale["lower"] + locale["upper"]
locale["alnum"]  = locale["alpha"] + locale["digit"]
locale["graph"]  = locale["print"] - locale["space"]
locale["punct"]  = locale["graph"] - locale["alnum"]
locale["xdigit"] = locale["digit"] + R"af" + R"AF"


function PL.locale (t)
    return extend(t or {}, locale)
end

end -- Module wrapper


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['evaluator'] = function (...)
---------------------------------------   ,---            |   ----------------
---------------------------------------   |__  .   , ,--. |   ----------------
-- Capture evaluators -----------------   |     \ /  ,--| |   ----------------
---------------------------------------   `---   v   `--' `-  ----------------

return function(Builder, PL) -- Decorator wrapper

local cprint = PL.cprint

local pcall, select, setmetatable, tonumber, tostring
    = pcall, select, setmetatable, tonumber, tostring

local s, t, u = require"string", require"table", require"util"

local _ENV = u.noglobals()

local s_sub, t_concat
    = s.sub, t.concat

local expose, strip_mt, t_unpack
    = u.expose, u.strip_mt, u.unpack

local evaluators = {}

local
function evaluate (capture, subject, index)
    -- print("*** Eval", index)
    -- cprint(capture)
    local acc, val_i, _ = {}
    -- PL.cprint(capture)
    _, val_i = evaluators.insert(capture, subject, acc, index, 1)
    return acc, val_i
end
PL.evaluate = evaluate

--- Some accumulator types for the evaluator
--




local function insert (capture, subject, acc, index, val_i)
    -- print("Insert", capture.start, capture.finish)
    for i = 1, capture.n - 1 do
        -- print("Eval Insert: ", capture[i].type, capture[i].start, capture[i])
            local c 
            index, val_i =
                evaluators[capture[i].type](capture[i], subject, acc, index, val_i)
    end
    return index, val_i
end
evaluators["insert"] = insert

local
function lookback(capture, tag, index)
    local found
    repeat
        for i = index - 1, 1, -1 do
            -- print("LB for",capture[i].type)
            if  capture[i].Ctag == tag then
                -- print"Found"
                found = capture[i]
                break
            end
        end
        capture, index = capture.parent, capture.parent_i
    until found or not capture

    if found then 
        return found
    else 
        tag = type(tag) == "string" and "'"..tag.."'" or tostring(tag)
        error("back reference "..tag.." not found")
    end
end

evaluators["Cb"] = function (capture, subject, acc, index, val_i)
    local ref, Ctag, _ = lookback(capture.parent, capture.tag, capture.parent_i)
    ref.Ctag, Ctag = nil, ref.Ctag
    _, val_i = evaluators.Cg(ref, subject, acc, ref.start, val_i)
    ref.Ctag = Ctag
    return index, val_i
end


evaluators["Cf"] = function (capture, subject, acc, index, val_i)
    if capture.n == 0 then
        error"No First Value"
    end

    local func, fold_acc, first_val_i, _ = capture.aux, {}
    index, first_val_i = evaluators[capture[1].type](capture[1], subject, fold_acc, index, 1)

    if first_val_i == 1 then 
        error"No first value"
    end
    
    local result = fold_acc[1]

    for i = 2, capture.n - 1 do
        local fold_acc2, vi = {}
        index, vi = evaluators[capture[i].type](capture[i], subject, fold_acc2, index, 1)
        result = func(result, t_unpack(fold_acc2, 1, vi - 1))
    end
    acc[val_i] = result
    return capture.finish, val_i + 1
end


evaluators["Cg"] = function (capture, subject, acc, index, val_i)
    local start, finish = capture.start, capture.finish
    local group_acc = {}

    if capture.Ctag ~= nil  then
        return start, val_i
    end

    local index, group_val_i = insert(capture, subject, group_acc, start, 1)
    if group_val_i == 1 then
        acc[val_i] = s_sub(subject, start, finish - 1)
        return finish, val_i + 1
    else
        for i = 1, group_val_i - 1 do
            val_i, acc[val_i] = val_i + 1, group_acc[i]
        end
        return capture.finish, val_i
    end
end


evaluators["C"] = function (capture, subject, acc, index, val_i)
    val_i, acc[val_i] = val_i + 1, s_sub(subject,capture.start, capture.finish - 1)
    local _
    _, val_i = insert(capture, subject, acc, capture.start, val_i)
    return capture.finish, val_i
end


evaluators["Cs"] = function (capture, subject, acc, index, val_i)
    local start, finish, n = capture.start, capture.finish, capture.n
    if n == 1 then
        acc[val_i] = s_sub(subject, start, finish - 1)
    else
        local subst_acc, cap_i, subst_i = {}, 1, 1
        repeat
            local cap, tmp_acc, tmp_i, _ = capture[cap_i], {}

            subst_acc[subst_i] = s_sub(subject, start, cap.start - 1)
            subst_i = subst_i + 1

            start, tmp_i = evaluators[cap.type](cap, subject, tmp_acc, index, 1)

            if tmp_i > 1 then
                subst_acc[subst_i] = tmp_acc[1]
                subst_i = subst_i + 1
            end

            cap_i = cap_i + 1
        until cap_i == n
        subst_acc[subst_i] = s_sub(subject, start, finish - 1)

        acc[val_i] = t_concat(subst_acc)
    end

    return capture.finish, val_i + 1
end


evaluators["Ct"] = function (capture, subject, acc, index, val_i)
    local tbl_acc, new_val_i, _ = {}, 1

    for i = 1, capture.n - 1 do
        local cap = capture[i]

        if cap.Ctag ~= nil then
            local tmp_acc = {}

            insert(cap, subject, tmp_acc, cap.start, 1)
            local val = (#tmp_acc == 0 and s_sub(subject, cap.start, cap.finish - 1) or tmp_acc[1])
            tbl_acc[cap.Ctag] = val
        else
            _, new_val_i = evaluators[cap.type](cap, subject, tbl_acc, cap.start, new_val_i)
        end
    end
    acc[val_i] = tbl_acc
    return capture.finish, val_i + 1
end


evaluators["value"] = function (capture, subject, acc, index, val_i)
    acc[val_i] = capture.value
    return capture.finish, val_i + 1
end


evaluators["values"] = function (capture, subject, acc, index, val_i)
local start, finish, values = capture.start, capture.finish, capture.values
    for i = 1, values.n do
        val_i, acc[val_i] = val_i + 1, values[i]
    end
    return finish, val_i
end


evaluators["/string"] = function (capture, subject, acc, index, val_i)
    -- print("/string", capture.start, capture.finish)
    local n, cached = capture.n, {}
    acc[val_i] = capture.aux:gsub("%%([%d%%])", function (d)
        if d == "%" then return "%" end
        d = tonumber(d)
        if not cached[d] then
            if d >= n then
                error("no capture at index "..d.." in /string capture.")
            end
            if d == 0 then
                cached[d] = s_sub(subject, capture.start, capture.finish - 1)
            else
                local tmp_acc, _, vi = {}
                _, vi = evaluators[capture[d].type](capture[d], subject, tmp_acc, capture.start, 1)
                if vi == 1 then error("no values in capture at index"..d.."in /string capture.") end
                cached[d] = tmp_acc[1]
            end
        end
        return cached[d]
    end)
    return capture.finish, val_i + 1
end


evaluators["/number"] = function (capture, subject, acc, index, val_i)
    local new_acc, _, vi = {}
    _, vi = insert(capture, subject, new_acc, capture.start, 1)
    if capture.aux >= vi then error("no capture '"..capture.aux.."' in /number capture.") end
    acc[val_i] = new_acc[capture.aux]
    return capture.finish, val_i + 1
end


evaluators["/table"] = function (capture, subject, acc, index, val_i)
    local key
    if capture.n > 1 then
        local new_acc = {}
        insert(capture, subject, new_acc, capture.start, 1)
        key = new_acc[1]
    else
        key = s_sub(subject, capture.start, capture.finish - 1)
    end

    if capture.aux[key] then
        acc[val_i] = capture.aux[key]
        return capture.finish, val_i + 1
    else
        return capture.start, val_i
    end
end


local
function insert_divfunc_results(acc, val_i, ...)
    local n = select('#', ...)
    for i = 1, n do
        val_i, acc[val_i] = val_i + 1, select(i, ...)
    end
    return val_i
end
evaluators["/function"] = function (capture, subject, acc, index, val_i)
    local func, params, new_val_i, _ = capture.aux
    if capture.n > 1 then
        params = {}
        _, new_val_i = insert(capture, subject, params, capture.start, 1)
    else
        new_val_i = 2
        params = {s_sub(subject, capture.start, capture.finish - 1)}
    end
    val_i = insert_divfunc_results(acc, val_i, func(t_unpack(params, 1, new_val_i - 1)))
    return capture.finish, val_i
end

end  -- Decorator wrapper


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['init'] = function (...)
return require"purelpeg"
end
end
--=============================================================================
do local _ENV = _ENV
packages['compiler'] = function (...)
local pairs, print, error, tostring, type
    = pairs, print, error, tostring, type

local s, t, u = require"string", require"table", require"util"

local _ENV = u.noglobals()

local s_byte, s_sub, t_concat, t_insert, t_remove, t_unpack
    = s.byte, s.sub, t.concat, t.insert, t.remove, u.unpack

local   expose,   load,   map,   map_all, t_pack
    = u.expose, u.load, u.map, u.map_all, u.pack



return function(Builder, PL)
local evaluate, PL_ispattern =  PL.evaluate, PL.ispattern
local get_int, charset = Builder.charset.get_int, Builder.charset



local compilers = {}


local
function compile(pt, ccache)
    -- print("Compile", pt.ptype)
    if not PL_ispattern(pt) then 
        --[[DBG]]expose(pt)
        error("pattern expected") 
    end
    local typ = pt.ptype
    if typ == "grammar" then
        ccache = {}
    elseif typ == "ref" or typ == "choice" or typ == "sequence" then
        if not ccache[pt] then
            ccache[pt] = compilers[typ](pt, ccache)
        end
        return ccache[pt]
    end
    if not pt.compiled then
         -- dprint("Not compiled:")
        -- PL.pprint(pt)
        pt.compiled = compilers[pt.ptype](pt, ccache)
    end

    return pt.compiled
end
PL.compile = compile

------------------------------------------------------------------------------
----------------------------------  ,--. ,--. ,--. |_  ,  , ,--. ,--. ,--.  --
--- Captures                        |    .--| |__' |   |  | |    |--' '--,
--                                  `--' `--' |    `-- `--' '    `--' `--'


-- These are all alike:


for k, v in pairs{
    ["C"] = "C", 
    ["Cf"] = "Cf", 
    ["Cg"] = "Cg", 
    ["Cs"] = "Cs",
    ["Ct"] = "Ct",
    ["/string"] = "/string",
    ["/table"] = "/table",
    ["/number"] = "/number",
    ["/function"] = "/function",
} do 
    compilers[k] = load(([[
    local compile = ...
    return function (pt, ccache)
        local matcher, aux = compile(pt.pattern, ccache), pt.aux
        return function (subject, index, cap_acc, cap_i, state)
             -- dprint("XXXX    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            local new_acc, nindex, success = {
                type = "XXXX",
                start = index,
                aux = aux,
                parent = cap_acc,
                parent_i = cap_i
            }
            success, index, new_acc.n
                = matcher(subject, index, new_acc, 1, state)
            if success then 
                -- dprint("\n\nXXXX captured: start:"..new_acc.start.." finish: "..index.."\n")
                new_acc.finish = index
                cap_acc[cap_i] = new_acc
                cap_i = cap_i + 1
            end
            return success, index, cap_i
        end
    end]]):gsub("XXXX", v), k.." compiler")(compile)
end


compilers["Carg"] = function (pt, ccache)
    local n = pt.aux
    return function (subject, index, cap_acc, cap_i, state)
        if state.args.n < n then error("reference to absent argument #"..n) end
        cap_acc[cap_i] = {
            type = "value",
            value = state.args[n],
            start = index,
            finish = index
        }
        return true, index, cap_i + 1
    end
end


compilers["Cb"] = function (pt, ccache)
    local tag = pt.aux
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Cb       ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
         -- dprint("TAG: " .. ((state.tags[tag] or {}).type or "NONE"))
        cap_acc[cap_i] = {
            type = "Cb",
            start = index,
            finish = index,
            parent = cap_acc,
            parent_i = cap_i,
            tag = tag
        }
        return true, index, cap_i + 1
    end
end


compilers["Cc"] = function (pt, ccache)
    local values = pt.aux
    return function (subject, index, cap_acc, cap_i, state)
        cap_acc[cap_i] = {
            type = "values", 
            values = values,
            start = index,
            finish = index,
            n = values.n
        } 
        return true, index, cap_i + 1
    end
end


compilers["Cp"] = function (pt, ccache)
    return function (subject, index, cap_acc, cap_i, state)
        cap_acc[cap_i] = {
            type = "value",
            value = index,
            start = index,
            finish = index
        }
        return true, index, cap_i + 1
    end
end


compilers["Ctag"] = function (pt, ccache)
    local matcher, tag = compile(pt.pattern, ccache), pt.aux
    return function (subject, index, cap_acc, cap_i, state)
        local new_acc, success = {
            type = "Cg", 
            start = index,
            Ctag = tag,
            parent = cap_acc,
            parent_i = cap_i
        }
        success, new_acc.finish, new_acc.n 
            = matcher(subject, index, new_acc, 1, state)
        if success then
            cap_acc[cap_i] = new_acc
        end
        return success, new_acc.finish, cap_i + 1
    end
end


compilers["/zero"] = function (pt, ccache)
    local matcher = compile(pt.pattern, ccache)
    return function (subject, index, cap_acc, cap_i, state)
        local success, nindex = matcher(subject, index, {type = "discard"}, 1, state)
        return success, nindex, cap_i
    end
end


local function pack_Cmt_caps(i,...) return i, t_pack(...) end

compilers["Cmt"] = function (pt, ccache)
    local matcher, func = compile(pt.pattern, ccache), pt.aux
    return function (subject, index, cap_acc, cap_i, state)
        local new_acc, success, nindex = {
            type = "insert", 
            parent = cap_acc, 
            parent_i = cap_i
        }
        success, nindex, new_acc.n = matcher(subject, index, new_acc, 1, state)

        if not success then return false, index, cap_i end
        -- print("# @ # %%% - Cmt EVAL", index, #new_acc ~= 0)
        local captures = #new_acc == 0 and {s_sub(subject, index, nindex - 1)}
                                       or  evaluate(new_acc, subject, nindex)
        local nnindex, values = pack_Cmt_caps(func(subject, nindex, t_unpack(captures)))

        if not nnindex then return false, index, cap_i end

        if nnindex == true then nnindex = nindex end

        if type(nnindex) == "number" 
        and index <= nnindex and nnindex <= #subject + 1
        then
            if #values > 0 then
                cap_acc[cap_i] = {
                    type = "values",
                    values = values, 
                    start = index,
                    finish = nnindex,
                    n = values.n
                }
                cap_i = cap_i + 1
            end
        elseif type(nnindex) == "number" then
            error"Index out of bounds returned by match-time capture."
        else
            error("Match time capture must return a number, a boolean or nil"
                .." as first argument, or nothing at all.")
        end
        return true, nnindex, cap_i
    end
end


------------------------------------------------------------------------------
------------------------------------  ,-.  ,--. ,-.     ,--. ,--. ,--. ,--. --
--- Other Patterns                    |  | |  | |  | -- |    ,--| |__' `--.
--                                    '  ' `--' '  '    `--' `--' |    `--'


compilers["string"] = function (pt, ccache)
    local S = pt.aux
    local N = #S
    return function(subject, index, cap_acc, cap_i, state)
         -- dprint("String    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        local in_1 = index - 1
        for i = 1, N do
            local c
            c = s_byte(subject,in_1 + i)
            if c ~= S[i] then
         -- dprint("%FString    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                return false, index, cap_i
            end
        end
         -- dprint("%SString    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        return true, index + N, cap_i
    end
end

compilers["char"]= function (pt, ccache)
    local c0 = pt.aux
    return function(subject, index, cap_acc, cap_i, state)
         -- dprint("Char    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        local c, nindex = get_int(subject, index)
        if c ~= c0 then
            return false, index, cap_i
        end
        return true, nindex, cap_i
    end
end


local 
function truecompiled (subject, index, cap_acc, cap_i, state)
     -- dprint("True    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
    return true, index, cap_i
end
compilers["true"] = function (pt)
    return truecompiled
end


local
function falsecompiled (subject, index, cap_acc, cap_i, state)
     -- dprint("False   ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
    return false, index, cap_i
end
compilers["false"] = function (pt)
    return falsecompiled
end


local
function eoscompiled (subject, index, cap_acc, cap_i, state)
     -- dprint("EOS     ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
    return index > #subject, index, cap_i
end
compilers["eos"] = function (pt)
    return eoscompiled
end


local
function onecompiled (subject, index, cap_acc, cap_i, state)
     -- dprint("One     ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
    local char, nindex = get_int(subject, index)
    if char 
    then return true, nindex, cap_i
    else return flase, index, cap_i end
end
compilers["one"] = function (pt)
    return onecompiled
end


compilers["any"] = function (pt)
    if not charset.binary then
        local N = pt.aux         
        return function(subject, index, cap_acc, cap_i, state)
             -- dprint("Any UTF-8",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            local n, c, nindex = N
            while n > 0 do
                c, nindex = get_int(subject, index)
                if not c then
                     -- dprint("%FAny    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                    return false, index, cap_i
                end
                n = n -1
            end
             -- dprint("%SAny    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            return true, nindex, cap_i
        end
    else -- version optimized for byte-width encodings.
        local N = pt.aux - 1
        return function(subject, index, cap_acc, cap_i, state)
             -- dprint("Any byte",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            local n = index + N
            if n <= #subject then 
                -- dprint("%SAny    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                return true, n + 1, cap_i
            else
                 -- dprint("%FAny    ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                return false, index, cap_i
            end
        end
    end
end


do
    local function checkpatterns(g)
        for k,v in pairs(g.aux) do
            if not PL_ispattern(v) then
                error(("rule 'A' is not a pattern"):gsub("A", tostring(k)))
            end
        end
    end

    compilers["grammar"] = function (pt, ccache)
        checkpatterns(pt)
        local gram = map_all(pt.aux, compile, ccache)
        local start = gram[1]
        return function (subject, index, cap_acc, cap_i, state)
             -- dprint("Grammar ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            t_insert(state.grammars, gram)
            local success, nindex, cap_i = start(subject, index, cap_acc, cap_i, state)
            t_remove(state.grammars)
             -- dprint("%Grammar ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            return success, nindex, cap_i
        end
    end
end

compilers["behind"] = function (pt, ccache)
    local matcher, N = compile(pt.pattern, ccache), pt.aux
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Behind  ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        if index <= N then return false, index, cap_i end

        local success = matcher(subject, index - N, {type = "discard"}, cap_i, state)
        return success, index, cap_i
    end
end

compilers["range"] = function (pt)
    local ranges = pt.aux
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Range   ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        local char, nindex = get_int(subject, index)
        for i = 1, #ranges do
            local r = ranges[i]
            if char and r[char]
            then return true, nindex, cap_i end
        end
        return false, index, cap_i
    end
end

compilers["set"] = function (pt)
    local s = pt.aux
    return function (subject, index, cap_acc, cap_i, state)
             -- dprint("Set, Set!",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        local char, nindex = get_int(subject, index, cap_acc, cap_i, state)
        if s[char] 
        then return true, nindex, cap_i
        else return false, index, cap_i end
    end
end

-- hack, for now.
compilers["range"] = compilers.set

compilers["ref"] = function (pt, ccache)
    local name = pt.aux
    local ref
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Reference",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        if not ref then 
            if #state.grammars == 0 then
                error(("rule 'XXXX' used outside a grammar"):gsub("XXXX", tostring(name)))
            elseif not state.grammars[#state.grammars][name] then
                error(("rule 'XXXX' undefined in given grammar"):gsub("XXXX", tostring(name)))
            end                
            ref = state.grammars[#state.grammars][name]
        end
        -- print("Ref",cap_acc, index) --, subject)
        return ref(subject, index, cap_acc, cap_i, state)
    end
end



-- Unroll the loop using a template:
local choice_tpl = [[
            success, index, cap_i = XXXX(subject, index, cap_acc, cap_i, state)
            if success then
                 -- dprint("%SChoice   ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                return true, index, cap_i
            end]]
compilers["choice"] = function (pt, ccache)
    local choices, n = map(pt.aux, compile, ccache), #pt.aux
    local names, chunks = {}, {}
    for i = 1, n do
        local m = "ch"..i
        names[#names + 1] = m
        chunks[ #names  ] = choice_tpl:gsub("XXXX", m)
    end
    local compiled = t_concat{
        "local ", t_concat(names, ", "), [[ = ...
        return function (subject, index, cap_acc, cap_i, state)
             -- dprint("Choice   ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            local success
            ]],
            t_concat(chunks,"\n"),[[
             -- dprint("%FChoice   ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            return false, index, cap_i
        end]]
    }
    -- print(compiled)
    return load(compiled, "Choice")(t_unpack(choices))
end



local sequence_tpl = [[
             -- dprint("XXXX", nindex, cap_acc, new_i, state)
            success, nindex, new_i = XXXX(subject, nindex, cap_acc, new_i, state)
            if not success then
                 -- dprint("%FSequence",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
                return false, index, cap_i
            end]]
compilers["sequence"] = function (pt, ccache)
    local sequence, n = map(pt.aux, compile, ccache), #pt.aux
    local names, chunks = {}, {}
    -- print(n)
    -- for k,v in pairs(pt.aux) do print(k,v) end
    for i = 1, n do
        local m = "seq"..i
        names[#names + 1] = m
        chunks[ #names  ] = sequence_tpl:gsub("XXXX", m)
    end
    local compiled = t_concat{
        "local ", t_concat(names, ", "), [[ = ...
        return function (subject, index, cap_acc, cap_i, state)
             -- dprint("Sequence",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
            local nindex, new_i, success = index, cap_i
            ]],
            t_concat(chunks,"\n"),[[
             -- dprint("%SSequence",cap_acc, cap_acc and cap_acc.type or "'nil'", new_i, index, state) --, subject)
             -- dprint("NEW I:",new_i)
            return true, nindex, new_i
        end]]
    }
    -- print(compiled)
   return load(compiled, "Sequence")(t_unpack(sequence))
end


compilers["at most"] = function (pt, ccache)
    local matcher, n = compile(pt.pattern, ccache), pt.aux
    n = -n
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("At most   ",cap_acc, cap_acc and cap_acc.type or "'nil'", index) --, subject)
        local success = true
        for i = 1, n do
            success, index, cap_i = matcher(subject, index, cap_acc, cap_i, state)
        end
        return true, index, cap_i             
    end
end

compilers["at least"] = function (pt, ccache)
    local matcher, n = compile(pt.pattern, ccache), pt.aux
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("At least  ",cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state) --, subject)
        local success = true
        for i = 1, n do
            success, index, cap_i = matcher(subject, index, cap_acc, cap_i, state)
            if not success then return false, index, cap_i end
        end
        local N = 1
        while success do
             -- dprint("    rep "..N,cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state)
            N=N+1
            success, index, cap_i = matcher(subject, index, cap_acc, cap_i, state)
        end
        return true, index, cap_i
    end
end

compilers["unm"] = function (pt, ccache)
    local matcher = compile(pt.pattern, ccache)
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Unm     ", cap_acc, cap_acc and cap_acc.type or "'nil'", cap_i, index, state)
        -- Throw captures away
        local success, _, _ = matcher(subject, index, {type = "discard", parent = cap_acc, parent_i = cap_i}, 1, state)
        return not success, index, cap_i
    end
end

compilers["lookahead"] = function (pt, ccache)
    local matcher = compile(pt.pattern, ccache)
    return function (subject, index, cap_acc, cap_i, state)
         -- dprint("Lookahead", cap_acc, cap_acc and cap_acc.type or "'nil'", index, cap_i, state)
        -- Throw captures away
        local success, _, _ = matcher(subject, index, {type = "discard", parent = cap_acc, parent_i = cap_i}, 1, state)
         -- dprint("%Lookahead", cap_acc, cap_acc and cap_acc.type or "'nil'", index, cap_i, state)
        return success, index, cap_i
    end
end

end

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['charsets'] = function (...)
---------------------------------------   .--. .                        '     -
---------------------------------------  /     |__  .--. .--. .--. .--. |--   -
-- Charset handling -------------------  \     |  | .--| |    '--. |--' |     -
---------------------------------------   '--' '  ' '--' '    '--' '--' '--'  -

-- We provide: 
-- * utf8_validate(subject, start, finish) -- validator
-- * utf8_split_int(subject)               --> table{int}
-- * utf8_split_char(subject)              --> table{char}
-- * utf8_next_int(subject, index)         -- iterator
-- * utf8_next_char(subject, index)        -- iterator
-- * utf8_get_int(subject, index)         -- Julia-style iterator
-- * utf8_get_char(subject, index)        -- Julia-style iterator
--
-- See each function for usage.


local s, t, u = require"string", require"table", require"util"


local _ENV = u.noglobals()


local copy = u.copy

local s_char, s_sub, s_byte, t_insert
    = s.char, s.sub, s.byte, t.insert

-------------------------------------------------------------------------------
--- UTF-8
--

-- Utility function.
-- Modified from code by Kein Hong Man <khman@users.sf.net>,
-- found at http://lua-users.org/wiki/SciteUsingUnicode.

local
function utf8_offset (byte)
    if byte < 128 then return 0, byte
    elseif byte < 192 then
        error("Byte values between 0x80 to 0xBF cannot start a multibyte sequence")
    elseif byte < 224 then return 1, byte - 192
    elseif byte < 240 then return 2, byte - 224
    elseif byte < 248 then return 3, byte - 240
    elseif byte < 252 then return 4, byte - 248
    elseif byte < 254 then return 5, byte - 252
    else
        error("Byte values between 0xFE and OxFF cannot start a multibyte sequence")
    end
end


-- validate a given (sub)string.
-- returns two values: 
-- * The first is either true, false or nil, respectively on success, error, or 
--   incomplete subject.
-- * The second is the index of the last byte of the last valid char.
local
function utf8_validate (subject, start, finish)
    start = start or 1
    finish = finish or #subject

    local offset, char
        = 0
    for i = start,finish do
        local b = s_byte(subject,i)
        if offset == 0 then
            char = i
            success, offset = pcall(utf8_offset, b)
            if not success then return false, char - 1 end
        else
            if not (127 < b and b < 192) then
                return false, char - 1
            end
            offset = offset -1
        end
    end
    if offset ~= 0 then return nil, char - 1 end -- Incomplete input.
    return true, finish
end

-- Usage:
--     for finish, start, cpt in utf8_next_int, "˙†ƒ˙©√" do
--         print(cpt)
--     end
-- `start` and `finish` being the bounds of the character, and `cpt` being the UTF-8 code point.
-- It produces:
--     729
--     8224
--     402
--     729
--     169
--     8730
local 
function utf8_next_int (subject, i)
    i = i and i+1 or 1
    if i > #subject then return end
    local c = s_byte(subject, i)
    local offset, val = utf8_offset(c)
    for i = i+1, i+offset do
        c = s_byte(subject, i)
        val = val * 64 + (c-128)
    end
  return i + offset, i, val
end


-- Usage:
--     for finish, start, cpt in utf8_next_int, "˙†ƒ˙©√" do
--         print(cpt)
--     end
-- `start` and `finish` being the bounds of the character, and `cpt` being the UTF-8 code point.
-- It produces:
--     ˙
--     †
--     ƒ
--     ˙
--     ©
--     √
local
function utf8_next_char (subject, i)
    i = i and i+1 or 1
    if i > #subject then return end
    local offset = utf8_offset(s_byte(subject,i))
    return i + offset, i, s_sub(subject, i, i + offset)
end


-- Takes a string, returns an array of code points.
local
function utf8_split_int (subject)
    local chars = {}
    for _, _, c in utf8_next_int, subject do
        t_insert(chars,c)
    end
    return chars
end

-- Takes a string, returns an array of characters.
local
function utf8_split_char (subject)
    local chars = {}
    for _, _, c in utf8_next_char, subject do
        t_insert(chars,c)
    end
    return chars
end

local 
function utf8_get_int(subject, i)
    if i > #subject then return end
    local c = s_byte(subject, i)
    local offset, val = utf8_offset(c)
    for i = i+1, i+offset do
        c = s_byte(subject, i)
        val = val * 64 + ( c - 128 ) 
    end
    return val, i + offset + 1
end

local
function split_generator (get)
    if not get then return end
    return function(subject)
        local res = {}
        local o, i = true
        while o do
            o,i = get(subject, i)
            res[#res] = o
        end
        return res
    end
end

local
function merge_generator (char)
    if not char then return end
    return function(ary)
        local res = {}
        for i = 1, #ary do
            t_insert(res,char(ary[i]))
        end
        return t_concat(res)
    end
end

local
function build_charset (funcs)
    return {
        name = funcs.name,
        split_int = split_generator(funcs.next_int),
        split_char = split_generator(funcs.next_char),
        next_int = funcs.next_int,
        next_char = funcs.next_char,
        merge = merge_generator(funcs.tochar),
        tochar = funcs.tochar,
        validate = funcs.validate
    }
end

local
function utf8_get_int2 (subject, i)
    local byte, b5, b4, b3, b2, b1 = s_byte(subject, i)
    if byte < 128 then return byte, i + 1
    elseif byte < 192 then
        error("Byte values between 0x80 to 0xBF cannot start a multibyte sequence")
    elseif byte < 224 then 
        return (byte - 192)*64 + s_byte(subject, i+1), i+2
    elseif byte < 240 then 
            b2, b1 = s_byte(subject, i+1, i+2)
        return (byte-224)*4096 + b2%64*64 + b1%64, i+3
    elseif byte < 248 then 
        b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3)
        return (byte-240)*262144 + b3%64*4096 + b2%64*64 + b1%64, i+4
    elseif byte < 252 then 
        b4, b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3, i+4)
        return (byte-248)*16777216 + b4%64*262144 + b3%64*4096 + b2%64*64 + b1%64, i+5
    elseif byte < 254 then 
        b5, b4, b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3, i+4, i+5)
        return (byte-252)*1073741824 + b5%64*16777216 + b4%64*262144 + b3%64*4096 + b2%64*64 + b1%64, i+6
    else
        error("Byte values between 0xFE and OxFF cannot start a multibyte sequence")
    end
end


local
function utf8_get_char(subject, i)
    if i > #subject then return end
    local offset = utf8_offset(s_byte(subject,i))
    return s_sub(subject, i, i + offset), i + offset + 1
end

local
function utf8_char(c)
    if     c < 128 then
        return --[[See the end of the line: --->]]                                           s_char(c)
    elseif c < 2048 then 
        return                                                          s_char(192 + c/64, 128 + c%64)
    elseif c < 65536 then
        return                                         s_char(224 + c/4096, 128 + c/64%64, 128 + c%64) 
    elseif c < 2097152 then 
        return                      s_char(240 + c/262144, 128 + c/4096%64, 128 + c/64%64, 128 + c%64) 
    elseif c < 67108864 then
        return s_char(248 + c/16777216, 128 + c/262144%64, 128 + c/4096%64, 128 + c/64%64, 128 + c%64) 
    elseif c < 2147483648 then 
        return s_char( 252 + c/1073741824, 
                   128 + c/16777216%64, 128 + c/262144%64, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)
    end
    error("Bad Unicode code point: "..c..".")
end

-------------------------------------------------------------------------------
--- ASCII and binary.
--

-- See UTF-8 above for the API docs.

local
function binary_validate (subject, start, finish)
    start = start or 1
    finish = finish or #subject
    return true, finish
end

local 
function binary_next_int (subject, i)
    i = i and i+1 or 1
    if i >= #subject then return end
    return i, i, s_sub(subject, i, i)
end

local
function binary_next_char (subject, i)
    i = i and i+1 or 1
    if i > #subject then return end
    return i, i, s_byte(subject,i)
end

local
function binary_split_int (subject)
    local chars = {}
    for i = 1, #subject do
        t_insert(chars, s_byte(subject,i))
    end
    return chars
end

local
function binary_split_char (subject)
    local chars = {}
    for i = 1, #subject do
        t_insert(chars, s_sub(subject,i,i))
    end
    return chars
end

local
function binary_get_int(subject, i)
    return s_byte(subject, i), i + 1
end

local
function binary_get_char(subject, i)
    return s_sub(subject, i, i), i + 1
end


-------------------------------------------------------------------------------
--- The table
--

local charsets = {
    binary = {
        name = "binary",
        binary = true,
        validate   = binary_validate,
        split_char = binary_split_char,
        split_int  = binary_split_int,
        next_char  = binary_next_char,
        next_int   = binary_next_int,
        get_char   = binary_get_char,
        get_int    = binary_get_int,
        tochar    = s_char
    },
    ["UTF-8"] = {
        name = "UTF-8",
        validate   = utf8_validate,
        split_char = utf8_split_char,
        split_int  = utf8_split_int,
        next_char  = utf8_next_char,
        next_int   = utf8_next_int,
        get_char   = utf8_get_char,
        get_int    = utf8_get_int
    }
}

return function (Builder)
    local cs = Builder.options.charset or "binary"
    if charsets[cs] then 
        Builder.charset = copy(charsets[cs])
        Builder.binary_split_int = binary_split_int
    else
        error("NYI: custom charsets")
    end
end


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['re'] = function (...)
local module = function(m, _G) local _G = _G or {}
-- hack to get this file to work with both
-- LuaLPeg and the LPeg test file during dev mode.


-- $Id: re.lua,v 1.44 2013/03/26 20:11:40 roberto Exp $

-- imported functions and modules
local tonumber, type, print, error = tonumber, type, print, error
local setmetatable = setmetatable

-- 'm' will be used to parse expressions, and 'mm' will be used to
-- create expressions; that is, 're' runs on 'm', creating patterns
-- on 'mm'
local mm = m

-- pattern's metatable
local mt = getmetatable(mm.P(0))



-- No more global accesses after this point
local version = _VERSION
if version == "Lua 5.2" then _ENV = nil end


local any = m.P(1)


-- Pre-defined names
local Predef = { nl = m.P"\n" }


local mem
local fmem
local gmem


local function updatelocale ()
  mm.locale(Predef)
  Predef.a = Predef.alpha
  Predef.c = Predef.cntrl
  Predef.d = Predef.digit
  Predef.g = Predef.graph
  Predef.l = Predef.lower
  Predef.p = Predef.punct
  Predef.s = Predef.space
  Predef.u = Predef.upper
  Predef.w = Predef.alnum
  Predef.x = Predef.xdigit
  Predef.A = any - Predef.a
  Predef.C = any - Predef.c
  Predef.D = any - Predef.d
  Predef.G = any - Predef.g
  Predef.L = any - Predef.l
  Predef.P = any - Predef.p
  Predef.S = any - Predef.s
  Predef.U = any - Predef.u
  Predef.W = any - Predef.w
  Predef.X = any - Predef.x
  mem = {}    -- restart memoization
  fmem = {}
  gmem = {}
  local mt = {__mode = "v"}
  setmetatable(mem, mt)
  setmetatable(fmem, mt)
  setmetatable(gmem, mt)
end


updatelocale()



local I = m.P(function (s,i) print(i, s:sub(1, i-1)); return i end)


local function getdef (id, defs)
  local c = defs and defs[id]
  if not c then error("undefined name: " .. id) end
  return c
end


local function patt_error (s, i)
  local msg = (#s < i + 20) and s:sub(i)
                             or s:sub(i,i+20) .. "..."
  msg = ("pattern error near '%s'"):format(msg)
  -- [[DBG]] print("patt_error", i, s)
  error(msg, 2)
end

local function mult (p, n)
  local np = mm.P(true)
  while n >= 1 do
    if n%2 >= 1 then np = np * p end
    p = p * p
    n = n/2
  end
  return np
end

local function equalcap (s, i, c)
  -- print("Equal cap: ", s, i, c)
  if type(c) ~= "string" then return nil end
  local e = #c + i
  if s:sub(i, e - 1) == c then return e else return nil end
end


local S = (Predef.space + "--" * (any - Predef.nl)^0)^0

local name = m.R("AZ", "az", "__") * m.R("AZ", "az", "__", "09")^0

local arrow = S * "<-"

local seq_follow = m.P"/" + ")" + "}" + ":}" + "~}" + "|}" + (name * arrow) + -1

name = m.C(name)


-- a defined name only have meaning in a given environment
local Def = name * m.Carg(1)

local num = m.C(m.R"09"^1) * S / tonumber

local String = "'" * m.C((any - "'")^0) * "'" +
               '"' * m.C((any - '"')^0) * '"'


local defined = "%" * Def / function (c,Defs)
  local cat =  Defs and Defs[c] or Predef[c]
  if not cat then error ("name '" .. c .. "' undefined") end
  return cat
end

local Range = m.Cs(any * (m.P"-"/"") * (any - "]")) / mm.R

local item = defined + Range + m.C(any)

local Class =
    "["
  * (m.C(m.P"^"^-1))    -- optional complement symbol
  * m.Cf(item * (item - "]")^0, mt.__add) /
                          function (c, p) return c == "^" and any - p or p end
  * "]"

local function adddef (t, k, exp)
  if t[k] then
    error("'"..k.."' already defined as a rule")
  else
    -- print("Add def:", k)
    t[k] = exp
  end
  return t
end

local function firstdef (n, r)
  -- print("First def: ", n)
  return adddef({n}, n, r)
  end

local
function Debug (pt) return m.Cmt(pt, function (s,i,...) 
    print( "Re DBG++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      , i, ('-'):rep(40)..'\n', s:sub(i,-1), ... ) 
      m.pprint(pt)
    return true, ...
  end)
end

local function NT (n, b)
  if not b then
    error("rule '"..n.."' used outside a grammar")
  else return mm.V(n)
  end
end

-- [[DBG]] local __mul = m.__mul
-- [[DBG]] m.__mul = function(a,b) m.pprint(a); m.pprint(b) return __mul(a,b) end

local exp = m.P{ "Exp",
  Exp = S * ( m.V"Grammar"
            + m.Cf(m.V"Seq" * ("/" * S * m.V"Seq")^0, mt.__add) );
  Seq = m.Cf(m.Cc(m.P"") * m.V"Prefix"^0 ,  mt.__mul)
        * (#seq_follow + patt_error);
  Prefix = "&" * S * m.V"Prefix" / mt.__len
         + "!" * S * m.V"Prefix" / mt.__unm
         + m.V"Suffix";
  Suffix = m.Cf(m.V"Primary" * S *
          ( ( m.P"+" * m.Cc(1, mt.__pow)
            + m.P"*" * m.Cc(0, mt.__pow)
            + m.P"?" * m.Cc(-1, mt.__pow)
            + "^" * ( m.Cg(num * m.Cc(mult))
                    + m.Cg(m.C(m.S"+-" * m.R"09"^1) * m.Cc(mt.__pow))
                    )
            + "->" * S * ( m.Cg((String + num) * m.Cc(mt.__div))
                         + m.P"{}" * m.Cc(nil, m.Ct)
                         + m.Cg(Def / getdef * m.Cc(mt.__div))
                         )
            + "=>" * S * m.Cg(Def / getdef * m.Cc(m.Cmt))
            ) * S
          )^0, function (a,b,f) 
                  -- print"Fold------------------"; 
                  -- print("f, a, b: ", f, a, b)
                  -- print(mm.ispattern(a))
                  -- mm.pprint(a)
                  -- print"Fold"; 
                  -- mm.pprint(b)
                  -- print"Fold"; 
                  -- mm.pprint(f(a,b))
                  -- print"Fold==================="; 
                  return  f(a,b) end );
  Primary = "(" * m.V"Exp" * ")"
            + String / mm.P
            + Class
            + defined
            + "{:" * (name * ":" + m.Cc(nil)) * m.V"Exp" * ":}" /
                     function (n, p) return mm.Cg(p, n) end
            + "=" * name / function (n) return mm.Cmt(mm.Cb(n), equalcap) end
            + m.P"{}" / mm.Cp
            + "{~" * m.V"Exp" * "~}" / mm.Cs
            + "{|" * m.V"Exp" * "|}" / mm.Ct
            + "{" * m.V"Exp" * "}" / mm.C
            + m.P"." * m.Cc(any)
            + (name * -arrow + "<" * name * ">") * m.Cb("G") / NT;
  Definition = Debug(name)  * arrow * m.V"Exp";
  Grammar = m.Cg(m.Cc(true), "G") *
            m.Cf(m.V"Definition"  / firstdef * m.Cg(m.V"Definition")^0,
              adddef) / function(t)
                          if false then
                            for k, p in pairs(t) do
                              if type(p) ~= "string" then
                                local enter = mm.Cmt(mm.P(true), function(s, p, ...)
                                  print("ENTER", k) return p end);
                                local leave = mm.Cmt(mm.P(true), function(s, p, ...)
                                  print("LEAVE", k) end);
                                t[k] = mm.Cmt(enter * p + leave, function(s, p, ...)
                                  print("---", k, "---", p, s:sub(1, p-1)) return p end)
                              end
                            end
                          end
                          return mm.P(t)
                        end
}

local pattern = S * m.Cg(m.Cc(false), "G") * exp / mm.P * (-any + patt_error)


local function compile (p, defs)
  if mm.type(p) == "pattern" then return p end   -- already compiled
  local cp = pattern:match(p, 1, defs)
  if not cp then error("incorrect pattern", 3) end
  -- m.pprint(cp)
  return cp
end

local function match (s, p, i)
  local cp = mem[p]
  if not cp then
    cp = compile(p)
    mem[p] = cp
  end
  -- print(cp)
  return cp:match(s, i or 1)
end

local function find (s, p, i)
  local cp = fmem[p]
  if not cp then
    cp = compile(p) / 0
    cp = mm.P{ mm.Cp() * cp * mm.Cp() + 1 * mm.V(1) }
    fmem[p] = cp
  end
  local i, e = cp:match(s, i or 1)
  if i then return i, e - 1
  else return i
  end
end

local function gsub (s, p, rep)
  local g = gmem[p] or {}   -- ensure gmem[p] is not collected while here
  gmem[p] = g
  local cp = g[rep]
  if not cp then
    cp = compile(p)
    cp = mm.Cs((cp / rep + 1)^0)
    g[rep] = cp
  end
  return cp:match(s)
end


-- exported names
local re = {
  compile = compile,
  match = match,
  find = find,
  gsub = gsub,
  updatelocale = updatelocale,
}

if version == "Lua 5.1" then _G.re = re end

return re
end

if arg and not release then return module(require(arg[1]), _G or {}) else return module end 
end
end
--=============================================================================
do local _ENV = _ENV
packages['factorizer'] = function (...)
local ipairs, pairs, print, setmetatable, type
    = ipairs, pairs, print, setmetatable, type

local t_insert = require"table".insert

local u = require"util"

local   id,   setify
    = u.id, u.setify

local _ENV = u.noglobals()



-- if pcall then 
--     pcall(setfenv, 2, setmetatable({},{ __index=error, __newindex=error }) )
-- end

local function arrayify(...) return {...} end

return function(Builder, PL)

if Builder.options.factorize == false then 
    print"No factorization"
    return {
        choice = arrayify,
        lookahead = id,
        sequence = arrayify,
        unm = id
    }
end

local constructors, PL_P =  Builder.constructors, PL.P
local truept, falsept 
    = constructors.constant.truept
    , constructors.constant.falsept

local --Range, Set, 
    S_union
    = --Builder.Range, Builder.set.new, 
    Builder.set.union


-- flattens a sequence (a * b) * (c * d) => a * b * c * d
local
function flatten(typ, a,b)
     local acc = {}
    for _, p in ipairs{a,b} do
        if p.ptype == typ then
            for _, q in ipairs(p.aux) do
                acc[#acc+1] = q
            end
        else
            acc[#acc+1] = p
        end
    end
    return acc
end

local
function process_booleans(lst, opts)
    local acc, id, brk = {}, opts.id, opts.brk
    for i = 1,#lst do
        local p = lst[i]
        if p ~= id then
            acc[#acc + 1] = p
        end
        if p == brk then
            break
        end
    end
    return acc
end

local
function append (acc, p1, p2)
    acc[#acc + 1] = p2
end

local
function seq_str_str (acc, p1, p2)
    acc[#acc] = PL_P(p1.as_is .. p2.as_is)
end

local
function seq_any_any (acc, p1, p2)
    acc[#acc] = PL_P(p1.aux + p2.aux)
end

local
function seq_unm_unm (acc, p1, p2)
    acc[#acc] = -(p1.pattern + p2.pattern)
end


-- Lookup table for the optimizers.
local seq_optimize = {
    string = {string = seq_str_str},
    any = {
        any = seq_any_any,
        one = seq_any_any
    },
    one = {
        any = seq_any_any,
        one = seq_any_any
    },
    unm = { 
        unm = append -- seq_unm_unm 
    }
}

-- Lookup misses end up with append.
local metaappend_mt = {
    __index = function()return append end
}
for k,v in pairs(seq_optimize) do
    setmetatable(v, metaappend_mt)
end
local metaappend = setmetatable({}, metaappend_mt) 
setmetatable(seq_optimize, {
    __index = function() return metaappend end
})

local unary = setify{
    "C", "Cf", "Cg", "Cs", "Ct", "/zero",
    "Ctag", "Cmt", "/string", "/number",
    "/table", "/function", "at least", "at most"
}

local type2cons = {
    ["/zero"] = PL.__div,
    ["/number"] = PL.__div,
    ["/string"] = PL.__div,
    ["/table"] = PL.__div,
    ["/function"] = PL.__div,
    ["at least"] = PL.__exp,
    ["at most"] = PL.__exp,
    ["Ctag"] = PL.Cg,
}

local
function mergeseqhead (p1, p2)
    local n, len = 0, m_min(#p1, p2)
    while n <= len do
        if pi[n + 1] == p2[n + 1] then n = n + 1
        else break end
    end
end

local
function choice (a,b)
    -- [[DP]] print("Factorize Choice")
    -- 1. flatten  (a + b) + (c + d) => a + b + c + d
    local dest = flatten("choice", a, b)
    -- 2. handle P(true) and P(false)
    dest = process_booleans(dest, { id = falsept, brk = truept })
    -- Concatenate `string` and `any` patterns.
    local changed
    local src
    repeat
        src, dest, changed = dest, {dest[1]}, false
        for i = 2,#src do
            local p1, p2 = src[i], dest[#dest]
            local type1, type2 = p1,type, p2.type
            if type1 == "set" and type2 == "set" then
                -- Merge character sets. S"abc" + S"ABC" => S"abcABC"
                dest[#dest] = constructors.aux(
                    "set", nil, 
                    S_union(p1.aux, p2.aux), 
                    "Union( "..p1.as_is.." || "..p2.as_is.." )"
                )
                changed = true
            elseif ( type1 == type2 ) and unary[type1] and ( p1.aux == p2.aux ) then
                -- C(a) + C(b) => C(a + b)
                dest[#dest] = PL[type2cons[type1] or type1](p1.pattern + p2.pattern, p1.aux)
                changed = true
            elseif ( type1 == type2 ) and type1 == "sequence" then
                -- "abd" + "acd" => "a" * ( "b" + "c" ) * "d"
                if p1[1] == p2[1]  then
                    mergeseqheads(p1,p2, dest)
                    changed = true
                elseif p1[#p1] == p2[#p2]  then
                    dest[#dest] = mergeseqtails(p1,p2)
                    changed = true
                end
            else
                dest[#dest + 1] = p2
            end
        end
    until not changed

    return dest
end

local
function lookahead (pt)
    return pt
end

local
function sequence(a,b)
    -- [[DP]] print("Factorize Sequence")
    -- A few optimizations:
    -- 1. flatten the sequence (a * b) * (c * d) => a * b * c * d
    local seq1 = flatten("sequence", a, b)
    -- 2. handle P(true) and P(false)
    seq1 = process_booleans(seq1, { id = truept, brk = falsept })
    -- Concatenate `string` and `any` patterns.
    -- TODO: Repeat patterns?
    local seq2 = {}
    seq2[1] = seq1[1]
    for i = 2,#seq1 do
        local p1, p2 = seq2[#seq2], seq1[i]
        seq_optimize[p1.ptype][p2.ptype](seq2, p1, p2)
    end
    return seq2
end

local
function unm (pt)
    -- [[DP]] print("Factorize Unm")
    if     pt == truept            then return -pt, true
    elseif pt == falsept           then return -pt, true
    elseif pt.ptype == "unm"       then return #pt.pattern, true
    elseif pt.ptype == "lookahead" then pt = pt.pattern
    end
    return pt
end

return {
    choice = choice,
    lookahead = lookahead,
    sequence = sequence,
    unm = unm
}
end
end
end
--=============================================================================
do local _ENV = _ENV
packages['util'] = function (...)
local getmetatable, setmetatable, ipairs, load, loadstring, next
    , pairs, print, select, table, tostring, type, unpack, _VERSION
    = getmetatable, setmetatable, ipairs, load, loadstring, next
    , pairs, print, select, table, tostring, type, unpack, _VERSION

local debug, table = require"debug", require"table"

local m_max
    , t_insert 
    = require"math".max
local s, t = require"string", require"table"
local s_match, s_gsub, t_concat, t_insert
    = s.match, s.gsub, t.concat, t.insert

local compat = require"compat"

local
function nop () end

local noglobals if pcall then
    local function errR (_,i)
        error("illegal global read: " .. tostring(i), 2)
    end
    local function errW (_,i, v)
        error("illegal global write: " .. tostring(i)..": "..tostring(v), 2)
    end
    local env = setmetatable({}, { __index=errR, __newindex=errW })
    noglobals = function()
        pcall(setfenv, 3, env)
    end
else
    noglobals = nop
end


local _ENV = noglobals() ------------------------------------------------------


local util = {
    nop = nop,
    noglobals = noglobals
}

util.unpack = table.unpack or unpack
util.pack = table.pack or function(...) return { n = select('#', ...), ... } end


if compat.lua51 then
    local old_load = load

   function util.load (ld, source, mode, env)
     -- We ignore mode. Both source and bytecode can be loaded.
     local fun
     if type (ld) == 'string' then
       fun = loadstring (ld)
     else
       fun = old_load (ld, source)
     end
     if env then
       setfenv (fun, env)
     end
     return fun
   end
else
    util.load = load
end

if compat.luajit and compat.jit then
    local function _fold(len, ary, func) 
        local acc = ary[1] 
        for i = 2, len do acc =func(acc, ary[i]) end 
        return acc 
    end
    function util.max (ary)
        local max = 0
        for i = 1, #ary do 
            max = m_max(max,ary[i])
        end
        return max        
    end
elseif compat.luajit then
    local t_unpack = util.unpack
    function util.max (ary)
     local len = #ary
        if len <=30 or len > 10240 then
            local max = 0
            for i = 1, #ary do 
                local j = ary[i] 
                if j > max then max = j end 
            end
            return max
        else
            return m_max(t_unpack(ary))
        end
    end
elseif compat.lua52 then
    local t_unpack = util.unpack
    function util.max (ary)
        local len = #ary
        if len == 0 
            then return 0
        elseif len <=20 or len > 10240 then
            local max = ary[1]
            for i = 2, len do 
                if ary[i] > max then max = ary[i] end 
            end
            return max
        else
            return m_max(t_unpack(ary))
        end
    end
else
    local t_unpack = util.unpack
    function util.max (ary)
        -- [[DB]] util.expose(ary)
        -- [[DB]] print(debug.traceback())
        local len = #ary
        if len == 0 then 
            return 0
        elseif len <=20 or len > 10240 then
            local max = ary[1]
            for i = 2, len do 
                if ary[i] > max then max = ary[i] end 
            end
            return max
        else
            return m_max(t_unpack(ary))
        end
    end
end            


local
function setmode(t,mode)
    local mt = getmetatable(t) or {}
    if mt.__mode then 
        error("The mode has already been set on table "..tostring(t)..".")
    end
    mt.__mode = mode
    return setmetatable(t, mt)
end

util.setmode = setmode

function util.weakboth (t)
    return setmode(t,"kv")
end

function util.weakkey (t)
    return setmode(t,"k")
end

function util.weakval (t)
    return setmode(t,"v")
end

function util.strip_mt (t)
    return setmetatable(t, nil)
end

local getuniqueid
do
    local N, index = 0, {}
    function getuniqueid(v)
        if not index[v] then
            N = N + 1
            index[v] = N
        end
        return index[v]
    end
end
util.getuniqueid = getuniqueid

do
    local counter = 0
    function util.gensym () 
        counter = counter + 1
        return "___SYM_"..counter
    end
end

function util.passprint (...) print(...) return ... end

local val_to_str_, key_to_str, table_tostring, cdata_to_str, t_cache
local multiplier = 2

local
function val_to_string (v, indent)
    indent = indent or 0
    t_cache = {} -- upvalue.
    local acc = {}
    val_to_str_(v, acc, indent, indent)
    local res = t_concat(acc, "")
    return res
end
util.val_to_str = val_to_string

function val_to_str_ ( v, acc, indent, str_indent )
    str_indent = str_indent or 1
    if "string" == type( v ) then
        v = s_gsub( v, "\n",  "\n" .. (" "):rep( indent * multiplier + str_indent ) )
        if s_match( s_gsub( v,"[^'\"]",""), '^"+$' ) then
            acc[#acc+1] = t_concat{ "'", "", v, "'" }
        else
            acc[#acc+1] = t_concat{'"', s_gsub(v,'"', '\\"' ), '"' }
        end
    elseif "cdata" == type( v ) then 
            cdata_to_str( v, acc, indent )
    elseif "table" == type(v) then
        if t_cache[v] then 
            acc[#acc+1] = t_cache[t]
        else
            t_cache[v] = tostring( v )
            table_tostring( v, acc, indent )
        end
    else
        acc[#acc+1] = tostring( v )
    end
end

function key_to_str ( k, acc, indent )
    if "string" == type( k ) and s_match( k, "^[_%a][_%a%d]*$" ) then
        acc[#acc+1] = s_gsub( k, "\n", (" "):rep( indent * multiplier + 1 ) .. "\n" )
    else
        acc[#acc+1] = "[ "
        val_to_str_( k, acc, indent )
        acc[#acc+1] = " ]"
    end
end

function cdata_to_str(v, acc, indent)
    acc[#acc+1] = ( " " ):rep( indent * multiplier )
    acc[#acc+1] = "["
    print(#acc)
    for i = 0, #v do
        if i % 16 == 0 and i ~= 0 then
            acc[#acc+1] = "\n"
            acc[#acc+1] = (" "):rep(indent * multiplier + 2)
        end
        acc[#acc+1] = v[i] and 1 or 0
        acc[#acc+1] = i ~= #v and  ", " or ""
    end
    print(#acc, acc[1], acc[2])
    acc[#acc+1] = "]"
end

function table_tostring ( tbl, acc, indent )
    -- acc[#acc+1] = ( " " ):rep( indent * multiplier )
    acc[#acc+1] = t_cache[tbl]
    acc[#acc+1] = "{\n"
    for k, v in pairs( tbl ) do
        local str_indent = 1
        acc[#acc+1] = (" "):rep((indent + 1) * multiplier)
        key_to_str( k, acc, indent + 1)

        if acc[#acc] == " ]"
        and acc[#acc - 2] == "[ " 
        then str_indent = 8 + #acc[#acc - 1]
        end

        acc[#acc+1] = " = "
        val_to_str_( v, acc, indent + 1, str_indent)
        acc[#acc+1] = "\n"
    end
    acc[#acc+1] = ( " " ):rep( indent * multiplier )
    acc[#acc+1] = "}"
end

function util.expose(v) print(val_to_string(v)) return v end
-------------------------------------------------------------------------------
--- Functional helpers
--

function util.map (ary, func, ...)
    if type(ary) == "function" then ary, func = func, ary end
    local res = {}
    for i = 1,#ary do
        res[i] = func(ary[i], ...)
    end
    return res
end

local
function map_all (tbl, func, ...)
    if type(tbl) == "function" then tbl, func = func, tbl end
    local res = {}
    for k, v in next, tbl do
        res[k]=func(v, ...)
    end
    return res
end

util.map_all = map_all

local
function fold (ary, func, acc)
    local i0 = 1
    if not acc then
        acc = ary[1]
        i0 = 2
    end
    for i = i0, #ary do
        acc = func(acc,ary[i])
    end
    return acc
end
util.fold = fold

local
function map_fold(ary, mfunc, ffunc, acc)
    local i0 = 1
    if not acc then
        acc = mfunc(ary[1])
        i0 = 2
    end
    for i = i0, #ary do
        acc = ffunc(acc,mfunc(ary[i]))
    end
    return acc
end
util.map_fold = map_fold

function util.zip(a1, a2)
    local res, len = {}, m_max(#a1,#a2)
    for i = 1,len do
        res[i] = {a1[i], a2[i]}
    end
    return res
end

function util.zip_all(t1, t2)
    local res = {}
    for k,v in pairs(t1) do
        res[k] = {v, t2[k]}
    end
    for k,v in pairs(t2) do
        if res[k] == nil then
            res[k] = {t1[k], v}
        end
    end
    return res
end

function util.filter(a1,func)
    local res = {}
    for i = 1,#ary do
        if func(ary[i]) then 
            t_insert(res, ary[i])
        end
    end

end

local
function id (...) return ... end
util.id = id



local function AND (a,b) return a and b end
local function OR  (a,b) return a or b  end

function util.copy (tbl) return map_all(tbl, id) end

function util.all (ary, mfunc) 
    if mfunc then 
        return map_fold(ary, mfunc, AND)
    else
        return fold(ary, AND)
    end
end

function util.any (ary, mfunc)
    if mfunc then 
        return map_fold(ary, mfunc, OR)
    else
        return fold(ary, OR)
    end
end

function util.get(field) 
    return function(tbl) return tbl[field] end 
end

function util.lt(ref) 
    return function(val) return val < ref end
end

-- function util.lte(ref) 
--     return function(val) return val <= ref end
-- end

-- function util.gt(ref) 
--     return function(val) return val > ref end
-- end

-- function util.gte(ref) 
--     return function(val) return val >= ref end
-- end

function util.compose(f,g) 
    return function(...) return f(g(...)) end
end

function util.extend (destination, ...)
    for i = 1, select('#', ...) do
        for k,v in pairs((select(i, ...))) do
            destination[k] = v
        end
    end
    return destination
end

function util.setify (t)
    local set = {}
    for i = 1, #t do
        set[t[i]]=true
    end
    return set
end
--[[
util.dprint =  print
--[=[]]
util.dprint =  nop
--]=]
return util

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--=============================================================================
do local _ENV = _ENV
packages['printers'] = function (...)
return function(Builder, PL)

---------------------------------------  ,--.     º      |     ---------------
---------------------------------------  |__' ,-- , ,-.  |--   ---------------
-- Print ------------------------------  |    |   | |  | |     ---------------
---------------------------------------  '    '   ' '  ' `--   ---------------

local ipairs, pairs, print, tostring, type 
    = ipairs, pairs, print, tostring, type

local s, t, u = require"string", require"table", require"util"


local _ENV = u.noglobals() ----------------------------------------------------


local s_char, t_concat 
    = s.char, t.concat

local   expose,   load,   map
    = u.expose, u.load, u.map

local printers = {}

local
function PL_pprint (pt, offset, prefix)
    -- [[DP]] print("PRINT", pt.ptype)
    -- [[DP]] expose(PL.proxycache[pt])
    return printers[pt.ptype](pt, offset, prefix)
end

function PL.pprint (pt)
    pt = PL.P(pt)
    print"\nPrint pattern"
    PL_pprint(pt, "", "")
    print"--- /pprint\n"
    return pt
end

for k, v in pairs{
    string       = [[ "P( \""..pt.as_is.."\" )"       ]],
    char         = [[ "P( '"..to_char(pt.aux).."' )"         ]],
    ["true"]     = [[ "P( true )"                     ]],
    ["false"]    = [[ "P( false )"                    ]],
    eos          = [[ "~EOS~"                         ]],
    one          = [[ "P( one )"                      ]],
    any          = [[ "P( "..pt.aux.." )"            ]],
    set          = [[ "S( "..'"'..pt.as_is..'"'.." )" ]],
    ["function"] = [[ "P( "..pt.aux.." )"            ]],
    ref = [[
        "V( ",
            (type(pt.aux) == "string" and "\""..pt.aux.."\"")
                          or tostring(pt.aux) 
        , " )"
        ]],
    range = [[
        "R( ",
            t_concat(map(
                pt.as_is, 
                function(e) return '"'..e..'"' end), ", "
            )
        ," )"
        ]]
} do
    printers[k] = load(([==[
        local k, map, t_concat, to_char = ...
        return function (pt, offset, prefix)
            print(t_concat{offset,prefix,XXXX})
        end
    ]==]):gsub("XXXX", v), k.." printer")(k, map, t_concat, s_char)
end


for k, v in pairs{
    ["behind"] = [[ PL_pprint(pt.pattern, offset, "B ") ]],
    ["at least"] = [[ PL_pprint(pt.pattern, offset, pt.aux.." ^ ") ]],
    ["at most"] = [[ PL_pprint(pt.pattern, offset, pt.aux.." ^ ") ]],
    unm        = [[PL_pprint(pt.pattern, offset, "- ")]],
    lookahead  = [[PL_pprint(pt.pattern, offset, "# ")]],
    choice = [[
        print(offset..prefix.."+")
        -- dprint"Printer for choice"
        map(pt.aux, PL_pprint, offset.." :", "")
        ]],
    sequence = [[
        print(offset..prefix.."*")
        -- dprint"Printer for Seq"
        map(pt.aux, PL_pprint, offset.." |", "")
        ]],
    grammar   = [[
        print(offset..prefix.."Grammar")
        -- dprint"Printer for Grammar"
        for k, pt in pairs(pt.aux) do
            local prefix = ( type(k)~="string" 
                             and tostring(k)
                             or "\""..k.."\"" )
            PL_pprint(pt, offset.."  ", prefix .. " = ")
        end
    ]]
} do
    printers[k] = load(([[
        local map, PL_pprint, ptype = ...
        return function (pt, offset, prefix)
            XXXX
        end
    ]]):gsub("XXXX", v), k.." printer")(map, PL_pprint, type)
end

-------------------------------------------------------------------------------
--- Captures patterns
--

-- for __, cap in pairs{"C", "Cs", "Ct"} do
-- for __, cap in pairs{"Carg", "Cb", "Cp"} do
-- function PL_Cc (...)
-- for __, cap in pairs{"Cf", "Cmt"} do
-- function PL_Cg (pt, tag)
-- local valid_slash_type = newset{"string", "number", "table", "function"}


for __, cap in pairs{"C", "Cs", "Ct"} do
    printers[cap] = function (pt, offset, prefix)
        print(offset..prefix..cap)
        PL_pprint(pt.pattern, offset.."  ", "")
    end
end

for __, cap in pairs{"Cg", "Ctag", "Cf", "Cmt", "/number", "/zero", "/function", "/table"} do
    printers[cap] = function (pt, offset, prefix)
        print(offset..prefix..cap.." "..tostring(pt.aux or ""))
        PL_pprint(pt.pattern, offset.."  ", "")
    end
end

printers["/string"] = function (pt, offset, prefix)
    print(offset..prefix..'/string "'..tostring(pt.aux or "")..'"')
    PL_pprint(pt.pattern, offset.."  ", "")
end

for __, cap in pairs{"Carg", "Cp"} do
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

function PL.cprint (capture)
    print"\nCapture Printer\n===============\n"
    -- print(capture)
    -- expose(capture)
    -- expose(capture[1])
    cprinters[capture.type](capture, "", "")
    print"\n/Cprinter -------\n"
end

cprinters["backref"] = function (capture, offset, prefix)
    print(offset..prefix.."Back: start = "..capture.start)
    cprinters[capture.ref.type](capture.ref, offset.."   ")
end

-- cprinters["string"] = function (capture, offset, prefix)
--     print(offset..prefix.."String: start = "..capture.start..", finish = "..capture.finish)
-- end
cprinters["value"] = function (capture, offset, prefix)
    print(offset..prefix.."Value: start = "..capture.start..", value = "..tostring(capture.value))
end

cprinters["values"] = function (capture, offset, prefix)
    -- expose(capture)
    print(offset..prefix.."Values: start = "..capture.start..", values = ")
    for _, c in pairs(capture.values) do
        print(offset.."   "..tostring(c))
    end
end

cprinters["insert"] = function (capture, offset, prefix)
    print(offset..prefix.."insert n="..capture.n)
    for i, subcap in ipairs(capture) do
        -- dprint("insertPrinter", subcap.type)
        cprinters[subcap.type](subcap, offset.."|  ", i..". ")
    end

end

for __, capname in ipairs{
    "Cf", "Cg", "tag","C", "Cs", 
    "/string", "/number", "/table", "/function" 
} do 
    cprinters[capname] = function (capture, offset, prefix)
        local message = offset..prefix..capname
            ..": start = "..capture.start 
            ..", finish = "..capture.finish
            ..(capture.Ctag and " tag = "..capture.Ctag or "")
        if capture.aux then 
            message = message .. ", aux = ".. tostring(capture.aux)
        end
        print(message)
        for i, subcap in ipairs(capture) do
            cprinters[subcap.type](subcap, offset.."   ", i..". ")
        end

    end
end


cprinters["Ct"] = function (capture, offset, prefix)
    local message = offset..prefix.."Ct: start = "..capture.start ..", finish = "..capture.finish
    if capture.aux then 
        message = message .. ", aux = ".. tostring(capture.aux)
    end
    print(message)
    for i, subcap in ipairs(capture) do
        -- print ("Subcap type",subcap.type)
        cprinters[subcap.type](subcap, offset.."   ", i..". ")
    end
    for k,v in pairs(capture.hash or {}) do 
        print(offset.."   "..k, "=", v)
        expose(v)
    end

end

cprinters["Cb"] = function (capture, offset, prefix)
    print(offset..prefix.."Cb: tag = "
        ..(type(capture.tag)~="string" and tostring(capture.tag) or "\""..capture.tag.."\"")
        )
end

return { pprint = PL.pprint,cprint = PL.cprint }

end -- module wrapper ---------------------------------------------------------


--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            The PureLPeg proto-library
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
end
end
--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
-- 
-- 
--            Dear user,
-- 
--            The PureLPeg library
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
--                               / library...
--                              /  ~ ~ ~ ~
--                             /    Love,
--                        #   /      ','
--                        #######    ·
--                        #####
--                        ###
--                        #
-- 
--               -- Pierre-Yves
-- 
-- 
-- 
--            P.S.: Even though I poured my heart into this work, 
--                  I _cannot_ provide any warranty regarding 
--                  its fitness for _any_ purpose. You
--                  acknowledge that I will not be held liable
--                  for any damage its use could incur.
                 