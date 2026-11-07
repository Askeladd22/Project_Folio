local Duel=require('experiments.merchant_wager_lab.duel')
local M={}

local reasons={
 initial_x='X nell’offerta iniziale: la mano va all’Artista.',
 artist_farkle='Farkle: il provvisorio è perso e il Mercante vince la mano.',
 tie_after_farkle='Farkle con offerta a zero: la mano va all’Artista.',
 offer_higher='L’offerta del Mercante supera il risultato dell’Artista.',
 tie_goes_to_artist='Parità di punti: la mano va all’Artista.',
 merchant_withdraws='Il Mercante rinuncia alla controfferta: la mano va all’Artista.',
 counteroffer_x='Il Mercante estrae X: la controfferta fallisce e la mano va all’Artista.',
 counteroffer_wins='La controfferta supera il risultato dell’Artista: il Mercante vince la mano.',
 best_of_three='Un contendente ha vinto due mani.',
 three_hands='Sono state giocate tutte e tre le mani.',
}

local actions_by_id={
 v3_roll={label='Lancia [Spazio]',width=244,primary=true},
 v3_reroll={label='Rilancia [Spazio]',width=244,primary=true},
 v3_take={label='Accantona [A]',width=194},
 v3_bank={label='Incassa [I]',width=194},
 v3_advance={label='Avanza Mercante [C]',width=270,primary=true},
 v3_next={label='Prossima mano [N]',width=270,primary=true},
 open_v3_feedback={label='Lascia feedback [F]',width=270,primary=true},
}

local function number(n)
 return tostring(n or 0)..' punti'
end

local function friendly_code(value)
 local label=tostring(value or 'esito non specificato'):gsub('[_%-]+',' ')
 return label:sub(1,1):upper()..label:sub(2)..'.'
end

function M.phase_name(duel)
 if duel.phase=='over' then return 'Incontro concluso' end
 if duel.phase=='hand_end' then return 'Mano conclusa' end
 if duel.phase=='merchant_decision' then return 'Controfferta del Mercante' end
 if duel.phase=='player' and duel.turn.phase=='fresh' then return 'Offerta iniziale' end
 if duel.phase=='player' and next(duel.turn.selected) then return 'Selezione dei dadi' end
 return 'Turno Farkle dell’Artista'
end

function M.event_message(duel)
 local hand=duel.hand
 if duel.phase=='merchant_decision' then
  local decision=Duel.preview_decision(duel)
  local difference=hand.player_result-hand.offer
  return ('Risultato %s, offerta %s: Artista +%d. Sorpasso %.0f%% / soglia %.0f%%. Il Mercante decide.'):format(
   number(hand.player_result),number(hand.offer),difference,decision.chance*100,decision.threshold*100)
 end
 if duel.phase=='hand_end' or duel.phase=='over' then
  return reasons[hand.end_reason] or
   ('La mano si conclude. Esito: '..friendly_code(hand.end_reason))
 end
 local latest=hand.player_decisions[#hand.player_decisions]
 if latest then
  if latest.action=='incassa' then
   return ('Hai incassato %s. Ora il Mercante deve superare il tuo risultato.'):format(
    number(hand.player_result))
  elseif latest.action=='accantona' then
   return ('Hai accantonato i dadi validi. Provvisorio del turno: %s.'):format(
    number(latest.provisional))
  elseif latest.outcome:match('^Farkle:') then
   return 'Farkle: nessuna combinazione valida; il provvisorio è perso.'
  elseif latest.outcome:match('^valido') then
   local points=latest.outcome:match('%+(%d+)')
   return ('Lancio valido%s. Seleziona i dadi da accantonare.'):format(
    points and ('; combinazione disponibile fino a '..number(points)) or '')
  elseif latest.action=='rilancia' then
   return 'Hai rilanciato i dadi disponibili.'
  end
 end
 if hand.x_count>0 then return reasons.initial_x end
 return ('Il Mercante offre %s. Lancia i sei dadi per iniziare.'):format(number(hand.offer))
end

function M.hand_heading(duel)
 if duel.phase=='over' then
  return duel.winner=='artist' and 'INCONTRO VINTO — ARTISTA' or 'INCONTRO VINTO — MERCANTE'
 end
 if duel.hand.winner=='artist' then return 'MANO VINTA — ARTISTA' end
 return 'MANO VINTA — MERCANTE'
end

function M.end_details(duel)
 local hand=duel.hand
 local score=('Risultato Artista: %s. Offerta finale del Mercante: %s.'):format(
  number(hand.player_result),number(hand.offer))
 if duel.phase=='over' then
  local reason=reasons[duel.end_reason] or friendly_code(duel.end_reason)
  return score..' '..reason..(' Fogli conquistati: %d.'):format(duel.pot_at_end or 0)
 end
 return score..' '..(reasons[hand.end_reason] or friendly_code(hand.end_reason))
end

function M.recent_event(duel,decision)
 if decision.actor=='merchant' then
  if decision.action=='withdraw' then return 'Il Mercante rinuncia.' end
  if decision.symbol=='X' then return 'Il Mercante estrae X: controfferta fallita.' end
  return ('Il Mercante estrae %s: offerta +%d.'):format(decision.symbol or 'un carattere',
   decision.added or 0)
 end
 if decision.action=='incassa' then
  return ('L’Artista incassa %s.'):format(number(decision.provisional))
 elseif decision.action=='accantona' then
  return ('L’Artista accantona dadi; provvisorio %s.'):format(number(decision.provisional))
 elseif decision.outcome:match('^Farkle:') then
  return 'Farkle dell’Artista: provvisorio perso.'
 elseif decision.action=='rilancia' then
  return 'L’Artista rilancia i dadi disponibili.'
 end
 return 'L’Artista lancia i dadi.'
end

function M.recent_events(duel,limit)
 local result={}
 local first=math.max(1,#duel.decisions-(limit or 3)+1)
 for i=first,#duel.decisions do
  result[#result+1]=M.recent_event(duel,duel.decisions[i])
 end
 return result
end

function M.actions(duel)
 local result={}
 local function add(id,active)
  if active then
   local spec=assert(actions_by_id[id],'unknown V3 UI action: '..id)
   result[#result+1]={id=id,label=spec.label,width=spec.width,primary=spec.primary or false}
  end
 end
 if duel.phase=='player' then
  add(duel.turn.phase=='fresh' and 'v3_roll' or 'v3_reroll',Duel.can_roll(duel))
  add('v3_take',Duel.can_take(duel))
  add('v3_bank',Duel.can_bank(duel))
 elseif duel.phase=='merchant_decision' then
  add('v3_advance',true)
 elseif duel.phase=='hand_end' then
  add('v3_next',true)
 elseif duel.phase=='over' then
  add('open_v3_feedback',true)
 end
 return result
end

function M.keyboard_action(duel,key,box_expanded)
 if box_expanded then
  if key=='e' or key=='escape' then return 'box_details' end
  if key=='r' then return 'replay_v3' end
  return nil
 end
 if key=='escape' then return 'back_mode' end
 if key=='e' then return 'box_details' end
 if key=='r' then return 'replay_v3' end
 if key:match('^[1-6]$') then
  local id=tonumber(key)
  if Duel.can_toggle(duel,id) then return 'toggle_die',id end
  return nil
 end
 local map={a='v3_take',i='v3_bank',c='v3_advance',n='v3_next',f='open_v3_feedback'}
 if key=='space' then
  if Duel.can_roll(duel) then return duel.turn.phase=='fresh' and 'v3_roll' or 'v3_reroll' end
  return nil
 end
 local action=map[key]
 if not action then return nil end
 for _,available in ipairs(M.actions(duel)) do
  if available.id==action then return action end
 end
 return nil
end

function M.viewport(width,height,canvas_width,canvas_height)
 local scale=math.min(width/canvas_width,height/canvas_height)
 return {scale=scale,x=(width-canvas_width*scale)/2,y=(height-canvas_height*scale)/2}
end

return M
