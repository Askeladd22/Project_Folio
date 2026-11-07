-- P4ND0RA isolated 1:1 boss-rules lab. Love 11.x.
-- The original mod's Star Realms players provide combat/Authority/cards/bases
-- manually here; no Farkle, no invented conversion into dice damage.
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
    text("P4ND0RA",48,45,"headline","gold")
    text("Original boss-rules laboratory  /  Project Folio",50,104,"sub","muted")
    panel(170,176,940,503)
    text("Configura lo scontro",216,205,"title")
    text("Difficolta'",216,270,"sub","muted")
    for i,name in ipairs(difficulty_order) do
        button(name,216+(i-1)*207,307,186,52,
            function() state.difficulty=name end,true,
            name==state.difficulty and "blue" or nil)
    end
    text("Giocatori cooperativi",216,395,"sub","muted")
    button("-",218,435,55,50,function()
        state.players=math.max(1,state.players-1)
    end,state.players>1)
    text(state.players,296,446,"title")
    button("+",344,435,55,50,function()
        state.players=math.min(4,state.players+1)
    end,state.players<4)
    text("Seed",493,395,"sub","muted")
    button("-",496,435,55,50,function()
        state.seed=math.max(1,state.seed-1)
    end,true)
    text(state.seed,567,446,"title")
    button("+",674,435,55,50,function() state.seed=state.seed+1 end,true)
    button("Avvia P4ND0RA",216,541,480,72,start,true,"green")
    text("Mod Star Realms: HP, scudi, Authority e carte sono mantenuti.",216,629,"small","muted")
    text("Le carte sono conteggi manuali: nessuna simulazione del deck.",216,653,"small","muted")
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
    local token_count=g:count_tokens()
    text("Sacchetto di azioni",827,124,"title")
    text("Cassa  "..#g.bag.."   /   Scarti  "..#g.discard..
         "   /   Estratti  "..#g.drawn,828,163,"small","muted")
    local keys={"attack","defense","repairs","oneStar","twoStar","threeStar","special","upgrade"}
    for i,token in ipairs(keys) do
        local col=(i-1)%4
        local row=math.floor((i-1)/4)
        local x=828+col*103;local y=201+row*44
        text(token,x,y,"small",token=="special" and "gold" or "text")
        text(token_count[token],x+63,y,"small","muted")
    end
end

local function player_card(p,i,x,y,w)
    local g=state.game
    local selected=state.selected==i
    use(selected and "blue" or "panel2");lg.rectangle("fill",x,y,w,91,6,6)
    if not p.alive then
        text("ELIMINATO",x+8,y+7,"small","red")
    else
        text(p.color,x+8,y+7,"sub")
    end
    text("Authority "..p.authority,x+8,y+34,"body",p.authority<=10 and "red" or "text")
    text("Base "..p.bases.."  Mano "..p.hand,x+8,y+65,"small","muted")
    state.buttons[#state.buttons+1]={x=x,y=y,w=w,h=91,
        fn=function()state.selected=i end}
end

local function draw_players()
    local g=state.game
    local p=current()
    panel(28,326,758,278)
    text("Giocatori · fase cooperativa",49,345,"title")
    for i,pl in ipairs(g.players) do
        local w=166
        player_card(pl,i,49+(i-1)*181,387,w)
    end
    if g.phase=="players" then
        text("Immetti gli effetti delle carte di Star Realms del giocatore selezionato.",
            50,498,"small","muted")
        button("Combat +1",49,532,112,44,action(function()
            g:combat(state.selected,1)
        end),p.alive,"blue")
        button("Combat +5",168,532,112,44,action(function()
            g:combat(state.selected,5)
        end),p.alive,"blue")
        button("Combat +10",287,532,122,44,action(function()
            g:combat(state.selected,10)
        end),p.alive,"blue")
        button("Cura +5",417,532,105,44,action(function()
            g:heal(state.selected,5)
        end),p.alive)
        button("+ Base",531,532,106,44,action(function()
            g:adjust_resource(state.selected,"bases",1)
        end),p.alive)
        button("+ Carta",646,532,114,44,action(function()
            g:adjust_resource(state.selected,"hand",1)
        end),p.alive)
    else
        text("Le azioni dei giocatori sono concluse. Osserva la sequenza P4ND0RA.",
            50,514,"body","muted",712)
    end
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
        text(g.result=="players_win" and "VITTORIA DEI GIOCATORI" or
             "P4ND0RA HA VINTO",49,642,"title",
             g.result=="players_win" and "green" or "red")
        button("Nuova partita [R]",49,698,247,47,start,true,"blue")
        button("Impostazioni [Esc]",308,698,214,47,
            function()state.screen="setup" end,true)
        return
    end
    if g.pending then
        local index=g.pending.targets[g.pending.current]
        local p=g.players[index]
        text("RAFFICA DI MISSILI  ·  "..p.color.." decide come reagire",
            49,642,"title","gold")
        button("Distruggi 1 base",49,693,248,52,action(function()
            g:resolve_missile("base")
        end),p.bases>0,"red")
        button("Perdi "..g.stats.missile.." Authority",309,693,265,52,
            action(function() g:resolve_missile("authority") end),
            true,"gold")
        return
    end
    if g.phase=="players" then
        text("FASE GIOCATORI  ·  agiscono tutti, poi P4ND0RA",
             49,638,"sub","blue")
        button("Scarta token (1 carta)",49,685,248,49,action(function()
            g:discard_random_token(state.selected)
        end),current().alive and current().hand>0 and #g.bag>0)
        button("Neutralizza (1 base)",309,685,229,49,action(function()
            g:blank_token(state.selected)
        end),current().alive and current().bases>0 and g.blank_next<g.draw_power)
        button("Fase boss [Invio]",780,684,450,50,
            action(function()g:begin_boss_turn()end),true,"red")
    else
        local next_action=g.queue[1]
        local stage=next_action and next_action.phase or "end"
        text("FASE BOSS  ·  "..string.upper(stage)..
             "  ·  round "..g.round,49,638,"sub","gold")
        local actions={}
        for _, token in ipairs(g.drawn_actions) do actions[#actions+1]=token end
        text("Token: "..(#actions>0 and table.concat(actions,", ") or "(nessuno)"),
            49,666,"small","muted",685)
        text("Scudi azzerati all'inizio del turno; i token risolvono in ordine.",
            49,705,"small","muted",685)
        button("Risolvi azione [Spazio]",780,684,450,52,
            action(function()g:advance()end),true,"gold")
    end
end

local function draw_status()
    local g=state.game
    text("P4ND0RA  /  ORIGINAL RULES LAB",29,21,"title","gold")
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

-- Dedicated CI smoke exercises actual LÖVE drawing, not only Lua syntax.
function love.update(_dt)
    if not smoke_enabled then return end
    smoke_frames = smoke_frames + 1
    local g = state.game
    if smoke_frames == 2 then
        g:begin_boss_turn()
    elseif smoke_frames >= 3 and smoke_frames <= 28 then
        if g.pending then
            g:resolve_missile("authority")
        elseif g.phase == "boss" then
            g:advance()
        elseif g.phase == "players" then
            g:begin_boss_turn()
        end
    elseif smoke_frames == 30 then
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
        if key=="a" then attempt(function()g:resolve_missile("authority")end) end
        if key=="b" then attempt(function()g:resolve_missile("base")end) end
    elseif g.phase=="players" then
        if key=="return" or key=="kpenter" then
            attempt(function()g:begin_boss_turn()end)
        elseif key=="1" then attempt(function()g:combat(state.selected,1)end)
        elseif key=="5" then attempt(function()g:combat(state.selected,5)end)
        elseif key=="0" then attempt(function()g:combat(state.selected,10)end)
        elseif key=="h" then attempt(function()g:heal(state.selected,5)end)
        elseif key=="b" then attempt(function()
            g:adjust_resource(state.selected,"bases",1)end)
        elseif key=="d" then attempt(function()g:discard_random_token(state.selected)end)
        elseif key=="n" then attempt(function()g:blank_token(state.selected)end)
        end
    elseif key=="space" then
        attempt(function()g:advance()end)
    end
end
