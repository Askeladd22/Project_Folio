-- Project Folio laboratory: canonical six-D6 Farkle against P4ND0RA.
-- An experimental bridge, NOT a reproduction of Star Realms player rules.
local Engine = require("engine")
local lg = love.graphics

local W, H = 1280, 800
local colors = {
    bg = {0.080, 0.092, 0.115},
    panel = {0.130, 0.151, 0.185},
    panel2 = {0.171, 0.196, 0.235},
    text = {0.935, 0.950, 0.958},
    muted = {0.660, 0.715, 0.775},
    gold = {0.954, 0.744, 0.365},
    blue = {0.390, 0.690, 0.950},
    green = {0.407, 0.811, 0.622},
    red = {0.952, 0.430, 0.425},
    border = {0.285, 0.335, 0.395},
}

local state = {
    screen = "setup", players = 1, difficulty = "Normal", seed = 101,
    game = nil, selected = 1, buttons = {}, fonts = {}, error = nil,
    -- Six-D6 Farkle is the only playable player mode.
    scale = 1, ox = 0, oy = 0, detailed = false,
}
local difficulty_order = {"Easy", "Normal", "Hard", "Nightmare"}

local function use(name) lg.setColor(colors[name] or colors.text) end

local function text(content, x, y, font, color, width, alignment)
    lg.setFont(state.fonts[font or "body"])
    use(color or "text")
    if width then
        lg.printf(tostring(content), x, y, width, alignment or "left")
    else
        lg.print(tostring(content), x, y)
    end
end

local function panel(x,y,w,h)
    use("panel"); lg.rectangle("fill",x,y,w,h,10,10)
    use("border"); lg.setLineWidth(1); lg.rectangle("line",x,y,w,h,10,10)
end

local function bar(x,y,w,h,fraction,color)
    use("panel2"); lg.rectangle("fill",x,y,w,h,5,5)
    use(color); lg.rectangle("fill",x,y,math.max(0,w*math.min(1,fraction)),h,5,5)
end

local function button(label,x,y,w,h,fn,enabled,accent)
    local on = enabled ~= false
    local style = (accent and colors[accent]) or colors.panel2
    lg.setColor(style[1],style[2],style[3],on and 1 or .32)
    lg.rectangle("fill",x,y,w,h,7,7)
    use(on and "text" or "muted")
    lg.setFont(state.fonts.button)
    lg.printf(label,x+4,y+(h-18)/2,w-8,"center")
    if fn and on then
        state.buttons[#state.buttons+1]={x=x,y=y,w=w,h=h,fn=fn}
    end
end

local function attempt(fn)
    local ok,err=pcall(fn)
    if ok then state.error=nil else
        state.error=tostring(err)
    end
end

local function start()
    state.game=Engine.new({
        players=state.players,difficulty=state.difficulty,seed=state.seed,
        farkle=true,
    })
    state.selected=1
    state.screen="game"
    state.error=nil
end

local function current()
    local g=state.game
    return g and g.players[state.selected]
end

local function action(fn)
    return function() attempt(fn) end
end

local function draw_setup()
    text("PROJECT FOLIO / P4ND0RA",48,45,"headline","gold")
    text("Sei dadi Farkle contro il sacchetto di P4ND0RA",50,105,"sub","muted")
    panel(170,175,940,505)
    text("Configura la sfida",216,205,"title")
    text("Difficolta' del boss",216,270,"sub","muted")
    for i,name in ipairs(difficulty_order) do
        button(name,216+(i-1)*207,307,186,52,
            function() state.difficulty=name end,true,
            name==state.difficulty and "blue" or nil)
    end
    text("Giocatori Farkle",216,392,"sub","muted")
    button("-",218,432,55,50,function()
        state.players=math.max(1,state.players-1)
    end,state.players>1)
    text(state.players,296,443,"title")
    button("+",344,432,55,50,function()
        state.players=math.min(4,state.players+1)
    end,state.players<4)
    text("Seed",493,392,"sub","muted")
    button("-",496,432,55,50,function()
        state.seed=math.max(1,state.seed-1)
    end,true)
    text(state.seed,567,443,"title")
    button("+",674,432,55,50,function()state.seed=state.seed+1 end,true)
    button("Gioca con sei dadi [Invio]",216,528,497,65,start,true,"green")
    text("Incasso: ogni 5 punti Farkle = 1 Combat.",216,610,"small","gold")
    text("EMP: blocca temporaneamente dadi nel lancio iniziale successivo.",
        216,633,"small","muted",830)
    text("Adattamento sperimentale; non e' Star Realms 1:1.",
        216,656,"small","muted",830)
end

local function stat(label,value,x,y,width,color)
    text(label,x,y,"small","muted")
    text(value,x,y+22,"title",color or "text",width)
end

local function draw_boss()
    local g=state.game
    panel(28,106,758,202)
    text("P4ND0RA  ·  "..g.difficulty,48,126,"title","gold")
    text(g.hp.." / "..g.stats.max_health.." HP",596,128,"title","text",166,"right")
    bar(48,174,708,13,g.hp/g.stats.max_health,"red")
    stat("Scudi",g.shield,50,205,98,"blue")
    stat("Pesca",g.draw_power,160,205,98,"gold")
    stat("Attacco",g.stats.attack,270,205,98)
    stat("Riparazione",g.stats.repair,380,205,98)
    stat("Difesa",g.stats.shield,505,205,98)
    stat("Upgrade",g.upgrades,638,205,100)
end

local function draw_bag()
    local g=state.game
    panel(804,106,447,202)
    text("Sacchetto di azioni",827,124,"title")
    text("Rimasti "..#g.bag.."   /   Scartati "..#g.discard..
         "   /   In risoluzione "..#g.drawn,828,163,"small","muted")
    local present = {}
    for _, token in ipairs(g.bag) do
        present[token] = (present[token] or 0) + 1
    end
    local names = {
        attack="Attacco",defense="Scudo",repairs="Ripara",
        oneStar="Missili",twoStar="EMP",threeStar="CQC",
        special="Nucleare",upgrade="Upgrade",
    }
    for i,token in ipairs(Engine.TOKEN_ORDER) do
        local col=(i-1)%4
        local row=math.floor((i-1)/4)
        local x=825+col*102
        local y=204+row*42
        text(names[token],x,y,"small",token=="special" and "gold" or "text")
        text((present[token] or 0).."/"..Engine.TOKENS[token],
            x,y+17,"small","muted")
    end
end

local function player_card(p,i,x,y,w)
    local g=state.game
    local selected=state.selected==i
    use(selected and "blue" or "panel2")
    lg.rectangle("fill",x,y,w,89,6,6)
    text(p.alive and p.color or "ELIMINATO",x+8,y+6,"sub",
         p.alive and "text" or "red")
    text("Resistenza "..p.authority,x+8,y+32,"small",
         p.authority<=10 and "red" or "text")
    local finished=g.farkle:is_finished(i)
    text(not p.alive and "Fuori gioco" or finished and "Turno concluso" or
         "Farkle: in corso",x+8,y+62,"small","muted")
    state.buttons[#state.buttons+1]={x=x,y=y,w=w,h=89,
        fn=function()state.selected=i end}
end

local function draw_players()
    local g=state.game
    local p=current()
    local f=g.farkle
    local turn=f.states[state.selected]
    panel(28,326,758,278)
    text("Incisore · sei dadi Farkle",49,345,"title")
    for i,pl in ipairs(g.players) do
        player_card(pl,i,49+(i-1)*181,385,166)
    end
    local selectable=g.phase=="players" and p.alive and
        not f:is_finished(state.selected) and turn.phase=="ready"
    for id=1,6 do
        local x=49+(id-1)*118
        local y=487
        local selected=not not turn.selected[id]
        local spent=not not turn.used[id]
        local locked=turn.penalty>0 and id<=turn.penalty
        use(locked and "red" or selected and "blue" or
            spent and "gold" or "panel2")
        lg.rectangle("fill",x,y,108,64,7,7)
        text(turn.hand[id] or "-",x+1,y+10,"title","text",106,"center")
        text(locked and "EMP" or spent and "Accant." or
             selected and "Scelto" or "Dado "..id,
             x+1,y+41,"small","text",106,"center")
        if selectable and not spent and turn.hand[id] then
            state.buttons[#state.buttons+1]={x=x,y=y,w=108,h=64,
                fn=action(function()g:toggle_farkle(state.selected,id)end)}
        end
    end
    local selection_points=select(1,f.Rules.selection(turn)) or 0
    local potential=turn.pot+selection_points
    local prompt
    if g.phase=="finished" then prompt="Incontro concluso."
    elseif g.phase=="boss" then
        prompt="Turno di P4ND0RA: attendi la risoluzione dei token."
    elseif f:is_finished(state.selected) then
        local result=f:result(state.selected)
        prompt=result.farkle and "FARKLE: 0 punti. Attendi il boss." or
            ("Incassati "..result.points.." punti. Attendi il boss.")
    else prompt=turn.last end
    text("Provvisorio "..potential.." pt  ·  Selezione "..selection_points..
         " pt  ·  Dadi liberi "..f.Rules.count_free(turn),
         49,559,"small","gold",705)
    text(prompt,49,579,"small","muted",705)
end

local function draw_events()
    local g=state.game
    panel(804,326,447,278)
    text("Cronaca delle azioni",827,345,"title")
    local n=#g.events
    local max_rows=9
    for i=math.max(1,n-max_rows+1),n do
        local index=i-math.max(1,n-max_rows+1)
        local line=g.events[i]
        if #line>59 then line=line:sub(1,56).."..." end
        text(line,827,393+index*22,"small",i==n and "gold" or "muted")
    end
end

local function draw_controls()
    local g=state.game
    panel(28,619,1223,149)
    if g.result then
        text(g.result=="players_win" and "VITTORIA DELL'INCISORE" or
             "P4ND0RA HA VINTO",49,642,"title",
             g.result=="players_win" and "green" or "red")
        button("Ricomincia [R]",49,697,247,47,start,true,"blue")
        button("Impostazioni [Esc]",308,697,214,47,
            function()state.screen="setup"end,true)
        return
    end
    if g.pending then
        local index=g.pending.targets[g.pending.current]
        local p=g.players[index]
        text("MISSILI: "..p.color.." perde "..g.stats.missile..
             " Resistenza",49,641,"title","gold")
        button("Subisci l'attacco [A]",49,691,300,52,
            action(function()g:resolve_missile("authority")end),true,"red")
        return
    end
    if g.phase=="players" then
        local f=g.farkle
        local turn=f.states[state.selected]
        local alive=current().alive
        local finished=f:is_finished(state.selected)
        local bankable,total=f:can_bank(state.selected)
        local can_roll=alive and not finished and f.Rules.can_roll(turn)
        local selected=alive and not finished and
            f.Rules.selection_option(turn)~=nil
        local all_done=true
        for i,p in ipairs(g.players) do
            if p.alive and not f:is_finished(i) then all_done=false end
        end
        text("FASE FARKLE · accantona, rischia o incassa",
            49,638,"sub","blue")
        text("Incasso: "..(bankable and total or 0)..
             " pt = "..math.floor((bankable and total or 0)/5)..
             " Combat  |  Neutralizza 20 pt · Scarta 30 pt",
            49,664,"small","muted",1158)
        button("Lancia [Spazio]",49,688,165,48,
            action(function()g:roll_farkle(state.selected)end),can_roll,"blue")
        button("Accantona [A]",223,688,166,48,
            action(function()g:take_farkle(state.selected)end),selected)
        button("Incassa [I]",398,688,175,48,
            action(function()g:bank_farkle(state.selected,"attack")end),
            alive and bankable,"green")
        button("Neutralizza",582,688,161,48,
            action(function()g:bank_farkle(state.selected,"blank")end),
            alive and bankable and total>=20 and
            g.blank_next<math.min(8,g.draw_power))
        button("Scarta token",752,688,152,48,
            action(function()g:bank_farkle(state.selected,"discard")end),
            alive and bankable and total>=30 and #g.bag>0)
        button("Fase boss [Invio]",913,688,317,48,
            action(function()g:begin_boss_turn()end),all_done,"red")
    else
        local next_action=g.queue[1]
        local stage=next_action and next_action.phase or "end"
        text("FASE P4ND0RA · "..string.upper(stage)..
             " · round "..g.round,49,638,"sub","gold")
        local actions={}
        for _,token in ipairs(g.drawn_actions) do
            actions[#actions+1]=token
        end
        text("Token estratti: "..(#actions>0 and table.concat(actions,", ")
                                or "(nessuno)"),
             49,667,"small","muted",690)
        text("Il boss pesca, esegue abilita', attacca, ripara e migliora.",
            49,709,"small","muted",690)
        button("Risolvi token [Spazio]",780,685,450,51,
            action(function()g:advance()end),true,"gold")
    end
end

local function draw_status()
    local g=state.game
    text("PROJECT FOLIO / FARKLE vs P4ND0RA",29,21,"title","gold")
    text("Round "..g.round.."   ·   seed "..g.seed.."   ·   "..
        g.player_count.." giocatore/i",676,27,"small","muted",560,"right")
    local phase=g.phase=="players" and "TURNO DEI GIOCATORI" or
        (g.phase=="boss" and "TURNO DI P4ND0RA" or "INCONTRO CONCLUSO")
    text(phase,29,68,"sub","blue")
    if g.active_defense_turns>0 then
        text("CQC ATTIVE · danni dimezzati",780,69,"small","gold",455,"right")
    else
        text("Nucleare "..g.special_counter.."/3",780,69,"small","muted",455,"right")
    end
    if state.error then
        use("red"); lg.rectangle("fill",22,775,1236,22,3,3)
        text(state.error,32,778,"small","text",1210)
    end
end

local smoke_frames = 0
local smoke_enabled = os.getenv("P4ND0RA_LAB_SMOKE") == "1"

function love.load()
    lg.setDefaultFilter("linear","linear")
    state.fonts={
        headline=lg.newFont(55),title=lg.newFont(23),sub=lg.newFont(18),
        body=lg.newFont(16),small=lg.newFont(14),button=lg.newFont(15),
    }
    if smoke_enabled then start() end
end

-- Dedicated CI exercises Farkle roll, bank and boss without GUI clicks.
function love.update(_dt)
    if not smoke_enabled then return end
    smoke_frames=smoke_frames+1
    local g=state.game
    if smoke_frames>=2 and smoke_frames<=68 and not g.result then
        if g.pending then
            g:resolve_missile("authority")
        elseif g.phase=="players" then
            local f=g.farkle
            local active
            for i,p in ipairs(g.players) do
                if p.alive and not f:is_finished(i) then active=i;break end
            end
            if active then
                local turn=f.states[active]
                if f.Rules.can_roll(turn) then
                    g:roll_farkle(active)
                elseif turn.phase=="ready" then
                    local option=f.Rules.options(turn)[1]
                    if option then
                        for _,id in ipairs(option.ids) do
                            g:toggle_farkle(active,id)
                        end
                        g:bank_farkle(active,"attack")
                    end
                end
            else
                g:begin_boss_turn()
            end
        elseif g.phase=="boss" then
            g:advance()
        end
    elseif smoke_frames==72 then
        love.event.quit()
    end
end

function love.draw()
    local w,h=lg.getDimensions()
    state.scale=math.min(w/W,h/H)
    state.ox=math.floor((w-W*state.scale)/2)
    state.oy=math.floor((h-H*state.scale)/2)
    lg.clear(colors.bg)
    lg.push()
    lg.translate(state.ox,state.oy)
    lg.scale(state.scale)
    state.buttons={}
    if state.screen=="setup" then draw_setup() else
        draw_status()
        draw_boss()
        draw_bag()
        draw_players()
        draw_events()
        draw_controls()
    end
    lg.pop()
end

function love.mousepressed(mx,my,button_id)
    if button_id~=1 then return end
    local x=(mx-state.ox)/state.scale
    local y=(my-state.oy)/state.scale
    for i=#state.buttons,1,-1 do
        local b=state.buttons[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
            b.fn()
            return
        end
    end
end

function love.keypressed(key)
    if key=="escape" then state.screen="setup";return end
    if state.screen=="setup" then
        if key=="return" or key=="kpenter" then start() end
        return
    end
    local g=state.game
    if key=="r" then start();return end
    if key=="tab" then
        state.selected=state.selected%#g.players+1
        return
    end
    if g.result then return end
    if g.pending then
        if key=="a" then attempt(function()
            g:resolve_missile("authority")
        end) end
    elseif g.phase=="players" then
        if key=="return" or key=="kpenter" then
            attempt(function()g:begin_boss_turn()end)
        elseif key=="space" then attempt(function()
            g:roll_farkle(state.selected)end)
        elseif key=="a" then attempt(function()
            g:take_farkle(state.selected)end)
        elseif key=="i" then attempt(function()
            g:bank_farkle(state.selected,"attack")end)
        elseif key=="n" then attempt(function()
            g:bank_farkle(state.selected,"blank")end)
        elseif key=="d" then attempt(function()
            g:bank_farkle(state.selected,"discard")end)
        end
    elseif key=="space" then attempt(function()g:advance()end)
    end
end
