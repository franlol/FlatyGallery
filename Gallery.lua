-------------------------------------------------------------------------------
-- Flaty Gallery: every LibFlatyUI component in every state. /flaty
-- Nothing is saved; the status line shows the last value changed.
-------------------------------------------------------------------------------
local UI = LibStub("LibFlatyUI-1.0"):New()
UI.OnChange = function() UI.RefreshAll() end

local win

-------------------------------------------------------------------------------
-- State and helpers
-------------------------------------------------------------------------------
local S = {
    checkOn = true, checkOff = false, checkTip = true, master = true, child = true,
    disOn = true, disOff = false,
    swOn = true, swOff = false, swTip = false, swMaster = true, swChild = false,
    size = 24, alpha = 0.8, time = 1.5, count = 5, step = 0.25, scale = 1, spacing = 4,
    seg2 = "left", seg3 = "medium", segNoLabel = "list",
    anchor = "TOP", zone = 7, font = "Fonts\\FRIZQT__.TTF",
    bar = "Interface\\TargetingFrame\\UI-StatusBar", fromFn = 1,
    unknown = "Interface\\AddOns\\MyAddon\\Media\\MyBar.tga",
    nameEnter = "Flaty", nameBlur = "", plain = "", locked = "Read only",
    color = { r = 0.27, g = 0.75, b = 0.45, a = 0.8 },
    colorSolid = { r = 1, g = 0.82, b = 0, a = 1 },
    colorLocked = { r = 0.4, g = 0.6, b = 1, a = 1 },
    showCard = true, advanced = false, opt = true, tab = "general",
    greyAll = false, spanish = false,
}
local groupVals = { buffs = true, debuffs = true, casts = false, pets = false, focus = true, boss = false }

local function Fmt(v)
    if type(v) == "boolean" then return v and "on" or "off" end
    if type(v) == "table" and v.r then
        return ("r %.2f  g %.2f  b %.2f  a %.2f"):format(v.r, v.g, v.b, v.a or 1)
    end
    if v == nil then return "nil" end
    return tostring(v)
end
local function Log(name, v)
    if win then win:SetStatus(name .. ":  " .. Fmt(v)) end
end
local function Get(k) return function() return S[k] end end
local function Set(k, name) return function(v) S[k] = v Log(name, v) end end
local function Click(name) return function() Log("Clicked", name) end end

-- every row greys out with "Grey all"; Off() rows are always disabled
local function E(o)
    o = o or {}
    local own = o.enableIf
    o.enableIf = function() return not S.greyAll and (not own or own()) end
    return o
end
local function Off(o)
    o = o or {}
    o.enableIf = function() return false end
    return o
end

local GetIcon = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
local function Icon(id) return id and GetIcon(id) or 134400 end
local function Move(list, from, to) table.insert(list, to, table.remove(list, from)) end

local GOOD = { 0.42, 0.84, 0.42 }
local BAD = { 1, 0.35, 0.3 }

-- refreshers for texts that are not controls (notes, titles)
local texts = {}
UI.OnRefresh = function() for _, f in ipairs(texts) do f() end end

local folds = {}
local function Card(page, col, title, subtitle, opts)
    return page:Add(col, UI.Card(page.content, title, subtitle, opts))
end

-------------------------------------------------------------------------------
-- Buttons
-------------------------------------------------------------------------------
local function BuildButtons(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Styles", "Default, accent and danger. Hover lights the border, pressing darkens it.")
    c:Add(UI.Buttons(c, {
        { "Default", Click("Default") },
        { "Accent", Click("Accent"), "accent" },
        { "Danger", Click("Danger"), "danger" },
    }, E()))
    c:Add(UI.Buttons(c, {
        { "With tooltip", Click("With tooltip"), nil, "A button can carry its own tooltip." },
        { "Single", Click("Single") },
    }, E()))
    c:Add(UI.Buttons(c, { { "Wide single button", Click("Wide single button") } }, E()))

    c = Card(page, 1, "Disabled", "Greyed out and ignores clicks; the layout does not move.")
    c:Add(UI.Buttons(c, {
        { "Default", Click("Default") },
        { "Accent", Click("Accent"), "accent" },
        { "Danger", Click("Danger"), "danger" },
    }, Off()))

    c = Card(page, 2, "Two-step confirm", "First click arms it, the second (within 3 s) runs it.")
    local r = c:Add(UI.Buttons(c, {
        { "Reset all", function() Log("Confirmed", "Reset all") end, "danger" },
        { "Delete profile", function() Log("Confirmed", "Delete profile") end, "danger" },
    }, E()))
    UI.Confirm(r.buttons[1])
    UI.Confirm(r.buttons[2], "Sure? Click again")

    c = Card(page, 2, "Dialog", "Darkens the screen. Escape or Cancel closes it.")
    c:Add(UI.Buttons(c, {
        { "Short", function()
            UI.Dialog("Delete the profile \"Healer\"?", "Delete", function() Log("Dialog", "accepted") end)
        end },
        { "Long text", function()
            UI.Dialog("This copies every setting from the selected profile over the current one. "
                .. "Your current bars, colors and texts are replaced and cannot be restored.",
                "Copy", function() Log("Dialog", "accepted") end, "Keep mine")
        end },
        { "Default buttons", function()
            UI.Dialog("Reload the interface now?", nil, function() Log("Dialog", "accepted") end)
        end },
    }, E()))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Toggles
-------------------------------------------------------------------------------
local function BuildToggles(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Check box")
    c:Add(UI.Check(c, "On", Get("checkOn"), Set("checkOn", "Check"), E()))
    c:Add(UI.Check(c, "Off", Get("checkOff"), Set("checkOff", "Check"), E()))
    c:Add(UI.Check(c, "With tooltip", Get("checkTip"), Set("checkTip", "Check"),
        E({ tip = "Hover anywhere on the row to see this." })))
    c:Add(UI.Check(c, "Parent option", Get("master"), Set("master", "Parent"), E()))
    c:Add(UI.Check(c, "Sub-option (needs the parent)", Get("child"), Set("child", "Sub-option"),
        E({ sub = true, enableIf = function() return S.master end })))
    c:Add(UI.Check(c, "Disabled, on", Get("disOn"), Set("disOn", "Check"), Off()))
    c:Add(UI.Check(c, "Disabled, off", Get("disOff"), Set("disOff", "Check"), Off()))
    c:Add(UI.Check(c, "A very long label that does not fit in the width of the card and gets cut",
        Get("checkOn"), Set("checkOn", "Check"), E()))

    c = Card(page, 1, "Check group", "Several on/off values in columns.")
    local function GG(v) return groupVals[v] end
    local function GS(v, on) groupVals[v] = on Log("Group " .. v, on) end
    c:Add(UI.CheckGroup(c, "Two columns", {
        { "buffs", "Buffs" }, { "debuffs", "Debuffs" }, { "casts", "Cast bars" }, { "pets", "Pets" },
    }, GG, GS, E()))
    c:Add(UI.CheckGroup(c, "Three columns", {
        { "buffs", "Buffs" }, { "debuffs", "Debuffs" }, { "casts", "Casts" },
        { "pets", "Pets" }, { "focus", "Focus" }, { "boss", "Boss" },
    }, GG, GS, E({ columns = 3 })))
    c:Add(UI.CheckGroup(c, nil, { { "focus", "No label" }, { "boss", "Second" } }, GG, GS, E()))
    c:Add(UI.CheckGroup(c, "Disabled", { { "buffs", "Buffs" }, { "casts", "Cast bars" } }, GG, GS, Off()))

    c = Card(page, 2, "Switch", "The knob slides; the track takes the accent when on.")
    c:Add(UI.Switch(c, "On", Get("swOn"), Set("swOn", "Switch"), E()))
    c:Add(UI.Switch(c, "Off", Get("swOff"), Set("swOff", "Switch"), E()))
    c:Add(UI.Switch(c, "With tooltip", Get("swTip"), Set("swTip", "Switch"),
        E({ tip = "Hover anywhere on the row to see this." })))
    c:Add(UI.Switch(c, "Parent option", Get("swMaster"), Set("swMaster", "Parent"), E()))
    c:Add(UI.Switch(c, "Sub-option (needs the parent)", Get("swChild"), Set("swChild", "Sub-option"),
        E({ sub = true, enableIf = function() return S.swMaster end })))
    c:Add(UI.Switch(c, "Disabled, on", Get("disOn"), Set("disOn", "Switch"), Off()))
    c:Add(UI.Switch(c, "Disabled, off", Get("disOff"), Set("disOff", "Switch"), Off()))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Values: slider, segmented, dropdown
-------------------------------------------------------------------------------
local ZONES = {}
for i, z in ipairs({ "Orgrimmar", "Stormwind", "Ironforge", "Darnassus", "Undercity", "Thunder Bluff",
    "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Dun Morogh", "Tirisfal Glades", "Westfall",
    "The Barrens", "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "Tanaris", "Feralas",
    "Un'Goro Crater", "Silithus", "Winterspring", "Eastern Plaguelands", "Western Plaguelands",
    "Burning Steppes", "Searing Gorge", "Blasted Lands", "Felwood", "Azshara", "Moonglade" }) do
    ZONES[i] = { i, z }
end

local function BuildValues(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Slider", "Drag, use < >, or click the value to type it.")
    c:Add(UI.Slider(c, "Size", 8, 64, 1, Get("size"), Set("size", "Size"), E({ format = UI.px })))
    c:Add(UI.Slider(c, "Opacity", 0, 1, 0.05, Get("alpha"), Set("alpha", "Opacity"), E({ format = UI.pct })))
    c:Add(UI.Slider(c, "Fade time", 0, 5, 0.1, Get("time"), Set("time", "Fade time"),
        E({ format = function(v) return ("%.1f s"):format(v) end })))
    c:Add(UI.Slider(c, "Count", 1, 10, 1, Get("count"), Set("count", "Count"), E()))
    c:Add(UI.Slider(c, "Fine step", 0, 1, 0.005, Get("step"), Set("step", "Fine step"), E()))
    c:Add(UI.Slider(c, "Disabled", 8, 64, 1, Get("size"), Set("size", "Size"), Off({ format = UI.px })))

    c = Card(page, 1, "Segmented", "Up to three exclusive choices.")
    c:Add(UI.Segmented(c, "Two options", { { "left", "Left" }, { "right", "Right" } },
        Get("seg2"), Set("seg2", "Segmented"), E()))
    c:Add(UI.Segmented(c, "Three options", { { "small", "Small" }, { "medium", "Medium" }, { "large", "Large" } },
        Get("seg3"), Set("seg3", "Segmented"), E()))
    c:Add(UI.Segmented(c, nil, { { "list", "No label" }, { "grid", "Grid" } },
        Get("segNoLabel"), Set("segNoLabel", "Segmented"), E()))
    c:Add(UI.Segmented(c, "Disabled", { { "small", "Small" }, { "medium", "Medium" }, { "large", "Large" } },
        Get("seg3"), Set("seg3", "Segmented"), Off()))

    c = Card(page, 2, "Dropdown", "More than three choices. One list open at a time; click outside to close.")
    c:Add(UI.Dropdown(c, "Short list", {
        { "TOP", "Top" }, { "BOTTOM", "Bottom" }, { "LEFT", "Left" }, { "RIGHT", "Right" }, { "CENTER", "Center" },
    }, Get("anchor"), Set("anchor", "Anchor"), E()))
    c:Add(UI.Dropdown(c, "Long list (scrolls, opens on the value)", ZONES, Get("zone"),
        function(v) S.zone = v Log("Zone", ZONES[v][2]) end, E()))
    c:Add(UI.Dropdown(c, "Fonts (drawn in their font)", {
        { "Fonts\\FRIZQT__.TTF", "Friz Quadrata", "Fonts\\FRIZQT__.TTF" },
        { "Fonts\\ARIALN.TTF", "Arial Narrow", "Fonts\\ARIALN.TTF" },
        { "Fonts\\MORPHEUS.TTF", "Morpheus", "Fonts\\MORPHEUS.TTF" },
        { "Fonts\\SKURRI.TTF", "Skurri", "Fonts\\SKURRI.TTF" },
    }, Get("font"), Set("font", "Font"), E()))
    c:Add(UI.Dropdown(c, "Textures (sample behind)", {
        { "Interface\\TargetingFrame\\UI-StatusBar", "Blizzard", nil, "Interface\\TargetingFrame\\UI-StatusBar" },
        { "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Raid", nil, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
        { "Interface\\Buttons\\WHITE8X8", "Flat", nil, "Interface\\Buttons\\WHITE8X8" },
    }, Get("bar"), Set("bar", "Texture"), E()))
    c:Add(UI.Dropdown(c, "Options from a function (as many as Count)", function()
        local list = {}
        for i = 1, S.count do list[i] = { i, "Option " .. i } end
        return list
    end, Get("fromFn"), Set("fromFn", "Option"), E()))
    c:Add(UI.Dropdown(c, "Value not in the list (shows the file name)", {
        { "a", "Something else" },
    }, Get("unknown"), Set("unknown", "Value"), E()))
    c:Add(UI.Dropdown(c, nil, {
        { "TOP", "No label" }, { "BOTTOM", "Bottom" },
    }, Get("anchor"), Set("anchor", "Anchor"), E()))
    c:Add(UI.Dropdown(c, "Disabled", ZONES, Get("zone"), Set("zone", "Zone"), Off()))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Text: inputs, search, code box, notes
-------------------------------------------------------------------------------
local SPELLS = { "Arcane Intellect", "Blessing of Might", "Fear Ward", "Flash Heal", "Frost Nova",
    "Mark of the Wild", "Power Word: Fortitude", "Power Word: Shield", "Rejuvenation", "Renew",
    "Shadow Word: Pain", "Thorns" }

local CODE = [[
-- Code box: multi-line, scrolls, keeps the cursor in view
local function OnEvent(self, event, unit)
    if event == "UNIT_HEALTH" and unit == "player" then
        local hp = UnitHealth(unit) / UnitHealthMax(unit)
        self.bar:SetValue(hp)
    end
end

frame:RegisterEvent("UNIT_HEALTH")
frame:SetScript("OnEvent", OnEvent)
]]

local function BuildText(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Input", "Tab and Shift+Tab move between inputs. Escape cancels.")
    c:Add(UI.Input(c, "Saves on Enter", Get("nameEnter"), Set("nameEnter", "Input"), E()))
    c:Add(UI.Input(c, "Saves when focus leaves", Get("nameBlur"), Set("nameBlur", "Input"),
        E({ saveOnBlur = true })))
    c:Add(UI.Input(c, nil, Get("plain"), Set("plain", "Input"), E()))
    c:Add(UI.Input(c, "Disabled", Get("locked"), Set("locked", "Input"), Off()))

    c = Card(page, 1, "Search box", "Hint while empty, x clears it, filters on every key.")
    local result
    c:Add(UI.SearchBox(c, nil, function(text)
        local q, hits = text:lower(), {}
        for _, s in ipairs(SPELLS) do
            if q == "" or s:lower():find(q, 1, true) then hits[#hits + 1] = s end
        end
        if result then result:SetText(#hits .. " of " .. #SPELLS .. ":  " .. table.concat(hits, ", ")) end
    end, E()))
    result = c:Add(UI.Note(c, #SPELLS .. " of " .. #SPELLS .. ":  " .. table.concat(SPELLS, ", ")))

    c = Card(page, 2, "Code box", "Click anywhere in it to type.")
    local code = c:Add(UI.CodeBox(c, 150, E()))
    code.edit:SetText(CODE)

    c = Card(page, 2, "Note", "Grey help text that wraps to the width.")
    local note = c:Add(UI.Note(c, "A short note."))
    local long = "A long note wraps over several lines and the card grows to fit it. "
        .. "Change the text with the buttons below: the rows under it move."
    c:Add(UI.Buttons(c, {
        { "Short", function() note:SetText("A short note.") page:Layout() end },
        { "Long", function() note:SetText(long) page:Layout() end },
    }, E()))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Colors
-------------------------------------------------------------------------------
local function BuildColors(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Color swatch", "Click to open the color picker. Cancel restores the color.")
    c:Add(UI.Swatch(c, "With opacity", Get("color"), function() Log("Color", S.color) end, E({ alpha = true })))
    c:Add(UI.Swatch(c, "Without opacity", Get("colorSolid"), function() Log("Color", S.colorSolid) end, E()))
    c:Add(UI.Swatch(c, "Disabled", Get("colorLocked"), nil, Off({ alpha = true })))

    c = Card(page, 2, "No color yet", "With nothing saved the swatch is empty and does not open.")
    c:Add(UI.Swatch(c, "Optional color", Get("colorOpt"), function() Log("Color", S.colorOpt) end, E({ alpha = true })))
    local r = c:Add(UI.Buttons(c, {
        { "Set a color", function()
            S.colorOpt = { r = 0.9, g = 0.3, b = 0.3, a = 1 }
            Log("Color", S.colorOpt)
            UI.RefreshAll()
        end },
        { "Clear color", function()
            S.colorOpt = nil
            Log("Color", nil)
            UI.RefreshAll()
        end, "danger" },
    }, E()))
    UI.Confirm(r.buttons[2])

    page:Layout()
end

-------------------------------------------------------------------------------
-- Lists
-------------------------------------------------------------------------------
local LIST = {
    plain = { "Health", "Name and level", "Power", "Threat %", "Combo points" },
    indicators = {
        { "Renew", "Aura", { 0.3, 0.9, 0.4 } }, { "Rejuvenation", "Aura", { 0.9, 0.4, 0.9 } },
        { "Power Word: Shield", "Aura", { 1, 0.85, 0.3 } }, { "Dispellable magic", "Dispel" },
        { "Dispellable poison", "Dispel" }, { "Aggro", "Status" }, { "Out of range", "Status" },
        { "Mana under 20%", "Status" }, { "Fear Ward", "Aura", { 0.95, 0.6, 0.2 } },
        { "Inner Fire", "Aura", { 0.4, 0.6, 1 } },
    },
    spells = {
        { "Power Word: Fortitude", 1243, true }, { "Arcane Intellect", 1459 }, { "Mark of the Wild", 1126 },
        { "Renew", 139 }, { "Rejuvenation", 774 }, { "Polymorph", 118 }, { "Fear", 5782 },
        { "Shadow Word: Pain", 589 }, { "Corruption", 172 },
    },
}

local function BuildLists(container)
    local page = UI.Page(container, 2)

    -- select + reorder
    local plain, sel = {}, 1
    for i, n in ipairs(LIST.plain) do plain[i] = { name = n } end
    local c = Card(page, 1, "Select and reorder", "Click to select, drag to reorder.")
    c:Add(UI.List(c, E({
        items = function() return plain end,
        label = function(d) return d.name end,
        selected = function(_, i) return i == sel end,
        onSelect = function(i, d) sel = i Log("Selected", d.name) end,
        onReorder = function(from, to) Move(plain, from, to) sel = to Log("Moved", from .. " -> " .. to) end,
        rows = 5,
    })))

    -- check boxes + swatch + tag + columns + scroll
    local ind = {}
    for i, d in ipairs(LIST.indicators) do ind[i] = { name = d[1], kind = d[2], color = d[3], on = i % 4 ~= 0 } end
    c = Card(page, 1, "Check, swatch, tag, columns", "Off rows dim. More rows than fit: it scrolls.", {
        fold = true, store = folds,
        summary = function()
            local n = 0
            for _, d in ipairs(ind) do if d.on then n = n + 1 end end
            return n .. " of " .. #ind .. " on"
        end,
    })
    c:Add(UI.List(c, E({
        items = function() return ind end,
        label = function(d) return d.name end,
        off = function(d) return not d.on end,
        checked = function(d) return d.on end,
        onCheck = function(d, v) d.on = v Log(d.name, v) end,
        lead = "swatch",
        color = function(d) return d.color end,
        tag = function(d) return d.kind, d.kind == "Dispel" and BAD or nil end,
        columns = { name = "Indicator", tag = "Type" },
        rows = 6,
    })))

    -- icon + id + remove
    local spells = {}
    local function Refill()
        wipe(spells)
        for i, d in ipairs(LIST.spells) do spells[i] = { name = d[1], id = d[2], builtin = d[3] } end
    end
    Refill()
    c = Card(page, 1, "Icon, ID, remove", "x asks first. The first row is built in: no x.")
    c:Add(UI.List(c, E({
        items = function() return spells end,
        label = function(d) return d.name end,
        lead = "icon",
        icon = function(d) return Icon(d.id) end,
        spell = function(d) return d.id end,
        secondary = function(d) return "#" .. d.id end,
        columns = { name = "Spell", secondary = "ID" },
        onRemove = function(i, d) table.remove(spells, i) Log("Removed", d.name) end,
        canRemove = function(d) return not d.builtin end,
        empty = "No spells. Press Refill.",
        rows = 6,
    })))
    c:Add(UI.Buttons(c, { { "Refill", function() Refill() UI.RefreshAll() end } }, E()))

    -- groups with partial checks
    local groups = {
        { label = "Lucifron", items = { { name = "Impending Doom", id = 19702, show = true },
            { name = "Lucifron's Curse", id = 19703, show = false }, { name = "Dominate Mind", id = 19711, show = true } } },
        { label = "Magmadar", items = { { name = "Panic", id = 19408, show = true }, { name = "Magma Spit", id = 19450, show = true } } },
        { label = "Garr", closed = true, items = { { name = "Magma Shackles", id = 19496, show = false } } },
        { label = "Shazzrah", items = {} },
    }
    local function Flatten()
        local rows = {}
        for _, g in ipairs(groups) do
            g.header = true
            g.count = #g.items > 0 and ("(" .. #g.items .. ")") or "none"
            g.off = #g.items == 0
            rows[#rows + 1] = g
            if not g.closed then for _, it in ipairs(g.items) do rows[#rows + 1] = it end end
        end
        return rows
    end
    c = Card(page, 2, "Groups", "Headers open and close. The header box sets all; a dash means some.")
    c:Add(UI.List(c, E({
        items = Flatten,
        label = function(d) return d.name end,
        off = function(d) return not d.show end,
        lead = "icon",
        icon = function(d) return Icon(d.id) end,
        spell = function(d) return d.id end,
        secondary = function(d) return tostring(d.id) end,
        checked = function(d)
            if not d.header then return d.show end
            if #d.items == 0 then return nil end
            local n = 0
            for _, it in ipairs(d.items) do if it.show then n = n + 1 end end
            if n == 0 then return false end
            return n == #d.items or "partial"
        end,
        onCheck = function(d, v)
            if d.header then for _, it in ipairs(d.items) do it.show = v end else d.show = v end
            Log(d.label or d.name, v)
        end,
        onToggle = function(g) g.closed = not g.closed end,
    })))

    -- rich headers: a header is a full row (dot, secondary, select)
    local zones = {
        { header = true, label = "Molten Core", here = true, n = 10, items = {
            { name = "Lucifron", n = 3 }, { name = "Magmadar", n = 2 } } },
        { header = true, label = "Onyxia's Lair", n = 1, closed = true, items = { { name = "Onyxia", n = 1 } } },
        { header = true, label = "World bosses", leaf = true, n = 0, items = {} },
    }
    local zoneSel = zones[1]
    c = Card(page, 2, "Rich headers", "Headers are full rows: dot, count and selection. A leaf has no chevron.")
    c:Add(UI.List(c, E({
        items = function()
            local rows = {}
            for _, z in ipairs(zones) do
                rows[#rows + 1] = z
                if not z.closed then for _, it in ipairs(z.items) do rows[#rows + 1] = it end end
            end
            return rows
        end,
        richHeaders = true,
        label = function(d) return d.label or d.name end,
        lead = "dot",
        color = function(d) return d.here and GOOD or nil end,
        secondary = function(d) return tostring(d.n) end,
        selected = function(d) return d == zoneSel end,
        onSelect = function(_, d) zoneSel = d Log("Selected", d.label or d.name) end,
        onToggle = function(z) z.closed = not z.closed end,
        rows = 6,
    })))

    c = Card(page, 2, "Empty", "Keeps its height and shows a message.")
    c:Add(UI.List(c, E({
        items = function() return {} end,
        label = function() return "" end,
        empty = "Nothing here yet.",
        rows = 3,
    })))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Cards
-------------------------------------------------------------------------------
local function BuildCards(container)
    local page = UI.Page(container, 2)

    local c = Card(page, 1, "Plain card")
    c:Add(UI.Check(c, "A row", Get("opt"), Set("opt", "Row"), E()))

    c = Card(page, 1, "Card with subtitle", "The subtitle wraps under the title when it is longer than the width of the card.")
    c:Add(UI.Check(c, "A row", Get("opt"), Set("opt", "Row"), E()))

    c = Card(page, 1, "Rows on demand")
    c:Add(UI.Check(c, "Show advanced options", Get("advanced"), Set("advanced", "Advanced"), E()))
    c:Add(UI.Slider(c, "Advanced: spacing", 0, 20, 1, Get("spacing"), Set("spacing", "Spacing"),
        E({ format = UI.px, showIf = function() return S.advanced end })))
    c:Add(UI.Check(c, "Advanced: snap to grid", Get("opt"), Set("opt", "Row"),
        E({ showIf = function() return S.advanced end })))
    c:Add(UI.Note(c, "Hidden rows leave no gap.", { showIf = function() return not S.advanced end }))

    c = Card(page, 2, "Folding card", "Click the title bar to fold it.", {
        fold = true, store = folds,
        summary = function() return "Size " .. S.size .. " px, opacity " .. UI.pct(S.alpha) end,
    })
    c:Add(UI.Slider(c, "Size", 8, 64, 1, Get("size"), Set("size", "Size"), E({ format = UI.px })))
    c:Add(UI.Slider(c, "Opacity", 0, 1, 0.05, Get("alpha"), Set("alpha", "Opacity"), E({ format = UI.pct })))

    c = Card(page, 2, "Starts folded", "Folded cards show the subtitle when there is no summary.", {
        fold = true, store = folds, folded = true,
    })
    c:Add(UI.Check(c, "A row", Get("opt"), Set("opt", "Row"), E()))

    c = Card(page, 2, "Whole card on demand")
    c:Add(UI.Switch(c, "Show the card below", Get("showCard"), Set("showCard", "Card"), E()))

    c = Card(page, 2, "Shown on demand", "Hidden cards close the gap in their column.")
    c.showIf = function() return S.showCard end
    c:Add(UI.Check(c, "A row", Get("opt"), Set("opt", "Row"), E()))

    page:Layout()
end

-------------------------------------------------------------------------------
-- Tabs and split
-------------------------------------------------------------------------------
local PROFILES = { "Default", "Healer", "Tank", "PvP", "Leveling", "Raid 40", "Battlegrounds", "Arena" }

local function BuildSplit(container)
    local left, right = UI.Split(container, 220)
    local profSel = 1

    local c = left:Add(1, UI.Card(left.content, "Profiles"))
    c:Add(UI.List(c, E({
        items = function() return PROFILES end,
        label = function(p) return p end,
        selected = function(_, i) return i == profSel end,
        onSelect = function(i, p) profSel = i Log("Profile", p) end,
        rows = 6,
    })))

    c = right:Add(1, UI.Card(right.content, PROFILES[1], "Split: a fixed list on the left, details on the right."))
    texts[#texts + 1] = function() c.title:SetText(PROFILES[profSel]) end

    local tabRow = c:Add(UI.Row(c, 26))
    local tabs = UI.Tabs(tabRow, {
        { "general", "General" }, { "look", "Look" }, { "advanced", "Advanced" },
    }, function(key)
        S.tab = key
        Log("Tab", key)
        UI.RefreshAll()
    end)
    tabs:SetPoint("TOPLEFT")
    tabs:SetPoint("TOPRIGHT")

    local function On(key) return function() return S.tab == key end end
    c:Add(UI.Check(c, "Enable this profile", Get("checkOn"), Set("checkOn", "Enable"), E({ showIf = On("general") })))
    c:Add(UI.Input(c, "Profile name", function() return PROFILES[profSel] end,
        function(v) if v ~= "" then PROFILES[profSel] = v end Log("Name", v) end, E({ showIf = On("general") })))
    c:Add(UI.Slider(c, "Scale", 0.5, 2, 0.05, Get("scale"), Set("scale", "Scale"), E({ format = UI.pct, showIf = On("look") })))
    c:Add(UI.Swatch(c, "Accent color", Get("color"), function() Log("Color", S.color) end, E({ alpha = true, showIf = On("look") })))
    c:Add(UI.Switch(c, "Debug messages", Get("swOff"), Set("swOff", "Debug"), E({ showIf = On("advanced") })))
    c:Add(UI.Buttons(c, { { "Delete profile", function() Log("Confirmed", "Delete profile") end, "danger" } },
        E({ showIf = On("advanced") })))

    left:Layout()
    right:Layout()
    tabs:Select(S.tab)
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------
local STRINGS = {
    en = { confirm = "Click again to confirm", search = "Search...", accept = "Accept", cancel = "Cancel" },
    es = { confirm = "Haz clic otra vez para confirmar", search = "Buscar...", accept = "Aceptar", cancel = "Cancelar" },
}

local function Open()
    if win then
        win:Toggle()
        return
    end
    win = UI.Window({ name = "FlatyGalleryWindow", title = "Flaty Gallery", version = LibStub.minors["LibFlatyUI-1.0"],
        width = 1000, height = 680 })
    win:SetSubtitle("Every LibFlatyUI component and state")
    win:AddHeaderButton("Español", function()
        S.spanish = not S.spanish
        for k, v in pairs(S.spanish and STRINGS.es or STRINGS.en) do UI.strings[k] = v end
        Log("Library texts", S.spanish and "Spanish" or "English")
        UI.RefreshAll()
    end, function() return S.spanish end, "Library texts (confirm, accept, cancel) in Spanish.")
    win:AddHeaderButton("Grey all", function()
        S.greyAll = not S.greyAll
        Log("Grey all", S.greyAll)
        UI.RefreshAll()
    end, function() return S.greyAll end, "Disables every control to compare both states.")

    win:AddSection("Controls")
    win:AddNav("buttons", "Buttons", BuildButtons)
    win:AddNav("toggles", "Toggles", BuildToggles, function() return S.swOn end)
    win:AddNav("values", "Values", BuildValues)
    win:AddNav("text", "Text", BuildText)
    win:AddNav("colors", "Colors", BuildColors)
    win:AddSection("Containers")
    win:AddNav("lists", "Lists", BuildLists)
    win:AddNav("cards", "Cards", BuildCards)
    win:AddNav("split", "Tabs and split", BuildSplit)
    win:Select("buttons")
    win:SetStatus("Change anything: its new value shows here.")
end

SLASH_FLATYGALLERY1 = "/flaty"
SlashCmdList.FLATYGALLERY = Open
