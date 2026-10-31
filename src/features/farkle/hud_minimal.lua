-- Minimalist frontend variant inspired by Squire's Dice / tavern table Farkle.
-- Preserves all game rules, combinations, medals, contracts and physics.
local R = require('src.gameplay.farkle.rules')
local Medals = require('src.gameplay.farkle.medals')
local D = require('src.features.farkle.dice')
local H = require('src.features.farkle.hud_model')
local Res = require('src.core.resolution_manager')
local Presentation = require('src.features.farkle.presentation')

local M = {}

-- Expanded visual roll area: taller and wider for prominent 3D dice tumbling
M.tray = {x = 40, y = 60, w = 1460, h = 808}

local fonts = {}
local textures = {}
local shelfWood, shelfQuad, shelfWidth
local ink = {0.12, 0.075, 0.035, 1}
local cream = {0.96, 0.90, 0.76, 1}
local muted_cream = {0.78, 0.72, 0.60, 1}
local gold = {0.90, 0.75, 0.35, 1}
local green = {0.20, 0.58, 0.32, 1}
local red = {0.78, 0.18, 0.14, 1}

local function get_font(size)
 local g=love.graphics
 if not fonts[size] then fonts[size]=g.newFont('resources/font/IMFeENsc28P.ttf',size) end
 return fonts[size]
end
local function txt(value,x,y,w,size,color,align)
 local g=love.graphics
 g.setFont(get_font(size))
 g.setColor(unpack(color or ink))
 g.printf(tostring(value),x,y,w,align or 'left')
end
local function get_texture(name)
 local g=love.graphics
 if not textures[name] then
  local image=g.newImage('resources/textures/'..name..'.png')
  image:setFilter('linear','linear')
  textures[name]=image
 end
 return textures[name]
end

-- Continuous wooden surface background: one expansive table
local function draw_surface()
    local g = love.graphics
    local wood = get_texture('wood')
    if wood then
        g.setColor(0.68, 0.52, 0.35, 1)
        g.draw(wood, 0, 0, 0, 1920 / wood:getWidth(), 1080 / wood:getHeight())
    else
        g.setColor(0.24, 0.14, 0.08, 1)
        g.rectangle('fill', 0, 0, 1920, 1080)
    end

    -- Warm subtle vignette across the tabletop
    g.setColor(0.84, 0.70, 0.46, 0.24)
    g.setLineWidth(2)
    g.rectangle('line', 26, 14, 1868, 1050, 6)
    g.setColor(0.17, 0.10, 0.05, 0.45)
    g.line(42, 82, 1878, 82)
    g.line(42, 910, 1478, 910)
    g.line(1492, 104, 1492, 1034)
    g.setColor(0.87, 0.72, 0.43, 0.45)
    for _, x in ipairs({43, 1478, 1877}) do
        for _, y in ipairs({95, 1043}) do
            g.circle('fill', x, y, 3)
        end
    end
    g.setLineWidth(1)
end

-- Subordinate manuscript on the right margin
local function draw_manuscript(u, s, x, y, w, h)
    local c = R.contracts[s.stage]
    require('src.features.farkle.folio_view').draw(s, u.presentation, x, y, w, h, txt, c.target)

    -- Register inspect folio button covering the manuscript
    u.buttons['folio'] = {
        x = x,
        y = y,
        w = w,
        h = h,
        enabled = s.phase ~= 'rolling',
        fn = function() u.modal = 'folio' end,
        label = 'Inspect folio [F]'
    }

end

-- Tactile action button
local function action_button(u, id, label, sublabel, x, y, w, h, on, fn, style)
    local g = love.graphics
    local bg_color
    local border_color = {0.35, 0.24, 0.14, 1}
    local text_color = ink

    if not on then
        bg_color = {0.38, 0.32, 0.26, 0.70}
        text_color = {0.62, 0.58, 0.52, 1}
    elseif style == 'primary' then
        bg_color = {0.18, 0.38, 0.24, 1}
        border_color = {0.84, 0.68, 0.32, 1}
        text_color = cream
    elseif style == 'amber' then
        bg_color = {0.58, 0.38, 0.16, 1}
        border_color = {0.92, 0.78, 0.42, 1}
        text_color = cream
    elseif style == 'danger' then
        bg_color = {0.52, 0.16, 0.14, 1}
        border_color = {0.85, 0.45, 0.35, 1}
        text_color = cream
    else
        bg_color = {0.88, 0.81, 0.66, 1}
        border_color = {0.50, 0.36, 0.22, 1}
        text_color = ink
    end

    -- Button shadow
    g.setColor(0.04, 0.02, 0.01, on and 0.40 or 0.20)
    g.rectangle('fill', x + 3, y + 4, w, h, 6)

    -- Button body
    g.setColor(unpack(bg_color))
    g.rectangle('fill', x, y, w, h, 6)

    -- Border
    g.setColor(unpack(border_color))
    g.setLineWidth(on and 2.5 or 1.5)
    g.rectangle('line', x, y, w, h, 6)
    g.setLineWidth(1)

    -- Label and sublabel
    local f_label = get_font(23)
    if sublabel and sublabel ~= '' then
        local lh = f_label:getHeight()
        txt(label, x + 12, y + (h - lh - 18) / 2, w - 24, 23, text_color, 'center')
        txt(sublabel, x + 12, y + (h - lh - 18) / 2 + lh + 2, w - 24, 15, on and (style == 'primary' and {0.85, 0.80, 0.65, 1} or {0.95, 0.88, 0.72, 1}) or {0.60, 0.55, 0.48, 1}, 'center')
    else
        local lh = f_label:getHeight()
        txt(label, x + 12, y + (h - lh) / 2, w - 24, 23, text_color, 'center')
    end

    u.buttons[id] = {x = x, y = y, w = w, h = h, enabled = on, fn = fn, label = label}
end

-- Compact header button
local function mini_button(u, id, label, x, y, w, h, on, fn)
    local g = love.graphics
    g.setColor(0.08, 0.045, 0.02, on and 0.55 or 0.30)
    g.rectangle('fill', x, y, w, h, 4)
    g.setColor(0.58, 0.42, 0.24, on and 0.8 or 0.4)
    g.rectangle('line', x, y, w, h, 4)
    txt(label, x + 4, y + (h - 18) / 2, w - 8, 17, on and cream or muted_cream, 'center')
    u.buttons[id] = {x = x, y = y, w = w, h = h, enabled = on, fn = fn, label = label}
end

-- Top bar showing the 4 essential metrics immediately visible
local function draw_top_bar(u, s)
    local g = love.graphics
    local c = R.contracts[s.stage]

    -- Subtle dark wood ribbon
    g.setColor(0.11, 0.08, 0.05, 0.35)
    g.line(50, 76, 1870, 76)

    -- Commission name
    txt('COMMISSIONE ' .. s.stage .. ' / 3 : ' .. c.name, 68, 23, 420, 20, cream)
    txt(c.condition, 68, 46, 420, 15, muted_cream)

    -- Divider
    g.setColor(0.52, 0.36, 0.20, 0.5)
    g.line(500, 22, 500, 68)

    -- 1. OBIETTIVO (Target)
    txt('OBIETTIVO', 530, 22, 180, 14, muted_cream)
    txt(c.target .. ' pt', 530, 39, 180, 27, gold)

    -- 2. PUNTI ASSICURATI (Banked)
    txt('ASSICURATI', 750, 22, 190, 14, muted_cream)
    txt(s.bank .. ' pt', 750, 39, 190, 27, {0.72, 0.88, 0.69, 1})

    -- 3. PUNTI A RISCHIO (Pot)
    txt('A RISCHIO', 980, 22, 190, 14, muted_cream)
    txt(s.pot .. ' pt', 980, 39, 190, 27, s.pot > 0 and gold or muted_cream)

    -- 4. TURNI DISPONIBILI (Turns left)
    local turns_left = math.max(0, c.limit - s.turn + ((s.phase == 'ended' or H.commission_closed(s)) and 0 or 1))
    txt('TURNI', 1210, 22, 130, 14, muted_cream)
    txt(turns_left, 1210, 39, 130, 27, turns_left <= 1 and red or cream)

    -- Header actions: Rules [?] and Menu [Esc]; alternate HUD removed.
    mini_button(u, 'help', 'Regole [?]', 1420, 24, 120, 42, s.phase ~= 'rolling', function() u.modal = 'help' end)
    mini_button(u, 'runmenu', 'Menu [Esc]', 1555, 24, 125, 42, s.phase ~= 'rolling', function() u.modal = 'run' end)
end

-- Physical front canalina with 6 carved niches integrated into the tray rim
local function draw_upper_shelf(u, s)
    local projection = u.trayProjection
    if not projection or not projection.front then return end

    local g = love.graphics
    local ax, ay, bx, by = 206, 350, 1336, 350
    local depth = 92
    u.upperShelf = {x = ax, y = ay - depth, w = bx - ax, h = depth + 18}

    local isBook = require('src.features.farkle.tray_workshop').current == 'book'
    if isBook then
        -- The six confirmed-dice positions become an inset parchment register
        -- along the codex's upper edge, not a separate walnut collecting tray.
        g.setColor(0.035, 0.020, 0.010, 0.46)
        g.polygon('fill', ax - 12, ay - depth + 10, bx + 12, by - depth + 10,
            bx + 15, by + 17, ax - 15, ay + 17)
        g.setColor(0.24, 0.115, 0.070, 1)
        g.polygon('fill', ax - 13, ay - depth + 5, bx + 13, by - depth + 5,
            bx + 12, by + 8, ax - 12, ay + 8)
        g.setColor(0.81, 0.725, 0.56, 1)
        g.polygon('fill', ax - 5, ay - depth, bx + 5, by - depth,
            bx + 5, by - 1, ax - 5, ay - 1)
        g.setColor(0.91, 0.83, 0.66, 0.74)
        g.rectangle('fill', ax + 3, ay - depth + 5, bx - ax - 6, 12)
        g.setColor(0.44, 0.31, 0.17, 0.34)
        g.setLineWidth(1)
        g.line(ax + 8, ay - depth + 22, bx - 8, by - depth + 22)
        g.line(ax + 8, ay - 10, bx - 8, by - 10)
        for j = 1, 4 do
            g.setColor(0.36, 0.25, 0.14, 0.15)
            g.line(ax + 8, ay + j * 2, bx - 8, by + j * 2)
        end
    else
        -- Original tray shelf retained only for the F8 visual comparisons.
        g.setColor(0.06, 0.035, 0.018, 0.55)
        g.polygon('fill', ax - 12, ay + 10, bx + 12, by + 10, bx + 6, by + 26, ax - 6, ay + 26)
        g.setColor(0.20, 0.11, 0.06, 1)
        g.polygon('fill', ax - 12, ay - 4, bx + 12, by - 4, bx + 5, by + 18, ax - 5, ay + 18)
        g.setColor(0.36, 0.23, 0.13, 1)
        g.polygon('fill', ax - 12, ay - depth + 8, ax, ay - depth, bx, by - depth, bx + 12, by - depth + 8, bx + 12, by - 4, bx, by + 2, ax, ay + 2, ax - 12, ay - 4)

        shelfWood = shelfWood or get_texture('tray/walnut') or get_texture('wood')
        if shelfWood then
            shelfWood:setFilter('linear', 'linear')
            local width = bx - ax
            if shelfWidth ~= width then
                shelfWidth = width
                shelfQuad = g.newQuad(0, 1200, math.min(4096, width * 3), depth * 3, 4096, 4096)
            end
            g.setColor(1, 0.94, 0.86, 0.95)
            g.draw(shelfWood, shelfQuad, ax, ay - depth, 0, 1 / 3, 1 / 3)
        end
        g.setColor(0.58, 0.40, 0.22, 1)
        g.line(ax, ay - depth, bx, by - depth)
        g.setColor(0.14, 0.07, 0.035, 0.35)
        for j = 1, 4 do
            g.line(ax + 8, ay + 2 + j * 2, bx - 8, by + 2 + j * 2)
        end
    end

    -- 6 Physical niches (nicchie) carved into the canalina
    local p = u.presentation
    local scale = (projection.scale or 1) / Res.get_scale()
    local contributors = p and Presentation.contributing_dice(p) or {}

    for i = 1, 6 do
        local t = (i - 0.5) / 6
        local nx = ax + (bx - ax) * t
        local ny = ay + (by - ay) * t - depth / 2
        local niche_w = math.min(50, (bx - ax) / 13)

        if isBook then
            -- A legible warm-ink seal under each accepted die.
            g.setColor(0.22, 0.125, 0.075, 0.14)
            g.ellipse('fill', nx, ny + 2, niche_w, 17)
            g.setColor(0.96, 0.88, 0.73, 0.68)
            g.ellipse('fill', nx, ny - 1, niche_w - 3, 13)
            g.setColor(0.43, 0.26, 0.12, 0.57)
            g.ellipse('line', nx, ny - 1, niche_w - 3, 13)
        else
            g.setColor(0.05, 0.03, 0.015, 0.60)
            g.ellipse('fill', nx, ny + 3, niche_w, 13)
            g.setColor(0.14, 0.20, 0.15, 0.85)
            g.ellipse('fill', nx, ny + 1, niche_w - 4, 10)
            g.setColor(0.68, 0.52, 0.30, 0.35)
            g.ellipse('line', nx, ny + 2, niche_w, 13)
        end

        -- If die is NOT held: faint carved socket number
        if not s.used[i] then
            txt(i, nx - 16, ny - 8, 32, 16, isBook and {0.38, 0.22, 0.12, 0.74} or {0.52, 0.38, 0.24, 0.50}, 'center')
        end
    end

    -- Render held dice physically sitting in their niches
    for i = 1, 6 do
        if s.used[i] then
            local e = p and p.shelf and p.shelf[i]
            local slot = (i - 0.5) / 6
            local x = ax + (bx - ax) * slot
            local y = ay + (by - ay) * slot - depth / 2 - 16

            if e and e.origin then
                local progress = math.min(1, e.age / Presentation.transfer_duration)
                local t = 1 - (1 - progress)^3
                if t < 1 then
                    local ox, oy = Res.to_virtual(e.origin.x, e.origin.y)
                    x = ox + (x - ox) * t
                    y = oy + (y - oy) * t - 22 * math.sin(math.pi * progress)
                end
            end

            -- Highlight ring on contributing scoring die
            if contributors[i] then
                g.setColor(0.96, 0.78, 0.35, 0.90)
                g.setLineWidth(2.5)
                g.ellipse('line', x, y + 17, 36, 13)
                g.setLineWidth(1)
            end

            -- g3d only: accepted physical orientation captured once.
            if e and dice and dice[i] then
                if e.g3dPortrait==nil then
                    e.g3dPortrait=require('src.engine3d.g3d_portrait')
                        .capture(dice[i],projection)
                end
                g.push('all')
                g.setBlendMode('alpha','premultiplied')
                g.setColor(1,1,1,1)
                local portraitScale=.68
                g.draw(e.g3dPortrait,x-56*portraitScale,
                    y-56*portraitScale,0,portraitScale,portraitScale)
                g.pop()
            end

            -- Value pill badge above the niche
            if s.hand[i] then
                local val = s.hand[i]
                local slot_x = ax + (bx - ax) * slot
                txt(i .. ' : ' .. val, slot_x - 42, ay - 19, 84, 16, isBook and ink or cream, 'center')
                if e then
                    txt('Tiro ' .. e.roll, slot_x - 42, ay + 6, 84, 13, isBook and {0.36,0.23,0.14,1} or muted_cream, 'center')
                end
            end
        end
    end

    -- Decorative brass corner pins on the canalina ends
    for _, t in ipairs({0.015, 0.985}) do
        local px = ax + (bx - ax) * t
        local py = ay + (by - ay) * t
        g.setColor(0.55, 0.42, 0.22, 1)
        g.circle('fill', px, py - 6, 4)
        g.setColor(0.20, 0.12, 0.06, 1)
        g.line(px - 2, py - 6, px + 2, py - 6)
    end
end

-- Contextual status message above action buttons
local function get_contextual_message(u, s)
    if u.manualRoll then
        local remaining=u.manualRoll.count
        return u.mouseThrow and 'Dado in mano: muovilo per ruotarlo, rilascia per lanciarlo (Esc annulla la presa).'
          or ('Lancia i dadi uno alla volta con il tasto destro: '..remaining..' ancora da lanciare.')
    end
    if u.physicalFailure then return u.physicalFailure end
    if s.phase == 'rolling' then return 'I dadi rotolano sulla pagina…' end
    if s.phase == 'fresh' then return 'Lancia tutti i 6 dadi per iniziare il tuo turno.' end
    if s.phase == 'lost' then return 'Commissione fallita: turni esauriti.' end
    if s.phase == 'won' then return 'Tutte le 3 commissioni sono state consegnate!' end
    if s.phase == 'advance' then return 'Commissione completata con successo! Avanza alla prossima.' end
    if s.phase == 'ended' then
        if u.lastLoss ~= nil then
            return u.lastLoss > 0 and ('FARKLE · ' .. u.lastLoss .. ' punti a rischio perduti.') or 'FARKLE · Turno concluso senza punti.'
        end
        return 'Punti assicurati nel manoscritto: +' .. (u.lastBank or 0) .. ' pt!'
    end
    if s.phase == 'rescue' then return 'FARKLE! Usa la medaglia Correttore per salvare il turno.' end
    if next(s.selected) then
        local pts = R.selection(s)
        if pts then
            local text = H.selection_text(s) or ''
            return 'Selezione: ' .. text .. ' (+ ' .. pts .. ' pt) · Conferma con Accantona.'
        else
            return 'Selezione non valida: ogni dado selezionato deve fare punteggio.'
        end
    end
    if s.hot then
        local canBank, _, minBank = R.bank_status(s)
        return canBank and 'DADI CALDI! Rilancia tutti i 6 dadi oppure incassa i punti a rischio.' or ('DADI CALDI! Rilancia per raggiungere la soglia di incasso (' .. minBank .. ' pt).')
    end
    if s.scored then
        local canBank, _, _, reason = R.bank_status(s)
        return canBank and 'Puoi rilanciare i dadi liberi oppure incassare i punti.' or reason
    end
    return 'Seleziona i dadi con punteggio direttamente nel vassoio (o tasti 1–6).'
end

-- Main interaction buttons: Lancia/Rilancia vs Incassa
local function draw_action_controls(u, s)
    local canBank, total, minimum = R.bank_status(s)
    local pts = R.selection(s)
    local selected_any = next(s.selected) ~= nil

    -- Status indicator bar above buttons
    local msg = get_contextual_message(u, s)
    local is_farkle = s.phase == 'lost' or (s.phase == 'ended' and u.lastLoss ~= nil)
    txt(msg, 60, 928, 1420, 20, is_farkle and red or (s.hot and gold or cream), 'center')

    local b1_x, b1_y, b1_w, b1_h = 240, 958, 480, 74
    local b2_x, b2_y, b2_w, b2_h = 760, 958, 480, 74

    if u.physicalFailure then
        action_button(u, 'retryphysical', 'Riprova Lancio Fisico', 'Problema di simulazione', b1_x, b1_y, 1000, b1_h, true, function() u:retry_physical() end, 'primary')
    elseif s.phase == 'rescue' then
        action_button(u, 'rescue', 'Usa Medaglia Correttore [M]', 'Rilancia gli stessi dadi', b1_x, b1_y, b1_w, b1_h, true, function() u:request(true) end, 'primary')
        action_button(u, 'fail', 'Accetta Farkle [Esc]', 'Perdi i punti del turno', b2_x, b2_y, b2_w, b2_h, true, function() u:act('accept_bust', function() return R.fail(s) end) end, 'danger')
    elseif H.commission_closed(s) then
        if s.phase == 'advance' then
            action_button(u, 'next', 'Prossima Commissione [N]', 'Continua l\'opera', b1_x, b1_y, 1000, b1_h, true, function() u:act('next', function() return R.advance(s) end) end, 'primary')
        end
    elseif s.phase == 'ended' then
        action_button(u, 'next', 'Prossimo Turno [N / Spazio]', 'Continua a tirare', b1_x, b1_y, 1000, b1_h, true, function() u:act('next', function() return R.next_turn(s) end) end, 'primary')
    else
        -- Active turn states
        if selected_any then
            -- Dice selected: unequivocal confirmation step
            local n = H.selected_count(s)
            local take_label = pts and ('Accantona ' .. n .. (n == 1 and ' dado' or ' dadi') .. ' · +' .. pts .. ' pt [A]') or 'Selezione non valida'
            local take_sub = pts and 'Sposta nella canalina e sblocca il rilancio' or 'Tutti i dadi scelti devono fare punto'
            action_button(u, 'take', take_label, take_sub, b1_x, b1_y, b1_w, b1_h, pts ~= nil, function() u:act('take', function() return R.take(s) end) end, pts and 'amber' or nil)
        else
            -- No dice currently selected
            local can_roll = R.can_roll(s)
            local roll_label = s.hot and 'Dadi Caldi! Rilancia tutti [Spazio]' or (s.phase == 'fresh' and 'Lancia i Dadi [Spazio]' or ('Rilancia ' .. R.count_free(s) .. ' Dadi [Spazio]'))
            local roll_sub = can_roll and 'Tasto destro: afferra, ruota e lancia ciascun dado' or 'Seleziona prima i dadi con punteggio'
            action_button(u, 'roll', roll_label, roll_sub, b1_x, b1_y, b1_w, b1_h, can_roll, function() u:request() end, can_roll and 'primary' or nil)
        end

        -- Second action: INCASSA (Bank)
        local bank_label = 'Incassa ' .. total .. ' pt [Invio]'
        local bank_sub = canBank and 'Metti al sicuro i punti nel manoscritto' or (total < minimum and ('Soglia minima di incasso: ' .. minimum .. ' pt') or 'Accantona dadi con punteggio per incassare')
        action_button(u, 'bank', bank_label, bank_sub, b2_x, b2_y, b2_w, b2_h, canBank, function() u:act('bank', function() return R.bank_turn(s) end) end, canBank and 'primary' or nil)
    end
end

-- Secondary consultable widgets (Medals, scoring options)
local function draw_secondary_controls(u, s)
    -- Options button (on-demand drawer)
    if s.phase == 'ready' then
        local choices = R.options(s)
        if #choices > 0 then
            mini_button(u, 'choices', 'Scelte (' .. #choices .. ')', 1524, 666, 340, 48, true, function() u.choicePage = 1; u.modal = 'choices' end)
        end
    end

    -- Medal badge / usage
    if s.medal ~= 'none' then
        local d = Medals.get(s.medal)
        local uses = Medals.remaining(s)
        local label = (d and d.label or 'Correttore') .. ' · ' .. uses .. (uses == 1 and ' uso' or ' usi')
        mini_button(u, 'medaluse', label, 1524, 730, 340, 48, d ~= nil and s.phase ~= 'rolling' and not H.commission_closed(s), function() u.medalDice = {}; u.modal = 'medaluse' end)
    end

    -- Build modifier note
    if s.build ~= 'normal' then
        local b_note = s.build == 'engraved' and 'Dado 1: faccia 2 sostituita da 1' or 'Dado 1: bilanciato verso l\'1'
        txt(b_note, 1524, 800, 340, 16, gold, 'center')
    end
end

-- Main draw function for the minimal HUD variant
function M.draw(u)
    local s = u.game
    if not s then return end

    u.buttons = {}
    Res.begin_ui()

    -- Continuous wooden table surface
    draw_surface()

    -- Top bar with 4 essential metrics
    draw_top_bar(u, s)

    -- Subordinate manuscript on the right margin
    draw_manuscript(u, s, 1524, 114, 340, 518)

    -- Primary contextual action controls (Lancia / Rilancia vs Incassa)
    if not H.reward_active(s) then draw_action_controls(u, s) end

    -- Secondary consultable controls
    if not H.reward_active(s) then draw_secondary_controls(u, s) else u.buttons = {} end

    Res.end_ui()
end

-- 3D Dice Selection Overlay and Front Canalina
function M.overlay(u, hits, options)
    u.hits = hits
    local g = love.graphics
    local s = u.game
    if not s then return end

    -- UI v2 supplies its own non-invasive indicators; keep the old
    -- presentation intact for the default HUD and retain shared shelf/modals.
    if not (options and options.hideIndicators) then
    local eligible = H.eligible(s)

    -- Draw the hand trajectory while the actual rigid body is being held.
    -- Its physical vertices follow and rotate with the cursor, in g3d and F9.
    if u.mouseThrow then
        local gesture=u.mouseThrow
        local ax,ay=Res.to_virtual(gesture.x0,gesture.y0)
        local bx,by=Res.to_virtual(gesture.x,gesture.y)
        Res.begin_ui()
        g.setColor(1,.82,.42,.8)
        g.setLineWidth(2)
        g.line(ax,ay,bx,by)
        g.circle('line',bx,by,13)
        g.setLineWidth(1)
        Res.end_ui()
    end

    -- Minimal on-screen marquee in native screen coordinates, independent
    -- of HUD scaling and of the game's scoring-die selection.
    local Marquee=require('src.features.farkle.marquee_selection')
    if u.marquee and Marquee.dragged(u.marquee) then
        local rect=Marquee.rectangle(u.marquee)
        g.push('all')
        g.setColor(.56,.85,.90,.10)
        g.rectangle('fill',rect.x,rect.y,rect.w,rect.h)
        g.setColor(.56,.85,.90,.88)
        g.setLineWidth(1.5)
        g.rectangle('line',rect.x,rect.y,rect.w,rect.h)
        g.pop()
    end
    local groupCount=Marquee.count(u.dragSelected)
    if groupCount>0 then
        g.push('all')
        g.setColor(.56,.85,.90,.9)
        g.setLineWidth(2.3)
        for _,hit in ipairs(hits or {}) do
            if u.dragSelected[hit.index or hit.roll_index] then
                g.circle('line',hit.x,hit.y,(hit.r or 24)+9)
            end
        end
        g.pop()
    end

    -- Highlight circles on 3D dice in the tray
    for _, h in ipairs(hits or {}) do
        local i = h.index or h.roll_index
        if i and (s.selected[i] or eligible[i]) then
            if s.selected[i] then
                -- Selected die: crisp vibrant golden-amber ring
                g.setColor(1, 0.82, 0.30, 1)
                g.setLineWidth(3.5)
                g.circle('line', h.x, h.y, (h.r or 25) + 5)
            elseif eligible[i] then
                -- Scoring eligible die: soft warm glow
                g.setColor(0.96, 0.85, 0.55, 0.45)
                g.setLineWidth(1.8)
                g.circle('line', h.x, h.y, (h.r or 25) + 4)
            end
        end
    end
    g.setLineWidth(1)
    end -- only legacy HUD draws full dice selection rings

    -- Physical front canalina with 6 carved niches for held dice
    Res.begin_ui()
    draw_upper_shelf(u, s)
    Res.end_ui()

    -- Delegate modals (help, folio, choices, run, reward, etc.) to the existing modal renderer
    local Hud = require('src.features.farkle.hud')
    if H.reward_active(s) or u.modal then
        Hud.overlay(u, hits)
    end
end

return M
