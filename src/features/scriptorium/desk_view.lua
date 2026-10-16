local Layout = require("src.features.scriptorium.page_layout")
local Colors = require("src.data.colors")
local RuntimeUI = require("src.core.runtime_ui")
local Config = require("src.data.scriptorium_module_config")
local Resolution = require("src.core.resolution_manager")
local EngineBridge = require("src.core.engine_bridge")
local View = {}
local fonts = {}
local images = {}

function View.reload_assets()
    images = {}
end

-- PNGs are drawn into explicit virtual rectangles, independent of input geometry.
-- Keep transparent margins in lectern/parchment PNGs aligned with these rectangles.
function View.draw_layer(name, rect, fallback)
    local path = (Config.desk_assets or {})[name]
    if path and images[path] == nil then
        images[path] = false
        if love.filesystem.getInfo(path, "file") then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok then
                image:setFilter("linear", "linear")
                images[path] = image
            end
        end
    end
    local image = path and images[path]
    if image then
        -- Art-pack PNGs have straight alpha; isolate compositing from the 3D pass.
        love.graphics.push("all")
        love.graphics.setBlendMode("alpha", "alphamultiply")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, rect.x, rect.y, 0, rect.w / image:getWidth(), rect.h / image:getHeight())
        love.graphics.pop()
        return true
    end
    fallback()
    return false
end

local function text(value, x, y, width, size, color)
    size = math.floor(size * RuntimeUI.scale() * (RuntimeUI.big_text() and 1.15 or 1))
    if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
    love.graphics.setFont(fonts[size])
    love.graphics.setColor(unpack(color or {0.16, 0.11, 0.07, 1}))
    love.graphics.printf(tostring(value), x, y, width, "left")
end

local function panel(r, color)
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 3)
    love.graphics.setColor(0.34, 0.22, 0.12, 1)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 3)
end

function View.draw_background(layout)
    love.graphics.clear(0.17, 0.14, 0.11, 1)
    View.draw_layer("background",layout.layers.background,function()
        panel(layout.layers.background, {0.31,0.28,0.22,1})
    end)
    View.draw_layer("desk",layout.layers.desk,function()
        panel(layout.layers.desk, {0.25,0.15,0.085,1})
        for x=0,1920,240 do
            love.graphics.setColor(0.13,0.08,0.04,1)
            love.graphics.line(x,650,x,1080)
        end
    end)
    View.draw_layer("lectern",layout.layers.lectern,function()
        love.graphics.setColor(0.08,0.05,0.03,0.55)
        love.graphics.polygon("fill",560,74,1360,74,1440,660,480,660)
        love.graphics.setColor(0.43,0.25,0.12,1)
        love.graphics.polygon("fill",570,48,1350,48,1410,642,510,642)
        panel({x=508,y=636,w=904,h=24}, {0.54,0.33,0.16,1})
    end)
    View.draw_layer("parchment",layout.layers.parchment,function()
        panel(layout.page, {0.91,0.85,0.69,1})
    end)
    -- Frames replace only the panel backing; content and hitboxes stay dynamic.
    View.draw_layer("commission_frame",layout.commission,function()
        panel(layout.commission, {0.86,0.78,0.60,1})
    end)
    View.draw_layer("gloss_frame",layout.glosses,function()
        panel(layout.glosses, {0.86,0.78,0.60,1})
    end)
end

function View.draw(self)
    local layout = Layout.get()
    View.draw_background(layout)
    local folio = self.run and self.run.current_folio
    if not folio then return end
    local element = folio.active_element or "TEXT"
    local elem = folio.elements[element]
    local focus = self.current_focus
    local legal = focus and focus.legal_by_element[element]
    local blocked = focus and focus.blocked_by_element[element]
    local hover_row, hover_col = Layout.hit_cell(self.mouse_x, self.mouse_y)
    self.hovered_cell = hover_row and {row=hover_row,col=hover_col,element=element} or nil
    text("SCRIPTORIUM  /  Folio " .. tostring(self.run.current_folio_index or 1), 650,82,620,24)
    text("4 righe / 5 colonne  -  scegli un dado, poi una casella",650,121,620,17)
    local hovered_preview
    for row=1,elem.pattern.rows do
        local open = folio:isRowOpen(row)
        local first = Layout.cell_rect(row,1)
        text(tostring(row) .. (open and " +" or " -"),621,first.y+36,62,18)
        for col=1,elem.pattern.cols do
            local r = Layout.cell_rect(row,col)
            local index = (row-1)*elem.pattern.cols+col
            local key = row .. ":" .. col
            local placed = elem.wet[index] or elem.placed[index]
            local preview = legal and legal.by_key[key]
            local constraint = elem.pattern.grid[index]
            local swatch = placed and Colors.swatch[placed.color]
                or type(constraint)=="string" and Colors.swatch[constraint]
            local fill = open and {0.96,0.90,0.75,1} or {0.58,0.53,0.43,1}
            panel(r,fill)
            if swatch then
                love.graphics.setColor(swatch[1],swatch[2],swatch[3],1)
                love.graphics.rectangle("fill",r.x+8,r.y+8,r.w-16,12)
            end
            text(placed and placed.value or type(constraint)=="number" and constraint or "-",
                r.x+36,r.y+29,60,30)
            if placed and placed.wet then text("umido",r.x+9,r.y+77,90,14) end
            if elem.stained and elem.stained[index] then text("X",r.x+9,r.y+66,80,20) end
            if preview then
                love.graphics.setColor(0.15,0.40,0.27,1)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line",r.x+3,r.y+3,r.w-6,r.h-6)
                text("+",r.x+78,r.y+72,20,20)
                self.ui_hit.placement_cells[#self.ui_hit.placement_cells+1] = {
                    element=element,row=row,col=col,rect=r,palette_options=preview.palette_colors,
                }
            elseif focus and not placed then
                text("x",r.x+78,r.y+72,20,18)
            end
            if self.state == "stain_pick" then
                for _,choice in ipairs(self.pending_stain_choices or {}) do
                    if choice.element==element and choice.row==row and choice.col==col then
                        text("!",r.x+8,r.y+68,25,24,{0.65,0.08,0.04,1})
                        self.ui_hit.stain_choice_cells[#self.ui_hit.stain_choice_cells+1] = {
                            element=element,row=row,col=col,index=choice.index,rect=r,
                        }
                    end
                end
            end
            local selected = self.selected_cell
            if selected and selected.element==element and selected.row==row and selected.col==col then
                love.graphics.setColor(0.44,0.19,0.08,1)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line",r.x-3,r.y-3,r.w+6,r.h+6)
            end
            if hover_row==row and hover_col==col then
                hovered_preview = preview
                love.graphics.setColor(0.08,0.08,0.07,1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line",r.x+6,r.y+6,r.w-12,r.h-12)
            end
            love.graphics.setLineWidth(1)
        end
    end
    local left,right = layout.commission,layout.glosses
    local done,target,label = folio:getObjectiveProgress()
    text("COMMISSIONE",left.x+24,left.y+22,372,25)
    text(self.run.commission_title or "",left.x+24,left.y+64,372,19)
    text((label or "Obiettivo") .. "  " .. done .. " / " .. target,left.x+24,left.y+120,372,20)
    text("Qualita: " .. tostring(folio:getQualityTier()) .. "\nMacchie: " .. folio.stain_count,
        left.x+24,left.y+175,372,21)
    text("INCHIOSTRI",left.x+24,left.y+247,372,19)
    self.ui_hit.inkwell_buttons = {}
    for i,color in ipairs(folio:getInkColors()) do
        local r = {x=left.x+24+((i-1)%3)*124,y=left.y+283+math.floor((i-1)/3)*72,w=112,h=62}
        panel(r,{0.96,0.90,0.75,1})
        local sw = Colors.swatch[color] or {0.3,0.3,0.3}
        love.graphics.setColor(sw[1],sw[2],sw[3],1)
        love.graphics.rectangle("fill",r.x+5,r.y+5,102,8)
        text(color,r.x+5,r.y+17,103,12)
        text(folio:getInkDrops(color),r.x+5,r.y+34,100,18)
        self.ui_hit.inkwell_buttons[#self.ui_hit.inkwell_buttons+1] = {color=color,rect=r}
    end
    text("GLOSSE",right.x+24,right.y+22,372,25)
    text(self:getInstructions(),right.x+24,right.y+70,372,20)
    local note = "Passa su una casella per leggerne lo stato.\n\n+ valida   x non disponibile\nBordo doppio: selezionata"
    if hover_row then
        local index=(hover_row-1)*elem.pattern.cols+hover_col
        if hovered_preview then
            note = "Riga " .. hover_row .. ", colonna " .. hover_col .. "\nPiazzamento disponibile.\n1 goccia del pigmento scelto.\nIl dado entra nel buffer umido."
            if #hovered_preview.palette_colors>1 then note=note .. "\nScegli il pigmento al clic." end
        elseif elem.wet[index] then note="Inchiostro umido: annullabile dal pannello dei comandi."
        elseif elem.placed[index] then note="Casella gia confermata."
        elseif not folio:isRowOpen(hover_row) then note="Riga chiusa: aprila durante la rigatura."
        elseif elem.stained and elem.stained[index] then note="Casella macchiata."
        elseif blocked and blocked[hover_row .. ":" .. hover_col] then
            local reasons={ink="Inchiostro insufficiente.",color="Pigmento non compatibile.",value="Valore o regola di riga non compatibile."}
            note=reasons[blocked[hover_row .. ":" .. hover_col]] or "Piazzamento non disponibile."
        end
        local constraint = elem.pattern.grid[index]
        if constraint then note=note .. "\nVincolo: " .. tostring(constraint) end
    end
    text("ANTEPRIMA",right.x+24,right.y+240,372,19)
    text(note,right.x+24,right.y+276,372,19)
end

local function button(_self, rect, label, enabled, primary)
    panel(rect, enabled and (primary and {0.75,0.59,0.32,1} or {0.86,0.78,0.60,1})
        or {0.46,0.39,0.29,1})
    text(label,rect.x+10,rect.y+10,rect.w-20,18,
        enabled and {0.12,0.09,0.05,1} or {0.75,0.69,0.58,1})
    return enabled and rect or nil
end

-- Same action/hitbox contract as the legacy HUD; all mutations remain in Actions.
function View.draw_controls(self)
    local folio = self.run and self.run.current_folio
    if not folio then return end
    local layout = Layout.get()
    local dock, actions = layout.dock, layout.actions
    View.draw_layer("palette_frame",dock,function()
        panel(dock,{0.57,0.43,0.28,1})
    end)
    View.draw_layer("actions_frame",actions,function()
        panel(actions,{0.57,0.43,0.28,1})
    end)
    local placing = self.state == "placing"
    local wet_count = folio:getWetCount()
    local wet_max = math.max(1,math.floor(tonumber(folio.wet_buffer_max) or 3))
    self.ui_hit.dice_chips = {} -- 3D dice are the only selection surface in desk mode.
    self.ui_hit.wet_buffer_undo_buttons = {}
    text("TAVOLOZZA DEL TURNO",dock.x+16,dock.y+12,388,17)
    for i=1,3 do
        local color = (self.turn_palette or {})[i]
        local r={x=dock.x+16+(i-1)*130,y=dock.y+42,w=122,h=42}
        panel(r,{0.88,0.81,0.66,1})
        if color then
            local sw=Colors.swatch[color] or {0.3,0.3,0.3}
            love.graphics.setColor(sw[1],sw[2],sw[3],1)
            love.graphics.rectangle("fill",r.x+5,r.y+5,112,6)
            text(color .. "  " .. folio:getInkDrops(color),r.x+6,r.y+17,111,13)
        else text("-",r.x+50,r.y+10,50,18) end
    end
    text("INCHIOSTRO UMIDO  " .. wet_count .. "/" .. wet_max,dock.x+16,dock.y+100,388,17)
    local step=388/wet_max
    for i=1,wet_max do
        local entry=(folio.wet_buffer or {})[i]
        local r={x=dock.x+16+(i-1)*step,y=dock.y+132,w=step-8,h=58}
        panel(r,{0.79,0.69,0.52,1})
        if entry then
            local sw=Colors.swatch[entry.color] or {0.3,0.3,0.3}
            love.graphics.setColor(sw[1],sw[2],sw[3],1)
            love.graphics.rectangle("fill",r.x+6,r.y+6,8,46)
            text(entry.value,r.x+24,r.y+12,r.w-54,23)
            if placing and (folio.turn_pushes or 0)==0 then
                local undo={x=r.x+r.w-32,y=r.y+8,w=28,h=40}
                button(self,undo,"x",true)
                self.ui_hit.wet_buffer_undo_buttons[#self.ui_hit.wet_buffer_undo_buttons+1]={index=i,rect=undo}
            end
        end
    end
    text("x annulla prima del rilancio",dock.x+16,dock.y+204,388,15)

    text("AZIONI",actions.x+16,actions.y+12,310,17)
    self.ui_hit.system_button=button(self,{x=actions.x+362,y=actions.y+8,w=42,h=40},"...",true)
    local action_y=actions.y+58
    if placing then
        local max=tonumber(folio.reroll_max)
        local left=max and math.max(0,math.floor(max)-(folio.turn_pushes or 0))
        local has_placed=false
        for _,die in ipairs(self.dice_results or {}) do if die.used then has_placed=true end end
        local can_reroll=has_placed and wet_count<wet_max and (left==nil or left>0)
        self.ui_hit.push_all_button=button(self,{x=actions.x+16,y=action_y,w=188,h=58},
            "Rilancia" .. (left and "  " .. left .. "/" .. math.floor(max) or ""),can_reroll)
        self.ui_hit.stop_button=button(self,{x=actions.x+216,y=action_y,w=188,h=58},"Conferma",wet_count>0,true)
        local penalty=math.max(1,wet_count)
        text("Fallimento: " .. penalty .. (penalty==1 and " macchia" or " macchie"),actions.x+16,action_y+78,388,16)
    else
        self.ui_hit.roll_button=button(self,{x=actions.x+16,y=action_y,w=388,h=58},
            self.state=="waiting" and "Lancia i dadi" or "Attendi",self.state=="waiting",true)
    end
end

function View.draw_popups(self)
    local actions=Layout.get().actions
    if self.show_system_menu then
        local r={x=actions.x+140,y=actions.y-158,w=280,h=150}
        panel(r,{0.66,0.52,0.35,1})
        for i,item in ipairs({{"system_restart_button","Ricomincia"},{"system_settings_button","Impostazioni"},{"system_main_menu_button","Menu principale"}}) do
            self.ui_hit[item[1]]=button(self,{x=r.x+8,y=r.y+8+(i-1)*46,w=r.w-16,h=40},item[2],true)
        end
    end
    local picker=self.palette_picker
    if picker then
        local options=picker.options or {}
        local width=#options*116+16
        local x=math.max(8,math.min(1920-width-8,(picker.anchor_x or 960)-width/2))
        local y=math.max(8,(picker.anchor_y or 180)-66)
        panel({x=x,y=y,w=width,h=62},{0.40,0.30,0.20,1})
        self.ui_hit.palette_color_buttons={}
        for i,color in ipairs(options) do
            local r={x=x+8+(i-1)*116,y=y+8,w=108,h=46}
            button(self,r,color,true)
            local sw=Colors.swatch[color] or {0.3,0.3,0.3}
            love.graphics.setColor(sw[1],sw[2],sw[3],1)
            love.graphics.rectangle("fill",r.x+6,r.y+35,r.w-12,6)
            self.ui_hit.palette_color_buttons[#self.ui_hit.palette_color_buttons+1]={color=color,rect=r}
        end
    end
end

function View.draw_dice_feedback(self, hits)
    local selected=self:getSelectedDie()
    local mouse_x,mouse_y=love.mouse.getPosition()
    local hovered=EngineBridge.pickTrayDie(mouse_x,mouse_y)
    local states={}
    local remaining,unusable=0,0
    for _,die in ipairs(self.dice_results or {}) do
        states[die.index]=die
        if not die.used then
            remaining=remaining+1
            if die.unusable then unusable=unusable+1 end
        end
    end
    -- Rerolls omit previously spent dice from dice_results. Keep their status on
    -- the physical die using the existing wet placement's original roll index.
    local folio=self.run and self.run.current_folio
    if self.state=="placing" and folio then
        for _,entry in ipairs(folio.wet_buffer or {}) do
            if entry.source_roll_index and not states[entry.source_roll_index] then
                states[entry.source_roll_index]={used=true,value=entry.value}
            end
        end
    end
    for _,hit in ipairs(hits or {}) do
        local die=states[hit.index]
        if die then
            local x,y=Resolution.to_virtual(hit.x,hit.y)
            local radius=hit.r/Resolution.get_scale()
            if selected==die or hovered==hit.index then
                love.graphics.setColor(1,0.85,0.38,1)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line",x,y,radius+3)
                love.graphics.setLineWidth(1)
            end
            if die.used or die.unusable then
                text(die.used and "usato" or "bloccato",x-40,y+radius,90,14,{1,0.85,0.60,1})
            end
        end
    end
    local info = self.state=="placing" and ("Dadi rimasti: " .. remaining .. "  |  Non utilizzabili: " .. unusable)
        or (self.state=="rolling" and "Lancio in corso" or "Seleziona i dadi direttamente sul banco")
    if selected then info=info .. "  |  Scelto: " .. selected.value .. "  |  Mosse: " .. (self.current_focus and self.current_focus.total_legal or 0) end
    text(info,540,1046,840,17,{0.98,0.92,0.79,1})
end

return View
